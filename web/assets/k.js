/* The members' page for one kuri: who paid, who has not, late fines, who
   took the pot, the numbers, the full ledger and the rules. Read only; the
   admins change the kuri in the Kuree app. The page arrives with the kuri
   inside it (#seed) and checks for a newer copy when it is opened again. */
(function () {
  "use strict";
  var MEN = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  var MSH = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  var app = document.getElementById("kapp");
  var seed = null;
  try { seed = JSON.parse(document.getElementById("seed").textContent); } catch (e) { seed = null; }
  if (!app || !seed || !seed.data) return;

  var data, PAYERS, SLOTS, POT, sel = null, lyear = null, at = seed.updated_at;

  function esc(v) { return String(v == null ? "" : v).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); }
  function group(n) {
    var s = String(Math.round(Math.abs(n)));
    if (s.length > 3) {
      var last = s.slice(-3), rest = s.slice(0, -3), parts = [];
      while (rest.length > 2) { parts.unshift(rest.slice(-2)); rest = rest.slice(0, -2); }
      if (rest) parts.unshift(rest);
      s = parts.join(",") + "," + last;
    }
    return (n < 0 ? "-" : "") + s;
  }
  function money(n) { return "₹" + group(Number(n) || 0); }
  function ord(n) { var m = n % 100; if (m >= 11 && m <= 13) return n + "th"; return n + (["th", "st", "nd", "rd"][n % 10] || "th"); }
  function svgi(id, cls) { return '<svg class="' + (cls || "icon") + '" aria-hidden="true"><use href="#' + id + '"/></svg>'; }
  function dim(y, m) { return new Date(y, m + 1, 0).getDate(); }
  function inMonth(n, day, add) {
    var b = new Date(data.startYear, data.startMonth - 1 + (n - 1) + (add || 0), 1);
    return new Date(b.getFullYear(), b.getMonth(), Math.min(day, dim(b.getFullYear(), b.getMonth())));
  }
  function cdate(n) { return inMonth(n, data.collectDay || 20); }
  function dline(n) {
    var d = inMonth(n, data.lastDay || 25, (data.lastDay || 25) < (data.collectDay || 20) ? 1 : 0);
    return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59);
  }
  function mlabel(n) { var d = cdate(n); return MEN[d.getMonth()] + " " + d.getFullYear(); }
  function msh(n) { return MSH[cdate(n).getMonth()]; }
  function FINE() { return Number(data.fine) || 0; }
  function nameOf(p) { var x = (data.people || []).filter(function (q) { return q.id === p.person; })[0]; return x ? x.name : "Someone"; }
  function slotName(s) { var o = SLOTS[s - 1]; return o ? o.name : ""; }
  function paid(m, id) { return !!(m.paid && m.paid[id]); }
  function fined(m, id) { return !!(m.fines && m.fines[id]); }
  function paidSum(m) { var t = 0; PAYERS.forEach(function (p) { if (paid(m, p.id)) t += p.amt; }); return t; }
  function fineSum(m) { var t = 0; PAYERS.forEach(function (p) { if (fined(m, p.id)) t += FINE(); }); return t; }
  function allFines() { var t = 0; data.months.forEach(function (m) { t += fineSum(m); }); return t; }
  function status(m) {
    if (PAYERS.length && PAYERS.every(function (p) { return paid(m, p.id); }) && m.winner) return "done";
    return new Date() >= cdate(m.n) ? "open" : "soon";
  }
  function drawn() { var o = {}; data.months.forEach(function (m) { if (m.winner) o[m.winner] = m.n; }); return o; }
  function daysUntil(d) {
    var a = new Date(); a.setHours(0, 0, 0, 0);
    return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - a) / 86400000);
  }
  /* the collection date is what the metric shows, so count to that; once it
     has passed, count to the last day to pay instead */
  function nextNote(n) {
    var dc = daysUntil(cdate(n));
    if (dc > 1) return "in " + dc + " days";
    if (dc === 1) return "tomorrow";
    if (dc === 0) return "today";
    var dd = daysUntil(dline(n));
    if (dd > 1) return dd + " days left to pay";
    if (dd === 1) return "last day tomorrow";
    if (dd === 0) return "pay by midnight today";
    return "deadline passed";
  }
  function count() { return data.months.length; }
  function firstOpen() { for (var i = 0; i < count(); i++) { if (status(data.months[i]) !== "done") return i + 1; } return count(); }
  function currentMonth() {
    var now = new Date();
    var n = (now.getFullYear() * 12 + now.getMonth()) - (data.startYear * 12 + (data.startMonth - 1)) + 1;
    return Math.min(count(), Math.max(1, n));
  }
  function part(p) {
    var s = data.share;
    if (!s || p.amt >= s) return "";
    if (p.amt * 2 === s) return "&frac12; share";
    if (p.amt * 3 === s) return "&#8531; share";
    if (p.amt * 4 === s) return "&frac14; share";
    return esc(money(p.amt)) + " share";
  }
  function yearPicker(years, on) {
    return '<div class="ypick">' +
      '<button class="ypick__btn" type="button" aria-haspopup="listbox" aria-expanded="false"' +
        ' aria-label="Year shown: ' + on + '. Pick another."><span>' + on + "</span>" + svgi("i-chev") + "</button>" +
      '<div class="ypick__menu" role="listbox" aria-label="Year">' +
      years.map(function (y) {
        return '<button class="ypick__opt' + (y === on ? " on" : "") + '" type="button" role="option"' +
          ' aria-selected="' + (y === on) + '" data-v="' + y + '">' + y + (y === on ? svgi("i-check") : "") + "</button>";
      }).join("") + "</div></div>";
  }
  function hold(q, fn) {
    var el = app.querySelector(q), top = el ? el.getBoundingClientRect().top : null;
    fn();
    if (top === null) return;
    var fix = function () {
      var e2 = app.querySelector(q);
      if (!e2) return;
      var d = e2.getBoundingClientRect().top - top;
      if (d) window.scrollBy({ top: d, behavior: "instant" });
    };
    fix();
    requestAnimationFrame(fix);
  }

  /* ---------- charts ---------- */
  function barChart() {
    var n = count(), W = Math.max(760, n * 52), H = 200, pad = 26, gap = n > 18 ? 5 : 9;
    var bw = (W - pad * 2 - gap * (n - 1)) / n, max = POT || 1;
    var o = '<svg viewBox="0 0 ' + W + " " + (H + 34) + '" role="img" aria-label="Collected each month">';
    [0, 0.5, 1].forEach(function (f) {
      var y = pad + (H - pad * 2) * (1 - f);
      o += '<line x1="' + pad + '" x2="' + (W - pad) + '" y1="' + y + '" y2="' + y + '" stroke="var(--border)" stroke-width="1"/>';
      o += '<text x="' + (pad - 6) + '" y="' + (y + 4) + '" text-anchor="end" font-size="10" fill="var(--muted)" font-family="Manrope,sans-serif">' +
        (f ? (max * f >= 1000 ? Math.round(max * f / 1000) + "k" : Math.round(max * f)) : "0") + "</text>";
    });
    data.months.forEach(function (m, i) {
      var v = paidSum(m), fn = fineSum(m);
      var h = (H - pad * 2) * (v / max), x = pad + i * (bw + gap);
      /* a fine is tiny next to the pot, so it gets a readable minimum cap */
      var fh = fn ? Math.max(5, (H - pad * 2) * (fn / max)) : 0;
      var y = pad + (H - pad * 2) - h - fh;
      var lbl = fn ? money(v + fn) + " incl. " + money(fn) + " fine" : money(v);
      o += '<rect x="' + x + '" y="' + pad + '" width="' + bw + '" height="' + (H - pad * 2) + '" rx="5" fill="var(--surface-2)"/>';
      if (h > 0) o += '<g class="mk-hit" tabindex="0" role="img" aria-label="' + mlabel(m.n) + ": " + lbl + '"' +
        ' data-tip="' + mlabel(m.n) + "|" + lbl + '"><title>' + mlabel(m.n) + ": " + lbl + "</title>" +
        '<rect class="chart__bar" x="' + x + '" y="' + (y + fh) + '" width="' + bw + '" height="' + Math.max(h, 3) + '" rx="5" fill="' +
        (m.n === sel ? "var(--brand-500)" : "var(--brand-300)") + '" style="transition-delay:' + (i * 30) + 'ms"/>' +
        (fn ? '<rect class="chart__bar" x="' + x + '" y="' + y + '" width="' + bw + '" height="' + fh + '" rx="3" fill="var(--bad)"' +
            ' style="transition-delay:' + (i * 30) + 'ms"/>' : "") + "</g>";
      o += '<text x="' + (x + bw / 2) + '" y="' + (H - pad + 16) + '" text-anchor="middle" font-size="10" font-family="Manrope,sans-serif" font-weight="' + (m.n === sel ? 700 : 500) + '" fill="' + (m.n === sel ? "var(--text)" : "var(--muted)") + '">' + msh(m.n) + "</text>";
      o += '<text x="' + (x + bw / 2) + '" y="' + (H - pad + 30) + '" text-anchor="middle" font-size="9" fill="var(--muted)" font-family="Manrope,sans-serif">' + m.n + "</text>";
    });
    return o + "</svg>";
  }
  function donut(parts, center, sub) {
    var C = 2 * Math.PI * 52, off = 0;
    var o = '<svg viewBox="0 0 132 132" aria-hidden="true"><circle cx="66" cy="66" r="52" fill="none" stroke="var(--surface-2)" stroke-width="15"/>';
    parts.forEach(function (p, i) {
      if (p.v <= 0) return;
      var len = C * p.v;
      o += '<circle class="chart__ring mk-hit" cx="66" cy="66" r="52" fill="none" stroke="' + p.c + '" stroke-width="15"' +
        ' stroke-linecap="butt" data-dash="' + len.toFixed(2) + " " + (C - len).toFixed(2) + '"' +
        ' stroke-dashoffset="' + (-off).toFixed(2) + '" transform="rotate(-90 66 66)" tabindex="0" role="img"' +
        (p.k ? ' aria-label="' + p.k + ": " + p.lbl + '" data-tip="' + p.k + "|" + p.lbl + '"' : "") +
        ' style="transition-delay:' + (i * 120) + 'ms">' + (p.k ? "<title>" + p.k + ": " + p.lbl + "</title>" : "") + "</circle>";
      off += len;
    });
    return '<div class="donut">' + o + "</svg><div><b>" + center + "</b><span>" + sub + "</span></div></div>";
  }

  /* ---------- render ---------- */
  function prepare(d) {
    data = d;
    data.months = (data.months || []).slice().sort(function (a, b) { return a.n - b.n; });
    data.months.forEach(function (m, i) { m.n = i + 1; m.paid = m.paid || {}; m.fines = m.fines || {}; });
    PAYERS = (data.payers || []).slice().sort(function (a, b) { return a.slot - b.slot || (a.id < b.id ? -1 : 1); })
      .map(function (p) { return { id: p.id, slot: p.slot, amt: Number(p.amt) || 0, name: nameOf(p), part: p.amt < data.share }; });
    SLOTS = [];
    for (var s = 1; s <= (data.slots || data.months.length); s++) {
      var ps = PAYERS.filter(function (p) { return p.slot === s; });
      SLOTS.push({ slot: s, name: ps.map(function (p) { return p.name; }).join(" / ") || "Slot " + s });
    }
    POT = (Number(data.share) || 0) * SLOTS.length;
  }

  function render() {
    var w = drawn(), done = 0, n = count();
    data.months.forEach(function (m) { if (status(m) === "done") done++; });
    if (!sel || sel > n) sel = currentMonth();
    var m = data.months[sel - 1], nx = firstOpen();
    var got = paidSum(m), fines = fineSum(m), pct = POT ? Math.round(got / POT * 100) : 0;
    var h = [];

    h.push('<section class="wrap ksum"><dl class="metrics">' +
      '<div class="metric metric--hi"><dt>Monthly pot</dt><dd class="num">' + money(POT) + "</dd><small>" + money(data.share) + " per share</small></div>" +
      '<div class="metric"><dt>Months settled</dt><dd class="num">' + done + "/" + n + "</dd></div>" +
      '<div class="metric"><dt>Next collection</dt><dd class="num">' + msh(nx) + " " + cdate(nx).getDate() + "</dd><small>" + nextNote(nx) + "</small></div>" +
      '<div class="metric"><dt>Draws left</dt><dd class="num">' + (SLOTS.length - Object.keys(w).length) + "</dd><small>slots yet to receive</small></div>" +
      (FINE() ? '<div class="metric"><dt>Fines collected</dt><dd class="num">' + money(allFines()) + "</dd><small>" + money(FINE()) + " each</small></div>" : "") +
      "</dl></section>");

    h.push('<section class="sec sec--tight" style="padding-top:44px"><div class="wrap">' +
      '<div class="sechead"><h2>Months</h2></div><div class="railwrap"><div class="rail" role="tablist" aria-label="Chit months">');
    data.months.forEach(function (x) {
      var st = status(x), lbl = st === "done" ? "Settled" : (st === "open" ? "In progress" : "Upcoming");
      h.push('<button class="chip ' + st + '" role="tab" data-month="' + x.n + '" aria-current="' + (x.n === sel) + '">' +
        "<small>Month " + x.n + "</small><b>" + msh(x.n) + " " + cdate(x.n).getFullYear() + "</b><i>" + lbl + "</i></button>");
    });
    h.push("</div></div>");

    var winCtl = '<span class="wtag' + (m.winner ? "" : " wtag--none") + '">' + (m.winner ? svgi("i-trophy") + esc(slotName(m.winner)) : "Not decided yet") + "</span>" +
      (m.winner ? '<span class="win__amt">Takes ' + money(POT + fines) + (fines ? " (pot + " + money(fines) + " fine)" : "") + "</span>" : "");
    var dl = dline(m.n);
    h.push('<div style="margin-top:20px" class="mcard"><div class="mcard__head"><div>' +
      '<div class="mnav">' +
        '<button class="ibtn" type="button" data-step="-1"' + (sel <= 1 ? " disabled" : "") + ' aria-label="Previous month">' + svgi("i-prev") + "</button>" +
        "<h3>Month " + m.n + ", " + mlabel(m.n) + "</h3>" +
        '<button class="ibtn" type="button" data-step="1"' + (sel >= n ? " disabled" : "") + ' aria-label="Next month">' + svgi("i-next") + "</button>" +
      "</div>" +
      '<div class="mcard__meta"><span>Collection ' + ord(cdate(m.n).getDate()) + "</span><span>Last date " + ord(dl.getDate()) + ", midnight</span>" +
        (FINE() ? "<span>Late fine " + money(FINE()) + "</span>" : "") + "</div>" +
      '<div class="mcard__meta"><span><b class="num">' + money(got) + '</b> of <span class="num">' + money(POT) + "</span> collected</span>" +
      (fines ? '<span class="num">+ ' + money(fines) + " in fines</span>" : "") + "</div>" +
      '<div class="bar" role="img" aria-label="' + pct + '% collected"><i style="width:' + pct + '%"></i></div></div>' +
      '<div class="win"><span class="win__lbl">Takes the pot</span>' + winCtl + "</div></div>");

    h.push('<div class="plist"><div class="plist__head">' +
      '<span class="ph-slot" aria-hidden="true"></span><span>Member</span>' +
      '<span class="ph-facts"><span>Payment</span><span>Draw</span><span>Amount due</span></span>' +
      "</div>");
    PAYERS.forEach(function (p) {
      var isw = m.winner === p.slot, pd = paid(m, p.id), fd = fined(m, p.id);
      var due = p.amt + (fd ? FINE() : 0);
      var dw = w[p.slot];
      var draw = isw ? '<span class="badge badge--win" title="Took the pot in month ' + m.n + '" aria-label="Took the pot in month ' + m.n + '">' + svgi("i-trophy") + m.n + "</span>"
        : (dw ? '<span class="badge badge--drawn" title="Took the pot in month ' + dw + '" aria-label="Took the pot in month ' + dw + '">' + svgi("i-trophy") + dw + "</span>"
          : '<span class="fval fval--mute">Waiting</span>');
      var pl = part(p);
      h.push('<div class="prow' + (isw ? " is-win" : "") + '">' +
        '<div class="prow__slot num">' + p.slot + "</div>" +
        '<div class="prow__name" title="' + esc(p.name) + '">' + esc(p.name) + (pl ? ' <span class="badge badge--plain">' + pl + "</span>" : "") + "</div>" +
        '<dl class="prow__facts">' +
          '<div><dt>Payment</dt><dd><span class="badge ' + (pd ? "badge--ok" : "badge--wait") + '">' + (pd ? "Paid" : "Pending") + "</span>" +
            (fd ? ' <span class="badge badge--bad" title="Paid after the last date, ' + money(FINE()) + ' late fine">Late</span>' : "") + "</dd></div>" +
          '<div><dt>Amount due</dt><dd><span class="fval num">' + money(due) + "</span>" + (fd ? " <small>incl. fine</small>" : "") + "</dd></div>" +
          '<div class="f-draw"><dt>Draw</dt><dd>' + draw + "</dd></div>" +
        "</dl></div>");
    });
    h.push("</div></div></div></section>");

    var left = SLOTS.filter(function (x) { return !w[x.slot]; }), nd = Object.keys(w).length;
    h.push('<section class="sec sec--tight"><div class="wrap"><div class="sechead"><h2>Numbers</h2></div>' +
      '<div class="chartgrid">' +
      '<div class="chart"><h3>Collected each month</h3><p class="sub">' + money(POT) + " due every month</p>" + barChart() +
      '<p class="sr">' + data.months.map(function (x) { return msh(x.n) + " " + money(paidSum(x)); }).join(", ") + "</p>" +
      '<div class="legend"><span><i style="background:var(--brand-500)"></i>Month ' + m.n + "</span>" +
      '<span><i style="background:var(--brand-300)"></i>Paid</span>' +
      (allFines() ? '<span><i style="background:var(--bad)"></i>Late fine</span>' : "") +
      '<span><i style="background:var(--surface-2)"></i>Pending</span></div></div>' +
      '<div class="chart"><h3>This month</h3><p class="sub">' + mlabel(m.n) + "</p>" +
      donut([{ v: POT ? got / POT : 0, c: "var(--brand-500)", k: "Paid in", lbl: money(got) },
             { v: POT ? (POT - got) / POT : 0, c: "var(--brand-200)", k: "Still to come", lbl: money(POT - got) }], pct + "%", money(got) + " / " + money(POT)) +
      '<div class="legend"><span><i style="background:var(--brand-500)"></i>Paid</span><span><i style="background:var(--brand-200)"></i>Pending</span></div></div>' +
      "</div>");
    h.push('<div class="chartgrid" style="margin-top:16px">' +
      '<div class="chart"><h3>Still to receive</h3><p class="sub">Slots that have not been drawn yet</p>' +
      '<div class="pills">' + (left.length ? left.map(function (x) { return '<span class="pill">' + x.slot + ". " + esc(x.name) + "</span>"; }).join("") : '<span class="pill">Every slot has taken the pot</span>') + "</div></div>" +
      '<div class="chart"><h3>Drawn</h3><p class="sub">out of ' + SLOTS.length + " slots</p>" +
      donut([{ v: nd / SLOTS.length, c: "var(--brand-500)", k: "Drawn", lbl: nd + " slots" },
             { v: (SLOTS.length - nd) / SLOTS.length, c: "var(--brand-200)", k: "Still to draw", lbl: (SLOTS.length - nd) + " slots" }], nd + "/" + SLOTS.length, "Drawn") +
      '<div class="legend"><span><i style="background:var(--brand-500)"></i>Drawn</span><span><i style="background:var(--brand-200)"></i>Remaining</span></div></div>' +
      "</div></div></section>");

    /* the ledger is read a year at a time, always as a full twelve months */
    var lyears = [], byYM = {};
    data.months.forEach(function (x) {
      var d = cdate(x.n), y = d.getFullYear();
      if (lyears.indexOf(y) < 0) lyears.push(y);
      byYM[y + "-" + (d.getMonth() + 1)] = x;
    });
    if (lyears.indexOf(lyear) < 0) lyear = cdate(sel).getFullYear();
    var lmonths = [];
    for (var lm = 1; lm <= 12; lm++) lmonths.push({ m: lm, b: byYM[lyear + "-" + lm] || null });
    h.push('<section class="sec sec--tight"><div class="wrap"><div class="sechead sechead--row">' +
      "<div><h2>Full ledger</h2>" +
      "<p>Every month, every member.<br>A trophy marks the month that slot took the pot.</p></div>" +
      '<div class="ledtools">' + yearPicker(lyears, lyear) + "</div></div>" +
      '<div class="chart" style="padding:0"><div class="scroll"><table class="ledger"><thead><tr><th class="who">Name</th>');
    lmonths.forEach(function (x) {
      h.push("<th" + (x.b ? "" : ' class="th--off"') + '><abbr title="' + MEN[x.m - 1] + " " + lyear + (x.b ? ", month " + x.b.n : "") + '">' + MSH[x.m - 1] + "</abbr></th>");
    });
    h.push("</tr></thead><tbody>");
    PAYERS.forEach(function (p) {
      h.push('<tr><td class="who">' + p.slot + ". " + esc(p.name) + "</td>");
      lmonths.forEach(function (mm) {
        if (!mm.b) { h.push('<td><span class="mk n" role="img" title="Outside the chit" aria-label="Outside the chit">' + svgi("i-dot") + "</span></td>"); return; }
        var x = mm.b, pd = paid(x, p.id), fd = fined(x, p.id), wn = x.winner === p.slot;
        var lb = fd ? "Paid late, fine" : (pd ? "Paid" : "Not paid");
        if (wn) {
          h.push('<td><span class="mk w" role="img" title="Took the pot in month ' + x.n + '" aria-label="Took the pot">' + svgi("i-trophy") + "</span></td>");
        } else if (fd) {
          var ft = "Paid after the last date, " + money(FINE()) + " late fine added to the pot";
          h.push('<td class="td--2"><span class="mk y" role="img" aria-label="Paid">' + svgi("i-check") + "</span>" +
            '<span class="mk f" role="img" title="' + ft + '" aria-label="' + ft + '">' + svgi("i-alert") + "</span></td>");
        } else {
          h.push('<td><span class="mk ' + (pd ? "y" : "n") + '" role="img" title="' + lb + '" aria-label="' + lb + '">' + svgi(pd ? "i-check" : "i-dot") + "</span></td>");
        }
      });
      h.push("</tr>");
    });
    h.push('</tbody></table></div></div><p class="hint">Showing ' + lyear + ".<br>Swipe the table sideways to see every month.</p></div></section>");

    /* rules */
    var splits = [];
    SLOTS.forEach(function (s) {
      var ps = PAYERS.filter(function (p) { return p.slot === s.slot; });
      if (ps.length < 2) return;
      var same = ps.every(function (p) { return p.amt === ps[0].amt; });
      splits.push(same ? ps.map(function (p) { return esc(p.name); }).join(" + ") + " " + money(ps[0].amt) + " each"
        : ps.map(function (p) { return esc(p.name) + " " + money(p.amt); }).join(", "));
    });
    var cd = data.collectDay || 20, ld = data.lastDay || 25;
    h.push('<section class="sec sec--tight"><div class="wrap"><div class="sechead"><h2>Rules</h2></div>' +
      '<dl class="metrics">' +
      '<div class="metric"><dt>Share per slot</dt><dd class="num">' + money(data.share) + "</dd>" + (splits.length ? "<small>" + splits.join("<br>") + "</small>" : "<small>every month</small>") + "</div>" +
      '<div class="metric"><dt>Collection day</dt><dd>' + ord(cd) + "</dd><small>every month</small></div>" +
      '<div class="metric"><dt>Last date</dt><dd>' + ord(ld) + "</dd><small>Midnight" + (ld < cd ? ", the month after" : "") + "</small></div>" +
      (FINE() ? '<div class="metric"><dt>Late fine</dt><dd class="num">' + money(FINE()) + "</dd><small>goes to that month&rsquo;s pot</small></div>" : "") +
      "</dl></div></section>");

    app.innerHTML = h.join("");
    charts(app);
    var yp = app.querySelector(".ypick");
    if (yp) yp.addEventListener("yearpick", function (e) { lyear = e.detail; hold(".ledtools", render); });
    app.querySelectorAll(".mnav button[data-step]").forEach(function (b) {
      b.addEventListener("click", function () {
        var next = sel + (+b.getAttribute("data-step"));
        if (next < 1 || next > count()) return;
        sel = next; hold(".mnav", render);
      });
    });
    /* land the month rail on the month showing, not always on month 1 */
    requestAnimationFrame(function () {
      var box = app.querySelector(".rail"), el = app.querySelector('.rail .chip[aria-current="true"]');
      if (!box || !el) return;
      var b = box.getBoundingClientRect(), r = el.getBoundingClientRect();
      box.scrollLeft += (r.left - b.left) - (b.width - r.width) / 2;
    });
  }

  app.addEventListener("click", function (e) {
    var b = e.target.closest("button");
    if (!b) return;
    if (b.dataset.month) { sel = parseInt(b.dataset.month, 10); render(); }
  });

  /* ---------- chart behaviour: reveal on scroll, tooltips on hover and tap ---------- */
  var tipsOn = false;
  function charts(root) {
    reveal(root);
    if (!tipsOn) { tooltips(); tipsOn = true; }
    yearpick(root);
  }
  function tooltips() {
    var tip = document.createElement("div"), open = null;
    tip.id = "charttip"; tip.className = "ctip"; tip.setAttribute("role", "status");
    document.body.appendChild(tip);
    function show(el, x, y) {
      var parts = (el.getAttribute("data-tip") || "").split("|");
      if (parts.length < 2) return;
      tip.innerHTML = "<b>" + parts[0] + "</b><span>" + parts[1] + "</span>";
      tip.classList.add("on");
      var box = el.getBoundingClientRect(), tw = tip.offsetWidth, th = tip.offsetHeight;
      var left = (x == null ? box.left + box.width / 2 : x) - tw / 2;
      var top = (y == null ? box.top : y) - th - 12;
      if (top < 8) top = (y == null ? box.bottom : y) + 14;
      tip.style.left = Math.max(8, Math.min(left, window.innerWidth - tw - 8)) + "px";
      tip.style.top = top + "px";
      if (open && open !== el) open.classList.remove("mk-on");
      el.classList.add("mk-on");
      open = el;
    }
    function hide() { tip.classList.remove("on"); if (open) { open.classList.remove("mk-on"); open = null; } }
    app.addEventListener("pointerover", function (e) { if (e.pointerType === "touch") return; var el = e.target.closest(".mk-hit"); if (el) show(el, e.clientX, e.clientY); });
    app.addEventListener("pointerout", function (e) { if (e.pointerType === "touch") return; if (e.target.closest(".mk-hit")) hide(); });
    app.addEventListener("pointerdown", function (e) {
      var el = e.target.closest(".mk-hit");
      if (!el) return hide();
      if (open === el) return hide();
      show(el, e.clientX, e.clientY);
    });
    app.addEventListener("focusin", function (e) { var el = e.target.closest(".mk-hit"); if (el) show(el, null, null); });
    app.addEventListener("focusout", hide);
    document.addEventListener("pointerdown", function (e) { if (!e.target.closest(".mk-hit")) hide(); }, true);
    window.addEventListener("scroll", hide, { passive: true });
    window.addEventListener("resize", hide);
  }
  function reveal(root) {
    var cards = root.querySelectorAll(".chart");
    var play = function (card) {
      card.classList.add("is-in");
      card.querySelectorAll(".chart__ring").forEach(function (c) { c.style.strokeDasharray = c.getAttribute("data-dash"); });
    };
    if (!("IntersectionObserver" in window)) { cards.forEach(play); return; }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { if (e.isIntersecting) { play(e.target); io.unobserve(e.target); } });
    }, { threshold: 0.2, rootMargin: "0px 0px -40px 0px" });
    cards.forEach(function (c) { io.observe(c); });
  }
  function yearpick(root) {
    root.querySelectorAll(".ypick").forEach(function (box) {
      var btn = box.querySelector(".ypick__btn"), menu = box.querySelector(".ypick__menu");
      if (!btn || !menu) return;
      function open(on) {
        box.classList.toggle("is-open", on);
        btn.setAttribute("aria-expanded", on ? "true" : "false");
        if (on) { var cur = menu.querySelector('[aria-selected="true"]'); (cur || menu.querySelector(".ypick__opt")).focus({ preventScroll: true }); }
      }
      btn.addEventListener("click", function (e) { e.stopPropagation(); open(!box.classList.contains("is-open")); });
      menu.addEventListener("click", function (e) {
        var o = e.target.closest(".ypick__opt");
        if (!o) return;
        open(false);
        box.dispatchEvent(new CustomEvent("yearpick", { bubbles: true, detail: +o.getAttribute("data-v") }));
      });
      menu.addEventListener("keydown", function (e) {
        var opts = [].slice.call(menu.querySelectorAll(".ypick__opt")), i = opts.indexOf(document.activeElement);
        if (e.key === "ArrowDown" || e.key === "ArrowUp") {
          e.preventDefault();
          var nn = i + (e.key === "ArrowDown" ? 1 : -1);
          if (nn < 0) nn = opts.length - 1;
          if (nn >= opts.length) nn = 0;
          opts[nn].focus();
        } else if (e.key === "Escape") { open(false); btn.focus({ preventScroll: true }); }
      });
      document.addEventListener("click", function (e) { if (!box.contains(e.target)) open(false); });
    });
  }

  /* ---------- a newer copy when the page is opened again ---------- */
  function refresh() {
    if (!seed.token) return;
    fetch("/rest/v1/rpc/shared_kuri", {
      method: "POST", cache: "no-store",
      headers: { "Content-Type": "application/json", apikey: "public" },
      body: JSON.stringify({ token: seed.token })
    }).then(function (r) { return r.ok ? r.json() : null; }).then(function (j) {
      if (!j || !j.data) return;
      if (j.updated_at === at) return;
      at = j.updated_at;
      prepare(j.data);
      render();
      stampUpdated();
    }).catch(function () { /* the copy on the page stays */ });
  }
  document.addEventListener("visibilitychange", function () { if (document.visibilityState === "visible") refresh(); });

  function stampUpdated() {
    var el = document.querySelector(".kbar__upd"), d = at ? new Date(at) : null;
    if (!el || !d || isNaN(d)) return;
    var h = d.getHours(), mi = d.getMinutes();
    el.textContent = "Updated " + d.getDate() + " " + MSH[d.getMonth()] + ", " + ((h % 12) || 12) + ":" + (mi < 10 ? "0" : "") + mi + (h < 12 ? " am" : " pm");
  }

  prepare(seed.data);
  render();
  stampUpdated();
})();
