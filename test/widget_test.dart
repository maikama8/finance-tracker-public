import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/navigation/launch_location.dart';
import 'package:finance_tracker/core/theme/theme_preference.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/data/memory_ledger_repository.dart';
import 'package:finance_tracker/features/settings/domain/app_settings.dart';
import 'package:finance_tracker/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime.utc(2026, 11, 14);

  Future<void> pumpKobo(WidgetTester tester) async {
    final repo = MemoryLedgerRepository();
    await repo.ensureSeeded(today);
    await repo.materializeRecurring(today);
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(FixedClock(today)),
        ],
        child: const KoboApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard shows net worth, wallets, and the over-budget alert', (
    tester,
  ) async {
    await pumpKobo(tester);
    expect(find.text('Kobo'), findsOneWidget);
    expect(find.text('Net worth'), findsOneWidget);
    expect(find.byKey(const Key('net-worth')), findsOneWidget);
    expect(find.text('Over budget'), findsOneWidget);
    expect(find.text('GTBank Salary'), findsWidgets);
    expect(find.text('OPay Everyday'), findsWidgets);
  });

  testWidgets('activity search filters notes', (tester) async {
    await pumpKobo(tester);
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Market run'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('transaction-search')), 'Mum');
    await tester.pumpAndSettle();
    expect(find.text('Send to Mum'), findsOneWidget);
    expect(find.text('Market run'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('transaction-search')),
      'zzzz-not-a-note',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing matches'), findsOneWidget);
  });

  testWidgets('activity filters include a date range', (tester) async {
    await pumpKobo(tester);
    tester.view.physicalSize = const Size(800, 900);
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Any date'), findsNWidgets(2));
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('budgets screen shows food over the monthly limit', (
    tester,
  ) async {
    await pumpKobo(tester);
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);
    expect(find.textContaining('over'), findsWidgets);
    expect(find.text('November 2026'), findsOneWidget);
  });

  testWidgets('accounts screen lists the mobile money wallets', (tester) async {
    await pumpKobo(tester);
    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();
    expect(find.text('OPay Everyday'), findsOneWidget);
    expect(find.text('Moniepoint Business'), findsOneWidget);
    expect(find.textContaining('Total in NGN'), findsOneWidget);
  });

  testWidgets('settings switches the theme to dark', (tester) async {
    await pumpKobo(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Appearance'));
    expect(Theme.of(context).brightness, Brightness.dark);
    await tester.scrollUntilVisible(find.text('Restore demo ledger'), 200);
    await tester.tap(find.text('Restore demo ledger'));
    await tester.pumpAndSettle();
    expect(find.text('Restore demo ledger?'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('an empty book explains what to add', (tester) async {
    final repo = MemoryLedgerRepository();
    await repo.saveSettings(const AppSettings(seeded: true));
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(FixedClock(today)),
        ],
        child: const KoboApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No spending yet'), findsOneWidget);
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('No transactions yet'), findsOneWidget);
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();
    expect(find.text('No budgets yet'), findsOneWidget);
    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();
    expect(find.text('No accounts yet'), findsOneWidget);
  });

  testWidgets('a launch location opens that tab in the requested theme', (
    tester,
  ) async {
    final repo = MemoryLedgerRepository();
    await repo.ensureSeeded(today);
    await repo.materializeRecurring(today);
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(FixedClock(today)),
          launchLocationProvider.overrideWithValue(
            const LaunchLocation(tab: 2, themeOverride: ThemePreference.dark),
          ),
        ],
        child: const KoboApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('November 2026'))).brightness,
      Brightness.dark,
    );
  });
}
