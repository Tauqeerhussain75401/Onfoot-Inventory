<%@ Page Title="Setup" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Setup.aspx.cs" Inherits="Onfoot_Inventory.Setup" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.6/css/dataTables.bootstrap5.min.css" />
    <style>
        /* ── Setup Page Styles ─────────────────────────────────── */
        .setup-tabs {
            display: flex;
            gap: 4px;
            background: #fff;
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 6px;
            margin-bottom: 22px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
        }

        .setup-tab-btn {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 16px;
            border: none;
            border-radius: 8px;
            background: transparent;
            color: var(--text-muted);
            font-size: 0.84rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            white-space: nowrap;
        }

        .setup-tab-btn:hover {
            background: var(--body-bg);
            color: var(--text-main);
        }

        .setup-tab-btn.active {
            background: var(--primary);
            color: #fff;
            box-shadow: 0 2px 8px rgba(37,99,235,0.25);
        }

        .setup-tab-btn .tab-icon {
            width: 28px;
            height: 28px;
            border-radius: 6px;
            background: rgba(255,255,255,0.2);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.85rem;
        }

        .setup-tab-btn:not(.active) .tab-icon {
            background: var(--body-bg);
        }

        .setup-tab-panel { display: none; }
        .setup-tab-panel.active { display: block; }

        /* ── Module card header ── */
        .module-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
            padding: 16px 20px;
            border-bottom: 1px solid var(--border);
        }

        .module-title {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .module-icon {
            width: 38px;
            height: 38px;
            border-radius: 9px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1rem;
        }

        .module-icon.blue   { background: #dbeafe; color: var(--primary); }
        .module-icon.green  { background: #dcfce7; color: var(--success); }
        .module-icon.purple { background: #ede9fe; color: var(--purple); }
        .module-icon.orange { background: #ffedd5; color: #ea580c; }

        .module-title h5 {
            margin: 0 0 2px;
            font-size: 0.95rem;
            font-weight: 700;
            color: var(--text-main);
        }

        .module-title p {
            margin: 0;
            font-size: 0.76rem;
            color: var(--text-muted);
        }

        /* ── Action buttons row ── */
        .module-actions {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* ── Item cards grid (alternative to table for small screens) ── */
        .items-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
            gap: 14px;
            padding: 18px 20px;
        }

        .item-card {
            background: var(--body-bg);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 14px 16px;
            display: flex;
            align-items: flex-start;
            gap: 12px;
            transition: box-shadow 0.15s, border-color 0.15s;
        }

        .item-card:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            border-color: #c7d2fe;
        }

        .item-card-icon {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            background: #fff;
            border: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.95rem;
            flex-shrink: 0;
        }

        .item-card-body { flex: 1; min-width: 0; }

        .item-card-name {
            font-size: 0.88rem;
            font-weight: 700;
            color: var(--text-main);
            margin: 0 0 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .item-card-desc {
            font-size: 0.75rem;
            color: var(--text-muted);
            margin: 0 0 8px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .item-card-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .item-card-actions {
            display: flex;
            gap: 4px;
        }

        .btn-icon {
            width: 28px;
            height: 28px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 6px;
            border: 1px solid var(--border);
            background: #fff;
            color: var(--text-muted);
            font-size: 0.75rem;
            cursor: pointer;
            transition: all 0.15s;
        }

        .btn-icon:hover { border-color: var(--primary); color: var(--primary); background: #eff6ff; }
        .btn-icon.danger:hover { border-color: var(--danger); color: var(--danger); background: #fef2f2; }

        /* ── Empty state ── */
        .empty-state {
            padding: 48px 20px;
            text-align: center;
            color: var(--text-muted);
        }

        .empty-state i {
            font-size: 2.5rem;
            margin-bottom: 12px;
            opacity: 0.3;
        }

        .empty-state p { font-size: 0.84rem; margin: 0; }

        /* ── Toggle switch ── */
        .form-switch .form-check-input { cursor: pointer; }

        /* ── Courier card meta rows ── */
        .courier-meta { display: flex; flex-direction: column; gap: 3px; margin: 5px 0 2px; }
        .courier-meta-row { display: flex; align-items: center; gap: 6px; font-size: 0.75rem; color: var(--text-muted); }
        .courier-meta-row i { width: 13px; text-align: center; font-size: 0.72rem; opacity: .65; }

        /* ── Stats strip ── */
        .setup-stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 14px;
            margin-bottom: 22px;
        }

        @media (max-width: 600px) {
            .setup-stats { grid-template-columns: 1fr; }
            .setup-tabs { flex-direction: column; }
            .setup-tab-btn { justify-content: flex-start; }
        }

        /* ── Toast ── */
        #setupToast {
            position: fixed;
            bottom: 24px;
            right: 24px;
            z-index: 9999;
            min-width: 280px;
            border-radius: 10px;
            padding: 12px 18px;
            font-size: 0.84rem;
            font-weight: 600;
            display: none;
            box-shadow: 0 8px 24px rgba(0,0,0,0.12);
            animation: slideUp 0.25s ease;
        }

        @keyframes slideUp {
            from { opacity: 0; transform: translateY(10px); }
            to   { opacity: 1; transform: translateY(0); }
        }

        #setupToast.success { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
        #setupToast.error   { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }
    </style>
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div>
            <h4><i class="fas fa-sliders-h me-2 text-primary"></i>Setup</h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="Default.aspx">Dashboard</a></li>
                    <li class="breadcrumb-item active">Setup</li>
                </ol>
            </nav>
        </div>
    </div>

    <!-- Stats Strip -->
    <div class="setup-stats" id="statsStrip">
        <div class="stat-card">
            <div class="stat-icon green"><i class="fas fa-store"></i></div>
            <div>
                <div class="stat-label">Marketplaces</div>
                <div class="stat-value" id="statMarketplaces">—</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue"><i class="fas fa-tags"></i></div>
            <div>
                <div class="stat-label">Categories</div>
                <div class="stat-value" id="statCategories">—</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon purple"><i class="fas fa-truck"></i></div>
            <div>
                <div class="stat-label">Couriers</div>
                <div class="stat-value" id="statCouriers">—</div>
            </div>
        </div>
    </div>

    <!-- Tab Navigation -->
    <div class="setup-tabs" role="tablist">
        <button class="setup-tab-btn active" onclick="showMarketplaces(this)" type="button">
            <span class="tab-icon"><i class="fas fa-store"></i></span>
            Marketplaces
        </button>
        <button class="setup-tab-btn" onclick="showCategories(this)" type="button">
            <span class="tab-icon"><i class="fas fa-tags"></i></span>
            Categories
        </button>
        <button class="setup-tab-btn" onclick="showCouriers(this)" type="button">
            <span class="tab-icon"><i class="fas fa-truck"></i></span>
            Couriers
        </button>
    </div>

    <!-- ============================================================ -->
    <!--  TAB: MARKETPLACES                                           -->
    <!-- ============================================================ -->
    <div class="setup-tab-panel active" id="panel-marketplaces">
        <div class="table-card">
            <div class="module-header">
                <div class="module-title">
                    <div class="module-icon green"><i class="fas fa-store"></i></div>
                    <div>
                        <h5>Marketplaces</h5>
                        <p>Sales channels where inventory is allocated and sold</p>
                    </div>
                </div>
                <div class="module-actions">
                    <label class="form-check form-switch mb-0 me-1 d-flex align-items-center gap-2" title="Show inactive">
                        <input class="form-check-input" type="checkbox" id="mpShowInactive" onchange="loadMarketplaces()">
                        <span style="font-size:0.78rem;color:var(--text-muted)">Show Inactive</span>
                    </label>
                    <button class="btn btn-primary btn-sm" onclick="openMarketplaceModal()">
                        <i class="fas fa-plus me-1"></i> Add Marketplace
                    </button>
                </div>
            </div>
            <div class="items-grid" id="mpGrid">
                <div class="empty-state"><i class="fas fa-store-slash d-block"></i><p>Loading...</p></div>
            </div>
        </div>
    </div>

    <!-- ============================================================ -->
    <!--  TAB: CATEGORIES                                             -->
    <!-- ============================================================ -->
    <div class="setup-tab-panel" id="panel-categories">
        <div class="table-card">
            <div class="module-header">
                <div class="module-title">
                    <div class="module-icon blue"><i class="fas fa-tags"></i></div>
                    <div>
                        <h5>Categories</h5>
                        <p>Organise products into logical groups</p>
                    </div>
                </div>
                <div class="module-actions">
                    <label class="form-check form-switch mb-0 me-1 d-flex align-items-center gap-2" title="Show inactive">
                        <input class="form-check-input" type="checkbox" id="catShowInactive" onchange="loadCategories()">
                        <span style="font-size:0.78rem;color:var(--text-muted)">Show Inactive</span>
                    </label>
                    <button class="btn btn-primary btn-sm" onclick="openCategoryModal()">
                        <i class="fas fa-plus me-1"></i> Add Category
                    </button>
                </div>
            </div>
            <div class="items-grid" id="catGrid">
                <div class="empty-state"><i class="fas fa-tags d-block"></i><p>Loading...</p></div>
            </div>
        </div>
    </div>

    <!-- ============================================================ -->
    <!--  TAB: COURIERS                                               -->
    <!-- ============================================================ -->
    <div class="setup-tab-panel" id="panel-couriers">
        <div class="table-card">
            <div class="module-header">
                <div class="module-title">
                    <div class="module-icon purple"><i class="fas fa-truck"></i></div>
                    <div>
                        <h5>Couriers</h5>
                        <p>Shipping and delivery service providers</p>
                    </div>
                </div>
                <div class="module-actions">
                    <label class="form-check form-switch mb-0 me-1 d-flex align-items-center gap-2" title="Show inactive">
                        <input class="form-check-input" type="checkbox" id="courierShowInactive" onchange="loadCouriers()">
                        <span style="font-size:0.78rem;color:var(--text-muted)">Show Inactive</span>
                    </label>
                    <button class="btn btn-primary btn-sm" onclick="openCourierModal()">
                        <i class="fas fa-plus me-1"></i> Add Courier
                    </button>
                </div>
            </div>
            <div class="items-grid" id="courierGrid">
                <div class="empty-state"><i class="fas fa-truck d-block"></i><p>Loading...</p></div>
            </div>
        </div>
    </div>


    <!-- ============================================================ -->
    <!--  MODAL: MARKETPLACE                                          -->
    <!-- ============================================================ -->
    <div class="modal fade" id="mpModal" tabindex="-1" aria-labelledby="mpModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" style="max-width:460px">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px;overflow:hidden">
                <div class="modal-header border-0 pb-0" style="background:linear-gradient(135deg,#f0f9ff,#e0f2fe);padding:20px 24px 12px">
                    <div class="d-flex align-items-center gap-3">
                        <div class="module-icon green"><i class="fas fa-store"></i></div>
                        <div>
                            <h5 class="modal-title mb-0" id="mpModalLabel" style="font-size:1rem;font-weight:700;">Add Marketplace</h5>
                            <p class="mb-0" style="font-size:0.75rem;color:var(--text-muted)">Sales channel configuration</p>
                        </div>
                    </div>
                    <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" style="padding:20px 24px">
                    <input type="hidden" id="mpId" value="0" />
                    <div class="mb-3">
                        <label class="form-label fw-600" style="font-size:0.82rem;font-weight:600;">Marketplace Name <span class="text-danger">*</span></label>
                        <input type="text" id="mpName" class="form-control form-control-sm" placeholder="e.g. Daraz, Amazon, Shopify" maxlength="100" />
                    </div>
                    <div class="mb-3">
                        <label class="form-label" style="font-size:0.82rem;font-weight:600;">Description</label>
                        <textarea id="mpDesc" class="form-control form-control-sm" rows="2" placeholder="Optional notes about this marketplace" maxlength="300"></textarea>
                    </div>
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input" type="checkbox" id="mpActive" checked>
                        <label class="form-check-label" for="mpActive" style="font-size:0.82rem;">Active</label>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0" style="padding:12px 24px 20px;gap:8px">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary btn-sm px-4" onclick="saveMarketplace()">
                        <i class="fas fa-save me-1"></i> Save
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ============================================================ -->
    <!--  MODAL: CATEGORY                                             -->
    <!-- ============================================================ -->
    <div class="modal fade" id="catModal" tabindex="-1" aria-labelledby="catModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" style="max-width:460px">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px;overflow:hidden">
                <div class="modal-header border-0 pb-0" style="background:linear-gradient(135deg,#eff6ff,#dbeafe);padding:20px 24px 12px">
                    <div class="d-flex align-items-center gap-3">
                        <div class="module-icon blue"><i class="fas fa-tags"></i></div>
                        <div>
                            <h5 class="modal-title mb-0" id="catModalLabel" style="font-size:1rem;font-weight:700;">Add Category</h5>
                            <p class="mb-0" style="font-size:0.75rem;color:var(--text-muted)">Product category configuration</p>
                        </div>
                    </div>
                    <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" style="padding:20px 24px">
                    <input type="hidden" id="catId" value="0" />
                    <div class="mb-3">
                        <label class="form-label" style="font-size:0.82rem;font-weight:600;">Category Name <span class="text-danger">*</span></label>
                        <input type="text" id="catName" class="form-control form-control-sm" placeholder="e.g. Shoes, Apparel, Accessories" maxlength="100" />
                    </div>
                    <div class="mb-3">
                        <label class="form-label" style="font-size:0.82rem;font-weight:600;">Description</label>
                        <textarea id="catDesc" class="form-control form-control-sm" rows="2" placeholder="Optional category description" maxlength="300"></textarea>
                    </div>
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input" type="checkbox" id="catActive" checked>
                        <label class="form-check-label" for="catActive" style="font-size:0.82rem;">Active</label>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0" style="padding:12px 24px 20px;gap:8px">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary btn-sm px-4" onclick="saveCategory()">
                        <i class="fas fa-save me-1"></i> Save
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ============================================================ -->
    <!--  MODAL: COURIER                                              -->
    <!-- ============================================================ -->
    <div class="modal fade" id="courierModal" tabindex="-1" aria-labelledby="courierModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" style="max-width:500px">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px;overflow:hidden">
                <div class="modal-header border-0 pb-0" style="background:linear-gradient(135deg,#f5f3ff,#ede9fe);padding:20px 24px 12px">
                    <div class="d-flex align-items-center gap-3">
                        <div class="module-icon purple"><i class="fas fa-truck"></i></div>
                        <div>
                            <h5 class="modal-title mb-0" id="courierModalLabel" style="font-size:1rem;font-weight:700;">Add Courier</h5>
                            <p class="mb-0" style="font-size:0.75rem;color:var(--text-muted)">Shipping partner details</p>
                        </div>
                    </div>
                    <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" style="padding:20px 24px">
                    <input type="hidden" id="courierId" value="0" />
                    <div class="row g-3">
                        <div class="col-12">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">Courier / Company Name <span class="text-danger">*</span></label>
                            <input type="text" id="courierName" class="form-control form-control-sm" placeholder="e.g. TCS, Leopards, M&P" maxlength="100" />
                        </div>
                        <div class="col-sm-6">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">Contact Person</label>
                            <input type="text" id="courierContact" class="form-control form-control-sm" placeholder="Contact name" maxlength="100" />
                        </div>
                        <div class="col-sm-6">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">Phone</label>
                            <input type="text" id="courierPhone" class="form-control form-control-sm" placeholder="+92-xxx-xxxxxxx" maxlength="30" />
                        </div>
                        <div class="col-12">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">Email</label>
                            <input type="email" id="courierEmail" class="form-control form-control-sm" placeholder="courier@example.com" maxlength="150" />
                        </div>
                        <div class="col-12">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">Notes</label>
                            <textarea id="courierNotes" class="form-control form-control-sm" rows="2" placeholder="Any additional notes" maxlength="400"></textarea>
                        </div>
                        <div class="col-12">
                            <div class="form-check form-switch mb-0">
                                <input class="form-check-input" type="checkbox" id="courierActive" checked>
                                <label class="form-check-label" for="courierActive" style="font-size:0.82rem;">Active</label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0" style="padding:12px 24px 20px;gap:8px">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary btn-sm px-4" onclick="saveCourier()">
                        <i class="fas fa-save me-1"></i> Save
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Delete Confirm Modal -->
    <div class="modal fade" id="deleteModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" style="max-width:380px">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px">
                <div class="modal-body text-center" style="padding:28px 24px 16px">
                    <div style="width:52px;height:52px;border-radius:50%;background:#fef2f2;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;font-size:1.3rem;color:var(--danger)">
                        <i class="fas fa-trash-alt"></i>
                    </div>
                    <h5 style="font-size:0.95rem;font-weight:700;margin-bottom:6px;">Delete Item</h5>
                    <p id="deleteModalMsg" class="text-muted mb-0" style="font-size:0.82rem;">Are you sure you want to delete this item?</p>
                </div>
                <div class="modal-footer border-0 justify-content-center pb-4" style="gap:8px">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-danger btn-sm px-4" id="deleteConfirmBtn">Delete</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Toast -->
    <div id="setupToast"></div>

</asp:Content>

<asp:Content ID="ScriptsContent" ContentPlaceHolderID="ScriptsContent" runat="server">
<script>
// ============================================================
// UTILITIES
// ============================================================
function api(method, data, cb) {
    $.ajax({
        type: 'POST',
        url: 'Setup.aspx/' + method,
        data: JSON.stringify(data),
        contentType: 'application/json; charset=utf-8',
        dataType: 'json',
        success: function(r) { cb(null, typeof r.d === 'string' ? JSON.parse(r.d) : r.d); },
        error:   function(e) { cb(e.responseText || 'Error', null); }
    });
}

function toast(msg, type) {
    var t = document.getElementById('setupToast');
    t.className = 'success error'.split(' ').includes(type) ? type : 'success';
    t.innerHTML = '<i class="fas fa-' + (type === 'error' ? 'times-circle' : 'check-circle') + ' me-2"></i>' + msg;
    t.style.display = 'block';
    setTimeout(function() { t.style.display = 'none'; }, 3200);
}

function switchTab(name, btn) {
    document.querySelectorAll('.setup-tab-panel').forEach(function(p) { p.classList.remove('active'); });
    document.querySelectorAll('.setup-tab-btn').forEach(function(b) { b.classList.remove('active'); });
    document.getElementById('panel-' + name).classList.add('active');
    btn.classList.add('active');
}

function badgeHtml(active) {
    return active
        ? '<span class="badge-active">Active</span>'
        : '<span class="badge-inactive">Inactive</span>';
}

// ============================================================
// STATS
// ============================================================
function loadStats() {
    api('GetSetupStats', {}, function(err, d) {
        if (d) {
            document.getElementById('statMarketplaces').textContent = d.Marketplaces;
            document.getElementById('statCategories').textContent   = d.Categories;
            document.getElementById('statCouriers').textContent     = d.Couriers;
        }
    });
}

// ============================================================
// MARKETPLACES
// ============================================================
var mpModal, mpModalBS;

function loadMarketplaces() {
    var showInactive = document.getElementById('mpShowInactive').checked;
    api('GetAllMarketplaces', { showInactive: showInactive }, function(err, list) {
        var grid = document.getElementById('mpGrid');
        if (err || !list || list.length === 0) {
            grid.innerHTML = '<div class="empty-state" style="grid-column:1/-1"><i class="fas fa-store-slash d-block"></i><p>No marketplaces found. Click "+ Add Marketplace" to create one.</p></div>';
            return;
        }
        grid.innerHTML = list.map(function(m) {
            return '<div class="item-card">' +
                '<div class="item-card-icon" style="color:#16a34a"><i class="fas fa-store"></i></div>' +
                '<div class="item-card-body">' +
                    '<p class="item-card-name">' + escHtml(m.MarketplaceName) + '</p>' +
                    '<p class="item-card-desc">' + (m.Description ? escHtml(m.Description) : '<span style="opacity:.45">No description</span>') + '</p>' +
                    '<div class="item-card-footer">' +
                        badgeHtml(m.IsActive) +
                        '<div class="item-card-actions">' +
                            '<button class="btn-icon" title="Edit" onclick="editMarketplace(' + m.MarketplaceId + ')"><i class="fas fa-pencil-alt"></i></button>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
            '</div>';
        }).join('');
    });
}

function openMarketplaceModal(id) {
    document.getElementById('mpId').value   = 0;
    document.getElementById('mpName').value = '';
    document.getElementById('mpDesc').value = '';
    document.getElementById('mpActive').checked = true;
    document.getElementById('mpModalLabel').textContent = 'Add Marketplace';
    if (!mpModalBS) mpModalBS = new bootstrap.Modal(document.getElementById('mpModal'));
    mpModalBS.show();
}

function editMarketplace(id) {
    api('GetMarketplaceById', { marketplaceId: id }, function(err, m) {
        if (err || !m) { toast('Could not load marketplace.', 'error'); return; }
        document.getElementById('mpId').value       = m.MarketplaceId;
        document.getElementById('mpName').value     = m.MarketplaceName;
        document.getElementById('mpDesc').value     = m.Description || '';
        document.getElementById('mpActive').checked = m.IsActive;
        document.getElementById('mpModalLabel').textContent = 'Edit Marketplace';
        if (!mpModalBS) mpModalBS = new bootstrap.Modal(document.getElementById('mpModal'));
        mpModalBS.show();
    });
}

function saveMarketplace() {
    var name = document.getElementById('mpName').value.trim();
    if (!name) { toast('Marketplace name is required.', 'error'); document.getElementById('mpName').focus(); return; }
    var data = {
        marketplace: {
            MarketplaceId:   parseInt(document.getElementById('mpId').value),
            MarketplaceName: name,
            Description:     document.getElementById('mpDesc').value.trim(),
            IsActive:        document.getElementById('mpActive').checked
        }
    };
    api('SaveMarketplace', data, function(err, r) {
        if (err || !r) { toast('Request failed.', 'error'); return; }
        if (!r.success) { toast(r.message, 'error'); return; }
        mpModalBS.hide();
        toast(r.message, 'success');
        loadMarketplaces();
        loadStats();
    });
}

// ============================================================
// CATEGORIES
// ============================================================
var catModalBS;

function loadCategories() {
    var showInactive = document.getElementById('catShowInactive').checked;
    api('GetCategories', { showInactive: showInactive }, function(err, list) {
        var grid = document.getElementById('catGrid');
        if (err || !list || list.length === 0) {
            grid.innerHTML = '<div class="empty-state" style="grid-column:1/-1"><i class="fas fa-tags d-block"></i><p>No categories found. Click "+ Add Category" to create one.</p></div>';
            return;
        }
        grid.innerHTML = list.map(function(c) {
            return '<div class="item-card">' +
                '<div class="item-card-icon" style="color:var(--primary)"><i class="fas fa-tag"></i></div>' +
                '<div class="item-card-body">' +
                    '<p class="item-card-name">' + escHtml(c.CategoryName) + '</p>' +
                    '<p class="item-card-desc">' + (c.Description ? escHtml(c.Description) : '<span style="opacity:.45">No description</span>') + '</p>' +
                    '<div class="item-card-footer">' +
                        '<div class="d-flex align-items-center gap-2">' +
                            badgeHtml(c.IsActive) +
                            '<span style="font-size:0.72rem;color:var(--text-muted)"><i class="fas fa-box me-1"></i>' + c.ProductCount + ' products</span>' +
                        '</div>' +
                        '<div class="item-card-actions">' +
                            '<button class="btn-icon" title="Edit" onclick="editCategory(' + c.CategoryId + ')"><i class="fas fa-pencil-alt"></i></button>' +
                            '<button class="btn-icon danger" title="Delete" onclick="confirmDelete(\'category\',' + c.CategoryId + ',\'' + escHtml(c.CategoryName) + '\')"><i class="fas fa-trash-alt"></i></button>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
            '</div>';
        }).join('');
    });
}

function openCategoryModal() {
    document.getElementById('catId').value   = 0;
    document.getElementById('catName').value = '';
    document.getElementById('catDesc').value = '';
    document.getElementById('catActive').checked = true;
    document.getElementById('catModalLabel').textContent = 'Add Category';
    if (!catModalBS) catModalBS = new bootstrap.Modal(document.getElementById('catModal'));
    catModalBS.show();
}

function editCategory(id) {
    api('GetCategoryById', { categoryId: id }, function(err, c) {
        if (err || !c) { toast('Could not load category.', 'error'); return; }
        document.getElementById('catId').value       = c.CategoryId;
        document.getElementById('catName').value     = c.CategoryName;
        document.getElementById('catDesc').value     = c.Description || '';
        document.getElementById('catActive').checked = c.IsActive;
        document.getElementById('catModalLabel').textContent = 'Edit Category';
        if (!catModalBS) catModalBS = new bootstrap.Modal(document.getElementById('catModal'));
        catModalBS.show();
    });
}

function saveCategory() {
    var name = document.getElementById('catName').value.trim();
    if (!name) { toast('Category name is required.', 'error'); document.getElementById('catName').focus(); return; }
    var data = {
        category: {
            CategoryId:   parseInt(document.getElementById('catId').value),
            CategoryName: name,
            Description:  document.getElementById('catDesc').value.trim(),
            IsActive:     document.getElementById('catActive').checked
        }
    };
    api('SaveCategory', data, function(err, r) {
        if (err || !r) { toast('Request failed.', 'error'); return; }
        if (!r.success) { toast(r.message, 'error'); return; }
        catModalBS.hide();
        toast(r.message, 'success');
        loadCategories();
        loadStats();
    });
}

// ============================================================
// COURIERS
// ============================================================
var courierModalBS;

function loadCouriers() {
    var showInactive = document.getElementById('courierShowInactive').checked;
    api('GetCouriers', { showInactive: showInactive }, function(err, list) {
        var grid = document.getElementById('courierGrid');
        if (err || !list || list.length === 0) {
            grid.innerHTML = '<div class="empty-state" style="grid-column:1/-1"><i class="fas fa-truck d-block"></i><p>No couriers found. Click "+ Add Courier" to get started.</p></div>';
            return;
        }
        grid.innerHTML = list.map(function(c) {
            var meta = '';
            if (c.ContactName) meta += '<div class="courier-meta-row"><i class="fas fa-user"></i>' + escHtml(c.ContactName) + '</div>';
            if (c.Phone)       meta += '<div class="courier-meta-row"><i class="fas fa-phone"></i>' + escHtml(c.Phone) + '</div>';
            if (c.Email)       meta += '<div class="courier-meta-row"><i class="fas fa-envelope"></i>' + escHtml(c.Email) + '</div>';
            if (!meta)         meta  = '<div class="courier-meta-row" style="opacity:.4"><i class="fas fa-info-circle"></i>No contact details</div>';

            return '<div class="item-card">' +
                '<div class="item-card-icon" style="color:var(--purple)"><i class="fas fa-truck"></i></div>' +
                '<div class="item-card-body">' +
                    '<p class="item-card-name">' + escHtml(c.CourierName) + '</p>' +
                    '<div class="courier-meta">' + meta + '</div>' +
                    '<div class="item-card-footer" style="margin-top:10px;">' +
                        badgeHtml(c.IsActive) +
                        '<div class="item-card-actions">' +
                            '<button class="btn-icon" title="Edit" onclick="editCourier(' + c.CourierId + ')"><i class="fas fa-pencil-alt"></i></button>' +
                            '<button class="btn-icon danger" title="Delete" onclick="confirmDelete(\'courier\',' + c.CourierId + ',\'' + escHtml(c.CourierName) + '\')"><i class="fas fa-trash-alt"></i></button>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
            '</div>';
        }).join('');
    });
}

function openCourierModal() {
    document.getElementById('courierId').value      = 0;
    document.getElementById('courierName').value    = '';
    document.getElementById('courierContact').value = '';
    document.getElementById('courierPhone').value   = '';
    document.getElementById('courierEmail').value   = '';
    document.getElementById('courierNotes').value   = '';
    document.getElementById('courierActive').checked = true;
    document.getElementById('courierModalLabel').textContent = 'Add Courier';
    if (!courierModalBS) courierModalBS = new bootstrap.Modal(document.getElementById('courierModal'));
    courierModalBS.show();
}

function editCourier(id) {
    api('GetCourierById', { courierId: id }, function(err, c) {
        if (err || !c) { toast('Could not load courier.', 'error'); return; }
        document.getElementById('courierId').value      = c.CourierId;
        document.getElementById('courierName').value    = c.CourierName;
        document.getElementById('courierContact').value = c.ContactName || '';
        document.getElementById('courierPhone').value   = c.Phone || '';
        document.getElementById('courierEmail').value   = c.Email || '';
        document.getElementById('courierNotes').value   = c.Notes || '';
        document.getElementById('courierActive').checked = c.IsActive;
        document.getElementById('courierModalLabel').textContent = 'Edit Courier';
        if (!courierModalBS) courierModalBS = new bootstrap.Modal(document.getElementById('courierModal'));
        courierModalBS.show();
    });
}

function saveCourier() {
    var name = document.getElementById('courierName').value.trim();
    if (!name) { toast('Courier name is required.', 'error'); document.getElementById('courierName').focus(); return; }
    var data = {
        courier: {
            CourierId:   parseInt(document.getElementById('courierId').value),
            CourierName: name,
            ContactName: document.getElementById('courierContact').value.trim(),
            Phone:       document.getElementById('courierPhone').value.trim(),
            Email:       document.getElementById('courierEmail').value.trim(),
            Notes:       document.getElementById('courierNotes').value.trim(),
            IsActive:    document.getElementById('courierActive').checked
        }
    };
    api('SaveCourier', data, function(err, r) {
        if (err || !r) { toast('Request failed.', 'error'); return; }
        if (!r.success) { toast(r.message, 'error'); return; }
        courierModalBS.hide();
        toast(r.message, 'success');
        loadCouriers();
        loadStats();
    });
}

// ============================================================
// DELETE (shared)
// ============================================================
var _deleteModal;

function confirmDelete(type, id, name) {
    var msg = 'Are you sure you want to delete <strong>' + escHtml(name) + '</strong>? This action cannot be undone.';
    document.getElementById('deleteModalMsg').innerHTML = msg;
    var btn = document.getElementById('deleteConfirmBtn');
    btn.onclick = function() { doDelete(type, id); };
    if (!_deleteModal) _deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));
    _deleteModal.show();
}

function doDelete(type, id) {
    var methodMap = { category: 'DeleteCategory', courier: 'DeleteCourier' };
    var paramMap  = { category: { categoryId: id }, courier: { courierId: id } };
    var reloadMap = { category: loadCategories, courier: loadCouriers };
    api(methodMap[type], paramMap[type], function(err, r) {
        _deleteModal.hide();
        if (err || !r) { toast('Request failed.', 'error'); return; }
        if (!r.success) { toast(r.message, 'error'); return; }
        toast(r.message, 'success');
        reloadMap[type]();
        loadStats();
    });
}

// ============================================================
// XSS safety
// ============================================================
function escHtml(s) {
    if (!s) return '';
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}

// ============================================================
// TAB CLICK HANDLERS (called from inline onclick attributes)
// ============================================================
function showMarketplaces(btn) { switchTab('marketplaces', btn); loadMarketplaces(); }
function showCategories(btn)   { switchTab('categories', btn);   loadCategories(); }
function showCouriers(btn)     { switchTab('couriers', btn);     loadCouriers(); }

// ============================================================
// INIT
// ============================================================
$(function() {
    loadStats();
    loadMarketplaces();

    // Enter key in modals
    ['mpName','catName','courierName'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                if (id === 'mpName') saveMarketplace();
                else if (id === 'catName') saveCategory();
                else if (id === 'courierName') saveCourier();
            }
        });
    });
});
</script>
</asp:Content>
