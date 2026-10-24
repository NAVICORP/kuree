import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import 'theme.dart';
import 'widgets.dart';

/// Every earlier version of the kuri, newest first, each with a way back.
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
          '${v['saved_by'] ?? 'Someone'}',
          KuriDoc.fromJson(Map<String, dynamic>.from(data)),
        ));
      }
      if (mounted) setState(() => versions = list);
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  /// What is different between this version and the one after it.
  String _summary(KuriDoc older, KuriDoc newer) {
    final bits = <String>[];
    for (var i = 0; i < newer.months.length; i++) {
      final a = i < older.months.length ? older.months[i] : Month(n: i + 1);
      final b = newer.months[i];
      final paidA = older.paidCount(a), paidB = newer.paidCount(b);
      if (paidA != paidB) bits.add('month ${b.n}: $paidA paid, later $paidB');
      if (a.winner != b.winner) {
        bits.add(a.winner == null ? 'month ${b.n} had no taker yet' : 'month ${b.n} went to ${older.slotName(a.winner!)}');
      }
      if (older.fineCount(a) != newer.fineCount(b)) bits.add('month ${b.n}: ${older.fineCount(a)} late fines');
    }
    if (older.name != newer.name || older.share != newer.share || older.slots != newer.slots || older.fine != newer.fine) {
      bits.add('different settings');
    }
    if (older.people.length != newer.people.length || older.payers.length != newer.payers.length) bits.add('different people or slots');
    if (bits.isEmpty) return 'Small changes';
    final s = bits.take(3).join('; ');
    return s[0].toUpperCase() + s.substring(1) + (bits.length > 3 ? '; and more' : '');
  }

  Future<void> _restore(_Version v) async {
    final ok = await confirm(context,
        title: 'Put this version back?',
        text: 'The kuri goes back to how ${v.by} left it, ${ago(v.at)}. What it shows now is kept in the history too, so you can undo this.',
        yes: 'Put it back');
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
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: () {
        if (versions == null && error != null) return LoadFailed(message: error!, onRetry: _load);
        if (versions == null) return const Loading();
        if (versions!.isEmpty) return const Center(child: EmptyState(icon: Icons.history_rounded, text: 'No earlier versions yet. Each save adds one.'));
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          itemCount: versions!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final v = versions![i];
            final newer = i == 0 ? widget.current : versions![i - 1].doc;
            return KCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ago(v.at), style: T.bodyStrong),
                    Text('Saved by ${v.by}', style: T.small),
                    const SizedBox(height: 4),
                    Text(_summary(v.doc, newer), style: T.small.copyWith(color: K.ink2)),
                  ]),
                ),
                const SizedBox(width: 8),
                KButton(
                  label: 'Put back',
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
