# Bhandara Live

Mobile app to discover and share **Bhandara** (community feast) events near you.

## Project Structure

```
Bhandara Live/
├── backend/          # Node.js REST API
│   ├── server.js
│   ├── database.js
│   ├── data/
│   └── uploads/
└── frontend/         # Flutter mobile app
    └── lib/
        ├── config/
        ├── models/
        ├── screens/
        ├── services/
        ├── utils/
        └── widgets/
```

## Features

- **Add Bhandara**: Name, street, village, pin code, date/time, invitation image, map location
- **List Bhandaras**: View all events with details
- **Nearest first**: When location is enabled, Bhandaras are sorted by distance
- **Map view**: See location on in-app map
- **Google Maps**: Tap location to open in Google Maps
- **WhatsApp share**: Share location via WhatsApp

---

## Backend Setup

```powershell
cd backend
npm install
npm start
```

Server runs at `http://localhost:3000`

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/bhandaras?lat=&lng=` | List all (sorted by distance if lat/lng provided) |
| GET | `/api/bhandaras/:id` | Get single Bhandara |
| POST | `/api/bhandaras` | Create Bhandara (multipart form) |

---

## Frontend Setup

```powershell
cd frontend
flutter pub get
flutter run
```

### API URL Configuration

Edit `frontend/lib/config/api_config.dart` and set `pcLocalIp` to your PC's Wi-Fi IP:

- **Android Emulator**: use `10.0.2.2`
- **Physical Device**: e.g. `192.168.1.5` (same Wi-Fi as your phone)
- **iOS Simulator**: `localhost` is used automatically on non-Android

See `frontend/lib/config/api_config.example.dart` for a template.

### Secrets (do not commit)

| File | Purpose |
|------|---------|
| `backend/.env` | Supabase service role key — copy from `backend/.env.example` |
| `frontend/lib/config/supabase_config.dart` | Supabase URL, anon key, Google Web Client ID — copy from `supabase_config.example.dart` |

These files are **gitignored**. Never push real keys to GitHub.

---

## How to Run (Full Stack)

1. Start backend:
   ```powershell
   cd "C:\Users\rahul\Desktop\Bhandara Live\backend"
   npm start
   ```

2. Start Flutter app (in another terminal):
   ```powershell
   cd "C:\Users\rahul\Desktop\Bhandara Live\frontend"
   flutter run
   ```

3. Allow location permission when prompted for nearest Bhandara sorting.

---

## Permissions

- Location (for nearest Bhandara + map picker)
- Gallery/Camera (for invitation image)
- Internet (API calls)
