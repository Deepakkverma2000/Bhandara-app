/**
 * Applies migrate_user_columns.sql using Supabase service role + pg when DATABASE_URL is set.
 * Falls back to printing instructions.
 */
require('dotenv').config();
const { isSupabaseConfigured } = require('../supabase');
const { getSupabase } = require('../supabase');

async function checkColumns() {
  if (!isSupabaseConfigured()) {
    console.log('Supabase not configured in .env');
    return false;
  }

  const supabase = getSupabase();
  const { error } = await supabase.from('users').select('is_blocked').limit(1);

  if (error && error.message.includes('is_blocked')) {
    return false;
  }

  return !error;
}

async function main() {
  const ok = await checkColumns();
  if (ok) {
    console.log('users.is_blocked column already exists.');
    return;
  }

  if (process.env.DATABASE_URL) {
    require('./migrate-db.js');
    return;
  }

  console.log('');
  console.log('Missing column: users.is_blocked');
  console.log('');
  console.log('Quick fix — open Supabase SQL Editor and run:');
  console.log('  backend/supabase/migrate_user_columns.sql');
  console.log('');
  console.log('Or add DATABASE_URL to backend/.env and run: npm run db:migrate');
  console.log('');
  process.exit(1);
}

main();
