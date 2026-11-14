import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/money_format.dart';
import '../../../core/time/iso_date.dart';
import '../../../state/providers.dart';
import '../../../ui/widgets.dart';
import '../domain/category.dart';
import '../domain/ledger_transaction.dart';
import '../domain/recurring_rule.dart';

/// Opens the sheet for a new posting, or for [existing].
Future<void> showTransactionForm(
  BuildContext context, {
  LedgerTransaction? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => TransactionFormSheet(existing: existing),
  );
}

/// Create or edit one posting. A new posting can also start a rule.
class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({this.existing, super.key});

  final LedgerTransaction? existing;

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late TransactionKind _kind;
  late String? _accountId;
  late String? _counterId;
  late String? _categoryId;
  late DateTime _date;
  late bool _repeat;
  late RecurrenceFrequency _frequency;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amount = TextEditingController(
      text: existing == null ? '' : formatEditableAmount(existing.amountMinor),
    );
    _note = TextEditingController(text: existing?.note ?? '');
    _kind = existing?.kind ?? TransactionKind.expense;
    _accountId = existing?.accountId;
    _counterId = existing?.counterAccountId;
    _categoryId = existing?.categoryId;
    _date = existing == null
        ? ref.read(clockProvider).today()
        : dateOnly(existing.occurredOn);
    _repeat = false;
    _frequency = RecurrenceFrequency.monthly;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    if (ledger == null) return const SizedBox.shrink();
    final accounts = ledger.accounts
        .where((account) => !account.archived)
        .toList();
    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }
    if (_counterId == _accountId) _counterId = null;
    final account = ledger.accountById(_accountId ?? '');
    final categories = ledger.categories.where((category) {
      return _kind == TransactionKind.income
          ? category.kind == CategoryKind.income
          : category.kind == CategoryKind.expense;
    }).toList();
    if (_kind != TransactionKind.transfer &&
        (_categoryId == null ||
            categories.every((category) => category.id != _categoryId))) {
      _categoryId = categories.isEmpty ? null : categories.first.id;
    }
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    String? conversion;
    if (_kind == TransactionKind.transfer &&
        account != null &&
        _counterId != null) {
      final counter = ledger.accountById(_counterId!);
      final amount = parseMoneyInput(_amount.text);
      if (counter != null &&
          amount != null &&
          counter.currencyCode != account.currencyCode) {
        final destination = ref
            .read(rateBookProvider)
            .convertMinor(
              amountMinor: amount,
              from: account.currencyCode,
              to: counter.currencyCode,
            );
        conversion =
            '${counter.name} receives ${formatMinor(destination, counter.currencyCode)}';
      }
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.existing == null ? 'New transaction' : 'Edit transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<TransactionKind>(
              segments: const <ButtonSegment<TransactionKind>>[
                ButtonSegment(
                  value: TransactionKind.income,
                  label: Text('Income'),
                ),
                ButtonSegment(
                  value: TransactionKind.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: TransactionKind.transfer,
                  label: Text('Transfer'),
                ),
              ],
              selected: <TransactionKind>{_kind},
              onSelectionChanged: (value) =>
                  setState(() => _kind = value.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: account == null ? null : '${account.currencyCode} ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _accountId,
              decoration: InputDecoration(
                labelText: _kind == TransactionKind.transfer
                    ? 'From account'
                    : 'Account',
              ),
              items: <DropdownMenuItem<String>>[
                for (final item in accounts)
                  DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.name),
                  ),
              ],
              onChanged: (value) => setState(() => _accountId = value),
            ),
            if (_kind == TransactionKind.transfer) ...<Widget>[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _counterId,
                decoration: const InputDecoration(labelText: 'To account'),
                items: <DropdownMenuItem<String>>[
                  for (final item in accounts)
                    if (item.id != _accountId)
                      DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                ],
                onChanged: (value) => setState(() => _counterId = value),
              ),
              if (conversion != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(conversion),
              ],
            ] else ...<Widget>[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: <DropdownMenuItem<String>>[
                  for (final item in categories)
                    DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.name),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(formatShortDate(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.utc(2000),
                  lastDate: DateTime.utc(2100),
                );
                if (picked != null) setState(() => _date = dateOnly(picked));
              },
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            if (widget.existing == null && _kind != TransactionKind.transfer)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat'),
                subtitle: const Text('Post this again on the same schedule'),
                value: _repeat,
                onChanged: (value) => setState(() => _repeat = value),
              ),
            if (_repeat)
              DropdownButtonFormField<RecurrenceFrequency>(
                isExpanded: true,
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Every'),
                items: const <DropdownMenuItem<RecurrenceFrequency>>[
                  DropdownMenuItem(
                    value: RecurrenceFrequency.weekly,
                    child: Text('Week'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.monthly,
                    child: Text('Month'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.yearly,
                    child: Text('Year'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _frequency = value);
                },
              ),
            if (widget.existing?.recurringRuleId != null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'This is one occurrence. Pausing the rule does not remove it.',
                ),
              ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              FieldError(_error!),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _save(accounts.isEmpty),
              child: Text(widget.existing == null ? 'Save' : 'Update'),
            ),
            if (widget.existing != null)
              TextButton(
                onPressed: () async {
                  await ref
                      .read(ledgerProvider.notifier)
                      .deleteTransaction(widget.existing!.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(bool noAccounts) async {
    final ledger = ref.read(ledgerProvider).asData?.value;
    if (ledger == null || noAccounts || _accountId == null) {
      setState(() => _error = 'Add an account first.');
      return;
    }
    final account = ledger.accountById(_accountId!);
    if (account == null) return;
    final amount = parseMoneyInput(_amount.text);
    if (amount == null) {
      setState(() => _error = 'Enter an amount like 1500 or 1500.50.');
      return;
    }
    if (_kind != TransactionKind.transfer && _categoryId == null) {
      setState(() => _error = 'Choose a category.');
      return;
    }
    int? destination;
    if (_kind == TransactionKind.transfer) {
      if (_counterId == null || _counterId == _accountId) {
        setState(() => _error = 'Choose a different account to receive it.');
        return;
      }
      final counter = ledger.accountById(_counterId!);
      if (counter == null) return;
      destination = counter.currencyCode == account.currencyCode
          ? amount
          : ref
                .read(rateBookProvider)
                .convertMinor(
                  amountMinor: amount,
                  from: account.currencyCode,
                  to: counter.currencyCode,
                );
    }
    final isNew = widget.existing == null;
    final ids = ref.read(idSourceProvider);
    RecurringRule? rule;
    var id = widget.existing?.id ?? ids.next('txn');
    if (isNew && _repeat) {
      final ruleId = ids.next('rule');
      id = RecurringSchedule.transactionId(ruleId, _date);
      rule = RecurringRule(
        id: ruleId,
        kind: _kind,
        frequency: _frequency,
        interval: 1,
        startOn: _date,
        accountId: account.id,
        categoryId: _categoryId,
        amountMinor: amount,
        currencyCode: account.currencyCode,
        note: _note.text.trim(),
        lastMaterializedOn: _date,
      );
    }
    final txn = LedgerTransaction(
      id: id,
      kind: _kind,
      accountId: account.id,
      counterAccountId: _kind == TransactionKind.transfer ? _counterId : null,
      categoryId: _kind == TransactionKind.transfer ? null : _categoryId,
      amountMinor: amount,
      destinationAmountMinor: destination,
      currencyCode: account.currencyCode,
      occurredOn: _date,
      note: _note.text.trim(),
      recurringRuleId: rule?.id ?? widget.existing?.recurringRuleId,
    );
    await ref
        .read(ledgerProvider.notifier)
        .saveTransaction(transaction: txn, newRule: rule, isNew: isNew);
    if (!mounted) return;
    Navigator.pop(context);
  }
}
