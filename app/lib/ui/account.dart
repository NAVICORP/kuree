import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/format.dart';
import 'home.dart';
import 'theme.dart';
import 'widgets.dart';

/// Your name, how you signed in, signing out and deleting the account.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.me});
  final Map<String, dynamic> me;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Map<String, dynamic> me = Map<String, dynamic>.from(widget.me);
  bool deleting = false;

  Future<void> _rename() async {
    final name = await askName(context, title: 'Your name', initial: (me['name'] as String?) ?? '');
    if (name == null) return;
    try {
      final r = await Api.instance.rpc('set_my_name', {'name': name});
      if (mounted && r is Map) setState(() => me = Map<String, dynamic>.from(r));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  Future<void> _signOut() async {
    if (!await confirm(context, title: 'Sign out?', text: 'Your chits stay safe on the server. Sign in again to see them.', yes: 'Sign out')) return;
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
    var login = false;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Delete your account?'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Kuree account and name are deleted. Chits you own pass to their next admin. Chits only you run are deleted for good, with their history and members\' links. This cannot be undone.'),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => set(() => login = !login),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Checkbox(
                    value: login,
                    onChanged: (v) => set(() => login = v ?? false),
                    activeColor: K.bad,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Also delete my SkiFi login', style: T.bodyStrong),
                      Text('The number or email you sign in with. Other SkiFi apps you use with it lose it too.', style: T.small),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            KButton(label: 'Cancel', kind: KButtonKind.ghost, small: true, onPressed: () => Navigator.of(ctx).pop()),
            KButton(label: 'Delete account', kind: KButtonKind.danger, small: true, onPressed: () => Navigator.of(ctx).pop(login)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = me['phone'] as String?;
    final email = me['email'] as String?;
    final name = (me['name'] as String?) ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
        KCard(
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: K.deep, shape: BoxShape.circle),
              child: Text(initials(name.isEmpty ? 'K' : name), style: T.h3.copyWith(color: K.heroText)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name.isEmpty ? 'No name yet' : name, style: T.h3),
                if (phone != null && phone.isNotEmpty) Text(prettyPhone(phone), style: T.small),
                if (email != null && email.isNotEmpty) Text(email, style: T.small),
              ]),
            ),
            KButton(label: 'Edit', small: true, kind: KButtonKind.secondary, onPressed: _rename),
          ]),
        ),
        const SizedBox(height: 14),
        KCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _row(Icons.privacy_tip_outlined, 'Privacy', () => launchUrl(Uri.parse(kPrivacyUrl), mode: LaunchMode.externalApplication)),
            const Divider(),
            _row(Icons.description_outlined, 'Terms', () => launchUrl(Uri.parse(kTermsUrl), mode: LaunchMode.externalApplication)),
            const Divider(),
            _row(Icons.mail_outline_rounded, 'Contact', () => launchUrl(Uri.parse('mailto:$kSupportEmail?subject=Kuree'))),
          ]),
        ),
        const SizedBox(height: 14),
        KCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _row(Icons.logout_rounded, 'Sign out', _signOut),
            const Divider(),
            _row(Icons.delete_outline_rounded, deleting ? 'Deleting…' : 'Delete account', deleting ? null : _delete, bad: true),
          ]),
        ),
      ]),
    );
  }

  Widget _row(IconData icon, String text, VoidCallback? onTap, {bool bad = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          Icon(icon, color: bad ? K.bad : K.ink2, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: T.bodyStrong.copyWith(color: bad ? K.bad : K.ink))),
          const Icon(Icons.chevron_right_rounded, color: K.border2),
        ]),
      ),
    );
  }
}
