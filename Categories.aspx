<%@ Page Title="Categories" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Categories.aspx.cs" Inherits="Onfoot_Inventory.Categories" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-left">
            <h4><i class="fas fa-tags me-2 text-primary"></i>Categories</h4>
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="<%: ResolveUrl("~/Default.aspx") %>">Dashboard</a></li>
                    <li class="breadcrumb-item active">Categories</li>
                </ol>
            </nav>
        </div>
        <button class="btn btn-primary" onclick="openAddModal()">
            <i class="fas fa-plus me-1"></i> Add Category
        </button>
    </div>

    <!-- Stats -->
    <div class="row g-3 mb-4">
        <div class="col-sm-6 col-xl-3">
            <div class="stat-card">
                <div class="stat-icon purple"><i class="fas fa-tags"></i></div>
                <div>
                    <div class="stat-label">Total Categories</div>
                    <div class="stat-value" id="statTotal">—</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="stat-card">
                <div class="stat-icon green"><i class="fas fa-check-circle"></i></div>
                <div>
                    <div class="stat-label">Active Categories</div>
                    <div class="stat-value" id="statActive">—</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="stat-card">
                <div class="stat-icon red"><i class="fas fa-times-circle"></i></div>
                <div>
                    <div class="stat-label">Inactive Categories</div>
                    <div class="stat-value" id="statInactive">—</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Table -->
    <div class="table-card fill-height">
        <div class="table-card-header">
            <h6><i class="fas fa-list me-2 text-primary"></i>Category List</h6>
        </div>
        <div class="table-card-body">
            <table id="tblCategories" class="table table-hover w-100">
                <thead>
                    <tr>
                        <th style="width:45px">#</th>
                        <th>Category Name</th>
                        <th>Description</th>
                        <th style="width:90px;text-align:center;">Products</th>
                        <th style="width:90px;text-align:center;">Status</th>
                        <th style="width:130px">Created</th>
                        <th style="width:100px;text-align:center;">Actions</th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
    </div>

</asp:Content>

