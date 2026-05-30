using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class Setup : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            EnsureCouriersTable();
        }

        // ── Models ──────────────────────────────────────────────────────────────

        public class MarketplaceModel
        {
            public int    MarketplaceId   { get; set; }
            public string MarketplaceName { get; set; }
            public string Description     { get; set; }
            public bool   IsActive        { get; set; }
        }

        public class CategoryModel
        {
            public int    CategoryId   { get; set; }
            public string CategoryName { get; set; }
            public string Description  { get; set; }
            public bool   IsActive     { get; set; }
        }

        public class CourierModel
        {
            public int    CourierId   { get; set; }
            public string CourierName { get; set; }
            public string ContactName { get; set; }
            public string Phone       { get; set; }
            public string Email       { get; set; }
            public string Notes       { get; set; }
            public bool   IsActive    { get; set; }
        }

        public class ShopifyRowDto
        {
            public string  Handle       { get; set; }
            public string  Title        { get; set; }
            public string  Type         { get; set; }
            public string  SKU          { get; set; }
            public string  Option1Name  { get; set; }
            public string  Option1Value { get; set; }
            public string  Option2Name  { get; set; }
            public string  Option2Value { get; set; }
            public string  Option3Name  { get; set; }
            public string  Option3Value { get; set; }
            public decimal Price        { get; set; }
            public decimal CostPrice    { get; set; }
            public int     Stock        { get; set; }
            public string  Status       { get; set; }
        }

        // ── Helpers ─────────────────────────────────────────────────────────────

        private static SqlConnection GetConnection()
        {
            return new SqlConnection(ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString);
        }

        private static string Ok(string msg) =>
            JsonConvert.SerializeObject(new { success = true, message = msg });

        private static string Fail(string msg) =>
            JsonConvert.SerializeObject(new { success = false, message = msg });

        private void EnsureCouriersTable()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Couriers')
                        BEGIN
                            CREATE TABLE Couriers (
                                CourierId   INT IDENTITY(1,1) PRIMARY KEY,
                                CourierName NVARCHAR(100) NOT NULL,
                                ContactName NVARCHAR(100) NULL,
                                Phone       NVARCHAR(30)  NULL,
                                Email       NVARCHAR(150) NULL,
                                Notes       NVARCHAR(400) NULL,
                                IsActive    BIT NOT NULL DEFAULT 1,
                                IsDeleted   BIT NOT NULL DEFAULT 0,
                                CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
                            )
                        END", conn))
                    {
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch { /* non-fatal — table may already exist */ }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  STATS
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetSetupStats()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();

                    int marketplaces = 0, categories = 0, couriers = 0;

                    using (var cmd = new SqlCommand("SELECT COUNT(*) FROM Marketplaces WHERE IsActive = 1", conn))
                        marketplaces = Convert.ToInt32(cmd.ExecuteScalar());

                    using (var cmd = new SqlCommand("SELECT COUNT(*) FROM Categories WHERE IsDeleted = 0 AND IsActive = 1", conn))
                        categories = Convert.ToInt32(cmd.ExecuteScalar());

                    // Couriers table may not exist yet on very first load
                    try
                    {
                        using (var cmd = new SqlCommand("SELECT COUNT(*) FROM Couriers WHERE IsDeleted = 0 AND IsActive = 1", conn))
                            couriers = Convert.ToInt32(cmd.ExecuteScalar());
                    }
                    catch { couriers = 0; }

                    return JsonConvert.SerializeObject(new
                    {
                        Marketplaces = marketplaces,
                        Categories   = categories,
                        Couriers     = couriers
                    });
                }
            }
            catch (Exception ex)
            {
                return JsonConvert.SerializeObject(new { Marketplaces = 0, Categories = 0, Couriers = 0 });
            }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  MARKETPLACE METHODS
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetAllMarketplaces(bool showInactive = false)
        {
            try
            {
                var list = new List<object>();
                using (var conn = GetConnection())
                {
                    conn.Open();
                    string filter = showInactive ? "" : "WHERE IsActive = 1";
                    using (var cmd = new SqlCommand(
                        "SELECT MarketplaceId, MarketplaceName, Description, IsActive, CreatedDate FROM Marketplaces " + filter + " ORDER BY MarketplaceName", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                            list.Add(new {
                                MarketplaceId   = Convert.ToInt32(r["MarketplaceId"]),
                                MarketplaceName = r["MarketplaceName"].ToString(),
                                Description     = r["Description"] == DBNull.Value ? "" : r["Description"].ToString(),
                                IsActive        = Convert.ToBoolean(r["IsActive"]),
                                CreatedDate     = Convert.ToDateTime(r["CreatedDate"]).ToString("dd-MMM-yyyy")
                            });
                    }
                }
                return JsonConvert.SerializeObject(list);
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        [WebMethod]
        public static string GetMarketplaceById(int marketplaceId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(
                        "SELECT MarketplaceId, MarketplaceName, Description, IsActive FROM Marketplaces WHERE MarketplaceId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", marketplaceId);
                        using (var r = cmd.ExecuteReader())
                        {
                            if (r.Read())
                                return JsonConvert.SerializeObject(new {
                                    MarketplaceId   = Convert.ToInt32(r["MarketplaceId"]),
                                    MarketplaceName = r["MarketplaceName"].ToString(),
                                    Description     = r["Description"] == DBNull.Value ? "" : r["Description"].ToString(),
                                    IsActive        = Convert.ToBoolean(r["IsActive"])
                                });
                        }
                    }
                }
                return "null";
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

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
                            return Fail("A marketplace named '" + marketplace.MarketplaceName.Trim() + "' already exists.");
                    }

                    if (marketplace.MarketplaceId == 0)
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
                        return Ok("Marketplace added successfully.");
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
                        return Ok("Marketplace updated successfully.");
                    }
                }
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  CATEGORY METHODS
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetCategories(bool showInactive = false)
        {
            try
            {
                var list = new List<object>();
                using (var conn = GetConnection())
                {
                    conn.Open();

                    bool hasProducts = TableExists(conn, "Products");
                    string productCount = hasProducts
                        ? "(SELECT COUNT(*) FROM Products p WHERE p.CategoryId = c.CategoryId AND p.IsActive = 1)"
                        : "0";

                    string filter = showInactive ? "WHERE c.IsDeleted = 0" : "WHERE c.IsDeleted = 0 AND c.IsActive = 1";

                    string sql = string.Format(@"
                        SELECT c.CategoryId, c.CategoryName, c.Description,
                               c.IsActive, c.IsDeleted, c.CreatedDate,
                               {0} AS ProductCount
                        FROM   Categories c
                        {1}
                        ORDER  BY c.CategoryName", productCount, filter);

                    using (var cmd = new SqlCommand(sql, conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                            list.Add(new {
                                CategoryId   = Convert.ToInt32(r["CategoryId"]),
                                CategoryName = r["CategoryName"].ToString(),
                                Description  = r["Description"] == DBNull.Value ? "" : r["Description"].ToString(),
                                IsActive     = Convert.ToBoolean(r["IsActive"]),
                                ProductCount = Convert.ToInt32(r["ProductCount"]),
                                CreatedDate  = Convert.ToDateTime(r["CreatedDate"]).ToString("dd-MMM-yyyy")
                            });
                    }
                }
                return JsonConvert.SerializeObject(list);
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        [WebMethod]
        public static string GetCategoryById(int categoryId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(
                        "SELECT CategoryId, CategoryName, Description, IsActive FROM Categories WHERE CategoryId = @Id AND IsDeleted = 0", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", categoryId);
                        using (var r = cmd.ExecuteReader())
                        {
                            if (r.Read())
                                return JsonConvert.SerializeObject(new {
                                    CategoryId   = Convert.ToInt32(r["CategoryId"]),
                                    CategoryName = r["CategoryName"].ToString(),
                                    Description  = r["Description"] == DBNull.Value ? "" : r["Description"].ToString(),
                                    IsActive     = Convert.ToBoolean(r["IsActive"])
                                });
                        }
                    }
                }
                return "null";
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        [WebMethod]
        public static string SaveCategory(CategoryModel category)
        {
            try
            {
                if (category == null || string.IsNullOrWhiteSpace(category.CategoryName))
                    return Fail("Category name is required.");

                using (var conn = GetConnection())
                {
                    conn.Open();

                    using (var chk = new SqlCommand(
                        "SELECT COUNT(1) FROM Categories WHERE CategoryName = @Name AND CategoryId <> @Id AND IsDeleted = 0", conn))
                    {
                        chk.Parameters.AddWithValue("@Name", category.CategoryName.Trim());
                        chk.Parameters.AddWithValue("@Id",   category.CategoryId);
                        if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                            return Fail("Category '" + category.CategoryName.Trim() + "' already exists.");
                    }

                    if (category.CategoryId == 0)
                    {
                        using (var cmd = new SqlCommand(@"
                            INSERT INTO Categories (CategoryName, Description, IsActive, IsDeleted, CreatedDate)
                            VALUES (@Name, @Desc, @Active, 0, GETDATE())", conn))
                        {
                            cmd.Parameters.AddWithValue("@Name",   category.CategoryName.Trim());
                            cmd.Parameters.AddWithValue("@Desc",   (object)(category.Description?.Trim()) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Active", category.IsActive);
                            cmd.ExecuteNonQuery();
                        }
                        return Ok("Category added successfully.");
                    }
                    else
                    {
                        using (var cmd = new SqlCommand(@"
                            UPDATE Categories
                            SET CategoryName = @Name, Description = @Desc, IsActive = @Active
                            WHERE CategoryId = @Id AND IsDeleted = 0", conn))
                        {
                            cmd.Parameters.AddWithValue("@Name",   category.CategoryName.Trim());
                            cmd.Parameters.AddWithValue("@Desc",   (object)(category.Description?.Trim()) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Active", category.IsActive);
                            cmd.Parameters.AddWithValue("@Id",     category.CategoryId);
                            cmd.ExecuteNonQuery();
                        }
                        return Ok("Category updated successfully.");
                    }
                }
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        [WebMethod]
        public static string DeleteCategory(int categoryId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();

                    using (var chk = new SqlCommand(
                        "SELECT COUNT(1) FROM Products WHERE CategoryId = @Id AND IsActive = 1", conn))
                    {
                        chk.Parameters.AddWithValue("@Id", categoryId);
                        int count = Convert.ToInt32(chk.ExecuteScalar());
                        if (count > 0)
                            return Fail("Cannot delete — " + count + " active product(s) use this category.");
                    }

                    using (var cmd = new SqlCommand(
                        "UPDATE Categories SET IsDeleted = 1 WHERE CategoryId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", categoryId);
                        cmd.ExecuteNonQuery();
                    }
                }
                return Ok("Category deleted successfully.");
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  COURIER METHODS
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetCouriers(bool showInactive = false)
        {
            try
            {
                var list = new List<object>();
                using (var conn = GetConnection())
                {
                    conn.Open();
                    string filter = showInactive ? "WHERE IsDeleted = 0" : "WHERE IsDeleted = 0 AND IsActive = 1";
                    using (var cmd = new SqlCommand(
                        "SELECT CourierId, CourierName, ContactName, Phone, Email, Notes, IsActive, CreatedDate FROM Couriers " + filter + " ORDER BY CourierName", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                            list.Add(new {
                                CourierId   = Convert.ToInt32(r["CourierId"]),
                                CourierName = r["CourierName"].ToString(),
                                ContactName = r["ContactName"] == DBNull.Value ? "" : r["ContactName"].ToString(),
                                Phone       = r["Phone"]       == DBNull.Value ? "" : r["Phone"].ToString(),
                                Email       = r["Email"]       == DBNull.Value ? "" : r["Email"].ToString(),
                                Notes       = r["Notes"]       == DBNull.Value ? "" : r["Notes"].ToString(),
                                IsActive    = Convert.ToBoolean(r["IsActive"]),
                                CreatedDate = Convert.ToDateTime(r["CreatedDate"]).ToString("dd-MMM-yyyy")
                            });
                    }
                }
                return JsonConvert.SerializeObject(list);
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        [WebMethod]
        public static string GetCourierById(int courierId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(
                        "SELECT CourierId, CourierName, ContactName, Phone, Email, Notes, IsActive FROM Couriers WHERE CourierId = @Id AND IsDeleted = 0", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", courierId);
                        using (var r = cmd.ExecuteReader())
                        {
                            if (r.Read())
                                return JsonConvert.SerializeObject(new {
                                    CourierId   = Convert.ToInt32(r["CourierId"]),
                                    CourierName = r["CourierName"].ToString(),
                                    ContactName = r["ContactName"] == DBNull.Value ? "" : r["ContactName"].ToString(),
                                    Phone       = r["Phone"]       == DBNull.Value ? "" : r["Phone"].ToString(),
                                    Email       = r["Email"]       == DBNull.Value ? "" : r["Email"].ToString(),
                                    Notes       = r["Notes"]       == DBNull.Value ? "" : r["Notes"].ToString(),
                                    IsActive    = Convert.ToBoolean(r["IsActive"])
                                });
                        }
                    }
                }
                return "null";
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        [WebMethod]
        public static string SaveCourier(CourierModel courier)
        {
            try
            {
                if (courier == null || string.IsNullOrWhiteSpace(courier.CourierName))
                    return Fail("Courier name is required.");

                using (var conn = GetConnection())
                {
                    conn.Open();

                    using (var chk = new SqlCommand(
                        "SELECT COUNT(1) FROM Couriers WHERE CourierName = @Name AND CourierId <> @Id AND IsDeleted = 0", conn))
                    {
                        chk.Parameters.AddWithValue("@Name", courier.CourierName.Trim());
                        chk.Parameters.AddWithValue("@Id",   courier.CourierId);
                        if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                            return Fail("A courier named '" + courier.CourierName.Trim() + "' already exists.");
                    }

                    if (courier.CourierId == 0)
                    {
                        using (var cmd = new SqlCommand(@"
                            INSERT INTO Couriers (CourierName, ContactName, Phone, Email, Notes, IsActive, IsDeleted, CreatedDate)
                            VALUES (@Name, @Contact, @Phone, @Email, @Notes, @Active, 0, GETDATE())", conn))
                        {
                            cmd.Parameters.AddWithValue("@Name",    courier.CourierName.Trim());
                            cmd.Parameters.AddWithValue("@Contact", (object)(courier.ContactName?.Trim()) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Phone",   (object)(courier.Phone?.Trim())       ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Email",   (object)(courier.Email?.Trim())       ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Notes",   (object)(courier.Notes?.Trim())       ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Active",  courier.IsActive);
                            cmd.ExecuteNonQuery();
                        }
                        return Ok("Courier added successfully.");
                    }
                    else
                    {
                        using (var cmd = new SqlCommand(@"
                            UPDATE Couriers
                            SET CourierName = @Name, ContactName = @Contact, Phone = @Phone,
                                Email = @Email, Notes = @Notes, IsActive = @Active
                            WHERE CourierId = @Id AND IsDeleted = 0", conn))
                        {
                            cmd.Parameters.AddWithValue("@Name",    courier.CourierName.Trim());
                            cmd.Parameters.AddWithValue("@Contact", (object)(courier.ContactName?.Trim()) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Phone",   (object)(courier.Phone?.Trim())       ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Email",   (object)(courier.Email?.Trim())       ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Notes",   (object)(courier.Notes?.Trim())       ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Active",  courier.IsActive);
                            cmd.Parameters.AddWithValue("@Id",      courier.CourierId);
                            cmd.ExecuteNonQuery();
                        }
                        return Ok("Courier updated successfully.");
                    }
                }
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        [WebMethod]
        public static string DeleteCourier(int courierId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(
                        "UPDATE Couriers SET IsDeleted = 1 WHERE CourierId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", courierId);
                        cmd.ExecuteNonQuery();
                    }
                }
                return Ok("Courier deleted successfully.");
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  SHOPIFY IMPORT
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string ImportShopifyProducts(string rowsJson)
        {
            try
            {
                var rows = JsonConvert.DeserializeObject<List<ShopifyRowDto>>(rowsJson);
                if (rows == null || rows.Count == 0)
                    return Fail("No data to import.");

                int productsInserted = 0, variantsInserted = 0, skipped = 0;

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Group rows by Handle (each Handle = one parent product)
                    var groups = new Dictionary<string, List<ShopifyRowDto>>(StringComparer.OrdinalIgnoreCase);
                    foreach (var row in rows)
                    {
                        var handle = (row.Handle ?? "").Trim();
                        if (string.IsNullOrEmpty(handle))
                            handle = "SHOPIFY_" + Guid.NewGuid().ToString("N").Substring(0, 8);
                        if (!groups.ContainsKey(handle)) groups[handle] = new List<ShopifyRowDto>();
                        groups[handle].Add(row);
                    }

                    foreach (var kvp in groups)
                    {
                        var handle      = kvp.Key;
                        var variantRows = kvp.Value;
                        var first       = variantRows[0];

                        // Skip if product already imported (same ProductCode)
                        int productId = 0;
                        using (var cmd = new SqlCommand(
                            "SELECT ProductId FROM Products WHERE ProductCode = @Code", conn))
                        {
                            cmd.Parameters.AddWithValue("@Code", handle);
                            var r = cmd.ExecuteScalar();
                            if (r != null && r != DBNull.Value) productId = Convert.ToInt32(r);
                        }

                        if (productId > 0) { skipped++; continue; }

                        // Resolve / auto-create category
                        var typeName   = (first.Type ?? "").Trim();
                        int categoryId = string.IsNullOrEmpty(typeName)
                            ? GetOrCreateCategory(conn, "Shopify Import")
                            : GetOrCreateCategory(conn, typeName);

                        var productName = (first.Title ?? handle).Trim();
                        var salePrice   = variantRows.Count > 0 ? variantRows[0].Price    : 0m;
                        var costPrice   = variantRows.Count > 0 ? variantRows[0].CostPrice : 0m;
                        bool isActive   = !string.Equals((first.Status ?? "").Trim(), "draft", StringComparison.OrdinalIgnoreCase);
                        // Product SKU = first variant's SKU without the size suffix
                        // "Flat - 062 - Fawn - Size - 36" → "Flat - 062 - Fawn"
                        var productSku  = StripSizeFromSku(first.SKU);

                        using (var cmd = new SqlCommand(@"
                            INSERT INTO Products
                                (ProductCode, SKUNumber, ProductName, CategoryId, CostPrice, SalePrice, IsActive, CreatedDate)
                            OUTPUT INSERTED.ProductId
                            VALUES (@Code, @SKU, @Name, @CatId, @Cost, @Price, @Active, GETDATE())", conn))
                        {
                            cmd.Parameters.AddWithValue("@Code",   handle);
                            cmd.Parameters.AddWithValue("@SKU",    (object)productSku ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Name",   productName);
                            cmd.Parameters.AddWithValue("@CatId",  categoryId);
                            cmd.Parameters.AddWithValue("@Cost",   costPrice);
                            cmd.Parameters.AddWithValue("@Price",  salePrice);
                            cmd.Parameters.AddWithValue("@Active", isActive);
                            productId = Convert.ToInt32(cmd.ExecuteScalar());
                        }
                        productsInserted++;

                        // Insert variants
                        foreach (var vr in variantRows)
                        {
                            string color = "", size = "";

                            var opts = new[]
                            {
                                new { Name = (vr.Option1Name  ?? "").ToLowerInvariant(), Value = vr.Option1Value  ?? "" },
                                new { Name = (vr.Option2Name  ?? "").ToLowerInvariant(), Value = vr.Option2Value  ?? "" },
                                new { Name = (vr.Option3Name  ?? "").ToLowerInvariant(), Value = vr.Option3Value  ?? "" }
                            };

                            foreach (var o in opts)
                            {
                                if (o.Name.Contains("color") || o.Name.Contains("colour"))
                                    color = o.Value.Trim();
                                else if (o.Name.Contains("size"))
                                    size  = o.Value.Trim();
                            }

                            // Fallback: option1 = color, option2 = size
                            if (string.IsNullOrEmpty(color) && !string.IsNullOrEmpty((vr.Option1Value ?? "").Trim()))
                                color = vr.Option1Value.Trim();
                            if (string.IsNullOrEmpty(size)  && !string.IsNullOrEmpty((vr.Option2Value ?? "").Trim()))
                                size  = vr.Option2Value.Trim();

                            if (string.IsNullOrEmpty(color)) color = "Default";
                            if (string.IsNullOrEmpty(size))  size  = "OS";

                            // Skip duplicate variants within same product
                            using (var chk = new SqlCommand(
                                "SELECT COUNT(1) FROM ProductVariants WHERE ProductId=@PId AND Color=@C AND Size=@S", conn))
                            {
                                chk.Parameters.AddWithValue("@PId", productId);
                                chk.Parameters.AddWithValue("@C",   color);
                                chk.Parameters.AddWithValue("@S",   size);
                                if (Convert.ToInt32(chk.ExecuteScalar()) > 0) continue;
                            }

                            using (var cmd = new SqlCommand(@"
                                INSERT INTO ProductVariants
                                    (ProductId, Color, Size, StockQuantity, SKUNumbers, IsActive)
                                VALUES (@PId, @C, @S, @Stock, @SKU, 1)", conn))
                            {
                                cmd.Parameters.AddWithValue("@PId",   productId);
                                cmd.Parameters.AddWithValue("@C",     color);
                                cmd.Parameters.AddWithValue("@S",     size);
                                cmd.Parameters.AddWithValue("@Stock", vr.Stock);
                                cmd.Parameters.AddWithValue("@SKU",   (object)(vr.SKU?.Trim()) ?? DBNull.Value);
                                cmd.ExecuteNonQuery();
                            }
                            variantsInserted++;
                        }
                    }
                }

                var msg = string.Format(
                    "Import complete: {0} product{1} and {2} variant{3} added.",
                    productsInserted, productsInserted == 1 ? "" : "s",
                    variantsInserted, variantsInserted == 1 ? "" : "s");
                if (skipped > 0)
                    msg += string.Format(" {0} product{1} skipped (already exist).", skipped, skipped == 1 ? "" : "s");

                return Ok(msg);
            }
            catch (Exception ex) { return Fail("Import error: " + ex.Message); }
        }

        private static string StripSizeFromSku(string variantSku)
        {
            if (string.IsNullOrWhiteSpace(variantSku)) return null;
            var s = variantSku.Trim();
            // "Flat - 062 - Fawn - Size - 36"  → "Flat - 062 - Fawn"   (Size - num)
            // "Pumps Jelly- 001 - BK - Size 36" → "Pumps Jelly- 001 - BK"  (Size num, no inner dash)
            var m = System.Text.RegularExpressions.Regex.Match(s,
                @"^(.*?)\s*-\s*Size\s*[-\s]*\d+\s*$",
                System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            if (m.Success) return m.Groups[1].Value.Trim();
            // "Heel - H2 - Maroon - 42" → "Heel - H2 - Maroon"  (bare number)
            m = System.Text.RegularExpressions.Regex.Match(s, @"^(.*?)\s*-\s*\d+\s*$");
            if (m.Success) return m.Groups[1].Value.Trim();
            return s;
        }

        private static int GetOrCreateCategory(SqlConnection conn, string name)
        {
            if (string.IsNullOrWhiteSpace(name)) name = "General";
            name = name.Trim();

            using (var cmd = new SqlCommand(
                "SELECT CategoryId FROM Categories WHERE CategoryName = @Name AND IsDeleted = 0", conn))
            {
                cmd.Parameters.AddWithValue("@Name", name);
                var r = cmd.ExecuteScalar();
                if (r != null && r != DBNull.Value) return Convert.ToInt32(r);
            }

            using (var cmd = new SqlCommand(@"
                INSERT INTO Categories (CategoryName, IsActive, IsDeleted, CreatedDate)
                OUTPUT INSERTED.CategoryId
                VALUES (@Name, 1, 0, GETDATE())", conn))
            {
                cmd.Parameters.AddWithValue("@Name", name);
                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }

        // ── Shared helper ────────────────────────────────────────────────────────

        private static bool TableExists(SqlConnection conn, string tableName)
        {
            using (var cmd = new SqlCommand(
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @t", conn))
            {
                cmd.Parameters.AddWithValue("@t", tableName);
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }
    }
}
