/* The store pictures: each app screen in a phone on Kuree green with a
   short caption, for the App Store (1206 x 2622, the size its iPhone slot asks for) and Google Play
   (1080 x 1920), plus the Play feature graphic (1024 x 500) and icon.

   node tools/store/make.cjs <folder with the store-*.png app screens> <out folder>

   The app screens come from app/test_screens/store_test.dart (CI puts them
   on the `screens` branch). Needs Playwright with Chromium. */
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const [, , SHOTS = 'shots', OUT = 'store'] = process.argv;
const REPO = path.resolve(__dirname, '..', '..');
const FONTS = path.join(REPO, 'web', 'assets', 'fonts');
const ICON = path.join(REPO, 'app', 'assets', 'brand', 'icon.png');

/* order, screen, caption (the highlighted words in <b>) */
const FRAMES = [
  ['month', 'Every month on <b>one screen</b>'],
  ['draw-result', 'The bottle picks <b>who takes the pot</b>'],
  ['members', 'Tap the tick <b>when they pay</b>'],
  ['reminders', 'Reminders on WhatsApp <b>in one tap</b>'],
  ['link', 'Members follow along <b>from a link</b>'],
  ['slots', 'Two people can <b>share a slot</b>'],
  ['home', 'Run <b>all your chits</b>'],
];

/* the iPhone status bar: time, signal, wifi, battery */
const BAR = '<div class="bar"><span>9:41</span><span class="sys"><svg viewBox="0 0 18 12"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5.5" width="3" height="6.5" rx="1"/><rect x="10" y="3" width="3" height="9" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg><svg class="wifi" viewBox="0 0 16 12"><path d="M1.4 4.7a9.6 9.6 0 0 1 13.2 0M3.9 7.4a6 6 0 0 1 8.2 0M6.5 10.1a2.3 2.3 0 0 1 3 0" stroke-width="1.9" stroke-linecap="round"/></svg><svg class="bat" viewBox="0 0 27 13"><rect x=".6" y=".6" width="22.8" height="11.8" rx="3.4" fill="none" stroke="currentColor" stroke-opacity=".4" stroke-width="1.2"/><rect x="2.4" y="2.4" width="19.2" height="8.2" rx="2"/><path d="M25 4.4v4.2a2.3 2.3 0 0 0 0-4.2z" opacity=".45"/></svg></span></div>';

const url = (f) => 'file://' + path.resolve(f);

function css(W) {
  return `
  @font-face{font-family:"Manrope";font-weight:400 800;src:url(${url(path.join(FONTS, 'manrope.woff2'))}) format("woff2")}
  @font-face{font-family:"Bricolage";font-weight:500 800;src:url(${url(path.join(FONTS, 'bricolage.woff2'))}) format("woff2")}
  *{margin:0;box-sizing:border-box;letter-spacing:0}
  html,body{width:${W}px;overflow:hidden}
  body{font-family:"Manrope",sans-serif;-webkit-font-smoothing:antialiased}`;
}

