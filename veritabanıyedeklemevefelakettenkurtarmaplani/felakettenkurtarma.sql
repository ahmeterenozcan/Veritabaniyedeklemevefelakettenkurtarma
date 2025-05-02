--------------------------------------------------------------------------------
-- 0) BAŞLANGIÇ: Örnek Ürünler Veritabanı Oluşturma ve Test Veri Eklemek
--------------------------------------------------------------------------------
-- 0.1 Veritabanı oluştur
IF DB_ID('DisasterDB') IS NULL
    CREATE DATABASE DisasterDB;
GO

-- 0.2 Ürünler tablosu oluştur ve örnek kayıt ekle
USE DisasterDB;
GO
IF OBJECT_ID('dbo.Urunler','U') IS NULL
BEGIN
    CREATE TABLE dbo.Urunler (
        UrunID   INT IDENTITY(1,1) PRIMARY KEY,
        UrunAdi  NVARCHAR(100),
        Fiyat     DECIMAL(10,2)
    );
    INSERT INTO dbo.Urunler (UrunAdi, Fiyat) VALUES
        ('Kalem',      1.50),
        ('Defter',    25.00),
        ('Kalemtıraş', 3.25);
END
GO

--------------------------------------------------------------------------------
-- 1) FULL BACKUP
--------------------------------------------------------------------------------
BACKUP DATABASE DisasterDB
TO DISK = N'D:\SQL_Backups\DisasterDB_Full.bak'
WITH INIT, FORMAT, 
     NAME = N'DisasterDB-FullBackup';
GO

--------------------------------------------------------------------------------
-- 2) DIFFERENTIAL BACKUP
--------------------------------------------------------------------------------
BACKUP DATABASE DisasterDB
TO DISK = N'D:\SQL_Backups\DisasterDB_Differential.bak'
WITH DIFFERENTIAL, INIT,
     NAME = N'DisasterDB-DiffBackup';
GO

--------------------------------------------------------------------------------
-- 3) TRANSACTION LOG BACKUP
--------------------------------------------------------------------------------
-- (Önce bir değişiklik yapıp sonra log alıyoruz)
INSERT INTO dbo.Urunler (UrunAdi, Fiyat)
VALUES ('Silgi', 2.00);
GO

BACKUP LOG DisasterDB
TO DISK = N'D:\SQL_Backups\DisasterDB_Log.trn'
WITH NAME = N'DisasterDB-LogBackup';
GO

--------------------------------------------------------------------------------
-- 4) FELAKET SENARYOSU: DB’yi Sil / Offline Yap
--------------------------------------------------------------------------------
-- (işlemi test amacıyla ya offline alıyoruz ya da tamamen siliyoruz)
ALTER DATABASE DisasterDB SET OFFLINE WITH ROLLBACK IMMEDIATE;
-- DROP DATABASE DisasterDB;
GO

--------------------------------------------------------------------------------
-- 5) RESTORE: Tam + Differential + Log Zinciri
--------------------------------------------------------------------------------
-- 5.1 Full yedekten restore (NORECOVERY)
RESTORE DATABASE DisasterDB
FROM DISK = N'D:\SQL_Backups\DisasterDB_Full.bak'
WITH 
    NORECOVERY,
    MOVE 'DisasterDB'     TO 'C:\SQLData\DisasterDB.mdf',
    MOVE 'DisasterDB_Log' TO 'C:\SQLData\DisasterDB.ldf';
GO

-- 5.2 Diff yedekten restore (NORECOVERY)
RESTORE DATABASE DisasterDB
FROM DISK = N'D:\SQL_Backups\DisasterDB_Differential.bak'
WITH NORECOVERY;
GO

-- 5.3 Log yedeğini point‑in‑time ile restore et (RECOVERY)
--    STOPAT değerini RESTORE HEADERONLY çıktınıza göre ayarlayın
RESTORE LOG DisasterDB
FROM DISK = N'D:\SQL_Backups\DisasterDB_Log.trn'
WITH 
    STOPAT   = '2025-05-02 21:25:41',  
    RECOVERY;
GO

--------------------------------------------------------------------------------
-- 6) DOĞRULAMA: Tamveritabanı geri geldi mi?
--------------------------------------------------------------------------------
SELECT * 
FROM DisasterDB.dbo.Urunler;
GO
