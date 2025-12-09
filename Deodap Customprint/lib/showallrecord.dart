import 'package:Deodap_Customprint/api_service.dart';
import 'package:Deodap_Customprint/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // Only for Colors and shadows
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

class ShowAllRecordCupertino extends StatefulWidget {
  const ShowAllRecordCupertino({super.key});

  @override
  State<ShowAllRecordCupertino> createState() => _ShowAllRecordCupertinoState();
}

class _ShowAllRecordCupertinoState extends State<ShowAllRecordCupertino>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<Product> _all = [];
  List<Product> _filtered = [];

  bool _loading = true;
  bool _deleting = false;

  // Selection
  bool _selectMode = false;
  final Set<String> _selectedOrderIds = {};
  bool get _isAnythingSelected => _selectedOrderIds.isNotEmpty;

  // Small “toast” overlay (Cupertino-styled)
  OverlayEntry? _toastEntry;

  // FAB-like scale animation for iOS bottom bar button
  late final AnimationController _barCtrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _barScale =
  CurvedAnimation(parent: _barCtrl, curve: Curves.easeOut);

  // ====== Styles (compact, iOS taste) ======
  TextStyle get _titleNav =>
      GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700);
  TextStyle get _pillStyle =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0B90A1));
  TextStyle get _metaStyle =>
      GoogleFonts.inter(fontSize: 12.5, color: CupertinoColors.secondaryLabel);
  TextStyle get _valueStyle =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: CupertinoColors.label);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _barCtrl.dispose();
    _toastEntry?.remove();
    super.dispose();
  }

  // =========================
  // Data
  // =========================
  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final from = DateTime.now().subtract(const Duration(days: 90)).toIso8601String();
      final list = await fetchProducts(fromDate: from);
      _all = list;
      _filtered = List<Product>.from(_all);
    } catch (e) {
      _showErrorDialog('Error loading orders: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySearch(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtered = List<Product>.from(_all));
      return;
    }
    setState(() {
      _filtered = _all.where((p) {
        final uid = p.productUniqueId.toLowerCase();
        final name = p.fullname.toLowerCase();
        final emp = p.mobileNumber.toLowerCase();
        return uid.contains(query) || name.contains(query) || emp.contains(query);
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _applySearch('');
    FocusScope.of(context).unfocus();
  }

  // =========================
  // Selection
  // =========================
  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (_selectMode) {
        _barCtrl.forward();
      } else {
        _selectedOrderIds.clear();
        _barCtrl.reverse();
      }
    });
  }

  void _toggleItem(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _selectAllVisible() {
    setState(() {
      if (_selectedOrderIds.length == _filtered.length) {
        _selectedOrderIds.clear();
      } else {
        _selectedOrderIds
          ..clear()
          ..addAll(_filtered.map((e) => e.productUniqueId));
      }
    });
  }

  // =========================
  // Delete
  // =========================
  Future<void> _deleteOne(Product p) async {
    final ok = await _confirmDelete(
      title: 'Delete Order',
      message:
      'Are you sure you want to delete this order?\n\nOrder ID: ${p.productUniqueId}\nCustomer: ${p.fullname}',
      destructive: true,
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    _showBlockingLoader('Deleting order…');
    try {
      final success = await deleteProductById(p.productId);
      Navigator.of(context).pop(); // close loader
      if (success) {
        setState(() {
          _all.removeWhere((e) => e.productUniqueId == p.productUniqueId);
          _filtered.removeWhere((e) => e.productUniqueId == p.productUniqueId);
        });
        _toast('Order "${p.productUniqueId}" deleted');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('Failed to delete order: $e');
    } finally {
      setState(() => _deleting = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedOrderIds.isEmpty) {
      _toast('No orders selected', error: true);
      return;
    }
    final ok = await _confirmDelete(
      title: 'Delete Selected',
      message: 'Are you sure you want to delete ${_selectedOrderIds.length} selected order(s)?',
      destructive: true,
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    _showBlockingLoader('Deleting ${_selectedOrderIds.length} orders…');

    try {
      final productIds = _all
          .where((p) => _selectedOrderIds.contains(p.productUniqueId))
          .map((p) => p.productId)
          .where((id) => id.isNotEmpty)
          .toList();

      final result = await deleteMultipleProducts(productIds);
      Navigator.of(context).pop(); // close loader

      setState(() {
        _all.removeWhere((p) => _selectedOrderIds.contains(p.productUniqueId));
        _filtered.removeWhere((p) => _selectedOrderIds.contains(p.productUniqueId));
        _selectedOrderIds.clear();
        _selectMode = false;
        _barCtrl.reverse();
      });

      if ((result['fail_count'] ?? 0) == 0) {
        _toast('${result['success_count']} orders deleted');
      } else {
        _showErrorDialog(
            'Deleted: ${result['success_count']}, Failed: ${result['fail_count']}\n${(result['errors'] as List).join('\n')}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('Failed to delete orders: $e');
    } finally {
      setState(() => _deleting = false);
    }
  }

  // =========================
  // UI Helpers
  // =========================
  Future<bool?> _confirmDelete({
    required String title,
    required String message,
    bool destructive = false,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(message, style: GoogleFonts.inter(height: 1.25)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showBlockingLoader(String msg) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: CupertinoAlertDialog(
          content: Column(
            children: [
              const SizedBox(height: 8),
              const CupertinoActivityIndicator(),
              const SizedBox(height: 12),
              Text(msg, style: GoogleFonts.inter()),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg, {bool error = false}) {
    _toastEntry?.remove();
    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
        child: _CupertinoToast(
          message: msg,
          error: error,
        ),
      ),
    );
    Overlay.of(context).insert(_toastEntry!);
    Future.delayed(const Duration(seconds: 2), () => _toastEntry?.remove());
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Error', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(message, style: GoogleFonts.inter(height: 1.25)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.inter()),
          )
        ],
      ),
    );
  }

  String _humanizeTime(String ts) {
    try {
      final dt = DateTime.parse(ts);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return ts;
    }
  }

  void _openImage(String? url) {
    if (url == null || url.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.9),
      pageBuilder: (c, _, __) => Stack(
        children: [
          Positioned.fill(
            child: PhotoView(
              imageProvider: NetworkImage(url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  color: CupertinoColors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _selectMode ? '${_selectedOrderIds.length} selected' : 'Order History',
          style: _titleNav,
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (_selectMode) {
              _toggleSelectMode();
            } else {
              Navigator.pop(context);
            }
          },
          child: Icon(_selectMode ? CupertinoIcons.xmark : CupertinoIcons.back),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectMode)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _selectAllVisible,
                child: const Icon(CupertinoIcons.checkmark_seal),
              )
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _loadAll,
                child: const Icon(CupertinoIcons.refresh),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _toggleSelectMode,
              child: Icon(
                _selectMode
                    ? CupertinoIcons.square_list
                    : CupertinoIcons.check_mark_circled,
              ),
            ),
          ],
        ),
        backgroundColor: CupertinoColors.systemGrey6,
        border: null,
      ),
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              CupertinoSliverRefreshControl(onRefresh: _loadAll),

              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: _SearchBarCupertino(
                    controller: _searchController,
                    onChanged: _applySearch,
                    onClear: _clearSearch,
                  ),
                ),
              ),

              // Chip: count
              if (!_loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x110B90A1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x220B90A1)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(CupertinoIcons.list_bullet, size: 16, color: Color(0xFF0B90A1)),
                          const SizedBox(width: 6),
                          Text('${_filtered.length} orders found', style: _pillStyle),
                        ]),
                      ),
                    ),
                  ),
                ),

              // Content
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CupertinoActivityIndicator(radius: 14)),
                )
              else if (_filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
                  sliver: SliverList.separated(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final p = _filtered[i];
                      final selected = _selectedOrderIds.contains(p.productUniqueId);
                      return _orderCell(p, selected);
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                  ),
                ),
            ],
          ),

          // Bottom delete bar (iOS-style) when selecting
          if (_selectMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ScaleTransition(
                scale: _barScale,
                child: _BottomBarCupertino(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    onPressed: _isAnythingSelected && !_deleting ? _deleteSelected : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.trash, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Delete (${_selectedOrderIds.length})',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // Widgets
  // =========================
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.tray, size: 56, color: CupertinoColors.systemGrey),
            const SizedBox(height: 12),
            Text('No orders found',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700, color: CupertinoColors.secondaryLabel)),
            const SizedBox(height: 6),
            Text('Pull to refresh or change your search',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }

  Widget _orderCell(Product p, bool selected) {
    final radius = BorderRadius.circular(14);
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: radius,
        border: Border.all(
          color: selected ? const Color(0xFF0B90A1) : CupertinoColors.separator,
          width: selected ? 1.6 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        borderRadius: radius,
        onPressed: () => _selectMode ? _toggleItem(p.productUniqueId) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID chip
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B90A1), Color(0xFF0A7B8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#${p.productId}',
                  style: GoogleFonts.inter(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Middle details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.productUniqueId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.label,
                      )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.person_solid, size: 13, color: CupertinoColors.systemGrey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.fullname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _valueStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.number, size: 13, color: CupertinoColors.systemGrey),
                      const SizedBox(width: 6),
                      Text('EMP: ${p.mobileNumber}', style: _metaStyle),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.time, size: 13, color: CupertinoColors.systemGrey),
                      const SizedBox(width: 6),
                      Text(_humanizeTime(p.createdAt), style: _metaStyle),
                    ],
                  ),
                ],
              ),
            ),

            // Image + quick delete
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openImage(p.productImage),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 78,
                      height: 78,
                      color: CupertinoColors.systemGrey6,
                      child: (p.productImage == null || p.productImage!.isEmpty)
                          ? const Icon(CupertinoIcons.photo_on_rectangle,
                          color: CupertinoColors.systemGrey, size: 26)
                          : Image.network(
                        p.productImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(CupertinoIcons.exclamationmark_triangle,
                              color: CupertinoColors.systemGrey, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_selectMode) ...[
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    color: CupertinoColors.systemRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    onPressed: _deleting ? null : () => _deleteOne(p),
                    child: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed, size: 18),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// Small Cupertino Widgets
// =========================

class _SearchBarCupertino extends StatelessWidget {
  const _SearchBarCupertino({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.search, color: CupertinoColors.activeBlue, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: CupertinoTextField.borderless(
              controller: controller,
              placeholder: 'Search by Order ID, Customer, or Employee Code…',
              onChanged: onChanged,
              style: GoogleFonts.inter(fontSize: 15, color: CupertinoColors.label),
              placeholderStyle: GoogleFonts.inter(
                fontSize: 14,
                color: CupertinoColors.placeholderText,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            CupertinoButton(
              padding: const EdgeInsets.all(4),
              minSize: 26,
              onPressed: onClear,
              child: const Icon(CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.systemGrey, size: 18),
            ),
        ],
      ),
    );
  }
}

class _BottomBarCupertino extends StatelessWidget {
  const _BottomBarCupertino({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + bottomInset),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: const Border(
          top: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CupertinoToast extends StatelessWidget {
  const _CupertinoToast({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final bg = error ? CupertinoColors.destructiveRed : const Color(0xFF0B90A1);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: GoogleFonts.inter(
              color: CupertinoColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  error ? CupertinoIcons.exclamationmark_triangle : CupertinoIcons.checkmark_alt,
                  color: CupertinoColors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(message)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
