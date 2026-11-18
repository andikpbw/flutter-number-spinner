import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'number_spinner_format.dart';
import 'number_spinner_math.dart';

const Color _kWhite = Color(0xFFFFFFFF);
const Color _kBlack = Color(0xFF000000);

const IconData _kIconRefreshRounded = IconData(
  0xf00e9,
  fontFamily: 'MaterialIcons',
);
const IconData _kIconAddRounded = IconData(
  0xf537,
  fontFamily: 'MaterialIcons',
);
const IconData _kIconRemoveRounded = IconData(
  0xf00f1,
  fontFamily: 'MaterialIcons',
);

/// Default vibrant 3D rainbow slice color palette inspired by classic lucky
/// number spin wheels.
const List<Color> defaultSpinWheelSliceColors = <Color>[
  Color(0xFFEF4444), // Red
  Color(0xFFF59E0B), // Amber / Yellow
  Color(0xFF22C55E), // Green
  Color(0xFF0EA5E9), // Sky Blue
  Color(0xFFA855F7), // Purple
  Color(0xFFF97316), // Orange
  Color(0xFF10B981), // Emerald
  Color(0xFF3B82F6), // Blue
  Color(0xFFEC4899), // Pink
  Color(0xFF8B5CF6), // Violet
];

/// Controller for [SpinWheelNumberSpinner] to trigger spins programmatically,
/// manage active wheel numbers, exclude winners, and configure weighted odds.
class SpinWheelController extends ChangeNotifier {
  /// Creates a [SpinWheelController].
  ///
  /// Either provide an explicit [items] list, or generate numbers from
  /// [min] to [max] with [step].
  SpinWheelController({
    List<num>? items,
    num min = 1,
    num max = 10,
    num step = 1,
    num? initialValue,
    Map<num, double>? weights,
    math.Random? random,
  })  : assert(step > 0, 'step must be greater than 0.'),
        _step = step,
        _random = random ?? math.Random() {
    final generated = items != null && items.isNotEmpty
        ? List<num>.of(items)
        : _generateItems(min: min, max: max, step: step);
    _initialItems = List<num>.unmodifiable(generated);
    _items = List<num>.of(generated);
    if (weights != null) {
      _weights.addAll(weights);
    }
    _selectedValue = (initialValue != null && _items.contains(initialValue))
        ? initialValue
        : _items.first;
  }

  late final List<num> _initialItems;
  late List<num> _items;
  final num _step;
  final math.Random _random;
  final Map<num, double> _weights = <num, double>{};

  late num _selectedValue;
  bool _isSpinning = false;
  int _spinRequestId = 0;
  num? _pendingTargetValue;
  int _pendingMinRotations = 5;
  Duration? _pendingDuration;

  /// Current active numbers on the spin wheel.
  List<num> get items => List<num>.unmodifiable(_items);

  /// Currently selected or winning number under the wheel pointer.
  num get selectedValue => _selectedValue;

  /// Index of [selectedValue] within [items].
  int get selectedIndex {
    final idx = _items.indexOf(_selectedValue);
    return idx >= 0 ? idx : 0;
  }

  /// Whether the wheel is currently animating a spin.
  bool get isSpinning => _isSpinning;

  /// Custom probability weights assigned to numbers on the wheel.
  Map<num, double> get weights => Map<num, double>.unmodifiable(_weights);

  _SpinRequestDescriptor get _pendingRequest => _SpinRequestDescriptor(
        id: _spinRequestId,
        targetValue: _pendingTargetValue,
        minRotations: _pendingMinRotations,
        duration: _pendingDuration,
      );

  static List<num> _generateItems({
    required num min,
    required num max,
    required num step,
  }) {
    final effectiveMin = math.min(min, max);
    final effectiveMax = math.max(min, max);
    final precision =
        NumberSpinnerMath.inferPrecision(effectiveMin, effectiveMax, step);
    final count = NumberSpinnerMath.stepCount(
      min: effectiveMin,
      max: effectiveMax,
      step: step,
      precision: precision,
    );
    return List<num>.generate(
      count,
      (i) => NumberSpinnerMath.valueAtStep(
        index: i,
        min: effectiveMin,
        max: effectiveMax,
        step: step,
        precision: precision,
      ),
    );
  }

