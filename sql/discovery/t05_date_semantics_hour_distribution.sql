/* ============================================================================
   T5 | P2 / S4 | Date semantics, edit history, hour distribution
   Goal    : decide which date column is the business date and what HistoryFactors represents.
   Outcome : t_date and SaveDate fall on the same day in all 17,654 rows (t_date = business date);
             1,778 updated orders = exactly the orders present in HistoryFactors (edit history,
             up to 5 versions per order), so History is not additional sales;
             about 88% of orders are placed between 18:00 and 23:59, peak around 21:00.
   ============================================================================ */

USE [BaranDb];

-- T5.1 t_date vs SaveDate consistency
SELECT COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN CAST(SaveDate AS date) = CAST(t_date AS date) THEN 1 ELSE 0 END) AS same_day,
       SUM(CASE WHEN t_date = SaveDate THEN 1 ELSE 0 END) AS same_datetime,
       MAX(ABS(DATEDIFF(minute, t_date, SaveDate))) AS max_diff_minutes
FROM dbo.orders;

-- T5.2 Edit history: are updated orders exactly the ones in HistoryFactors?
SELECT (SELECT COUNT_BIG(*)
        FROM   dbo.orders
        WHERE  LastUpdateDate IS NOT NULL) AS orders_with_update,
       (SELECT COUNT_BIG(*)
        FROM   dbo.orders AS o
        WHERE  o.LastUpdateDate IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   dbo.HistoryFactors AS h
                           WHERE  h.t_orderID = o.t_orderID)) AS updated_with_history,
       (SELECT COUNT_BIG(*)
        FROM   dbo.orders AS o
        WHERE  o.LastUpdateDate IS NULL
               AND EXISTS (SELECT 1
                           FROM   dbo.HistoryFactors AS h
                           WHERE  h.t_orderID = o.t_orderID)) AS not_updated_with_history;

-- T5.3 Versions per edited order
SELECT versions, COUNT_BIG(*) AS orders
FROM (SELECT t_orderID, COUNT_BIG(*) AS versions FROM dbo.HistoryFactors GROUP BY t_orderID) AS v
GROUP BY versions
ORDER BY versions;

-- T5.4 Date columns in candidate activity tables (metadata only; feeds T6)
SELECT t.name AS table_name, c.name AS column_name, TYPE_NAME(c.user_type_id) AS data_type
FROM sys.tables AS t
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE t.name IN (N'ReceivedDocuments', N'PaymentDocuments', N'PurchaseFactors',
                 N'UserLogs', N'FactorLogs', N'Product_Logs', N'CallerIdEvents', N'AllCalls', N'CallEvents')
  AND TYPE_NAME(c.user_type_id) IN (N'datetime', N'datetime2', N'smalldatetime', N'date')
ORDER BY t.name, c.column_id;

-- T5.5 Does t_date carry a time component? Hour distribution
SELECT DATEPART(hour, t_date) AS hr, COUNT_BIG(*) AS orders
FROM dbo.orders
GROUP BY DATEPART(hour, t_date)
ORDER BY hr;
