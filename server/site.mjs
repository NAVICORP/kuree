/*
 * kuree.skifi.co: the members' pages, the spreadsheets, the plain pages, and
 * the door to the Kuree API.
 *
 * /k/<token>              a kuri as its members see it (read only, no numbers)
 * /k/<token>/report.xlsx  the same kuri as a spreadsheet, made fresh when it changes
 * /, /privacy, /terms, /delete-account
 * /rest/v1, /auth/v1, /functions/v1, /storage/v1, /platform  passed to the API
 *
 * Plain Node, no packages. Text goes out compressed (brotli or gzip).
 */
import { createServer } from 'node:http';
import { existsSync, mkdirSync, readFileSync, renameSync, statSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { Readable } from 'node:stream';
import zlib from 'node:zlib';

const ROOT = path.resolve(process.env.SITE_ROOT || path.join(import.meta.dirname, '..', 'web'));
const API = (process.env.API_INTERNAL || 'http://kuree-api:8000').replace(/\/$/, '');
const PORT = Number(process.env.PORT || 8000);
const TOOLS = path.resolve(process.env.TOOLS_DIR || path.join(import.meta.dirname, '..', 'tools'));
const CACHE = process.env.XLSX_CACHE || '/tmp/kuree-xlsx';
const ORIGIN = (process.env.SITE_URL || 'https://kuree.skifi.co').replace(/\/$/, '');

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8',
  '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp',
  '.ico': 'image/x-icon', '.woff2': 'font/woff2', '.txt': 'text/plain; charset=utf-8',
  '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
};
const TEXT = new Set(['.html', '.js', '.css', '.json', '.svg', '.txt']);
const API_PATHS = /^\/(rest|auth|functions|storage)\/v1(\/|$)|^\/platform\//;
const TOKEN = /^\/k\/([A-Za-z0-9_-]{16,64})(\/report\.xlsx)?\/?$/;
const SECURITY = {
  'x-content-type-options': 'nosniff',
  'referrer-policy': 'strict-origin-when-cross-origin',
  'x-frame-options': 'DENY',
  'permissions-policy': 'camera=(), microphone=(), geolocation=()',
};
const CSP = "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; " +
  "connect-src 'self'; font-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'";

// ---------------------------------------------------------------- small helpers

const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const read = (rel) => readFileSync(path.join(ROOT, rel), 'utf8');
const ordinal = (n) => {
  const m = n % 100;
  if (m >= 11 && m <= 13) return `${n}th`;
  return `${n}${['th', 'st', 'nd', 'rd'][n % 10] || 'th'}`;
};
const groupDigits = (n) => {
  let s = String(Math.round(Math.abs(Number(n) || 0)));
  if (s.length > 3) {
    const last = s.slice(-3); let rest = s.slice(0, -3); const parts = [];
    while (rest.length > 2) { parts.unshift(rest.slice(-2)); rest = rest.slice(0, -2); }
    if (rest) parts.unshift(rest);
    s = `${parts.join(',')},${last}`;
  }
  return s;
};
const money = (n) => `₹${groupDigits(n)}`;

function encodingFor(req) {
  const a = String(req.headers['accept-encoding'] || '');
  return /\bbr\b/.test(a) ? 'br' : /\bgzip\b/.test(a) ? 'gzip' : null;
}
function squeeze(buf, enc, best) {
  return enc === 'br'
    ? zlib.brotliCompressSync(buf, { params: { [zlib.constants.BROTLI_PARAM_QUALITY]: best ? 11 : 5, [zlib.constants.BROTLI_PARAM_SIZE_HINT]: buf.length } })
    : zlib.gzipSync(buf, { level: best ? 9 : 6 });
}

/* Pages link /assets files with ?v=<hash of the file>, written in as each
   page goes out, so browsers can keep assets for a year and still pick up
   a change straight away. */
const ver = new Map();
function verOf(rel) {
  const f = path.join(ROOT, rel);
  let st;
  try { st = statSync(f); } catch { return null; }
  const hit = ver.get(rel);
  if (hit && hit.m === st.mtimeMs) return hit.v;
  const v = createHash('sha1').update(readFileSync(f)).digest('hex').slice(0, 8);
  ver.set(rel, { m: st.mtimeMs, v });
  return v;
}
const stampAssets = (html) => html.replace(/(href|src)="(\/assets\/[\w./-]+\.(?:js|css|png|woff2))"/g, (all, attr, rel) => {
  const v = verOf(rel);
  return v ? `${attr}="${rel}?v=${v}"` : all;
});

