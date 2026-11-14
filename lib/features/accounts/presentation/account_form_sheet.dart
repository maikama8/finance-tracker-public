import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/currency.dart';
import '../../../core/formatting/money_format.dart';
import '../../../state/providers.dart';
import '../domain/account.dart';

Future<void> showAccountForm(BuildContext context, {String? accountId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => AccountFormSheet(accountId: accountId),
  );
}

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({this.accountId, super.key});

  final String? accountId;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _institution;
  late final TextEditingController _opening;
  late AccountKind _kind;
  late String _currency;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ledger = ref.read(ledgerProvider).asData?.value;
    final existing = ledger?.accountById(widget.accountId ?? '');
    _name = TextEditingController(text: existing?.name ?? '');
    _institution = TextEditingController(text: existing?.institution ?? '');
    _opening = TextEditingController(
      text: existing == null ? '' : _major(existing.openingBalanceMinor),
    );
    _kind = existing?.kind ?? AccountKind.bank;
    _currency =
        existing?.currencyCode ??
        ledger?.settings.baseCurrencyCode ??
        Currencies.defaultBase;
  }

  @override
  void dispose() {
    _name.dispose();
    _institution.dispose();
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    final existing = ledger?.accountById(widget.accountId ?? '');
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              existing == null ? 'New account' : existing.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountKind>(
              isExpanded: true,
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Kind'),
              items: const <DropdownMenuItem<AccountKind>>[
                DropdownMenuItem(value: AccountKind.cash, child: Text('Cash')),
                DropdownMenuItem(value: AccountKind.bank, child: Text('Bank')),
                DropdownMenuItem(
                  value: AccountKind.mobileMoney,
                  child: Text('Mobile money'),
                ),
              ],
              onChanged: existing == null
                  ? (value) {
                      if (value != null) setState(() => _kind = value);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: <DropdownMenuItem<String>>[
                for (final currency in Currencies.all)
                  DropdownMenuItem<String>(
                    value: currency.code,
                    child: Text('${currency.code} · ${currency.name}'),
                  ),
              ],
              onChanged: existing == null
                  ? (value) {
                      if (value != null) setState(() => _currency = value);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _institution,
              decoration: const InputDecoration(
                labelText: 'Institution',
                hintText: 'GTBank, OPay, Moniepoint',
              ),
            ),
            if (existing == null) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: _opening,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Opening balance',
                  hintText: '0',
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty) {
                  setState(() => _error = 'Name the account.');
                  return;
                }
                final opening =
                    parseMoneyInput(_opening.text, allowZero: true) ?? 0;
                if (existing == null &&
                    _opening.text.trim().isNotEmpty &&
                    parseMoneyInput(_opening.text, allowZero: true) == null) {
                  setState(() => _error = 'Opening balance is not a number.');
                  return;
                }
                final account = Account(
                  id: existing?.id ?? ref.read(idSourceProvider).next('acct'),
                  name: name,
                  kind: _kind,
                  currencyCode: existing?.currencyCode ?? _currency,
                  openingBalanceMinor: existing?.openingBalanceMinor ?? opening,
                  institution: _institution.text.trim().isEmpty
                      ? null
                      : _institution.text.trim(),
                  color: existing?.color ?? _colorFor(name),
                  createdAt:
                      existing?.createdAt ?? ref.read(clockProvider).now(),
                );
                await ref
                    .read(ledgerProvider.notifier)
                    .saveAccount(account, isNew: existing == null);
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
                      .setAccountArchived(
                        existing.id,
                        archived: !existing.archived,
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text(existing.archived ? 'Restore' : 'Archive'),
              ),
          ],
        ),
      ),
    );
  }
}

int _colorFor(String name) {
  const palette = <int>[
    0xFF0E8F5B,
    0xFF1D4E89,
    0xFFC5922C,
    0xFF5B4B8A,
    0xFFB23A32,
    0xFF2A9D8F,
  ];
  return palette[(name.hashCode & 0x7fffffff) % palette.length];
}

String _major(int minor) {
  final fraction = minor.abs() % 100;
  final major = minor ~/ 100;
  if (fraction == 0) return '$major';
  return '$major.${fraction.toString().padLeft(2, '0')}';
}
