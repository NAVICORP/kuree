import 'api.dart';

/// What the app does while its loading screen shows. The session saved on
/// this phone is already picked up ([Api.load] in main, which only reads the
/// phone); this waits for it to be renewed if it had run out and, when
/// someone is signed in, asks the server for their chits, so the Chits tab
/// opens with them already there.
class Startup {
  Startup._();
  static final Startup instance = Startup._();

  Future<List<dynamic>>? _first;

  /// Loads the chits. Throws an [ApiError] when they could not be loaded and
  /// the person is still signed in; a session that ended just leads to the
  /// sign-in screen, without an error.
  Future<void> run() async {
    if (!Api.instance.signedIn) return;
    final f = Future.wait([Api.instance.rpc('my_kuris'), Api.instance.rpc('whoami')]);
    _first = f;
    try {
      await f;
    } on ApiError {
      if (identical(_first, f)) _first = null;
      if (!Api.instance.signedIn) return;
      rethrow;
    }
  }

  /// The chits and the person loaded at start (or still on their way), for
  /// the home screen to use once instead of asking again. Null after that.
  Future<List<dynamic>>? take() {
    final f = _first;
    _first = null;
    return f;
  }
}
