import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/format.dart';
import 'theme.dart';
import 'widgets.dart';

/// Country codes for WhatsApp numbers, with flags as pictures (Windows and
/// some Android phones show flag emoji as two letters).
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
    final c = countryOf(code);
    return Material(
      color: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: K.border2)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final picked = await showPicker<String>(
            context,
            title: 'Country code',
            selected: code,
            options: [for (final x in kCountries) PickOption(x.$1, x.$3, sub: '+${x.$1}')],
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
                child: Image.asset('assets/flags/${c.$2}.webp', width: 22, height: 16, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              Text('+${c.$1}', style: T.bodyStrong),
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
      if (mounted) setState(() => error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sendPhone() => _run(() async {
        final p = fullPhone(cc, _num.text);
        if (p.isEmpty) throw ApiError('Enter your WhatsApp number.');
        await Api.instance.sendWhatsAppCode(p);
        phone = p;
        _go(_Step.phoneCode);
        _startWait();
      });

  Future<void> _sendEmail() => _run(() async {
        final e = _mail.text.trim().toLowerCase();
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) throw ApiError('That email does not look right.');
        await Api.instance.sendEmailCode(e);
        email = e;
        _go(_Step.emailCode);
        _startWait();
      });

  Future<void> _verify() => _run(() async {
        final c = _code.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (c.length != 6) throw ApiError('Enter the 6 digit code.');
        if (step == _Step.phoneCode) {
          await Api.instance.verifyWhatsAppCode(phone, c);
        } else {
          await Api.instance.verifyEmailCode(email, c);
        }
      });

  Future<void> _password() => _run(() async {
        final e = _mail.text.trim().toLowerCase();
        if (e.isEmpty || _pass.text.isEmpty) throw ApiError('Enter the email and the password.');
        await Api.instance.signInWithPassword(e, _pass.text);
      });

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset('assets/brand/icon.png', width: 84, height: 84),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Kuree', textAlign: TextAlign.center, style: T.display),
                  const SizedBox(height: 6),
                  Text(_sub, textAlign: TextAlign.center, style: T.body.copyWith(color: K.muted)),
                  const SizedBox(height: 26),
                  KCard(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topCenter,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (error != null) ...[Notice(error!), const SizedBox(height: 14)],
                        ..._form(),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _link('Privacy', kPrivacyUrl),
                    const SizedBox(width: 18),
                    _link('Terms', kTermsUrl),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  String get _sub => switch (step) {
        _Step.phoneCode => 'Check WhatsApp for the code.',
        _Step.emailCode => 'Check your email for the code.',
        _Step.phone => 'Sign in with your WhatsApp number.',
        _Step.email || _Step.password => 'Sign in with your email.',
        _Step.start => 'Run your kuri from your phone.',
      };

  Widget _link(String text, String url) => GestureDetector(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Text(text, style: T.small.copyWith(decoration: TextDecoration.underline, decorationColor: K.muted)),
      );

  List<Widget> _form() {
    switch (step) {
      case _Step.start:
        return [
          KButton(label: 'Continue with WhatsApp', icon: Icons.chat_rounded, expand: true, onPressed: () => _go(_Step.phone)),
          const SizedBox(height: 10),
          KButton(label: 'Use email instead', icon: Icons.mail_outline_rounded, kind: KButtonKind.secondary, expand: true, onPressed: () => _go(_Step.email)),
        ];
      case _Step.phone:
        return [
          const Text('WhatsApp number', style: T.label),
          const SizedBox(height: 8),
          Row(children: [
            CountryButton(code: cc, onChanged: (v) => setState(() => cc = v)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _num,
                autofocus: true,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                style: T.bodyStrong,
                decoration: const InputDecoration(hintText: 'Phone number'),
                onSubmitted: (_) => _sendPhone(),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          KButton(label: 'Send code on WhatsApp', icon: Icons.send_rounded, expand: true, busy: busy, onPressed: _sendPhone),
          const SizedBox(height: 6),
          KButton(label: 'Use email instead', kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.email)),
        ];
      case _Step.phoneCode:
      case _Step.emailCode:
        final wa = step == _Step.phoneCode;
        return [
          Text.rich(
            TextSpan(style: T.body.copyWith(color: K.ink2), children: [
              TextSpan(text: wa ? 'We sent a 6 digit code on WhatsApp to ' : 'We sent a 6 digit code to '),
              TextSpan(text: wa ? prettyPhone(phone) : email, style: const TextStyle(fontWeight: FontWeight.w800)),
              const TextSpan(text: '. It works for 10 minutes.'),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0).merge(T.tabular),
            decoration: const InputDecoration(hintText: '000000'),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 16),
          KButton(label: 'Sign in', icon: Icons.check_rounded, expand: true, busy: busy, onPressed: _verify),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            KButton(
              label: wait > 0 ? 'Send again in ${wait}s' : 'Send again',
              kind: KButtonKind.ghost,
              small: true,
              onPressed: wait > 0 || busy ? null : (wa ? _sendPhone : _sendEmail),
            ),
            KButton(
              label: wa ? 'Another number' : 'Another email',
              kind: KButtonKind.ghost,
              small: true,
              onPressed: () => _go(wa ? _Step.phone : _Step.email),
            ),
          ]),
        ];
      case _Step.email:
        return [
          const Text('Email', style: T.label),
          const SizedBox(height: 8),
          TextField(
            controller: _mail,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
            style: T.bodyStrong,
            decoration: const InputDecoration(hintText: 'you@example.com'),
            onSubmitted: (_) => _sendEmail(),
          ),
          const SizedBox(height: 16),
          KButton(label: 'Email me a code', icon: Icons.mail_outline_rounded, expand: true, busy: busy, onPressed: _sendEmail),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            KButton(label: 'Use WhatsApp', kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.phone)),
            KButton(label: 'Use a password', kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.password)),
          ]),
        ];
      case _Step.password:
        return [
          const Text('Email', style: T.label),
          const SizedBox(height: 8),
          TextField(
            controller: _mail,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            style: T.bodyStrong,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
          const SizedBox(height: 12),
          const Text('Password', style: T.label),
          const SizedBox(height: 8),
          TextField(
            controller: _pass,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            style: T.bodyStrong,
            onSubmitted: (_) => _password(),
          ),
          const SizedBox(height: 16),
          KButton(label: 'Sign in', icon: Icons.check_rounded, expand: true, busy: busy, onPressed: _password),
          const SizedBox(height: 6),
          KButton(label: 'Email me a code instead', kind: KButtonKind.ghost, small: true, onPressed: () => _go(_Step.email)),
        ];
    }
  }
}
