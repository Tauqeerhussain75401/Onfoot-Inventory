using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class Categories : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e) { }

        public class CategoryModel
        {
            public int    CategoryId   { get; set; }
            public string CategoryName { get; set; }
            public string Description  { get; set; }
            public bool   IsActive     { get; set; }
        }

        private static SqlConnection GetConnection()
        {
            return new SqlConnection(ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString);
        }

        // ── GET ALL ────────────────────────────────────────────────────────────
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

                    string filter = showInactive
                        ? "WHERE c.IsDeleted = 0"
                        : "WHERE c.IsDeleted = 0 AND c.IsActive = 1";

                    string sql = string.Format(@"
                        SELECT c.CategoryId, c.CategoryName, c.Description,
                               c.IsActive, c.IsDeleted, c.CreatedDate,
                               {0} AS ProductCount
                        FROM   Categories c
                        {1}
                        ORDER  BY c.CategoryName",
                        productCount, filter);

                    using (var cmd = new SqlCommand(sql, conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            list.Add(new
                            {
                                CategoryId   = Convert.ToInt32(r["CategoryId"]),
                                CategoryName = r["CategoryName"].ToString(),
                                Description  = r["Description"] == DBNull.Value ? "" : r["Description"].ToString(),
                                IsActive     = Convert.ToBoolean(r["IsActive"]),
                                IsDeleted    = Convert.ToBoolean(r["IsDeleted"]),
                                ProductCount = Convert.ToInt32(r["ProductCount"]),
                                CreatedDate  = Convert.ToDateTime(r["CreatedDate"]).ToString("dd-MMM-yyyy")
                            });
                        }
                    }
                }
                return JsonConvert.SerializeObject(list);
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        // ── GET BY ID ──────────────────────────────────────────────────────────
        [WebMethod]
        public static string GetById(int categoryId)
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
                            {
                                return JsonConvert.SerializeObject(new
                                {
                                    CategoryId   = Convert.ToInt32(r["CategoryId"]),
                                    CategoryName = r["CategoryName"].ToString(),
                                    Description  = r["Description"] == DBNull.Value ? "" : r["Description"].ToString(),
                                    IsActive     = Convert.ToBoolean(r["IsActive"])
                                });
                            }
                        }
                    }
                }
                return "null";
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        // ── INSERT / UPDATE ────────────────────────────────────────────────────
        [WebMethod]
        public static string SaveCategory(CategoryModel category)
        {
            try
            {
                if (category == null || string.IsNullOrWhiteSpace(category.CategoryName))
                    return JsonConvert.SerializeObject(new { success = false, message = "Category Name is required." });

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // duplicate name check (exclude deleted)
                    using (var chk = new SqlCommand(
                        "SELECT COUNT(1) FROM Categories WHERE CategoryName = @Name AND CategoryId <> @Id AND IsDeleted = 0", conn))
                    {
                        chk.Parameters.AddWithValue("@Name", category.CategoryName.Trim());
                        chk.Parameters.AddWithValue("@Id",   category.CategoryId);
                        if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                            return JsonConvert.SerializeObject(new
                            {
                                success = false,
                                message = "Category '" + category.CategoryName.Trim() + "' already exists."
                            });
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
                        return JsonConvert.SerializeObject(new { success = true, message = "Category added successfully." });
                    }
                    else
                    {
                        using (var cmd = new SqlCommand(@"
                            UPDATE Categories
                            SET    CategoryName = @Name,
                                   Description  = @Desc,
                                   IsActive     = @Active
                            WHERE  CategoryId   = @Id AND IsDeleted = 0", conn))
                        {
                            cmd.Parameters.AddWithValue("@Name",   category.CategoryName.Trim());
                            cmd.Parameters.AddWithValue("@Desc",   (object)(category.Description?.Trim()) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@Active", category.IsActive);
                            cmd.Parameters.AddWithValue("@Id",     category.CategoryId);
                            cmd.ExecuteNonQuery();
                        }
                        return JsonConvert.SerializeObject(new { success = true, message = "Category updated successfully." });
                    }
                }
            }
            catch (Exception ex)
            {
                return JsonConvert.SerializeObject(new { success = false, message = ex.Message });
            }
        }

        // ── DELETE (soft — sets IsDeleted = 1) ────────────────────────────────
        [WebMethod]
        public static string DeleteCategory(int categoryId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();

                    // block if active products exist
                    using (var chk = new SqlCommand(
                        "SELECT COUNT(1) FROM Products WHERE CategoryId = @Id AND IsActive = 1", conn))
                    {
                        chk.Parameters.AddWithValue("@Id", categoryId);
                        int count = Convert.ToInt32(chk.ExecuteScalar());
                        if (count > 0)
                            return JsonConvert.SerializeObject(new
                            {
                                success = false,
                                message = "Cannot delete — " + count + " active product(s) use this category."
                            });
                    }

                    using (var cmd = new SqlCommand(
                        "UPDATE Categories SET IsDeleted = 1 WHERE CategoryId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", categoryId);
                        cmd.ExecuteNonQuery();
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Category deleted successfully." });
            }
            catch (Exception ex)
            {
                return JsonConvert.SerializeObject(new { success = false, message = ex.Message });
            }
        }

        // ── STATS ──────────────────────────────────────────────────────────────
        [WebMethod]
        public static string GetStats()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT COUNT(*) AS Total,
                               ISNULL(SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END), 0) AS Active
                        FROM   Categories
                        WHERE  IsDeleted = 0", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                            return JsonConvert.SerializeObject(new
                            {
                                Total  = Convert.ToInt32(r["Total"]),
                                Active = Convert.ToInt32(r["Active"])
                            });
                    }
                }
                return JsonConvert.SerializeObject(new { Total = 0, Active = 0 });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        // ── HELPER ─────────────────────────────────────────────────────────────
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
