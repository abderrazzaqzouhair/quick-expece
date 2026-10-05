import 'package:database/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quik_expense_mobile/config/providers/database_providers.dart';
import 'package:quik_expense_mobile/features/add_expense/add_expense_screen.dart';
import 'package:quik_expense_mobile/features/categories/categories_screen.dart';
import 'package:quik_expense_mobile/features/expense_list/expense_list_screen.dart';
import 'package:quik_expense_mobile/features/history/history_screen.dart';
import 'package:quik_expense_mobile/config/providers/preferences_providers.dart';
import 'package:quik_expense_mobile/features/home/home_screen.dart';
import 'package:quik_expense_mobile/features/profile/profile_screen.dart';
import 'package:quik_expense_mobile/features/profile/screens/edit_profile_screen.dart';
import 'package:quik_expense_mobile/features/profile/screens/privacy_screen.dart';
import 'package:quik_expense_mobile/features/profile/screens/settings_screen.dart';
import 'package:quik_expense_mobile/features/profile/screens/support_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quik_expense_mobile/features/statistics/statistics_screen.dart';

/// The screen must fit without overflow on a small phone, including with
/// larger system text (layout errors fail the test).
void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  for (final textScale in [1.0, 1.3]) {
    testWidgets('fits iPhone SE at text scale $textScale', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      tester.view
        ..physicalSize = const Size(750, 1334)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const AddExpenseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enter an amount'), findsOneWidget);

      // Category sheet grid too.
      await tester.tap(find.text('Choose category'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Travel'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    });

    testWidgets('History fits iPhone SE at text scale $textScale', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() async {
        for (final (c, sname, cents) in [
          ('Subscriptions & Digital', 'Gaming Subscriptions', 99999999),
          ('Entertainment & Fun', 'Streaming', 1500),
          ('Food & Drinks', 'Coffee', 450),
        ]) {
          await db.expensesDao.add(
            subcategoryId: CatalogueSeeder.subcategoryId(c, sname),
            amountCents: cents,
            date: DateTime.now(),
            note: 'A fairly long note that should be truncated nicely',
          );
        }
      });
      tester.view
        ..physicalSize = const Size(750, 1334)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gaming Subscriptions'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    });

    for (final (name, screen) in [
      ('Home', const HomeScreen()),
      ('Statistics', const StatisticsScreen()),
    ]) {
      testWidgets('$name fits iPhone SE at text scale $textScale', (
        tester,
      ) async {
        final db = AppDatabase(NativeDatabase.memory());
        await tester.runAsync(() async {
          final now = DateTime.now();
          for (final (c, sname, cents, monthsAgo) in [
            ('Subscriptions & Digital', 'Gaming Subscriptions', 99999999, 0),
            ('Entertainment & Fun', 'Streaming', 1500, 0),
            ('Food & Drinks', 'Coffee', 450, 0),
            ('Personal & Lifestyle', 'Perfume', 800, 0),
            ('Education & Learning', 'Books', 12000, 1),
          ]) {
            await db.expensesDao.add(
              subcategoryId: CatalogueSeeder.subcategoryId(c, sname),
              amountCents: cents,
              date: DateTime(now.year, now.month - monthsAgo, now.day),
              note: 'A fairly long note that should be truncated nicely',
            );
          }
        });
        tester.view
          ..physicalSize = const Size(750, 1334)
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: screen,
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        // Scroll through everything so every section lays out.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(db.close);
      });
    }

    for (final (name, screen) in [
      ('Categories', const CategoriesScreen()),
      ('Expense List', const ExpenseListScreen()),
    ]) {
      testWidgets('$name fits iPhone SE at text scale $textScale', (
        tester,
      ) async {
        final db = AppDatabase(NativeDatabase.memory());
        await tester.runAsync(() async {
          final now = DateTime.now();
          for (final (c, sname, cents) in [
            ('Subscriptions & Digital', 'Gaming Subscriptions', 99999999),
            ('Entertainment & Fun', 'Streaming', 1500),
            ('Food & Drinks', 'Coffee', 450),
          ]) {
            await db.expensesDao.add(
              subcategoryId: CatalogueSeeder.subcategoryId(c, sname),
              amountCents: cents,
              date: now,
              note: 'A fairly long note that should be truncated nicely',
            );
          }
        });
        tester.view
          ..physicalSize = const Size(750, 1334)
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: screen,
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(db.close);
      });
    }

    for (final (name, screen) in [
      ('Profile', const ProfileScreen()),
      ('Edit Profile', const EditProfileScreen()),
      ('Settings', const SettingsScreen()),
      ('Support', const SupportScreen()),
      ('Privacy', const PrivacyScreen()),
    ]) {
      testWidgets('$name fits iPhone SE at text scale $textScale', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({
          'profile.name': 'Abdelkarim Benjelloun El Idrissi',
          'profile.email': 'a.very.long.email.address@example-domain.ma',
        });
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase(NativeDatabase.memory());
        await tester.runAsync(
          () => db.expensesDao.add(
            subcategoryId: CatalogueSeeder.subcategoryId(
              'Subscriptions & Digital',
              'Gaming Subscriptions',
            ),
            amountCents: 99999999,
            date: DateTime(2024, 1, 1),
          ),
        );
        tester.view
          ..physicalSize = const Size(750, 1334)
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: screen,
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(db.close);
      });
    }
  }
}
