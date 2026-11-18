/// Visual and interactive layout modes supported by `NumberSpinner`.
enum NumberSpinnerLayout {
  /// Compact capsule/card spinner with directional rolling-digit odometer
  /// animation, drag-to-spin gesture support, and optional `+` / `-` buttons.
  odometer,

  /// Vertical 3D cylindrical drum wheel picker with a central magnification
  /// lens, gradient edge fades, and smooth item snapping.
  wheelVertical,

  /// Horizontal 3D carousel wheel picker with a central selection highlight,
  /// gradient side fades, and smooth item snapping.
  wheelHorizontal,

  /// Interactive sliding ruler / tick-mark gauge with major/minor ticks,
  /// center pointer needle, and live animated value readout.
  ruler,
}

/// Predefined sizing presets for `NumberSpinner`.
enum NumberSpinnerSize {
  /// Compact size suitable for dense toolbars, tables, and list tiles.
  small,

  /// Default balanced size suitable for standard forms and cards.
  medium,

  /// Prominent size with larger typography and touch targets for hero UI controls.
  large,
}

/// Placement options for the increment (`+`) and decrement (`-`) buttons.
enum NumberSpinnerButtonPosition {
  /// Decrement button on the left and increment button on the right (`[-] 42 [+]`).
  sides,

  /// Increment and decrement buttons stacked vertically on the trailing side (`42 [▲/▼]`).
  stackedEnd,

  /// Increment button above the value and decrement button below (`[▲] / 42 / [▼]`).
  topBottom,

  /// Hides the stepper buttons so the user interacts via wheel scrolling,
  /// drag-to-spin gestures, keyboard arrows, or mouse wheel.
  none,
}

/// Built-in visual theme presets for `NumberSpinnerStyle`.
enum NumberSpinnerThemePreset {
  /// Clean Material 3 surface with subtle border, soft shadow, and primary accent highlights.
  modern,

  /// Translucent frosted glassmorphic look with luminous border and soft glow.
  glass,

  /// High-contrast dark cyber style with glowing neon accent border and digits.
  neon,

  /// Ultra-clean minimal borderless capsule that blends into surrounding surfaces.
  minimal,

  /// Tactile soft-UI surface with warm rounded contours and gentle elevation.
  soft,
}

/// Direction of an odometer value change animation.
enum OdometerScrollDirection {
  /// Value increased; digits roll upward.
  up,

  /// Value decreased; digits roll downward.
  down,

  /// No directional movement.
  none,
}

/// Signature for a function that formats a numeric [value] into a display string.
typedef NumberSpinnerLabelBuilder = String Function(num value);
