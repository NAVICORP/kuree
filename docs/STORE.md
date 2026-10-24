# Kuree: store listing

Everything to paste into Google Play Console and App Store Connect. The pictures are in `store/` (made by `tools/store/make.cjs` from the app screens with the made-up Riverside chit, so no real names are shown).

## Both stores

- App name: **Kuree: Chit Tracker** (if the name is free; otherwise **Kuree Chit Manager**)
- Developer: SkiFi (SKIFI GROUP LLC)
- Category: **Finance** (App Store secondary: Productivity)
- Website: https://kureeapp.com
- Support email: contact@skifi.co
- Privacy policy: https://kureeapp.com/privacy
- Terms: https://kureeapp.com/terms
- Account deletion: https://kureeapp.com/delete-account (also in the app: Account > Delete account)
- Price: free, no in-app purchases, no ads

## Google Play

**Short description** (80 max)

```
Track chit payments and fines, draw who takes the pot, remind on WhatsApp.
```

**Full description** (4000 max)

```
Kuree keeps your chit in one place: who paid, who is late, who takes the pot and what comes next.

It is made for the people who run a chit. Members don't need the app. They follow along from a private link you share in the group, with no login.

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

Kuree only keeps the record. It never holds or moves money; members pay each other the way they always have.

Sign in with a code on WhatsApp or by email.
```

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
- Users can ask for their data to be deleted: Yes (in the app, and https://kureeapp.com/delete-account).
- No location, contacts, photos, files, audio, device IDs, analytics or crash data are collected. Saving the draw video writes to the phone's gallery only.

**App access** (for review): sign in with Email > Use a password, with the review account in `docs/RELEASE.md` section 5. It opens a sample chit.

## App Store

- **Subtitle** (30 max): `Payments, fines and the draw`
- **Promotional text** (170 max): `Run your chit from your phone: who paid, who is late, the monthly bottle draw and WhatsApp reminders. Members follow along from a link.`
- **Keywords** (100 max): `chit,chit fund,kuri,savings group,rotating savings,committee,monthly draw,pot,fines,whatsapp`
- **Description**: the Google Play full description above.
- **What's New** (first version): `The first version of Kuree.`
- Age rating: 4+ (no gambling: see the content rating note above). Made for Kids: No.
- Copyright: `2026 SKIFI GROUP LLC`
- **App Privacy**: Contact Info (Name, Email Address, Phone Number) and User Content (Other User Content), all linked to the user, used for App Functionality only. No tracking. No third-party advertising or analytics.
- Sign in with Apple: not needed (the app has no Google, Facebook or other social sign-in).
- Review notes:

```
Kuree is for the admins of a chit, an informal rotating savings group common in India (also called a kuri): each month every member pays a share and one member takes the whole pot, until everyone has had it once. The app keeps the record only and never holds or moves money. It is not a chit fund company and offers no financial service.

To sign in: Email > Use a password, with the review account below. It has a sample chit ready.

The bottle draw picks which member receives this month's pot (their own group's savings). Nothing is staked or won from the app.

Members see the chit on a read-only web page from a link the admin shares, for example https://kureeapp.com/k/demo
```

## Pictures

| File | Size | Use |
|---|---|---|
| `store/ios/1.png` to `store/ios/7.png` | 1290 x 2796 | App Store, 6.7" and 6.9" iPhone |
| `store/play/1.png` to `store/play/7.png` | 1080 x 1920 | Google Play phone screenshots |
| `store/play/feature.png` | 1024 x 500 | Google Play feature graphic |
| `store/play/icon.png` | 512 x 512 | Google Play app icon |
