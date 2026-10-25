#!/usr/bin/env python3
"""Put a Kuree update on Google Play as drafts, through the Play Developer API.

  play_publish.py [--aab FILE] [--pictures DIR] [--text docs/STORE.md] [--dry-run]

--aab       the signed .aab. It goes into a DRAFT release on the production
            track, with the release notes from docs/STORE.md.
--pictures  a folder with 1.png, 2.png, ... (phone screenshots, in order) and
            feature.png (1024 x 500). They replace the ones on the en-US listing.
--text      docs/STORE.md: the short and full description replace the ones on
            the en-US listing (the title and the video stay as they are).
--dry-run   do everything in a throwaway edit, ask Google to check it, then
            throw it away. Nothing is saved.

Nothing is ever sent for review or rolled out from here. The edit is committed
with changesNotSentForReview=true, so the changes wait under "Changes not yet
sent for review" in Play Console, and with changesInReviewBehavior=
ERROR_IF_IN_REVIEW, so changes already in review are never cancelled (Google
answers with an error instead, and nothing is saved). The release is a draft.
Sending for review stays a click in Play Console.

Needs PLAY_SERVICE_ACCOUNT_JSON: the service account key (the .json file, raw
or base64), for an account invited in Play Console > Users and permissions.
Python packages: pyjwt, cryptography.
"""
import argparse
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

PACKAGE = 'co.skifi.kuree'
LANG = 'en-US'
TRACK = 'production'
API = f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}'
UPLOAD = f'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE}'
SCOPE = 'https://www.googleapis.com/auth/androidpublisher'
LIMITS = {'short': 80, 'full': 4000, 'notes': 500}
BANNED = {'—': 'an em dash', '·': 'a middle dot', '–': 'an en dash'}

summary = []


def say(line=''):
    print(line, flush=True)
    summary.append(line)


def fail(msg):
    say(f'**Stopped:** {msg}')
    write_summary()
    sys.exit(f'::error::{msg}')


def write_summary():
    path = os.environ.get('GITHUB_STEP_SUMMARY')
    if path:
        with open(path, 'a', encoding='utf-8') as f:
            f.write('\n'.join(summary) + '\n')


# ---- sign in as the service account ---------------------------------------

def service_account():
    raw = os.environ.get('PLAY_SERVICE_ACCOUNT_JSON', '').strip()
    if not raw:
        fail('Add the repository secret PLAY_SERVICE_ACCOUNT_JSON first (docs/STORE.md, "Publishing from GitHub").')
    if not raw.startswith('{'):
        try:
            raw = base64.b64decode(raw).decode()
        except ValueError:
            fail('PLAY_SERVICE_ACCOUNT_JSON is neither JSON nor base64 JSON.')
    try:
        info = json.loads(raw)
    except ValueError:
        fail('PLAY_SERVICE_ACCOUNT_JSON is not valid JSON.')
    if info.get('type') != 'service_account' or 'private_key' not in info:
        fail('PLAY_SERVICE_ACCOUNT_JSON is not a service account key file.')
    return info


def access_token(info):
    now = int(time.time())
    uri = info.get('token_uri', 'https://oauth2.googleapis.com/token')
    assertion = jwt.encode({'iss': info['client_email'], 'scope': SCOPE, 'aud': uri, 'iat': now, 'exp': now + 3500},
                           info['private_key'], algorithm='RS256', headers={'kid': info.get('private_key_id', '')})
    body = urllib.parse.urlencode({'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion': assertion})
    req = urllib.request.Request(uri, data=body.encode(), method='POST')
    req.add_header('Content-Type', 'application/x-www-form-urlencoded')
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode())['access_token']
    except urllib.error.HTTPError as e:
        fail(f'Google did not accept the service account key ({e.code}): {e.read().decode(errors="replace")[:300]}')


# ---- the API ----------------------------------------------------------------

