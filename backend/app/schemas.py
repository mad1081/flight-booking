from datetime import date, datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class Airport(BaseModel):
    code: str
    city: str
    name: str
    country: str


class FlightOffer(BaseModel):
    offer_id: str
    flight_id: str
    price_kzt: int
    fare_name: str
    cabin_baggage_kg: int
    checked_baggage_kg: int
    remaining_seats: int
    is_refundable: bool
    price_assessment: Literal["good", "average", "high"]
    flight_number: str
    departure_at: datetime
    arrival_at: datetime
    stop_airport_codes: list[str]
    duration_minutes: int
    origin_code: str
    origin_city: str
    origin_name: str
    destination_code: str
    destination_city: str
    destination_name: str
    airline_code: str
    airline_name: str
    airline_brand_color: int


class PricePoint(BaseModel):
    recorded_at: datetime
    price_kzt: int


class FlightDetails(BaseModel):
    offer: FlightOffer
    price_history: list[PricePoint]


class SeatMap(BaseModel):
    flight_id: str
    occupied: list[str]


class BookingCreate(BaseModel):
    offer_id: str = Field(min_length=1, max_length=100)
    seat_code: str = Field(pattern=r"^[1-8][A-F]$")
    passenger_name: str = Field(min_length=2, max_length=160)


class Booking(BaseModel):
    id: UUID
    user_id: UUID
    offer_id: str
    seat_code: str
    passenger_name: str
    total_kzt: int
    status: Literal["confirmed"]
    created_at: datetime
    origin_code: str
    origin_city: str
    destination_code: str
    destination_city: str
    airline_name: str
    flight_number: str
    departure_at: datetime
    arrival_at: datetime
    fare_name: str
    checked_baggage_kg: int


class Health(BaseModel):
    status: Literal["ok"] = "ok"
    supabase_configured: bool


Sort = Literal["recommended", "cheapest", "fastest", "departure_time"]


def departure_window(day: date) -> tuple[datetime, datetime]:
    from datetime import timedelta, timezone
    from zoneinfo import ZoneInfo

    local_start = datetime(day.year, day.month, day.day, tzinfo=ZoneInfo('Asia/Almaty'))
    return local_start.astimezone(timezone.utc), (local_start + timedelta(days=1)).astimezone(timezone.utc)
