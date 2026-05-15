<%@ Page Title="Dashboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="Onfoot_Inventory._Default" %>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-left">
            <h4><i class="fas fa-chart-pie me-2 text-primary"></i>Dashboard</h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item active">Dashboard</li>
                </ol>
            </nav>
        </div>
        <span class="text-muted small">
            <i class="fas fa-circle text-success me-1" style="font-size:0.6rem;"></i>
            System Online
        </span>
    </div>

    <!-- Welcome Banner -->
    <div class="dashboard-card mb-4" style="background:linear-gradient(135deg,#1a2332 0%,#2563eb 100%);color:#fff;border-radius:14px;padding:28px 30px;">
        <div class="d-flex align-items-center justify-content-between flex-wrap gap-3">
            <div>
                <h3 class="mb-1 fw-bold" style="font-size:1.5rem;">Welcome to Onfoot Inventory</h3>
                <p class="mb-0 opacity-75" style="font-size:0.9rem;">
                    Manage your footwear product catalog, track stock levels, and monitor your business.
                </p>
            </div>
            <div style="font-size:3.5rem;opacity:0.25;">
                <i class="fas fa-shoe-prints"></i>
            </div>
        </div>
    </div>

    <!-- Stat Cards -->
    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon blue"><i class="fas fa-boxes"></i></div>
                <div>
                    <div class="stat-label">Total Products</div>
                    <div class="stat-value" id="dashTotal">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon green"><i class="fas fa-check-circle"></i></div>
                <div>
                    <div class="stat-label">Active Products</div>
                    <div class="stat-value" id="dashActive">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon yellow"><i class="fas fa-exclamation-triangle"></i></div>
                <div>
                    <div class="stat-label">Low Stock Alerts</div>
                    <div class="stat-value" id="dashLowStock">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon purple"><i class="fas fa-tags"></i></div>
                <div>
                    <div class="stat-label">Categories</div>
                    <div class="stat-value" id="dashCategories">—</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Actions -->
    <div class="row g-3">
        <div class="col-md-6 col-lg-4">
            <div class="dashboard-card h-100">
                <h6 class="fw-bold mb-3" style="color:#1e293b;">
                    <i class="fas fa-bolt text-primary me-2"></i>Quick Actions
                </h6>
                <div class="d-grid gap-2">
                    <a href="<%: ResolveUrl("~/Products") %>" class="btn btn-primary">
                        <i class="fas fa-box-open me-2"></i>Manage Products
                    </a>
                    <a href="<%: ResolveUrl("~/Products") %>" class="btn btn-outline-secondary">
                        <i class="fas fa-plus me-2"></i>Add New Product
                    </a>
                </div>
            </div>
        </div>
        <div class="col-md-6 col-lg-8">
            <div class="dashboard-card h-100">
                <h6 class="fw-bold mb-3" style="color:#1e293b;">
                    <i class="fas fa-info-circle text-primary me-2"></i>System Information
                </h6>
                <div class="row g-3">
                    <div class="col-sm-6">
                        <div style="background:#f8fafc;border-radius:8px;padding:14px;">
                            <div class="text-muted" style="font-size:0.75rem;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;">Company</div>
                            <div class="fw-semibold mt-1">Onfoot Footwear</div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div style="background:#f8fafc;border-radius:8px;padding:14px;">
                            <div class="text-muted" style="font-size:0.75rem;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;">System Version</div>
                            <div class="fw-semibold mt-1">v1.0.0</div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div style="background:#f8fafc;border-radius:8px;padding:14px;">
                            <div class="text-muted" style="font-size:0.75rem;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;">Framework</div>
                            <div class="fw-semibold mt-1">ASP.NET Web Forms 4.8</div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div style="background:#f8fafc;border-radius:8px;padding:14px;">
                            <div class="text-muted" style="font-size:0.75rem;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;">Today</div>
                            <div class="fw-semibold mt-1"><%= DateTime.Now.ToString("dd MMM yyyy") %></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="ScriptsContent" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        $(document).ready(function () {
            loadDashboardStats();
        });

        function loadDashboardStats() {
            $.ajax({
                type: 'POST',
                url: 'Products.aspx/GetProductStats',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: function (res) {
                    var s = JSON.parse(res.d);
                    $('#dashTotal').text(s.TotalProducts);
                    $('#dashActive').text(s.ActiveProducts);
                    $('#dashLowStock').text(s.LowStock);
                    $('#dashCategories').text(s.TotalCategories);
                },
                error: function () {
                    $('#dashTotal, #dashActive, #dashLowStock, #dashCategories').text('N/A');
                }
            });
        }
    </script>
</asp:Content>
