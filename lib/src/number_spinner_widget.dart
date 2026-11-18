import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'number_spinner_controller.dart';
import 'number_spinner_format.dart';
import 'number_spinner_math.dart';
import 'number_spinner_style.dart';
import 'number_spinner_types.dart';
import 'odometer_text.dart';
import 'spin_wheel_number_spinner.dart';

const Color _kWhite = Color(0xFFFFFFFF);
const Color _kBlack = Color(0xFF000000);
const Color _kTransparent = Color(0x00000000);

const IconData _kIconAddRounded = IconData(
  0xf537,
  fontFamily: 'MaterialIcons',
);
const IconData _kIconRemoveRounded = IconData(
  0xf00f1,
  fontFamily: 'MaterialIcons',
);
const IconData _kIconArrowUpRounded = IconData(
  0xf82e,
  fontFamily: 'MaterialIcons',
);
const IconData _kIconArrowDownRounded = IconData(
  0xf82b,
  fontFamily: 'MaterialIcons',
);
const IconData _kIconArrowLeftRounded = IconData(
  0xf82c,
  fontFamily: 'MaterialIcons',
);
const IconData _kIconArrowRightRounded = IconData(
  0xf82d,
  fontFamily: 'MaterialIcons',
);
const IconData _kIconArrowDropDownRounded = IconData(
  0xf577,
  fontFamily: 'MaterialIcons',
);

/// A modern, eye-catching animated number spinner widget for Flutter.
///
/// Supports four distinct visual layouts via [NumberSpinnerLayout]:
/// - [NumberSpinnerLayout.odometer]: Animated rolling-digit capsule with
///   drag-to-spin gestures, optional direct text editing, and stepper buttons.
/// - [NumberSpinnerLayout.wheelVertical]: 3D vertical cylindrical drum picker
///   with a central magnification lens and gradient edge fades.
/// - [NumberSpinnerLayout.wheelHorizontal]: 3D horizontal carousel wheel picker.
/// - [NumberSpinnerLayout.ruler]: Interactive sliding tick-mark gauge ruler
///   with a center indicator needle and live digital readout header.
class NumberSpinner extends StatefulWidget {
  /// Creates a [NumberSpinner].
  const NumberSpinner({
    super.key,
    this.controller,
    this.initialValue = 0,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.largeStepCount = 10,
    this.precision,
    this.loop = false,
    this.onChanged,
    this.onSubmitted,
    this.layout = NumberSpinnerLayout.odometer,
    this.size = NumberSpinnerSize.medium,
    this.buttonPosition = NumberSpinnerButtonPosition.sides,
    this.format = const NumberSpinnerFormat.standard(),
    this.style = const NumberSpinnerStyle(),
    this.enabled = true,
    this.readOnly = false,
    this.allowDirectInput = true,
    this.enableDragGesture = true,
    this.enableLongPressRepeat = true,
    this.enableTurbo = true,
    this.enableMouseWheel = true,
    this.enableKeyboardShortcuts = true,
    this.enableHapticFeedback = false,
    this.longPressDelay = const Duration(milliseconds: 350),
    this.repeatInterval = const Duration(milliseconds: 85),
    this.labelText,
    this.helperText,
    this.errorText,
    this.prefix,
    this.suffix,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  })  : assert(step > 0, 'step must be greater than 0.'),
        assert(largeStepCount >= 1, 'largeStepCount must be at least 1.');

  /// Optional external controller for programmatic value and bound management.
  final NumberSpinnerController? controller;

  /// Initial numeric value used when [controller] is not provided.
  final num initialValue;

  /// Minimum allowed value (used when [controller] is not provided).
  final num min;

  /// Maximum allowed value (used when [controller] is not provided).
  final num max;

  /// Step increment size (used when [controller] is not provided).
  final num step;

  /// Number of steps applied when pressing `PageUp` or `PageDown`, or during
  /// high-speed turbo repeat.
  final int largeStepCount;

  /// Optional explicit number of decimal places. When `null`, inferred from
  /// [initialValue], [min], [max], and [step].
  final int? precision;

  /// Whether stepping past [max] wraps around to [min] (and vice versa).
  final bool loop;

  /// Called whenever the spinner value changes.
  final ValueChanged<num>? onChanged;

  /// Called when the user commits a value via direct keyboard input or Enter key.
  final ValueChanged<num>? onSubmitted;

  /// Visual layout mode of the spinner.
  final NumberSpinnerLayout layout;

  /// Predefined sizing preset (`small`, `medium`, or `large`).
  final NumberSpinnerSize size;

  /// Placement of the increment (`+`) and decrement (`-`) buttons.
  final NumberSpinnerButtonPosition buttonPosition;

  /// Number formatting configuration (currency, percentage, units, padding).
  final NumberSpinnerFormat format;

  /// Visual styling and theme preset configuration.
  final NumberSpinnerStyle style;

  /// Whether the spinner accepts user interaction.
  final bool enabled;

  /// Whether the spinner value cannot be modified by user gestures or buttons.
  final bool readOnly;

  /// Whether tapping the active value in [NumberSpinnerLayout.odometer] opens
  /// an inline numeric text input for direct entry.
  final bool allowDirectInput;

  /// Whether dragging across the value area in [NumberSpinnerLayout.odometer]
  /// spins the value continuously.
  final bool enableDragGesture;

  /// Whether holding down `+` or `-` continuously repeats the step action.
  final bool enableLongPressRepeat;

  /// Whether long-press auto-repeat accelerates after sustained holding.
  final bool enableTurbo;

  /// Whether scrolling the mouse wheel over the spinner steps the value.
  final bool enableMouseWheel;

  /// Whether arrow keys, `PageUp`/`PageDown`, and `Home`/`End` step the value.
  final bool enableKeyboardShortcuts;

  /// Whether to trigger light haptic selection feedback on step changes.
  final bool enableHapticFeedback;

  /// Initial delay before long-press auto-repeat begins.
  final Duration longPressDelay;

