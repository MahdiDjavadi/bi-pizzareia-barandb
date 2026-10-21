/* ============================================================================
   T3 | P2 / S3 (+ part of S5) | Key uniqueness, relationships, domains
   ============================================================================ */
USE [BaranDb];

-- T3.1 Key uniqueness (declared keys are absent, so test it)
SELECT 'orders.t_orderID' AS key_name,
       COUNT_BIG(*) AS total_rows,
       COUNT_BIG(DISTINCT t_orderID) AS distinct_keys,
       SUM(CASE WHEN t_orderID IS NULL THEN 1 ELSE 0 END) AS null_keys
FROM   dbo.orders
UNION ALL
SELECT 'orderItems.ID',
       COUNT_BIG(*),
       COUNT_BIG(DISTINCT ID),
       SUM(CASE WHEN ID IS NULL THEN 1 ELSE 0 END)
FROM   dbo.orderItems
UNION ALL
SELECT 'customers.t_customerID',
       COUNT_BIG(*),
       COUNT_BIG(DISTINCT t_customerID),
       SUM(CASE WHEN t_customerID IS NULL THEN 1 ELSE 0 END)
FROM   dbo.customers
UNION ALL
SELECT 'HistoryFactors.t_orderID',
       COUNT_BIG(*),
       COUNT_BIG(DISTINCT t_orderID),
       SUM(CASE WHEN t_orderID IS NULL THEN 1 ELSE 0 END)
FROM   dbo.HistoryFactors
UNION ALL
SELECT 'product.t_productID',
       COUNT_BIG(*),
       COUNT_BIG(DISTINCT t_productID),
       SUM(CASE WHEN t_productID IS NULL THEN 1 ELSE 0 END)
FROM   dbo.products;

-- T3.2 Candidate relationships (EXISTS avoids join multiplication)
SELECT   relationship,
         COUNT_BIG(*) AS child_rows,
         SUM(CASE WHEN child_id IS NULL THEN 1 ELSE 0 END) AS null_refs,
         SUM(CASE WHEN child_id IS NOT NULL
                       AND parent_exists = 0 THEN 1 ELSE 0 END) AS orphan_rows
FROM     (SELECT 'orderItems -> orders' AS relationship,
                 oi.t_orderID AS child_id,
                 CASE WHEN EXISTS (SELECT 1
                                   FROM   dbo.orders AS o
                                   WHERE  o.t_orderID = oi.t_orderID) THEN 1 ELSE 0 END AS parent_exists
          FROM   dbo.orderItems AS oi
          UNION ALL
          SELECT 'orders -> customers',
                 o.t_customerID,
                 CASE WHEN EXISTS (SELECT 1
                                   FROM   dbo.customers AS c
                                   WHERE  c.t_customerID = o.t_customerID) THEN 1 ELSE 0 END
          FROM   dbo.orders AS o
          UNION ALL
          SELECT 'HistoryFactors -> orders',
                 h.t_orderID,
                 CASE WHEN EXISTS (SELECT 1
                                   FROM   dbo.orders AS o
                                   WHERE  o.t_orderID = h.t_orderID) THEN 1 ELSE 0 END
          FROM   dbo.HistoryFactors AS h
          UNION ALL
          SELECT 'orderItems -> products',
                 oi.t_productID,
                 CASE WHEN EXISTS (SELECT 1
                                   FROM   dbo.products AS o
                                   WHERE  o.t_productID = oi.t_productID) THEN 1 ELSE 0 END
          FROM   dbo.orderItems AS oi) AS relationships
GROUP BY relationship;

-- T3.3 Orders without any line item
SELECT COUNT_BIG(*) AS order_rows,
       COUNT_BIG(*) - COUNT_BIG(items.t_orderID) AS orders_without_items
FROM   dbo.orders AS o
       LEFT OUTER JOIN
       (SELECT DISTINCT t_orderID
        FROM   dbo.orderItems
        WHERE  t_orderID IS NOT NULL) AS items
       ON items.t_orderID = o.t_orderID;

-- T3.4 Value distributions of status/channel columns (counts only, no personal data)
SELECT   't_show' AS dim,
         CAST (t_show AS NVARCHAR (300)) AS val,
         COUNT_BIG(*) AS cnt
FROM     dbo.orders
GROUP BY t_show
UNION ALL
SELECT   'FactorType',
         CAST (FactorType AS NVARCHAR (300)),
         COUNT_BIG(*)
FROM     dbo.orders
GROUP BY FactorType
UNION ALL
SELECT   'fromMobile',
         CAST (fromMobile AS NVARCHAR (300)),
         COUNT_BIG(*)
FROM     dbo.orders
GROUP BY fromMobile
UNION ALL
SELECT   'SysName',
         CAST (SysName AS NVARCHAR (300)),
         COUNT_BIG(*)
FROM     dbo.orders
GROUP BY SysName
UNION ALL
SELECT   't_paymentMethod',
         CAST (t_paymentMethod AS NVARCHAR (300)),
         COUNT_BIG(*)
FROM     dbo.orders
GROUP BY t_paymentMethod
UNION ALL
SELECT   'OnlineShopId_is_set',
         CASE WHEN OnlineShopId IS NULL THEN N'NULL' ELSE N'NOT NULL' END,
         COUNT_BIG(*)
FROM     dbo.orders
GROUP BY CASE WHEN OnlineShopId IS NULL THEN N'NULL' ELSE N'NOT NULL' END
ORDER BY dim,
         cnt DESC;
