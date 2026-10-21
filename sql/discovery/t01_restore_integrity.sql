/* ============================================================================
   T1 | P2 / S0-S1 | Restore and integrity
   ============================================================================ */

-- T1.1 Local file fingerprint (run in PowerShell, not in SSMS; keep the output private)
-- Get-FileHash -Algorithm SHA256 -LiteralPath '<BACKUP_PATH>'
-- Hash value: <store in private notes, never commit>

-- T1.2 Backup metadata only (no restore yet)
RESTORE HEADERONLY
FROM DISK = N'<BACKUP_PATH>';

RESTORE FILELISTONLY
FROM DISK = N'<BACKUP_PATH>';

-- T1.3 Version of the server doing the restore
SELECT @@VERSION;

-- T1.4 Restore as a new database (fails safely if BaranDB already exists)
-- Logical names below come from FILELISTONLY.
DECLARE @data_path nvarchar(260) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(260));
DECLARE @log_path  nvarchar(260) = CAST(SERVERPROPERTY('InstanceDefaultLogPath')  AS nvarchar(260));

DECLARE @sql nvarchar(max) = N'
RESTORE DATABASE [BaranDB]
FROM DISK = N''<BACKUP_PATH>''
WITH
    MOVE N''Baran'' TO N''' + @data_path + N'BaranDB.mdf'',
    MOVE N''Baran_log''  TO N''' + @log_path  + N'BaranDB_log.ldf'',
    RECOVERY, STATS = 5;';

EXEC sys.sp_executesql @sql;

-- T1.5 Integrity check on the restored copy, then protect it
DBCC CHECKDB (N'BaranDB') WITH NO_INFOMSGS, ALL_ERRORMSGS;

ALTER DATABASE [BaranDB] SET READ_ONLY WITH ROLLBACK IMMEDIATE;

-- T1.6 Confirm restore settings
SELECT name, compatibility_level, collation_name, is_read_only
FROM sys.databases WHERE name = N'BaranDb';
