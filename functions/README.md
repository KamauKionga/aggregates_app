# Cloud Functions for Aggregates App

This folder contains Firebase Cloud Functions to handle financial settlement tasks:

- `onOrderDelivered` (Firestore onUpdate): When an order transitions to `delivered`, credits pending wallet entries for the trucker and the referring agent (if any). Marks order doc with `settlementProcessed` to ensure idempotency.

- `eodSettlement` (Scheduled): Runs daily at 23:59 EAT (Africa/Nairobi timezone) and moves all wallets' `pending` amounts into `available`, writing corresponding ledger entries with reference `eod-settlement`.

- `approveWithdrawal` (Callable): Callable function restricted to admin users (requires custom claim `admin: true`). Approves a withdrawal request and writes ledger entries atomically.

Testing locally:

- Install Firebase CLI and start emulators: `firebase emulators:start --only functions,firestore`
- Deploy or run functions locally via emulator. Ensure admin custom claim exists on test user (use `firebase auth:import` or admin SDK to set custom claims).

Security note:

- The callable `approveWithdrawal` checks the `admin` custom claim. In production you should manage admin claims via Firebase Admin SDK.
- The `onOrderDelivered` function assumes truthfulness of `order.truckerEarnings`. In future, move earnings calculations server-side or validate amounts.
