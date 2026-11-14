import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/money_format.dart';
import '../../../state/providers.dart';
import '../../../ui/icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets.dart';
import '../../dashboard/domain/ledger_report.dart';
import '../domain/account.dart';
import 'account_form_sheet.dart';

/// Wallets, with a native balance and a base-currency estimate.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    if (ledger == null) return const SizedBox.shrink();
    final rates = ref.watch(rateBookProvider);
    final base = ledger.settings.baseCurrencyCode;
    final active = ledger.accounts
        .where((account) => !account.archived)
        .toList();
    final archived = ledger.accounts
        .where((account) => account.archived)
        .toList();
    final total = LedgerReport.netWorthMinor(
      accounts: ledger.accounts,
      transactions: ledger.transactions,
      rates: rates,
      baseCurrency: base,
      asOf: ref.watch(clockProvider).today(),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: <Widget>[
        Text('Total in $base', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          formatMinor(total, base),
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (active.isEmpty && archived.isEmpty)
          const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No accounts yet',
            message: 'Add a bank, a cash wallet, or mobile money.',
          ),
        for (final account in active) ...<Widget>[
          _AccountCard(id: account.id),
          const SizedBox(height: 10),
        ],
        if (archived.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          const Text('Archived', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final account in archived) ...<Widget>[
            _AccountCard(id: account.id),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    if (ledger == null) return const SizedBox.shrink();
    final account = ledger.accountById(id);
    if (account == null) return const SizedBox.shrink();
    final balance = LedgerReport.balanceMinor(account, ledger.transactions);
    final base = ledger.settings.baseCurrencyCode;
    final rates = ref.watch(rateBookProvider);
    final converted = rates.convertMinor(
      amountMinor: balance,
      from: account.currencyCode,
      to: base,
    );
    final muted = AppColors.mutedOf(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showAccountForm(context, accountId: account.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Color(account.color).withValues(alpha: 0.16),
                child: Icon(
                  accountKindIcon(account.kind),
                  color: Color(account.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${account.institution ?? account.kind.label} · ${account.currencyCode}',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatMinor(balance, account.currencyCode),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (account.currencyCode != base)
                    Text(
                      '≈ ${formatMinor(converted, base)}',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
