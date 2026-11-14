import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/exchange_rate_service.dart';
import '../../../core/formatting/money_format.dart';
import '../../../state/providers.dart';
import '../../../ui/icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets.dart';
import '../../accounts/domain/account.dart';
import '../../dashboard/domain/ledger_report.dart';
import '../../transactions/domain/ledger_transaction.dart';
import 'dashboard_charts.dart';

/// Net worth, wallets, charts, and the latest postings.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figures = ref.watch(dashboardProvider);
    final ledger = ref.watch(ledgerProvider).asData?.value;
    if (figures == null || ledger == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final hero = _Hero(figures: figures);
    final wallets = _Wallets(figures: figures);
    final charts = <Widget>[
      SectionCard(
        title: 'Spending this month',
        subtitle: 'Expenses, converted to ${figures.baseCurrency}',
        child: SpendingPie(
          spending: figures.spending,
          currency: figures.baseCurrency,
        ),
      ),
      SectionCard(
        title: 'Cash flow',
        subtitle: 'Income and spending, transfers left out',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Legend(),
            const SizedBox(height: 8),
            CashFlowChart(trend: figures.trend, currency: figures.baseCurrency),
          ],
        ),
      ),
      SectionCard(
        title: 'Net worth',
        subtitle: 'Balances converted at the active rates',
        child: NetWorthChart(
          points: figures.netWorth,
          currency: figures.baseCurrency,
        ),
      ),
    ];
    const recent = _Recent();
    if (!wide) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          hero,
          const SizedBox(height: 12),
          wallets,
          const SizedBox(height: 12),
          for (final chart in charts) ...<Widget>[
            chart,
            const SizedBox(height: 12),
          ],
          recent,
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Column(
                children: <Widget>[
                  hero,
                  const SizedBox(height: 12),
                  wallets,
                  const SizedBox(height: 12),
                  recent,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < charts.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 12),
                    charts[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.figures});

  final DashboardFigures figures;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.mutedOf(context);
    final netColor = figures.month.netMinor < 0
        ? AppColors.expense
        : AppColors.income;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Net worth', style: TextStyle(color: muted)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMinor(figures.netWorthMinor, figures.baseCurrency),
                key: const Key('net-worth'),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatMonthYear(figures.today.year, figures.today.month)} · ${figures.baseCurrency} · offline unless you refresh rates',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                StatTile(
                  label: 'Income',
                  value: formatMinor(
                    figures.month.incomeMinor,
                    figures.baseCurrency,
                  ),
                  color: AppColors.income,
                ),
                StatTile(
                  label: 'Spent',
                  value: formatMinor(
                    figures.month.expenseMinor,
                    figures.baseCurrency,
                  ),
                  color: AppColors.expense,
                ),
                StatTile(
                  label: 'Net',
                  value: formatSignedMinor(
                    figures.month.netMinor,
                    figures.baseCurrency,
                  ),
                  color: netColor,
                ),
              ],
            ),
            if (figures.alerts.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _AlertBanner(figures: figures),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.figures});

  final DashboardFigures figures;

  @override
  Widget build(BuildContext context) {
    final lines = figures.alerts
        .map(
          (alert) =>
              '${alert.categoryName} is ${formatMinor(alert.remainingMinor.abs(), figures.baseCurrency)} over',
        )
        .join(' · ');
    return Container(
      key: const Key('over-budget'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Over budget',
            style: TextStyle(
              color: AppColors.expense,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(lines),
        ],
      ),
    );
  }
}

class _Wallets extends ConsumerWidget {
  const _Wallets({required this.figures});

  final DashboardFigures figures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    final rates = ref.watch(rateBookProvider);
    if (ledger == null) return const SizedBox.shrink();
    final accounts = ledger.accounts.where((account) => !account.archived);
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (final account in accounts)
            _WalletCard(
              account: account,
              transactions: ledger.transactions,
              rates: rates,
              baseCurrency: figures.baseCurrency,
            ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.account,
    required this.transactions,
    required this.rates,
    required this.baseCurrency,
  });

  final Account account;
  final List<LedgerTransaction> transactions;
  final ExchangeRateService rates;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    final balance = LedgerReport.balanceMinor(account, transactions);
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(accountKindIcon(account.kind), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                formatMinor(balance, account.currencyCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (account.currencyCode != baseCurrency)
                Text(
                  '≈ ${formatMinor(rates.convertMinor(amountMinor: balance, from: account.currencyCode, to: baseCurrency), baseCurrency)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedOf(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _Swatch(color: AppColors.income, label: 'Income'),
        SizedBox(width: 12),
        _Swatch(color: AppColors.expense, label: 'Spent'),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _Recent extends ConsumerWidget {
  const _Recent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    if (ledger == null) return const SizedBox.shrink();
    final recent = ledger.transactions.take(5).toList(growable: false);
    return SectionCard(
      title: 'Recent',
      child: recent.isEmpty
          ? Text(
              'Nothing posted yet.',
              style: TextStyle(color: AppColors.mutedOf(context)),
            )
          : Column(
              children: <Widget>[
                for (final txn in recent) _RecentRow(txnId: txn.id),
              ],
            ),
    );
  }
}

class _RecentRow extends ConsumerWidget {
  const _RecentRow({required this.txnId});

  final String txnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData!.value;
    final txn = ledger.transactions.firstWhere((item) => item.id == txnId);
    final account = ledger.accountById(txn.accountId);
    final category = txn.categoryId == null
        ? null
        : ledger.categoryById(txn.categoryId!);
    final color = switch (txn.kind) {
      TransactionKind.income => AppColors.income,
      TransactionKind.expense => AppColors.expense,
      TransactionKind.transfer => Theme.of(context).colorScheme.onSurface,
    };
    final signed = switch (txn.kind) {
      TransactionKind.income => txn.amountMinor,
      TransactionKind.expense => -txn.amountMinor,
      TransactionKind.transfer => txn.amountMinor,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(
            category == null
                ? Icons.swap_horiz
                : categoryIcon(category.iconKey),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(txn.note.isEmpty ? txn.kind.label : txn.note),
                Text(
                  '${formatShortDate(txn.occurredOn)} · ${account?.name ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            txn.kind == TransactionKind.income
                ? formatSignedMinor(signed, txn.currencyCode)
                : formatMinor(signed, txn.currencyCode),
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