  /// Tick interval between repeated steps during a long press.
  final Duration repeatInterval;

  /// Optional label displayed above the spinner.
  final String? labelText;

  /// Optional helper caption displayed below the spinner.
  final String? helperText;

  /// Optional validation error message displayed below the spinner.
  final String? errorText;

  /// Optional leading widget placed inside the spinner value display.
  final Widget? prefix;

  /// Optional trailing widget placed inside the spinner value display.
  final Widget? suffix;

  /// Optional focus node for keyboard navigation and focus state tracking.
  final FocusNode? focusNode;

  /// Whether this spinner should focus itself automatically on mount.
  final bool autofocus;

  /// Optional accessibility label announced by screen readers.
  final String? semanticLabel;

  @override
  State<NumberSpinner> createState() => _NumberSpinnerState();
}

class _NumberSpinnerState extends State<NumberSpinner> {
  NumberSpinnerController? _internalController;
  FocusNode? _internalFocusNode;
  FixedExtentScrollController? _wheelController;
  TextEditingController? _directEditController;
  FocusNode? _directEditFocusNode;

  Timer? _longPressTimer;
  Timer? _repeatTimer;
  int _repeatTicks = 0;
  double _dragAccumulator = 0;

  bool _isFocused = false;
  bool _isEditingDirectly = false;
  bool _isSyncingWheel = false;
  num? _lastNotifiedValue;

