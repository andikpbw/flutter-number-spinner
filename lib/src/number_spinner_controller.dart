import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'number_spinner_math.dart';
import 'number_spinner_types.dart';

/// Programmatic controller for `NumberSpinner` and `MultiDigitNumberSpinner`.
///
/// Extends [ValueNotifier] of [num] so it can be observed directly with
/// `ValueListenableBuilder<num>` or `ListenableBuilder`.
class NumberSpinnerController extends ValueNotifier<num> {
  /// Creates a [NumberSpinnerController] with the given initial [value] and bounds.
  NumberSpinnerController({
    num value = 0,
    num min = 0,
    num max = 100,
    num step = 1,
    int? precision,
    bool loop = false,
  })  : assert(step > 0, 'step must be greater than 0.'),
        _min = math.min(min, max),
        _max = math.max(min, max),
        _step = step <= 0 ? 1 : step,
        _precision = (precision ??
                NumberSpinnerMath.inferPrecision(value, min, max, step))
            .clamp(0, NumberSpinnerMath.maxSupportedPrecision),
        _loop = loop,
        _initialValue = NumberSpinnerMath.clamp(
          value,
          min: math.min(min, max),
          max: math.max(min, max),
          precision: precision ??
              NumberSpinnerMath.inferPrecision(value, min, max, step),
        ),
        super(
          NumberSpinnerMath.clamp(
            value,
            min: math.min(min, max),
            max: math.max(min, max),
            precision: precision ??
                NumberSpinnerMath.inferPrecision(value, min, max, step),
          ),
        );

  num _min;
  num _max;
  num _step;
  int _precision;
  bool _loop;
  final num _initialValue;
  OdometerScrollDirection _lastDirection = OdometerScrollDirection.none;

  /// Minimum allowed numeric value.
  num get min => _min;

  /// Maximum allowed numeric value.
  num get max => _max;

  /// Step increment size.
  num get step => _step;

  /// Number of decimal digits preserved during arithmetic and rounding.
  int get precision => _precision;

  /// Whether stepping past [max] wraps around to [min] (and vice versa).
  bool get loop => _loop;

  /// The initial value supplied when this controller was constructed.
  num get initialValue => _initialValue;

  /// Direction of the most recent value transition.
  OdometerScrollDirection get lastDirection => _lastDirection;

  /// Whether the value is currently at or below [min].
  bool get isAtMin => value <= _min;

  /// Whether the value is currently at or above [max].
  bool get isAtMax => value >= _max;

  /// Whether [increment] can change the current value.
  bool get canIncrement => _loop || value < _max;

  /// Whether [decrement] can change the current value.
  bool get canDecrement => _loop || value > _min;

  /// Total number of discrete steps between [min] and [max].
  int get totalSteps => NumberSpinnerMath.stepCount(
        min: _min,
        max: _max,
        step: _step,
        precision: _precision,
      );

  /// Current 0-based step index corresponding to [value].
  int get currentStepIndex => NumberSpinnerMath.stepIndexForValue(
        value,
        min: _min,
        max: _max,
        step: _step,
        precision: _precision,
      );

  /// Normalized progress of [value] between [min] (`0.0`) and [max] (`1.0`).
  double get progress {
    final span = _max - _min;
    if (span <= 0) return 1.0;
    return ((value - _min) / span).clamp(0.0, 1.0);
  }

  @override
  set value(num newValue) {
    setValue(newValue, snap: false);
  }

  /// Sets the spinner value to [newValue], clamping or wrapping within bounds.
  ///
  /// When [snap] is `true`, [newValue] is aligned to the nearest valid [step]
  /// increment starting from [min].
  bool setValue(num newValue, {bool snap = true}) {
    num resolved;
    if (_loop) {
      resolved = NumberSpinnerMath.wrap(
        newValue,
        min: _min,
        max: _max,
        step: _step,
        precision: _precision,
      );
    } else if (snap) {
      resolved = NumberSpinnerMath.snapToStep(
        newValue,
        min: _min,
        max: _max,
        step: _step,
        precision: _precision,
      );
    } else {
      resolved = NumberSpinnerMath.clamp(
        newValue,
        min: _min,
        max: _max,
        precision: _precision,
      );
    }

    final current = super.value;
    if (resolved == current) {
      return false;
    }

    _lastDirection = resolved > current
        ? OdometerScrollDirection.up
        : OdometerScrollDirection.down;
    super.value = resolved;
    return true;
  }

