import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' show AppleLogoPainter;
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/social.dart';
import '../l10n/strings.dart';
import 'glass.dart';
import 'language.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Step { start, email, emailCode, password }

/// The first screen: Apple (on iPhone), Google, or email with a code. The
/// store review account signs in with email and a password.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.apple, this.google});

  /// For previews and tests: show the Apple or Google button whatever this
  /// build supports.
  final bool? apple;
  final bool? google;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  _Step step = _Step.start;
  String email = '';
  String? error;
  bool busy = false;

  /// 'apple' or 'google' while that sheet is open.
  String? busyWith;
  int wait = 0;
  Timer? _timer;
  final _mail = TextEditingController();
  final _code = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _mail.dispose();
    _code.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _go(_Step s) => setState(() {
        step = s;
        error = null;
        _code.clear();
      });

  void _startWait() {
    _timer?.cancel();
    setState(() => wait = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => wait = wait > 0 ? wait - 1 : 0);
      if (wait == 0) t.cancel();
    });
  }

  Future<void> _run(Future<void> Function() job) async {
    if (busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await job();
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = S.of(context).somethingWrong);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Apple's or Google's own sheet. Closing it leaves this screen as it was.
  Future<void> _social(String provider) async {
    if (busy) return;
    setState(() {
      busy = true;
      busyWith = provider;
      error = null;
    });
    try {
      if (provider == 'apple') {
        await SocialSignIn.apple();
      } else {
        await SocialSignIn.google();
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = S.of(context).somethingWrong);
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          busyWith = null;
        });
      }
    }
  }

  Future<void> _sendEmail() => _run(() async {
        final e = _mail.text.trim().toLowerCase();
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) throw ApiError(S.current.errEmailLooksWrong);
        await Api.instance.sendEmailCode(e);
        email = e;
        _go(_Step.emailCode);
        _startWait();
      });

  Future<void> _verify() => _run(() async {
        final c = _code.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (c.length != 6) throw ApiError(S.current.enterCode);
        await Api.instance.verifyEmailCode(email, c);
      });

  Future<void> _password() => _run(() async {
        final e = _mail.text.trim().toLowerCase();
        if (e.isEmpty || _pass.text.isEmpty) throw ApiError(S.current.enterEmailPassword);
        await Api.instance.signInWithPassword(e, _pass.text);
      });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: K.paper,
      // Soft green and sun light behind a frosted glass card.
      body: AmbientLight(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Sp.lg, Sp.sm, Sp.lg, 0),
              child: const Align(alignment: AlignmentDirectional.centerEnd, child: LanguageChip()),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.md, Sp.xl, Sp.xxl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(K.r),
                          child: Image.asset('assets/brand/icon.png', width: 84, height: 84),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Kuree', textAlign: TextAlign.center, style: T.display),
                      const SizedBox(height: 6),
                      Text(_sub(s), textAlign: TextAlign.center, style: T.body.copyWith(color: K.muted)),
                      const SizedBox(height: 26),
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
                            ..._form(s),
                          ]),
                        ),
                      ),
                      const SizedBox(height: Sp.md),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _link(s.privacy, kPrivacyUrl),
                        const SizedBox(width: Sp.sm),
                        _link(s.terms, kTermsUrl),
                      ]),
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

  String _sub(S s) => switch (step) {
        _Step.emailCode => s.subEmailCode,
        _Step.email || _Step.password => s.subEmail,
        _Step.start => s.subStart,
      };

  Widget _link(String text, String url) => Semantics(
        link: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Text(text, style: T.small.copyWith(decoration: TextDecoration.underline, decorationColor: K.muted)),
          ),
        ),
      );

  /// A sentence with the email in bold. The sentence comes from the app's
  /// words with a marker where the email goes.
  Widget _sentTo(String Function(String) sentence, String to, bool ltrValue) {
    const mark = '\u0000';
    final parts = sentence(mark).split(mark);
    return Text.rich(
      TextSpan(style: T.body.copyWith(color: K.ink2), children: [
        TextSpan(text: parts.first),
        TextSpan(text: ltrValue ? '\u2066$to\u2069' : to, style: const TextStyle(fontWeight: FontWeight.w800)),
        if (parts.length > 1) TextSpan(text: parts.sublist(1).join(to)),
      ]),
    );
  }

  Widget _ghosts(List<Widget> buttons) => Wrap(alignment: WrapAlignment.center, spacing: Sp.xs, runSpacing: Sp.xs, children: buttons);

  List<Widget> _form(S s) {
    switch (step) {
      case _Step.start:
        final apple = widget.apple ?? SocialSignIn.appleAvailable;
        final google = widget.google ?? SocialSignIn.googleAvailable;
        return [
          // Apple's button comes first on iPhone, as large as the others.
          if (apple) ...[
            KButton(
              label: s.continueApple,
              kind: KButtonKind.apple,
              leading: const _AppleLogo(),
              expand: true,
              busy: busyWith == 'apple',
              onPressed: busy ? null : () => _social('apple'),
            ),
            const SizedBox(height: Sp.md - 2),
          ],
          if (google) ...[
            KButton(
              label: s.continueGoogle,
              kind: KButtonKind.google,
              leading: const GoogleLogo(),
              expand: true,
              busy: busyWith == 'google',
              onPressed: busy ? null : () => _social('google'),
            ),
            const SizedBox(height: Sp.md - 2),
          ],
          KButton(
            label: s.continueEmail,
            icon: Icons.mail_outline_rounded,
            kind: apple || google ? KButtonKind.secondary : KButtonKind.primary,
            expand: true,
            onPressed: busy ? null : () => _go(_Step.email),
          ),
        ];
      case _Step.emailCode:
        return [
          _sentTo(s.codeSentEmail, email, true),
          const SizedBox(height: 14),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0).merge(T.tabular),
            decoration: const InputDecoration(hintText: '000000'),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: Sp.lg),
          KButton(label: s.signIn, icon: Icons.check_rounded, expand: true, busy: busy, onPressed: _verify),
          const SizedBox(height: 6),
          _ghosts([
            KButton(
              label: wait > 0 ? s.sendAgainIn(wait) : s.sendAgain,
              kind: KButtonKind.ghost,
              small: true,
              onPressed: wait > 0 || busy ? null : _sendEmail,
            ),
            KButton(
              label: s.anotherEmail,
              kind: KButtonKind.ghost,
              small: true,
              onPressed: () => _go(_Step.email),
            ),
          ]),
        ];
      case _Step.email:
        return [
          Text(s.email, style: T.label),
          const SizedBox(height: Sp.sm),
          TextField(
            controller: _mail,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            style: T.bodyStrong,
            decoration: const InputDecoration(hintText: 'you@example.com'),
            onSubmitted: (_) => _sendEmail(),
          ),
          const SizedBox(height: Sp.lg),
          KButton(label: s.emailMeCode, icon: Icons.mail_outline_rounded, expand: true, busy: busy, onPressed: _sendEmail),
          const SizedBox(height: 6),
          _ghosts([
            KButton(label: s.otherWays, kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.start)),
            KButton(label: s.usePassword, kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.password)),
          ]),
        ];
      case _Step.password:
        return [
          Text(s.email, style: T.label),
          const SizedBox(height: Sp.sm),
          TextField(
            controller: _mail,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            style: T.bodyStrong,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
          const SizedBox(height: Sp.md),
          Text(s.password, style: T.label),
          const SizedBox(height: Sp.sm),
          TextField(
            controller: _pass,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            style: T.bodyStrong,
            onSubmitted: (_) => _password(),
          ),
          const SizedBox(height: Sp.lg),
          KButton(label: s.signIn, icon: Icons.check_rounded, expand: true, busy: busy, onPressed: _password),
          const SizedBox(height: 6),
          _ghosts([KButton(label: s.emailCodeInstead, kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.email))]),
        ];
    }
  }
}

