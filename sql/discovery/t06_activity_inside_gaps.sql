/* ============================================================================
   T6 | P2 / S4 (+ part of S7) | Activity of other tables inside the gaps
   ============================================================================ */

USE [BaranDb];

-- T6.1 Activity of other tables inside and around the gaps
-- Note: period_name values P0-P4 below are gap windows, not project phases.
WITH periods AS (
    SELECT * FROM (VALUES
        (N'P0 start-gap',  CAST('2024-10-20' AS date), CAST('2024-10-22' AS date)),
        (N'P1 pre-gap',    CAST('2024-10-19' AS date), CAST('2024-11-08' AS date)),
        (N'P2 gap-35d',    CAST('2024-11-09' AS date), CAST('2024-12-13' AS date)),
        (N'P3 post-gap',   CAST('2024-12-14' AS date), CAST('2025-01-17' AS date)),
        (N'P4 nowruz-gap', CAST('2025-03-21' AS date), CAST('2025-03-24' AS date))
    ) AS v(period_name, d_from, d_to)
),
activity AS (
    SELECT 'orders' AS source, CAST(t_date AS date) AS d FROM dbo.orders
    UNION ALL SELECT 'ReceivedDocuments', CAST([Date] AS date) FROM dbo.ReceivedDocuments
    UNION ALL SELECT 'PaymentDocuments',  CAST([Date] AS date) FROM dbo.PaymentDocuments
    UNION ALL SELECT 'PurchaseFactors',   CAST([Date] AS date) FROM dbo.PurchaseFactors
    UNION ALL SELECT 'UserLogs',          CAST([Date] AS date) FROM dbo.UserLogs
    UNION ALL SELECT 'FactorLogs',        CAST(LogDate AS date) FROM dbo.FactorLogs
    UNION ALL SELECT 'Product_Logs',      CAST([Date] AS date) FROM dbo.Product_Logs
    UNION ALL SELECT 'CallerIdEvents',    CAST(EventDate AS date) FROM dbo.CallerIdEvents
    UNION ALL SELECT 'CallEvents',        CAST(EventDate AS date) FROM dbo.CallEvents
    UNION ALL SELECT 'AllCalls',          CAST(CallDate AS date) FROM dbo.AllCalls
)
SELECT s.source, p.period_name,
       DATEDIFF(day, p.d_from, p.d_to) + 1 AS days_in_period,
       COUNT_BIG(a.d) AS rows_in_period,
       COUNT_BIG(DISTINCT a.d) AS active_days,
       CAST(COUNT_BIG(a.d) AS decimal(18,1)) / (DATEDIFF(day, p.d_from, p.d_to) + 1) AS rows_per_day
FROM periods AS p
CROSS JOIN (SELECT DISTINCT source FROM activity) AS s
LEFT JOIN activity AS a
       ON a.source = s.source AND a.d BETWEEN p.d_from AND p.d_to
GROUP BY s.source, p.period_name, p.d_from, p.d_to
ORDER BY s.source, p.d_from;

-- T6.2 Single-day gaps in orders (exactly one missing day between two active days)
WITH d AS (
    SELECT DISTINCT CAST(t_date AS date) AS d FROM dbo.orders WHERE t_date IS NOT NULL
), g AS (
    SELECT d, LAG(d) OVER (ORDER BY d) AS prev_d FROM d
)
SELECT prev_d, d AS next_active_day, DATEADD(day, 1, prev_d) AS missing_day
FROM g
WHERE DATEDIFF(day, prev_d, d) = 2;
