import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import '../l10n/strings.dart';
import 'sign_in.dart';
import 'theme.dart';
import 'widgets.dart';

/// Who runs the chit. The owner adds co-admins by WhatsApp number or email;
/// they see the chit the next time they sign in with it.
class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key, required this.record});
  final KuriRecord record;

  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  List<Map<String, dynamic>>? admins;
  String? error;

  bool get owner => widget.record.isOwner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _take(dynamic j) {
    setState(() => admins = (j as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
  }

  Future<void> _load() async {
    try {
      final j = await Api.instance.rpc('kuri_admin_list', {'id': widget.record.id});
      if (mounted) _take(j);
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  Future<void> _add() async {
    final added = await showKSheet<dynamic>(context, title: S.of(context).addAnAdmin, builder: (ctx) => _AddAdmin(kuriId: widget.record.id));
    if (added != null && mounted) {
      _take(added);
      toast(context, S.of(context).adminAdded);
    }
  }

  Future<void> _remove(Map<String, dynamic> a) async {
    final mine = a['me'] == true;
    final s = S.of(context);
    final ok = await confirm(context,
        title: mine ? s.leaveChitTitle : s.removeAdminTitle(_label(a)),
        text: mine ? s.leaveChitText : s.removeAdminText,
        yes: mine ? s.leave : s.remove,
        danger: true);
    if (!ok) return;
    try {
      final j = await Api.instance.rpc('remove_kuri_admin', {'admin_id': a['id']});
      if (!mounted) return;
      if (mine) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        return;
      }
      _take(j);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  Future<void> _makeOwner(Map<String, dynamic> a) async {
    final s = S.of(context);
    final ok = await confirm(context, title: s.makeOwnerTitle(_label(a)), text: s.makeOwnerText, yes: s.makeOwner);
    if (!ok) return;
    try {
      final j = await Api.instance.rpc('make_kuri_owner', {'admin_id': a['id']});
      if (!mounted) return;
      _take(j);
      Navigator.of(context).popUntil((r) => r.isFirst);
      toast(context, s.ownsNow(_label(a)));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  String _label(Map<String, dynamic> a) {
    final n = (a['name'] as String?)?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final p = a['phone'] as String?;
    if (p != null && p.isNotEmpty) return prettyPhone(p);
    return (a['email'] as String?) ?? S.current.roleAdmin;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.admins)),
      floatingActionButton: owner
          ? FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: K.deep,
              foregroundColor: Colors.white,
              elevation: 2,
              highlightElevation: 4,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(s.addAdmin, style: T.button.copyWith(color: Colors.white)),
            )
          : null,
      body: () {
        if (admins == null && error != null) return LoadFailed(message: error!, onRetry: _load);
        if (admins == null) return const Loading();
        return ListView(padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, 112), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
            child: Text(s.adminsExplain, style: T.small),
          ),
          const SizedBox(height: Sp.md + 2),
          for (final a in admins!) ...[
            KCard(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 12),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: a['role'] == 'owner' ? K.deep : K.surface2, shape: BoxShape.circle),
                  child: Text(initials(_label(a)),
                      style: T.label.copyWith(color: a['role'] == 'owner' ? K.heroText : K.ink2, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(_label(a), style: T.bodyStrong),
                      if (a['role'] == 'owner') Pill(s.roleOwner),
                      if (a['me'] == true) Pill(s.you, color: K.surface2, fg: K.ink2),
                    ]),
                    if ((a['phone'] as String?)?.isNotEmpty ?? false)
                      Text(prettyPhone(a['phone'] as String), textDirection: TextDirection.ltr, style: T.small),
                    if ((a['email'] as String?)?.isNotEmpty ?? false)
                      Text(a['email'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                  ]),
                ),
                if (a['role'] != 'owner' && (owner || a['me'] == true))
                  IconButton(
                    tooltip: s.more,
                    icon: const Icon(Icons.more_horiz_rounded, color: K.muted),
                    onPressed: () async {
                      final pick = await showPicker<String>(context, title: _label(a), options: [
                        if (owner && a['me'] != true) PickOption('owner', s.makeOwner, icon: Icons.workspace_premium_outlined),
                        PickOption('remove', a['me'] == true ? s.leaveChit : s.removeAdmin, icon: Icons.person_remove_outlined),
                      ]);
                      if (pick?.value == 'owner') await _makeOwner(a);
                      if (pick?.value == 'remove') await _remove(a);
                    },
                  ),
              ]),
            ),
            const SizedBox(height: Sp.md - 2),
          ],
        ]);
      }(),
    );
  }
}

class _AddAdmin extends StatefulWidget {
  const _AddAdmin({required this.kuriId});
  final String kuriId;

  @override
  State<_AddAdmin> createState() => _AddAdminState();
}

class _AddAdminState extends State<_AddAdmin> {
  bool byEmail = false;
  String cc = '91';
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final phone = byEmail ? null : fullPhone(cc, _phone.text);
      if (!byEmail && (phone == null || phone.isEmpty)) throw ApiError(S.current.enterTheirWa);
      final email = byEmail ? _email.text.trim().toLowerCase() : null;
      if (byEmail && (email == null || !email.contains('@'))) throw ApiError(S.current.enterTheirEmail);
      final j = await Api.instance.rpc('add_kuri_admin', {'id': widget.kuriId, 'phone': phone, 'email': email, 'name': _name.text.trim()});
      if (mounted) Navigator.of(context).pop(j);
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (error != null) ...[Notice(error!), const SizedBox(height: Sp.md)],
      Text(s.fieldName, style: T.label),
      const SizedBox(height: Sp.sm),
      TextField(controller: _name, textCapitalization: TextCapitalization.words, style: T.bodyStrong, decoration: InputDecoration(hintText: s.theirName)),
      const SizedBox(height: Sp.md + 2),
      Row(children: [
        Expanded(child: Text(byEmail ? s.email : s.waNumberHint, style: T.label)),
        KButton(
          label: byEmail ? s.useWa : s.useEmail,
          kind: KButtonKind.ghost,
          small: true,
          onPressed: () => setState(() => byEmail = !byEmail),
        ),
      ]),
      const SizedBox(height: Sp.xs),
      if (byEmail)
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textDirection: TextDirection.ltr,
          style: T.bodyStrong,
          decoration: const InputDecoration(hintText: 'name@example.com'),
        )
      else
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            CountryButton(code: cc, onChanged: (v) => setState(() => cc = v)),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                style: T.bodyStrong,
                decoration: InputDecoration(hintText: s.phoneHint),
              ),
            ),
          ]),
        ),
      const SizedBox(height: Sp.sm),
      Text(byEmail ? s.adminSignInEmail : s.adminSignInNumber, style: T.small),
      const SizedBox(height: Sp.lg),
      KButton(label: s.addAdmin, icon: Icons.person_add_alt_1_rounded, expand: true, busy: busy, onPressed: _go),
    ]);
  }
}
