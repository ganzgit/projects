--Represent the "book_date" column in "yyyy-mmm-dd" format using Bookings table:

SELECT 
book_ref, 
TO_CHAR(book_date, 'YYYY-Mon-DD') AS book_date, 
total_amount
FROM bookings
ORDER BY book_ref;

--Find the seat number which is least allocated among all the seats:

WITH ranked_seats AS (
  SELECT 
    seat_no, 
    DENSE_RANK() OVER (ORDER BY COUNT(*) ASC) AS seat_rank
  FROM boarding_passes
  GROUP BY seat_no
)
SELECT seat_no
FROM ranked_seats
WHERE seat_rank = 1;

--Identify the month-wise highest paying passenger name and passenger id:

WITH month_wise_amount AS (
  SELECT
    TO_CHAR(b.book_date, 'Mon-YY') AS booking_month,
    t.passenger_id,
    t.passenger_name,
    b.total_amount
  FROM bookings AS b
  INNER JOIN tickets AS t
  ON t.book_ref = b.book_ref
),
rank_data AS (
  SELECT
    booking_month,
    passenger_id,
    passenger_name,
    total_amount,
    DENSE_RANK() OVER (PARTITION BY booking_month ORDER BY total_amount DESC) AS rank
  FROM month_wise_amount
)
SELECT
  booking_month,
  passenger_id,
  passenger_name,
  total_amount
FROM rank_data
WHERE rank = 1;

--Identify the travel details of non-stop journeys:


SELECT
  t.passenger_id,
  t.passenger_name,
  t.ticket_no AS ticket_number,
  COUNT(bp.flight_id) AS flight_count,
  CASE
    WHEN COUNT(bp.flight_id) > 1 THEN 'Non-Stop Journey'
    WHEN COUNT(bp.flight_id) = 1 THEN 'One-Stop Journey'
    ELSE 'Unknown'
  END AS journey_type
FROM tickets t
LEFT JOIN boarding_passes AS bp ON t.ticket_no = bp.ticket_no
GROUP BY t.passenger_id, t.passenger_name, t.ticket_no;

--Find how many tickets are there without boarding passes:

SELECT 
COUNT(t.ticket_no) AS tickets_without_boarding_passes
FROM tickets t
LEFT JOIN boarding_passes bp 
ON t.ticket_no = bp.ticket_no
WHERE bp.ticket_no IS NULL;

--Identify details of the longest flight using the flights table:


WITH duration_details AS (
  SELECT
    DISTINCT flight_no,
    departure_airport,
    arrival_airport,
    aircraft_code,
    (actual_arrival - actual_departure) AS duration
  FROM flights
),
longest_flight AS (
  SELECT
    *,
    RANK() OVER (ORDER BY duration DESC) AS flights_rank
  FROM duration_details
  WHERE duration IS NOT NULL
)
SELECT
  flight_no,
  departure_airport,
  arrival_airport,
  aircraft_code,
  duration
FROM longest_flight
WHERE flights_rank = 1;

--Identify details of all the morning flights (between 6 AM to 11 AM) using the flights table:


WITH flight_details AS (
  SELECT
    flight_id,
    flight_no,
    scheduled_departure,
    scheduled_arrival,
    TO_CHAR(scheduled_departure, 'HH24:MI:SS') AS timings
  FROM flights
)
SELECT *
FROM flight_details
WHERE timings BETWEEN '06:00:00' AND '11:00:00';

--Identify the earliest morning flight available from every airport:


WITH flight_details AS (
  SELECT
    flight_id,
    flight_no,
    scheduled_departure,
    scheduled_arrival,
    departure_airport,
    TO_CHAR(scheduled_departure, 'HH24:MI:SS') AS timings
  FROM flights
),
earliest_morning_flight AS (
  SELECT *
  FROM flight_details
  WHERE timings BETWEEN '06:00:00' AND '11:00:00'
),
every_airport AS (
  SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY departure_airport ORDER BY scheduled_departure) AS flight_rank
  FROM earliest_morning_flight
)
SELECT
  flight_id,
  flight_no,
  scheduled_departure,
  scheduled_arrival,
  departure_airport,
  timings
FROM every_airport
WHERE flight_rank = 1;

--Categorize the flights based on their timings:

SELECT
flight_id,
flight_no,
scheduled_departure,
scheduled_arrival,
CASE WHEN
scheduled_departure::time between '02:00:00' and '06:00:00' THEN 'Early morning flights'
WHEN
scheduled_departure::time between '06:00:00' and '11:00:00' THEN 'Morning flights'
WHEN
scheduled_departure::time between '11:00:00' and '16:00:00' THEN 'Noon flights'
WHEN 
scheduled_departure::time between '16:00:00' and '19:00:00' THEN 'Evening flights'
WHEN
scheduled_departure::time between '19:00:00' and '23:00:00' THEN 'Night flights'
ELSE 'late night flights'
END AS timings
FROM flights


-- Query to get the count of seats in various fare conditions for every aircraft code
SELECT
  a.aircraft_code,
  s.fare_conditions,
  COUNT(s.seat_no) AS seat_count
FROM
  aircrafts a
JOIN
  seats s ON a.aircraft_code = s.aircraft_code
GROUP BY
  a.aircraft_code,
  s.fare_conditions
ORDER BY
  a.aircraft_code;

