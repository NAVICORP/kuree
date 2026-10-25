import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import '../l10n/strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Every earlier version of the chit, newest first, each with a way back.
/// Returns true when a version was put back.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.record, required this.current});
  final KuriRecord record;
  final KuriDoc current;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _Version {
  _Version(this.id, this.at, this.by, this.doc);
  final int id;
  final DateTime at;
  final String by;
  final KuriDoc doc;
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<_Version>? versions;
  String? error;
  int? restoring;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final j = await Api.instance.rpc('kuri_versions', {'id': widget.record.id});
      final list = <_Version>[];
      for (final v in (j as List? ?? const []).whereType<Map>()) {
        final data = v['data'];
        if (data is! Map) continue;
        list.add(_Version(
          (v['id'] as num).toInt(),
          DateTime.tryParse('${v['saved_at']}')?.toLocal() ?? DateTime.now(),
          '${v['saved_by'] ?? S.current.someone}',
          KuriDoc.fromJson(Map<String, dynamic>.from(data)),
        ));
      }
      if (mounted) setState(() => versions = list);
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  /// What is different between this version and the one after it.
  String _summary(S t, KuriDoc older, KuriDoc newer) {
    final bits = <String>[];
    for (var i = 0; i < newer.months.length; i++) {
      final a = i < older.months.length ? older.months[i] : Month(n: i + 1);
      final b = newer.months[i];
      final paidA = older.paidCount(a), paidB = newer.paidCount(b);
      if (paidA != paidB) bits.add(t.histPaid(b.n, paidA, paidB));
      if (a.winner != b.winner) {
        bits.add(a.winner == null ? t.histNoTaker(b.n) : t.histWentTo(b.n, older.slotName(a.winner!)));
      }
      if (older.fineCount(a) != newer.fineCount(b)) bits.add(t.histFines(b.n, older.fineCount(a)));
    }
    if (older.name != newer.name ||
        older.share != newer.share ||
        older.slots != newer.slots ||
        older.fine != newer.fine ||
        older.currency != newer.currency) {
      bits.add(t.histSettings);
    }
    if (older.people.length != newer.people.length || older.payers.length != newer.payers.length) bits.add(t.histPeople);
    if (bits.isEmpty) return t.histSmall;
    final shown = [...bits.take(3), if (bits.length > 3) t.histAndMore].join('; ');
    return shown[0].toUpperCase() + shown.substring(1);
  }

  Future<void> _restore(_Version v) async {
    final s = S.of(context);
    final ok = await confirm(context, title: s.restoreTitle, text: s.restoreText(v.by, ago(v.at)), yes: s.putItBack);
    if (!ok) return;
    setState(() => restoring = v.id);
    try {
      await Api.instance.rpc('restore_kuri', {'version': v.id});
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => restoring = null);
        toast(context, e.message, bad: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.history)),
      body: () {
        if (versions == null && error != null) return LoadFailed(message: error!, onRetry: _load);
        if (versions == null) return const Loading();
        if (versions!.isEmpty) return Center(child: EmptyState(icon: Icons.history_rounded, text: s.historyEmpty));
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, 40),
          itemCount: versions!.length,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.md - 2),
          itemBuilder: (_, i) {
            final v = versions![i];
            final newer = i == 0 ? widget.current : versions![i - 1].doc;
            return KCard(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ago(v.at), style: T.bodyStrong),
                    Text(s.savedBy(v.by), style: T.small),
                    const SizedBox(height: Sp.xs),
                    Text(_summary(s, v.doc, newer), style: T.small.copyWith(color: K.ink2)),
                  ]),
                ),
                const SizedBox(width: Sp.sm),
                KButton(
                  label: s.putBack,
                  icon: Icons.undo_rounded,
                  kind: KButtonKind.secondary,
                  small: true,
                  busy: restoring == v.id,
                  onPressed: restoring == null ? () => _restore(v) : null,
                ),
              ]),
            );
          },
        );
      }(),
    );
  }
}