function sendBody(req, res, status, type, body, extra = {}) {
  const buf = Buffer.isBuffer(body) ? body : Buffer.from(body);
  const ext = Object.entries(TYPES).find(([, t]) => t === type)?.[0] ?? '';
  const enc = TEXT.has(ext) && buf.length > 1024 ? encodingFor(req) : null;
  const out = enc ? squeeze(buf, enc, false) : buf;
  res.writeHead(status, {
    ...SECURITY,
    'content-type': type,
    'content-length': String(out.length),
    ...(TEXT.has(ext) ? { vary: 'accept-encoding' } : {}),
    ...(enc ? { 'content-encoding': enc } : {}),
    ...extra,
  });
  res.end(req.method === 'HEAD' ? undefined : out);
}

const packed = new Map();
function sendFile(req, res, file, cache) {
  const ext = path.extname(file).toLowerCase();
  const st = statSync(file);
  const enc = TEXT.has(ext) && st.size > 1024 ? encodingFor(req) : null;
  let body;
  if (enc) {
    const key = `${enc}:${file}`;
    const hit = packed.get(key);
    if (hit && hit.m === st.mtimeMs) body = hit.body;
    else { body = squeeze(readFileSync(file), enc, true); packed.set(key, { m: st.mtimeMs, body }); }
  } else body = readFileSync(file);
  res.writeHead(200, {
    ...SECURITY,
    'content-type': TYPES[ext] || 'application/octet-stream',
    'content-length': String(body.length),
    'cache-control': cache,
    ...(TEXT.has(ext) ? { vary: 'accept-encoding' } : {}),
    ...(enc ? { 'content-encoding': enc } : {}),
  });
  res.end(req.method === 'HEAD' ? undefined : body);
}

/** A plain page (home, privacy, terms) in the Kuree shell. */
function shell(title, body, { home = false } = {}) {
  return stampAssets(`<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>${esc(title)}</title>
<meta name="description" content="Kuree: run your kuri from your phone.">
<meta name="theme-color" content="#FAFAF5">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="apple-touch-icon" href="/assets/brand/touch-180.png">
<meta property="og:title" content="${esc(title)}">
<meta property="og:image" content="${ORIGIN}/assets/brand/og.png">
<link rel="stylesheet" href="/assets/app.css">
<link rel="stylesheet" href="/assets/site.css">
<link rel="stylesheet" href="/assets/kuree.css">
</head>
<body>
<main class="kpage">
${home ? '' : '<a class="kpage__top" href="/"><img src="/assets/brand/icon-64.png" alt="" width="36" height="36">Kuree</a>'}
${body}
</main>
<footer class="kfoot"><p><a href="/privacy">Privacy</a> &nbsp; <a href="/terms">Terms</a> &nbsp; <a href="/delete-account">Delete an account</a></p><p>Made by <a href="https://skifi.co" target="_blank" rel="noopener">SkiFi</a></p></footer>
</body>
</html>`);
}

const PAGES = {
  '/': ['Kuree', 'pages/home.html', true],
  '/privacy': ['Privacy | Kuree', 'pages/privacy.html'],
  '/terms': ['Terms | Kuree', 'pages/terms.html'],
  '/delete-account': ['Deleting an account | Kuree', 'pages/delete-account.html'],
};

// ---------------------------------------------------------------- a kuri from its link

async function sharedKuri(token) {
  const r = await fetch(`${API}/rest/v1/rpc/shared_kuri`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', apikey: 'public', accept: 'application/json' },
    body: JSON.stringify({ token }),
  });
  if (!r.ok) throw new Error(`shared_kuri ${r.status}`);
  const j = await r.json();
  return j && j.data ? j : null;
}

