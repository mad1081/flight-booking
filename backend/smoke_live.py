"""Read-only check of the configured live Supabase catalog through FastAPI."""

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from fastapi.testclient import TestClient

from app.main import app


def main() -> None:
    tomorrow = (datetime.now(ZoneInfo("Asia/Almaty")) + timedelta(days=1)).date()
    with TestClient(app) as client:
        health = client.get("/api/v1/health")
        health.raise_for_status()
        assert health.json()["supabase_configured"]

        airports = client.get("/api/v1/airports")
        airports.raise_for_status()
        assert len(airports.json()) >= 2

        flights = client.get(
            "/api/v1/flights",
            params={
                "origin": "NQZ",
                "destination": "ALA",
                "departure_date": tomorrow.isoformat(),
            },
        )
        flights.raise_for_status()
        assert flights.json()
        offer_id = flights.json()[0]["offer_id"]
        details = client.get(f"/api/v1/offers/{offer_id}")
        details.raise_for_status()
        assert details.json()["price_history"]

        assert client.get("/api/v1/bookings").status_code == 401
        print(f"Live API OK: {len(airports.json())} airports, {len(flights.json())} offers for {tomorrow}")


if __name__ == "__main__":
    main()
