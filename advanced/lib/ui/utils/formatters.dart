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

/// Formats a rate (bytes per second) from a cumulative byte counter and the
/// seconds since the counter was last updated.
///
/// Falls back to the cumulative byte count when no usable update window is
/// available, and to `—/s` when the counter itself is missing.
String formatRate(double? bytes, double? timeSinceUpdate) {
  if (bytes != null && timeSinceUpdate != null && timeSinceUpdate > 0) {
    return '${formatBytes(bytes / timeSinceUpdate)}/s';
  }
  if (bytes != null) {
    return formatBytes(bytes);
  }
  return '—/s';
}

/// Maps a server-provided unit label (from the repository's `getItemUnit`)
/// onto the per-second suffix used next to a rate value.
///
/// The client hardcodes `/s` for byte rates; the server's Glances unit
/// identifiers (`percent`, `bytes`, `bytes_per_sec`) already describe the
/// same byte-per-second metric, so any rate-style unit resolves back to `/s`.
/// Returns [fallback] when the server exposes no unit, keeping the hardcoded
/// suffix intact.
String rateSuffix(String? serverUnit, {String fallback = '/s'}) {
  if (serverUnit == null) {
    return fallback;
  }
  final String unit = serverUnit.trim().toLowerCase();
  if (unit == 'bytes_per_sec' || unit == 'bytes_per_second' || unit == 'b/s') {
    return '/s';
  }
  return fallback;
}
