import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/money_format.dart';
import '../../../state/providers.dart';
import '../../../ui/widgets.dart';
import '../../transactions/domain/category.dart';
import '../domain/category_budget.dart';

/// Opens the sheet for a new budget, or the budget with [budgetId].
Future<void> showBudgetForm(BuildContext context, {String? budgetId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => BudgetFormSheet(budgetId: budgetId),
  );
}

/// Create or edit one monthly category limit.
class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({this.budgetId, super.key});

  final String? budgetId;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late final TextEditingController _amount;
  String? _categoryId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ledger = ref.read(ledgerProvider).asData?.value;
    final existing = _existing(ledger?.budgets);
    _amount = TextEditingController(
      text: existing == null ? '' : formatEditableAmount(existing.limitMinor),
    );
    _categoryId = existing?.categoryId;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  CategoryBudget? _existing(List<CategoryBudget>? budgets) {
    if (widget.budgetId == null || budgets == null) return null;
    for (final budget in budgets) {
      if (budget.id == widget.budgetId) return budget;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    if (ledger == null) return const SizedBox.shrink();
    final existing = _existing(ledger.budgets);
    final taken = <String>{
      for (final budget in ledger.budgets)
        if (budget.id != existing?.id) budget.categoryId,
    };
    final choices = ledger.categories.where((category) {
      return category.kind == CategoryKind.expense &&
          (category.id == existing?.categoryId || !taken.contains(category.id));
    }).toList();
    _categoryId ??= choices.isEmpty ? null : choices.first.id;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            existing == null ? 'New budget' : 'Edit budget',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: <DropdownMenuItem<String>>[
              for (final category in choices)
                DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: existing == null
                ? (value) => setState(() => _categoryId = value)
                : null,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monthly limit',
              prefixText: '${ledger.settings.baseCurrencyCode} ',
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            FieldError(_error!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final amount = parseMoneyInput(_amount.text);
              if (amount == null || _categoryId == null) {
                setState(() => _error = 'Enter a limit above zero.');
                return;
              }
              final budget = CategoryBudget(
                id: existing?.id ?? ref.read(idSourceProvider).next('bud'),
                categoryId: _categoryId!,
                limitMinor: amount,
                currencyCode: ledger.settings.baseCurrencyCode,
              );
              await ref.read(ledgerProvider.notifier).saveBudget(budget);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          if (existing != null)
            TextButton(
              onPressed: () async {
                await ref
                    .read(ledgerProvider.notifier)
                    .deleteBudget(existing.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }
}
