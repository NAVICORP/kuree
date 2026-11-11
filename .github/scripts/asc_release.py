#!/usr/bin/env python3
"""Gets an App Store version ready for review, short of submitting it.

  asc_release.py <version> <build number> <notes file>

Makes the version if there is none being prepared (App Store Connect copies the
description, keywords and screenshots from the live version), waits for the
build to finish processing, attaches it, and writes the notes into "What's New"
for every language. Submitting stays a person's job in App Store Connect.

Needs the same App Store Connect key secrets as app.yml.
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
from asc_screenshots import call, BUNDLE_ID, EDITABLE  # noqa: E402

version, build_no, notes_file = sys.argv[1], sys.argv[2], sys.argv[3]
notes = open(notes_file).read().strip()

apps = [a for a in call('GET', f'/apps?filter[bundleId]={BUNDLE_ID}&limit=10')['data']
        if a['attributes']['bundleId'] == BUNDLE_ID]
app = apps[0]['id']

versions = call('GET', f'/apps/{app}/appStoreVersions?filter[platform]=IOS&limit=50')['data']
for v in versions:
    print(f"Found version {v['attributes']['versionString']}: {v['attributes']['appStoreState']}")
# A version added to a review draft but not yet submitted can still change build.
editable = [v for v in versions if v['attributes']['appStoreState'] in EDITABLE | {'READY_FOR_REVIEW'}]
same = [v for v in editable if v['attributes']['versionString'] == version]
if same:
    vid = same[0]['id']
    print(f'Using version {version}, already being prepared.')
elif editable:
    vid = editable[0]['id']
    call('PATCH', f'/appStoreVersions/{vid}', {'data': {'type': 'appStoreVersions', 'id': vid,
         'attributes': {'versionString': version}}})
    print(f"Renamed the version being prepared ({editable[0]['attributes']['versionString']}) to {version}.")
else:
    vid = call('POST', '/appStoreVersions', {'data': {'type': 'appStoreVersions',
               'attributes': {'platform': 'IOS', 'versionString': version, 'releaseType': 'AFTER_APPROVAL'},
               'relationships': {'app': {'data': {'type': 'apps', 'id': app}}}}})['data']['id']
    print(f'Made version {version}.')

build = None
for i in range(45):
    found = call('GET', f'/builds?filter[app]={app}&filter[version]={build_no}'
                        f'&filter[preReleaseVersion.version]={version}&limit=5')['data']
    if found:
        state = found[0]['attributes']['processingState']
        print(f'Build {build_no}: {state}')
        if state == 'VALID':
            build = found[0]
            break
        if state in ('FAILED', 'INVALID'):
            sys.exit(f'::error::Build {build_no} is {state} in App Store Connect.')
    else:
        print(f'Build {build_no} is not in App Store Connect yet.')
    time.sleep(60)
if not build:
    sys.exit(f'::error::Build {build_no} did not finish processing in 45 minutes. Run this again later.')

if build['attributes'].get('usesNonExemptEncryption') is None:
    call('PATCH', f"/builds/{build['id']}", {'data': {'type': 'builds', 'id': build['id'],
         'attributes': {'usesNonExemptEncryption': False}}})
    print('Answered the encryption question: standard encryption only (HTTPS).')

call('PATCH', f'/appStoreVersions/{vid}/relationships/build', {'data': {'type': 'builds', 'id': build['id']}})
print(f'Attached build {build_no} to version {version}.')

for loc in call('GET', f'/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50')['data']:
    call('PATCH', f"/appStoreVersionLocalizations/{loc['id']}", {'data': {
         'type': 'appStoreVersionLocalizations', 'id': loc['id'], 'attributes': {'whatsNew': notes}}})
    print(f"Wrote What's New for {loc['attributes']['locale']}.")

with open(os.environ.get('GITHUB_STEP_SUMMARY', os.devnull), 'a') as f:
    f.write(f'Version {version} has build {build_no} and its notes. Press Add for Review, then Submit, '
            'in App Store Connect.\n')
