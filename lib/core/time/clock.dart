import 'iso_date.dart';

/// The clock the ledger uses for "today".
///
/// Tests pass a [FixedClock]. The running app uses [SystemClock], which reads
/// the device's local calendar date.
abstract class Clock {
  const Clock();

  DateTime now();

  DateTime today() => dateOnly(now());
}

/// [Clock] backed by [DateTime.now].
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// [Clock] that always reports [instant]. Tests use it to pin the open month.
class FixedClock extends Clock {
  const FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}
