import 'package:flutter/widgets.dart';

import 'number_spinner_types.dart';

const Color _kWhite = Color(0xFFFFFFFF);

/// Visual styling and geometry configuration for `NumberSpinner` and
/// `MultiDigitNumberSpinner`.
@immutable
class NumberSpinnerStyle {
  /// Creates a custom [NumberSpinnerStyle].
  const NumberSpinnerStyle({
    this.preset = NumberSpinnerThemePreset.modern,
    this.width,
    this.height,
    this.itemExtent,
    this.visibleItemCount = 3,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.backgroundGradient,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderWidth = 1.5,
    this.focusedBorderWidth = 2.0,
    this.boxShadow,
    this.selectionHighlightColor,
    this.selectionBorderColor,
    this.selectionBorderRadius,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.accentColor,
    this.buttonBackgroundColor,
    this.buttonHoverColor,
    this.buttonSplashColor,
    this.buttonIconColor,
    this.disabledButtonIconColor,
    this.buttonBorderRadius,
    this.buttonSize,
    this.iconSize,
    this.incrementIcon,
    this.decrementIcon,
    this.perspective = 0.003,
    this.diameterRatio = 1.6,
    this.magnification = 1.12,
    this.useMagnifier = true,
    this.squeeze = 1.08,
    this.fadeEdges = true,
    this.showProgressIndicator = false,
    this.progressTrackColor,
    this.progressColor,
    this.progressHeight = 3.0,
    this.rulerMajorTickColor,
    this.rulerMinorTickColor,
    this.rulerIndicatorColor,
    this.rulerMajorTickInterval = 5,
    this.animationDuration = const Duration(milliseconds: 220),
    this.animationCurve = Curves.easeOutCubic,
  })  : assert(visibleItemCount >= 1, 'visibleItemCount must be at least 1.'),
        assert(
          perspective > 0 && perspective <= 0.01,
          'perspective must be in (0, 0.01].',
        ),
        assert(
          rulerMajorTickInterval >= 1,
          'rulerMajorTickInterval must be at least 1.',
        );

  /// Clean Material 3 adaptive surface preset with soft elevation and primary accent highlights.
  factory NumberSpinnerStyle.modern({
    Color? accentColor,
    BorderRadius? borderRadius,
    bool showProgressIndicator = false,
  }) {
    return NumberSpinnerStyle(
      preset: NumberSpinnerThemePreset.modern,
      accentColor: accentColor,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      showProgressIndicator: showProgressIndicator,
    );
  }

