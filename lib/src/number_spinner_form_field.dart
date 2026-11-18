import 'package:flutter/material.dart';

import 'number_spinner_controller.dart';
import 'number_spinner_format.dart';
import 'number_spinner_style.dart';
import 'number_spinner_types.dart';
import 'number_spinner_widget.dart';

/// A [FormField] wrapper around [NumberSpinner] that integrates with Flutter's
/// [Form] validation, state saving, and reset lifecycle.
class NumberSpinnerFormField extends FormField<num> {
  /// Creates a [NumberSpinnerFormField].
  NumberSpinnerFormField({
    super.key,
    this.controller,
    num initialValue = 0,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    int largeStepCount = 10,
    this.precision,
    this.loop = false,
    ValueChanged<num>? onChanged,
    ValueChanged<num>? onSubmitted,
    NumberSpinnerLayout layout = NumberSpinnerLayout.odometer,
    NumberSpinnerSize size = NumberSpinnerSize.medium,
    NumberSpinnerButtonPosition buttonPosition =
        NumberSpinnerButtonPosition.sides,
    NumberSpinnerFormat format = const NumberSpinnerFormat.standard(),
    NumberSpinnerStyle style = const NumberSpinnerStyle(),
    super.enabled = true,
    bool readOnly = false,
    bool allowDirectInput = true,
    bool enableDragGesture = true,
    bool enableLongPressRepeat = true,
    bool enableTurbo = true,
    bool enableMouseWheel = true,
    bool enableKeyboardShortcuts = true,
    bool enableHapticFeedback = false,
    String? labelText,
    String? helperText,
    Widget? prefix,
    Widget? suffix,
    FocusNode? focusNode,
    bool autofocus = false,
    String? semanticLabel,
    super.onSaved,
    super.validator,
    super.autovalidateMode,
    super.restorationId,
  }) : super(
          initialValue: controller != null ? controller.value : initialValue,
          builder: (FormFieldState<num> field) {
            final state = field as _NumberSpinnerFormFieldState;
            return NumberSpinner(
              controller: state._effectiveController,
              min: min,
              max: max,
              step: step,
              largeStepCount: largeStepCount,
              precision: precision,
              loop: loop,
              layout: layout,
              size: size,
              buttonPosition: buttonPosition,
              format: format,
              style: style,
              enabled: enabled,
              readOnly: readOnly,
              allowDirectInput: allowDirectInput,
              enableDragGesture: enableDragGesture,
              enableLongPressRepeat: enableLongPressRepeat,
              enableTurbo: enableTurbo,
              enableMouseWheel: enableMouseWheel,
              enableKeyboardShortcuts: enableKeyboardShortcuts,
              enableHapticFeedback: enableHapticFeedback,
              labelText: labelText,
              helperText: helperText,
              errorText: field.errorText,
              prefix: prefix,
              suffix: suffix,
              focusNode: focusNode,
              autofocus: autofocus,
              semanticLabel: semanticLabel,
              onChanged: (val) {
                field.didChange(val);
                onChanged?.call(val);
              },
              onSubmitted: onSubmitted,
            );
          },
        );

  /// Optional external controller bound to this form field.
  final NumberSpinnerController? controller;

  /// Minimum allowed numeric value.
  final num min;

  /// Maximum allowed numeric value.
  final num max;

  /// Step increment size.
  final num step;

  /// Optional explicit decimal precision.
  final int? precision;

  /// Whether stepping past [max] wraps around to [min].
  final bool loop;

  @override
  FormFieldState<num> createState() => _NumberSpinnerFormFieldState();
}

class _NumberSpinnerFormFieldState extends FormFieldState<num> {
  NumberSpinnerController? _internalController;

  NumberSpinnerFormField get _formField => widget as NumberSpinnerFormField;

  NumberSpinnerController get _effectiveController =>
      _formField.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (_formField.controller == null) {
      _internalController = NumberSpinnerController(
        value: widget.initialValue ?? 0,
        min: _formField.min,
        max: _formField.max,
        step: _formField.step,
        precision: _formField.precision,
        loop: _formField.loop,
      );
    } else {
      _formField.controller!.addListener(_handleExternalControllerChanged);
    }
  }

  @override
  void didUpdateWidget(covariant NumberSpinnerFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_formField.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleExternalControllerChanged);
      if (_formField.controller != null) {
        _internalController?.dispose();
        _internalController = null;
        _formField.controller!.addListener(_handleExternalControllerChanged);
        setValue(_formField.controller!.value);
      } else {
        _internalController = NumberSpinnerController(
          value: value ?? widget.initialValue ?? 0,
          min: _formField.min,
          max: _formField.max,
          step: _formField.step,
          precision: _formField.precision,
          loop: _formField.loop,
        );
      }
    } else if (_internalController != null) {
      _internalController!.updateBounds(
        min: _formField.min,
        max: _formField.max,
        step: _formField.step,
        precision: _formField.precision,
        loop: _formField.loop,
      );
    }
  }

  @override
  void dispose() {
    _formField.controller?.removeListener(_handleExternalControllerChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _handleExternalControllerChanged() {
    final externalVal = _formField.controller!.value;
    if (externalVal != value) {
      didChange(externalVal);
    }
  }

  @override
  void reset() {
    super.reset();
    final initial = widget.initialValue ?? 0;
    _effectiveController.setValue(initial, snap: false);
  }
}
