import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import 'theme.dart';
import 'widgets.dart';

/// Every word on the feature request screens, in one place, so they can be
/// translated together.
class FeatureRequestText {
  static const title = 'Request a feature';
  static const introTitle = 'Tell us what would help';
  static const introText = 'An idea, something that gets in the way, a feature you miss. We read every request.';
  static const fieldTitle = 'Your idea in a few words';
  static const fieldTitleHint = 'For example: a reminder the day before';
  static const fieldDetails = 'Tell us more (optional)';
  static const fieldDetailsHint = 'How would you use it? What happens today?';
  static const importance = 'How much would it help?';
  static const nice = 'Nice to have';
  static const important = 'Important';
  static const must = 'Must have';
  static const send = 'Send request';
  static const needTitle = 'Give your idea a short title.';
  static const thanksTitle = 'Thank you!';
  static const thanksText = 'Your request reached the Kuree team. You can follow it below.';
  static const sendAnother = 'Send another';
  static const yours = 'Your requests';
  static const noneYet = 'Your requests will show here, with what the team decides.';
  static const reply = 'From the Kuree team';
  static const inboxTitle = 'Feature requests';
  static const inboxEmpty = 'No requests here yet.';
  static const all = 'All';
  static const statusNew = 'New';
  static const statusPlanned = 'Planned';
  static const statusDone = 'Done';
  static const statusDeclined = 'Declined';
  static const change = 'Update the request';
  static const noteLabel = 'Note for the person who asked (optional)';
  static const noteHint = 'For example: coming in the next update';
  static const save = 'Save';
  static const saved = 'Saved.';
  static const from = 'From';
  static const signedOut = 'Account deleted';
}

String _statusLabel(String s) => switch (s) {
      'planned' => FeatureRequestText.statusPlanned,
      'done' => FeatureRequestText.statusDone,
      'declined' => FeatureRequestText.statusDeclined,
      _ => FeatureRequestText.statusNew,
    };

String _importanceLabel(String? s) => switch (s) {
      'nice' => FeatureRequestText.nice,
      'important' => FeatureRequestText.important,
      'must' => FeatureRequestText.must,
      _ => '',
    };

(Color, Color, IconData) _statusLook(String s) => switch (s) {
      'planned' => (K.sunSoft, K.warn, Icons.event_available_rounded),
      'done' => (K.brand100, K.brand600, Icons.check_circle_rounded),
      'declined' => (K.surface2, K.muted, Icons.do_not_disturb_on_outlined),
      _ => (const Color(0xFFE4EDF2), const Color(0xFF2A5670), Icons.fiber_new_rounded),
    };

/// One request as the server sends it.
class FeatureRequest {
  FeatureRequest(this.j);
  final Map<String, dynamic> j;

  int get id => (j['id'] as num).toInt();
  String get title => (j['title'] as String?) ?? '';
  String get details => (j['details'] as String?) ?? '';
  String? get importance => j['importance'] as String?;
  String get status => (j['status'] as String?) ?? 'new';
  String get note => (j['owner_note'] as String?) ?? '';
  DateTime get created => DateTime.tryParse((j['created_at'] as String?) ?? '')?.toLocal() ?? DateTime.now();
  String get name => (j['name'] as String?) ?? '';
  String get email => (j['email'] as String?) ?? '';
  String get phone => (j['phone'] as String?) ?? '';
  String get platform => (j['platform'] as String?) ?? '';
  String get version => (j['app_version'] as String?) ?? '';
  String get language => (j['language'] as String?) ?? '';
  bool get signedUp => j['signed_up'] != false;

  static List<FeatureRequest> list(dynamic j) =>
      j is List ? [for (final x in j) if (x is Map) FeatureRequest(Map<String, dynamic>.from(x))] : const [];
}

/// The calls behind the screens.
class FeatureRequests {
  /// The app version sent with a request. Builds can set it with
  /// --dart-define=KUREE_VERSION=1.0.1
  static const version = String.fromEnvironment('KUREE_VERSION', defaultValue: '1.0.0');

  static String get platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }

  /// True when the signed-in person is on the Kuree team and may read every
  /// request (show the inbox entry only then).
  static Future<bool> isOwner() async {
    try {
      return await Api.instance.rpc('feature_owner') == true;
    } on ApiError {
      return false;
    }
  }

  static Future<void> send({required String title, required String details, String? importance, String? language}) async {
    await Api.instance.rpc('request_feature', {
      'title': title,
      'details': details,
      'importance': importance,
      'app_version': version,
      'platform': platform,
      'language': language,
    });
  }

  static Future<List<FeatureRequest>> mine() async => FeatureRequest.list(await Api.instance.rpc('my_feature_requests'));

  static Future<(Map<String, int>, List<FeatureRequest>)> all({String? status}) async {
    final r = await Api.instance.rpc('all_feature_requests', {'status': status});
    final counts = <String, int>{};
    if (r is Map && r['counts'] is Map) {
      for (final e in (r['counts'] as Map).entries) {
        counts['${e.key}'] = e.value is num ? (e.value as num).toInt() : 0;
      }
    }
    return (counts, FeatureRequest.list(r is Map ? r['requests'] : null));
  }

  static Future<FeatureRequest> setStatus(int id, String status, String note) async {
    final r = await Api.instance.rpc('set_feature_request_status', {'id': id, 'status': status, 'note': note});
    return FeatureRequest(r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{'id': id, 'status': status});
  }
}