class _AppleLogo extends StatelessWidget {
  const _AppleLogo();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 16,
        height: 19,
        child: CustomPaint(painter: AppleLogoPainter(color: Colors.white)),
      );
}

/// Google's four colour G, drawn from Google's own artwork (48 units square).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: const CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  static final _parts = <(Color, Path)>[
    (const Color(0xFFEA4335), Path()..moveTo(24,9.5)..cubicTo(27.54,9.5,30.71,10.72,33.21,13.1)..lineTo(40.06,6.25)..cubicTo(35.9,2.38,30.47,0,24,0)..cubicTo(14.62,0,6.51,5.38,2.56,13.22)..lineTo(10.54,19.41)..cubicTo(12.43,13.72,17.74,9.5,24,9.5)..close()),
    (const Color(0xFF4285F4), Path()..moveTo(46.98,24.55)..cubicTo(46.98,22.98,46.83,21.46,46.6,20)..lineTo(24,20)..lineTo(24,29.02)..lineTo(36.94,29.02)..cubicTo(36.36,31.98,34.68,34.5,32.16,36.2)..lineTo(39.89,42.2)..cubicTo(44.4,38.02,46.98,31.84,46.98,24.55)..close()),
    (const Color(0xFFFBBC05), Path()..moveTo(10.53,28.59)..cubicTo(10.05,27.14,9.77,25.6,9.77,24)..cubicTo(9.77,22.4,10.04,20.86,10.53,19.41)..lineTo(2.55,13.22)..cubicTo(0.92,16.46,0,20.12,0,24)..cubicTo(0,27.88,0.92,31.54,2.56,34.78)..lineTo(10.53,28.59)..close()),
    (const Color(0xFF34A853), Path()..moveTo(24,48)..cubicTo(30.48,48,35.93,45.87,39.89,42.19)..lineTo(32.16,36.19)..cubicTo(30.01,37.64,27.24,38.49,24,38.49)..cubicTo(17.74,38.49,12.43,34.27,10.53,28.58)..lineTo(2.55,34.77)..cubicTo(6.51,42.62,14.62,48,24,48)..close()),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    for (final (color, path) in _parts) {
      canvas.drawPath(path, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
