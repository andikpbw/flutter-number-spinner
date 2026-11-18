import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'number_spinner_controller.dart';
import 'number_spinner_math.dart';
import 'number_spinner_style.dart';
import 'number_spinner_types.dart';

/// Multi-column 3D digit-wheel spinner where each place-value digit (`0..9`)
/// is displayed in its own scrollable drum column.
///
/// Ideal for combination locks, hardware counters, frequency tuners, timers,
/// and precision decimal readouts.
class MultiDigitNumberSpinner extends StatefulWidget {
  /// Creates a [MultiDigitNumberSpinner].
  const MultiDigitNumberSpinner({
    super.key,
    this.controller,
    this.initialValue = 0,
    this.min = 0,
    this.max = 999,
    this.integerDigits = 3,
    this.decimalDigits = 0,
    this.onChanged,
    this.style = const NumberSpinnerStyle(),
    this.columnWidth = 42,
    this.columnSpacing = 4,
    this.decimalSeparator = '.',
    this.prefixText,
    this.suffixText,
    this.loopDigits = true,
    this.showColumnDividers = true,
    this.enabled = true,
    this.readOnly = false,
    this.labelText,
  })  : assert(integerDigits >= 1, 'integerDigits must be at least 1.'),
        assert(
          decimalDigits >= 0 && decimalDigits <= 4,
          'decimalDigits must be between 0 and 4.',
        ),
        assert(min >= 0, 'MultiDigitNumberSpinner requires non-negative min.');

  /// Optional external controller for programmatic value changes.
  final NumberSpinnerController? controller;

  /// Initial numeric value when [controller] is not provided.
  final num initialValue;

  /// Minimum allowed non-negative value.
  final num min;

  /// Maximum allowed value.
  final num max;

  /// Number of integer digit columns to render.
  final int integerDigits;

  /// Number of fractional decimal digit columns to render after [decimalSeparator].
  final int decimalDigits;

  /// Called whenever the combined numeric value changes.
  final ValueChanged<num>? onChanged;

  /// Visual style and theme configuration.
  final NumberSpinnerStyle style;

  /// Width of each individual digit wheel column.
  final double columnWidth;

  /// Horizontal gap between adjacent digit columns.
  final double columnSpacing;

  /// Character rendered between integer and decimal digit columns.
  final String decimalSeparator;

  /// Optional static prefix badge rendered before the digit columns.
  final String? prefixText;

  /// Optional static suffix badge rendered after the digit columns.
  final String? suffixText;

  /// Whether each `0..9` digit wheel loops continuously.
  final bool loopDigits;

  /// Whether subtle vertical dividers are drawn between digit columns.
  final bool showColumnDividers;

  /// Whether the widget accepts user interaction.
  final bool enabled;

  /// Whether the digit wheels are read-only.
  final bool readOnly;

  /// Optional label displayed above the spinner.
  final String? labelText;

  @override
  State<MultiDigitNumberSpinner> createState() =>
      _MultiDigitNumberSpinnerState();
}

class _MultiDigitNumberSpinnerState extends State<MultiDigitNumberSpinner> {
  NumberSpinnerController? _internalController;
  late List<FixedExtentScrollController> _columnControllers;
  bool _isSyncing = false;
  num? _lastNotifiedValue;

  NumberSpinnerController get _controller =>
      widget.controller ?? _internalController!;

  int get _totalColumns => widget.integerDigits + widget.decimalDigits;

  double get _unitStep => widget.decimalDigits == 0
      ? 1.0
      : math.pow(10, -widget.decimalDigits).toDouble();

