// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_spinner/number_spinner.dart';

void main() {
  group('NumberSpinnerMath', () {
    test('eliminates IEEE 754 floating-point drift', () {
      expect(NumberSpinnerMath.add(0.1, 0.2), 0.3);
      expect(NumberSpinnerMath.subtract(0.3, 0.1), 0.2);
      expect(NumberSpinnerMath.add(1.005, 0.005, precision: 3), 1.01);
    });

    test('infers precision accurately', () {
      expect(NumberSpinnerMath.inferPrecision(1, 10, 100), 0);
      expect(NumberSpinnerMath.inferPrecision(0, 10, 0.25), 2);
      expect(NumberSpinnerMath.inferPrecision(0.125, 1.5), 3);
    });

    test('clamps, snaps, and wraps values accurately', () {
      expect(NumberSpinnerMath.clamp(150, min: 0, max: 100), 100);
      expect(NumberSpinnerMath.clamp(-10, min: 0, max: 100), 0);
      expect(
        NumberSpinnerMath.snapToStep(13, min: 0, max: 100, step: 5),
        15,
      );
      expect(
        NumberSpinnerMath.wrap(24, min: 0, max: 23, step: 1),
        0,
      );
      expect(
        NumberSpinnerMath.wrap(-1, min: 0, max: 23, step: 1),
        23,
      );
    });

    test('computes stepCount, valueAtStep, and stepIndexForValue', () {
      expect(NumberSpinnerMath.stepCount(min: 0, max: 10, step: 2), 6);
      expect(
        NumberSpinnerMath.valueAtStep(index: 3, min: 0, max: 10, step: 2),
        6,
      );
      expect(
        NumberSpinnerMath.stepIndexForValue(6, min: 0, max: 10, step: 2),
        3,
      );
    });
  });

  group('NumberSpinnerFormat', () {
    test(
        'formats standard, decimal, padded, currency, european, percentage, and unit',
        () {
      const standard = NumberSpinnerFormat.standard();
      expect(standard.format(12500), '12,500');

      const decimal = NumberSpinnerFormat.decimal();
      expect(decimal.format(12.5, precision: 2), '12.50');

      const padded = NumberSpinnerFormat.padded(width: 3);
      expect(padded.format(7), '007');

      const currency = NumberSpinnerFormat.currency(symbol: r'$');
      expect(currency.format(1250.5, precision: 2), r'$1,250.50');

      const european = NumberSpinnerFormat.european(
        symbol: '€',
        padDecimals: true,
      );
      expect(european.format(1250.5, precision: 2), '€1.250,50');

      const percentage = NumberSpinnerFormat.percentage();
      expect(percentage.format(75.5, precision: 1), '75.5%');

      const unit = NumberSpinnerFormat.unit(unit: 'kg');
      expect(unit.format(72), '72 kg');

      final custom = NumberSpinnerFormat.custom((v) => 'Level $v');
      expect(custom.format(4), 'Level 4');
    });
  });

  group('NumberSpinnerController', () {
    test('manages stepping, bounds, looping, progress, and reset', () {
      final controller = NumberSpinnerController(
        value: 10,
        min: 0,
        max: 20,
        step: 5,
      );

      expect(controller.value, 10);
      expect(controller.progress, 0.5);
      expect(controller.totalSteps, 5);
      expect(controller.currentStepIndex, 2);

      expect(controller.increment(), isTrue);
      expect(controller.value, 15);
      expect(controller.lastDirection, OdometerScrollDirection.up);

      expect(controller.decrement(2), isTrue);
      expect(controller.value, 5);
      expect(controller.lastDirection, OdometerScrollDirection.down);

      controller.setValue(20);
      expect(controller.isAtMax, isTrue);
      expect(controller.canIncrement, isFalse);
      expect(controller.increment(), isFalse);

      controller.updateBounds(loop: true);
      expect(controller.canIncrement, isTrue);
      expect(controller.increment(), isTrue);
      expect(controller.value, 0);

      controller.reset();
      expect(controller.value, 10);
      controller.dispose();
    });
  });

  group('NumberSpinnerStyle', () {
    test('supports factory presets, copyWith, and value equality', () {
      final modern = NumberSpinnerStyle.modern(showProgressIndicator: true);
      final copy = modern.copyWith(height: 52);

      expect(modern.preset, NumberSpinnerThemePreset.modern);
      expect(modern.showProgressIndicator, isTrue);
      expect(copy.height, 52);
      expect(modern == modern.copyWith(), isTrue);
      expect(modern.hashCode, modern.copyWith().hashCode);

      expect(NumberSpinnerStyle.glass().preset, NumberSpinnerThemePreset.glass);
      expect(NumberSpinnerStyle.neon().preset, NumberSpinnerThemePreset.neon);
      expect(
        NumberSpinnerStyle.minimal().preset,
        NumberSpinnerThemePreset.minimal,
      );
      expect(NumberSpinnerStyle.soft().preset, NumberSpinnerThemePreset.soft);
    });
  });

  group('NumberSpinner Widget', () {
    testWidgets('increments and decrements on button taps in odometer layout', (
      tester,
    ) async {
      num? latestValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberSpinner(
              labelText: 'Quantity',
              initialValue: 5,
              min: 0,
              max: 10,
              step: 1,
              onChanged: (v) => latestValue = v,
            ),
          ),
        ),
      );

      expect(find.text('Quantity'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(latestValue, 6);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(latestValue, 5);
    });

    testWidgets('supports keyboard shortcuts and mouse scroll wheel', (
      tester,
    ) async {
      final controller = NumberSpinnerController(
        value: 10,
        min: 0,
        max: 100,
        step: 2,
      );
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberSpinner(
              controller: controller,
              focusNode: focusNode,
              largeStepCount: 5,
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(controller.value, 12);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(controller.value, 10);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(controller.value, 20);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(controller.value, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(controller.value, 100);

      // Mouse wheel scroll down -> decrement
      final center = tester.getCenter(find.byType(NumberSpinner));
      final testPointer = TestPointer(1, PointerDeviceKind.mouse);
      testPointer.hover(center);
      await tester.sendEventToBinding(
        testPointer.scroll(const Offset(0, 20)),
      );
      await tester.pumpAndSettle();
      expect(controller.value, 98);

      focusNode.dispose();
      controller.dispose();
    });

    testWidgets('supports vertical drag-to-spin and direct tap-to-edit input', (
      tester,
    ) async {
      final controller = NumberSpinnerController(
        value: 20,
        min: 0,
        max: 100,
        step: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NumberSpinner(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Drag upward on center to spin value up
      await tester.drag(find.byType(OdometerNumberText), const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(controller.value, greaterThan(20));

      // Tap center to enter direct edit mode
      await tester.tap(find.byType(OdometerNumberText));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '77');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(controller.value, 77);

      controller.dispose();
    });

    testWidgets('renders wheelVertical, wheelHorizontal, and ruler layouts', (
      tester,
    ) async {
      final verticalController = NumberSpinnerController(
        value: 5,
        min: 0,
        max: 10,
      );
      final horizontalController = NumberSpinnerController(
        value: 3,
        min: 1,
        max: 8,
      );
      final rulerController = NumberSpinnerController(
        value: 50,
        min: 0,
        max: 100,
        step: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  NumberSpinner(
                    controller: verticalController,
                    layout: NumberSpinnerLayout.wheelVertical,
                    buttonPosition: NumberSpinnerButtonPosition.topBottom,
                  ),
                  NumberSpinner(
                    controller: horizontalController,
                    layout: NumberSpinnerLayout.wheelHorizontal,
                  ),
                  NumberSpinner(
                    controller: rulerController,
                    layout: NumberSpinnerLayout.ruler,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListWheelScrollView), findsNWidgets(3));

      verticalController.increment();
      horizontalController.increment();
      rulerController.increment();
      await tester.pumpAndSettle();

      expect(verticalController.value, 6);
      expect(horizontalController.value, 4);
      expect(rulerController.value, 55);

      verticalController.dispose();
      horizontalController.dispose();
      rulerController.dispose();
    });
  });

  group('MultiDigitNumberSpinner', () {
    testWidgets('renders place-value digit columns and syncs with controller', (
      tester,
    ) async {
      final controller = NumberSpinnerController(
        value: 42.5,
        min: 0,
        max: 99.9,
        step: 0.1,
        precision: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiDigitNumberSpinner(
              controller: controller,
              labelText: 'Frequency',
              integerDigits: 2,
              decimalDigits: 1,
              suffixText: 'Hz',
            ),
          ),
        ),
      );

      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Hz'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));

      controller.setValue(87.3, snap: false);
      await tester.pumpAndSettle();
      expect(controller.value, 87.3);

      controller.dispose();
    });
  });

  group('NumberSpinnerFormField', () {
    testWidgets('validates, saves, and resets inside a Form', (tester) async {
      final formKey = GlobalKey<FormState>();
      num? savedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: NumberSpinnerFormField(
                labelText: 'Seats',
                initialValue: 2,
                min: 1,
                max: 20,
                validator: (val) =>
                    (val == null || val < 3) ? 'Minimum 3 seats' : null,
                onSaved: (val) => savedValue = val,
              ),
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Minimum 3 seats'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(formKey.currentState!.validate(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Minimum 3 seats'), findsNothing);

      formKey.currentState!.save();
      expect(savedValue, 3);

      formKey.currentState!.reset();
      await tester.pumpAndSettle();
      expect(formKey.currentState!.validate(), isFalse);
    });
  });

  group('SpinWheelNumberSpinner', () {
    testWidgets(
        'spins to target value, adds/removes numbers, and excludes winners', (
      tester,
    ) async {
      final controller = SpinWheelController(
        min: 1,
        max: 10,
        step: 1,
        initialValue: 1,
      );
      num? spinResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpinWheelNumberSpinner(
              controller: controller,
              labelText: 'Spin Number',
              spinDuration: const Duration(milliseconds: 300),
              onSpinEnd: (winner) => spinResult = winner,
            ),
          ),
        ),
      );

      expect(find.text('Spin Number'), findsOneWidget);
      expect(controller.items.length, 10);

      controller.spin(
        targetValue: 7,
        minRotations: 2,
        duration: const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedValue, 7);
      expect(spinResult, 7);

      controller.addNumber();
      expect(controller.items.length, 11);
      expect(controller.items.last, 11);

      expect(controller.removeLastNumber(), isTrue);
      expect(controller.items.length, 10);

      expect(controller.excludeNumber(7), isTrue);
      expect(controller.items.contains(7), isFalse);

      controller.resetNumbers();
      expect(controller.items.length, 10);

      controller.dispose();
    });
  });
}
