using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class Stock : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e) { }

        // ============================================================
        // MODELS
        // ============================================================
        public class MarketplaceModel
        {
            public int    MarketplaceId   { get; set; }
            public string MarketplaceName { get; set; }
            public string Description     { get; set; }
            public bool   IsActive        { get; set; }
        }

        public class StockSummaryItem
        {
            public int                 VariantId         { get; set; }
            public int                 ProductId         { get; set; }
            public string              ProductCode       { get; set; }
            public string              ProductName       { get; set; }
            public string              Color             { get; set; }
            public string              Size              { get; set; }
            public string              SKUNumbers        { get; set; }
            public int                 WarehouseStock    { get; set; }
            public int                 MinStockLevel     { get; set; }
            public int                 TotalAllocated    { get; set; }
            public Dictionary<int,int> MarketplaceStocks { get; set; }
        }

        // ============================================================
        // HELPERS
        // ============================================================
        private static SqlConnection GetConnection()
        {
            string cs = ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString;
            return new SqlConnection(cs);
        }

        private static string SafeStr(IDataReader r, string col)
        {
            int i = r.GetOrdinal(col);
            return r.IsDBNull(i) ? string.Empty : r.GetString(i);
        }

        private static string Fail(string msg) =>
            JsonConvert.SerializeObject(new { success = false, message = msg });

        private static string CurrentUser()
        {
            var session = System.Web.HttpContext.Current.Session;
            return session?["FullName"]?.ToString()
                ?? session?["Username"]?.ToString()
                ?? "Unknown";
        }

        private static string GetPrimarySKU(string skuNumbers)
        {
            if (string.IsNullOrWhiteSpace(skuNumbers)) return string.Empty;
            int comma = skuNumbers.IndexOf(',');
            return comma >= 0 ? skuNumbers.Substring(0, comma).Trim() : skuNumbers.Trim();
        }

        // ============================================================
        // GET ACTIVE MARKETPLACES  (for dropdowns)
        // ============================================================
        [WebMethod]
        public static string GetMarketplaces()
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT MarketplaceId, MarketplaceName, Description FROM Marketplaces WHERE IsActive = 1 ORDER BY marketplaceid", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        list.Add(new {
                            MarketplaceId   = Convert.ToInt32(rdr["MarketplaceId"]),
                            MarketplaceName = rdr["MarketplaceName"].ToString(),
                            Description     = SafeStr(rdr, "Description")
                        });
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // GET ALL MARKETPLACES  (for management modal)
        // ============================================================
        [WebMethod]
        public static string GetAllMarketplaces()
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT MarketplaceId, MarketplaceName, Description, IsActive, CreatedDate FROM Marketplaces ORDER BY MarketplaceName", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        list.Add(new {
                            MarketplaceId   = Convert.ToInt32(rdr["MarketplaceId"]),
                            MarketplaceName = rdr["MarketplaceName"].ToString(),
                            Description     = SafeStr(rdr, "Description"),
                            IsActive        = Convert.ToBoolean(rdr["IsActive"]),
                            CreatedDate     = Convert.ToDateTime(rdr["CreatedDate"]).ToString("dd-MMM-yyyy")
                        });
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // SAVE MARKETPLACE  (add or edit)
        // ============================================================
        [WebMethod]
        public static string SaveMarketplace(MarketplaceModel marketplace)
        {
            try
            {
                if (marketplace == null || string.IsNullOrWhiteSpace(marketplace.MarketplaceName))
                    return Fail("Marketplace name is required.");

                using (var conn = GetConnection())
                {
                    conn.Open();

                    using (var chk = new SqlCommand(
                        "SELECT COUNT(1) FROM Marketplaces WHERE MarketplaceName = @Name AND MarketplaceId <> @Id", conn))
                    {
                        chk.Parameters.AddWithValue("@Name", marketplace.MarketplaceName.Trim());
                        chk.Parameters.AddWithValue("@Id",   marketplace.MarketplaceId);
                        if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                            return Fail("A marketplace with this name already exists.");
                    }

                    bool isNew = marketplace.MarketplaceId == 0;
                    if (isNew)
                    {
                        using (var cmd = new SqlCommand(@"
                            INSERT INTO Marketplaces (MarketplaceName, Description, IsActive, CreatedDate)
                            VALUES (@Name, @Desc, @Active, GETDATE())", conn))
                        {
                            cmd.Parameters.AddWithValue("@Name",   marketplace.MarketplaceName.Trim());
                            cmd.Parameters.AddWithValue("@Desc",   (object)(marketplace.Description?.Trim()) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Active", marketplace.IsActive);
                            cmd.ExecuteNonQuery();
                        }
                    }
                    else
                    {
                        using (var cmd = new SqlCommand(@"
                            UPDATE Marketplaces
                            SET MarketplaceName = @Name, Description = @Desc, IsActive = @Active
                            WHERE MarketplaceId = @Id", conn))
                        {
                            cmd.Parameters.AddWithValue("@Name",   marketplace.MarketplaceName.Trim());
                            cmd.Parameters.AddWithValue("@Desc",   (object)(marketplace.Description?.Trim()) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Active", marketplace.IsActive);
                            cmd.Parameters.AddWithValue("@Id",     marketplace.MarketplaceId);
                            cmd.ExecuteNonQuery();
                        }
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Marketplace saved successfully." });
            }
            catch (Exception ex)
            {
                return Fail("Error: " + ex.Message);
            }
        }

        // ============================================================
        // GET STOCK STATS  (header cards)
        // ============================================================
        [WebMethod]
        public static string GetStockStats()
        {
            using (var conn = GetConnection())
            {
                conn.Open();

                int warehouseTotal = 0, marketplaceTotal = 0, activeMarketplaces = 0, totalVariants = 0;

                using (var cmd = new SqlCommand(@"
                    SELECT ISNULL(SUM(StockQuantity), 0) AS WarehouseTotal,
                           COUNT(*)                       AS TotalVariants
                    FROM ProductVariants WHERE IsActive = 1", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        warehouseTotal = Convert.ToInt32(rdr["WarehouseTotal"]);
                        totalVariants  = Convert.ToInt32(rdr["TotalVariants"]);
                    }
                }

                using (var cmd2 = new SqlCommand(
                    "SELECT ISNULL(SUM(StockQuantity), 0) FROM MarketplaceInventory", conn))
                    marketplaceTotal = Convert.ToInt32(cmd2.ExecuteScalar());

                using (var cmd3 = new SqlCommand(
                    "SELECT COUNT(*) FROM Marketplaces WHERE IsActive = 1", conn))
                    activeMarketplaces = Convert.ToInt32(cmd3.ExecuteScalar());

                return JsonConvert.SerializeObject(new {
                    WarehouseTotal     = warehouseTotal,
                    MarketplaceTotal   = marketplaceTotal,
                    ActiveMarketplaces = activeMarketplaces,
                    TotalVariants      = totalVariants
                });
            }
        }

        // ============================================================
        // GET PRODUCTS FOR DROPDOWN
        // ============================================================
        [WebMethod]
        public static string GetProductsForDropdown()
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT ProductId, ProductCode, ProductName FROM Products WHERE IsActive = 1 ORDER BY ProductCode", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                        list.Add(new {
                            ProductId   = Convert.ToInt32(rdr["ProductId"]),
                            ProductCode = rdr["ProductCode"].ToString(),
                            ProductName = rdr["ProductName"].ToString()
                        });
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // GET VARIANTS BY PRODUCT
        // ============================================================
        [WebMethod]
        public static string GetVariantsByProduct(int productId)
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(@"
                    SELECT VariantId, Color, Size, SKUNumbers, StockQuantity
                    FROM ProductVariants
                    WHERE ProductId = @Id AND IsActive = 1
                    ORDER BY Color, Size", conn))
                {
                    cmd.Parameters.AddWithValue("@Id", productId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                            list.Add(new {
                                VariantId     = Convert.ToInt32(rdr["VariantId"]),
                                Color         = rdr["Color"].ToString(),
                                Size          = rdr["Size"].ToString(),
                                SKUNumbers    = GetPrimarySKU(rdr.IsDBNull(rdr.GetOrdinal("SKUNumbers")) ? "" : rdr["SKUNumbers"].ToString()),
                                StockQuantity = Convert.ToInt32(rdr["StockQuantity"])
                            });
                    }
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // GET STOCK SUMMARY  (main table)
        // ============================================================
        [WebMethod]
        public static string GetStockSummary()
        {
            using (var conn = GetConnection())
            {
                conn.Open();

                var items    = new List<StockSummaryItem>();
                var indexMap = new Dictionary<int, int>(); // variantId → index in items

                using (var cmd = new SqlCommand(@"
                    SELECT pv.VariantId, p.ProductId, p.ProductCode, p.ProductName,
                           pv.Color, pv.Size, pv.SKUNumbers,
                           pv.StockQuantity AS WarehouseStock,
                           p.MinStockLevel
                    FROM ProductVariants pv
                    INNER JOIN Products p ON p.ProductId = pv.ProductId
                    WHERE pv.IsActive = 1 AND p.IsActive = 1
                    ORDER BY p.ProductCode, pv.Color, pv.Size", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        var item = new StockSummaryItem {
                            VariantId         = Convert.ToInt32(rdr["VariantId"]),
                            ProductId         = Convert.ToInt32(rdr["ProductId"]),
                            ProductCode       = rdr["ProductCode"].ToString(),
                            ProductName       = rdr["ProductName"].ToString(),
                            Color             = rdr["Color"].ToString(),
                            Size              = rdr["Size"].ToString(),
                            SKUNumbers        = GetPrimarySKU(rdr.IsDBNull(rdr.GetOrdinal("SKUNumbers")) ? "" : rdr["SKUNumbers"].ToString()),
                            WarehouseStock    = Convert.ToInt32(rdr["WarehouseStock"]),
                            MinStockLevel     = Convert.ToInt32(rdr["MinStockLevel"]),
                            MarketplaceStocks = new Dictionary<int, int>()
                        };
                        indexMap[item.VariantId] = items.Count;
                        items.Add(item);
                    }
                }

                // Fill marketplace stocks
                using (var cmd2 = new SqlCommand(@"
                    SELECT mi.VariantId, mi.MarketplaceId, mi.StockQuantity
                    FROM MarketplaceInventory mi
                    INNER JOIN ProductVariants pv ON pv.VariantId = mi.VariantId AND pv.IsActive = 1", conn))
                using (var rdr2 = cmd2.ExecuteReader())
                {
                    while (rdr2.Read())
                    {
                        int vid  = Convert.ToInt32(rdr2["VariantId"]);
                        int mpid = Convert.ToInt32(rdr2["MarketplaceId"]);
                        int qty  = Convert.ToInt32(rdr2["StockQuantity"]);
                        if (indexMap.ContainsKey(vid))
                            items[indexMap[vid]].MarketplaceStocks[mpid] = qty;
                    }
                }

                // Compute TotalAllocated
                foreach (var item in items)
                {
                    int total = 0;
                    foreach (var q in item.MarketplaceStocks.Values) total += q;
                    item.TotalAllocated = total;
                }

                return JsonConvert.SerializeObject(items);
            }
        }

        // ============================================================
        // ADD STOCK  (receive into warehouse)
        // ============================================================
        [WebMethod]
        public static string AddStock(int variantId, int quantity, string notes)
        {
            try
            {
                if (variantId <= 0) return Fail("Invalid variant.");
                if (quantity  <= 0) return Fail("Quantity must be greater than zero.");

                using (var conn = GetConnection())
                {
                    conn.Open();
                    string user = CurrentUser();
                    using (var tx = conn.BeginTransaction())
                    {
                        try
                        {
                            using (var cmd = new SqlCommand(@"
                                UPDATE ProductVariants
                                SET StockQuantity = StockQuantity + @qty
                                WHERE VariantId = @vid AND IsActive = 1", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@qty", quantity);
                                cmd.Parameters.AddWithValue("@vid", variantId);
                                if (cmd.ExecuteNonQuery() == 0)
                                { tx.Rollback(); return Fail("Variant not found."); }
                            }

                            using (var cmd2 = new SqlCommand(@"
                                INSERT INTO StockMovements
                                    (VariantId, MovementType, FromMarketplaceId, ToMarketplaceId, Quantity, Notes, CreatedBy, CreatedDate)
                                VALUES (@vid, 'RECEIVE', NULL, NULL, @qty, @notes, @user, GETDATE())", conn, tx))
                            {
                                cmd2.Parameters.AddWithValue("@vid",   variantId);
                                cmd2.Parameters.AddWithValue("@qty",   quantity);
                                cmd2.Parameters.AddWithValue("@notes", (object)(notes?.Trim()) ?? DBNull.Value);
                                cmd2.Parameters.AddWithValue("@user",  user);
                                cmd2.ExecuteNonQuery();
                            }

                            tx.Commit();
                        }
                        catch { tx.Rollback(); throw; }
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Stock added to warehouse successfully." });
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        // ============================================================
        // ALLOCATE STOCK  (warehouse → marketplace)
        // ============================================================
        [WebMethod]
        public static string AllocateStock(int variantId, int marketplaceId, int quantity, string notes)
        {
            try
            {
                if (variantId     <= 0) return Fail("Invalid variant.");
                if (marketplaceId <= 0) return Fail("Invalid marketplace.");
                if (quantity      <= 0) return Fail("Quantity must be greater than zero.");

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Check warehouse stock
                    int warehouse = 0;
                    using (var chk = new SqlCommand(
                        "SELECT StockQuantity FROM ProductVariants WHERE VariantId = @vid AND IsActive = 1", conn))
                    {
                        chk.Parameters.AddWithValue("@vid", variantId);
                        var scalar = chk.ExecuteScalar();
                        if (scalar == null) return Fail("Variant not found.");
                        warehouse = Convert.ToInt32(scalar);
                    }

                    if (quantity > warehouse)
                        return Fail("Not enough warehouse stock. Available: " + warehouse);

                    string user = CurrentUser();
                    using (var tx = conn.BeginTransaction())
                    {
                        try
                        {
                            // Decrease warehouse
                            using (var c1 = new SqlCommand(@"
                                UPDATE ProductVariants
                                SET StockQuantity = StockQuantity - @qty
                                WHERE VariantId = @vid", conn, tx))
                            {
                                c1.Parameters.AddWithValue("@qty", quantity);
                                c1.Parameters.AddWithValue("@vid", variantId);
                                c1.ExecuteNonQuery();
                            }

                            // Upsert marketplace inventory
                            using (var c2 = new SqlCommand(@"
                                IF EXISTS (SELECT 1 FROM MarketplaceInventory WHERE VariantId = @vid AND MarketplaceId = @mpid)
                                    UPDATE MarketplaceInventory
                                    SET StockQuantity = StockQuantity + @qty, UpdatedDate = GETDATE()
                                    WHERE VariantId = @vid AND MarketplaceId = @mpid
                                ELSE
                                    INSERT INTO MarketplaceInventory (VariantId, MarketplaceId, StockQuantity, UpdatedDate)
                                    VALUES (@vid, @mpid, @qty, GETDATE())", conn, tx))
                            {
                                c2.Parameters.AddWithValue("@vid",  variantId);
                                c2.Parameters.AddWithValue("@mpid", marketplaceId);
                                c2.Parameters.AddWithValue("@qty",  quantity);
                                c2.ExecuteNonQuery();
                            }

                            // Movement log
                            using (var c3 = new SqlCommand(@"
                                INSERT INTO StockMovements
                                    (VariantId, MovementType, FromMarketplaceId, ToMarketplaceId, Quantity, Notes, CreatedBy, CreatedDate)
                                VALUES (@vid, 'ALLOCATE', NULL, @mpid, @qty, @notes, @user, GETDATE())", conn, tx))
                            {
                                c3.Parameters.AddWithValue("@vid",   variantId);
                                c3.Parameters.AddWithValue("@mpid",  marketplaceId);
                                c3.Parameters.AddWithValue("@qty",   quantity);
                                c3.Parameters.AddWithValue("@notes", (object)(notes?.Trim()) ?? DBNull.Value);
                                c3.Parameters.AddWithValue("@user",  user);
                                c3.ExecuteNonQuery();
                            }

                            tx.Commit();
                        }
                        catch { tx.Rollback(); throw; }
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Stock allocated to marketplace successfully." });
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        // ============================================================
        // TRANSFER STOCK  (marketplace → marketplace)
        // ============================================================
        [WebMethod]
        public static string TransferStock(int variantId, int fromMarketplaceId, int toMarketplaceId, int quantity, string notes)
        {
            try
            {
                if (variantId         <= 0) return Fail("Invalid variant.");
                if (fromMarketplaceId <= 0) return Fail("Invalid source marketplace.");
                if (toMarketplaceId   <= 0) return Fail("Invalid destination marketplace.");
                if (fromMarketplaceId == toMarketplaceId) return Fail("Source and destination cannot be the same marketplace.");
                if (quantity          <= 0) return Fail("Quantity must be greater than zero.");

                using (var conn = GetConnection())
                {
                    conn.Open();

                    int fromStock = 0;
                    using (var chk = new SqlCommand(
                        "SELECT ISNULL(StockQuantity,0) FROM MarketplaceInventory WHERE VariantId = @vid AND MarketplaceId = @mpid", conn))
                    {
                        chk.Parameters.AddWithValue("@vid",  variantId);
                        chk.Parameters.AddWithValue("@mpid", fromMarketplaceId);
                        fromStock = Convert.ToInt32(chk.ExecuteScalar() ?? 0);
                    }

                    if (quantity > fromStock)
                        return Fail("Not enough stock in source marketplace. Available: " + fromStock);

                    string user = CurrentUser();
                    using (var tx = conn.BeginTransaction())
                    {
                        try
                        {
                            // Decrease source marketplace
                            using (var c1 = new SqlCommand(@"
                                UPDATE MarketplaceInventory
                                SET StockQuantity = StockQuantity - @qty, UpdatedDate = GETDATE()
                                WHERE VariantId = @vid AND MarketplaceId = @from", conn, tx))
                            {
                                c1.Parameters.AddWithValue("@qty",  quantity);
                                c1.Parameters.AddWithValue("@vid",  variantId);
                                c1.Parameters.AddWithValue("@from", fromMarketplaceId);
                                c1.ExecuteNonQuery();
                            }

                            // Upsert destination marketplace
                            using (var c2 = new SqlCommand(@"
                                IF EXISTS (SELECT 1 FROM MarketplaceInventory WHERE VariantId = @vid AND MarketplaceId = @to)
                                    UPDATE MarketplaceInventory
                                    SET StockQuantity = StockQuantity + @qty, UpdatedDate = GETDATE()
                                    WHERE VariantId = @vid AND MarketplaceId = @to
                                ELSE
                                    INSERT INTO MarketplaceInventory (VariantId, MarketplaceId, StockQuantity, UpdatedDate)
                                    VALUES (@vid, @to, @qty, GETDATE())", conn, tx))
                            {
                                c2.Parameters.AddWithValue("@vid", variantId);
                                c2.Parameters.AddWithValue("@to",  toMarketplaceId);
                                c2.Parameters.AddWithValue("@qty", quantity);
                                c2.ExecuteNonQuery();
                            }

                            // Movement log
                            using (var c3 = new SqlCommand(@"
                                INSERT INTO StockMovements
                                    (VariantId, MovementType, FromMarketplaceId, ToMarketplaceId, Quantity, Notes, CreatedBy, CreatedDate)
                                VALUES (@vid, 'TRANSFER', @from, @to, @qty, @notes, @user, GETDATE())", conn, tx))
                            {
                                c3.Parameters.AddWithValue("@vid",   variantId);
                                c3.Parameters.AddWithValue("@from",  fromMarketplaceId);
                                c3.Parameters.AddWithValue("@to",    toMarketplaceId);
                                c3.Parameters.AddWithValue("@qty",   quantity);
                                c3.Parameters.AddWithValue("@notes", (object)(notes?.Trim()) ?? DBNull.Value);
                                c3.Parameters.AddWithValue("@user",  user);
                                c3.ExecuteNonQuery();
                            }

                            tx.Commit();
                        }
                        catch { tx.Rollback(); throw; }
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Stock transferred successfully." });
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        // ============================================================
        // RETURN STOCK  (marketplace → warehouse)
        // ============================================================
        [WebMethod]
        public static string ReturnStock(int variantId, int marketplaceId, int quantity, string notes)
        {
            try
            {
                if (variantId     <= 0) return Fail("Invalid variant.");
                if (marketplaceId <= 0) return Fail("Invalid marketplace.");
                if (quantity      <= 0) return Fail("Quantity must be greater than zero.");

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Check marketplace stock
                    int mpStock = 0;
                    using (var chk = new SqlCommand(
                        "SELECT ISNULL(StockQuantity,0) FROM MarketplaceInventory WHERE VariantId = @vid AND MarketplaceId = @mpid", conn))
                    {
                        chk.Parameters.AddWithValue("@vid",  variantId);
                        chk.Parameters.AddWithValue("@mpid", marketplaceId);
                        var scalar = chk.ExecuteScalar();
                        mpStock = scalar == null ? 0 : Convert.ToInt32(scalar);
                    }

                    if (quantity > mpStock)
                        return Fail("Not enough marketplace stock to return. Available: " + mpStock);

                    using (var tx = conn.BeginTransaction())
                    {
                        try
                        {
                            // Decrease marketplace stock
                            using (var c1 = new SqlCommand(@"
                                UPDATE MarketplaceInventory
                                SET StockQuantity = StockQuantity - @qty, UpdatedDate = GETDATE()
                                WHERE VariantId = @vid AND MarketplaceId = @mpid", conn, tx))
                            {
                                c1.Parameters.AddWithValue("@qty",  quantity);
                                c1.Parameters.AddWithValue("@vid",  variantId);
                                c1.Parameters.AddWithValue("@mpid", marketplaceId);
                                c1.ExecuteNonQuery();
                            }

                            // Increase warehouse stock
                            using (var c2 = new SqlCommand(@"
                                UPDATE ProductVariants
                                SET StockQuantity = StockQuantity + @qty
                                WHERE VariantId = @vid", conn, tx))
                            {
                                c2.Parameters.AddWithValue("@qty", quantity);
                                c2.Parameters.AddWithValue("@vid", variantId);
                                c2.ExecuteNonQuery();
                            }

                            // Movement log
                            using (var c3 = new SqlCommand(@"
                                INSERT INTO StockMovements
                                    (VariantId, MovementType, FromMarketplaceId, ToMarketplaceId, Quantity, Notes, CreatedBy, CreatedDate)
                                VALUES (@vid, 'RETURN', @mpid, NULL, @qty, @notes, @user, GETDATE())", conn, tx))
                            {
                                c3.Parameters.AddWithValue("@vid",   variantId);
                                c3.Parameters.AddWithValue("@mpid",  marketplaceId);
                                c3.Parameters.AddWithValue("@qty",   quantity);
                                c3.Parameters.AddWithValue("@notes", (object)(notes?.Trim()) ?? DBNull.Value);
                                c3.Parameters.AddWithValue("@user",  CurrentUser());
                                c3.ExecuteNonQuery();
                            }

                            tx.Commit();
                        }
                        catch { tx.Rollback(); throw; }
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Stock returned to warehouse successfully." });
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        // ============================================================
        // MARK DAMAGED  (remove from marketplace, NOT back to warehouse)
        // ============================================================
        [WebMethod]
        public static string MarkDamaged(int variantId, int marketplaceId, int quantity, string notes)
        {
            try
            {
                if (variantId     <= 0) return Fail("Invalid variant.");
                if (marketplaceId <= 0) return Fail("Invalid marketplace.");
                if (quantity      <= 0) return Fail("Quantity must be greater than zero.");

                using (var conn = GetConnection())
                {
                    conn.Open();

                    int mpStock = 0;
                    using (var chk = new SqlCommand(
                        "SELECT ISNULL(StockQuantity,0) FROM MarketplaceInventory WHERE VariantId = @vid AND MarketplaceId = @mpid", conn))
                    {
                        chk.Parameters.AddWithValue("@vid",  variantId);
                        chk.Parameters.AddWithValue("@mpid", marketplaceId);
                        mpStock = Convert.ToInt32(chk.ExecuteScalar() ?? 0);
                    }

                    if (quantity > mpStock)
                        return Fail("Not enough marketplace stock. Available: " + mpStock);

                    string user = CurrentUser();
                    using (var tx = conn.BeginTransaction())
                    {
                        try
                        {
                            // Only reduce marketplace stock — do NOT touch warehouse
                            using (var c1 = new SqlCommand(@"
                                UPDATE MarketplaceInventory
                                SET StockQuantity = StockQuantity - @qty, UpdatedDate = GETDATE()
                                WHERE VariantId = @vid AND MarketplaceId = @mpid", conn, tx))
                            {
                                c1.Parameters.AddWithValue("@qty",  quantity);
                                c1.Parameters.AddWithValue("@vid",  variantId);
                                c1.Parameters.AddWithValue("@mpid", marketplaceId);
                                c1.ExecuteNonQuery();
                            }

                            using (var c2 = new SqlCommand(@"
                                INSERT INTO StockMovements
                                    (VariantId, MovementType, FromMarketplaceId, ToMarketplaceId, Quantity, Notes, CreatedBy, CreatedDate)
                                VALUES (@vid, 'DAMAGED', @mpid, NULL, @qty, @notes, @user, GETDATE())", conn, tx))
                            {
                                c2.Parameters.AddWithValue("@vid",   variantId);
                                c2.Parameters.AddWithValue("@mpid",  marketplaceId);
                                c2.Parameters.AddWithValue("@qty",   quantity);
                                c2.Parameters.AddWithValue("@notes", (object)(notes?.Trim()) ?? DBNull.Value);
                                c2.Parameters.AddWithValue("@user",  user);
                                c2.ExecuteNonQuery();
                            }

                            tx.Commit();
                        }
                        catch { tx.Rollback(); throw; }
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Stock marked as damaged and removed." });
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        // ============================================================
        // GET ALL STOCK MOVEMENTS  (full history, all variants)
        // ============================================================
        [WebMethod]
        public static string GetAllStockMovements()
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(@"
                    SELECT TOP 1000
                           sm.MovementType, sm.Quantity, sm.Notes, sm.CreatedDate, sm.CreatedBy,
                           ISNULL(pv.SKUNumbers, pv.Color + ' / Sz ' + pv.Size) AS SKUDisplay,
                           p.ProductCode, p.ProductName,
                           mf.MarketplaceName AS FromName,
                           mt.MarketplaceName AS ToName
                    FROM StockMovements sm
                    INNER JOIN ProductVariants pv ON pv.VariantId = sm.VariantId
                    INNER JOIN Products        p  ON p.ProductId  = pv.ProductId
                    LEFT  JOIN Marketplaces    mf ON mf.MarketplaceId = sm.FromMarketplaceId
                    LEFT  JOIN Marketplaces    mt ON mt.MarketplaceId = sm.ToMarketplaceId
                    ORDER BY sm.CreatedDate DESC", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        string from = rdr.IsDBNull(rdr.GetOrdinal("FromName")) ? "Warehouse" : rdr["FromName"].ToString();
                        string to   = rdr.IsDBNull(rdr.GetOrdinal("ToName"))   ? "Warehouse" : rdr["ToName"].ToString();
                        list.Add(new {
                            MovementType = rdr["MovementType"].ToString(),
                            SKUDisplay   = GetPrimarySKU(rdr["SKUDisplay"].ToString()),
                            ProductCode  = rdr["ProductCode"].ToString(),
                            ProductName  = rdr["ProductName"].ToString(),
                            From         = from,
                            To           = to,
                            Quantity     = Convert.ToInt32(rdr["Quantity"]),
                            Notes        = rdr.IsDBNull(rdr.GetOrdinal("Notes"))     ? "" : rdr["Notes"].ToString(),
                            CreatedBy    = rdr.IsDBNull(rdr.GetOrdinal("CreatedBy")) ? "" : rdr["CreatedBy"].ToString(),
                            CreatedDate  = Convert.ToDateTime(rdr["CreatedDate"]).ToString("dd-MMM-yyyy HH:mm")
                        });
                    }
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // GET STOCK MOVEMENTS  (history for one variant)
        // ============================================================
        [WebMethod]
        public static string GetStockMovements(int variantId)
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(@"
                    SELECT sm.MovementId, sm.MovementType, sm.Quantity, sm.Notes, sm.CreatedDate,
                           sm.CreatedBy,
                           mf.MarketplaceName AS FromName,
                           mt.MarketplaceName AS ToName
                    FROM StockMovements sm
                    LEFT JOIN Marketplaces mf ON mf.MarketplaceId = sm.FromMarketplaceId
                    LEFT JOIN Marketplaces mt ON mt.MarketplaceId = sm.ToMarketplaceId
                    WHERE sm.VariantId = @vid
                    ORDER BY sm.CreatedDate DESC", conn))
                {
                    cmd.Parameters.AddWithValue("@vid", variantId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            string from = rdr.IsDBNull(rdr.GetOrdinal("FromName")) ? "Warehouse" : rdr["FromName"].ToString();
                            string to   = rdr.IsDBNull(rdr.GetOrdinal("ToName"))   ? "Warehouse" : rdr["ToName"].ToString();
                            list.Add(new {
                                MovementType = rdr["MovementType"].ToString(),
                                From         = from,
                                To           = to,
                                Quantity     = Convert.ToInt32(rdr["Quantity"]),
                                Notes        = rdr.IsDBNull(rdr.GetOrdinal("Notes"))      ? "" : rdr["Notes"].ToString(),
                                CreatedBy    = rdr.IsDBNull(rdr.GetOrdinal("CreatedBy"))  ? "" : rdr["CreatedBy"].ToString(),
                                CreatedDate  = Convert.ToDateTime(rdr["CreatedDate"]).ToString("dd-MMM-yyyy HH:mm")
                            });
                        }
                    }
                }
            }
            return JsonConvert.SerializeObject(list);
        }
    }
}
