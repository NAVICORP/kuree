/*
 * Mails each new feature request to the Kuree team (FEATURE_MAIL_TO, by
 * default ishaque@skifi.co), then stamps it emailed_at
 * (supabase/migrations/0007_feature_mail.sql). Runs inside the push sender.
 *
 * Mail goes out through SMTP, the same settings the SkiFi login (SkAuth)
 * uses: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS and SMTP_FROM. Without
 * SMTP_HOST it sends nothing and leaves the requests waiting, so they all
 * go once it is set. Uses the `nodemailer` package the app base image has.
 */
import { createRequire } from 'node:module';

const log = (...a) => console.log(new Date().toISOString(), ...a);
const IMPORTANCE = { nice: 'Nice to have', important: 'Important', must: 'Must have' };

/** The subject and plain text of the mail for one request. */
export function mailFor(r) {
  const who = [r.name, r.email, r.phone].filter(Boolean).join(', ') || 'someone signed out';
  const where = [r.platform, r.app_version, r.language].filter(Boolean).join(' ');
  const lines = [
    r.title,
    '',
    r.details || '(no details)',
    '',
    `From: ${who}`,
    r.importance ? `How important: ${IMPORTANCE[r.importance] || r.importance}` : '',
    where ? `App: ${where}` : '',
    `Sent: ${new Date(r.created_at).toISOString().replace('T', ' ').slice(0, 16)} UTC`,
    '',
    'Reply to them and set its status in the Kuree app: Profile > Feature requests.',
  ].filter((l, i, a) => l !== '' || (i > 0 && a[i - 1] !== ''));
  const short = r.title.length > 70 ? `${r.title.slice(0, 67)}...` : r.title;
  return { subject: `Kuree feature request: ${short}`, text: lines.join('\n') };
}

let transport = null;
let warned = false;

function mailer() {
  if (transport) return transport;
  const host = (process.env.SMTP_HOST || '').trim();
  if (!host) return null;
  const nodemailer = createRequire(process.env.PG_FROM || '/srv/backend/api/package.json')('nodemailer');
  const port = Number(process.env.SMTP_PORT || 587);
  transport = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: process.env.SMTP_USER ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS || '' } : undefined,
  });
  return transport;
}

/** Mails what waits, a few at a time. */
export async function mailRound(db) {
  const t = mailer();
  if (!t) {
    if (!warned) log('feature mail: SMTP_HOST is not set; requests wait until it is');
    warned = true;
    return;
  }
  const to = (process.env.FEATURE_MAIL_TO || 'ishaque@skifi.co').trim();
  const from = (process.env.SMTP_FROM || 'Kuree <account@skifi.co>').trim();
  const { rows } = await db.query(
    `select id, name, email, phone, title, details, importance, app_version, platform, language, created_at
       from public.feature_requests where emailed_at is null order by id limit 10`);
  for (const r of rows) {
    const m = mailFor(r);
    try {
      await t.sendMail({ from, to, subject: m.subject, text: m.text, replyTo: r.email || undefined });
      await db.query('update public.feature_requests set emailed_at = now() where id = $1', [r.id]);
      log(`feature mail: sent request ${r.id}`);
    } catch (e) {
      log(`feature mail: request ${r.id} not sent: ${e.message}`);
      return;
    }
  }
}
