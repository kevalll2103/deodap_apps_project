// File: lib/widgets/date_filter_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calllogmonitor/models/datefilter.dart';

enum DateFilterType {
  today,
  yesterday,
  currentWeek,
  previousWeek,
  currentMonth,
  previousMonth,
  currentYear,
  custom
}

class DateFilterWidget extends StatefulWidget {
  final Function(DateTime fromDate, DateTime toDate, DateFilterType filterType) onDateChanged;
  final DateFilterType initialFilter;
  final Color primaryColor;

  const DateFilterWidget({
    Key? key,
    required this.onDateChanged,
    this.initialFilter = DateFilterType.today,
    this.primaryColor = const Color(0xFF8B4513), // AppTheme.primaryBrown
  }) : super(key: key);

  @override
  State<DateFilterWidget> createState() => _DateFilterWidgetState();
}

class _DateFilterWidgetState extends State<DateFilterWidget> {
  DateFilterType _selectedFilter = DateFilterType.today;
  DateTime? _customFromDate;
  DateTime? _customToDate;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _applyFilter(_selectedFilter);
  }

  String _getFilterDisplayName(DateFilterType filter) {
    switch (filter) {
      case DateFilterType.today:
        return 'Today';
      case DateFilterType.yesterday:
        return 'Yesterday';
      case DateFilterType.currentWeek:
        return 'Current Week';
      case DateFilterType.previousWeek:
        return 'Previous Week';
      case DateFilterType.currentMonth:
        return 'Current Month';
      case DateFilterType.previousMonth:
        return 'Previous Month';
      case DateFilterType.currentYear:
        return 'Current Year';
      case DateFilterType.custom:
        return 'Custom Range';
    }
  }

  Map<String, DateTime> _calculateDateRange(DateFilterType filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (filter) {
      case DateFilterType.today:
        return {
          'from': today,
          'to': endOfToday,
        };

      case DateFilterType.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return {
          'from': yesterday,
          'to': yesterday.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        };

      case DateFilterType.currentWeek:
        final weekday = now.weekday;
        final mondayOfWeek = today.subtract(Duration(days: weekday - 1));
        final sundayOfWeek = mondayOfWeek.add(const Duration(days: 6));
        return {
          'from': mondayOfWeek,
          'to': sundayOfWeek.isAfter(today) ? endOfToday : sundayOfWeek.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        };

      case DateFilterType.previousWeek:
        final weekday = now.weekday;
        final mondayOfThisWeek = today.subtract(Duration(days: weekday - 1));
        final mondayOfLastWeek = mondayOfThisWeek.subtract(const Duration(days: 7));
        final sundayOfLastWeek = mondayOfLastWeek.add(const Duration(days: 6));
        return {
          'from': mondayOfLastWeek,
          'to': sundayOfLastWeek.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        };

      case DateFilterType.currentMonth:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
        final toDate = endOfMonth.isAfter(now) ? endOfToday : endOfMonth;
        return {
          'from': firstOfMonth,
          'to': toDate,
        };

      case DateFilterType.previousMonth:
        final firstOfPrevMonth = DateTime(now.year, now.month - 1, 1);
        final lastOfPrevMonth = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        return {
          'from': firstOfPrevMonth,
          'to': lastOfPrevMonth,
        };

      case DateFilterType.currentYear:
        final firstOfYear = DateTime(now.year, 1, 1);
        final lastOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        final toDate = lastOfYear.isAfter(now) ? endOfToday : lastOfYear;
        return {
          'from': firstOfYear,
          'to': toDate,
        };

      case DateFilterType.custom:
        final safeNow = DateTime.now();
        final safeToDate = (_customToDate ?? safeNow).isAfter(safeNow)
            ? DateTime(safeNow.year, safeNow.month, safeNow.day, 23, 59, 59)
            : _customToDate!;
        return {
          'from': _customFromDate ?? today,
          'to': safeToDate,
        };
    }
  }

  void _applyFilter(DateFilterType filter) {
    final dateRange = _calculateDateRange(filter);
    final now = DateTime.now();

    final fromDate = dateRange['from']!;
    final toDate = dateRange['to']!;
    final validToDate = toDate.isAfter(now) ? DateTime(now.year, now.month, now.day, 23, 59, 59) : toDate;

    widget.onDateChanged(fromDate, validToDate, filter);
  }

  Future<void> _showCustomDatePicker() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customFromDate != null && _customToDate != null
          ? DateTimeRange(start: _customFromDate!, end: _customToDate!)
          : DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: widget.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customFromDate = picked.start;
        _customToDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _selectedFilter = DateFilterType.custom;
      });
      _applyFilter(DateFilterType.custom);
    }
  }

  String _getDateRangeText() {
    final dateRange = _calculateDateRange(_selectedFilter);
    final fromDate = dateRange['from']!;
    final toDate = dateRange['to']!;

    final formatter = DateFormat('dd MMM yyyy');

    if (_selectedFilter == DateFilterType.today) {
      return 'Today: ${formatter.format(fromDate)}';
    } else if (_selectedFilter == DateFilterType.yesterday) {
      return 'Yesterday: ${formatter.format(fromDate)}';
    } else {
      return '${formatter.format(fromDate)} - ${formatter.format(toDate)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range,
                color: widget.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter by Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DateFilterType>(
                    value: _selectedFilter,
                    isDense: true,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.primaryColor,
                      size: 20,
                    ),
                    items: DateFilterType.values.map((DateFilterType filter) {
                      return DropdownMenuItem<DateFilterType>(
                        value: filter,
                        child: Text(_getFilterDisplayName(filter)),
                      );
                    }).toList(),
                    onChanged: (DateFilterType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFilter = newValue;
                        });

                        if (newValue == DateFilterType.custom) {
                          _showCustomDatePicker();
                        } else {
                          _applyFilter(newValue);
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getDateRangeText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_selectedFilter == DateFilterType.custom)
                  GestureDetector(
                    onTap: _showCustomDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
