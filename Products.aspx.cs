using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class Products : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e) { }

        // ============================================================
        // MODELS
        // ============================================================
        public class ProductModel
        {
            public int     ProductId           { get; set; }
            public string  ProductCode         { get; set; }
            public string  SKUNumber           { get; set; }  // single SKU per product
            public string  ProductName         { get; set; }
            public int     CategoryId          { get; set; }
            public string  Material            { get; set; }
            public string  Description         { get; set; }
            public decimal ManufacturingPrice  { get; set; }
            public decimal CostPrice           { get; set; }
            public decimal SalePrice           { get; set; }
            public int     MinStockLevel       { get; set; }
            public string  Unit                { get; set; }
            public bool    IsActive            { get; set; }
        }

        public class VariantModel
        {
            public string Color         { get; set; }
            public string Size          { get; set; }
            public int    StockQuantity { get; set; }
            public string SKUNumbers    { get; set; }  // comma-separated per color
        }

        // ============================================================
        // HELPERS
        // ============================================================
        private static SqlConnection GetConnection()
        {
            string connStr = ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString;
            return new SqlConnection(connStr);
        }

        private static string SafeStr(IDataReader r, string col)
        {
            int i = r.GetOrdinal(col);
            return r.IsDBNull(i) ? string.Empty : r.GetString(i);
        }

        private static decimal SafeDec(IDataReader r, string col)
        {
            int i = r.GetOrdinal(col);
            return r.IsDBNull(i) ? 0m : Convert.ToDecimal(r.GetValue(i));
        }

        // ============================================================
        // GET PRODUCTS (list)
        // ============================================================
        [WebMethod]
        public static string GetProducts(bool showInactive = false)
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                var sql = @"
                    SELECT p.ProductId, p.ProductCode, p.SKUNumber, p.ProductName,
                           p.CategoryId, c.CategoryName,
                           p.ManufacturingPrice, p.CostPrice, p.SalePrice,
                           p.Material, p.Description, p.MinStockLevel, p.Unit,
                           p.IsActive, p.CreatedDate,
                           COUNT(DISTINCT pv.Color)           AS TotalColors,
                           ISNULL(SUM(pv.StockQuantity), 0)   AS TotalStock
                    FROM Products p
                    INNER JOIN Categories c ON p.CategoryId = c.CategoryId
                    LEFT  JOIN ProductVariants pv ON pv.ProductId = p.ProductId AND pv.IsActive = 1
                    " + (showInactive ? "" : "WHERE p.IsActive = 1") + @"
                    GROUP BY p.ProductId, p.ProductCode, p.SKUNumber, p.ProductName,
                             p.CategoryId, c.CategoryName,
                             p.ManufacturingPrice, p.CostPrice, p.SalePrice,
                             p.Material, p.Description, p.MinStockLevel, p.Unit,
                             p.IsActive, p.CreatedDate
                    ORDER BY p.CreatedDate DESC";


                using (var cmd = new SqlCommand(sql, conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        list.Add(new
                        {
                            ProductId          = Convert.ToInt32(rdr["ProductId"]),
                            ProductCode        = SafeStr(rdr, "ProductCode"),
                            SKUNumber          = SafeStr(rdr, "SKUNumber"),
                            ProductName        = SafeStr(rdr, "ProductName"),
                            CategoryId         = Convert.ToInt32(rdr["CategoryId"]),
                            CategoryName       = SafeStr(rdr, "CategoryName"),
                            ManufacturingPrice = SafeDec(rdr, "ManufacturingPrice"),
                            CostPrice          = SafeDec(rdr, "CostPrice"),
                            SalePrice          = SafeDec(rdr, "SalePrice"),
                            Material           = SafeStr(rdr, "Material"),
                            Description        = SafeStr(rdr, "Description"),
                            MinStockLevel      = Convert.ToInt32(rdr["MinStockLevel"]),
                            Unit               = SafeStr(rdr, "Unit"),
                            IsActive           = Convert.ToBoolean(rdr["IsActive"]),
                            CreatedDate        = Convert.ToDateTime(rdr["CreatedDate"]).ToString("dd-MMM-yyyy"),
                            TotalColors        = Convert.ToInt32(rdr["TotalColors"]),
                            TotalStock         = Convert.ToInt32(rdr["TotalStock"])
                        });
                    }
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // GET PRODUCT BY ID (edit — includes variants)
        // ============================================================
        [WebMethod]
        public static string GetProductById(int productId)
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                object product = null;

                using (var cmd = new SqlCommand("SELECT * FROM Products WHERE ProductId = @Id", conn))
                {
                    cmd.Parameters.AddWithValue("@Id", productId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            product = new
                            {
                                ProductId          = Convert.ToInt32(rdr["ProductId"]),
                                ProductCode        = SafeStr(rdr, "ProductCode"),
                                SKUNumber          = SafeStr(rdr, "SKUNumber"),
                                ProductName        = SafeStr(rdr, "ProductName"),
                                CategoryId         = Convert.ToInt32(rdr["CategoryId"]),
                                Material           = SafeStr(rdr, "Material"),
                                Description        = SafeStr(rdr, "Description"),
                                ManufacturingPrice = SafeDec(rdr, "ManufacturingPrice"),
                                CostPrice          = SafeDec(rdr, "CostPrice"),
                                SalePrice          = SafeDec(rdr, "SalePrice"),
                                MinStockLevel      = Convert.ToInt32(rdr["MinStockLevel"]),
                                Unit               = SafeStr(rdr, "Unit"),
                                IsActive           = Convert.ToBoolean(rdr["IsActive"])
                            };
                        }
                    }
                }

                if (product == null) return "null";

                var variants = new List<object>();
                using (var cmd2 = new SqlCommand(
                    "SELECT Color, Size, StockQuantity, SKUNumbers FROM ProductVariants WHERE ProductId = @Id AND IsActive = 1 ORDER BY Color, Size", conn))
                {
                    cmd2.Parameters.AddWithValue("@Id", productId);
                    using (var rdr2 = cmd2.ExecuteReader())
                    {
                        while (rdr2.Read())
                        {
                            variants.Add(new
                            {
                                Color         = rdr2["Color"].ToString(),
                                Size          = rdr2["Size"].ToString(),
                                StockQuantity = Convert.ToInt32(rdr2["StockQuantity"]),
                                SKUNumbers    = rdr2.IsDBNull(rdr2.GetOrdinal("SKUNumbers")) ? "" : rdr2["SKUNumbers"].ToString()
                            });
                        }
                    }
                }

                return JsonConvert.SerializeObject(new { Product = product, Variants = variants });
            }
        }

        // ============================================================
        // GET CATEGORIES
        // ============================================================
        [WebMethod]
        public static string GetCategories()
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                using (var cmd = new SqlCommand(
                    "SELECT CategoryId, CategoryName FROM Categories WHERE IsActive = 1 ORDER BY CategoryName", conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        list.Add(new
                        {
                            CategoryId   = Convert.ToInt32(rdr["CategoryId"]),
                            CategoryName = rdr["CategoryName"].ToString()
                        });
                    }
                }
            }
            return JsonConvert.SerializeObject(list);
        }

        // ============================================================
        // SAVE PRODUCT (Insert or Update + Variants)
        // ============================================================
        [WebMethod]
        public static string SaveProduct(ProductModel product, string variantsJson)
        {
            try
            {
                if (product == null)
                    return Fail("Invalid data received.");
                if (string.IsNullOrWhiteSpace(product.ProductCode))
                    return Fail("Product Code is required.");
                if (string.IsNullOrWhiteSpace(product.ProductName))
                    return Fail("Product Name is required.");
                if (product.CategoryId <= 0)
                    return Fail("Please select a Category.");

                var variants = JsonConvert.DeserializeObject<List<VariantModel>>(variantsJson ?? "[]")
                               ?? new List<VariantModel>();

                bool isNew = product.ProductId == 0;

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Duplicate check: same ProductCode AND same SKUNumber
                    using (var chk = new SqlCommand(@"
                        SELECT COUNT(1) FROM Products
                        WHERE ProductCode = @Code
                          AND ProductId  <> @Id
                          AND (
                                (@SKU IS NOT NULL AND SKUNumber = @SKU)
                             OR (@SKU IS NULL     AND SKUNumber IS NULL)
                          )", conn))
                    {
                        chk.Parameters.AddWithValue("@Code", product.ProductCode.Trim());
                        chk.Parameters.AddWithValue("@Id",   product.ProductId);
                        chk.Parameters.AddWithValue("@SKU",  (object)(product.SKUNumber?.Trim()) ?? DBNull.Value);
                        if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                            return Fail("A product with Code '" + product.ProductCode + "' and the same SKU already exists.");
                    }

                    int savedId = product.ProductId;

                    if (isNew)
                    {
                        const string sql = @"
                            INSERT INTO Products
                                (ProductCode, SKUNumber, ProductName, CategoryId,
                                 Material, Description,
                                 ManufacturingPrice, CostPrice, SalePrice,
                                 MinStockLevel, Unit, IsActive, CreatedDate)
                            OUTPUT INSERTED.ProductId
                            VALUES
                                (@ProductCode, @SKUNumber, @ProductName, @CategoryId,
                                 @Material, @Description,
                                 @ManufacturingPrice, @CostPrice, @SalePrice,
                                 @MinStockLevel, @Unit, @IsActive, GETDATE())";

                        using (var cmd = new SqlCommand(sql, conn))
                        {
                            AddParams(cmd, product);
                            savedId = Convert.ToInt32(cmd.ExecuteScalar());
                        }
                    }
                    else
                    {
                        const string sql = @"
                            UPDATE Products SET
                                ProductCode        = @ProductCode,
                                SKUNumber          = @SKUNumber,
                                ProductName        = @ProductName,
                                CategoryId         = @CategoryId,
                                Material           = @Material,
                                Description        = @Description,
                                ManufacturingPrice = @ManufacturingPrice,
                                CostPrice          = @CostPrice,
                                SalePrice          = @SalePrice,
                                MinStockLevel      = @MinStockLevel,
                                Unit               = @Unit,
                                IsActive           = @IsActive,
                                UpdatedDate        = GETDATE()
                            WHERE ProductId = @ProductId";

                        using (var cmd = new SqlCommand(sql, conn))
                        {
                            AddParams(cmd, product);
                            cmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                            cmd.ExecuteNonQuery();
                        }

                        // Selectively deactivate removed variants and insert only new ones
                        var existingVariants = new System.Collections.Generic.Dictionary<string, int>();
                        using (var sel = new SqlCommand(
                            "SELECT VariantId, Color, Size FROM ProductVariants WHERE ProductId = @Id AND IsActive = 1", conn))
                        {
                            sel.Parameters.AddWithValue("@Id", savedId);
                            using (var rdr = sel.ExecuteReader())
                            {
                                while (rdr.Read())
                                {
                                    string key = rdr["Color"].ToString().Trim().ToLower()
                                               + "|" + rdr["Size"].ToString().Trim().ToLower();
                                    existingVariants[key] = Convert.ToInt32(rdr["VariantId"]);
                                }
                            }
                        }

                        var submittedKeys = new System.Collections.Generic.HashSet<string>();
                        foreach (var v in variants)
                        {
                            if (string.IsNullOrWhiteSpace(v.Color) || string.IsNullOrWhiteSpace(v.Size)) continue;
                            submittedKeys.Add(v.Color.Trim().ToLower() + "|" + v.Size.Trim().ToLower());
                        }

                        // Deactivate only variants that were removed
                        foreach (var kvp in existingVariants)
                        {
                            if (!submittedKeys.Contains(kvp.Key))
                            {
                                using (var del = new SqlCommand(
                                    "UPDATE ProductVariants SET IsActive = 0 WHERE VariantId = @vid", conn))
                                {
                                    del.Parameters.AddWithValue("@vid", kvp.Value);
                                    del.ExecuteNonQuery();
                                }
                            }
                        }

                        // Insert new variants or update SKUNumbers on existing ones
                        foreach (var v in variants)
                        {
                            if (string.IsNullOrWhiteSpace(v.Color) || string.IsNullOrWhiteSpace(v.Size)) continue;
                            string vKey = v.Color.Trim().ToLower() + "|" + v.Size.Trim().ToLower();
                            if (!existingVariants.ContainsKey(vKey))
                            {
                                using (var vc = new SqlCommand(@"
                                    INSERT INTO ProductVariants (ProductId, Color, Size, StockQuantity, SKUNumbers, IsActive)
                                    VALUES (@ProductId, @Color, @Size, @StockQuantity, @SKUNumbers, 1)", conn))
                                {
                                    vc.Parameters.AddWithValue("@ProductId",     savedId);
                                    vc.Parameters.AddWithValue("@Color",         v.Color.Trim());
                                    vc.Parameters.AddWithValue("@Size",          v.Size.Trim());
                                    vc.Parameters.AddWithValue("@StockQuantity", v.StockQuantity);
                                    vc.Parameters.AddWithValue("@SKUNumbers",    (object)(v.SKUNumbers?.Trim()) ?? DBNull.Value);
                                    vc.ExecuteNonQuery();
                                }
                            }
                            else
                            {
                                using (var vu = new SqlCommand(
                                    "UPDATE ProductVariants SET SKUNumbers = @sku WHERE VariantId = @vid", conn))
                                {
                                    vu.Parameters.AddWithValue("@sku", (object)(v.SKUNumbers?.Trim()) ?? DBNull.Value);
                                    vu.Parameters.AddWithValue("@vid", existingVariants[vKey]);
                                    vu.ExecuteNonQuery();
                                }
                            }
                        }
                    }

                    // For new products, insert all variants
                    if (isNew)
                    foreach (var v in variants)
                    {
                        if (string.IsNullOrWhiteSpace(v.Color) || string.IsNullOrWhiteSpace(v.Size)) continue;
                        using (var vc = new SqlCommand(@"
                            INSERT INTO ProductVariants (ProductId, Color, Size, StockQuantity, SKUNumbers, IsActive)
                            VALUES (@ProductId, @Color, @Size, @StockQuantity, @SKUNumbers, 1)", conn))
                        {
                            vc.Parameters.AddWithValue("@ProductId",     savedId);
                            vc.Parameters.AddWithValue("@Color",         v.Color.Trim());
                            vc.Parameters.AddWithValue("@Size",          v.Size.Trim());
                            vc.Parameters.AddWithValue("@StockQuantity", v.StockQuantity);
                            vc.Parameters.AddWithValue("@SKUNumbers",    (object)(v.SKUNumbers?.Trim()) ?? DBNull.Value);
                            vc.ExecuteNonQuery();
                        }
                    }
                }

                return JsonConvert.SerializeObject(new
                {
                    success = true,
                    message = isNew ? "Product added successfully." : "Product updated successfully."
                });
            }
            catch (Exception ex)
            {
                return Fail("Error: " + ex.Message);
            }
        }

        private static void AddParams(SqlCommand cmd, ProductModel p)
        {
            cmd.Parameters.AddWithValue("@ProductCode",        p.ProductCode?.Trim()        ?? "");
            cmd.Parameters.AddWithValue("@SKUNumber",          (object)(p.SKUNumber?.Trim())  ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@ProductName",        p.ProductName?.Trim()         ?? "");
            cmd.Parameters.AddWithValue("@CategoryId",         p.CategoryId);
            cmd.Parameters.AddWithValue("@Material",           (object)(p.Material?.Trim())    ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@Description",        (object)(p.Description?.Trim()) ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@ManufacturingPrice", p.ManufacturingPrice);
            cmd.Parameters.AddWithValue("@CostPrice",          p.CostPrice);
            cmd.Parameters.AddWithValue("@SalePrice",          p.SalePrice);
            cmd.Parameters.AddWithValue("@MinStockLevel",      p.MinStockLevel);
            cmd.Parameters.AddWithValue("@Unit",               p.Unit ?? "Pair");
            cmd.Parameters.AddWithValue("@IsActive",           p.IsActive);
        }

        // ============================================================
        // DELETE PRODUCT (soft delete)
        // ============================================================
        [WebMethod]
        public static string DeleteProduct(int productId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(
                        "UPDATE Products SET IsActive = 0, UpdatedDate = GETDATE() WHERE ProductId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", productId);
                        cmd.ExecuteNonQuery();
                    }
                }
                return JsonConvert.SerializeObject(new { success = true, message = "Product deactivated successfully." });
            }
            catch (Exception ex)
            {
                return Fail("Error: " + ex.Message);
            }
        }

        // ============================================================
        // STATS
        // ============================================================
        [WebMethod]
        public static string GetProductStats()
        {
            using (var conn = GetConnection())
            {
                conn.Open();

                int total = 0, active = 0, cats = 0, lowStock = 0;

                const string sql = @"
                    SELECT COUNT(*)                                     AS TotalProducts,
                           Isnull(SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END),0) AS ActiveProducts,
                           (SELECT COUNT(*) FROM Categories WHERE IsActive = 1) AS TotalCategories
                    FROM Products";

                using (var cmd = new SqlCommand(sql, conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        total  = Convert.ToInt32(rdr["TotalProducts"]);
                        active = Convert.ToInt32(rdr["ActiveProducts"]);
                        cats   = Convert.ToInt32(rdr["TotalCategories"]);
                    }
                }

                const string lowSql = @"
                    SELECT COUNT(*) FROM (
                        SELECT p.ProductId
                        FROM   Products p
                        LEFT JOIN ProductVariants pv ON pv.ProductId = p.ProductId AND pv.IsActive = 1
                        WHERE  p.IsActive = 1
                        GROUP BY p.ProductId, p.MinStockLevel
                        HAVING ISNULL(SUM(pv.StockQuantity), 0) <= p.MinStockLevel
                    ) t";

                using (var cmd2 = new SqlCommand(lowSql, conn))
                    lowStock = Convert.ToInt32(cmd2.ExecuteScalar());

                return JsonConvert.SerializeObject(new
                {
                    TotalProducts   = total,
                    ActiveProducts  = active,
                    LowStock        = lowStock,
                    TotalCategories = cats
                });
            }
        }

        // ============================================================
        // GET VARIANTS FOR VIEW (dedicated variant modal)
        // ============================================================
        [WebMethod]
        public static string GetVariantsForView(int productId)
        {
            using (var conn = GetConnection())
            {
                conn.Open();

                int    pid = 0, minStock = 0;
                string code = "", name = "";

                using (var cmd = new SqlCommand(
                    "SELECT ProductId, ProductCode, ProductName, MinStockLevel FROM Products WHERE ProductId = @Id", conn))
                {
                    cmd.Parameters.AddWithValue("@Id", productId);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            pid      = Convert.ToInt32(rdr["ProductId"]);
                            code     = rdr["ProductCode"].ToString();
                            name     = rdr["ProductName"].ToString();
                            minStock = Convert.ToInt32(rdr["MinStockLevel"]);
                        }
                    }
                }

                if (pid == 0) return "null";

                var variants = new List<object>();
                using (var cmd2 = new SqlCommand(
                    "SELECT VariantId, Color, Size, SKUNumbers, StockQuantity FROM ProductVariants WHERE ProductId = @Id AND IsActive = 1 ORDER BY Color, Size", conn))
                {
                    cmd2.Parameters.AddWithValue("@Id", productId);
                    using (var rdr2 = cmd2.ExecuteReader())
                    {
                        while (rdr2.Read())
                        {
                            variants.Add(new
                            {
                                VariantId     = Convert.ToInt32(rdr2["VariantId"]),
                                Color         = rdr2["Color"].ToString(),
                                Size          = rdr2["Size"].ToString(),
                                SKUNumbers    = rdr2.IsDBNull(rdr2.GetOrdinal("SKUNumbers")) ? "" : rdr2["SKUNumbers"].ToString(),
                                StockQuantity = Convert.ToInt32(rdr2["StockQuantity"])
                            });
                        }
                    }
                }

                return JsonConvert.SerializeObject(new
                {
                    ProductId     = pid,
                    ProductCode   = code,
                    ProductName   = name,
                    MinStockLevel = minStock,
                    Variants      = variants
                });
            }
        }

        // ============================================================
        // SAVE VARIANTS (from variant view modal)
        // ============================================================
        public class VariantUpdateItem
        {
            public int    VariantId     { get; set; }
            public int    StockQuantity { get; set; }
            public string SKUNumbers    { get; set; }
        }

        [WebMethod]
        public static string SaveVariants(int productId, int minStockLevel, string variantsJson)
        {
            try
            {
                var items = JsonConvert.DeserializeObject<List<VariantUpdateItem>>(variantsJson ?? "[]")
                            ?? new List<VariantUpdateItem>();

                using (var conn = GetConnection())
                {
                    conn.Open();

                    using (var cmd = new SqlCommand(
                        "UPDATE Products SET MinStockLevel = @ml, UpdatedDate = GETDATE() WHERE ProductId = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@ml",  minStockLevel);
                        cmd.Parameters.AddWithValue("@id",  productId);
                        cmd.ExecuteNonQuery();
                    }

                    foreach (var v in items)
                    {
                        using (var cmd = new SqlCommand(
                            "UPDATE ProductVariants SET StockQuantity = @qty, SKUNumbers = @sku WHERE VariantId = @vid AND IsActive = 1", conn))
                        {
                            cmd.Parameters.AddWithValue("@qty", v.StockQuantity);
                            cmd.Parameters.AddWithValue("@sku", (object)(v.SKUNumbers?.Trim()) ?? DBNull.Value);
                            cmd.Parameters.AddWithValue("@vid", v.VariantId);
                            cmd.ExecuteNonQuery();
                        }
                    }
                }

                return JsonConvert.SerializeObject(new { success = true, message = "Variants saved successfully." });
            }
            catch (Exception ex)
            {
                return Fail("Error: " + ex.Message);
            }
        }

        private static string Fail(string msg) =>
            JsonConvert.SerializeObject(new { success = false, message = msg });
    }
}