function kuriPage(token, k) {
  const d = k.data;
  const group = String(d.group || '').trim();
  const name = String(d.name || 'Kuri').trim();
  const cd = Number(d.collectDay) || 20, ld = Number(d.lastDay) || 25, fine = Number(d.fine) || 0;
  const lead = `Collection on the ${ordinal(cd)} of every month.<br>Pay by midnight on the ${ordinal(ld)}${ld < cd ? ' of the next month' : ''}` +
    (fine ? `, ${esc(money(fine))} fine after that.` : '.');
  const seed = JSON.stringify({ data: d, updated_at: k.updated_at, token })
    .replace(/</g, '\\u003c').replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029');
  const title = group ? `${group} ${name}` : name;
  const fill = {
    TITLE: esc(title),
    DESC: esc('Who has paid, who took the pot, fines and what is still open.'),
    GROUP: esc(group),
    NAME: esc(name),
    LEAD: lead,
    REPORT: `/k/${token}/report.xlsx`,
    UPDATED: '',
    ORIGIN,
    SEED: seed,
  };
  return stampAssets(read('k.html')).replace(/\{\{(\w+)\}\}/g, (all, k2) => (k2 in fill ? fill[k2] : all));
}

const making = new Map();
function makeSheet(doc, file) {
  mkdirSync(CACHE, { recursive: true });
  const part = `${file}.${process.pid}.part`;
  return new Promise((ok, bad) => {
    const py = spawn('python3', [path.join(TOOLS, 'xlsx.py'), part], { stdio: ['pipe', 'inherit', 'inherit'] });
    const t = setTimeout(() => py.kill('SIGKILL'), 30000);
    py.on('error', (e) => { clearTimeout(t); bad(e); });
    py.on('exit', (code) => {
      clearTimeout(t);
      if (code !== 0) return bad(new Error(`xlsx.py exited ${code}`));
      renameSync(part, file);
      ok();
    });
    py.stdin.end(JSON.stringify(doc));
  });
}

async function report(req, res, token, k) {
  const tag = createHash('sha1').update(`${token}|${k.updated_at}`).digest('hex').slice(0, 20);
  const file = path.join(CACHE, `${tag}.xlsx`);
  if (!existsSync(file)) {
    if (!making.has(file)) making.set(file, makeSheet(k.data, file).finally(() => making.delete(file)));
    await making.get(file);
  }
  const d = k.data;
  const base = `${d.group || ''} ${d.name || 'kuri'}`.trim().replace(/[^A-Za-z0-9]+/g, '-').replace(/^-|-$/g, '').toLowerCase() || 'kuri';
  res.writeHead(200, {
    ...SECURITY,
    'content-type': TYPES['.xlsx'],
    'cache-control': 'no-store',
    'x-robots-tag': 'noindex, nofollow',
    'content-disposition': `attachment; filename="${base}.xlsx"`,
  });
  res.end(req.method === 'HEAD' ? undefined : readFileSync(file));
}

// ---------------------------------------------------------------- the API

const HOP = new Set(['connection', 'keep-alive', 'proxy-connection', 'transfer-encoding', 'upgrade', 'te', 'trailer', 'host', 'content-length']);
async function proxy(req, res) {
  const headers = new Headers();
  for (const [k, v] of Object.entries(req.headers)) {
    if (HOP.has(k) || v == null) continue;
    headers.set(k, Array.isArray(v) ? v.join(', ') : v);
  }
  headers.set('x-forwarded-for', String(req.headers['x-forwarded-for'] || req.socket.remoteAddress || ''));
  headers.set('x-forwarded-proto', String(req.headers['x-forwarded-proto'] || 'https'));
  headers.set('x-forwarded-host', String(req.headers.host || ''));
  const hasBody = !['GET', 'HEAD'].includes(req.method);
  let up;
  try {
    up = await fetch(API + req.url, {
      method: req.method, headers, redirect: 'manual',
      body: hasBody ? Readable.toWeb(req) : undefined,
      duplex: hasBody ? 'half' : undefined,
    });
  } catch (e) {
    console.error('api unreachable', e.message);
    res.writeHead(502, { 'content-type': 'application/json' });
    return res.end('{"message":"The Kuree server is starting up. Try again in a moment."}');
  }
  const out = {};
  up.headers.forEach((v, k) => { if (!HOP.has(k) && k !== 'content-encoding') out[k] = v; });
  const len = up.headers.get('content-length');
  const enc = /json|text/.test(up.headers.get('content-type') || '') && !(len != null && Number(len) < 1024) ? encodingFor(req) : null;
  if (enc) {
    delete out['content-length'];
    out['content-encoding'] = enc;
    out.vary = out.vary ? `${out.vary}, accept-encoding` : 'accept-encoding';
  }
  res.writeHead(up.status, out);
  if (!up.body || req.method === 'HEAD') return res.end();
  const from = Readable.fromWeb(up.body);
  if (!enc) return from.pipe(res);
  const z = enc === 'br' ? zlib.createBrotliCompress({ params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 4 } }) : zlib.createGzip({ level: 5 });
  from.pipe(z).pipe(res);
}

