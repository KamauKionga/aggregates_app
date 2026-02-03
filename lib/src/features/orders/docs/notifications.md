# Notifications

This document describes the notification system added to the app.

Collections / schema

- users/{uid}/preferences/notifications
  - email: bool
  - sms: bool
  - inApp: bool
  - whatsapp: bool

- users/{uid}/notifications/{notificationId}
  - title: string
  - body: string
  - data: map
  - read: bool
  - createdAt: timestamp

- admin_notifications/{id}
  - disputeId: string
  - orderId: string
  - raisedBy: string
  - reason: string
  - createdAt: timestamp
  - status: 'new'|'processing'|'done'

Triggers

- orders/{orderId} onUpdate: onOrderStatusChange
  - Sends buyer and trucker notifications for status transitions (truck_assigned, loaded, delivered, cancelled).

- disputes/{disputeId} onCreate: onDisputeCreated
  - Notifies buyer, trucker and writes an admin_notifications doc for admins to pick up.

Providers

- Email: configured via SENDGRID_API_KEY (functions config or env)
- SMS: Twilio config via TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM
- WhatsApp: Twilio WhatsApp using WHATSAPP_FROM
- In-app: Firestore notifications collection (users/{uid}/notifications)

Client behavior

- The app listens to users/{uid}/notifications for real-time in-app messages.
- Users manage preferences in users/{uid}/preferences/notifications.
- Sensitive provider keys must be set in functions config:
  firebase functions:config:set sendgrid.key="..." twilio.sid="..." twilio.token="..." twilio.from="..." twilio.whatsapp_from="..."