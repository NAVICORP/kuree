/// Numbers, dates and names the way the group writes them.
library;

import '../l10n/strings.dart';

/// English month names. Shown text goes through [monthName] so it follows
/// the app's language; these stay for code that needs English.
const List<String> kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const List<String> kMonthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// A month's name in the app's language (1 = January).
String monthName(int month) => S.current.monthsLong[(month - 1) % 12];

/// A month's short name in the app's language (1 = Jan).
String monthShortName(int month) => S.current.monthsShort[(month - 1) % 12];

/// 65000 as "65,000" and 150000 as "1,50,000" (Indian grouping).
String groupDigits(num value) {
  final negative = value < 0;
  var s = value.abs().round().toString();
  if (s.length > 3) {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    s = '${parts.join(',')},$last3';
  }
  return negative ? '-$s' : s;
}

/// 150000 as "150,000" (groups of three).
String groupThousands(num value) {
  final negative = value < 0;
  final s = value.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return negative ? '-$b' : b.toString();
}

/// A currency a chit can be kept in. Amounts are whole numbers, so no
/// decimals are shown.
class Currency {
  const Currency(this.code, this.symbol, {this.indian = false, this.spaced = false});

  /// ISO code, saved with the chit: "INR".
  final String code;

  /// What goes before the amount: "₹", "AED".
  final String symbol;

  /// Indian grouping (1,50,000) rather than thousands (150,000).
  final bool indian;

  /// A space between the symbol and the amount ("AED 1,500", not "₹1,500").
  final bool spaced;

  String format(num value) {
    final digits = indian ? groupDigits(value) : groupThousands(value);
    return spaced ? '$symbol $digits' : '$symbol$digits';
  }

  /// The currency's name in the app's language.
  String get name => S.current.currencyName(code);
}

/// Every currency on offer, in the order the picker shows them.
const List<Currency> kCurrencies = [
  Currency('INR', '₹', indian: true),
  Currency('AED', 'AED', spaced: true),
  Currency('SAR', 'SAR', spaced: true),
  Currency('QAR', 'QAR', spaced: true),
  Currency('KWD', 'KWD', spaced: true),
  Currency('OMR', 'OMR', spaced: true),
  Currency('BHD', 'BHD', spaced: true),
  Currency('USD', r'$'),
  Currency('GBP', '£'),
  Currency('EUR', '€'),
  Currency('SGD', r'S$'),
  Currency('MYR', 'RM', spaced: true),
  Currency('LKR', 'Rs', spaced: true),
];

/// The currency for a saved code; anything unknown is the Indian rupee.
Currency currencyOf(String? code) {
  final c = (code ?? '').trim().toUpperCase();
  for (final x in kCurrencies) {
    if (x.code == c) return x;
  }
  return kCurrencies.first;
}

/// ₹65,000, or in another currency: AED 65,000.
String money(num value, [String currency = 'INR']) => currencyOf(currency).format(value);

/// 1st, 2nd, 3rd, 4th, 11th, 21st, 25th (English).
String ordinal(int n) {
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

/// A day of the month in the app's language: "25th" in English, "25" in
/// the others (their sentences carry the word for "date").
String dayOf(int n) => S.current.code == 'en' ? ordinal(n) : '$n';

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// The first word of a name: "Anees Muhammed" says hi to "Anees".
String firstName(String name) {
  final t = name.trim();
  if (t.isEmpty) return t;
  return t.split(RegExp(r'\s+')).first;
}

/// Up to two letters for an avatar.
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters2(1).toUpperCase();
  return (parts.first.characters2(1) + parts.last.characters2(1)).toUpperCase();
}

extension _Chars on String {
  String characters2(int n) {
    final runes = this.runes.toList();
    return String.fromCharCodes(runes.take(n));
  }
}

/// A name as one key, so "Sinan KP" and "sinan  kp" are the same person.
String nameKey(String name) => name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// 7:31 pm
String clock(DateTime d) {
  final h = d.hour, m = d.minute;
  final hh = (h % 12) == 0 ? 12 : h % 12;
  return '$hh:${m.toString().padLeft(2, '0')} ${h < 12 ? S.current.am : S.current.pm}';
}

/// 20 Oct 2026, 7:31 pm
String stamp(DateTime d) => '${d.day} ${monthShortName(d.month)} ${d.year}, ${clock(d)}';

/// "just now", "5 min ago", "yesterday", or the date.
String ago(DateTime d, [DateTime? now]) {
  final s = S.current;
  final n = now ?? DateTime.now();
  final diff = n.difference(d);
  if (diff.inSeconds < 60) return s.agoJustNow;
  if (diff.inMinutes < 60) return s.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24 && n.day == d.day) return s.agoToday(clock(d));
  final yesterday = DateTime(n.year, n.month, n.day).subtract(const Duration(days: 1));
  if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) {
    return s.agoYesterday(clock(d));
  }
  return stamp(d);
}

/// Digits only, with the country code; 10 digits on their own are Indian.
String phoneDigits(String raw, {String defaultCountry = '91'}) {
  final t = raw.trim();
  var d = t.replaceAll(RegExp(r'[^0-9]'), '');
  if (t.startsWith('00')) d = d.substring(2);
  if (t.startsWith('+') || t.startsWith('00')) return d;
  if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
  if (d.length == 10) return '$defaultCountry$d';
  return d;
}

/// +91 90721 50276
String prettyPhone(String digits) {
  final d = digits.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return '';
  if (d.length == 12 && d.startsWith('91')) return '+91 ${d.substring(2, 7)} ${d.substring(7)}';
  return '+$d';
}
