/// Integer division that rounds half away from zero.
///
/// `divRound(5, 2)` is 3. `divRound(-5, 2)` is -3. A remainder of exactly
/// half rounds away from zero, so `divRound(1, 2)` is 1.
int divRound(int numerator, int denominator) {
  if (denominator == 0) {
    throw ArgumentError.value(denominator, 'denominator', 'must not be zero');
  }
  final negative = numerator < 0;
  final absolute = numerator.abs();
  final divisor = denominator.abs();
  final quotient = absolute ~/ divisor;
  final remainder = absolute % divisor;
  final rounded = remainder * 2 >= divisor ? quotient + 1 : quotient;
  final signed = negative == (denominator < 0) ? rounded : -rounded;
  return signed;
}
