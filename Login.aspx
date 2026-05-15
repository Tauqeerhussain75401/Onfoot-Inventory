<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="Onfoot_Inventory.Login" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Login | Onfoot Inventory</title>
    <link href="Content/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet" />
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            font-size: 0.875rem;
            background: linear-gradient(135deg, #1a2332 0%, #2563eb 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .login-card {
            background: #fff;
            border-radius: 16px;
            padding: 40px 36px 32px;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 24px 64px rgba(0,0,0,0.35);
        }
        .login-logo {
            text-align: center;
            margin-bottom: 28px;
        }
        .login-logo img { width: 56px; height: 56px; object-fit: contain; }
        .login-logo h4 {
            color: #1e293b;
            font-weight: 700;
            margin: 10px 0 4px;
            font-size: 1.2rem;
        }
        .login-logo p { color: #64748b; font-size: 0.82rem; margin: 0; }
        .form-label { color: #374151; font-weight: 600; font-size: 0.82rem; margin-bottom: 5px; }
        .form-control {
            border: 1.5px solid #e2e8f0;
            border-radius: 8px;
            padding: 10px 14px;
            font-size: 0.9rem;
            width: 100%;
            outline: none;
            transition: border-color 0.2s;
        }
        .form-control:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235,0.12); }
        .input-wrap { position: relative; }
        .toggle-eye {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            color: #94a3b8;
            background: none;
            border: none;
            padding: 0;
        }
        .toggle-eye:hover { color: #2563eb; }
        .btn-login {
            background: #2563eb;
            color: #fff;
            border: none;
            border-radius: 8px;
            padding: 11px;
            font-size: 0.95rem;
            font-weight: 600;
            width: 100%;
            cursor: pointer;
            transition: background 0.2s;
            margin-top: 4px;
        }
        .btn-login:hover { background: #1d4ed8; }
        .error-panel {
            background: #fef2f2;
            border: 1px solid #fca5a5;
            color: #dc2626;
            border-radius: 8px;
            padding: 10px 14px;
            font-size: 0.85rem;
            margin-bottom: 16px;
        }
        .val-msg { color: #dc2626; font-size: 0.78rem; margin-top: 3px; display: block; }
        .login-footer { text-align: center; margin-top: 20px; color: #94a3b8; font-size: 0.76rem; }
    </style>
</head>
<body>
    <form id="form1" runat="server" autocomplete="off">
        <div class="login-card">

            <div class="login-logo">
                <img src="Content/Logo/Onfoot logo icon.png" alt="Onfoot" />
                <h4>Onfoot Inventory</h4>
                <p>Sign in to continue</p>
            </div>

            <asp:Panel ID="pnlError" runat="server" CssClass="error-panel" Visible="false">
                <i class="fas fa-exclamation-circle me-1"></i>
                <asp:Literal ID="litError" runat="server" />
            </asp:Panel>

            <div class="mb-3">
                <label class="form-label"><i class="fas fa-user me-1"></i>Username</label>
                <asp:TextBox ID="txtUsername" runat="server" CssClass="form-control" placeholder="Enter username" MaxLength="50" />
                <asp:RequiredFieldValidator ID="rfvUsername" runat="server"
                    ControlToValidate="txtUsername"
                    ErrorMessage="Username is required."
                    CssClass="val-msg" Display="Dynamic" />
            </div>

            <div class="mb-4">
                <label class="form-label"><i class="fas fa-lock me-1"></i>Password</label>
                <div class="input-wrap">
                    <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control"
                        TextMode="Password" placeholder="Enter password"
                        style="padding-right:40px;" MaxLength="100" />
                    <button type="button" class="toggle-eye" onclick="togglePwd()" tabindex="-1">
                        <i class="fas fa-eye" id="eyeIcon"></i>
                    </button>
                </div>
                <asp:RequiredFieldValidator ID="rfvPassword" runat="server"
                    ControlToValidate="txtPassword"
                    ErrorMessage="Password is required."
                    CssClass="val-msg" Display="Dynamic" />
            </div>

            <asp:Button ID="btnLogin" runat="server" Text="Sign In"
                CssClass="btn-login" OnClick="btnLogin_Click" />

            <div class="login-footer">
                &copy; <%= DateTime.Now.Year %> Onfoot Footwear &mdash; All Rights Reserved
            </div>
        </div>
    </form>

    <script>
        function togglePwd() {
            var box = document.getElementById('<%= txtPassword.ClientID %>');
            var icon = document.getElementById('eyeIcon');
            if (box.type === 'password') {
                box.type = 'text';
                icon.className = 'fas fa-eye-slash';
            } else {
                box.type = 'password';
                icon.className = 'fas fa-eye';
            }
        }
    </script>
</body>
</html>
