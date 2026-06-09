using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class NewInvoice : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            EnsureTables();
        }

        // ── Models ───────────────────────────────────────────────────────────────

        public class InvoiceItemModel
        {
            public int     VariantId  { get; set; }
            public string  Size       { get; set; }
            public string  SKUNumber  { get; set; }
            public int     Qty        { get; set; }
            public decimal SalePrice  { get; set; }
        }

        public class InvoiceModel
        {
            public int     CustomerId  { get; set; }
            public string  InvoiceDate { get; set; }
            public decimal Discount    { get; set; }
            public string  Notes       { get; set; }
            public List<InvoiceItemModel> Items { get; set; }
        }

        // ── Helpers ──────────────────────────────────────────────────────────────

        private static SqlConnection GetConnection() =>
            new SqlConnection(ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString);

        private static string Ok(string msg, object data = null) =>
            JsonConvert.SerializeObject(new { success = true, message = msg, data = data });

        private static string Fail(string msg) =>
            JsonConvert.SerializeObject(new { success = false, message = msg });

        // ── Schema ───────────────────────────────────────────────────────────────

        private void EnsureTables()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'B2BCustomers')
                        BEGIN
                            CREATE TABLE B2BCustomers (
                                CustomerId      INT IDENTITY(1,1) PRIMARY KEY,
                                ShopName        NVARCHAR(200) NOT NULL,
                                PersonName      NVARCHAR(150) NOT NULL,
                                ContactNo1      NVARCHAR(30)  NOT NULL,
                                ContactNo2      NVARCHAR(30)  NULL,
                                ShopAddress     NVARCHAR(500) NOT NULL,
                                OpeningBalance  DECIMAL(18,2) NOT NULL DEFAULT 0,
                                City            NVARCHAR(100) NULL,
                                Email           NVARCHAR(150) NULL,
                                Notes           NVARCHAR(500) NULL,
                                IsActive        BIT           NOT NULL DEFAULT 1,
                                IsDeleted       BIT           NOT NULL DEFAULT 0,
                                CreatedDate     DATETIME      NOT NULL DEFAULT GETDATE()
                            )
                        END
                        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CustomerInvoices')
                        BEGIN
                            CREATE TABLE CustomerInvoices (
                                InvoiceId     INT IDENTITY(1,1) PRIMARY KEY,
                                InvoiceNumber NVARCHAR(100) NOT NULL,
                                CustomerId    INT           NOT NULL,
                                InvoiceDate   DATE          NOT NULL,
                                TotalQty      INT           NOT NULL DEFAULT 0,
                                TotalAmount   DECIMAL(18,2) NOT NULL DEFAULT 0,
                                Discount      DECIMAL(18,2) NOT NULL DEFAULT 0,
                                GrandTotal    DECIMAL(18,2) NOT NULL DEFAULT 0,
                                Notes         NVARCHAR(500) NULL,
                                Status        NVARCHAR(50)  NOT NULL DEFAULT 'Active',
                                CreatedDate   DATETIME      NOT NULL DEFAULT GETDATE(),
                                CONSTRAINT FK_CustInv_Customer FOREIGN KEY (CustomerId) REFERENCES B2BCustomers(CustomerId)
                            )
                        END
                        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CustomerInvoiceItems')
                        BEGIN
                            CREATE TABLE CustomerInvoiceItems (
                                ItemId      INT IDENTITY(1,1) PRIMARY KEY,
                                InvoiceId   INT           NOT NULL,
                                VariantId   INT           NULL,
                                Size        NVARCHAR(20)  NOT NULL,
                                SKUNumber   NVARCHAR(200) NULL,
                                Qty         INT           NOT NULL DEFAULT 1,
                                SalePrice   DECIMAL(18,2) NOT NULL DEFAULT 0,
                                Total       DECIMAL(18,2) NOT NULL DEFAULT 0,
                                CONSTRAINT FK_CustInvItem_Invoice FOREIGN KEY (InvoiceId) REFERENCES CustomerInvoices(InvoiceId)
                            )
                        END
                        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CustomerLedger')
                        BEGIN
                            CREATE TABLE CustomerLedger (
                                LedgerId        INT IDENTITY(1,1) PRIMARY KEY,
                                CustomerId      INT           NOT NULL,
                                InvoiceId       INT           NULL,
                                TransactionType NVARCHAR(50)  NOT NULL,
                                Amount          DECIMAL(18,2) NOT NULL,
                                Notes           NVARCHAR(500) NULL,
                                CreatedDate     DATETIME      NOT NULL DEFAULT GETDATE(),
                                CONSTRAINT FK_Ledger_Customer FOREIGN KEY (CustomerId) REFERENCES B2BCustomers(CustomerId),
                                CONSTRAINT FK_Ledger_Invoice  FOREIGN KEY (InvoiceId)  REFERENCES CustomerInvoices(InvoiceId)
                            )
                        END", conn))
                    {
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch { }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  DROPDOWNS
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetB2BCustomers()
        {
            var list = new List<object>();
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT CustomerId, ShopName, PersonName, ContactNo1
                        FROM   B2BCustomers
                        WHERE  IsActive = 1 AND IsDeleted = 0
                        ORDER  BY ShopName", conn))
                    using (var r = cmd.ExecuteReader())
                        while (r.Read())
                            list.Add(new {
                                CustomerId = Convert.ToInt32(r["CustomerId"]),
                                ShopName   = r["ShopName"].ToString(),
                                PersonName = r["PersonName"].ToString(),
                                ContactNo1 = r["ContactNo1"].ToString()
                            });
                }
            }
            catch { }
            return JsonConvert.SerializeObject(list);
        }

        [WebMethod]
        public static string GetProductsForDropdown()
        {
            var list = new List<object>();
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT ProductId, ProductName, ProductCode
                        FROM   Products
                        WHERE  IsActive = 1
                        ORDER  BY ProductName", conn))
                    using (var r = cmd.ExecuteReader())
                        while (r.Read())
                            list.Add(new {
                                ProductId   = Convert.ToInt32(r["ProductId"]),
                                ProductName = r["ProductName"].ToString(),
                                ProductCode = r["ProductCode"].ToString()
                            });
                }
            }
            catch { }
            return JsonConvert.SerializeObject(list);
        }

        [WebMethod]
        public static string GetColorsByProduct(int productId)
        {
            var list = new List<string>();
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT DISTINCT Color
                        FROM   ProductVariants
                        WHERE  ProductId = @PId AND IsActive = 1
                        ORDER  BY Color", conn))
                    {
                        cmd.Parameters.AddWithValue("@PId", productId);
                        using (var r = cmd.ExecuteReader())
                            while (r.Read())
                                list.Add(r["Color"].ToString());
                    }
                }
            }
            catch { }
            return JsonConvert.SerializeObject(list);
        }

        [WebMethod]
        public static string GetVariantsByProductColor(int productId, string color)
        {
            var list = new List<object>();
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT pv.VariantId, pv.Size, pv.SKUNumbers, pv.StockQuantity,
                               p.SalePrice
                        FROM   ProductVariants pv
                        INNER  JOIN Products p ON p.ProductId = pv.ProductId
                        WHERE  pv.ProductId = @PId AND pv.Color = @Color AND pv.IsActive = 1
                        ORDER  BY TRY_CAST(pv.Size AS INT), pv.Size", conn))
                    {
                        cmd.Parameters.AddWithValue("@PId",   productId);
                        cmd.Parameters.AddWithValue("@Color", color ?? "");
                        using (var r = cmd.ExecuteReader())
                            while (r.Read())
                                list.Add(new {
                                    VariantId     = Convert.ToInt32(r["VariantId"]),
                                    Size          = r["Size"].ToString(),
                                    SKUNumbers    = r["SKUNumbers"] == DBNull.Value ? "" : r["SKUNumbers"].ToString(),
                                    StockQuantity = Convert.ToInt32(r["StockQuantity"]),
                                    SalePrice     = Convert.ToDecimal(r["SalePrice"])
                                });
                    }
                }
            }
            catch { }
            return JsonConvert.SerializeObject(list);
        }

        [WebMethod]
        public static string GetNextInvoiceNumber()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    var today = DateTime.Now.ToString("yyyy-MM-dd");
                    int seq;
                    using (var cmd = new SqlCommand(@"
                        SELECT COUNT(1) + 1
                        FROM   CustomerInvoices
                        WHERE  CONVERT(DATE, InvoiceDate) = @Today", conn))
                    {
                        cmd.Parameters.AddWithValue("@Today", today);
                        seq = Convert.ToInt32(cmd.ExecuteScalar());
                    }
                    return JsonConvert.SerializeObject(
                        string.Format("INV-{0}-{1:D2}", today, seq));
                }
            }
            catch
            {
                return JsonConvert.SerializeObject("INV-" + DateTime.Now.ToString("yyyy-MM-dd") + "-01");
            }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  SAVE INVOICE
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string SaveInvoice(InvoiceModel invoice)
        {
            if (invoice == null)                                    return Fail("Invalid request.");
            if (invoice.CustomerId <= 0)                            return Fail("Please select a customer.");
            if (string.IsNullOrWhiteSpace(invoice.InvoiceDate))     return Fail("Invoice date is required.");
            if (invoice.Items == null || invoice.Items.Count == 0)  return Fail("Add at least one item.");

            invoice.Items.RemoveAll(x => x.Qty <= 0);
            if (invoice.Items.Count == 0) return Fail("All items have zero quantity.");

            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var tran = conn.BeginTransaction())
                    {
                        try
                        {
                            int     totalQty   = 0;
                            decimal totalAmt   = 0;
                            foreach (var it in invoice.Items)
                            {
                                totalQty += it.Qty;
                                totalAmt += it.Qty * it.SalePrice;
                            }
                            decimal discount   = invoice.Discount < 0 ? 0 : invoice.Discount;
                            decimal grandTotal = totalAmt - discount;
                            if (grandTotal < 0) grandTotal = 0;

                            // Sequence for today
                            int seq;
                            using (var cmd = new SqlCommand(@"
                                SELECT COUNT(1) + 1
                                FROM CustomerInvoices
                                WHERE CONVERT(DATE, InvoiceDate) = @Today",
                                conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@Today", invoice.InvoiceDate);
                                seq = Convert.ToInt32(cmd.ExecuteScalar());
                            }
                            var invNum = string.Format("INV-{0}-{1:D2}", invoice.InvoiceDate, seq);

                            // Insert header
                            int invoiceId;
                            using (var cmd = new SqlCommand(@"
                                INSERT INTO CustomerInvoices
                                    (InvoiceNumber, CustomerId, InvoiceDate, TotalQty,
                                     TotalAmount, Discount, GrandTotal, Notes, Status, CreatedDate)
                                VALUES
                                    (@Num, @CustId, @Date, @TotalQty,
                                     @TotalAmt, @Disc, @Grand, @Notes, 'Active', GETDATE());
                                SELECT SCOPE_IDENTITY();",
                                conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@Num",      invNum);
                                cmd.Parameters.AddWithValue("@CustId",   invoice.CustomerId);
                                cmd.Parameters.AddWithValue("@Date",     invoice.InvoiceDate);
                                cmd.Parameters.AddWithValue("@TotalQty", totalQty);
                                cmd.Parameters.AddWithValue("@TotalAmt", totalAmt);
                                cmd.Parameters.AddWithValue("@Disc",     discount);
                                cmd.Parameters.AddWithValue("@Grand",    grandTotal);
                                cmd.Parameters.AddWithValue("@Notes",
                                    string.IsNullOrWhiteSpace(invoice.Notes)
                                        ? (object)DBNull.Value : invoice.Notes.Trim());
                                invoiceId = Convert.ToInt32(cmd.ExecuteScalar());
                            }

                            // Insert items
                            foreach (var it in invoice.Items)
                            {
                                using (var cmd = new SqlCommand(@"
                                    INSERT INTO CustomerInvoiceItems
                                        (InvoiceId, VariantId, Size, SKUNumber, Qty, SalePrice, Total)
                                    VALUES
                                        (@InvId, @VarId, @Size, @SKU, @Qty, @Price, @Total)",
                                    conn, tran))
                                {
                                    cmd.Parameters.AddWithValue("@InvId", invoiceId);
                                    cmd.Parameters.AddWithValue("@VarId",
                                        it.VariantId > 0 ? (object)it.VariantId : DBNull.Value);
                                    cmd.Parameters.AddWithValue("@Size",  it.Size ?? "");
                                    cmd.Parameters.AddWithValue("@SKU",
                                        string.IsNullOrWhiteSpace(it.SKUNumber)
                                            ? (object)DBNull.Value : it.SKUNumber);
                                    cmd.Parameters.AddWithValue("@Qty",   it.Qty);
                                    cmd.Parameters.AddWithValue("@Price", it.SalePrice);
                                    cmd.Parameters.AddWithValue("@Total", it.Qty * it.SalePrice);
                                    cmd.ExecuteNonQuery();
                                }
                            }

                            // Ledger entry
                            using (var cmd = new SqlCommand(@"
                                INSERT INTO CustomerLedger
                                    (CustomerId, InvoiceId, TransactionType, Amount, Notes, CreatedDate)
                                VALUES
                                    (@CustId, @InvId, 'Invoice', @Amount, @Notes, GETDATE())",
                                conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@CustId", invoice.CustomerId);
                                cmd.Parameters.AddWithValue("@InvId",  invoiceId);
                                cmd.Parameters.AddWithValue("@Amount", grandTotal);
                                cmd.Parameters.AddWithValue("@Notes",  "Invoice " + invNum);
                                cmd.ExecuteNonQuery();
                            }

                            tran.Commit();
                            return Ok("Invoice " + invNum + " saved successfully.",
                                new { InvoiceId = invoiceId, InvoiceNumber = invNum });
                        }
                        catch { tran.Rollback(); throw; }
                    }
                }
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }
    }
}