  /// Sets the spinner value to the given 0-based step [index].
  bool setStepIndex(int index) {
    final count = totalSteps;
    if (count <= 0) return false;
    final resolvedIndex =
        _loop ? ((index % count) + count) % count : index.clamp(0, count - 1);
    final target = NumberSpinnerMath.valueAtStep(
      index: resolvedIndex,
      min: _min,
      max: _max,
      step: _step,
      precision: _precision,
    );
    return setValue(target, snap: false);
  }

  /// Increments the current value by [steps] multiples of [step].
  ///
  /// Returns `true` if the value changed.
  bool increment([int steps = 1]) {
    if (steps == 0) return false;
    if (steps < 0) return decrement(-steps);
    if (!canIncrement) return false;

    final delta = NumberSpinnerMath.roundToPrecision(_step * steps, _precision);
    final candidate =
        NumberSpinnerMath.add(value, delta, precision: _precision);

    if (_loop && candidate > _max) {
      final wrapped = NumberSpinnerMath.wrap(
        candidate,
        min: _min,
        max: _max,
        step: _step,
        precision: _precision,
      );
      if (wrapped == value) return false;
      _lastDirection = OdometerScrollDirection.up;
      super.value = wrapped;
      return true;
    }

    final clamped = NumberSpinnerMath.clamp(
      candidate,
      min: _min,
      max: _max,
      precision: _precision,
    );
    if (clamped == value) return false;
    _lastDirection = OdometerScrollDirection.up;
    super.value = clamped;
    return true;
  }

  /// Decrements the current value by [steps] multiples of [step].
  ///
  /// Returns `true` if the value changed.
  bool decrement([int steps = 1]) {
    if (steps == 0) return false;
    if (steps < 0) return increment(-steps);
    if (!canDecrement) return false;

    final delta = NumberSpinnerMath.roundToPrecision(_step * steps, _precision);
    final candidate =
        NumberSpinnerMath.subtract(value, delta, precision: _precision);

    if (_loop && candidate < _min) {
      final wrapped = NumberSpinnerMath.wrap(
        candidate,
        min: _min,
        max: _max,
        step: _step,
        precision: _precision,
      );
      if (wrapped == value) return false;
      _lastDirection = OdometerScrollDirection.down;
      super.value = wrapped;
      return true;
    }

    final clamped = NumberSpinnerMath.clamp(
      candidate,
      min: _min,
      max: _max,
      precision: _precision,
    );
    if (clamped == value) return false;
    _lastDirection = OdometerScrollDirection.down;
    super.value = clamped;
    return true;
  }

  /// Resets the spinner back to [initialValue].
  void reset() {
    setValue(_initialValue, snap: false);
  }

  /// Dynamically updates one or more boundary or stepping parameters and
  /// re-clamps the current value if needed.
  void updateBounds({
    num? min,
    num? max,
    num? step,
    int? precision,
    bool? loop,
  }) {
    final nextMin = min ?? _min;
    final nextMax = max ?? _max;
    _min = math.min(nextMin, nextMax);
    _max = math.max(nextMin, nextMax);
    if (step != null && step > 0) {
      _step = step;
    }
    if (precision != null) {
      _precision = precision.clamp(0, NumberSpinnerMath.maxSupportedPrecision);
    }
    if (loop != null) {
      _loop = loop;
    }

    final clamped = NumberSpinnerMath.clamp(
      super.value,
      min: _min,
      max: _max,
      precision: _precision,
    );
    if (clamped != super.value) {
      super.value = clamped;
    } else {
      notifyListeners();
    }
  }
}
