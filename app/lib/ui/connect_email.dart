import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../l10n/strings.dart';
import 'code_boxes.dart';
import 'glass.dart';
import 'language.dart';
import 'theme.dart';
import 'widgets.dart';

/// For someone still signed in with a WhatsApp number only: WhatsApp sign-in
/// has ended, so they add an email (a code to it, then the code) before going
/// on. The number stays on the account, so every chit stays. Signing out is
/// the other way out.
class ConnectEmailScreen extends StatefulWidget {
  const ConnectEmailScreen({super.key, this.startWithCode});

  /// Opens at the code step for this email (screenshots).
  final String? startWithCode;

  @override
  State<ConnectEmailScreen> createState() => _ConnectEmailScreenState();
}

class _ConnectEmailScreenState extends State<ConnectEmailScreen> {
  final _mail = TextEditingController();
  final _code = TextEditingController();
  late String email = widget.startWithCode ?? '';
  late bool codeStep = widget.startWithCode != null;
  bool busy = false;
  String? error;
  int wait = 0;
  Timer? _timer;

  @override
  void dispose() {
    _mail.dispose();
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await fn();
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _startWait() {
    _timer?.cancel();
    setState(() => wait = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => wait = wait > 0 ? wait - 1 : 0);
      if (wait == 0) t.cancel();
    });
  }

  Future<void> _send() => _run(() async {
        final e = (codeStep ? email : _mail.text).trim().toLowerCase();
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) throw ApiError(S.current.errEmailLooksWrong);
        await Api.instance.sendLinkCode(e);
        email = e;
        _code.clear();
        setState(() => codeStep = true);
        _startWait();
      });

  Future<void> _verify() => _run(() async {
        final c = _code.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (c.length != 6) throw ApiError(S.current.enterCode);
        // The new session carries the email; the app then goes on by itself.
        await Api.instance.verifyLinkCode(email, c);
      });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: K.paper,
      body: AmbientLight(
        child: SafeArea(
          child: Column(children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(Sp.lg, Sp.sm, Sp.lg, 0),
              child: Align(alignment: AlignmentDirectional.centerEnd, child: LanguageChip()),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.md, Sp.xl, Sp.xxl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(color: K.brand100, shape: BoxShape.circle),
                          child: const Icon(Icons.alternate_email_rounded, color: K.green, size: 34),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(s.linkEmailTitle, textAlign: TextAlign.center, style: T.h1),
                      const SizedBox(height: 8),
                      Text(s.linkEmailText, textAlign: TextAlign.center, style: T.body.copyWith(color: K.muted)),
                      const SizedBox(height: 24),
                      Glass(
                        tone: GlassTone.sheet,
                        blur: 24,
                        radius: K.rLg,
                        padding: const EdgeInsets.fromLTRB(Sp.xl, 22, Sp.xl, Sp.xl),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.topCenter,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            if (error != null) ...[Notice(error!), const SizedBox(height: 14)],
                            ...(codeStep ? _codeForm(s) : _emailForm(s)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: Sp.md),
                      Center(
                        child: KButton(
                          label: s.signOut,
                          kind: KButtonKind.ghost,
                          small: true,
                          onPressed: busy ? null : () => Api.instance.signOut(),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _emailForm(S s) => [
        TextField(
          controller: _mail,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: s.email, hintText: 'you@example.com'),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: Sp.lg),
        KButton(label: s.emailMeCode, icon: Icons.mail_outline_rounded, expand: true, busy: busy, onPressed: _send),
      ];

  List<Widget> _codeForm(S s) => [
        Text(s.codeSentEmail(email), style: T.body.copyWith(color: K.ink2)),
        const SizedBox(height: 14),
        CodeBoxes(controller: _code, autofocus: widget.startWithCode == null, onCompleted: (_) => _verify()),
        const SizedBox(height: Sp.lg),
        KButton(label: s.linkEmailConfirm, icon: Icons.check_rounded, expand: true, busy: busy, onPressed: _verify),
        const SizedBox(height: 6),
        Wrap(alignment: WrapAlignment.center, spacing: Sp.xs, children: [
          KButton(
            label: wait > 0 ? s.sendAgainIn(wait) : s.sendAgain,
            kind: KButtonKind.ghost,
            small: true,
            onPressed: wait > 0 || busy ? null : _send,
          ),
          KButton(
            label: s.anotherEmail,
            kind: KButtonKind.ghost,
            small: true,
            onPressed: busy ? null : () => setState(() => codeStep = false),
          ),
        ]),
      ];
}
