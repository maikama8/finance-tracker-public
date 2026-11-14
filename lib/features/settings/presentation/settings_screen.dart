import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency/currency.dart';
import '../../../core/currency/mock_exchange_rate_service.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../state/providers.dart';
import '../../../ui/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider).asData?.value;
    if (ledger == null) return const SizedBox.shrink();
    final settings = ledger.settings;
    final rates = ref.watch(rateBookProvider);
    final live = rates is! MockExchangeRateService;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMuted
        : AppColors.muted;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemePreference>(
          segments: const <ButtonSegment<ThemePreference>>[
            ButtonSegment(value: ThemePreference.system, label: Text('System')),
            ButtonSegment(value: ThemePreference.light, label: Text('Light')),
            ButtonSegment(value: ThemePreference.dark, label: Text('Dark')),
          ],
          selected: <ThemePreference>{settings.theme},
          onSelectionChanged: (value) {
            ref
                .read(ledgerProvider.notifier)
                .saveSettings(settings.copyWith(theme: value.first));
          },
        ),
        const SizedBox(height: 20),
        Text('Base currency', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: settings.baseCurrencyCode,
          items: <DropdownMenuItem<String>>[
            for (final currency in Currencies.all)
              DropdownMenuItem<String>(
                value: currency.code,
                child: Text('${currency.code} · ${currency.name}'),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            ref
                .read(ledgerProvider.notifier)
                .saveSettings(settings.copyWith(baseCurrencyCode: value));
          },
        ),
        const SizedBox(height: 20),
        Text('Exchange rates', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          live ? 'Using a live quote from open.er-api.com for this session.' : 'Offline demo rates, pivoted through the naira. They are fixtures, not a market quote.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: <Widget>[
                for (final currency in Currencies.all)
                  if (currency.code != settings.baseCurrencyCode)
                    ListTile(
                      dense: true,
                      title: Text('1 ${currency.code}'),
                      trailing: Text(
                        formatMinor(
                          rates.convertMinor(
                            amountMinor: 100,
                            from: currency.code,
                            to: settings.baseCurrencyCode,
                          ),
                          settings.baseCurrencyCode,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (live)
          OutlinedButton(
            onPressed: () => ref.read(rateBookProvider.notifier).useOffline(),
            child: const Text('Use offline rates'),
          )
        else
          FilledButton(
            onPressed: () async {
              final message = await ref
                  .read(rateBookProvider.notifier)
                  .useLiveRates();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    message ??
                        'Live rates are on until you leave this session.',
                  ),
                ),
              );
            },
            child: const Text('Try live rates'),
          ),
        const SizedBox(height: 20),
        Text('Demo ledger', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Restoring replaces accounts, transactions, budgets, and rules with the seeded book.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Restore demo ledger?'),
                content: const Text(
                  'This replaces everything currently stored on this device.',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Restore'),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            await ref.read(ledgerProvider.notifier).restoreDemo();
          },
          child: const Text('Restore demo ledger'),
        ),
        const SizedBox(height: 28),
        Text(
          'Kobo keeps the book on this device. CSV export is on the Activity screen.',
          style: TextStyle(color: muted),
        ),
      ],
    );
  }
}
