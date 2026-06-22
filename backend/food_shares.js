const fs = require('fs');
const path = require('path');
const { getSupabase, isSupabaseConfigured } = require('./supabase');

const dataPath = path.join(__dirname, 'data', 'food_shares.json');

function mapFromDb(row) {
  return {
    id: row.id,
    postedBy: row.posted_by,
    contactName: row.contact_name,
    phoneNumber: row.phone_number,
    eventName: row.event_name,
    foodDescription: row.food_description,
    quantity: row.quantity,
    street: row.street,
    village: row.village,
    pinCode: row.pin_code,
    latitude: row.latitude,
    longitude: row.longitude,
    status: row.status,
    acceptedBy: row.accepted_by,
    acceptedByName: row.accepted_by_name,
    acceptedByPhone: row.accepted_by_phone,
    acceptedPickupTime: row.accepted_pickup_time,
    acceptedPlatesRequired: row.accepted_plates_required,
    acceptedAt: row.accepted_at,
    createdAt: row.created_at,
  };
}

function mapToDb(data) {
  return {
    id: data.id,
    posted_by: data.postedBy,
    contact_name: data.contactName,
    phone_number: data.phoneNumber,
    event_name: data.eventName || null,
    food_description: data.foodDescription,
    quantity: data.quantity || null,
    street: data.street,
    village: data.village,
    pin_code: data.pinCode,
    latitude: data.latitude,
    longitude: data.longitude,
    status: data.status || 'open',
    accepted_by: data.acceptedBy || null,
    accepted_by_name: data.acceptedByName || null,
    accepted_by_phone: data.acceptedByPhone || null,
    accepted_pickup_time: data.acceptedPickupTime || null,
    accepted_plates_required: data.acceptedPlatesRequired ?? null,
    accepted_at: data.acceptedAt || null,
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

function writeAllLocal(posts) {
  ensureDataFile();
  fs.writeFileSync(dataPath, JSON.stringify(posts, null, 2));
}

async function getAllFoodShares() {
  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('food_share_posts')
      .select('*')
      .in('status', ['open', 'accepted'])
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data || []).map(mapFromDb);
  }

  return readAllLocal()
    .filter((p) => p.status === 'open' || p.status === 'accepted')
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

async function getFoodShareById(id) {
  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('food_share_posts')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data ? mapFromDb(data) : null;
  }

  return readAllLocal().find((p) => p.id === id) || null;
}

async function createFoodShare(data) {
  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data: row, error } = await supabase
      .from('food_share_posts')
      .insert(mapToDb(data))
      .select('*')
      .single();

    if (error) throw new Error(error.message);
    return mapFromDb(row);
  }

  const posts = readAllLocal();
  posts.unshift(data);
  writeAllLocal(posts);
  return data;
}

async function acceptFoodShare(id, userId, { contactName, phoneNumber, pickupTime, platesRequired }) {
  const existing = await getFoodShareById(id);
  if (!existing) throw new Error('Food share post not found');
  if (existing.postedBy === userId) throw new Error('You cannot accept your own post');
  if (existing.status !== 'open') throw new Error('This food has already been accepted');

  const acceptedAt = new Date().toISOString();
  const updates = {
    status: 'accepted',
    acceptedBy: userId,
    acceptedByName: contactName,
    acceptedByPhone: phoneNumber,
    acceptedPickupTime: pickupTime,
    acceptedPlatesRequired: platesRequired,
    acceptedAt,
  };

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('food_share_posts')
      .update({
        status: 'accepted',
        accepted_by: userId,
        accepted_by_name: contactName,
        accepted_by_phone: phoneNumber,
        accepted_pickup_time: pickupTime,
        accepted_plates_required: platesRequired,
        accepted_at: acceptedAt,
      })
      .eq('id', id)
      .eq('status', 'open')
      .select('*')
      .maybeSingle();

    if (error) throw new Error(error.message);
    if (!data) throw new Error('This food has already been accepted');
    return mapFromDb(data);
  }

  const posts = readAllLocal();
  const index = posts.findIndex((p) => p.id === id);
  if (index === -1) throw new Error('Food share post not found');
  if (posts[index].status !== 'open') throw new Error('This food has already been accepted');

  posts[index] = { ...posts[index], ...updates };
  writeAllLocal(posts);
  return posts[index];
}

async function updateFoodShare(id, userId, data) {
  const existing = await getFoodShareById(id);
  if (!existing) throw new Error('Food share post not found');
  if (existing.postedBy !== userId) throw new Error('You can only edit your own post');

  const updated = {
    ...existing,
    contactName: data.contactName,
    phoneNumber: data.phoneNumber,
    eventName: data.eventName || null,
    foodDescription: data.foodDescription,
    quantity: data.quantity || null,
    street: data.street,
    village: data.village,
    pinCode: data.pinCode,
    latitude: data.latitude,
    longitude: data.longitude,
  };

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { data: row, error } = await supabase
      .from('food_share_posts')
      .update({
        contact_name: updated.contactName,
        phone_number: updated.phoneNumber,
        event_name: updated.eventName,
        food_description: updated.foodDescription,
        quantity: updated.quantity,
        street: updated.street,
        village: updated.village,
        pin_code: updated.pinCode,
        latitude: updated.latitude,
        longitude: updated.longitude,
      })
      .eq('id', id)
      .eq('posted_by', userId)
      .select('*')
      .maybeSingle();

    if (error) throw new Error(error.message);
    if (!row) throw new Error('Food share post not found');
    return mapFromDb(row);
  }

  const posts = readAllLocal();
  const index = posts.findIndex((p) => p.id === id);
  if (index === -1) throw new Error('Food share post not found');
  if (posts[index].postedBy !== userId) throw new Error('You can only edit your own post');

  posts[index] = updated;
  writeAllLocal(posts);
  return updated;
}

async function deleteFoodShare(id, userId) {
  const existing = await getFoodShareById(id);
  if (!existing) throw new Error('Food share post not found');
  if (existing.postedBy !== userId) throw new Error('You can only remove your own post');

  if (isSupabaseConfigured()) {
    const supabase = getSupabase();
    const { error } = await supabase.from('food_share_posts').delete().eq('id', id).eq('posted_by', userId);
    if (error) throw new Error(error.message);
    return true;
  }

  const posts = readAllLocal().filter((p) => p.id !== id);
  writeAllLocal(posts);
  return true;
}

module.exports = {
  getAllFoodShares,
  getFoodShareById,
  createFoodShare,
  updateFoodShare,
  acceptFoodShare,
  deleteFoodShare,
};
