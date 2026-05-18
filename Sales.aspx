<%@ Page Title="Sales" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Sales.aspx.cs" Inherits="Onfoot_Inventory.Sales" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css" rel="stylesheet" />
    <link href="https://cdn.datatables.net/responsive/2.5.0/css/responsive.bootstrap5.min.css" rel="stylesheet" />
    <!-- PDF.js for client-side BOL text extraction -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
    <style>
        .platform-website { background:#2563eb;color:#fff; }
        .platform-daraz    { background:#f97316;color:#fff; }
        .platform-markaz   { background:#16a34a;color:#fff; }
        .platform-badge    { display:inline-block;padding:2px 10px;border-radius:20px;font-size:0.75rem;font-weight:600; }
        .sale-items-table td, .sale-items-table th { padding:5px 8px;vertical-align:middle; }
        .sku-search-row input { border-right:0; }
        #tblSales tbody tr { cursor:pointer; }
        #tblSales tbody tr:hover td { background:#f0f4ff !important; }
        .stat-platform { border-top:3px solid; }
        .stat-website  { border-color:#2563eb; }
        .stat-daraz    { border-color:#f97316; }
        .stat-markaz   { border-color:#16a34a; }
        .variant-check-item:hover { background:#f8faff !important; }
        #manualSaleModal { padding: 0 !important; }
        #manualSaleModal .modal-dialog {
            max-width: 84%;
            width: 84%;
            margin: 2.5vh 8%;
            height: calc(100% - 5vh);
        }
        #manualSaleModal .modal-content {
            height: 100%;
            border-radius: 6px;
        }
    </style>
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-left">
            <h4><i class="fas fa-receipt me-2 text-primary"></i>Sales</h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="<%: ResolveUrl("~/") %>">Dashboard</a></li>
                    <li class="breadcrumb-item active">Sales</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex gap-2">
            <button class="btn btn-outline-secondary btn-sm" onclick="loadSales()" title="Refresh">
                <i class="fas fa-sync-alt me-1"></i> Refresh
            </button>
            <button class="btn btn-success" onclick="openManualSaleModal()">
                <i class="fas fa-pencil-alt me-1"></i> Manual Sale
            </button>
            <button class="btn btn-primary" onclick="openAddSaleModal()">
                <i class="fas fa-file-pdf me-1"></i> BOL Upload
            </button>
        </div>
    </div>

    <!-- Stats Row 1 -->
    <div class="row g-3 mb-3">
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon blue"><i class="fas fa-file-invoice"></i></div>
                <div>
                    <div class="stat-label">Total Bills</div>
                    <div class="stat-value" id="statTotalBills">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon green"><i class="fas fa-coins"></i></div>
                <div>
                    <div class="stat-label">Total Revenue</div>
                    <div class="stat-value" id="statTotalRevenue">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon purple"><i class="fas fa-calendar-day"></i></div>
                <div>
                    <div class="stat-label">Today's Bills</div>
                    <div class="stat-value" id="statTodayBills">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon yellow"><i class="fas fa-money-bill-wave"></i></div>
                <div>
                    <div class="stat-label">Today's Revenue</div>
                    <div class="stat-value" id="statTodayRevenue">—</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Stats Row 2 — Platform breakdown -->
    <div class="row g-3 mb-4">
        <div class="col-md-4">
            <div class="stat-card stat-platform stat-website">
                <div class="stat-icon" style="background:#dbeafe;"><i class="fas fa-globe" style="color:#2563eb;"></i></div>
                <div>
                    <div class="stat-label">Website Revenue</div>
                    <div class="stat-value" id="statWebsite">—</div>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="stat-card stat-platform stat-daraz">
                <div class="stat-icon" style="background:#ffedd5;"><i class="fas fa-shopping-bag" style="color:#f97316;"></i></div>
                <div>
                    <div class="stat-label">Daraz Revenue</div>
                    <div class="stat-value" id="statDaraz">—</div>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="stat-card stat-platform stat-markaz">
                <div class="stat-icon" style="background:#dcfce7;"><i class="fas fa-store" style="color:#16a34a;"></i></div>
                <div>
                    <div class="stat-label">Markaz Revenue</div>
                    <div class="stat-value" id="statMarkaz">—</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Sales Table -->
    <div class="table-card">
        <div class="table-card-header">
            <h6><i class="fas fa-list me-2 text-primary"></i>Sales List</h6>
            <div class="d-flex align-items-center gap-2 flex-wrap">
                <select id="filterPlatform" class="form-select form-select-sm" style="width:130px" onchange="loadSales()">
                    <option value="">All Platforms</option>
                    <option value="Website">Website</option>
                    <option value="Daraz">Daraz</option>
                    <option value="Markaz">Markaz</option>
                </select>
                <select id="filterStatus" class="form-select form-select-sm" style="width:130px" onchange="loadSales()">
                    <option value="">All Status</option>
                    <option value="Completed">Completed</option>
                    <option value="Cancelled">Cancelled</option>
                </select>
            </div>
        </div>
        <div class="table-card-body">
            <div class="table-responsive">
                <table id="tblSales" class="table table-hover w-100">
                    <thead>
                        <tr>
                            <th style="width:40px">#</th>
                            <th>Bill No</th>
                            <th style="width:100px">Platform</th>
                            <th style="width:105px">Date</th>
                            <th style="width:70px" class="text-center">Items</th>
                            <th style="width:80px" class="text-center">Total Qty</th>
                            <th style="width:120px">Amount</th>
                            <th style="width:90px">Status</th>
                            <th style="width:90px">Actions</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
    </div>

</asp:Content>

<%-- ============================================================
     MODALS + SCRIPTS
     ============================================================ --%>
<asp:Content ID="ModalsContent" ContentPlaceHolderID="ScriptsContent" runat="server">

    <!-- ========== ADD SALE MODAL ========== -->
    <div class="modal fade" id="saleModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-receipt me-2"></i>New Sale</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">

                    <!-- Sale Header -->
                    <div class="row g-3 mb-3">
                        <div class="col-md-3">
                            <label class="form-label">Platform <span class="text-danger">*</span></label>
                            <div class="d-flex gap-2 flex-wrap mt-1">
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="platform" id="rbWebsite" value="Website" checked />
                                    <label class="form-check-label" for="rbWebsite">
                                        <span class="platform-badge platform-website">Website</span>
                                    </label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="platform" id="rbDaraz" value="Daraz" />
                                    <label class="form-check-label" for="rbDaraz">
                                        <span class="platform-badge platform-daraz">Daraz</span>
                                    </label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="platform" id="rbMarkaz" value="Markaz" />
                                    <label class="form-check-label" for="rbMarkaz">
                                        <span class="platform-badge platform-markaz">Markaz</span>
                                    </label>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Bill Number <span class="text-danger">*</span></label>
                            <input type="text" id="txtBillNumber" class="form-control" placeholder="e.g. BILL-001" maxlength="100" />
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Sale Date <span class="text-danger">*</span></label>
                            <input type="date" id="txtSaleDate" class="form-control" />
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Notes</label>
                            <input type="text" id="txtNotes" class="form-control" placeholder="Optional notes" maxlength="500" />
                        </div>
                    </div>

                    <hr class="my-2" />

                    <!-- BOL Upload -->
                    <div class="p-2 bg-light rounded mb-1">
                        <div class="d-flex align-items-center gap-3">
                            <i class="fas fa-file-pdf text-danger fa-lg"></i>
                            <div class="flex-grow-1">
                                <div class="fw-semibold" style="font-size:0.85rem;">Bill of Lading Upload (PostEx)</div>
                                <div class="text-muted" style="font-size:0.75rem;">Upload BOL PDF — extracts all products automatically from every page</div>
                            </div>
                            <input type="file" id="bolFileInput" accept=".pdf" class="d-none" />
                            <button type="button" class="btn btn-outline-danger btn-sm" onclick="$('#bolFileInput').click()">
                                <i class="fas fa-upload me-1"></i> Upload BOL PDF
                            </button>
                        </div>
                        <div id="bolStatus" class="mt-1" style="font-size:0.8rem;min-height:18px;"></div>
                    </div>

                    <!-- SKU Search -->
                    <div class="mb-2">
                        <div class="input-group sku-search-row">
                            <span class="input-group-text"><i class="fas fa-search"></i></span>
                            <input type="text" id="txtSearchSKU" class="form-control form-control-sm"
                                   placeholder="Search order ID, product, SKU — or enter exact SKU to add"
                                   oninput="filterSaleItems()"
                                   onkeydown="if(event.key==='Enter'){searchSKU();return false;}" />
                            <button class="btn btn-primary btn-sm" type="button" onclick="searchSKU()" title="Add item by exact SKU">
                                <i class="fas fa-plus me-1"></i> Add SKU
                            </button>
                            <button class="btn btn-outline-secondary btn-sm" type="button" onclick="$('#txtSearchSKU').val('');filterSaleItems();" title="Clear">
                                <i class="fas fa-times"></i>
                            </button>
                        </div>
                        <div id="skuSearchResult" class="mt-1"></div>
                    </div>

                    <!-- Sale Items Table -->
                    <div class="table-responsive">
                        <table class="table table-sm table-bordered sale-items-table mb-1" id="tblSaleItems">
                            <thead class="table-primary">
                                <tr>
                                    <th style="width:35px">#</th>
                                    <th style="width:90px">Order ID</th>
                                    <th style="width:80px">Product</th>
                                    <th style="width:200px">SKU</th>
                                    <th style="width:70px">Color</th>
                                    <th style="width:55px">Size</th>
                                    <th style="width:70px" class="text-center">Qty</th>
                                    <th style="width:110px">Sale Price</th>
                                    <th style="width:100px">Total</th>
                                    <th style="width:40px"></th>
                                </tr>
                            </thead>
                            <tbody id="saleItemsBody">
                                <tr id="noItemsRow">
                                    <td colspan="10" class="text-center text-muted py-3">
                                        <i class="fas fa-inbox me-1"></i> No items added. Search SKU or upload BOL.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- Grand Total -->
                    <div class="text-end">
                        <span class="text-muted me-2">Total Qty:</span>
                        <strong id="lblTotalQty">0</strong>
                        <span class="ms-4 text-muted me-2">Grand Total:</span>
                        <strong class="text-primary fs-6" id="lblGrandTotal">Rs. 0.00</strong>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i> Cancel
                    </button>
                    <button type="button" id="btnSaveSale" class="btn btn-primary" onclick="saveSale()">
                        <i class="fas fa-save me-1"></i> Save Sale
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ========== VIEW SALE MODAL ========== -->
    <div class="modal fade" id="viewSaleModal" tabindex="-1">
        <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-eye me-2"></i><span id="viewSaleTitle">Sale Detail</span></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="viewSaleBody">
                    <div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x text-primary"></i></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="button" id="btnCancelSale" class="btn btn-danger" onclick="cancelSale()">
                        <i class="fas fa-ban me-1"></i> Cancel Sale
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- BOL Customers List Modal -->
    <div class="modal fade" id="bolCustomersModal" tabindex="-1">
        <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-users me-2 text-primary"></i>Customers from BOL</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body p-0">
                    <table class="table table-sm table-hover mb-0" id="tblBolCustomers">
                        <thead class="table-primary sticky-top">
                            <tr>
                                <th style="width:80px">Order ID</th>
                                <th>Name</th>
                                <th style="width:150px">Phone</th>
                                <th style="width:110px">Destination</th>
                                <th>Address</th>
                            </tr>
                        </thead>
                        <tbody id="bolCustomersBody"></tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <small class="text-muted me-auto">These customers will be saved automatically when you save the sale.</small>
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Customer Detail Modal -->
    <div class="modal fade" id="customerModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered" style="max-width:420px">
            <div class="modal-content">
                <div class="modal-header bg-info text-white">
                    <h5 class="modal-title"><i class="fas fa-user me-2"></i>Customer Info</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="customerModalBody">
                    <div class="text-center py-3"><i class="fas fa-spinner fa-spin fa-2x text-primary"></i></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Cancel Confirm Modal -->
    <div class="modal fade" id="cancelConfirmModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered" style="max-width:420px">
            <div class="modal-content">
                <div class="modal-header" style="background:#b91c1c;">
                    <h5 class="modal-title text-white"><i class="fas fa-ban me-2"></i>Cancel Sale</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center py-4">
                    <div class="mb-3" style="font-size:2.5rem;color:#fca5a5;"><i class="fas fa-exclamation-circle"></i></div>
                    <p class="mb-1">Cancel sale <strong id="cancelBillName"></strong>?</p>
                    <p class="text-muted small">Stock quantities will be restored automatically.</p>
                </div>
                <div class="modal-footer justify-content-center gap-3">
                    <button type="button" class="btn btn-secondary px-4" data-bs-dismiss="modal">No, Keep It</button>
                    <button type="button" class="btn btn-danger px-4" id="btnConfirmCancel" onclick="executeCancel()">
                        <i class="fas fa-ban me-1"></i> Yes, Cancel
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ========== MANUAL SALE MODAL ========== -->
    <div class="modal fade" id="manualSaleModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header bg-success text-white">
                    <h5 class="modal-title"><i class="fas fa-pencil-alt me-2"></i>Manual Sale Entry</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">

                    <!-- Sale Header -->
                    <div class="row g-3 mb-3">
                        <div class="col-md-3">
                            <label class="form-label">Marketplace <span class="text-danger">*</span></label>
                            <select id="ddlManualMarketplace" class="form-select" onchange="loadVariants()">
                                <option value="">Loading...</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Bill Number <span class="text-danger">*</span></label>
                            <input type="text" id="txtManualBillNo" class="form-control" placeholder="Auto-filled or enter manually" maxlength="100" />
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Sale Date <span class="text-danger">*</span></label>
                            <input type="date" id="txtManualSaleDate" class="form-control" onchange="autoFillManualBillNo()" />
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Notes</label>
                            <input type="text" id="txtManualNotes" class="form-control" placeholder="Optional notes" maxlength="500" />
                        </div>
                    </div>

                    <hr class="my-2" />

                    <!-- Product Multi-Select Checkbox Dropdown -->
                    <div class="mb-2">
                        <label class="form-label small fw-semibold mb-1"><i class="fas fa-boxes me-1 text-success"></i>Select Products</label>
                        <div class="d-flex gap-2 align-items-start">
                            <div class="flex-grow-1 position-relative" id="variantDropdownWrapper">
                                <button type="button" id="btnVariantDropdown"
                                        class="form-select text-start text-truncate"
                                        style="cursor:pointer;"
                                        onclick="toggleVariantDropdown(event)">
                                    <span id="variantDropdownLabel" class="text-muted">Click to select products...</span>
                                </button>
                                <div id="variantDropdownPanel" class="d-none border rounded shadow-sm bg-white"
                                     style="position:absolute;top:calc(100% + 2px);left:0;right:0;z-index:1055;display:flex;flex-direction:column;max-height:480px;">
                                    <div class="p-2 border-bottom bg-light flex-shrink-0">
                                        <input type="text" id="txtVariantFilter" class="form-control form-control-sm"
                                               placeholder="Search product, SKU, color, size..."
                                               oninput="filterVariantList()"
                                               onclick="event.stopPropagation()" />
                                    </div>
                                    <div id="variantCheckboxList" style="overflow-y:auto;flex:1;">
                                        <div class="text-center text-muted py-3 small">
                                            <i class="fas fa-spinner fa-spin me-1"></i> Loading products...
                                        </div>
                                    </div>
                                    <div class="px-3 py-2 border-top bg-light flex-shrink-0 d-flex justify-content-between align-items-center">
                                        <small id="variantSelectCount" class="text-muted">0 selected</small>
                                        <button type="button" class="btn btn-link btn-sm p-0 text-muted" onclick="clearVariantSelection()">Clear all</button>
                                    </div>
                                </div>
                            </div>
                            <button class="btn btn-primary flex-shrink-0" type="button" onclick="addSelectedVariants()">
                                <i class="fas fa-plus me-1"></i> Add Selected
                            </button>
                        </div>
                        <div id="variantStockError" class="mt-1" style="display:none;"></div>
                    </div>

                    <!-- Sale Items Heading -->
                    <div class="d-flex align-items-center gap-2 mb-2 mt-1">
                        <i class="fas fa-list text-success"></i>
                        <span class="fw-semibold" style="font-size:0.95rem;">Sale Items</span>
                        <span id="manualItemCount" class="badge bg-success ms-1">0</span>
                    </div>

                    <!-- Sale Items Table -->
                    <div class="table-responsive">
                        <table class="table table-sm table-bordered sale-items-table mb-1">
                            <thead class="table-success">
                                <tr style="font-size:0.95rem;">
                                    <th style="width:30px">#</th>
                                    <th style="width:150px">Order ID</th>
                                    <th style="width:220px">SKU</th>
                                    <th style="width:55px">Color</th>
                                    <th style="width:55px">Size</th>
                                    <th style="width:55px" class="text-center">Qty</th>
                                    <th style="width:120px">Sale Price</th>
                                    <th style="width:100px">Total</th>
                                    <th style="width:25px"></th>
                                </tr>
                            </thead>
                            <tbody id="manualSaleItemsBody">
                                <tr>
                                    <td colspan="9" class="text-center text-muted py-3">
                                        <i class="fas fa-inbox me-1"></i> No items added. Search and add SKU above.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- Grand Total -->
                    <div class="text-end">
                        <span class="text-muted me-2">Total Qty:</span>
                        <strong id="lblManualTotalQty">0</strong>
                        <span class="ms-4 text-muted me-2">Grand Total:</span>
                        <strong class="text-success fs-6" id="lblManualGrandTotal">Rs. 0.00</strong>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i> Cancel
                    </button>
                    <button type="button" id="btnSaveManualSale" class="btn btn-success" onclick="saveManualSale()">
                        <i class="fas fa-save me-1"></i> Save Sale
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Toast Container -->
    <div class="toast-container-fixed" id="toastContainer"></div>

    <!-- DataTables -->
    <script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.7/js/dataTables.bootstrap5.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.5.0/js/dataTables.responsive.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.5.0/js/responsive.bootstrap5.min.js"></script>

    <script>
        var salesTable;
        var saleItems       = [];  // [{variantId, sku, productName, color, size, qty, salePrice}]
        var currentSaleId   = 0;
        var cancelSaleId    = 0;
        var bolCustomers    = [];   // customers extracted from uploaded BOL

        var pkFmt = { minimumFractionDigits: 2 };

        /* ============================================================ INIT */
        $(document).ready(function () {
            initDataTable();
            loadStats();
            loadSales();

            // Set today's date
            $('#txtSaleDate').val(new Date().toISOString().split('T')[0]);

            // Row click → view sale
            $('#tblSales tbody').on('click', 'tr', function (e) {
                if ($(e.target).closest('.btn-view, .btn-cancel-sale').length) return;
                var $btn = $(this).find('.btn-view');
                if (!$btn.length) return;
                var m = $btn.attr('onclick').match(/viewSale\((\d+)\)/);
                if (m) viewSale(parseInt(m[1]));
            });
        });

        function initDataTable() {
            salesTable = $('#tblSales').DataTable({
                responsive:  true,
                pageLength:  15,
                lengthMenu:  [[10,15,25,50],[10,15,25,50]],
                columnDefs:  [{ orderable: false, targets: [8] }],
                order:       [[3, 'desc']],
                language: {
                    search:            '',
                    searchPlaceholder: 'Search sales...',
                    emptyTable:        "<div class='text-center py-4 text-muted'><i class='fas fa-inbox fa-2x mb-2 d-block'></i>No sales found</div>"
                },
                dom: "<'row mb-2'<'col-sm-6'l><'col-sm-6'f>><'row'<'col-sm-12'tr>><'row mt-2'<'col-sm-5'i><'col-sm-7'p>>"
            });
        }

        /* ============================================================ LOAD DATA */
        function loadStats() {
            $.ajax({
                type:'POST', url:'Sales.aspx/GetSaleStats',
                contentType:'application/json; charset=utf-8', dataType:'json',
                success: function(res) {
                    var s = JSON.parse(res.d);
                    $('#statTotalBills').text(s.TotalBills);
                    $('#statTotalRevenue').text('Rs. ' + parseFloat(s.TotalRevenue).toLocaleString('en-PK', pkFmt));
                    $('#statTodayBills').text(s.TodayBills);
                    $('#statTodayRevenue').text('Rs. ' + parseFloat(s.TodayRevenue).toLocaleString('en-PK', pkFmt));
                    $('#statWebsite').text('Rs. ' + parseFloat(s.WebsiteRevenue).toLocaleString('en-PK', pkFmt));
                    $('#statDaraz').text('Rs. '   + parseFloat(s.DarazRevenue).toLocaleString('en-PK', pkFmt));
                    $('#statMarkaz').text('Rs. '  + parseFloat(s.MarkazRevenue).toLocaleString('en-PK', pkFmt));
                }
            });
        }

        function loadSales() {
            var platform = $('#filterPlatform').val();
            var status   = $('#filterStatus').val();
            $.ajax({
                type:'POST', url:'Sales.aspx/GetSales',
                contentType:'application/json; charset=utf-8', dataType:'json',
                data: JSON.stringify({ platform: platform, status: status }),
                success: function(res) {
                    var rows = JSON.parse(res.d);
                    salesTable.clear();
                    $.each(rows, function(i, s) {
                        var pBadge   = '<span class="platform-badge platform-' + s.Platform.toLowerCase() + '">' + s.Platform + '</span>';
                        var stBadge  = s.Status === 'Completed'
                            ? '<span class="badge-active">Completed</span>'
                            : '<span class="badge-inactive">Cancelled</span>';
                        var actions  = '<button class="btn-action-edit btn-view me-1" onclick="viewSale(' + s.SaleId + ')" title="View"><i class="fas fa-eye"></i></button>';
                        if (s.HasCustomer)
                            actions += '<button class="btn btn-sm btn-outline-info py-0 px-1 me-1" onclick="viewCustomer(' + s.SaleId + ')" title="Customer Info"><i class="fas fa-user"></i></button>';
                        if (s.Status === 'Completed')
                            actions += '<button class="btn-action-delete btn-cancel-sale" onclick="confirmCancelSale(' + s.SaleId + ',\'' + escJs(s.BillNumber) + '\')" title="Cancel Sale"><i class="fas fa-ban"></i></button>';

                        salesTable.row.add([
                            i + 1,
                            '<strong>' + escHtml(s.BillNumber) + '</strong>',
                            pBadge,
                            s.SaleDate,
                            '<span class="badge bg-secondary">' + s.ItemCount + '</span>',
                            s.TotalQty,
                            'Rs. ' + parseFloat(s.TotalAmount).toLocaleString('en-PK', pkFmt),
                            stBadge,
                            actions
                        ]);
                    });
                    salesTable.draw();
                },
                error: function() { showToast('Failed to load sales.', 'danger'); }
            });
        }

        /* ============================================================ ADD SALE MODAL */
        function openAddSaleModal() {
            saleItems = [];
            renderSaleItems();
            $('#txtBillNumber, #txtNotes').val('');
            bolCustomers = [];
            $('#txtSaleDate').val(new Date().toISOString().split('T')[0]);
            $('#rbWebsite').prop('checked', true);
            $('#txtSearchSKU').val('');
            $('#skuSearchResult').html('');
            $('#bolStatus').html('');
            $('#bolFileInput').val('');
            new bootstrap.Modal(document.getElementById('saleModal')).show();
            setTimeout(function() { $('#txtBillNumber').focus(); }, 400);
        }

        /* ============================================================ SKU SEARCH */
        function searchSKU() {
            var sku = $.trim($('#txtSearchSKU').val());
            if (!sku) return;
            $('#skuSearchResult').html('<span class="text-muted small"><i class="fas fa-spinner fa-spin me-1"></i>Searching...</span>');

            $.ajax({
                type:'POST', url:'Sales.aspx/GetVariantBySKU',
                contentType:'application/json; charset=utf-8', dataType:'json',
                data: JSON.stringify({ sku: sku }),
                success: function(res) {
                    var v = JSON.parse(res.d);
                    if (!v) {
                        $('#skuSearchResult').html('<span class="text-danger small"><i class="fas fa-times-circle me-1"></i>SKU "' + escHtml(sku) + '" not found.</span>');
                        return;
                    }
                    var html = '<div class="d-flex align-items-center gap-3 p-2 bg-light border rounded mt-1">'
                             + '<div class="flex-grow-1">'
                             + '<span class="fw-semibold">' + escHtml(v.ProductName) + '</span>'
                             + ' <span class="badge bg-secondary">' + escHtml(v.Color) + '</span>'
                             + ' <span class="badge bg-light text-dark border">Sz ' + escHtml(v.Size) + '</span>'
                             + ' <code class="ms-1" style="font-size:0.75rem;">' + escHtml(sku) + '</code>'
                             + '</div>'
                             + '<span class="text-muted small">Stock: ' + v.StockQty + '</span>'
                             + '<button type="button" class="btn btn-success btn-sm" onclick="addSKUToItems(' + JSON.stringify(v).replace(/"/g,'&quot;') + ',\'' + escJs(sku) + '\')">'
                             + '<i class="fas fa-plus me-1"></i>Add</button>'
                             + '</div>';
                    $('#skuSearchResult').html(html);
                },
                error: function() { $('#skuSearchResult').html('<span class="text-danger small">Search failed.</span>'); }
            });
        }

        function addSKUToItems(variant, sku) {
            // Check duplicate
            if (saleItems.some(function(x){ return x.sku === sku; })) {
                showToast('SKU "' + sku + '" already in the list.', 'warning'); return;
            }
            saleItems.push({
                variantId:   variant.VariantId,
                sku:         sku,
                productName: variant.ProductName,
                color:       variant.Color,
                size:        variant.Size,
                qty:         1,
                salePrice:   variant.SalePrice,
                matched:     true,
                orderRef:    ''
            });
            renderSaleItems();
            $('#txtSearchSKU').val('');
            $('#skuSearchResult').html('');
            $('#txtSearchSKU').focus();
        }

        function removeSaleItem(idx) {
            saleItems.splice(idx, 1);
            renderSaleItems();
        }

        function updateItemQty(idx, val) {
            saleItems[idx].qty = parseInt(val) || 1;
            recalcTotals();
        }

        function updateItemPrice(idx, val) {
            saleItems[idx].salePrice = parseFloat(val) || 0;
            recalcTotals();
        }

        function renderSaleItems() {
            var $body = $('#saleItemsBody');
            if (saleItems.length === 0) {
                $body.html('<tr id="noItemsRow"><td colspan="10" class="text-center text-muted py-3"><i class="fas fa-inbox me-1"></i> No items added. Search SKU or upload BOL.</td></tr>');
                $('#lblTotalQty').text('0');
                $('#lblGrandTotal').text('Rs. 0.00');
                return;
            }

            var html = '';
            var lastOrderRef = null;

            saleItems.forEach(function (it, idx) {
                var lineTotal  = (it.qty * it.salePrice).toFixed(2);
                var rowClass   = (it.matched === false) ? 'table-warning' : '';
                var skuDisplay = it.matched === false
                    ? '<code style="font-size:0.76rem;color:#b45309;">' + escHtml(it.sku) + ' ⚠</code>'
                    : '<code style="font-size:0.76rem;">' + escHtml(it.sku) + '</code>';

                // Show Order ID only on first occurrence
                var orderKey  = it.orderRef || '';
                var orderCell = (orderKey !== lastOrderRef)
                    ? '<strong style="font-size:0.82rem;">' + escHtml(orderKey || '—') + '</strong>'
                    : '';
                lastOrderRef = orderKey;
                var orderData = 'data-ref="' + escHtml(orderKey) + '"';

                html += '<tr class="' + rowClass + '">'
                      + '<td class="text-center text-muted" style="font-size:0.78rem;">' + (idx + 1) + '</td>'
                      + '<td style="white-space:nowrap;" ' + orderData + '>' + orderCell + '</td>'
                      + '<td style="max-width:80px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="' + escHtml(it.productName) + '">'
                      +     '<small>' + escHtml(it.productName) + '</small></td>'
                      + '<td>' + skuDisplay + '</td>'
                      + '<td>' + (it.color ? '<span class="badge bg-secondary">' + escHtml(it.color) + '</span>' : '—') + '</td>'
                      + '<td class="text-center">' + escHtml(it.size) + '</td>'
                      + '<td><input type="number" class="form-control form-control-sm text-center" min="1" value="' + it.qty + '" onchange="updateItemQty(' + idx + ',this.value)" style="width:58px" /></td>'
                      + '<td><div class="input-group input-group-sm"><span class="input-group-text">Rs.</span><input type="number" class="form-control" min="0" step="0.01" value="' + it.salePrice + '" onchange="updateItemPrice(' + idx + ',this.value)" /></div></td>'
                      + '<td class="fw-semibold">Rs. ' + parseFloat(lineTotal).toLocaleString('en-PK', pkFmt) + '</td>'
                      + '<td class="text-center"><button type="button" class="btn btn-sm btn-outline-danger py-0 px-1" onclick="removeSaleItem(' + idx + ')"><i class="fas fa-times"></i></button></td>'
                      + '</tr>';
            });

            $body.html(html);
            recalcTotals();
        }

        function filterSaleItems() {
            var q = $.trim($('#txtItemSearch').val()).toLowerCase();
            if (!q) { renderSaleItems(); return; }

            var lastOrderRef = null;
            $('#saleItemsBody tr').each(function () {
                var $tr      = $(this);
                var product  = ($tr.find('td:eq(2)').text()  || '').toLowerCase();
                var sku      = ($tr.find('td:eq(3)').text()  || '').toLowerCase();
                var orderId  = ($tr.find('td:eq(1)').text()  || '').toLowerCase();
                var color    = ($tr.find('td:eq(4)').text()  || '').toLowerCase();
                var size     = ($tr.find('td:eq(5)').text()  || '').toLowerCase();

                var matches = product.indexOf(q) >= 0
                           || sku.indexOf(q)     >= 0
                           || orderId.indexOf(q) >= 0
                           || color.indexOf(q)   >= 0
                           || size.indexOf(q)    >= 0;

                $tr.toggle(matches);

                if (matches) {
                    // Re-manage Order ID visibility: show only on first visible row per order
                    var $orderCell = $tr.find('td:eq(1)');
                    var currentRef = $orderCell.data('ref') || $orderCell.text().trim();
                    $orderCell.data('ref', currentRef);

                    if (currentRef && currentRef !== lastOrderRef) {
                        $orderCell.html('<strong style="font-size:0.82rem;">' + escHtml(currentRef) + '</strong>');
                        lastOrderRef = currentRef;
                    } else if (currentRef === lastOrderRef) {
                        $orderCell.html('');
                    }
                }
            });
        }

        function filterSaleItems() {
            var q = $.trim($('#txtSearchSKU').val()).toLowerCase();
            if (!q) { renderSaleItems(); return; }

            var lastRef = null;
            $('#saleItemsBody tr').each(function () {
                var $tr     = $(this);
                var orderId = ($tr.find('td:eq(1)').attr('data-ref') || '').toLowerCase();
                var product = ($tr.find('td:eq(2)').text() || '').toLowerCase();
                var sku     = ($tr.find('td:eq(3)').text() || '').toLowerCase();
                var color   = ($tr.find('td:eq(4)').text() || '').toLowerCase();

                var match = orderId.indexOf(q) >= 0
                         || product.indexOf(q) >= 0
                         || sku.indexOf(q)     >= 0
                         || color.indexOf(q)   >= 0;

                $tr.toggle(match);

                if (match) {
                    var ref = $tr.find('td:eq(1)').attr('data-ref') || '';
                    var $cell = $tr.find('td:eq(1)');
                    if (ref && ref !== lastRef) {
                        $cell.html('<strong style="font-size:0.82rem;">' + escHtml(ref) + '</strong>');
                        lastRef = ref;
                    } else {
                        $cell.html('');
                    }
                }
            });
        }

        function recalcTotals() {
            var totalQty = 0, grandTotal = 0;
            saleItems.forEach(function(it) {
                totalQty   += it.qty;
                grandTotal += it.qty * it.salePrice;
            });
            $('#lblTotalQty').text(totalQty);
            $('#lblGrandTotal').text('Rs. ' + grandTotal.toLocaleString('en-PK', pkFmt));
        }

        /* ============================================================ BOL UPLOAD — PDF.js extraction */
        // Set PDF.js worker
        pdfjsLib.GlobalWorkerOptions.workerSrc =
            'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

        // Wire file input change
        document.getElementById('bolFileInput').addEventListener('change', function () {
            if (this.files && this.files[0]) processBOL(this.files[0]);
        });

        async function processBOL(file) {
            $('#bolStatus').html('<i class="fas fa-spinner fa-spin me-1 text-primary"></i> Reading PDF: <strong>' + escHtml(file.name) + '</strong>');

            try {
                var arrayBuffer = await file.arrayBuffer();
                var pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
                var numPages = pdf.numPages;

                // Extract text from every page
                var pageTexts = [];
                for (var i = 1; i <= numPages; i++) {
                    var page     = await pdf.getPage(i);
                    var content  = await page.getTextContent();
                    var pageText = content.items.map(function (it) { return it.str; }).join(' ');
                    pageTexts.push(pageText);
                }

                var fullText = pageTexts.join('\n---PAGE---\n');

                $('#bolStatus').html('<i class="fas fa-spinner fa-spin me-1 text-primary"></i> Matching SKUs in inventory (' + numPages + ' pages)...');

                $.ajax({
                    type: 'POST', url: 'Sales.aspx/ParseBOLText',
                    contentType: 'application/json; charset=utf-8', dataType: 'json',
                    data: JSON.stringify({ bolText: fullText }),
                    success: function (res) {
                        var result = JSON.parse(res.d);
                        if (!result.success) {
                            $('#bolStatus').html('<span class="text-danger"><i class="fas fa-times-circle me-1"></i>' + escHtml(result.message) + '</span>');
                            return;
                        }

                        var items = result.items;
                        bolCustomers = result.customers || [];

                        // Auto-set platform from detected BOL type
                        if (result.platform) {
                            $('input[name="platform"][value="' + result.platform + '"]').prop('checked', true);
                        }

                        if (!items || items.length === 0) {
                            $('#bolStatus').html('<span class="text-warning"><i class="fas fa-exclamation-triangle me-1"></i>No products found in BOL.</span>');
                            return;
                        }

                        // Auto-fill sale date from BOL
                        var bolDate = items[0].SaleDate || new Date().toISOString().split('T')[0];
                        $('#txtSaleDate').val(bolDate);

                        // Auto-fill bill number as date-seq (e.g. 2026-05-02-01)
                        if (!$.trim($('#txtBillNumber').val())) {
                            $.ajax({
                                type: 'POST', url: 'Sales.aspx/GetNextBillNumber',
                                contentType: 'application/json; charset=utf-8', dataType: 'json',
                                data: JSON.stringify({ saleDate: bolDate }),
                                success: function (r) { $('#txtBillNumber').val(JSON.parse(r.d)); }
                            });
                        }

                        // Aggregate items: same variant → add qty
                        var added = 0, merged = 0, unmatched = 0;
                        items.forEach(function (it) {
                            if (!it.Matched) unmatched++;

                            if (it.VariantId > 0) {
                                // Same variant from a different order ref = new row (keep order ref separate)
                                var existing = saleItems.find(function (x) {
                                    return x.variantId === it.VariantId && x.orderRef === it.OrderRef;
                                });
                                if (existing) { existing.qty += it.Quantity; merged++; return; }
                            }

                            saleItems.push({
                                variantId:   it.VariantId,
                                sku:         it.SKUNumber || (it.ProductCode + '-' + it.Size),
                                productName: it.ProductName,
                                color:       it.Color,
                                size:        it.Size,
                                qty:         it.Quantity,
                                salePrice:   it.SalePrice,
                                matched:     it.Matched,
                                orderRef:    it.OrderRef
                            });
                            added++;
                        });

                        renderSaleItems();

                        var custBtn = bolCustomers.length > 0
                            ? ' &nbsp;<button type="button" class="btn btn-outline-primary btn-sm py-0" onclick="showBolCustomers()">'
                              + '<i class="fas fa-users me-1"></i>Customers (' + bolCustomers.length + ')</button>'
                            : '';

                        var msg = '<i class="fas fa-check-circle me-1 text-success"></i>'
                                + '<strong>' + items.length + '</strong> items from <strong>' + numPages + '</strong> pages. '
                                + added + ' added, ' + merged + ' qty merged' + custBtn;
                        if (unmatched > 0)
                            msg += ' &nbsp;<span class="text-warning small"><i class="fas fa-exclamation-triangle me-1"></i>' + unmatched + ' not matched</span>';
                        $('#bolStatus').html(msg);
                    },
                    error: function () {
                        $('#bolStatus').html('<span class="text-danger"><i class="fas fa-times-circle me-1"></i>Server error parsing BOL.</span>');
                    }
                });
            } catch (e) {
                $('#bolStatus').html('<span class="text-danger"><i class="fas fa-times-circle me-1"></i>Error reading PDF: ' + escHtml(e.message) + '</span>');
            }
        }

        /* ============================================================ SAVE SALE */
        function saveSale() {
            var billNo   = $.trim($('#txtBillNumber').val());
            var platform = $('input[name="platform"]:checked').val();
            var saleDate = $('#txtSaleDate').val();

            if (!billNo)   { shakeField('#txtBillNumber'); showToast('Bill Number is required.', 'warning'); return; }
            if (!saleDate) { shakeField('#txtSaleDate');   showToast('Sale Date is required.', 'warning');   return; }
            if (saleItems.length === 0) { showToast('Add at least one item.', 'warning'); return; }

            var sale = {
                SaleId:     0,
                BillNumber: billNo,
                Platform:   platform,
                SaleDate:   saleDate,
                Status:     'Completed',
                Notes:      $.trim($('#txtNotes').val())
            };

            var itemsPayload = saleItems.map(function(it) {
                return {
                    VariantId:   it.variantId,
                    SKUNumber:   it.sku,
                    ProductName: it.productName,
                    Color:       it.color,
                    Size:        it.size,
                    Quantity:    it.qty,
                    SalePrice:   it.salePrice
                };
            });

            var $btn = $('#btnSaveSale');
            $btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i> Saving...');

            $.ajax({
                type:'POST', url:'Sales.aspx/SaveSale',
                contentType:'application/json; charset=utf-8', dataType:'json',
                data: JSON.stringify({ sale: sale, itemsJson: JSON.stringify(itemsPayload), customersJson: JSON.stringify(bolCustomers) }),
                success: function(res) {
                    var r = JSON.parse(res.d);
                    if (r.success) {
                        bootstrap.Modal.getInstance(document.getElementById('saleModal')).hide();
                        showToast(r.message, 'success');
                        loadSales(); loadStats();
                    } else {
                        showToast(r.message, 'danger');
                    }
                },
                error: function() { showToast('An error occurred.', 'danger'); },
                complete: function() { $btn.prop('disabled', false).html('<i class="fas fa-save me-1"></i> Save Sale'); }
            });
        }

        /* ============================================================ VIEW SALE */
        function viewSale(saleId) {
            currentSaleId = saleId;
            $('#viewSaleTitle').text('Sale Detail');
            $('#viewSaleBody').html('<div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x text-primary"></i></div>');
            new bootstrap.Modal(document.getElementById('viewSaleModal')).show();

            $.ajax({
                type:'POST', url:'Sales.aspx/GetSaleById',
                contentType:'application/json; charset=utf-8', dataType:'json',
                data: JSON.stringify({ saleId: saleId }),
                success: function(res) {
                    var data = JSON.parse(res.d);
                    if (!data) { showToast('Sale not found.', 'warning'); return; }
                    var s = data.Sale, items = data.Items;

                    var pClass = 'platform-' + s.Platform.toLowerCase();
                    $('#viewSaleTitle').text('Bill: ' + s.BillNumber);

                    var cancelled = s.Status === 'Cancelled';
                    $('#btnCancelSale').toggle(!cancelled);

                    var infoHtml = '<div class="row g-2 mb-3">'
                        + '<div class="col-auto"><span class="platform-badge ' + pClass + '">' + s.Platform + '</span></div>'
                        + '<div class="col-auto text-muted small pt-1"><i class="fas fa-calendar me-1"></i>' + s.SaleDate + '</div>'
                        + '<div class="col-auto ms-auto">'
                        + (cancelled ? '<span class="badge bg-danger">Cancelled</span>' : '<span class="badge bg-success">Completed</span>')
                        + '</div></div>';
                    if (s.Notes) infoHtml += '<p class="text-muted small mb-2"><i class="fas fa-sticky-note me-1"></i>' + escHtml(s.Notes) + '</p>';

                    var tableHtml = '<div class="table-responsive"><table class="table table-sm table-bordered mb-2">'
                        + '<thead class="table-light"><tr><th>#</th><th>SKU</th><th>Product</th><th>Color</th><th>Size</th><th class="text-center">Qty</th><th>Price</th><th>Total</th></tr></thead><tbody>';
                    $.each(items, function(i, it) {
                        tableHtml += '<tr>'
                            + '<td>' + (i+1) + '</td>'
                            + '<td><code style="font-size:0.75rem;">' + escHtml(it.SKUNumber) + '</code></td>'
                            + '<td>' + escHtml(it.ProductName) + '</td>'
                            + '<td><span class="badge bg-secondary">' + escHtml(it.Color) + '</span></td>'
                            + '<td>' + escHtml(it.Size) + '</td>'
                            + '<td class="text-center">' + it.Quantity + '</td>'
                            + '<td>Rs. ' + parseFloat(it.SalePrice).toLocaleString('en-PK', pkFmt) + '</td>'
                            + '<td>Rs. ' + parseFloat(it.TotalAmount).toLocaleString('en-PK', pkFmt) + '</td>'
                            + '</tr>';
                    });
                    tableHtml += '</tbody></table></div>';
                    tableHtml += '<div class="text-end"><span class="text-muted me-2">Grand Total:</span>'
                               + '<strong class="text-primary fs-6">Rs. ' + parseFloat(s.TotalAmount).toLocaleString('en-PK', pkFmt) + '</strong></div>';

                    $('#viewSaleBody').html(infoHtml + tableHtml);
                },
                error: function() { showToast('Failed to load sale.', 'danger'); }
            });
        }

        /* ============================================================ CANCEL SALE */
        function cancelSale() {
            bootstrap.Modal.getInstance(document.getElementById('viewSaleModal')).hide();
            setTimeout(function() {
                $('#cancelBillName').text('#' + currentSaleId);
                cancelSaleId = currentSaleId;
                new bootstrap.Modal(document.getElementById('cancelConfirmModal')).show();
            }, 300);
        }

        function confirmCancelSale(saleId, billNo) {
            cancelSaleId = saleId;
            $('#cancelBillName').text('"' + billNo + '"');
            new bootstrap.Modal(document.getElementById('cancelConfirmModal')).show();
        }

        function executeCancel() {
            var $btn = $('#btnConfirmCancel');
            $btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i> Cancelling...');
            $.ajax({
                type:'POST', url:'Sales.aspx/CancelSale',
                contentType:'application/json; charset=utf-8', dataType:'json',
                data: JSON.stringify({ saleId: cancelSaleId }),
                success: function(res) {
                    var r = JSON.parse(res.d);
                    bootstrap.Modal.getInstance(document.getElementById('cancelConfirmModal')).hide();
                    showToast(r.message, r.success ? 'success' : 'danger');
                    if (r.success) { loadSales(); loadStats(); }
                },
                error: function() { showToast('Cancel failed.', 'danger'); },
                complete: function() { $btn.prop('disabled', false).html('<i class="fas fa-ban me-1"></i> Yes, Cancel'); }
            });
        }

        /* ============================================================ BOL CUSTOMERS LIST */
        function showBolCustomers() {
            var html = '';
            bolCustomers.forEach(function (c) {
                html += '<tr>'
                      + '<td><span class="badge bg-light text-dark border" style="font-size:0.72rem;">' + escHtml(c.OrderRef) + '</span></td>'
                      + '<td><strong>' + escHtml(c.Name) + '</strong></td>'
                      + '<td><i class="fas fa-phone me-1 text-success" style="font-size:0.75rem;"></i><code style="font-size:0.78rem;">' + escHtml(c.Phone) + '</code></td>'
                      + '<td>' + (c.Destination ? '<span class="badge bg-info text-dark">' + escHtml(c.Destination) + '</span>' : '—') + '</td>'
                      + '<td class="text-muted small">' + escHtml(c.Address) + '</td>'
                      + '</tr>';
            });
            $('#bolCustomersBody').html(html || '<tr><td colspan="4" class="text-muted text-center py-3">No customers extracted.</td></tr>');
            new bootstrap.Modal(document.getElementById('bolCustomersModal')).show();
        }

        /* ============================================================ CUSTOMER */
        var custLookupTimer = null;

        function lookupCustomerByPhone() {
            clearTimeout(custLookupTimer);
            var raw = $.trim($('#txtCustPhone').val());
            if (raw.length < 7) { $('#custLookupStatus').html(''); return; }

            custLookupTimer = setTimeout(function () {
                $.ajax({
                    type: 'POST', url: 'Sales.aspx/GetCustomerByPhone',
                    contentType: 'application/json; charset=utf-8', dataType: 'json',
                    data: JSON.stringify({ phone: raw }),
                    success: function (res) {
                        var c = JSON.parse(res.d);
                        if (c) {
                            $('#txtCustName').val(c.Name);
                            $('#txtCustDesignation').val(c.Designation);
                            $('#txtCustAddress').val(c.Address);
                            $('#custLookupStatus').html('<span class="text-success"><i class="fas fa-check-circle me-1"></i>Returning customer found</span>');
                        } else {
                            $('#custLookupStatus').html('<span class="text-muted"><i class="fas fa-user-plus me-1"></i>New customer</span>');
                        }
                    }
                });
            }, 600);
        }

        function viewCustomer(saleId) {
            $('#customerModalBody').html('<div class="text-center py-3"><i class="fas fa-spinner fa-spin fa-2x text-primary"></i></div>');
            new bootstrap.Modal(document.getElementById('customerModal')).show();

            $.ajax({
                type: 'POST', url: 'Sales.aspx/GetCustomerBySaleId',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ saleId: saleId }),
                success: function (res) {
                    var c = JSON.parse(res.d);
                    if (!c) { $('#customerModalBody').html('<p class="text-muted text-center">No customer data.</p>'); return; }
                    var html = '<div class="list-group list-group-flush">'
                             + '<div class="list-group-item px-0"><small class="text-muted d-block">Phone</small>'
                             +     '<strong><i class="fas fa-phone me-1 text-success"></i>' + escHtml(c.Phone) + '</strong></div>'
                             + '<div class="list-group-item px-0"><small class="text-muted d-block">Name</small>'
                             +     '<strong>' + escHtml(c.Name) + '</strong></div>';
                    if (c.Designation)
                        html += '<div class="list-group-item px-0"><small class="text-muted d-block">Designation</small>'
                             +     escHtml(c.Designation) + '</div>';
                    if (c.Address)
                        html += '<div class="list-group-item px-0"><small class="text-muted d-block">Address</small>'
                             +     escHtml(c.Address) + '</div>';
                    html += '<div class="list-group-item px-0"><small class="text-muted d-block">Customer Since</small>'
                         +     escHtml(c.Since) + '</div></div>';
                    $('#customerModalBody').html(html);
                },
                error: function () { $('#customerModalBody').html('<p class="text-danger text-center">Failed to load.</p>'); }
            });
        }

        /* ============================================================ MANUAL SALE */
        var manualSaleItems = [];

        function loadManualMarketplaces(callback) {
            $.ajax({
                type: 'POST', url: 'Sales.aspx/GetMarketplaces',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (res) {
                    var markets = JSON.parse(res.d);
                    var $sel = $('#ddlManualMarketplace').empty();
                    if (!markets || markets.length === 0) {
                        $sel.append('<option value="">No marketplaces found</option>');
                    } else {
                        $.each(markets, function (i, m) {
                            $sel.append('<option value="' + escHtml(m.MarketplaceName) + '">' + escHtml(m.MarketplaceName) + '</option>');
                        });
                    }
                    if (callback) callback();
                },
                error: function () {
                    $('#ddlManualMarketplace').html('<option value="">Failed to load</option>');
                }
            });
        }

        function openManualSaleModal() {
            manualSaleItems = [];
            renderManualItems();
            $('#txtManualBillNo, #txtManualNotes').val('');
            var today = new Date().toISOString().split('T')[0];
            $('#txtManualSaleDate').val(today);
            selectedVariantIds = {};
            updateVariantDropdownLabel();
            $('#variantStockError').hide().html('');
            loadManualMarketplaces(function () { loadVariants(); });
            $('#variantDropdownPanel').addClass('d-none');
            $('#txtVariantFilter').val('');
            new bootstrap.Modal(document.getElementById('manualSaleModal')).show();
            // Auto-fill bill number
            $.ajax({
                type: 'POST', url: 'Sales.aspx/GetNextBillNumber',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ saleDate: today }),
                success: function (r) { $('#txtManualBillNo').val(JSON.parse(r.d)); }
            });
        }

        function autoFillManualBillNo() {
            var d = $('#txtManualSaleDate').val();
            if (!d || $.trim($('#txtManualBillNo').val())) return;
            $.ajax({
                type: 'POST', url: 'Sales.aspx/GetNextBillNumber',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ saleDate: d }),
                success: function (r) { $('#txtManualBillNo').val(JSON.parse(r.d)); }
            });
        }

        /* ---- Variant checkbox dropdown ---- */
        var allVariants      = [];
        var selectedVariantIds = {};   // { variantId: variantObj }

        function loadVariants() {
            var marketplace = $('#ddlManualMarketplace').val() || '';
            $('#variantCheckboxList').html('<div class="text-center text-muted py-3 small"><i class="fas fa-spinner fa-spin me-1"></i> Loading products...</div>');
            selectedVariantIds = {};
            updateVariantDropdownLabel();
            $.ajax({
                type: 'POST', url: 'Sales.aspx/GetAllVariants',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ marketplaceName: marketplace }),
                success: function (res) {
                    allVariants = JSON.parse(res.d);
                    renderVariantCheckboxes(allVariants);
                },
                error: function () {
                    $('#variantCheckboxList').html('<div class="text-center text-danger py-2 small"><i class="fas fa-times-circle me-1"></i>Failed to load products.</div>');
                }
            });
        }

        function renderVariantCheckboxes(variants) {
            if (!variants || variants.length === 0) {
                $('#variantCheckboxList').html('<div class="text-center text-muted py-3 small">No products found.</div>');
                return;
            }
            var html = '';
            variants.forEach(function (v) {
                var checked    = selectedVariantIds[v.VariantId] ? 'checked' : '';
                var rowBg      = selectedVariantIds[v.VariantId] ? 'background:#f0fdf4;' : '';
                var stockClass = v.StockQty <= 0 ? 'text-danger' : v.StockQty < 5 ? 'text-warning' : 'text-muted';
                html += '<div class="variant-check-item d-flex align-items-center gap-2 px-3 py-2 border-bottom" '
                      +     'style="cursor:pointer;' + rowBg + '" '
                      +     'data-vid="' + v.VariantId + '" '
                      +     'onclick="toggleVariantCheck(' + v.VariantId + ',this)">'
                      + '<input type="checkbox" class="form-check-input mt-0 flex-shrink-0" style="width:1.1rem;height:1.1rem;" ' + checked
                      +        ' onclick="event.stopPropagation();toggleVariantCheck(' + v.VariantId + ',this.closest(\'.variant-check-item\'))" />'
                      + '<div class="flex-grow-1" style="min-width:0;">'
                      +     '<span class="fw-semibold d-block text-truncate" style="font-size:0.92rem;" title="' + escHtml(v.ProductName) + '">'
                      +         escHtml(v.ProductName)
                      +         (v.ProductCode ? ' <span class="text-muted fw-normal" style="font-size:0.85rem;">(' + escHtml(v.ProductCode) + ')</span>' : '')
                      +     '</span>'
                      +     '<span class="badge bg-secondary me-1" style="font-size:0.75rem;">' + escHtml(v.Color) + '</span>'
                      +     '<span class="badge bg-light text-dark border me-1" style="font-size:0.75rem;">Sz&nbsp;' + escHtml(v.Size) + '</span>'
                      +     '<code style="font-size:0.78rem;">' + escHtml(v.SKUNumber) + '</code>'
                      + '</div>'
                      + '<span class="' + stockClass + ' flex-shrink-0" style="font-size:0.85rem;font-weight:600;">Stk:&nbsp;' + v.StockQty + '</span>'
                      + '</div>';
            });
            $('#variantCheckboxList').html(html);
        }

        function toggleVariantDropdown(e) {
            if (e) e.stopPropagation();
            var $p = $('#variantDropdownPanel');
            if ($p.hasClass('d-none')) {
                $p.removeClass('d-none').css('display', 'flex');
                $('#txtVariantFilter').focus();
            } else {
                $p.addClass('d-none');
            }
        }

        // Close when clicking outside
        $(document).on('click.variantDropdown', function (e) {
            if (!$(e.target).closest('#variantDropdownWrapper').length) {
                $('#variantDropdownPanel').addClass('d-none');
            }
        });

        function filterVariantList() {
            var q = $.trim($('#txtVariantFilter').val()).toLowerCase();
            if (!q) { renderVariantCheckboxes(allVariants); return; }
            var filtered = allVariants.filter(function (v) {
                return (v.ProductName || '').toLowerCase().indexOf(q) >= 0
                    || (v.SKUNumber   || '').toLowerCase().indexOf(q) >= 0
                    || (v.Color       || '').toLowerCase().indexOf(q) >= 0
                    || (v.Size        || '').toLowerCase().indexOf(q) >= 0
                    || (v.ProductCode || '').toLowerCase().indexOf(q) >= 0;
            });
            renderVariantCheckboxes(filtered);
        }

        function toggleVariantCheck(variantId, rowEl) {
            var v = allVariants.find(function (x) { return x.VariantId === variantId; });
            if (!v) return;
            var $row = $(rowEl);
            var $chk = $row.find('input[type="checkbox"]');
            if (selectedVariantIds[variantId]) {
                delete selectedVariantIds[variantId];
                $chk.prop('checked', false);
                $row.css('background', '');
            } else {
                selectedVariantIds[variantId] = v;
                $chk.prop('checked', true);
                $row.css('background', '#f0fdf4');
            }
            updateVariantDropdownLabel();
        }

        function updateVariantDropdownLabel() {
            var vals  = Object.values(selectedVariantIds);
            var count = vals.length;
            $('#variantSelectCount').text(count + ' selected');
            if (count === 0) {
                $('#variantDropdownLabel').addClass('text-muted').text('Click to select products...');
            } else {
                var preview = vals.slice(0, 2).map(function (v) {
                    return v.ProductName + ' (' + v.Color + ' Sz' + v.Size + ')';
                }).join(', ');
                if (vals.length > 2) preview += ' +' + (vals.length - 2) + ' more';
                $('#variantDropdownLabel').removeClass('text-muted').text(count + ' selected: ' + preview);
            }
        }

        function clearVariantSelection() {
            selectedVariantIds = {};
            updateVariantDropdownLabel();
            filterVariantList();
        }

        function addSelectedVariants() {
            var selected = Object.values(selectedVariantIds);
            if (selected.length === 0) { showToast('Select at least one product.', 'warning'); return; }

            $('#variantStockError').hide().html('');

            var added = 0, skipped = 0, noStock = [];

            selected.forEach(function (v) {
                if (v.StockQty <= 0) {
                    noStock.push({ name: v.ProductName, color: v.Color, size: v.Size, sku: v.SKUNumber });
                    return;
                }
                if (manualSaleItems.some(function (x) { return x.variantId === v.VariantId; })) {
                    skipped++; return;
                }
                manualSaleItems.push({
                    variantId:   v.VariantId,
                    sku:         v.SKUNumber,
                    productName: v.ProductName,
                    color:       v.Color,
                    size:        v.Size,
                    qty:         1,
                    salePrice:   v.SalePrice,
                    orderRef:    ''
                });
                added++;
            });

            if (noStock.length > 0) {
                var errorHtml = '<div class="alert alert-danger py-2 px-3 mb-0" style="font-size:0.85rem;">'
                              + '<i class="fas fa-times-circle me-1"></i>'
                              + '<strong>' + noStock.length + ' product(s) not added &mdash; stock is 0:</strong>'
                              + '<ul class="mb-0 mt-1 ps-3">';
                noStock.forEach(function (item) {
                    errorHtml += '<li>' + escHtml(item.name) + ' (' + escHtml(item.color) + ' Sz' + escHtml(item.size) + ')'
                               + ' &mdash; <code>' + escHtml(item.sku) + '</code></li>';
                });
                errorHtml += '</ul></div>';
                $('#variantStockError').html(errorHtml).show();
            }

            if (added > 0) {
                renderManualItems();
                selectedVariantIds = {};
                updateVariantDropdownLabel();
                filterVariantList();
                $('#variantDropdownPanel').addClass('d-none');
            }

            if (added > 0 && skipped > 0)
                showToast(added + ' added, ' + skipped + ' already in list.', 'info');
            else if (added > 0 && noStock.length === 0)
                showToast(added + ' product(s) added to sale.', 'success');
            else if (added === 0 && noStock.length === 0)
                showToast('All selected products are already in the list.', 'warning');
        }

        function removeManualItem(idx) { manualSaleItems.splice(idx, 1); renderManualItems(); }

        function updateManualItemOrderRef(idx, val) { manualSaleItems[idx].orderRef = val; }

        function updateManualItemQty(idx, val) {
            manualSaleItems[idx].qty = parseInt(val) || 1;
            refreshRowTotal(idx);
            recalcManualTotals();
        }

        function updateManualItemPrice(idx, val) {
            manualSaleItems[idx].salePrice = parseFloat(val) || 0;
            refreshRowTotal(idx);
            recalcManualTotals();
        }

        function refreshRowTotal(idx) {
            var it = manualSaleItems[idx];
            var lineTotal = (it.qty * it.salePrice);
            $('#rowTotal_' + idx).text('Rs. ' + lineTotal.toLocaleString('en-PK', pkFmt));
        }

        function renderManualItems() {
            var $body = $('#manualSaleItemsBody');
            if (manualSaleItems.length === 0) {
                $body.html('<tr><td colspan="9" class="text-center text-muted py-3"><i class="fas fa-inbox me-1"></i> No items added. Search and add SKU above.</td></tr>');
                $('#lblManualTotalQty').text('0');
                $('#lblManualGrandTotal').text('Rs. 0.00');
                return;
            }
            var html = '';
            manualSaleItems.forEach(function (it, idx) {
                var lineTotal = (it.qty * it.salePrice).toFixed(2);
                html += '<tr style="font-size:0.93rem;">'
                      + '<td class="text-center text-muted">' + (idx + 1) + '</td>'
                      + '<td><input type="text" class="form-control" style="font-size:0.9rem;" placeholder="Order ID" value="' + escHtml(it.orderRef || '') + '" oninput="updateManualItemOrderRef(' + idx + ',this.value)" /></td>'
                      + '<td><code style="font-size:0.88rem;">' + escHtml(it.sku) + '</code></td>'
                      + '<td>' + (it.color ? '<span class="badge bg-secondary" style="font-size:0.8rem;">' + escHtml(it.color) + '</span>' : '—') + '</td>'
                      + '<td class="text-center">' + escHtml(it.size) + '</td>'
                      + '<td><input type="number" class="form-control text-center" style="font-size:0.9rem;" min="1" value="' + it.qty + '" onchange="updateManualItemQty(' + idx + ',this.value)" /></td>'
                      + '<td><div class="input-group"><span class="input-group-text" style="font-size:0.88rem;">Rs.</span><input type="number" class="form-control" style="font-size:0.9rem;" min="0" step="0.01" value="' + (it.salePrice || '') + '" placeholder="0" onchange="updateManualItemPrice(' + idx + ',this.value)" /></div></td>'
                      + '<td class="fw-semibold" id="rowTotal_' + idx + '" style="font-size:0.93rem;">Rs. ' + parseFloat(lineTotal).toLocaleString('en-PK', pkFmt) + '</td>'
                      + '<td class="text-center"><button type="button" class="btn btn-sm btn-outline-danger" onclick="removeManualItem(' + idx + ')"><i class="fas fa-times"></i></button></td>'
                      + '</tr>';
            });
            $body.html(html);
            recalcManualTotals();
        }

        function recalcManualTotals() {
            var totalQty = 0, grandTotal = 0;
            manualSaleItems.forEach(function (it) { totalQty += it.qty; grandTotal += it.qty * it.salePrice; });
            $('#lblManualTotalQty').text(totalQty);
            $('#lblManualGrandTotal').text('Rs. ' + grandTotal.toLocaleString('en-PK', pkFmt));
            $('#manualItemCount').text(manualSaleItems.length);
        }

        function saveManualSale() {
            var billNo   = $.trim($('#txtManualBillNo').val());
            var platform = $('#ddlManualMarketplace').val();
            var saleDate = $('#txtManualSaleDate').val();

            if (!platform) { shakeField('#ddlManualMarketplace'); showToast('Select a marketplace.', 'warning');  return; }
            if (!billNo)   { shakeField('#txtManualBillNo');       showToast('Bill Number is required.', 'warning'); return; }
            if (!saleDate) { shakeField('#txtManualSaleDate');     showToast('Sale Date is required.', 'warning');   return; }
            if (manualSaleItems.length === 0) { showToast('Add at least one item.', 'warning'); return; }

            var sale = {
                SaleId:     0,
                BillNumber: billNo,
                Platform:   platform,
                SaleDate:   saleDate,
                Status:     'Completed',
                Notes:      $.trim($('#txtManualNotes').val())
            };

            var itemsPayload = manualSaleItems.map(function (it) {
                return {
                    VariantId:   it.variantId,
                    SKUNumber:   it.sku,
                    ProductName: it.productName,
                    Color:       it.color,
                    Size:        it.size,
                    Quantity:    it.qty,
                    SalePrice:   it.salePrice,
                    OrderRef:    it.orderRef || ''
                };
            });

            var $btn = $('#btnSaveManualSale');
            $btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i> Saving...');

            $.ajax({
                type: 'POST', url: 'Sales.aspx/SaveSale',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ sale: sale, itemsJson: JSON.stringify(itemsPayload), customersJson: '[]' }),
                success: function (res) {
                    var r = JSON.parse(res.d);
                    if (r.success) {
                        bootstrap.Modal.getInstance(document.getElementById('manualSaleModal')).hide();
                        showToast(r.message, 'success');
                        loadSales(); loadStats();
                    } else {
                        showToast(r.message, 'danger');
                    }
                },
                error: function () { showToast('An error occurred.', 'danger'); },
                complete: function () { $btn.prop('disabled', false).html('<i class="fas fa-save me-1"></i> Save Sale'); }
            });
        }

        /* ============================================================ HELPERS */
        function shakeField(sel) {
            var $el = $(sel); $el.addClass('border-danger');
            setTimeout(function(){ $el.removeClass('border-danger'); }, 2500);
        }
        function escHtml(s) { if (!s) return ''; return $('<div>').text(s).html(); }
        function escJs(s)   { if (!s) return ''; return s.replace(/'/g,"\\'").replace(/"/g,'\\"'); }
        function showToast(message, type) {
            var icons  = {success:'fa-check-circle',danger:'fa-times-circle',warning:'fa-exclamation-triangle',info:'fa-info-circle'};
            var colors = {success:'#16a34a',danger:'#dc2626',warning:'#d97706',info:'#2563eb'};
            var icon = icons[type]||icons.info, color = colors[type]||colors.info;
            var html = '<div class="app-toast toast show mb-2" style="background:#fff;border-left:4px solid '+color+';min-width:280px;">'
                     + '<div class="d-flex align-items-center toast-body gap-3">'
                     + '<i class="fas '+icon+'" style="color:'+color+';font-size:1.1rem;"></i>'
                     + '<span style="flex:1;font-size:0.875rem;">'+message+'</span>'
                     + '<button type="button" class="btn-close btn-close-sm ms-auto" data-bs-dismiss="toast"></button>'
                     + '</div></div>';
            var $t = $(html);
            $('#toastContainer').append($t);
            $t.find('.btn-close').on('click', function(){ $t.remove(); });
            setTimeout(function(){ $t.fadeOut(400, function(){ $t.remove(); }); }, 4000);
        }
    </script>

</asp:Content>
