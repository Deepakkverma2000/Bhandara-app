let admin = null;
let messaging = null;

function initFirebaseAdmin() {
  if (messaging) return messaging;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (!serviceAccountJson && !serviceAccountPath) {
    return null;
  }

  try {
    admin = require('firebase-admin');

    if (admin.apps.length > 0) {
      messaging = admin.messaging();
      return messaging;
    }

    let credential;
    if (serviceAccountPath) {
      credential = admin.credential.cert(require(serviceAccountPath));
    } else {
      credential = admin.credential.cert(JSON.parse(serviceAccountJson));
    }

    admin.initializeApp({ credential });
    messaging = admin.messaging();
    console.log('Firebase Admin initialized for push notifications');
    return messaging;
  } catch (error) {
    console.warn('Firebase Admin not configured:', error.message);
    return null;
  }
}

async function sendPushNotifications(tokens, { title, body, data = {} }) {
  const msg = initFirebaseAdmin();
  if (!msg || tokens.length === 0) {
    return { successCount: 0, failureCount: tokens.length };
  }

  const stringData = Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, String(value)]),
  );

  try {
    const response = await msg.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: stringData,
      android: {
        priority: 'high',
        notification: {
          channelId: 'bhandara_notifications',
          sound: 'default',
        },
      },
    });

    return {
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('FCM send error:', error.message);
    return { successCount: 0, failureCount: tokens.length };
  }
}

module.exports = { sendPushNotifications, initFirebaseAdmin };
