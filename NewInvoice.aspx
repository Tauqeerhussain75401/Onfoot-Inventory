    <%@ Page Title="New Invoice" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="NewInvoice.aspx.cs" Inherits="Onfoot_Inventory.NewInvoice" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* ── Page layout ── */
        .inv-section-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            margin-bottom: 20px;
            overflow: hidden;
        }
        .inv-section-header {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 14px 20px;
            border-bottom: 1px solid #e2e8f0;
            font-weight: 700;
            font-size: 0.88rem;
        }
        .inv-section-body { padding: 18px 20px; }

        /* ── Sticky summary ── */
        .summary-sticky {
            position: sticky;
            top: 20px;
        }
        .summary-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            overflow: hidden;
        }
        .summary-header {
            padding: 14px 20px 12px;
            background: linear-gradient(135deg, #1e40af, #2563eb);
            color: #fff;
        }
        .summary-body { padding: 16px 20px; }
        .summary-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 7px 0;
            font-size: 0.88rem;
            border-bottom: 1px solid #f1f5f9;
        }
        .summary-row:last-child { border-bottom: none; }
        .summary-label { color: #64748b; font-weight: 500; }
        .summary-value { font-weight: 600; color: #1e293b; }
        .grand-total-row {
            background: #f0fdf4;
            border-radius: 8px;
            padding: 12px 14px !important;
            margin-top: 6px;
            border: 1px solid #bbf7d0 !important;
        }
        .grand-total-label { font-weight: 700; font-size: 0.9rem; color: #15803d; }
        .grand-total-value { font-size: 1.3rem; font-weight: 800; color: #15803d; }

        /* ── Items grid ── */
        .items-grid { width: 100%; border-collapse: collapse; }
        .items-grid thead th {
            background: #f8fafc;
            font-size: 0.72rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .05em;
            color: #64748b;
            padding: 10px 12px;
            border-bottom: 2px solid #e2e8f0;
            white-space: nowrap;
        }
        .items-grid tbody td {
            padding: 9px 12px;
            vertical-align: middle;
            font-size: 0.875rem;
            border-bottom: 1px solid #f1f5f9;
        }
        .items-grid tbody tr:last-child td { border-bottom: none; }
        .items-grid tbody tr:hover td { background: #f8faff; }

        .size-pill {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 38px;
            height: 38px;
            border-radius: 8px;
            background: #eff6ff;
            color: #1d4ed8;
            font-weight: 800;
            font-size: 0.92rem;
            border: 1px solid #bfdbfe;
        }
        .row-num {
            color: #94a3b8;
            font-size: 0.78rem;
            font-weight: 600;
        }
        .sku-code {
            font-family: 'Courier New', monospace;
            font-size: 0.76rem;
            color: #475569;
            background: #f1f5f9;
            padding: 2px 6px;
            border-radius: 4px;
        }
        .total-cell {
            font-weight: 700;
            color: #15803d;
            font-size: 0.9rem;
        }

        /* ── Product selector ── */
        .product-selector {
            background: #fafbff;
            border: 2px dashed #c7d2fe;
            border-radius: 10px;
            padding: 16px 18px;
            transition: border-color .2s;
        }
        .product-selector:hover { border-color: #818cf8; }

        /* ── Empty state ── */
        .empty-items {
            text-align: center;
            padding: 48px 20px;
            color: #94a3b8;
        }
        .empty-items i { font-size: 2.5rem; margin-bottom: 12px; display: block; opacity: .4; }
        .empty-items p { font-size: 0.88rem; margin: 0; }

        /* ── Invoice number badge ── */
        .inv-num-badge {
            display: inline-block;
            background: rgba(255,255,255,.2);
            border: 1px solid rgba(255,255,255,.3);
            border-radius: 6px;
            padding: 3px 10px;
            font-size: 0.8rem;
            font-weight: 700;
            letter-spacing: .03em;
            margin-top: 4px;
        }

        /* ── Action bar ── */
        .action-bar {
            position: sticky;
            bottom: 0;
            background: #fff;
            border-top: 1px solid #e2e8f0;
            padding: 12px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            z-index: 100;
            border-radius: 0 0 12px 12px;
            box-shadow: 0 -4px 16px rgba(0,0,0,.06);
        }

        /* ── Collapse toggle ── */
        .collapse-toggle {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 22px;
            height: 22px;
            border-radius: 5px;
            border: none;
            background: rgba(99,102,241,0.15);
            color: #4338ca;
            cursor: pointer;
            flex-shrink: 0;
            transition: background .15s;
        }
        .collapse-toggle:hover { background: rgba(99,102,241,0.3); }
        .collapse-toggle i { transition: transform .2s ease; font-size: 0.65rem; }

        /* ── Discount input ── */
        .discount-wrap { position: relative; }
        .discount-wrap .form-control { padding-right: 48px; text-align: right; }
        .discount-wrap .cur-label {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 0.78rem;
            color: #94a3b8;
            font-weight: 600;
            pointer-events: none;
        }

        @media (max-width: 991px) {
            .summary-sticky { position: static; margin-top: 20px; }
        }
    </style>
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-left">
            <h4>
                <a href="<%: ResolveUrl("~/CustomerBilling.aspx") %>"
                   style="color:var(--text-muted);font-size:0.85rem;font-weight:500;text-decoration:none;margin-right:8px;">
                    <i class="fas fa-arrow-left me-1"></i>Customer Billing
                </a>
                <i class="fas fa-chevron-right me-2" style="font-size:0.7rem;color:#cbd5e1;"></i>
                <i class="fas fa-file-invoice-dollar me-2 text-primary"></i>New Invoice
            </h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="<%: ResolveUrl("~/") %>">Dashboard</a></li>
                    <li class="breadcrumb-item"><a href="<%: ResolveUrl("~/CustomerBilling.aspx") %>">Customer Billing</a></li>
                    <li class="breadcrumb-item active">New Invoice</li>
                </ol>
            </nav>
        </div>
    </div>

    <!-- Two-column layout -->
    <div class="row g-4 align-items-start">

        <!-- ── LEFT: Form ─────────────────────────────── -->
        <div class="col-lg-8">

            <!-- Card 1: Invoice Details -->
            <div class="inv-section-card">
                <div class="inv-section-header" style="background:linear-gradient(135deg,#eff6ff,#dbeafe);">
                    <div style="width:32px;height:32px;border-radius:8px;background:#dbeafe;
                                display:flex;align-items:center;justify-content:center;
                                font-size:0.9rem;color:#1d4ed8;">
                        <i class="fas fa-info-circle"></i>
                    </div>
                    <span style="color:#1e40af;">Invoice Details</span>
                </div>
                <div class="inv-section-body">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold" style="font-size:0.82rem;">
                                Customer <span class="text-danger">*</span>
                            </label>
                            <select id="ddlCustomer" class="form-select">
                                <option value="">Select Customer</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold" style="font-size:0.82rem;">
                                Invoice Date <span class="text-danger">*</span>
                            </label>
                            <input type="date" id="txtInvoiceDate" class="form-control" />
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold" style="font-size:0.82rem;">Notes</label>
                            <input type="text" id="txtNotes" class="form-control"
                                   placeholder="Optional note..." maxlength="500" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Card 2: Add Products -->
            <div class="inv-section-card">
                <div class="inv-section-header" style="background:linear-gradient(135deg,#ecfdf5,#d1fae5);">
                    <div style="width:32px;height:32px;border-radius:8px;background:#d1fae5;
                                display:flex;align-items:center;justify-content:center;
                                font-size:0.9rem;color:#065f46;">
                        <i class="fas fa-plus-circle"></i>
                    </div>
                    <span style="color:#065f46;">Add Products</span>
                    <span class="text-muted fw-normal" style="font-size:0.78rem;margin-left:4px;">
                        select product &amp; color then click Add
                    </span>
                </div>
                <div class="inv-section-body">
                    <div class="product-selector">
                        <div class="row g-3 align-items-end">
                            <div class="col-md-5">
                                <label class="form-label fw-semibold mb-1" style="font-size:0.8rem;">Product</label>
                                <select id="ddlProduct" class="form-select form-select-sm"
                                        onchange="onProductChange()">
                                    <option value="">Loading products...</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold mb-1" style="font-size:0.8rem;">Color</label>
                                <select id="ddlColor" class="form-select form-select-sm" disabled>
                                    <option value="">Select product first</option>
                                </select>
                            </div>
                            <div class="col-md-3">
                                <button type="button" class="btn btn-success btn-sm w-100"
                                        onclick="addVariants()">
                                    <i class="fas fa-plus me-1"></i> Add to Invoice
                                </button>
                            </div>
                        </div>
                        <div id="addStatus" class="mt-2" style="min-height:18px;font-size:0.78rem;"></div>
                    </div>
                </div>
            </div>

            <!-- Card 3: Invoice Items -->
            <div class="inv-section-card">
                <div class="inv-section-header" style="background:#f8fafc;">
                    <div style="width:32px;height:32px;border-radius:8px;background:#e2e8f0;
                                display:flex;align-items:center;justify-content:center;
                                font-size:0.9rem;color:#475569;">
                        <i class="fas fa-list-ul"></i>
                    </div>
                    <span style="color:#334155;">Invoice Items</span>
                    <span id="itemCountBadge" class="badge ms-1"
                          style="background:#e2e8f0;color:#475569;font-size:0.72rem;">0 items</span>
                </div>

                <div id="itemsWrap">
                    <div class="empty-items" id="emptyState">
                        <i class="fas fa-box-open"></i>
                        <p>No items added yet.<br />Select a product and color above, then click <strong>Add to Invoice</strong>.</p>
                    </div>
                </div>

                <!-- Discount row inside card -->
                <div id="discountRow" class="d-none" style="padding:14px 20px;border-top:1px solid #e2e8f0;background:#fafbff;">
                    <div class="row align-items-center justify-content-end g-2">
                        <div class="col-auto">
                            <label class="form-label mb-0 fw-semibold" style="font-size:0.82rem;color:#64748b;">
                                <i class="fas fa-tag me-1 text-warning"></i>Discount
                            </label>
                        </div>
                        <div class="col-auto">
                            <div class="discount-wrap">
                                <input type="number" id="txtDiscount" class="form-control form-control-sm"
                                       style="width:140px;" min="0" step="0.01" value="0"
                                       oninput="recalc()" />
                                <span class="cur-label">Rs.</span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

        </div><!-- /col-lg-8 -->

        <!-- ── RIGHT: Summary ─────────────────────────── -->
        <div class="col-lg-4">
            <div class="summary-sticky">
                <div class="summary-card">

                    <!-- Summary Header -->
                    <div class="summary-header">
                        <div style="font-size:0.72rem;opacity:.75;text-transform:uppercase;letter-spacing:.06em;font-weight:600;">
                            Invoice Number
                        </div>
                        <div class="inv-num-badge" id="invNumDisplay">Generating...</div>
                    </div>

                    <!-- Summary Body -->
                    <div class="summary-body">
                        <div class="summary-row">
                            <span class="summary-label"><i class="fas fa-boxes me-1"></i>Total Qty</span>
                            <span class="summary-value" id="sumQty">0</span>
                        </div>
                        <div class="summary-row">
                            <span class="summary-label"><i class="fas fa-receipt me-1"></i>Total Amount</span>
                            <span class="summary-value" id="sumTotal">Rs. 0.00</span>
                        </div>
                        <div class="summary-row">
                            <span class="summary-label"><i class="fas fa-tag me-1 text-warning"></i>Discount</span>
                            <span class="summary-value" style="color:#d97706;" id="sumDiscount">Rs. 0.00</span>
                        </div>
                        <div class="summary-row grand-total-row">
                            <span class="grand-total-label"><i class="fas fa-check-circle me-1"></i>Grand Total</span>
                            <span class="grand-total-value" id="sumGrand">Rs. 0.00</span>
                        </div>
                    </div>

                    <!-- Action Buttons -->
                    <div style="padding:0 20px 20px;">
                        <button type="button" id="btnSave" class="btn btn-primary w-100 mb-2"
                                onclick="saveInvoice()">
                            <i class="fas fa-save me-2"></i>Save Invoice
                        </button>
                        <a href="<%: ResolveUrl("~/CustomerBilling.aspx") %>"
                           class="btn btn-light w-100" style="font-size:0.85rem;">
                            <i class="fas fa-times me-1"></i>Cancel
                        </a>
                    </div>

                </div><!-- /summary-card -->
            </div><!-- /summary-sticky -->
        </div>

    </div><!-- /row -->

</asp:Content>

<asp:Content ID="ScriptsContent" ContentPlaceHolderID="ScriptsContent" runat="server">

    <script>
        var invoiceItems = [];  // [{variantId, size, sku, qty, salePrice}]
        var collapseState = {}; // ghKey -> true (collapsed)
        var pkFmt = { minimumFractionDigits: 2 };

        /* ============================================================ INIT */
        $(document).ready(function () {
            var today = new Date().toISOString().split('T')[0];
            $('#txtInvoiceDate').val(today);

            loadCustomers();
            loadProducts();
            getNextInvNumber();
        });

        /* ============================================================ DROPDOWNS */
        function loadCustomers() {
            api('GetB2BCustomers', {}, function (err, list) {
                var $d = $('#ddlCustomer').empty();
                $d.append('<option value="">Select Customer</option>');
                if (!err && list)
                    $.each(list, function (i, c) {
                        $d.append('<option value="' + c.CustomerId + '">'
                            + escHtml(c.ShopName) + '  (' + escHtml(c.PersonName) + ')</option>');
                    });
            });
        }

        function loadProducts() {
            api('GetProductsForDropdown', {}, function (err, list) {
                var $d = $('#ddlProduct').empty();
                $d.append('<option value="">Select Product</option>');
                if (!err && list)
                    $.each(list, function (i, p) {
                        $d.append('<option value="' + p.ProductId + '">'
                            + escHtml(p.ProductName) + '</option>');
                    });
            });
        }

        function getNextInvNumber() {
            api('GetNextInvoiceNumber', {}, function (err, num) {
                $('#invNumDisplay').text(num || '-');
            });
        }

        function onProductChange() {
            var pid = parseInt($('#ddlProduct').val()) || 0;
            var $c  = $('#ddlColor');
            $c.html('<option value="">Loading...</option>').prop('disabled', true);
            if (!pid) { $c.html('<option value="">Select product first</option>'); return; }
            api('GetColorsByProduct', { productId: pid }, function (err, colors) {
                $c.empty().prop('disabled', false);
                $c.append('<option value="">Select Color</option>');
                if (!err && colors && colors.length)
                    $.each(colors, function (i, c) {
                        $c.append('<option value="' + escHtml(c) + '">' + escHtml(c) + '</option>');
                    });
                else
                    $c.append('<option value="" disabled>No colors found</option>');
            });
        }

        /* ============================================================ ADD VARIANTS */
        function addVariants() {
            var pid   = parseInt($('#ddlProduct').val()) || 0;
            var color = $('#ddlColor').val();
            if (!pid)   { shakeField('#ddlProduct'); showToast('Select a product.',  'warning'); return; }
            if (!color) { shakeField('#ddlColor');   showToast('Select a color.',    'warning'); return; }

            $('#addStatus').html(
                '<i class="fas fa-spinner fa-spin me-1 text-primary"></i> Loading variants...');

            var productName = $.trim($('#ddlProduct option:selected').text());

            api('GetVariantsByProductColor', { productId: pid, color: color }, function (err, variants) {
                if (err || !variants) {
                    $('#addStatus').html('<span class="text-danger"><i class="fas fa-times-circle me-1"></i>Failed to load variants.</span>');
                    return;
                }
                if (!variants.length) {
                    $('#addStatus').html('<span class="text-warning"><i class="fas fa-exclamation-triangle me-1"></i>No sizes found for this selection.</span>');
                    return;
                }
                var added = 0, skipped = 0;
                $.each(variants, function (i, v) {
                    if (invoiceItems.some(function (x) { return x.variantId === v.VariantId; })) {
                        skipped++; return;
                    }
                    invoiceItems.push({
                        variantId:   v.VariantId,
                        productName: productName,
                        color:       color,
                        size:        v.Size,
                        sku:         v.SKUNumbers || '',
                        qty:         1,
                        salePrice:   parseFloat(v.SalePrice) || 0
                    });
                    added++;
                });
                renderGrid();

                var msg = '';
                if (added)   msg += '<span class="text-success"><i class="fas fa-check-circle me-1"></i>' + added + ' size(s) added.</span>';
                if (skipped) msg += (msg ? ' &nbsp;' : '') + '<span class="text-warning"><i class="fas fa-info-circle me-1"></i>' + skipped + ' already added.</span>';
                $('#addStatus').html(msg);

                // Keep product selected so user can pick another color for the same product
                $('#ddlColor').val('');
            });
        }

        /* ============================================================ GRID */
        function renderGrid() {
            var $wrap = $('#itemsWrap');
            if (invoiceItems.length === 0) {
                $wrap.html('<div class="empty-items" id="emptyState">'
                    + '<i class="fas fa-box-open"></i>'
                    + '<p>No items added yet.<br />Select a product and color above, then click <strong>Add to Invoice</strong>.</p>'
                    + '</div>');
                $('#itemCountBadge').text('0 items');
                $('#discountRow').addClass('d-none');
                recalc(); return;
            }

            // Build ordered groups keyed by product+color
            var groupKeys = [], groupMap = {};
            invoiceItems.forEach(function (it, idx) {
                var key = (it.productName || '') + '||' + (it.color || '');
                if (!groupMap[key]) {
                    groupMap[key] = { productName: it.productName || '', color: it.color || '', rows: [] };
                    groupKeys.push(key);
                }
                groupMap[key].rows.push({ it: it, idx: idx });
            });

            var html = '<div class="table-responsive"><table class="items-grid"><thead><tr>'
                + '<th style="width:36px" class="text-center">#</th>'
                + '<th style="width:64px" class="text-center">Size</th>'
                + '<th>SKU</th>'
                + '<th style="width:96px" class="text-center">Qty</th>'
                + '<th style="width:160px">Sale Price</th>'
                + '<th style="width:120px" class="text-end">Total</th>'
                + '<th style="width:40px"></th>'
                + '</tr></thead><tbody>';

            var rowNum = 1;
            groupKeys.forEach(function (key) {
                var g = groupMap[key];

                // Group subtotal
                var groupTotal = 0, groupQty = 0;
                g.rows.forEach(function (r) {
                    groupQty  += r.it.qty || 0;
                    groupTotal += (r.it.qty || 0) * (r.it.salePrice || 0);
                });

                // Group header row
                var safePN  = escJs(g.productName), safeC = escJs(g.color);
                var ghKey   = encodeURIComponent(g.productName + '||' + g.color);
                var ghStyle = 'padding:8px 10px;border-bottom:1px solid #c7d2fe;vertical-align:middle;';
                var isCollapsed  = !!collapseState[ghKey];
                var chevronStyle = isCollapsed ? 'transform:rotate(-90deg);' : '';

                html += '<tr data-ghkey="' + ghKey + '" style="background:linear-gradient(135deg,#eff6ff,#e0e7ff);">'

                    // cols 1-3: product info
                    + '<td colspan="3" style="' + ghStyle + '">'
                    +   '<div class="d-flex align-items-center gap-2 flex-wrap">'
                    +     '<button type="button" class="collapse-toggle" onclick="toggleGroup(\'' + ghKey + '\')" title="Collapse / Expand">'
                    +       '<i class="fas fa-chevron-down" style="' + chevronStyle + '"></i>'
                    +     '</button>'
                    +     '<span style="font-weight:700;font-size:0.88rem;color:#1e40af;">' + escHtml(g.productName) + '</span>'
                    +     '<span style="background:#bfdbfe;color:#1e40af;border-radius:20px;font-size:0.72rem;font-weight:600;padding:2px 9px;">' + escHtml(g.color) + '</span>'
                    +     '<span style="font-size:0.78rem;color:#64748b;">' + g.rows.length + ' sizes</span>'
                    +   '</div>'
                    + '</td>'

                    // col 4: group qty input
                    + '<td style="' + ghStyle + '" class="text-center">'
                    +   '<input type="number" class="form-control form-control-sm text-center px-1" '
                    +     'style="width:72px;margin:0 auto;background:#e0e7ff;border-color:#a5b4fc;font-weight:700;color:#3730a3;" '
                    +     'min="0" value="1" title="Set qty for all sizes in this group" '
                    +     'oninput="setGroupQty(\'' + safePN + '\',\'' + safeC + '\',this.value)" />'
                    + '</td>'

                    // col 5: group price input
                    + '<td style="' + ghStyle + '">'
                    +   '<div class="input-group input-group-sm">'
                    +     '<span class="input-group-text" style="background:#e0e7ff;border-color:#a5b4fc;color:#3730a3;font-weight:600;">Rs.</span>'
                    +     '<input type="number" class="form-control" min="0" step="0.01" '
                    +       'style="background:#e0e7ff;border-color:#a5b4fc;font-weight:700;color:#3730a3;" '
                    +       'value="0" title="Set price for all sizes in this group" '
                    +       'oninput="setGroupPrice(\'' + safePN + '\',\'' + safeC + '\',this.value)" />'
                    +   '</div>'
                    + '</td>'

                    // col 6: group total
                    + '<td class="text-end gh-amt-badge" '
                    +   'style="' + ghStyle + 'font-weight:700;color:#15803d;font-size:0.9rem;">'
                    +   'Rs. ' + groupTotal.toLocaleString('en-PK', pkFmt)
                    + '</td>'

                    // col 7: remove button
                    + '<td class="text-center" style="' + ghStyle + '">'
                    +   '<button type="button" onclick="removeGroup(\'' + safePN + '\',\'' + safeC + '\')" '
                    +     'style="background:#fee2e2;color:#dc2626;border:none;border-radius:6px;'
                    +            'padding:4px 8px;font-size:0.76rem;font-weight:600;cursor:pointer;white-space:nowrap;">'
                    +     '<i class="fas fa-trash-alt" style="font-size:0.7rem;"></i> Remove'
                    +   '</button>'
                    + '</td>'
                    + '</tr>';

                // Size rows
                g.rows.forEach(function (entry) {
                    var it = entry.it, idx = entry.idx;
                    var total = (it.qty || 0) * (it.salePrice || 0);
                    var hiddenAttr = isCollapsed ? ' style="display:none;"' : '';
                    html += '<tr data-idx="' + idx + '" data-groupkey="' + ghKey + '"' + hiddenAttr + '>';
                    html += '<td class="text-center row-num">' + rowNum + '</td>';
                    html += '<td class="text-center"><span class="size-pill">' + escHtml(it.size) + '</span></td>';
                    html += '<td><span class="sku-code">' + escHtml(it.sku || '-') + '</span></td>';
                    html += '<td class="text-center">'
                        + '<input type="number" class="form-control form-control-sm text-center px-1" '
                        + 'style="width:72px;margin:0 auto;" min="0" value="' + it.qty + '" '
                        + 'oninput="updateQty(' + idx + ',this.value)" /></td>';
                    html += '<td><div class="input-group input-group-sm">'
                        + '<span class="input-group-text">Rs.</span>'
                        + '<input type="number" class="form-control" min="0" step="0.01" value="' + it.salePrice + '" '
                        + 'oninput="updatePrice(' + idx + ',this.value)" /></div></td>';
                    html += '<td class="text-end total-cell row-total">Rs. ' + total.toLocaleString('en-PK', pkFmt) + '</td>';
                    html += '<td class="text-center">'
                        + '<button type="button" class="btn btn-sm py-0 px-2" '
                        + 'style="background:#fee2e2;color:#dc2626;border:none;border-radius:6px;" '
                        + 'onclick="removeItem(' + idx + ')" title="Remove">'
                        + '<i class="fas fa-times"></i></button></td>';
                    html += '</tr>';
                    rowNum++;
                });
            });

            html += '</tbody></table></div>';
            $wrap.html(html);
            $('#itemCountBadge').text(invoiceItems.length + ' size(s) in ' + groupKeys.length + ' product(s)');
            $('#discountRow').removeClass('d-none');
            recalc();
        }

        function updateQty(idx, val) {
            invoiceItems[idx].qty = parseInt(val) || 0;
            var t = invoiceItems[idx].qty * invoiceItems[idx].salePrice;
            $('tr[data-idx="' + idx + '"] .row-total').text('Rs. ' + t.toLocaleString('en-PK', pkFmt));
            refreshGroupHeader(invoiceItems[idx].productName, invoiceItems[idx].color);
            recalc();
        }

        function updatePrice(idx, val) {
            invoiceItems[idx].salePrice = parseFloat(val) || 0;
            var t = invoiceItems[idx].qty * invoiceItems[idx].salePrice;
            $('tr[data-idx="' + idx + '"] .row-total').text('Rs. ' + t.toLocaleString('en-PK', pkFmt));
            refreshGroupHeader(invoiceItems[idx].productName, invoiceItems[idx].color);
            recalc();
        }

        function refreshGroupHeader(productName, color) {
            var gTotal = 0;
            invoiceItems.forEach(function (it) {
                if (it.productName === productName && it.color === color)
                    gTotal += (it.qty || 0) * (it.salePrice || 0);
            });
            $('tr[data-ghkey="' + encodeURIComponent(productName + '||' + color) + '"]')
                .find('.gh-amt-badge')
                .text('Rs. ' + gTotal.toLocaleString('en-PK', pkFmt));
        }

        function setGroupQty(productName, color, val) {
            var qty = parseInt(val) || 0;
            invoiceItems.forEach(function (it, idx) {
                if (it.productName === productName && it.color === color) {
                    it.qty = qty;
                    $('tr[data-idx="' + idx + '"] input[type="number"]:first').val(qty);
                    var t = qty * it.salePrice;
                    $('tr[data-idx="' + idx + '"] .row-total').text('Rs. ' + t.toLocaleString('en-PK', pkFmt));
                }
            });
            refreshGroupHeader(productName, color);
            recalc();
        }

        function setGroupPrice(productName, color, val) {
            var price = parseFloat(val) || 0;
            invoiceItems.forEach(function (it, idx) {
                if (it.productName === productName && it.color === color) {
                    it.salePrice = price;
                    $('tr[data-idx="' + idx + '"] .input-group input[type="number"]').val(price);
                    var t = it.qty * price;
                    $('tr[data-idx="' + idx + '"] .row-total').text('Rs. ' + t.toLocaleString('en-PK', pkFmt));
                }
            });
            refreshGroupHeader(productName, color);
            recalc();
        }

        function removeItem(idx) {
            invoiceItems.splice(idx, 1);
            renderGrid();
        }

        function removeGroup(productName, color) {
            invoiceItems = invoiceItems.filter(function (it) {
                return !(it.productName === productName && it.color === color);
            });
            renderGrid();
        }

        function toggleGroup(ghKey) {
            collapseState[ghKey] = !collapseState[ghKey];
            var $rows = $('tr[data-groupkey="' + ghKey + '"]');
            var $icon = $('tr[data-ghkey="' + ghKey + '"] .collapse-toggle i');
            if (collapseState[ghKey]) {
                $rows.hide();
                $icon.css('transform', 'rotate(-90deg)');
            } else {
                $rows.show();
                $icon.css('transform', '');
            }
        }

        function recalc() {
            var qty = 0, total = 0;
            invoiceItems.forEach(function (it) {
                qty   += it.qty || 0;
                total += (it.qty || 0) * (it.salePrice || 0);
            });
            var disc  = parseFloat($('#txtDiscount').val()) || 0;
            var grand = Math.max(0, total - disc);

            $('#sumQty').text(qty);
            $('#sumTotal').text('Rs. ' + total.toLocaleString('en-PK', pkFmt));
            $('#sumDiscount').text('Rs. ' + disc.toLocaleString('en-PK', pkFmt));
            $('#sumGrand').text('Rs. ' + grand.toLocaleString('en-PK', pkFmt));
        }

        /* ============================================================ SAVE */
        function saveInvoice() {
            var custId = parseInt($('#ddlCustomer').val()) || 0;
            var date   = $('#txtInvoiceDate').val();
            var notes  = $.trim($('#txtNotes').val());
            var disc   = parseFloat($('#txtDiscount').val()) || 0;

            if (!custId) { shakeField('#ddlCustomer');   showToast('Please select a customer.',   'warning'); return; }
            if (!date)   { shakeField('#txtInvoiceDate');showToast('Invoice date is required.',   'warning'); return; }

            var items = invoiceItems.filter(function (it) { return it.qty > 0; });
            if (!items.length) { showToast('Add at least one item with quantity > 0.', 'warning'); return; }

            var $btn = $('#btnSave');
            $btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-2"></i>Saving...');

            api('SaveInvoice', {
                invoice: {
                    CustomerId:  custId,
                    InvoiceDate: date,
                    Discount:    disc,
                    Notes:       notes,
                    Items: items.map(function (it) {
                        return { VariantId: it.variantId, Size: it.size,
                                 SKUNumber: it.sku, Qty: it.qty, SalePrice: it.salePrice };
                    })
                }
            }, function (err, r) {
                $btn.prop('disabled', false).html('<i class="fas fa-save me-2"></i>Save Invoice');
                if (err || !r) { showToast('Request failed. Please try again.', 'danger'); return; }
                if (!r.success) { showToast(r.message, 'danger'); return; }
                var inv = (r.data && r.data.InvoiceNumber) ? r.data.InvoiceNumber : '';
                window.location.href = 'CustomerBilling.aspx?saved=1&inv=' + encodeURIComponent(inv);
            });
        }

        /* ============================================================ HELPERS */
        function api(method, data, cb) {
            $.ajax({
                type: 'POST', url: 'NewInvoice.aspx/' + method,
                data: JSON.stringify(data),
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (r) { cb(null, typeof r.d === 'string' ? JSON.parse(r.d) : r.d); },
                error:   function (e) { cb(e.responseText || 'Error', null); }
            });
        }

        function escHtml(s) {
            if (!s) return '';
            return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
                            .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
        }

        function escJs(s) {
            if (!s) return '';
            return String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/"/g,'\\"');
        }

        function shakeField(sel) {
            $(sel).addClass('is-invalid');
            setTimeout(function () { $(sel).removeClass('is-invalid'); }, 2000);
        }

        function showToast(msg, type) {
            var icon  = type === 'success' ? 'check-circle' : type === 'warning' ? 'exclamation-triangle' : 'times-circle';
            var bg    = type === 'success' ? '#f0fdf4'      : type === 'warning' ? '#fffbeb'               : '#fef2f2';
            var color = type === 'success' ? '#15803d'      : type === 'warning' ? '#92400e'               : '#b91c1c';
            var bdr   = type === 'success' ? '#bbf7d0'      : type === 'warning' ? '#fde68a'               : '#fecaca';
            var id = 'toast_' + Date.now();
            $('body').append('<div id="' + id + '" style="position:fixed;bottom:24px;right:24px;z-index:9999;'
                + 'min-width:280px;border-radius:10px;padding:12px 18px;font-size:0.84rem;font-weight:600;'
                + 'background:' + bg + ';color:' + color + ';border:1px solid ' + bdr + ';'
                + 'box-shadow:0 8px 24px rgba(0,0,0,0.12);animation:slideUp .25s ease;">'
                + '<i class="fas fa-' + icon + ' me-2"></i>' + escHtml(msg) + '</div>');
            setTimeout(function () { $('#' + id).fadeOut(300, function () { $(this).remove(); }); }, 3500);
        }
    </script>

    <style>
        @keyframes slideUp {
            from { opacity:0; transform:translateY(10px); }
            to   { opacity:1; transform:translateY(0); }
        }
    </style>

</asp:Content>
