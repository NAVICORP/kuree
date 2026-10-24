# Kuree on the App Store: the plan for the day

Each step says who does it: **You** (needs your identity, a password, a payment or a final yes) or **Claude** (done in your browser or on GitHub while you watch). Times are rough. No Mac is needed: GitHub Actions builds and uploads the app.

Every value to paste is in [APPSTORE.md](APPSTORE.md).

## Have these ready (You, 5 min)

- Your legal first and last name, exactly as on your passport.
- SKIFI GROUP LLC's D-U-N-S number (the one Google Play accepted).
- The LLC's registration document (Wyoming articles of organization or a certificate of good standing), as a PDF. Apple asks for it for the EU listing (step 8).
- The phone you'll answer if Apple calls to verify the company.
- A card for the USD 99 yearly fee.

## 1. Enroll in the Apple Developer Program (You, 30 min, then waiting)

**This is the one blocker. Start it first thing.** Everything after step 1 waits for Apple's approval.

1. Check the company is listed correctly: https://developer.apple.com/enroll/duns-lookup/ (Claude can do this with you). The legal name must read SKIFI GROUP LLC with the same address as the D-U-N-S record. If it's missing or different, fix it with D&B first: a new or updated record can take up to 5 business days at D&B and 2 more to reach Apple.
2. Use an Apple Account with two-factor on, under your legal name (not "SkiFi"), with your company email: ishaque@skifi.co. Apple wants an email on the company's own domain.
3. Enroll: https://developer.apple.com/programs/enroll/ > Start your enrollment > Company or organization.
   - Legal entity name: SKIFI GROUP LLC (no trading names)
   - D-U-N-S number
   - Website: https://skifi.co
   - Work email ishaque@skifi.co, phone +91 78270 87878
   - Your role: owner (you must be able to sign agreements for the company)
4. Apple checks the details and may call you. Once they approve, you accept the license agreement and pay USD 99.

How long: often 1 to 3 business days, sometimes a couple of weeks when a name or address doesn't match the D-U-N-S record. Apple doesn't promise a time. Check the status at https://developer.apple.com/account.

## While Apple reviews the enrollment (Claude)

- Add a support page at https://kureeapp.com/support (contact email, FAQ, how to delete an account). The App Store asks for a support URL.
- Make sure the iOS pull request ("iOS: App Store ready build and TestFlight pipeline") is green and merged (You merge it).
- Check the review account: you sign in once in the app with contact@skifi.co and the review password, and Claude makes sure it has a sample chit. Use the same account for both stores.
- Keep the `store-pictures` branch: the App Store screenshots live there (`store/ios/1.png` to `7.png`, 1290 x 2796).

## 2. Accept the agreements (You, 5 min)

App Store Connect > Business: https://appstoreconnect.apple.com/business. Accept the latest Apple Developer Program License Agreement. Kuree is free with no in-app purchases, so the Paid Apps agreement, tax forms and bank details aren't needed.

## 3. Register the bundle ID (Claude, 3 min)

https://developer.apple.com/account/resources/identifiers/list > + > App IDs > App. Description `Kuree`, Explicit bundle ID `co.skifi.kuree`. No extra capabilities unless the iOS pull request lists one. Register.

## 4. Create the app in App Store Connect (Claude, 5 min)

https://appstoreconnect.apple.com/apps > + > New App, with the values in APPSTORE.md section 1. Set the developer name to SkiFi if App Store Connect offers it (the seller shows as SKIFI GROUP LLC).

## 5. API key, Team ID and GitHub secrets (You with Claude, 10 min)

1. Users and Access > Integrations > App Store Connect API: https://appstoreconnect.apple.com/access/integrations/api. As the Account Holder, request API access if it asks (usually approved straight away).
2. Team Keys > Generate API Key. Name `GitHub Actions`, access **Admin** (the build creates its own signing certificate and profile, which needs Admin). Download the `.p8` file: it can only be downloaded once, so keep it in your password manager. Note the **Key ID** and the **Issuer ID** shown on the page.
3. Team ID: https://developer.apple.com/account > Membership details.
4. GitHub > NAVICORP/kuree > Settings > Secrets and variables > Actions: https://github.com/NAVICORP/kuree/settings/secrets/actions. Add:

| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | the Team ID (10 characters) |
| `APP_STORE_CONNECT_KEY_ID` | the Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | the Issuer ID |
| `APP_STORE_CONNECT_KEY_P8` | the .p8 file as base64 |

To copy the .p8 as base64 in PowerShell:

```
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\Downloads\AuthKey_XXXXXXXXXX.p8")) | Set-Clipboard
```

## 6. Build and upload to TestFlight (Claude, about 30 min, mostly waiting)

GitHub > Actions > app.yml > Run workflow on `main` with **testflight** ticked: https://github.com/NAVICORP/kuree/actions/workflows/app.yml (or `gh workflow run app.yml --ref main -f testflight=true`). It signs the app with the API key and uploads it. App Store Connect then processes the build for 10 to 30 minutes and emails you when it's ready.

For a quick compile check without uploading, run it with **ios** ticked instead.

## 7. Try it on your iPhone (You, 15 min)

1. App Store Connect > the app > TestFlight > Internal Testing: create a group and add yourself.
2. Install TestFlight from the App Store: https://apps.apple.com/app/testflight/id899247664, then open the invite.
3. Check: sign in, tick a payment, mark someone late, run the bottle draw and save the video, send a reminder, share the members' link. Try Delete account only on a spare account, never on the review account.

## 8. EU listing details (You, 10 min)

App Store Connect > Business > Agreements > Compliance > Digital Services Act > Complete Compliance Requirements. Choose **trader** (SKIFI GROUP LLC is a business). The address comes from the D-U-N-S record; add contact@skifi.co and +91 78270 87878 (both verified with a code) and upload the LLC registration PDF. These details appear publicly on the EU product page. If this holds up the launch, untick the 27 EU countries under Availability for now and add them back once it's verified.

## 9. Fill in the listing (Claude, 30 min)

From APPSTORE.md, in App Store Connect:

- App Information: subtitle, categories, content rights, privacy policy URL (section 2).
- Pricing and Availability: free, everywhere except China mainland (section 3).
- Version 1.0: promotional text, description, keywords, support and marketing URLs, copyright, the 7 screenshots, the build from step 6 (section 4).
- App Review Information: the demo account and notes (section 5). You type the password.
- Age rating: all None or No, giving 4+ (section 6).
- App Privacy: the five data types, then Publish (section 7).

## 10. Submit for review (You, 2 min)

Add for Review > Submit to App Review. Choose to release automatically once approved (or manually, to pick the day). Apple reviews most apps within 24 to 48 hours.

If Apple rejects it, Claude drafts the reply in Resolution Center. The likely questions, and the answers already in the notes:

- "Is this a financial service?" No: records only, no money moves through the app.
- "Is the draw a lottery?" No: nothing is bought or staked, and it only sets the order in which members receive their own savings.
- "We couldn't sign in." Use email > Use a password with the demo account; it must not be deleted or have its password changed.

## 11. After approval (Claude)

- Put the App Store link into the store buttons on kureeapp.com (`web/assets/home.js`).
- Update the Instagram bio to "Now on Google Play and App Store".
- Add the App Store link to the Play listing's website and to the YouTube description.

## Time, all in

About 2 hours of hands-on work on the day, plus Apple's enrollment check (days) and the app review (a day or two).
