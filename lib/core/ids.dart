/// Short unique ids for rows the user creates.
class IdSource {
  int _n = 0;

  /// `prefix`, the time, and a counter. Two calls in one microsecond differ.
  String next(String prefix) {
    _n += 1;
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return '${prefix}_${micros}_$_n';
  }
}