-- How many aircraft codes have at least one Business class seat?
WITH counting AS (
  SELECT
    aircraft_code,
    fare_conditions,
    COUNT(seat_no) AS seat_count
  FROM
    seats
  WHERE
    fare_conditions = 'Business'
  GROUP BY
    aircraft_code,
    fare_conditions
)
SELECT
  COUNT(aircraft_code)
FROM
  counting;

-- Find out the name of the airport having the maximum number of departure flights
SELECT
  a.airport_name
FROM
  airports a
JOIN
  flights f ON a.airport_code = f.departure_airport
GROUP BY
  a.airport_name
ORDER BY
  COUNT(*) DESC
LIMIT 1;

-- How many flights from ‘DME’ airport don’t have actual departure?
SELECT
  COUNT(flight_id) AS Flight_Count
FROM
  flights
WHERE
  departure_airport = 'DME'
  AND
  actual_departure IS NULL;

-- Identify flight ids having a range between 3000 to 6000
SELECT
  DISTINCT flight_no,
  a.aircraft_code,
  range
FROM
  flights f
JOIN
  aircrafts a ON f.aircraft_code = a.aircraft_code
WHERE
  range BETWEEN 3000 AND 6000;

-- Write a query to get the count of flights flying between URS and KUF
SELECT
  COUNT(flight_id) AS Flight_count
FROM
  flights
WHERE
  (departure_airport = 'KUF' AND arrival_airport = 'URS')
  OR
  (departure_airport = 'URS' AND arrival_airport = 'KUF');

-- Query to get the count of flights flying from either NOZ or KRR
SELECT
  COUNT(flight_id) AS Flight_count
FROM
  flights
WHERE
  departure_airport = 'NOZ'
  OR
  departure_airport = 'KRR';

-- Write a query to get the count of flights flying from specific airports
SELECT
  departure_airport,
  COUNT(flight_id) AS Flights_count
FROM
  flights
WHERE
  departure_airport IN ('KZN', 'DME', 'NBC', 'NJC', 'GDX', 'SGC', 'VKO', 'ROV')
GROUP BY
  departure_airport;

-- Query to extract flight details having a range between 3000 and 6000 and flying from DME
SELECT
  DISTINCT f.flight_no,
  a.aircraft_code,
  a.range,
  f.departure_airport
FROM
  flights f
JOIN
  aircrafts a ON f.aircraft_code = a.aircraft_code
WHERE
  f.departure_airport = 'DME'
  AND
  a.range BETWEEN 3000 AND 6000;

-- Find the list of flight ids which are using aircrafts from “Airbus” company and got cancelled or delayed
SELECT
  DISTINCT f.flight_id,
  a.model AS aircraft_model
FROM
  flights f
JOIN
  aircrafts a ON f.aircraft_code = a.aircraft_code
WHERE
  a.model LIKE '%Airbus%'
  AND
  f.status IN ('Cancelled', 'Delayed');

-- Identify which airport(name) has the most cancelled flights (arriving)
WITH cancelled_flights AS (
  SELECT
    f.arrival_airport,
    a.airport_name,
    COUNT(flight_id) AS flights_count
  FROM
    flights f
  INNER JOIN
    airports a ON f.arrival_airport = a.airport_code
  WHERE
    status = 'Cancelled'
  GROUP BY
    f.arrival_airport,
    a.airport_name
)
SELECT
  airport_name
FROM
  cancelled_flights
WHERE
  flights_count > 1;

-- Identify date-wise the last flight id flying from every airport
WITH date_wise_last_flight AS (
  SELECT
    flight_id,
    flight_no,
    departure_airport,
    scheduled_departure,
    RANK() OVER (PARTITION BY departure_airport ORDER BY scheduled_departure DESC) AS rank
  FROM
    flights
)
SELECT
  flight_id,
  flight_no,
  scheduled_departure,
  departure_airport
FROM
  date_wise_last_flight
WHERE
  rank = 1;

-- Identify the list of customers who will get a refund due to the cancellation of the flights and how much amount they will get
SELECT
  t.passenger_name,
  b.total_amount AS total_refund
FROM
  bookings b
JOIN
  tickets t ON b.book_ref = t.book_ref
JOIN
  ticket_flights tf ON t.ticket_no = tf.ticket_no
JOIN
  flights f ON tf.flight_id = f.flight_id
WHERE
  f.status = 'Cancelled';

-- Identify date-wise the first cancelled flight id flying from every airport
WITH first_cancelled_flight AS (
  SELECT
    flight_id,
    flight_no,
    scheduled_departure,
    departure_airport,
    RANK() OVER (PARTITION BY departure_airport ORDER BY scheduled_departure ASC) AS rank
  FROM
    flights
  WHERE
    status = 'Cancelled'
)
SELECT
  flight_id,
  flight_no,
  scheduled_departure,
  departure_airport
FROM
  first_cancelled_flight
WHERE
  rank = 1;

-- Identify the list of flight ids having the highest range
WITH highest_range AS (
  SELECT
    f.flight_no,
    a.range,
    DENSE_RANK() OVER (ORDER BY a.range DESC) AS range_rank
  FROM
    flights f
  INNER JOIN
    aircrafts a ON f.aircraft_code = a.aircraft_code
  GROUP BY
    f.flight_no,
    a.range
)
SELECT
  flight_no,
  range
FROM
  highest_range
WHERE
  range_rank = 1;
