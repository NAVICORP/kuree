// Checks the push words and the Firebase calls without the network:
//   node --test server/push_test.mjs
import assert from 'node:assert/strict';
import { createVerify, generateKeyPairSync } from 'node:crypto';
import test from 'node:test';

import { accessToken, message, send, serviceAccount } from './push.mjs';
import { TEXT, words } from './push_text.mjs';

const holes = (s) => [...s.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort().join(',');

test('every language has every message, with the same blanks, and keeps the copy rules', () => {
  for (const [lang, t] of Object.entries(TEXT)) {
    assert.deepEqual(Object.keys(t).sort(), Object.keys(TEXT.en).sort(), lang);
    for (const [k, v] of Object.entries(t)) {
      assert.equal(holes(v), holes(TEXT.en[k]), `${lang}.${k}`);
      assert.ok(!v.includes('—') && !v.includes('·'), `${lang}.${k} has an em dash or a middle dot`);
    }
  }
  for (const v of Object.values(TEXT.en)) assert.ok(!/\bkuris?\b/i.test(v), v);
  assert.deepEqual(Object.keys(TEXT).sort(), ['ar', 'en', 'hi', 'kn', 'ml', 'ta']);
});

test('one person by name, more as a count, a draw without names by slot', () => {
  const a = { chit: 'Riverside 5K Chit', by: 'Ishaque' };
  assert.deepEqual(words('paid', { ...a, n: 1, who: 'Nazil' }, 'en'), { title: 'Riverside 5K Chit', body: 'Ishaque marked Nazil paid' });
  assert.equal(words('unpaid', { ...a, n: 3 }, 'en').body, 'Ishaque marked 3 payments not paid');
  assert.equal(words('late', { ...a, n: 2, who: 'Mufaz' }, 'en').body, 'Ishaque marked 2 payments late');
  assert.equal(words('draw', { ...a, m: 5, slot: 2, who: 'Farhan / Yasir' }, 'en').body, 'Month 5: Farhan / Yasir takes the pot');
  assert.equal(words('draw', { ...a, m: 5, slot: 2 }, 'en').body, 'Month 5: slot 2 takes the pot');
  assert.equal(words('admin_added', a, 'ml').body, 'Ishaque നിങ്ങളെ അഡ്മിനായി ചേർത്തു');
  assert.equal(words('paid', { chit: 'C', n: 1, who: 'X' }, 'zz').body, 'Kuree marked X paid');
});

test('the message opens the chit and uses the app\'s channel and icon', () => {
  const m = message({ token: 'tok', lang: 'hi' }, { kuri_id: 'k-1', kind: 'admin_added', args: { chit: 'C', by: 'A' } });
  assert.equal(m.token, 'tok');
  assert.deepEqual(m.data, { kuri: 'k-1', kind: 'admin_added' });
  assert.equal(m.android.notification.channel_id, 'updates');
  assert.equal(m.android.notification.icon, 'ic_stat_kuree');
  assert.equal(m.notification.body, 'A ने आपको एडमिन बनाया');
});

test('no service account, no push', () => {
  assert.equal(serviceAccount(''), null);
  assert.throws(() => serviceAccount('{"client_email":"x"}'));
});

test('signs in to Google with the service account, sends, and spots phones that are gone', async () => {
  const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const sa = serviceAccount(Buffer.from(JSON.stringify({
    client_email: 'push@skifi.iam.gserviceaccount.com', project_id: 'skifi-test',
    private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
  })).toString('base64'));
  const calls = [];
  const real = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    calls.push({ url: String(url), init });
    if (String(url).includes('oauth2')) {
      const jwt = new URLSearchParams(init.body.toString()).get('assertion').split('.');
      const ok = createVerify('RSA-SHA256').update(`${jwt[0]}.${jwt[1]}`).verify(publicKey, Buffer.from(jwt[2], 'base64url'));
      const claims = JSON.parse(Buffer.from(jwt[1], 'base64url'));
      assert.ok(ok, 'the assertion is signed with the key');
      assert.equal(claims.scope, 'https://www.googleapis.com/auth/firebase.messaging');
      return new Response(JSON.stringify({ access_token: 'at', expires_in: 3600 }), { status: 200 });
    }
    const body = JSON.parse(init.body);
    if (body.message.token === 'gone') {
      return new Response(JSON.stringify({ error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] } }), { status: 404 });
    }
    if (body.message.token === 'busy') return new Response('{}', { status: 503 });
    return new Response('{}', { status: 200 });
  };
  try {
    assert.equal(await accessToken(sa), 'at');
    assert.equal(await send(sa, { token: 'ok' }), 'sent');
    assert.equal(await send(sa, { token: 'gone' }), 'gone');
    assert.equal(await send(sa, { token: 'busy' }), 'retry');
    const fcm = calls.filter((c) => c.url.includes('fcm.googleapis.com'));
    assert.equal(fcm[0].url, 'https://fcm.googleapis.com/v1/projects/skifi-test/messages:send');
    assert.equal(fcm[0].init.headers.authorization, 'Bearer at');
    assert.equal(calls.filter((c) => c.url.includes('oauth2')).length, 1, 'the Google token is reused');
  } finally {
    globalThis.fetch = real;
  }
});
