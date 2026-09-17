import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

Widget _wrapTestWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('ShadInput Keyboard Configuration', () {
    testWidgets('respects custom textInputAction, capitalization, autofill hints, and scrollPadding',
        (tester) async {
      String? submittedValue;
      final focusNode = FocusNode();

      await tester.pumpWidget(
        _wrapTestWidget(
          ShadInput(
            label: 'Test Input',
            focusNode: focusNode,
            textInputAction: TextInputAction.send,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.organizationName],
            scrollPadding: const EdgeInsets.only(top: 25, bottom: 100),
            onFieldSubmitted: (v) => submittedValue = v,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textInputAction, equals(TextInputAction.send));
      expect(textField.textCapitalization, equals(TextCapitalization.words));
      expect(textField.autofillHints, contains(AutofillHints.organizationName));
      expect(textField.scrollPadding, equals(const EdgeInsets.only(top: 25, bottom: 100)));

      // Simulate onFieldSubmitted
      await tester.enterText(find.byType(TextField), 'Acme Corp');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(submittedValue, equals('Acme Corp'));
      focusNode.dispose();
    });

    testWidgets('defaults to TextInputAction.next for single-line and TextInputAction.newline for multi-line',
        (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          const Column(
            children: [
              ShadInput(label: 'Single Line', maxLines: 1),
              ShadInput(label: 'Multi Line', maxLines: 3),
            ],
          ),
        ),
      );

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields[0].textInputAction, equals(TextInputAction.next));
      expect(textFields[1].textInputAction, equals(TextInputAction.newline));
    });
  });

  group('ShadAmountInput Keyboard & Minor Units', () {
    testWidgets('configures numeric keyboard, default next action, and scrollPadding', (tester) async {
      final focusNode = FocusNode();
      String? submitted;

      await tester.pumpWidget(
        _wrapTestWidget(
          ShadAmountInput(
            label: 'Amount',
            focusNode: focusNode,
            onFieldSubmitted: (v) => submitted = v,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, equals(const TextInputType.numberWithOptions(decimal: true)));
      expect(textField.textInputAction, equals(TextInputAction.next));
      expect(textField.scrollPadding, equals(const EdgeInsets.only(top: 20, bottom: 96)));

      await tester.enterText(find.byType(TextField), '45000');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(submitted, equals('45000'));
      focusNode.dispose();
    });

    test('preserves integer minor-unit financial rules (no double IEEE-754 drift)', () {
      expect(ShadAmountInput.parseToMinorUnits('15000'), equals(1500000));
      expect(ShadAmountInput.parseToMinorUnits('15,000.75'), equals(1500075));
      expect(ShadAmountInput.parseToMinorUnits('0.05'), equals(5));
      expect(ShadAmountInput.parseToMinorUnits(''), equals(0));
    });
  });

  group('Focus Chain Ownership', () {
    testWidgets('advances focus deterministically from Field 1 to Field 2 upon submission',
        (tester) async {
      final focusNode1 = FocusNode();
      final focusNode2 = FocusNode();

      await tester.pumpWidget(
        _wrapTestWidget(
          Column(
            children: [
              ShadInput(
                key: const ValueKey('field1'),
                focusNode: focusNode1,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => focusNode2.requestFocus(),
              ),
              ShadInput(
                key: const ValueKey('field2'),
                focusNode: focusNode2,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      );

      // Initially focus field 1
      focusNode1.requestFocus();
      await tester.pump();
      expect(focusNode1.hasFocus, isTrue);
      expect(focusNode2.hasFocus, isFalse);

      // Submit field 1
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      // Field 2 must now have received focus deterministically
      expect(focusNode1.hasFocus, isFalse);
      expect(focusNode2.hasFocus, isTrue);

      focusNode1.dispose();
      focusNode2.dispose();
    });
  });

  group('KeyboardDismissible Tap Outside', () {
    testWidgets('unfocuses active text input when tapping on blank canvas without blocking buttons',
        (tester) async {
      final focusNode = FocusNode();
      bool buttonClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyboardDismissible(
              child: Column(
                children: [
                  Container(
                    key: const ValueKey('blank_space'),
                    color: Colors.transparent,
                    height: 100,
                    width: double.infinity,
                  ),
                  ShadInput(
                    key: const ValueKey('input'),
                    focusNode: focusNode,
                  ),
                  ShadButton(
                    key: const ValueKey('save_button'),
                    label: 'Save',
                    onPressed: () => buttonClicked = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Focus the input
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Tap on empty space above
      await tester.tap(find.byKey(const ValueKey('blank_space')));
      await tester.pump();

      // Keyboard & focus must be dismissed
      expect(focusNode.hasFocus, isFalse);

      // Tapping the button should still fire its callback without obstruction
      await tester.tap(find.byKey(const ValueKey('save_button')));
      await tester.pump();
      expect(buttonClicked, isTrue);

      focusNode.dispose();
    });
  });

  group('Scroll Keyboard Dismissal Configuration', () {
    testWidgets('scroll views configured with onDrag keyboardDismissBehavior', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          const KeyboardAwareScroll(
            child: Column(
              children: [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      final scrollView = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      expect(scrollView.keyboardDismissBehavior, equals(ScrollViewKeyboardDismissBehavior.onDrag));
    });
  });

  group('ShadSheet Keyboard Inset Accommodation', () {
    testWidgets('adjusts bottom padding dynamically to include viewInsets.bottom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              viewInsets: EdgeInsets.only(bottom: 300),
              padding: EdgeInsets.only(bottom: 20),
            ),
            child: ShadSheet(
              showHandle: false,
              title: const Text('Sheet Title'),
              child: Container(key: const ValueKey('sheet_content'), height: 50),
            ),
          ),
        ),
      );

      // Find the root Container of ShadSheet
      final containers = tester.widgetList<Container>(find.descendant(
        of: find.byType(ShadSheet),
        matching: find.byType(Container),
      )).toList();

      final rootContainer = containers.first;
      final padding = rootContainer.padding as EdgeInsets;
      // In ShadSheet: viewInsets.bottom > 0 ? viewInsets.bottom + ShadSpacing.md : safeAreaBottom + ShadSpacing.lg
      // 300 + 12 (ShadSpacing.md) = 312
      expect(padding.bottom, equals(300.0 + ShadSpacing.md));
    });
  });
}
