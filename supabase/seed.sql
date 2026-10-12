-- Re-runnable demonstration inventory for the next 30 days.
-- Run after migrations/20261012_initial.sql in the Supabase SQL Editor.
insert into public.airports (code, city, name, country) values
  ('NQZ', 'Astana', 'Nursultan Nazarbayev International Airport', 'Kazakhstan'),
  ('ALA', 'Almaty', 'Almaty International Airport', 'Kazakhstan'),
  ('CIT', 'Shymkent', 'Shymkent International Airport', 'Kazakhstan'),
  ('SCO', 'Aktau', 'Aktau International Airport', 'Kazakhstan'),
  ('GUW', 'Atyrau', 'Atyrau International Airport', 'Kazakhstan')
on conflict (code) do update set city = excluded.city, name = excluded.name;

insert into public.airlines (code, name, brand_color) values
  ('KC', 'Air Astana', 21147),
  ('FS', 'FlyArystan', 14883127),
  ('DV', 'SCAT Airlines', 23978)
on conflict (code) do update set name = excluded.name, brand_color = excluded.brand_color;

with routes(origin_code, destination_code) as (
  values ('NQZ','ALA'), ('ALA','NQZ'), ('NQZ','CIT'), ('NQZ','SCO')
), templates(idx, airline_code, flight_number, departure_time, duration_minutes) as (
  values
    (0, 'FS', 'FS 7152', time '06:40', 105),
    (1, 'KC', 'KC 622', time '08:15', 100),
    (2, 'DV', 'DV 704', time '17:10', 105)
), flights_to_seed as (
  select
    to_char(day::date, 'YYYYMMDD') || '-' || r.origin_code || '-' || r.destination_code || '-' || t.idx as id,
    t.airline_code, t.flight_number, r.origin_code, r.destination_code,
    (day::date + t.departure_time) at time zone 'Asia/Almaty' as departure_at,
    ((day::date + t.departure_time) at time zone 'Asia/Almaty') + make_interval(mins => t.duration_minutes) as arrival_at
  from generate_series(current_date + 1, current_date + 30, interval '1 day') day
  cross join routes r cross join templates t
)
insert into public.flights
  (id, airline_code, flight_number, origin_code, destination_code, departure_at, arrival_at)
select id, airline_code, flight_number, origin_code, destination_code, departure_at, arrival_at
from flights_to_seed on conflict (id) do nothing;

with templates(idx, fare_name, base_price, checked_kg, refundable, assessment) as (
  values
    ('0', 'Basic', 31990, 0, false, 'good'),
    ('1', 'Standard', 42500, 23, true, 'average'),
    ('2', 'Comfort', 36700, 20, false, 'average')
)
insert into public.flight_offers
  (id, flight_id, price_kzt, fare_name, cabin_baggage_kg,
   checked_baggage_kg, remaining_seats, is_refundable, price_assessment)
select
  f.id || '-' || lower(t.fare_name), f.id,
  t.base_price + ((f.departure_at::date - current_date) % 5) * 1200,
  t.fare_name, 7, t.checked_kg, 36, t.refundable, t.assessment
from public.flights f
join templates t on right(f.id, 1) = t.idx
where f.departure_at >= now() and f.departure_at < now() + interval '31 days'
on conflict (id) do nothing;

insert into public.price_history (offer_id, recorded_at, price_kzt)
select o.id,
       date_trunc('day', now()) - (4 - step.n) * interval '1 day',
       o.price_kzt + (array[5500,3000,6500,1200,0])[step.n + 1]
from public.flight_offers o
join public.flights f on f.id = o.flight_id
cross join generate_series(0, 4) as step(n)
where f.departure_at >= now() and f.departure_at < now() + interval '31 days'
on conflict (offer_id, recorded_at) do nothing;
