import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Idempotent on order settlement via 'settlementProcessed' flag on order doc.
export const onOrderDelivered = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!after) return;

    const beforeStatus = before?.status;
    const afterStatus = after.status;

    if (beforeStatus === 'delivered' || afterStatus !== 'delivered') {
      // nothing to do
      return;
    }

    const orderId = context.params.orderId;

    // If already processed, exit
    if (after.settlementProcessed) return;

    const buyerId = after.buyerId as string;
    const truckerId = after.assignedTruckerId as string | undefined;
    const truckerEarnings = (after.truckerEarnings as number) || 0;

    await db.runTransaction(async (tx) => {
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await tx.get(orderRef);
      const orderData = orderSnap.data() as any;
      if (orderData?.settlementProcessed) return;

      // Credit trucker pending wallet
      if (truckerId && truckerEarnings > 0) {
        const walletRef = db.collection('wallets').doc(truckerId);
        const wSnap = await tx.get(walletRef);
        if (!wSnap.exists) {
          tx.set(walletRef, { id: truckerId, ownerType: 'trucker', available: 0, pending: truckerEarnings, updatedAt: admin.firestore.Timestamp.now() });
        } else {
          const wData = wSnap.data() as any;
          const pending = (wData.pending || 0) + truckerEarnings;
          tx.update(walletRef, { pending, updatedAt: admin.firestore.Timestamp.now() });
        }
        const ledgerRef = walletRef.collection('ledger').doc();
        tx.set(ledgerRef, { id: ledgerRef.id, walletId: truckerId, amount: truckerEarnings, type: 'pending_credit', reference: `order:${orderId}:trucker_earning`, createdAt: admin.firestore.Timestamp.now() });
      }

      // Credit agent commission if buyer linked
      const buyerRef = db.collection('users').doc(buyerId);
      const buyerSnap = await tx.get(buyerRef);
      const referredByAgentId = (buyerSnap.data() as any)?.referredByAgentId as string | undefined;
      if (referredByAgentId) {
        const commission = 200; // Ksh
        const walletRef = db.collection('wallets').doc(referredByAgentId);
        const wSnap = await tx.get(walletRef);
        if (!wSnap.exists) {
          tx.set(walletRef, { id: referredByAgentId, ownerType: 'agent', available: 0, pending: commission, updatedAt: admin.firestore.Timestamp.now() });
        } else {
          const wData = wSnap.data() as any;
          const pending = (wData.pending || 0) + commission;
          tx.update(walletRef, { pending, updatedAt: admin.firestore.Timestamp.now() });
        }
        const ledgerRef = walletRef.collection('ledger').doc();
        tx.set(ledgerRef, { id: ledgerRef.id, walletId: referredByAgentId, amount: commission, type: 'pending_credit', reference: `order:${orderId}:agent_commission`, createdAt: admin.firestore.Timestamp.now() });
      }

      tx.update(orderRef, { settlementProcessed: true, settlementProcessedAt: admin.firestore.Timestamp.now() });
    });
  });

// Move pending => available at EoD (23:59 EAT). Schedule using Nairobi timezone.
export const eodSettlement = functions.pubsub
  .schedule('59 23 * * *')
  .timeZone('Africa/Nairobi')
  .onRun(async (context) => {
    const walletsRef = db.collection('wallets');
    const q = await walletsRef.where('pending', '>', 0).get();
    const batch = db.batch();
    for (const doc of q.docs) {
      const data = doc.data() as any;
      const pending = data.pending || 0;
      if (!pending || pending === 0) continue;
      const available = data.available || 0;
      const docRef = walletsRef.doc(doc.id);
      batch.update(docRef, { available: available + pending, pending: 0, updatedAt: admin.firestore.Timestamp.now() });
      const ledgerRef = docRef.collection('ledger').doc();
      batch.set(ledgerRef, { id: ledgerRef.id, walletId: doc.id, amount: pending, type: 'available_credit', reference: 'eod-settlement', createdAt: admin.firestore.Timestamp.now() });
    }
    await batch.commit();
    return null;
  });

// Admin callable to approve withdrawal by id. Caller must have admin custom claim set (admin=true).
export const approveWithdrawal = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Request had no auth context');
  const isAdmin = context.auth.token && context.auth.token.admin === true;
  if (!isAdmin) throw new functions.https.HttpsError('permission-denied', 'Admin privileges required');

  const withdrawalId = data.withdrawalId as string;
  if (!withdrawalId) throw new functions.https.HttpsError('invalid-argument', 'withdrawalId is required');

  const withdrawRef = db.collection('withdrawals').doc(withdrawalId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(withdrawRef);
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'Withdrawal not found');
    const wd = snap.data() as any;
    if (wd.status !== 'requested') throw new functions.https.HttpsError('failed-precondition', 'Withdrawal not in requested state');

    const walletRef = db.collection('wallets').doc(wd.walletId as string);
    const wSnap = await tx.get(walletRef);
    if (!wSnap.exists) throw new functions.https.HttpsError('not-found', 'Wallet not found');
    const wData = wSnap.data() as any;
    const available = wData.available || 0;
    const amount = wd.amount as number;
    if (available < amount) throw new functions.https.HttpsError('failed-precondition', 'Insufficient balance');
    tx.update(walletRef, { available: available - amount, updatedAt: admin.firestore.Timestamp.now() });
    tx.update(withdrawRef, { status: 'approved', approvedBy: context.auth.uid, approvedAt: admin.firestore.Timestamp.now() });
    const ledgerRef = walletRef.collection('ledger').doc();
    tx.set(ledgerRef, { id: ledgerRef.id, walletId: walletRef.id, amount: -amount, type: 'withdrawal', reference: withdrawalId, createdAt: admin.firestore.Timestamp.now() });
  });
  return { success: true };
});
