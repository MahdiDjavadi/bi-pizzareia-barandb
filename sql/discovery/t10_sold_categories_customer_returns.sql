
/* ============================================================================
   T10 | P2 / S5-S6 | Sold categories, text variants, dominant customer, returns
   ============================================================================ */

USE [BaranDb];

-- T10.1 Which categories are actually sold? (counts and amounts only)
WITH sold AS (
    SELECT t_productID, COUNT_BIG(*) AS lines, SUM(t_qana * OnePrice) AS line_amount
    FROM dbo.orderItems
    GROUP BY t_productID
)
SELECT p.t_category, p.ProductType,
       COUNT_BIG(*) AS products,
       SUM(CASE WHEN s.t_productID IS NOT NULL THEN 1 ELSE 0 END) AS products_sold,
       COALESCE(SUM(s.lines), 0) AS lines,
       COALESCE(SUM(s.line_amount), 0) AS line_amount
FROM dbo.products AS p
LEFT JOIN sold AS s ON s.t_productID = p.t_productID
GROUP BY p.t_category, p.ProductType
ORDER BY line_amount DESC, p.t_category, p.ProductType;

-- T10.2 t_copr by category (isPizza is dead, so test against category)
SELECT p.t_category, oi.t_copr, COUNT_BIG(*) AS lines
FROM dbo.orderItems AS oi
JOIN dbo.products AS p ON p.t_productID = oi.t_productID
GROUP BY p.t_category, oi.t_copr
ORDER BY p.t_category, oi.t_copr;

-- T10.3 Arabic vs Persian letter variants in category text (binary comparison)
SELECT SUM(CASE WHEN t_category COLLATE Latin1_General_BIN2 LIKE N'%' + NCHAR(1610) + N'%' THEN 1 ELSE 0 END) AS has_arabic_yeh,
       SUM(CASE WHEN t_category COLLATE Latin1_General_BIN2 LIKE N'%' + NCHAR(1740) + N'%' THEN 1 ELSE 0 END) AS has_persian_yeh,
       SUM(CASE WHEN t_category COLLATE Latin1_General_BIN2 LIKE N'%' + NCHAR(1603) + N'%' THEN 1 ELSE 0 END) AS has_arabic_kaf,
       SUM(CASE WHEN t_category COLLATE Latin1_General_BIN2 LIKE N'%' + NCHAR(1705) + N'%' THEN 1 ELSE 0 END) AS has_persian_kaf
FROM dbo.products;

-- T10.4 Dominant customer: ids and relation to order type (ids and counts only, no personal data)
SELECT TOP (3) t_customerID, COUNT_BIG(*) AS orders
FROM dbo.orders
GROUP BY t_customerID
ORDER BY orders DESC;

WITH top_c AS (
    SELECT TOP (1) t_customerID
    FROM dbo.orders
    GROUP BY t_customerID
    ORDER BY COUNT_BIG(*) DESC
)
SELECT o.FactorType,
       CASE WHEN o.t_customerID = t.t_customerID THEN 1 ELSE 0 END AS is_top_customer,
       COUNT_BIG(*) AS orders
FROM dbo.orders AS o
CROSS JOIN top_c AS t
GROUP BY o.FactorType, CASE WHEN o.t_customerID = t.t_customerID THEN 1 ELSE 0 END
ORDER BY o.FactorType, is_top_customer DESC;

-- T10.5 Columns of customers (names and types only; find non-sensitive flags)
SELECT c.column_id, c.name AS column_name, TYPE_NAME(c.user_type_id) AS data_type
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID(N'dbo.customers')
ORDER BY c.column_id;

-- T10.6 BackFactors link: does FactorId point to orders, and does it explain t_show = 0?
SELECT COUNT_BIG(*) AS back_rows,
       SUM(match_order_id) AS match_t_orderID,
       SUM(match_factor_no) AS match_FactorNumber,
       SUM(CASE WHEN match_order_id = 1 AND show_flag = 0 THEN 1 ELSE 0 END) AS match_and_t_show_0,
       MIN(AmountNotBack) AS min_amount, MAX(AmountNotBack) AS max_amount
FROM (SELECT b.AmountNotBack,
             CASE WHEN EXISTS (SELECT 1 FROM dbo.orders AS o WHERE o.t_orderID = b.FactorId) THEN 1 ELSE 0 END AS match_order_id,
             CASE WHEN EXISTS (SELECT 1 FROM dbo.orders AS o WHERE o.FactorNumber = b.FactorId) THEN 1 ELSE 0 END AS match_factor_no,
             (SELECT TOP (1) o.t_show FROM dbo.orders AS o WHERE o.t_orderID = b.FactorId) AS show_flag
      FROM dbo.BackFactors AS b) AS x;

SELECT COUNT_BIG(*) AS t_show_0_orders, SUM(has_back) AS with_back_row
FROM (SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.BackFactors AS b WHERE b.FactorId = o.t_orderID) THEN 1 ELSE 0 END AS has_back
      FROM dbo.orders AS o
      WHERE o.t_show = 0) AS x;
