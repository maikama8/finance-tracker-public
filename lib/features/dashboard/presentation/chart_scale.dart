import 'dart:math' as math;

/// An axis range with a round step, in the same units as the plotted values.
class ChartScale {
  const ChartScale({required this.min, required this.max, required this.step});

  final double min;
  final double max;

  /// Distance between ticks. Positive.
  final double step;

  /// From zero up to a round ceiling above [peak].
  ///
  /// A peak that already lands on a tick gets one extra step, so the tallest
  /// bar does not sit on the frame.
  factory ChartScale.fromZero(double peak) {
    if (peak <= 0 || peak.isNaN || peak.isInfinite) {
      return const ChartScale(min: 0, max: 1, step: 1);
    }
    final step = _niceStep(peak / 4);
    var max = (peak / step).ceil() * step;
    if (max <= peak) max += step;
    return ChartScale(min: 0, max: max.toDouble(), step: step);
  }

  /// Headroom around a series that does not start at zero.
  factory ChartScale.around(double low, double high) {
    if (low.isNaN || high.isNaN || low.isInfinite || high.isInfinite) {
      return const ChartScale(min: 0, max: 1, step: 1);
    }
    var start = low;
    var end = high;
    if (start == end) {
      final pad = start.abs() == 0 ? 1.0 : start.abs() * 0.1;
      start -= pad;
      end += pad;
    }
    if (start > end) {
      final swap = start;
      start = end;
      end = swap;
    }
    final step = _niceStep((end - start) / 4);
    var min = (start / step).floor() * step;
    var max = (end / step).ceil() * step;
    if (max <= end) max += step;
    if (min >= start) min -= step;
    return ChartScale(min: min.toDouble(), max: max.toDouble(), step: step);
  }
}

double _niceStep(double rough) {
  if (rough <= 0 || rough.isNaN || rough.isInfinite) return 1;
  final exponent = (math.log(rough) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final fraction = rough / magnitude;
  final nice = fraction <= 1
      ? 1.0
      : fraction <= 2
      ? 2.0
      : fraction <= 2.5
      ? 2.5
      : fraction <= 5
      ? 5.0
      : 10.0;
  return nice * magnitude;
}
