-- ============================================================
-- Onfoot Inventory – Database Changes
-- Run this AFTER DatabaseSetup.sql is already applied.
-- ============================================================

USE OnfootInventory;
GO

-- ============================================================
-- Marketplaces  (dynamic list of sales channels)
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Marketplaces')
BEGIN
    CREATE TABLE Marketplaces (
        MarketplaceId   INT           IDENTITY(1,1) PRIMARY KEY,
        MarketplaceName NVARCHAR(100) NOT NULL,
        Description     NVARCHAR(500) NULL,
        IsActive        BIT           NOT NULL DEFAULT 1,
        CreatedDate     DATETIME      NOT NULL DEFAULT GETDATE()
    );

    -- Default seed data
    INSERT INTO Marketplaces (MarketplaceName, Description, IsActive)
    VALUES
        ('Website', 'Own website orders',  1),
        ('Daraz',   'Daraz marketplace',   1),
        ('Markaz',  'Markaz platform',     1);
END
GO

-- ============================================================
-- MarketplaceInventory  (stock per variant per marketplace)
-- ProductVariants.StockQuantity = warehouse / unallocated stock
-- MarketplaceInventory.StockQuantity = stock sent to that channel
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MarketplaceInventory')
BEGIN
    CREATE TABLE MarketplaceInventory (
        InventoryId     INT      IDENTITY(1,1) PRIMARY KEY,
        VariantId       INT      NOT NULL,
        MarketplaceId   INT      NOT NULL,
        StockQuantity   INT      NOT NULL DEFAULT 0,
        UpdatedDate     DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_MI_Variants      FOREIGN KEY (VariantId)     REFERENCES ProductVariants(VariantId),
        CONSTRAINT FK_MI_Marketplaces  FOREIGN KEY (MarketplaceId) REFERENCES Marketplaces(MarketplaceId),
        CONSTRAINT UQ_MI_VariantMarket UNIQUE (VariantId, MarketplaceId)
    );
END
GO

-- ============================================================
-- StockMovements  (full audit trail)
-- MovementType values:
--   RECEIVE  – stock added to warehouse
--   ALLOCATE – stock moved warehouse → marketplace
--   RETURN   – stock moved marketplace → warehouse
-- FromMarketplaceId NULL = source is warehouse
-- ToMarketplaceId   NULL = destination is warehouse
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StockMovements')
BEGIN
    CREATE TABLE StockMovements (
        MovementId        INT           IDENTITY(1,1) PRIMARY KEY,
        VariantId         INT           NOT NULL,
        MovementType      NVARCHAR(50)  NOT NULL,
        FromMarketplaceId INT           NULL,
        ToMarketplaceId   INT           NULL,
        Quantity          INT           NOT NULL,
        Notes             NVARCHAR(500) NULL,
        CreatedDate       DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_SM_Variants   FOREIGN KEY (VariantId)          REFERENCES ProductVariants(VariantId),
        CONSTRAINT FK_SM_FromMarket FOREIGN KEY (FromMarketplaceId)  REFERENCES Marketplaces(MarketplaceId),
        CONSTRAINT FK_SM_ToMarket   FOREIGN KEY (ToMarketplaceId)    REFERENCES Marketplaces(MarketplaceId)
    );
END
GO

-- Add CreatedBy to StockMovements (run once, safe to re-run)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'StockMovements' AND COLUMN_NAME = 'CreatedBy')
BEGIN
    ALTER TABLE StockMovements ADD CreatedBy NVARCHAR(150) NULL;
END
GO

-- ============================================================
-- Indexes
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MarketplaceInventory_VariantId')
    CREATE INDEX IX_MarketplaceInventory_VariantId ON MarketplaceInventory(VariantId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_StockMovements_VariantId')
    CREATE INDEX IX_StockMovements_VariantId ON StockMovements(VariantId);
GO

PRINT 'DatabaseChanges applied successfully.';