class Play:
    def __init__(self, token):
        self.token = token

    def call(self, method, url, body=None, data=None, ctype=None, timeout=120):
        if body is not None:
            data, ctype = json.dumps(body).encode(), 'application/json'
        if data is None and method in ('POST', 'PUT', 'PATCH'):
            data = b''  # Google answers 411 to a POST without Content-Length
        req = urllib.request.Request(url, method=method, data=data)
        req.add_header('Authorization', 'Bearer ' + self.token)
        if ctype:
            req.add_header('Content-Type', ctype)
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                text = r.read().decode()
                return json.loads(text) if text else {}
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors='replace')
            try:
                detail = json.loads(detail)['error']['message']
            except (ValueError, KeyError, TypeError):
                pass
            raise RuntimeError(f'{method} {url.split(PACKAGE)[-1]} failed ({e.code}): {detail}') from None

    def api(self, method, path, body=None, **kw):
        return self.call(method, API + path, body=body, **kw)

    def upload(self, path, data, ctype):
        return self.call('POST', UPLOAD + path + '?uploadType=media', data=data, ctype=ctype, timeout=900)


# ---- inputs -----------------------------------------------------------------

def store_text(path):
    """The short description, full description and release notes: the first
    fenced block after each label in the Google Play part of docs/STORE.md."""
    with open(path, encoding='utf-8') as f:
        doc = f.read()
    m = re.search(r'^## Google Play\s*$(.*?)(?=^## )', doc, re.S | re.M)
    if not m:
        fail(f'{path} has no "## Google Play" section.')
    part = m.group(1)
    out = {}
    for key, label in (('short', 'Short description'), ('full', 'Full description'), ('notes', 'Release notes')):
        b = re.search(r'\*\*' + label + r'\b[^\n]*\n+```[^\n]*\n(.*?)\n```', part, re.S)
        if not b:
            fail(f'{path}: no fenced block after "**{label}**" in the Google Play section.')
        text = b.group(1).strip()
        if len(text) > LIMITS[key]:
            fail(f'{label} is {len(text)} characters; Google Play allows {LIMITS[key]}.')
        for ch, name in BANNED.items():
            if ch in text:
                fail(f'{label} has {name}; the house style does not use them.')
        out[key] = text
    return out


def png_info(path):
    with open(path, 'rb') as f:
        head = f.read(26)
    if head[:8] != b'\x89PNG\r\n\x1a\n':
        fail(f'{path} is not a PNG.')
    w, h, colour = int.from_bytes(head[16:20], 'big'), int.from_bytes(head[20:24], 'big'), head[25]
    return w, h, colour in (4, 6)


def pictures(folder):
    shots = []
    n = 1
    while os.path.exists(os.path.join(folder, f'{n}.png')):
        shots.append(os.path.join(folder, f'{n}.png'))
        n += 1
    if not 2 <= len(shots) <= 8:
        fail(f'{folder} needs 2 to 8 phone screenshots named 1.png, 2.png, ...; found {len(shots)}.')
    for s in shots:
        w, h, alpha = png_info(s)
        if alpha:
            fail(f'{s} has an alpha channel; Google Play wants 24-bit PNG.')
        if not (320 <= min(w, h) and max(w, h) <= 3840 and max(w, h) <= 2 * min(w, h)):
            fail(f'{s} is {w} x {h}; Google Play wants sides of 320 to 3840 px, the long side at most twice the short one.')
        if os.path.getsize(s) > 8 * 1024 * 1024:
            fail(f'{s} is over 8 MB.')
    feature = os.path.join(folder, 'feature.png')
    if not os.path.exists(feature):
        fail(f'{feature} is missing.')
    w, h, alpha = png_info(feature)
    if (w, h) != (1024, 500) or alpha:
        fail(f'{feature} must be 1024 x 500 without alpha; it is {w} x {h}{" with alpha" if alpha else ""}.')
    return shots, feature


# ---- the work -----------------------------------------------------------------

