/// Formats a 24-hour value (0-23) to 12-hour AM/PM shorthand.
/// Examples: 0 → "12a", 1 → "1a", 12 → "12p", 13 → "1p"
class HourFormatter {
  static String format(int hour24) {
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final ampm = (hour24 < 12 || hour24 == 24) ? 'a' : 'p';
    return '$hour12$ampm';
  }
}