  NumberSpinnerController get _controller =>
      widget.controller ?? _internalController!;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  bool get _isInteractive => widget.enabled && !widget.readOnly;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = NumberSpinnerController(
        value: widget.initialValue,
        min: widget.min,
        max: widget.max,
        step: widget.step,
        precision: widget.precision,
        loop: widget.loop,
      );
    }
    _lastNotifiedValue = _controller.value;
    _controller.addListener(_handleControllerChanged);

    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _focusNode.addListener(_handleFocusChanged);

    _initWheelControllerIfNeeded();
  }

  void _initWheelControllerIfNeeded() {
    final usesWheel = widget.layout == NumberSpinnerLayout.wheelVertical ||
        widget.layout == NumberSpinnerLayout.wheelHorizontal ||
        widget.layout == NumberSpinnerLayout.ruler;
    if (usesWheel) {
      _wheelController?.dispose();
      _wheelController = FixedExtentScrollController(
        initialItem: _controller.currentStepIndex,
      );
    } else {
      _wheelController?.dispose();
      _wheelController = null;
    }
  }

  @override
  void didUpdateWidget(covariant NumberSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      if (widget.controller == null) {
        _internalController ??= NumberSpinnerController(
          value: widget.initialValue,
          min: widget.min,
          max: widget.max,
          step: widget.step,
          precision: widget.precision,
          loop: widget.loop,
        );
      } else {
        _internalController?.dispose();
        _internalController = null;
      }
      _lastNotifiedValue = _controller.value;
      _controller.addListener(_handleControllerChanged);
    } else if (widget.controller == null && _internalController != null) {
      if (widget.min != oldWidget.min ||
          widget.max != oldWidget.max ||
          widget.step != oldWidget.step ||
          widget.precision != oldWidget.precision ||
          widget.loop != oldWidget.loop) {
        _internalController!.updateBounds(
          min: widget.min,
          max: widget.max,
          step: widget.step,
          precision: widget.precision,
          loop: widget.loop,
        );
      }
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      if (widget.focusNode == null) {
        _internalFocusNode ??= FocusNode();
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChanged);
    }

    if (widget.layout != oldWidget.layout) {
      _initWheelControllerIfNeeded();
    }
  }

  @override
  void dispose() {
    _stopRepeatTimers();
    _controller.removeListener(_handleControllerChanged);
    _internalController?.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _internalFocusNode?.dispose();
    _wheelController?.dispose();
    _directEditController?.dispose();
    _directEditFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final current = _controller.value;
    final valueChanged = current != _lastNotifiedValue;
    _lastNotifiedValue = current;

    if (!_isSyncingWheel &&
        _wheelController != null &&
        _wheelController!.hasClients) {
      final targetIndex = _controller.currentStepIndex;
      final total = _controller.totalSteps;
      final currentWheelItem = _wheelController!.selectedItem;
      final normalizedWheelItem =
          total > 0 ? ((currentWheelItem % total) + total) % total : 0;
      if (normalizedWheelItem != targetIndex) {
        _isSyncingWheel = true;
        _wheelController!.jumpToItem(targetIndex);
        _isSyncingWheel = false;
      }
    }

    setState(() {});
    if (valueChanged) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
      widget.onChanged?.call(current);
    }
  }

  void _stepBy(int steps) {
    if (!_isInteractive || steps == 0) return;
    if (_isEditingDirectly) {
      _commitDirectInput();
    }
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    if (steps > 0) {
      _controller.increment(steps);
    } else {
      _controller.decrement(-steps);
    }
  }

  void _startLongPressRepeat({required bool isIncrement}) {
    if (!_isInteractive || !widget.enableLongPressRepeat) return;
    _stopRepeatTimers();
    _repeatTicks = 0;

    _longPressTimer = Timer(widget.longPressDelay, () {
      _repeatTimer = Timer.periodic(widget.repeatInterval, (timer) {
        if (!mounted || !_isInteractive) {
          _stopRepeatTimers();
          return;
        }
        final canContinue =
            isIncrement ? _controller.canIncrement : _controller.canDecrement;
        if (!canContinue) {
          _stopRepeatTimers();
          return;
        }
        _repeatTicks++;
        final multiplier = (widget.enableTurbo && _repeatTicks > 24)
            ? widget.largeStepCount
            : (widget.enableTurbo && _repeatTicks > 10 ? 2 : 1);
        _stepBy(isIncrement ? multiplier : -multiplier);
      });
    });
  }

  void _stopRepeatTimers() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _repeatTicks = 0;
  }

  void _beginDirectInput() {
    if (!_isInteractive ||
        !widget.allowDirectInput ||
        widget.layout != NumberSpinnerLayout.odometer) {
      return;
    }
    final rawText = _controller.precision == 0
        ? _controller.value.round().toString()
        : _controller.value.toStringAsFixed(_controller.precision);
    _directEditController?.dispose();
    _directEditController = TextEditingController(text: rawText)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: rawText.length,
      );
    _directEditFocusNode?.dispose();
    _directEditFocusNode = FocusNode()
      ..addListener(() {
        if (_directEditFocusNode != null &&
            !_directEditFocusNode!.hasFocus &&
            _isEditingDirectly) {
          _commitDirectInput();
        }
      });

    setState(() {
      _isEditingDirectly = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isEditingDirectly) {
        _directEditFocusNode?.requestFocus();
      }
    });
  }

  void _commitDirectInput() {
    if (!_isEditingDirectly) return;
    final raw = _directEditController?.text.trim() ?? '';
    final normalized = raw
        .replaceAll(widget.format.prefix, '')
        .replaceAll(widget.format.suffix, '')
        .replaceAll(widget.format.thousandSeparator, '')
        .replaceAll(widget.format.decimalSeparator, '.')
        .trim();
    final parsed = num.tryParse(normalized);
    setState(() {
      _isEditingDirectly = false;
    });
    if (parsed != null) {
      _controller.setValue(parsed);
      widget.onSubmitted?.call(_controller.value);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_isInteractive ||
        !widget.enableKeyboardShortcuts ||
        _isEditingDirectly) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight) {
      _stepBy(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft) {
      _stepBy(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _stepBy(widget.largeStepCount);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _stepBy(-widget.largeStepCount);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _controller.setValue(_controller.min, snap: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _controller.setValue(_controller.max, snap: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      widget.onSubmitted?.call(_controller.value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!_isInteractive || !widget.enableMouseWheel) return;
    if (event is PointerScrollEvent) {
      final dy = event.scrollDelta.dy;
      final dx = event.scrollDelta.dx;
      final delta = dy != 0 ? dy : dx;
      if (delta < 0) {
        _stepBy(1);
      } else if (delta > 0) {
        _stepBy(-1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = DefaultTextStyle.of(context).style;
    final baseTextColor = baseTextStyle.color ?? const Color(0xFF0F172A);
    final isDark = baseTextColor.computeLuminance() > 0.5 ||
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final palette = _AmbientPalette.fromBrightness(isDark: isDark);
    final hasError =
        widget.errorText != null && widget.errorText!.trim().isNotEmpty;
    final metrics = _resolveMetrics(widget.size, widget.layout, widget.style);
    final colors = _resolveColors(palette, hasError);

    final formattedValue = widget.format.format(
      _controller.value,
      precision: _controller.precision,
    );

    Widget coreContainer = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: metrics.width,
      height: metrics.height,
      decoration: BoxDecoration(
        color: widget.style.backgroundGradient == null
            ? colors.backgroundColor
            : null,
        gradient: widget.style.backgroundGradient,
        borderRadius: metrics.borderRadius,
        border: metrics.borderWidth > 0
            ? Border.all(
                color: colors.borderColor,
                width: metrics.borderWidth,
              )
            : null,
        boxShadow: colors.boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: widget.style.padding ?? EdgeInsets.zero,
              child: _buildLayoutContent(context, metrics, colors),
            ),
          ),
          if (widget.style.showProgressIndicator)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildProgressBar(colors),
            ),
        ],
      ),
    );

    if (!widget.enabled) {
      coreContainer = Opacity(
        opacity: 0.55,
        child: IgnorePointer(child: coreContainer),
      );
    }

    final canInc = _isInteractive && _controller.canIncrement;
    final canDec = _isInteractive && _controller.canDecrement;
    final nextIncValue = canInc
        ? (_controller.loop
            ? NumberSpinnerMath.wrap(
                NumberSpinnerMath.add(
                  _controller.value,
                  _controller.step,
                  precision: _controller.precision,
                ),
                min: _controller.min,
                max: _controller.max,
                step: _controller.step,
                precision: _controller.precision,
              )
            : NumberSpinnerMath.clamp(
                NumberSpinnerMath.add(
                  _controller.value,
                  _controller.step,
                  precision: _controller.precision,
                ),
                min: _controller.min,
                max: _controller.max,
                precision: _controller.precision,
              ))
        : null;
    final nextDecValue = canDec
        ? (_controller.loop
            ? NumberSpinnerMath.wrap(
                NumberSpinnerMath.subtract(
                  _controller.value,
                  _controller.step,
                  precision: _controller.precision,
                ),
                min: _controller.min,
                max: _controller.max,
                step: _controller.step,
                precision: _controller.precision,
              )
            : NumberSpinnerMath.clamp(
                NumberSpinnerMath.subtract(
                  _controller.value,
                  _controller.step,
                  precision: _controller.precision,
                ),
                min: _controller.min,
                max: _controller.max,
                precision: _controller.precision,
              ))
        : null;

    final interactiveSpinner = Semantics(
      label: widget.semanticLabel ?? widget.labelText ?? 'Number Spinner',
      value: formattedValue,
      increasedValue: nextIncValue != null
          ? widget.format.format(
              nextIncValue,
              precision: _controller.precision,
            )
          : null,
      decreasedValue: nextDecValue != null
          ? widget.format.format(
              nextDecValue,
              precision: _controller.precision,
            )
          : null,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onIncrease: canInc ? () => _stepBy(1) : null,
      onDecrease: canDec ? () => _stepBy(-1) : null,
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          canRequestFocus: widget.enabled,
          onKeyEvent: _handleKeyEvent,
          child: coreContainer,
        ),
      ),
    );

    if (widget.labelText == null && widget.helperText == null && !hasError) {
      return interactiveSpinner;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: baseTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasError
                  ? palette.error
                  : (_isFocused
                      ? colors.accentColor
                      : palette.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 6),
        ],
        interactiveSpinner,
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: baseTextStyle.copyWith(
              fontSize: 12,
              color: palette.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: baseTextStyle.copyWith(
              fontSize: 12,
              color: palette.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLayoutContent(
    BuildContext context,
    _SpinnerMetrics metrics,
    _SpinnerColors colors,
  ) {
    switch (widget.layout) {
      case NumberSpinnerLayout.odometer:
        return _buildOdometerLayout(context, metrics, colors);
      case NumberSpinnerLayout.wheelVertical:
        return _buildVerticalWheelLayout(context, metrics, colors);
      case NumberSpinnerLayout.wheelHorizontal:
        return _buildHorizontalWheelLayout(context, metrics, colors);
      case NumberSpinnerLayout.ruler:
        return _buildRulerLayout(context, metrics, colors);
      case NumberSpinnerLayout.spinWheel:
        return Center(
          child: SpinWheelNumberSpinner(
            min: _controller.min,
            max: _controller.max,
            step: _controller.step,
            initialValue: _controller.value,
            format: widget.format,
            wheelSize: math.min(metrics.width ?? 220, metrics.height - 16),
            showControlBar: false,
            showResultBadge: false,
            enabled: _isInteractive,
            enableHapticFeedback: widget.enableHapticFeedback,
            onChanged: (val) => _controller.setValue(val, snap: false),
            onSpinEnd: (val) => widget.onSubmitted?.call(val),
          ),
        );
    }
  }

  Widget _buildOdometerLayout(
    BuildContext context,
    _SpinnerMetrics metrics,
    _SpinnerColors colors,
  ) {
    final centerDisplay = _buildOdometerValueArea(context, metrics, colors);

    switch (widget.buttonPosition) {
      case NumberSpinnerButtonPosition.sides:
        return Row(
          mainAxisSize:
              widget.style.width == null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            _buildStepperButton(
              isIncrement: false,
              metrics: metrics,
              colors: colors,
              icon: widget.style.decrementIcon ?? _kIconRemoveRounded,
            ),
            if (widget.style.width != null)
              Expanded(child: centerDisplay)
            else
              Flexible(child: centerDisplay),
            _buildStepperButton(
              isIncrement: true,
              metrics: metrics,
              colors: colors,
              icon: widget.style.incrementIcon ?? _kIconAddRounded,
            ),
          ],
        );

      case NumberSpinnerButtonPosition.stackedEnd:
        return Row(
          mainAxisSize:
              widget.style.width == null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (widget.style.width != null)
              Expanded(child: centerDisplay)
            else
              Flexible(child: centerDisplay),
            Container(
              width: 1,
              height: double.infinity,
              color: colors.borderColor.withValues(alpha: 0.35),
            ),
            SizedBox(
              width: metrics.buttonSize,
              child: Column(
                children: [
                  Expanded(
                    child: _buildStepperButton(
                      isIncrement: true,
                      metrics: metrics,
                      colors: colors,
                      icon: widget.style.incrementIcon ?? _kIconArrowUpRounded,
                      compact: true,
                    ),
                  ),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: colors.borderColor.withValues(alpha: 0.35),
                  ),
                  Expanded(
                    child: _buildStepperButton(
                      isIncrement: false,
                      metrics: metrics,
                      colors: colors,
                      icon:
                          widget.style.decrementIcon ?? _kIconArrowDownRounded,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case NumberSpinnerButtonPosition.topBottom:
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildStepperButton(
              isIncrement: true,
              metrics: metrics,
              colors: colors,
              icon: widget.style.incrementIcon ?? _kIconArrowUpRounded,
              fullWidth: true,
            ),
            Expanded(child: centerDisplay),
            _buildStepperButton(
              isIncrement: false,
              metrics: metrics,
              colors: colors,
              icon: widget.style.decrementIcon ?? _kIconArrowDownRounded,
              fullWidth: true,
            ),
          ],
        );

      case NumberSpinnerButtonPosition.none:
        return centerDisplay;
    }
  }

  Widget _buildOdometerValueArea(
    BuildContext context,
    _SpinnerMetrics metrics,
    _SpinnerColors colors,
  ) {
    Widget valueChild;
    if (_isEditingDirectly && _directEditController != null) {
      valueChild = SizedBox(
        width: math.max(64, metrics.minCenterWidth),
        child: EditableText(
          controller: _directEditController!,
          focusNode: _directEditFocusNode!,
          textAlign: TextAlign.center,
          style: colors.selectedTextStyle,
          cursorColor: colors.accentColor,
          backgroundCursorColor: colors.unselectedTextStyle.color ?? _kBlack,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          onSubmitted: (_) => _commitDirectInput(),
        ),
      );
    } else {
      valueChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.prefix != null) ...[
            widget.prefix!,
            const SizedBox(width: 6),
          ],
          OdometerNumberText(
            value: _controller.value,
            format: widget.format,
            precision: _controller.precision,
            direction: _controller.lastDirection,
            style: colors.selectedTextStyle,
            duration: widget.style.animationDuration,
            curve: widget.style.animationCurve,
          ),
          if (widget.suffix != null) ...[
            const SizedBox(width: 6),
            widget.suffix!,
          ],
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _beginDirectInput,
      onVerticalDragStart: widget.enableDragGesture && _isInteractive
          ? (_) => _dragAccumulator = 0
          : null,
      onVerticalDragUpdate: widget.enableDragGesture && _isInteractive
          ? (details) {
              _dragAccumulator -= details.delta.dy;
              const threshold = 16.0;
              final steps = (_dragAccumulator / threshold).truncate();
              if (steps != 0) {
                _dragAccumulator -= steps * threshold;
                _stepBy(steps);
              }
            }
          : null,
      onHorizontalDragStart: widget.enableDragGesture && _isInteractive
          ? (_) => _dragAccumulator = 0
          : null,
      onHorizontalDragUpdate: widget.enableDragGesture && _isInteractive
          ? (details) {
              _dragAccumulator += details.delta.dx;
              const threshold = 18.0;
              final steps = (_dragAccumulator / threshold).truncate();
              if (steps != 0) {
                _dragAccumulator -= steps * threshold;
                _stepBy(steps);
              }
            }
          : null,
      child: Container(
        constraints: BoxConstraints(minWidth: metrics.minCenterWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.selectionHighlightColor,
            borderRadius:
                widget.style.selectionBorderRadius ?? BorderRadius.circular(10),
            border: colors.selectionBorderColor != _kTransparent
                ? Border.all(color: colors.selectionBorderColor, width: 1)
                : null,
          ),
          child: valueChild,
        ),
      ),
    );
  }

  Widget _buildVerticalWheelLayout(
    BuildContext context,
    _SpinnerMetrics metrics,
    _SpinnerColors colors,
  ) {
    final wheelCore = Stack(
      alignment: Alignment.center,
      children: [
        // Central selection lens
        IgnorePointer(
          child: Container(
            height: metrics.itemExtent,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colors.selectionHighlightColor,
              borderRadius: widget.style.selectionBorderRadius ??
                  BorderRadius.circular(12),
              border: Border.all(
                color: colors.selectionBorderColor,
                width: 1.2,
              ),
            ),
          ),
        ),
        _wrapWithEdgeFade(
          axis: Axis.vertical,
          enabled: widget.style.fadeEdges,
          child: _buildListWheel(
            axis: Axis.vertical,
            metrics: metrics,
            colors: colors,
          ),
        ),
      ],
    );

    if (widget.buttonPosition == NumberSpinnerButtonPosition.topBottom) {
      return Column(
        children: [
          _buildStepperButton(
            isIncrement: true,
            metrics: metrics,
            colors: colors,
            icon: widget.style.incrementIcon ?? _kIconArrowUpRounded,
            fullWidth: true,
          ),
          Expanded(child: wheelCore),
          _buildStepperButton(
            isIncrement: false,
            metrics: metrics,
            colors: colors,
            icon: widget.style.decrementIcon ?? _kIconArrowDownRounded,
            fullWidth: true,
          ),
        ],
      );
    }

    if (widget.buttonPosition == NumberSpinnerButtonPosition.sides) {
      return Row(
        children: [
          _buildStepperButton(
            isIncrement: false,
            metrics: metrics,
            colors: colors,
            icon: widget.style.decrementIcon ?? _kIconRemoveRounded,
          ),
          Expanded(child: wheelCore),
          _buildStepperButton(
            isIncrement: true,
            metrics: metrics,
            colors: colors,
            icon: widget.style.incrementIcon ?? _kIconAddRounded,
          ),
        ],
      );
    }

    return wheelCore;
  }

  Widget _buildHorizontalWheelLayout(
    BuildContext context,
    _SpinnerMetrics metrics,
    _SpinnerColors colors,
  ) {
    final wheelCore = Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Container(
            width: metrics.itemExtent,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: colors.selectionHighlightColor,
              borderRadius: widget.style.selectionBorderRadius ??
                  BorderRadius.circular(12),
              border: Border.all(
                color: colors.selectionBorderColor,
                width: 1.2,
              ),
            ),
          ),
        ),
        _wrapWithEdgeFade(
          axis: Axis.horizontal,
          enabled: widget.style.fadeEdges,
          child: RotatedBox(
            quarterTurns: 3,
            child: _buildListWheel(
              axis: Axis.horizontal,
              metrics: metrics,
              colors: colors,
            ),
          ),
        ),
      ],
    );

    if (widget.buttonPosition == NumberSpinnerButtonPosition.sides) {
      return Row(
        children: [
          _buildStepperButton(
            isIncrement: false,
            metrics: metrics,
            colors: colors,
            icon: widget.style.decrementIcon ?? _kIconArrowLeftRounded,
          ),
          Expanded(child: wheelCore),
          _buildStepperButton(
            isIncrement: true,
            metrics: metrics,
            colors: colors,
            icon: widget.style.incrementIcon ?? _kIconArrowRightRounded,
          ),
        ],
      );
    }

    return wheelCore;
  }

  Widget _buildRulerLayout(
    BuildContext context,
    _SpinnerMetrics metrics,
    _SpinnerColors colors,
  ) {
    final total = _controller.totalSteps;
    final currentIdx = _controller.currentStepIndex;
    final majorInterval = widget.style.rulerMajorTickInterval;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.buttonPosition != NumberSpinnerButtonPosition.none)
            _buildCompactCircleButton(
              isIncrement: false,
              colors: colors,
              icon: widget.style.decrementIcon ?? _kIconRemoveRounded,
            )
          else
            const SizedBox(width: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: colors.selectionHighlightColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colors.selectionBorderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.prefix != null) ...[
                  widget.prefix!,
                  const SizedBox(width: 4),
                ],
                OdometerNumberText(
                  value: _controller.value,
                  format: widget.format,
                  precision: _controller.precision,
                  direction: _controller.lastDirection,
                  style: colors.selectedTextStyle,
                  duration: widget.style.animationDuration,
                  curve: widget.style.animationCurve,
                ),
                if (widget.suffix != null) ...[
                  const SizedBox(width: 4),
                  widget.suffix!,
                ],
              ],
            ),
          ),
          if (widget.buttonPosition != NumberSpinnerButtonPosition.none)
            _buildCompactCircleButton(
              isIncrement: true,
              colors: colors,
              icon: widget.style.incrementIcon ?? _kIconAddRounded,
            )
          else
            const SizedBox(width: 28),
        ],
      ),
    );

    final rulerTrack = Stack(
      alignment: Alignment.center,
      children: [
        _wrapWithEdgeFade(
          axis: Axis.horizontal,
          enabled: widget.style.fadeEdges,
          child: RotatedBox(
            quarterTurns: 3,
            child: ListWheelScrollView.useDelegate(
              controller: _wheelController,
              itemExtent: metrics.rulerTickSpacing,
              perspective: 0.0005,
              diameterRatio: 8.0,
              physics: _isInteractive
                  ? const FixedExtentScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onSelectedItemChanged: (rawIndex) {
                if (_isSyncingWheel || !_isInteractive) return;
                _isSyncingWheel = true;
                _controller.setStepIndex(rawIndex);
                _isSyncingWheel = false;
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: total,
                builder: (context, index) {
                  if (index < 0 || index >= total) return null;
                  final isMajor = index % majorInterval == 0;
                  final isSelected = index == currentIdx;
                  final stepValue = NumberSpinnerMath.valueAtStep(
                    index: index,
                    min: _controller.min,
                    max: _controller.max,
                    step: _controller.step,
                    precision: _controller.precision,
                  );

                  return RotatedBox(
                    quarterTurns: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _isInteractive
                          ? () => _animateWheelToIndex(index)
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: isSelected ? 2.5 : (isMajor ? 2.0 : 1.2),
                            height: isSelected ? 24.0 : (isMajor ? 18.0 : 10.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.rulerIndicatorColor
                                  : (isMajor
                                      ? colors.rulerMajorTickColor
                                      : colors.rulerMinorTickColor),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 3),
                          SizedBox(
                            height: 15,
                            child: isMajor
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      widget.format.format(
                                        stepValue,
                                        precision: _controller.precision,
                                      ),
                                      style:
                                          colors.unselectedTextStyle.copyWith(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? colors.accentColor
                                            : colors.unselectedTextStyle.color,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Center indicator pointer needle
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _kIconArrowDropDownRounded,
                  size: 20,
                  color: colors.rulerIndicatorColor,
                ),
                Container(
                  width: 2.5,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.rulerIndicatorColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: colors.rulerIndicatorColor.withValues(
                          alpha: 0.45,
                        ),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Column(
      children: [
        header,
        Expanded(child: rulerTrack),
      ],
    );
  }

  Widget _buildListWheel({
    required Axis axis,
    required _SpinnerMetrics metrics,
    required _SpinnerColors colors,
  }) {
    final total = _controller.totalSteps;
    final currentIdx = _controller.currentStepIndex;
    final useLoopDelegate = _controller.loop && total > 1 && total <= 200;

    Widget buildWheelItem(BuildContext context, int index) {
      final normalizedIndex = total > 0 ? ((index % total) + total) % total : 0;
      final isSelected = normalizedIndex == currentIdx;
      final itemValue = NumberSpinnerMath.valueAtStep(
        index: normalizedIndex,
        min: _controller.min,
        max: _controller.max,
        step: _controller.step,
        precision: _controller.precision,
      );
      final label = widget.format.format(
        itemValue,
        precision: _controller.precision,
      );

      Widget itemContent = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:
            _isInteractive ? () => _animateWheelToIndex(normalizedIndex) : null,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: isSelected
                ? colors.selectedTextStyle
                : colors.unselectedTextStyle,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      if (axis == Axis.horizontal) {
        itemContent = RotatedBox(
          quarterTurns: 1,
          child: itemContent,
        );
      }

      return itemContent;
    }

    final delegate = useLoopDelegate
        ? ListWheelChildLoopingListDelegate(
            children: List<Widget>.generate(
              total,
              (index) => buildWheelItem(context, index),
            ),
          )
        : ListWheelChildBuilderDelegate(
            childCount: total,
            builder: (context, index) {
              if (index < 0 || index >= total) return null;
              return buildWheelItem(context, index);
            },
          );

    return ListWheelScrollView.useDelegate(
      controller: _wheelController,
      itemExtent: metrics.itemExtent,
      perspective: widget.style.perspective,
      diameterRatio: widget.style.diameterRatio,
      magnification: widget.style.magnification,
      useMagnifier: widget.style.useMagnifier,
      squeeze: widget.style.squeeze,
      physics: _isInteractive
          ? const FixedExtentScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      onSelectedItemChanged: (rawIndex) {
        if (_isSyncingWheel || !_isInteractive) return;
        _isSyncingWheel = true;
        _controller.setStepIndex(rawIndex);
        _isSyncingWheel = false;
      },
      childDelegate: delegate,
    );
  }

  void _animateWheelToIndex(int targetIndex) {
    if (_wheelController != null && _wheelController!.hasClients) {
      _wheelController!.animateToItem(
        targetIndex,
        duration: widget.style.animationDuration,
        curve: widget.style.animationCurve,
      );
    } else {
      _controller.setStepIndex(targetIndex);
    }
  }

  Widget _wrapWithEdgeFade({
    required Axis axis,
    required bool enabled,
    required Widget child,
  }) {
    if (!enabled) return child;
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: axis == Axis.vertical
              ? Alignment.topCenter
              : Alignment.centerLeft,
          end: axis == Axis.vertical
              ? Alignment.bottomCenter
              : Alignment.centerRight,
          colors: const [
            _kTransparent,
            _kBlack,
            _kBlack,
            _kTransparent,
          ],
          stops: const [0.0, 0.22, 0.78, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }

  Widget _buildStepperButton({
    required bool isIncrement,
    required _SpinnerMetrics metrics,
    required _SpinnerColors colors,
    required IconData icon,
    bool compact = false,
    bool fullWidth = false,
  }) {
    final canAct = _isInteractive &&
        (isIncrement ? _controller.canIncrement : _controller.canDecrement);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canAct ? () => _stepBy(isIncrement ? 1 : -1) : null,
      onTapDown: canAct
          ? (_) => _startLongPressRepeat(isIncrement: isIncrement)
          : null,
      onTapUp: (_) => _stopRepeatTimers(),
      onTapCancel: _stopRepeatTimers,
      child: MouseRegion(
        cursor: canAct ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.buttonBackgroundColor,
            borderRadius: widget.style.buttonBorderRadius,
          ),
          child: SizedBox(
            width: fullWidth ? double.infinity : metrics.buttonSize,
            height: fullWidth
                ? metrics.compactButtonHeight
                : (compact ? null : double.infinity),
            child: Center(
              child: Icon(
                icon,
                size: compact ? metrics.iconSize * 0.85 : metrics.iconSize,
                color: canAct
                    ? colors.buttonIconColor
                    : colors.disabledButtonIconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCircleButton({
    required bool isIncrement,
    required _SpinnerColors colors,
    required IconData icon,
  }) {
    final canAct = _isInteractive &&
        (isIncrement ? _controller.canIncrement : _controller.canDecrement);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canAct ? () => _stepBy(isIncrement ? 1 : -1) : null,
      onTapDown: canAct
          ? (_) => _startLongPressRepeat(isIncrement: isIncrement)
          : null,
      onTapUp: (_) => _stopRepeatTimers(),
      onTapCancel: _stopRepeatTimers,
      child: MouseRegion(
        cursor: canAct ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.buttonBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Icon(
                icon,
                size: 16,
                color: canAct
                    ? colors.buttonIconColor
                    : colors.disabledButtonIconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(_SpinnerColors colors) {
    return SizedBox(
      height: widget.style.progressHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.progressTrackColor),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: _controller.progress.clamp(0.0, 1.0),
            heightFactor: 1.0,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.progressColor),
            ),
          ),
        ),
      ),
    );
  }

  _SpinnerMetrics _resolveMetrics(
    NumberSpinnerSize size,
    NumberSpinnerLayout layout,
    NumberSpinnerStyle style,
  ) {
    final double baseItemExtent;
    final double baseButtonSize;
    final double baseIconSize;
    final double baseFontSize;
    final double minCenterWidth;
    final double compactButtonHeight;
    final double rulerTickSpacing;

    switch (size) {
      case NumberSpinnerSize.small:
        baseItemExtent = 34;
        baseButtonSize = 34;
        baseIconSize = 17;
        baseFontSize = 14;
        minCenterWidth = 64;
        compactButtonHeight = 24;
        rulerTickSpacing = 12;
      case NumberSpinnerSize.medium:
        baseItemExtent = 44;
        baseButtonSize = 42;
        baseIconSize = 20;
        baseFontSize = 17;
        minCenterWidth = 84;
        compactButtonHeight = 28;
        rulerTickSpacing = 14;
      case NumberSpinnerSize.large:
        baseItemExtent = 54;
        baseButtonSize = 52;
        baseIconSize = 24;
        baseFontSize = 21;
        minCenterWidth = 108;
        compactButtonHeight = 34;
        rulerTickSpacing = 16;
    }

    final itemExtent = style.itemExtent ?? baseItemExtent;
    final buttonSize = style.buttonSize ?? baseButtonSize;
    final iconSize = style.iconSize ?? baseIconSize;

    double? defaultWidth = style.width;
    double defaultHeight;

    switch (layout) {
      case NumberSpinnerLayout.odometer:
        if (widget.buttonPosition == NumberSpinnerButtonPosition.topBottom) {
          defaultHeight =
              style.height ?? (itemExtent + (compactButtonHeight * 2) + 8);
          defaultWidth ??= minCenterWidth + 32;
        } else {
          defaultHeight = style.height ?? itemExtent;
        }
      case NumberSpinnerLayout.wheelVertical:
        final wheelHeight = itemExtent * style.visibleItemCount;
        final extraButtons =
            widget.buttonPosition == NumberSpinnerButtonPosition.topBottom
                ? (compactButtonHeight * 2)
                : 0.0;
        defaultHeight = style.height ?? (wheelHeight + extraButtons);
        defaultWidth ??= minCenterWidth +
            (widget.buttonPosition == NumberSpinnerButtonPosition.sides
                ? buttonSize * 2
                : 44);
      case NumberSpinnerLayout.wheelHorizontal:
        defaultHeight = style.height ?? (itemExtent + 12);
        defaultWidth ??= (itemExtent * style.visibleItemCount) +
            (widget.buttonPosition == NumberSpinnerButtonPosition.sides
                ? buttonSize * 2
                : 24);
      case NumberSpinnerLayout.ruler:
        defaultHeight = style.height ?? (itemExtent + 54);
        defaultWidth ??= 260;
      case NumberSpinnerLayout.spinWheel:
        defaultHeight = style.height ?? (itemExtent * 5);
        defaultWidth ??= style.height ?? (itemExtent * 5);
    }

    final borderWidth =
        _isFocused ? style.focusedBorderWidth : style.borderWidth;
    final borderRadius = style.borderRadius ?? BorderRadius.circular(16);

    return _SpinnerMetrics(
      width: defaultWidth,
      height: defaultHeight,
      itemExtent: itemExtent,
      buttonSize: buttonSize,
      iconSize: iconSize,
      fontSize: baseFontSize,
      minCenterWidth: minCenterWidth,
      compactButtonHeight: compactButtonHeight,
      rulerTickSpacing: rulerTickSpacing,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
    );
  }

  _SpinnerColors _resolveColors(_AmbientPalette palette, bool hasError) {
    final style = widget.style;
    final isNeon = style.preset == NumberSpinnerThemePreset.neon;
    final isSoft = style.preset == NumberSpinnerThemePreset.soft;
    final isMinimal = style.preset == NumberSpinnerThemePreset.minimal;

    final accentColor = style.accentColor ?? palette.primary;
    final backgroundColor = style.backgroundColor ??
        (isNeon
            ? const Color(0xFF0F172A)
            : (isMinimal
                ? palette.surfaceContainerHighest.withValues(alpha: 0.45)
                : palette.surface));

    final borderColor = hasError
        ? (style.errorBorderColor ?? palette.error)
        : (_isFocused
            ? (style.focusedBorderColor ?? accentColor)
            : (style.borderColor ??
                palette.outlineVariant.withValues(alpha: 0.75)));

    final selectionHighlightColor = style.selectionHighlightColor ??
        accentColor.withValues(alpha: isMinimal ? 0.08 : 0.12);

    final selectionBorderColor = style.selectionBorderColor ??
        accentColor.withValues(alpha: _isFocused ? 0.45 : 0.2);

    final metrics = _resolveMetrics(widget.size, widget.layout, style);

    final selectedTextStyle = TextStyle(
      fontSize: metrics.fontSize,
      fontWeight: FontWeight.w700,
      color: isNeon ? accentColor : palette.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    ).merge(style.selectedTextStyle);

    final unselectedTextStyle = TextStyle(
      fontSize: metrics.fontSize * 0.85,
      fontWeight: FontWeight.w500,
      color: isNeon
          ? _kWhite.withValues(alpha: 0.45)
          : palette.onSurfaceVariant.withValues(alpha: 0.65),
      fontFeatures: const [FontFeature.tabularFigures()],
    ).merge(style.unselectedTextStyle);

    final buttonBackgroundColor = style.buttonBackgroundColor ??
        (isMinimal ? _kTransparent : accentColor.withValues(alpha: 0.08));

    final buttonHoverColor =
        style.buttonHoverColor ?? accentColor.withValues(alpha: 0.14);
    final buttonSplashColor =
        style.buttonSplashColor ?? accentColor.withValues(alpha: 0.2);
    final buttonIconColor =
        style.buttonIconColor ?? (isNeon ? accentColor : palette.onSurface);
    final disabledButtonIconColor = style.disabledButtonIconColor ??
        palette.onSurface.withValues(alpha: 0.26);

    final List<BoxShadow> boxShadow = style.boxShadow ??
        (isSoft
            ? [
                BoxShadow(
                  color: _kBlack.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                if (_isFocused)
                  BoxShadow(
                    color: (hasError ? palette.error : accentColor)
                        .withValues(alpha: 0.18),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ]);

    return _SpinnerColors(
      accentColor: accentColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      selectionHighlightColor: selectionHighlightColor,
      selectionBorderColor: selectionBorderColor,
      selectedTextStyle: selectedTextStyle,
      unselectedTextStyle: unselectedTextStyle,
      buttonBackgroundColor: buttonBackgroundColor,
      buttonHoverColor: buttonHoverColor,
      buttonSplashColor: buttonSplashColor,
      buttonIconColor: buttonIconColor,
      disabledButtonIconColor: disabledButtonIconColor,
      boxShadow: boxShadow,
      progressTrackColor:
          style.progressTrackColor ?? accentColor.withValues(alpha: 0.12),
      progressColor: style.progressColor ?? accentColor,
      rulerMajorTickColor: style.rulerMajorTickColor ??
          palette.onSurface.withValues(alpha: 0.65),
      rulerMinorTickColor: style.rulerMinorTickColor ??
          palette.onSurfaceVariant.withValues(alpha: 0.3),
      rulerIndicatorColor: style.rulerIndicatorColor ?? accentColor,
    );
  }
}

class _AmbientPalette {
  const _AmbientPalette({
    required this.primary,
    required this.surface,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outlineVariant,
    required this.error,
  });

  factory _AmbientPalette.fromBrightness({required bool isDark}) {
    if (isDark) {
      return const _AmbientPalette(
        primary: Color(0xFF818CF8),
        surface: Color(0xFF1E293B),
        surfaceContainerHighest: Color(0xFF334155),
        onSurface: Color(0xFFF8FAFC),
        onSurfaceVariant: Color(0xFF94A3B8),
        outlineVariant: Color(0xFF334155),
        error: Color(0xFFF87171),
      );
    }
    return const _AmbientPalette(
      primary: Color(0xFF4F46E5),
      surface: Color(0xFFFFFFFF),
      surfaceContainerHighest: Color(0xFFE2E8F0),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF64748B),
      outlineVariant: Color(0xFFCBD5E1),
      error: Color(0xFFDC2626),
    );
  }

  final Color primary;
  final Color surface;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outlineVariant;
  final Color error;
}

class _SpinnerMetrics {
  const _SpinnerMetrics({
    required this.width,
    required this.height,
    required this.itemExtent,
    required this.buttonSize,
    required this.iconSize,
    required this.fontSize,
    required this.minCenterWidth,
    required this.compactButtonHeight,
    required this.rulerTickSpacing,
    required this.borderWidth,
    required this.borderRadius,
  });

  final double? width;
  final double height;
  final double itemExtent;
  final double buttonSize;
  final double iconSize;
  final double fontSize;
  final double minCenterWidth;
  final double compactButtonHeight;
  final double rulerTickSpacing;
  final double borderWidth;
  final BorderRadius borderRadius;
}

class _SpinnerColors {
  const _SpinnerColors({
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.selectionHighlightColor,
    required this.selectionBorderColor,
    required this.selectedTextStyle,
    required this.unselectedTextStyle,
    required this.buttonBackgroundColor,
    required this.buttonHoverColor,
    required this.buttonSplashColor,
    required this.buttonIconColor,
    required this.disabledButtonIconColor,
    required this.boxShadow,
    required this.progressTrackColor,
    required this.progressColor,
    required this.rulerMajorTickColor,
    required this.rulerMinorTickColor,
    required this.rulerIndicatorColor,
  });

  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color selectionHighlightColor;
  final Color selectionBorderColor;
  final TextStyle selectedTextStyle;
  final TextStyle unselectedTextStyle;
  final Color buttonBackgroundColor;
  final Color buttonHoverColor;
  final Color buttonSplashColor;
  final Color buttonIconColor;
  final Color disabledButtonIconColor;
  final List<BoxShadow> boxShadow;
  final Color progressTrackColor;
  final Color progressColor;
  final Color rulerMajorTickColor;
  final Color rulerMinorTickColor;
  final Color rulerIndicatorColor;
}
