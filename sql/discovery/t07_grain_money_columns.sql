/* ============================================================================
   T7 | P2 / S5 | Grain and money columns
   ============================================================================ */

USE [BaranDb];

-- T7.1 Line grain: repeated products inside one order
SELECT COUNT_BIG(*) AS order_product_groups,
       SUM(CASE WHEN c > 1 THEN 1 ELSE 0 END) AS groups_with_repeats,
       SUM(c) - COUNT_BIG(*) AS extra_rows,
       MAX(c) AS max_repeats
FROM (SELECT t_orderID, t_productID, COUNT_BIG(*) AS c
      FROM dbo.orderItems
      GROUP BY t_orderID, t_productID) AS g;

SELECT COUNT_BIG(*) AS identical_line_groups, SUM(c) AS rows_in_those_groups
FROM (SELECT COUNT_BIG(*) AS c
      FROM dbo.orderItems
      GROUP BY t_orderID, t_productID, t_qana, t_amta, OnePrice
      HAVING COUNT_BIG(*) > 1) AS d;

SELECT SUM(CASE WHEN t_productID IS NULL THEN 1 ELSE 0 END) AS null_product,
       COUNT_BIG(DISTINCT t_productID) AS distinct_products
FROM dbo.orderItems;

-- T7.2 Value profile of money columns (nulls, zeros, negatives, range)
SELECT 'orderItems' AS tbl, v.col, COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN v.val IS NULL THEN 1 ELSE 0 END) AS nulls,
       SUM(CASE WHEN v.val = 0 THEN 1 ELSE 0 END) AS zeros,
       SUM(CASE WHEN v.val < 0 THEN 1 ELSE 0 END) AS negatives,
       MIN(v.val) AS min_v, MAX(v.val) AS max_v, AVG(v.val) AS avg_v
FROM dbo.orderItems AS oi
CROSS APPLY (VALUES ('t_qana', CAST(oi.t_qana AS float)), ('t_amta', CAST(oi.t_amta AS float)),
                    ('t_copr', CAST(oi.t_copr AS float)), ('t_tax', CAST(oi.t_tax AS float)),
                    ('OnePrice', CAST(oi.OnePrice AS float)), ('DiscountPrecent', CAST(oi.DiscountPrecent AS float))
            ) AS v(col, val)
GROUP BY v.col
UNION ALL
SELECT 'orders', v.col, COUNT_BIG(*),
       SUM(CASE WHEN v.val IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN v.val = 0 THEN 1 ELSE 0 END),
       SUM(CASE WHEN v.val < 0 THEN 1 ELSE 0 END),
       MIN(v.val), MAX(v.val), AVG(v.val)
FROM dbo.orders AS o
CROSS APPLY (VALUES ('t_orderTotal', CAST(o.t_orderTotal AS float)), ('t_gst', CAST(o.t_gst AS float)),
                    ('t_discount', CAST(o.t_discount AS float)), ('t_given', CAST(o.t_given AS float)),
                    ('t_change', CAST(o.t_change AS float)), ('TaxAmount', CAST(o.TaxAmount AS float)),
                    ('DriverAmount', CAST(o.DriverAmount AS float)), ('DiscountAmount', CAST(o.DiscountAmount AS float)),
                    ('ServiceAmount', CAST(o.ServiceAmount AS float))
            ) AS v(col, val)
GROUP BY v.col
ORDER BY tbl, v.col;

-- T7.3 How are the line money columns related? (tolerance of 1 unit)
SELECT COUNT_BIG(*) AS total_lines,
       SUM(CASE WHEN ABS(t_amta - t_qana * OnePrice) <= 1 THEN 1 ELSE 0 END) AS amta_eq_qana_x_oneprice,
       SUM(CASE WHEN ABS(t_amta - t_qana * t_copr)   <= 1 THEN 1 ELSE 0 END) AS amta_eq_qana_x_copr,
       SUM(CASE WHEN ABS(t_copr - OnePrice)          <= 1 THEN 1 ELSE 0 END) AS copr_eq_oneprice,
       SUM(CASE WHEN t_amta IS NULL OR t_qana IS NULL OR OnePrice IS NULL OR t_copr IS NULL THEN 1 ELSE 0 END) AS has_null_input
FROM dbo.orderItems;

-- T7.4 Header total vs line totals (split by t_show)
WITH l AS (
    SELECT t_orderID, SUM(t_amta) AS lines_amta, SUM(t_qana * OnePrice) AS lines_qp
    FROM dbo.orderItems
    GROUP BY t_orderID
)
SELECT o.t_show, COUNT_BIG(*) AS orders,
       SUM(CASE WHEN ABS(o.t_orderTotal - l.lines_amta) <= 1 THEN 1 ELSE 0 END) AS total_eq_sum_amta,
       SUM(CASE WHEN ABS(o.t_orderTotal - l.lines_qp)   <= 1 THEN 1 ELSE 0 END) AS total_eq_sum_qana_x_price,
       SUM(CASE WHEN ABS(o.t_orderTotal - l.lines_amta) > 1
                 AND ABS(o.t_orderTotal - l.lines_qp)   > 1 THEN 1 ELSE 0 END) AS matches_neither
FROM dbo.orders AS o
JOIN l ON l.t_orderID = o.t_orderID
GROUP BY o.t_show
ORDER BY o.t_show;

-- T7.5 Which table does t_productID point to? (names only, plus sizes)
SELECT t.name AS table_name, SUM(ps.row_count) AS est_rows
FROM sys.tables AS t
JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = t.object_id AND ps.index_id IN (0, 1)
WHERE t.name LIKE N'%product%' OR t.name LIKE N'%menu%' OR t.name LIKE N'%food%'
   OR t.name LIKE N'%category%' OR t.name LIKE N'%group%'
GROUP BY t.name
ORDER BY est_rows DESC, t.name;
