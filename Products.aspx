<%@ Page Title="Products" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Products.aspx.cs" Inherits="Onfoot_Inventory.Products" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css" rel="stylesheet" />
    <link href="https://cdn.datatables.net/responsive/2.5.0/css/responsive.bootstrap5.min.css" rel="stylesheet" />
    <style>
        .variant-table th, .variant-table td { padding: 5px 6px; vertical-align: middle; }
        .variant-table input[type=number] { width: 62px; text-align: center; padding: 3px 4px; }
        #tblProducts tbody tr { cursor: pointer; }
        #tblProducts tbody tr:hover td { background-color: #f0f4ff !important; }
    </style>
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-left">
            <h4><i class="fas fa-box-open me-2 text-primary"></i>Products</h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="<%: ResolveUrl("~/") %>">Dashboard</a></li>
                    <li class="breadcrumb-item active">Products</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex gap-2">
            <button class="btn btn-outline-secondary btn-sm" onclick="loadProducts()" title="Refresh">
                <i class="fas fa-sync-alt me-1"></i> Refresh
            </button>
            <button class="btn btn-primary" onclick="openAddModal()">
                <i class="fas fa-plus me-1"></i> Add Product
            </button>
        </div>
    </div>

    <!-- Stats -->
    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon blue"><i class="fas fa-boxes"></i></div>
                <div>
                    <div class="stat-label">Total Products</div>
                    <div class="stat-value" id="statTotal">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon green"><i class="fas fa-check-circle"></i></div>
                <div>
                    <div class="stat-label">Active Products</div>
                    <div class="stat-value" id="statActive">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon yellow"><i class="fas fa-exclamation-triangle"></i></div>
                <div>
                    <div class="stat-label">Low Stock Items</div>
                    <div class="stat-value" id="statLowStock">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-3 col-sm-6">
            <div class="stat-card">
                <div class="stat-icon purple"><i class="fas fa-tags"></i></div>
                <div>
                    <div class="stat-label">Categories</div>
                    <div class="stat-value" id="statCategories">—</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Products Table -->
    <div class="table-card">
        <div class="table-card-header">
            <h6><i class="fas fa-list me-2 text-primary"></i>Product List</h6>
            <div class="d-flex align-items-center gap-2">
                <label class="form-check form-switch mb-0 me-2">
                    <input class="form-check-input" type="checkbox" id="chkShowInactive" onchange="loadProducts()">
                    <span class="form-check-label text-muted" style="font-size:0.8rem;">Show Inactive</span>
                </label>
            </div>
        </div>
        <div class="table-card-body">
            <div class="table-responsive">
                <table id="tblProducts" class="table table-hover w-100">
                    <thead>
                        <tr>
                            <th style="width:40px">#</th>
                            <th>Code</th>
                            <th>Product Name</th>
                            <th>Category</th>
                            <th>SKU(s)</th>
                            <th style="width:90px">Colors</th>
                            <th style="width:90px">Stock</th>
                            <th style="width:110px">Sale Price</th>
                            <th style="width:75px">Status</th>
                            <th style="width:85px">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="tblProductsBody"></tbody>
                </table>
            </div>
        </div>
    </div>

</asp:Content>

<%-- ============================================================
     MODAL + SCRIPTS
     ============================================================ --%>
