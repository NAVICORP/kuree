# Putting Kuree on the stores

## 1. The server (once)

1. **SkAuth knows Kuree.** On the SkAuth service in Dokploy, add Kuree to `SKAUTH_APPS`:
   `{"id":"kuree","name":"Kuree","site":"https://kuree.skifi.co","api":"https://kuree.skifi.co","color":"#032A09"}`
   and redeploy SkAuth.
2. **Dokploy compose.** New compose `kuree` from GitHub `NAVICORP/kuree`, branch `main`, compose path `./deploy/docker-compose.yml`. Domain `kuree.skifi.co` to service `site`, port 8000, HTTPS on. Deploy.
3. **DNS.** In Cloudflare, `kuree` A record to the VPS (179.198.218.204), proxied like the other subdomains.
4. Open https://kuree.skifi.co/health. It says `{"ok":true}`.
5. **Boystown.** Sign in to the app as Ishaque (email ishaque@skifi.co, or WhatsApp if that email is on the same SkiFi account). The home screen offers "Bring in the Boystown 5K Kuri". Tap it once. Anees is added as an admin.

## 2. Accounts (once)

- **Google Play Console** (USD 25 once). Register as an **organization** (SKIFI GROUP LLC or SKIFI CREATIVE HUB LLP, needs a D-U-N-S number) if you can. A **personal** account created after November 2023 has to run a closed test with at least 12 testers for 14 days in a row before it can publish; the Boystown members can be those testers.
- **Apple Developer Program** (USD 99 a year), as SKIFI GROUP LLC (also needs a D-U-N-S number) or as yourself.

## 3. Android

1. Make the upload key once and keep it, with its passwords, in your password manager:
   `keytool -genkey -v -keystore kuree-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. GitHub > NAVICORP/kuree > Settings > Secrets and variables > Actions, add:
   - `ANDROID_KEYSTORE_B64`: the file as base64 (`base64 -i kuree-upload.jks | pbcopy` on the Mac)
   - `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`), `ANDROID_KEY_PASSWORD`
3. Every push to `main` then builds `kuree-android-bundle` (the .aab) next to the test APK, under Actions > the run > Artifacts.
4. Play Console > Create app: name **Kuree**, package `co.skifi.kuree`, free, app.
5. Upload the .aab to **Internal testing** first, then Closed testing (and production when allowed).
6. App content:
   - Privacy policy: https://kuree.skifi.co/privacy
   - App access: give the review account (section 5).
   - Ads: none. Data safety: collects phone number or email (sign-in), name, and what admins enter; nothing shared, nothing sold, encrypted in transit, deletion at https://kuree.skifi.co/delete-account.
   - Financial features: Kuree only keeps records; it does not move money.

## 4. iPhone

On the Mac, with Xcode and Flutter:

1. `cd app && flutter pub get && open ios/Runner.xcworkspace`
2. Runner > Signing & Capabilities: pick your team. Bundle id `co.skifi.kuree`.
3. App Store Connect > New app: Kuree, bundle id `co.skifi.kuree`, SKU `kuree`.
4. Back in the terminal: `flutter build ipa`, then open `build/ios/archive/Runner.xcarchive` and Distribute App > App Store Connect. Or Product > Archive in Xcode.
5. TestFlight first, then submit. Privacy policy URL and the review account as below. Encryption: the app only uses standard HTTPS (already set in Info.plist).

## 5. The review account

Both stores need a way in without a WhatsApp code. Make an email account with a password once (an address you can open, for example review@skifi.co):

```
curl -X POST https://kuree.skifi.co/auth/v1/signup -H 'apikey: public' -H 'content-type: application/json' \
  -d '{"email":"review@skifi.co","password":"choose-a-long-one"}'
```

Confirm the email it sends, sign in once in the app with Email > Use a password, and make a sample kuri. Give that email and password to both stores.

## 6. Store listing

- Name: Kuree. Icon: `app/assets/brand/icon.png` (1024 x 1024).
- Screenshots: the `screens` branch has a picture of every screen after each build (phone size).
- Support email: contact@skifi.co. Website: https://kuree.skifi.co
