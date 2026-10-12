-- Qanat coursework schema. Apply to one Supabase PostgreSQL project.
-- Catalog is readable by guests; personal data is protected by RLS.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 120),
  created_at timestamptz not null default now()
);

create table if not exists public.airports (
  code text primary key check (code ~ '^[A-Z]{3}$'),
  city text not null,
  name text not null,
  country text not null default 'Kazakhstan'
);

create table if not exists public.airlines (
  code text primary key,
  name text not null,
  brand_color integer not null
);

create table if not exists public.flights (
  id text primary key,
  airline_code text not null references public.airlines(code),
  flight_number text not null,
  origin_code text not null references public.airports(code),
  destination_code text not null references public.airports(code),
  departure_at timestamptz not null,
  arrival_at timestamptz not null,
  stop_airport_codes text[] not null default '{}',
  check (origin_code <> destination_code),
  check (arrival_at > departure_at)
);
create index if not exists flights_route_date_idx
  on public.flights (origin_code, destination_code, departure_at);

create table if not exists public.flight_offers (
  id text primary key,
  flight_id text not null references public.flights(id) on delete cascade,
  price_kzt integer not null check (price_kzt > 0),
  fare_name text not null,
  cabin_baggage_kg integer not null check (cabin_baggage_kg >= 0),
  checked_baggage_kg integer not null check (checked_baggage_kg >= 0),
  remaining_seats integer not null check (remaining_seats >= 0),
  is_refundable boolean not null default false,
  price_assessment text not null check (price_assessment in ('good', 'average', 'high'))
);
create index if not exists flight_offers_flight_idx on public.flight_offers (flight_id);

create table if not exists public.price_history (
  id bigint generated always as identity primary key,
  offer_id text not null references public.flight_offers(id) on delete cascade,
  recorded_at timestamptz not null,
  price_kzt integer not null check (price_kzt > 0),
  unique (offer_id, recorded_at)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  offer_id text not null references public.flight_offers(id),
  flight_id text not null references public.flights(id),
  seat_code text not null check (seat_code ~ '^[1-8][A-F]$'),
  passenger_name text not null check (char_length(passenger_name) between 2 and 160),
  total_kzt integer not null check (total_kzt > 0),
  status text not null default 'confirmed' check (status = 'confirmed'),
  created_at timestamptz not null default now(),
  unique (flight_id, seat_code)
);
create index if not exists bookings_user_date_idx on public.bookings (user_id, created_at desc);

-- Security-invoker views preserve the RLS of underlying tables.
create or replace view public.flight_catalog with (security_invoker = true) as
select
  o.id as offer_id, o.flight_id, o.price_kzt, o.fare_name,
  o.cabin_baggage_kg, o.checked_baggage_kg, o.remaining_seats,
  o.is_refundable, o.price_assessment,
  f.flight_number, f.departure_at, f.arrival_at, f.stop_airport_codes,
  extract(epoch from (f.arrival_at - f.departure_at))::integer / 60 as duration_minutes,
  f.origin_code, origin.city as origin_city, origin.name as origin_name,
  f.destination_code, destination.city as destination_city,
  destination.name as destination_name,
  airline.code as airline_code, airline.name as airline_name,
  airline.brand_color as airline_brand_color
from public.flight_offers o
join public.flights f on f.id = o.flight_id
join public.airports origin on origin.code = f.origin_code
join public.airports destination on destination.code = f.destination_code
join public.airlines airline on airline.code = f.airline_code;

create or replace view public.booking_tickets with (security_invoker = true) as
select
  b.id, b.user_id, b.offer_id, b.seat_code, b.passenger_name,
  b.total_kzt, b.status, b.created_at,
  c.origin_code, c.origin_city, c.destination_code, c.destination_city,
  c.airline_name, c.flight_number, c.departure_at, c.arrival_at,
  c.fare_name, c.checked_baggage_kg
from public.bookings b
join public.flight_catalog c on c.offer_id = b.offer_id;

