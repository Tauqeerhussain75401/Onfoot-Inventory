-- ============================================================
-- Onfoot Inventory – Database Setup Script
-- Database: OnfootInventory
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'OnfootInventory')
BEGIN
    CREATE DATABASE OnfootInventory;
END
GO

USE OnfootInventory;
GO

-- ============================================================
-- Categories
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Categories')
BEGIN
    CREATE TABLE Categories (
        CategoryId   INT           IDENTITY(1,1) PRIMARY KEY,
        CategoryName NVARCHAR(100) NOT NULL,
        Description  NVARCHAR(500) NULL,
        IsActive     BIT           NOT NULL DEFAULT 1,
        IsDeleted    BIT           NOT NULL DEFAULT 0,
        CreatedDate  DATETIME      NOT NULL DEFAULT GETDATE()
    );
END
GO

-- ============================================================
-- Products
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Products')
BEGIN
    CREATE TABLE Products (
        ProductId          INT             IDENTITY(1,1) PRIMARY KEY,
        ProductCode        NVARCHAR(50)    NOT NULL,
        SKUNumber          NVARCHAR(100)   NULL,
        ProductName        NVARCHAR(200)   NOT NULL,
        CategoryId         INT             NOT NULL,
        Material           NVARCHAR(100)   NULL,
        Description        NVARCHAR(1000)  NULL,
        ManufacturingPrice DECIMAL(18,2)   NOT NULL DEFAULT 0,
        CostPrice          DECIMAL(18,2)   NOT NULL DEFAULT 0,
        SalePrice          DECIMAL(18,2)   NOT NULL DEFAULT 0,
        MinStockLevel      INT             NOT NULL DEFAULT 0,
        Unit               NVARCHAR(20)    NOT NULL DEFAULT 'Pair',
        IsActive           BIT             NOT NULL DEFAULT 1,
        CreatedDate        DATETIME        NOT NULL DEFAULT GETDATE(),
        UpdatedDate        DATETIME        NULL,
        CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId)
            REFERENCES Categories(CategoryId)
    );
END
GO

-- ============================================================
-- ProductVariants
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ProductVariants')
BEGIN
    CREATE TABLE ProductVariants (
        VariantId     INT           IDENTITY(1,1) PRIMARY KEY,
        ProductId     INT           NOT NULL,
        Color         NVARCHAR(50)  NOT NULL,
        Size          NVARCHAR(20)  NOT NULL,
        StockQuantity INT           NOT NULL DEFAULT 0,
        SKUNumbers    NVARCHAR(200) NULL,
        IsActive      BIT           NOT NULL DEFAULT 1,
        CONSTRAINT FK_ProductVariants_Products FOREIGN KEY (ProductId)
            REFERENCES Products(ProductId)
    );
END
GO

-- ============================================================
-- Customers
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Customers')
BEGIN
    CREATE TABLE Customers (
        CustomerId   INT           IDENTITY(1,1) PRIMARY KEY,
        Name         NVARCHAR(150) NOT NULL DEFAULT '',
        Phone        NVARCHAR(20)  NOT NULL,
        Designation  NVARCHAR(100) NULL,
        Address      NVARCHAR(500) NULL,
        Destination  NVARCHAR(100) NULL,
        BuyingCount  INT           NOT NULL DEFAULT 0,
        CreatedDate  DATETIME      NOT NULL DEFAULT GETDATE(),
        UpdatedDate  DATETIME      NULL,
        CONSTRAINT UQ_Customers_Phone UNIQUE (Phone)
    );
END
GO

-- ============================================================
-- Sales
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Sales')
BEGIN
    CREATE TABLE Sales (
        SaleId       INT            IDENTITY(1,1) PRIMARY KEY,
        BillNumber   NVARCHAR(50)   NOT NULL,
        Platform     NVARCHAR(50)   NOT NULL,
        SaleDate     DATETIME       NOT NULL,
        TotalQty     INT            NOT NULL DEFAULT 0,
        TotalAmount  DECIMAL(18,2)  NOT NULL DEFAULT 0,
        Status       NVARCHAR(20)   NOT NULL DEFAULT 'Completed',
        Notes        NVARCHAR(1000) NULL,
        CustomerId   INT            NULL,
        CreatedDate  DATETIME       NOT NULL DEFAULT GETDATE(),
        UpdatedDate  DATETIME       NULL,
        CONSTRAINT FK_Sales_Customers FOREIGN KEY (CustomerId)
            REFERENCES Customers(CustomerId)
    );
END
GO

-- ============================================================
-- SaleItems
-- ============================================================
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SaleItems')
BEGIN
    CREATE TABLE SaleItems (
        SaleItemId  INT            IDENTITY(1,1) PRIMARY KEY,
        SaleId      INT            NOT NULL,
        VariantId   INT            NULL,
        SKUNumber   NVARCHAR(200)  NOT NULL DEFAULT '',
        ProductName NVARCHAR(200)  NULL,
        Color       NVARCHAR(50)   NULL,
        Size        NVARCHAR(20)   NULL,
        Quantity    INT            NOT NULL DEFAULT 1,
        SalePrice   DECIMAL(18,2)  NOT NULL DEFAULT 0,
        TotalAmount DECIMAL(18,2)  NOT NULL DEFAULT 0,
        CONSTRAINT FK_SaleItems_Sales FOREIGN KEY (SaleId)
            REFERENCES Sales(SaleId),
        CONSTRAINT FK_SaleItems_Variants FOREIGN KEY (VariantId)
            REFERENCES ProductVariants(VariantId)
    );
END
GO

-- ============================================================
-- Indexes for performance
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Products_CategoryId')
    CREATE INDEX IX_Products_CategoryId ON Products(CategoryId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProductVariants_ProductId')
    CREATE INDEX IX_ProductVariants_ProductId ON ProductVariants(ProductId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Sales_SaleDate')
    CREATE INDEX IX_Sales_SaleDate ON Sales(SaleDate);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SaleItems_SaleId')
    CREATE INDEX IX_SaleItems_SaleId ON SaleItems(SaleId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customers_Phone')
    CREATE INDEX IX_Customers_Phone ON Customers(Phone);
GO

-- ============================================================
-- Sample Categories (optional seed data)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM Categories)
BEGIN
    INSERT INTO Categories (CategoryName, Description, IsActive)
    VALUES
        ('Flat Shoes',   'Ladies flat footwear',    1),
        ('Heels',        'High heel footwear',       1),
        ('Sandals',      'Open-toe sandals',         1),
        ('Casual Shoes', 'Everyday casual footwear', 1);
END
GO

PRINT 'OnfootInventory database setup completed successfully.';
