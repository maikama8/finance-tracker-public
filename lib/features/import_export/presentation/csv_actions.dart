import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/providers.dart';
import '../domain/csv_ledger.dart';

const XTypeGroup csvTypeGroup = XTypeGroup(
  label: 'CSV',
  extensions: <String>['csv'],
  mimeTypes: <String>['text/csv'],
  webWildCards: <String>['text/csv', '.csv'],
);

Future<void> exportLedger(
  WidgetRef ref,
  ScaffoldMessengerState messenger,
) async {
  final snapshot = ref.read(ledgerProvider).asData?.value;
  if (snapshot == null) return;
  final location = await getSaveLocation(
    suggestedName: 'kobo-ledger.csv',
    acceptedTypeGroups: const <XTypeGroup>[csvTypeGroup],
  );
  if (location == null) return;
  final csv = CsvLedger.export(snapshot);
  final file = XFile.fromData(
    utf8.encode(csv),
    mimeType: 'text/csv',
    name: 'kobo-ledger.csv',
  );
  await file.saveTo(location.path);
  messenger.showSnackBar(
    const SnackBar(content: Text('Exported kobo-ledger.csv')),
  );
}

Future<void> importLedger(
  WidgetRef ref,
  ScaffoldMessengerState messenger,
) async {
  final file = await openFile(
    acceptedTypeGroups: const <XTypeGroup>[csvTypeGroup],
  );
  if (file == null) return;
  final csv = await file.readAsString();
  final plan = await ref.read(ledgerProvider.notifier).importCsv(csv);
  final failed = plan.errors.length;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Imported ${plan.imported}. Skipped ${plan.skipped}. $failed row${failed == 1 ? '' : 's'} failed.',
      ),
    ),
  );
}
