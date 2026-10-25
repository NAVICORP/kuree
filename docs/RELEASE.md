# Putting Kuree on the stores

## 1. The server (once)

1. **SkAuth knows Kuree.** On the SkAuth service in Dokploy, add Kuree to `SKAUTH_APPS`:
   `{"id":"kuree","name":"Kuree","site":"https://kuree.skifi.co","api":"https://kuree.skifi.co","color":"#032A09"}`
   and redeploy SkAuth. (SkAuth knows Kuree by its first address, kuree.skifi.co; members and admins only see kureeapp.com.)
2. **Dokploy compose.** New compose `kuree` from GitHub `NAVICORP/kuree`, branch `main`, compose path `./deploy/docker-compose.yml`. Domains `kureeapp.com`, `www.kureeapp.com` and `kuree.skifi.co` to service `site`, port 8000, HTTPS on. Deploy.
3. **DNS.** kureeapp.com is on Cloudflare: A records for `@` and `www` to the VPS (179.198.218.204). The old `kuree` record on skifi.co stays, so links already shared still work; the site moves them to kureeapp.com.
4. Open https://kureeapp.com/health. It says `{"ok":true}`.
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
   - Privacy policy: https://kureeapp.com/privacy
   - App access: give the review account (section 5).
   - Ads: none. Data safety: collects phone number or email (sign-in), name, and what admins enter; nothing shared, nothing sold, encrypted in transit, deletion at https://kureeapp.com/delete-account.
   - Financial features: Kuree only keeps records; it does not move money.
7. **Updates.** Raise `version:` in `app/pubspec.yaml` (1.0.1, 1.0.2, ...) in the PR. The version code is the App run number, so every build on main is higher than the last. After the merge, the App run on main builds the bundle. Then Actions > Google Play drafts > Run workflow saves the bundle, the release notes, the pictures and the listing text as drafts (setup in [STORE.md](STORE.md), "Publishing from GitHub"). Check them in Play Console and press Send changes for review on the Publishing overview. Don't send while an earlier release is still in review: Google may put the app at the back of the review queue.

## 4. iPhone

No Mac needed: GitHub Actions builds the app and uploads it to TestFlight. The step-by-step plan is in [IOS-LAUNCH.md](IOS-LAUNCH.md), and every App Store Connect field is in [APPSTORE.md](APPSTORE.md).

## 5. The review account

Both stores need a way in without a WhatsApp code. Make an email account with a password once (an address you can open, for example review@skifi.co):

```
curl -X POST https://kureeapp.com/auth/v1/signup -H 'apikey: public' -H 'content-type: application/json' \
  -d '{"email":"review@skifi.co","password":"choose-a-long-one"}'
```

Confirm the email it sends, sign in once in the app with Email > Use a password, and make a sample chit. Give that email and password to both stores.

## 6. Store listing

- Name: Kuree. Icon: `app/assets/brand/icon.png` (1024 x 1024).
- Screenshots: the `screens` branch has a picture of every screen after each build (phone size).
- Support email: contact@skifi.co. Website: https://kureeapp.com
