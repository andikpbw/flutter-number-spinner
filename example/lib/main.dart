// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:number_spinner/number_spinner.dart';

void main() {
  runApp(const NumberSpinnerExampleApp());
}

/// Root application widget for the `number_spinner` interactive showcase.
class NumberSpinnerExampleApp extends StatefulWidget {
  /// Creates a [NumberSpinnerExampleApp].
  const NumberSpinnerExampleApp({super.key});

  @override
  State<NumberSpinnerExampleApp> createState() =>
      _NumberSpinnerExampleAppState();
}

class _NumberSpinnerExampleAppState extends State<NumberSpinnerExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Spinner Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      home: NumberSpinnerShowcasePage(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.light
                ? ThemeMode.dark
                : ThemeMode.light;
          });
        },
      ),
    );
  }
}

/// Interactive showcase screen demonstrating all layouts, styles, and controllers
/// of `number_spinner`.
class NumberSpinnerShowcasePage extends StatefulWidget {
  /// Creates a [NumberSpinnerShowcasePage].
  const NumberSpinnerShowcasePage({
    required this.isDark,
    required this.onToggleTheme,
    super.key,
  });

  /// Whether dark mode is currently active.
  final bool isDark;

  /// Callback to toggle light and dark theme modes.
  final VoidCallback onToggleTheme;

  @override
  State<NumberSpinnerShowcasePage> createState() =>
      _NumberSpinnerShowcasePageState();
}