  /// Triggers a spin animation on the attached [SpinWheelNumberSpinner].
  ///
  /// When [targetValue] is omitted, a winning number is chosen randomly using
  /// [weights] (or uniform probability when no weights are set).
  num spin({
    num? targetValue,
    int minRotations = 5,
    Duration? duration,
  }) {
    if (_items.isEmpty) return _selectedValue;
    final resolvedTarget = (targetValue != null && _items.contains(targetValue))
        ? targetValue
        : _pickWeightedRandom();
    _pendingTargetValue = resolvedTarget;
    _pendingMinRotations = math.max(1, minRotations);
    _pendingDuration = duration;
    _spinRequestId++;
    notifyListeners();
    return resolvedTarget;
  }

  num _pickWeightedRandom() {
    if (_items.length == 1) return _items.first;
    var totalWeight = 0.0;
    for (final item in _items) {
      final w = (_weights[item] ?? 1.0).clamp(0.0, double.infinity);
      totalWeight += w;
    }
    if (totalWeight <= 0) {
      return _items[_random.nextInt(_items.length)];
    }
    var roll = _random.nextDouble() * totalWeight;
    for (final item in _items) {
      final w = (_weights[item] ?? 1.0).clamp(0.0, double.infinity);
      if (roll < w) {
        return item;
      }
      roll -= w;
    }
    return _items.last;
  }

  /// Appends a new number slice to the wheel.
  ///
  /// When [value] is omitted, adds the next step increment after the current
  /// maximum value on the wheel.
  void addNumber([num? value]) {
    if (_isSpinning) return;
    final precision = NumberSpinnerMath.inferPrecision(
      _items.isEmpty ? 0 : _items.last,
      _step,
    );
    final nextVal = value ??
        (_items.isEmpty
            ? 1
            : NumberSpinnerMath.add(
                _items.reduce(math.max),
                _step,
                precision: precision,
              ));
    _items.add(nextVal);
    notifyListeners();
  }

  /// Removes the last number slice from the wheel (keeping at least 2 slices).
  bool removeLastNumber() {
    if (_isSpinning || _items.length <= 2) return false;
    final removed = _items.removeLast();
    if (_selectedValue == removed) {
      _selectedValue = _items.first;
    }
    notifyListeners();
    return true;
  }

  /// Excludes a specific [value] from the wheel (for example, after it wins).
  ///
  /// Keeps at least 2 slices on the wheel.
  bool excludeNumber(num value) {
    if (_isSpinning || _items.length <= 2) return false;
    final removed = _items.remove(value);
    if (removed) {
      if (_selectedValue == value) {
        _selectedValue = _items.first;
      }
      notifyListeners();
    }
    return removed;
  }

  /// Restores the initial list of numbers on the wheel.
  void resetNumbers() {
    if (_isSpinning) return;
    _items = List<num>.of(_initialItems);
    if (!_items.contains(_selectedValue)) {
      _selectedValue = _items.first;
    }
    notifyListeners();
  }

  /// Sets the relative winning weight/probability for [value].
  void setWeight(num value, double weight) {
    _weights[value] = math.max(0, weight);
    notifyListeners();
  }

  void _updateSelectedFromWheel(num value, {required bool spinning}) {
    final changed = _selectedValue != value || _isSpinning != spinning;
    _selectedValue = value;
    _isSpinning = spinning;
    if (changed) {
      notifyListeners();
    }
  }
}

class _SpinRequestDescriptor {
  const _SpinRequestDescriptor({
    required this.id,
    required this.targetValue,
    required this.minRotations,
    required this.duration,
  });

  final int id;
  final num? targetValue;
  final int minRotations;
  final Duration? duration;
}

