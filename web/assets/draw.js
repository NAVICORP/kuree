/* The bottle draw from the Kuree app, on the landing page. The same scene as
   app/lib/draw/scene.dart (one rolled slip per waiting slot dropped into a
   glass bottle, corked, shaken, tipped until one slip falls out and opens),
   drawn on a canvas, with the same music and sounds made in the browser.

   KureeDraw.mount(canvas, { entries, kicker, title, subtitle, pot })
     .play({ sound, countdown })  starts a fresh draw with a new pick
     .stop()                       stops it
     .onEnd = fn                   called when a draw has finished */
(function () {
  "use strict";

  var W = 1080, H = 1920, STEP = 1000 / 120, COUNTDOWN = 3000;
  var C = { deep: "#032A09", green: "#24592B", leaf: "#3E9E58", sun: "#FFD84D", mint: "#DDEEDF", paper: "#FFFDF4", ink: "#0F2413", peach: "#F6E3D5" };
  var FH = '"Bricolage Grotesque", "Manrope", system-ui, sans-serif';
  var FB = '"Manrope", system-ui, sans-serif';
  var MON = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  var BW = 470, BH = 560, NECKW = 170, NECKH = 140, SHOULDER = 100, R = 36;

  function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function ease(t) { t = clamp(t, 0, 1); return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2; }
  function out(t) { t = clamp(t, 0, 1); return 1 - Math.pow(1 - t, 3); }
  function back(t) { t = clamp(t, 0, 1); var c = 1.7; return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2); }
  function rgba(hex, a) {
    var n = parseInt(hex.slice(1), 16);
    return "rgba(" + (n >> 16 & 255) + "," + (n >> 8 & 255) + "," + (n & 255) + "," + clamp(a, 0, 1).toFixed(3) + ")";
  }
  function fair(n) {
    if (window.crypto && crypto.getRandomValues) {
      var a = new Uint32Array(1), lim = Math.floor(4294967296 / n) * n;
      do { crypto.getRandomValues(a); } while (a[0] >= lim);
      return a[0] % n;
    }
    return Math.floor(Math.random() * n);
  }
  function shuffle(list) {
    var x = list.slice();
    for (var i = x.length - 1; i > 0; i--) { var j = fair(i + 1), t = x[i]; x[i] = x[j]; x[j] = t; }
    return x;
  }
  function stamp(d) {
    var h = d.getHours(), m = d.getMinutes();
    return d.getDate() + " " + MON[d.getMonth()] + " " + d.getFullYear() + ", " + ((h % 12) || 12) + ":" + (m < 10 ? "0" : "") + m + (h < 12 ? " am" : " pm");
  }

  /* when each part starts, in ms after the countdown (as in the app) */
  function makePlan(n) {
    var gap = Math.max(170, Math.min(300, 2000 / n)), d = gap / 0.62, write = [];
    for (var i = 0; i < n; i++) write.push({ at: 570 + i * gap, d: d });
    var inEnd = write[n - 1].at + d + 600, shake = inEnd + 360, pick = shake + 1840 + 200, reveal = pick + 2060;
    return { write: write, cork: inEnd, shake: shake, shakeD: 1840, pick: pick, pickD: 2060, reveal: reveal, end: reveal + 4600 };
  }

  /* ---------------------------------------------------------------- sound */

  function makeSound() {
    var AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    var ac = new AC(), comp = ac.createDynamicsCompressor(), master = ac.createGain();
    comp.threshold.value = -14; comp.ratio.value = 4; comp.attack.value = 0.003; comp.release.value = 0.2;
    master.gain.value = 0.8; master.connect(comp); comp.connect(ac.destination);
    var music = ac.createGain(); music.gain.value = 0.55; music.connect(master);
    var sfx = ac.createGain(); sfx.gain.value = 0.9; sfx.connect(master);
    var noise = ac.createBuffer(1, ac.sampleRate * 2, ac.sampleRate), nd = noise.getChannelData(0);
    for (var i = 0; i < nd.length; i++) nd[i] = Math.random() * 2 - 1;

    function env(gn, t, a, peak, d) {
      gn.gain.setValueAtTime(0.0001, t);
      gn.gain.exponentialRampToValueAtTime(peak, t + a);
      gn.gain.exponentialRampToValueAtTime(0.0001, t + a + d);
    }
    function osc(type, f, t, dur, bus, peak, a, f2) {
      var o = ac.createOscillator(), gn = ac.createGain();
      o.type = type; o.frequency.setValueAtTime(f, t);
      if (f2) o.frequency.exponentialRampToValueAtTime(f2, t + dur);
      env(gn, t, a || 0.005, peak, dur);
      o.connect(gn); gn.connect(bus); o.start(t); o.stop(t + dur + 0.05);
    }
    function nz(t, dur, bus, peak, type, f, q, f2, a) {
      var src = ac.createBufferSource(), fl = ac.createBiquadFilter(), gn = ac.createGain();
      src.buffer = noise; src.loop = true;
      fl.type = type || "bandpass"; fl.frequency.setValueAtTime(f || 2000, t); fl.Q.value = q || 1;
      if (f2) fl.frequency.exponentialRampToValueAtTime(f2, t + dur);
      env(gn, t, a || 0.004, peak, dur);
      src.connect(fl); fl.connect(gn); gn.connect(bus);
      src.start(t, Math.random()); src.stop(t + dur + 0.05);
    }
    var NOTE = function (n) { return 440 * Math.pow(2, (n - 69) / 12); };
    function kick(t, v) { osc("sine", 150, t, 0.28, music, 0.9 * (v || 1), 0.002, 42); }
    function snare(t, v) { nz(t, 0.16, music, 0.35 * (v || 1), "highpass", 1800); osc("triangle", 190, t, 0.08, music, 0.25 * (v || 1)); }
    function hat(t, v) { nz(t, 0.045, music, 0.12 * (v || 1), "highpass", 8000); }
    function shaker(t, v) { nz(t, 0.06, music, 0.08 * (v || 1), "bandpass", 5200, 2); }
    function mallet(t, n, v, dur) {
      var f = NOTE(n);
      osc("sine", f, t, dur || 0.5, music, 0.32 * (v || 1), 0.003);
      osc("sine", f * 4, t, 0.08, music, 0.06 * (v || 1), 0.002);
    }
    function bass(t, n, dur) { osc("triangle", NOTE(n), t, dur, music, 0.42, 0.01); osc("sine", NOTE(n - 12), t, dur, music, 0.3, 0.01); }
    function pad(t, notes, dur, v) {
      notes.forEach(function (n) {
        [-6, 6].forEach(function (cents) {
          var o = ac.createOscillator(), fl = ac.createBiquadFilter(), gn = ac.createGain();
          o.type = "sawtooth"; o.frequency.value = NOTE(n); o.detune.value = cents;
          fl.type = "lowpass"; fl.frequency.value = 1400;
          gn.gain.setValueAtTime(0.0001, t); gn.gain.exponentialRampToValueAtTime(0.035 * (v || 1), t + 0.25);
          gn.gain.setValueAtTime(0.035 * (v || 1), t + dur - 0.3); gn.gain.exponentialRampToValueAtTime(0.0001, t + dur);
          o.connect(fl); fl.connect(gn); gn.connect(music); o.start(t); o.stop(t + dur + 0.05);
        });
      });
    }
    function clink(t) {
      var f = 1900 + Math.random() * 1300;
      osc("sine", f, t, 0.5, sfx, 0.16, 0.002); osc("sine", f * 2.76, t, 0.22, sfx, 0.05, 0.002);
      nz(t, 0.05, sfx, 0.08, "bandpass", 3000, 3);
    }
    function pen(t, dur) { for (var x = 0; x < dur; x += 0.07 + Math.random() * 0.05) nz(t + x, 0.06, sfx, 0.07, "bandpass", 3500 + Math.random() * 2000, 4); }
    function rustle(t, dur, up) { nz(t, dur, sfx, 0.16, "bandpass", up ? 900 : 3200, 1.2, up ? 3400 : 900, 0.04); }
    function whoosh(t, dur) { nz(t, dur, sfx, 0.22, "bandpass", 400, 1.4, 2400, dur * 0.4); }
    function corkIn(t) { osc("sine", 520, t, 0.35, sfx, 0.08, 0.02, 900); osc("sine", 110, t + 0.45, 0.18, sfx, 0.4, 0.002, 60); nz(t + 0.45, 0.06, sfx, 0.2, "lowpass", 900); }
    function pop(t) { osc("sine", 520, t, 0.14, sfx, 0.5, 0.001, 120); nz(t, 0.08, sfx, 0.4, "bandpass", 1400, 1.5); }
    function rattle(t, dur) {
      for (var x = 0; x < dur; x += 0.025 + Math.random() * 0.05) {
        var a = Math.sin(x / dur * Math.PI);
        if (Math.random() < 0.75) nz(t + x, 0.03, sfx, 0.05 + 0.18 * a, "bandpass", 2200 + Math.random() * 2200, 3);
        if (Math.random() < 0.18) clink(t + x);
      }
    }
    function roll(t, dur) {
      for (var x = 0; x < dur; x += lerp(0.11, 0.035, x / dur)) {
        var v = lerp(0.25, 1, x / dur);
        nz(t + x, 0.08, music, 0.22 * v, "highpass", 1600); osc("triangle", 200, t + x, 0.05, music, 0.12 * v);
      }
      var o = ac.createOscillator(), fl = ac.createBiquadFilter(), gn = ac.createGain();
      o.type = "sawtooth"; o.frequency.setValueAtTime(110, t); o.frequency.exponentialRampToValueAtTime(440, t + dur);
      fl.type = "lowpass"; fl.frequency.setValueAtTime(300, t); fl.frequency.exponentialRampToValueAtTime(4000, t + dur);
      gn.gain.setValueAtTime(0.0001, t); gn.gain.exponentialRampToValueAtTime(0.09, t + dur); gn.gain.exponentialRampToValueAtTime(0.0001, t + dur + 0.05);
      o.connect(fl); fl.connect(gn); gn.connect(music); o.start(t); o.stop(t + dur + 0.1);
    }
    function tada(t) {
      kick(t, 1.2); nz(t, 2.2, music, 0.28, "highpass", 5000, 0.7, null, 0.002);
      [60, 64, 67, 72, 76].forEach(function (n, i) { mallet(t + i * 0.035, n + 12, 1.1, 1.2); });
      pad(t, [48, 60, 64, 67, 72], 2.8, 1.6);
      bass(t, 36, 1.4);
      for (var i = 0; i < 9; i++) osc("sine", NOTE(84 + [0, 4, 7, 12, 16, 12, 7, 4, 0][i]), t + 0.25 + i * 0.07, 0.3, sfx, 0.07, 0.002);
      for (var c = 0; c < 26; c++) nz(t + 0.1 + Math.random() * 1.6, 0.02, sfx, 0.05, "highpass", 6000);
    }
    function beep(t, hi) { osc("sine", hi ? 1320 : 880, t, 0.18, sfx, 0.35, 0.003); osc("sine", hi ? 2640 : 1760, t, 0.08, sfx, 0.06, 0.003); }
    var BEAT = 60 / 116, PROG = [[48, [60, 64, 67]], [45, [57, 60, 64]], [41, [57, 60, 65]], [43, [59, 62, 67]]], ARP = [0, 1, 2, 1, 2, 0, 1, 2];
    function groove(t0, t1, hot) {
      var bar = 0;
      for (var t = t0; t < t1 - 0.01; t += BEAT * 4, bar++) {
        var ch = PROG[bar % 4], left = t1 - t;
        bass(t, ch[0], Math.min(BEAT * 1.8, left)); if (left > BEAT * 2) bass(t + BEAT * 2, ch[0], BEAT * 1.6);
        if (bar % 2 === 0 || hot) pad(t, ch[1], Math.min(BEAT * 4, left), hot ? 1.2 : 0.8);
        for (var b = 0; b < 8; b++) {
          var tt = t + b * BEAT / 2;
          if (tt >= t1 - 0.02) break;
          if (b % 4 === 0) kick(tt);
          if (hot && b % 4 === 2) snare(tt);
          hat(tt, b % 2 ? 0.6 : 1);
          if (hot) shaker(tt + BEAT / 4);
          mallet(tt, ch[1][ARP[b]] + 12, b % 2 ? 0.55 : 0.8, 0.45);
        }
      }
    }
    function outro(t) {
      [[48, [72, 76, 79]], [41, [69, 72, 77]], [43, [71, 74, 79]], [48, [72, 76, 84]]].forEach(function (c, i) {
        var tt = t + i * BEAT * 2;
        bass(tt, c[0], BEAT * 1.8); pad(tt, c[1].map(function (n) { return n - 12; }), BEAT * 2, 0.9);
        c[1].forEach(function (n, j) { mallet(tt + j * BEAT / 2, n, 0.7, 0.5); });
        kick(tt); hat(tt + BEAT / 2); hat(tt + BEAT, 0.6); hat(tt + BEAT * 1.5);
      });
    }
    return {
      /* schedule everything; `from` is the scene time (ms) the audio clock starts at */
      play: function (P, from) {
        if (ac.state === "suspended") ac.resume();
        var T = ac.currentTime + 0.05 - from / 1000, at = function (ms) { return T + ms / 1000; };
        if (from < 0) { for (var k = 0; k < 4; k++) if (-COUNTDOWN + k * 1000 >= from) beep(at(-COUNTDOWN + k * 1000), k === 3); }
        groove(Math.max(at(0), ac.currentTime), at(P.shake), false);
        groove(at(P.shake), at(P.pick), true);
        P.write.forEach(function (w) {
          if (w.at < from) return;
          rustle(at(w.at), 0.25, true);
          pen(at(w.at + w.d * 0.08), w.d * 0.32 / 1000);
          rustle(at(w.at + w.d * 0.5), w.d * 0.16 / 1000);
          whoosh(at(w.at + w.d * 0.66), w.d * 0.3 / 1000);
          clink(at(w.at + w.d + 60)); clink(at(w.at + w.d + 260));
        });
        corkIn(at(P.cork));
        rattle(at(P.shake), P.shakeD / 1000);
        pop(at(P.shake + P.shakeD + 80));
        whoosh(at(P.pick + P.pickD * 0.32), 0.6);
        whoosh(at(P.pick + P.pickD * 0.62), 0.7);
        roll(at(P.pick), P.pickD / 1000);
        rustle(at(P.reveal + 300), 0.4, true);
        tada(at(P.reveal + 620));
        outro(at(P.reveal + 620 + 1600));
      },
      stop: function () {
        try { master.gain.setTargetAtTime(0.0001, ac.currentTime, 0.06); setTimeout(function () { ac.close(); }, 300); } catch (e) { /* closed */ }
      }
    };
  }

  /* ---------------------------------------------------------------- the scene */

  function Scene(o) {
    var order = shuffle(o.entries), n = order.length;
    var pickIndex = fair(n), P = makePlan(n), when = new Date();
    var hues = [C.paper, "#FFF7E0", "#F7FBF6", "#FFF9EC"];
    var slips = order.map(function (e, i) {
      return { e: e, i: i, mode: "wait", x: 0, y: 0, vx: 0, vy: 0, va: 0, ang: (Math.random() - 0.5) * 0.6, hue: hues[i % 4], ox0: 0, oy0: 0, oang: 0 };
    });
    var confetti = [], burst = false, simT = -COUNTDOWN;
    var B = { x: W / 2, y: 1220, a: 0, s: 1, ox: 0 };

    function pose(t) {
      B.x = W / 2;
      if (t < P.shake || t < 0) { B.a = 0; B.ox = 0; }
      else if (t < P.shake + P.shakeD) {
        var q = (t - P.shake) / P.shakeD, amp = Math.sin(q * Math.PI);
        B.a = Math.sin(q * Math.PI * 9) * 0.42 * amp + Math.sin(q * Math.PI * 23) * 0.06 * amp;
        B.ox = Math.sin(q * Math.PI * 7 + 1) * 70 * amp;
      } else if (t < P.pick) { B.a = 0; B.ox = 0; }
      else if (t < P.reveal) {
        var pk = (t - P.pick) / P.pickD;
        B.a = lerp(0, 2.25, ease(pk / 0.45)) - (pk > 0.75 ? lerp(0, 2.25, ease((pk - 0.75) / 0.25)) : 0);
        B.ox = 0;
      } else { B.a = 0; B.ox = 0; }
      if (t >= P.reveal) {
        var rv = t - P.reveal;
        B.s = lerp(1, 0.5, ease(rv / 900));
        B.y = lerp(1220, 1500, ease(rv / 900));
      } else { B.s = 1; B.y = 1220; }
    }
    function mode(t) { return t < P.cork ? "open" : (t >= P.pick && t < P.reveal ? "tip" : "closed"); }
    function kick(t) { return (t >= P.shake && t < P.shake + P.shakeD) ? 260 * Math.sin((t - P.shake) / P.shakeD * Math.PI) : 0; }
    function cork(t) {
      if (t < P.cork) return 0;
      if (t < P.shake) return out((t - P.cork) / 700);
      if (t < P.shake + P.shakeD) return 1;
      if (t < P.pick) return 1 - out((t - P.shake - P.shakeD) / 450);
      return 0;
    }
    function toWorld(x, y) {
      var c = Math.cos(B.a), s = Math.sin(B.a);
      return { x: B.x + B.ox + (x * c - y * s) * B.s, y: B.y + (x * s + y * c) * B.s };
    }
    function toLocal(x, y) {
      var dx = (x - B.x - B.ox) / B.s, dy = (y - B.y) / B.s, c = Math.cos(-B.a), s = Math.sin(-B.a);
      return { x: dx * c - dy * s, y: dx * s + dy * c };
    }
    function bottlePath(g, close, extra) {
      var w = BW / 2, h = BH / 2, nn = NECKW / 2, top = -h - SHOULDER, nt = top - NECKH - (extra || 0);
      g.beginPath();
      g.moveTo(-nn, nt);
      g.lineTo(-nn, top);
      g.bezierCurveTo(-nn, top + 60, -w, top + 40, -w, -h + 30);
      g.lineTo(-w, h - 70);
      g.quadraticCurveTo(-w, h, -w + 70, h);
      g.lineTo(w - 70, h);
      g.quadraticCurveTo(w, h, w, h - 70);
      g.lineTo(w, -h + 30);
      g.bezierCurveTo(w, top + 40, nn, top + 60, nn, top);
      g.lineTo(nn, nt);
      if (close) g.closePath();
    }

    /* ---------- simulation, in fixed steps */
    function advanceTo(t) {
      var guard = 0;
      while (simT + STEP <= t && guard++ < 240) { simT += STEP; update(simT, STEP / 1000); }
      if (simT + STEP <= t) simT = t;                /* a long pause (hidden tab): skip ahead */
    }
    function update(t, dt) {
      if (t < 0) return;
      pose(t);
      slips.forEach(function (s) {
        if (s.mode !== "wait") return;
        if ((t - P.write[s.i].at) / P.write[s.i].d < 1) return;
        var mouth = toWorld(0, -BH / 2 - SHOULDER - NECKH - 30), local = toLocal(mouth.x, mouth.y);
        s.mode = "in";
        s.x = local.x + (Math.random() - 0.5) * 10; s.y = local.y;
        s.vx = (Math.random() - 0.5) * 60; s.vy = 600;
        s.ang = Math.PI / 2 + (s.i % 2 ? 0.25 : -0.25);
        s.va = (Math.random() - 0.5) * 3;
      });
      if (t >= P.pick && t < P.reveal) {
        var ch = slips[pickIndex], pk = (t - P.pick) / P.pickD;
        if (ch.mode === "in" && pk > 0.32) { ch.mode = "out"; ch.ox0 = ch.x; ch.oy0 = ch.y; ch.oang = ch.ang; }
      }
      physics(dt, mode(t), kick(t));
      if (!burst && t >= P.reveal + 650) { burst = true; spray(W / 2, 800); }
      confetti.forEach(function (b) {
        b.vy += 1500 * dt; b.vx *= Math.pow(0.99, dt * 60);
        b.x += b.vx * dt; b.y += b.vy * dt; b.r += b.vr * dt; b.life -= dt * 0.18;
      });
      confetti = confetti.filter(function (b) { return b.life > 0 && b.y < H + 60; });
    }
    function physics(dt, md, kk) {
      var gx = Math.sin(-B.a) * 2600, gy = Math.cos(-B.a) * 2600;
      var inside = slips.filter(function (s) { return s.mode === "in"; });
      var damp = Math.pow(0.995, dt * 60), dampA = Math.pow(0.985, dt * 60), k = kk * dt * 60;
      inside.forEach(function (s) {
        var co = Math.abs(Math.cos(s.ang)), si = Math.abs(Math.sin(s.ang));
        var hx = Math.max(R, 64 * co + 23 * si) + 6, hy = Math.max(R, 64 * si + 23 * co) + 6;
        var w = BW / 2 - hx, h = BH / 2 - hy, nn = Math.max(0, NECKW / 2 - hx), top = -BH / 2 - SHOULDER - NECKH + hy;
        s.vx += gx * dt; s.vy += gy * dt;
        if (k > 0) { s.vx += (Math.random() - 0.5) * k; s.vy += (Math.random() - 0.65) * k; s.va += (Math.random() - 0.5) * k * 0.01; }
        s.vx *= damp; s.vy *= damp; s.va *= dampA;
        s.x += s.vx * dt; s.y += s.vy * dt; s.ang += s.va * dt;
        var bodyTop = -BH / 2 + 30, neckBase = -BH / 2 - SHOULDER + hy;
        if (s.y < bodyTop) {
          var q = clamp((bodyTop - s.y) / (bodyTop - neckBase), 0, 1), lim = lerp(w, nn, q);
          if (s.x < -lim) { s.x = -lim; s.vx = Math.abs(s.vx) * 0.4; }
          if (s.x > lim) { s.x = lim; s.vx = -Math.abs(s.vx) * 0.4; }
          var cap = md === "open" ? -1e9 : (md === "tip" ? neckBase : top);
          if (s.y < cap) { s.y = cap; s.vy = Math.abs(s.vy) * 0.3; }
        } else {
          if (s.x < -w) { s.x = -w; s.vx = Math.abs(s.vx) * 0.45; s.va += s.vy * 0.002; }
          if (s.x > w) { s.x = w; s.vx = -Math.abs(s.vx) * 0.45; s.va -= s.vy * 0.002; }
        }
        if (s.y > h) { s.y = h; s.vy = -Math.abs(s.vy) * 0.35; s.vx *= 0.9; s.va += s.vx * 0.003; }
      });
      for (var i = 0; i < inside.length; i++) {
        for (var j = i + 1; j < inside.length; j++) {
          var a = inside[i], b = inside[j], dx = b.x - a.x, dy = b.y - a.y, d2 = dx * dx + dy * dy, m = R * 2 * 0.86;
          if (d2 < m * m && d2 > 0.01) {
            var d = Math.sqrt(d2), push = (m - d) / 2, ux = dx / d, uy = dy / d;
            a.x -= ux * push; a.y -= uy * push; b.x += ux * push; b.y += uy * push;
            var rv = (b.vx - a.vx) * ux + (b.vy - a.vy) * uy;
            if (rv < 0) { var imp = rv * 0.6; a.vx += ux * imp; a.vy += uy * imp; b.vx -= ux * imp; b.vy -= uy * imp; }
          }
        }
      }
    }
    function spray(x, y) {
      var cols = [C.sun, C.leaf, C.mint, "#FFFFFF", C.peach, "#7FD18F"];
      for (var i = 0; i < 170; i++) {
        var a = Math.random() * Math.PI * 2, sp = 500 + Math.random() * 1200;
        confetti.push({ x: x, y: y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp - 700, r: Math.random() * 6, vr: (Math.random() - 0.5) * 14,
          w: 12 + Math.random() * 14, h: 6 + Math.random() * 10, c: cols[i % cols.length], life: 1 });
      }
    }

    /* ---------- painting */
    function text(g, s, x, y, size, weight, color, heading, align, middle) {
      if (!s || size <= 0) return 0;
      g.font = weight + " " + size + "px " + (heading ? FH : FB);
      g.textAlign = align || "center";
      g.textBaseline = middle ? "middle" : "alphabetic";
      g.fillStyle = color;
      g.fillText(s, x, y);
      return g.measureText(s).width;
    }
    function bg(g, t) {
      var gr = g.createRadialGradient(W / 2, 760, 80, W / 2, 900, 1300);
      gr.addColorStop(0, "#0E4A1A"); gr.addColorStop(0.55, C.deep); gr.addColorStop(1, "#021A05");
      g.fillStyle = gr; g.fillRect(0, 0, W, H);
      var clock = t + COUNTDOWN;
      for (var i = 0; i < 6; i++) {
        var raw = i * 211 + clock * 0.02 * (i % 2 ? 1 : -1);
        var x = ((raw % (W + 400)) + (W + 400)) % (W + 400) - 200, y = 300 + i * 260;
        g.fillStyle = rgba(i % 2 ? C.sun : C.leaf, 0.07);
        g.beginPath(); g.arc(x, y, 160 + i * 20, 0, Math.PI * 2); g.fill();
      }
    }
    function header(g) {
      text(g, o.kicker, W / 2, 150, 36, 700, C.sun);
      text(g, o.title, W / 2, 250, 84, 700, "#FFFFFF", true);
      text(g, o.subtitle, W / 2, 312, 38, 600, "rgba(221,238,223,.85)");
    }
    function footer(g) { text(g, n + " names in the bottle. Drawn " + stamp(when), W / 2, H - 70, 30, 600, "rgba(221,238,223,.7)"); }
    function caption(g, a, b) {
      text(g, a, W / 2, 1640, 52, 700, "#FFFFFF", true);
      if (b) text(g, b, W / 2, 1700, 34, 600, "rgba(221,238,223,.8)");
    }
    function bottleBack(g) {
      g.save(); g.translate(B.x + B.ox, B.y); g.rotate(B.a); g.scale(B.s, B.s);
      var gr = g.createLinearGradient(-BW / 2, 0, BW / 2, 0);
      gr.addColorStop(0, "rgba(180,230,200,.16)"); gr.addColorStop(0.5, "rgba(180,230,200,.05)"); gr.addColorStop(1, "rgba(180,230,200,.14)");
      bottlePath(g, true); g.fillStyle = gr; g.fill();
      g.restore();
    }
    function rr(g, x, y, w, h, r) {
      r = Math.min(r, w / 2, h / 2);
      g.beginPath();
      g.moveTo(x + r, y); g.arcTo(x + w, y, x + w, y + h, r); g.arcTo(x + w, y + h, x, y + h, r);
      g.arcTo(x, y + h, x, y, r); g.arcTo(x, y, x + w, y, r); g.closePath();
    }
    function bottleFront(g, ck) {
      g.save(); g.translate(B.x + B.ox, B.y); g.rotate(B.a); g.scale(B.s, B.s);
      bottlePath(g, false);
      g.lineWidth = 10; g.lineJoin = "round"; g.strokeStyle = "rgba(220,245,230,.55)"; g.stroke();
      var nn = NECKW / 2, nt = -BH / 2 - SHOULDER - NECKH;
      rr(g, -nn - 16, nt - 22, NECKW + 32, 30, 12); g.fillStyle = "rgba(220,245,230,.5)"; g.fill();
      g.lineCap = "round";
      g.beginPath(); g.moveTo(-BW / 2 + 52, -BH / 2 + 70); g.lineTo(-BW / 2 + 52, BH / 2 - 120);
      g.lineWidth = 14; g.strokeStyle = "rgba(255,255,255,.35)"; g.stroke();
      g.beginPath(); g.moveTo(-BW / 2 + 84, -BH / 2 + 90); g.lineTo(-BW / 2 + 84, -BH / 2 + 260);
      g.lineWidth = 8; g.strokeStyle = "rgba(255,255,255,.18)"; g.stroke();
      if (ck > 0) {
        var cy = nt - 26 - (1 - ck) * 340, ca = (1 - ck) * 1.4, al = clamp(ck * 1.4, 0, 1);
        g.save(); g.translate(0, cy); g.rotate(ca); g.globalAlpha = al;
        var gr = g.createLinearGradient(-60, 0, 60, 0);
        gr.addColorStop(0, "#A7743E"); gr.addColorStop(0.5, "#D6A564"); gr.addColorStop(1, "#9A6A36");
        g.beginPath(); g.moveTo(-70, -60); g.lineTo(70, -60); g.lineTo(58, 70); g.lineTo(-58, 70); g.closePath();
        g.fillStyle = gr; g.fill();
        g.fillStyle = "rgba(60,30,10,.25)";
        [[-30, -20], [18, 6], [-6, 40], [34, -36]].forEach(function (d) { g.beginPath(); g.arc(d[0], d[1], 5, 0, Math.PI * 2); g.fill(); });
        g.restore();
      }
      g.restore();
    }
    function slipFlat(g, x, y, w, h, rot, sl, letters, alpha) {
      if (alpha <= 0) return;
      g.save(); g.translate(x, y); g.rotate(rot); g.globalAlpha = clamp(alpha, 0, 1);
      g.save();
      g.shadowColor = "rgba(0,0,0,.35)"; g.shadowBlur = 30; g.shadowOffsetY = 14;
      rr(g, -w / 2, -h / 2, w, h, 14); g.fillStyle = sl.hue; g.fill();
      g.restore();
      g.save(); rr(g, -w / 2, -h / 2, w, h, 14); g.clip();
      g.lineWidth = 2; g.strokeStyle = "rgba(36,89,43,.12)";
      for (var ly = -h / 2 + 46; ly < h / 2; ly += 40) { g.beginPath(); g.moveTo(-w / 2, ly); g.lineTo(w / 2, ly); g.stroke(); }
      g.strokeStyle = "rgba(200,70,50,.25)";
      g.beginPath(); g.moveTo(-w / 2 + 80, -h / 2); g.lineTo(-w / 2 + 80, h / 2); g.stroke();
      g.restore();
      if (h > 90) {
        g.fillStyle = C.sun; g.beginPath(); g.arc(-w / 2 + 40, 0, 26, 0, Math.PI * 2); g.fill();
        text(g, String(sl.e.slot), -w / 2 + 40, 2, 28, 800, C.deep, false, "center", true);
      }
      var name = sl.e.name, shown = letters == null ? name : name.slice(0, Math.min(letters, name.length));
      var fs = Math.min(h * 0.4, (w - 140) / Math.max(4, name.length) * 1.75);
      var width = text(g, shown, -w / 2 + 100, 4, fs, 700, C.ink, true, "left", true);
      if (letters != null && letters < name.length) { g.fillStyle = C.green; g.beginPath(); g.arc(-w / 2 + 100 + width + 8, 10, 7, 0, Math.PI * 2); g.fill(); }
      g.restore();
    }
    function slipRolled(g, x, y, rot, sl, scale) {
      var w = 128 * scale, h = 46 * scale;
      g.save(); g.translate(x, y); g.rotate(rot);
      var gr = g.createLinearGradient(0, -h / 2, 0, h / 2);
      gr.addColorStop(0, "#FFFFFF"); gr.addColorStop(0.45, sl.hue); gr.addColorStop(1, "#D9D3BD");
      rr(g, -w / 2, -h / 2, w, h, h / 2); g.fillStyle = gr; g.fill();
      g.lineWidth = 2; g.strokeStyle = "rgba(15,36,19,.18)"; g.stroke();
      g.fillStyle = "rgba(15,36,19,.08)";
      g.beginPath(); g.ellipse(w / 2 - h / 4, 0, h / 5, h / 2 - 2, 0, 0, Math.PI * 2); g.fill();
      g.fillStyle = C.sun; g.fillRect(-7 * scale, -h / 2, 14 * scale, h);
      g.restore();
    }
    function clipInside(g, extra) {
      g.translate(B.x + B.ox, B.y); g.rotate(B.a); g.scale(B.s, B.s);
      bottlePath(g, true, extra); g.clip();
      g.scale(1 / B.s, 1 / B.s); g.rotate(-B.a); g.translate(-(B.x + B.ox), -B.y);
    }

    function paint(g, t) {
      pose(t < 0 ? 0 : t);
      if (t < 0) { B.a = 0; B.ox = 0; B.s = 1; B.y = 1220; }
      bg(g, t);
      header(g);
      if (t < 0) {
        bottleBack(g); bottleFront(g, 0);
        var since = t + COUNTDOWN, left = 3 - Math.floor(since / 1000), f = (since % 1000) / 1000;
        text(g, String(left), W / 2, 1160, 360 + f * 120, 800, rgba(C.sun, 1 - f * 0.6), true, "center", true);
        caption(g, "Get ready", "The draw starts in a moment");
        footer(g);
        return;
      }
      var top = [];
      slips.forEach(function (s) {
        if (s.mode === "in" || s.mode === "out" || t < P.write[s.i].at) return;
        var k = (t - P.write[s.i].at) / P.write[s.i].d, sx = W / 2, sy = 520;
        if (k < 0.5) {
          var appear = out(k / 0.12), letters = Math.floor(clamp((k - 0.08) / 0.32, 0, 1) * s.e.name.length);
          top.push(function () { slipFlat(g, sx, sy + (1 - appear) * 60, 620, 170, s.ang * 0.2, s, letters, appear); });
        } else if (k < 0.66) {
          var r = ease((k - 0.5) / 0.16);
          if (r < 0.6) top.push(function () { slipFlat(g, sx, sy, lerp(620, 140, r / 0.6), lerp(170, 50, r / 0.6), s.ang * 0.2, s, null, 1 - r * 0.6); });
          else top.push(function () { slipRolled(g, sx, sy, s.ang * 0.2 * (1 - r), s, 1.2); });
        } else {
          var f2 = clamp((k - 0.66) / 0.34, 0, 1), mouth = toWorld(0, -BH / 2 - SHOULDER - NECKH - 30);
          var fx = lerp(sx, mouth.x, ease(f2)), fy = lerp(sy, mouth.y, ease(f2)) - Math.sin(f2 * Math.PI) * 140;
          var ang = lerp(0, Math.PI / 2 + (s.i % 2 ? 0.25 : -0.25), ease(f2));
          top.push(function () { slipRolled(g, fx, fy, ang, s, lerp(1.2, 1, f2)); });
        }
      });
      var md = mode(t);
      bottleBack(g);
      g.save(); clipInside(g, md === "open" ? 600 : 0);
      slips.forEach(function (s) {
        if (s.mode !== "in") return;
        var wp = toWorld(s.x, s.y);
        slipRolled(g, wp.x, wp.y, B.a + s.ang, s, B.s);
      });
      g.restore();
      bottleFront(g, cork(t));

      var lastEnd = P.write[n - 1].at + P.write[n - 1].d;
      if (t < 1500) caption(g, "Writing every name", "One slip for every slot still waiting for the pot");
      else if (t < lastEnd) caption(g, "Into the bottle", slips.filter(function (s) { return t >= P.write[s.i].at; }).length + " of " + n);
      else if (t < P.shake) caption(g, "Closing the bottle");
      else if (t < P.shake + P.shakeD) caption(g, "Shaking", "Every slip has the same chance");
      else if (t < P.reveal) caption(g, "Picking one");
      top.forEach(function (fn) { fn(); });

      var ch = slips[pickIndex];
      if (ch.mode === "out" && t < P.reveal) {
        var pk = (t - P.pick) / P.pickD, e = clamp((pk - 0.32) / 0.3, 0, 1), topY = -BH / 2 - SHOULDER - NECKH - 80;
        if (e < 1) {
          var lx = lerp(ch.ox0, 0, ease(Math.min(1, e * 1.6))), ly = lerp(ch.oy0, topY, ease(e)), wp = toWorld(lx, ly);
          g.save(); clipInside(g, 600);
          slipRolled(g, wp.x, wp.y, B.a + lerp(ch.oang, Math.PI / 2, e), ch, 1);
          g.restore();
        } else {
          var sa = B.a, so = B.ox, ss = B.s, sy2 = B.y;
          pose(P.pick + 0.62 * P.pickD);
          var from = toWorld(0, topY), fromA = B.a + Math.PI / 2;
          B.a = sa; B.ox = so; B.s = ss; B.y = sy2;
          var u = clamp((pk - 0.62) / 0.38, 0, 1);
          var wx = lerp(from.x, W / 2, ease(u)), wy = lerp(from.y, 820, ease(u)) - Math.sin(u * Math.PI) * 120;
          slipRolled(g, wx, wy, lerp(fromA, Math.PI * 2, ease(u)), ch, lerp(1, 1.3, u));
        }
      }
      if (t >= P.reveal) {
        var rk = t - P.reveal;
        g.save();
        g.beginPath(); g.rect(0, 350, W, H - 350); g.clip();
        g.translate(W / 2, 800); g.rotate(t / 4000);
        g.fillStyle = rgba(C.sun, clamp(rk / 600, 0, 1) * 0.22);
        for (var i = 0; i < 14; i++) {
          g.rotate(Math.PI * 2 / 14);
          g.beginPath(); g.moveTo(0, 0); g.lineTo(-60, -900); g.lineTo(60, -900); g.closePath(); g.fill();
        }
        g.restore();
        var op = back(rk / 700);
        if (rk < 350) slipRolled(g, W / 2, 800, 0, ch, 1.3 + rk / 350 * 0.4);
        else slipFlat(g, W / 2, 800, lerp(180, 860, op), lerp(60, 250, op), 0, ch, null, 1);
        var a = clamp((rk - 700) / 500, 0, 1);
        if (a > 0) {
          text(g, "TAKES THE POT THIS MONTH", W / 2, 1010, 46, 800, rgba(C.sun, a));
          text(g, o.pot, W / 2, 1110, 96, 800, "rgba(255,255,255," + a + ")", true);
        }
      }
      confetti.forEach(function (b) {
        g.save(); g.translate(b.x, b.y); g.rotate(b.r);
        g.fillStyle = rgba(b.c, clamp(b.life, 0, 1));
        g.fillRect(-b.w / 2, -b.h / 2, b.w, b.h * Math.abs(Math.cos(b.r * 2)));
        g.restore();
      });
      footer(g);
    }

    return {
      plan: P,
      picked: function () { return order[pickIndex]; },
      length: P.end,
      advanceTo: advanceTo,
      paint: paint,
      setStart: function (t) { simT = t; }
    };
  }

  /* ---------------------------------------------------------------- on the page */

  function mount(canvas, o) {
    var g = canvas.getContext("2d"), scene = null, raf = 0, t0 = 0, from = 0, snd = null, api = {};
    function fit() {
      var r = canvas.getBoundingClientRect(), dpr = Math.min(window.devicePixelRatio || 1, 2);
      var w = Math.max(270, Math.round(r.width * dpr)), h = Math.round(w * H / W);
      if (canvas.width !== w) { canvas.width = w; canvas.height = h; }
    }
    function frame(now) {
      var t = from + (now - t0);
      scene.advanceTo(t);
      g.setTransform(canvas.width / W, 0, 0, canvas.height / H, 0, 0);
      scene.paint(g, t);
      if (t < scene.length) raf = requestAnimationFrame(frame);
      else { raf = 0; if (snd) { snd.stop(); snd = null; } if (api.onEnd) api.onEnd(scene.picked()); }
    }
    api.play = function (opt) {
      opt = opt || {};
      api.stop();
      fit();
      scene = Scene(o);
      from = opt.countdown ? -COUNTDOWN : 0;
      scene.setStart(from);
      if (opt.sound) { snd = makeSound(); if (snd) snd.play(scene.plan, from); }
      t0 = performance.now();
      raf = requestAnimationFrame(frame);
    };
    api.stop = function () {
      if (raf) cancelAnimationFrame(raf);
      raf = 0;
      if (snd) { snd.stop(); snd = null; }
    };
    api.still = function (t) {                     /* one frame, for reduced motion */
      fit();
      scene = Scene(o);
      scene.setStart(0);
      for (var x = 0; x <= t; x += 1000) scene.advanceTo(x);
      scene.advanceTo(t);
      g.setTransform(canvas.width / W, 0, 0, canvas.height / H, 0, 0);
      scene.paint(g, t);
    };
    api.length = function () { return makePlan(o.entries.length).end; };
    api.playing = function () { return !!raf; };
    window.addEventListener("resize", function () { if (!raf && scene) return; fit(); });
    return api;
  }

  window.KureeDraw = { mount: mount };
})();
