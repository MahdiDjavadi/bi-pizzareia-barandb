/* ============================================================================
   T8 | P2 / S5 | Header/line reconciliation, channel hints
   ============================================================================ */

USE [BaranDb];

-- T8.1 Direct equality tests for suspected duplicate/derived columns
SELECT COUNT_BIG(*) AS total_lines,
       SUM(CASE WHEN ABS(t_amta - OnePrice) <= 1 THEN 1 ELSE 0 END) AS amta_eq_oneprice,
       SUM(CASE WHEN t_qana = 1 THEN 1 ELSE 0 END) AS qty_eq_1,
       SUM(CASE WHEN t_qana <> FLOOR(t_qana) THEN 1 ELSE 0 END) AS fractional_qty
FROM dbo.orderItems;

SELECT COUNT_BIG(*) AS total_orders,
       SUM(CASE WHEN ABS(t_given - t_orderTotal) <= 1 THEN 1 ELSE 0 END) AS given_eq_total
FROM dbo.orders;

-- T8.2 Profile of the other header money columns (non-zero counts and range)
SELECT v.col, COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN v.val <> 0 THEN 1 ELSE 0 END) AS non_zero,
       SUM(CASE WHEN v.val < 0 THEN 1 ELSE 0 END) AS negatives,
       MIN(v.val) AS min_v, MAX(v.val) AS max_v
FROM dbo.orders AS o
CROSS APPLY (VALUES ('DriverAmount', CAST(o.DriverAmount AS float)),
                    ('t_discount', CAST(o.t_discount AS float)),
                    ('TaxAmount', CAST(o.TaxAmount AS float)),
                    ('Tax_Amount', CAST(o.Tax_Amount AS float)),
                    ('TotalServiceAmount', CAST(o.TotalServiceAmount AS float)),
                    ('RoundDiscountAmount', CAST(o.RoundDiscountAmount AS float)),
                    ('CustomerDiscountAmount', CAST(o.CustomerDiscountAmount AS float)),
                    ('SalesmanAmount', CAST(o.SalesmanAmount AS float)),
                    ('TotalSalesmanAmount', CAST(o.TotalSalesmanAmount AS float)),
                    ('OfferValue', CAST(o.OfferValue AS float))
            ) AS v(col, val)
GROUP BY v.col
ORDER BY v.col;

-- T8.3 What explains the difference between header total and sum(qty x price)?
-- Classes are evaluated in order: the first matching class wins (tolerance of 1 unit).
WITH l AS (
    SELECT t_orderID, SUM(t_qana * OnePrice) AS lines_qp
    FROM dbo.orderItems
    GROUP BY t_orderID
), x AS (
    SELECT o.t_orderID,
           o.t_orderTotal - l.lines_qp AS diff,
           CAST(o.DriverAmount AS float) AS driver,
           CAST(o.t_discount AS float)   AS disc,
           CAST(o.TaxAmount AS float)    AS tax
    FROM dbo.orders AS o
    JOIN l ON l.t_orderID = o.t_orderID
)
SELECT CASE
           WHEN ABS(diff) <= 1                          THEN '1 match'
           WHEN ABS(diff - driver) <= 1                 THEN '2 diff = +driver'
           WHEN ABS(diff + disc) <= 1                   THEN '3 diff = -discount'
           WHEN ABS(diff - driver + disc) <= 1          THEN '4 diff = +driver -discount'
           WHEN ABS(diff - tax) <= 1                    THEN '5 diff = +tax'
           WHEN ABS(diff - driver - tax + disc) <= 1    THEN '6 diff = +driver +tax -discount'
           WHEN diff > 0                                THEN '9a unexplained, header higher'
           ELSE                                              '9b unexplained, header lower'
       END AS reconciliation_class,
       COUNT_BIG(*) AS orders,
       MIN(diff) AS min_diff, MAX(diff) AS max_diff, AVG(diff) AS avg_diff
FROM x
GROUP BY CASE
           WHEN ABS(diff) <= 1                          THEN '1 match'
           WHEN ABS(diff - driver) <= 1                 THEN '2 diff = +driver'
           WHEN ABS(diff + disc) <= 1                   THEN '3 diff = -discount'
           WHEN ABS(diff - driver + disc) <= 1          THEN '4 diff = +driver -discount'
           WHEN ABS(diff - tax) <= 1                    THEN '5 diff = +tax'
           WHEN ABS(diff - driver - tax + disc) <= 1    THEN '6 diff = +driver +tax -discount'
           WHEN diff > 0                                THEN '9a unexplained, header higher'
           ELSE                                              '9b unexplained, header lower'
       END
ORDER BY reconciliation_class;

-- T8.4 Channel hypothesis: do FactorType, driver fee, driver id and people count line up?
SELECT FactorType,
       CASE WHEN DriverAmount > 0 THEN 1 ELSE 0 END AS has_driver_fee,
       CASE WHEN t_driver <> 0 THEN 1 ELSE 0 END    AS has_driver_id,
       CASE WHEN numberOfPeople > 0 THEN 1 ELSE 0 END AS has_people,
       COUNT_BIG(*) AS orders
FROM dbo.orders
GROUP BY FactorType,
         CASE WHEN DriverAmount > 0 THEN 1 ELSE 0 END,
         CASE WHEN t_driver <> 0 THEN 1 ELSE 0 END,
         CASE WHEN numberOfPeople > 0 THEN 1 ELSE 0 END
ORDER BY FactorType, has_driver_fee DESC, has_driver_id DESC, has_people DESC;

-- T8.5 Columns of the product-table candidates (metadata only)
SELECT t.name AS table_name, c.column_id, c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type, c.is_identity
FROM sys.tables AS t
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE t.name IN (N'products', N'ProductGroups', N'MenuGroupItems', N'MenuGroups', N'ProductUnits')
ORDER BY t.name, c.column_id;
