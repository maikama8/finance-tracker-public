/// Short unique ids for rows the user creates.
class IdSource {
  int _n = 0;

  String next(String prefix) {
    _n += 1;
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return '${prefix}_${micros}_$_n';
  }
}
