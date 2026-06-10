using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class CustomerBilling : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            EnsureTables();
        }

        // ── Helpers ──────────────────────────────────────────────────────────────

        private static SqlConnection GetConnection() =>
            new SqlConnection(ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString);

        private static string Ok(string msg) =>
            JsonConvert.SerializeObject(new { success = true, message = msg });

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
        //  STATS
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetInvoiceStats()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT COUNT(*)                   AS TotalInvoices,
                               ISNULL(SUM(GrandTotal), 0) AS TotalAmount,
                               COUNT(DISTINCT CustomerId) AS TotalCustomers
                        FROM   CustomerInvoices
                        WHERE  Status = 'Active'", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                            return JsonConvert.SerializeObject(new {
                                TotalInvoices  = Convert.ToInt32(r["TotalInvoices"]),
                                TotalAmount    = Convert.ToDecimal(r["TotalAmount"]),
                                TotalCustomers = Convert.ToInt32(r["TotalCustomers"])
                            });
                    }
                }
            }
            catch { }
            return JsonConvert.SerializeObject(new { TotalInvoices = 0, TotalAmount = 0m, TotalCustomers = 0 });
        }

        // ════════════════════════════════════════════════════════════════════════
        //  INVOICES LIST
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetInvoices()
        {
            var list = new List<object>();
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT ci.InvoiceId, ci.InvoiceNumber, ci.InvoiceDate,
                               ci.TotalQty, ci.TotalAmount, ci.Discount, ci.GrandTotal,
                               ci.Notes, ci.Status, ci.CustomerId,
                               b.ShopName, b.PersonName, b.ContactNo1
                        FROM   CustomerInvoices ci
                        INNER  JOIN B2BCustomers b ON b.CustomerId = ci.CustomerId
                        ORDER  BY ci.CreatedDate DESC", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                            list.Add(new {
                                InvoiceId     = Convert.ToInt32(r["InvoiceId"]),
                                InvoiceNumber = r["InvoiceNumber"].ToString(),
                                InvoiceDate   = Convert.ToDateTime(r["InvoiceDate"]).ToString("dd-MMM-yyyy"),
                                TotalQty      = Convert.ToInt32(r["TotalQty"]),
                                TotalAmount   = Convert.ToDecimal(r["TotalAmount"]),
                                Discount      = Convert.ToDecimal(r["Discount"]),
                                GrandTotal    = Convert.ToDecimal(r["GrandTotal"]),
                                Notes         = r["Notes"] == DBNull.Value ? "" : r["Notes"].ToString(),
                                Status        = r["Status"].ToString(),
                                CustomerId    = Convert.ToInt32(r["CustomerId"]),
                                ShopName      = r["ShopName"].ToString(),
                                PersonName    = r["PersonName"].ToString(),
                                ContactNo1    = r["ContactNo1"].ToString()
                            });
                    }
                }
            }
            catch { }
            return JsonConvert.SerializeObject(list);
        }

        // ════════════════════════════════════════════════════════════════════════
        //  INVOICE DETAIL
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetInvoiceById(int invoiceId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    object header = null;
                    using (var cmd = new SqlCommand(@"
                        SELECT ci.InvoiceId, ci.InvoiceNumber, ci.InvoiceDate,
                               ci.TotalQty, ci.TotalAmount, ci.Discount, ci.GrandTotal,
                               ci.Notes, ci.Status, ci.CustomerId,
                               b.ShopName, b.PersonName, b.ContactNo1, b.ShopAddress, b.City
                        FROM   CustomerInvoices ci
                        INNER  JOIN B2BCustomers b ON b.CustomerId = ci.CustomerId
                        WHERE  ci.InvoiceId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", invoiceId);
                        using (var r = cmd.ExecuteReader())
                        {
                            if (r.Read())
                                header = new {
                                    InvoiceId     = Convert.ToInt32(r["InvoiceId"]),
                                    InvoiceNumber = r["InvoiceNumber"].ToString(),
                                    InvoiceDate   = Convert.ToDateTime(r["InvoiceDate"]).ToString("dd-MMM-yyyy"),
                                    TotalQty      = Convert.ToInt32(r["TotalQty"]),
                                    TotalAmount   = Convert.ToDecimal(r["TotalAmount"]),
                                    Discount      = Convert.ToDecimal(r["Discount"]),
                                    GrandTotal    = Convert.ToDecimal(r["GrandTotal"]),
                                    Notes         = r["Notes"] == DBNull.Value ? "" : r["Notes"].ToString(),
                                    Status        = r["Status"].ToString(),
                                    CustomerId    = Convert.ToInt32(r["CustomerId"]),
                                    ShopName      = r["ShopName"].ToString(),
                                    PersonName    = r["PersonName"].ToString(),
                                    ContactNo1    = r["ContactNo1"].ToString(),
                                    ShopAddress   = r["ShopAddress"].ToString(),
                                    City          = r["City"] == DBNull.Value ? "" : r["City"].ToString()
                                };
                        }
                    }

                    var items = new List<object>();
                    using (var cmd2 = new SqlCommand(@"
                        SELECT ItemId, VariantId, Size, SKUNumber, Qty, SalePrice, Total
                        FROM   CustomerInvoiceItems
                        WHERE  InvoiceId = @Id
                        ORDER  BY ItemId", conn))
                    {
                        cmd2.Parameters.AddWithValue("@Id", invoiceId);
                        using (var r2 = cmd2.ExecuteReader())
                        {
                            while (r2.Read())
                                items.Add(new {
                                    ItemId    = Convert.ToInt32(r2["ItemId"]),
                                    VariantId = r2["VariantId"] == DBNull.Value ? 0 : Convert.ToInt32(r2["VariantId"]),
                                    Size      = r2["Size"].ToString(),
                                    SKUNumber = r2["SKUNumber"] == DBNull.Value ? "" : r2["SKUNumber"].ToString(),
                                    Qty       = Convert.ToInt32(r2["Qty"]),
                                    SalePrice = Convert.ToDecimal(r2["SalePrice"]),
                                    Total     = Convert.ToDecimal(r2["Total"])
                                });
                        }
                    }

                    return JsonConvert.SerializeObject(new { header, items });
                }
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  CUSTOMER LEDGER
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetCustomerLedger(int customerId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    object customer = null;
                    using (var cmd = new SqlCommand(@"
                        SELECT CustomerId, ShopName, PersonName, ContactNo1, OpeningBalance, CreatedDate
                        FROM   B2BCustomers WHERE CustomerId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", customerId);
                        using (var r = cmd.ExecuteReader())
                        {
                            if (r.Read())
                                customer = new {
                                    CustomerId     = Convert.ToInt32(r["CustomerId"]),
                                    ShopName       = r["ShopName"].ToString(),
                                    PersonName     = r["PersonName"].ToString(),
                                    ContactNo1     = r["ContactNo1"].ToString(),
                                    OpeningBalance = Convert.ToDecimal(r["OpeningBalance"]),
                                    CreatedDate    = Convert.ToDateTime(r["CreatedDate"]).ToString("dd-MMM-yyyy")
                                };
                        }
                    }

                    var entries = new List<object>();
                    using (var cmd = new SqlCommand(@"
                        SELECT cl.LedgerId, cl.TransactionType, cl.Amount, cl.Notes,
                               cl.CreatedDate, ci.InvoiceNumber
                        FROM   CustomerLedger cl
                        LEFT   JOIN CustomerInvoices ci ON ci.InvoiceId = cl.InvoiceId
                        WHERE  cl.CustomerId = @Id
                        ORDER  BY cl.CreatedDate ASC, cl.LedgerId ASC", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", customerId);
                        using (var r = cmd.ExecuteReader())
                        {
                            while (r.Read())
                                entries.Add(new {
                                    LedgerId        = Convert.ToInt32(r["LedgerId"]),
                                    TransactionType = r["TransactionType"].ToString(),
                                    Amount          = Convert.ToDecimal(r["Amount"]),
                                    Notes           = r["Notes"] == DBNull.Value ? "" : r["Notes"].ToString(),
                                    CreatedDate     = Convert.ToDateTime(r["CreatedDate"]).ToString("dd-MMM-yyyy"),
                                    InvoiceNumber   = r["InvoiceNumber"] == DBNull.Value ? "" : r["InvoiceNumber"].ToString()
                                });
                        }
                    }

                    return JsonConvert.SerializeObject(new { customer, entries });
                }
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  CANCEL INVOICE
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string CancelInvoice(int invoiceId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var tran = conn.BeginTransaction())
                    {
                        try
                        {
                            using (var cmd = new SqlCommand(
                                "UPDATE CustomerInvoices SET Status='Cancelled' WHERE InvoiceId=@Id",
                                conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@Id", invoiceId);
                                cmd.ExecuteNonQuery();
                            }
                            using (var cmd = new SqlCommand(
                                "DELETE FROM CustomerLedger WHERE InvoiceId=@Id",
                                conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@Id", invoiceId);
                                cmd.ExecuteNonQuery();
                            }
                            tran.Commit();
                            return Ok("Invoice cancelled successfully.");
                        }
                        catch { tran.Rollback(); throw; }
                    }
                }
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }
    }
}
