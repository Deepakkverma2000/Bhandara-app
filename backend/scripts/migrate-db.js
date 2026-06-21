require('dotenv').config();
const fs = require('fs');
const path = require('path');

async function runMigration() {
  const databaseUrl = process.env.DATABASE_URL;

  if (!databaseUrl) {
    console.error('DATABASE_URL is not set in backend/.env');
    console.error('');
    console.error('Get it from Supabase Dashboard → Project Settings → Database');
    console.error('→ Connection string → URI (use the postgres password)');
    console.error('');
    console.error('OR paste backend/supabase/migrate_user_columns.sql into Supabase SQL Editor and Run.');
    process.exit(1);
  }

  let pg;
  try {
    pg = require('pg');
  } catch (_) {
    console.error('Run: npm install pg');
    process.exit(1);
  }

  const sqlPath = path.join(__dirname, '..', 'supabase', 'migrate_user_columns.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');

  const client = new pg.Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    await client.query(sql);
    console.log('Migration completed successfully.');
  } catch (error) {
    console.error('Migration failed:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();
