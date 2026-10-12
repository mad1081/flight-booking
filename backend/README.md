# Qanat FastAPI

FastAPI is the flight and booking HTTP layer. It uses the project's publishable key for public catalog reads and forwards the signed-in user's Supabase access token for protected booking reads and the booking RPC. Supabase PostgreSQL is the only database. FastAPI stores no local user database and no bank/passport data.

From `backend/` in PowerShell:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
# Edit .env with your Supabase project URL and publishable key.
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Verify on the laptop: `http://127.0.0.1:8000/api/v1/health` and `http://127.0.0.1:8000/docs`. The health response says whether Supabase credentials are present; it does not prove the migration or live connectivity. Run tests from this directory with `.\.venv\Scripts\python.exe -m pytest -q`. To check the configured live catalog through FastAPI, run `.\.venv\Scripts\python.exe smoke_live.py`.

The Android phone must reach port 8000 on your laptop's LAN address. Use HTTPS and a hosted API for a release build, not the laptop's temporary development address. The publishable key is not a secret; the user's JWT is required to read or create that user's bookings. RLS and the database RPC enforce ownership, seat availability, and server-calculated prices.
