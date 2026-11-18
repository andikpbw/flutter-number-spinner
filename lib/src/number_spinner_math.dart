import 'dart:math' as math;

/// Precision-safe decimal arithmetic and step mapping utilities for `NumberSpinner`.
///
/// Prevents IEEE 754 floating-point drift (for example, `0.1 + 0.2 == 0.3`)
/// by scaling operands to integer representations during addition, subtraction,
/// snapping, and index calculation.
class NumberSpinnerMath {
  const NumberSpinnerMath._();

  /// Maximum supported decimal precision (number of fractional digits).
  static const int maxSupportedPrecision = 8;

  /// Infers the required decimal precision from up to three numeric values
  /// (typically `min`, `max`, `step`, and `initialValue`).
  static int inferPrecision([num? a, num? b, num? c, num? d]) {
    return [
      _decimalPlacesOf(a),
      _decimalPlacesOf(b),
      _decimalPlacesOf(c),
      _decimalPlacesOf(d),
    ].reduce(math.max);
  }

  static int _decimalPlacesOf(num? value) {
    if (value == null || value is int) return 0;
    if (value.isNaN || value.isInfinite) return 0;
    final text = value.toString().toLowerCase();
    if (text.contains('e-')) {
      final parts = text.split('e-');
      final exp = int.tryParse(parts.last) ?? 0;
      final mantissaDecimals =
          parts.first.contains('.') ? parts.first.split('.').last.length : 0;
      return (exp + mantissaDecimals).clamp(0, maxSupportedPrecision);
    }
    final dotIndex = text.indexOf('.');
    if (dotIndex < 0) return 0;
    final fractional =
        text.substring(dotIndex + 1).replaceAll(RegExp(r'0+$'), '');
    return fractional.length.clamp(0, maxSupportedPrecision);
  }

  /// Rounds [value] to [precision] decimal digits.
  ///
  /// Returns an [int] when [precision] is `0`, or a clean [double] otherwise.
  static num roundToPrecision(num value, int precision) {
    final safePrecision = precision.clamp(0, maxSupportedPrecision);
    if (safePrecision == 0) {
      return value.round();
    }
    final factor = math.pow(10, safePrecision).toDouble();
    final scaled = (value * factor).round();
    return double.parse((scaled / factor).toStringAsFixed(safePrecision));
  }

  /// Precision-safe addition of [a] and [b] rounded to [precision] decimal places.
  static num add(num a, num b, {int? precision}) {
    final effectivePrecision =
        (precision ?? inferPrecision(a, b)).clamp(0, maxSupportedPrecision);
    final factor = math.pow(10, effectivePrecision).toDouble();
    final aScaled = (a * factor).round();
    final bScaled = (b * factor).round();
    final resultScaled = aScaled + bScaled;
    if (effectivePrecision == 0) {
      return resultScaled;
    }
    return double.parse(
      (resultScaled / factor).toStringAsFixed(effectivePrecision),
    );
  }

  /// Precision-safe subtraction (`a - b`) rounded to [precision] decimal places.
  static num subtract(num a, num b, {int? precision}) {
    return add(a, -b, precision: precision);
  }

  /// Clamps [value] within `[min, max]` and rounds to [precision].
  static num clamp(
    num value, {
    required num min,
    required num max,
    int? precision,
  }) {
    final effectiveMin = math.min(min, max);
    final effectiveMax = math.max(min, max);
    final effectivePrecision =
        (precision ?? inferPrecision(value, effectiveMin, effectiveMax))
            .clamp(0, maxSupportedPrecision);
    final clamped = value.clamp(effectiveMin, effectiveMax);
    return roundToPrecision(clamped, effectivePrecision);
  }

  /// Wraps [value] cyclically around `[min, max]` with step size [step].
  ///
  /// When [value] exceeds [max], it wraps around to [min] (and vice versa).
  static num wrap(
    num value, {
    required num min,
    required num max,
    required num step,
    int? precision,
  }) {
    final effectiveMin = math.min(min, max);
    final effectiveMax = math.max(min, max);
    final safeStep = step <= 0 ? 1 : step;
    final effectivePrecision = (precision ??
            inferPrecision(value, effectiveMin, effectiveMax, safeStep))
        .clamp(0, maxSupportedPrecision);

    final totalSteps = stepCount(
      min: effectiveMin,
      max: effectiveMax,
      step: safeStep,
      precision: effectivePrecision,
    );
    if (totalSteps <= 1) {
      return roundToPrecision(effectiveMin, effectivePrecision);
    }

    final factor = math.pow(10, effectivePrecision).toDouble();
    final minScaled = (effectiveMin * factor).round();
    final stepScaled = math.max(1, (safeStep * factor).round());
    final valueScaled = (value * factor).round();

    final rawIndex = ((valueScaled - minScaled) / stepScaled).round();
    final wrappedIndex = ((rawIndex % totalSteps) + totalSteps) % totalSteps;

    return valueAtStep(
      index: wrappedIndex,
      min: effectiveMin,
      max: effectiveMax,
      step: safeStep,
      precision: effectivePrecision,
    );
  }

