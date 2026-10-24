// Brings the Boystown 5K Kuri over from boystown.skifi.co, once.
//
// Reads the live kuri and the Members list from the Boystown site (both are
// public there), turns them into a Kuree kuri with the same slot ids (so
// every payment and fine carries over as it is) and each person's WhatsApp
// number for reminders, then saves it as the signed-in person. The database
// decides who may do this (Ishaque only) and refuses a second import.

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

const API = (Deno.env.get('SUPABASE_URL') ?? 'http://127.0.0.1:8000').replace(/\/$/, '');
// Inside Dokploy the Boystown API answers on the shared network; the public
// site is the fallback.
const SOURCES = [Deno.env.get('BOYSTOWN_URL'), 'http://boystown-api:8000', 'https://boystown.skifi.co']
  .filter((u): u is string => !!u)
  .map((u) => u.replace(/\/$/, ''));

// Who is in the 5K Kuri, slot by slot (assets/kuri-roster.js on the Boystown site).
const ROSTER: [string, number, string, number][] = [
  ['p1', 1, 'Nazil', 5000], ['p2', 2, 'Nazil', 5000], ['p3', 3, 'Ramshad Ac', 5000],
  ['p4', 4, 'Anees Muhammed', 5000], ['p5', 5, 'Ishaque', 5000], ['p6', 6, 'Ashif', 5000],
  ['p7', 7, 'Muhajir', 5000], ['p8', 8, 'Sinan KP', 5000], ['p9', 9, 'Naif', 5000],
  ['p10a', 10, 'Farhan', 2500], ['p10b', 10, 'Yasir', 2500], ['p11', 11, 'Anwar', 5000],
  ['p12', 12, 'Mufaz', 5000], ['p13', 13, 'Mufaz', 5000],
];
// The Boystown admin who runs the draws.
const ADMINS = ['Anees Muhammed'];

const key = (n: unknown) => String(n ?? '').toLowerCase().replace(/\s+/g, ' ').trim();
const digits = (p: unknown) => String(p ?? '').replace(/[^0-9]/g, '');

async function readBoystown(): Promise<Record<string, any>> {
  let last = '';
  for (const base of SOURCES) {
    try {
      const r = await fetch(`${base}/rest/v1/docs?select=key,data&key=in.(kuri5k,members)`, {
        headers: { apikey: 'public', Accept: 'application/json' },
        signal: AbortSignal.timeout(8000),
      });
      if (!r.ok) { last = `${base} ${r.status}`; continue; }
      const rows = await r.json() as { key: string; data: any }[];
      const docs = Object.fromEntries(rows.map((d) => [d.key, d.data]));
      if (docs.kuri5k?.months) return docs;
      last = `${base}: no kuri`;
    } catch (e) {
      last = `${base}: ${(e as Error).message}`;
    }
  }
  throw new Error(last || 'Boystown did not answer');
}

export function convert(kuri: any, members: any[]): Record<string, unknown> {
  const phones = new Map<string, string>();
  for (const m of members ?? []) if (m?.name && digits(m.phone).length >= 8) phones.set(key(m.name), digits(m.phone));
  const people: { id: string; name: string; phone?: string }[] = [];
  const idOf = new Map<string, string>();
  for (const [, , name] of ROSTER) {
    if (idOf.has(key(name))) continue;
    const id = `m${people.length + 1}`;
    idOf.set(key(name), id);
    const phone = phones.get(key(name));
    people.push(phone ? { id, name, phone } : { id, name });
  }
  const payers = ROSTER.map(([id, slot, name, amt]) => ({ id, slot, person: idOf.get(key(name))!, amt }));
  const slots = Number(kuri.slots) || 13;
  const months = (kuri.months ?? []).slice(0, slots).map((m: any, i: number) => {
    const out: Record<string, unknown> = {
      n: i + 1,
      winner: Number(m.winner) > 0 ? Number(m.winner) : null,
      paid: Object.fromEntries(Object.entries(m.paid ?? {}).filter(([, v]) => v === true)),
      fines: Object.fromEntries(Object.entries(m.fines ?? {}).filter(([, v]) => v === true)),
      note: String(m.note ?? ''),
    };
    if (m.draw && typeof m.draw === 'object') out.draw = m.draw;
    return out;
  });
  return {
    v: 1,
    source: 'boystown-5k',
    name: '5K Kuri',
    group: 'Boystown',
    share: Number(kuri.share) || 5000,
    slots,
    startYear: Number(kuri.startYear) || 2026,
    startMonth: Number(kuri.startMonth) || 6,
    collectDay: 20,
    lastDay: 25,
    fine: Number(kuri.fine) || 200,
    groupLang: 'ml',
    people,
    payers,
    months,
    updated: new Date().toISOString().slice(0, 10),
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
  if (req.method !== 'POST') return json({ message: 'Use POST.' }, 405);
  const auth = req.headers.get('Authorization') ?? '';
  if (!/^Bearer\s+\S+/.test(auth) || /^Bearer\s+public$/.test(auth)) return json({ message: 'Sign in first.' }, 401);
  const headers = { Authorization: auth, 'Content-Type': 'application/json', apikey: 'public' };
  const rpc = async (fn: string, body: unknown) => {
    const r = await fetch(`${API}/rest/v1/rpc/${fn}`, { method: 'POST', headers, body: JSON.stringify(body) });
    const j = await r.json().catch(() => null);
    if (!r.ok) throw Object.assign(new Error(j?.message ?? `${fn} ${r.status}`), { status: r.status });
    return j;
  };

  let docs: Record<string, any>;
  try {
    docs = await readBoystown();
  } catch (e) {
    console.error('import-boystown read', (e as Error).message);
    return json({ message: 'The Boystown site did not answer. Try again in a minute.' }, 502);
  }
  const members = docs.members?.members ?? [];
  try {
    const ishaque = members.find((m: any) => key(m?.name) === 'ishaque');
    if (ishaque?.phone) await rpc('note_boystown_owner_phone', { phone: digits(ishaque.phone) });
    const me = await rpc('whoami', {});
    if (!me?.can_import_boystown) return json({ message: 'Only the Boystown owner can bring this kuri in, once.' }, 403);
    const admins = ADMINS
      .map((n) => members.find((m: any) => key(m?.name) === key(n)))
      .filter((m: any) => m && digits(m.phone).length >= 8)
      .map((m: any) => ({ name: m.name, phone: digits(m.phone) }));
    const kuri = await rpc('import_boystown', { data: convert(docs.kuri5k, members), admins });
    return json({ kuri });
  } catch (e) {
    const status = (e as { status?: number }).status ?? 500;
    return json({ message: (e as Error).message || 'The import did not finish. Try again.' }, status >= 400 && status < 600 ? status : 500);
  }
});
