import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../l10n/strings.dart';
import 'language.dart';
import 'theme.dart';
import 'widgets.dart';

/// Country codes for WhatsApp numbers, with flags as pictures (Windows and
/// some Android phones show flag emoji as two letters). The English names
/// are a fallback; the list shows them in the app's language.
const kCountries = <(String, String, String)>[
  ('91', 'in', 'India'),
  ('971', 'ae', 'UAE'),
  ('966', 'sa', 'Saudi Arabia'),
  ('974', 'qa', 'Qatar'),
  ('965', 'kw', 'Kuwait'),
  ('968', 'om', 'Oman'),
  ('973', 'bh', 'Bahrain'),
  ('1', 'us', 'United States'),
  ('44', 'gb', 'United Kingdom'),
  ('61', 'au', 'Australia'),
  ('65', 'sg', 'Singapore'),
  ('60', 'my', 'Malaysia'),
  ('49', 'de', 'Germany'),
];

(String, String, String) countryOf(String code) => kCountries.firstWhere((c) => c.$1 == code, orElse: () => kCountries.first);

/// A number typed after a country code, as digits with the code. Someone who
/// types their own +44 overrides the picker.
String fullPhone(String cc, String raw) {
  final t = raw.trim();
  final own = t.startsWith('+') || t.startsWith('00');
  var d = t.replaceAll(RegExp(r'[^0-9]'), '');
  if (t.startsWith('00')) d = d.substring(2);
  if (!own) d = cc + d.replaceFirst(RegExp(r'^0+'), '');
  return d.length >= 8 && d.length <= 15 ? d : '';
}

/// The country code button: a flag and +91, opening a list.
class CountryButton extends StatelessWidget {
  const CountryButton({super.key, required this.code, required this.onChanged});
  final String code;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = countryOf(code);
    return Material(
      color: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rMd), side: const BorderSide(color: K.border2)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final picked = await showPicker<String>(
            context,
            title: s.countryCode,
            selected: code,
            options: [for (final x in kCountries) PickOption(x.$1, s.countryName(x.$2), sub: '+${x.$1}')],
          );
          if (picked != null) onChanged(picked.value);
        },
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset('assets/flags/${c.$2}.png', width: 22, height: 16, fit: BoxFit.cover),
              ),
              const SizedBox(width: Sp.sm),
              Text('+${c.$1}', textDirection: TextDirection.ltr, style: T.bodyStrong),
              const Icon(Icons.expand_more_rounded, size: 20, color: K.muted),
            ]),
          ),
        ),
      ),
    );
  }
}

enum _Step { start, phone, phoneCode, email, emailCode, password }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  _Step step = _Step.start;
  String cc = '91';
  String phone = '';
  String email = '';
  String? error;
  bool busy = false;
  int wait = 0;
  Timer? _timer;
  final _num = TextEditingController();
  final _mail = TextEditingController();
  final _code = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _num.dispose();
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

  Future<void> _sendPhone() => _run(() async {
        final p = fullPhone(cc, _num.text);
        if (p.isEmpty) throw ApiError(S.current.enterYourWa);
        await Api.instance.sendWhatsAppCode(p);
        phone = p;
        _go(_Step.phoneCode);
        _startWait();
      });

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
        if (step == _Step.phoneCode) {
          await Api.instance.verifyWhatsAppCode(phone, c);
        } else {
          await Api.instance.verifyEmailCode(email, c);
        }
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
      body: Stack(children: [
        Positioned(
          top: -220,
          left: -100,
          right: -100,
          child: Container(
            height: 520,
            decoration: const BoxDecoration(
              gradient: RadialGradient(colors: [Color(0x29116326), Color(0x00116326)], radius: 0.6),
            ),
          ),
        ),
        SafeArea(
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
                      KCard(
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
      ]),
    );
  }

  String _sub(S s) => switch (step) {
        _Step.phoneCode => s.subPhoneCode,
        _Step.emailCode => s.subEmailCode,
        _Step.phone => s.subPhone,
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

  /// A sentence with the phone number or email in bold. The sentence comes
  /// from the app's words with a marker where the number goes.
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

  /// The number field: country code and number, left to right in every language.
  Widget _phoneField(S s) => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          CountryButton(code: cc, onChanged: (v) => setState(() => cc = v)),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: TextField(
              controller: _num,
              autofocus: true,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              style: T.bodyStrong,
              decoration: InputDecoration(hintText: s.phoneHint),
              onSubmitted: (_) => _sendPhone(),
            ),
          ),
        ]),
      );

  Widget _ghosts(List<Widget> buttons) => Wrap(alignment: WrapAlignment.center, spacing: Sp.xs, runSpacing: Sp.xs, children: buttons);

  List<Widget> _form(S s) {
    switch (step) {
      case _Step.start:
        return [
          KButton(label: s.continueWa, icon: Icons.chat_rounded, expand: true, onPressed: () => _go(_Step.phone)),
          const SizedBox(height: Sp.md - 2),
          KButton(label: s.useEmailInstead, icon: Icons.mail_outline_rounded, kind: KButtonKind.secondary, expand: true, onPressed: () => _go(_Step.email)),
        ];
      case _Step.phone:
        return [
          Text(s.waNumberHint, style: T.label),
          const SizedBox(height: Sp.sm),
          _phoneField(s),
          const SizedBox(height: Sp.lg),
          KButton(label: s.sendCodeWa, icon: Icons.send_rounded, expand: true, busy: busy, onPressed: _sendPhone),
          const SizedBox(height: 6),
          _ghosts([KButton(label: s.useEmailInstead, kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.email))]),
        ];
      case _Step.phoneCode:
      case _Step.emailCode:
        final wa = step == _Step.phoneCode;
        return [
          wa ? _sentTo(s.codeSentWa, prettyPhone(phone), true) : _sentTo(s.codeSentEmail, email, true),
          const SizedBox(height: 14),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0).merge(T.tabular),
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
              onPressed: wait > 0 || busy ? null : (wa ? _sendPhone : _sendEmail),
            ),
            KButton(
              label: wa ? s.anotherNumber : s.anotherEmail,
              kind: KButtonKind.ghost,
              small: true,
              onPressed: () => _go(wa ? _Step.phone : _Step.email),
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
            KButton(label: s.useWa, kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.phone)),
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
