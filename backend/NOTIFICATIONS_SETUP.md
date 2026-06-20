# Notifications Setup — Bhandara Live

When someone adds a new Bhandara, **all other devices** get:
1. **Phone notification** (if Firebase is configured)
2. **In-app bell** on Home dashboard (orange badge with count)
3. Tap notification → opens list → tap item → marks as **seen** and removes from bell

---

## Step 1 — Run Supabase SQL (required)

In Supabase **SQL Editor**, run the full file:
`backend/supabase/schema.sql`

This creates:
- `notifications` — inbox entries
- `notification_reads` — per-device seen state
- `device_tokens` — FCM tokens for push

---

## Step 2 — Restart backend

```powershell
cd "C:\Users\rahul\Desktop\Bhandara Live\backend"
npm start
```

---

## Step 3 — In-app notifications (works without Firebase)

Already built in:
- Bell icon on **Home** header (top right)
- Polls every 15 seconds for new Bhandara alerts
- **Seen notifications disappear** from bell and list

Test:
1. Open app on **Phone A** and **Phone B** (or Chrome + phone)
2. Add Bhandara from Phone A
3. Within ~15 sec, Phone B bell shows `1`
4. Tap bell → tap notification → it clears after seen

---

## Step 4 — Push notifications to all devices (Firebase)

For instant alerts when app is closed:

### A) Firebase project
1. [Firebase Console](https://console.firebase.google.com) → Add project
2. Add **Android app** with package: `com.bhandaralive.bhandara_live`
3. Download `google-services.json`
4. Place at: `frontend/android/app/google-services.json`

### B) Backend service account
1. Firebase → Project Settings → **Service accounts**
2. **Generate new private key** → save JSON file
3. Put file in `backend/firebase-service-account.json`
4. Add to `backend/.env`:

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

### C) Rebuild app

```powershell
cd "C:\Users\rahul\Desktop\Bhandara Live\frontend"
flutter pub get
flutter run -d RZCX1045CMH
```

Allow **notification permission** when prompted on phone.

---

## How it works

```
User adds Bhandara
       ↓
Backend saves to Supabase
       ↓
Creates notification record
       ↓
├── FCM push → all registered devices (except poster)
└── In-app poll → bell badge on other devices

User taps notification → marked read → removed from bell
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Bell never updates | Backend running? Same Wi-Fi? Correct IP in `api_config.dart` |
| SQL error on notifications | Re-run `schema.sql` in Supabase |
| No phone push | Add `google-services.json` + Firebase service account |
| Poster gets own alert | Fixed — poster device is auto-excluded |
