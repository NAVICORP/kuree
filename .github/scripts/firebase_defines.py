#!/usr/bin/env python3
"""Turns a Firebase app config file into the --dart-define flags the Kuree app
reads (app/lib/core/config.dart), so no Firebase file has to live in the
repository or in the Android and iOS projects.

    firebase_defines.py android google-services.json
    firebase_defines.py ios GoogleService-Info.plist

The file may be the plain file or base64 (as kept in the repository secrets
FIREBASE_ANDROID_JSON and FIREBASE_IOS_PLIST). Prints the flags on one line.
"""
import base64
import json
import plistlib
import sys

PACKAGE = 'co.skifi.kuree'


def raw(path):
    data = open(path, 'rb').read().strip()
    if data[:1] in (b'{', b'<'):
        return data
    return base64.b64decode(data)


def android(data):
    j = json.loads(data)
    info = j['project_info']
    for c in j.get('client', []):
        ci = c.get('client_info', {})
        if ci.get('android_client_info', {}).get('package_name') == PACKAGE:
            return {
                'KUREE_FB_API_KEY': c['api_key'][0]['current_key'],
                'KUREE_FB_APP_ID': ci['mobilesdk_app_id'],
                'KUREE_FB_SENDER_ID': info['project_number'],
                'KUREE_FB_PROJECT_ID': info['project_id'],
            }
    sys.exit(f'::error::google-services.json has no Android app {PACKAGE}. Add it in the Firebase console.')


def ios(data):
    p = plistlib.loads(data)
    if p.get('BUNDLE_ID') != PACKAGE:
        sys.exit(f'::error::GoogleService-Info.plist is for {p.get("BUNDLE_ID")}, not {PACKAGE}.')
    return {
        'KUREE_FB_API_KEY': p['API_KEY'],
        'KUREE_FB_APP_ID': p['GOOGLE_APP_ID'],
        'KUREE_FB_SENDER_ID': p['GCM_SENDER_ID'],
        'KUREE_FB_PROJECT_ID': p['PROJECT_ID'],
        'KUREE_FB_IOS_BUNDLE_ID': p['BUNDLE_ID'],
    }


if __name__ == '__main__':
    if len(sys.argv) != 3 or sys.argv[1] not in ('android', 'ios'):
        sys.exit(__doc__)
    values = (android if sys.argv[1] == 'android' else ios)(raw(sys.argv[2]))
    for k, v in values.items():
        if not str(v) or any(c.isspace() or c in '"\'$`\\' for c in str(v)):
            sys.exit(f'::error::{k} in the Firebase file looks wrong.')
    print(' '.join(f'--dart-define={k}={v}' for k, v in values.items()))
