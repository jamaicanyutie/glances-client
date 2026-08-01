/// Shared formatting helpers for Glances metrics.
///
/// Every model field in the data layer is nullable, so these helpers accept
/// nullable inputs and fall back to `—` instead of crashing.
library;

/// Formats [bytes] (a byte count) into a compact human-readable string using
/// binary prefixes: B, KB, MB, GB, TB.
///
/// One decimal place is kept for KB and above; byte counts are shown whole.
/// Returns `—` when [bytes] is null.
String formatBytes(double? bytes) {
  if (bytes == null || bytes < 0) {
    return '—';
  }
  const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes;
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  if (unit == 0) {
    return '${value.toStringAsFixed(0)} ${units[unit]}';
  }
  return '${value.toStringAsFixed(1)} ${units[unit]}';
}

/// Formats [value] as a percentage with a single decimal place, e.g. `42.0%`.
///
/// Returns `—` when [value] is null.
String formatPercent(double? value) {
  if (value == null) {
    return '—';
  }
  return '${value.toStringAsFixed(1)}%';
}
