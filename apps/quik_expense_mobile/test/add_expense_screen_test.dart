import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quik_expense_mobile/config/providers/database_providers.dart';
import 'package:quik_expense_mobile/features/add_expense/add_expense_screen.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Home stub → pushes the screen, like the bottom-nav "create" button.
  Future<void> pumpScreen(WidgetTester tester) async {
    // Tall phone-sized screen so the whole (lazily built) form is on screen.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/add'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(path: '/add', builder: (_, _) => const AddExpenseScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await settleDb(tester);
  }

  testWidgets('saves an expense and pops back', (tester) async {
    await pumpScreen(tester);
    expect(find.text('New expense'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField).first, '42,5');
    await tapChip(tester, 'Transport');
    await settleDb(tester);
    expect(saveEnabled(tester), isFalse); // no subcategory yet

    await tapChip(tester, 'Bus');
    final noteField = find.byType(TextFormField);
    await tester.scrollUntilVisible(
      noteField,
      200,
      scrollable: _formScrollable,
    );
    await tester.enterText(noteField, '  Commute  ');
    await tester.pumpAndSettle();
    expect(saveEnabled(tester), isTrue);

    await tester.tap(find.text('Save expense'));
    await settleDb(tester);

    expect(find.text('open'), findsOneWidget); // popped
    expect(find.text('Expense added'), findsOneWidget);

    final saved = (await tester.runAsync(
      () => db.expensesDao.watchDetails().first,
    ))!;
    expect(saved, hasLength(1));
    expect(saved.single.expense.amountCents, 4250);
    expect(saved.single.expense.note, 'Commute');
    expect(saved.single.subcategory.name, 'Bus');
    expect(saved.single.category.name, 'Transport');

    await disposeTree(tester);
  });

  testWidgets('switching category clears the subcategory', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField).first, '10');
    await tapChip(tester, 'Transport');
    await settleDb(tester);
    await tapChip(tester, 'Taxi');
    await tester.pumpAndSettle();
    expect(saveEnabled(tester), isTrue);

    await tapChip(tester, 'Travel');
    await settleDb(tester);
    expect(find.text('Taxi'), findsNothing);
    expect(find.text('Flights'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);

    await disposeTree(tester);
  });
}

/// Drift runs its queries on real async time, which the widget tester's
/// fake clock never advances — give it a moment, then settle the UI.
Future<void> settleDb(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the app so drift's stream subscriptions close, then lets its
/// cancellation timer fire (the tester fails on pending timers).
Future<void> disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// The form's ListView scrollable (text fields have their own inside).
final _formScrollable = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

/// Scrolls [label] into view (clear of the pinned Save button), then taps it.
Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.text(label);
  await tester.scrollUntilVisible(chip, 120, scrollable: _formScrollable);
  await tester.drag(find.byType(ListView), const Offset(0, -120));
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pump();
}

/// Whether the "Save expense" button is tappable.
bool saveEnabled(WidgetTester tester) =>
    tester
        .widget<InkWell>(
          find
              .ancestor(
                of: find.text('Save expense'),
                matching: find.byType(InkWell),
              )
              .first, // nearest InkWell = the button's own
        )
        .onTap !=
    null;
