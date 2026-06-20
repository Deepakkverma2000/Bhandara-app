# Supabase Setup for Bhandara Live

Follow these steps in your Supabase account. Add keys only to `backend/.env` on your PC — never commit them to git.

## Step 1 — Create / open project

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Open your project (or create a new one)

## Step 2 — Create database table

1. In Supabase: **SQL Editor** → **New query**
2. Copy all SQL from `backend/supabase/schema.sql`
3. Click **Run**

This creates:
- Table `bhandaras` (all Bhandara data)
- Storage bucket `bhandara-images` (invitation photos)
- Public read policies

## Step 3 — Create storage bucket (if SQL didn't create it)

1. Go to **Storage** → **New bucket**
2. Name: `bhandara-images`
3. Enable **Public bucket**
4. Save

## Step 4 — Get API keys

1. Go to **Project Settings** → **API**
2. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **service_role** key (secret) → `SUPABASE_SERVICE_ROLE_KEY`

> Use **service_role** key only on backend (never in Flutter app).

## Step 5 — Create `.env` file on your PC

In folder `backend/`, create a file named `.env`:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...
PORT=3000
```

You can copy from `.env.example` and fill values.

## Step 6 — Install dependencies & restart backend

```powershell
cd "C:\Users\rahul\Desktop\Bhandara Live\backend"
npm install
npm start
```

You should see:
```
Storage: Supabase
```

If you see `Local JSON`, Supabase keys are missing from `.env`.

## Step 7 — Run app on phone

```powershell
cd "C:\Users\rahul\Desktop\Bhandara Live\frontend"
flutter run -d RZCX1045CMH
```

Make sure:
- Phone & PC on **same Wi-Fi**
- `frontend/lib/config/api_config.dart` has correct PC IP
- Backend is running

---

## Where data is saved

| Setup | Data location | Images |
|-------|---------------|--------|
| **With Supabase** | Supabase → Table Editor → `bhandaras` | Storage → `bhandara-images` |
| **Without Supabase** | `backend/data/bhandaras.json` | `backend/uploads/` |

---

## Troubleshooting save error

1. **Restart backend** after code changes (`Ctrl+C` then `npm start`)
2. Check health: open `http://YOUR_PC_IP:3000/api/health` on phone browser
3. If connection fails → fix `pcLocalIp` in `api_config.dart`
4. If 400 error → fill all fields including **Bhandara Name** and **Publisher Name**
5. Check backend terminal logs when you tap Save
