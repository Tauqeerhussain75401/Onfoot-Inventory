using System;
using System.Web;
using System.Web.Security;
using System.Web.UI;

namespace Onfoot_Inventory
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Redirect to login if not authenticated
            if (Session["UserID"] == null || !HttpContext.Current.User.Identity.IsAuthenticated)
            {
                FormsAuthentication.SignOut();
                Response.Redirect("~/Login.aspx", true);
            }

            if (!IsPostBack)
                PopulateUserBar();
        }

        private void PopulateUserBar()
        {
            string fullName = Session["FullName"] as string ?? HttpContext.Current.User.Identity.Name;
            string role     = Session["Role"]     as string ?? "";

            litFullName.Text = HttpUtility.HtmlEncode(fullName);
            litRole.Text     = HttpUtility.HtmlEncode(role);
            litAvatar.Text   = fullName.Length > 0
                               ? fullName[0].ToString().ToUpper()
                               : "U";
        }

    }
}