/// A 3D colorful circular lucky spin wheel / roulette number picker widget.
///
/// Features vibrant 3D pie slices, outer metallic bezel with pegs, a central
/// teardrop pointer hub, tap-to-spin and swipe/fling-to-spin physics,
/// optional `[-]` `[↻]` `[+]` control buttons, weighted probabilities, and
/// live result display.
class SpinWheelNumberSpinner extends StatefulWidget {
  /// Creates a [SpinWheelNumberSpinner].
  const SpinWheelNumberSpinner({
    super.key,
    this.controller,
    this.items,
    this.min = 1,
    this.max = 10,
    this.step = 1,
    this.initialValue,
    this.onChanged,
    this.onSpinStart,
    this.onSpinEnd,
    this.format = const NumberSpinnerFormat.standard(useGrouping: false),
    this.sliceColors = defaultSpinWheelSliceColors,
    this.wheelSize = 260,
    this.spinDuration = const Duration(milliseconds: 3200),
    this.minSpinRotations = 5,
    this.showControlBar = true,
    this.showResultBadge = true,
    this.showPegs = true,
    this.enableSwipeToSpin = true,
    this.enableTapToSpin = true,
    this.enableHapticFeedback = false,
    this.enabled = true,
    this.labelText,
  })  : assert(step > 0, 'step must be greater than 0.'),
        assert(wheelSize >= 120, 'wheelSize must be at least 120.');

  /// Optional controller for programmatic spinning, dynamic slice editing,
  /// and custom probability weights.
  final SpinWheelController? controller;

  /// Explicit list of numbers to display on the wheel slices.
  /// When `null`, numbers are generated from [min] to [max] by [step].
  final List<num>? items;

  /// Minimum number on the wheel when [items] is `null`.
  final num min;

  /// Maximum number on the wheel when [items] is `null`.
  final num max;

  /// Step increment between numbers when [items] is `null`.
  final num step;

  /// Initial selected number at the 12-o'clock pointer.
  final num? initialValue;

  /// Called whenever the slice under the pointer changes during or after a spin.
  final ValueChanged<num>? onChanged;

  /// Called when a spin animation starts.
  final VoidCallback? onSpinStart;

  /// Called with the winning number when the spin animation comes to rest.
  final ValueChanged<num>? onSpinEnd;

  /// Formatter for slice labels and the result badge.
  final NumberSpinnerFormat format;

  /// Palette of colors cycled across the wheel slices.
  final List<Color> sliceColors;

  /// Diameter of the circular spin wheel in logical pixels.
  final double wheelSize;

  /// Default duration of a spin animation.
  final Duration spinDuration;

  /// Minimum full 360-degree rotations performed per spin.
  final int minSpinRotations;

  /// Whether to display the bottom `[-]` `[↻]` `[+]` action bar.
  final bool showControlBar;

  /// Whether to display the live winning number card/badge.
  final bool showResultBadge;

  /// Whether to render metallic pegs around the wheel rim between slices.
  final bool showPegs;

  /// Whether dragging/flinging the wheel spins it.
  final bool enableSwipeToSpin;

  /// Whether tapping the center pointer hub or wheel spins it.
  final bool enableTapToSpin;

  /// Whether to trigger selection haptic ticks as slices pass the pointer.
  final bool enableHapticFeedback;

  /// Whether user interaction is enabled.
  final bool enabled;

  /// Optional title label displayed above the spin wheel.
  final String? labelText;

  @override
  State<SpinWheelNumberSpinner> createState() => _SpinWheelNumberSpinnerState();
}