// ---------------------------------------------------------------- the server

function notFound(req, res, kuri = false) {
  const body = kuri ? read('pages/gone.html') : '<div class="kgone"><h1>Nothing here</h1><p><a href="/">Kuree</a></p></div>';
  sendBody(req, res, 404, TYPES['.html'], shell(kuri ? 'Link no longer works | Kuree' : 'Not found | Kuree', body, { home: kuri }),
    { 'cache-control': 'no-store', 'x-robots-tag': 'noindex', 'content-security-policy': CSP });
}

async function handle(req, res) {
  const url = new URL(req.url, 'http://x');
  const p = url.pathname;
  if (p === '/health') return sendBody(req, res, 200, TYPES['.json'], '{"ok":true}', { 'cache-control': 'no-store' });
  if (API_PATHS.test(p)) return proxy(req, res);
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, { allow: 'GET, HEAD' });
    return res.end();
  }

  const t = p.match(TOKEN);
  if (t) {
    let k;
    try {
      k = await sharedKuri(t[1]);
    } catch (e) {
      console.error('shared kuri', e.message);
      return sendBody(req, res, 503, TYPES['.html'], shell('Kuree', '<div class="kgone"><h1>One moment</h1><p>The kuri could not be loaded just now. Try again in a minute.</p></div>', { home: true }),
        { 'cache-control': 'no-store', 'retry-after': '30' });
    }
    if (!k) return notFound(req, res, true);
    if (t[2]) {
      try {
        return await report(req, res, t[1], k);
      } catch (e) {
        console.error('report', e.message);
        return sendBody(req, res, 503, TYPES['.txt'], 'The spreadsheet could not be made just now. Try again in a minute.', { 'cache-control': 'no-store' });
      }
    }
    return sendBody(req, res, 200, TYPES['.html'], kuriPage(t[1], k), {
      'cache-control': 'no-store',
      'x-robots-tag': 'noindex, nofollow',
      'referrer-policy': 'no-referrer',
      'content-security-policy': CSP,
    });
  }

  const page = PAGES[p.replace(/\/$/, '') || '/'];
  if (page) {
    return sendBody(req, res, 200, TYPES['.html'], shell(page[0], read(page[1]), { home: !!page[2] }),
      { 'cache-control': 'public, max-age=300', 'content-security-policy': CSP });
  }
  if (p === '/robots.txt') return sendBody(req, res, 200, TYPES['.txt'], 'User-agent: *\nDisallow: /k/\n', { 'cache-control': 'public, max-age=3600' });
  if (p === '/favicon.ico') return sendFile(req, res, path.join(ROOT, 'favicon.ico'), 'public, max-age=86400');
  if (p.startsWith('/assets/')) {
    let rel;
    try { rel = decodeURIComponent(p); } catch { return notFound(req, res); }
    const f = path.resolve(ROOT, `.${rel}`);
    if (!f.startsWith(path.join(ROOT, 'assets') + path.sep) || !existsSync(f) || !statSync(f).isFile()) return notFound(req, res);
    return sendFile(req, res, f, url.searchParams.has('v') ? 'public, max-age=31536000, immutable' : 'public, max-age=3600');
  }
  return notFound(req, res);
}

createServer((req, res) => {
  handle(req, res).catch((e) => {
    console.error('request failed', req.url, e);
    if (!res.headersSent) res.writeHead(500, { 'content-type': 'text/plain' });
    res.end('Something went wrong.');
  });
}).listen(PORT, () => console.log(`kuree site on :${PORT}, api ${API}`));
