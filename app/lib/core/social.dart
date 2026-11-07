import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../l10n/strings.dart';
import 'api.dart';
import 'config.dart';

/// Sign in with Apple (iPhone only) and with Google, through the phone's own
/// sheets. Each returns false when the person closed the sheet, so the sign-in
/// screen can stay as it was; anything else that goes wrong is an [ApiError].
class SocialSignIn {
  SocialSignIn._();

  static bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Apple's sign-in is offered on iPhone.
  static bool get appleAvailable => _ios;

  /// Google's needs this build's client ids; without them the button hides.
  static bool get googleAvailable =>
      (_android && kGoogleServerClientId.isNotEmpty) || (_ios && kGoogleIosClientId.isNotEmpty && kGoogleServerClientId.isNotEmpty);

  static Future<void>? _googleReady;

  static Future<bool> google() async {
    final g = GoogleSignIn.instance;
    try {
      // The server client id makes the id token's audience the SkiFi login's
      // web client, which is what the server checks.
      await (_googleReady ??= g.initialize(
        clientId: _ios ? kGoogleIosClientId : null,
        serverClientId: kGoogleServerClientId,
      ));
      final account = await g.authenticate(scopeHint: const ['email']);
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) throw ApiError(S.current.errSignInNotFinished);
      await Api.instance.signInWithIdToken('google', token);
      // Kuree keeps its own session; forget the Google one so the next sign-in
      // asks which account again.
      try {
        await g.signOut();
      } catch (_) {}
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) return false;
      throw ApiError(S.current.errSignInNotFinished);
    }
  }

  static Future<bool> apple() async {
    try {
      // Apple gets the SHA-256 of a fresh nonce; the server gets the nonce
      // itself and checks the two match.
      final raw = generateNonce();
      final hashed = sha256.convert(utf8.encode(raw)).toString();
      final c = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashed,
      );
      final token = c.identityToken;
      if (token == null || token.isEmpty) throw ApiError(S.current.errSignInNotFinished);
      final name = [c.givenName, c.familyName].whereType<String>().map((x) => x.trim()).where((x) => x.isNotEmpty).join(' ');
      await Api.instance.signInWithIdToken('apple', token, nonce: raw, name: name);
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return false;
      throw ApiError(S.current.errSignInNotFinished);
    } on SignInWithAppleException {
      throw ApiError(S.current.errSignInNotFinished);
    }
  }
}
