/* kuree.skifi.co: the landing page. The phone in the hero ticks off who
   paid, the feature cards come in as they scroll into view, the group
   message switches language, and the bottle draw plays when it is seen. */
document.documentElement.classList.add("js");
(function () {
  "use strict";
  var MEN = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  var MSH = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  var reduce = window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches;

  function $(s, r) { return (r || document).querySelector(s); }
  function $$(s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); }
  function money(n) {
    var s = String(Math.round(n));
    if (s.length > 3) {
      var last = s.slice(-3), rest = s.slice(0, -3), parts = [];
      while (rest.length > 2) { parts.unshift(rest.slice(-2)); rest = rest.slice(0, -2); }
      if (rest) parts.unshift(rest);
      s = parts.join(",") + "," + last;
    }
    return "₹" + s;
  }
  function count(el, from, to, ms) {
    if (reduce) { el.textContent = money(to); return; }
    var t0 = performance.now();
    (function step(now) {
      var k = Math.min(1, (now - t0) / ms), e = 1 - Math.pow(1 - k, 3);
      el.textContent = money(from + (to - from) * e);
      if (k < 1) requestAnimationFrame(step);
    })(t0);
  }
  function seen(el, fn, threshold) {
    if (!("IntersectionObserver" in window)) { fn(true); return; }
    new IntersectionObserver(function (es) { es.forEach(function (e) { fn(e.isIntersecting, e); }); }, { threshold: threshold || 0.2 }).observe(el);
  }
  function ready(fn) { if (document.readyState !== "loading") fn(); else document.addEventListener("DOMContentLoaded", fn); }

  ready(function () {
    var now = new Date();
    $$("[data-month]").forEach(function (el) { el.textContent = MEN[now.getMonth()] + " " + now.getFullYear(); });
    $$("[data-mon]").forEach(function (el) { el.textContent = MSH[now.getMonth()]; });

    /* the bar at the top gets a line once the page moves */
    var nav = $("#nav");
    function onScroll() { nav.classList.toggle("is-stuck", window.scrollY > 8); }
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();

    /* sections come in as they are scrolled to */
    var io = "IntersectionObserver" in window ? new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); onIn(e.target); } });
    }, { threshold: 0.18, rootMargin: "0px 0px -6% 0px" }) : null;
    $$(".reveal").forEach(function (el) { if (io) io.observe(el); else { el.classList.add("in"); onIn(el); } });

    function onIn(el) {
      if (el.classList.contains("card--big")) bigCard(el);
    }

    /* the big feature card: two more people pay */
    function bigCard(card) {
      var amt = $(".vpay__amt", card), bar = $(".vpay__bar i", card), a = $(".vrow--a", card), b = $(".vrow--b", card);
      var steps = [[a, 85000, 95000, 79.2, 1100], [b, 95000, 105000, 87.5, 1900]];
      steps.forEach(function (s) {
        setTimeout(function () {
          s[0].classList.add("is-on", "just");
          count(amt, s[1], s[2], 700);
          bar.style.width = s[3] + "%";
        }, reduce ? 0 : s[4]);
      });
    }

    /* ---------------------------------------------------------- the phone in the hero */
    (function hero() {
      var list = $("#hList"), wrap = list && list.parentNode;
      if (!list) return;
      var amt = $("#hAmt"), prog = $("#hProg"), paidEl = $("#hPaid"), left = $("#hLeft"), pot = $("#hPot"), potName = $("#hPotName"), btns = $("#hBtns"), win = $("#hWin");
      var due = [["s5", 10000], ["s9", 10000], ["s11", 5000], ["s13", 10000]];
      var BASE = 85000, TOTAL = 120000, PAID = 9, N = 13;
      var state = { sum: BASE, paid: PAID };
      if (reduce) return;

      function set(sum, paid) {
        count(amt, state.sum, sum, 650);
        state.sum = sum; state.paid = paid;
        prog.style.width = (sum / TOTAL * 100).toFixed(1) + "%";
        paidEl.textContent = paid;
        left.textContent = paid >= N ? "All paid" : (N - paid) + " to go";
      }
      function tick(i) {
        var row = $('[data-p="' + due[i][0] + '"]', list);
        row.classList.add("is-paid", "just");
        $("small", row).textContent = "Paid " + money(due[i][1]);
        set(state.sum + due[i][1], state.paid + 1);
        setTimeout(function () { row.classList.remove("just"); }, 600);
      }
      function scrollEnd() {
        var dy = list.scrollHeight - wrap.clientHeight * 0.8;
        list.style.transform = "translateY(" + (-Math.max(0, dy)) + "px)";
      }
      function won() {
        pot.classList.add("is-won");
        potName.textContent = "3. Jibin";
        btns.style.opacity = "0.35";
        win.classList.add("show");
      }
      function reset() {
        due.forEach(function (d) {
          var row = $('[data-p="' + d[0] + '"]', list);
          row.classList.remove("is-paid");
          $("small", row).textContent = "Pending " + money(d[1]);
        });
        list.style.transform = "";
        pot.classList.remove("is-won");
        potName.textContent = "Not decided yet";
        btns.style.opacity = "";
        win.classList.remove("show");
        set(BASE, PAID);
      }
      var plan = [[1800, function () { tick(0); }], [3300, function () { tick(1); }], [4800, function () { tick(2); }],
        [5900, scrollEnd], [6900, function () { tick(3); }], [8300, won], [14500, reset]];
      var LOOP = 16000, t = 0, next = 0, on = false, last = 0;
      seen($(".stage"), function (v) { on = v; }, 0.25);
      (function loop(ts) {
        var dt = last ? Math.min(100, ts - last) : 0;
        last = ts;
        if (on && !document.hidden) {
          t += dt;
          while (next < plan.length && t >= plan[next][0]) { plan[next][1](); next++; }
          if (t >= LOOP) { t = 0; next = 0; }
        }
        requestAnimationFrame(loop);
      })(performance.now());
    })();

    /* ---------------------------------------------------------- the group message */
    var WORDS = { ml: { paid: "പണമടച്ചവർ", due: "പണമടക്കാത്തവർ" }, en: { paid: "Paid", due: "Not paid yet" } };
    $$(".seg__b").forEach(function (b) {
      b.addEventListener("click", function () {
        var lang = b.getAttribute("data-lang");
        $$(".seg__b").forEach(function (x) { var onx = x === b; x.classList.toggle("is-on", onx); x.setAttribute("aria-pressed", onx ? "true" : "false"); });
        $$("[data-t]").forEach(function (el) {
          el.textContent = WORDS[lang][el.getAttribute("data-t")];
          el.classList.toggle("ml", lang === "ml");
        });
        var bub = $("#groupMsg");
        bub.classList.remove("swap"); void bub.offsetWidth; bub.classList.add("swap");
      });
    });

    /* ---------------------------------------------------------- the bottle draw */
    (function draw() {
      var cv = $("#drawCanvas"), note = $("#drawNote"), playBtn = $("#drawPlay"), againBtn = $("#drawAgain");
      if (!cv || !window.KureeDraw || !cv.getContext) return;
      var entries = [{ slot: 1, name: "Rahul" }, { slot: 3, name: "Jibin" }, { slot: 4, name: "Shabna" }, { slot: 5, name: "Vishnu" },
        { slot: 7, name: "Salman" }, { slot: 9, name: "Anand" }, { slot: 10, name: "Riya / Jaseem" }, { slot: 12, name: "Faisal" }];
      var d = window.KureeDraw.mount(cv, {
        entries: entries, kicker: "RIVERSIDE 10K KURI", title: "Month 5 draw",
        subtitle: MEN[now.getMonth()] + " " + now.getFullYear() + ", pot ₹1,20,000", pot: "₹1,20,000"
      });
      var visible = false, again = 0, fontsReady = false, withSound = false;
      function start(sound) {
        clearTimeout(again);
        withSound = !!sound;
        note.textContent = "";
        d.play({ sound: withSound, countdown: withSound });
      }
      d.onEnd = function (p) {
        note.textContent = "The bottle picked " + p.slot + ". " + p.name + ".";
        withSound = false;
        if (!reduce) again = setTimeout(function () { if (visible && !d.playing()) start(false); }, 6000);
      };
      function go() {
        if (!fontsReady) return;
        if (reduce) { d.still(d.length() - 2600); return; }
        if (visible && !d.playing()) start(false);
      }
      var fl = document.fonts && document.fonts.load ? Promise.all([
        document.fonts.load('700 84px "Bricolage Grotesque"'), document.fonts.load('800 46px "Manrope"'), document.fonts.load('600 38px "Manrope"')
      ]) : Promise.resolve();
      fl.catch(function () {}).then(function () { fontsReady = true; go(); });
      seen(cv, function (v) {
        visible = v;
        if (v) go();
        else { clearTimeout(again); if (d.playing()) d.stop(); }
      }, 0.35);
      playBtn.addEventListener("click", function () { start(true); });
      againBtn.addEventListener("click", function () { start(false); });
    })();
  });
})();
