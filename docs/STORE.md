# Kuree: store listing

Everything to paste into Google Play Console and App Store Connect. The pictures are in `store/` on the `store-pictures` branch (made by `tools/store/make.cjs` from the app screens with the made-up Riverside chit, so no real names are shown).

## Both stores

- App name: **Kuree: Chit Tracker** (if the name is free; otherwise **Kuree Chit Manager**)
- Developer: SkiFi (SKIFI GROUP LLC)
- Category: **Finance** (App Store secondary: Productivity)
- Website: https://kureeapp.com
- Support email: contact@skifi.co
- Privacy policy: https://kureeapp.com/privacy
- Terms: https://kureeapp.com/terms
- Account deletion: https://kureeapp.com/delete-account (also in the app: Profile in the footer > Delete account)
- Price: free, no in-app purchases, no ads

## Google Play

**Short description** (80 max)

```
Track chit payments and fines, draw who takes the pot, remind on WhatsApp.
```

**Full description** (1,802 of 4000, the same text as the App Store description)

```
Kuree keeps your chit in one place: who paid, who is late, who takes the pot and what comes next.

It is made for the people who run a chit. Kuree only keeps the record. It never holds, moves or lends money; members pay each other the way they always have.

Members don't need the app. They follow along from a private link you share in the group, with no login.

EVERY MONTH ON ONE SCREEN
- Tap the tick when someone pays. The total and what's left update as you go.
- Mark late payers and the fine is added to their row.
- Two people can share one slot, as half shares or any parts.

THE BOTTLE DRAW
- Every slot still waiting for the pot goes into the bottle as a slip.
- The phone's secure random numbers pick one. Every slip has the same chance.
- Music and sound, about 15 seconds. Save it as a video for the group.
- Prefer to pick by hand? Choose, or draw all the remaining months at once.

REMINDERS ON WHATSAPP
- Send who paid and who hasn't to the group in one tap.
- Or send each person a reminder with the amount and the last day to pay.

A LINK FOR MEMBERS
- Members open the link in any browser and see who paid, the fines, who took the pot and what comes next.
- Phone numbers stay with the admins.
- Make a new link any time and the old one stops working.

RUN IT TOGETHER
- Add co-admins by WhatsApp number or email.
- Every change is kept. Undo, or bring back any earlier version.
- Download every month and every payment as an Excel sheet.

YOUR LANGUAGE, YOUR CURRENCY
- Use Kuree in English, Arabic, Hindi, Malayalam, Tamil or Kannada.
- Pick the currency for each chit: rupees, dirhams, riyals, dollars and more.

Sign in with a code on WhatsApp or by email. Delete your account any time from your Profile.

Privacy: https://kureeapp.com/privacy
Terms: https://kureeapp.com/terms
```

**Release notes** for 1.0.1 (496 of 500, en-US, the only listing language)

```
A new, more compact look.
- A footer with Chits, To collect and Profile, also inside a chit.
- To collect: everyone still to pay this month, across your chits.
- Profile: language, help, sign out and delete account.
- Use Kuree in English, Arabic, Hindi, Malayalam, Tamil or Kannada.
- Pick the currency for each chit.
- Add names one at a time, past 10 slots.
- Change the late fine from the chit screen.
- Pick the first month and collection day on a calendar.
- Request a feature from Profile.
```

Release history: 1.0.0 (version code 21, the first design) sent for review on 24 Oct 2026. 1.0.1 is the first update: the compact design with the footer.

**Store settings**

- App category: Finance. Tags: Personal finance, Productivity.
- Contains ads: No. In-app purchases: No.
- Target audience: 18 and over.
- Content rating questionnaire: Utility. No violence, no user-to-user chat, no real-money gambling. The draw only decides the order in which members receive their own savings; nothing is staked or won from the app.
- Financial features declaration: the app keeps records for a savings group. It does not lend, take deposits, process payments or move money.
- News app: No. Government app: No. COVID app: No.

**Data safety**

| Data | Collected | Shared | Why | Optional |
|---|---|---|---|---|
| Name (the admin's display name) | Yes | No | App functionality | No |
| Phone number (admin sign-in with WhatsApp) | Yes | No | Account management | Yes, email works instead |
| Email address (admin sign-in with email) | Yes | No | Account management | Yes, WhatsApp works instead |
| Other user-generated content (the chit: member names, payments, and member phone numbers the admin adds for reminders) | Yes | No | App functionality | No |

- Data is encrypted in transit: Yes.
- Users can ask for their data to be deleted: Yes (in the app under Profile, and https://kureeapp.com/delete-account).
- No location, contacts, photos, files, audio, device IDs, analytics or crash data are collected. Saving the draw video writes to the phone's gallery only.

**App access** (for review): sign in with Email > Use a password, with the review account in `docs/RELEASE.md` section 5. It opens a sample chit. To delete the account: Profile in the footer > Delete account.

**Store listing contact details** (Store settings): contact@skifi.co, +91 78270 87878, https://kureeapp.com. Privacy policy (App content): https://kureeapp.com/privacy.

## App Store

Everything for App Store Connect, field by field, is in [APPSTORE.md](APPSTORE.md). The plan for publishing on iPhone is in [IOS-LAUNCH.md](IOS-LAUNCH.md).

## Pictures

The pictures are on the `store-pictures` branch, under `store/` (not on main). They are rendered again whenever the app screens change.

| File | Size | Use |
|---|---|---|
| `store/ios/1.png` to `store/ios/7.png` | see APPSTORE.md | App Store iPhone screenshots |
| `store/play/1.png` to `store/play/7.png` | 1080 x 1920 | Google Play phone screenshots, same captions and order as the App Store set |
| `store/play/feature.png` | 1024 x 500 | Google Play feature graphic |
| `store/play/icon.png` | 512 x 512 | Google Play app icon (unchanged since 1.0.0) |

## Publishing from GitHub

`.github/workflows/play.yml` (Actions > Google Play drafts > Run workflow) saves an update on Google Play as **drafts**: the signed bundle from the newest successful App run on main in a draft production release with the release notes above, the pictures from `store-pictures`, and the short and full description above. It never sends anything for review and never rolls anything out: that stays Publishing overview > Send changes for review in Play Console. If Google still has changes in review it stops with an error and saves nothing. Tick "Dry run" to let Google check everything without saving.

One time, before the first run (owner account):

1. Google Cloud console (console.cloud.google.com) > the project menu > New project, name `kuree-play` > Create.
2. In that project: APIs and services > Library > "Google Play Android Developer API" > Enable.
3. IAM and admin > Service accounts > Create service account, name `github-play` > Create and continue > Done (no roles needed).
4. Open `github-play` > Keys > Add key > Create new key > JSON > Create. A .json file downloads. If Google says key creation is turned off by an organisation policy, make the project from a personal Google account (for example the Gmail one) instead; the service account works the same.
5. Play Console > Users and permissions > Invite new users: the service account's email (`github-play@kuree-play.iam.gserviceaccount.com` or as shown) > App permissions > Add app > Kuree > tick **Release apps to testing tracks**, **Release to production, exclude devices, and use Play App Signing** and **Manage store presence** > Apply > Invite user.
6. GitHub > NAVICORP/kuree > Settings > Secrets and variables > Actions > New repository secret: name `PLAY_SERVICE_ACCOUNT_JSON`, value: the whole .json file. Then delete the .json from the computer.
