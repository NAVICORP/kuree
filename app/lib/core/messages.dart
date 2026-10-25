import 'dart:math';

import '../l10n/strings.dart';
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

// The messages below are written in the app's language.

/// The message to one person who has not paid yet.
String reminderFor(KuriDoc k, Month m, Due d) {
  final s = S.current;
  final group = k.group.trim();
  final name = firstName(d.person.name);
  final amount = k.money(d.amount);
  final label = k.monthLabel(m.n);
  final day = dayOf(k.deadline(m.n).day);
  final head = group.isEmpty
      ? s.msgReminder(name, k.name, amount, m.n, label, day)
      : s.msgReminderFrom(name, group, k.name, amount, m.n, label, day);
  final fine = k.fine > 0 ? s.msgFineAfter(k.money(k.fine)) : '';
  return '$head$fine${s.msgThanks}';
}

/// Who has paid and who has not, for the group chat, with the members' link.
/// The two headings are in bold on WhatsApp (*like this*), so the lists
/// stand apart.
String groupList(KuriDoc k, Month m, String shareToken) {
  final s = S.current;
  final mon = monthName(k.collectDate(m.n).month);
  final paid = k.paidNames(m);
  final due = k.dues(m).map((d) => d.person.name).toList();
  final paidHead = '*${s.msgPaidHead(mon)}*';
  final dueHead = '*${s.msgDueHead(mon)}*';
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
  return S.current.msgDrawResult(k.fullName, month, k.monthLabel(month), slot, k.slotName(slot), k.money(k.pot), names, stamp(when));
}

/// A WhatsApp link: to one person when there is a number, or to any chat
/// when there is not. api.whatsapp.com keeps emoji intact (wa.me does not).
Uri whatsApp(String text, {String phone = ''}) {
  final d = phone.isEmpty ? '' : phoneDigits(phone);
  return Uri.parse('https://api.whatsapp.com/send?${d.isEmpty ? '' : 'phone=$d&'}text=${Uri.encodeComponent(text)}');
}
