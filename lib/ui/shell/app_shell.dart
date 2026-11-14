import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/presentation/account_form_sheet.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/budgets/presentation/budget_form_sheet.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/import_export/presentation/csv_actions.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/transaction_form_sheet.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../state/providers.dart';

/// Navigation shell. Wide windows use a rail. Narrow windows use a bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider);
    return ledger.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 12),
                Text(
                  'The ledger could not be opened.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(ledgerProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (_) => const _LoadedShell(),
    );
  }
}

class _LoadedShell extends ConsumerWidget {
  const _LoadedShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final onSettings = tab == 4;
    final page = switch (tab) {
      1 => const TransactionsScreen(),
      2 => const BudgetsScreen(),
      3 => const AccountsScreen(),
      4 => const SettingsScreen(),
      _ => const DashboardScreen(),
    };
    final title = switch (tab) {
      1 => 'Activity',
      2 => 'Budgets',
      3 => 'Accounts',
      4 => 'Settings',
      _ => 'Kobo',
    };
    final fab = switch (tab) {
      1 => FloatingActionButton.extended(
        onPressed: () => showTransactionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Transaction'),
      ),
      2 => FloatingActionButton.extended(
        onPressed: () => showBudgetForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
      3 => FloatingActionButton.extended(
        onPressed: () => showAccountForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Account'),
      ),
      _ => null,
    };
    final bar = AppBar(
      leading: onSettings
          ? IconButton(
              tooltip: 'Back',
              onPressed: () => ref.read(shellProvider.notifier).select(0),
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      title: Text(title),
      actions: <Widget>[
        if (tab == 1) ...<Widget>[
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await exportLedger(ref, messenger);
            },
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Import CSV',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await importLedger(ref, messenger);
            },
            icon: const Icon(Icons.upload_outlined),
          ),
        ],
        if (!onSettings)
          IconButton(
            tooltip: 'Settings',
            onPressed: () => ref.read(shellProvider.notifier).select(4),
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
    );
    final destinations = const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Activity',
      ),
      NavigationDestination(
        icon: Icon(Icons.pie_chart_outline),
        selectedIcon: Icon(Icons.pie_chart),
        label: 'Budgets',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Accounts',
      ),
    ];
    if (wide) {
      return Scaffold(
        appBar: bar,
        floatingActionButton: fab,
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: onSettings ? null : tab,
              onDestinationSelected: ref.read(shellProvider.notifier).select,
              labelType: NavigationRailLabelType.all,
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Activity'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: Text('Budgets'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Accounts'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: page,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: bar,
      floatingActionButton: fab,
      body: page,
      bottomNavigationBar: onSettings
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: ref.read(shellProvider.notifier).select,
              destinations: destinations,
            ),
    );
  }
}
