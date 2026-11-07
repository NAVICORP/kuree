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

/// Push notifications (Firebase Cloud Messaging). The builds read these from
/// the Firebase config files in the repository secrets FIREBASE_ANDROID_JSON
/// and FIREBASE_IOS_PLIST (see .github/workflows/app.yml). Empty: no push,
/// and the app works as before with only the reminders set on the phone.
const String kFirebaseApiKey = String.fromEnvironment('KUREE_FB_API_KEY');
const String kFirebaseAppId = String.fromEnvironment('KUREE_FB_APP_ID');
const String kFirebaseSenderId = String.fromEnvironment('KUREE_FB_SENDER_ID');
const String kFirebaseProjectId = String.fromEnvironment('KUREE_FB_PROJECT_ID');
const String kFirebaseIosBundleId = String.fromEnvironment('KUREE_FB_IOS_BUNDLE_ID');

bool get kPushConfigured =>
    kFirebaseApiKey.isNotEmpty && kFirebaseAppId.isNotEmpty && kFirebaseSenderId.isNotEmpty && kFirebaseProjectId.isNotEmpty;
