<%@ Page Title="Customer Billing" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="CustomerBilling.aspx.cs" Inherits="Onfoot_Inventory.CustomerBilling" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css" rel="stylesheet" />
    <link href="https://cdn.datatables.net/responsive/2.5.0/css/responsive.bootstrap5.min.css" rel="stylesheet" />
    <style>
        #tblInvoices { border-collapse: separate; border-spacing: 0; table-layout: fixed; width: 100% !important; }
        #tblInvoices thead th {
            background: #f8fafc;
            color: var(--text-muted);
            font-size: 0.72rem;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            padding: 10px 14px;
            border-bottom: 1px solid var(--border);
            white-space: nowrap;
        }
        #tblInvoices tbody td {
            padding: 11px 14px;
            vertical-align: middle;
            font-size: 0.895rem;
            border-top: none;
            border-bottom: 1px solid #e8edf5;
        }
        #tblInvoices tbody tr:nth-child(even) td { background: #f7f9ff; }
        #tblInvoices tbody tr:hover td          { background: #eff6ff !important; cursor: pointer; }

        .inv-action-wrap { display:flex; gap:4px; justify-content:center; align-items:center; }
        .btn-grid-view   { display:inline-flex;align-items:center;justify-content:center;
                           width:30px;height:30px;border-radius:6px;border:none;cursor:pointer;
                           background:#dbeafe;color:#1d4ed8;font-size:0.82rem;transition:background .15s; }
        .btn-grid-view:hover   { background:#bfdbfe; }
        .btn-grid-ledger { display:inline-flex;align-items:center;justify-content:center;
                           width:30px;height:30px;border-radius:6px;border:none;cursor:pointer;
                           background:#d1fae5;color:#065f46;font-size:0.82rem;transition:background .15s; }
        .btn-grid-ledger:hover { background:#a7f3d0; }
        .btn-grid-cancel { display:inline-flex;align-items:center;justify-content:center;
                           width:30px;height:30px;border-radius:6px;border:none;cursor:pointer;
                           background:#fee2e2;color:#dc2626;font-size:0.82rem;transition:background .15s; }
        .btn-grid-cancel:hover { background:#fecaca; }

        .inv-number  { font-weight:700; color:var(--primary); font-size:0.85rem; }
        .inv-shop    { font-weight:600; }
        .inv-person  { font-size:0.78rem; color:var(--text-muted); }

        /* View modal */
        .detail-info-box {
            background:#f8faff;
            border:1px solid #e0e7ff;
            border-radius:10px;
            padding:14px 16px;
        }
        .detail-sum-box {
            background:#f0fdf4;
            border:1px solid #bbf7d0;
            border-radius:10px;
            padding:14px 16px;
        }
        .view-items-table { width:100%; border-collapse:collapse; }
        .view-items-table thead th {
            background:#f8fafc;
            font-size:0.72rem;
            font-weight:700;
            text-transform:uppercase;
            letter-spacing:.04em;
            color:#64748b;
            padding:9px 12px;
            border-bottom:2px solid #e2e8f0;
        }
        .view-items-table tbody td {
            padding:9px 12px;
            vertical-align:middle;
            font-size:0.875rem;
            border-bottom:1px solid #f1f5f9;
        }
        .size-pill {
            display:inline-flex;align-items:center;justify-content:center;
            min-width:36px;height:36px;border-radius:8px;
            background:#eff6ff;color:#1d4ed8;font-weight:800;font-size:0.9rem;
            border:1px solid #bfdbfe;
        }

        /* Ledger */
        .ledger-table td, .ledger-table th { padding:7px 12px;font-size:0.84rem;vertical-align:middle; }
        .ledger-debit  { color:#dc2626;font-weight:600; }
        .ledger-credit { color:#16a34a;font-weight:600; }

        /* View modal – group rows */
        .view-group-row { cursor: pointer; }
        .view-group-row:hover td { background: #dcfce7 !important; }
        .view-chevron { transition: transform .2s ease; font-size: 0.65rem; color: #15803d; }
    </style>
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-left">
            <h4><i class="fas fa-file-invoice-dollar me-2 text-primary"></i>Customer Billing &amp; Invoicing</h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="<%: ResolveUrl("~/") %>">Dashboard</a></li>
                    <li class="breadcrumb-item active">Customer Billing</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex gap-2">
            <button class="btn btn-outline-secondary btn-sm" onclick="loadInvoices();loadStats();" title="Refresh">
                <i class="fas fa-sync-alt me-1"></i> Refresh
            </button>
            <a href="<%: ResolveUrl("~/NewInvoice.aspx") %>" class="btn btn-primary">
                <i class="fas fa-plus me-1"></i> New Invoice
            </a>
        </div>
    </div>

    <!-- Stat Cards -->
    <div class="row g-3 mb-4">
        <div class="col-xl-4 col-sm-6">
            <div class="stat-card" style="border-top:3px solid #2563eb;">
                <div class="stat-icon blue"><i class="fas fa-file-invoice"></i></div>
                <div>
                    <div class="stat-label">Total Invoices</div>
                    <div class="stat-value" id="statTotal">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-4 col-sm-6">
            <div class="stat-card" style="border-top:3px solid #16a34a;">
                <div class="stat-icon green"><i class="fas fa-rupee-sign"></i></div>
                <div>
                    <div class="stat-label">Total Billed Amount</div>
                    <div class="stat-value" id="statAmount">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-4 col-sm-6">
            <div class="stat-card" style="border-top:3px solid #7c3aed;">
                <div class="stat-icon purple"><i class="fas fa-store-alt"></i></div>
                <div>
                    <div class="stat-label">Customers Billed</div>
                    <div class="stat-value" id="statCustomers">—</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Invoices Table -->
    <div class="table-card">
        <div class="table-card-body p-0">
            <div class="table-responsive">
                <table id="tblInvoices" class="table mb-0 w-100">
                    <thead>
                        <tr>
                            <th style="width:4%">#</th>
                            <th style="width:13%">Invoice No</th>
                            <th style="width:18%">Customer</th>
                            <th style="width:10%">Date</th>
                            <th style="width:6%">Qty</th>
                            <th style="width:11%">Total</th>
                            <th style="width:9%">Discount</th>
                            <th style="width:11%">Grand Total</th>
                            <th style="width:8%">Status</th>
                            <th style="width:10%">Actions</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="ModalsContent" ContentPlaceHolderID="ScriptsContent" runat="server">

    <!-- ========== VIEW INVOICE MODAL ========== -->
    <div class="modal fade" id="viewModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable modal-lg">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px;overflow:hidden;">
                <div class="modal-header border-0" style="background:linear-gradient(135deg,#f0fdf4,#dcfce7);padding:18px 24px 14px;">
                    <div class="d-flex align-items-center gap-3">
                        <div style="width:38px;height:38px;border-radius:9px;background:#dcfce7;
                                    display:flex;align-items:center;justify-content:center;font-size:1rem;color:#15803d;">
                            <i class="fas fa-file-invoice-dollar"></i>
                        </div>
                        <div>
                            <h5 class="modal-title mb-0" id="viewTitle" style="font-size:1rem;font-weight:700;">Invoice</h5>
                            <p class="mb-0" id="viewSubtitle" style="font-size:0.74rem;color:var(--text-muted);"></p>
                        </div>
                    </div>
                    <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="viewBody" style="padding:20px 24px;">
                    <div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x text-success"></i></div>
                </div>
                <div class="modal-footer border-0" style="padding:12px 24px 18px;gap:8px;">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">Close</button>
                    <button type="button" class="btn btn-outline-secondary btn-sm px-4" onclick="printInvoice()">
                        <i class="fas fa-print me-1"></i> Print
                    </button>
                    <button type="button" class="btn btn-success btn-sm px-4" id="btnViewLedger" onclick="openLedgerFromView()">
                        <i class="fas fa-book me-1"></i> View Ledger
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- ========== LEDGER MODAL ========== -->
    <div class="modal fade" id="ledgerModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable modal-lg">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px;overflow:hidden;">
                <div class="modal-header border-0" style="background:linear-gradient(135deg,#ecfdf5,#d1fae5);padding:18px 24px 14px;">
                    <div class="d-flex align-items-center gap-3">
                        <div style="width:38px;height:38px;border-radius:9px;background:#d1fae5;
                                    display:flex;align-items:center;justify-content:center;font-size:1rem;color:#065f46;">
                            <i class="fas fa-book"></i>
                        </div>
                        <div>
                            <h5 class="modal-title mb-0" id="ledgerTitle" style="font-size:1rem;font-weight:700;">Ledger</h5>
                            <p class="mb-0" id="ledgerSubtitle" style="font-size:0.74rem;color:var(--text-muted);"></p>
                        </div>
                    </div>
                    <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="ledgerBody" style="padding:20px 24px;">
                    <div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x text-success"></i></div>
                </div>
                <div class="modal-footer border-0" style="padding:12px 24px 18px;">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- ========== CANCEL CONFIRM ========== -->
    <div class="modal fade" id="cancelModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered" style="max-width:380px;">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px;">
                <div class="modal-body text-center" style="padding:28px 24px 16px;">
                    <div style="width:52px;height:52px;border-radius:50%;background:#fef2f2;
                                display:flex;align-items:center;justify-content:center;
                                margin:0 auto 14px;font-size:1.3rem;color:#dc2626;">
                        <i class="fas fa-ban"></i>
                    </div>
                    <h5 style="font-size:0.95rem;font-weight:700;margin-bottom:6px;">Cancel Invoice</h5>
                    <p id="cancelMsg" class="text-muted mb-0" style="font-size:0.82rem;"></p>
                </div>
                <div class="modal-footer border-0 justify-content-center pb-4" style="gap:8px;">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">Keep It</button>
                    <button type="button" class="btn btn-danger btn-sm px-4" id="btnConfirmCancel">
                        <i class="fas fa-ban me-1"></i> Cancel Invoice
                    </button>
                </div>
            </div>
        </div>
    </div>

    <div class="toast-container-fixed" id="toastContainer"></div>

    <script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.7/js/dataTables.bootstrap5.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.5.0/js/dataTables.responsive.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.5.0/js/responsive.bootstrap5.min.js"></script>

    <script>
        var invTable;
        var viewModalBS, ledgerModalBS, cancelModalBS;
        var viewCustomerId = 0, cancelInvoiceId = 0;
        var viewCollapseState = {}, currentViewData = null;
        var pkFmt = { minimumFractionDigits: 2 };

        /* ── Init ── */
        $(document).ready(function () {
            initTable();
            loadStats();
            loadInvoices();
            checkSavedParam();
        });

        function checkSavedParam() {
            var params = new URLSearchParams(window.location.search);
            if (params.get('saved') === '1') {
                var inv = params.get('inv') || '';
                showToast('Invoice ' + (inv ? inv + ' ' : '') + 'saved successfully.', 'success');
                window.history.replaceState({}, '', 'CustomerBilling.aspx');
            }
        }

        function initTable() {
            invTable = $('#tblInvoices').DataTable({
                responsive: false,
                pageLength: 20,
                lengthMenu: [[10,20,50,100],[10,20,50,100]],
                scrollY: '520px',
                scrollCollapse: false,
                columnDefs: [
                    { orderable: false, targets: [0,9] },
                    { className: 'text-center', targets: [0,4,8,9] },
                    { className: 'text-end', targets: [5,6,7] }
                ],
                order: [],
                language: {
                    search: '', searchPlaceholder: 'Search invoices...',
                    emptyTable: "<div class='text-center py-5 text-muted'><i class='fas fa-file-invoice fa-2x mb-3 d-block opacity-50'></i><div style='font-size:0.95rem;'>No invoices yet</div><div style='font-size:0.82rem;margin-top:4px;'><a href='NewInvoice.aspx' class='text-primary'>Create your first invoice</a></div></div>",
                    lengthMenu: "Show _MENU_ entries",
                    info: "Showing _START_ - _END_ of _TOTAL_ invoices",
                    paginate: { previous: '<i class="fas fa-chevron-left"></i>', next: '<i class="fas fa-chevron-right"></i>' }
                },
                dom: "<'row align-items-center px-3 pt-3 pb-2'<'col-sm-4'l><'col-sm-8'f>><'row'<'col-sm-12'tr>><'row align-items-center px-3 pt-2 pb-3'<'col-sm-5 text-muted small'i><'col-sm-7'p>>"
            });
        }

        /* ── Stats ── */
        function loadStats() {
            api('GetInvoiceStats', {}, function (err, s) {
                if (!s) return;
                $('#statTotal').text(s.TotalInvoices);
                $('#statAmount').text('Rs. ' + parseFloat(s.TotalAmount).toLocaleString('en-PK', pkFmt));
                $('#statCustomers').text(s.TotalCustomers);
            });
        }

        /* ── List ── */
        function loadInvoices() {
            api('GetInvoices', {}, function (err, list) {
                invTable.clear();
                if (err || !list) { invTable.draw(); return; }
                $.each(list, function (i, inv) {
                    var st = inv.Status === 'Active'
                        ? '<span class="badge-active">Active</span>'
                        : '<span class="badge-inactive">Cancelled</span>';
                    var custCell = '<div class="inv-shop">' + escHtml(inv.ShopName) + '</div>'
                                 + '<div class="inv-person">' + escHtml(inv.PersonName) + '</div>';
                    var disc = parseFloat(inv.Discount);
                    var discCell = disc > 0
                        ? '<span style="color:#d97706;font-weight:600;">Rs. ' + disc.toLocaleString('en-PK', pkFmt) + '</span>'
                        : '<span class="text-muted">Rs. 0.00</span>';
                    var actions = '<div class="inv-action-wrap">'
                        + '<button class="btn-grid-view" onclick="viewInvoice(' + inv.InvoiceId + ')" title="View"><i class="fas fa-eye"></i></button>'
                        + '<button class="btn-grid-ledger" onclick="openLedger(' + inv.CustomerId + ')" title="Ledger"><i class="fas fa-book"></i></button>';
                    if (inv.Status === 'Active')
                        actions += '<button class="btn-grid-cancel" onclick="confirmCancel(' + inv.InvoiceId + ',\'' + escJs(inv.InvoiceNumber) + '\')" title="Cancel"><i class="fas fa-ban"></i></button>';
                    actions += '</div>';
                    invTable.row.add([
                        i + 1,
                        '<span class="inv-number">' + escHtml(inv.InvoiceNumber) + '</span>',
                        custCell,
                        inv.InvoiceDate,
                        inv.TotalQty,
                        'Rs. ' + parseFloat(inv.TotalAmount).toLocaleString('en-PK', pkFmt),
                        discCell,
                        '<strong style="color:#15803d;">Rs. ' + parseFloat(inv.GrandTotal).toLocaleString('en-PK', pkFmt) + '</strong>',
                        st,
                        actions
                    ]);
                });
                invTable.draw();
            });
        }

        /* ── View Invoice ── */
        function viewInvoice(id) {
            if (!viewModalBS) viewModalBS = new bootstrap.Modal(document.getElementById('viewModal'));
            $('#viewTitle').text('Invoice'); $('#viewSubtitle').text('');
            $('#viewBody').html('<div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x text-success"></i></div>');
            viewModalBS.show();

            api('GetInvoiceById', { invoiceId: id }, function (err, data) {
                if (err || !data || !data.header) {
                    $('#viewBody').html('<p class="text-danger text-center py-3">Failed to load invoice.</p>');
                    return;
                }
                currentViewData = data;
                viewCollapseState = {};
                var h = data.header;
                viewCustomerId = h.CustomerId;
                $('#viewTitle').text(h.InvoiceNumber);
                $('#viewSubtitle').html(escHtml(h.ShopName) + ' &nbsp;&bull;&nbsp; ' + escHtml(h.InvoiceDate));

                var isActive = h.Status === 'Active';
                var stBadge  = isActive
                    ? '<span style="display:inline-block;background:#dcfce7;color:#15803d;border-radius:20px;font-size:0.66rem;font-weight:700;padding:2px 9px;vertical-align:middle;letter-spacing:.02em;">Active</span>'
                    : '<span style="display:inline-block;background:#fee2e2;color:#dc2626;border-radius:20px;font-size:0.66rem;font-weight:700;padding:2px 9px;vertical-align:middle;letter-spacing:.02em;">Cancelled</span>';

                // ── Bill To (left) | Invoice ref (right) ──────────────────────────
                var html = '<div class="d-flex justify-content-between align-items-start mb-4 pb-3" style="border-bottom:2px solid #eef2f7;">';
                html += '<div>';
                html += '<div style="font-size:0.58rem;text-transform:uppercase;letter-spacing:.12em;color:#94a3b8;font-weight:700;margin-bottom:7px;">Bill To</div>';
                html += '<div style="font-size:1.05rem;font-weight:800;color:#0f172a;line-height:1.3;">' + escHtml(h.ShopName) + '&nbsp;' + stBadge + '</div>';
                html += '<div style="font-size:0.84rem;color:#475569;margin-top:6px;">' + escHtml(h.PersonName) + '</div>';
                html += '<div style="font-size:0.81rem;color:#64748b;margin-top:3px;"><i class="fas fa-phone fa-xs me-1" style="opacity:.5;"></i>' + escHtml(h.ContactNo1) + '</div>';
                if (h.City) html += '<div style="font-size:0.79rem;color:#94a3b8;margin-top:3px;"><i class="fas fa-map-marker-alt fa-xs me-1"></i>' + escHtml(h.City) + '</div>';
                html += '</div>';
                html += '<div style="text-align:right;">';
                html += '<div style="font-size:0.58rem;text-transform:uppercase;letter-spacing:.12em;color:#94a3b8;font-weight:700;margin-bottom:7px;">Invoice</div>';
                html += '<div style="font-size:1.1rem;font-weight:800;color:#1e40af;letter-spacing:-.01em;">' + escHtml(h.InvoiceNumber) + '</div>';
                html += '<div style="font-size:0.81rem;color:#64748b;margin-top:6px;"><i class="fas fa-calendar-alt fa-xs me-1" style="opacity:.5;"></i>' + escHtml(h.InvoiceDate) + '</div>';
                html += '</div>';
                html += '</div>';

                // ── Notes ─────────────────────────────────────────────────────────
                if (h.Notes) {
                    html += '<div class="mb-3 px-3 py-2 rounded" style="background:#fffbeb;border-left:3px solid #fcd34d;font-size:0.82rem;color:#92400e;">';
                    html += '<i class="fas fa-sticky-note me-1"></i>' + escHtml(h.Notes) + '</div>';
                }

                // ── Items table ────────────────────────────────────────────────────
                html += '<div class="table-responsive mb-0" style="border-radius:8px;border:1px solid #e2e8f0;">';
                html += '<table class="view-items-table"><thead><tr>'
                    + '<th style="width:60px" class="text-center">Size</th>'
                    + '<th>SKU</th>'
                    + '<th style="width:60px" class="text-center">Qty</th>'
                    + '<th style="width:120px" class="text-end">Sale Price</th>'
                    + '<th style="width:120px" class="text-end">Total</th>'
                    + '</tr></thead><tbody>';

                if (data.items && data.items.length) {
                    var vGroups = {}, vGroupKeys = [];
                    $.each(data.items, function (i, it) {
                        var sku  = it.SKUNumber || '';
                        var gKey = sku.replace(/\s*-\s*[Ss]ize.*$/i, '').trim() || sku || 'Other';
                        gKey = gKey.replace(/\s*-\s*/g, ' - ').replace(/\s+/g, ' ').trim();
                        if (!vGroups[gKey]) { vGroups[gKey] = { label: gKey, items: [] }; vGroupKeys.push(gKey); }
                        vGroups[gKey].items.push(it);
                    });
                    var multiGrp = vGroupKeys.length > 1;
                    $.each(vGroupKeys, function (gi, gKey) {
                        var grp     = vGroups[gKey];
                        var safeKey = encodeURIComponent(gKey);
                        if (multiGrp) {
                            var gTotal = 0, gQty = 0;
                            $.each(grp.items, function (i, it) { gTotal += parseFloat(it.Total)||0; gQty += parseInt(it.Qty)||0; });
                            var ghS = 'padding:9px 14px;background:linear-gradient(135deg,#f0fdf4,#e8fdf2);border-bottom:1px solid #c6f6d5;vertical-align:middle;';
                            html += '<tr class="view-group-row" data-vghkey="' + safeKey + '" onclick="toggleViewGroup(\'' + safeKey + '\')">'
                                + '<td colspan="3" style="' + ghS + '">'
                                +   '<div class="d-flex align-items-center gap-2">'
                                +     '<i class="fas fa-chevron-down view-chevron"></i>'
                                +     '<span style="font-weight:700;font-size:0.83rem;color:#065f46;">' + escHtml(grp.label) + '</span>'
                                +     '<span style="font-size:0.73rem;color:#64748b;margin-left:2px;">' + grp.items.length + ' size(s) &bull; Qty: ' + gQty + '</span>'
                                +   '</div>'
                                + '</td>'
                                + '<td style="' + ghS + '"></td>'
                                + '<td class="text-end" style="' + ghS + 'font-weight:700;color:#15803d;font-size:0.88rem;">Rs. ' + gTotal.toLocaleString('en-PK', pkFmt) + '</td>'
                                + '</tr>';
                        }
                        $.each(grp.items, function (i, it) {
                            var rowAttr = multiGrp ? ' data-vgroupkey="' + safeKey + '"' : '';
                            html += '<tr' + rowAttr + '>'
                                + '<td class="text-center"><span class="size-pill">' + escHtml(it.Size) + '</span></td>'
                                + '<td style="font-size:0.82rem;color:#475569;">' + escHtml(it.SKUNumber || '—') + '</td>'
                                + '<td class="text-center fw-semibold">' + it.Qty + '</td>'
                                + '<td class="text-end" style="color:#475569;">Rs. ' + parseFloat(it.SalePrice).toLocaleString('en-PK', pkFmt) + '</td>'
                                + '<td class="text-end fw-bold" style="color:#15803d;">Rs. ' + parseFloat(it.Total).toLocaleString('en-PK', pkFmt) + '</td>'
                                + '</tr>';
                        });
                    });
                } else {
                    html += '<tr><td colspan="5" class="text-center text-muted py-4">No items.</td></tr>';
                }
                html += '</tbody></table></div>';

                // ── Totals (right-aligned) ─────────────────────────────────────────
                html += '<div class="d-flex justify-content-end mt-3">';
                html += '<div style="min-width:285px;">';
                html += '<div class="d-flex justify-content-between py-2" style="font-size:0.85rem;color:#475569;border-bottom:1px solid #f1f5f9;">';
                html += '<span>Subtotal <span style="font-size:0.75rem;color:#94a3b8;">(' + h.TotalQty + ' items)</span></span>';
                html += '<span class="fw-semibold">Rs. ' + parseFloat(h.TotalAmount).toLocaleString('en-PK', pkFmt) + '</span>';
                html += '</div>';
                if (parseFloat(h.Discount) > 0) {
                    html += '<div class="d-flex justify-content-between py-2" style="font-size:0.85rem;color:#475569;border-bottom:1px solid #f1f5f9;">';
                    html += '<span>Discount</span>';
                    html += '<span style="color:#d97706;font-weight:600;">&#8722;&nbsp;Rs. ' + parseFloat(h.Discount).toLocaleString('en-PK', pkFmt) + '</span>';
                    html += '</div>';
                }
                html += '<div class="d-flex justify-content-between align-items-center px-4 py-3 mt-2" style="background:linear-gradient(135deg,#f0fdf4,#dcfce7);border:1px solid #bbf7d0;border-radius:10px;">';
                html += '<span style="font-weight:700;font-size:0.9rem;color:#15803d;"><i class="fas fa-check-circle me-1" style="opacity:.75;"></i>Grand Total</span>';
                html += '<strong style="font-size:1.22rem;color:#15803d;letter-spacing:-.02em;">Rs. ' + parseFloat(h.GrandTotal).toLocaleString('en-PK', pkFmt) + '</strong>';
                html += '</div>';
                html += '</div></div>';

                $('#viewBody').html(html);
            });
        }

        function openLedgerFromView() {
            viewModalBS.hide();
            setTimeout(function () { openLedger(viewCustomerId); }, 300);
        }

        function toggleViewGroup(safeKey) {
            viewCollapseState[safeKey] = !viewCollapseState[safeKey];
            var $rows = $('tr[data-vgroupkey="' + safeKey + '"]');
            var $icon = $('tr[data-vghkey="' + safeKey + '"] .view-chevron');
            if (viewCollapseState[safeKey]) {
                $rows.hide();
                $icon.css('transform', 'rotate(-90deg)');
            } else {
                $rows.show();
                $icon.css('transform', '');
            }
        }

        function printInvoice() {
            if (!currentViewData || !currentViewData.header) return;
            var h     = currentViewData.header;
            var items = currentViewData.items || [];
            // Build product groups (collapsed view — one row per product)
            var vGrps = {}, vGrpKeys = [];
            $.each(items, function (i, it) {
                var sku  = it.SKUNumber || '';
                var gKey = sku.replace(/\s*-\s*[Ss]ize.*$/i, '').trim() || sku || 'Other';
                gKey = gKey.replace(/\s*-\s*/g, ' - ').replace(/\s+/g, ' ').trim();
                if (!vGrps[gKey]) { vGrps[gKey] = { label: gKey, items: [] }; vGrpKeys.push(gKey); }
                vGrps[gKey].items.push(it);
            });

            function buildGroupRows() {
                var r = '', n = 1;
                $.each(vGrpKeys, function (i, gKey) {
                    var grp = vGrps[gKey], gT = 0, gQ = 0;
                    $.each(grp.items, function (j, it) { gT += parseFloat(it.Total)||0; gQ += parseInt(it.Qty)||0; });
                    var firstRate = parseFloat(grp.items[0].SalePrice) || 0;
                    var allSame   = grp.items.every(function (it) { return parseFloat(it.SalePrice) === firstRate; });
                    var minRate   = Math.min.apply(null, grp.items.map(function (it) { return parseFloat(it.SalePrice)||0; }));
                    var maxRate   = Math.max.apply(null, grp.items.map(function (it) { return parseFloat(it.SalePrice)||0; }));
                    var rateStr   = allSame
                        ? 'Rs. ' + firstRate.toLocaleString('en-PK', pkFmt)
                        : 'Rs. ' + minRate.toLocaleString('en-PK', pkFmt) + ' - ' + maxRate.toLocaleString('en-PK', pkFmt);
                    var bg = n % 2 === 0 ? 'background:#f9fafb;' : '';
                    r += '<tr style="' + bg + '">'
                        + '<td style="padding:7px 10px;border-bottom:1px solid #eee;color:#9ca3af;font-size:10px;">' + n + '</td>'
                        + '<td style="padding:7px 10px;border-bottom:1px solid #eee;font-weight:600;font-size:12px;">' + escHtml(grp.label) + '</td>'
                        + '<td style="padding:7px 10px;border-bottom:1px solid #eee;text-align:center;font-size:11px;color:#6b7280;">' + grp.items.length + ' size(s)</td>'
                        + '<td style="padding:7px 10px;border-bottom:1px solid #eee;text-align:right;font-size:11px;color:#1e40af;font-weight:600;">' + rateStr + '</td>'
                        + '<td style="padding:7px 10px;border-bottom:1px solid #eee;text-align:center;font-weight:700;font-size:12px;">' + gQ + '</td>'
                        + '<td style="padding:7px 10px;border-bottom:1px solid #eee;text-align:right;font-weight:700;font-size:12px;color:#15803d;">Rs. ' + gT.toLocaleString('en-PK', pkFmt) + '</td>'
                        + '</tr>';
                    n++;
                });
                return r;
            }

            var stClr = h.Status === 'Active' ? 'background:#dcfce7;color:#15803d;' : 'background:#fee2e2;color:#dc2626;';

            function buildCopy(copyLabel) {
                var isC    = copyLabel === 'Customer Copy';
                var badgeBg = isC ? 'background:#eff6ff;color:#1d4ed8;' : 'background:#f0fdf4;color:#15803d;';
                return ''
                    + '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">'
                    +   '<span style="font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.1em;padding:3px 10px;border-radius:20px;' + badgeBg + '">' + copyLabel + '</span>'
                    +   '<span style="font-size:10px;color:#9ca3af;font-weight:600;letter-spacing:.04em;">Onfoot Inventory</span>'
                    + '</div>'
                    + '<div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:14px;padding-bottom:12px;border-bottom:2px solid #e5e7eb;">'
                    +   '<div>'
                    +     '<div style="font-size:9px;text-transform:uppercase;letter-spacing:.1em;color:#9ca3af;font-weight:700;margin-bottom:5px;">Bill To</div>'
                    +     '<div style="font-size:14px;font-weight:800;color:#0f172a;">' + escHtml(h.ShopName) + '</div>'
                    +     '<div style="font-size:11px;color:#475569;margin-top:3px;">' + escHtml(h.PersonName) + '</div>'
                    +     '<div style="font-size:11px;color:#6b7280;margin-top:2px;">' + escHtml(h.ContactNo1) + (h.City ? ' &bull; ' + escHtml(h.City) : '') + '</div>'
                    +     (h.Notes ? '<div style="font-size:10px;color:#92400e;margin-top:4px;padding:3px 7px;background:#fffbeb;border-left:2px solid #fcd34d;">Note: ' + escHtml(h.Notes) + '</div>' : '')
                    +   '</div>'
                    +   '<div style="text-align:right;">'
                    +     '<div style="font-size:9px;text-transform:uppercase;letter-spacing:.1em;color:#9ca3af;font-weight:700;margin-bottom:5px;">Invoice</div>'
                    +     '<div style="font-size:15px;font-weight:800;color:#1e40af;">' + escHtml(h.InvoiceNumber) + '</div>'
                    +     '<div style="font-size:11px;color:#6b7280;margin-top:3px;">' + escHtml(h.InvoiceDate) + '</div>'
                    +     '<div style="display:inline-block;margin-top:4px;padding:2px 8px;border-radius:20px;font-size:9px;font-weight:700;' + stClr + '">' + escHtml(h.Status) + '</div>'
                    +   '</div>'
                    + '</div>'
                    + '<table style="width:100%;border-collapse:collapse;margin-bottom:10px;">'
                    +   '<thead><tr style="background:#f8fafc;">'
                    +     '<th style="padding:6px 10px;border-bottom:2px solid #e5e7eb;font-size:9px;text-transform:uppercase;color:#6b7280;width:22px;">#</th>'
                    +     '<th style="padding:6px 10px;border-bottom:2px solid #e5e7eb;font-size:9px;text-transform:uppercase;color:#6b7280;">Product</th>'
                    +     '<th style="padding:6px 10px;border-bottom:2px solid #e5e7eb;font-size:9px;text-transform:uppercase;color:#6b7280;text-align:center;width:54px;">Sizes</th>'
                    +     '<th style="padding:6px 10px;border-bottom:2px solid #e5e7eb;font-size:9px;text-transform:uppercase;color:#6b7280;text-align:right;width:100px;">Rate</th>'
                    +     '<th style="padding:6px 10px;border-bottom:2px solid #e5e7eb;font-size:9px;text-transform:uppercase;color:#6b7280;text-align:center;width:40px;">Qty</th>'
                    +     '<th style="padding:6px 10px;border-bottom:2px solid #e5e7eb;font-size:9px;text-transform:uppercase;color:#6b7280;text-align:right;width:90px;">Amount</th>'
                    +   '</tr></thead>'
                    +   '<tbody>' + buildGroupRows() + '</tbody>'
                    + '</table>'
                    + '<div style="display:flex;justify-content:flex-end;">'
                    +   '<div style="min-width:210px;">'
                    +     '<div style="display:flex;justify-content:space-between;padding:4px 0;font-size:11px;color:#6b7280;border-bottom:1px solid #f3f4f6;">'
                    +       '<span>Subtotal (' + h.TotalQty + ' items)</span><span style="font-weight:600;color:#374151;">Rs. ' + parseFloat(h.TotalAmount).toLocaleString('en-PK', pkFmt) + '</span>'
                    +     '</div>'
                    +     (parseFloat(h.Discount) > 0
                            ? '<div style="display:flex;justify-content:space-between;padding:4px 0;font-size:11px;color:#6b7280;border-bottom:1px solid #f3f4f6;">'
                              + '<span>Discount</span><span style="font-weight:600;color:#d97706;">- Rs. ' + parseFloat(h.Discount).toLocaleString('en-PK', pkFmt) + '</span>'
                              + '</div>'
                            : '')
                    +     '<div style="display:flex;justify-content:space-between;padding:8px 12px;margin-top:6px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:6px;">'
                    +       '<span style="font-weight:700;font-size:12px;color:#15803d;">Grand Total</span>'
                    +       '<strong style="font-size:15px;color:#15803d;">Rs. ' + parseFloat(h.GrandTotal).toLocaleString('en-PK', pkFmt) + '</strong>'
                    +     '</div>'
                    +   '</div>'
                    + '</div>';
            }

            var win = window.open('', '_blank', 'width=700,height=940');
            win.document.write(
                '<!DOCTYPE html><html><head>'
                + '<title>Invoice ' + escHtml(h.InvoiceNumber) + '</title>'
                + '<style>'
                + '*{box-sizing:border-box;margin:0;padding:0;}'
                + 'body{font-family:Arial,sans-serif;background:#f3f4f6;}'
                + '.page{max-width:640px;margin:0 auto;padding:16px;}'
                + '.action-bar{display:flex;gap:8px;margin-bottom:14px;}'
                + '.btn-p{flex:1;padding:10px;border:none;border-radius:8px;font-size:13px;font-weight:700;cursor:pointer;}'
                + '.btn-print{background:#1e40af;color:#fff;}'
                + '.btn-pdf{background:#15803d;color:#fff;}'
                + '.copy-card{background:#fff;border-radius:10px;padding:18px 20px;box-shadow:0 1px 4px rgba(0,0,0,.08);}'
                + '.cut-wrap{display:flex;align-items:center;gap:8px;margin:12px 0;}'
                + '.cut-line{flex:1;border-top:2px dashed #cbd5e1;}'
                + '.cut-text{font-size:10px;color:#94a3b8;font-weight:700;letter-spacing:.06em;white-space:nowrap;}'
                + '@media print{'
                +   '.action-bar{display:none!important;}'
                +   'body{background:#fff;}'
                +   '.page{padding:0;max-width:100%;}'
                +   '.copy-card{box-shadow:none;border-radius:0;padding:12px 14px;}'
                +   '.cut-wrap{margin:4px 0;}'
                +   '@page{margin:8mm;size:A4;}'
                + '}'
                + '</style></head><body>'
                + '<div class="page">'
                +   '<div class="action-bar">'
                +     '<button class="btn-p btn-print" onclick="window.print()">&#128438; &nbsp;Print</button>'
                +     '<button class="btn-p btn-pdf" onclick="window.print()">&#8595; &nbsp;Download PDF &nbsp;<small style="opacity:.8;">(Save as PDF)</small></button>'
                +   '</div>'
                +   '<div class="copy-card">' + buildCopy('Customer Copy') + '</div>'
                +   '<div class="cut-wrap"><div class="cut-line"></div><span class="cut-text">&#9988; &nbsp;CUT HERE&nbsp; &#9988;</span><div class="cut-line"></div></div>'
                +   '<div class="copy-card">' + buildCopy('Company Copy') + '</div>'
                + '</div>'
                + '<script>window.onload=function(){window.print();}<\/script>'
                + '</body></html>'
            );
            win.document.close();
        }

        /* ── Ledger ── */
        function openLedger(customerId) {
            if (!ledgerModalBS) ledgerModalBS = new bootstrap.Modal(document.getElementById('ledgerModal'));
            $('#ledgerTitle').text('Customer Ledger'); $('#ledgerSubtitle').text('');
            $('#ledgerBody').html('<div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x text-success"></i></div>');
            ledgerModalBS.show();

            api('GetCustomerLedger', { customerId: customerId }, function (err, data) {
                if (err || !data || !data.customer) {
                    $('#ledgerBody').html('<p class="text-danger text-center py-3">Failed to load ledger.</p>');
                    return;
                }
                var c = data.customer;
                $('#ledgerTitle').text(c.ShopName + ' Ledger');
                $('#ledgerSubtitle').text(c.PersonName + ' | ' + c.ContactNo1);

                var bal = parseFloat(c.OpeningBalance) || 0;
                var html = '<div class="p-2 rounded mb-3 d-flex align-items-center gap-3" style="background:#f0fdf4;border:1px solid #bbf7d0;">';
                html += '<i class="fas fa-store-alt text-success"></i>';
                html += '<div><strong>' + escHtml(c.ShopName) + '</strong><span class="text-muted ms-2" style="font-size:0.82rem;">' + escHtml(c.PersonName) + ' &bull; ' + escHtml(c.ContactNo1) + '</span></div>';
                html += '<div class="ms-auto text-end"><div style="font-size:0.72rem;color:#64748b;text-transform:uppercase;letter-spacing:.04em;">Opening Balance</div>';
                html += '<strong class="ledger-debit">Rs. ' + bal.toLocaleString('en-PK', pkFmt) + '</strong></div></div>';

                html += '<div class="table-responsive" style="border-radius:8px;border:1px solid #e2e8f0;">';
                html += '<table class="table table-sm ledger-table mb-0"><thead class="table-light"><tr>'
                    + '<th style="width:110px">Date</th><th style="width:100px">Type</th>'
                    + '<th>Reference</th><th style="width:130px" class="text-end">Amount</th>'
                    + '<th style="width:140px" class="text-end">Balance</th></tr></thead><tbody>';

                if (bal > 0) {
                    html += '<tr style="background:#fefce8;"><td class="text-muted" style="font-size:0.78rem;">' + escHtml(c.CreatedDate) + '</td>';
                    html += '<td><span class="badge rounded-pill" style="background:#fef3c7;color:#92400e;font-size:0.7rem;">Opening</span></td>';
                    html += '<td class="text-muted" style="font-size:0.82rem;">Opening Balance</td>';
                    html += '<td class="text-end ledger-debit">Rs. ' + bal.toLocaleString('en-PK', pkFmt) + '</td>';
                    html += '<td class="text-end fw-bold">Rs. ' + bal.toLocaleString('en-PK', pkFmt) + '</td></tr>';
                }

                if (!data.entries || !data.entries.length) {
                    html += '<tr><td colspan="5" class="text-center text-muted py-3">No transactions yet.</td></tr>';
                } else {
                    $.each(data.entries, function (i, e) {
                        if (e.TransactionType === 'Invoice') bal += parseFloat(e.Amount);
                        else if (e.TransactionType === 'Payment') bal -= parseFloat(e.Amount);
                        var badge = e.TransactionType === 'Invoice'
                            ? '<span class="badge rounded-pill" style="background:#fee2e2;color:#b91c1c;font-size:0.7rem;">Invoice</span>'
                            : '<span class="badge rounded-pill" style="background:#dcfce7;color:#15803d;font-size:0.7rem;">Payment</span>';
                        var amtCell = e.TransactionType === 'Payment'
                            ? '<td class="text-end ledger-credit">- Rs. ' + parseFloat(e.Amount).toLocaleString('en-PK', pkFmt) + '</td>'
                            : '<td class="text-end ledger-debit">Rs. '    + parseFloat(e.Amount).toLocaleString('en-PK', pkFmt) + '</td>';
                        var balColor = bal > 0 ? '#dc2626' : bal < 0 ? '#15803d' : '#94a3b8';
                        html += '<tr><td style="font-size:0.8rem;">' + escHtml(e.CreatedDate) + '</td>';
                        html += '<td>' + badge + '</td>';
                        html += '<td style="font-size:0.82rem;">' + (e.InvoiceNumber ? '<strong>' + escHtml(e.InvoiceNumber) + '</strong>' : '') + '</td>';
                        html += amtCell;
                        html += '<td class="text-end fw-bold" style="color:' + balColor + ';">Rs. ' + Math.abs(bal).toLocaleString('en-PK', pkFmt) + (bal < 0 ? ' <small class="text-success">(Cr)</small>' : '') + '</td></tr>';
                    });
                }
                html += '</tbody></table></div>';
                var balClass = bal > 0 ? 'ledger-debit' : 'ledger-credit';
                html += '<div class="mt-3 p-3 rounded d-flex justify-content-between align-items-center" style="background:#f8faff;border:1px solid #e0e7ff;">';
                html += '<span class="fw-semibold">Outstanding Balance</span>';
                html += '<strong class="' + balClass + '" style="font-size:1.1rem;">Rs. ' + Math.abs(bal).toLocaleString('en-PK', pkFmt) + (bal < 0 ? ' (Advance)' : '') + '</strong></div>';
                $('#ledgerBody').html(html);
            });
        }

        /* ── Cancel ── */
        function confirmCancel(id, num) {
            cancelInvoiceId = id;
            $('#cancelMsg').html('Cancel invoice <strong>' + escHtml(num) + '</strong>? The ledger entry will be removed.');
            document.getElementById('btnConfirmCancel').onclick = executeCancel;
            if (!cancelModalBS) cancelModalBS = new bootstrap.Modal(document.getElementById('cancelModal'));
            cancelModalBS.show();
        }

        function executeCancel() {
            api('CancelInvoice', { invoiceId: cancelInvoiceId }, function (err, r) {
                cancelModalBS.hide();
                if (err || !r || !r.success) { showToast(r ? r.message : 'Request failed.', 'danger'); return; }
                showToast(r.message, 'success');
                loadInvoices(); loadStats();
            });
        }

        /* ── API ── */
        function api(method, data, cb) {
            $.ajax({
                type: 'POST', url: 'CustomerBilling.aspx/' + method,
                data: JSON.stringify(data),
                contentType: 'application/json; charset=utf-8', dataType: 'json',
                success: function (r) { cb(null, typeof r.d === 'string' ? JSON.parse(r.d) : r.d); },
                error:   function (e) { cb(e.responseText || 'Error', null); }
            });
        }

        /* ── Helpers ── */
        function escHtml(s) {
            if (!s) return '';
            return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
        }
        function escJs(s) {
            if (!s) return '';
            return String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/"/g,'\\"');
        }
        function showToast(msg, type) {
            var icon  = type === 'success' ? 'check-circle' : type === 'warning' ? 'exclamation-triangle' : 'times-circle';
            var bg    = type === 'success' ? '#f0fdf4' : type === 'warning' ? '#fffbeb' : '#fef2f2';
            var color = type === 'success' ? '#15803d' : type === 'warning' ? '#92400e' : '#b91c1c';
            var bdr   = type === 'success' ? '#bbf7d0' : type === 'warning' ? '#fde68a' : '#fecaca';
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
        @keyframes slideUp { from{opacity:0;transform:translateY(10px)} to{opacity:1;transform:translateY(0)} }
    </style>

</asp:Content>
