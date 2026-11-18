import 'package:flutter/material.dart';

import 'number_spinner_format.dart';
import 'number_spinner_types.dart';

/// Animated odometer-style numeric text widget that rolls digits vertically
/// when [value] increases or decreases.
///
/// Can be used standalone for animated counters, live dashboards, prices,
/// and scoreboards, or inside `NumberSpinner`.
class OdometerNumberText extends StatefulWidget {
  /// Creates an [OdometerNumberText] widget.
  const OdometerNumberText({
    required this.value,
    super.key,
    this.formattedText,
    this.format = const NumberSpinnerFormat.standard(),
    this.precision = 0,
    this.style,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
    this.direction,
    this.animatePerCharacter = true,
    this.textAlign = TextAlign.center,
  });

  /// Current numeric value to display.
  final num value;

  /// Optional pre-formatted display string. When omitted, [format] and
  /// [precision] are used to format [value].
  final String? formattedText;

  /// Formatter used when [formattedText] is `null`.
  final NumberSpinnerFormat format;

  /// Decimal precision used when formatting [value].
  final int precision;

  /// Text style applied to the rendered digits and symbols.
  final TextStyle? style;

  /// Duration of the vertical roll transition.
  final Duration duration;

  /// Easing curve of the vertical roll transition.
  final Curve curve;

  /// Explicit roll direction. When `null`, the direction is inferred
  /// automatically by comparing [value] against the previous value.
  final OdometerScrollDirection? direction;

  /// Whether each character slot animates independently so unchanged leading
  /// digits remain stationary.
  final bool animatePerCharacter;

  /// Horizontal alignment of the odometer text.
  final TextAlign textAlign;

  @override
  State<OdometerNumberText> createState() => _OdometerNumberTextState();
}

class _OdometerNumberTextState extends State<OdometerNumberText> {
  OdometerScrollDirection _effectiveDirection = OdometerScrollDirection.up;

  @override
  void initState() {
    super.initState();
    _effectiveDirection = widget.direction ?? OdometerScrollDirection.up;
  }

  @override
  void didUpdateWidget(covariant OdometerNumberText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.direction != null) {
      _effectiveDirection = widget.direction!;
    } else if (widget.value > oldWidget.value) {
      _effectiveDirection = OdometerScrollDirection.up;
    } else if (widget.value < oldWidget.value) {
      _effectiveDirection = OdometerScrollDirection.down;
    }
  }

  String get _displayText =>
      widget.formattedText ??
      widget.format.format(widget.value, precision: widget.precision);

  @override
  Widget build(BuildContext context) {
    final text = _displayText;
    final effectiveStyle =
        widget.style ?? Theme.of(context).textTheme.titleMedium;

    if (!widget.animatePerCharacter) {
      return ClipRect(
        child: _buildAnimatedSlot(
          slotKey: ValueKey<String>(text),
          text: text,
          style: effectiveStyle,
        ),
      );
    }

    final characters = text.characters.toList(growable: false);
    final total = characters.length;

    return Semantics(
      label: text,
      excludeSemantics: true,
      child: ClipRect(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: _rowAlignment(widget.textAlign),
          children: List<Widget>.generate(total, (index) {
            final char = characters[index];
            // Index from the right so place-value columns stay stable when the
            // digit count grows or shrinks.
            final rightPlaceIndex = total - 1 - index;
            final currentKey = ValueKey<String>('$rightPlaceIndex:$char');
            return _buildAnimatedSlot(
              slotKey: currentKey,
              text: char,
              style: effectiveStyle,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedSlot({
    required ValueKey<String> slotKey,
    required String text,
    required TextStyle? style,
  }) {
    final isUp = _effectiveDirection != OdometerScrollDirection.down;

    return AnimatedSwitcher(
      duration: widget.duration,
      switchInCurve: widget.curve,
      switchOutCurve: widget.curve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == slotKey;
        final double enterStart = isUp ? 0.85 : -0.85;
        final double exitEnd = isUp ? -0.85 : 0.85;
        final offsetTween = Tween<Offset>(
          begin: Offset(0, isIncoming ? enterStart : exitEnd),
          end: Offset.zero,
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetTween.animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: slotKey,
        style: style,
      ),
    );
  }

  MainAxisAlignment _rowAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return MainAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return MainAxisAlignment.end;
      case TextAlign.center:
      case TextAlign.justify:
        return MainAxisAlignment.center;
    }
  }
}
