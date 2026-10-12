# Qanat

Flutter/Dart coursework prototype for finding, comparing and mock-booking flights. The UI is currently in Kazakh. Browsing is guest-first; signing in is required for booking and trips.

Project brief: [docs/project_brief_kk.md](docs/project_brief_kk.md). Mandatory assessment criteria and product requirements: [Qanat_requirements.txt](Qanat_requirements.txt).

## Run

```powershell
.\tools\flutter\bin\flutter.bat pub get
.\tools\flutter\bin\flutter.bat run
```

To verify:

```powershell
.\tools\flutter\bin\flutter.bat analyze
.\tools\flutter\bin\flutter.bat test
.\tools\flutter\bin\flutter.bat build apk --debug
```

The Android toolchain is installed locally in `tools/` and the Android SDK is in the standard user SDK directory. The debug APK is produced at `build/app/outputs/flutter-apk/app-debug.apk`.

Emulator QA screenshots: [Home](docs/screenshots/home.png), [search results](docs/screenshots/results.png), [flight details](docs/screenshots/flight_details.png), and [guest booking gate](docs/screenshots/auth_gate.png).

## Supabase + FastAPI mode

The app has two modes. Without configuration it runs the existing local/mock demo. With configuration, Supabase Auth manages accounts and sessions; Flutter calls FastAPI for airport, flight, seat, and booking data; FastAPI uses one Supabase PostgreSQL database. There is no second database. Checkout, airline inventory, and ticket issuance remain mock; no money or bank card data is collected. Passenger documents remain in the in-memory checkout draft and are never sent to the API.

1. Create a Supabase project. In its SQL Editor, run [the migration](supabase/migrations/20261012_initial.sql), then [the demo seed](supabase/seed.sql). The seed provides flights for the next 30 days and can be rerun later.
2. Copy `backend/.env.example` to `backend/.env` and fill in the project URL and **publishable** key. Never use a secret/service-role key in Flutter or commit secrets. See [backend instructions](backend/README.md).
3. Copy `config/example.json` to `config/local.json`. Use the same URL and publishable key, plus the FastAPI address reachable by the device.
4. Start FastAPI and run Flutter with:

```powershell
.\tools\flutter\bin\flutter.bat run -d R5CY52FCEWR --dart-define-from-file=config/local.json
```

For an Android phone connected by USB, use your laptop's LAN IPv4 address in `API_BASE_URL` (for example `http://192.168.1.20:8000`), put phone and laptop on the same Wi-Fi, and allow Python/port 8000 through Windows Firewall if prompted. The API is hosted on the laptop for development; the phone needs that laptop running. The Android debug manifest permits local HTTP. For a standalone release APK, deploy FastAPI behind HTTPS and set `API_BASE_URL` to that public URL; cleartext HTTP is not enabled in release.

For the Android emulator, use `config/emulator.json` instead; its `API_BASE_URL` should be `http://10.0.2.2:8000`, the emulator's route to the laptop's localhost. Keep the FastAPI process running while using either device.

Supabase email confirmation may be enabled. In that case registration asks the user to confirm the email and then sign in; for a quick coursework demo, configure that setting consciously in the Supabase Auth dashboard. Existing local/mock accounts are not migrated automatically to Supabase Auth.
