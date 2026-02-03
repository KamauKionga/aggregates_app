// bootstrap.ts

// Code to initialize admin only once
import * as admin from 'firebase-admin';

admin.initializeApp();

export default admin;