using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Security;
using System.Web.UI;

namespace Onfoot_Inventory
{
    public partial class Login : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            UnobtrusiveValidationMode = System.Web.UI.UnobtrusiveValidationMode.None;

            if (!IsPostBack && User.Identity.IsAuthenticated)
                Response.Redirect("~/Default.aspx", true);
        }

        protected void btnLogin_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            string username = txtUsername.Text.Trim();
            string password = txtPassword.Text;

            string connStr = ConfigurationManager.ConnectionStrings["OnfootDB"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                const string sql = @"
                    SELECT UserID, FullName, Role
                    FROM   dbo.Users
                    WHERE  Username  = @u
                      AND  Password  = @p
                      AND  IsActive  = 1";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@u", username);
                    cmd.Parameters.AddWithValue("@p", password);

                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            int    userId   = (int)dr["UserID"];
                            string fullName = dr["FullName"].ToString();
                            string role     = dr["Role"].ToString();
                            dr.Close();

                            // Record last login time
                            using (SqlCommand upd = new SqlCommand(
                                "UPDATE dbo.Users SET LastLogin = @now WHERE UserID = @id", conn))
                            {
                                upd.Parameters.AddWithValue("@now", DateTime.Now);
                                upd.Parameters.AddWithValue("@id", userId);
                                upd.ExecuteNonQuery();
                            }

                            // Persist user info in session for display
                            Session["UserID"]   = userId;
                            Session["Username"] = username;
                            Session["FullName"] = fullName;
                            Session["Role"]     = role;

                            FormsAuthentication.SetAuthCookie(username, false);
                            Response.Redirect("~/Default.aspx", true);
                        }
                        else
                        {
                            pnlError.Visible = true;
                            litError.Text    = "Invalid username or password, or account is inactive.";
                        }
                    }
                }
            }
        }
    }
}
