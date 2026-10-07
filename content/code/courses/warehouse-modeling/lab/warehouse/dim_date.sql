-- One row per calendar day of the period, and one for a date not reached yet.
CREATE TABLE dim_date AS
WITH days AS (
    SELECT CAST(d AS DATE) AS date
    FROM range(DATE '2024-01-01', DATE '2026-01-01', INTERVAL 1 DAY) AS t(d)
),
holidays (date, holiday) AS (VALUES
    (DATE '2024-01-01', 'New Year'),          (DATE '2024-03-29', 'Good Friday'),
    (DATE '2024-04-21', 'Tiradentes'),        (DATE '2024-05-01', 'Labour Day'),
    (DATE '2024-09-07', 'Independence Day'),  (DATE '2024-10-12', 'Our Lady of Aparecida'),
    (DATE '2024-11-02', 'All Souls'),         (DATE '2024-11-15', 'Republic Day'),
    (DATE '2024-11-20', 'Black Consciousness'), (DATE '2024-12-25', 'Christmas'),
    (DATE '2025-01-01', 'New Year'),          (DATE '2025-04-18', 'Good Friday'),
    (DATE '2025-04-21', 'Tiradentes'),        (DATE '2025-05-01', 'Labour Day'),
    (DATE '2025-09-07', 'Independence Day'),  (DATE '2025-10-12', 'Our Lady of Aparecida'),
    (DATE '2025-11-02', 'All Souls'),         (DATE '2025-11-15', 'Republic Day'),
    (DATE '2025-11-20', 'Black Consciousness'), (DATE '2025-12-25', 'Christmas')
)
SELECT CAST(strftime(date, '%Y%m%d') AS INTEGER) AS date_key,
       date,
       year(date)                  AS year,
       quarter(date)               AS quarter,
       month(date)                 AS month,
       monthname(date)             AS month_name,
       day(date)                   AS day_of_month,
       isodow(date)                AS day_of_week,
       dayname(date)               AS day_name,
       isodow(date) >= 6           AS is_weekend,
       holiday IS NOT NULL         AS is_holiday,
       coalesce(holiday, '')       AS holiday
FROM days LEFT JOIN holidays USING (date)
UNION ALL
SELECT 0, NULL, NULL, NULL, NULL, 'Not yet', NULL, NULL, 'Not yet', NULL, NULL, ''
ORDER BY date_key;