<asp:Content ID="ScriptsContent" ContentPlaceHolderID="ScriptsContent" runat="server">

    <!-- Add / Edit Modal -->
    <div class="modal fade" id="categoryModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered" style="max-width:480px">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-tag me-2"></i><span id="modalTitle">Add Category</span></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" id="hdnCategoryId" value="0" />

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Category Name <span class="text-danger">*</span></label>
                        <input type="text" id="txtCategoryName" class="form-control"
                               placeholder="e.g. Slipper, Pumps, Heel" maxlength="100" />
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Description</label>
                        <textarea id="txtDescription" class="form-control" rows="3"
                                  placeholder="Optional description..." maxlength="300"></textarea>
                    </div>

                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" id="chkIsActive" checked />
                        <label class="form-check-label" for="chkIsActive">Active</label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times me-1"></i> Cancel
                    </button>
                    <button type="button" id="btnSaveNew" class="btn btn-outline-primary" onclick="saveCategory(true)">
                        <i class="fas fa-plus me-1"></i> Save & New
                    </button>
                    <button type="button" id="btnSave" class="btn btn-primary" onclick="saveCategory(false)">
                        <i class="fas fa-save me-1"></i> Save
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Delete Confirm Modal -->
    <div class="modal fade" id="deleteModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered" style="max-width:400px">
            <div class="modal-content">
                <div class="modal-header" style="background:#b91c1c;">
                    <h5 class="modal-title text-white"><i class="fas fa-trash me-2"></i>Confirm Delete</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center py-4">
                    <div class="mb-3" style="font-size:2.5rem;color:#fca5a5;">
                        <i class="fas fa-exclamation-circle"></i>
                    </div>
                    <p class="mb-1">Are you sure you want to delete:</p>
                    <p class="fw-bold fs-5" id="lblDeleteName"></p>
                    <p class="text-muted small mb-0">Products under this category will not be affected.</p>
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
    <div id="toastContainer" class="toast-container-fixed"></div>

    <script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.7/js/dataTables.bootstrap5.min.js"></script>

    <script>
        var catTable;
        var deleteId = 0;

        $(document).ready(function () {
            catTable = $('#tblCategories').DataTable({
                pageLength: 15,
                language: {
                    search: '',
                    searchPlaceholder: 'Search categories...',
                    emptyTable: "<div class='text-center py-3 text-muted'><i class='fas fa-inbox fa-2x mb-2 d-block'></i>No categories found</div>"
                },
                columnDefs: [{ orderable: false, targets: [6] }],
                dom: "<'row mb-2'<'col-sm-6'l><'col-sm-6'f>><'row'<'col-sm-12'tr>><'row mt-2'<'col-sm-5'i><'col-sm-7'p>>"
            });

            loadStats();
            loadCategories();
        });

        // ── LOAD STATS ────────────────────────────────────────────
        function loadStats() {
            $.ajax({
                type: 'POST',
                url: 'Categories.aspx/GetStats',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: function (res) {
                    var s = JSON.parse(res.d);
                    $('#statTotal').text(s.Total);
                    $('#statActive').text(s.Active);
                    $('#statInactive').text(s.Total - s.Active);
                },
                error: function (xhr) {
                    console.error('GetStats error:', parseError(xhr));
                }
            });
        }

        // ── LOAD TABLE ────────────────────────────────────────────
        function loadCategories() {
            $.ajax({
                type: 'POST',
                url: 'Categories.aspx/GetCategories',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                data: JSON.stringify({ showInactive: true }),
                success: function (res) {
                    var rows = JSON.parse(res.d);
                    catTable.clear();
                    $.each(rows, function (i, c) {
                        var badge   = c.IsActive
                            ? '<span class="badge bg-success">Active</span>'
                            : '<span class="badge bg-secondary">Inactive</span>';
                        var desc    = c.Description ? escHtml(c.Description) : '<span class="text-muted">&mdash;</span>';
                        var actions = '<button class="btn btn-sm btn-outline-primary me-1" onclick="editCategory(' + c.CategoryId + ')" title="Edit"><i class="fas fa-edit"></i></button>'
                                    + '<button class="btn btn-sm btn-outline-danger" onclick="confirmDelete(' + c.CategoryId + ',\'' + escJs(c.CategoryName) + '\')" title="Delete"><i class="fas fa-trash"></i></button>';
                        catTable.row.add([
                            i + 1,
                            '<strong>' + escHtml(c.CategoryName) + '</strong>',
                            desc,
                            '<div class="text-center">' + c.ProductCount + '</div>',
                            '<div class="text-center">' + badge + '</div>',
                            c.CreatedDate,
                            '<div class="text-center">' + actions + '</div>'
                        ]);
                    });
                    catTable.draw();
                },
                error: function (xhr) {
                    showToast('Failed to load categories: ' + parseError(xhr), 'danger');
                }
            });
        }

        // ── ADD MODAL ─────────────────────────────────────────────
        function openAddModal() {
            $('#hdnCategoryId').val('0');
            $('#modalTitle').text('Add Category');
            $('#txtCategoryName').val('');
            $('#txtDescription').val('');
            $('#chkIsActive').prop('checked', true);
            $('#btnSaveNew').show();
            new bootstrap.Modal(document.getElementById('categoryModal')).show();
            setTimeout(function () { $('#txtCategoryName').focus(); }, 400);
        }

        // ── EDIT MODAL ────────────────────────────────────────────
        function editCategory(id) {
            $.ajax({
                type: 'POST',
                url: 'Categories.aspx/GetById',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                data: JSON.stringify({ categoryId: id }),
                success: function (res) {
                    var c = JSON.parse(res.d);
                    if (!c) return;
                    $('#hdnCategoryId').val(c.CategoryId);
                    $('#txtCategoryName').val(c.CategoryName);
                    $('#txtDescription').val(c.Description);
                    $('#chkIsActive').prop('checked', c.IsActive);
                    $('#modalTitle').text('Edit Category');
                    $('#btnSaveNew').hide();
                    new bootstrap.Modal(document.getElementById('categoryModal')).show();
                    setTimeout(function () { $('#txtCategoryName').focus(); }, 400);
                },
                error: function (xhr) {
                    showToast('Failed to load category: ' + parseError(xhr), 'danger');
                }
            });
        }

        // ── SAVE (Insert / Update) ────────────────────────────────
        function saveCategory(andNew) {
            var name = $.trim($('#txtCategoryName').val());
            if (!name) {
                $('#txtCategoryName').addClass('is-invalid');
                setTimeout(function () { $('#txtCategoryName').removeClass('is-invalid'); }, 2500);
                showToast('Category Name is required.', 'warning');
                return;
            }

            var payload = {
                category: {
                    CategoryId:   parseInt($('#hdnCategoryId').val()) || 0,
                    CategoryName: name,
                    Description:  $.trim($('#txtDescription').val()),
                    IsActive:     $('#chkIsActive').is(':checked')
                }
            };

            $('#btnSave, #btnSaveNew').prop('disabled', true);
            $('#btnSave').html('<i class="fas fa-spinner fa-spin me-1"></i> Saving...');

            $.ajax({
                type: 'POST',
                url: 'Categories.aspx/SaveCategory',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                data: JSON.stringify(payload),
                success: function (res) {
                    var r = JSON.parse(res.d);
                    if (r.success) {
                        showToast(r.message, 'success');
                        loadCategories();
                        loadStats();
                        if (andNew) {
                            $('#hdnCategoryId').val('0');
                            $('#modalTitle').text('Add Category');
                            $('#txtCategoryName').val('');
                            $('#txtDescription').val('');
                            $('#chkIsActive').prop('checked', true);
                            setTimeout(function () { $('#txtCategoryName').focus(); }, 100);
                        } else {
                            bootstrap.Modal.getInstance(document.getElementById('categoryModal')).hide();
                        }
                    } else {
                        showToast(r.message, 'danger');
                    }
                },
                error: function (xhr) {
                    showToast('Error: ' + parseError(xhr), 'danger');
                },
                complete: function () {
                    $('#btnSave, #btnSaveNew').prop('disabled', false);
                    $('#btnSave').html('<i class="fas fa-save me-1"></i> Save');
                }
            });
        }

        // ── DELETE ────────────────────────────────────────────────
        function confirmDelete(id, name) {
            deleteId = id;
            $('#lblDeleteName').text('"' + name + '"');
            new bootstrap.Modal(document.getElementById('deleteModal')).show();
        }

        function executeDelete() {
            $('#btnConfirmDelete').prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i> Deleting...');
            $.ajax({
                type: 'POST',
                url: 'Categories.aspx/DeleteCategory',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                data: JSON.stringify({ categoryId: deleteId }),
                success: function (res) {
                    var r = JSON.parse(res.d);
                    bootstrap.Modal.getInstance(document.getElementById('deleteModal')).hide();
                    showToast(r.message, r.success ? 'success' : 'danger');
                    if (r.success) { loadCategories(); loadStats(); }
                },
                error: function (xhr) {
                    showToast('Delete failed: ' + parseError(xhr), 'danger');
                },
                complete: function () {
                    $('#btnConfirmDelete').prop('disabled', false).html('<i class="fas fa-trash me-1"></i> Yes, Delete');
                }
            });
        }

        // ── HELPERS ───────────────────────────────────────────────
        function parseError(xhr) {
            try {
                var json = JSON.parse(xhr.responseText);
                return json.Message || json.message || xhr.statusText;
            } catch (e) {
                return xhr.status + ' ' + xhr.statusText;
            }
        }

        function escHtml(s) { return s ? $('<div>').text(s).html() : ''; }
        function escJs(s)   { return s ? s.replace(/\\/g, '\\\\').replace(/'/g, "\\'") : ''; }

        function showToast(message, type) {
            var colors = { success: '#16a34a', danger: '#dc2626', warning: '#d97706' };
            var icons  = { success: 'fa-check-circle', danger: 'fa-times-circle', warning: 'fa-exclamation-triangle' };
            var color  = colors[type] || colors.danger;
            var icon   = icons[type]  || icons.danger;
            var $t = $(
                '<div class="app-toast toast show mb-2" style="background:#fff;border-left:4px solid ' + color + ';min-width:280px;">' +
                '<div class="d-flex align-items-center toast-body gap-3">' +
                '<i class="fas ' + icon + '" style="color:' + color + ';font-size:1.1rem;"></i>' +
                '<span style="flex:1;font-size:0.875rem;">' + message + '</span>' +
                '<button type="button" class="btn-close btn-close-sm ms-auto"></button>' +
                '</div></div>'
            );
            $('#toastContainer').append($t);
            $t.find('.btn-close').on('click', function () { $t.remove(); });
            setTimeout(function () { $t.fadeOut(400, function () { $t.remove(); }); }, 4000);
        }
    </script>

</asp:Content>
