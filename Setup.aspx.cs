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