class _NumberSpinnerShowcasePageState extends State<NumberSpinnerShowcasePage> {
  final NumberSpinnerController _liveController = NumberSpinnerController(
    value: 1250,
    min: 0,
    max: 5000,
    step: 50,
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _liveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('number_spinner • Humanize AI'),
        actions: [
          IconButton(
            tooltip: 'Toggle Light / Dark Theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionCard(
            title: '1. Odometer Spinners & Theme Presets',
            subtitle:
                'Per-character rolling digit odometer animation with drag-to-spin and tap-to-edit.',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                NumberSpinner(
                  labelText: 'Modern (With Progress)',
                  initialValue: 42,
                  min: 0,
                  max: 100,
                  style: NumberSpinnerStyle.modern(showProgressIndicator: true),
                ),
                NumberSpinner(
                  labelText: 'Glassmorphic',
                  initialValue: 18.5,
                  min: 0,
                  max: 50,
                  step: 0.5,
                  precision: 1,
                  format: const NumberSpinnerFormat.decimal(suffix: ' GB'),
                  style: NumberSpinnerStyle.glass(showProgressIndicator: true),
                ),
                NumberSpinner(
                  labelText: 'Neon Cyber',
                  initialValue: 750,
                  min: 0,
                  max: 2000,
                  step: 25,
                  format: const NumberSpinnerFormat.currency(
                    symbol: r'$',
                    padDecimals: false,
                  ),
                  style: NumberSpinnerStyle.neon(),
                ),
                NumberSpinner(
                  labelText: 'Soft UI Capsule',
                  initialValue: 65,
                  min: 0,
                  max: 100,
                  step: 5,
                  format: const NumberSpinnerFormat.percentage(),
                  style: NumberSpinnerStyle.soft(),
                ),
                NumberSpinner(
                  labelText: 'Minimal Pill',
                  initialValue: 3,
                  min: 1,
                  max: 20,
                  style: NumberSpinnerStyle.minimal(),
                ),
                const NumberSpinner(
                  labelText: 'Stacked End Buttons',
                  initialValue: 120,
                  min: 0,
                  max: 500,
                  step: 10,
                  buttonPosition: NumberSpinnerButtonPosition.stackedEnd,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '2. 3D Cylindrical Wheel Pickers (Vertical & Horizontal)',
            subtitle:
                'Magnification lens, 3D cylinder perspective, edge gradient fade, and cyclic looping.',
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const NumberSpinner(
                  labelText: 'Hour (Loop 00..23)',
                  initialValue: 9,
                  min: 0,
                  max: 23,
                  loop: true,
                  layout: NumberSpinnerLayout.wheelVertical,
                  buttonPosition: NumberSpinnerButtonPosition.topBottom,
                  format: NumberSpinnerFormat.padded(width: 2),
                ),
                NumberSpinner(
                  labelText: 'Minute (Neon Wheel)',
                  initialValue: 30,
                  min: 0,
                  max: 59,
                  loop: true,
                  layout: NumberSpinnerLayout.wheelVertical,
                  buttonPosition: NumberSpinnerButtonPosition.none,
                  format: const NumberSpinnerFormat.padded(width: 2),
                  style: NumberSpinnerStyle.neon(
                    accentColor: const Color(0xFF38BDF8),
                    showProgressIndicator: false,
                  ),
                ),
                const NumberSpinner(
                  labelText: 'Horizontal 3D Carousel',
                  initialValue: 4,
                  min: 1,
                  max: 12,
                  layout: NumberSpinnerLayout.wheelHorizontal,
                  format: NumberSpinnerFormat(suffix: 'x'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '3. Interactive Sliding Ruler Gauge',
            subtitle:
                'Major & minor tick marks, center glowing pointer needle, and live odometer badge.',
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                NumberSpinner(
                  labelText: 'Body Weight (kg)',
                  initialValue: 68.5,
                  min: 35,
                  max: 150,
                  step: 0.5,
                  precision: 1,
                  layout: NumberSpinnerLayout.ruler,
                  format: const NumberSpinnerFormat.unit(
                    unit: 'kg',
                    padDecimals: true,
                  ),
                  style: NumberSpinnerStyle.modern(showProgressIndicator: true),
                ),
                NumberSpinner(
                  labelText: 'Core Temperature (°C)',
                  initialValue: 36.5,
                  min: 30,
                  max: 45,
                  step: 0.5,
                  precision: 1,
                  layout: NumberSpinnerLayout.ruler,
                  format: const NumberSpinnerFormat.unit(
                    unit: '°C',
                    padDecimals: true,
                  ),
                  style: NumberSpinnerStyle.neon(
                    accentColor: const Color(0xFFF43F5E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '4. Multi-Digit 3D Drum Spinner',
            subtitle:
                'Spin each individual place-value digit column (100s, 10s, 1s, .1s) independently.',
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              children: [
                const MultiDigitNumberSpinner(
                  labelText: 'Combination Counter (000..999)',
                  initialValue: 428,
                  min: 0,
                  max: 999,
                  integerDigits: 3,
                ),
                MultiDigitNumberSpinner(
                  labelText: 'FM Radio Frequency (MHz)',
                  initialValue: 104.5,
                  min: 87.5,
                  max: 108.0,
                  integerDigits: 3,
                  decimalDigits: 1,
                  suffixText: 'MHz',
                  style: NumberSpinnerStyle.neon(
                    accentColor: const Color(0xFF00F5D4),
                    showProgressIndicator: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '5. Programmatic Controller & Standalone Odometer',
            subtitle:
                'Synchronize NumberSpinnerController with OdometerNumberText and external controls.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<num>(
                  valueListenable: _liveController,
                  builder: (context, value, _) {
                    return Row(
                      children: [
                        const Text('Live Odometer Readout: '),
                        OdometerNumberText(
                          value: value,
                          format: const NumberSpinnerFormat.currency(
                            symbol: r'$',
                            padDecimals: false,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                NumberSpinner(
                  controller: _liveController,
                  size: NumberSpinnerSize.large,
                  format: const NumberSpinnerFormat.currency(
                    symbol: r'$',
                    padDecimals: false,
                  ),
                  style: NumberSpinnerStyle.modern(showProgressIndicator: true),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _liveController.increment(5),
                      child: const Text(r'+$250'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _liveController.decrement(5),
                      child: const Text(r'-$250'),
                    ),
                    OutlinedButton(
                      onPressed: () => _liveController.setValue(3500),
                      child: const Text(r'Jump to $3,500'),
                    ),
                    TextButton(
                      onPressed: _liveController.reset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '6. Form Validation (NumberSpinnerFormField)',
            subtitle:
                'Integrates directly with Flutter Form validation, saving, and reset.',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NumberSpinnerFormField(
                    labelText: 'Cloud Cluster Nodes (Min 3)',
                    helperText: 'Select between 3 and 32 nodes',
                    initialValue: 2,
                    min: 1,
                    max: 32,
                    step: 1,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value < 3) {
                        return 'Production clusters require at least 3 nodes.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () {
                          _formKey.currentState?.validate();
                        },
                        child: const Text('Validate Form'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          _formKey.currentState?.reset();
                        },
                        child: const Text('Reset Form'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
