/* The App Store creative assets: the product page header (3840 x 1646, 21:9)
   and the search results picture (3840 x 2560, 3:2). Kuree green, one short
   line, and the app itself in three phones.

   node tools/store/creative.cjs <folder with the store-*.png app screens> <out folder>

   The app screens come from app/test_screens/store_test.dart (CI puts them
   on the `screens` branch). Needs Playwright with Chromium. Apple wants the
   main subject near the centre, so the phones and the line sit in the middle
   and the sides are only background. */
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const [, , SHOTS = 'shots', OUT = 'store'] = process.argv;
const REPO = path.resolve(__dirname, '..', '..');
const FONTS = path.join(REPO, 'web', 'assets', 'fonts');
const url = (f) => 'file://' + path.resolve(f);

const pick = (name) => {
  for (const n of [name, `${name}-a`, `${name}-b`]) {
    const f = path.join(SHOTS, `store-${n}.png`);
    if (fs.existsSync(f)) return f;
  }
  throw new Error(`missing store-${name}.png in ${SHOTS}`);
};

/* the iPhone status bar: time, signal, wifi, battery */
const BAR = '<div class="bar"><span>9:41</span><span class="sys"><svg viewBox="0 0 18 12"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5.5" width="3" height="6.5" rx="1"/><rect x="10" y="3" width="3" height="9" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg><svg class="wifi" viewBox="0 0 16 12"><path d="M1.4 4.7a9.6 9.6 0 0 1 13.2 0M3.9 7.4a6 6 0 0 1 8.2 0M6.5 10.1a2.3 2.3 0 0 1 3 0" stroke-width="1.9" stroke-linecap="round"/></svg><svg class="bat" viewBox="0 0 27 13"><rect x=".6" y=".6" width="22.8" height="11.8" rx="3.4" fill="none" stroke="currentColor" stroke-opacity=".4" stroke-width="1.2"/><rect x="2.4" y="2.4" width="19.2" height="8.2" rx="2"/><path d="M25 4.4v4.2a2.3 2.3 0 0 0 0-4.2z" opacity=".45"/></svg></span></div>';

/* An iPhone, true to size: screen 430 x 932 points, bezel 3.3 mm, corners 55 pt.
   x is the centre, y the top, w the body width, r a tilt in degrees. */
function phone(shot, { x, y, w, r = 0, z = 1 }) {
  const isDraw = path.basename(shot).startsWith('store-draw');
  const bez = w * 0.0424, scrW = w - bez * 2, scrH = scrW * 932 / 430;
  const inner = scrW * 55 / 430, rad = inner + bez, pt = scrW / 430;
  const h = scrH + bez * 2;
  return `<div class="dev" style="left:${x - w / 2}px;top:${y}px;width:${w}px;height:${h}px;border-radius:${rad}px;padding:${bez}px;z-index:${z};
    transform:rotate(${r}deg);transform-origin:50% 0;
    box-shadow:inset 0 0 0 ${w * 0.0055}px #59625B,inset 0 0 0 ${w * 0.013}px #1D2420,0 0 0 ${w * 0.002}px rgba(0,0,0,.4),0 ${w * 0.06}px ${w * 0.12}px ${-w * 0.03}px rgba(0,0,0,.7)">
    <div class="scr" style="border-radius:${inner}px;background:${isDraw ? '#032A09' : '#F3F5F0'}">
      <img src="${url(shot)}" style="object-fit:${isDraw ? 'cover' : 'fill'}">
      ${BAR.replace('class="bar"', `class="bar" style="height:${59 * pt}px;padding:0 ${31 * pt}px 0 ${46 * pt}px;font-size:${17 * pt}px;color:${isDraw ? '#fff' : '#0F2413'}"`)
        .replace('class="sys"', `class="sys" style="gap:${6 * pt}px"`)
        .replace(/<svg /g, `<svg style="height:${11.5 * pt}px" `)}
      <i class="island" style="top:${11 * pt}px;width:${126 * pt}px;height:${37.3 * pt}px;margin-left:${-63 * pt}px"></i>
    </div></div>`;
}

