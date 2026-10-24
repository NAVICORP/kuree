/// Where the Kuree server lives. Builds can point elsewhere with
/// --dart-define=KUREE_API=https://example.com
const String kApiBase = String.fromEnvironment('KUREE_API', defaultValue: 'https://kuree.skifi.co');

/// The private link members open from WhatsApp.
String shareUrl(String token) => '$kApiBase/k/$token';

/// The spreadsheet behind that link.
String reportUrl(String token) => '$kApiBase/k/$token/report.xlsx';

const String kPrivacyUrl = '$kApiBase/privacy';
const String kTermsUrl = '$kApiBase/terms';
const String kSupportEmail = 'contact@skifi.co';