<asp:Content ID="ModalsContent" ContentPlaceHolderID="ScriptsContent" runat="server">

    <!-- Add / Edit Product Modal -->
    <div class="modal fade" id="productModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <i class="fas fa-box me-2"></i>
                        <span id="modalTitle">Add New Product</span>
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" id="hdnProductId" value="0" />

                    <div class="row g-3">

                        <!-- Row 1: Code / Name / Category -->
                        <div class="col-md-4">
                            <label class="form-label">Product Code <span class="text-danger">*</span></label>
                            <input type="text" id="txtProductCode" class="form-control" placeholder="e.g. 001" maxlength="50" oninput="onProductNameChange()" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Product Name <span class="text-danger">*</span></label>
                            <input type="text" id="txtProductName" class="form-control" placeholder="Enter product name" maxlength="200" oninput="onProductNameChange()" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Category <span class="text-danger">*</span></label>
                            <select id="ddlCategory" class="form-select">
                                <option value="">-- Select Category --</option>
                            </select>
                        </div>

                        <!-- Row 2: Single SKU -->
                        <div class="col-12">
                            <label class="form-label">SKU Number</label>
                            <input type="text" id="txtSKUNumber" class="form-control" placeholder="e.g. SKU-001" maxlength="100" />
                        </div>

                        <!-- Pricing divider -->
                        <div class="col-12">
                            <hr class="my-1" />
                            <small class="text-muted fw-semibold text-uppercase" style="font-size:0.72rem;letter-spacing:0.8px;">
                                <i class="fas fa-tags me-1"></i> Pricing
                            </small>
                        </div>

                        <!-- Row 3: 3 prices + unit -->
                        <div class="col-md-3">
                            <label class="form-label">Manufacturing Price</label>
                            <div class="input-group">
                                <span class="input-group-text">Rs.</span>
                                <input type="number" id="txtMfgPrice" class="form-control" value="0" min="0" step="0.01" />
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Cost Price</label>
                            <div class="input-group">
                                <span class="input-group-text">Rs.</span>
                                <input type="number" id="txtCostPrice" class="form-control" value="0" min="0" step="0.01" />
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Sale Price</label>
                            <div class="input-group">
                                <span class="input-group-text">Rs.</span>
                                <input type="number" id="txtSalePrice" class="form-control" value="0" min="0" step="0.01" />
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Unit</label>
                            <select id="ddlUnit" class="form-select">
                                <option value="Pair">Pair</option>
                                <option value="Dozen">Dozen</option>
                                <option value="Box">Box</option>
                                <option value="Piece">Piece</option>
                                <option value="Carton">Carton</option>
                            </select>
                        </div>

                        <!-- Row 4: Material / Min Stock / Status -->
                        <div class="col-md-4">
                            <label class="form-label">Material</label>
                            <input type="text" id="txtMaterial" class="form-control" placeholder="e.g. Leather, Synthetic" maxlength="100" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Min Stock Level</label>
                            <input type="number" id="txtMinStock" class="form-control" value="5" min="0" />
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Status</label>
                            <div class="form-check form-switch mt-2">
                                <input class="form-check-input" type="checkbox" id="chkIsActive" checked />
                                <label class="form-check-label" for="chkIsActive">Active</label>
                            </div>
                        </div>

                        <!-- Description -->
                        <div class="col-12">
                            <label class="form-label">Description</label>
                            <textarea id="txtDescription" class="form-control" rows="2" placeholder="Optional product description..." maxlength="500"></textarea>
                        </div>

                        <!-- Colors & Sizes divider -->
                        <div class="col-12">
                            <hr class="my-1" />
                            <small class="text-muted fw-semibold text-uppercase" style="font-size:0.72rem;letter-spacing:0.8px;">
                                <i class="fas fa-palette me-1"></i> Colors &amp; Sizes — Stock per Size
                            </small>
                        </div>

                        <!-- Color input + grid -->
                        <div class="col-12">
                            <div class="d-flex gap-2 align-items-center mb-2 flex-wrap">
                                <input type="text" id="txtNewColor" class="form-control" style="max-width:180px"
                                       placeholder="e.g. Black" maxlength="50"
                                       onkeydown="if(event.key==='Enter'){addColor();return false;}" />
                                <button type="button" class="btn btn-outline-primary btn-sm" onclick="addColor()">
                                    <i class="fas fa-plus me-1"></i> Add Color
                                </button>
                                <small class="text-muted">Type a color name and click Add, then enter qty per size</small>
                            </div>
                            <div id="variantsTableContainer">
                                <p class="text-muted small text-center py-2 mb-0">No colors added yet.</p>
                            </div>
                        </div>

                    </div><!-- /row -->
                </div><!-- /modal-body -->
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i> Cancel
                    </button>
                    <button type="button" id="btnSaveProduct" class="btn btn-primary" onclick="saveProduct()">
                        <i class="fas fa-save me-1"></i> Save Product
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Variant View / Edit Modal -->
    <div class="modal fade" id="variantModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header bg-primary text-white">
                    <h5 class="modal-title">
                        <i class="fas fa-layer-group me-2"></i>
                        <span id="variantModalTitle">Variants</span>
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="d-flex align-items-center gap-3 mb-3 pb-2 border-bottom">
                        <small class="text-muted" id="variantModalSubtitle"></small>
                        <div class="ms-auto d-flex align-items-center gap-2">
                            <label class="form-label mb-0 text-nowrap">Min Stock Level:</label>
                            <input type="number" id="txtVariantMinStock" class="form-control form-control-sm" style="width:80px" min="0" value="5" />
                        </div>
                    </div>
                    <div id="variantModalBody">
                        <div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x text-primary"></i></div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i> Close
                    </button>
                    <button type="button" id="btnSaveVariants" class="btn btn-primary" onclick="saveVariants()">
                        <i class="fas fa-save me-1"></i> Save Variants
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Delete Confirm Modal -->
    <div class="modal fade" id="deleteModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered" style="max-width:420px">
            <div class="modal-content">
                <div class="modal-header" style="background:#b91c1c;">
                    <h5 class="modal-title text-white"><i class="fas fa-trash me-2"></i>Confirm Delete</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center py-4">
                    <div class="mb-3" style="font-size:2.5rem;color:#fca5a5;">
                        <i class="fas fa-exclamation-circle"></i>
                    </div>
                    <p class="mb-1">Are you sure you want to deactivate:</p>
                    <p class="fw-bold fs-6" id="deleteProductName"></p>
                    <p class="text-muted small">The product will be marked as inactive and removed from active listings.</p>
                </div>
                <div class="modal-footer justify-content-center gap-3">
                    <button type="button" class="btn btn-secondary px-4" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-danger px-4" id="btnConfirmDelete" onclick="executeDelete()">
                        <i class="fas fa-trash me-1"></i> Yes, Delete
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Toast Container -->
    <div class="toast-container-fixed" id="toastContainer"></div>

    <!-- DataTables JS -->
    <script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.7/js/dataTables.bootstrap5.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.5.0/js/dataTables.responsive.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.5.0/js/responsive.bootstrap5.min.js"></script>

    <script>
        var productsTable;
        var deleteProductId = 0;
        var colorVariants   = [];
        var DEFAULT_SIZES   = ['36', '37', '38', '39', '40', '41', '42'];
        var activeSizes     = DEFAULT_SIZES.slice(); // current active sizes (can be trimmed per product)

        /* ============================================================
           INIT
        ============================================================ */
        $(document).ready(function () {
            initDataTable();
            loadCategories();
            loadStats();
            loadProducts();

            // Click any row → open variant view modal
            $('#tblProducts tbody').on('click', 'tr', function (e) {
                if ($(e.target).closest('.btn-action-edit, .btn-action-delete').length) return;
                var $editBtn = $(this).find('.btn-action-edit');
                if (!$editBtn.length) return;
                var match = $editBtn.attr('onclick').match(/editProduct\((\d+)\)/);
                if (match) openVariantModal(parseInt(match[1]));
            });
        });

        function initDataTable() {
            productsTable = $('#tblProducts').DataTable({
                responsive:  true,
                pageLength:  15,
                lengthMenu:  [[10, 15, 25, 50, 100], [10, 15, 25, 50, 100]],
                columnDefs:  [{ orderable: false, targets: [9] }],
                language: {
                    search:            '',
                    searchPlaceholder: 'Search products...',
                    lengthMenu:        'Show _MENU_ entries',
                    info:              'Showing _START_ to _END_ of _TOTAL_ products',
                    emptyTable:        "<div class='text-center py-4 text-muted'><i class='fas fa-inbox fa-2x mb-2 d-block'></i>No products found</div>"
                },
                dom: "<'row mb-2'<'col-sm-6'l><'col-sm-6'f>>" +
                     "<'row'<'col-sm-12'tr>>" +
                     "<'row mt-2'<'col-sm-5'i><'col-sm-7'p>>"
            });
        }

        /* ============================================================
           LOAD DATA
        ============================================================ */
        function loadCategories() {
            $.ajax({
                type: 'POST', url: 'Products.aspx/GetCategories',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (res) {
                    var cats = JSON.parse(res.d);
                    var html = '<option value="">-- Select Category --</option>';
                    $.each(cats, function (i, c) {
                        html += '<option value="' + c.CategoryId + '">' + c.CategoryName + '</option>';
                    });
                    $('#ddlCategory').html(html);
                }
            });
        }

        function loadStats() {
            $.ajax({
                type: 'POST', url: 'Products.aspx/GetProductStats',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (res) {
                    var s = JSON.parse(res.d);
                    $('#statTotal').text(s.TotalProducts);
                    $('#statActive').text(s.ActiveProducts);
                    $('#statLowStock').text(s.LowStock);
                    $('#statCategories').text(s.TotalCategories);
                }
            });
        }

        function loadProducts() {
            var showInactive = $('#chkShowInactive').is(':checked');
            $.ajax({
                type: 'POST', url: 'Products.aspx/GetProducts',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ showInactive: showInactive }),
                success: function (res) {
                    var products = JSON.parse(res.d);
                    productsTable.clear();
                    $.each(products, function (i, p) {
                        var statusBadge = p.IsActive
                            ? '<span class="badge-active">Active</span>'
                            : '<span class="badge-inactive">Inactive</span>';

                        var stockCls  = (p.TotalStock <= p.MinStockLevel) ? 'badge-low-stock' : 'badge-normal-stock';
                        var stockHtml = '<span class="' + stockCls + '">' + p.TotalStock + ' ' + escHtml(p.Unit) + '</span>';

                        var catBadge  = '<span class="badge bg-light text-dark border" style="font-size:0.75rem;">' + escHtml(p.CategoryName) + '</span>';

                        var skuHtml = p.SKUNumber
                            ? '<code style="font-size:0.74rem">' + escHtml(p.SKUNumber) + '</code>'
                            : '<span class="text-muted">—</span>';

                        var colorHtml = p.TotalColors > 0
                            ? '<span class="badge bg-info text-dark">' + p.TotalColors + ' color' + (p.TotalColors !== 1 ? 's' : '') + '</span>'
                            : '<span class="text-muted">—</span>';

                        var actions = '<button class="btn-action-edit me-1" onclick="editProduct(' + p.ProductId + ')" title="Edit"><i class="fas fa-edit"></i></button>'
                                    + '<button class="btn-action-delete" onclick="confirmDelete(' + p.ProductId + ',\'' + escJs(p.ProductName) + '\')" title="Delete"><i class="fas fa-trash"></i></button>';

                        productsTable.row.add([
                            i + 1,
                            '<code>' + escHtml(p.ProductCode) + '</code>',
                            '<strong>' + escHtml(p.ProductName) + '</strong>',
                            catBadge,
                            skuHtml,
                            colorHtml,
                            stockHtml,
                            'Rs. ' + parseFloat(p.SalePrice).toLocaleString('en-PK', { minimumFractionDigits: 2 }),
                            statusBadge,
                            actions
                        ]);
                    });
                    productsTable.draw();
                },
                error: function () { showToast('Failed to load products. Check database connection.', 'danger'); }
            });
        }

        /* ============================================================
           ADD / EDIT
        ============================================================ */
        function openAddModal() {
            resetForm();
            $('#hdnProductId').val('0');
            $('#modalTitle').text('Add New Product');
            var modal = new bootstrap.Modal(document.getElementById('productModal'));
            modal.show();
            setTimeout(function () { $('#txtProductCode').focus(); }, 400);
        }

        function editProduct(productId) {
            $.ajax({
                type: 'POST', url: 'Products.aspx/GetProductById',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ productId: productId }),
                success: function (res) {
                    var data = JSON.parse(res.d);
                    if (!data) { showToast('Product not found.', 'warning'); return; }
                    var p        = data.Product;
                    var variants = data.Variants || [];

                    resetForm();
                    $('#hdnProductId').val(p.ProductId);
                    $('#txtProductCode').val(p.ProductCode);
                    $('#txtProductName').val(p.ProductName);
                    $('#ddlCategory').val(p.CategoryId);
                    $('#txtSKUNumber').val(p.SKUNumber);
                    $('#txtMfgPrice').val(p.ManufacturingPrice);
                    $('#txtCostPrice').val(p.CostPrice);
                    $('#txtSalePrice').val(p.SalePrice);
                    $('#txtMaterial').val(p.Material);
                    $('#txtMinStock').val(p.MinStockLevel);
                    $('#ddlUnit').val(p.Unit);
                    $('#txtDescription').val(p.Description);
                    $('#chkIsActive').prop('checked', p.IsActive);

                    // Rebuild color/size grid from saved variants
                    colorVariants = [];
                    activeSizes   = DEFAULT_SIZES.slice();
                    $.each(variants, function (i, v) {
                        var cv = null;
                        for (var j = 0; j < colorVariants.length; j++) {
                            if (colorVariants[j].color === v.Color) { cv = colorVariants[j]; break; }
                        }
                        if (!cv) {
                            var sizes = {};
                            activeSizes.forEach(function (s) { sizes[s] = 0; });
                            cv = { color: v.Color, skuNumbers: v.SKUNumbers || '', sizes: sizes };
                            colorVariants.push(cv);
                        }
                        if (activeSizes.indexOf(v.Size) >= 0) cv.sizes[v.Size] = v.StockQuantity;
                    });
                    renderVariantsTable();

                    $('#modalTitle').text('Edit Product');
                    var modal = new bootstrap.Modal(document.getElementById('productModal'));
                    modal.show();
                },
                error: function () { showToast('Failed to load product details.', 'danger'); }
            });
        }

        function saveProduct() {
            var code  = $.trim($('#txtProductCode').val());
            var name  = $.trim($('#txtProductName').val());
            var catId = $('#ddlCategory').val();

            if (!code)  { shakeField('#txtProductCode'); showToast('Product Code is required.', 'warning'); return; }
            if (!name)  { shakeField('#txtProductName'); showToast('Product Name is required.', 'warning'); return; }
            if (!catId) { shakeField('#ddlCategory');    showToast('Please select a Category.', 'warning'); return; }

            var product = {
                ProductId:          parseInt($('#hdnProductId').val()) || 0,
                ProductCode:        code,
                ProductName:        name,
                CategoryId:         parseInt(catId),
                SKUNumber:          $.trim($('#txtSKUNumber').val()),
                ManufacturingPrice: parseFloat($('#txtMfgPrice').val())  || 0,
                CostPrice:          parseFloat($('#txtCostPrice').val()) || 0,
                SalePrice:          parseFloat($('#txtSalePrice').val()) || 0,
                Material:           $.trim($('#txtMaterial').val()),
                Description:        $.trim($('#txtDescription').val()),
                MinStockLevel:      parseInt($('#txtMinStock').val())    || 5,
                Unit:               $('#ddlUnit').val(),
                IsActive:           $('#chkIsActive').is(':checked')
            };

            // Flatten colorVariants → [{Color, Size, StockQuantity}]
            var variantsList = [];
            colorVariants.forEach(function (cv) {
                // split comma-separated SKUs and assign one per size
                var skuParts = (cv.skuNumbers || '').split(',').map(function (s) { return s.trim(); });
                activeSizes.forEach(function (sz, szIdx) {
                    variantsList.push({
                        Color:         cv.color,
                        Size:          sz,
                        StockQuantity: cv.sizes[sz] || 0,
                        SKUNumbers:    skuParts[szIdx] || ''
                    });
                });
            });

            var $btn = $('#btnSaveProduct');
            $btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i> Saving...');

            $.ajax({
                type: 'POST', url: 'Products.aspx/SaveProduct',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ product: product, variantsJson: JSON.stringify(variantsList) }),
                success: function (res) {
                    var result = JSON.parse(res.d);
                    if (result.success) {
                        bootstrap.Modal.getInstance(document.getElementById('productModal')).hide();
                        showToast(result.message, 'success');
                        loadProducts();
                        loadStats();
                    } else {
                        showToast(result.message, 'danger');
                    }
                },
                error: function () { showToast('An error occurred. Please try again.', 'danger'); },
                complete: function () { $btn.prop('disabled', false).html('<i class="fas fa-save me-1"></i> Save Product'); }
            });
        }

        /* ============================================================
           COLOR / SIZE VARIANTS
        ============================================================ */
        function addColor() {
            var color = $.trim($('#txtNewColor').val());
            if (!color) { shakeField('#txtNewColor'); showToast('Enter a color name.', 'warning'); return; }

            for (var j = 0; j < colorVariants.length; j++) {
                if (colorVariants[j].color.toLowerCase() === color.toLowerCase()) {
                    showToast('Color "' + color + '" is already added.', 'warning'); return;
                }
            }

            var sizes = {};
            activeSizes.forEach(function (s) { sizes[s] = 0; });
            colorVariants.push({ color: color, skuNumbers: '', sizes: sizes });
            autoGenerateSKUs();
            renderVariantsTable();
            $('#txtNewColor').val('').focus();
        }

        function removeColor(idx) {
            colorVariants.splice(idx, 1);
            renderVariantsTable();
        }

        function updateQty(colorIdx, size, val) {
            colorVariants[colorIdx].sizes[size] = parseInt(val) || 0;
        }

        function updateSkuNumbers(colorIdx, val) {
            colorVariants[colorIdx].skuNumbers = val;
        }

        function removeSize(size) {
            activeSizes = activeSizes.filter(function (s) { return s !== size; });
            colorVariants.forEach(function (cv) { delete cv.sizes[size]; });
            autoGenerateSKUs();
            renderVariantsTable();
        }

        function autoGenerateSKUs() {
            var productCode = $.trim($('#txtProductCode').val());
            var productName = $.trim($('#txtProductName').val());
            var prefix = [productCode, productName].filter(Boolean).join('-');
            colorVariants.forEach(function (cv) {
                // one SKU per size: ProductCode-ProductName-Color-Size
                var parts = activeSizes.map(function (sz) {
                    return [prefix, cv.color, sz].filter(Boolean).join('-');
                });
                cv.skuNumbers = parts.join(', ');
            });
        }

        function onProductNameChange() {
            if (colorVariants.length > 0) {
                autoGenerateSKUs();
                renderVariantsTable();
            }
        }

        function renderVariantsTable() {
            if (colorVariants.length === 0) {
                $('#variantsTableContainer').html('<p class="text-muted small text-center py-2 mb-0">No colors added yet.</p>');
                return;
            }

            var html = '<div class="table-responsive"><table class="table table-sm table-bordered variant-table mb-0">';
            html += '<thead class="table-light"><tr>'
                  + '<th style="min-width:110px">Color</th>'
                  + '<th style="min-width:200px">SKU(s) <small class="text-muted fw-normal">(auto-generated)</small></th>';
            activeSizes.forEach(function (s) {
                html += '<th class="text-center" style="width:80px">'
                      + 'Size ' + s + '<br>'
                      + '<button type="button" class="btn btn-xs btn-outline-danger py-0 px-1 mt-1" style="font-size:0.65rem;line-height:1.2;" onclick="removeSize(\'' + s + '\')" title="Remove size ' + s + '">'
                      + '<i class="fas fa-times"></i> Remove</button></th>';
            });
            html += '<th style="width:44px"></th></tr></thead><tbody>';

            colorVariants.forEach(function (cv, idx) {
                html += '<tr>';
                html += '<td><span class="badge bg-secondary" style="font-size:0.82rem;font-weight:500;">' + escHtml(cv.color) + '</span></td>';
                html += '<td><input type="text" class="form-control form-control-sm" maxlength="500" value="'
                      + escHtml(cv.skuNumbers || '')
                      + '" oninput="updateSkuNumbers(' + idx + ',this.value)" /></td>';
                activeSizes.forEach(function (sz) {
                    html += '<td><input type="number" class="form-control form-control-sm text-center" min="0" value="'
                          + (cv.sizes[sz] || 0)
                          + '" onchange="updateQty(' + idx + ',\'' + sz + '\',this.value)" /></td>';
                });
                html += '<td class="text-center">'
                      + '<button type="button" class="btn btn-sm btn-outline-danger py-0 px-1" onclick="removeColor(' + idx + ')" title="Remove color">'
                      + '<i class="fas fa-times"></i></button></td>';
                html += '</tr>';
            });

            html += '</tbody></table></div>';
            $('#variantsTableContainer').html(html);
        }

        /* ============================================================
           VARIANT VIEW MODAL
        ============================================================ */
        var currentVariantProductId = 0;

        function openVariantModal(productId) {
            currentVariantProductId = productId;
            $('#variantModalTitle').text('Variants');
            $('#variantModalSubtitle').text('');
            $('#variantModalBody').html('<div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x text-primary"></i></div>');
            new bootstrap.Modal(document.getElementById('variantModal')).show();

            $.ajax({
                type: 'POST', url: 'Products.aspx/GetVariantsForView',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ productId: productId }),
                success: function (res) {
                    var data = JSON.parse(res.d);
                    if (!data) { showToast('Product not found.', 'warning'); return; }
                    $('#variantModalTitle').text('Variants — ' + data.ProductName);
                    $('#variantModalSubtitle').text('Code: ' + data.ProductCode);
                    $('#txtVariantMinStock').val(data.MinStockLevel);
                    renderVariantViewTable(data.Variants);
                },
                error: function () { showToast('Failed to load variants.', 'danger'); }
            });
        }

        function renderVariantViewTable(variants) {
            if (!variants || variants.length === 0) {
                $('#variantModalBody').html('<p class="text-muted text-center py-3">No variants found. Add colors in the product edit form.</p>');
                return;
            }

            var html = '<div class="table-responsive"><table class="table table-sm table-bordered align-middle mb-0">'
                     + '<thead class="table-primary"><tr>'
                     + '<th style="width:100px">Color</th>'
                     + '<th style="width:60px" class="text-center">Size</th>'
                     + '<th>SKU</th>'
                     + '<th style="width:100px" class="text-center">Stock Qty</th>'
                     + '</tr></thead><tbody>';

            var lastColor = '';
            variants.forEach(function (v) {
                var colorCell = '';
                if (v.Color !== lastColor) {
                    colorCell = '<span class="badge bg-secondary" style="font-size:0.82rem;">' + escHtml(v.Color) + '</span>';
                    lastColor = v.Color;
                }
                html += '<tr>'
                      + '<td>' + colorCell + '</td>'
                      + '<td class="text-center fw-semibold">' + escHtml(v.Size) + '</td>'
                      + '<td><input type="text" class="form-control form-control-sm" maxlength="200"'
                      +     ' data-variant-id="' + v.VariantId + '" data-field="sku"'
                      +     ' value="' + escHtml(v.SKUNumbers) + '" /></td>'
                      + '<td><input type="number" class="form-control form-control-sm text-center" min="0"'
                      +     ' data-variant-id="' + v.VariantId + '" data-field="qty"'
                      +     ' value="' + v.StockQuantity + '" /></td>'
                      + '</tr>';
            });

            html += '</tbody></table></div>';
            $('#variantModalBody').html(html);
        }

        function saveVariants() {
            var minStock = parseInt($('#txtVariantMinStock').val()) || 0;
            var variantsList = [];

            $('#variantModalBody tbody tr').each(function () {
                var $qty = $(this).find('input[data-field="qty"]');
                var $sku = $(this).find('input[data-field="sku"]');
                if (!$qty.length) return;
                variantsList.push({
                    VariantId:     parseInt($qty.data('variant-id')),
                    StockQuantity: parseInt($qty.val()) || 0,
                    SKUNumbers:    $.trim($sku.val())
                });
            });

            var $btn = $('#btnSaveVariants');
            $btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i> Saving...');

            $.ajax({
                type: 'POST', url: 'Products.aspx/SaveVariants',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({
                    productId:    currentVariantProductId,
                    minStockLevel: minStock,
                    variantsJson: JSON.stringify(variantsList)
                }),
                success: function (res) {
                    var result = JSON.parse(res.d);
                    if (result.success) {
                        bootstrap.Modal.getInstance(document.getElementById('variantModal')).hide();
                        showToast(result.message, 'success');
                        loadProducts();
                        loadStats();
                    } else {
                        showToast(result.message, 'danger');
                    }
                },
                error: function () { showToast('Save failed. Please try again.', 'danger'); },
                complete: function () { $btn.prop('disabled', false).html('<i class="fas fa-save me-1"></i> Save Variants'); }
            });
        }

        /* ============================================================
           DELETE
        ============================================================ */
        function confirmDelete(productId, productName) {
            deleteProductId = productId;
            $('#deleteProductName').text('"' + productName + '"');
            var modal = new bootstrap.Modal(document.getElementById('deleteModal'));
            modal.show();
        }

        function executeDelete() {
            var $btn = $('#btnConfirmDelete');
            $btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i> Deleting...');
            $.ajax({
                type: 'POST', url: 'Products.aspx/DeleteProduct',
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                data: JSON.stringify({ productId: deleteProductId }),
                success: function (res) {
                    var result = JSON.parse(res.d);
                    bootstrap.Modal.getInstance(document.getElementById('deleteModal')).hide();
                    if (result.success) {
                        showToast(result.message, 'success');
                        loadProducts(); loadStats();
                    } else {
                        showToast(result.message, 'danger');
                    }
                },
                error: function () { showToast('Delete failed. Please try again.', 'danger'); },
                complete: function () { $btn.prop('disabled', false).html('<i class="fas fa-trash me-1"></i> Yes, Delete'); }
            });
        }

        /* ============================================================
           HELPERS
        ============================================================ */
        function resetForm() {
            $('#txtProductCode, #txtProductName, #txtSKUNumber, #txtMaterial, #txtDescription').val('');
            $('#ddlCategory').val('');
            $('#ddlUnit').val('Pair');
            $('#txtMfgPrice, #txtCostPrice, #txtSalePrice').val('0');
            $('#txtMinStock').val('5');
            $('#chkIsActive').prop('checked', true);
            colorVariants = [];
            activeSizes   = DEFAULT_SIZES.slice();
            $('#variantsTableContainer').html('<p class="text-muted small text-center py-2 mb-0">No colors added yet.</p>');
            $('#txtNewColor').val('');
        }

        function shakeField(selector) {
            var $el = $(selector);
            $el.addClass('border-danger');
            setTimeout(function () { $el.removeClass('border-danger'); }, 2500);
        }

        function escHtml(str) {
            if (!str) return '';
            return $('<div>').text(str).html();
        }

        function escJs(str) {
            if (!str) return '';
            return str.replace(/'/g, "\\'").replace(/"/g, '\\"');
        }

        function showToast(message, type) {
            var icons  = { success: 'fa-check-circle', danger: 'fa-times-circle', warning: 'fa-exclamation-triangle', info: 'fa-info-circle' };
            var colors = { success: '#16a34a', danger: '#dc2626', warning: '#d97706', info: '#2563eb' };
            var icon   = icons[type]  || icons.info;
            var color  = colors[type] || colors.info;
            var html   = '<div class="app-toast toast show mb-2" style="background:#fff;border-left:4px solid ' + color + ';min-width:280px;">'
                       + '<div class="d-flex align-items-center toast-body gap-3">'
                       + '<i class="fas ' + icon + '" style="color:' + color + ';font-size:1.1rem;"></i>'
                       + '<span style="flex:1;font-size:0.875rem;">' + message + '</span>'
                       + '<button type="button" class="btn-close btn-close-sm ms-auto" data-bs-dismiss="toast"></button>'
                       + '</div></div>';
            var $toast = $(html);
            $('#toastContainer').append($toast);
            $toast.find('.btn-close').on('click', function () { $toast.remove(); });
            setTimeout(function () { $toast.fadeOut(400, function () { $toast.remove(); }); }, 4000);
        }
    </script>

</asp:Content>