  /// Frosted glassmorphic preset with translucent surface, luminous border, and soft glow.
  factory NumberSpinnerStyle.glass({
    Color? accentColor,
    BorderRadius? borderRadius,
    bool showProgressIndicator = false,
  }) {
    final accent = accentColor ?? const Color(0xFF6366F1);
    return NumberSpinnerStyle(
      preset: NumberSpinnerThemePreset.glass,
      accentColor: accent,
      borderRadius: borderRadius ?? BorderRadius.circular(18),
      backgroundColor: accent.withValues(alpha: 0.08),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _kWhite.withValues(alpha: 0.22),
          accent.withValues(alpha: 0.08),
        ],
      ),
      borderColor: accent.withValues(alpha: 0.28),
      focusedBorderColor: accent,
      selectionHighlightColor: accent.withValues(alpha: 0.14),
      selectionBorderColor: accent.withValues(alpha: 0.35),
      buttonBackgroundColor: accent.withValues(alpha: 0.12),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.14),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      showProgressIndicator: showProgressIndicator,
    );
  }

  /// High-contrast dark cyber preset with glowing neon accent border and digits.
  factory NumberSpinnerStyle.neon({
    Color accentColor = const Color(0xFF00F5D4),
    BorderRadius? borderRadius,
    bool showProgressIndicator = true,
  }) {
    return NumberSpinnerStyle(
      preset: NumberSpinnerThemePreset.neon,
      accentColor: accentColor,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      backgroundColor: const Color(0xFF0F172A),
      borderColor: accentColor.withValues(alpha: 0.55),
      focusedBorderColor: accentColor,
      selectionHighlightColor: accentColor.withValues(alpha: 0.14),
      selectionBorderColor: accentColor.withValues(alpha: 0.6),
      selectedTextStyle: TextStyle(
        color: accentColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        shadows: [
          Shadow(
            color: accentColor.withValues(alpha: 0.65),
            blurRadius: 10,
          ),
        ],
      ),
      unselectedTextStyle: TextStyle(
        color: _kWhite.withValues(alpha: 0.45),
        fontWeight: FontWeight.w500,
      ),
      buttonBackgroundColor: accentColor.withValues(alpha: 0.14),
      buttonIconColor: accentColor,
      disabledButtonIconColor: _kWhite.withValues(alpha: 0.22),
      rulerIndicatorColor: accentColor,
      rulerMajorTickColor: accentColor.withValues(alpha: 0.7),
      rulerMinorTickColor: _kWhite.withValues(alpha: 0.25),
      progressColor: accentColor,
      progressTrackColor: _kWhite.withValues(alpha: 0.1),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.25),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ],
      showProgressIndicator: showProgressIndicator,
    );
  }

  /// Ultra-clean minimal borderless capsule preset.
  factory NumberSpinnerStyle.minimal({
    Color? accentColor,
    BorderRadius? borderRadius,
  }) {
    return NumberSpinnerStyle(
      preset: NumberSpinnerThemePreset.minimal,
      accentColor: accentColor,
      borderRadius: borderRadius ?? BorderRadius.circular(999),
      borderWidth: 0,
      focusedBorderWidth: 1.5,
      boxShadow: const [],
    );
  }

  /// Soft tactile rounded UI preset with gentle dual shadows.
  factory NumberSpinnerStyle.soft({
    Color? accentColor,
    BorderRadius? borderRadius,
    bool showProgressIndicator = false,
  }) {
    final accent = accentColor ?? const Color(0xFF0EA5E9);
    return NumberSpinnerStyle(
      preset: NumberSpinnerThemePreset.soft,
      accentColor: accent,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      borderWidth: 1.0,
      showProgressIndicator: showProgressIndicator,
    );
  }

  /// Visual theme preset used for default color fallbacks.
  final NumberSpinnerThemePreset preset;

  /// Explicit outer width of the spinner container.
  final double? width;

  /// Explicit outer height of the spinner container.
  final double? height;

  /// Extent (height for vertical wheel, width for horizontal wheel/ruler) of each step item.
  final double? itemExtent;

  /// Number of visible items in `wheelVertical` or `wheelHorizontal` layouts.
  final int visibleItemCount;

  /// Inner padding of the spinner container.
  final EdgeInsetsGeometry? padding;

  /// Corner radius of the outer spinner container.
  final BorderRadius? borderRadius;

  /// Solid background fill color of the spinner container.
  final Color? backgroundColor;

  /// Optional gradient fill overriding [backgroundColor].
  final Gradient? backgroundGradient;

  /// Default border color when unfocused.
  final Color? borderColor;

  /// Border color when the spinner has keyboard or pointer focus.
  final Color? focusedBorderColor;

  /// Border color when `errorText` is active.
  final Color? errorBorderColor;

  /// Border stroke width in logical pixels when unfocused.
  final double borderWidth;

  /// Border stroke width in logical pixels when focused.
  final double focusedBorderWidth;

  /// Custom drop shadows rendered behind the spinner container.
  final List<BoxShadow>? boxShadow;

  /// Fill color of the central selection lens or highlight pill.
  final Color? selectionHighlightColor;

  /// Border color of the central selection lens or highlight pill.
  final Color? selectionBorderColor;

  /// Corner radius of the central selection lens or highlight pill.
  final BorderRadius? selectionBorderRadius;

  /// Text style applied to the active/selected number value.
  final TextStyle? selectedTextStyle;

  /// Text style applied to unselected wheel or ruler numbers.
  final TextStyle? unselectedTextStyle;

  /// Primary accent color used for focus rings, active indicators, and highlights.
  final Color? accentColor;

  /// Background color of the increment and decrement stepper buttons.
  final Color? buttonBackgroundColor;

  /// Hover overlay color for stepper buttons on desktop and web.
  final Color? buttonHoverColor;

  /// Ink splash color for stepper buttons.
  final Color? buttonSplashColor;

  /// Icon color for enabled stepper buttons.
  final Color? buttonIconColor;

  /// Icon color for disabled stepper buttons (when at `min` or `max`).
  final Color? disabledButtonIconColor;

  /// Corner radius of the stepper buttons.
  final BorderRadius? buttonBorderRadius;

  /// Explicit square or rectangular dimension for stepper buttons.
  final double? buttonSize;

  /// Size of the increment and decrement icons.
  final double? iconSize;

  /// Custom icon for the increment button.
  final IconData? incrementIcon;

  /// Custom icon for the decrement button.
  final IconData? decrementIcon;

  /// 3D cylindrical perspective factor for wheel layouts (`(0, 0.01]`).
  final double perspective;

  /// Ratio between wheel cylinder diameter and viewport size.
  final double diameterRatio;

  /// Magnification scale applied to the center item in wheel layouts.
  final double magnification;

  /// Whether center magnification is enabled in wheel layouts.
  final bool useMagnifier;

  /// Compactness factor of items on the 3D wheel cylinder.
  final double squeeze;

  /// Whether to apply a smooth gradient fade mask at the edges of wheel and ruler layouts.
  final bool fadeEdges;

  /// Whether to render a subtle normalized progress bar along the bottom edge.
  final bool showProgressIndicator;

  /// Background track color of the bottom progress indicator.
  final Color? progressTrackColor;

  /// Active fill color of the bottom progress indicator.
  final Color? progressColor;

  /// Height of the bottom progress indicator bar.
  final double progressHeight;

  /// Color of major tick marks in `NumberSpinnerLayout.ruler`.
  final Color? rulerMajorTickColor;

  /// Color of minor tick marks in `NumberSpinnerLayout.ruler`.
  final Color? rulerMinorTickColor;

  /// Color of the center needle indicator in `NumberSpinnerLayout.ruler`.
  final Color? rulerIndicatorColor;

  /// Step interval between major tick marks in `NumberSpinnerLayout.ruler`.
  final int rulerMajorTickInterval;

  /// Duration of odometer roll and wheel programmatic animations.
  final Duration animationDuration;

  /// Easing curve of odometer roll and wheel programmatic animations.
  final Curve animationCurve;

  /// Creates a copy of this [NumberSpinnerStyle] with the given fields replaced.
  NumberSpinnerStyle copyWith({
    NumberSpinnerThemePreset? preset,
    double? width,
    double? height,
    double? itemExtent,
    int? visibleItemCount,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? errorBorderColor,
    double? borderWidth,
    double? focusedBorderWidth,
    List<BoxShadow>? boxShadow,
    Color? selectionHighlightColor,
    Color? selectionBorderColor,
    BorderRadius? selectionBorderRadius,
    TextStyle? selectedTextStyle,
    TextStyle? unselectedTextStyle,
    Color? accentColor,
    Color? buttonBackgroundColor,
    Color? buttonHoverColor,
    Color? buttonSplashColor,
    Color? buttonIconColor,
    Color? disabledButtonIconColor,
    BorderRadius? buttonBorderRadius,
    double? buttonSize,
    double? iconSize,
    IconData? incrementIcon,
    IconData? decrementIcon,
    double? perspective,
    double? diameterRatio,
    double? magnification,
    bool? useMagnifier,
    double? squeeze,
    bool? fadeEdges,
    bool? showProgressIndicator,
    Color? progressTrackColor,
    Color? progressColor,
    double? progressHeight,
    Color? rulerMajorTickColor,
    Color? rulerMinorTickColor,
    Color? rulerIndicatorColor,
    int? rulerMajorTickInterval,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return NumberSpinnerStyle(
      preset: preset ?? this.preset,
      width: width ?? this.width,
      height: height ?? this.height,
      itemExtent: itemExtent ?? this.itemExtent,
      visibleItemCount: visibleItemCount ?? this.visibleItemCount,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      borderColor: borderColor ?? this.borderColor,
      focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
      errorBorderColor: errorBorderColor ?? this.errorBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      focusedBorderWidth: focusedBorderWidth ?? this.focusedBorderWidth,
      boxShadow: boxShadow ?? this.boxShadow,
      selectionHighlightColor:
          selectionHighlightColor ?? this.selectionHighlightColor,
      selectionBorderColor: selectionBorderColor ?? this.selectionBorderColor,
      selectionBorderRadius:
          selectionBorderRadius ?? this.selectionBorderRadius,
      selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
      unselectedTextStyle: unselectedTextStyle ?? this.unselectedTextStyle,
      accentColor: accentColor ?? this.accentColor,
      buttonBackgroundColor:
          buttonBackgroundColor ?? this.buttonBackgroundColor,
      buttonHoverColor: buttonHoverColor ?? this.buttonHoverColor,
      buttonSplashColor: buttonSplashColor ?? this.buttonSplashColor,
      buttonIconColor: buttonIconColor ?? this.buttonIconColor,
      disabledButtonIconColor:
          disabledButtonIconColor ?? this.disabledButtonIconColor,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonSize: buttonSize ?? this.buttonSize,
      iconSize: iconSize ?? this.iconSize,
      incrementIcon: incrementIcon ?? this.incrementIcon,
      decrementIcon: decrementIcon ?? this.decrementIcon,
      perspective: perspective ?? this.perspective,
      diameterRatio: diameterRatio ?? this.diameterRatio,
      magnification: magnification ?? this.magnification,
      useMagnifier: useMagnifier ?? this.useMagnifier,
      squeeze: squeeze ?? this.squeeze,
      fadeEdges: fadeEdges ?? this.fadeEdges,
      showProgressIndicator:
          showProgressIndicator ?? this.showProgressIndicator,
      progressTrackColor: progressTrackColor ?? this.progressTrackColor,
      progressColor: progressColor ?? this.progressColor,
      progressHeight: progressHeight ?? this.progressHeight,
      rulerMajorTickColor: rulerMajorTickColor ?? this.rulerMajorTickColor,
      rulerMinorTickColor: rulerMinorTickColor ?? this.rulerMinorTickColor,
      rulerIndicatorColor: rulerIndicatorColor ?? this.rulerIndicatorColor,
      rulerMajorTickInterval:
          rulerMajorTickInterval ?? this.rulerMajorTickInterval,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NumberSpinnerStyle &&
        other.preset == preset &&
        other.width == width &&
        other.height == height &&
        other.itemExtent == itemExtent &&
        other.visibleItemCount == visibleItemCount &&
        other.padding == padding &&
        other.borderRadius == borderRadius &&
        other.backgroundColor == backgroundColor &&
        other.backgroundGradient == backgroundGradient &&
        other.borderColor == borderColor &&
        other.focusedBorderColor == focusedBorderColor &&
        other.errorBorderColor == errorBorderColor &&
        other.borderWidth == borderWidth &&
        other.focusedBorderWidth == focusedBorderWidth &&
        other.selectionHighlightColor == selectionHighlightColor &&
        other.selectionBorderColor == selectionBorderColor &&
        other.selectionBorderRadius == selectionBorderRadius &&
        other.selectedTextStyle == selectedTextStyle &&
        other.unselectedTextStyle == unselectedTextStyle &&
        other.accentColor == accentColor &&
        other.buttonBackgroundColor == buttonBackgroundColor &&
        other.buttonHoverColor == buttonHoverColor &&
        other.buttonSplashColor == buttonSplashColor &&
        other.buttonIconColor == buttonIconColor &&
        other.disabledButtonIconColor == disabledButtonIconColor &&
        other.buttonBorderRadius == buttonBorderRadius &&
        other.buttonSize == buttonSize &&
        other.iconSize == iconSize &&
        other.incrementIcon == incrementIcon &&
        other.decrementIcon == decrementIcon &&
        other.perspective == perspective &&
        other.diameterRatio == diameterRatio &&
        other.magnification == magnification &&
        other.useMagnifier == useMagnifier &&
        other.squeeze == squeeze &&
        other.fadeEdges == fadeEdges &&
        other.showProgressIndicator == showProgressIndicator &&
        other.progressTrackColor == progressTrackColor &&
        other.progressColor == progressColor &&
        other.progressHeight == progressHeight &&
        other.rulerMajorTickColor == rulerMajorTickColor &&
        other.rulerMinorTickColor == rulerMinorTickColor &&
        other.rulerIndicatorColor == rulerIndicatorColor &&
        other.rulerMajorTickInterval == rulerMajorTickInterval &&
        other.animationDuration == animationDuration &&
        other.animationCurve == animationCurve;
  }

  @override
  int get hashCode => Object.hashAll([
        preset,
        width,
        height,
        itemExtent,
        visibleItemCount,
        padding,
        borderRadius,
        backgroundColor,
        backgroundGradient,
        borderColor,
        focusedBorderColor,
        errorBorderColor,
        borderWidth,
        focusedBorderWidth,
        selectionHighlightColor,
        selectionBorderColor,
        selectionBorderRadius,
        selectedTextStyle,
        unselectedTextStyle,
        accentColor,
        buttonBackgroundColor,
        buttonHoverColor,
        buttonSplashColor,
        buttonIconColor,
        disabledButtonIconColor,
        buttonBorderRadius,
        buttonSize,
        iconSize,
        incrementIcon,
        decrementIcon,
        perspective,
        diameterRatio,
        magnification,
        useMagnifier,
        squeeze,
        fadeEdges,
        showProgressIndicator,
        progressTrackColor,
        progressColor,
        progressHeight,
        rulerMajorTickColor,
        rulerMinorTickColor,
        rulerIndicatorColor,
        rulerMajorTickInterval,
        animationDuration,
        animationCurve,
      ]);
}