// ---------------------------------------------------------------- asking for a feature

/// Where an admin asks for something new and follows what happened to it.
class FeatureRequestScreen extends StatefulWidget {
  const FeatureRequestScreen({super.key});

  @override
  State<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends State<FeatureRequestScreen> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  String? _importance;
  bool _sending = false;
  bool _sent = false;
  String? _error;
  List<FeatureRequest>? _mine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final m = await FeatureRequests.mine();
      if (mounted) setState(() => _mine = m);
    } on ApiError {
      if (mounted) setState(() => _mine ??= const []);
    }
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    if (title.length < 3) {
      setState(() => _error = FeatureRequestText.needTitle);
      return;
    }
    FocusScope.of(context).unfocus();
    final language = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await FeatureRequests.send(title: title, details: _details.text.trim(), importance: _importance, language: language);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
        _title.clear();
        _details.clear();
        _importance = null;
      });
      _load();
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(FeatureRequestText.title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            HeroCard(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: K.sun, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: K.deep, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(FeatureRequestText.introTitle, style: T.h2.copyWith(color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(FeatureRequestText.introText, style: T.body.copyWith(color: K.heroText)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _sent ? _thanks() : _form(),
            ),
            const SectionTitle(FeatureRequestText.yours),
            if (_mine == null)
              const Padding(padding: EdgeInsets.all(24), child: Loading())
            else if (_mine!.isEmpty)
              const KCard(child: EmptyState(icon: Icons.inbox_outlined, text: FeatureRequestText.noneYet))
            else
              for (final r in _mine!) Padding(padding: const EdgeInsets.only(bottom: 10), child: _RequestCard(r)),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return KCard(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _title,
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: FeatureRequestText.fieldTitle, hintText: FeatureRequestText.fieldTitleHint),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _details,
          maxLength: 2000,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: FeatureRequestText.fieldDetails,
            hintText: FeatureRequestText.fieldDetailsHint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        Text(FeatureRequestText.importance, style: T.label),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (v, label) in const [
            ('nice', FeatureRequestText.nice),
            ('important', FeatureRequestText.important),
            ('must', FeatureRequestText.must),
          ])
            _Choice(
              label: label,
              selected: _importance == v,
              onTap: () => setState(() => _importance = _importance == v ? null : v),
            ),
        ]),
        if (_error != null) ...[const SizedBox(height: 14), Notice(_error!)],
        const SizedBox(height: 18),
        KButton(label: FeatureRequestText.send, icon: Icons.send_rounded, expand: true, busy: _sending, onPressed: _send),
      ]),
    );
  }

  Widget _thanks() {
    return KCard(
      key: const ValueKey('thanks'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: K.sun, shape: BoxShape.circle),
          child: const Icon(Icons.favorite_rounded, color: K.deep, size: 30),
        ),
        const SizedBox(height: 14),
        Text(FeatureRequestText.thanksTitle, style: T.h2, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(FeatureRequestText.thanksText, style: T.body.copyWith(color: K.muted), textAlign: TextAlign.center),
        const SizedBox(height: 18),
        KButton(
          label: FeatureRequestText.sendAnother,
          icon: Icons.add_rounded,
          kind: KButtonKind.secondary,
          onPressed: () => setState(() => _sent = false),
        ),
      ]),
    );
  }
}

/// A rounded choice that fills in when picked.
class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? K.deep : K.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? K.deep : K.border2)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (selected) ...[const Icon(Icons.check_rounded, size: 17, color: K.sun), const SizedBox(width: 6)],
              Text(label, style: T.label.copyWith(color: selected ? Colors.white : K.ink2)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _statusLook(status);
    return Pill(_statusLabel(status), color: bg, fg: fg, icon: icon);
  }
}

/// One of my requests, with its status and the team's reply.
class _RequestCard extends StatelessWidget {
  const _RequestCard(this.r);
  final FeatureRequest r;

  @override
  Widget build(BuildContext context) {
    final imp = _importanceLabel(r.importance);
    return KCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(r.title, style: T.bodyStrong)),
          const SizedBox(width: 10),
          _StatusPill(r.status),
        ]),
        if (r.details.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.details, style: T.body.copyWith(color: K.ink2), maxLines: 4, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Text(imp.isEmpty ? ago(r.created) : '${ago(r.created)}, $imp', style: T.small),
        if (r.note.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Reply(r.note),
        ],
      ]),
    );
  }
}