  /// Snaps [value] to the nearest valid step increment starting from [min]
  /// within `[min, max]`.
  static num snapToStep(
    num value, {
    required num min,
    required num max,
    required num step,
    int? precision,
  }) {
    final effectiveMin = math.min(min, max);
    final effectiveMax = math.max(min, max);
    final safeStep = step <= 0 ? 1 : step;
    final effectivePrecision = (precision ??
            inferPrecision(value, effectiveMin, effectiveMax, safeStep))
        .clamp(0, maxSupportedPrecision);

    final index = stepIndexForValue(
      value,
      min: effectiveMin,
      max: effectiveMax,
      step: safeStep,
      precision: effectivePrecision,
    );

    return valueAtStep(
      index: index,
      min: effectiveMin,
      max: effectiveMax,
      step: safeStep,
      precision: effectivePrecision,
    );
  }

  /// Returns the total number of discrete steps in `[min, max]` for [step].
  static int stepCount({
    required num min,
    required num max,
    required num step,
    int? precision,
  }) {
    final effectiveMin = math.min(min, max);
    final effectiveMax = math.max(min, max);
    final safeStep = step <= 0 ? 1 : step;
    final effectivePrecision =
        (precision ?? inferPrecision(effectiveMin, effectiveMax, safeStep))
            .clamp(0, maxSupportedPrecision);

    final factor = math.pow(10, effectivePrecision).toDouble();
    final minScaled = (effectiveMin * factor).round();
    final maxScaled = (effectiveMax * factor).round();
    final stepScaled = math.max(1, (safeStep * factor).round());

    final count = ((maxScaled - minScaled) ~/ stepScaled) + 1;
    return math.max(1, count);
  }

  /// Converts a 0-based step [index] into the corresponding numeric value
  /// within `[min, max]`.
  static num valueAtStep({
    required int index,
    required num min,
    required num max,
    required num step,
    int? precision,
  }) {
    final effectiveMin = math.min(min, max);
    final effectiveMax = math.max(min, max);
    final safeStep = step <= 0 ? 1 : step;
    final effectivePrecision =
        (precision ?? inferPrecision(effectiveMin, effectiveMax, safeStep))
            .clamp(0, maxSupportedPrecision);

    final count = stepCount(
      min: effectiveMin,
      max: effectiveMax,
      step: safeStep,
      precision: effectivePrecision,
    );
    final clampedIndex = index.clamp(0, count - 1);

    final factor = math.pow(10, effectivePrecision).toDouble();
    final minScaled = (effectiveMin * factor).round();
    final stepScaled = math.max(1, (safeStep * factor).round());
    final valueScaled = minScaled + (clampedIndex * stepScaled);

    final rawValue = effectivePrecision == 0
        ? valueScaled
        : double.parse(
            (valueScaled / factor).toStringAsFixed(effectivePrecision),
          );

    return clamp(
      rawValue,
      min: effectiveMin,
      max: effectiveMax,
      precision: effectivePrecision,
    );
  }

  /// Returns the nearest 0-based step index for [value] within `[min, max]`.
  static int stepIndexForValue(
    num value, {
    required num min,
    required num max,
    required num step,
    int? precision,
  }) {
    final effectiveMin = math.min(min, max);
    final effectiveMax = math.max(min, max);
    final safeStep = step <= 0 ? 1 : step;
    final effectivePrecision = (precision ??
            inferPrecision(value, effectiveMin, effectiveMax, safeStep))
        .clamp(0, maxSupportedPrecision);

    final count = stepCount(
      min: effectiveMin,
      max: effectiveMax,
      step: safeStep,
      precision: effectivePrecision,
    );

    final factor = math.pow(10, effectivePrecision).toDouble();
    final minScaled = (effectiveMin * factor).round();
    final stepScaled = math.max(1, (safeStep * factor).round());
    final valueScaled = (value * factor).round();

    final index = ((valueScaled - minScaled) / stepScaled).round();
    return index.clamp(0, count - 1);
  }
}
