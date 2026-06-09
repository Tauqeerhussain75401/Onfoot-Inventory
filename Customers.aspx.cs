using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Services;
using Newtonsoft.Json;

namespace Onfoot_Inventory
{
    public partial class Customers : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            EnsureB2BCustomersTable();
        }

        // ── Model ────────────────────────────────────────────────────────────────

        public class B2BCustomerModel
        {
            public int     CustomerId      { get; set; }
            public string  ShopName        { get; set; }
            public string  PersonName      { get; set; }
            public string  ContactNo1      { get; set; }
            public string  ContactNo2      { get; set; }
            public string  ShopAddress     { get; set; }
            public decimal OpeningBalance  { get; set; }
            public string  City            { get; set; }
            public string  Email           { get; set; }
            public string  Notes           { get; set; }
            public bool    IsActive        { get; set; }
        }

        // ── Helpers ──────────────────────────────────────────────────────────────

        private static SqlConnection GetConnection() =>
            new SqlConnection(ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString);

        private static string Ok(string msg) =>
            JsonConvert.SerializeObject(new { success = true,  message = msg });

        private static string Fail(string msg) =>
            JsonConvert.SerializeObject(new { success = false, message = msg });

        private void EnsureB2BCustomersTable()
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
                                ShopName        NVARCHAR(200)  NOT NULL,
                                PersonName      NVARCHAR(150)  NOT NULL,
                                ContactNo1      NVARCHAR(30)   NOT NULL,
                                ContactNo2      NVARCHAR(30)   NULL,
                                ShopAddress     NVARCHAR(500)  NOT NULL,
                                OpeningBalance  DECIMAL(18,2)  NOT NULL DEFAULT 0,
                                City            NVARCHAR(100)  NULL,
                                Email           NVARCHAR(150)  NULL,
                                Notes           NVARCHAR(500)  NULL,
                                IsActive        BIT            NOT NULL DEFAULT 1,
                                IsDeleted       BIT            NOT NULL DEFAULT 0,
                                CreatedDate     DATETIME       NOT NULL DEFAULT GETDATE()
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
        public static string GetCustomerStats()
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    int total = 0, active = 0;
                    decimal totalBalance = 0;

                    using (var cmd = new SqlCommand(
                        @"SELECT
                            COUNT(*)                                    AS Total,
                            SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS Active,
                            ISNULL(SUM(OpeningBalance), 0)              AS TotalBalance
                          FROM B2BCustomers
                          WHERE IsDeleted = 0", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            total        = Convert.ToInt32(r["Total"]);
                            active       = Convert.ToInt32(r["Active"]);
                            totalBalance = Convert.ToDecimal(r["TotalBalance"]);
                        }
                    }

                    return JsonConvert.SerializeObject(new
                    {
                        Total               = total,
                        Active              = active,
                        TotalOpeningBalance = totalBalance
                    });
                }
            }
            catch (Exception ex)
            {
                return JsonConvert.SerializeObject(new { Total = 0, Active = 0, TotalOpeningBalance = 0 });
            }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  LIST
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetCustomers()
        {
            try
            {
                var list = new List<object>();
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT CustomerId, ShopName, PersonName, ContactNo1, ContactNo2,
                               ShopAddress, OpeningBalance, City, Email, Notes, IsActive, CreatedDate
                        FROM   B2BCustomers
                        WHERE  IsDeleted = 0
                        ORDER  BY ShopName", conn))
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                            list.Add(new {
                                CustomerId     = Convert.ToInt32(r["CustomerId"]),
                                ShopName       = r["ShopName"].ToString(),
                                PersonName     = r["PersonName"].ToString(),
                                ContactNo1     = r["ContactNo1"].ToString(),
                                ContactNo2     = r["ContactNo2"] == DBNull.Value ? "" : r["ContactNo2"].ToString(),
                                ShopAddress    = r["ShopAddress"].ToString(),
                                OpeningBalance = Convert.ToDecimal(r["OpeningBalance"]),
                                City           = r["City"]  == DBNull.Value ? "" : r["City"].ToString(),
                                Email          = r["Email"] == DBNull.Value ? "" : r["Email"].ToString(),
                                Notes          = r["Notes"] == DBNull.Value ? "" : r["Notes"].ToString(),
                                IsActive       = Convert.ToBoolean(r["IsActive"]),
                                CreatedDate    = Convert.ToDateTime(r["CreatedDate"]).ToString("dd-MMM-yyyy")
                            });
                    }
                }
                return JsonConvert.SerializeObject(list);
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  GET BY ID
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string GetCustomerById(int customerId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(@"
                        SELECT CustomerId, ShopName, PersonName, ContactNo1, ContactNo2,
                               ShopAddress, OpeningBalance, City, Email, Notes, IsActive
                        FROM   B2BCustomers
                        WHERE  CustomerId = @Id AND IsDeleted = 0", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", customerId);
                        using (var r = cmd.ExecuteReader())
                        {
                            if (r.Read())
                                return JsonConvert.SerializeObject(new {
                                    CustomerId     = Convert.ToInt32(r["CustomerId"]),
                                    ShopName       = r["ShopName"].ToString(),
                                    PersonName     = r["PersonName"].ToString(),
                                    ContactNo1     = r["ContactNo1"].ToString(),
                                    ContactNo2     = r["ContactNo2"] == DBNull.Value ? "" : r["ContactNo2"].ToString(),
                                    ShopAddress    = r["ShopAddress"].ToString(),
                                    OpeningBalance = Convert.ToDecimal(r["OpeningBalance"]),
                                    City           = r["City"]  == DBNull.Value ? "" : r["City"].ToString(),
                                    Email          = r["Email"] == DBNull.Value ? "" : r["Email"].ToString(),
                                    Notes          = r["Notes"] == DBNull.Value ? "" : r["Notes"].ToString(),
                                    IsActive       = Convert.ToBoolean(r["IsActive"])
                                });
                        }
                    }
                }
                return "null";
            }
            catch (Exception ex) { throw new Exception(ex.Message); }
        }

        // ════════════════════════════════════════════════════════════════════════
        //  SAVE (INSERT / UPDATE)
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string SaveCustomer(B2BCustomerModel customer)
        {
            try
            {
                if (customer == null)
                    return Fail("Invalid request.");

                if (string.IsNullOrWhiteSpace(customer.ShopName))
                    return Fail("Shop Name is required.");
                if (string.IsNullOrWhiteSpace(customer.PersonName))
                    return Fail("Person Name is required.");
                if (string.IsNullOrWhiteSpace(customer.ContactNo1))
                    return Fail("Contact No 1 is required.");

                if (string.IsNullOrWhiteSpace(customer.ShopAddress))
                    return Fail("Shop Address is required.");

                using (var conn = GetConnection())
                {
                    conn.Open();

                    // Duplicate shop name check (same city, if provided)
                    using (var chk = new SqlCommand(@"
                        SELECT COUNT(1) FROM B2BCustomers
                        WHERE  ShopName = @Name AND CustomerId <> @Id AND IsDeleted = 0", conn))
                    {
                        chk.Parameters.AddWithValue("@Name", customer.ShopName.Trim());
                        chk.Parameters.AddWithValue("@Id",   customer.CustomerId);
                        if (Convert.ToInt32(chk.ExecuteScalar()) > 0)
                            return Fail("A customer with shop name '" + customer.ShopName.Trim() + "' already exists.");
                    }

                    if (customer.CustomerId == 0)
                    {
                        using (var cmd = new SqlCommand(@"
                            INSERT INTO B2BCustomers
                                (ShopName, PersonName, ContactNo1, ContactNo2, ShopAddress,
                                 OpeningBalance, City, Email, Notes, IsActive, IsDeleted, CreatedDate)
                            VALUES
                                (@ShopName, @PersonName, @Contact1, @Contact2, @Address,
                                 @Balance, @City, @Email, @Notes, @Active, 0, GETDATE())", conn))
                        {
                            BindParams(cmd, customer);
                            cmd.ExecuteNonQuery();
                        }
                        return Ok("Customer added successfully.");
                    }
                    else
                    {
                        using (var cmd = new SqlCommand(@"
                            UPDATE B2BCustomers
                            SET ShopName       = @ShopName,
                                PersonName     = @PersonName,
                                ContactNo1     = @Contact1,
                                ContactNo2     = @Contact2,
                                ShopAddress    = @Address,
                                OpeningBalance = @Balance,
                                City           = @City,
                                Email          = @Email,
                                Notes          = @Notes,
                                IsActive       = @Active
                            WHERE CustomerId = @Id AND IsDeleted = 0", conn))
                        {
                            BindParams(cmd, customer);
                            cmd.Parameters.AddWithValue("@Id", customer.CustomerId);
                            cmd.ExecuteNonQuery();
                        }
                        return Ok("Customer updated successfully.");
                    }
                }
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }

        private static void BindParams(SqlCommand cmd, B2BCustomerModel c)
        {
            cmd.Parameters.AddWithValue("@ShopName",   c.ShopName.Trim());
            cmd.Parameters.AddWithValue("@PersonName", c.PersonName.Trim());
            cmd.Parameters.AddWithValue("@Contact1",   c.ContactNo1.Trim());
            cmd.Parameters.AddWithValue("@Contact2",   string.IsNullOrWhiteSpace(c.ContactNo2) ? (object)DBNull.Value : c.ContactNo2.Trim());
            cmd.Parameters.AddWithValue("@Address",    c.ShopAddress.Trim());
            cmd.Parameters.AddWithValue("@Balance",    c.OpeningBalance);
            cmd.Parameters.AddWithValue("@City",       string.IsNullOrWhiteSpace(c.City)  ? (object)DBNull.Value : c.City.Trim());
            cmd.Parameters.AddWithValue("@Email",      string.IsNullOrWhiteSpace(c.Email) ? (object)DBNull.Value : c.Email.Trim());
            cmd.Parameters.AddWithValue("@Notes",      string.IsNullOrWhiteSpace(c.Notes) ? (object)DBNull.Value : c.Notes.Trim());
            cmd.Parameters.AddWithValue("@Active",     c.IsActive);
        }

        // ════════════════════════════════════════════════════════════════════════
        //  DELETE (soft)
        // ════════════════════════════════════════════════════════════════════════

        [WebMethod]
        public static string DeleteCustomer(int customerId)
        {
            try
            {
                using (var conn = GetConnection())
                {
                    conn.Open();
                    using (var cmd = new SqlCommand(
                        "UPDATE B2BCustomers SET IsDeleted = 1 WHERE CustomerId = @Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", customerId);
                        cmd.ExecuteNonQuery();
                    }
                }
                return Ok("Customer deleted successfully.");
            }
            catch (Exception ex) { return Fail("Error: " + ex.Message); }
        }
    }
}
