import 'number_spinner_math.dart';
import 'number_spinner_types.dart';

/// Configurable formatter for displaying numeric values inside `NumberSpinner`.
///
/// Supports prefix/suffix decorators, thousand grouping separators, custom
/// decimal separators, fixed decimal padding, zero-padded integer digits
/// (such as `01`, `02`), and custom label builder callbacks.
class NumberSpinnerFormat {
  /// Creates a custom [NumberSpinnerFormat].
  const NumberSpinnerFormat({
    this.prefix = '',
    this.suffix = '',
    this.thousandSeparator = ',',
    this.decimalSeparator = '.',
    this.useGrouping = true,
    this.padDecimals = false,
    this.minIntegerDigits = 1,
    this.showPlusSign = false,
    this.customFormatter,
  }) : assert(minIntegerDigits >= 1, 'minIntegerDigits must be at least 1.');

  /// Standard integer or decimal format with comma thousand grouping.
  const NumberSpinnerFormat.standard({
    this.prefix = '',
    this.suffix = '',
    this.useGrouping = true,
    this.showPlusSign = false,
  })  : thousandSeparator = ',',
        decimalSeparator = '.',
        padDecimals = false,
        minIntegerDigits = 1,
        customFormatter = null;

  /// Fixed-decimal format that pads trailing zeros up to precision.
  const NumberSpinnerFormat.decimal({
    this.prefix = '',
    this.suffix = '',
    this.useGrouping = true,
    this.padDecimals = true,
    this.showPlusSign = false,
  })  : thousandSeparator = ',',
        decimalSeparator = '.',
        minIntegerDigits = 1,
        customFormatter = null;

  /// Zero-padded integer format (for example, `width: 2` produces `00`, `01`, `09`).
  ///
  /// Ideal for clocks, timers, counters, and scoreboards.
  const NumberSpinnerFormat.padded({
    int width = 2,
    this.prefix = '',
    this.suffix = '',
    this.showPlusSign = false,
  })  : assert(width >= 1, 'width must be at least 1.'),
        thousandSeparator = '',
        decimalSeparator = '.',
        useGrouping = false,
        padDecimals = false,
        minIntegerDigits = width,
        customFormatter = null;

  /// Currency format preset (for example, `$1,250.00`).
  const NumberSpinnerFormat.currency({
    String symbol = r'$',
    this.thousandSeparator = ',',
    this.decimalSeparator = '.',
    this.padDecimals = true,
    this.showPlusSign = false,
  })  : prefix = symbol,
        suffix = '',
        useGrouping = true,
        minIntegerDigits = 1,
        customFormatter = null;

  /// European number and currency format preset (`1.250,50`).
  const NumberSpinnerFormat.european({
    String symbol = '',
    this.suffix = '',
    this.padDecimals = false,
    this.showPlusSign = false,
  })  : prefix = symbol,
        thousandSeparator = '.',
        decimalSeparator = ',',
        useGrouping = true,
        minIntegerDigits = 1,
        customFormatter = null;

  /// Percentage format preset (`75%` or `12.5%`).
  const NumberSpinnerFormat.percentage({
    this.padDecimals = false,
    this.showPlusSign = false,
  })  : prefix = '',
        suffix = '%',
        thousandSeparator = ',',
        decimalSeparator = '.',
        useGrouping = true,
        minIntegerDigits = 1,
        customFormatter = null;

  /// Physical or measurement unit format preset (for example, `120 kg`, `36.5 °C`).
  const NumberSpinnerFormat.unit({
    required String unit,
    this.useGrouping = true,
    this.padDecimals = false,
    this.showPlusSign = false,
  })  : prefix = '',
        suffix = ' $unit',
        thousandSeparator = ',',
        decimalSeparator = '.',
        minIntegerDigits = 1,
        customFormatter = null;

  /// Custom callback-driven format preset.
  const NumberSpinnerFormat.custom(
    NumberSpinnerLabelBuilder formatter,
  )   : prefix = '',
        suffix = '',
        thousandSeparator = ',',
        decimalSeparator = '.',
        useGrouping = false,
        padDecimals = false,
        minIntegerDigits = 1,
        showPlusSign = false,
        customFormatter = formatter;

  /// Text prepended before the formatted number (for example, `$`).
  final String prefix;

  /// Text appended after the formatted number (for example, `%` or ` kg`).
  final String suffix;

  /// Character used to separate groups of thousands (for example, `,` or `.`).
  final String thousandSeparator;

  /// Character used as the decimal point (for example, `.` or `,`).
  final String decimalSeparator;

  /// Whether to insert [thousandSeparator] every three integer digits.
  final bool useGrouping;

  /// Whether to pad fractional digits with trailing zeros up to `precision`.
  final bool padDecimals;

  /// Minimum number of integer digits to display, padding with leading zeros.
  final int minIntegerDigits;

  /// Whether positive numbers should be prefixed with `+`.
  final bool showPlusSign;

  /// Optional custom callback that overrides standard formatting when provided.
  final NumberSpinnerLabelBuilder? customFormatter;

  /// Formats [value] according to this format configuration and [precision].
  String format(num value, {int precision = 0}) {
    final safePrecision =
        precision.clamp(0, NumberSpinnerMath.maxSupportedPrecision);
    final rounded = NumberSpinnerMath.roundToPrecision(value, safePrecision);

    if (customFormatter != null) {
      return customFormatter!(rounded);
    }

    final isNegative = rounded < 0;
    final absValue = rounded.abs();

    String raw;
    if (safePrecision == 0) {
      raw = absValue.round().toString();
    } else if (padDecimals) {
      raw = absValue.toStringAsFixed(safePrecision);
    } else {
      raw = absValue
          .toStringAsFixed(safePrecision)
          .replaceFirst(RegExp(r'\.?0+$'), '');
    }

    final parts = raw.split('.');
    var intPart = parts.first.padLeft(minIntegerDigits, '0');
    final decPart = parts.length > 1 ? parts[1] : '';

    if (useGrouping &&
        thousandSeparator.isNotEmpty &&
        intPart.length > 3 &&
        minIntegerDigits <= 1) {
      intPart = _applyGrouping(intPart, thousandSeparator);
    }

    final sign = isNegative ? '-' : (showPlusSign && rounded > 0 ? '+' : '');
    final numberPart =
        decPart.isNotEmpty ? '$intPart$decimalSeparator$decPart' : intPart;

    return '$sign$prefix$numberPart$suffix';
  }

  static String _applyGrouping(String digits, String separator) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
