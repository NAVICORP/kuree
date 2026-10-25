import 'dart:math';

import 'config.dart';
import 'format.dart';
import 'kuri.dart';

/// A fair whole number below n, from the phone's secure random source.
final Random _secure = Random.secure();
int fair(int n) => _secure.nextInt(n);

/// A fair shuffle (Fisher-Yates with secure random numbers).
List<T> shuffled<T>(List<T> list) {
  final x = List<T>.of(list);
  for (var i = x.length - 1; i > 0; i--) {
    final j = fair(i + 1);
    final t = x[i];
    x[i] = x[j];
    x[j] = t;
  }
  return x;
}

/// The message to one person who has not paid yet.
String reminderFor(KuriDoc k, Month m, Due d) {
  final fine = k.fine > 0 ? ' After that there is a late fine of ${money(k.fine)}.' : '';
  final from = k.group.trim().isEmpty ? '' : ' from ${k.group.trim()}';
  return 'Hi ${firstName(d.person.name)}, a reminder$from: your ${k.name} payment of ${money(d.amount)} '
      'for month ${m.n} (${k.monthLabel(m.n)}) is due by midnight on the ${ordinal(k.deadline(m.n).day)}.$fine Thank you.';
}

/// Who has paid and who has not, for the group chat, with the members' link.
String groupList(KuriDoc k, Month m, String shareToken) {
  final mon = kMonths[k.collectDate(m.n).month - 1];
  final paid = k.paidNames(m);
  final due = k.dues(m).map((d) => d.person.name).toList();
  // In bold on WhatsApp (*like this*), so the two lists stand apart.
  final paidHead = '*$mon : Paid*';
  final dueHead = '*$mon : Not paid yet*';
  final b = StringBuffer();
  if (paid.isNotEmpty) {
    b.writeln(paidHead);
    b.write(paid.map((n) => '✅ $n').join('\n'));
  }
  if (paid.isNotEmpty && due.isNotEmpty) b.writeln();
  if (due.isNotEmpty) {
    b.writeln(dueHead);
    b.write(due.map((n) => '❌ $n').join('\n'));
  }
  if (shareToken.isNotEmpty) b.write('\n\n${shareUrl(shareToken)}');
  return b.toString().trim();
}

/// The result of a bottle draw, for the group chat.
String drawResult(KuriDoc k, int month, int slot, int names, DateTime when) {
  return '${k.fullName}, month $month (${k.monthLabel(month)})\n'
      'The bottle picked: $slot. ${k.slotName(slot)}\n'
      'Takes the pot of ${money(k.pot)}.\n'
      '$names names were in the bottle. Drawn ${stamp(when)}.';
}

/// A WhatsApp link: to one person when there is a number, or to any chat
/// when there is not. api.whatsapp.com keeps emoji intact (wa.me does not).
Uri whatsApp(String text, {String phone = ''}) {
  final d = phone.isEmpty ? '' : phoneDigits(phone);
  return Uri.parse('https://api.whatsapp.com/send?${d.isEmpty ? '' : 'phone=$d&'}text=${Uri.encodeComponent(text)}');
}
