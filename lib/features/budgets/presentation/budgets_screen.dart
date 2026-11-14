import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/money_format.dart';
import '../../../state/providers.dart';
import '../../../ui/icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets.dart';
import '../domain/budget_engine.dart';
import 'budget_form_sheet.dart';

/// Monthly limits, and how much of each one is already spent.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    final month = ref.watch(budgetMonthProvider);
    if (ledger == null) return const SizedBox.shrink();
    final snapshots = BudgetEngine.progress(
      budgets: ledger.budgets,
      categories: ledger.categories,
      transactions: ledger.transactions,
      rates: ref.watch(rateBookProvider),
      baseCurrency: ledger.settings.baseCurrencyCode,
      year: month.year,
      month: month.month,
    );
    final over = snapshots.where((item) => item.isOver).length;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Previous month',
                onPressed: () =>
                    ref.read(budgetMonthProvider.notifier).shift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  formatMonthYear(month.year, month.month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () =>
                    ref.read(budgetMonthProvider.notifier).shift(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              over == 0 ? 'Nothing is over budget.' : '$over over budget',
              style: TextStyle(
                color: over == 0 ? AppColors.income : AppColors.expense,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: snapshots.isEmpty
              ? const Center(
                  child: EmptyState(
                    icon: Icons.pie_chart_outline,
                    title: 'No budgets yet',
                    message: 'Set a monthly limit for a spending category.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: snapshots.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final snapshot = snapshots[index];
                    return _BudgetCard(snapshot: snapshot);
                  },
                ),
        ),
      ],
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.snapshot});

  final BudgetSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = snapshot.isOver ? AppColors.expense : AppColors.income;
    final status = snapshot.remainingMinor < 0
        ? '${formatMinor(snapshot.remainingMinor.abs(), snapshot.baseCurrency)} over'
        : snapshot.remainingMinor == 0
        ? 'On budget'
        : '${formatMinor(snapshot.remainingMinor, snapshot.baseCurrency)} left';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showBudgetForm(context, budgetId: snapshot.budgetId),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    categoryIcon(snapshot.iconKey),
                    color: Color(snapshot.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      snapshot.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(formatShare(snapshot.spentMinor, snapshot.limitMinor)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: snapshot.ratio.clamp(0, 1).toDouble(),
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatMinor(snapshot.spentMinor, snapshot.baseCurrency)} of ${formatMinor(snapshot.limitMinor, snapshot.baseCurrency)} · $status',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
