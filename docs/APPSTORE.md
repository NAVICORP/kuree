# Kuree: App Store listing

Everything to paste into App Store Connect, field by field, in the order the pages ask for it. Character limits are checked; the count is in brackets.

The plan for the day (enrollment, the build, submitting) is in [IOS-LAUNCH.md](IOS-LAUNCH.md). The Google Play listing is in [STORE.md](STORE.md).

## 1. New app (Apps > + > New App)

| Field | Value |
|---|---|
| Platforms | iOS |
| Name | `Kuree: Chit Tracker` (19 of 30) |
| Primary language | English (U.S.) |
| Bundle ID | `co.skifi.kuree` (register it first under Certificates, Identifiers & Profiles > Identifiers if it isn't in the list) |
| SKU | `kuree` |
| User access | Full access |

If the name is taken: `Kuree Chit Manager`.

## 2. App Information

| Field | Value |
|---|---|
| Subtitle | `Payments, fines and the draw` (28 of 30) |
| Category | Primary: **Finance**. Secondary: **Productivity** |
| Content rights | No, it doesn't contain, show or access third-party content |
| Age rating | 4+ (answers in section 6) |
| Privacy policy URL | https://kureeapp.com/privacy |
| Digital Services Act (EU) | Trader (see [IOS-LAUNCH.md](IOS-LAUNCH.md), step 8) |

Why Finance first: people look for chit apps there, Google Play has it there too, and money trackers such as bill splitters sit in Finance. Productivity is second because Kuree is a record keeper, not a financial service.

## 3. Pricing and Availability

- Price: Free (USD 0). No in-app purchases.
- Availability: all countries and regions **except China mainland** (selling there needs a Chinese ICP filing number).

## 4. Version 1.0 page

**Promotional text** (135 of 170, can be changed any time without a review)

```
Run your chit from your phone: who paid, who is late, the monthly bottle draw and WhatsApp reminders. Members follow along from a link.
```

**Description** (1,808 of 4,000)

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

Sign in with a code on WhatsApp or by email. Delete your account any time from the Account screen.

Privacy: https://kureeapp.com/privacy
Terms: https://kureeapp.com/terms
```

**Keywords** (95 of 100, no spaces, none of the words in the name)

```
chitty,fund,committee,kitty,rosca,savings,group,monthly,draw,pot,fines,reminder,dues,collection
```

No app names or trademarks go in keywords (Review Guideline 2.3.7), so WhatsApp is only in the description, where it describes a feature.

| Field | Value |
|---|---|
| Support URL | https://kureeapp.com/support (Claude adds this page on the day; until then https://kureeapp.com/#faq) |
| Marketing URL | https://kureeapp.com |
| Version | 1.0.0 (App Store Connect suggests 1.0; change it to match the build) |
| Copyright | `2026 SKIFI GROUP LLC` |
| What's New | `The first version of Kuree.` (not shown for the first version, but harmless) |

**Screenshots**: App Store Connect now asks for the "iPhone with Dynamic Island (medium display)" slot, which takes 1206 x 2622 (or 1179 x 2556) and rejects 1290 x 2796. The 1290 x 2796 files in `store/ios/1.png` to `7.png` on the `store-pictures` branch were resized to 1206 x 2622 (scaled to 2622 high, 2 px trimmed from each side) and uploaded in order, 25 Oct 2026. RGB, no transparency. The app is iPhone only, so no iPad screenshots are needed. No app preview video (previews may only show footage captured from the app; the launch reel isn't that).

**Build**: pick the build that the TestFlight workflow uploaded (step 6 of the plan).

## 5. App Review Information

**Sign-in required**: Yes.

| Field | Value |
|---|---|
| User name | `contact@skifi.co` |
| Password | the same review password as Google Play (you type it in) |
| First name | Ishaque |
| Last name | Nv |
| Phone | +91 78270 87878 |
| Email | contact@skifi.co |

**Notes** (paste as is)

```
Kuree is a record keeper for the admins of a chit, an informal rotating savings group common in India. Each month every member pays a share and one member takes the whole pot, until everyone has had it once.

Kuree only keeps the record: who paid, late fines and who took the pot. It never holds, moves or lends money. It takes no payments, has no in-app purchases and is not a chit fund company or a financial service. Members pay each other directly, outside the app, as they always have.

To sign in: tap "Use email instead", then "Use a password", and use the demo account above. It has a sample chit ready.

The bottle draw only decides which member receives this month's pot, which is the group's own savings. Nothing is bought, staked or won in the app.

Members see a read-only web page from a private link the admin shares, for example https://kureeapp.com/k/demo

To delete the account: tap the round initial at the top right of the home screen, then Delete account.
```

## 6. Age rating questionnaire

Answer **None** or **No** to everything:

| Section | Item | Answer |
|---|---|---|
| In-app controls | Parental controls | No |
| | Age assurance | No |
| Capabilities | Unrestricted web access | No (links open in Safari or WhatsApp, not inside the app) |
| | User-generated content | No (a chit's records are only seen by its own admins and by people its admins send a private link to; nothing is published or shared with strangers) |
| | Messaging and chat | No (WhatsApp reminders are sent from WhatsApp on the admin's own phone) |
| | Social media | No |
| | Advertising | No |
| Mature themes | Profanity, horror, alcohol, tobacco or drugs | None |
| Medical or wellness | Medical information, health or wellness topics | None |
| Sexuality or nudity | All items | None |
| Violence | All items, including guns or other weapons | None |
| Chance-based activities | Gambling | No (no betting or wagering; the draw only sets the order members receive their own savings) |
| | Simulated gambling | None |
| | Contests | None |
| | Loot boxes | No |

Result: **4+**. Don't choose the Kids category.

## 7. App Privacy (Data types)

Start: "Do you or your third-party partners collect data from this app?" **Yes.**

| Data type | Collected | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|---|
| Contact Info > Name | Yes | Yes | No | App Functionality |
| Contact Info > Email Address | Yes | Yes | No | App Functionality |
| Contact Info > Phone Number | Yes | Yes | No | App Functionality |
| User Content > Other User Content | Yes | Yes | No | App Functionality |
| Identifiers > User ID | Yes | Yes | No | App Functionality |

Everything else (location, contacts, photos or videos, health, financial info, browsing or search history, purchases, usage data, diagnostics, device ID): **Not collected**.

What each line covers:

- **Name**: the admin's display name, shown to their co-admins.
- **Email Address, Phone Number**: the admin's sign-in (email, or WhatsApp number). Either one, not both.
- **Other User Content**: the chit itself: its name and amounts, members' names, members' WhatsApp numbers if the admin adds them for reminders, payments, fines and draws.
- **User ID**: the SkiFi account ID the sign-in gives each admin.
- No ads, analytics, crash reporting or trackers, so "Data Used to Track You" is empty.
- "Financial Info" is not collected: Kuree records amounts the group agreed, not anyone's bank, card or credit details.

This matches the Google Play Data safety form, plus User ID, which Apple lists separately.

## 8. Export compliance

Already answered in the build: `ITSAppUsesNonExemptEncryption` is false in Info.plist (the app only uses standard HTTPS from iOS). App Store Connect won't ask. If it ever does: "None of the algorithms mentioned above".

## 9. Things Apple checks that Kuree already covers

| Rule | How Kuree meets it |
|---|---|
| 2.1 Demo account | contact@skifi.co with a password, sample chit ready |
| 3.2.1(viii) Financial services need a licensed institution | Not a financial service: records only, said in the description and the review notes |
| 4.8 Sign in with Apple | Not needed: Kuree only uses SkiFi's own sign-in (WhatsApp code or email), no Google or Facebook login |
| 5.1.1(v) Account deletion in the app | Account > Delete account, plus https://kureeapp.com/delete-account |
| 5.1.1(i) Privacy policy | https://kureeapp.com/privacy, linked in the app and the listing |
| 5.3 Gambling and lotteries | No stake, no prize beyond members' own savings, no purchases |
