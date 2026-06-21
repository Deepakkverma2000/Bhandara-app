require('dotenv').config();

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const {
  getAllBhandaras,
  getBhandaraById,
  getBhandarasByUserId,
  createBhandara,
  deleteExpiredBhandaras,
  isSupabaseConfigured,
} = require('./database');
const {
  upsertDeviceToken,
  getNotificationsForDevice,
  getUnreadCount,
  markNotificationRead,
  markAllRead,
  notifyNewBhandara,
} = require('./notifications');
const { verifyAuthToken, requireActiveUser, requireAdmin } = require('./auth');
const { submitBhandaraReport, getUserBlockStatus, getAllReportsForAdmin, getReportsGroupedByUserForAdmin, setUserBlocked } = require('./reports');

const app = express();
const PORT = process.env.PORT || 3000;

const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const IMAGE_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif']);

function isAllowedImage(file) {
  if (file.mimetype && file.mimetype.startsWith('image/')) {
    return true;
  }

  const ext = path.extname(file.originalname || '').toLowerCase();
  if (IMAGE_EXTENSIONS.has(ext)) {
    return true;
  }

  // Android often sends gallery files as application/octet-stream
  if (
    file.mimetype === 'application/octet-stream' &&
    (ext === '' || IMAGE_EXTENSIONS.has(ext))
  ) {
    return true;
  }

  return false;
}

function resolveImageMime(file) {
  if (file.mimetype && file.mimetype.startsWith('image/')) {
    return file.mimetype;
  }

  const ext = path.extname(file.originalname || '').toLowerCase();
  const mimeMap = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.gif': 'image/gif',
    '.heic': 'image/heic',
    '.heif': 'image/heif',
  };

  return mimeMap[ext] || 'image/jpeg';
}

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (isAllowedImage(file)) {
      cb(null, true);
    } else {
      console.error('Rejected file:', file.originalname, file.mimetype);
      cb(new Error(`Only image files are allowed (received: ${file.mimetype})`));
    }
  },
});

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(uploadsDir));

app.use((req, _res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
  next();
});

function formatBhandara(row, req) {
  if (!row) return null;
  const baseUrl = `${req.protocol}://${req.get('host')}`;

  let imageUrl = row.imageUrl || null;
  if (!imageUrl && row.imagePath) {
    imageUrl = `${baseUrl}/uploads/${row.imagePath}`;
  }

  return {
    id: row.id,
    bhandaraName: row.bhandaraName || row.name,
    publisherName: row.publisherName || 'Unknown',
    name: row.bhandaraName || row.name,
    street: row.street,
    village: row.village,
    pinCode: row.pinCode || row.pin_code,
    date: row.date,
    latitude: row.latitude,
    longitude: row.longitude,
    imageUrl,
    postedBy: row.postedBy || row.posted_by || null,
    createdAt: row.createdAt || row.created_at,
  };
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

app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    message: 'Bhandara Live API is running',
    storage: isSupabaseConfigured() ? 'supabase' : 'local-json',
  });
});