class _SpinWheelNumberSpinnerState extends State<SpinWheelNumberSpinner>
    with SingleTickerProviderStateMixin {
  SpinWheelController? _internalController;
  late AnimationController _animController;
  Animation<double>? _angleAnimation;

  double _currentAngle = 0.0;
  int _lastHandledRequestId = 0;
  int _lastNotifiedSliceIndex = 0;

  SpinWheelController get _controller =>
      widget.controller ?? _internalController!;

  int get _precision => NumberSpinnerMath.inferPrecision(
        widget.min,
        widget.max,
        widget.step,
      );

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = SpinWheelController(
        items: widget.items,
        min: widget.min,
        max: widget.max,
        step: widget.step,
        initialValue: widget.initialValue,
      );
    }
    _animController = AnimationController(
      vsync: this,
      duration: widget.spinDuration,
    )
      ..addListener(_handleAnimationFrame)
      ..addStatusListener(_handleAnimationStatus);

    _alignWheelToSelectedValue();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SpinWheelNumberSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      if (widget.controller == null) {
        _internalController ??= SpinWheelController(
          items: widget.items,
          min: widget.min,
          max: widget.max,
          step: widget.step,
          initialValue: widget.initialValue,
        );
      } else {
        _internalController?.dispose();
        _internalController = null;
      }
      _lastHandledRequestId = _controller._pendingRequest.id;
      _controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _internalController?.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _alignWheelToSelectedValue() {
    final items = _controller.items;
    if (items.isEmpty) return;
    final idx = _controller.selectedIndex;
    final sliceSweep = (2 * math.pi) / items.length;
    _currentAngle = -(idx * sliceSweep);
    _lastNotifiedSliceIndex = idx;
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final req = _controller._pendingRequest;
    if (req.id != _lastHandledRequestId) {
      _lastHandledRequestId = req.id;
      _startSpinToValue(
        targetValue: req.targetValue ?? _controller.selectedValue,
        minRotations: req.minRotations,
        duration: req.duration ?? widget.spinDuration,
      );
      return;
    }
    setState(() {});
  }

  void _startSpinToValue({
    required num targetValue,
    required int minRotations,
    required Duration duration,
  }) {
    final items = _controller.items;
    if (items.isEmpty) return;
    final targetIndex = math.max(0, items.indexOf(targetValue));
    final sliceSweep = (2 * math.pi) / items.length;

    // Target angle that places targetIndex centered at top (12 o'clock)
    final desiredMod =
        ((-targetIndex * sliceSweep) % (2 * math.pi) + (2 * math.pi)) %
            (2 * math.pi);
    final currentMod =
        (_currentAngle % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    var delta = desiredMod - currentMod;
    if (delta <= 0) {
      delta += 2 * math.pi;
    }

    final totalRotation = (minRotations * 2 * math.pi) + delta;
    final endAngle = _currentAngle + totalRotation;

    _animController.duration = duration;
    _angleAnimation = Tween<double>(
      begin: _currentAngle,
      end: endAngle,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutQuart,
      ),
    );

    _controller._updateSelectedFromWheel(
      _controller.selectedValue,
      spinning: true,
    );
    widget.onSpinStart?.call();
    _animController.forward(from: 0.0);
  }

  void _handleAnimationFrame() {
    if (_angleAnimation == null) return;
    _currentAngle = _angleAnimation!.value;
    final items = _controller.items;
    if (items.isEmpty) return;

    final idx = _indexAtTopPointer(_currentAngle, items.length);
    if (idx != _lastNotifiedSliceIndex) {
      _lastNotifiedSliceIndex = idx;
      final val = items[idx];
      _controller._updateSelectedFromWheel(
        val,
        spinning: _animController.isAnimating,
      );
      if (widget.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
      widget.onChanged?.call(val);
    }
    setState(() {});
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final items = _controller.items;
      if (items.isEmpty) return;
      final idx = _indexAtTopPointer(_currentAngle, items.length);
      final winner = items[idx];
      _controller._updateSelectedFromWheel(winner, spinning: false);
      widget.onSpinEnd?.call(winner);
      setState(() {});
    }
  }

  int _indexAtTopPointer(double angleRadians, int count) {
    if (count <= 0) return 0;
    final sliceSweep = (2 * math.pi) / count;
    final normalized =
        ((-angleRadians) % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    final index = ((normalized + (sliceSweep / 2)) ~/ sliceSweep) % count;
    return index.clamp(0, count - 1);
  }

  void _triggerUserSpin() {
    if (!widget.enabled || _controller.isSpinning) return;
    _controller.spin(
      minRotations: widget.minSpinRotations,
      duration: widget.spinDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = DefaultTextStyle.of(context).style;
    final baseColor = baseTextStyle.color ?? const Color(0xFF0F172A);
    final isDark = baseColor.computeLuminance() > 0.5 ||
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;

    final items = _controller.items;
    final labels = items
        .map((v) => widget.format.format(v, precision: _precision))
        .toList(growable: false);
    final activeIdx = _indexAtTopPointer(_currentAngle, items.length);

    Widget wheelCanvas = SizedBox(
      width: widget.wheelSize,
      height: widget.wheelSize,
      child: CustomPaint(
        painter: _SpinWheelPainter(
          labels: labels,
          sliceColors: widget.sliceColors.isEmpty
              ? defaultSpinWheelSliceColors
              : widget.sliceColors,
          rotationAngle: _currentAngle,
          activeIndex: activeIdx,
          showPegs: widget.showPegs,
          isDark: isDark,
        ),
      ),
    );

    if (widget.enabled &&
        (widget.enableTapToSpin || widget.enableSwipeToSpin)) {
      wheelCanvas = GestureDetector(
        onTap: widget.enableTapToSpin ? _triggerUserSpin : null,
        onPanUpdate: widget.enableSwipeToSpin
            ? (details) {
                if (_controller.isSpinning) return;
                setState(() {
                  _currentAngle +=
                      (details.delta.dx - details.delta.dy) * 0.015;
                });
              }
            : null,
        onPanEnd: widget.enableSwipeToSpin
            ? (details) {
                if (_controller.isSpinning) return;
                if (details.velocity.pixelsPerSecond.distance > 120) {
                  _triggerUserSpin();
                }
              }
            : null,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: wheelCanvas,
        ),
      );
    }

    final resultText = widget.format.format(
      _controller.selectedValue,
      precision: _precision,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: baseTextStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
        ],
        wheelCanvas,
        if (widget.showResultBadge) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : _kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kBlack.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Result: ',
                  style: baseTextStyle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  resultText,
                  style: baseTextStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.showControlBar) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCircleActionButton(
                icon: _kIconRemoveRounded,
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF3B82F6),
                size: 40,
                onTap: widget.enabled &&
                        !_controller.isSpinning &&
                        _controller.items.length > 2
                    ? () => _controller.removeLastNumber()
                    : null,
              ),
              const SizedBox(width: 14),
              _buildCircleActionButton(
                icon: _kIconRefreshRounded,
                backgroundColor: const Color(0xFF22C55E),
                iconColor: _kWhite,
                size: 52,
                isPrimary: true,
                onTap: widget.enabled && !_controller.isSpinning
                    ? _triggerUserSpin
                    : null,
              ),
              const SizedBox(width: 14),
              _buildCircleActionButton(
                icon: _kIconAddRounded,
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF3B82F6),
                size: 40,
                onTap: widget.enabled && !_controller.isSpinning
                    ? () => _controller.addNumber()
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required double size,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: isPrimary
                    ? _kWhite.withValues(alpha: 0.7)
                    : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                width: isPrimary ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isPrimary ? backgroundColor : _kBlack)
                      .withValues(alpha: isPrimary ? 0.35 : 0.08),
                  blurRadius: isPrimary ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: isPrimary ? 26 : 20,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinWheelPainter extends CustomPainter {
  const _SpinWheelPainter({
    required this.labels,
    required this.sliceColors,
    required this.rotationAngle,
    required this.activeIndex,
    required this.showPegs,
    required this.isDark,
  });

  final List<String> labels;
  final List<Color> sliceColors;
  final double rotationAngle;
  final int activeIndex;
  final bool showPegs;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final wheelRadius = outerRadius - 8;

    // 1. Outer bezel shadow & 3D ring
    final shadowPaint = Paint()
      ..color = _kBlack.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center.translate(0, 4), outerRadius - 2, shadowPaint);

    final bezelPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _kWhite,
          isDark ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          const Color(0xFF94A3B8),
        ],
        stops: const [0.75, 0.92, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius - 1, bezelPaint);

    final count = labels.length;
    if (count == 0) return;

    final sliceSweep = (2 * math.pi) / count;
    // Start angle offset so index 0 is centered at 12 o'clock (-pi / 2)
    final baseStartAngle = (-math.pi / 2) - (sliceSweep / 2) + rotationAngle;
    final wheelRect = Rect.fromCircle(center: center, radius: wheelRadius);

    final dividerPaint = Paint()
      ..color = _kWhite.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // 2. Draw colorful 3D pie slices
    for (var i = 0; i < count; i++) {
      final startAngle = baseStartAngle + (i * sliceSweep);
      final baseColor = sliceColors[i % sliceColors.length];
      final isSelected = i == activeIndex;

      final slicePaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            Color.lerp(baseColor, _kWhite, isSelected ? 0.35 : 0.22)!,
            baseColor,
            Color.lerp(baseColor, _kBlack, 0.18)!,
          ],
          stops: const [0.15, 0.72, 1.0],
        ).createShader(wheelRect);

      canvas.drawArc(wheelRect, startAngle, sliceSweep, true, slicePaint);
      canvas.drawArc(wheelRect, startAngle, sliceSweep, true, dividerPaint);

      // 3. Draw radial number label near the outer edge of each slice
      final midAngle = startAngle + (sliceSweep / 2);
      final textRadius = wheelRadius * 0.74;
      final labelOffset = Offset(
        center.dx + textRadius * math.cos(midAngle),
        center.dy + textRadius * math.sin(midAngle),
      );

      final fontSize = (wheelRadius * (count > 12 ? 0.13 : 0.165)).clamp(
        11.0,
        24.0,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: _kWhite,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: _kBlack.withValues(alpha: 0.45),
                offset: const Offset(0, 1.5),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(labelOffset.dx, labelOffset.dy);
      canvas.rotate(midAngle + (math.pi / 2));
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // 4. Glossy 3D top-half light reflection overlay
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _kWhite.withValues(alpha: 0.26),
          _kWhite.withValues(alpha: 0.04),
          _kBlack.withValues(alpha: 0.0),
          _kBlack.withValues(alpha: 0.14),
        ],
        stops: const [0.0, 0.42, 0.6, 1.0],
      ).createShader(wheelRect);
    canvas.drawCircle(center, wheelRadius, glossPaint);

    // 5. Outer rim border & perimeter pegs
    final rimStrokePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, wheelRadius, rimStrokePaint);

    if (showPegs) {
      final pegFill = Paint()..color = _kWhite;
      final pegBorder = Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      for (var i = 0; i < count; i++) {
        final angle = baseStartAngle + (i * sliceSweep);
        final pegPos = Offset(
          center.dx + wheelRadius * math.cos(angle),
          center.dy + wheelRadius * math.sin(angle),
        );
        canvas.drawCircle(pegPos, 3.2, pegFill);
        canvas.drawCircle(pegPos, 3.2, pegBorder);
      }
    }

    // 6. Center 3D Teardrop Pointer & Hub (pointing upward to 12 o'clock)
    final hubRadius = wheelRadius * 0.19;
    final pointerTipY = center.dy - (hubRadius * 2.05);

    final pointerPath = Path()
      ..moveTo(center.dx, pointerTipY)
      ..quadraticBezierTo(
        center.dx + (hubRadius * 0.92),
        center.dy - (hubRadius * 0.5),
        center.dx + (hubRadius * 0.95),
        center.dy,
      )
      ..arcToPoint(
        Offset(center.dx - (hubRadius * 0.95), center.dy),
        radius: Radius.circular(hubRadius * 0.95),
        clockwise: true,
      )
      ..quadraticBezierTo(
        center.dx - (hubRadius * 0.92),
        center.dy - (hubRadius * 0.5),
        center.dx,
        pointerTipY,
      )
      ..close();

    final pointerShadow = Paint()
      ..color = _kBlack.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(pointerPath.shift(const Offset(0, 3)), pointerShadow);

    final pointerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFBBF24),
          Color(0xFFF97316),
          Color(0xFFEA580C),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: hubRadius * 2),
      );
    canvas.drawPath(pointerPath, pointerPaint);

    final pointerBorder = Paint()
      ..color = _kWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(pointerPath, pointerBorder);

    // Inner white glossy circle on the center hub
    final innerDotPaint = Paint()..color = _kWhite;
    canvas.drawCircle(center, hubRadius * 0.48, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _SpinWheelPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.labels != labels ||
        oldDelegate.sliceColors != sliceColors ||
        oldDelegate.showPegs != showPegs ||
        oldDelegate.isDark != isDark;
  }
}
