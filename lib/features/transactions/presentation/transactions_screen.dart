import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/money_format.dart';
import '../../../core/time/iso_date.dart';
import '../../../state/providers.dart';
import '../../../ui/icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets.dart';
import '../domain/ledger_transaction.dart';
import '../domain/recurring_rule.dart';
import '../domain/transaction_query.dart';
import 'transaction_form_sheet.dart';

/// Searchable list of postings, grouped by day, plus the repeating rules.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    final query = ref.watch(transactionQueryProvider);
    if (ledger == null) return const SizedBox.shrink();
    final visible = filterTransactions(
      transactions: ledger.transactions,
      accounts: ledger.accounts,
      categories: ledger.categories,
      query: query,
    );
    final today = ref.watch(clockProvider).today();
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            key: const Key('transaction-search'),
            decoration: InputDecoration(
              hintText: 'Search notes, accounts, categories',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () => ref
                          .read(transactionQueryProvider.notifier)
                          .update(query.copyWith(text: '')),
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (value) => ref
                .read(transactionQueryProvider.notifier)
                .update(query.copyWith(text: value)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: <Widget>[
              _KindChip(label: 'All', kind: null, selected: query.kind),
              _KindChip(
                label: 'Income',
                kind: TransactionKind.income,
                selected: query.kind,
              ),
              _KindChip(
                label: 'Expense',
                kind: TransactionKind.expense,
                selected: query.kind,
              ),
              _KindChip(
                label: 'Transfers',
                kind: TransactionKind.transfer,
                selected: query.kind,
              ),
              ActionChip(
                label: Text(query.hasFacet ? 'Filters on' : 'Filters'),
                avatar: const Icon(Icons.tune, size: 18),
                onPressed: () => _showFilters(context, ref),
              ),
            ],
          ),
        ),
        if (ledger.rules.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: <Widget>[
                for (final rule in ledger.rules)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        '${rule.note} · ${rule.frequency.label.toLowerCase()}',
                      ),
                      onPressed: () => _showRule(context, ref, rule, today),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: query.isNarrowed
                        ? Icons.search_off
                        : Icons.receipt_long_outlined,
                    title: query.isNarrowed
                        ? 'Nothing matches'
                        : 'No transactions yet',
                    message: query.isNarrowed
                        ? 'Try a different note, account, or date.'
                        : 'Add income, an expense, or a transfer.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final txn = visible[index];
                    final previous = index == 0 ? null : visible[index - 1];
                    final showHeader =
                        previous == null ||
                        !sameDay(previous.occurredOn, txn.occurredOn);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                            child: Text(
                              _heading(txn.occurredOn, today),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        _TransactionTile(id: txn.id),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showFilters(BuildContext context, WidgetRef ref) async {
    final ledger = ref.read(ledgerProvider).asData?.value;
    if (ledger == null) return;
    var query = ref.read(transactionQueryProvider);
    final today = ref.read(clockProvider).today();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bottom = MediaQuery.viewInsetsOf(context).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: query.accountId,
                      decoration: const InputDecoration(labelText: 'Account'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any account'),
                        ),
                        for (final account in ledger.accounts)
                          DropdownMenuItem<String?>(
                            value: account.id,
                            child: Text(account.name),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        query = query.copyWith(
                          accountId: value,
                          clearAccount: value == null,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('From'),
                      subtitle: Text(
                        query.from == null
                            ? 'Any date'
                            : formatShortDate(query.from!),
                      ),
                      trailing: query.from == null
                          ? const Icon(Icons.calendar_today_outlined)
                          : IconButton(
                              tooltip: 'Clear start date',
                              onPressed: () => setState(
                                () => query = query.copyWith(clearFrom: true),
                              ),
                              icon: const Icon(Icons.close),
                            ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: query.from ?? today,
                          firstDate: DateTime.utc(2000),
                          lastDate: DateTime.utc(2100),
                        );
                        if (picked == null) return;
                        setState(
                          () => query = query.copyWith(from: dateOnly(picked)),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('To'),
                      subtitle: Text(
                        query.to == null
                            ? 'Any date'
                            : formatShortDate(query.to!),
                      ),
                      trailing: query.to == null
                          ? const Icon(Icons.calendar_today_outlined)
                          : IconButton(
                              tooltip: 'Clear end date',
                              onPressed: () => setState(
                                () => query = query.copyWith(clearTo: true),
                              ),
                              icon: const Icon(Icons.close),
                            ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: query.to ?? today,
                          firstDate: DateTime.utc(2000),
                          lastDate: DateTime.utc(2100),
                        );
                        if (picked == null) return;
                        setState(
                          () => query = query.copyWith(to: dateOnly(picked)),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: query.categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any category'),
                        ),
                        for (final category in ledger.categories)
                          DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        query = query.copyWith(
                          categoryId: value,
                          clearCategory: value == null,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            ref
                                .read(transactionQueryProvider.notifier)
                                .update(
                                  query.copyWith(
                                    clearAccount: true,
                                    clearCategory: true,
                                    clearFrom: true,
                                    clearTo: true,
                                  ),
                                );
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        FilledButton(
                          // Form buttons stretch. A row cannot give this one
                          // an infinite width, so it sizes to the label.
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () {
                            ref
                                .read(transactionQueryProvider.notifier)
                                .update(query);
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRule(
    BuildContext context,
    WidgetRef ref,
    RecurringRule rule,
    DateTime today,
  ) async {
    final next = RecurringSchedule.nextAfter(rule, today);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(rule.note),
          content: Text(
            '${rule.frequency.label} · ${formatMinor(rule.amountMinor, rule.currencyCode)}'
            '${next == null ? '' : '\nNext ${formatShortDate(next)}'}'
            '${rule.active ? '' : '\nPaused'}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await ref
                    .read(ledgerProvider.notifier)
                    .setRuleActive(rule.id, active: !rule.active);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(rule.active ? 'Pause' : 'Resume'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(ledgerProvider.notifier).deleteRule(rule.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Delete rule'),
            ),
          ],
        );
      },
    );
  }
}

class _KindChip extends ConsumerWidget {
  const _KindChip({
    required this.label,
    required this.kind,
    required this.selected,
  });

  final String label;
  final TransactionKind? kind;
  final TransactionKind? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = selected == kind;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: on,
        onSelected: (_) {
          final query = ref.read(transactionQueryProvider);
          ref
              .read(transactionQueryProvider.notifier)
              .update(
                query.copyWith(kind: kind, clearKind: kind == null || on),
              );
        },
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    if (ledger == null) return const SizedBox.shrink();
    LedgerTransaction? txn;
    for (final item in ledger.transactions) {
      if (item.id == id) txn = item;
    }
    if (txn == null) return const SizedBox.shrink();
    final current = txn;
    final account = ledger.accountById(current.accountId);
    final category = current.categoryId == null
        ? null
        : ledger.categoryById(current.categoryId!);
    final color = switch (current.kind) {
      TransactionKind.income => AppColors.income,
      TransactionKind.expense => AppColors.expense,
      TransactionKind.transfer => Theme.of(context).colorScheme.onSurface,
    };
    final amount = switch (current.kind) {
      TransactionKind.income => formatSignedMinor(
        current.amountMinor,
        current.currencyCode,
      ),
      TransactionKind.expense => formatMinor(
        -current.amountMinor,
        current.currencyCode,
      ),
      TransactionKind.transfer => formatMinor(
        current.amountMinor,
        current.currencyCode,
      ),
    };
    return ListTile(
      leading: Icon(
        category == null ? Icons.swap_horiz : categoryIcon(category.iconKey),
        color: category == null ? null : Color(category.color),
      ),
      title: Text(current.note.isEmpty ? current.kind.label : current.note),
      subtitle: Text(
        account?.name ?? '',
        style: TextStyle(color: AppColors.mutedOf(context)),
      ),
      trailing: Text(
        amount,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      onTap: () => showTransactionForm(context, existing: current),
    );
  }
}

String _heading(DateTime date, DateTime today) {
  if (sameDay(date, today)) {
    return 'Today';
  }
  if (sameDay(date, today.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return formatShortDate(date);
}