def describe_track(play, edit):
    try:
        t = play.api('GET', f'/edits/{edit}/tracks/{TRACK}')
    except RuntimeError as e:
        say(f'- Production track: could not read it ({e}).')
        return []
    rels = t.get('releases', [])
    for r in rels:
        say(f"- Production now: release \"{r.get('name', '')}\", version codes {', '.join(r.get('versionCodes', []))}, status {r.get('status')}")
    if not rels:
        say('- Production now: no releases.')
    return rels


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--aab')
    ap.add_argument('--pictures')
    ap.add_argument('--text')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()
    if not (a.aab or a.pictures or a.text):
        fail('Nothing to do: choose the bundle, the pictures or the text.')

    # check everything local before talking to Google
    words = store_text(a.text or 'docs/STORE.md') if (a.text or a.aab) else None
    shots, feature = pictures(a.pictures) if a.pictures else (None, None)
    if a.aab and not os.path.isfile(a.aab):
        fail(f'{a.aab} not found.')

    play = Play(access_token(service_account()))
    say(f'## Google Play: {PACKAGE}{" (dry run, nothing is saved)" if a.dry_run else ""}')
    edit = play.api('POST', '/edits', {})['id']
    try:
        existing = describe_track(play, edit)

        if a.aab:
            size = os.path.getsize(a.aab) / 1e6
            say(f'- Uploading the bundle ({size:.1f} MB)...')
            with open(a.aab, 'rb') as f:
                b = play.upload(f'/edits/{edit}/bundles', f.read(), 'application/octet-stream')
            code = b['versionCode']
            used = [int(c) for r in existing for c in r.get('versionCodes', [])]
            if used and code <= max(used):
                raise RuntimeError(f'The bundle has version code {code}, not higher than {max(used)} already on production. Build a newer one.')
            # Only the new draft is sent; Play keeps the other releases on the
            # track (the one in review, or the live one) as they are.
            play.api('PUT', f'/edits/{edit}/tracks/{TRACK}', {
                'track': TRACK,
                'releases': [{
                    'versionCodes': [str(code)],
                    'status': 'draft',
                    'releaseNotes': [{'language': LANG, 'text': words['notes']}],
                }],
            })
            say(f'- Bundle: version code {code} (sha256 {b.get("sha256", "")[:12]}...) in a **draft** production release, with the release notes.')

        if a.text:
            play.api('PATCH', f'/edits/{edit}/listings/{LANG}',
                     {'language': LANG, 'shortDescription': words['short'], 'fullDescription': words['full']})
            say(f'- Listing text ({LANG}): short description and full description ({len(words["full"])} characters) replaced.')

        if a.pictures:
            play.api('DELETE', f'/edits/{edit}/listings/{LANG}/phoneScreenshots')
            for s in shots:
                with open(s, 'rb') as f:
                    play.upload(f'/edits/{edit}/listings/{LANG}/phoneScreenshots', f.read(), 'image/png')
            play.api('DELETE', f'/edits/{edit}/listings/{LANG}/featureGraphic')
            with open(feature, 'rb') as f:
                play.upload(f'/edits/{edit}/listings/{LANG}/featureGraphic', f.read(), 'image/png')
            say(f'- Pictures ({LANG}): {len(shots)} phone screenshots and the feature graphic replaced.')

        play.api('POST', f'/edits/{edit}:validate')
        say('- Google checked the edit: no problems.')

        if a.dry_run:
            play.api('DELETE', f'/edits/{edit}')
            say('- Dry run: the edit was thrown away. Nothing changed in Play Console.')
        else:
            q = urllib.parse.urlencode({'changesNotSentForReview': 'true', 'changesInReviewBehavior': 'ERROR_IF_IN_REVIEW'})
            play.api('POST', f'/edits/{edit}:commit?{q}')
            say('- **Saved as drafts.** Nothing was sent for review.')
            say('- Next, in Play Console: Publishing overview > Changes not yet sent for review. '
                'Check the draft release (Test and release > Production) and the listing, then Send changes for review.')
    except RuntimeError as e:
        try:
            play.api('DELETE', f'/edits/{edit}')
        except RuntimeError:
            pass
        msg = str(e)
        if 'review' in msg.lower():
            msg += ' (If Google says changes are in review: wait until the current review is finished, then run this again.)'
        fail(msg + ' Nothing was saved.')
    write_summary()


if __name__ == '__main__':
    main()
