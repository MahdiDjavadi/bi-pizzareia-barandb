/* ============================================================================
   T4 | P2 / S4 | Date coverage, gaps, monthly volume
   Goal    : establish the real transaction period and find periods without activity.
   Outcome : orders.t_date spans 2024-10-19 to 2025-12-22 (387 active days); the last day is partial
             (backup taken at 18:07), so the analytical as-of date is 2025-12-21.
             Gaps: 3 days at the start, 35 days (2024-11-09 to 2024-12-13), 4 days (2025-03-21 to 03-24),
             plus one single day found in T6.
   ============================================================================ */

USE [BaranDb];

-- T4.1 Date column profile
SELECT 'orders.t_date' AS col, COUNT_BIG(*) AS total_rows, COUNT_BIG(t_date) AS non_null,
       MIN(t_date) AS min_dt, MAX(t_date) AS max_dt,
       COUNT_BIG(DISTINCT CAST(t_date AS date)) AS active_days
FROM dbo.orders
UNION ALL
SELECT 'orders.SaveDate', COUNT_BIG(*), COUNT_BIG(SaveDate), MIN(SaveDate), MAX(SaveDate),
       COUNT_BIG(DISTINCT CAST(SaveDate AS date))
FROM dbo.orders
UNION ALL
SELECT 'orders.LastUpdateDate', COUNT_BIG(*), COUNT_BIG(LastUpdateDate), MIN(LastUpdateDate), MAX(LastUpdateDate),
       COUNT_BIG(DISTINCT CAST(LastUpdateDate AS date))
FROM dbo.orders
UNION ALL
SELECT 'HistoryFactors.Date', COUNT_BIG(*), COUNT_BIG([Date]), MIN([Date]), MAX([Date]),
       COUNT_BIG(DISTINCT CAST([Date] AS date))
FROM dbo.HistoryFactors;

-- T4.2 Monthly volume of orders (t_show split for the 518 candidate returns)
SELECT DATEFROMPARTS(YEAR(t_date), MONTH(t_date), 1) AS month_start,
       COUNT_BIG(*) AS orders,
       SUM(CASE WHEN t_show = 0 THEN 1 ELSE 0 END) AS t_show_0
FROM dbo.orders
WHERE t_date IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(t_date), MONTH(t_date), 1)
ORDER BY month_start;

-- T4.3 Gaps of 1+ consecutive days without orders
WITH d AS (
    SELECT DISTINCT CAST(t_date AS date) AS d FROM dbo.orders WHERE t_date IS NOT NULL
), g AS (
    SELECT d, LAG(d) OVER (ORDER BY d) AS prev_d FROM d
)
SELECT prev_d, d AS next_active_day, DATEDIFF(day, prev_d, d) - 1 AS missing_days
FROM g
WHERE DATEDIFF(day, prev_d, d) > 1
ORDER BY prev_d;

-- T4.4 Last 14 days before the maximum date (completeness of the tail)
SELECT CAST(t_date AS date) AS day, COUNT_BIG(*) AS orders
FROM dbo.orders
WHERE t_date >= DATEADD(day, -14, (SELECT MAX(t_date) FROM dbo.orders))
GROUP BY CAST(t_date AS date)
ORDER BY day;
