import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/data/memory_ledger_repository.dart';
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
  });
}
