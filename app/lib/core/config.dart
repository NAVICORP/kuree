/// Where the Kuree server lives. Builds can point elsewhere with
/// --dart-define=KUREE_API=https://example.com
const String kApiBase = String.fromEnvironment('KUREE_API', defaultValue: 'https://kureeapp.com');

/// The private link members open from WhatsApp.
String shareUrl(String token) => '$kApiBase/k/$token';

/// The spreadsheet behind that link.
String reportUrl(String token) => '$kApiBase/k/$token/report.xlsx';

const String kPrivacyUrl = '$kApiBase/privacy';
const String kTermsUrl = '$kApiBase/terms';
const String kSupportEmail = 'contact@skifi.co';

/// Google sign-in. The web client id of the SkiFi login's Google project:
/// the id tokens are made for it, so the server can check them. Builds set
/// it with --dart-define=KUREE_GOOGLE_SERVER_CLIENT_ID=...; empty hides the
/// Google button.
const String kGoogleServerClientId = String.fromEnvironment('KUREE_GOOGLE_SERVER_CLIENT_ID');

/// The iOS client id for co.skifi.kuree in the same Google project. The iOS
/// build also needs its reversed form as a URL scheme (the workflow writes
/// app/ios/Flutter/Google.xcconfig). Empty hides the Google button on iPhone.
const String kGoogleIosClientId = String.fromEnvironment('KUREE_GOOGLE_IOS_CLIENT_ID');
