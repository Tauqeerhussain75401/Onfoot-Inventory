using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class Sales : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e) { }

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
        // STATS
        // ============================================================
        [WebMethod]
        public static string GetSaleStats()
        {
            using (var conn = GetConnection())
            {
                conn.Open();
                const string sql = @"
                    SELECT
                        COUNT(*)                                                                          AS TotalBills,
                        ISNULL(SUM(TotalAmount), 0)                                                      AS TotalRevenue,
                        ISNULL(SUM(CASE WHEN CAST(SaleDate AS DATE) = CAST(GETDATE() AS DATE) THEN 1    ELSE 0 END),0) AS TodayBills,
                        ISNULL(SUM(CASE WHEN CAST(SaleDate AS DATE) = CAST(GETDATE() AS DATE)
                                        THEN TotalAmount ELSE 0 END), 0)                                 AS TodayRevenue,
                        ISNULL(SUM(CASE WHEN Platform = 'Website' THEN TotalAmount ELSE 0 END), 0)       AS WebsiteRevenue,
                        ISNULL(SUM(CASE WHEN Platform = 'Daraz'   THEN TotalAmount ELSE 0 END), 0)       AS DarazRevenue,
                        ISNULL(SUM(CASE WHEN Platform = 'Markaz'  THEN TotalAmount ELSE 0 END), 0)       AS MarkazRevenue
                    FROM Sales WHERE Status = 'Completed'";

                using (var cmd = new SqlCommand(sql, conn))
                using (var rdr = cmd.ExecuteReader())
                {
                    if (rdr.Read())
                    {
                        return JsonConvert.SerializeObject(new
                        {
                            TotalBills     = Convert.ToInt32(rdr["TotalBills"]),
                            TotalRevenue   = SafeDec(rdr, "TotalRevenue"),
                            TodayBills     = Convert.ToInt32(rdr["TodayBills"]),
                            TodayRevenue   = SafeDec(rdr, "TodayRevenue"),
                            WebsiteRevenue = SafeDec(rdr, "WebsiteRevenue"),
                            DarazRevenue   = SafeDec(rdr, "DarazRevenue"),
                            MarkazRevenue  = SafeDec(rdr, "MarkazRevenue")
                        });
                    }
                }
            }
            return JsonConvert.SerializeObject(new { TotalBills=0, TotalRevenue=0, TodayBills=0, TodayRevenue=0, WebsiteRevenue=0, DarazRevenue=0, MarkazRevenue=0 });
        }

        // ============================================================
        // GET SALES LIST
        // ============================================================
        [WebMethod]
        public static string GetSales(string platform = "", string status = "")
        {
            var list = new List<object>();
            using (var conn = GetConnection())
            {
                conn.Open();
                var where = "WHERE 1=1";
                if (!string.IsNullOrEmpty(platform)) where += " AND s.Platform = @Platform";
                if (!string.IsNullOrEmpty(status))   where += " AND s.Status = @Status";

                var sql = @"
                    SELECT s.SaleId, s.BillNumber, s.Platform, s.SaleDate,
                           s.TotalQty, s.TotalAmount, s.Status, s.Notes, s.CreatedDate,
                           s.CustomerId,
                           CASE WHEN s.CustomerId IS NOT NULL THEN 1 ELSE 0 END AS HasCustomer,
                           COUNT(si.SaleItemId) AS ItemCount
                    FROM Sales s
                    LEFT JOIN SaleItems si ON si.SaleId = s.SaleId
                    " + where + @"
                    GROUP BY s.SaleId, s.BillNumber, s.Platform, s.SaleDate,
                             s.TotalQty, s.TotalAmount, s.Status, s.Notes, s.CreatedDate,
                             s.CustomerId
                    ORDER BY s.CreatedDate DESC";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(platform)) cmd.Parameters.AddWithValue("@Platform", platform);
                    if (!string.IsNullOrEmpty(status))   cmd.Parameters.AddWithValue("@Status",   status);

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
                                CreatedDate = Convert.ToDateTime(rdr["CreatedDate"]).ToString("dd-MMM-yyyy")
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

                using (var cmd = new SqlCommand("SELECT * FROM Sales WHERE SaleId = @Id", conn))
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
                                Notes       = SafeStr(rdr, "Notes")
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
                                TotalAmount = SafeDec(rdr2, "TotalAmount")
                            });
                        }
                    }
                }
                return JsonConvert.SerializeObject(new { Sale = sale, Items = items });
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
                    WHERE  pv.SKUNumbers = @SKU
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
        public static string SaveSale(SaleModel sale, string itemsJson, string customersJson = "")
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

                    // Insert Sale header
                    const string insertSale = @"
                        INSERT INTO Sales (BillNumber, Platform, SaleDate, TotalQty, TotalAmount, Status, Notes)
                        OUTPUT INSERTED.SaleId
                        VALUES (@BillNumber, @Platform, @SaleDate, @TotalQty, @TotalAmount, 'Completed', @Notes)";

                    using (var cmd = new SqlCommand(insertSale, conn))
                    {
                        cmd.Parameters.AddWithValue("@BillNumber",  sale.BillNumber.Trim());
                        cmd.Parameters.AddWithValue("@Platform",    sale.Platform);
                        cmd.Parameters.AddWithValue("@SaleDate",    DateTime.Parse(sale.SaleDate));
                        cmd.Parameters.AddWithValue("@TotalQty",    totalQty);
                        cmd.Parameters.AddWithValue("@TotalAmount", totalAmount);
                        cmd.Parameters.AddWithValue("@Notes",       (object)(sale.Notes?.Trim()) ?? DBNull.Value);
                        saleId = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    // Insert items + deduct stock
                    foreach (var it in items)
                    {
                        decimal lineTotal = it.Quantity * it.SalePrice;

                        const string insertItem = @"
                            INSERT INTO SaleItems
                                (SaleId, VariantId, SKUNumber, ProductName, Color, Size, Quantity, SalePrice, TotalAmount)
                            VALUES
                                (@SaleId, @VariantId, @SKUNumber, @ProductName, @Color, @Size, @Quantity, @SalePrice, @TotalAmount)";

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
                            cmd.ExecuteNonQuery();
                        }

                        // Deduct stock from variant
                        if (it.VariantId > 0)
                        {
                            using (var cmd = new SqlCommand(
                                "UPDATE ProductVariants SET StockQuantity = StockQuantity - @qty WHERE VariantId = @vid AND StockQuantity >= @qty", conn))
                            {
                                cmd.Parameters.AddWithValue("@qty", it.Quantity);
                                cmd.Parameters.AddWithValue("@vid", it.VariantId);
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

                // Save all BOL customers (bulk — upsert by phone)
                if (!string.IsNullOrWhiteSpace(customersJson))
                {
                    var bolCustomers = JsonConvert.DeserializeObject<List<CustomerRecord>>(customersJson)
                                       ?? new List<CustomerRecord>();
                    using (var cc = GetConnection())
                    {
                        cc.Open();
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

                            if (existId == 0)
                            {
                                using (var ins = new SqlCommand(@"
                                    INSERT INTO Customers (Name, Phone, Destination, Address, BuyingCount)
                                    VALUES (@N, @P, @Dest, @A, 1)", cc))
                                {
                                    ins.Parameters.AddWithValue("@N",    c.Name?.Trim()                 ?? "");
                                    ins.Parameters.AddWithValue("@P",    ph);
                                    ins.Parameters.AddWithValue("@Dest", (object)(c.Destination?.Trim()) ?? DBNull.Value);
                                    ins.Parameters.AddWithValue("@A",    (object)(c.Address?.Trim())     ?? DBNull.Value);
                                    ins.ExecuteNonQuery();
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
                                }
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

                    // Restore stock in one JOIN update
                    const string restoreSql = @"
                        UPDATE pv
                        SET    pv.StockQuantity = pv.StockQuantity + si.Quantity
                        FROM   ProductVariants pv
                        INNER JOIN SaleItems si ON si.VariantId = pv.VariantId
                        WHERE  si.SaleId = @Id AND si.VariantId IS NOT NULL";

                    using (var cmd = new SqlCommand(restoreSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", saleId);
                        cmd.ExecuteNonQuery();
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
                        return JsonConvert.SerializeObject(saleDate + "-" + seq);
                    }
                }
            }
            catch
            {
                return JsonConvert.SerializeObject(saleDate + "-01");
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
                var extracted  = new List<object>();
                var customers  = new List<object>();

                var pages = bolText.Split(new[] { "---PAGE---" }, StringSplitOptions.RemoveEmptyEntries);

                using (var conn = GetConnection())
                {
                    conn.Open();

                    foreach (var page in pages)
                    {
                        // ── Order Reference ─────────────────────────────
                        var orderMatch = Regex.Match(page, @"#(\d+)");
                        string orderRef = orderMatch.Success ? "#" + orderMatch.Groups[1].Value : "";

                        // ── Customer / Consignee data ────────────────────
                        // Name: "Name: Shahid Khan OMS Phone:"
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
                        // FullDesc = "Flat - 056 - Peach - Size 39"
                        var itemMatches = Regex.Matches(productsText,
                            @"\[(\d+)\s+X\s+[^\(]+\(([^)]+)\)",
                            RegexOptions.IgnoreCase);

                        foreach (Match m in itemMatches)
                        {
                            int    qty      = int.Parse(m.Groups[1].Value.Trim());
                            string fullDesc = m.Groups[2].Value.Trim(); // e.g. "Flat - 056 - Peach - Size 39"

                            // Extract ProductCode: first number after a dash  "- 056 -"
                            var codeM2 = Regex.Match(fullDesc, @"-\s*(\d+)\s*-");
                            // Extract Size: number after "Size"
                            var sizeM2 = Regex.Match(fullDesc, @"Size\s*-?\s*(\d+)", RegexOptions.IgnoreCase);

                            string productCode = codeM2.Success ? codeM2.Groups[1].Value.Trim() : "";
                            string size        = sizeM2.Success ? sizeM2.Groups[1].Value.Trim() : "";

                            var v = new VariantLookupResult
                            {
                                VariantId   = 0,
                                SKUNumber   = fullDesc,                            // show full BOL desc when not matched
                                ProductName = "(" + fullDesc + ")",
                                Color       = "",
                                Size        = size,
                                SalePrice   = cod,
                                Matched     = false
                            };

                            if (!string.IsNullOrEmpty(productCode) && !string.IsNullOrEmpty(size))
                            {
                                // Extract color from BOL description: "Flat - 056 - Peach - Size 39" → "Peach"
                                var colorM = Regex.Match(fullDesc,
                                    @"-\s*\d+\s*-\s*([\w\s]+?)\s*-?\s*Size",
                                    RegexOptions.IgnoreCase);
                                string bolColor = colorM.Success ? colorM.Groups[1].Value.Trim() : "";

                                const string skuSql = @"
                                    SELECT TOP 1 pv.VariantId, pv.SKUNumbers, pv.Color, pv.Size,
                                                 p.ProductName, p.ProductCode, p.SalePrice
                                    FROM   ProductVariants pv
                                    INNER JOIN Products p ON p.ProductId = pv.ProductId
                                    WHERE  pv.SKUNumbers LIKE @SKUPattern
                                      AND  pv.IsActive = 1
                                      AND  p.IsActive  = 1";

                                // Stage 1: match Code + Color + Size  (e.g. 056-%-Peach-39)
                                bool found = false;
                                if (!string.IsNullOrEmpty(bolColor))
                                {
                                    using (var cmd = new SqlCommand(skuSql, conn))
                                    {
                                        cmd.Parameters.AddWithValue("@SKUPattern",
                                            productCode + "-%-" + bolColor + "-" + size);
                                        using (var rdr = cmd.ExecuteReader())
                                        {
                                            if (rdr.Read())
                                            {
                                                v.VariantId   = Convert.ToInt32(rdr["VariantId"]);
                                                v.SKUNumber   = SafeStr(rdr, "SKUNumbers");
                                                v.ProductName = SafeStr(rdr, "ProductName");
                                                v.Color       = SafeStr(rdr, "Color");
                                                v.Size        = SafeStr(rdr, "Size");
                                                v.SalePrice   = SafeDec(rdr, "SalePrice");
                                                v.Matched     = true;
                                                found         = true;
                                            }
                                        }
                                    }
                                }

                                // Stage 2 fallback: match Code + Size only (e.g. 056-%-39)
                                if (!found)
                                {
                                    using (var cmd = new SqlCommand(skuSql, conn))
                                    {
                                        cmd.Parameters.AddWithValue("@SKUPattern",
                                            productCode + "-%-" + size);
                                        using (var rdr = cmd.ExecuteReader())
                                        {
                                            if (rdr.Read())
                                            {
                                                v.VariantId   = Convert.ToInt32(rdr["VariantId"]);
                                                v.SKUNumber   = SafeStr(rdr, "SKUNumbers");
                                                v.ProductName = SafeStr(rdr, "ProductName");
                                                v.Color       = SafeStr(rdr, "Color");
                                                v.Size        = SafeStr(rdr, "Size");
                                                v.SalePrice   = SafeDec(rdr, "SalePrice");
                                                v.Matched     = true;
                                            }
                                        }
                                    }
                                }
                            }

                            extracted.Add(new
                            {
                                OrderRef    = orderRef,
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

        private static string Fail(string msg) =>
            JsonConvert.SerializeObject(new { success = false, message = msg });
    }
}
