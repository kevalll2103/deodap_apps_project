// lib/all_employee_picked_orders_screen.dart
// Shows ALL employees with their picked orders in a date range,
// using api_emp_picked_orders.php (no emp_id filter).

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllEmployeePickedOrdersScreen extends StatefulWidget {
  const AllEmployeePickedOrdersScreen({super.key});

  @override
  State<AllEmployeePickedOrdersScreen> createState() =>
      _AllEmployeePickedOrdersScreenState();
}

class _AllEmployeePickedOrdersScreenState
    extends State<AllEmployeePickedOrdersScreen> {
  // ====== CONFIG ======
  static const String _base = 'https://customprint.deodap.com/stockbridge';
  static const String _endpoint = '$_base/all_picked_order.php';

  final DateFormat _apiFmt = DateFormat('yyyy-MM-dd');
  final DateFormat _dispFmt = DateFormat('dd MMM yyyy');

  bool _loading = false;
  String? _error;

  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  int _summaryTotalEmployees = 0;
  int _summaryTotalOrders = 0;

  List<EmployeePickedGroup> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchData(); // default today
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
      _employees = [];
      _summaryTotalEmployees = 0;
      _summaryTotalOrders = 0;
    });

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Missing session token — please login again.';
        });
        return;
      }

      final params = {
        'date_from': _apiFmt.format(_from),
        'date_to': _apiFmt.format(_to),
      };

      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = res.body;

      if (res.statusCode != 200) {
        final snippet = body.length > 300 ? body.substring(0, 300) : body;
        setState(() {
          _loading = false;
          _error = 'Server error (${res.statusCode}). Response:\n$snippet';
        });
        return;
      }

      dynamic obj;
      try {
        obj = jsonDecode(body);
      } on FormatException catch (_) {
        final snippet = body.length > 300 ? body.substring(0, 300) : body;
        setState(() {
          _loading = false;
          _error =
              'Invalid JSON from server. First part of response:\n$snippet';
        });
        return;
      }

      if (obj is! Map || obj['status'] != true) {
        final msg = (obj is Map ? obj['message'] : null)?.toString() ??
            'Unexpected response from server.';
        setState(() {
          _loading = false;
          _error = msg;
        });
        return;
      }

      final summary = obj['summary'] ?? {};
      final totalEmployees = _safeInt(summary['total_employees']);
      final totalOrdersPicked = _safeInt(summary['total_orders_picked']);

      final emps = List<Map<String, dynamic>>.from(obj['employees'] ?? []);
      final parsedEmployees = <EmployeePickedGroup>[];

      for (final e in emps) {
        final empId = _safeInt(e['emp_id']);
        final empCode = e['emp_code']?.toString() ?? '';
        final empName = e['emp_name']?.toString() ?? '';

        final ordersList = List<Map<String, dynamic>>.from(e['orders'] ?? []);
        final orders = ordersList.map((o) => PickedOrder.fromJson(o)).toList();

        final totalOrdersForEmp = _safeInt(e['total_orders_picked']) != 0
            ? _safeInt(e['total_orders_picked'])
            : orders.length;

        final totalQty = orders.fold(
          0,
          (sum, order) => sum + order.items.fold(0, (s, it) => s + it.qty),
        );

        parsedEmployees.add(
          EmployeePickedGroup(
            empId: empId,
            empCode: empCode,
            empName: empName,
            totalOrdersPicked: totalOrdersForEmp,
            totalQtyPicked: totalQty,
            orders: orders,
          ),
        );
      }

      setState(() {
        _loading = false;
        _employees = parsedEmployees;
        _summaryTotalEmployees =
            totalEmployees != 0 ? totalEmployees : parsedEmployees.length;
        _summaryTotalOrders = totalOrdersPicked != 0
            ? totalOrdersPicked
            : _sumOrders(parsedEmployees);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Network / parse error: $e';
      });
    }
  }

  int _sumOrders(List<EmployeePickedGroup> emps) {
    int sum = 0;
    for (final e in emps) {
      sum += e.totalOrdersPicked;
    }
    return sum;
  }

  Future<void> _selectDate({required bool isFrom}) async {
    final initialDate = isFrom ? _from : _to;

    await showCupertinoModalPopup(
      context: context,
      builder: (_) {
        DateTime temp = initialDate;
        return Container(
          height: 260,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          if (isFrom) {
                            _from = temp;
                            if (_to.isBefore(_from)) {
                              _to = _from;
                            }
                          } else {
                            _to = temp;
                            if (_to.isBefore(_from)) {
                              _from = _to;
                            }
                          }
                        });
                        Navigator.of(context).pop();
                        _fetchData();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  maximumDate: DateTime.now().add(const Duration(days: 1)),
                  onDateTimeChanged: (v) => temp = v,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Back',
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Picked Orders',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              'All Employees',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        backgroundColor:
            CupertinoColors.systemGroupedBackground.resolveFrom(context),
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildDateToolbar(),
            _buildGlobalSummaryCard(),
            const SizedBox(height: 4),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _DateChip(
              label: 'From',
              value: _dispFmt.format(_from),
              onTap: () => _selectDate(isFrom: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DateChip(
              label: 'To',
              value: _dispFmt.format(_to),
              onTap: () => _selectDate(isFrom: false),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            borderRadius: BorderRadius.circular(14),
            color: CupertinoColors.activeBlue,
            onPressed: _fetchData,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.refresh,
                  size: 18,
                  color: CupertinoColors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reload',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlobalSummaryCard() {
    final dateRangeText = '${_dispFmt.format(_from)} – ${_dispFmt.format(_to)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.chart_bar_alt_fill,
              size: 26,
              color: CupertinoColors.activeBlue.resolveFrom(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateRangeText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _summaryPill(
                  context: context,
                  label: 'Employees',
                  value: '$_summaryTotalEmployees',
                ),
                const SizedBox(height: 4),
                _summaryPill(
                  context: context,
                  label: 'Orders',
                  value: '$_summaryTotalOrders',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryPill({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CupertinoColors.systemRed,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    }
    if (_employees.isEmpty) {
      return Center(
        child: Text(
          'No picked orders for any employee in this range.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    return CupertinoScrollbar(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _employees.length,
        itemBuilder: (_, i) {
          final emp = _employees[i];
          return _EmployeeSection(emp: emp);
        },
      ),
    );
  }

  static int _safeInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}

// ====== DATA MODELS ======

class EmployeePickedGroup {
  final int empId;
  final String empCode;
  final String empName;
  final int totalOrdersPicked;
  final int totalQtyPicked;
  final List<PickedOrder> orders;

  EmployeePickedGroup({
    required this.empId,
    required this.empCode,
    required this.empName,
    required this.totalOrdersPicked,
    required this.totalQtyPicked,
    required this.orders,
  });
}

class PickedOrder {
  final int id;
  final String? invoiceId;
  final String? invoiceDate;
  final String? orderDate;
  final String? shipmentDate;
  final String? deliveredDate;
  final String? warehouse;
  final String? channel;
  final String? company;
  final String? buyerName;
  final String? buyerAddress1;
  final String? buyerAddress2;
  final String? buyerCity;
  final String? buyerState;
  final String? buyerPincode;
  final String? buyerPhone;
  final String? buyerEmail;
  final String? gstName;
  final String? gstNumber;
  final String? billingName;
  final String? billingAddress1;
  final String? billingAddress2;
  final String? billingCity;
  final String? billingState;
  final String? billingPincode;
  final String? billingPhone;
  final String? billingEmail;
  final String? shippingCompany;
  final String? shipmentTracker;
  final String? orderType;
  final String? packLog;
  final String? rawJson;
  final String? createdAt;
  final String? updatedAt;
  final int? pickStatus;
  final int? pickedByEmpId;
  final String? pickedAt;

  final List<PickedItem> items;

  PickedOrder({
    required this.id,
    required this.invoiceId,
    required this.invoiceDate,
    required this.orderDate,
    required this.shipmentDate,
    required this.deliveredDate,
    required this.warehouse,
    required this.channel,
    required this.company,
    required this.buyerName,
    required this.buyerAddress1,
    required this.buyerAddress2,
    required this.buyerCity,
    required this.buyerState,
    required this.buyerPincode,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.gstName,
    required this.gstNumber,
    required this.billingName,
    required this.billingAddress1,
    required this.billingAddress2,
    required this.billingCity,
    required this.billingState,
    required this.billingPincode,
    required this.billingPhone,
    required this.billingEmail,
    required this.shippingCompany,
    required this.shipmentTracker,
    required this.orderType,
    required this.packLog,
    required this.rawJson,
    required this.createdAt,
    required this.updatedAt,
    required this.pickStatus,
    required this.pickedByEmpId,
    required this.pickedAt,
    required this.items,
  });

  factory PickedOrder.fromJson(Map<String, dynamic> j) {
    final itemsList = List<Map<String, dynamic>>.from(j['items'] ?? []);
    return PickedOrder(
      id: _safeInt(j['id']),
      invoiceId: j['invoice_id']?.toString(),
      invoiceDate: j['invoice_date']?.toString(),
      orderDate: j['order_date']?.toString(),
      shipmentDate: j['shipment_date']?.toString(),
      deliveredDate: j['delivered_date']?.toString(),
      warehouse: j['warehouse']?.toString(),
      channel: j['channel']?.toString(),
      company: j['company']?.toString(),
      buyerName: j['buyer_name']?.toString(),
      buyerAddress1: j['buyer_address1']?.toString(),
      buyerAddress2: j['buyer_address2']?.toString(),
      buyerCity: j['buyer_cty']?.toString(), // alias in PHP
      buyerState: j['buyer_state']?.toString(),
      buyerPincode: j['buyer_pincode']?.toString(),
      buyerPhone: j['buyer_phone']?.toString(),
      buyerEmail: j['buyer_email']?.toString(),
      gstName: j['gst_name']?.toString(),
      gstNumber: j['gst_number']?.toString(),
      billingName: j['billing_name']?.toString(),
      billingAddress1: j['billing_address1']?.toString(),
      billingAddress2: j['billing_address2']?.toString(),
      billingCity: j['billing_cty']?.toString(),
      billingState: j['billing_state']?.toString(),
      billingPincode: j['billing_pincode']?.toString(),
      billingPhone: j['billing_phone']?.toString(),
      billingEmail: j['billing_email']?.toString(),
      shippingCompany: j['shipping_company']?.toString(),
      shipmentTracker: j['shipment_tracker']?.toString(),
      orderType: j['order_type']?.toString(),
      packLog: j['pack_log']?.toString(),
      rawJson: j['raw_json']?.toString(),
      createdAt: j['created_at']?.toString(),
      updatedAt: j['updated_at']?.toString(),
      pickStatus: j['pick_status'] == null ? null : _safeInt(j['pick_status']),
      pickedByEmpId: j['picked_by_emp_id'] == null
          ? null
          : _safeInt(j['picked_by_emp_id']),
      pickedAt: j['picked_at']?.toString(),
      items: itemsList.map(PickedItem.fromJson).toList(),
    );
  }

  static int _safeInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}

class PickedItem {
  final int id;
  final int? orderId;
  final String? channelOrderId;
  final String? channelSubOrderId;
  final String? skuCode;
  final int qty;
  final double? sellingPricePerItem;
  final double? shippingChargePerItem;
  final double? promoDiscounts;
  final double? transactionCharges;
  final double? invoiceAmount;
  final String? currencyCode;
  final double? taxRate;
  final double? taxAmount;
  final double? igstRate;
  final double? igstAmount;
  final double? cgstRate;
  final double? cgstAmount;
  final double? sgstRate;
  final double? sgstAmount;
  final String? status;
  final double? settlementAmount;
  final String? skuUpc;
  final String? listingSku;
  final String? rawJson;
  final String? createdAt;
  final String? updatedAt;

  PickedItem({
    required this.id,
    required this.orderId,
    required this.channelOrderId,
    required this.channelSubOrderId,
    required this.skuCode,
    required this.qty,
    required this.sellingPricePerItem,
    required this.shippingChargePerItem,
    required this.promoDiscounts,
    required this.transactionCharges,
    required this.invoiceAmount,
    required this.currencyCode,
    required this.taxRate,
    required this.taxAmount,
    required this.igstRate,
    required this.igstAmount,
    required this.cgstRate,
    required this.cgstAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.status,
    required this.settlementAmount,
    required this.skuUpc,
    required this.listingSku,
    required this.rawJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PickedItem.fromJson(Map<String, dynamic> j) {
    return PickedItem(
      id: _safeInt(j['id']),
      orderId: j['order_id'] == null ? null : _safeInt(j['order_id']),
      channelOrderId: j['channel_order_id']?.toString(),
      channelSubOrderId: j['channel_sub_order_id']?.toString(),
      skuCode: j['sku_code']?.toString(),
      qty: _safeInt(j['qty']),
      sellingPricePerItem: _safeDouble(j['selling_price_per_item']),
      shippingChargePerItem: _safeDouble(j['shipping_charge_per_item']),
      promoDiscounts: _safeDouble(j['promo_discounts']),
      transactionCharges: _safeDouble(j['transaction_charges']),
      invoiceAmount: _safeDouble(j['invoice_amount']),
      currencyCode: j['currency_code']?.toString(),
      taxRate: _safeDouble(j['tax_rate']),
      taxAmount: _safeDouble(j['tax_amount']),
      igstRate: _safeDouble(j['igst_rate']),
      igstAmount: _safeDouble(j['igst_amount']),
      cgstRate: _safeDouble(j['cgst_rate']),
      cgstAmount: _safeDouble(j['cgst_amount']),
      sgstRate: _safeDouble(j['sgst_rate']),
      sgstAmount: _safeDouble(j['sgst_amount']),
      status: j['status']?.toString(),
      settlementAmount: _safeDouble(j['settlement_amount']),
      skuUpc: j['sku_upc']?.toString(),
      listingSku: j['listing_sku']?.toString(),
      rawJson: j['raw_json']?.toString(),
      createdAt: j['created_at']?.toString(),
      updatedAt: j['updated_at']?.toString(),
    );
  }

  static int _safeInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  static double? _safeDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}

// ====== UI WIDGETS ======

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = CupertinoColors.systemGrey4.resolveFrom(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.calendar,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeSection extends StatelessWidget {
  final EmployeePickedGroup emp;
  const _EmployeeSection({required this.emp});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].isEmpty ? '?' : parts[0][0].toUpperCase();
    }
    final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    final second = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
    final joined = '$first$second';
    return joined.isEmpty ? '?' : joined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Employee header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF34C759),
                        Color(0xFF007AFF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(emp.empName),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.empName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Emp Code: ${emp.empCode}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _pill(
                      context: context,
                      label: 'Orders',
                      value: '${emp.totalOrdersPicked}',
                    ),
                    const SizedBox(height: 4),
                    _pill(
                      context: context,
                      label: 'Qty',
                      value: '${emp.totalQtyPicked}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Orders list
          if (emp.orders.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                'No orders for this employee in this range.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  decoration: TextDecoration.none,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
              child: Column(
                children: emp.orders.map((o) => _OrderCard(order: o)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PickedOrder order;
  const _OrderCard({required this.order});

  int get _totalQty => order.items.fold(0, (sum, it) => sum + (it.qty));

  @override
  Widget build(BuildContext context) {
    final itemsCount = order.items.length;

    final buyerLine = [
      if (order.buyerName != null && order.buyerName!.isNotEmpty)
        order.buyerName,
      if (order.buyerCity != null && order.buyerCity!.isNotEmpty)
        order.buyerCity,
      if (order.buyerState != null && order.buyerState!.isNotEmpty)
        order.buyerState,
    ].whereType<String>().join(' • ');

    final topRight = [
      if (order.channel != null && order.channel!.isNotEmpty) order.channel,
      if (order.warehouse != null && order.warehouse!.isNotEmpty)
        order.warehouse,
    ].join(' • ');

    String? firstSku;
    if (order.items.isNotEmpty) {
      final it = order.items.first;
      firstSku = (it.listingSku?.isNotEmpty ?? false)
          ? it.listingSku
          : (it.skuCode?.isNotEmpty ?? false)
              ? it.skuCode
              : null;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: CupertinoColors.systemGrey5,
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: order id + channel/warehouse
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}'
                    '${order.invoiceId != null && order.invoiceId!.isNotEmpty ? ' • Inv: ${order.invoiceId}' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.label.resolveFrom(context),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (topRight.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      topRight,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (buyerLine.isNotEmpty)
              Text(
                buyerLine,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                  decoration: TextDecoration.none,
                ),
              ),
            if (order.buyerPhone != null && order.buyerPhone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  order.buyerPhone!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            if (order.shipmentTracker != null &&
                order.shipmentTracker!.trim().isNotEmpty)
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location_solid,
                    size: 13,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.shipmentTracker!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.activeBlue,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            if (order.shipmentTracker != null &&
                order.shipmentTracker!.trim().isNotEmpty)
              const SizedBox(height: 4),
            Row(
              children: [
                if (order.orderDate != null && order.orderDate!.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Order: ${order.orderDate}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                if (order.pickedAt != null && order.pickedAt!.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Picked: ${order.pickedAt}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    '$itemsCount item${itemsCount == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Qty: $_totalQty',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  if (firstSku != null && firstSku.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        firstSku!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== ORDER DETAIL SCREEN ======

class OrderDetailScreen extends StatelessWidget {
  final PickedOrder order;
  const OrderDetailScreen({super.key, required this.order});

  int get _totalQty => order.items.fold(0, (sum, it) => sum + (it.qty));

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Orders',
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order #${order.id}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: TextDecoration.none,
              ),
            ),
            if (order.shipmentTracker != null &&
                order.shipmentTracker!.trim().isNotEmpty)
              Text(
                order.shipmentTracker!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.activeBlue,
                  decoration: TextDecoration.none,
                ),
              ),
          ],
        ),
        backgroundColor:
            CupertinoColors.systemGroupedBackground.resolveFrom(context),
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            _OrderSummaryCard(order: order, totalQty: _totalQty),
            const SizedBox(height: 12),
            _Section(
              title: 'Shipping & Tracking',
              children: [
                _info('Shipping Company', order.shippingCompany),
                _info('Shipment Tracker', order.shipmentTracker),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Items (${order.items.length})',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            if (order.items.isEmpty)
              Text(
                'No items found for this order.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  decoration: TextDecoration.none,
                ),
              )
            else
              ...order.items.map((it) => _ItemCard(item: it)),
            const SizedBox(height: 16),
            _Section(
              title: 'Buyer Details',
              children: [
                _info('Buyer Name', order.buyerName),
                _info('Address 1', order.buyerAddress1),
                _info('Address 2', order.buyerAddress2),
                _info('City', order.buyerCity),
                _info('State', order.buyerState),
                _info('Pincode', order.buyerPincode),
                _info('Phone', order.buyerPhone),
                _info('Email', order.buyerEmail),
                _info('GST Name', order.gstName),
                _info('GST Number', order.gstNumber),
              ],
            ),
            _Section(
              title: 'Billing Details',
              children: [
                _info('Billing Name', order.billingName),
                _info('Address 1', order.billingAddress1),
                _info('Address 2', order.billingAddress2),
                _info('City', order.billingCity),
                _info('State', order.billingState),
                _info('Pincode', order.billingPincode),
                _info('Phone', order.billingPhone),
                _info('Email', order.billingEmail),
              ],
            ),
            _Section(
              title: 'System / Internal',
              children: [
                _info('Pick Status', order.pickStatus?.toString()),
                _info('Picked By Emp ID', order.pickedByEmpId?.toString()),
                _info('Picked At', order.pickedAt),
                _info('Created At', order.createdAt),
                _info('Updated At', order.updatedAt),
                _info('Order Type', order.orderType),
                _info('Pack Log', order.packLog),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _info(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return _InfoRow(label: label, value: value);
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final PickedOrder order;
  final int totalQty;

  const _OrderSummaryCard({
    required this.order,
    required this.totalQty,
  });

  @override
  Widget build(BuildContext context) {
    final buyerLine = [
      if (order.buyerName != null && order.buyerName!.isNotEmpty)
        order.buyerName,
      if (order.buyerCity != null && order.buyerCity!.isNotEmpty)
        order.buyerCity,
      if (order.buyerState != null && order.buyerState!.isNotEmpty)
        order.buyerState,
    ].whereType<String>().join(' • ');

    final topRight = [
      if (order.channel != null && order.channel!.isNotEmpty) order.channel,
      if (order.warehouse != null && order.warehouse!.isNotEmpty)
        order.warehouse,
    ].join(' • ');

    String datesStr = '';
    if (order.orderDate != null && order.orderDate!.isNotEmpty) {
      datesStr = 'Order: ${order.orderDate}';
    }
    if (order.invoiceDate != null && order.invoiceDate!.isNotEmpty) {
      datesStr = datesStr.isEmpty
          ? 'Invoice: ${order.invoiceDate}'
          : '$datesStr • Invoice: ${order.invoiceDate}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order id & channel/wh
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}'
                  '${order.invoiceId != null && order.invoiceId!.isNotEmpty ? ' • Inv: ${order.invoiceId}' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (topRight.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    topRight,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (buyerLine.isNotEmpty)
            Text(
              buyerLine,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          if (order.buyerPhone != null && order.buyerPhone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                order.buyerPhone!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (datesStr.isNotEmpty)
            Text(
              datesStr,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
          if (order.pickedAt != null && order.pickedAt!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Picked: ${order.pickedAt}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pill(
                context: context,
                label: 'Items',
                value: '${order.items.length}',
              ),
              const SizedBox(width: 8),
              _pill(
                context: context,
                label: 'Total Qty',
                value: '$totalQty',
              ),
              if (order.orderType != null && order.orderType!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _pill(
                  context: context,
                  label: 'Type',
                  value: order.orderType!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...visible,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CupertinoColors.label.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final PickedItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (item.listingSku?.isNotEmpty ?? false)
                ? item.listingSku!
                : (item.skuCode ?? '-'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          _InfoRow(
            label: 'Qty',
            value: '${item.qty}',
          ),
          if (item.channelSubOrderId != null &&
              item.channelSubOrderId!.isNotEmpty)
            _InfoRow(
              label: 'Sub Order ID',
              value: item.channelSubOrderId!,
            ),
          if (item.sellingPricePerItem != null)
            _InfoRow(
              label: 'Selling Price / item',
              value: item.sellingPricePerItem!.toStringAsFixed(2),
            ),
          if (item.shippingChargePerItem != null)
            _InfoRow(
              label: 'Shipping / item',
              value: item.shippingChargePerItem!.toStringAsFixed(2),
            ),
          if (item.invoiceAmount != null)
            _InfoRow(
              label: 'Invoice Amount',
              value: item.invoiceAmount!.toStringAsFixed(2),
            ),
          if (item.settlementAmount != null)
            _InfoRow(
              label: 'Settlement Amount',
              value: item.settlementAmount!.toStringAsFixed(2),
            ),
          if (item.taxRate != null)
            _InfoRow(
              label: 'Tax Rate',
              value: item.taxRate!.toStringAsFixed(2),
            ),
          if (item.taxAmount != null)
            _InfoRow(
              label: 'Tax Amount',
              value: item.taxAmount!.toStringAsFixed(2),
            ),
          if (item.status != null && item.status!.isNotEmpty)
            _InfoRow(
              label: 'Status',
              value: item.status!,
            ),
        ],
      ),
    );
  }
}
