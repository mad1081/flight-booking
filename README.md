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

Flights, accounts, bookings, and checkout are local/mock implementations for coursework demonstration. No real airline inventory, ticket issuance, payment, or bank card collection is connected. Passenger document number remains only in the in-memory checkout draft and is not persisted.
