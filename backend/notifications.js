const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { getSupabase, isSupabaseConfigured } = require('./supabase');
const { sendPushNotifications } = require('./pushService');

const dataDir = path.join(__dirname, 'data');
const tokensPath = path.join(dataDir, 'device_tokens.json');
const notificationsPath = path.join(dataDir, 'notifications.json');
const readsPath = path.join(dataDir, 'notification_reads.json');

function ensureDataFiles() {
  if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
  if (!fs.existsSync(tokensPath)) fs.writeFileSync(tokensPath, '[]');
  if (!fs.existsSync(notificationsPath)) fs.writeFileSync(notificationsPath, '[]');
  if (!fs.existsSync(readsPath)) fs.writeFileSync(readsPath, '[]');
}

function readJson(filePath) {
  ensureDataFiles();
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeJson(filePath, data) {
  ensureDataFiles();
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
}

function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function formatNotification(row, deviceId, readIds) {
  return {
    id: row.id,
    bhandaraId: row.bhandara_id || row.bhandaraId,
    title: row.title,
    body: row.body,
    createdAt: row.created_at || row.createdAt,
    isRead: readIds.has(row.id),
  };
}

async function upsertDeviceToken({ deviceId, fcmToken, platform, latitude, longitude }) {
  if (!deviceId) throw new Error('deviceId is required');

  const now = new Date().toISOString();

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('device_tokens')
      .upsert(
        {
          device_id: deviceId,
          fcm_token: fcmToken || null,
          platform: platform || 'unknown',
          latitude: latitude ?? null,
          longitude: longitude ?? null,
          updated_at: now,
        },
        { onConflict: 'device_id' },
      )
      .select('*')
      .single();

    if (error) throw new Error(error.message);
    return data;
  }

  const tokens = readJson(tokensPath);
  const index = tokens.findIndex((t) => t.deviceId === deviceId);
  const record = {
    deviceId,
    fcmToken: fcmToken || null,
    platform: platform || 'unknown',
    latitude: latitude ?? null,
    longitude: longitude ?? null,
    updatedAt: now,
  };

  if (index >= 0) {
    tokens[index] = { ...tokens[index], ...record };
  } else {
    tokens.push({ ...record, createdAt: now });
  }

  writeJson(tokensPath, tokens);
  return record;
}

async function getNotificationsForDevice(deviceId, { userId = null, unreadOnly = false } = {}) {
  if (!deviceId && !userId) throw new Error('deviceId or userId is required');

  let list;

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();

    const [{ data: notifications, error: notifError }, { data: reads, error: readError }] =
      await Promise.all([
        supabase.from('notifications').select('*').order('created_at', { ascending: false }),
        userId
          ? supabase.from('notification_reads').select('notification_id').eq('user_id', userId)
          : supabase.from('notification_reads').select('notification_id').eq('device_id', deviceId),
      ]);

    if (notifError) throw new Error(notifError.message);
    if (readError) throw new Error(readError.message);

    const readIds = new Set((reads || []).map((r) => r.notification_id));
    list = (notifications || []).map((n) => formatNotification(n, deviceId, readIds));
  } else {
    const notifications = readJson(notificationsPath);
    const reads = readJson(readsPath).filter((r) =>
      userId ? r.userId === userId : r.deviceId === deviceId,
    );
    const readIds = new Set(reads.map((r) => r.notificationId));

    list = notifications
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .map((n) => formatNotification(n, deviceId, readIds));
  }

  if (unreadOnly) {
    list = list.filter((n) => !n.isRead);
  }

  return list;
}

async function getUnreadCount(deviceId, userId = null) {
  const list = await getNotificationsForDevice(deviceId, { userId, unreadOnly: true });
  return list.length;
}