class _Reply extends StatelessWidget {
  const _Reply(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: const BoxDecoration(
        color: K.mint,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(6),
          topEnd: Radius.circular(18),
          bottomStart: Radius.circular(18),
          bottomEnd: Radius.circular(18),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(FeatureRequestText.reply, style: T.tiny.copyWith(color: K.brand600)),
        const SizedBox(height: 4),
        Text(text, style: T.body),
      ]),
    );
  }
}

// ---------------------------------------------------------------- the owner inbox

/// Every request, for the Kuree team. Open it only when
/// [FeatureRequests.isOwner] is true; the server refuses everyone else.
class FeatureInboxScreen extends StatefulWidget {
  const FeatureInboxScreen({super.key});

  @override
  State<FeatureInboxScreen> createState() => _FeatureInboxScreenState();
}

class _FeatureInboxScreenState extends State<FeatureInboxScreen> {
  String? _filter;
  Map<String, int> _counts = const {};
  List<FeatureRequest>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (counts, items) = await FeatureRequests.all(status: _filter);
      if (mounted) {
        setState(() {
          _counts = counts;
          _items = items;
          _error = null;
        });
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _pick(String? f) {
    if (f == _filter) return;
    setState(() {
      _filter = f;
      _items = null;
    });
    _load();
  }

  Future<void> _open(FeatureRequest r) async {
    final changed = await showKSheet<bool>(context, title: FeatureRequestText.change, builder: (ctx) => _StatusSheet(r));
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final filters = <(String?, String)>[
      (null, FeatureRequestText.all),
      ('new', FeatureRequestText.statusNew),
      ('planned', FeatureRequestText.statusPlanned),
      ('done', FeatureRequestText.statusDone),
      ('declined', FeatureRequestText.statusDeclined),
    ];
    Widget body;
    if (_error != null && _items == null) {
      body = LoadFailed(message: _error!, onRetry: () {
        setState(() => _error = null);
        _load();
      });
    } else if (_items == null) {
      body = const Loading();
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        color: K.green,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            if (_items!.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 40), child: EmptyState(icon: Icons.inbox_outlined, text: FeatureRequestText.inboxEmpty))
            else
              for (final r in _items!) Padding(padding: const EdgeInsets.only(bottom: 10), child: _InboxCard(r, onTap: () => _open(r))),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text(FeatureRequestText.inboxTitle)),
      body: SafeArea(
        top: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              children: [
                for (final (v, label) in filters)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _Choice(
                      label: '$label ${_counts[v ?? 'all'] ?? 0}',
                      selected: _filter == v,
                      onTap: () => _pick(v),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ]),
      ),
    );
  }
}

/// One request in the inbox: what, who, when, and its status.
class _InboxCard extends StatelessWidget {
  const _InboxCard(this.r, {required this.onTap});
  final FeatureRequest r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final who = r.signedUp
        ? [r.name, r.email.isNotEmpty ? r.email : (r.phone.isNotEmpty ? prettyPhone(r.phone) : '')].where((s) => s.isNotEmpty).join(', ')
        : FeatureRequestText.signedOut;
    final meta = [
      ago(r.created),
      _importanceLabel(r.importance),
      [r.platform, r.version, r.language].where((s) => s.isNotEmpty).join(' '),
    ].where((s) => s.isNotEmpty).join(', ');
    return KCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(r.title, style: T.bodyStrong)),
          const SizedBox(width: 10),
          _StatusPill(r.status),
        ]),
        if (r.details.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.details, style: T.body.copyWith(color: K.ink2), maxLines: 5, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 16, color: K.muted),
          const SizedBox(width: 6),
          Expanded(child: Text('${FeatureRequestText.from} ${who.isEmpty ? '?' : who}', style: T.small, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 4),
        Text(meta, style: T.tiny),
        if (r.note.isNotEmpty) ...[const SizedBox(height: 12), _Reply(r.note)],
      ]),
    );
  }
}

/// The owner changes a request's status and leaves a note.
class _StatusSheet extends StatefulWidget {
  const _StatusSheet(this.r);
  final FeatureRequest r;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  late String _status = widget.r.status;
  late final TextEditingController _note = TextEditingController(text: widget.r.note);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FeatureRequests.setStatus(widget.r.id, _status, _note.text.trim());
      if (!mounted) return;
      toast(context, FeatureRequestText.saved);
      Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.r.title, style: T.h3),
      if (widget.r.details.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(widget.r.details, style: T.body.copyWith(color: K.ink2)),
      ],
      const SizedBox(height: 18),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in const ['new', 'planned', 'done', 'declined'])
          _Choice(label: _statusLabel(s), selected: _status == s, onTap: () => setState(() => _status = s)),
      ]),
      const SizedBox(height: 18),
      TextField(
        controller: _note,
        maxLength: 500,
        minLines: 2,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: FeatureRequestText.noteLabel,
          hintText: FeatureRequestText.noteHint,
          alignLabelWithHint: true,
        ),
      ),
      if (_error != null) ...[const SizedBox(height: 10), Notice(_error!)],
      const SizedBox(height: 14),
      KButton(label: FeatureRequestText.save, icon: Icons.check_rounded, expand: true, busy: _saving, onPressed: _save),
    ]);
  }
}
