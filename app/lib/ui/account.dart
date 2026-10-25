import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../l10n/lang.dart';
import '../l10n/strings.dart';
import 'feature_request_screen.dart';
import 'home.dart';
import 'language.dart';
import 'theme.dart';
import 'widgets.dart';

/// Your name, the app's language, feature requests, signing out and deleting
/// the account.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.me});
  final Map<String, dynamic> me;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Map<String, dynamic> me = Map<String, dynamic>.from(widget.me);
  bool deleting = false;

  /// True for the Kuree team, who also see every request sent in.
  bool owner = false;

  @override
  void initState() {
    super.initState();
    FeatureRequests.isOwner().then((v) {
      if (mounted && v) setState(() => owner = true);
    });
  }

  Future<void> _rename() async {
    final name = await askName(context, title: S.of(context).yourName, initial: (me['name'] as String?) ?? '');
    if (name == null) return;
    try {
      final r = await Api.instance.rpc('set_my_name', {'name': name});
      if (mounted && r is Map) setState(() => me = Map<String, dynamic>.from(r));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  Future<void> _signOut() async {
    final s = S.of(context);
    if (!await confirm(context, title: s.signOutTitle, text: s.signOutText, yes: s.signOut)) return;
    await Api.instance.signOut();
  }

  Future<void> _delete() async {
    final choice = await _askDelete();
    if (choice == null || !mounted) return;
    setState(() => deleting = true);
    try {
      await Api.instance.deleteAccount(skifiLogin: choice);
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => deleting = false);
        toast(context, e.message, bad: true);
      }
    }
  }

  /// The delete confirmation, with the choice to delete the SkiFi login too.
  /// Null when cancelled; otherwise whether to delete the login.
  Future<bool?> _askDelete() {
    final s = S.of(context);
    var login = false;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(s.deleteAccountTitle),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.deleteAccountText, style: T.body.copyWith(color: K.ink2)),
              const SizedBox(height: Sp.md),
              Material(
                color: login ? K.badBg : K.surface2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rSm)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => set(() => login = !login),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 12, 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Checkbox(
                        value: login,
                        onChanged: (v) => set(() => login = v ?? false),
                        activeColor: K.bad,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.deleteLoginToo, style: T.bodyStrong),
                            const SizedBox(height: 2),
                            Text(s.deleteLoginTooSub, style: T.small),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
          actions: [
            Wrap(alignment: WrapAlignment.end, spacing: Sp.sm, runSpacing: Sp.sm, children: [
              KButton(label: s.cancel, kind: KButtonKind.ghost, small: true, onPressed: () => Navigator.of(ctx).pop()),
              KButton(label: s.deleteAccount, kind: KButtonKind.danger, small: true, onPressed: () => Navigator.of(ctx).pop(login)),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final phone = me['phone'] as String?;
    final email = me['email'] as String?;
    final name = (me['name'] as String?) ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(s.account)),
      body: ListView(padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, 40), children: [
        KCard(
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: K.deep, shape: BoxShape.circle),
              child: Text(initials(name.isEmpty ? 'K' : name), style: T.h3.copyWith(color: K.heroText)),
            ),
            const SizedBox(width: Sp.md + 2),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name.isEmpty ? s.noNameYet : name, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.h3),
                if (phone != null && phone.isNotEmpty) Text(prettyPhone(phone), textDirection: TextDirection.ltr, style: T.small),
                if (email != null && email.isNotEmpty) Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
              ]),
            ),
            const SizedBox(width: Sp.sm),
            KButton(label: s.edit, small: true, kind: KButtonKind.secondary, onPressed: _rename),
          ]),
        ),
        const SizedBox(height: Sp.md + 2),
        KCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _row(Icons.translate_rounded, s.language, () => pickLanguage(context),
                value: Lang.instance.chosen == null ? '${S.names[s.code]} (${s.languagePhone})' : S.names[s.code]),
            const Divider(),
            _row(Icons.lightbulb_outline_rounded, s.requestFeature, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeatureRequestScreen()));
            }),
            if (owner) ...[
              const Divider(),
              _row(Icons.inbox_outlined, s.featureInbox, () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeatureInboxScreen()));
              }),
            ],
          ]),
        ),
        const SizedBox(height: Sp.md + 2),
        KCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _row(Icons.privacy_tip_outlined, s.privacy, () => launchUrl(Uri.parse(kPrivacyUrl), mode: LaunchMode.externalApplication)),
            const Divider(),
            _row(Icons.description_outlined, s.terms, () => launchUrl(Uri.parse(kTermsUrl), mode: LaunchMode.externalApplication)),
            const Divider(),
            _row(Icons.mail_outline_rounded, s.contact, () => launchUrl(Uri.parse('mailto:$kSupportEmail?subject=Kuree'))),
          ]),
        ),
        const SizedBox(height: Sp.md + 2),
        KCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _row(Icons.logout_rounded, s.signOut, _signOut),
            const Divider(),
            _row(Icons.delete_outline_rounded, deleting ? s.deleting : s.deleteAccount, deleting ? null : _delete, bad: true),
          ]),
        ),
      ]),
    );
  }

  Widget _row(IconData icon, String text, VoidCallback? onTap, {bool bad = false, String? value}) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 14, 14),
          child: Row(children: [
            Icon(icon, color: bad ? K.bad : K.ink2, size: 22),
            const SizedBox(width: Sp.md + 2),
            Expanded(child: Text(text, style: T.bodyStrong.copyWith(color: bad ? K.bad : K.ink))),
            if (value != null) ...[
              const SizedBox(width: Sp.sm),
              Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: T.small)),
            ],
            const SizedBox(width: Sp.xs),
            const Icon(Icons.chevron_right_rounded, color: K.border2),
          ]),
        ),
      ),
    );
  }
}