  bool get _isInteractive => widget.enabled && !widget.readOnly;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = NumberSpinnerController(
        value: widget.initialValue,
        min: widget.min,
        max: widget.max,
        step: _unitStep,
        precision: widget.decimalDigits,
      );
    }
    _lastNotifiedValue = _controller.value;
    _controller.addListener(_handleControllerChanged);
    _initColumnControllers();
  }

  void _initColumnControllers() {
    final digits = _extractDigits(_controller.value);
    _columnControllers = List<FixedExtentScrollController>.generate(
      _totalColumns,
      (i) => FixedExtentScrollController(initialItem: digits[i]),
    );
  }

  void _disposeColumnControllers() {
    for (final c in _columnControllers) {
      c.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant MultiDigitNumberSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      if (widget.controller == null) {
        _internalController ??= NumberSpinnerController(
          value: widget.initialValue,
          min: widget.min,
          max: widget.max,
          step: _unitStep,
          precision: widget.decimalDigits,
        );
      } else {
        _internalController?.dispose();
        _internalController = null;
      }
      _lastNotifiedValue = _controller.value;
      _controller.addListener(_handleControllerChanged);
    }

    if (widget.integerDigits != oldWidget.integerDigits ||
        widget.decimalDigits != oldWidget.decimalDigits) {
      _disposeColumnControllers();
      _initColumnControllers();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _internalController?.dispose();
    _disposeColumnControllers();
    super.dispose();
  }

  List<int> _extractDigits(num value) {
    final clamped = NumberSpinnerMath.clamp(
      value,
      min: _controller.min,
      max: _controller.max,
      precision: widget.decimalDigits,
    ).abs();

    final scale = math.pow(10, widget.decimalDigits).round();
    final scaledInt = (clamped * scale).round();
    final padded = scaledInt.toString().padLeft(_totalColumns, '0');
    final slice = padded.length > _totalColumns
        ? padded.substring(padded.length - _totalColumns)
        : padded;

    return List<int>.generate(
      _totalColumns,
      (i) => int.tryParse(slice[i]) ?? 0,
    );
  }

  num _composeValueFromDigits(List<int> digits) {
    var scaledInt = 0;
    for (final d in digits) {
      scaledInt = (scaledInt * 10) + d.clamp(0, 9);
    }
    if (widget.decimalDigits == 0) {
      return scaledInt;
    }
    final scale = math.pow(10, widget.decimalDigits).toDouble();
    return NumberSpinnerMath.roundToPrecision(
      scaledInt / scale,
      widget.decimalDigits,
    );
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final current = _controller.value;
    final changed = current != _lastNotifiedValue;
    _lastNotifiedValue = current;

    if (!_isSyncing) {
      final digits = _extractDigits(current);
      _isSyncing = true;
      for (var i = 0; i < _columnControllers.length; i++) {
        final col = _columnControllers[i];
        if (col.hasClients) {
          final currentDigit = ((col.selectedItem % 10) + 10) % 10;
          if (currentDigit != digits[i]) {
            col.jumpToItem(digits[i]);
          }
        }
      }
      _isSyncing = false;
    }

    setState(() {});
    if (changed) {
      widget.onChanged?.call(current);
    }
  }

  void _onDigitColumnChanged(int columnIndex, int rawSelectedItem) {
    if (_isSyncing || !_isInteractive) return;
    final newDigit = ((rawSelectedItem % 10) + 10) % 10;
    final digits = _extractDigits(_controller.value);
    if (digits[columnIndex] == newDigit) return;

    digits[columnIndex] = newDigit;
    final rawValue = _composeValueFromDigits(digits);
    final clampedValue = NumberSpinnerMath.clamp(
      rawValue,
      min: _controller.min,
      max: _controller.max,
      precision: widget.decimalDigits,
    );

    _isSyncing = true;
    _controller.setValue(clampedValue, snap: false);
    _isSyncing = false;

    // If clamping adjusted one of the digits, synchronize the wheels to match
    if (clampedValue != rawValue) {
      final clampedDigits = _extractDigits(clampedValue);
      _isSyncing = true;
      for (var i = 0; i < _columnControllers.length; i++) {
        if (_columnControllers[i].hasClients) {
          _columnControllers[i].jumpToItem(clampedDigits[i]);
        }
      }
      _isSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = widget.style;
    final isNeon = style.preset == NumberSpinnerThemePreset.neon;

    final accentColor = style.accentColor ?? colorScheme.primary;
    final itemExtent = style.itemExtent ?? 42.0;
    final height = style.height ?? (itemExtent * style.visibleItemCount);
    final backgroundColor = style.backgroundColor ??
        (isNeon ? const Color(0xFF0F172A) : colorScheme.surface);
    final borderColor = style.borderColor ??
        (isNeon
            ? accentColor.withValues(alpha: 0.55)
            : colorScheme.outlineVariant.withValues(alpha: 0.75));
    final selectionHighlightColor =
        style.selectionHighlightColor ?? accentColor.withValues(alpha: 0.14);
    final selectionBorderColor =
        style.selectionBorderColor ?? accentColor.withValues(alpha: 0.35);

    final selectedTextStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: isNeon ? accentColor : colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    ).merge(style.selectedTextStyle);

    final unselectedTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: isNeon
          ? Colors.white.withValues(alpha: 0.38)
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
      fontFeatures: const [FontFeature.tabularFigures()],
    ).merge(style.unselectedTextStyle);

    final activeDigits = _extractDigits(_controller.value);
    final children = <Widget>[];

    if (widget.prefixText != null && widget.prefixText!.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 4),
          child: Text(widget.prefixText!, style: selectedTextStyle),
        ),
      );
    }

    for (var col = 0; col < _totalColumns; col++) {
      if (col > 0) {
        if (widget.decimalDigits > 0 && col == widget.integerDigits) {
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                widget.decimalSeparator,
                style: selectedTextStyle,
              ),
            ),
          );
        } else if (widget.showColumnDividers) {
          children.add(
            Container(
              width: 1,
              height: height * 0.65,
              margin:
                  EdgeInsets.symmetric(horizontal: widget.columnSpacing / 2),
              color: borderColor.withValues(alpha: 0.35),
            ),
          );
        } else if (widget.columnSpacing > 0) {
          children.add(SizedBox(width: widget.columnSpacing));
        }
      }

      children.add(
        SizedBox(
          width: widget.columnWidth,
          height: height,
          child: _buildDigitWheelColumn(
            columnIndex: col,
            selectedDigit: activeDigits[col],
            itemExtent: itemExtent,
            selectedTextStyle: selectedTextStyle,
            unselectedTextStyle: unselectedTextStyle,
          ),
        ),
      );
    }

    if (widget.suffixText != null && widget.suffixText!.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 10),
          child: Text(
            widget.suffixText!,
            style: selectedTextStyle.copyWith(
              fontSize: (selectedTextStyle.fontSize ?? 20) * 0.78,
            ),
          ),
        ),
      );
    }

    Widget spinnerBox = Container(
      height: height,
      padding: style.padding ?? const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: style.backgroundGradient == null ? backgroundColor : null,
        gradient: style.backgroundGradient,
        borderRadius: style.borderRadius ?? BorderRadius.circular(16),
        border: style.borderWidth > 0
            ? Border.all(color: borderColor, width: style.borderWidth)
            : null,
        boxShadow: style.boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            right: 4,
            height: itemExtent,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: selectionHighlightColor,
                  borderRadius:
                      style.selectionBorderRadius ?? BorderRadius.circular(10),
                  border: Border.all(
                    color: selectionBorderColor,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ],
      ),
    );

    if (!widget.enabled) {
      spinnerBox = Opacity(
        opacity: 0.55,
        child: IgnorePointer(child: spinnerBox),
      );
    }

    if (widget.labelText == null) {
      return spinnerBox;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText!,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        spinnerBox,
      ],
    );
  }

  Widget _buildDigitWheelColumn({
    required int columnIndex,
    required int selectedDigit,
    required double itemExtent,
    required TextStyle selectedTextStyle,
    required TextStyle unselectedTextStyle,
  }) {
    Widget buildDigitItem(int digit) {
      final isSelected = digit == selectedDigit;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isInteractive
            ? () {
                final col = _columnControllers[columnIndex];
                if (col.hasClients) {
                  col.animateToItem(
                    digit,
                    duration: widget.style.animationDuration,
                    curve: widget.style.animationCurve,
                  );
                }
              }
            : null,
        child: Center(
          child: Text(
            digit.toString(),
            style: isSelected ? selectedTextStyle : unselectedTextStyle,
          ),
        ),
      );
    }

    final delegate = widget.loopDigits
        ? ListWheelChildLoopingListDelegate(
            children: List<Widget>.generate(10, buildDigitItem),
          )
        : ListWheelChildBuilderDelegate(
            childCount: 10,
            builder: (context, index) {
              if (index < 0 || index >= 10) return null;
              return buildDigitItem(index);
            },
          );

    Widget wheel = ListWheelScrollView.useDelegate(
      controller: _columnControllers[columnIndex],
      itemExtent: itemExtent,
      perspective: widget.style.perspective,
      diameterRatio: widget.style.diameterRatio,
      magnification: widget.style.magnification,
      useMagnifier: widget.style.useMagnifier,
      squeeze: widget.style.squeeze,
      physics: _isInteractive
          ? const FixedExtentScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      onSelectedItemChanged: (rawIndex) =>
          _onDigitColumnChanged(columnIndex, rawIndex),
      childDelegate: delegate,
    );

    if (widget.style.fadeEdges) {
      wheel = ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.22, 0.78, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: wheel,
      );
    }

    return wheel;
  }
}