function framePage(W, H, shot, caption, isDraw) {
  const s = W / 1290;                       /* everything is laid out for 1290 wide */
  const tall = H / W > 2;                   /* App Store frames are taller than Play ones */
  const capTop = (tall ? 230 : 150) * s;
  const capSize = (tall ? 112 : 96) * s;
  /* An iPhone 16 Plus, true to size: body 77.8 x 160.9 mm, screen 430 x 932
     points (the 1290 x 2796 screenshots), bezel 3.3 mm, display corners 55 pt. */
  const devW = (tall ? 1010 : 860) * s;
  const devTop = (tall ? 640 : 470) * s;
  const bez = devW * 0.0424, scrW = devW - bez * 2, scrH = scrW * 932 / 430;
  const inner = scrW * 55 / 430, rad = inner + bez, pt = scrW / 430;
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css(W)}
  body{height:${H}px;position:relative;color:#fff;
    background:radial-gradient(${1400 * s}px ${1200 * s}px at 80% 8%,#1A5A27 0%,#032A09 55%,#021A05 100%)}
  .glow{position:absolute;inset:0;background:radial-gradient(${700 * s}px ${600 * s}px at 10% 100%,rgba(255,216,77,.13),transparent 70%),radial-gradient(${600 * s}px ${500 * s}px at 85% 55%,rgba(62,158,88,.28),transparent 70%)}
  h1{position:absolute;left:${90 * s}px;right:${90 * s}px;top:${capTop}px;text-align:center;font-family:"Bricolage";font-weight:700;
    font-size:${capSize}px;line-height:1.04;text-wrap:balance}
  h1 b{color:#FFD84D;font-weight:700}
  .dev{position:absolute;left:${(W - devW) / 2}px;top:${devTop}px;width:${devW}px;height:${scrH + bez * 2}px;border-radius:${rad}px;
    background:#050806;padding:${bez}px;
    box-shadow:inset 0 0 0 ${devW * 0.0055}px #59625B,inset 0 0 0 ${devW * 0.013}px #1D2420,0 0 0 ${2 * s}px rgba(0,0,0,.4),0 ${60 * s}px ${120 * s}px ${-30 * s}px rgba(0,0,0,.7)}
  .dev::before,.dev::after{content:"";position:absolute;width:${devW * 0.011}px;background:#2E3631}
  .dev::before{right:${-devW * 0.009}px;top:27%;height:11.5%;border-radius:0 ${4 * s}px ${4 * s}px 0}
  .dev::after{left:${-devW * 0.009}px;top:17%;height:22%;border-radius:${4 * s}px 0 0 ${4 * s}px;
    background:linear-gradient(#2E3631 0 15%,transparent 15% 29%,#2E3631 29% 60%,transparent 60% 69%,#2E3631 69% 100%)}
  .scr{position:relative;width:${scrW}px;height:${scrH}px;border-radius:${inner}px;overflow:hidden;background:${isDraw ? '#032A09' : '#F3F5F0'}}
  .scr img{display:block;width:100%;height:100%;object-fit:${isDraw ? 'cover' : 'fill'}}
  .island{position:absolute;left:50%;top:${11 * pt}px;width:${126 * pt}px;height:${37.3 * pt}px;margin-left:${-63 * pt}px;border-radius:99px;background:#000}
  .bar{position:absolute;left:0;right:0;top:0;height:${59 * pt}px;display:flex;align-items:center;justify-content:space-between;padding:0 ${31 * pt}px 0 ${46 * pt}px;
    color:${isDraw ? '#fff' : '#0F2413'};font-family:-apple-system,"SF Pro Text","Manrope",sans-serif;font-weight:600;font-size:${17 * pt}px}
  .sys{display:flex;gap:${6 * pt}px;align-items:center}
  .sys svg{display:block;height:${11.5 * pt}px;width:auto;fill:currentColor}
  .sys .bat{height:${13 * pt}px}
  .sys .wifi{fill:none;stroke:currentColor}
  .home{position:absolute;left:50%;bottom:${8 * pt}px;width:${144 * pt}px;height:${5 * pt}px;margin-left:${-72 * pt}px;border-radius:9px;background:${isDraw ? 'rgba(255,255,255,.7)' : '#0F2413'}}
  </style></head><body><div class="glow"></div><h1>${caption}</h1>
  <div class="dev"><div class="scr"><img src="${url(shot)}">${BAR}<i class="island"></i><i class="home"></i></div></div>
  </body></html>`;
}

function featurePage(shot) {
  const W = 1024, H = 500;
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css(W)}
  body{height:${H}px;position:relative;color:#fff;overflow:hidden;
    background:radial-gradient(700px 520px at 78% 20%,#1A5A27 0%,#032A09 58%,#021A05 100%)}
  .glow{position:absolute;inset:0;background:radial-gradient(420px 320px at 0% 100%,rgba(255,216,77,.14),transparent 70%)}
  .copy{position:absolute;left:64px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center;gap:18px;width:520px}
  .mark{display:flex;align-items:center;gap:20px}
  .mark img{width:104px;height:104px;border-radius:26px;box-shadow:0 18px 36px -16px rgba(0,0,0,.7)}
  .mark span{font-family:"Bricolage";font-weight:700;font-size:92px;line-height:1}
  p{font-size:31px;font-weight:600;color:rgba(221,238,223,.9);line-height:1.3}
  p b{color:#FFD84D;font-weight:700}
  .dev{position:absolute;left:650px;top:64px;width:300px;height:620.4px;border-radius:47.8px;padding:12.7px;background:#050806;
    box-shadow:inset 0 0 0 1.65px #59625B,inset 0 0 0 3.9px #1D2420,0 0 0 1px rgba(0,0,0,.4),0 40px 80px -20px rgba(0,0,0,.7)}
  .scr{position:relative;width:100%;height:100%;border-radius:35.1px;overflow:hidden;background:#F3F5F0}
  .island{position:absolute;left:50%;top:7px;width:80.5px;height:23.8px;margin-left:-40.2px;border-radius:99px;background:#000}
  .scr img{display:block;width:100%}
  .bar{position:absolute;left:0;right:0;top:0;height:37.7px;display:flex;align-items:center;justify-content:space-between;padding:0 19.8px 0 29.4px;
    color:#0F2413;font-family:-apple-system,"SF Pro Text","Manrope",sans-serif;font-weight:600;font-size:10.9px}
  .sys{display:flex;gap:3.8px;align-items:center}
  .sys svg{display:block;height:7.3px;width:auto;fill:currentColor}
  .sys .bat{height:8.3px}
  .sys .wifi{fill:none;stroke:currentColor}
  </style></head><body><div class="glow"></div>
  <div class="copy"><div class="mark"><img src="${url(ICON)}"><span>Kuree</span></div><p>Run your chit <b>from your phone</b></p></div>
  <div class="dev"><div class="scr"><img src="${url(shot)}">${BAR}<i class="island"></i></div></div></body></html>`;
}

(async () => {
  const pick = (name) => {
    for (const n of [name, `${name}-a`, `${name}-b`]) {
      const f = path.join(SHOTS, `store-${n}.png`);
      if (fs.existsSync(f)) return f;
    }
    throw new Error(`missing store-${name}.png in ${SHOTS}`);
  };
  const tmp = fs.mkdtempSync('/tmp/kuree-store-');
  const browser = await chromium.launch();
  async function render(html, W, H, file) {
    const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
    const f = path.join(tmp, 'p.html');
    fs.writeFileSync(f, html);
    await page.goto('file://' + f);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(150);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    await page.screenshot({ path: file, clip: { x: 0, y: 0, width: W, height: H } });
    await page.close();
    console.log('made', file);
  }
  for (const [i, [name, caption]] of FRAMES.entries()) {
    const shot = pick(name);
    const isDraw = name.startsWith('draw');
    await render(framePage(1206, 2622, shot, caption, isDraw), 1206, 2622, path.join(OUT, 'ios', `${i + 1}.png`));
    await render(framePage(1080, 1920, shot, caption, isDraw), 1080, 1920, path.join(OUT, 'play', `${i + 1}.png`));
  }
  await render(featurePage(pick('month')), 1024, 500, path.join(OUT, 'play', 'feature.png'));
  await render(`<!doctype html><html><head><style>*{margin:0}body{width:512px;height:512px}img{display:block;width:512px;height:512px}</style></head><body><img src="${url(ICON)}"></body></html>`,
    512, 512, path.join(OUT, 'play', 'icon.png'));
  await browser.close();
})().catch((e) => { console.error(e); process.exit(1); });
