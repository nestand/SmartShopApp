class DatabaseUtils {
  /// Safely convert database value to int
  static int? safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// Safely convert database value to non-null int
  static int safeIntNotNull(dynamic value, {int defaultValue = 0}) {
    final result = safeInt(value);
    return result ?? defaultValue;
  }

  /// Safely convert database value to double
  static double? safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely convert database value to bool
  static bool safeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final intValue = int.tryParse(value);
      return intValue == 1;
    }
    return defaultValue;
  }

  /// Safely convert database value to String
  static String safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }
}
