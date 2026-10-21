/* ============================================================================
   T2 | P2 / S2 | Table inventory and key candidates
   ============================================================================ */

USE [BaranDb];

-- T2.1 Inventory: estimated rows, columns, PK flag, FK counts
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    (SELECT SUM(ps.row_count) FROM sys.dm_db_partition_stats AS ps
      WHERE ps.object_id = t.object_id AND ps.index_id IN (0, 1)) AS est_rows,
    (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id = t.object_id) AS column_count,
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes AS i
                       WHERE i.object_id = t.object_id AND i.is_primary_key = 1)
         THEN 1 ELSE 0 END AS has_pk,
    (SELECT COUNT(*) FROM sys.foreign_keys AS fk WHERE fk.parent_object_id = t.object_id) AS fk_out,
    (SELECT COUNT(*) FROM sys.foreign_keys AS fk WHERE fk.referenced_object_id = t.object_id) AS fk_in
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY est_rows DESC, schema_name, table_name;

-- T2.2 Declared keys and indexes on core candidates
SELECT t.name AS table_name, i.name AS index_name, i.type_desc, i.is_unique, i.is_primary_key,
       STRING_AGG(c.name, N', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
FROM sys.tables AS t
JOIN sys.indexes AS i ON i.object_id = t.object_id AND i.index_id > 0
JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE t.name IN (N'orders', N'orderItems', N'customers', N'HistoryFactors', N'HistoryFactorItems', N'products', N'PurchaseFactors', N'PurchaseFactorItems', N'HistoryPurchaseFactorItems', N'HistoryPurchaseFactors')
GROUP BY t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY t.name, i.is_primary_key DESC;

-- T2.3 Columns of the header/line candidates (metadata only, no data)
SELECT t.name AS table_name, c.column_id, c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type, c.max_length, c.is_nullable, c.is_identity
FROM sys.tables AS t
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE t.name IN (N'orders', N'orderItems', N'HistoryFactors', N'HistoryFactorItems')
ORDER BY t.name, c.column_id;

-- T2.4 Name search across all tables, including empty ones
SELECT t.name AS table_name, SUM(ps.row_count) AS est_rows
FROM sys.tables AS t
JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = t.object_id AND ps.index_id IN (0, 1)
WHERE t.name LIKE N'%factor%' OR t.name LIKE N'%order%' OR t.name LIKE N'%sale%'
    OR t.name LIKE N'%invoice%' OR t.name LIKE N'%customer%' OR t.name LIKE N'%payment%'
GROUP BY t.name
ORDER BY t.name;
