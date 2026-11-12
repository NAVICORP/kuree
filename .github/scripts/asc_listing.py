#!/usr/bin/env python3
"""Bring the App Store text of the version being prepared in line with
'chits and the law': the description, the promotional text and the App
Review notes. Each change is a plain text swap, safe to run again: text that
is already changed is left as it is.

  asc_listing.py <version>
"""
import sys

sys.path.insert(0, __file__.rsplit('/', 1)[0])
from asc_screenshots import call, BUNDLE_ID, EDITABLE  # noqa: E402

version = sys.argv[1]
LAW = ("CHITS AND THE LAW\n"
       "In India, chits come under the Chit Funds Act, 1982: a chit needs the State Government's sanction and "
       "registration with the Registrar of Chits before it starts. The organiser is responsible for following the "
       "law where they live. Kuree only keeps the record. More: https://kureeapp.com/terms#law\n\n")
SWAPS = [
    ("It is made for the people who run a chit. Kuree only keeps the record. It never holds, moves or lends money; "
     "members pay each other the way they always have.",
     "It is made for chit organisers and admins. Kuree only keeps the record. It never holds, moves or lends money, "
     "and it does not run, register or approve chits."),
]
PROMO = [("Run your chit from your phone", "Keep your chit's record on your phone")]
NOTES = [
    ("a chit, an informal rotating savings group common in India", "a chit, a rotating savings group common in India"),
    ("Members pay each other directly, outside the app, as they always have.",
     "Members pay each other directly, outside the app. Kuree does not run, register or approve chits."),
]


def swap(text, pairs):
    for old, new in pairs:
        text = text.replace(old, new)
    return text


app = call('GET', f'/apps?filter[bundleId]={BUNDLE_ID}')['data'][0]['id']
versions = call('GET', f'/apps/{app}/appStoreVersions?filter[platform]=IOS&limit=20')['data']
open_ = [v for v in versions if v['attributes']['appStoreState'] in EDITABLE | {'READY_FOR_REVIEW'}
         and v['attributes']['versionString'] == version]
if not open_:
    states = ', '.join(f"{v['attributes']['versionString']} {v['attributes']['appStoreState']}" for v in versions)
    sys.exit(f'::error::Version {version} cannot be changed now ({states}).')
vid = open_[0]['id']

for loc in call('GET', f'/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50')['data']:
    a = loc['attributes']
    desc = swap(a.get('description') or '', SWAPS)
    if 'CHITS AND THE LAW' not in desc:
        at = desc.find('Sign in with')
        desc = desc[:at] + LAW + desc[at:] if at >= 0 else desc.rstrip() + '\n\n' + LAW.rstrip()
    attrs = {'description': desc}
    if a.get('promotionalText'):
        attrs['promotionalText'] = swap(a['promotionalText'], PROMO)
    call('PATCH', f"/appStoreVersionLocalizations/{loc['id']}",
         {'data': {'type': 'appStoreVersionLocalizations', 'id': loc['id'], 'attributes': attrs}})
    print(f"Description for {a['locale']}: {len(desc)} characters, law paragraph in.")

detail = call('GET', f'/appStoreVersions/{vid}/appStoreReviewDetail').get('data')
if detail:
    notes = swap(detail['attributes'].get('notes') or '', NOTES)
    call('PATCH', f"/appStoreReviewDetails/{detail['id']}",
         {'data': {'type': 'appStoreReviewDetails', 'id': detail['id'], 'attributes': {'notes': notes}}})
    print('Review notes updated: ' + ('informal' in notes and 'still says informal' or 'no "informal"'))
