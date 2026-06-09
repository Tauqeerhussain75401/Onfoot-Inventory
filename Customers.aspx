<%@ Page Title="Customers" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Customers.aspx.cs" Inherits="Onfoot_Inventory.Customers" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css" rel="stylesheet" />
    <link href="https://cdn.datatables.net/responsive/2.5.0/css/responsive.bootstrap5.min.css" rel="stylesheet" />
    <style>
        #tblCustomers { border-collapse: separate; border-spacing: 0; table-layout: fixed; width: 100% !important; }
        #tblCustomers thead th {
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
        #tblCustomers tbody td {
            padding: 11px 14px;
            vertical-align: middle;
            font-size: 0.895rem;
            border-top: none;
            border-bottom: 1px solid #e8edf5;
        }
        #tblCustomers tbody tr:nth-child(even) td { background: #f7f9ff; }
        #tblCustomers tbody tr:hover td          { background: #eff6ff !important; cursor: pointer; }

        .cust-action-wrap { display:flex; gap:4px; justify-content:center; align-items:center; }
        .btn-grid-edit   { display:inline-flex;align-items:center;justify-content:center;
                           width:30px;height:30px;border-radius:6px;border:none;cursor:pointer;
                           background:#fef3c7;color:#d97706;font-size:0.82rem;transition:background .15s; }
        .btn-grid-edit:hover   { background:#fde68a; }
        .btn-grid-del    { display:inline-flex;align-items:center;justify-content:center;
                           width:30px;height:30px;border-radius:6px;border:none;cursor:pointer;
                           background:#fee2e2;color:#dc2626;font-size:0.82rem;transition:background .15s; }
        .btn-grid-del:hover    { background:#fecaca; }

        .balance-positive { color:#16a34a; font-weight:700; }
        .balance-zero     { color:#94a3b8; }

        .cust-shop-name { font-weight:600; color:var(--text-main); }
        .cust-person    { font-size:0.82rem; color:var(--text-muted); }
    </style>
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-left">
            <h4><i class="fas fa-store-alt me-2 text-primary"></i>B2B Customers</h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="<%: ResolveUrl("~/") %>">Dashboard</a></li>
                    <li class="breadcrumb-item active">Customers</li>
                </ol>
            </nav>
        </div>
        <div class="d-flex gap-2">
            <button class="btn btn-outline-secondary btn-sm" onclick="loadCustomers()" title="Refresh">
                <i class="fas fa-sync-alt me-1"></i> Refresh
            </button>
            <button class="btn btn-primary" onclick="openAddCustomer()">
                <i class="fas fa-plus me-1"></i> Add Customer
            </button>
        </div>
    </div>

    <!-- Stat Cards -->
    <div class="row g-3 mb-4">
        <div class="col-xl-4 col-sm-6">
            <div class="stat-card" style="border-top:3px solid #2563eb;">
                <div class="stat-icon blue"><i class="fas fa-users"></i></div>
                <div>
                    <div class="stat-label">Total Customers</div>
                    <div class="stat-value" id="statTotal">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-4 col-sm-6">
            <div class="stat-card" style="border-top:3px solid #16a34a;">
                <div class="stat-icon green"><i class="fas fa-user-check"></i></div>
                <div>
                    <div class="stat-label">Active</div>
                    <div class="stat-value" id="statActive">—</div>
                </div>
            </div>
        </div>
        <div class="col-xl-4 col-sm-6">
            <div class="stat-card" style="border-top:3px solid #7c3aed;">
                <div class="stat-icon purple"><i class="fas fa-wallet"></i></div>
                <div>
                    <div class="stat-label">Total Opening Balance</div>
                    <div class="stat-value" id="statBalance">—</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Customers Table -->
    <div class="table-card">
        <div class="table-card-body p-0">
            <div class="table-responsive">
                <table id="tblCustomers" class="table mb-0 w-100">
                    <thead>
                        <tr>
                            <th style="width:4%">#</th>
                            <th style="width:18%">Shop Name</th>
                            <th style="width:14%">Person Name</th>
                            <th style="width:12%">Contact No 1</th>
                            <th style="width:11%">Contact No 2</th>
                            <th style="width:18%">City / Address</th>
                            <th style="width:10%">Opening Bal.</th>
                            <th style="width:7%">Status</th>
                            <th style="width:6%">Actions</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="ModalsContent" ContentPlaceHolderID="ScriptsContent" runat="server">

    <!-- ========== ADD / EDIT CUSTOMER MODAL ========== -->
    <div class="modal fade" id="customerModal" tabindex="-1" data-bs-backdrop="static" aria-labelledby="customerModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px;overflow:hidden">
                <div class="modal-header border-0 pb-0" style="background:linear-gradient(135deg,#eff6ff,#dbeafe);padding:20px 24px 12px">
                    <div class="d-flex align-items-center gap-3">
                        <div class="module-icon blue" style="width:38px;height:38px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:1rem;background:#dbeafe;color:var(--primary)">
                            <i class="fas fa-store-alt"></i>
                        </div>
                        <div>
                            <h5 class="modal-title mb-0" id="customerModalLabel" style="font-size:1rem;font-weight:700;">Add B2B Customer</h5>
                            <p class="mb-0" style="font-size:0.75rem;color:var(--text-muted)">Mall / local market customer details</p>
                        </div>
                    </div>
                    <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal"></button>
                </div>

                <div class="modal-body" style="padding:20px 24px">
                    <input type="hidden" id="custId" value="0" />

                    <div class="row g-3">
                        <!-- Shop Name -->
                        <div class="col-md-6">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">
                                Shop Name <span class="text-danger">*</span>
                            </label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text"><i class="fas fa-store"></i></span>
                                <input type="text" id="custShopName" class="form-control"
                                       placeholder="e.g. Bata Gulshan, Metro Shoes" maxlength="200" />
                            </div>
                        </div>

                        <!-- Person Name -->
                        <div class="col-md-6">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">
                                Person Name <span class="text-danger">*</span>
                            </label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text"><i class="fas fa-user"></i></span>
                                <input type="text" id="custPersonName" class="form-control"
                                       placeholder="Contact person's full name" maxlength="150" />
                            </div>
                        </div>

                        <!-- Contact No 1 -->
                        <div class="col-md-4">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">
                                Contact No 1 <span class="text-danger">*</span>
                            </label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text"><i class="fas fa-phone"></i></span>
                                <input type="text" id="custContact1" class="form-control"
                                       placeholder="+92-xxx-xxxxxxx" maxlength="30" />
                            </div>
                        </div>

                        <!-- Contact No 2 -->
                        <div class="col-md-4">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">
                                Contact No 2
                            </label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text"><i class="fas fa-phone-alt"></i></span>
                                <input type="text" id="custContact2" class="form-control"
                                       placeholder="Alternate number" maxlength="30" />
                            </div>
                        </div>

                        <!-- Opening Balance -->
                        <div class="col-md-4">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">
                                Opening Balance <span class="text-danger">*</span>
                            </label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text">Rs.</span>
                                <input type="number" id="custOpeningBalance" class="form-control"
                                       placeholder="0.00" min="0" step="0.01" value="0" />
                            </div>
                        </div>

                        <!-- Shop Address -->
                        <div class="col-md-8">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">
                                Shop Address <span class="text-danger">*</span>
                            </label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text"><i class="fas fa-map-marker-alt"></i></span>
                                <input type="text" id="custShopAddress" class="form-control"
                                       placeholder="Shop address, floor, mall name" maxlength="500" />
                            </div>
                        </div>

                        <!-- City -->
                        <div class="col-md-4">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">City</label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text"><i class="fas fa-city"></i></span>
                                <input type="text" id="custCity" class="form-control"
                                       placeholder="e.g. Karachi, Lahore" maxlength="100" />
                            </div>
                        </div>

                        <!-- Email -->
                        <div class="col-md-6">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">Email</label>
                            <div class="input-group input-group-sm">
                                <span class="input-group-text"><i class="fas fa-envelope"></i></span>
                                <input type="email" id="custEmail" class="form-control"
                                       placeholder="customer@example.com" maxlength="150" />
                            </div>
                        </div>

                        <!-- Notes -->
                        <div class="col-md-6">
                            <label class="form-label" style="font-size:0.82rem;font-weight:600;">Notes</label>
                            <textarea id="custNotes" class="form-control form-control-sm" rows="2"
                                      placeholder="Any additional notes about this customer" maxlength="500"></textarea>
                        </div>

                        <!-- Active toggle -->
                        <div class="col-12">
                            <div class="form-check form-switch mb-0">
                                <input class="form-check-input" type="checkbox" id="custActive" checked />
                                <label class="form-check-label" for="custActive" style="font-size:0.82rem;">Active</label>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal-footer border-0 pt-0" style="padding:12px 24px 20px;gap:8px">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i> Cancel
                    </button>
                    <button type="button" class="btn btn-primary btn-sm px-4" id="btnSaveCustomer" onclick="saveCustomer()">
                        <i class="fas fa-save me-1"></i> Save Customer
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Delete Confirm Modal -->
    <div class="modal fade" id="deleteCustomerModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" style="max-width:380px">
            <div class="modal-content border-0 shadow-lg" style="border-radius:14px">
                <div class="modal-body text-center" style="padding:28px 24px 16px">
                    <div style="width:52px;height:52px;border-radius:50%;background:#fef2f2;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;font-size:1.3rem;color:#dc2626">
                        <i class="fas fa-trash-alt"></i>
                    </div>
                    <h5 style="font-size:0.95rem;font-weight:700;margin-bottom:6px;">Delete Customer</h5>
                    <p id="deleteCustomerMsg" class="text-muted mb-0" style="font-size:0.82rem;">Are you sure?</p>
                </div>
                <div class="modal-footer border-0 justify-content-center pb-4" style="gap:8px">
                    <button type="button" class="btn btn-light btn-sm px-4" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-danger btn-sm px-4" id="btnConfirmDeleteCustomer">
                        <i class="fas fa-trash-alt me-1"></i> Delete
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
        var custTable;
        var custModalBS, deleteModalBS;
        var pkFmt = { minimumFractionDigits: 2 };

        /* ============================================================ INIT */
        $(document).ready(function () {
            initTable();
            loadStats();
            loadCustomers();
        });

        function initTable() {
            custTable = $('#tblCustomers').DataTable({
                responsive:     false,
                pageLength:     20,
                lengthMenu:     [[10, 20, 50, 100], [10, 20, 50, 100]],
                scrollY:        '520px',
                scrollCollapse: false,
                columnDefs: [
                    { orderable: false, targets: [0, 8] },
                    { className: 'text-center', targets: [0, 7, 8] }
                ],
                order: [[1, 'asc']],
                language: {
                    search:            '',
                    searchPlaceholder: 'Search customers...',
                    emptyTable:        "<div class='text-center py-5 text-muted'><i class='fas fa-users fa-2x mb-3 d-block opacity-50'></i><div style='font-size:0.95rem;'>No customers found</div></div>",
                    lengthMenu:        "Show _MENU_ entries",
                    info:              "Showing _START_ - _END_ of _TOTAL_ customers",
                    paginate:          { previous: '<i class="fas fa-chevron-left"></i>', next: '<i class="fas fa-chevron-right"></i>' }
                },
                dom: "<'row align-items-center px-3 pt-3 pb-2'<'col-sm-4'l><'col-sm-8'f>><'row'<'col-sm-12'tr>><'row align-items-center px-3 pt-2 pb-3'<'col-sm-5 text-muted small'i><'col-sm-7'p>>"
            });
        }

        /* ============================================================ LOAD */
        function loadStats() {
            api('GetCustomerStats', {}, function (err, d) {
                if (!d) return;
                $('#statTotal').text(d.Total);
                $('#statActive').text(d.Active);
                $('#statBalance').text('Rs. ' + parseFloat(d.TotalOpeningBalance).toLocaleString('en-PK', pkFmt));
            });
        }

        function loadCustomers() {
            api('GetCustomers', {}, function (err, list) {
                custTable.clear();
                if (err || !list) { custTable.draw(); return; }
                $.each(list, function (i, c) {
                    var statusBadge = c.IsActive
                        ? '<span class="badge-active">Active</span>'
                        : '<span class="badge-inactive">Inactive</span>';

                    var contact2 = c.ContactNo2
                        ? escHtml(c.ContactNo2)
                        : '<span class="text-muted">—</span>';

                    var cityAddr = c.City
                        ? '<span style="font-size:0.82rem;">' + escHtml(c.City) + '</span>'
                        : '<span class="text-muted" style="font-size:0.82rem;">—</span>';

                    var bal = parseFloat(c.OpeningBalance);
                    var balHtml = bal > 0
                        ? '<span class="balance-positive">Rs. ' + bal.toLocaleString('en-PK', pkFmt) + '</span>'
                        : '<span class="balance-zero">Rs. 0.00</span>';

                    var shopCell = '<div class="cust-shop-name">' + escHtml(c.ShopName) + '</div>';
                    var personCell = '<div class="cust-person">' + escHtml(c.PersonName) + '</div>';

                    var actions = '<div class="cust-action-wrap">'
                        + '<button class="btn-grid-edit" onclick="editCustomer(' + c.CustomerId + ')" title="Edit"><i class="fas fa-pencil-alt"></i></button>'
                        + '<button class="btn-grid-del"  onclick="confirmDeleteCustomer(' + c.CustomerId + ',\'' + escJs(c.ShopName) + '\')" title="Delete"><i class="fas fa-trash-alt"></i></button>'
                        + '</div>';

                    custTable.row.add([
                        i + 1,
                        shopCell,
                        personCell,
                        escHtml(c.ContactNo1),
                        contact2,
                        cityAddr,
                        balHtml,
                        statusBadge,
                        actions
                    ]);
                });
                custTable.draw();
            });
        }

        /* ============================================================ ADD */
        function openAddCustomer() {
            resetForm();
            $('#customerModalLabel').text('Add B2B Customer');
            if (!custModalBS) custModalBS = new bootstrap.Modal(document.getElementById('customerModal'));
            custModalBS.show();
            setTimeout(function () { $('#custShopName').focus(); }, 300);
        }

        /* ============================================================ EDIT */
        function editCustomer(id) {
            api('GetCustomerById', { customerId: id }, function (err, c) {
                if (err || !c) { showToast('Could not load customer.', 'danger'); return; }
                resetForm();
                $('#custId').val(c.CustomerId);
                $('#custShopName').val(c.ShopName);
                $('#custPersonName').val(c.PersonName);
                $('#custContact1').val(c.ContactNo1);
                $('#custContact2').val(c.ContactNo2 || '');
                $('#custShopAddress').val(c.ShopAddress);
                $('#custOpeningBalance').val(c.OpeningBalance);
                $('#custCity').val(c.City || '');
                $('#custEmail').val(c.Email || '');
                $('#custNotes').val(c.Notes || '');
                $('#custActive').prop('checked', c.IsActive);
                $('#customerModalLabel').text('Edit B2B Customer');
                if (!custModalBS) custModalBS = new bootstrap.Modal(document.getElementById('customerModal'));
                custModalBS.show();
            });
        }

        /* ============================================================ SAVE */
        function saveCustomer() {
            var shopName   = $.trim($('#custShopName').val());
            var personName = $.trim($('#custPersonName').val());
            var contact1   = $.trim($('#custContact1').val());
            var contact2   = $.trim($('#custContact2').val());
            var address    = $.trim($('#custShopAddress').val());
            var balance    = parseFloat($('#custOpeningBalance').val()) || 0;

            if (!shopName)   { shakeField('#custShopName');   showToast('Shop Name is required.', 'warning');     return; }
            if (!personName) { shakeField('#custPersonName'); showToast('Person Name is required.', 'warning');   return; }
            if (!contact1)   { shakeField('#custContact1');   showToast('Contact No 1 is required.', 'warning');  return; }

            if (!address)    { shakeField('#custShopAddress');showToast('Shop Address is required.', 'warning');  return; }

            var payload = {
                customer: {
                    CustomerId:     parseInt($('#custId').val()),
                    ShopName:       shopName,
                    PersonName:     personName,
                    ContactNo1:     contact1,
                    ContactNo2:     contact2,
                    ShopAddress:    address,
                    OpeningBalance: balance,
                    City:           $.trim($('#custCity').val()),
                    Email:          $.trim($('#custEmail').val()),
                    Notes:          $.trim($('#custNotes').val()),
                    IsActive:       $('#custActive').prop('checked')
                }
            };

            var $btn = $('#btnSaveCustomer');
            $btn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i> Saving...');

            api('SaveCustomer', payload, function (err, r) {
                $btn.prop('disabled', false).html('<i class="fas fa-save me-1"></i> Save Customer');
                if (err || !r) { showToast('Request failed.', 'danger'); return; }
                if (!r.success) { showToast(r.message, 'danger'); return; }
                custModalBS.hide();
                showToast(r.message, 'success');
                loadCustomers();
                loadStats();
            });
        }

        /* ============================================================ DELETE */
        function confirmDeleteCustomer(id, name) {
            document.getElementById('deleteCustomerMsg').innerHTML =
                'Are you sure you want to delete <strong>' + escHtml(name) + '</strong>? This action cannot be undone.';
            document.getElementById('btnConfirmDeleteCustomer').onclick = function () {
                doDeleteCustomer(id);
            };
            if (!deleteModalBS) deleteModalBS = new bootstrap.Modal(document.getElementById('deleteCustomerModal'));
            deleteModalBS.show();
        }

        function doDeleteCustomer(id) {
            api('DeleteCustomer', { customerId: id }, function (err, r) {
                deleteModalBS.hide();
                if (err || !r) { showToast('Request failed.', 'danger'); return; }
                if (!r.success) { showToast(r.message, 'danger'); return; }
                showToast(r.message, 'success');
                loadCustomers();
                loadStats();
            });
        }

        /* ============================================================ HELPERS */
        function resetForm() {
            $('#custId').val(0);
            $('#custShopName, #custPersonName, #custContact1, #custContact2').val('');
            $('#custShopAddress, #custCity, #custEmail, #custNotes').val('');
            $('#custOpeningBalance').val('0');
            $('#custActive').prop('checked', true);
        }

        function api(method, data, cb) {
            $.ajax({
                type: 'POST',
                url: 'Customers.aspx/' + method,
                data: JSON.stringify(data),
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: function (r) {
                    cb(null, typeof r.d === 'string' ? JSON.parse(r.d) : r.d);
                },
                error: function (e) {
                    cb(e.responseText || 'Error', null);
                }
            });
        }

        function escHtml(s) {
            if (!s) return '';
            return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
        }

        function escJs(s) {
            if (!s) return '';
            return String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/"/g,'\\"');
        }

        function shakeField(sel) {
            var $el = $(sel);
            $el.addClass('is-invalid');
            setTimeout(function () { $el.removeClass('is-invalid'); }, 2000);
        }

        /* ============================================================ TOAST */
        function showToast(msg, type) {
            var icon = type === 'success' ? 'check-circle' : type === 'warning' ? 'exclamation-triangle' : 'times-circle';
            var bg   = type === 'success' ? '#f0fdf4' : type === 'warning' ? '#fffbeb' : '#fef2f2';
            var color= type === 'success' ? '#15803d' : type === 'warning' ? '#92400e' : '#b91c1c';
            var border=type === 'success' ? '#bbf7d0' : type === 'warning' ? '#fde68a' : '#fecaca';

            var id = 'toast_' + Date.now();
            var html = '<div id="' + id + '" style="position:fixed;bottom:24px;right:24px;z-index:9999;'
                     + 'min-width:280px;border-radius:10px;padding:12px 18px;font-size:0.84rem;font-weight:600;'
                     + 'background:' + bg + ';color:' + color + ';border:1px solid ' + border + ';'
                     + 'box-shadow:0 8px 24px rgba(0,0,0,0.12);animation:slideUp 0.25s ease;">'
                     + '<i class="fas fa-' + icon + ' me-2"></i>' + escHtml(msg) + '</div>';
            $('body').append(html);
            setTimeout(function () { $('#' + id).fadeOut(300, function () { $(this).remove(); }); }, 3200);
        }

        /* ============================================================ ENTER KEY */
        $(document).on('keydown', '#customerModal input:not([type=number])', function (e) {
            if (e.key === 'Enter') saveCustomer();
        });
    </script>

    <style>
        @keyframes slideUp {
            from { opacity: 0; transform: translateY(10px); }
            to   { opacity: 1; transform: translateY(0); }
        }
    </style>

</asp:Content>
