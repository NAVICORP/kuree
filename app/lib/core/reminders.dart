import '../l10n/strings.dart';
import 'kuri.dart';

/// What a reminder on the phone is about.
enum ReminderKind {
  /// The morning of the collection day.
  collection,

  /// The evening before the last day to pay without a fine.
  lastDay,
}

/// One notification the phone shows at a set time, for one month of one chit.
class Reminder {
  const Reminder({required this.kuriId, required this.kind, required this.month, required this.at, required this.body});

  /// The chit it opens when tapped.
  final String kuriId;
  final ReminderKind kind;
  final int month;

  /// When it shows, in the phone's own time.
  final DateTime at;
  final String body;

  @override
  String toString() => 'Reminder($kind, $kuriId, month $month, $at, "$body")';
}

/// The collection reminder shows at 9 in the morning; the last day reminder
/// at 7 in the evening the day before.
const int kCollectionHour = 9;
const int kLastDayHour = 19;

/// How far ahead reminders are set. The app sets them again every time the
/// chits load, so a short window is enough.
const Duration kReminderWindow = Duration(days: 60);

/// iPhones keep at most 64 waiting notifications for an app; this stays
/// under that.
const int kMaxReminders = 60;

/// Every reminder due after [now] and within [window], soonest first, at
/// most [max]. Months everyone has paid get none. The count of people still
/// to pay is taken as it stands now. Pure: the same chits and time always
/// give the same list.
List<Reminder> planReminders(
  Iterable<KuriRecord> kuris,
  DateTime now, {
  S? strings,
  Duration window = kReminderWindow,
  int max = kMaxReminders,
}) {
  final s = strings ?? S.current;
  final end = now.add(window);
  bool inWindow(DateTime t) => t.isAfter(now) && !t.isAfter(end);
  final out = <Reminder>[];
  for (final k in kuris) {
    final doc = k.doc;
    if (doc.payers.isEmpty) continue;
    final chit = doc.fullName;
    for (final m in doc.months) {
      final owing = doc.dues(m).length;
      if (owing == 0) continue;
      final c = doc.collectDate(m.n);
      final collect = DateTime(c.year, c.month, c.day);
      final morning = DateTime(c.year, c.month, c.day, kCollectionHour);
      if (inWindow(morning)) {
        out.add(Reminder(kuriId: k.id, kind: ReminderKind.collection, month: m.n, at: morning, body: s.notifCollection(chit, owing)));
      }
      // Only when the last day comes after the collection day: when they are
      // the same day, the morning reminder says it all.
      final d = doc.deadline(m.n);
      final last = DateTime(d.year, d.month, d.day);
      if (last.isAfter(collect)) {
        final evening = DateTime(last.year, last.month, last.day - 1, kLastDayHour);
        if (inWindow(evening)) {
          out.add(Reminder(kuriId: k.id, kind: ReminderKind.lastDay, month: m.n, at: evening, body: s.notifLastDay(chit, owing)));
        }
      }
    }
  }
  out.sort((a, b) {
    final t = a.at.compareTo(b.at);
    return t != 0 ? t : a.kuriId.compareTo(b.kuriId);
  });
  return out.length > max ? out.sublist(0, max) : out;
}
