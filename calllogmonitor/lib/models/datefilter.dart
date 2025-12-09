// File: lib/models/date_filter_type.dart

/// Enum representing different date filter types for call analytics
enum DateFilterType {
  /// Today's calls only
  today,

  /// Yesterday's calls only
  yesterday,

  /// Current week's calls (Monday to Sunday)
  currentWeek,

  /// Previous week's calls (Monday to Sunday)
  previousWeek,

  /// Current month's calls
  currentMonth,

  /// Previous month's calls
  previousMonth,

  /// Current year's calls
  currentYear,

  /// Custom date range selected by user
  custom
}

/// Extension to provide display names for DateFilterType
extension DateFilterTypeExtension on DateFilterType {
  /// Returns a user-friendly display name for the filter type
  String get displayName {
    switch (this) {
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
}