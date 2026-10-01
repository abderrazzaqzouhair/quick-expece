import 'package:database/database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quik_expense_mobile/config/providers/database_providers.dart';
import 'package:quik_expense_mobile/config/providers/preferences_providers.dart';
import 'package:quik_expense_mobile/config/router/app_routes.dart';
import 'package:quik_expense_mobile/features/profile/data/profile_providers.dart';
import 'package:quik_expense_mobile/features/profile/data/profile_store.dart';
import 'package:quik_expense_mobile/features/profile/profile_screen.dart';
import 'package:quik_expense_mobile/features/profile/screens/edit_profile_screen.dart';
import 'package:quik_expense_mobile/features/profile/screens/manage_categories_screen.dart';
import 'package:quik_expense_mobile/features/profile/screens/manage_subcategories_screen.dart';
import 'package:quik_expense_mobile/features/profile/screens/settings_screen.dart';
import 'package:quik_expense_mobile/shared/haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  String sub(String c, String s) => CatalogueSeeder.subcategoryId(c, s);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('profile store', () {
    test('defaults, save persists, initials', () async {
      final c = container();
      final p = c.read(profileProvider);
      expect(p.hasName, isFalse);
      expect(p.initials, '?');
      expect(prefs.getString('profile.memberSince'), isNotNull);

      await c
          .read(profileProvider.notifier)
          .save(name: '  sara  alaoui ', email: 'sara@x.ma', colorIndex: 3);
      expect(c.read(profileProvider).name, 'sara  alaoui');
      expect(c.read(profileProvider).initials, 'SA');
      expect(prefs.getString('profile.email'), 'sara@x.ma');
      expect(prefs.getInt('profile.colorIndex'), 3);
    });

    test('haptics setting drives the global switch', () async {
      final c = container();
      expect(c.read(settingsProvider).hapticsEnabled, isTrue);
      await c.read(settingsProvider.notifier).setHaptics(false);
      expect(Haptics.enabled, isFalse);
      expect(prefs.getBool('settings.haptics'), isFalse);
      await c.read(settingsProvider.notifier).reset();
      expect(Haptics.enabled, isTrue);
    });
  });

  group('data actions', () {
    test('CSV is oldest-first and escapes commas/quotes', () async {
      await db.expensesDao.add(
        subcategoryId: sub('Transport', 'Taxi'),
        amountCents: 3000,
        date: DateTime(2026, 9, 2, 19, 5),
        note: 'Airport, "late" flight',
      );
      await db.expensesDao.add(
        subcategoryId: sub('Food & Drinks', 'Coffee'),
        amountCents: 450,
        date: DateTime(2026, 9, 1, 8, 30),
      );
      final (csv, count) = await container()
          .read(dataActionsProvider)
          .exportCsv();
      expect(count, 2);
      expect(csv.split('\n'), [
        'Date,Time,Category,Subcategory,Amount (MAD),Note',
        '2026-09-01,08:30,Food & Drinks,Coffee,4.50,',
        '2026-09-02,19:05,Transport,Taxi,30.00,"Airport, ""late"" flight"',
        '',
      ]);
    });

    test('erase everything resets expenses, categories and profile', () async {
      final c = container();
      await db.expensesDao.add(
        subcategoryId: sub('Transport', 'Bus'),
        amountCents: 100,
        date: DateTime(2026, 9, 1),
      );
      await db.categoriesDao.setSelected(
        CatalogueSeeder.categoryId('Travel'),
        selected: false,
      );
      await c
          .read(profileProvider.notifier)
          .save(name: 'Ali', email: '', colorIndex: 2);

      await c.read(dataActionsProvider).eraseEverything();

      expect((await db.expensesDao.watchSummary().first).count, 0);
      final travel = await db.categoriesDao.findById(
        CatalogueSeeder.categoryId('Travel'),
      );
      expect(travel!.isSelected, isTrue);
      expect(c.read(profileProvider).hasName, isFalse);
    });

    test('trackingDuration', () {
      final now = DateTime.now();
      expect(trackingDuration(now), 'Today');
      expect(
        trackingDuration(DateTime(now.year, now.month, now.day - 1)),
        '1 day',
      );
      expect(
        trackingDuration(DateTime(now.year, now.month, now.day - 90)),
        '3 months',
      );
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, String initial) async {
      tester.view
        ..physicalSize = const Size(1179, 2556)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: initial,
        routes: [
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: AppRoutes.profileEdit,
            builder: (_, _) => const EditProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileCategories,
            builder: (_, _) => const ManageCategoriesScreen(),
          ),
          GoRoute(
            path: '/profile/categories/:id',
            builder: (_, s) =>
                ManageSubcategoriesScreen(categoryId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.profileSettings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await settleDb(tester);
    }

    testWidgets('hub shows stats; editing the profile updates it', (
      tester,
    ) async {
      await tester.runAsync(
        () => db.expensesDao.add(
          subcategoryId: sub('Transport', 'Bus'),
          amountCents: 1250,
          date: DateTime.now(),
        ),
      );
      await pump(tester, '/profile');

      expect(find.text('Add your name'), findsOneWidget);
      expect(find.text('12.50'), findsOneWidget); // MAD spent
      expect(find.text('Expense'), findsOneWidget); // singular
      expect(find.text('12 of 12'), findsOneWidget); // categories shown

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Sara Alaoui');
      await tester.enterText(find.byType(TextFormField).last, 'not-an-email');
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).last, 'sara@mail.ma');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Sara Alaoui'), findsOneWidget); // back on the hub
      expect(find.text('sara@mail.ma'), findsOneWidget);
      expect(find.text('SA'), findsOneWidget);
      expect(prefs.getString('profile.name'), 'Sara Alaoui');

      await disposeTree(tester);
    });

    testWidgets('leaving edit profile with changes asks to discard', (
      tester,
    ) async {
      await pump(tester, '/profile');
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Ali');
      await tester.pump(); // rebuild with the unsaved-changes guard on
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Add your name'), findsOneWidget);
      expect(prefs.getString('profile.name'), isNull);

      await disposeTree(tester);
    });

    testWidgets('hide a category; last visible one is protected', (
      tester,
    ) async {
      await pump(tester, AppRoutes.profileCategories);
      expect(find.text('12 of 12 shown'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Travel'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(switchInRow('Travel'));
      await settleDb(tester);
      expect(find.text('Hidden'), findsOneWidget); // Travel's row subtitle
      final travel = (await tester.runAsync(
        () => db.categoriesDao.findById(CatalogueSeeder.categoryId('Travel')),
      ))!;
      expect(travel.isSelected, isFalse);

      // Hide all but Miscellaneous directly (one statement), then try to
      // hide it too.
      await tester.runAsync(
        () =>
            (db.update(db.categories)
                  ..where((c) => c.name.equals('Miscellaneous').not()))
                .write(const CategoriesCompanion(isSelected: Value(false))),
      );
      await settleDb(tester);
      await tester.tap(switchInRow('Miscellaneous'));
      await settleDb(tester);
      expect(find.text('Keep at least one category visible.'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('subcategories toggle, with last-one guard', (tester) async {
      await pump(
        tester,
        AppRoutes.profileSubcategories(
          CatalogueSeeder.categoryId('Miscellaneous'),
        ),
      );
      expect(
        find.text('3 of 3 subcategories shown'.toUpperCase()),
        findsOneWidget,
      );

      await tester.tap(switchInRow('Random'));
      await settleDb(tester);
      await tester.tap(switchInRow('Small Stuff'));
      await settleDb(tester);
      expect(
        find.text('1 of 3 subcategories shown'.toUpperCase()),
        findsOneWidget,
      );

      await tester.tap(switchInRow('Unexpected'));
      await settleDb(tester);
      expect(
        find.text('Keep at least one subcategory, or hide the whole category.'),
        findsOneWidget,
      );

      await disposeTree(tester);
    });

    testWidgets('settings: delete all expenses after confirming', (
      tester,
    ) async {
      await tester.runAsync(
        () => db.expensesDao.add(
          subcategoryId: sub('Transport', 'Bus'),
          amountCents: 100,
          date: DateTime.now(),
        ),
      );
      await pump(tester, AppRoutes.profileSettings);

      await tester.tap(find.text('Delete all expenses'));
      await tester.pumpAndSettle();
      expect(find.text('Delete all 1 expenses?'), findsOneWidget);
      await tester.tap(find.text('Delete All Expenses'));
      await settleDb(tester);

      expect(find.text('1 expenses deleted'), findsOneWidget);
      final summary = (await tester.runAsync(
        () => db.expensesDao.watchSummary().first,
      ))!;
      expect(summary.count, 0);

      await disposeTree(tester);
    });
  });
}

/// The Switch in the list row whose title is [title].
Finder switchInRow(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first,
  matching: find.byType(Switch),
);

Future<void> settleDb(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Future<void> disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 6));
}
