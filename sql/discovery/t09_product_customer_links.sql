/* ============================================================================
   T9 | P2 / S5 | Product link, t_copr meaning, customer distribution
   ============================================================================ */

USE [BaranDb];

-- T9.1 Product key uniqueness and relationship (EXISTS inside a derived table)
SELECT COUNT_BIG(*) AS products, COUNT_BIG(DISTINCT t_productID) AS distinct_ids,
       SUM(CASE WHEN t_productID IS NULL THEN 1 ELSE 0 END) AS null_ids
FROM dbo.products;

SELECT COUNT_BIG(*) AS line_rows,
       SUM(CASE WHEN t_productID IS NULL THEN 1 ELSE 0 END) AS null_refs,
       SUM(CASE WHEN t_productID IS NOT NULL AND product_exists = 0 THEN 1 ELSE 0 END) AS orphan_rows
FROM (SELECT oi.t_productID,
             CASE WHEN EXISTS (SELECT 1 FROM dbo.products AS p WHERE p.t_productID = oi.t_productID)
                  THEN 1 ELSE 0 END AS product_exists
      FROM dbo.orderItems AS oi) AS x;

-- T9.2 Product attribute distributions (counts only)
SELECT 't_category' AS dim, CAST(t_category AS nvarchar(300)) AS val, COUNT_BIG(*) AS products
FROM dbo.products GROUP BY t_category
UNION ALL SELECT 'ProductType', CAST(ProductType AS nvarchar(300)), COUNT_BIG(*) FROM dbo.products GROUP BY ProductType
UNION ALL SELECT 'isPizza',     CAST(isPizza AS nvarchar(300)),     COUNT_BIG(*) FROM dbo.products GROUP BY isPizza
UNION ALL SELECT 't_show',      CAST(t_show AS nvarchar(300)),      COUNT_BIG(*) FROM dbo.products GROUP BY t_show
ORDER BY dim, products DESC;

-- T9.3 What does t_copr mean? Cross it with product flags (safe only if T9.1 shows unique product ids)
SELECT oi.t_copr, p.isPizza, COUNT_BIG(*) AS lines
FROM dbo.orderItems AS oi
LEFT JOIN dbo.products AS p ON p.t_productID = oi.t_productID
GROUP BY oi.t_copr, p.isPizza
ORDER BY oi.t_copr, p.isPizza;

-- T9.4 Customer distribution (counts only, no personal data)
SELECT COUNT_BIG(*) AS orders,
       COUNT_BIG(DISTINCT t_customerID) AS distinct_customers,
       MAX(c) AS max_orders_one_customer,
       CAST(MAX(c) AS decimal(18,4)) / COUNT_BIG(*) AS top_customer_share
FROM (SELECT t_customerID, COUNT_BIG(*) OVER (PARTITION BY t_customerID) AS c
      FROM dbo.orders) AS x;

-- T9.5 Columns of BackFactors (metadata only; candidate for returned/cancelled sales)
SELECT t.name AS table_name, c.column_id, c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type
FROM sys.tables AS t
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE t.name = N'BackFactors'
ORDER BY c.column_id;
