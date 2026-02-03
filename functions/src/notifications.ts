import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// Providers configuration read from env or functions config
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || functions.config().sendgrid?.key;
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || functions.config().twilio?.sid;
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || functions.config().twilio?.token;
const TWILIO_FROM = process.env.TWILIO_FROM || functions.config().twilio?.from;
const WHATSAPP_FROM = process.env.WHATSAPP_FROM || functions.config().twilio?.whatsapp_from;

// NOTE: Provider SDK code is intentionally left as placeholders. Install and configure SendGrid/Twilio SDKs and replace the pseudo-code below.

async function sendEmail(to: string, subject: string, text: string) {
  if (!SENDGRID_API_KEY) {
    console.warn('SendGrid key not configured, skipping email to', to);
    return;
  }
  // TODO: Implement SendGrid send here.
}

async function sendSms(to: string, text: string) {
  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_FROM) {
    console.warn('Twilio not configured, skipping SMS to', to);
    return;
  }
  // TODO: Implement Twilio SMS send here.
}

async function sendWhatsapp(to: string, text: string) {
  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !WHATSAPP_FROM) {
    console.warn('WhatsApp not configured, skipping WhatsApp to', to);
    return;
  }
  // TODO: Implement Twilio WhatsApp send here.
}

async function sendInApp(userId: string, payload: any) {
  const notifRef = db.collection('users').doc(userId).collection('notifications').doc();
  await notifRef.set({
    title: payload.title,
    body: payload.body,
    data: payload.data || {},
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export async function sendNotificationToUser(userId: string, payload: { title: string; body: string; data?: any }) {
  // Read notification preferences
  const prefRef = db.collection('users').doc(userId).collection('preferences').doc('notifications');
  const prefSnap = await prefRef.get();
  const prefs = prefSnap.exists ? prefSnap.data() : { email: true, sms: false, inApp: true, whatsapp: false };

  // Read user contact info
  const userSnap = await db.collection('users').doc(userId).get();
  const user = userSnap.exists ? userSnap.data() : null;
  const email = user?.email;
  const phone = user?.phone;

  // In-app
  if (prefs?.inApp !== false) {
    await sendInApp(userId, payload);
  }

  // Email
  if (prefs?.email && email) {
    try {
      await sendEmail(email, payload.title, payload.body);
    } catch (e) {
      console.error('email send error', e);
    }
  }

  // SMS
  if (prefs?.sms && phone) {
    try {
      await sendSms(phone, payload.body);
    } catch (e) {
      console.error('sms send error', e);
    }
  }

  // WhatsApp (abstracted)
  if (prefs?.whatsapp && phone) {
    try {
      await sendWhatsapp(phone, payload.body);
    } catch (e) {
      console.error('whatsapp send error', e);
    }
  }
}

// Trigger: order status changes
export const onOrderStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const prevStatus = before.status;
    const nextStatus = after.status;
    if (prevStatus === nextStatus) return;

    const orderId = context.params.orderId;
    const buyerId = after.buyerId;
    const truckerId = after.truckerId;

    // Friendly messages per status
    let title = `Order ${orderId} update`;
    let body = `Order status changed from ${prevStatus} to ${nextStatus}`;

    if (nextStatus === 'truck_assigned') {
      title = 'Truck Assigned';
      body = `A truck has been assigned to your order ${orderId}.`;
    } else if (nextStatus === 'loaded') {
      title = 'Order Loaded';
      body = `Order ${orderId} has been loaded.`;
    } else if (nextStatus === 'delivered') {
      title = 'Order Delivered';
      body = `Order ${orderId} has been delivered.`;
    } else if (nextStatus === 'cancelled') {
      title = 'Order Cancelled';
      body = `Order ${orderId} has been cancelled.`;
    }

    // Send notifications
    if (buyerId) {
      await sendNotificationToUser(buyerId, { title, body, data: { orderId, status: nextStatus } });
    }
    if (truckerId && ['truck_assigned', 'loaded', 'delivered', 'cancelled'].includes(nextStatus)) {
      await sendNotificationToUser(truckerId, { title, body, data: { orderId, status: nextStatus } });
    }
  });

// Trigger: dispute created
export const onDisputeCreated = functions.firestore
  .document('disputes/{disputeId}')
  .onCreate(async (snap, ctx) => {
    const dispute = snap.data();
    const orderId = dispute.orderId;
    const raisedBy = dispute.raisedBy;
    const reason = dispute.reason;

    const orderSnap = await db.collection('orders').doc(orderId).get();
    const order = orderSnap.exists ? orderSnap.data() : null;
    const buyerId = order?.buyerId;
    const truckerId = order?.truckerId;

    // Create admin notification doc for admins to pick up (admins can poll this collection)
    const adminNotifRef = db.collection('admin_notifications').doc();
    await adminNotifRef.set({
      disputeId: snap.id,
      orderId,
      raisedBy,
      reason,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'new',
    });

    // Notify buyer/trucker (except the one who raised the dispute)
    if (buyerId && buyerId !== raisedBy) {
      await sendNotificationToUser(buyerId, { title: 'Dispute Opened', body: `A dispute was opened for order ${orderId}: ${reason}` });
    }
    if (truckerId && truckerId !== raisedBy) {
      await sendNotificationToUser(truckerId, { title: 'Dispute Opened', body: `A dispute was opened for order ${orderId}: ${reason}` });
    }
    // Confirm to the raising user
    if (raisedBy) {
      await sendNotificationToUser(raisedBy, { title: 'Dispute Submitted', body: `Your dispute for order ${orderId} was submitted.` });
    }
  });
