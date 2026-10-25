import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/kuri.dart';
import '../l10n/strings.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

/// The To collect tab: everyone still to pay this month, chit by chit, with a
/// way to remind them and to open the chit.
class CollectList extends StatelessWidget {
  const CollectList({super.key, required this.kuris, required this.onOpen, required this.onRefresh});
  final List<KuriRecord> kuris;
  final Future<void> Function(KuriRecord) onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = <(KuriRecord, Month, List<Due>)>[];
    for (final k in kuris) {
      final d = k.doc;
      if (d.months.isEmpty) continue;
      final m = d.months[d.currentMonth() - 1];
      final dues = d.dues(m);
      if (dues.isNotEmpty) items.add((k, m, dues));
    }
    return RefreshIndicator(
      color: K.green,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xs, Sp.page, Sp.xxl),
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 72),
              child: EmptyState(icon: kuris.isEmpty ? Icons.savings_outlined : Icons.check_rounded, text: kuris.isEmpty ? s.noChits : s.nothingToCollect),
            )
          else ...[
            Padding(padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, Sp.md), child: Text(s.collectIntro, style: T.small)),
            for (final it in items) ...[
              _CollectCard(record: it.$1, month: it.$2, dues: it.$3, onOpen: () => onOpen(it.$1), onSaved: onRefresh),
              const SizedBox(height: Sp.md),
            ],
          ],
        ],
      ),
    );
  }
}

class _CollectCard extends StatelessWidget {
  const _CollectCard({required this.record, required this.month, required this.dues, required this.onOpen, required this.onSaved});
  final KuriRecord record;
  final Month month;
  final List<Due> dues;
  final VoidCallback onOpen;
  final Future<void> Function() onSaved;

  /// The reminders sheet for this chit. A number added here is saved straight
  /// away, so the next reminder can go to that person directly.
  Future<void> _remind(BuildContext context) async {
    final doc = record.doc.copy();
    final m = doc.months[month.n - 1];
    await showRemindersSheet(context, doc, m, record.shareToken, onAddNumber: (person) async {
      final phone = await askPhone(context, person.name, person.phone);
      if (phone == null) return;
      person.phone = phone;
      try {
        doc.updated = DateTime.now().toIso8601String().substring(0, 10);
        final j = await Api.instance.rpc('save_kuri', {'id': record.id, 'data': doc.toJson(), 'expected': record.updatedAtRaw});
        if (j is Map) record.updatedAtRaw = KuriRecord.fromJson(Map<String, dynamic>.from(j)).updatedAtRaw;
      } on ApiError catch (e) {
        if (context.mounted) toast(context, e.message, bad: true);
      }
    });
    await onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final doc = record.doc;
    final n = month.n;
    final total = dues.fold<int>(0, (t, d) => t + d.amount);
    return KCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Sp.lg, 14, Sp.lg, Sp.md),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (doc.group.trim().isNotEmpty)
                    Text(doc.group, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small.copyWith(color: K.green, fontWeight: FontWeight.w700)),
                  Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.h3),
                  const SizedBox(height: 2),
                  Text(s.collectionNote(doc.collectDate(n).day, doc.monthShort(n), doc.nextNote(n)), style: T.small),
                ]),
              ),
              const SizedBox(width: Sp.sm),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(doc.money(total), style: T.h3.merge(T.tabular)),
                const SizedBox(height: Sp.xs),
                Pill(s.toGo(dues.length), color: K.warnBg, fg: K.warn),
              ]),
            ]),
          ),
        ),
        const Divider(),
        for (var i = 0; i < dues.length; i++) ...[
          if (i > 0) const Divider(indent: Sp.lg, endIndent: Sp.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: 11),
            child: Row(children: [
              Expanded(child: Text(dues[i].person.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body)),
              const SizedBox(width: Sp.sm),
              Text(doc.money(dues[i].amount), style: T.bodyStrong.merge(T.tabular)),
            ]),
          ),
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(Sp.md),
          child: Row(children: [
            Expanded(
              child: KButton(label: s.remind, icon: Icons.chat_outlined, kind: KButtonKind.secondary, small: true, expand: true, onPressed: () => _remind(context)),
            ),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: KButton(label: s.open, icon: Icons.arrow_forward_rounded, kind: KButtonKind.ghost, small: true, expand: true, onPressed: onOpen),
            ),
          ]),
        ),
      ]),
    );
  }
}
