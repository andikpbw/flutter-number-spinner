## 1.0.1

- Migrated core library widgets (`lib/`) from `package:flutter/material.dart` to `package:flutter/widgets.dart` for full Flutter 3.47+ static analysis compatibility and framework independence (`MaterialApp`, `CupertinoApp`, and `WidgetsApp`).

## 1.0.0

- Initial release of `number_spinner`.
- Added `NumberSpinner` with 4 eye-catching layouts:
  - `NumberSpinnerLayout.odometer` (animated rolling-digit capsule with drag-to-spin and stepper controls).
  - `NumberSpinnerLayout.wheelVertical` (3D vertical cylindrical drum picker with selection lens and gradient edge fade).
  - `NumberSpinnerLayout.wheelHorizontal` (3D horizontal carousel wheel picker).
  - `NumberSpinnerLayout.ruler` (interactive sliding tick-mark gauge ruler with live readout badge).
- Added `OdometerNumberText` for standalone directional rolling-digit animations.
- Added `MultiDigitNumberSpinner` for independent place-value 3D digit-column wheels.
- Added `NumberSpinnerController` with precision-safe stepping, wrap-around (`loop`) support, bounds management, and normalized progress tracking.
- Added `NumberSpinnerFormat` with presets for standard numbers, decimals, zero-padded counters, currency, percentages, measurement units, and custom callbacks.
- Added `NumberSpinnerStyle` with 5 modern visual presets (`modern`, `glass`, `neon`, `minimal`, `soft`).
- Added `NumberSpinnerFormField` for seamless `Form` validation and state persistence.
- Added keyboard navigation (`ArrowUp`, `ArrowDown`, `ArrowLeft`, `ArrowRight`, `PageUp`, `PageDown`, `Home`, `End`), mouse scroll wheel support, and long-press turbo auto-repeat.
