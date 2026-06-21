const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { getSupabase, isSupabaseConfigured, supabaseUrl } = require('./supabase');

const dataPath = path.join(__dirname, 'data', 'bhandaras.json');
const IMAGE_BUCKET = 'bhandara-images';

function mapFromDb(row) {
  return {
    id: row.id,
    bhandaraName: row.bhandara_name,
    publisherName: row.publisher_name,
    street: row.street,
    village: row.village,
    pinCode: row.pin_code,
    date: row.date,
    latitude: row.latitude,
    longitude: row.longitude,
    imageUrl: row.image_url,
    imagePath: null,
    postedBy: row.posted_by || null,
    createdAt: row.created_at,
  };
}

function mapToDb(data) {
  return {
    id: data.id,
    bhandara_name: data.bhandaraName,
    publisher_name: data.publisherName,
    street: data.street,
    village: data.village,
    pin_code: data.pinCode,
    date: data.date,
    latitude: data.latitude,
    longitude: data.longitude,
    image_url: data.imageUrl || null,
    posted_by: data.postedBy || null,
    created_at: data.createdAt,
  };
}

function ensureDataFile() {
  const dir = path.dirname(dataPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  if (!fs.existsSync(dataPath)) fs.writeFileSync(dataPath, JSON.stringify([], null, 2));
}

function readAllLocal() {
  ensureDataFile();
  return JSON.parse(fs.readFileSync(dataPath, 'utf8'));
}

function writeAllLocal(bhandaras) {
  ensureDataFile();
  fs.writeFileSync(dataPath, JSON.stringify(bhandaras, null, 2));
}

async function uploadImageToSupabase(file) {
  const ext = path.extname(file.originalname) || '.jpg';
  const fileName = `${uuidv4()}${ext}`;
  const supabase = getSupabase();

  const { error } = await supabase.storage
    .from(IMAGE_BUCKET)
    .upload(fileName, file.buffer, {
      contentType: file.mimetype,
      upsert: false,
    });

  if (error) throw new Error(`Image upload failed: ${error.message}`);

  return `${supabaseUrl}/storage/v1/object/public/${IMAGE_BUCKET}/${fileName}`;
}

async function deleteExpiredBhandaras() {
  const now = new Date().toISOString();

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('bhandaras')
      .delete()
      .lt('date', now)
      .select('id');

    if (error) throw new Error(error.message);

    const removed = data?.length || 0;
    if (removed > 0) {
      console.log(`Removed ${removed} expired Bhandara(s) from Supabase`);
    }
    return removed;
  }

  const bhandaras = readAllLocal();
  const active = bhandaras.filter((b) => new Date(b.date) >= new Date());
  const removed = bhandaras.length - active.length;

  if (removed > 0) {
    writeAllLocal(active);
    console.log(`Removed ${removed} expired Bhandara(s) from local storage`);
  }

  return removed;
}

async function getAllBhandaras() {
  await deleteExpiredBhandaras();

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('bhandaras')
      .select('*')
      .order('date', { ascending: true });

    if (error) throw new Error(error.message);
    return (data || []).map(mapFromDb);
  }

  return readAllLocal().sort((a, b) => new Date(a.date) - new Date(b.date));
}

async function getBhandaraById(id) {
  await deleteExpiredBhandaras();

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('bhandaras')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data ? mapFromDb(data) : null;
  }

  return readAllLocal().find((b) => b.id === id) || null;
}

async function createBhandara(data, imageFile = null) {
  if (isSupabaseConfigured()) {
    if (imageFile) {
      data.imageUrl = await uploadImageToSupabase(imageFile);
    }

    const supabase = getSupabase();
    const { data: inserted, error } = await supabase
      .from('bhandaras')
      .insert(mapToDb(data))
      .select('*')
      .single();

    if (error) throw new Error(error.message);
    return mapFromDb(inserted);
  }

  if (imageFile) {
    const uploadsDir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
    const ext = path.extname(imageFile.originalname) || '.jpg';
    const fileName = `${uuidv4()}${ext}`;
    fs.writeFileSync(path.join(uploadsDir, fileName), imageFile.buffer);
    data.imagePath = fileName;
  }

  const bhandaras = readAllLocal();
  bhandaras.push({
    ...data,
    postedBy: data.postedBy || null,
  });
  writeAllLocal(bhandaras);
  return data;
}

async function getBhandarasByUserId(userId) {
  await deleteExpiredBhandaras();

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const byId = new Map();

    const { data: linked, error } = await supabase
      .from('bhandaras')
      .select('*')
      .eq('posted_by', userId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);

    for (const row of linked || []) {
      byId.set(row.id, mapFromDb(row));
    }

    const { data: user, error: userError } = await supabase
      .from('users')
      .select('full_name')
      .eq('id', userId)
      .maybeSingle();

    if (userError) throw new Error(userError.message);

    const fullName = (user?.full_name || '').trim().toLowerCase();
    if (fullName) {
      const { data: legacy, error: legacyError } = await supabase
        .from('bhandaras')
        .select('*')
        .is('posted_by', null);

      if (legacyError) throw new Error(legacyError.message);

      for (const row of legacy || []) {
        if ((row.publisher_name || '').trim().toLowerCase() === fullName) {
          byId.set(row.id, mapFromDb(row));
        }
      }
    }

    return [...byId.values()].sort(
      (a, b) => new Date(b.createdAt) - new Date(a.createdAt),
    );
  }

  return readAllLocal()
    .filter((b) => b.postedBy === userId)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

module.exports = {
  getAllBhandaras,
  getBhandaraById,
  getBhandarasByUserId,
  createBhandara,
  deleteExpiredBhandaras,
  isSupabaseConfigured,
};