async function markNotificationRead(notificationId, deviceId, userId = null) {
  if (!notificationId || (!deviceId && !userId)) {
    throw new Error('notificationId and deviceId or userId are required');
  }

  const now = new Date().toISOString();

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const row = userId
      ? {
          notification_id: notificationId,
          user_id: userId,
          device_id: deviceId || `user-${userId}`,
          read_at: now,
        }
      : {
          notification_id: notificationId,
          device_id: deviceId,
          read_at: now,
        };

    const onConflict = userId ? 'notification_id,user_id' : 'notification_id,device_id';
    const { error } = await supabase.from('notification_reads').upsert(row, { onConflict });

    if (error) throw new Error(error.message);
    return { success: true };
  }

  const reads = readJson(readsPath);
  const exists = reads.some((r) =>
    r.notificationId === notificationId &&
    (userId ? r.userId === userId : r.deviceId === deviceId),
  );

  if (!exists) {
    reads.push({
      id: uuidv4(),
      notificationId,
      deviceId: deviceId || null,
      userId: userId || null,
      readAt: now,
    });
    writeJson(readsPath, reads);
  }

  return { success: true };
}

async function markAllRead(deviceId, userId = null) {
  const notifications = await getNotificationsForDevice(deviceId, { userId });
  const unread = notifications.filter((n) => !n.isRead);

  for (const n of unread) {
    await markNotificationRead(n.id, deviceId, userId);
  }

  return { success: true, count: unread.length };
}

async function createNotificationRecord(bhandara) {
  const title = 'New Bhandara Added';
  const body = `"${bhandara.bhandaraName}" added in ${bhandara.village}`;

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('notifications')
      .insert({
        bhandara_id: bhandara.id,
        title,
        body,
      })
      .select('*')
      .single();

    if (error) throw new Error(error.message);
    return data;
  }

  const record = {
    id: uuidv4(),
    bhandaraId: bhandara.id,
    title,
    body,
    createdAt: new Date().toISOString(),
  };

  const notifications = readJson(notificationsPath);
  notifications.push(record);
  writeJson(notificationsPath, notifications);
  return record;
}

async function getAllDeviceTokens(excludeDeviceId = null) {
  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    let query = supabase.from('device_tokens').select('*');
    if (excludeDeviceId) {
      query = query.neq('device_id', excludeDeviceId);
    }

    const { data, error } = await query;
    if (error) throw new Error(error.message);
    return data || [];
  }

  let tokens = readJson(tokensPath);
  if (excludeDeviceId) {
    tokens = tokens.filter((t) => t.deviceId !== excludeDeviceId);
  }
  return tokens.map((t) => ({
    device_id: t.deviceId,
    fcm_token: t.fcmToken,
    latitude: t.latitude,
    longitude: t.longitude,
  }));
}

async function notifyNewBhandara(bhandara, excludeUserId = null, excludeDeviceId = null) {
  const notification = await createNotificationRecord(bhandara);

  // Don't show notification to the user who just added the Bhandara
  if (notification?.id) {
    if (excludeUserId) {
      await markNotificationRead(notification.id, excludeDeviceId, excludeUserId);
    } else if (excludeDeviceId) {
      await markNotificationRead(notification.id, excludeDeviceId);
    }
  }

  const tokens = await getAllDeviceTokens(excludeDeviceId);
  const fcmTokens = tokens
    .map((t) => t.fcm_token)
    .filter((token) => typeof token === 'string' && token.length > 0);

  if (fcmTokens.length === 0) {
    console.log('No FCM tokens registered — in-app notifications still saved');
    return { pushed: 0 };
  }

  const title = 'New Bhandara Added';
  const body = `"${bhandara.bhandaraName}" added in ${bhandara.village}`;

  const result = await sendPushNotifications(fcmTokens, {
    title,
    body,
    data: {
      bhandaraId: bhandara.id,
      type: 'new_bhandara',
    },
  });

  console.log(`Push sent to ${result.successCount}/${fcmTokens.length} devices`);
  return result;
}

module.exports = {
  upsertDeviceToken,
  getNotificationsForDevice,
  getUnreadCount,
  markNotificationRead,
  markAllRead,
  notifyNewBhandara,
};
