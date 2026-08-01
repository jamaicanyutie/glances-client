/// A single point in a plugin history series, used to render sparklines.
///
/// The Glances history endpoints return an array of `[timestamp, value]`
/// pairs. This model decodes one such pair, where the timestamp is an
/// ISO-8601 string (e.g. `2026-07-30T12:00:00.000Z`) and the value is any
/// JSON number.
class HistoryPoint {
  /// Timestamp of the sample.
  final DateTime time;

  /// Sampled value.
  final double value;

  /// Creates a [HistoryPoint].
  const HistoryPoint({required this.time, required this.value});

  /// Parses a `[iso8601String, num]` pair from the Glances history API.
  ///
  /// Throws a [FormatException] with a descriptive message when [json] is
  /// not a two-element list of a string timestamp and a numeric value.
  factory HistoryPoint.fromJson(Object? json) {
    if (json is! List || json.length < 2) {
      throw FormatException(
        'Expected a [timestamp, value] pair, got: $json',
      );
    }
    final Object? timeRaw = json[0];
    final Object? valueRaw = json[1];
    if (timeRaw is! String) {
      throw FormatException(
        'Expected an ISO-8601 timestamp string, got: $timeRaw',
      );
    }
    if (valueRaw is! num) {
      throw FormatException(
        'Expected a numeric value, got: $valueRaw',
      );
    }
    return HistoryPoint(
      time: DateTime.parse(timeRaw),
      value: valueRaw.toDouble(),
    );
  }
}
