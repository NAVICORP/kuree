#!/usr/bin/env python3
"""Replace the App Store screenshots of a version with the pictures in a folder.

  asc_screenshots.py <folder> [version] [locale]

<folder> holds 1.png, 2.png, ... in the order they should show. The version
(default 1.0.0) must still be editable (Prepare for Submission, or rejected).
The locale defaults to en-US. The pictures go into the screenshot set that
already holds the iPhone screenshots, so the display size stays the one App
Store Connect asked for.

Order of work, so a bad picture never leaves the page empty: the first new
picture is uploaded and checked by Apple while the old ones are still there,
then the old ones are removed, the rest go up, and the set is put in order.

Needs: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID,
APP_STORE_CONNECT_KEY_P8 (the .p8 file, raw or base64).
Python packages: pyjwt, cryptography.
"""
import base64
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt

API = 'https://api.appstoreconnect.apple.com/v1'
BUNDLE_ID = 'co.skifi.kuree'
EDITABLE = {'PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED', 'INVALID_BINARY'}


def env(name):
    v = os.environ.get(name, '').strip()
    if not v:
        sys.exit(f'::error::{name} is not set.')
    return v


def p8():
    raw = env('APP_STORE_CONNECT_KEY_P8')
    if 'BEGIN PRIVATE KEY' in raw:
        return raw.encode()
    return base64.b64decode(raw)


def token():
    now = int(time.time())
    return jwt.encode(
        {'iss': env('APP_STORE_CONNECT_ISSUER_ID'), 'iat': now, 'exp': now + 1100, 'aud': 'appstoreconnect-v1'},
        p8(), algorithm='ES256', headers={'kid': env('APP_STORE_CONNECT_KEY_ID'), 'typ': 'JWT'})


def call(method, path, body=None):
    req = urllib.request.Request(API + path, method=method, data=json.dumps(body).encode() if body else None)
    req.add_header('Authorization', 'Bearer ' + token())
    req.add_header('Content-Type', 'application/json')
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            text = r.read().decode()
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors='replace')
        try:
            errs = json.loads(detail).get('errors', [])
            detail = '; '.join(f"{x.get('title', '')}: {x.get('detail', '')}" for x in errs) or detail
        except ValueError:
            pass
        raise RuntimeError(f'{method} {path} failed ({e.code}): {detail}') from None


def png_size(path):
    with open(path, 'rb') as f:
        head = f.read(24)
    if head[:8] != b'\x89PNG\r\n\x1a\n':
        sys.exit(f'::error::{path} is not a PNG.')
    return int.from_bytes(head[16:20], 'big'), int.from_bytes(head[20:24], 'big')


def upload(set_id, path):
    data = open(path, 'rb').read()
    name = os.path.basename(path)
    made = call('POST', '/appScreenshots', {'data': {
        'type': 'appScreenshots',
        'attributes': {'fileName': name, 'fileSize': len(data)},
        'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': set_id}}}}})['data']
    for op in made['attributes']['uploadOperations']:
        part = data[op['offset']:op['offset'] + op['length']]
        req = urllib.request.Request(op['url'], method=op['method'], data=part)
        for h in op.get('requestHeaders') or []:
            req.add_header(h['name'], h['value'])
        with urllib.request.urlopen(req, timeout=120):
            pass
    call('PATCH', f"/appScreenshots/{made['id']}", {'data': {
        'type': 'appScreenshots', 'id': made['id'],
        'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(data).hexdigest()}}})
    return made['id']


def wait(shot_id, name):
    for _ in range(90):
        a = call('GET', f'/appScreenshots/{shot_id}')['data']['attributes']
        state = (a.get('assetDeliveryState') or {}).get('state')
        if state == 'COMPLETE':
            print(f'  {name}: ready')
            return True
        if state == 'FAILED':
            errs = (a.get('assetDeliveryState') or {}).get('errors') or []
            print(f"::error::{name} was not accepted: {'; '.join(e.get('description', e.get('code', '')) for e in errs)}")
            return False
        time.sleep(4)
    print(f'::error::{name} is still processing after 6 minutes.')
    return False


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    folder = sys.argv[1]
    version = sys.argv[2] if len(sys.argv) > 2 else '1.0.0'
    locale = sys.argv[3] if len(sys.argv) > 3 else 'en-US'

    files = []
    n = 1
    while os.path.exists(os.path.join(folder, f'{n}.png')):
        files.append(os.path.join(folder, f'{n}.png'))
        n += 1
    if not files:
        sys.exit(f'::error::No 1.png in {folder}.')
    if len(files) > 10:
        sys.exit('::error::App Store Connect takes at most 10 screenshots.')
    sizes = {png_size(f) for f in files}
    if len(sizes) != 1:
        sys.exit(f'::error::The pictures are not all one size: {sorted(sizes)}')
    print(f'{len(files)} pictures, {sizes.pop()}')

    apps = call('GET', f'/apps?filter[bundleId]={BUNDLE_ID}')['data']
    if not apps:
        sys.exit(f'::error::No app with bundle ID {BUNDLE_ID}.')
    app_id = apps[0]['id']
    versions = call('GET', f'/apps/{app_id}/appStoreVersions?filter[platform]=IOS&filter[versionString]={version}')['data']
    if not versions:
        sys.exit(f'::error::No iOS version {version}.')
    v = versions[0]
    state = v['attributes'].get('appStoreState') or v['attributes'].get('appVersionState')
    if state not in EDITABLE and v['attributes'].get('appVersionState') not in EDITABLE:
        sys.exit(f'::error::Version {version} is {state}; its screenshots cannot be changed now.')
    locs = call('GET', f"/appStoreVersions/{v['id']}/appStoreVersionLocalizations?limit=50")['data']
    loc = next((l for l in locs if l['attributes']['locale'] == locale), None)
    if not loc:
        sys.exit(f'::error::Version {version} has no {locale} page.')

    sets = call('GET', f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?include=appScreenshots&limit=50")
    iphone = []
    for s in sets['data']:
        kind = s['attributes']['screenshotDisplayType']
        shots = [r['id'] for r in (s.get('relationships', {}).get('appScreenshots', {}).get('data') or [])]
        print(f'set {kind}: {len(shots)} screenshots')
        if kind.startswith('APP_IPHONE') and shots:
            iphone.append((len(shots), kind, s['id'], shots))
    if not iphone:
        sys.exit('::error::No iPhone screenshot set with pictures in it. Upload one picture in App Store Connect first so the size is known.')
    iphone.sort(reverse=True)
    _, kind, set_id, old = iphone[0]
    print(f'Replacing the {len(old)} screenshots in {kind}')

    names = [os.path.basename(f) for f in files]
    new = []
    if len(old) + 1 <= 10:
        first = upload(set_id, files[0])
        if not wait(first, names[0]):
            call('DELETE', f'/appScreenshots/{first}')
            sys.exit(1)
        new.append(first)
    for sid in old:
        call('DELETE', f'/appScreenshots/{sid}')
    print(f'  removed the {len(old)} old screenshots')
    for f, name in list(zip(files, names))[len(new):]:
        sid = upload(set_id, f)
        if not wait(sid, name):
            sys.exit(1)
        new.append(sid)
    call('PATCH', f'/appScreenshotSets/{set_id}/relationships/appScreenshots',
         {'data': [{'type': 'appScreenshots', 'id': i} for i in new]})
    print(f'Done: {len(new)} screenshots in {kind}, in order.')
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a') as fh:
            fh.write(f'Replaced the App Store screenshots of Kuree {version} ({locale}, {kind}) with {len(new)} new ones.\n')


if __name__ == '__main__':
    main()
