import json

from fastapi.testclient import TestClient
import httpx

from app.config import Settings
from app.main import create_app


OFFER = {
    "offer_id": "20261013-NQZ-ALA-0-basic",
    "flight_id": "20261013-NQZ-ALA-0",
    "price_kzt": 31990,
    "fare_name": "Basic",
    "cabin_baggage_kg": 7,
    "checked_baggage_kg": 0,
    "remaining_seats": 36,
    "is_refundable": False,
    "price_assessment": "good",
    "flight_number": "FS 7152",
    "departure_at": "2026-10-13T01:40:00+00:00",
    "arrival_at": "2026-10-13T03:25:00+00:00",
    "stop_airport_codes": [],
    "duration_minutes": 105,
    "origin_code": "NQZ",
    "origin_city": "Astana",
    "origin_name": "Astana Airport",
    "destination_code": "ALA",
    "destination_city": "Almaty",
    "destination_name": "Almaty Airport",
    "airline_code": "FS",
    "airline_name": "FlyArystan",
    "airline_brand_color": 14883127,
}
BOOKING_ID = "b7042db0-f341-48f2-955d-6df77918845e"
USER_ID = "4032da40-2ed6-4107-9b45-6101d52b5639"
BOOKING = {
    "id": BOOKING_ID,
    "user_id": USER_ID,
    "offer_id": OFFER["offer_id"],
    "seat_code": "3A",
    "passenger_name": "Ayan Tester",
    "total_kzt": 31990,
    "status": "confirmed",
    "created_at": "2026-10-12T12:00:00+00:00",
    "origin_code": "NQZ",
    "origin_city": "Astana",
    "destination_code": "ALA",
    "destination_city": "Almaty",
    "airline_name": "FlyArystan",
    "flight_number": "FS 7152",
    "departure_at": OFFER["departure_at"],
    "arrival_at": OFFER["arrival_at"],
    "fare_name": "Basic",
    "checked_baggage_kg": 0,
}


def app_client(requests: list[httpx.Request]):
    def handler(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        path = request.url.path
        if path == "/auth/v1/user":
            if request.headers.get("authorization") == "Bearer valid-token":
                return httpx.Response(200, json={"id": USER_ID})
            return httpx.Response(401, json={"message": "invalid"})
        if path == "/rest/v1/airports":
            return httpx.Response(200, json=[{"code": "NQZ", "city": "Astana", "name": "Astana Airport", "country": "Kazakhstan"}])
        if path == "/rest/v1/flight_catalog":
            return httpx.Response(200, json=[OFFER])
        if path == "/rest/v1/price_history":
            return httpx.Response(200, json=[{"recorded_at": "2026-10-12T00:00:00+00:00", "price_kzt": 34000}])
        if path == "/rest/v1/rpc/occupied_seats":
            return httpx.Response(200, json=[{"seat_code": "1A"}])
        if path == "/rest/v1/rpc/confirm_mock_booking":
            return httpx.Response(200, json=BOOKING_ID)
        if path == "/rest/v1/booking_tickets":
            if request.headers.get("authorization") != "Bearer valid-token":
                return httpx.Response(401, json={"message": "invalid"})
            return httpx.Response(200, json=[BOOKING])
        return httpx.Response(404, json={"message": "not found"})

    app = create_app(
        Settings("https://example.supabase.co", "sb_publishable_test"),
        transport=httpx.MockTransport(handler),
    )
    return TestClient(app)


def test_guest_catalog_and_offer_details():
    requests = []
    with app_client(requests) as client:
        assert client.get("/api/v1/health").json()["supabase_configured"] is True
        assert client.get("/api/v1/airports").json()[0]["code"] == "NQZ"
        response = client.get("/api/v1/flights", params={
            "origin": "NQZ", "destination": "ALA", "departure_date": "2026-10-13",
            "checked_baggage_only": "true",
        })
        assert response.status_code == 200
        assert response.json() == []
        response = client.get("/api/v1/flights", params={
            "origin": "NQZ", "destination": "ALA", "departure_date": "2026-10-13",
        })
        assert response.json()[0]["offer_id"] == OFFER["offer_id"]
        assert client.get(f"/api/v1/offers/{OFFER['offer_id']}").json()["price_history"][0]["price_kzt"] == 34000
        assert client.get(f"/api/v1/flights/{OFFER['flight_id']}/occupied-seats").json()["occupied"] == ["1A"]
    assert all(request.headers.get("apikey") == "sb_publishable_test" for request in requests)
    search = next(request for request in requests if request.url.path == "/rest/v1/flight_catalog" and "departure_at" in request.url.params)
    assert search.url.params.get_list("departure_at") == ["gte.2026-10-12T19:00:00+00:00", "lt.2026-10-13T19:00:00+00:00"]


def test_booking_requires_auth_and_forwards_the_user_token():
    requests = []
    with app_client(requests) as client:
        assert client.get("/api/v1/bookings").status_code == 401
        assert client.get("/api/v1/bookings", headers={"Authorization": "Bearer bad"}).status_code == 401
        headers = {"Authorization": "Bearer valid-token"}
        response = client.post("/api/v1/bookings", headers=headers, json={
            "offer_id": OFFER["offer_id"], "seat_code": "3A", "passenger_name": "Ayan Tester",
        })
        assert response.status_code == 201
        assert response.json()["id"] == BOOKING_ID
        assert client.get("/api/v1/bookings", headers=headers).json()[0]["user_id"] == USER_ID
    rpc = next(request for request in requests if request.url.path.endswith("confirm_mock_booking"))
    assert rpc.headers["authorization"] == "Bearer valid-token"
    assert json.loads(rpc.content)["p_seat_code"] == "3A"


def test_unconfigured_api_is_explicit():
    app = create_app(Settings("", ""))
    with TestClient(app) as client:
        assert client.get("/api/v1/health").json()["supabase_configured"] is False
        assert client.get("/api/v1/airports").status_code == 503
