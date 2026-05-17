<%@ Page Title="Stock Management" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Stock.aspx.cs" Inherits="Onfoot_Inventory.Stock" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css" rel="stylesheet" />
    <link href="https://cdn.datatables.net/responsive/2.5.0/css/responsive.bootstrap5.min.css" rel="stylesheet" />
    <style>
        /* ── Stock grid ───────────────────────────────────────────── */
        #tblStock thead th {
            background: #f8fafc;
            border-bottom: 2px solid #e2e8f0;
            font-size: .72rem;
            text-transform: uppercase;
            letter-spacing: .5px;
            white-space: nowrap;
            padding: 10px 12px;
            vertical-align: middle;
        }
        #tblStock tbody td {
            padding: 9px 12px;
            vertical-align: middle;
            border-bottom: 1px solid #f1f5f9;
            font-size: .875rem;
        }
        #tblStock tbody tr:hover td { background: #f0f6ff; }
        #tblStock tbody tr:nth-child(even) td { background: #fafbfd; }
        #tblStock tbody tr:nth-child(even):hover td { background: #f0f6ff; }

        /* ── Stock qty badges ─────────────────────────────────────── */
        .sq-badge {
            display: inline-block;
            min-width: 40px;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: .8rem;
            font-weight: 700;
            text-align: center;
            color: #fff;
        }
        .sq-green  { background: #16a34a; }
        .sq-red    { background: #dc2626; }
        .sq-grey   { background: #6b7280; }
        .sq-blue   { background: #2563eb; }

        /* ── Misc ─────────────────────────────────────────────────── */
        #tblStock tbody tr { cursor: default; }
        .mp-manage-row { border-bottom: 1px solid #f1f5f9; padding: 8px 0; }
    </style>
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-left">
            <h4><i class="fas fa-warehouse me-2 text-primary"></i>Stock Management</h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="<%: ResolveUrl("~/") %>">Dashboard</a></li>
                    <li class="breadcrumb-item active">Stock Management</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <button class="btn btn-outline-secondary btn-sm" onclick="loadPage()" title="Refresh">
                <i class="fas fa-sync-alt me-1"></i> Refresh
            </button>
            <button class="btn btn-outline-info btn-sm" onclick="openManageMarketplacesModal()">
                <i class="fas fa-store me-1"></i> Marketplaces
            </button>
            <button class="btn btn-primary" onclick="openAllocateBulkModal()">
                <i class="fas fa-share-alt me-1"></i> Allocate Stock
            </button>
            <button class="btn btn-success" onclick="openAddStockModal(0)">
                <i class="fas fa-plus me-1"></i> Add Stock
            </button>
        </div>
    </div>

    <!-- Stats -->
    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon blue"><i class="fas fa-warehouse"></i></div>
                <div>
                    <div class="stat-label">Warehouse Stock</div>
                    <div class="stat-value" id="statWarehouse">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon green"><i class="fas fa-share-alt"></i></div>
                <div>
                    <div class="stat-label">Marketplace Stock</div>
                    <div class="stat-value" id="statMarketplace">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon purple"><i class="fas fa-store"></i></div>
                <div>
                    <div class="stat-label">Active Marketplaces</div>
                    <div class="stat-value" id="statMpCount">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon yellow"><i class="fas fa-layer-group"></i></div>
                <div>
                    <div class="stat-label">Total Variants</div>
                    <div class="stat-value" id="statVariants">—</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Stock Table -->
    <div class="table-card">
        <div class="table-card-body">
            <div class="table-responsive">
                <table id="tblStock" class="table table-hover w-100">
                    <thead id="stockThead"></thead>
                    <tbody id="stockTbody"></tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- ============================================================
         MODAL: ADD STOCK  (receive into warehouse)
         ============================================================ -->
    <div class="modal fade" id="addStockModal" tabindex="-1">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-plus-circle me-2 text-success"></i>Add Stock to Warehouse</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Product <span class="text-danger">*</span></label>
                        <select id="addStockProduct" class="form-select" onchange="loadVariantsForAdd()">
                            <option value="">-- Select Product --</option>
                        </select>
                    </div>

                    <!-- Variant rows appear after product is selected -->
                    <div id="addStockVariantsList" style="display:none;">
                        <div class="row g-2 align-items-center mb-2">
                            <div class="col">
                                <input type="text" id="addStockSearch" class="form-control form-control-sm"
                                       placeholder="Search SKU, color or size..." oninput="filterAddStockRows()" />
                            </div>
                            <div class="col-auto">
                                <input type="number" id="addStockGlobalQty" class="form-control form-control-sm"
                                       min="0" placeholder="Qty (all)" style="width:110px;"
                                       oninput="applyAddStockGlobalQty()" />
                            </div>
                            <div class="col-auto">
                                <span class="fw-bold text-success" id="addStockTotal" style="font-size:.95rem;"></span>
                            </div>
                        </div>
                        <small class="text-muted d-block mb-1" id="addStockVariantCount"></small>
                        <div class="table-responsive" style="max-height:480px; overflow-y:auto;">
                            <table class="table table-sm table-bordered align-middle mb-0">
                                <thead class="table-light sticky-top">
                                    <tr>
                                        <th>SKU</th>
                                        <th class="text-center" style="width:110px">Current Stock</th>
                                        <th style="width:110px">Add Qty</th>
                                    </tr>
                                </thead>
                                <tbody id="addStockVariantsBody"></tbody>
                            </table>
                        </div>
                    </div>

                    <div id="addStockError" class="alert alert-danger d-none mt-2"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-success" id="btnAddStockSave" onclick="saveAddStock()">
                        <i class="fas fa-save me-1"></i> Add Stock
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ============================================================
         MODAL: BULK ALLOCATE TO MARKETPLACE  (header button)
         ============================================================ -->
    <div class="modal fade" id="allocateBulkModal" tabindex="-1">
        <div class="modal-dialog modal-xl modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-share-alt me-2 text-primary"></i>Allocate Stock to Marketplace</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Product <span class="text-danger">*</span></label>
                        <select id="allocBulkProduct" class="form-select" onchange="loadAllocBulkVariants()">
                            <option value="">-- Select Product --</option>
                        </select>
                    </div>

                    <div id="allocBulkList" style="display:none;">
                        <div class="row g-2 align-items-center mb-2">
                            <div class="col-md-3">
                                <input type="text" id="allocBulkSearch" class="form-control form-control-sm"
                                       placeholder="Search SKU, color or size..." oninput="filterAllocBulkRows()" />
                            </div>
                            <div class="col-md-3">
                                <select id="allocBulkGlobalFrom" class="form-select form-select-sm"
                                        onchange="applyGlobalAllocDefaults()">
                                    <option value="0">From: Warehouse</option>
                                </select>
                            </div>
                            <div class="col-md-3">
                                <select id="allocBulkGlobalMp" class="form-select form-select-sm"
                                        onchange="applyGlobalAllocDefaults()">
                                    <option value="">-- Allocate To (all rows) --</option>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <input type="number" id="allocBulkGlobalQty" class="form-control form-control-sm"
                                       min="0" placeholder="Qty (all)" oninput="applyGlobalAllocDefaults()" />
                            </div>
                            <div class="col-md-1 text-end">
                                <span class="fw-bold text-primary" id="allocBulkTotal" style="font-size:.9rem;"></span>
                            </div>
                        </div>
                        <div class="table-responsive" style="max-height:460px; overflow-y:auto;">
                            <table class="table table-sm table-bordered align-middle mb-0">
                                <thead class="table-light sticky-top" id="allocBulkThead"></thead>
                                <tbody id="allocBulkTbody"></tbody>
                            </table>
                        </div>
                    </div>

                    <div id="allocBulkError" class="alert alert-danger d-none mt-2"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" id="btnAllocSave" onclick="saveAllocBulk()">
                        <i class="fas fa-paper-plane me-1"></i> Allocate
                    </button>
                </div>
            </div>
        </div>
    </div>

<!-- ============================================================
         MODAL: ALLOCATE TO MARKETPLACE
         ============================================================ -->
    <div class="modal fade" id="allocateModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-share-alt me-2 text-primary"></i>Allocate to Marketplace</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" id="allocVariantId" value="0" />

                    <!-- Variant info banner -->
                    <div class="mb-3 p-3 rounded" style="background:#eff6ff; border:1px solid #bfdbfe;">
                        <div class="fw-semibold text-primary" id="allocVariantLabel"></div>
                        <small class="text-muted">
                            Available warehouse stock:
                            <strong id="allocWarehouseStock" class="text-success">—</strong>
                        </small>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Marketplace <span class="text-danger">*</span></label>
                        <select id="allocMarketplace" class="form-select">
                            <option value="">-- Select Marketplace --</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Quantity <span class="text-danger">*</span></label>
                        <input type="number" id="allocQty" class="form-control" min="1" placeholder="Enter quantity to send" />
                        <div class="form-text">Max available: <span id="allocMaxHint">—</span></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Notes</label>
                        <input type="text" id="allocNotes" class="form-control" placeholder="Optional notes" />
                    </div>
                    <div id="allocError" class="alert alert-danger d-none"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" onclick="saveAllocate()">
                        <i class="fas fa-paper-plane me-1"></i> Allocate
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ============================================================
         MODAL: RETURN FROM MARKETPLACE
         ============================================================ -->
    <div class="modal fade" id="returnModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-undo me-2 text-warning"></i>Return to Warehouse</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" id="returnVariantId" value="0" />

                    <div class="mb-3 p-3 rounded" style="background:#fff7ed; border:1px solid #fed7aa;">
                        <div class="fw-semibold text-warning" id="returnVariantLabel"></div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Return From Marketplace <span class="text-danger">*</span></label>
                        <select id="returnMarketplace" class="form-select" onchange="onReturnMpChange()">
                            <option value="">-- Select Marketplace --</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Quantity <span class="text-danger">*</span></label>
                        <input type="number" id="returnQty" class="form-control" min="1" />
                        <div class="form-text">Available on selected marketplace: <span id="returnMaxHint">—</span></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Notes</label>
                        <input type="text" id="returnNotes" class="form-control" placeholder="Optional notes" />
                    </div>
                    <div id="returnError" class="alert alert-danger d-none"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-warning" onclick="saveReturn()">
                        <i class="fas fa-undo me-1"></i> Return to Warehouse
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ============================================================
         MODAL: STOCK HISTORY
         ============================================================ -->
    <div class="modal fade" id="historyModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-history me-2 text-secondary"></i>Stock History - <span id="historyVariantLabel"></span></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body p-0">
                    <div class="table-responsive">
                        <table class="table table-sm mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>Date</th>
                                    <th>Type</th>
                                    <th>From</th>
                                    <th>To</th>
                                    <th class="text-center">Qty</th>
                                    <th>By</th>
                                </tr>
                            </thead>
                            <tbody id="historyBody">
                                <tr><td colspan="6" class="text-center text-muted py-3">Loading…</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- ============================================================
         MODAL: MANAGE MARKETPLACES
         ============================================================ -->
    <div class="modal fade" id="manageMarketplacesModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-store me-2 text-info"></i>Manage Marketplaces</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">

                    <!-- Existing marketplaces list -->
                    <h6 class="mb-2 text-muted">Existing Marketplaces</h6>
                    <div id="mpListContainer" class="mb-4">
                        <div class="text-muted text-center py-2">Loading…</div>
                    </div>

                    <hr />

                    <!-- Add / Edit form -->
                    <h6 class="mb-2 text-muted" id="mpFormTitle">Add New Marketplace</h6>
                    <input type="hidden" id="mpEditId" value="0" />
                    <div class="row g-2 align-items-end">
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Name <span class="text-danger">*</span></label>
                            <input type="text" id="mpName" class="form-control" placeholder="e.g. TikTok Shop" />
                        </div>
                        <div class="col-md-5">
                            <label class="form-label fw-semibold">Description</label>
                            <input type="text" id="mpDesc" class="form-control" placeholder="Optional description" />
                        </div>
                        <div class="col-md-2 d-flex align-items-end">
                            <div class="form-check form-switch mb-2">
                                <input class="form-check-input" type="checkbox" id="mpActive" checked />
                                <label class="form-check-label" for="mpActive">Active</label>
                            </div>
                        </div>
                        <div class="col-md-1 d-flex align-items-end">
                            <button class="btn btn-primary w-100" onclick="saveMp()"><i class="fas fa-save"></i></button>
                        </div>
                    </div>
                    <div id="mpFormError" class="alert alert-danger d-none mt-2"></div>
                    <div id="mpFormSuccess" class="alert alert-success d-none mt-2"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Toast -->
    <div class="toast-container position-fixed bottom-0 end-0 p-3" style="z-index:9999;">
        <div id="mainToast" class="toast align-items-center border-0" role="alert">
            <div class="d-flex">
                <div class="toast-body" id="mainToastBody"></div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="ScriptsContent" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.7/js/dataTables.bootstrap5.min.js"></script>

    <script>
        // ── state ────────────────────────────────────────────────────────────
        var allMarketplaces = [];   // active marketplaces (for table columns)
        var stockData       = [];   // full stock summary
        var currentVariant  = null; // variant object selected for allocate/return
        var dtStock         = null; // DataTable instance

        // ── boot ─────────────────────────────────────────────────────────────
        $(function () { loadPage(); });

        function loadPage() {
            loadStats();
            loadMarketplacesAndStock();
        }

        // ── stats cards ───────────────────────────────────────────────────────
        function loadStats() {
            $.ajax({
                type: 'POST', url: 'Stock.aspx/GetStockStats',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (r) {
                    var d = JSON.parse(r.d);
                    $('#statWarehouse').text(d.WarehouseTotal);
                    $('#statMarketplace').text(d.MarketplaceTotal);
                    $('#statMpCount').text(d.ActiveMarketplaces);
                    $('#statVariants').text(d.TotalVariants);
                }
            });
        }

        // ── load marketplaces then stock ──────────────────────────────────────
        function loadMarketplacesAndStock() {
            $.ajax({
                type: 'POST', url: 'Stock.aspx/GetMarketplaces',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (r) {
                    allMarketplaces = JSON.parse(r.d);
                    loadStockSummary();
                }
            });
        }

        function loadStockSummary() {
            $.ajax({
                type: 'POST', url: 'Stock.aspx/GetStockSummary',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (r) {
                    stockData = JSON.parse(r.d);
                    buildTable(stockData);
                }
            });
        }

        // ── marketplace accent colours (cycles if > 6) ────────────────────────
        var MP_COLORS = ['#3b82f6','#f59e0b','#10b981','#8b5cf6','#ef4444','#06b6d4'];

        // ── build DataTable ───────────────────────────────────────────────────
        function buildTable(data) {
            if (dtStock) { dtStock.destroy(); dtStock = null; }

            // ── thead ─────────────────────────────────────────────────────────
            var head = '<tr>'
                + '<th style="width:36px">#</th>'
                + '<th>Product</th>'
                + '<th>SKU</th>'
                + '<th class="text-center" style="width:100px;">'
                + '<span style="display:inline-flex;align-items:center;gap:4px;">'
                + '<i class="fas fa-warehouse" style="color:#6366f1;font-size:.8rem;"></i>'
                + '<span style="color:#6366f1;font-weight:700;">Warehouse</span>'
                + '</span></th>';

            allMarketplaces.forEach(function (m, idx) {
                var c = MP_COLORS[idx % MP_COLORS.length];
                head += '<th class="text-center" style="width:110px;">'
                    + '<span style="display:inline-flex;align-items:center;gap:4px;">'
                    + '<i class="fas fa-store" style="color:' + c + ';font-size:.75rem;"></i>'
                    + '<span style="color:' + c + ';font-weight:700;">' + esc(m.MarketplaceName) + '</span>'
                    + '</span></th>';
            });

            head += '<th class="text-center" style="width:100px;">'
                  + '<span style="color:#64748b;font-weight:700;">Allocated</span></th>'
                  + '<th style="width:120px;">Actions</th></tr>';
            document.getElementById('stockThead').innerHTML = head;

            // ── tbody ─────────────────────────────────────────────────────────
            var rows = '';
            data.forEach(function (item, i) {
                var wQty = item.WarehouseStock;

                rows += '<tr>';
                rows += '<td class="text-muted fw-semibold" style="font-size:.8rem;">' + (i + 1) + '</td>';

                // Product
                rows += '<td>'
                      + '<span class="fw-bold" style="color:#1e293b;">' + esc(item.ProductCode) + '</span>'
                      + '<br><span style="font-size:.78rem;color:#94a3b8;">' + esc(item.ProductName) + '</span>'
                      + '</td>';

                // SKU
                var skuText = item.SKUNumbers || (item.Color + ' / Sz ' + item.Size);
                rows += '<td style="color:#475569;">'
                      + esc(skuText)
                      + '&nbsp;<button class="btn btn-link btn-sm p-0" style="font-size:.75rem;color:#94a3b8;vertical-align:middle;" '
                      + 'onclick="copySku(\'' + esc(skuText) + '\')" title="Copy SKU">'
                      + '<i class="fas fa-copy"></i></button>'
                      + '</td>';

                // Warehouse
                rows += '<td class="text-center">'
                      + '<span class="sq-badge ' + (wQty > 0 ? 'sq-green' : 'sq-red') + '">' + wQty + '</span>'
                      + '</td>';

                // Marketplace cells
                allMarketplaces.forEach(function (m) {
                    var qty = (item.MarketplaceStocks && item.MarketplaceStocks[m.MarketplaceId]) || 0;
                    rows += '<td class="text-center">'
                          + '<span class="sq-badge ' + (qty > 0 ? 'sq-green' : 'sq-red') + '">' + qty + '</span>'
                          + '</td>';
                });

                // Allocated
                var alloc = item.TotalAllocated;
                rows += '<td class="text-center">'
                      + '<span class="sq-badge ' + (alloc > 0 ? 'sq-blue' : 'sq-grey') + '">' + alloc + '</span>'
                      + '</td>';

                // Actions
                rows += '<td>'
                      + '<div class="btn-group btn-group-sm">'
                      + '<button class="btn btn-outline-success" onclick="openAddStockModal(' + item.VariantId + ')" title="Add to Warehouse"><i class="fas fa-plus"></i></button>'
                      + '<button class="btn btn-outline-primary" onclick="openAllocateModal(' + item.VariantId + ')" title="Allocate to Marketplace"><i class="fas fa-share-alt"></i></button>'
                      + '<button class="btn btn-outline-warning" onclick="openReturnModal(' + item.VariantId + ')" title="Return to Warehouse"><i class="fas fa-undo"></i></button>'
                      + '<button class="btn btn-outline-secondary" onclick="openHistoryModal(' + item.VariantId + ',\'' + esc(item.ProductCode + ' ' + item.Color + ' sz' + item.Size) + '\')" title="History"><i class="fas fa-history"></i></button>'
                      + '</div>'
                      + '</td>';
                rows += '</tr>';
            });

            document.getElementById('stockTbody').innerHTML = rows
                || '<tr><td colspan="100" class="text-center text-muted py-4">No variants found. Add products first.</td></tr>';

            dtStock = $('#tblStock').DataTable({
                pageLength: 25,
                order: [[1, 'asc']],
                columnDefs: [{ orderable: false, targets: -1 }],
                language: { emptyTable: 'No stock records found.' }
            });
        }

        // ── toast helper ──────────────────────────────────────────────────────
        function showToast(msg, isOk) {
            var t = document.getElementById('mainToast');
            t.className = 'toast align-items-center border-0 text-white ' + (isOk ? 'bg-success' : 'bg-danger');
            document.getElementById('mainToastBody').textContent = msg;
            bootstrap.Toast.getOrCreateInstance(t, { delay: 3000 }).show();
        }

        function esc(s) {
            return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
        }

        function copySku(text) {
            navigator.clipboard.writeText(text).then(function () {
                showToast('SKU copied: ' + text, true);
            }).catch(function () {
                // Fallback for older browsers
                var ta = document.createElement('textarea');
                ta.value = text;
                ta.style.position = 'fixed';
                ta.style.opacity = '0';
                document.body.appendChild(ta);
                ta.select();
                document.execCommand('copy');
                document.body.removeChild(ta);
                showToast('SKU copied: ' + text, true);
            });
        }

        // ─────────────────────────────────────────────────────────────────────
        // ADD STOCK MODAL
        // ─────────────────────────────────────────────────────────────────────
        function openAddStockModal(variantId) {
            $('#addStockError').addClass('d-none');
            $('#addStockNotes').val('');
            document.getElementById('addStockVariantsList').style.display = 'none';
            document.getElementById('addStockVariantsBody').innerHTML = '';
            document.getElementById('addStockTotal').textContent = '';
            document.getElementById('addStockGlobalQty').value = '';

            // Load products into dropdown
            $.ajax({
                type: 'POST', url: 'Stock.aspx/GetProductsForDropdown',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (r) {
                    var sel = document.getElementById('addStockProduct');
                    sel.innerHTML = '<option value="">-- Select Product --</option>';
                    JSON.parse(r.d).forEach(function (p) {
                        sel.innerHTML += '<option value="' + p.ProductId + '">'
                            + esc(p.ProductCode + ' - ' + p.ProductName) + '</option>';
                    });

                    // If opened from a row button, auto-select that product
                    if (variantId > 0) {
                        var item = stockData.find(function (x) { return x.VariantId == variantId; });
                        if (item && item.ProductId) {
                            sel.value = item.ProductId;
                            loadVariantsForAdd(variantId);
                        }
                    } else {
                        sel.value = '';
                    }
                }
            });

            bootstrap.Modal.getOrCreateInstance(document.getElementById('addStockModal')).show();
        }

        function loadVariantsForAdd(highlightVariantId) {
            var pid = document.getElementById('addStockProduct').value;
            var listDiv = document.getElementById('addStockVariantsList');
            listDiv.style.display = 'none';
            document.getElementById('addStockVariantsBody').innerHTML = '';
            if (!pid) return;

            $.ajax({
                type: 'POST', url: 'Stock.aspx/GetVariantsByProduct',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ productId: parseInt(pid) }),
                success: function (r) {
                    var variants = JSON.parse(r.d);
                    if (variants.length === 0) {
                        document.getElementById('addStockVariantsBody').innerHTML =
                            '<tr><td colspan="4" class="text-center text-muted py-3">No variants found for this product.</td></tr>';
                        listDiv.style.display = '';
                        return;
                    }

                    document.getElementById('addStockSearch').value = '';
                    var rows = '';
                    variants.forEach(function (v) {
                        var low  = v.StockQuantity === 0;
                        var sku  = v.SKUNumbers || (v.Color + ' / Size ' + v.Size);
                        var hl   = (highlightVariantId && v.VariantId == highlightVariantId)
                                   ? ' style="background:#f0fdf4;"' : '';
                        // data-search stores lowercase text for filtering
                        var searchText = (v.Color + ' ' + v.Size + ' ' + sku).toLowerCase();
                        rows += '<tr' + hl + ' data-search="' + esc(searchText) + '">'
                            + '<td>'
                            + '<span class="fw-semibold">' + esc(sku) + '</span>'
                            + '&nbsp;<button class="btn btn-link btn-sm p-0" style="font-size:.72rem;color:#94a3b8;vertical-align:middle;" '
                            + 'onclick="copySku(\'' + esc(sku) + '\')" title="Copy SKU"><i class="fas fa-copy"></i></button>'
                            + '<br><small class="text-muted">' + esc(v.Color) + ' / Size ' + esc(v.Size) + '</small>'
                            + '</td>'
                            + '<td class="text-center">'
                            + '<span class="badge ' + (low ? 'bg-danger' : 'bg-success') + '">'
                            + v.StockQuantity + '</span>'
                            + (low ? '&nbsp;<i class="fas fa-exclamation-triangle text-danger" style="font-size:.7rem"></i>' : '')
                            + '</td>'
                            + '<td><input type="number" class="form-control form-control-sm add-variant-qty" '
                            + 'data-variant-id="' + v.VariantId + '" min="0" placeholder="0" oninput="updateAddStockTotal()" '
                            + (highlightVariantId && v.VariantId == highlightVariantId ? 'autofocus' : '') + ' /></td>'
                            + '</tr>';
                    });
                    document.getElementById('addStockVariantsBody').innerHTML = rows;
                    document.getElementById('addStockVariantCount').textContent = variants.length + ' variant(s)';
                    document.getElementById('addStockTotal').textContent = '';
                    document.getElementById('addStockGlobalQty').value = '';
                    listDiv.style.display = '';
                }
            });
        }

        function setBtnLoading(btnId, loading) {
            var btn = document.getElementById(btnId);
            if (!btn) return;
            if (loading) {
                btn.disabled = true;
                btn._origHtml = btn.innerHTML;
                btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status"></span> Saving...';
            } else {
                btn.disabled = false;
                btn.innerHTML = btn._origHtml || btn.innerHTML;
            }
        }

        function saveAddStock() {
            var inputs = document.querySelectorAll('.add-variant-qty');
            var toSave = [];

            inputs.forEach(function (inp) {
                var qty = parseInt(inp.value) || 0;
                if (qty > 0)
                    toSave.push({ variantId: parseInt(inp.getAttribute('data-variant-id')), quantity: qty });
            });

            if (toSave.length === 0) {
                showAddStockError('Enter a quantity for at least one variant.');
                return;
            }

            setBtnLoading('btnAddStockSave', true);
            var done = 0, errors = [];

            toSave.forEach(function (item) {
                $.ajax({
                    type: 'POST', url: 'Stock.aspx/AddStock',
                    contentType: 'application/json; charset=utf-8', dataType: 'json',
                    data: JSON.stringify({ variantId: item.variantId, quantity: item.quantity, notes: '' }),
                    success: function (r) {
                        var res = JSON.parse(r.d);
                        if (!res.success) errors.push(res.message);
                        done++;
                        if (done === toSave.length) {
                            setBtnLoading('btnAddStockSave', false);
                            if (errors.length === 0) {
                                bootstrap.Modal.getInstance(document.getElementById('addStockModal')).hide();
                                showToast(toSave.length + ' variant(s) updated successfully.', true);
                                loadPage();
                            } else {
                                showAddStockError(errors.join(' | '));
                            }
                        }
                    },
                    error: function () {
                        done++;
                        errors.push('Server error on one request.');
                        if (done === toSave.length) {
                            setBtnLoading('btnAddStockSave', false);
                            showAddStockError(errors.join(' | '));
                        }
                    }
                });
            });
        }

        function showAddStockError(msg) {
            var el = document.getElementById('addStockError');
            el.textContent = msg; el.classList.remove('d-none');
        }

        function filterAddStockRows() {
            var q = document.getElementById('addStockSearch').value.toLowerCase().trim();
            document.querySelectorAll('#addStockVariantsBody tr').forEach(function (row) {
                var text = row.getAttribute('data-search') || '';
                row.style.display = (!q || text.indexOf(q) !== -1) ? '' : 'none';
            });
            applyAddStockGlobalQty();
        }

        function applyAddStockGlobalQty() {
            var qty = document.getElementById('addStockGlobalQty').value;
            if (qty === '') return;
            document.querySelectorAll('#addStockVariantsBody tr').forEach(function (row) {
                if (row.style.display === 'none') return;
                var inp = row.querySelector('.add-variant-qty');
                if (inp) inp.value = qty;
            });
            updateAddStockTotal();
        }

        function updateAddStockTotal() {
            var total = 0;
            document.querySelectorAll('.add-variant-qty').forEach(function (inp) {
                total += parseInt(inp.value) || 0;
            });
            var el = document.getElementById('addStockTotal');
            el.textContent = total > 0 ? 'Total Adding: ' + total : '';
        }

        // ─────────────────────────────────────────────────────────────────────
        // ALLOCATE MODAL
        // ─────────────────────────────────────────────────────────────────────
        function openAllocateModal(variantId) {
            var item = stockData.find(function (x) { return x.VariantId == variantId; });
            if (!item) return;
            currentVariant = item;

            document.getElementById('allocVariantId').value = variantId;
            document.getElementById('allocVariantLabel').textContent =
                item.ProductCode + ' — ' + item.Color + ' / Size ' + item.Size;
            document.getElementById('allocWarehouseStock').textContent = item.WarehouseStock;
            document.getElementById('allocMaxHint').textContent = item.WarehouseStock;
            document.getElementById('allocQty').value  = '';
            document.getElementById('allocNotes').value = '';
            $('#allocError').addClass('d-none');

            // Fill marketplace dropdown
            var mpSel = document.getElementById('allocMarketplace');
            mpSel.innerHTML = '<option value="">-- Select Marketplace --</option>';
            allMarketplaces.forEach(function (m) {
                var cur = (item.MarketplaceStocks && item.MarketplaceStocks[m.MarketplaceId]) || 0;
                mpSel.innerHTML += '<option value="' + m.MarketplaceId + '">'
                    + esc(m.MarketplaceName) + ' (currently ' + cur + ')</option>';
            });

            bootstrap.Modal.getOrCreateInstance(document.getElementById('allocateModal')).show();
        }

        function saveAllocate() {
            var vid  = parseInt(document.getElementById('allocVariantId').value);
            var mpid = parseInt(document.getElementById('allocMarketplace').value) || 0;
            var qty  = parseInt($('#allocQty').val()) || 0;
            var notes = $('#allocNotes').val();

            if (!mpid)   { showAllocError('Please select a marketplace.'); return; }
            if (qty < 1) { showAllocError('Enter a valid quantity.'); return; }

            $.ajax({
                type: 'POST', url: 'Stock.aspx/AllocateStock',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ variantId: vid, marketplaceId: mpid, quantity: qty, notes: notes }),
                success: function (r) {
                    var res = JSON.parse(r.d);
                    if (res.success) {
                        bootstrap.Modal.getInstance(document.getElementById('allocateModal')).hide();
                        showToast(res.message, true);
                        loadPage();
                    } else {
                        showAllocError(res.message);
                    }
                }
            });
        }

        function showAllocError(msg) {
            var el = document.getElementById('allocError');
            el.textContent = msg; el.classList.remove('d-none');
        }

        // ─────────────────────────────────────────────────────────────────────
        // RETURN MODAL
        // ─────────────────────────────────────────────────────────────────────
        function openReturnModal(variantId) {
            var item = stockData.find(function (x) { return x.VariantId == variantId; });
            if (!item) return;
            currentVariant = item;

            document.getElementById('returnVariantId').value = variantId;
            document.getElementById('returnVariantLabel').textContent =
                item.ProductCode + ' — ' + item.Color + ' / Size ' + item.Size;
            document.getElementById('returnQty').value  = '';
            document.getElementById('returnNotes').value = '';
            document.getElementById('returnMaxHint').textContent = '—';
            $('#returnError').addClass('d-none');

            // Fill marketplace dropdown (only those with stock > 0)
            var mpSel = document.getElementById('returnMarketplace');
            mpSel.innerHTML = '<option value="">-- Select Marketplace --</option>';
            allMarketplaces.forEach(function (m) {
                var cur = (item.MarketplaceStocks && item.MarketplaceStocks[m.MarketplaceId]) || 0;
                if (cur > 0) {
                    mpSel.innerHTML += '<option value="' + m.MarketplaceId + '" data-stock="' + cur + '">'
                        + esc(m.MarketplaceName) + ' (' + cur + ' available)</option>';
                }
            });

            bootstrap.Modal.getOrCreateInstance(document.getElementById('returnModal')).show();
        }

        function onReturnMpChange() {
            var sel = document.getElementById('returnMarketplace');
            var opt = sel.options[sel.selectedIndex];
            var stock = opt ? (opt.getAttribute('data-stock') || '—') : '—';
            document.getElementById('returnMaxHint').textContent = stock;
        }

        function saveReturn() {
            var vid   = parseInt(document.getElementById('returnVariantId').value);
            var mpid  = parseInt(document.getElementById('returnMarketplace').value) || 0;
            var qty   = parseInt($('#returnQty').val()) || 0;
            var notes = $('#returnNotes').val();

            if (!mpid)   { showReturnError('Please select a marketplace.'); return; }
            if (qty < 1) { showReturnError('Enter a valid quantity.'); return; }

            $.ajax({
                type: 'POST', url: 'Stock.aspx/ReturnStock',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ variantId: vid, marketplaceId: mpid, quantity: qty, notes: notes }),
                success: function (r) {
                    var res = JSON.parse(r.d);
                    if (res.success) {
                        bootstrap.Modal.getInstance(document.getElementById('returnModal')).hide();
                        showToast(res.message, true);
                        loadPage();
                    } else {
                        showReturnError(res.message);
                    }
                }
            });
        }

        function showReturnError(msg) {
            var el = document.getElementById('returnError');
            el.textContent = msg; el.classList.remove('d-none');
        }

        // ─────────────────────────────────────────────────────────────────────
        // HISTORY MODAL
        // ─────────────────────────────────────────────────────────────────────
        function openHistoryModal(variantId, label) {
            document.getElementById('historyVariantLabel').textContent = label;
            document.getElementById('historyBody').innerHTML =
                '<tr><td colspan="6" class="text-center text-muted py-3">Loading…</td></tr>';
            bootstrap.Modal.getOrCreateInstance(document.getElementById('historyModal')).show();

            $.ajax({
                type: 'POST', url: 'Stock.aspx/GetStockMovements',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ variantId: variantId }),
                success: function (r) {
                    var rows = '';
                    JSON.parse(r.d).forEach(function (m) {
                        var badge = '';
                        if      (m.MovementType === 'RECEIVE')  badge = '<span class="badge bg-success">RECEIVE</span>';
                        else if (m.MovementType === 'ALLOCATE') badge = '<span class="badge bg-primary">ALLOCATE</span>';
                        else if (m.MovementType === 'RETURN')   badge = '<span class="badge bg-warning text-dark">RETURN</span>';
                        else if (m.MovementType === 'TRANSFER') badge = '<span class="badge bg-info text-dark">TRANSFER</span>';
                        else badge = '<span class="badge bg-secondary">' + esc(m.MovementType) + '</span>';

                        rows += '<tr>'
                            + '<td><small>' + esc(m.CreatedDate) + '</small></td>'
                            + '<td>' + badge + '</td>'
                            + '<td><small>' + esc(m.From) + '</small></td>'
                            + '<td><small>' + esc(m.To)   + '</small></td>'
                            + '<td class="text-center fw-semibold">' + m.Quantity + '</td>'
                            + '<td><small class="text-primary fw-semibold">' + esc(m.CreatedBy || '-') + '</small></td>'
                            + '</tr>';
                    });
                    document.getElementById('historyBody').innerHTML = rows ||
                        '<tr><td colspan="6" class="text-center text-muted py-3">No movements recorded yet.</td></tr>';
                }
            });
        }

        // ─────────────────────────────────────────────────────────────────────
        // BULK ALLOCATE MODAL
        // ─────────────────────────────────────────────────────────────────────
        function openAllocateBulkModal() {
            document.getElementById('allocBulkList').style.display      = 'none';
            document.getElementById('allocBulkThead').innerHTML         = '';
            document.getElementById('allocBulkTbody').innerHTML         = '';
            document.getElementById('allocBulkTotal').textContent       = '';
            document.getElementById('allocBulkSearch').value            = '';
            document.getElementById('allocBulkGlobalQty').value         = '';
            document.getElementById('allocBulkGlobalFrom').value        = '0';
            document.getElementById('allocBulkGlobalMp').value          = '';
            $('#allocBulkError').addClass('d-none');

            $.ajax({
                type: 'POST', url: 'Stock.aspx/GetProductsForDropdown',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (r) {
                    var sel = document.getElementById('allocBulkProduct');
                    sel.innerHTML = '<option value="">-- Select Product --</option>';
                    JSON.parse(r.d).forEach(function (p) {
                        sel.innerHTML += '<option value="' + p.ProductId + '">'
                            + esc(p.ProductCode + ' - ' + p.ProductName) + '</option>';
                    });
                    sel.value = '';
                }
            });

            bootstrap.Modal.getOrCreateInstance(document.getElementById('allocateBulkModal')).show();
        }

        function loadAllocBulkVariants() {
            var pid = parseInt(document.getElementById('allocBulkProduct').value) || 0;
            var listDiv = document.getElementById('allocBulkList');
            listDiv.style.display = 'none';
            document.getElementById('allocBulkTotal').textContent = '';
            if (!pid) return;

            // Filter from already-loaded stockData
            var variants = stockData.filter(function (x) { return x.ProductId === pid; });

            if (variants.length === 0) {
                listDiv.style.display = '';
                document.getElementById('allocBulkTbody').innerHTML =
                    '<tr><td colspan="100" class="text-center text-muted py-3">No variants found.</td></tr>';
                return;
            }

            // ── populate global From / Allocate-To dropdowns ──────
            var gFrom = document.getElementById('allocBulkGlobalFrom');
            gFrom.innerHTML = '<option value="0">From: Warehouse</option>';
            allMarketplaces.forEach(function (m) {
                gFrom.innerHTML += '<option value="' + m.MarketplaceId + '">From: ' + esc(m.MarketplaceName) + '</option>';
            });
            gFrom.value = '0';

            var gMp = document.getElementById('allocBulkGlobalMp');
            gMp.innerHTML = '<option value="">-- Allocate To (all rows) --</option>';
            allMarketplaces.forEach(function (m) {
                gMp.innerHTML += '<option value="' + m.MarketplaceId + '">' + esc(m.MarketplaceName) + '</option>';
            });
            gMp.value = '';
            document.getElementById('allocBulkGlobalQty').value = '';

            // ── thead ────────────────────────────────────────────────
            var head = '<tr>'
                + '<th>SKU</th>'
                + '<th style="width:160px;">Allocate From</th>'
                + '<th class="text-center" style="width:90px;">Available</th>'
                + '<th style="width:160px;">Allocate To</th>'
                + '<th class="text-center" style="width:90px;">Available</th>'
                + '<th style="width:90px;">Qty</th>'
                + '</tr>';
            document.getElementById('allocBulkThead').innerHTML = head;

            // ── tbody ────────────────────────────────────────────────
            document.getElementById('allocBulkSearch').value = '';
            var rows = '';
            variants.forEach(function (v) {
                var skuText    = v.SKUNumbers || (v.Color + ' / Sz ' + v.Size);
                var searchText = (v.SKUNumbers + ' ' + v.Color + ' ' + v.Size).toLowerCase();

                // From options: Warehouse + each marketplace with stock counts
                var fromOpts = '<option value="0">Warehouse (' + v.WarehouseStock + ')</option>';
                allMarketplaces.forEach(function (m) {
                    var mpQty = (v.MarketplaceStocks && v.MarketplaceStocks[m.MarketplaceId]) || 0;
                    fromOpts += '<option value="' + m.MarketplaceId + '">' + esc(m.MarketplaceName) + ' (' + mpQty + ')</option>';
                });

                // Allocate To options: all marketplaces
                var toOpts = '<option value="">-- Select --</option>';
                allMarketplaces.forEach(function (m) {
                    toOpts += '<option value="' + m.MarketplaceId + '">' + esc(m.MarketplaceName) + '</option>';
                });

                rows += '<tr data-search="' + esc(searchText) + '">';

                // SKU
                rows += '<td><span class="fw-semibold" style="color:#1e293b;">' + esc(skuText) + '</span>'
                      + '&nbsp;<button class="btn btn-link btn-sm p-0" style="font-size:.72rem;color:#94a3b8;vertical-align:middle;" '
                      + 'onclick="copySku(\'' + esc(skuText) + '\')" title="Copy SKU"><i class="fas fa-copy"></i></button>'
                      + '<br><small class="text-muted">' + esc(v.Color) + ' / Size ' + esc(v.Size) + '</small></td>';

                // From dropdown
                rows += '<td><select class="form-select form-select-sm alloc-bulk-from" '
                      + 'data-variant-id="' + v.VariantId + '" onchange="updateRowAvailable(this)">'
                      + fromOpts + '</select></td>';

                // Available badge (default = warehouse stock)
                rows += '<td class="text-center">'
                      + '<span class="sq-badge ' + (v.WarehouseStock > 0 ? 'sq-green' : 'sq-red') + ' alloc-row-avail" '
                      + 'id="avail_' + v.VariantId + '" data-available="' + v.WarehouseStock + '">'
                      + v.WarehouseStock + '</span></td>';

                // Allocate To dropdown
                rows += '<td><select class="form-select form-select-sm alloc-bulk-mp" '
                      + 'data-variant-id="' + v.VariantId + '" onchange="updateToAvailable(this)">'
                      + toOpts + '</select></td>';

                // To Available badge (updates when Allocate To changes)
                rows += '<td class="text-center">'
                      + '<span class="sq-badge sq-grey alloc-row-toavail" id="toavail_' + v.VariantId + '">-</span>'
                      + '</td>';

                // Qty
                rows += '<td><input type="number" class="form-control form-control-sm alloc-bulk-qty" '
                      + 'data-variant-id="' + v.VariantId + '" '
                      + 'min="0" placeholder="0" oninput="updateAllocBulkTotal()" /></td>';

                rows += '</tr>';
            });
            document.getElementById('allocBulkTbody').innerHTML = rows;
            listDiv.style.display = '';
        }

        function filterAllocBulkRows() {
            var q = document.getElementById('allocBulkSearch').value.toLowerCase().trim();
            document.querySelectorAll('#allocBulkTbody tr').forEach(function (row) {
                var text = row.getAttribute('data-search') || '';
                row.style.display = (!q || text.indexOf(q) !== -1) ? '' : 'none';
            });
            applyGlobalAllocDefaults();
        }

        function applyGlobalAllocDefaults() {
            var fromId = document.getElementById('allocBulkGlobalFrom').value;
            var mpid   = document.getElementById('allocBulkGlobalMp').value;
            var qty    = document.getElementById('allocBulkGlobalQty').value;

            document.querySelectorAll('#allocBulkTbody tr').forEach(function (row) {
                if (row.style.display === 'none') return;

                if (fromId !== '') {
                    var fromSel = row.querySelector('.alloc-bulk-from');
                    if (fromSel) { fromSel.value = fromId; updateRowAvailable(fromSel); }
                }
                if (mpid) {
                    var mpSel = row.querySelector('.alloc-bulk-mp');
                    if (mpSel) { mpSel.value = mpid; updateToAvailable(mpSel); }
                }
                if (qty !== '') {
                    var qtyInp = row.querySelector('.alloc-bulk-qty');
                    if (qtyInp) qtyInp.value = qty;
                }
            });
            updateAllocBulkTotal();
        }

        function updateToAvailable(toSel) {
            var vid  = parseInt(toSel.getAttribute('data-variant-id'));
            var toId = parseInt(toSel.value) || 0;
            var v    = stockData.find(function (x) { return x.VariantId === vid; });
            var el   = document.getElementById('toavail_' + vid);
            if (!el) return;
            if (!toId || !v) { el.textContent = '-'; el.className = 'sq-badge sq-grey alloc-row-toavail'; return; }
            var qty = (v.MarketplaceStocks && v.MarketplaceStocks[toId]) || 0;
            el.textContent = qty;
            el.className   = 'sq-badge ' + (qty > 0 ? 'sq-green' : 'sq-red') + ' alloc-row-toavail';
        }

        function updateRowAvailable(fromSel) {
            var vid    = parseInt(fromSel.getAttribute('data-variant-id'));
            var fromId = parseInt(fromSel.value) || 0;
            var v      = stockData.find(function (x) { return x.VariantId === vid; });
            if (!v) return;

            var avail = fromId === 0
                ? v.WarehouseStock
                : ((v.MarketplaceStocks && v.MarketplaceStocks[fromId]) || 0);

            var el = document.getElementById('avail_' + vid);
            if (el) {
                el.textContent             = avail;
                el.setAttribute('data-available', avail);
                el.className = 'sq-badge ' + (avail > 0 ? 'sq-green' : 'sq-red') + ' alloc-row-avail';
            }
        }

        function updateAllocBulkTotal() {
            var total = 0;
            document.querySelectorAll('.alloc-bulk-qty').forEach(function (inp) {
                total += parseInt(inp.value) || 0;
            });
            var el = document.getElementById('allocBulkTotal');
            el.textContent = total > 0 ? 'Total Allocating: ' + total : '';
        }

        function saveAllocBulk() {
            var qtyInputs = document.querySelectorAll('.alloc-bulk-qty');
            var toSave    = [];
            var valid     = true;

            qtyInputs.forEach(function (inp) {
                if (!valid) return;
                var qty = parseInt(inp.value) || 0;
                if (qty <= 0) return;

                var vid      = parseInt(inp.getAttribute('data-variant-id'));
                var fromSel  = document.querySelector('.alloc-bulk-from[data-variant-id="' + vid + '"]');
                var fromId   = fromSel ? (parseInt(fromSel.value) || 0) : 0;
                var mpSel    = document.querySelector('.alloc-bulk-mp[data-variant-id="' + vid + '"]');
                var toId     = mpSel ? (parseInt(mpSel.value) || 0) : 0;
                var availEl  = document.getElementById('avail_' + vid);
                var avail    = availEl ? (parseInt(availEl.getAttribute('data-available')) || 0) : 0;

                if (!toId) {
                    document.getElementById('allocBulkError').textContent =
                        'Please select "Allocate To" for every variant with a quantity.';
                    $('#allocBulkError').removeClass('d-none');
                    valid = false; return;
                }
                if (fromId === toId) {
                    document.getElementById('allocBulkError').textContent =
                        'Source and destination cannot be the same marketplace.';
                    $('#allocBulkError').removeClass('d-none');
                    valid = false; return;
                }
                if (qty > avail) {
                    document.getElementById('allocBulkError').textContent =
                        'Qty ' + qty + ' exceeds available stock (' + avail + ') for one of the variants.';
                    $('#allocBulkError').removeClass('d-none');
                    valid = false; return;
                }
                toSave.push({ variantId: vid, fromId: fromId, toId: toId, quantity: qty });
            });

            if (!valid) return;
            if (toSave.length === 0) {
                document.getElementById('allocBulkError').textContent =
                    'Enter a quantity and select marketplaces for at least one variant.';
                $('#allocBulkError').removeClass('d-none');
                return;
            }
            $('#allocBulkError').addClass('d-none');
            setBtnLoading('btnAllocSave', true);

            var done = 0, errors = [];
            toSave.forEach(function (item) {
                var url, data;
                if (item.fromId === 0) {
                    // Warehouse → Marketplace
                    url  = 'Stock.aspx/AllocateStock';
                    data = { variantId: item.variantId, marketplaceId: item.toId, quantity: item.quantity, notes: '' };
                } else {
                    // Marketplace → Marketplace
                    url  = 'Stock.aspx/TransferStock';
                    data = { variantId: item.variantId, fromMarketplaceId: item.fromId, toMarketplaceId: item.toId, quantity: item.quantity, notes: '' };
                }
                $.ajax({
                    type: 'POST', url: url,
                    contentType: 'application/json; charset=utf-8', dataType: 'json',
                    data: JSON.stringify(data),
                    success: function (r) {
                        var res = JSON.parse(r.d);
                        if (!res.success) errors.push(res.message);
                        done++;
                        if (done === toSave.length) {
                            setBtnLoading('btnAllocSave', false);
                            bootstrap.Modal.getInstance(document.getElementById('allocateBulkModal')).hide();
                            showToast(errors.length === 0
                                ? toSave.length + ' variant(s) processed successfully.'
                                : errors.join(' | '), errors.length === 0);
                            loadPage();
                        }
                    },
                    error: function () {
                        done++;
                        errors.push('Server error.');
                        if (done === toSave.length) {
                            setBtnLoading('btnAllocSave', false);
                            document.getElementById('allocBulkError').textContent = errors.join(' | ');
                            $('#allocBulkError').removeClass('d-none');
                        }
                    }
                });
            });
        }

        // ─────────────────────────────────────────────────────────────────────
        // MANAGE MARKETPLACES MODAL
        // ─────────────────────────────────────────────────────────────────────
        function openManageMarketplacesModal() {
            resetMpForm();
            loadMpList();
            bootstrap.Modal.getOrCreateInstance(document.getElementById('manageMarketplacesModal')).show();
        }

        function loadMpList() {
            $.ajax({
                type: 'POST', url: 'Stock.aspx/GetAllMarketplaces',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (r) {
                    var html = '';
                    JSON.parse(r.d).forEach(function (m) {
                        html += '<div class="mp-manage-row d-flex align-items-center gap-2">'
                            + '<div class="flex-grow-1">'
                            + '<strong>' + esc(m.MarketplaceName) + '</strong>'
                            + (m.Description ? '<br><small class="text-muted">' + esc(m.Description) + '</small>' : '')
                            + '</div>'
                            + '<span class="badge ' + (m.IsActive ? 'bg-success' : 'bg-secondary') + '">'
                            + (m.IsActive ? 'Active' : 'Inactive') + '</span>'
                            + '<button class="btn btn-outline-primary btn-sm" onclick="editMp(' + m.MarketplaceId + ',\'' + esc(m.MarketplaceName) + '\',\'' + esc(m.Description || '') + '\',' + m.IsActive + ')">'
                            + '<i class="fas fa-edit"></i></button>'
                            + '</div>';
                    });
                    document.getElementById('mpListContainer').innerHTML = html ||
                        '<div class="text-muted text-center py-2">No marketplaces yet.</div>';
                }
            });
        }

        function editMp(id, name, desc, active) {
            document.getElementById('mpEditId').value = id;
            document.getElementById('mpName').value   = name;
            document.getElementById('mpDesc').value   = desc;
            document.getElementById('mpActive').checked = active;
            document.getElementById('mpFormTitle').textContent = 'Edit Marketplace';
            $('#mpFormError,#mpFormSuccess').addClass('d-none');
        }

        function resetMpForm() {
            document.getElementById('mpEditId').value   = 0;
            document.getElementById('mpName').value     = '';
            document.getElementById('mpDesc').value     = '';
            document.getElementById('mpActive').checked = true;
            document.getElementById('mpFormTitle').textContent = 'Add New Marketplace';
            $('#mpFormError,#mpFormSuccess').addClass('d-none');
        }

        function saveMp() {
            var name   = $('#mpName').val().trim();
            var desc   = $('#mpDesc').val().trim();
            var active = document.getElementById('mpActive').checked;
            var id     = parseInt(document.getElementById('mpEditId').value) || 0;

            if (!name) {
                var el = document.getElementById('mpFormError');
                el.textContent = 'Name is required.'; el.classList.remove('d-none');
                return;
            }

            $.ajax({
                type: 'POST', url: 'Stock.aspx/SaveMarketplace',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ marketplace: { MarketplaceId: id, MarketplaceName: name, Description: desc, IsActive: active } }),
                success: function (r) {
                    var res = JSON.parse(r.d);
                    if (res.success) {
                        var ok = document.getElementById('mpFormSuccess');
                        ok.textContent = res.message; ok.classList.remove('d-none');
                        $('#mpFormError').addClass('d-none');
                        resetMpForm();
                        loadMpList();
                        // Reload marketplaces for table columns after a short delay
                        setTimeout(function () { loadMarketplacesAndStock(); loadStats(); }, 500);
                    } else {
                        var err = document.getElementById('mpFormError');
                        err.textContent = res.message; err.classList.remove('d-none');
                        $('#mpFormSuccess').addClass('d-none');
                    }
                }
            });
        }
    </script>
</asp:Content>
