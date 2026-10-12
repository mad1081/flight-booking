from contextlib import asynccontextmanager
from datetime import date
from typing import Literal
from uuid import UUID
from zoneinfo import ZoneInfo

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request
import httpx

from .config import Settings
from .gateway import SupabaseGateway
from .schemas import (
    Airport, Booking, BookingCreate, FlightDetails, FlightOffer, Health,
    PricePoint, SeatMap, Sort, departure_window,
)


def create_app(
    settings: Settings | None = None,
    *,
    transport: httpx.AsyncBaseTransport | None = None,
) -> FastAPI:
    settings = settings or Settings.from_env()

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        async with httpx.AsyncClient(
            base_url=settings.supabase_url or "https://not-configured.invalid",
            transport=transport,
            timeout=10,
        ) as client:
            app.state.gateway = SupabaseGateway(client, settings)
            yield

    app = FastAPI(title="Qanat API", version="0.1.0", lifespan=lifespan)

    def gateway(request: Request) -> SupabaseGateway:
        if not settings.configured:
            raise HTTPException(status_code=503, detail="Supabase is not configured")
        return request.app.state.gateway

    def bearer_token(authorization: str | None = Header(default=None)) -> str:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Bearer token required")
        token = authorization.removeprefix("Bearer ").strip()
        if not token:
            raise HTTPException(status_code=401, detail="Bearer token required")
        return token

    @app.get("/api/v1/health", response_model=Health)
    def health() -> Health:
        return Health(supabase_configured=settings.configured)

    @app.get("/api/v1/airports", response_model=list[Airport])
    async def airports(db: SupabaseGateway = Depends(gateway)):
        return await db.airports()

    @app.get("/api/v1/flights", response_model=list[FlightOffer])
    async def flights(
        origin: str = Query(pattern=r"^[A-Z]{3}$"),
        destination: str = Query(pattern=r"^[A-Z]{3}$"),
        departure_date: date = Query(),
        sort: Sort = "recommended",
        passengers: int = Query(default=1, ge=1, le=9),
        max_price_kzt: int | None = Query(default=None, ge=0),
        airline_code: str | None = Query(default=None, pattern=r"^[A-Z0-9]{2,4}$"),
        direct_only: bool = False,
        checked_baggage_only: bool = False,
        departure_hour_from: int | None = Query(default=None, ge=0, le=23),
        departure_hour_to: int | None = Query(default=None, ge=0, le=23),
        db: SupabaseGateway = Depends(gateway),
    ):
        if origin == destination:
            raise HTTPException(status_code=422, detail="Origin and destination must differ")
        start, end = departure_window(departure_date)
        rows = await db.flight_catalog(origin, destination, start.isoformat(), end.isoformat())
        offers = [FlightOffer.model_validate(row) for row in rows]
        local_zone = ZoneInfo("Asia/Almaty")
        offers = [
            offer for offer in offers
            if offer.remaining_seats >= passengers
            and (max_price_kzt is None or offer.price_kzt <= max_price_kzt)
            and (airline_code is None or offer.airline_code == airline_code)
            and (not direct_only or not offer.stop_airport_codes)
            and (not checked_baggage_only or offer.checked_baggage_kg > 0)
            and (
                departure_hour_from is None
                or offer.departure_at.astimezone(local_zone).hour >= departure_hour_from
            )
            and (
                departure_hour_to is None
                or offer.departure_at.astimezone(local_zone).hour <= departure_hour_to
            )
        ]
        if sort == "cheapest":
            offers.sort(key=lambda offer: (offer.price_kzt, offer.duration_minutes))
        elif sort == "fastest":
            offers.sort(key=lambda offer: (offer.duration_minutes, offer.price_kzt))
        elif sort == "departure_time":
            offers.sort(key=lambda offer: offer.departure_at)
        else:
            offers.sort(key=lambda offer: (
                offer.price_kzt * 0.45
                + offer.duration_minutes * 80
                + len(offer.stop_airport_codes) * 14000
                - min(offer.checked_baggage_kg, 23) * 250,
                offer.price_kzt,
            ))
        return offers

    @app.get("/api/v1/offers/{offer_id}", response_model=FlightDetails)
    async def offer_details(offer_id: str, db: SupabaseGateway = Depends(gateway)):
        offer = await db.offer(offer_id)
        if offer is None:
            raise HTTPException(status_code=404, detail="Offer not found")
        history = await db.price_history(offer_id)
        return FlightDetails(offer=FlightOffer.model_validate(offer), price_history=[PricePoint.model_validate(point) for point in history])

    @app.get("/api/v1/flights/{flight_id}/occupied-seats", response_model=SeatMap)
    async def occupied_seats(flight_id: str, db: SupabaseGateway = Depends(gateway)):
        return SeatMap(flight_id=flight_id, occupied=await db.occupied_seats(flight_id))

    @app.get("/api/v1/bookings", response_model=list[Booking])
    async def bookings(
        token: str = Depends(bearer_token), db: SupabaseGateway = Depends(gateway)
    ):
        await db.verify_user(token)
        return await db.bookings(token)

    @app.get("/api/v1/bookings/{booking_id}", response_model=Booking)
    async def booking_details(
        booking_id: UUID,
        token: str = Depends(bearer_token),
        db: SupabaseGateway = Depends(gateway),
    ):
        await db.verify_user(token)
        rows = await db.bookings(token, booking_id)
        if not rows:
            raise HTTPException(status_code=404, detail="Booking not found")
        return rows[0]

    @app.post("/api/v1/bookings", response_model=Booking, status_code=201)
    async def confirm_booking(
        request: BookingCreate,
        token: str = Depends(bearer_token),
        db: SupabaseGateway = Depends(gateway),
    ):
        await db.verify_user(token)
        booking_id = await db.confirm_booking(
            token, request.offer_id, request.seat_code, request.passenger_name
        )
        rows = await db.bookings(token, booking_id)
        if not rows:
            raise HTTPException(status_code=502, detail="Booking was saved but could not be loaded")
        return rows[0]

    return app


app = create_app()
