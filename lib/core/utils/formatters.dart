import 'package:intl/intl.dart';

/// Formatting utilities for dates, currency, and numbers.
class AppFormatters {
  AppFormatters._();

  static final DateFormat _longDateFormat = DateFormat('MMMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _monthAbbrFormat = DateFormat('MMM yyyy');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEEE');
  static final DateFormat _shortDayOfWeekFormat = DateFormat('EEE');

  static String formatDate(DateTime date) {
    return _longDateFormat.format(date);
  }

  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  static String formatMonthAbbr(DateTime date) {
    return _monthAbbrFormat.format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return _dayOfWeekFormat.format(date);
  }

  static String formatShortDayOfWeek(DateTime date) {
    return _shortDayOfWeekFormat.format(date);
  }

  static String formatDuration(Duration? duration) {
    if (duration == null) return 'In Progress';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  static String formatDurationVerbose(Duration? duration) {
    if (duration == null) return 'In Progress';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '$hours hr $minutes min';
    } else if (hours > 0) {
      return '$hours hr';
    } else {
      return '$minutes min';
    }
  }

  static String formatCurrency(num amount) {
    // Gym management currency (e.g. ₹0)
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }
}