function page(W, H, title, size, top, phones) {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  @font-face{font-family:"Manrope";font-weight:400 800;src:url(${url(path.join(FONTS, 'manrope.woff2'))}) format("woff2")}
  @font-face{font-family:"Bricolage";font-weight:500 800;src:url(${url(path.join(FONTS, 'bricolage.woff2'))}) format("woff2")}
  *{margin:0;box-sizing:border-box;letter-spacing:0}
  html,body{width:${W}px;height:${H}px;overflow:hidden}
  body{position:relative;color:#fff;font-family:"Manrope",sans-serif;-webkit-font-smoothing:antialiased;
    background:radial-gradient(${W * 0.55}px ${H * 0.9}px at 50% 18%,#1E6A2E 0%,#0A3D14 45%,#032A09 75%,#021A05 100%)}
  .glow{position:absolute;inset:0;background:
    radial-gradient(${W * 0.22}px ${H * 0.5}px at 12% 105%,rgba(255,216,77,.16),transparent 70%),
    radial-gradient(${W * 0.22}px ${H * 0.5}px at 88% 105%,rgba(62,158,88,.30),transparent 70%)}
  h1{position:absolute;left:0;right:0;top:${top}px;margin:0 auto;max-width:${W * 0.72}px;text-align:center;font-family:"Bricolage";font-weight:700;
    font-size:${size}px;line-height:1.04;text-wrap:balance;z-index:5}
  h1 b{color:#FFD84D;font-weight:700}
  .dev{position:absolute;background:#050806}
  .scr{position:relative;width:100%;height:100%;overflow:hidden}
  .scr img{display:block;width:100%;height:100%}
  .island{position:absolute;left:50%;border-radius:99px;background:#000}
  .bar{position:absolute;left:0;right:0;top:0;display:flex;align-items:center;justify-content:space-between;
    font-family:-apple-system,"SF Pro Text","Manrope",sans-serif;font-weight:600}
  .sys{display:flex;align-items:center}
  .sys svg{display:block;width:auto;fill:currentColor}
  .sys .wifi{fill:none;stroke:currentColor}
  </style></head><body><div class="glow"></div><h1>${title}</h1>${phones.join('')}</body></html>`;
}

(async () => {
  const browser = await chromium.launch();
  const tmp = fs.mkdtempSync('/tmp/kuree-creative-');
  async function render(html, W, H, file) {
    const p = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
    const f = path.join(tmp, 'p.html');
    fs.writeFileSync(f, html);
    await p.goto('file://' + f);
    await p.evaluate(() => document.fonts.ready);
    await p.waitForTimeout(200);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    await p.screenshot({ path: file, clip: { x: 0, y: 0, width: W, height: H } });
    await p.close();
    console.log('made', file);
  }

  /* Header, 21:9. One line on top, three phones rising from the bottom edge. */
  {
    const W = 3840, H = 1646, cx = W / 2;
    await render(page(W, H, 'Run your chit <b>from your phone</b>', 150, 150, [
      phone(pick('home'), { x: cx - 760, y: 640, w: 600, r: -7, z: 1 }),
      phone(pick('draw-result'), { x: cx + 760, y: 640, w: 600, r: 7, z: 1 }),
      phone(pick('month'), { x: cx, y: 470, w: 700, z: 2 }),
    ]), W, H, path.join(OUT, 'header.png'));
  }

  /* Search results, 3:2. Says what the app does, shows the app. */
  {
    const W = 3840, H = 2560, cx = W / 2;
    await render(page(W, H, 'Who paid, who is late, <b>who takes the pot</b>', 200, 210, [
      phone(pick('reminders'), { x: cx - 930, y: 1000, w: 780, r: -7, z: 1 }),
      phone(pick('draw-result'), { x: cx + 930, y: 1000, w: 780, r: 7, z: 1 }),
      phone(pick('members'), { x: cx, y: 780, w: 900, z: 2 }),
    ]), W, H, path.join(OUT, 'search.png'));
  }
  await browser.close();
})().catch((e) => { console.error(e); process.exit(1); });