alter table public.profiles enable row level security;
alter table public.airports enable row level security;
alter table public.airlines enable row level security;
alter table public.flights enable row level security;
alter table public.flight_offers enable row level security;
alter table public.price_history enable row level security;
alter table public.bookings enable row level security;

create policy "profiles read own" on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
create policy "profiles update own" on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "airports public read" on public.airports for select to anon, authenticated using (true);
create policy "airlines public read" on public.airlines for select to anon, authenticated using (true);
create policy "flights public read" on public.flights for select to anon, authenticated using (true);
create policy "offers public read" on public.flight_offers for select to anon, authenticated using (true);
create policy "price history public read" on public.price_history for select to anon, authenticated using (true);
create policy "bookings read own" on public.bookings for select to authenticated
  using ((select auth.uid()) = user_id);

grant select on public.airports, public.airlines, public.flights,
  public.flight_offers, public.price_history, public.flight_catalog to anon, authenticated;
grant select on public.profiles, public.bookings, public.booking_tickets to authenticated;
grant update (display_name) on public.profiles to authenticated;
revoke all on public.bookings from anon;

create or replace function public.create_profile_for_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    case
      when char_length(trim(coalesce(new.raw_user_meta_data ->> 'name', ''))) >= 2
        then left(trim(new.raw_user_meta_data ->> 'name'), 120)
      else left('User ' || new.id::text, 120)
    end
  );
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_qanat on auth.users;
create trigger on_auth_user_created_qanat after insert on auth.users
  for each row execute function public.create_profile_for_user();
revoke execute on function public.create_profile_for_user() from public, anon, authenticated;

-- The app cannot insert bookings directly or forge a price. This RPC computes
-- the total and atomically reserves a seat. No passport data is stored.
create or replace function public.confirm_mock_booking(
  p_offer_id text, p_seat_code text, p_passenger_name text
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_user_id uuid := (select auth.uid());
  v_offer record;
  v_booking_id uuid;
  v_total integer;
begin
  if v_user_id is null then
    raise exception 'Login required' using errcode = '28000';
  end if;
  if p_seat_code !~ '^[1-8][A-F]$' or
     p_seat_code = any(array['1A','1F','2C','3B','4D','5A','5E','6C','7F']) then
    raise exception 'Seat unavailable' using errcode = '22023';
  end if;
  if char_length(trim(p_passenger_name)) not between 2 and 160 then
    raise exception 'Invalid passenger name' using errcode = '22023';
  end if;

  select o.flight_id, o.price_kzt, o.remaining_seats, f.departure_at
    into v_offer
    from public.flight_offers o
    join public.flights f on f.id = o.flight_id
    where o.id = p_offer_id
    for update of o;
  if not found or v_offer.departure_at <= now() then
    raise exception 'Flight unavailable' using errcode = '22023';
  end if;
  if v_offer.remaining_seats <= 0 then
    raise exception 'Sold out' using errcode = '22023';
  end if;

  v_total := v_offer.price_kzt + case when left(p_seat_code, 1)::integer <= 2 then 9000 else 0 end;
  insert into public.bookings
    (user_id, offer_id, flight_id, seat_code, passenger_name, total_kzt)
  values
    (v_user_id, p_offer_id, v_offer.flight_id, p_seat_code, trim(p_passenger_name), v_total)
  returning id into v_booking_id;
  update public.flight_offers set remaining_seats = remaining_seats - 1 where id = p_offer_id;
  return v_booking_id;
end;
$$;
revoke all on function public.confirm_mock_booking(text, text, text) from public, anon;
grant execute on function public.confirm_mock_booking(text, text, text) to authenticated;

-- A public seat map may reveal seat codes, never other passengers' data.
create or replace function public.occupied_seats(p_flight_id text)
returns table (seat_code text) language sql stable security definer set search_path = '' as $$
  select b.seat_code from public.bookings b where b.flight_id = p_flight_id
  union
  select fixed.seat_code from unnest(array['1A','1F','2C','3B','4D','5A','5E','6C','7F']) as fixed(seat_code);
$$;
revoke all on function public.occupied_seats(text) from public;
grant execute on function public.occupied_seats(text) to anon, authenticated;
