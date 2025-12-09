import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter/services.dart';
class AwaitedOrdersScreen extends StatefulWidget {
  @override
  State<AwaitedOrdersScreen> createState() => _AwaitedOrdersScreenState();
}

class _AwaitedOrdersScreenState extends State<AwaitedOrdersScreen>
    with TickerProviderStateMixin {
  // ---- Replaces TabController/TabBarView ----
  late final PageController _pageController;

  // Per-tab scroll controllers (for Up/Down buttons)
  final List<ScrollController> _scrollControllers =
  List.generate(3, (_) => ScrollController());

  // UI state
  final List<TextEditingController> _searchControllers =
  List.generate(3, (_) => TextEditingController());
  bool _isAscending = true;
  bool _showSearchBar = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);

    // Keep segmented control in sync while swiping (near-instant updates).
    _pageController.addListener(() {
      final double? p = _pageController.page;
      if (p == null) return;
      final int nearest = p.round(); // closest page while dragging
      if (nearest != _currentTabIndex) {
        setState(() => _currentTabIndex = nearest);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _searchControllers) {
      c.dispose();
    }
    for (final sc in _scrollControllers) {
      sc.dispose();
    }
    super.dispose();
  }

  // ---- Demo data (unchanged) ----
  final List<Map<String, dynamic>> pendingInwardData = [
    {
      'orderNo': '#135-8617-1027',
      'orderDate': '04/10/25 12:22:02 AM',
      'totalParts': 2,
      'secondaryPartsCreated': 1,
      'secondaryPartsPickedUp': 1,
      'secondaryPartsReceived': 0,
      'status': 'Pending Inward',
    },
    {
      'orderNo': '#135-7387-2514',
      'orderDate': '04/10/25 09:32:01 AM',
      'totalParts': 3,
      'secondaryPartsCreated': 2,
      'secondaryPartsPickedUp': 2,
      'secondaryPartsReceived': 1,
      'status': 'Pending Inward',
    },
    {
      'orderNo': '#135-0620-9737',
      'orderDate': '05/10/25 12:58:01 AM',
      'totalParts': 2,
      'secondaryPartsCreated': 1,
      'secondaryPartsPickedUp': 1,
      'secondaryPartsReceived': 0,
      'status': 'Pending Inward',
    },
  ];

  final List<Map<String, dynamic>> pendingPickupData = [
    {
      'orderNo': '#135-6414-6819',
      'orderDate': '08/10/25 03:46:02 AM',
      'totalParts': 3,
      'secondaryPartsCreated': 2,
      'secondaryPartsPickedUp': 2,
      'secondaryPartsReceived': 1,
      'status': 'Pending Pickup',
    },
    {
      'orderNo': '#135-7625-3557',
      'orderDate': '08/10/25 09:26:02 AM',
      'totalParts': 2,
      'secondaryPartsCreated': 1,
      'secondaryPartsPickedUp': 1,
      'secondaryPartsReceived': 0,
      'status': 'Pending Pickup',
    },
  ];

  final List<Map<String, dynamic>> pendingPartCreationData = [
    {
      'orderNo': '#135-9988-4455',
      'orderDate': '09/10/25 11:15:30 AM',
      'totalParts': 4,
      'secondaryPartsCreated': 0,
      'secondaryPartsPickedUp': 0,
      'secondaryPartsReceived': 0,
      'status': 'Pending Part Creation',
    },
    {
      'orderNo': '#135-2233-7788',
      'orderDate': '09/10/25 02:45:15 PM',
      'totalParts': 1,
      'secondaryPartsCreated': 0,
      'secondaryPartsPickedUp': 0,
      'secondaryPartsReceived': 0,
      'status': 'Pending Part Creation',
    },
  ];

  // ---- Helpers ----
  DateTime parseOrderDate(String dateString) {
    try {
      final parts = dateString.split(' ');
      if (parts.length >= 3) {
        final datePart = parts[0];
        final timePart = parts[1];
        final amPm = parts[2].toUpperCase();

        final dc = datePart.split('/');
        if (dc.length == 3) {
          int day = int.parse(dc[0]);
          int month = int.parse(dc[1]);
          int year = int.parse(dc[2]);
          if (year < 100) year += 2000;

          final tc = timePart.split(':');
          if (tc.length == 3) {
            int hour = int.parse(tc[0]);
            final minute = int.parse(tc[1]);
            final second = int.parse(tc[2]);

            if (amPm == 'PM' && hour != 12) hour += 12;
            if (amPm == 'AM' && hour == 12) hour = 0;

            return DateTime(year, month, day, hour, minute, second);
          }
        }
      }
    } catch (_) {}
    return DateTime.now();
  }

  List<Map<String, dynamic>> getFilteredData(int tabIndex, String query) {
    List<Map<String, dynamic>> data;
    switch (tabIndex) {
      case 0:
        data = List.from(pendingInwardData);
        break;
      case 1:
        data = List.from(pendingPickupData);
        break;
      case 2:
        data = List.from(pendingPartCreationData);
        break;
      default:
        data = [];
    }

    data.sort((a, b) {
      final aD = parseOrderDate(a['orderDate']);
      final bD = parseOrderDate(b['orderDate']);
      return _isAscending ? aD.compareTo(bD) : bD.compareTo(aD);
    });

    if (query.isEmpty) return data;

    final q = query.toLowerCase();
    return data.where((item) {
      return item['orderNo'].toString().toLowerCase().contains(q) ||
          item['orderDate'].toString().toLowerCase().contains(q);
    }).toList();
  }

  int getTabCount(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return pendingInwardData.length;
      case 1:
        return pendingPickupData.length;
      case 2:
        return pendingPartCreationData.length;
      default:
        return 0;
    }
  }

  // ---- Dialogs / Buttons ----
  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    final screenWidth = MediaQuery.of(context).size.width;

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Order Details',
          style: GoogleFonts.roboto(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
            decoration: TextDecoration.none,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: screenWidth * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenWidth * 0.02),
              _buildDetailRow('Order No:', order['orderNo'], isOrderNumber: true),
              _buildDetailRow('Date:', order['orderDate']),
              _buildDetailRow('Status:', order['status']),
              _buildDetailRow('Total Parts:', '${order['totalParts']}'),
              _buildDetailRow('Sec. Created:', '${order['secondaryPartsCreated']}'),
              _buildDetailRow('Sec. Picked Up:', '${order['secondaryPartsPickedUp']}'),
              _buildDetailRow('Sec. Received:', '${order['secondaryPartsReceived']}'),
              SizedBox(height: screenWidth * 0.04),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: _buildActionButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        _printOrder(order);
                      },
                      icon: CupertinoIcons.printer,
                      label: 'Print',
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Flexible(
                    child: _buildActionButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        _showOrderList(order);
                      },
                      icon: CupertinoIcons.list_bullet,
                      label: 'List',
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Flexible(
                    child: _buildActionButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        _showOrderSettings(order);
                      },
                      icon: CupertinoIcons.gear,
                      label: 'Settings',
                      color: CupertinoColors.systemOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'Close',
              style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600, decoration: TextDecoration.none),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.03, horizontal: screenWidth * 0.02),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: screenWidth * 0.055, color: color),
            SizedBox(height: screenWidth * 0.01),
            Text(
              label,
              style: GoogleFonts.roboto(
                  fontSize: screenWidth * 0.03,
                  color: color,
                  decoration: TextDecoration.none),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _printOrder(Map<String, dynamic> order) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Print Order'),
        content: Text('Printing order ${order['orderNo']}...'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showOrderList(Map<String, dynamic> order) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Order List'),
        content: Text('Showing list for order ${order['orderNo']}...'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showOrderSettings(Map<String, dynamic> order) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Order Settings'),
        content: Text('Settings for order ${order['orderNo']}...'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isOrderNumber = false}) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.3,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: screenWidth * 0.032,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: isOrderNumber
                  ? EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: screenWidth * 0.01)
                  : EdgeInsets.zero,
              decoration: isOrderNumber
                  ? BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                  CupertinoColors.activeBlue.withOpacity(0.25),
                  width: 1,
                ),
              )
                  : null,
              child: Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: screenWidth * 0.032,
                  fontWeight:
                  isOrderNumber ? FontWeight.w700 : FontWeight.w400,
                  color: isOrderNumber
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Search + list ----
  Widget buildSearchBar(int tabIndex) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: _showSearchBar ? screenWidth * 0.175 : 0,
      child: _showSearchBar
          ? Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: CupertinoTextField(
          controller: _searchControllers[tabIndex],
          placeholder: 'Search orders...',
          prefix: Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.02),
            child: Icon(CupertinoIcons.search,
                color: CupertinoColors.systemGrey,
                size: screenWidth * 0.05),
          ),
          style: GoogleFonts.roboto(
              fontSize: screenWidth * 0.035,
              decoration: TextDecoration.none),
          onChanged: (_) => setState(() {}),
          clearButtonMode: OverlayVisibilityMode.editing,
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget buildDataTable(
      List<Map<String, dynamic>> data, ScrollController controller) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.tray,
                size: screenWidth * 0.16, color: CupertinoColors.systemGrey),
            SizedBox(height: screenWidth * 0.04),
            Text(
              'No orders found',
              style: GoogleFonts.roboto(
                fontSize: screenWidth * 0.045,
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    }

    // PageView provides constraints, so Column+Scroll below will lay out correctly.
    return SingleChildScrollView(
      controller: controller,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.map(_buildOrderCard).toList(),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GestureDetector(
      onTap: () => _showOrderDetailsDialog(order),
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
        padding: EdgeInsets.all(screenWidth * (isTablet ? 0.04 : 0.03)),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: CupertinoColors.systemGrey4,
                blurRadius: 2,
                offset: Offset(0, 1)),
          ],
        ),
        child:
        isTablet ? _buildTabletLayout(order) : _buildMobileLayout(order),
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic> order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fullDateTime = order['orderDate'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                order['orderNo'],
                style: GoogleFonts.roboto(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.systemIndigo, // Updated for iOS feel
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Text(
              fullDateTime,
              style: GoogleFonts.roboto(
                fontSize: screenWidth * 0.025,
                color: CupertinoColors.systemGrey,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.02),
        Row(
          children: [
            Expanded(child: _buildStatChip('Total', '${order['totalParts']}', CupertinoColors.systemBlue)),
            SizedBox(width: screenWidth * 0.01),
            Expanded(child: _buildStatChip('Sec. Created', '${order['secondaryPartsCreated']}', CupertinoColors.systemPurple)),
            SizedBox(width: screenWidth * 0.01),
            Expanded(child: _buildStatChip('Sec. Picked', '${order['secondaryPartsPickedUp']}', CupertinoColors.systemTeal)),
            SizedBox(width: screenWidth * 0.01),
            Expanded(
              child: _buildStatChip(
                'Sec. Received',
                '${order['secondaryPartsReceived']}',
                order['secondaryPartsReceived'] == 0
                    ? CupertinoColors.systemOrange
                    : CupertinoColors.systemGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletLayout(Map<String, dynamic> order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fullDateTime = order['orderDate'];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            order['orderNo'],
            style: GoogleFonts.roboto(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.systemIndigo, // Updated for iOS feel
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            fullDateTime,
            style: GoogleFonts.roboto(
              fontSize: screenWidth * 0.02,
              color: CupertinoColors.systemGrey,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Expanded(child: _buildStatChip('Total', '${order['totalParts']}', CupertinoColors.systemBlue)),
        SizedBox(width: screenWidth * 0.01),
        Expanded(child: _buildStatChip('Sec. Created', '${order['secondaryPartsCreated']}', CupertinoColors.systemPurple)),
        SizedBox(width: screenWidth * 0.01),
        Expanded(child: _buildStatChip('Sec. Picked', '${order['secondaryPartsPickedUp']}', CupertinoColors.systemTeal)),
        SizedBox(width: screenWidth * 0.01),
        Expanded(
          child: _buildStatChip(
            'Sec. Received',
            '${order['secondaryPartsReceived']}',
            order['secondaryPartsReceived'] == 0
                ? CupertinoColors.systemOrange
                : CupertinoColors.systemGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.015, vertical: screenWidth * 0.02),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w600,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.roboto(
                fontSize: screenWidth * 0.02,
                color: color,
                decoration: TextDecoration.none),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildTabContent(int tabIndex) {
    final filtered =
    getFilteredData(tabIndex, _searchControllers[tabIndex].text);

    return Column(
      children: [
        buildSearchBar(tabIndex),
        Expanded(child: buildDataTable(filtered, _scrollControllers[tabIndex])),
      ],
    );
  }

  void _generateReport() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Generate Report', style: GoogleFonts.roboto()),
        content:
        Text('Report generation feature coming soon!', style: GoogleFonts.roboto()),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: GoogleFonts.roboto()),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Smooth scroll helpers for FABs
  void _scrollToTop() {
    final c = _scrollControllers[_currentTabIndex];
    if (!c.hasClients) return;
    c.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToBottom() {
    final c = _scrollControllers[_currentTabIndex];
    if (!c.hasClients) return;
    c.animateTo(
      c.position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Awaited Orders',
          style: GoogleFonts.roboto(
            fontSize: screenWidth * (isTablet ? 0.035 : 0.045),
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(_showSearchBar ? CupertinoIcons.xmark : CupertinoIcons.search,
                  size: screenWidth * 0.055),
              onPressed: () {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                  if (!_showSearchBar) {
                    for (var c in _searchControllers) c.clear();
                  }
                });
              },
            ),
            SizedBox(width: screenWidth * 0.02),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(_isAscending ? CupertinoIcons.sort_up : CupertinoIcons.sort_down,
                  size: screenWidth * 0.055),
              onPressed: () => setState(() => _isAscending = !_isAscending),
            ),
            SizedBox(width: screenWidth * 0.02),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.doc_text, size: screenWidth * 0.055),
              onPressed: _generateReport,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // iOS style segmented header; updates instantly while swiping
            Container(
              width: double.infinity,
              color: CupertinoColors.systemBackground,
              padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.01),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _currentTabIndex,
                children: {
                  0: _segChild(screenWidth, screenHeight, isTablet, 'Inward', getTabCount(0)),
                  1: _segChild(screenWidth, screenHeight, isTablet, 'Pickup', getTabCount(1)),
                  2: _segChild(screenWidth, screenHeight, isTablet, 'Creation', getTabCount(2)),
                },
                onValueChanged: (int? value) {
                  if (value == null) return;
                  setState(() => _currentTabIndex = value);
                  // Smoothly animate to the selected page
                  _pageController.animateToPage(
                    value,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),

            // Content: PageView with three pages + overlayed scroll buttons
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    children: [
                      buildTabContent(0),
                      buildTabContent(1),
                      buildTabContent(2),
                    ],
                  ),

                  // Bottom-right Up/Down buttons
                  Positioned(
                    right: 12,
                    bottom: 16,
                    child: Column(
                      children: [
                        _roundCupertinoFab(
                          icon: CupertinoIcons.arrow_up,
                          onPressed: _scrollToTop,
                          semanticLabel: 'Scroll to top',
                        ),
                        const SizedBox(height: 10),
                        _roundCupertinoFab(
                          icon: CupertinoIcons.arrow_down,
                          onPressed: _scrollToBottom,
                          semanticLabel: 'Scroll to bottom',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Segmented control child (with gray, bold count)
  Widget _segChild(double screenWidth, double screenHeight, bool isTablet,
      String title, int count) {
    return Container(
      width: screenWidth * 0.32,
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.015, horizontal: screenWidth * 0.01),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: screenWidth * (isTablet ? 0.025 : 0.03),
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            '($count)',
            style: GoogleFonts.roboto(
              fontSize: screenWidth * (isTablet ? 0.02 : 0.022),
              fontWeight: FontWeight.w700, // bold
              color: CupertinoColors.systemGrey, // gray
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // Small rounded Cupertino-style button (soft edges, subtle shadow)
  Widget _roundCupertinoFab({
    required IconData icon,
    required VoidCallback onPressed,
    String? semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.withOpacity(0.9),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: CupertinoColors.separator,
                width: 0.5,
              ),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.all(12),
              minSize: 0,
              onPressed: onPressed,
              child: Icon(icon, size: 22, color: CupertinoColors.activeBlue),
            ),
          ),
        ),
      ),
    );
  }
}

// Needed for BackdropFilter blur
// Add this import at the top of the file with others:
// import 'dart:ui';