app.get('/api/bhandaras', async (req, res) => {
  try {
    const userLat = parseFloat(req.query.lat);
    const userLng = parseFloat(req.query.lng);
    const hasLocation = !Number.isNaN(userLat) && !Number.isNaN(userLng);

    let bhandaras = (await getAllBhandaras()).map((row) => formatBhandara(row, req));

    if (hasLocation) {
      bhandaras = bhandaras
        .map((b) => ({
          ...b,
          distanceKm: haversineDistance(userLat, userLng, b.latitude, b.longitude),
        }))
        .sort((a, b) => a.distanceKm - b.distanceKm);
    }

    res.json({ success: true, data: bhandaras });
  } catch (error) {
    console.error('GET /api/bhandaras error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/api/bhandaras/:id', async (req, res) => {
  try {
    const row = await getBhandaraById(req.params.id);
    if (!row) {
      return res.status(404).json({ success: false, message: 'Bhandara not found' });
    }
    res.json({ success: true, data: formatBhandara(row, req) });
  } catch (error) {
    console.error('GET /api/bhandaras/:id error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.post('/api/bhandaras', verifyAuthToken, requireActiveUser, upload.single('image'), async (req, res) => {
  try {
    console.log('POST body fields:', req.body);

    const {
      bhandaraName,
      publisherName,
      name,
      street,
      village,
      pinCode,
      date,
      latitude,
      longitude,
    } = req.body;

    const finalBhandaraName = (bhandaraName || name || '').trim();
    const finalPublisherName = (publisherName || '').trim();

    if (
      !finalBhandaraName ||
      !finalPublisherName ||
      !street ||
      !village ||
      !pinCode ||
      !date ||
      !latitude ||
      !longitude
    ) {
      return res.status(400).json({
        success: false,
        message:
          'All fields are required: bhandaraName, publisherName, street, village, pinCode, date, latitude, longitude',
        received: req.body,
      });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      return res.status(400).json({ success: false, message: 'Invalid latitude or longitude' });
    }

    const data = {
      id: uuidv4(),
      bhandaraName: finalBhandaraName,
      publisherName: finalPublisherName,
      street: street.trim(),
      village: village.trim(),
      pinCode: pinCode.trim(),
      date,
      latitude: lat,
      longitude: lng,
      imageUrl: null,
      postedBy: req.authUser.id,
      createdAt: new Date().toISOString(),
    };

    const created = await createBhandara(data, req.file ? { ...req.file, mimetype: resolveImageMime(req.file) } : null);
    console.log('Bhandara created:', created.id);

    const excludeDeviceId = req.body.deviceId || req.headers['x-device-id'] || null;
    notifyNewBhandara(created, excludeDeviceId).catch((err) => {
      console.error('Notification error:', err.message);
    });

    res.status(201).json({ success: true, data: formatBhandara(created, req) });
  } catch (error) {
    console.error('POST /api/bhandaras error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.post('/api/reports', verifyAuthToken, requireActiveUser, async (req, res) => {
  try {
    const { bhandaraId, reason } = req.body;

    if (!bhandaraId) {
      return res.status(400).json({ success: false, message: 'bhandaraId is required' });
    }

    if (!reason || !String(reason).trim()) {
      return res.status(400).json({ success: false, message: 'Report reason is required' });
    }

    const result = await submitBhandaraReport({
      bhandaraId: String(bhandaraId),
      reporterId: req.authUser.id,
      reason: String(reason),
    });

    res.status(201).json({ success: true, data: result });
  } catch (error) {
    console.error('POST /api/reports error:', error.message);
    const status = error.message.includes('already reported') ? 409 : 400;
    res.status(status).json({ success: false, message: error.message });
  }
});

app.post('/api/bhandaras/:id/report', verifyAuthToken, requireActiveUser, async (req, res) => {
  try {
    const { reason } = req.body;

    if (!reason || !String(reason).trim()) {
      return res.status(400).json({ success: false, message: 'Report reason is required' });
    }

    const result = await submitBhandaraReport({
      bhandaraId: req.params.id,
      reporterId: req.authUser.id,
      reason: String(reason),
    });

    res.status(201).json({ success: true, data: result });
  } catch (error) {
    console.error('POST /api/bhandaras/:id/report error:', error.message);
    const status = error.message.includes('already reported') ? 409 : 400;
    res.status(status).json({ success: false, message: error.message });
  }
});

app.get('/api/users/me/status', verifyAuthToken, async (req, res) => {
  try {
    const status = await getUserBlockStatus(req.authUser.id);
    res.json({ success: true, data: status });
  } catch (error) {
    console.error('GET /api/users/me/status error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/api/users/me/bhandaras', verifyAuthToken, requireActiveUser, async (req, res) => {
  try {
    const bhandaras = await getBhandarasByUserId(req.authUser.id);
    res.json({
      success: true,
      data: bhandaras.map((row) => formatBhandara(row, req)),
      total: bhandaras.length,
    });
  } catch (error) {
    console.error('GET /api/users/me/bhandaras error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/api/admin/reports', verifyAuthToken, requireAdmin, async (req, res) => {
  try {
    const reports = await getAllReportsForAdmin();
    res.json({ success: true, data: reports, total: reports.length });
  } catch (error) {
    console.error('GET /api/admin/reports error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/api/admin/reports/by-user', verifyAuthToken, requireAdmin, async (req, res) => {
  try {
    const groups = await getReportsGroupedByUserForAdmin();
    res.json({ success: true, data: groups, total: groups.length });
  } catch (error) {
    console.error('GET /api/admin/reports/by-user error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.patch('/api/admin/users/:id/block', verifyAuthToken, requireAdmin, async (req, res) => {
  try {
    const blocked = req.body?.blocked;
    if (typeof blocked !== 'boolean') {
      return res.status(400).json({ success: false, message: 'blocked (boolean) is required' });
    }

    const result = await setUserBlocked(req.params.id, blocked);
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('PATCH /api/admin/users/:id/block error:', error.message);
    res.status(400).json({ success: false, message: error.message });
  }
});

app.post('/api/device-tokens', async (req, res) => {
  try {
    const { deviceId, fcmToken, platform, latitude, longitude } = req.body;
    if (!deviceId) {
      return res.status(400).json({ success: false, message: 'deviceId is required' });
    }

    const lat = latitude != null ? parseFloat(latitude) : null;
    const lng = longitude != null ? parseFloat(longitude) : null;

    await upsertDeviceToken({
      deviceId,
      fcmToken,
      platform,
      latitude: Number.isNaN(lat) ? null : lat,
      longitude: Number.isNaN(lng) ? null : lng,
    });

    res.json({ success: true });
  } catch (error) {
    console.error('POST /api/device-tokens error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/api/notifications', async (req, res) => {
  try {
    const deviceId = req.query.deviceId;
    if (!deviceId) {
      return res.status(400).json({ success: false, message: 'deviceId query param is required' });
    }

    const unreadOnly = req.query.unreadOnly === 'true';
    const notifications = await getNotificationsForDevice(deviceId, { unreadOnly });
    res.json({ success: true, data: notifications });
  } catch (error) {
    console.error('GET /api/notifications error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/api/notifications/unread-count', async (req, res) => {
  try {
    const deviceId = req.query.deviceId;
    if (!deviceId) {
      return res.status(400).json({ success: false, message: 'deviceId query param is required' });
    }

    const count = await getUnreadCount(deviceId);
    res.json({ success: true, count });
  } catch (error) {
    console.error('GET /api/notifications/unread-count error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.post('/api/notifications/:id/read', async (req, res) => {
  try {
    const { deviceId } = req.body;
    if (!deviceId) {
      return res.status(400).json({ success: false, message: 'deviceId is required' });
    }

    await markNotificationRead(req.params.id, deviceId);
    res.json({ success: true });
  } catch (error) {
    console.error('POST /api/notifications/:id/read error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.post('/api/notifications/read-all', async (req, res) => {
  try {
    const { deviceId } = req.body;
    if (!deviceId) {
      return res.status(400).json({ success: false, message: 'deviceId is required' });
    }

    const result = await markAllRead(deviceId);
    res.json({ success: true, ...result });
  } catch (error) {
    console.error('POST /api/notifications/read-all error:', error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err.message);
  res.status(400).json({ success: false, message: err.message });
});

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`Bhandara Live API running on http://0.0.0.0:${PORT}`);
  console.log(`Storage: ${isSupabaseConfigured() ? 'Supabase' : 'Local JSON (backend/data/bhandaras.json)'}`);
  if (!isSupabaseConfigured()) {
    console.log('Tip: Add Supabase keys to backend/.env to store data in cloud');
  }

  try {
    await deleteExpiredBhandaras();
  } catch (error) {
    console.error('Startup cleanup failed:', error.message);
  }
});
