using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class Sales : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e) { EnsureCourierIdColumn(); EnsureBOLFileColumn(); EnsureIsFulfilledColumn(); }

        private static void EnsureCourierIdColumn()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        IF NOT EXISTS (
                            SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                            WHERE TABLE_NAME = 'Sales' AND COLUMN_NAME = 'CourierId'
                        )
                        ALTER TABLE Sales ADD CourierId INT NULL
                            CONSTRAINT FK_Sales_Couriers FOREIGN KEY (CourierId) REFERENCES Couriers(CourierId)", conn))
                    {
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch { }
        }

        private static void EnsureBOLFileColumn()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        IF NOT EXISTS (
                            SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                            WHERE TABLE_NAME = 'Sales' AND COLUMN_NAME = 'BOLFile')
                        ALTER TABLE Sales ADD BOLFile NVARCHAR(500) NULL;
                        IF NOT EXISTS (
                            SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                            WHERE TABLE_NAME = 'Sales' AND COLUMN_NAME = 'TrackingNo')
                        ALTER TABLE Sales ADD TrackingNo NVARCHAR(200) NULL;
                        IF NOT EXISTS (
                            SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                            WHERE TABLE_NAME = 'Sales' AND COLUMN_NAME = 'OrderRef')
                        ALTER TABLE Sales ADD OrderRef NVARCHAR(200) NULL;", conn))
                    {
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch { }
        }

        private static void EnsureIsFulfilledColumn()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        IF NOT EXISTS (
                            SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                            WHERE TABLE_NAME = 'SaleItems' AND COLUMN_NAME = 'IsFulfilled')
                        ALTER TABLE SaleItems ADD IsFulfilled BIT NOT NULL DEFAULT 1;", conn))
                    {
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch { }
        }

        // ============================================================
        // MODELS
        // ============================================================
        public class SaleModel
        {
            public int    SaleId          { get; set; }
            public string BillNumber      { get; set; }
            public string Platform        { get; set; }
            public string SaleDate        { get; set; }
            public string Status          { get; set; }
            public string Notes           { get; set; }
            public string SaleSource      { get; set; }   // "Manual" | "BOL"
            public int?   CourierId       { get; set; }
            public string OrderRef        { get; set; }
            // Customer
            public string CustPhone       { get; set; }
            public string CustName        { get; set; }
            public string CustDesignation { get; set; }
            public string CustAddress     { get; set; }
        }

        public class SaleItemModel
        {
            public int     VariantId   { get; set; }
            public string  SKUNumber   { get; set; }
            public string  ProductName { get; set; }
            public string  Color       { get; set; }
            public string  Size        { get; set; }
            public int     Quantity    { get; set; }
            public decimal SalePrice   { get; set; }
            public bool?   IsFulfilled { get; set; }  // null = treat as true (fulfilled)
        }

        public class BolSaleGroup
        {
            public string            OrderRef   { get; set; }
            public string            TrackingNo { get; set; }
            public List<SaleItemModel> Items    { get; set; }
        }

        // ============================================================
        // HELPERS
        // ============================================================
        private static SqlConnection GetConnection()
        {
            return new SqlConnection(
                ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString);
        }

        private static string SafeStr(IDataReader r, string col)
        {
            int i = r.GetOrdinal(col);
            return r.IsDBNull(i) ? "" : r.GetString(i);
        }

        private static decimal SafeDec(IDataReader r, string col)
        {
            int i = r.GetOrdinal(col);
            return r.IsDBNull(i) ? 0m : Convert.ToDecimal(r.GetValue(i));
        }

        // ============================================================
        // ALL ACTIVE VARIANTS  (for manual sale checkbox dropdown)
        // ============================================================
        [WebMethod]
        public static string GetAllVariants(string marketplaceName = "")
        {
            var result = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();

                // Build per-marketplace stock map: variantId -> [{Name, Stock}]
                var stockMap = new Dictionary<int, List<object>>();
                const string mktSql = @"
                    SELECT mi.VariantId, m.MarketplaceName, ISNULL(mi.StockQuantity, 0) AS Stock
                    FROM   MarketplaceInventory mi
                    INNER JOIN Marketplaces m ON m.MarketplaceId = mi.MarketplaceId
                    WHERE  m.IsActive = 1
                    ORDER  BY m.MarketplaceId";
                using (var cmd = new SqlCommand(mktSql, conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        int vid = Convert.ToInt32(rdr["VariantId"]);
                        if (!stockMap.ContainsKey(vid)) stockMap[vid] = new List<object>();
                        stockMap[vid].Add(new
                        {
                            Name  = rdr["MarketplaceName"].ToString(),
                            Stock = Convert.ToInt32(rdr["Stock"])
                        });
                    }
                }

                const string sql = @"
                    SELECT pv.VariantId, pv.SKUNumbers, pv.Color, pv.Size,
                           ISNULL(mi.StockQuantity, 0) AS MarketplaceStock,
                           p.ProductName, p.ProductCode, p.SalePrice
                    FROM   ProductVariants pv
                    INNER JOIN Products p ON p.ProductId = pv.ProductId
                    LEFT JOIN Marketplaces m
                           ON m.MarketplaceName = @MktName AND m.IsActive = 1
                    LEFT JOIN MarketplaceInventory mi
                           ON mi.VariantId = pv.VariantId AND mi.MarketplaceId = m.MarketplaceId
                    WHERE  pv.IsActive = 1 AND p.IsActive = 1
                    ORDER  BY p.ProductName, pv.Color, pv.Size";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MktName", marketplaceName?.Trim() ?? "");
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            int vid = Convert.ToInt32(rdr["VariantId"]);
                            result.Add(new
                            {
                                VariantId    = vid,
                                SKUNumber    = SafeStr(rdr, "SKUNumbers"),
                                ProductName  = SafeStr(rdr, "ProductName"),
                                ProductCode  = SafeStr(rdr, "ProductCode"),
                                Color        = SafeStr(rdr, "Color"),
                                Size         = SafeStr(rdr, "Size"),
                                SalePrice    = SafeDec(rdr, "SalePrice"),
                                StockQty     = Convert.ToInt32(rdr["MarketplaceStock"]),
                                MarketStocks = stockMap.ContainsKey(vid) ? stockMap[vid] : new List<object>()
                            });
                        }
                    }
                }
            }
            return JsonConvert.SerializeObject(result);
        }

        // ============================================================
        // MARKETPLACES  (dynamic list from DB)
        // ============================================================
        [WebMethod]
        public static string GetMarketplaces()
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT MarketplaceId, MarketplaceName FROM Marketplaces WHERE IsActive = 1 ORDER BY MarketplaceId", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        list.Add(new
                        {
                            MarketplaceId   = Convert.ToInt32(rdr["MarketplaceId"]),
                            MarketplaceName = rdr["MarketplaceName"].ToString()
                        });
                    }
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // COURIERS  (for manual sale dropdown)
        // ============================================================
        [WebMethod]
        public static string GetCouriers()
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT CourierId, CourierName FROM Couriers WHERE IsActive = 1 AND IsDeleted = 0 ORDER BY CourierId ASC", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        list.Add(new
                        {
                            CourierId   = Convert.ToInt32(rdr["CourierId"]),
                            CourierName = rdr["CourierName"].ToString()
                        });
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // STATS
        // ============================================================
        [WebMethod]
        public static string GetSaleStats(string startDate = "", string endDate = "")
        {
            bool hasDateFilter = !string.IsNullOrWhiteSpace(startDate) || !string.IsNullOrWhiteSpace(endDate);

            // Build date WHERE fragment — today when no filter, range when filter is set
            string dateWhere;
            if (hasDateFilter)
            {
                var parts = new System.Collections.Generic.List<string>();
                if (!string.IsNullOrWhiteSpace(startDate)) parts.Add("CAST(SaleDate AS DATE) >= @StartDate");
                if (!string.IsNullOrWhiteSpace(endDate))   parts.Add("CAST(SaleDate AS DATE) <= @EndDate");
                dateWhere = string.Join(" AND ", parts);
            }
            else
            {
                dateWhere = "CAST(SaleDate AS DATE) = CAST(GETDATE() AS DATE)";
            }

            using (var conn = GetConnection())
            {
                conn.Open();

                string totalSql = @"
                    SELECT
                        ISNULL(SUM(CASE WHEN ISNULL(SaleSource,'Manual') = 'Manual' THEN 1           ELSE 0 END), 0) AS ManualBills,
                        ISNULL(SUM(CASE WHEN ISNULL(SaleSource,'Manual') = 'Manual' THEN TotalAmount ELSE 0 END), 0) AS ManualRevenue,
                        ISNULL(SUM(CASE WHEN SaleSource = 'BOL'                     THEN 1           ELSE 0 END), 0) AS BOLBills,
                        ISNULL(SUM(CASE WHEN SaleSource = 'BOL'                     THEN TotalAmount ELSE 0 END), 0) AS BOLRevenue,
                        COUNT(*)                                                                                       AS TotalBills,
                        ISNULL(SUM(TotalAmount), 0)                                                                    AS TotalRevenue
                    FROM Sales
                    WHERE Status = 'Completed'
                      AND " + dateWhere;

                int     totalBills = 0, manualBills = 0, bolBills = 0;
                decimal totalRevenue = 0, manualRevenue = 0, bolRevenue = 0;

                using (var cmd = new SqlCommand(totalSql, conn))
                {
                    if (!string.IsNullOrWhiteSpace(startDate)) cmd.Parameters.AddWithValue("@StartDate", DateTime.Parse(startDate));
                    if (!string.IsNullOrWhiteSpace(endDate))   cmd.Parameters.AddWithValue("@EndDate",   DateTime.Parse(endDate));
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            manualBills   = Convert.ToInt32(rdr["ManualBills"]);
                            manualRevenue = SafeDec(rdr, "ManualRevenue");
                            bolBills      = Convert.ToInt32(rdr["BOLBills"]);
                            bolRevenue    = SafeDec(rdr, "BOLRevenue");
                            totalBills    = Convert.ToInt32(rdr["TotalBills"]);
                            totalRevenue  = SafeDec(rdr, "TotalRevenue");
                        }
                    }
                }

                // Per-marketplace revenue + order count
                // OrderCount = distinct OrderRef values per bill;
                // if a bill has no OrderRef, it counts as 1 order.
                string mktSql = @"
                    WITH SaleOrderCounts AS (
                        SELECT
                            s.SaleId,
                            s.Platform,
                            s.TotalAmount,
                            1 AS OrderCount
                        FROM  Sales s
                        WHERE s.Status = 'Completed'
                          AND " + dateWhere + @"
                    )
                    SELECT m.MarketplaceName,
                           ISNULL(SUM(soc.TotalAmount), 0) AS Revenue,
                           ISNULL(SUM(soc.OrderCount),  0) AS OrderCount
                    FROM   Marketplaces m
                    LEFT JOIN SaleOrderCounts soc ON soc.Platform = m.MarketplaceName
                    WHERE  m.IsActive = 1
                    GROUP  BY m.MarketplaceId, m.MarketplaceName
                    ORDER  BY m.MarketplaceId";

                var marketplaceRevenues = new List<object>();
                using (var cmd = new SqlCommand(mktSql, conn))
                {
                    if (!string.IsNullOrWhiteSpace(startDate)) cmd.Parameters.AddWithValue("@StartDate", DateTime.Parse(startDate));
                    if (!string.IsNullOrWhiteSpace(endDate))   cmd.Parameters.AddWithValue("@EndDate",   DateTime.Parse(endDate));
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            marketplaceRevenues.Add(new
                            {
                                Name       = rdr["MarketplaceName"].ToString(),
                                Revenue    = SafeDec(rdr, "Revenue"),
                                OrderCount = Convert.ToInt32(rdr["OrderCount"])
                            });
                        }
                    }
                }

                return JsonConvert.SerializeObject(new
                {
                    ManualBills         = manualBills,
                    ManualRevenue       = manualRevenue,
                    BOLBills            = bolBills,
                    BOLRevenue          = bolRevenue,
                    TotalBills          = totalBills,
                    TotalRevenue        = totalRevenue,
                    MarketplaceRevenues = marketplaceRevenues,
                    IsFiltered          = hasDateFilter
                });
            }
        }

        // ============================================================
        // GET SALES LIST
        // ============================================================
        [WebMethod]
        public static string GetSales(string platform = "", string status = "", string startDate = "", string endDate = "")
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                bool hasDateFilter = !string.IsNullOrWhiteSpace(startDate) || !string.IsNullOrWhiteSpace(endDate);

                var where = "WHERE 1=1";
                if (!string.IsNullOrEmpty(platform))           where += " AND s.Platform = @Platform";
                if (!string.IsNullOrEmpty(status))             where += " AND s.Status = @Status";
                if (!string.IsNullOrWhiteSpace(startDate))     where += " AND CAST(s.SaleDate AS DATE) >= @StartDate";
                if (!string.IsNullOrWhiteSpace(endDate))       where += " AND CAST(s.SaleDate AS DATE) <= @EndDate";

                // No date filter → limit to newest 100 rows; date filter → return all matching rows
                string topClause = hasDateFilter ? "" : "TOP 100 ";

                var sql = @"
                    SELECT " + topClause + @"s.SaleId, s.BillNumber, s.Platform, s.SaleDate,
                           s.TotalQty, s.TotalAmount, s.Status, s.Notes, s.CreatedDate,
                           s.CustomerId, ISNULL(s.SaleSource, 'Manual') AS SaleSource,
                           CASE WHEN s.CustomerId IS NOT NULL THEN 1 ELSE 0 END AS HasCustomer,
                           COUNT(si.SaleItemId) AS ItemCount,
                           c.CourierName
                    FROM Sales s
                    LEFT JOIN SaleItems si ON si.SaleId = s.SaleId
                    LEFT JOIN Couriers c ON c.CourierId = s.CourierId
                    " + where + @"
                    GROUP BY s.SaleId, s.BillNumber, s.Platform, s.SaleDate,
                             s.TotalQty, s.TotalAmount, s.Status, s.Notes, s.CreatedDate,
                             s.CustomerId, s.SaleSource, c.CourierName
                    ORDER BY s.SaleId DESC";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(platform))           cmd.Parameters.AddWithValue("@Platform",  platform);
                    if (!string.IsNullOrEmpty(status))             cmd.Parameters.AddWithValue("@Status",    status);
                    if (!string.IsNullOrWhiteSpace(startDate))     cmd.Parameters.AddWithValue("@StartDate", DateTime.Parse(startDate));
                    if (!string.IsNullOrWhiteSpace(endDate))       cmd.Parameters.AddWithValue("@EndDate",   DateTime.Parse(endDate));

                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            list.Add(new
                            {
                                SaleId      = Convert.ToInt32(rdr["SaleId"]),
                                BillNumber  = SafeStr(rdr, "BillNumber"),
                                Platform    = SafeStr(rdr, "Platform"),
                                SaleDate    = Convert.ToDateTime(rdr["SaleDate"]).ToString("dd-MMM-yyyy"),
                                TotalQty    = Convert.ToInt32(rdr["TotalQty"]),
                                TotalAmount = SafeDec(rdr, "TotalAmount"),
                                Status      = SafeStr(rdr, "Status"),
                                Notes       = SafeStr(rdr, "Notes"),
                                ItemCount   = Convert.ToInt32(rdr["ItemCount"]),
                                HasCustomer = Convert.ToInt32(rdr["HasCustomer"]) == 1,
                                CreatedDate = Convert.ToDateTime(rdr["CreatedDate"]).ToString("dd-MMM-yyyy"),
                                CourierName = SafeStr(rdr, "CourierName"),
                                SaleSource  = SafeStr(rdr, "SaleSource")
                            });
                        }
                    }
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // GET SALE BY ID (view detail)
        // ============================================================
        [WebMethod]
        public static string GetSaleById(int saleId)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                object sale = null;

                using (var cmd = new SqlCommand(@"
                    SELECT s.*, c.CourierName
                    FROM   Sales s
                    LEFT JOIN Couriers c ON c.CourierId = s.CourierId
                    WHERE  s.SaleId = @Id", conn))
                {
                    cmd.Parameters.AddWithValue("@Id", saleId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            sale = new
                            {
                                SaleId      = Convert.ToInt32(rdr["SaleId"]),
                                BillNumber  = SafeStr(rdr, "BillNumber"),
                                Platform    = SafeStr(rdr, "Platform"),
                                SaleDate    = Convert.ToDateTime(rdr["SaleDate"]).ToString("yyyy-MM-dd"),
                                TotalQty    = Convert.ToInt32(rdr["TotalQty"]),
                                TotalAmount = SafeDec(rdr, "TotalAmount"),
                                Status      = SafeStr(rdr, "Status"),
                                Notes       = SafeStr(rdr, "Notes"),
                                CourierName = SafeStr(rdr, "CourierName"),
                                OrderRef    = SafeStr(rdr, "OrderRef"),
                                TrackingNo  = SafeStr(rdr, "TrackingNo")
                            };
                        }
                    }
                }
                if (sale == null) return "null";

                var items = new List<object>();
                using (var cmd2 = new SqlCommand(
                    "SELECT * FROM SaleItems WHERE SaleId = @Id ORDER BY SaleItemId", conn))
                {
                    cmd2.Parameters.AddWithValue("@Id", saleId);
                    using (var rdr2 = cmd2.ExecuteReader())
                    {
                        while (rdr2.Read())
                        {
                            bool isFulfilled = !rdr2.IsDBNull(rdr2.GetOrdinal("IsFulfilled")) && Convert.ToBoolean(rdr2["IsFulfilled"]);
                            items.Add(new
                            {
                                SaleItemId  = Convert.ToInt32(rdr2["SaleItemId"]),
                                VariantId   = rdr2.IsDBNull(rdr2.GetOrdinal("VariantId")) ? 0 : Convert.ToInt32(rdr2["VariantId"]),
                                SKUNumber   = SafeStr(rdr2, "SKUNumber"),
                                ProductName = SafeStr(rdr2, "ProductName"),
                                Color       = SafeStr(rdr2, "Color"),
                                Size        = SafeStr(rdr2, "Size"),
                                Quantity    = Convert.ToInt32(rdr2["Quantity"]),
                                SalePrice   = SafeDec(rdr2, "SalePrice"),
                                TotalAmount = SafeDec(rdr2, "TotalAmount"),
                                IsFulfilled = isFulfilled
                            });
                        }
                    }
                }
                return JsonConvert.SerializeObject(new { Sale = sale, Items = items });
            }
        }

        // ============================================================
        // GET SALE FOR EDIT
        // ============================================================
        [WebMethod]
        public static string GetSaleForEdit(int saleId)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                object sale = null;
                using (var cmd = new SqlCommand("SELECT * FROM Sales WHERE SaleId = @Id", conn))
                {
                    cmd.Parameters.AddWithValue("@Id", saleId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                            sale = new
                            {
                                SaleId     = Convert.ToInt32(rdr["SaleId"]),
                                BillNumber = SafeStr(rdr, "BillNumber"),
                                Platform   = SafeStr(rdr, "Platform"),
                                SaleDate   = Convert.ToDateTime(rdr["SaleDate"]).ToString("yyyy-MM-dd"),
                                Notes      = SafeStr(rdr, "Notes"),
                                OrderRef   = SafeStr(rdr, "OrderRef")
                            };
                    }
                }
                if (sale == null) return "null";

                var items = new List<object>();
                using (var cmd2 = new SqlCommand(
                    "SELECT * FROM SaleItems WHERE SaleId = @Id ORDER BY SaleItemId", conn))
                {
                    cmd2.Parameters.AddWithValue("@Id", saleId);
                    using (var rdr2 = cmd2.ExecuteReader())
                    {
                        while (rdr2.Read())
                            items.Add(new
                            {
                                VariantId   = rdr2.IsDBNull(rdr2.GetOrdinal("VariantId")) ? 0 : Convert.ToInt32(rdr2["VariantId"]),
                                SKUNumber   = SafeStr(rdr2, "SKUNumber"),
                                ProductName = SafeStr(rdr2, "ProductName"),
                                Color       = SafeStr(rdr2, "Color"),
                                Size        = SafeStr(rdr2, "Size"),
                                Quantity    = Convert.ToInt32(rdr2["Quantity"]),
                                SalePrice   = SafeDec(rdr2, "SalePrice")
                            });
                    }
                }
                return JsonConvert.SerializeObject(new { Sale = sale, Items = items });
            }
        }

        // ============================================================
        // UPDATE SALE  (restore old stock → delete items → re-insert → reapply stock)
        // ============================================================
        [WebMethod]
        public static string UpdateSale(SaleModel sale, string itemsJson)
        {
            try
            {
                if (sale == null || sale.SaleId <= 0) return Fail("Invalid sale data.");
                if (string.IsNullOrWhiteSpace(sale.BillNumber)) return Fail("Bill Number is required.");
                if (string.IsNullOrWhiteSpace(sale.Platform))   return Fail("Platform is required.");
                if (string.IsNullOrWhiteSpace(sale.SaleDate))   return Fail("Sale Date is required.");

                var newItems = JsonConvert.DeserializeObject<List<SaleItemModel>>(itemsJson ?? "[]")
                               ?? new List<SaleItemModel>();
                if (newItems.Count == 0) return Fail("Add at least one item.");

                int     totalQty    = 0;
                decimal totalAmount = 0;
                foreach (var it in newItems) { totalQty += it.Quantity; totalAmount += it.Quantity * it.SalePrice; }

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Verify sale exists and is not Cancelled
                    using (var cmd = new SqlCommand("SELECT Status FROM Sales WHERE SaleId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", sale.SaleId);
                        var r = cmd.ExecuteScalar();
                        if (r == null) return Fail("Sale not found.");
                        if (r.ToString() == "Cancelled") return Fail("Cancelled sales cannot be edited.");
                    }

                    // Duplicate bill check (exclude this sale)
                    using (var chk = new SqlCommand(
                        "SELECT COUNT(1) FROM Sales WHERE BillNumber = @BN AND Platform = @PL AND SaleId <> @Id", conn))
                    {
                        chk.Parameters.AddWithValue("@BN", sale.BillNumber.Trim());
                        chk.Parameters.AddWithValue("@PL", sale.Platform);
                        chk.Parameters.AddWithValue("@Id", sale.SaleId);
                        if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                            return Fail("Bill Number '" + sale.BillNumber + "' already exists for " + sale.Platform + ".");
                    }

                    // Step 1: Restore all existing stock deductions
                    var deductions = new List<(int VariantId, int? MarketplaceId, int Quantity, int DeductionId)>();
                    using (var cmd = new SqlCommand(
                        "SELECT DeductionId, VariantId, MarketplaceId, Quantity FROM SaleStockDeductions WHERE SaleId = @Id AND IsRestored = 0", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", sale.SaleId);
                        using (var rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                int? mid = rdr.IsDBNull(rdr.GetOrdinal("MarketplaceId")) ? (int?)null : Convert.ToInt32(rdr["MarketplaceId"]);
                                deductions.Add((Convert.ToInt32(rdr["VariantId"]), mid, Convert.ToInt32(rdr["Quantity"]), Convert.ToInt32(rdr["DeductionId"])));
                            }
                        }
                    }

                    foreach (var d in deductions)
                    {
                        if (d.MarketplaceId.HasValue)
                        {
                            using (var cmd = new SqlCommand(@"
                                UPDATE MarketplaceInventory SET StockQuantity = StockQuantity + @qty
                                WHERE VariantId = @vid AND MarketplaceId = @mid", conn))
                            {
                                cmd.Parameters.AddWithValue("@qty", d.Quantity);
                                cmd.Parameters.AddWithValue("@vid", d.VariantId);
                                cmd.Parameters.AddWithValue("@mid", d.MarketplaceId.Value);
                                cmd.ExecuteNonQuery();
                            }
                        }
                        else
                        {
                            using (var cmd = new SqlCommand(
                                "UPDATE ProductVariants SET StockQuantity = StockQuantity + @qty WHERE VariantId = @vid", conn))
                            {
                                cmd.Parameters.AddWithValue("@qty", d.Quantity);
                                cmd.Parameters.AddWithValue("@vid", d.VariantId);
                                cmd.ExecuteNonQuery();
                            }
                        }
                        // Delete the deduction row — must happen before SaleItems is deleted
                        // because FK_SSD_SaleItems references SaleItems.SaleItemId
                        using (var cmd = new SqlCommand(
                            "DELETE FROM SaleStockDeductions WHERE DeductionId = @Id", conn))
                        {
                            cmd.Parameters.AddWithValue("@Id", d.DeductionId);
                            cmd.ExecuteNonQuery();
                        }
                    }

                    // Remove any remaining deduction rows (e.g. IsRestored=1 from a previous
                    // failed edit) so FK_SSD_SaleItems no longer blocks the SaleItems delete.
                    using (var cmd = new SqlCommand(
                        "DELETE FROM SaleStockDeductions WHERE SaleId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", sale.SaleId);
                        cmd.ExecuteNonQuery();
                    }

                    // Step 2: Delete existing sale items (all FK references are now gone)
                    using (var cmd = new SqlCommand("DELETE FROM SaleItems WHERE SaleId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", sale.SaleId);
                        cmd.ExecuteNonQuery();
                    }

                    // Step 3: Compute status from new items, then update sale header
                    int editFulfilled = newItems.Count(it => it.IsFulfilled ?? true);
                    string editStatus = editFulfilled == newItems.Count ? "Completed"
                                      : editFulfilled == 0 ? "Unfulfilled"
                                      : "Partial";

                    using (var cmd = new SqlCommand(@"
                        UPDATE Sales
                        SET    BillNumber = @BillNumber, Platform = @Platform, SaleDate = @SaleDate,
                               TotalQty = @TotalQty, TotalAmount = @TotalAmount, Status = @Status,
                               Notes = @Notes, OrderRef = @OrderRef, UpdatedDate = GETDATE()
                        WHERE  SaleId = @SaleId", conn))
                    {
                        cmd.Parameters.AddWithValue("@BillNumber",  sale.BillNumber.Trim());
                        cmd.Parameters.AddWithValue("@Platform",    sale.Platform);
                        cmd.Parameters.AddWithValue("@SaleDate",    DateTime.Parse(sale.SaleDate));
                        cmd.Parameters.AddWithValue("@TotalQty",    totalQty);
                        cmd.Parameters.AddWithValue("@TotalAmount", totalAmount);
                        cmd.Parameters.AddWithValue("@Status",      editStatus);
                        cmd.Parameters.AddWithValue("@Notes",       (object)(sale.Notes?.Trim())   ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@OrderRef",    string.IsNullOrWhiteSpace(sale.OrderRef) ? (object)DBNull.Value : sale.OrderRef.Trim());
                        cmd.Parameters.AddWithValue("@SaleId",      sale.SaleId);
                        cmd.ExecuteNonQuery();
                    }

                    // Step 4: Resolve new marketplace ID
                    int? marketplaceId = null;
                    using (var cmd = new SqlCommand(
                        "SELECT TOP 1 MarketplaceId FROM Marketplaces WHERE MarketplaceName = @P AND IsActive = 1", conn))
                    {
                        cmd.Parameters.AddWithValue("@P", sale.Platform);
                        var r = cmd.ExecuteScalar();
                        if (r != null) marketplaceId = Convert.ToInt32(r);
                    }

                    // Step 5: Insert new items + deduct stock
                    foreach (var it in newItems)
                    {
                        decimal lineTotal = it.Quantity * it.SalePrice;

                        using (var cmd = new SqlCommand(@"
                            INSERT INTO SaleItems
                                (SaleId, VariantId, SKUNumber, ProductName, Color, Size, Quantity, SalePrice, TotalAmount, IsFulfilled)
                            VALUES
                                (@SaleId, @VariantId, @SKUNumber, @ProductName, @Color, @Size, @Quantity, @SalePrice, @TotalAmount, @IsFulfilled)", conn))
                        {
                            cmd.Parameters.AddWithValue("@SaleId",      sale.SaleId);
                            cmd.Parameters.AddWithValue("@VariantId",   it.VariantId > 0 ? (object)it.VariantId : DBNull.Value);
                            cmd.Parameters.AddWithValue("@SKUNumber",   it.SKUNumber  ?? "");
                            cmd.Parameters.AddWithValue("@ProductName", (object)(it.ProductName) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Color",       (object)(it.Color)       ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Size",        (object)(it.Size)        ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Quantity",    it.Quantity);
                            cmd.Parameters.AddWithValue("@SalePrice",   it.SalePrice);
                            cmd.Parameters.AddWithValue("@TotalAmount", lineTotal);
                            cmd.Parameters.AddWithValue("@IsFulfilled", it.IsFulfilled ?? true);
                            cmd.ExecuteNonQuery();
                        }

                        if (it.VariantId > 0 && (it.IsFulfilled ?? true))
                        {
                            int saleItemId = 0;
                            using (var cmd = new SqlCommand(
                                "SELECT TOP 1 SaleItemId FROM SaleItems WHERE SaleId=@S AND VariantId=@V ORDER BY SaleItemId DESC", conn))
                            {
                                cmd.Parameters.AddWithValue("@S", sale.SaleId);
                                cmd.Parameters.AddWithValue("@V", it.VariantId);
                                var r = cmd.ExecuteScalar();
                                if (r != null) saleItemId = Convert.ToInt32(r);
                            }

                            if (marketplaceId.HasValue)
                            {
                                using (var cmd = new SqlCommand(@"
                                    UPDATE MarketplaceInventory
                                    SET    StockQuantity = StockQuantity - @qty
                                    WHERE  VariantId = @vid AND MarketplaceId = @mid AND StockQuantity >= @qty", conn))
                                {
                                    cmd.Parameters.AddWithValue("@qty", it.Quantity);
                                    cmd.Parameters.AddWithValue("@vid", it.VariantId);
                                    cmd.Parameters.AddWithValue("@mid", marketplaceId.Value);
                                    cmd.ExecuteNonQuery();
                                }
                            }
                            else
                            {
                                using (var cmd = new SqlCommand(@"
                                    UPDATE ProductVariants
                                    SET    StockQuantity = StockQuantity - @qty
                                    WHERE  VariantId = @vid AND StockQuantity >= @qty", conn))
                                {
                                    cmd.Parameters.AddWithValue("@qty", it.Quantity);
                                    cmd.Parameters.AddWithValue("@vid", it.VariantId);
                                    cmd.ExecuteNonQuery();
                                }
                            }

                            using (var cmd = new SqlCommand(@"
                                INSERT INTO SaleStockDeductions
                                    (SaleId, SaleItemId, VariantId, MarketplaceId, Quantity)
                                VALUES
                                    (@SaleId, @SaleItemId, @VariantId, @MarketplaceId, @Quantity)", conn))
                            {
                                cmd.Parameters.AddWithValue("@SaleId",        sale.SaleId);
                                cmd.Parameters.AddWithValue("@SaleItemId",    saleItemId > 0 ? (object)saleItemId : DBNull.Value);
                                cmd.Parameters.AddWithValue("@VariantId",     it.VariantId);
                                cmd.Parameters.AddWithValue("@MarketplaceId", marketplaceId.HasValue ? (object)marketplaceId.Value : DBNull.Value);
                                cmd.Parameters.AddWithValue("@Quantity",      it.Quantity);
                                cmd.ExecuteNonQuery();
                            }
                        }
                    }
                }

                return JsonConvert.SerializeObject(new { success = true, message = "Sale updated successfully." });
            }
            catch (Exception ex)
            {
                return Fail("Error: " + ex.Message);
            }
        }

        // ============================================================
        // LOOKUP VARIANT BY SKU
        // ============================================================
        [WebMethod]
        public static string GetVariantBySKU(string sku)
        {
            if (string.IsNullOrWhiteSpace(sku))
                return "null";

            using (var conn = GetConnection())
            {
                conn.Open();
                const string sql = @"
                    SELECT TOP 1
                           pv.VariantId, pv.Color, pv.Size, pv.StockQuantity,
                           p.ProductName, p.ProductCode, p.SalePrice
                    FROM   ProductVariants pv
                    INNER JOIN Products p ON p.ProductId = pv.ProductId
                    WHERE  EXISTS (
                               SELECT 1 FROM STRING_SPLIT(pv.SKUNumbers, ',') AS ss
                               WHERE LTRIM(RTRIM(ss.value)) = @SKU
                           )
                      AND  pv.IsActive   = 1
                      AND  p.IsActive    = 1";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@SKU", sku.Trim());
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            return JsonConvert.SerializeObject(new
                            {
                                VariantId   = Convert.ToInt32(rdr["VariantId"]),
                                ProductName = rdr["ProductName"].ToString(),
                                ProductCode = rdr["ProductCode"].ToString(),
                                Color       = rdr["Color"].ToString(),
                                Size        = rdr["Size"].ToString(),
                                SalePrice   = SafeDec(rdr, "SalePrice"),
                                StockQty    = Convert.ToInt32(rdr["StockQuantity"])
                            });
                        }
                    }
                }
            }
            return "null";
        }

        // ============================================================
        // SAVE SALE  (insert + deduct stock)
        // ============================================================
        [WebMethod]
        public static string SaveSale(SaleModel sale, string itemsJson, string customersJson = "", string bolFileName = "", string trackingNo = "")
        {
            try
            {
                if (sale == null)
                    return Fail("Invalid data.");
                if (string.IsNullOrWhiteSpace(sale.BillNumber))
                    return Fail("Bill Number is required.");
                if (string.IsNullOrWhiteSpace(sale.Platform))
                    return Fail("Platform is required.");
                if (string.IsNullOrWhiteSpace(sale.SaleDate))
                    return Fail("Sale Date is required.");

                var items = JsonConvert.DeserializeObject<List<SaleItemModel>>(itemsJson ?? "[]")
                            ?? new List<SaleItemModel>();
                if (items.Count == 0)
                    return Fail("Add at least one item.");

                // Totals
                int     totalQty    = 0;
                decimal totalAmount = 0;
                foreach (var it in items)
                {
                    totalQty    += it.Quantity;
                    totalAmount += it.Quantity * it.SalePrice;
                }

                int saleId = 0;

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Duplicate bill check
                    using (var chk = new SqlCommand(
                        "SELECT COUNT(1) FROM Sales WHERE BillNumber = @BN AND Platform = @PL", conn))
                    {
                        chk.Parameters.AddWithValue("@BN", sale.BillNumber.Trim());
                        chk.Parameters.AddWithValue("@PL", sale.Platform);
                        if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                            return Fail("Bill Number '" + sale.BillNumber + "' already exists for " + sale.Platform + ".");
                    }

                    // Compute status from items, then insert Sale header
                    int saveFulfilled = items.Count(it => it.IsFulfilled ?? true);
                    string saveStatus = saveFulfilled == items.Count ? "Completed"
                                      : saveFulfilled == 0 ? "Unfulfilled"
                                      : "Partial";

                    const string insertSale = @"
                        INSERT INTO Sales (BillNumber, Platform, SaleDate, TotalQty, TotalAmount, Status, Notes, SaleSource, CourierId, BOLFile, TrackingNo, OrderRef)
                        OUTPUT INSERTED.SaleId
                        VALUES (@BillNumber, @Platform, @SaleDate, @TotalQty, @TotalAmount, @Status, @Notes, @SaleSource, @CourierId, @BOLFile, @TrackingNo, @OrderRef)";

                    using (var cmd = new SqlCommand(insertSale, conn))
                    {
                        cmd.Parameters.AddWithValue("@BillNumber",  sale.BillNumber.Trim());
                        cmd.Parameters.AddWithValue("@Platform",    sale.Platform);
                        cmd.Parameters.AddWithValue("@SaleDate",    DateTime.Parse(sale.SaleDate));
                        cmd.Parameters.AddWithValue("@TotalQty",    totalQty);
                        cmd.Parameters.AddWithValue("@TotalAmount", totalAmount);
                        cmd.Parameters.AddWithValue("@Status",      saveStatus);
                        cmd.Parameters.AddWithValue("@Notes",       (object)(sale.Notes?.Trim())   ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@SaleSource",  string.IsNullOrWhiteSpace(sale.SaleSource) ? "Manual" : sale.SaleSource.Trim());
                        cmd.Parameters.AddWithValue("@CourierId",   sale.CourierId.HasValue ? (object)sale.CourierId.Value : DBNull.Value);
                        cmd.Parameters.AddWithValue("@BOLFile",     string.IsNullOrWhiteSpace(bolFileName)   ? (object)DBNull.Value : bolFileName.Trim());
                        cmd.Parameters.AddWithValue("@TrackingNo",  string.IsNullOrWhiteSpace(trackingNo)    ? (object)DBNull.Value : trackingNo.Trim());
                        cmd.Parameters.AddWithValue("@OrderRef",    string.IsNullOrWhiteSpace(sale.OrderRef) ? (object)DBNull.Value : sale.OrderRef.Trim());
                        saleId = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    // Resolve marketplace ID from platform name
                    int? marketplaceId = null;
                    using (var cmd = new SqlCommand(
                        "SELECT TOP 1 MarketplaceId FROM Marketplaces WHERE MarketplaceName = @P AND IsActive = 1", conn))
                    {
                        cmd.Parameters.AddWithValue("@P", sale.Platform);
                        var r = cmd.ExecuteScalar();
                        if (r != null) marketplaceId = Convert.ToInt32(r);
                    }

                    // Insert items + deduct stock
                    foreach (var it in items)
                    {
                        decimal lineTotal = it.Quantity * it.SalePrice;

                        const string insertItem = @"
                            INSERT INTO SaleItems
                                (SaleId, VariantId, SKUNumber, ProductName, Color, Size, Quantity, SalePrice, TotalAmount, IsFulfilled)
                            VALUES
                                (@SaleId, @VariantId, @SKUNumber, @ProductName, @Color, @Size, @Quantity, @SalePrice, @TotalAmount, @IsFulfilled)";

                        using (var cmd = new SqlCommand(insertItem, conn))
                        {
                            cmd.Parameters.AddWithValue("@SaleId",      saleId);
                            cmd.Parameters.AddWithValue("@VariantId",   it.VariantId > 0 ? (object)it.VariantId : DBNull.Value);
                            cmd.Parameters.AddWithValue("@SKUNumber",   it.SKUNumber  ?? "");
                            cmd.Parameters.AddWithValue("@ProductName", (object)(it.ProductName) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Color",       (object)(it.Color)       ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Size",        (object)(it.Size)        ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Quantity",    it.Quantity);
                            cmd.Parameters.AddWithValue("@SalePrice",   it.SalePrice);
                            cmd.Parameters.AddWithValue("@TotalAmount", lineTotal);
                            cmd.Parameters.AddWithValue("@IsFulfilled", it.IsFulfilled ?? true);
                            cmd.ExecuteNonQuery();
                        }

                        if (it.VariantId > 0 && (it.IsFulfilled ?? true))
                        {
                            int saleItemId = 0;

                            // Get the SaleItemId just inserted
                            using (var cmd = new SqlCommand(
                                "SELECT TOP 1 SaleItemId FROM SaleItems WHERE SaleId=@S AND VariantId=@V ORDER BY SaleItemId DESC", conn))
                            {
                                cmd.Parameters.AddWithValue("@S", saleId);
                                cmd.Parameters.AddWithValue("@V", it.VariantId);
                                var r = cmd.ExecuteScalar();
                                if (r != null) saleItemId = Convert.ToInt32(r);
                            }

                            if (marketplaceId.HasValue)
                            {
                                // Deduct from marketplace inventory
                                using (var cmd = new SqlCommand(@"
                                    UPDATE MarketplaceInventory
                                    SET    StockQuantity = StockQuantity - @qty
                                    WHERE  VariantId = @vid AND MarketplaceId = @mid
                                      AND  StockQuantity >= @qty", conn))
                                {
                                    cmd.Parameters.AddWithValue("@qty", it.Quantity);
                                    cmd.Parameters.AddWithValue("@vid", it.VariantId);
                                    cmd.Parameters.AddWithValue("@mid", marketplaceId.Value);
                                    cmd.ExecuteNonQuery();
                                }
                            }
                            else
                            {
                                // Fallback: deduct from warehouse
                                using (var cmd = new SqlCommand(@"
                                    UPDATE ProductVariants
                                    SET    StockQuantity = StockQuantity - @qty
                                    WHERE  VariantId = @vid AND StockQuantity >= @qty", conn))
                                {
                                    cmd.Parameters.AddWithValue("@qty", it.Quantity);
                                    cmd.Parameters.AddWithValue("@vid", it.VariantId);
                                    cmd.ExecuteNonQuery();
                                }
                            }

                            // Record the deduction in SaleStockDeductions
                            using (var cmd = new SqlCommand(@"
                                INSERT INTO SaleStockDeductions
                                    (SaleId, SaleItemId, VariantId, MarketplaceId, Quantity)
                                VALUES
                                    (@SaleId, @SaleItemId, @VariantId, @MarketplaceId, @Quantity)", conn))
                            {
                                cmd.Parameters.AddWithValue("@SaleId",        saleId);
                                cmd.Parameters.AddWithValue("@SaleItemId",    saleItemId > 0 ? (object)saleItemId : DBNull.Value);
                                cmd.Parameters.AddWithValue("@VariantId",     it.VariantId);
                                cmd.Parameters.AddWithValue("@MarketplaceId", marketplaceId.HasValue ? (object)marketplaceId.Value : DBNull.Value);
                                cmd.Parameters.AddWithValue("@Quantity",      it.Quantity);
                                cmd.ExecuteNonQuery();
                            }
                        }
                    }
                }

                // Save customer and link to sale
                if (!string.IsNullOrWhiteSpace(sale.CustPhone))
                {
                    string phone = NormalizePhone(sale.CustPhone);
                    int custId = 0;

                    using (var conn2 = GetConnection())
                    {
                        conn2.Open();
                        using (var cmd = new SqlCommand("SELECT CustomerId FROM Customers WHERE Phone = @P", conn2))
                        {
                            cmd.Parameters.AddWithValue("@P", phone);
                            var r = cmd.ExecuteScalar();
                            if (r != null) custId = Convert.ToInt32(r);
                        }

                        if (custId == 0)
                        {
                            using (var cmd = new SqlCommand(@"
                                INSERT INTO Customers (Name, Phone, Designation, Address)
                                OUTPUT INSERTED.CustomerId
                                VALUES (@N, @P, @D, @A)", conn2))
                            {
                                cmd.Parameters.AddWithValue("@N", sale.CustName?.Trim() ?? "");
                                cmd.Parameters.AddWithValue("@P", phone);
                                cmd.Parameters.AddWithValue("@D", (object)(sale.CustDesignation?.Trim()) ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@A", (object)(sale.CustAddress?.Trim())     ?? DBNull.Value);
                                custId = Convert.ToInt32(cmd.ExecuteScalar());
                            }
                        }
                        else
                        {
                            using (var cmd = new SqlCommand(@"
                                UPDATE Customers SET Name=@N, Designation=@D, Address=@A, UpdatedDate=GETDATE()
                                WHERE CustomerId=@Id", conn2))
                            {
                                cmd.Parameters.AddWithValue("@N",  sale.CustName?.Trim() ?? "");
                                cmd.Parameters.AddWithValue("@D",  (object)(sale.CustDesignation?.Trim()) ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@A",  (object)(sale.CustAddress?.Trim())     ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@Id", custId);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        using (var cmd = new SqlCommand("UPDATE Sales SET CustomerId=@C WHERE SaleId=@S", conn2))
                        {
                            cmd.Parameters.AddWithValue("@C", custId);
                            cmd.Parameters.AddWithValue("@S", saleId);
                            cmd.ExecuteNonQuery();
                        }
                    }
                }

                // Save all BOL customers (bulk — upsert by phone) and link first to Sale.CustomerId
                if (!string.IsNullOrWhiteSpace(customersJson))
                {
                    var bolCustomers = JsonConvert.DeserializeObject<List<CustomerRecord>>(customersJson)
                                       ?? new List<CustomerRecord>();
                    using (var cc = GetConnection())
                    {
                        cc.Open();
                        int firstCustomerId = 0;

                        foreach (var c in bolCustomers)
                        {
                            if (string.IsNullOrWhiteSpace(c.Phone)) continue;
                            string ph = NormalizePhone(c.Phone);

                            int existId = 0;
                            using (var chk = new SqlCommand("SELECT CustomerId FROM Customers WHERE Phone=@P", cc))
                            {
                                chk.Parameters.AddWithValue("@P", ph);
                                var r = chk.ExecuteScalar();
                                if (r != null) existId = Convert.ToInt32(r);
                            }

                            int savedId = 0;
                            if (existId == 0)
                            {
                                using (var ins = new SqlCommand(@"
                                    INSERT INTO Customers (Name, Phone, Destination, Address, BuyingCount)
                                    OUTPUT INSERTED.CustomerId
                                    VALUES (@N, @P, @Dest, @A, 1)", cc))
                                {
                                    ins.Parameters.AddWithValue("@N",    c.Name?.Trim()                 ?? "");
                                    ins.Parameters.AddWithValue("@P",    ph);
                                    ins.Parameters.AddWithValue("@Dest", (object)(c.Destination?.Trim()) ?? DBNull.Value);
                                    ins.Parameters.AddWithValue("@A",    (object)(c.Address?.Trim())     ?? DBNull.Value);
                                    savedId = Convert.ToInt32(ins.ExecuteScalar());
                                }
                            }
                            else
                            {
                                using (var upd = new SqlCommand(@"
                                    UPDATE Customers
                                    SET    Name        = @N,
                                           Destination = @Dest,
                                           Address     = @A,
                                           BuyingCount = BuyingCount + 1,
                                           UpdatedDate = GETDATE()
                                    WHERE  CustomerId  = @Id", cc))
                                {
                                    upd.Parameters.AddWithValue("@N",    c.Name?.Trim()                 ?? "");
                                    upd.Parameters.AddWithValue("@Dest", (object)(c.Destination?.Trim()) ?? DBNull.Value);
                                    upd.Parameters.AddWithValue("@A",    (object)(c.Address?.Trim())     ?? DBNull.Value);
                                    upd.Parameters.AddWithValue("@Id",   existId);
                                    upd.ExecuteNonQuery();
                                    savedId = existId;
                                }
                            }

                            if (firstCustomerId == 0 && savedId > 0)
                                firstCustomerId = savedId;
                        }

                        // Link the first BOL customer to the sale (only if not already linked)
                        if (firstCustomerId > 0)
                        {
                            using (var upd = new SqlCommand(
                                "UPDATE Sales SET CustomerId=@C WHERE SaleId=@S AND CustomerId IS NULL", cc))
                            {
                                upd.Parameters.AddWithValue("@C", firstCustomerId);
                                upd.Parameters.AddWithValue("@S", saleId);
                                upd.ExecuteNonQuery();
                            }
                        }
                    }
                }

                return JsonConvert.SerializeObject(new { success = true, message = "Sale saved successfully." });
            }
            catch (Exception ex)
            {
                return Fail("Error: " + ex.Message);
            }
        }

        // ============================================================
        // SAVE BOL SALES  (one Sale per OrderRef group)
        // ============================================================
        [WebMethod]
        public static string SaveBOLSales(
            string platform, string saleDate, int? courierId,
            string baseBillNumber, string groupsJson, string customersJson, string bolFileName,
            string saleSource = "BOL", string notes = null)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(platform)) return Fail("Platform is required.");
                if (string.IsNullOrWhiteSpace(saleDate))  return Fail("Sale Date is required.");

                var groups = JsonConvert.DeserializeObject<List<BolSaleGroup>>(groupsJson ?? "[]")
                             ?? new List<BolSaleGroup>();
                groups = groups.Where(g => g.Items != null && g.Items.Count > 0).ToList();
                if (groups.Count == 0) return Fail("No items to save.");

                var customers = JsonConvert.DeserializeObject<List<CustomerRecord>>(customersJson ?? "[]")
                                ?? new List<CustomerRecord>();
                var custByOrderRef = new Dictionary<string, CustomerRecord>(StringComparer.OrdinalIgnoreCase);
                foreach (var c in customers)
                    if (!string.IsNullOrWhiteSpace(c.OrderRef) && !custByOrderRef.ContainsKey(c.OrderRef))
                        custByOrderRef[c.OrderRef] = c;

                var saleDateParsed = DateTime.Parse(saleDate);
                bool multiGroup    = groups.Count > 1;

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Resolve marketplace ID from platform name once
                    int? marketplaceId = null;
                    using (var cmd = new SqlCommand(
                        "SELECT TOP 1 MarketplaceId FROM Marketplaces WHERE MarketplaceName = @P AND IsActive = 1", conn))
                    {
                        cmd.Parameters.AddWithValue("@P", platform);
                        var r = cmd.ExecuteScalar();
                        if (r != null) marketplaceId = Convert.ToInt32(r);
                    }

                    // Count existing sales on this date for sequential bill numbers (multi-group)
                    int existingCount = 0;
                    if (multiGroup)
                    {
                        using (var cmd = new SqlCommand(
                            "SELECT COUNT(*) FROM Sales WHERE CAST(SaleDate AS DATE) = @D", conn))
                        {
                            cmd.Parameters.AddWithValue("@D", saleDateParsed.Date);
                            existingCount = Convert.ToInt32(cmd.ExecuteScalar());
                        }
                    }

                    // Reject if any OrderRef from this BOL already exists in Sales
                    foreach (var grp in groups)
                    {
                        if (string.IsNullOrWhiteSpace(grp.OrderRef)) continue;
                        using (var chk = new SqlCommand(
                            "SELECT COUNT(1) FROM Sales WHERE OrderRef = @OR", conn))
                        {
                            chk.Parameters.AddWithValue("@OR", grp.OrderRef.Trim());
                            if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                                return Fail("Order ID '" + grp.OrderRef.Trim() + "' already exists. This BOL may have already been uploaded.");
                        }
                    }

                    // Reject if any TrackingNo from this BOL already exists in Sales
                    foreach (var grp in groups)
                    {
                        if (string.IsNullOrWhiteSpace(grp.TrackingNo)) continue;
                        using (var chk = new SqlCommand(
                            "SELECT COUNT(1) FROM Sales WHERE TrackingNo = @TN", conn))
                        {
                            chk.Parameters.AddWithValue("@TN", grp.TrackingNo.Trim());
                            if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                                return Fail("Tracking No '" + grp.TrackingNo.Trim() + "' already exists. This BOL may have already been uploaded.");
                        }
                    }

                    int groupIndex = 0;
                    foreach (var grp in groups)
                    {
                        // Determine bill number
                        string billNo;
                        if (!multiGroup)
                        {
                            billNo = string.IsNullOrWhiteSpace(baseBillNumber)
                                ? saleDate + " - (01)"
                                : baseBillNumber.Trim();
                        }
                        else
                        {
                            int seq = existingCount + groupIndex + 1;
                            billNo = saleDate + " - (" + seq.ToString("D2") + ")";
                            while (true)
                            {
                                using (var chk = new SqlCommand(
                                    "SELECT COUNT(1) FROM Sales WHERE BillNumber = @BN AND Platform = @PL", conn))
                                {
                                    chk.Parameters.AddWithValue("@BN", billNo);
                                    chk.Parameters.AddWithValue("@PL", platform);
                                    if (Convert.ToInt32(chk.ExecuteScalar()) == 0) break;
                                }
                                seq++;
                                billNo = saleDate + " - (" + seq.ToString("D2") + ")";
                            }
                            existingCount = seq - 1;
                        }

                        // Compute totals and fulfillment status
                        int     totalQty    = 0;
                        decimal totalAmount = 0;
                        foreach (var it in grp.Items) { totalQty += it.Quantity; totalAmount += it.Quantity * it.SalePrice; }
                        int grpFulfilled = grp.Items.Count(it => it.IsFulfilled ?? true);
                        string grpStatus = grpFulfilled == grp.Items.Count ? "Completed"
                                         : grpFulfilled == 0 ? "Unfulfilled"
                                         : "Partial";

                        // Insert Sale header
                        const string insertSale = @"
                            INSERT INTO Sales (BillNumber, Platform, SaleDate, TotalQty, TotalAmount, Status, Notes, SaleSource, CourierId, BOLFile, TrackingNo, OrderRef)
                            OUTPUT INSERTED.SaleId
                            VALUES (@BillNumber, @Platform, @SaleDate, @TotalQty, @TotalAmount, @Status, @Notes, @SaleSource, @CourierId, @BOLFile, @TrackingNo, @OrderRef)";

                        int saleId;
                        using (var cmd = new SqlCommand(insertSale, conn))
                        {
                            cmd.Parameters.AddWithValue("@BillNumber",  billNo);
                            cmd.Parameters.AddWithValue("@Platform",    platform);
                            cmd.Parameters.AddWithValue("@SaleDate",    saleDateParsed);
                            cmd.Parameters.AddWithValue("@TotalQty",    totalQty);
                            cmd.Parameters.AddWithValue("@TotalAmount", totalAmount);
                            cmd.Parameters.AddWithValue("@Status",      grpStatus);
                            cmd.Parameters.AddWithValue("@Notes",       string.IsNullOrWhiteSpace(notes)             ? (object)DBNull.Value : notes.Trim());
                            cmd.Parameters.AddWithValue("@SaleSource",  string.IsNullOrWhiteSpace(saleSource)        ? "Manual" : saleSource.Trim());
                            cmd.Parameters.AddWithValue("@CourierId",   courierId.HasValue ? (object)courierId.Value : DBNull.Value);
                            cmd.Parameters.AddWithValue("@BOLFile",     string.IsNullOrWhiteSpace(bolFileName)       ? (object)DBNull.Value : bolFileName.Trim());
                            cmd.Parameters.AddWithValue("@TrackingNo",  string.IsNullOrWhiteSpace(grp.TrackingNo)    ? (object)DBNull.Value : grp.TrackingNo.Trim());
                            cmd.Parameters.AddWithValue("@OrderRef",    string.IsNullOrWhiteSpace(grp.OrderRef)      ? (object)DBNull.Value : grp.OrderRef.Trim());
                            saleId = Convert.ToInt32(cmd.ExecuteScalar());
                        }

                        // Insert SaleItems + deduct stock
                        foreach (var it in grp.Items)
                        {
                            decimal lineTotal = it.Quantity * it.SalePrice;

                            const string insertItem = @"
                                INSERT INTO SaleItems
                                    (SaleId, VariantId, SKUNumber, ProductName, Color, Size, Quantity, SalePrice, TotalAmount, IsFulfilled)
                                OUTPUT INSERTED.SaleItemId
                                VALUES
                                    (@SaleId, @VariantId, @SKUNumber, @ProductName, @Color, @Size, @Quantity, @SalePrice, @TotalAmount, @IsFulfilled)";

                            int saleItemId;
                            using (var cmd = new SqlCommand(insertItem, conn))
                            {
                                cmd.Parameters.AddWithValue("@SaleId",      saleId);
                                cmd.Parameters.AddWithValue("@VariantId",   it.VariantId > 0 ? (object)it.VariantId : DBNull.Value);
                                cmd.Parameters.AddWithValue("@SKUNumber",   it.SKUNumber  ?? "");
                                cmd.Parameters.AddWithValue("@ProductName", (object)(it.ProductName) ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@Color",       (object)(it.Color)       ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@Size",        (object)(it.Size)        ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@Quantity",    it.Quantity);
                                cmd.Parameters.AddWithValue("@SalePrice",   it.SalePrice);
                                cmd.Parameters.AddWithValue("@TotalAmount", lineTotal);
                                cmd.Parameters.AddWithValue("@IsFulfilled", it.IsFulfilled ?? true);
                                saleItemId = Convert.ToInt32(cmd.ExecuteScalar());
                            }

                            if (it.VariantId > 0 && (it.IsFulfilled ?? true))
                            {
                                if (marketplaceId.HasValue)
                                {
                                    using (var cmd = new SqlCommand(@"
                                        UPDATE MarketplaceInventory
                                        SET    StockQuantity = StockQuantity - @qty
                                        WHERE  VariantId = @vid AND MarketplaceId = @mid
                                          AND  StockQuantity >= @qty", conn))
                                    {
                                        cmd.Parameters.AddWithValue("@qty", it.Quantity);
                                        cmd.Parameters.AddWithValue("@vid", it.VariantId);
                                        cmd.Parameters.AddWithValue("@mid", marketplaceId.Value);
                                        cmd.ExecuteNonQuery();
                                    }
                                }
                                else
                                {
                                    using (var cmd = new SqlCommand(@"
                                        UPDATE ProductVariants
                                        SET    StockQuantity = StockQuantity - @qty
                                        WHERE  VariantId = @vid AND StockQuantity >= @qty", conn))
                                    {
                                        cmd.Parameters.AddWithValue("@qty", it.Quantity);
                                        cmd.Parameters.AddWithValue("@vid", it.VariantId);
                                        cmd.ExecuteNonQuery();
                                    }
                                }

                                using (var cmd = new SqlCommand(@"
                                    INSERT INTO SaleStockDeductions
                                        (SaleId, SaleItemId, VariantId, MarketplaceId, Quantity)
                                    VALUES (@SaleId, @SaleItemId, @VariantId, @MarketplaceId, @Quantity)", conn))
                                {
                                    cmd.Parameters.AddWithValue("@SaleId",        saleId);
                                    cmd.Parameters.AddWithValue("@SaleItemId",    saleItemId > 0 ? (object)saleItemId : DBNull.Value);
                                    cmd.Parameters.AddWithValue("@VariantId",     it.VariantId);
                                    cmd.Parameters.AddWithValue("@MarketplaceId", marketplaceId.HasValue ? (object)marketplaceId.Value : DBNull.Value);
                                    cmd.Parameters.AddWithValue("@Quantity",      it.Quantity);
                                    cmd.ExecuteNonQuery();
                                }
                            }
                        }

                        // Upsert customer and link to sale
                        if (custByOrderRef.TryGetValue(grp.OrderRef ?? "", out CustomerRecord matchedCust)
                            && !string.IsNullOrWhiteSpace(matchedCust.Phone))
                        {
                            string normPhone = NormalizePhone(matchedCust.Phone);
                            int savedCustId  = 0;

                            int existId = 0;
                            using (var cmd = new SqlCommand(
                                "SELECT TOP 1 CustomerId FROM Customers WHERE Phone = @Ph", conn))
                            {
                                cmd.Parameters.AddWithValue("@Ph", normPhone);
                                var r = cmd.ExecuteScalar();
                                if (r != null) existId = Convert.ToInt32(r);
                            }

                            if (existId == 0)
                            {
                                using (var ins = new SqlCommand(@"
                                    INSERT INTO Customers (Name, Phone, Destination, Address)
                                    OUTPUT INSERTED.CustomerId
                                    VALUES (@N, @Ph, @Dest, @A)", conn))
                                {
                                    ins.Parameters.AddWithValue("@N",    matchedCust.Name?.Trim()              ?? "");
                                    ins.Parameters.AddWithValue("@Ph",   normPhone);
                                    ins.Parameters.AddWithValue("@Dest", (object)(matchedCust.Destination?.Trim()) ?? DBNull.Value);
                                    ins.Parameters.AddWithValue("@A",    (object)(matchedCust.Address?.Trim())     ?? DBNull.Value);
                                    savedCustId = Convert.ToInt32(ins.ExecuteScalar());
                                }
                            }
                            else
                            {
                                using (var upd = new SqlCommand(@"
                                    UPDATE Customers
                                    SET    Name = @N, Destination = @Dest, Address = @A, UpdatedDate = GETDATE()
                                    WHERE  CustomerId = @Id", conn))
                                {
                                    upd.Parameters.AddWithValue("@N",    matchedCust.Name?.Trim()              ?? "");
                                    upd.Parameters.AddWithValue("@Dest", (object)(matchedCust.Destination?.Trim()) ?? DBNull.Value);
                                    upd.Parameters.AddWithValue("@A",    (object)(matchedCust.Address?.Trim())     ?? DBNull.Value);
                                    upd.Parameters.AddWithValue("@Id",   existId);
                                    upd.ExecuteNonQuery();
                                    savedCustId = existId;
                                }
                            }

                            if (savedCustId > 0)
                            {
                                using (var upd = new SqlCommand(
                                    "UPDATE Sales SET CustomerId=@C WHERE SaleId=@S AND CustomerId IS NULL", conn))
                                {
                                    upd.Parameters.AddWithValue("@C", savedCustId);
                                    upd.Parameters.AddWithValue("@S", saleId);
                                    upd.ExecuteNonQuery();
                                }
                            }
                        }

                        groupIndex++;
                    }
                }

                return JsonConvert.SerializeObject(new { success = true, message = "BOL sales saved successfully." });
            }
            catch (Exception ex)
            {
                return Fail("Error: " + ex.Message);
            }
        }

        // ============================================================
        // CANCEL SALE  (restore stock)
        // ============================================================
        [WebMethod]
        public static string CancelSale(int saleId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Restore stock using SaleStockDeductions records
                    var deductions = new List<(int VariantId, int? MarketplaceId, int Quantity, int DeductionId)>();
                    using (var cmd = new SqlCommand(
                        "SELECT DeductionId, VariantId, MarketplaceId, Quantity FROM SaleStockDeductions WHERE SaleId = @Id AND IsRestored = 0", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", saleId);
                        using (var rdr = cmd.ExecuteReader())
                        {
                            while (rdr.Read())
                            {
                                int?  mid = rdr.IsDBNull(rdr.GetOrdinal("MarketplaceId")) ? (int?)null : Convert.ToInt32(rdr["MarketplaceId"]);
                                deductions.Add((
                                    Convert.ToInt32(rdr["VariantId"]),
                                    mid,
                                    Convert.ToInt32(rdr["Quantity"]),
                                    Convert.ToInt32(rdr["DeductionId"])
                                ));
                            }
                        }
                    }

                    foreach (var d in deductions)
                    {
                        if (d.MarketplaceId.HasValue)
                        {
                            using (var cmd = new SqlCommand(@"
                                UPDATE MarketplaceInventory
                                SET    StockQuantity = StockQuantity + @qty
                                WHERE  VariantId = @vid AND MarketplaceId = @mid", conn))
                            {
                                cmd.Parameters.AddWithValue("@qty", d.Quantity);
                                cmd.Parameters.AddWithValue("@vid", d.VariantId);
                                cmd.Parameters.AddWithValue("@mid", d.MarketplaceId.Value);
                                cmd.ExecuteNonQuery();
                            }
                        }
                        else
                        {
                            using (var cmd = new SqlCommand(@"
                                UPDATE ProductVariants
                                SET    StockQuantity = StockQuantity + @qty
                                WHERE  VariantId = @vid", conn))
                            {
                                cmd.Parameters.AddWithValue("@qty", d.Quantity);
                                cmd.Parameters.AddWithValue("@vid", d.VariantId);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        // Mark deduction as restored
                        using (var cmd = new SqlCommand(
                            "UPDATE SaleStockDeductions SET IsRestored = 1, RestoredDate = GETDATE() WHERE DeductionId = @Id", conn))
                        {
                            cmd.Parameters.AddWithValue("@Id", d.DeductionId);
                            cmd.ExecuteNonQuery();
                        }
                    }

                    // Mark sale as Cancelled
                    using (var cmd = new SqlCommand(
                        "UPDATE Sales SET Status = 'Cancelled', UpdatedDate = GETDATE() WHERE SaleId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", saleId);
                        cmd.ExecuteNonQuery();
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Sale cancelled and stock restored." });
            }
            catch (Exception ex)
            {
                return Fail("Error: " + ex.Message);
            }
        }

        // ============================================================
        // NEXT BILL NUMBER  →  2026-05-02-01, -02, -03 …
        // ============================================================
        [WebMethod]
        public static string GetNextBillNumber(string saleDate)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(
                        "SELECT COUNT(*) FROM Sales WHERE CAST(SaleDate AS DATE) = @D", conn))
                    {
                        cmd.Parameters.AddWithValue("@D", DateTime.Parse(saleDate).Date);
                        int count  = Convert.ToInt32(cmd.ExecuteScalar());
                        string seq = (count + 1).ToString("D2");
                        return JsonConvert.SerializeObject(saleDate + " - (" + seq + ")");
                    }
                }
            }
            catch
            {
                return JsonConvert.SerializeObject(saleDate + " - (01)");
            }
        }

        // ============================================================
        // CUSTOMER — lookup by phone (auto-fill form)
        // ============================================================
        [WebMethod]
        public static string GetCustomerByPhone(string phone)
        {
            if (string.IsNullOrWhiteSpace(phone)) return "null";
            phone = NormalizePhone(phone.Trim());
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT Name, Designation, Address FROM Customers WHERE Phone = @P", conn))
                {
                    cmd.Parameters.AddWithValue("@P", phone);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                            return JsonConvert.SerializeObject(new
                            {
                                Name        = SafeStr(rdr, "Name"),
                                Designation = SafeStr(rdr, "Designation"),
                                Address     = SafeStr(rdr, "Address")
                            });
                    }
                }
            }
            return "null";
        }

        // ============================================================
        // CUSTOMER — get by sale id (for customer detail modal)
        // ============================================================
        [WebMethod]
        public static string GetCustomerBySaleId(int saleId)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                const string sql = @"
                    SELECT c.CustomerId, c.Name, c.Phone, c.Designation, c.Address, c.CreatedDate
                    FROM   Customers c
                    INNER JOIN Sales s ON s.CustomerId = c.CustomerId
                    WHERE  s.SaleId = @SaleId";
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@SaleId", saleId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                            return JsonConvert.SerializeObject(new
                            {
                                CustomerId  = Convert.ToInt32(rdr["CustomerId"]),
                                Name        = SafeStr(rdr, "Name"),
                                Phone       = SafeStr(rdr, "Phone"),
                                Designation = SafeStr(rdr, "Designation"),
                                Address     = SafeStr(rdr, "Address"),
                                Since       = Convert.ToDateTime(rdr["CreatedDate"]).ToString("dd-MMM-yyyy")
                            });
                    }
                }
            }
            return "null";
        }

        // ============================================================
        // PHONE NORMALIZER  →  +923132329672
        // ============================================================
        private static string NormalizePhone(string phone)
        {
            phone = Regex.Replace(phone, @"[\s\-\(\)]", "");
            if (phone.StartsWith("0") && phone.Length >= 10)
                phone = "+92" + phone.Substring(1);
            else if (!phone.StartsWith("+"))
                phone = "+92" + phone;
            return phone;
        }

        // ============================================================
        // PARSE BILL OF LADING TEXT  (PostEx format)
        // Called after PDF.js extracts text client-side
        // ============================================================
        private class VariantLookupResult
        {
            public int     VariantId   { get; set; }
            public string  SKUNumber   { get; set; }
            public string  ProductName { get; set; }
            public string  Color       { get; set; }
            public string  Size        { get; set; }
            public decimal SalePrice   { get; set; }
            public bool    Matched     { get; set; }
        }

        public class CustomerRecord
        {
            public string OrderRef    { get; set; }
            public string Name        { get; set; }
            public string Phone       { get; set; }
            public string Destination { get; set; }
            public string Address     { get; set; }
        }

        [WebMethod]
        public static string ParseBOLText(string bolText)
        {
            try
            {
                var extracted = new List<object>();
                var customers = new List<object>();

                var pages = bolText.Split(new[] { "---PAGE---" }, StringSplitOptions.RemoveEmptyEntries);

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // ── Step 1: Pre-load ALL active variant SKUs into memory (one query) ──
                    // skuMap   : trimmed-SKU → variant  (exact lookup, O(1))
                    // skuEntries: flat list of (sku, variant) pairs for LIKE-pattern fallback
                    var skuMap     = new Dictionary<string, VariantLookupResult>(StringComparer.OrdinalIgnoreCase);
                    var skuEntries = new List<(string Sku, VariantLookupResult Variant)>();

                    using (var cmd = new SqlCommand(@"
                        SELECT pv.VariantId, pv.SKUNumbers, pv.Color, pv.Size,
                               p.ProductName, p.ProductCode, p.SalePrice
                        FROM   ProductVariants pv
                        INNER  JOIN Products p ON p.ProductId = pv.ProductId
                        WHERE  pv.IsActive = 1 AND p.IsActive = 1", conn))
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            var vr = new VariantLookupResult
                            {
                                VariantId   = Convert.ToInt32(rdr["VariantId"]),
                                SKUNumber   = SafeStr(rdr, "SKUNumbers"),
                                ProductName = SafeStr(rdr, "ProductName"),
                                Color       = SafeStr(rdr, "Color"),
                                Size        = SafeStr(rdr, "Size"),
                                SalePrice   = SafeDec(rdr, "SalePrice"),
                                Matched     = true
                            };
                            // Split comma-separated SKUs and index each one by both
                            // the raw trimmed value AND its normalized form, so BOL
                            // descriptions stored with spaces ("Flat - 033 - Black - Size - 38")
                            // match the normalized lookup key ("Flat-033-Black-38").
                            foreach (var raw in vr.SKUNumber.Split(','))
                            {
                                string sku = raw.Trim();
                                if (string.IsNullOrEmpty(sku)) continue;
                                if (!skuMap.ContainsKey(sku)) skuMap[sku] = vr;
                                string normKey = NormalizeSKU(sku);
                                if (!skuMap.ContainsKey(normKey)) skuMap[normKey] = vr;
                                skuEntries.Add((sku, vr));
                            }
                        }
                    }

                    // ── Step 2: Process each BOL page ────────────────────────────────────
                    foreach (var page in pages)
                    {
                        // ── Order Reference ─────────────────────────────
                        // Anchor to "Order Reference" label first to avoid matching street numbers like "Street #3"
                        var orderMatch = Regex.Match(page, @"Order\s+Reference[:\s#]*(\d+)", RegexOptions.IgnoreCase);
                        if (!orderMatch.Success)
                            orderMatch = Regex.Match(page, @"#\s*(\d{4,})");   // fallback: 4+ digit ref
                        string orderRef = orderMatch.Success ? "#" + orderMatch.Groups[1].Value : "";

                        // ── Tracking Number ───────────────────────────────
                        // PostEx: all-digit 12+ chars (e.g. 25599760010021)
                        // Leopards: 1-3 uppercase letters + 9+ digits (e.g. KI7535710536)
                        var trackingM2 = Regex.Match(page, @"\b([A-Z]{1,3}\d{9,}|\d{12,})\b");
                        string trackingNo = trackingM2.Success ? trackingM2.Groups[1].Value : "";

                        // ── Customer / Consignee data ────────────────────
                        var nameM  = Regex.Match(page, @"Name:\s*(.+?)\s*(?:OMS)?\s*(?:Phone:|PostEx|$)", RegexOptions.IgnoreCase);
                        var phoneM = Regex.Match(page, @"Phone:\s*(\d[\d\s\-]{8,14})(?:\s|Scan|$)");
                        var addrM  = Regex.Match(page, @"Address:\s*(.+?)(?:Scan\s+for|\d{12,}|Destination:)", RegexOptions.Singleline | RegexOptions.IgnoreCase);
                        var destM  = Regex.Match(page, @"Destination:\s*([A-Za-z][A-Za-z\s]{1,40}?)(?=\s*(?:COD:|Date:|Service:|Pieces:|\d{5,}))", RegexOptions.IgnoreCase);
                        var codM   = Regex.Match(page, @"COD:\s*([\d.]+)");

                        string custName  = nameM.Success  ? Regex.Replace(nameM.Groups[1].Value.Trim(), @"\s*OMS\s*$", "", RegexOptions.IgnoreCase).Trim() : "";
                        string custPhone = phoneM.Success ? NormalizePhone(Regex.Replace(phoneM.Groups[1].Value, @"\s", "")) : "";
                        string custAddr  = addrM.Success  ? Regex.Replace(addrM.Groups[1].Value.Trim(), @"\s{2,}", " ") : "";
                        string custDest  = destM.Success  ? destM.Groups[1].Value.Trim() : "";

                        if (!string.IsNullOrWhiteSpace(custPhone))
                        {
                            customers.Add(new
                            {
                                OrderRef    = orderRef,
                                Name        = custName,
                                Phone       = custPhone,
                                Destination = custDest,
                                Address     = custAddr
                            });
                        }

                        // ── Products line ────────────────────────────────
                        var prodMatch = Regex.Match(page,
                            @"Products:\s*(.+?)(?:Shipper:|$)",
                            RegexOptions.Singleline | RegexOptions.IgnoreCase);
                        if (!prodMatch.Success) continue;

                        var productsText = prodMatch.Groups[1].Value;

                        var dateM   = Regex.Match(page, @"Date:\s*(\d{4}-\d{2}-\d{2})");
                        string saleDate = dateM.Success ? dateM.Groups[1].Value : DateTime.Today.ToString("yyyy-MM-dd");
                        decimal cod = codM.Success ? decimal.Parse(codM.Groups[1].Value) : 0;

                        // Capture: [Qty X ProductTitle (FullDesc)]
                        var itemMatches = Regex.Matches(productsText,
                            @"\[(\d+)\s+X\s+[^\(]+\(([^)]+)\)",
                            RegexOptions.IgnoreCase);

                        // Split COD equally across total units so each SKU gets its share
                        int totalItemQty = 0;
                        foreach (Match m0 in itemMatches)
                            totalItemQty += int.Parse(m0.Groups[1].Value.Trim());
                        decimal perUnitPrice = totalItemQty > 0 ? Math.Round(cod / totalItemQty, 2) : 0;

                        foreach (Match m in itemMatches)
                        {
                            int    qty      = int.Parse(m.Groups[1].Value.Trim());
                            string fullDesc = m.Groups[2].Value.Trim(); // e.g. "Flat - 056 - Peach - Size 39"

                            var codeM2 = Regex.Match(fullDesc, @"-\s*(\d+)\s*-");
                            var sizeM2 = Regex.Match(fullDesc, @"Size\s*-?\s*(\d+)", RegexOptions.IgnoreCase);
                            // Fallback: no "Size" keyword → take the last number at the end of the desc
                            // e.g. "Pumps - 059 - Black - 39" → 39
                            if (!sizeM2.Success)
                                sizeM2 = Regex.Match(fullDesc.TrimEnd(), @"-\s*(\d{2,3})\s*$");

                            string productCode = codeM2.Success ? codeM2.Groups[1].Value.Trim() : "";
                            string size        = sizeM2.Success ? sizeM2.Groups[1].Value.Trim() : "";

                            var v = new VariantLookupResult
                            {
                                VariantId   = 0,
                                SKUNumber   = fullDesc,
                                ProductName = "(" + fullDesc + ")",
                                Color       = "",
                                Size        = size,
                                SalePrice   = perUnitPrice,
                                Matched     = false
                            };

                            // Stage 0: normalize BOL desc → exact in-memory SKU lookup
                            // "Flat - 056 - Peach - Size 39"     → "Flat-056-Peach-39"
                            // "Flat - 048 - Marhoon - Size - 39" → "Flat-048-Marhoon-39"
                            var normSku = NormalizeSKU(fullDesc);

                            bool found = skuMap.TryGetValue(normSku, out var hit);

                            if (!found && !string.IsNullOrEmpty(productCode) && !string.IsNullOrEmpty(size))
                            {
                                var colorM = Regex.Match(fullDesc,
                                    @"-\s*\d+\s*-\s*([\w\s]+?)\s*-?\s*Size",
                                    RegexOptions.IgnoreCase);
                                string bolColor = colorM.Success ? colorM.Groups[1].Value.Trim() : "";

                                // Stage 1: Code + Color + Size  (e.g. 056-%-Peach-39)
                                if (!string.IsNullOrEmpty(bolColor))
                                {
                                    string p1 = productCode + "-%-" + bolColor + "-" + size;
                                    var e1 = skuEntries.Find(e => SqlLike(e.Sku, p1));
                                    if (e1.Variant != null) { hit = e1.Variant; found = true; }
                                }

                                // Stage 2 fallback: Code + Size only  (e.g. 056-%-39)
                                if (!found)
                                {
                                    string p2 = productCode + "-%-" + size;
                                    var e2 = skuEntries.Find(e => SqlLike(e.Sku, p2));
                                    if (e2.Variant != null) { hit = e2.Variant; found = true; }
                                }
                            }

                            if (found && hit != null)
                            {
                                v.VariantId   = hit.VariantId;
                                v.SKUNumber   = hit.SKUNumber;
                                v.ProductName = hit.ProductName;
                                v.Color       = hit.Color;
                                // Prefer the size extracted from the BOL text ("Size 41") over
                                // the DB column value, which may differ.  Fall back to DB only
                                // when the BOL has no explicit size keyword (code-first SKUs
                                // such as "001-Pumps-Black-36" have no "Size" token).
                                v.Size        = !string.IsNullOrEmpty(size) ? size : hit.Size;
                                v.SalePrice   = hit.SalePrice > 0 ? hit.SalePrice : perUnitPrice;
                                v.Matched     = true;
                            }

                            extracted.Add(new
                            {
                                OrderRef    = orderRef,
                                TrackingNo  = trackingNo,
                                SaleDate    = saleDate,
                                COD         = cod,
                                Quantity    = qty,
                                FullDesc    = fullDesc,
                                ProductCode = productCode,
                                VariantId   = v.VariantId,
                                SKUNumber   = v.SKUNumber,
                                ProductName = v.ProductName,
                                Color       = v.Color,
                                Size        = v.Size,
                                SalePrice   = v.SalePrice,
                                Matched     = v.Matched
                            });
                        }
                    }
                }

                // ── Platform auto-detection ───────────────────────────
                string detectedPlatform = "Website";
                string allText = string.Join(" ", pages);
                if (Regex.IsMatch(allText, @"\bDaraz\b", RegexOptions.IgnoreCase))
                    detectedPlatform = "Daraz";
                else if (Regex.IsMatch(allText, @"\bMarkaz\b", RegexOptions.IgnoreCase))
                    detectedPlatform = "Markaz";

                return JsonConvert.SerializeObject(new { success = true, items = extracted, customers = customers, platform = detectedPlatform });
            }
            catch (Exception ex)
            {
                return JsonConvert.SerializeObject(new { success = false, message = ex.Message, items = new List<object>(), customers = new List<object>() });
            }
        }

        // Normalizes a SKU (or BOL description) to dash-separated, no-spaces form.
        // "Flat - 033 - Black - Size - 38" → "Flat-033-Black-38"
        // "001-Pumps-Black-36"             → "001-Pumps-Black-36"  (unchanged)
        private static string NormalizeSKU(string s)
        {
            s = Regex.Replace(s, @"\s*-\s*",         "-"); // collapse spaces around dashes
            s = Regex.Replace(s, @"-?[Ss]ize[\s-]*", "-"); // remove "Size" keyword
            s = Regex.Replace(s, @"\s+",             "-"); // remaining spaces → dash
            s = Regex.Replace(s, @"-{2,}",           "-").Trim('-'); // dedup & trim
            return s;
        }

        // Converts a SQL LIKE pattern (% = any chars, _ = any single char) to a regex match
        private static bool SqlLike(string value, string pattern)
        {
            string regex = "^" + Regex.Escape(pattern).Replace(@"\%", ".*").Replace(@"\_", ".") + "$";
            return Regex.IsMatch(value, regex, RegexOptions.IgnoreCase);
        }

        private static string Fail(string msg) =>
            JsonConvert.SerializeObject(new { success = false, message = msg });
    }
}
