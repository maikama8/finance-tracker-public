# Contributing

Thanks for looking at Kobo. Issues and pull requests are welcome.

## Setup

Install Flutter 3.47.9 (Dart 3.13.7) from the stable channel, then:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed $(find lib test -name '*.dart' ! -name '*.g.dart')
flutter analyze
flutter test
```

`make check` runs the same three steps.

## Pull requests

- Keep the change focused. A bug fix does not need a drive-by rewrite.
- Behaviour that the tests lock, including the 14 November 2026 demo book, should stay the same unless the change is about that behaviour. Update the test and the README together when a locked figure moves.
- Run format, analyze, and the tests. CI runs those, plus `flutter build web --release`.
- Commit messages should say what changed and why. `fix:`, `feat:`, `docs:`, `test:`, and `refactor:` are the prefixes this repo uses.
- Do not commit secrets, editor settings, or local notes.

## Schema changes

Drift's generated file is committed at `lib/data/drift/app_database.g.dart`. After you change `lib/data/drift/tables.dart` or `app_database.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit the generated file. Bump `schemaVersion` and add a migration if an existing database has to survive the change. The current schema is version 1.

The web build also needs `web/sqlite3.wasm` and `web/drift_worker.js`. Those are the Drift runtime for the pinned packages. Replace them only when you bump `drift` or `sqlite3`, and say so in the pull request.

## Reporting bugs

Use the bug report template. A note that names the screen, the currency, and what you expected is enough to start. A CSV that reproduces an import failure is even better. Please leave account numbers and anything personal out of the sample.
