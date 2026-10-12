"""Small PostgREST adapter. All data lives in the same Supabase project."""

from uuid import UUID

from fastapi import HTTPException
import httpx

from .config import Settings


class SupabaseGateway:
    def __init__(self, client: httpx.AsyncClient, settings: Settings):
        self.client = client
        self.settings = settings

    async def _request(
        self,
        method: str,
        path: str,
        *,
        params: list[tuple[str, str]] | None = None,
        payload: dict[str, str] | None = None,
        token: str | None = None,
    ):
        headers = {"apikey": self.settings.publishable_key}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        try:
            response = await self.client.request(
                method, path, headers=headers, params=params, json=payload
            )
        except httpx.RequestError as exc:
            raise HTTPException(status_code=502, detail="Supabase is unavailable") from exc
        if response.status_code >= 400:
            try:
                code = response.json().get("code")
            except (ValueError, AttributeError):
                code = None
            if response.status_code in (401, 403):
                raise HTTPException(status_code=401, detail="Invalid or expired session")
            if code == "23505":
                raise HTTPException(status_code=409, detail="Seat already booked")
            if code == "22023":
                raise HTTPException(status_code=422, detail="Flight or seat unavailable")
            raise HTTPException(status_code=502, detail="Supabase request failed")
        return response.json()

    async def verify_user(self, token: str) -> UUID:
        payload = await self._request("GET", "/auth/v1/user", token=token)
        try:
            return UUID(payload["id"])
        except (KeyError, TypeError, ValueError) as exc:
            raise HTTPException(status_code=401, detail="Invalid user claims") from exc

    async def airports(self) -> list[dict]:
        return await self._request(
            "GET", "/rest/v1/airports", params=[("select", "code,city,name,country"), ("order", "city.asc")]
        )

    async def flight_catalog(self, origin: str, destination: str, start: str, end: str) -> list[dict]:
        return await self._request(
            "GET",
            "/rest/v1/flight_catalog",
            params=[
                ("select", "*"),
                ("origin_code", f"eq.{origin}"),
                ("destination_code", f"eq.{destination}"),
                ("departure_at", f"gte.{start}"),
                ("departure_at", f"lt.{end}"),
                ("limit", "100"),
            ],
        )

    async def offer(self, offer_id: str) -> dict | None:
        rows = await self._request(
            "GET", "/rest/v1/flight_catalog",
            params=[("select", "*"), ("offer_id", f"eq.{offer_id}"), ("limit", "1")],
        )
        return rows[0] if rows else None

    async def price_history(self, offer_id: str) -> list[dict]:
        return await self._request(
            "GET", "/rest/v1/price_history",
            params=[
                ("select", "recorded_at,price_kzt"),
                ("offer_id", f"eq.{offer_id}"),
                ("order", "recorded_at.asc"),
            ],
        )

    async def occupied_seats(self, flight_id: str) -> list[str]:
        rows = await self._request(
            "POST", "/rest/v1/rpc/occupied_seats", payload={"p_flight_id": flight_id}
        )
        return [row["seat_code"] for row in rows]

    async def bookings(self, token: str, booking_id: UUID | None = None) -> list[dict]:
        params = [("select", "*"), ("order", "created_at.desc")]
        if booking_id is not None:
            params.append(("id", f"eq.{booking_id}"))
        return await self._request("GET", "/rest/v1/booking_tickets", params=params, token=token)

    async def confirm_booking(self, token: str, offer_id: str, seat_code: str, passenger_name: str) -> UUID:
        result = await self._request(
            "POST",
            "/rest/v1/rpc/confirm_mock_booking",
            payload={
                "p_offer_id": offer_id,
                "p_seat_code": seat_code,
                "p_passenger_name": passenger_name.strip(),
            },
            token=token,
        )
        try:
            return UUID(result)
        except (TypeError, ValueError) as exc:
            raise HTTPException(status_code=502, detail="Invalid booking response") from exc
