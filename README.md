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

Edit `frontend/lib/config/api_config.dart`:

- **Android Emulator**: `http://10.0.2.2:3000` (default)
- **Physical Device**: Use your PC's local IP, e.g. `http://192.168.1.5:3000`
- **iOS Simulator**: `http://localhost:3000`

Make sure your phone and PC are on the same Wi-Fi when testing on a physical device.

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
