/*
 * Kuree's push sender: sends what waits in push_outbox (see
 * supabase/migrations/0005_push.sql) to the admins' phones through Firebase
 * Cloud Messaging (HTTP v1), then marks it sent.
 *
 * Runs as its own service (deploy/docker-compose.yml, service `push`), with
 * the database password from the stack's secrets and the Firebase service
 * account in FIREBASE_SERVICE_ACCOUNT_JSON (the JSON key file, plain or
 * base64). Without that variable it sends nothing: lines are marked sent so
 * nothing piles up, and it says so once in the log.
 *
 * Wakes on the database's kuree_push notice after each save, and once a
 * minute anyway. Plain Node, plus the `pg` package the app base image has.
 */
import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';

import { mailRound } from './feature_mail.mjs';
import { words } from './push_text.mjs';

const SECRETS = process.env.SECRETS_DIR || '/secrets';
const secret = (name) => {
  try {
    return readFileSync(`${SECRETS}/${name}`, 'utf8').trim();
  } catch {
    return '';
  }
};
const DB_URL = process.env.DATABASE_URL ||
  `postgres://postgres:${encodeURIComponent(process.env.DB_PASSWORD || secret('db_password'))}@${process.env.DB_HOST || 'db'}:5432/${process.env.DB_NAME || 'kuree'}`;
const EVERY_MS = 60_000;
const BATCH = 100;

const log = (...a) => console.log(new Date().toISOString(), ...a);

// ---------------------------------------------------------------- Firebase

/** The service account, or null when push is not set up. */
export function serviceAccount(raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '') {
  const text = raw.trim();
  if (!text) return null;
  const json = text.startsWith('{') ? text : Buffer.from(text, 'base64').toString('utf8');
  const sa = JSON.parse(json);
  if (!sa.client_email || !sa.private_key || !sa.project_id) throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is missing client_email, private_key or project_id');
  return sa;
}

const b64url = (v) => Buffer.from(typeof v === 'string' ? v : JSON.stringify(v)).toString('base64url');

let access = { token: '', until: 0 };
export async function accessToken(sa) {
  if (access.token && Date.now() < access.until - 60_000) return access.token;
  const now = Math.floor(Date.now() / 1000);
  const aud = sa.token_uri || 'https://oauth2.googleapis.com/token';
  const head = b64url({ alg: 'RS256', typ: 'JWT' });
  const body = b64url({ iss: sa.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging', aud, iat: now, exp: now + 3600 });
  const sig = createSign('RSA-SHA256').update(`${head}.${body}`).sign(sa.private_key).toString('base64url');
  const r = await fetch(aud, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${head}.${body}.${sig}` }),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || !j.access_token) throw new Error(`Google sign-in for Firebase failed (${r.status}): ${j.error_description || j.error || ''}`);
  access = { token: j.access_token, until: Date.now() + (j.expires_in || 3600) * 1000 };
  return access.token;
}

/** One phone's message, as FCM HTTP v1 takes it. */
export function message(device, line) {
  const w = words(line.kind, line.args || {}, device.lang);
  if (!w) return null;
  return {
    token: device.token,
    notification: { title: w.title, body: w.body },
    // The app opens this chit when the message is tapped.
    data: { kuri: String(line.kuri_id), kind: line.kind },
    android: { priority: 'normal', notification: { channel_id: 'updates', icon: 'ic_stat_kuree', color: '#24592B' } },
    apns: { payload: { aps: { sound: 'default' } } },
  };
}

/** 'sent', 'gone' (the phone no longer has the app: forget it) or 'retry'. */
export async function send(sa, msg) {
  const r = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
    method: 'POST',
    headers: { authorization: `Bearer ${await accessToken(sa)}`, 'content-type': 'application/json' },
    body: JSON.stringify({ message: msg }),
  });
  if (r.ok) return 'sent';
  const j = await r.json().catch(() => ({}));
  const code = (j.error?.details || []).map((d) => d.errorCode).find(Boolean) || j.error?.status || '';
  if (r.status === 404 || code === 'UNREGISTERED' || (r.status === 400 && code === 'INVALID_ARGUMENT' && /token/i.test(j.error?.message || ''))) return 'gone';
  if (r.status === 401) access = { token: '', until: 0 };
  log(`push failed (${r.status} ${code}): ${j.error?.message || ''}`);
  return r.status === 429 || r.status >= 500 ? 'retry' : 'sent';
}

// ---------------------------------------------------------------- the outbox

let sa = null;
let db = null;
let busy = false;
let again = false;

async function round() {
  if (busy) {
    again = true;
    return;
  }
  busy = true;
  try {
    do {
      again = false;
      const { rows } = await db.query(
        'select id, kuri_id, kind, args from public.push_outbox where sent_at is null order by id limit $1', [BATCH]);
      for (const line of rows) {
        if (sa) {
          const { rows: phones } = await db.query('select token, platform, lang from public.push_recipients($1)', [line.id]);
          let retry = false;
          for (const phone of phones) {
            const msg = message(phone, line);
            if (!msg) continue;
            const result = await send(sa, msg).catch((e) => {
              log(`push: ${e.message}`);
              return 'retry';
            });
            if (result === 'gone') await db.query('delete from public.push_devices where token = $1', [phone.token]);
            if (result === 'retry') retry = true;
          }
          // A Google outage: try the whole line again later, unless it is old.
          if (retry) {
            await db.query("update public.push_outbox set sent_at = now() where id = $1 and created_at < now() - interval '1 hour'", [line.id]);
            continue;
          }
        }
        await db.query('update public.push_outbox set sent_at = now() where id = $1', [line.id]);
      }
      if (rows.length === BATCH) again = true;
    } while (again);
  } catch (e) {
    log(`push round: ${e.message}`);
  } finally {
    busy = false;
  }
}

async function tidy() {
  try {
    await db.query("delete from public.push_outbox where sent_at < now() - interval '7 days' or created_at < now() - interval '14 days'");
  } catch (e) {
    log(`push tidy: ${e.message}`);
  }
}

async function listen() {
  try {
    const c = await db.connect();
    c.on('notification', () => round());
    c.on('error', (e) => {
      log(`push listen: ${e.message}`);
      c.release(true);
      setTimeout(listen, 5000);
    });
    await c.query('listen kuree_push');
    log('push: listening');
  } catch (e) {
    log(`push listen: ${e.message}`);
    setTimeout(listen, 5000);
  }
}

export async function main() {
  try {
    sa = serviceAccount();
  } catch (e) {
    log(`push: ${e.message}; nothing will be sent`);
  }
  if (!sa) log('push: FIREBASE_SERVICE_ACCOUNT_JSON is not set; messages are dropped, not sent');
  // `pg` comes with the app base image (its API uses it).
  const pg = createRequire(process.env.PG_FROM || '/srv/backend/api/package.json')('pg');
  db = new pg.Pool({ connectionString: DB_URL, max: 2 });
  db.on('error', (e) => log(`push db: ${e.message}`));
  await listen();
  await round();
  setInterval(round, EVERY_MS);
  // New feature requests go to the team by email.
  const mail = () => mailRound(db).catch((e) => log(`feature mail: ${e.message}`));
  mail();
  setInterval(mail, EVERY_MS);
  setInterval(tidy, 3600_000);
  tidy();
}

if (process.argv[1] === new URL(import.meta.url).pathname) main();
