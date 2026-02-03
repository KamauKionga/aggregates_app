import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

const CANCELLATION_FEE_PERCENT = 0.10; // default 10% fee after truck assigned

function isAdmin(context: functions.https.CallableContext) {
  return !!(context.auth && context.auth.token && context.auth.token.admin === true);
}

export const cancelOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Request not authenticated');

  const uid = context.auth.uid;
  const { orderId, reason } = data;
  if (!orderId) throw new functions.https.HttpsError('invalid-argument', 'orderId required');

  const orderRef = db.collection('orders').doc(orderId);

  return db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) throw new functions.https.HttpsError('not-found', 'Order not found');

    const order = orderSnap.data()!;
    const status = order.status || 'pending';
    const totalAmountCents = order.totalAmountCents || 0;
    const buyerId = order.buyerId;
    const truckerId = order.truckerId;

    if (status === 'loaded' || status === 'delivered') {
      throw new functions.https.HttpsError('failed-precondition', 'Order cannot be cancelled after loading or delivery');
    }

    if (status === 'pending') {
      const refundAmount = totalAmountCents;

      tx.update(orderRef, {
        status: 'cancelled',
        cancellation: {
          by: uid,
          reason: reason || 'Cancelled by user before truck assigned',
          refundedCents: refundAmount,
          feeCents: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });

      const buyerWalletRef = db.collection('wallets').doc(buyerId);
      const buyerLedgerRef = buyerWalletRef.collection('ledger').doc();

      tx.set(buyerLedgerRef, {
        amountCents: refundAmount,
        type: 'credit',
        ref: `order-${orderId}-refund`,
        status: 'available',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(buyerWalletRef, {
        availableCents: admin.firestore.FieldValue.increment(refundAmount),
      });

      return { success: true, refundedCents: refundAmount };
    }

    if (status === 'truck_assigned') {
      const fee = Math.round(totalAmountCents * CANCELLATION_FEE_PERCENT);
      const refundAmount = Math.max(0, totalAmountCents - fee);

      tx.update(orderRef, {
        status: 'cancelled',
        cancellation: {
          by: uid,
          reason: reason || 'Cancelled after truck assignment',
          refundedCents: refundAmount,
          feeCents: fee,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });

      const buyerWalletRef = db.collection('wallets').doc(buyerId);
      const buyerLedgerRef = buyerWalletRef.collection('ledger').doc();
      tx.set(buyerLedgerRef, {
        amountCents: refundAmount,
        type: 'credit',
        ref: `order-${orderId}-refund`,
        status: 'available',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(buyerWalletRef, {
        availableCents: admin.firestore.FieldValue.increment(refundAmount),
      });

      const platformWalletRef = db.collection('platform').doc('revenue');
      const platformLedgerRef = platformWalletRef.collection('ledger').doc();
      tx.set(platformLedgerRef, {
        amountCents: fee,
        type: 'credit',
        ref: `order-${orderId}-cancellationFee`,
        status: 'available',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(platformWalletRef, {
        availableCents: admin.firestore.FieldValue.increment(fee),
      });

      return { success: true, refundedCents: refundAmount, feeCents: fee };
    }

    throw new functions.https.HttpsError('failed-precondition', `Order in state ${status} cannot be cancelled`);
  });
});

export const openDispute = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Request not authenticated');
  const uid = context.auth.uid;
  const { orderId, reason, evidenceUrls } = data;
  if (!orderId || !reason) throw new functions.https.HttpsError('invalid-argument', 'orderId and reason required');

  const orderRef = db.collection('orders').doc(orderId);
  const disputeRef = db.collection('disputes').doc();

  return db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) throw new functions.https.HttpsError('not-found', 'Order not found');
    const order = orderSnap.data()!;
    const truckerId = order.truckerId;

    tx.set(disputeRef, {
      orderId,
      raisedBy: uid,
      reason,
      evidenceUrls: evidenceUrls || [],
      status: 'open',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (truckerId) {
      const ledgerRef = db.collection('wallets').doc(truckerId).collection('ledger');
      const q = await ledgerRef.where('ref', '==', `order-${orderId}`).where('status', '==', 'pending').get();
      let totalHeld = 0;
      q.forEach((le) => {
        const amt = le.data()?.amountCents || 0;
        tx.update(le.ref, { status: 'on_hold' });
        totalHeld += amt;
      });
      if (totalHeld > 0) {
        const walletRef = db.collection('wallets').doc(truckerId);
        tx.update(walletRef, {
          pendingCents: admin.firestore.FieldValue.increment(-totalHeld),
          onHoldCents: admin.firestore.FieldValue.increment(totalHeld),
        });
      }
    }

    tx.update(orderRef, { hasOpenDispute: true });

    return { success: true, disputeId: disputeRef.id };
  });
});

export const resolveDispute = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Request not authenticated');
  if (!isAdmin(context)) throw new functions.https.HttpsError('permission-denied', 'Admin only');

  const adminUid = context.auth.uid;
  const { disputeId, action, refundAmountCents, note } = data;
  if (!disputeId || !action) throw new functions.https.HttpsError('invalid-argument', 'disputeId and action required');

  const disputeRef = db.collection('disputes').doc(disputeId);

  return db.runTransaction(async (tx) => {
    const dSnap = await tx.get(disputeRef);
    if (!dSnap.exists) throw new functions.https.HttpsError('not-found', 'Dispute not found');
    const dispute = dSnap.data()!;
    if (dispute.status === 'resolved') {
      throw new functions.https.HttpsError('failed-precondition', 'Dispute already resolved');
    }

    const orderRef = db.collection('orders').doc(dispute.orderId);
    const oSnap = await tx.get(orderRef);
    if (!oSnap.exists) throw new functions.https.HttpsError('not-found', 'Order not found');
    const order = oSnap.data()!;
    const buyerId = order.buyerId;
    const truckerId = order.truckerId;
    const totalAmountCents = order.totalAmountCents || 0;

    let actualRefund = 0;
    if (action === 'refund') {
      actualRefund = refundAmountCents ?? totalAmountCents;
    } else if (action === 'partial') {
      if (!refundAmountCents) throw new functions.https.HttpsError('invalid-argument', 'refundAmountCents required for partial');
      actualRefund = Math.min(refundAmountCents, totalAmountCents);
    } else if (action === 'deny') {
      actualRefund = 0;
    } else {
      throw new functions.https.HttpsError('invalid-argument', 'Unknown action');
    }

    tx.update(disputeRef, {
      status: action === 'deny' ? 'rejected' : 'resolved',
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedBy: adminUid,
      resolutionNote: note || null,
      refundAmountCents: actualRefund,
    });

    tx.update(orderRef, { hasOpenDispute: false });

    if (actualRefund > 0) {
      const buyerWalletRef = db.collection('wallets').doc(buyerId);
      const buyerLedgerRef = buyerWalletRef.collection('ledger').doc();
      tx.set(buyerLedgerRef, {
        amountCents: actualRefund,
        type: 'credit',
        ref: `dispute-${disputeId}-refund`,
        status: 'available',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(buyerWalletRef, {
        availableCents: admin.firestore.FieldValue.increment(actualRefund),
      });
    }

    if (truckerId) {
      const ledgerQuery = await db.collection('wallets').doc(truckerId).collection('ledger')
        .where('ref', '==', `order-${orderRef.id}`)
        .where('status', '==', 'on_hold')
        .get();

      let totalReleased = 0;
      ledgerQuery.forEach((le) => {
        const leData = le.data();
        const amt = leData.amountCents || 0;
        tx.update(le.ref, { status: 'released' });
        totalReleased += amt;
      });

      if (totalReleased > 0) {
        const walletRef = db.collection('wallets').doc(truckerId);
        tx.update(walletRef, {
          onHoldCents: admin.firestore.FieldValue.increment(-totalReleased),
          availableCents: admin.firestore.FieldValue.increment(totalReleased),
        });
      }
    }

    return { success: true, actualRefundCents: actualRefund };
  });
});
