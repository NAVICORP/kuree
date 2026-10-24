/* The Kuree team's inbox of feature requests (/admin/requests).
   Sign in with an email code (or a password), then read and answer every
   request. The database decides who may see them; this page only asks. */
(function () {
  'use strict';

  var KEY = 'kuree.admin.session';
  var STATUSES = [['', 'All'], ['new', 'New'], ['planned', 'Planned'], ['done', 'Done'], ['declined', 'Declined']];
  var LABEL = { new: 'New', planned: 'Planned', done: 'Done', declined: 'Declined' };
  var IMPORTANCE = { nice: 'Nice to have', important: 'Important', must: 'Must have' };
  var session = null;
  var filter = '';
  var pendingEmail = '';

  function $(id) { return document.getElementById(id); }
  function show(el, on) { if (el) el.hidden = !on; }
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  function save(s) {
    session = s;
    try {
      if (s) sessionStorage.setItem(KEY, JSON.stringify(s)); else sessionStorage.removeItem(KEY);
    } catch (e) { /* private mode: stays signed in until the tab closes */ }
  }
  function restore() {
    try { return JSON.parse(sessionStorage.getItem(KEY) || 'null'); } catch (e) { return null; }
  }

  function toSession(j) {
    if (!j || typeof j.access_token !== 'string' || typeof j.refresh_token !== 'string') return null;
    var exp = typeof j.expires_at === 'number' ? j.expires_at * 1000
      : Date.now() + (typeof j.expires_in === 'number' ? j.expires_in : 3000) * 1000;
    return { access: j.access_token, refresh: j.refresh_token, exp: exp, email: (j.user && j.user.email) || '' };
  }

  function nice(status, j) {
    var m = (j && (j.message || j.msg || j.error_description || j.error)) || '';
    var s = String(m).toLowerCase();
    if (status === 0) return 'No connection. Check your internet and try again.';
    if (s.indexOf('rate limit') >= 0 || s.indexOf('too many') >= 0) return 'Too many tries. Wait a minute and try again.';
    if ((s.indexOf('invalid') >= 0 || s.indexOf('expired') >= 0) && (s.indexOf('token') >= 0 || s.indexOf('otp') >= 0 || s.indexOf('code') >= 0)) {
      return 'That code is wrong or has expired. Ask for a new one.';
    }
    if (s.indexOf('invalid login credentials') >= 0) return 'That email and password do not match.';
    if (m) return String(m);
    return status >= 500 ? 'The Kuree server had a problem. Try again in a minute.' : 'Something went wrong (' + status + ').';
  }

  function call(method, path, body, withUser) {
    var headers = { apikey: 'public', 'Content-Type': 'application/json', Accept: 'application/json', 'X-Client-Info': 'kuree-admin/1.0' };
    headers.Authorization = 'Bearer ' + (withUser && session ? session.access : 'public');
    return fetch(path, { method: method, headers: headers, body: body == null ? undefined : JSON.stringify(body) })
      .then(function (r) {
        return r.text().then(function (t) {
          var j = null;
          try { j = t ? JSON.parse(t) : null; } catch (e) { j = null; }
          if (r.ok) return j;
          var err = new Error(nice(r.status, j));
          err.status = r.status;
          err.code = j && j.code;
          throw err;
        });
      }, function () {
        var err = new Error(nice(0));
        err.status = 0;
        throw err;
      });
  }

  function fresh() {
    if (!session || session.exp - Date.now() > 60000) return Promise.resolve();
    return call('POST', '/auth/v1/token?grant_type=refresh_token', { refresh_token: session.refresh }, false)
      .then(function (j) {
        var s = toSession(j);
        if (!s) throw new Error('Sign in again.');
        if (!s.email) s.email = session.email;
        save(s);
      });
  }

  function rpc(fn, args) {
    return fresh().then(function () { return call('POST', '/rest/v1/rpc/' + fn, args || {}, true); });
  }

  // ---------------------------------------------------------------- signing in

  function signinError(msg) {
    var e = $('admErr');
    e.textContent = msg || '';
    show(e, !!msg);
  }

  function busy(form, on) {
    var b = form.querySelector('button[type="submit"]');
    if (b) b.disabled = on;
  }

  function signedIn(j) {
    var s = toSession(j);
    if (!s) throw new Error('The sign-in did not finish. Try again.');
    save(s);
    openInbox();
  }

  function setupSignin() {
    var emailForm = $('admEmailForm'), codeForm = $('admCodeForm'), pwForm = $('admPwForm'), sw = $('admSwitch');
    var usingPw = false;

    emailForm.addEventListener('submit', function (e) {
      e.preventDefault();
      var email = $('admEmail').value.trim().toLowerCase();
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return signinError('That email does not look right.');
      signinError('');
      busy(emailForm, true);
      call('POST', '/auth/v1/otp', { email: email, create_user: true, data: {} }, false)
        .then(function () {
          pendingEmail = email;
          $('admCodeHint').textContent = 'We sent a code to ' + email + '.';
          show(emailForm, false);
          show(codeForm, true);
          show(sw, false);
          $('admCode').focus();
        }, function (err) { signinError(err.message); })
        .then(function () { busy(emailForm, false); });
    });

    codeForm.addEventListener('submit', function (e) {
      e.preventDefault();
      var code = $('admCode').value.replace(/\s+/g, '');
      if (!code) return signinError('Enter the code from your email.');
      signinError('');
      busy(codeForm, true);
      call('POST', '/auth/v1/verify', { email: pendingEmail, token: code, type: 'email' }, false)
        .then(signedIn)
        .catch(function (err) { signinError(err.message); })
        .then(function () { busy(codeForm, false); });
    });

    $('admBack').addEventListener('click', function () {
      show(codeForm, false);
      show(emailForm, true);
      show(sw, true);
      signinError('');
    });

    pwForm.addEventListener('submit', function (e) {
      e.preventDefault();
      var email = $('admPwEmail').value.trim().toLowerCase(), pw = $('admPw').value;
      if (!email || !pw) return signinError('Enter your email and password.');
      signinError('');
      busy(pwForm, true);
      call('POST', '/auth/v1/token?grant_type=password', { email: email, password: pw }, false)
        .then(signedIn)
        .catch(function (err) { signinError(err.message); })
        .then(function () { busy(pwForm, false); });
    });

    sw.addEventListener('click', function () {
      usingPw = !usingPw;
      show(pwForm, usingPw);
      show(emailForm, !usingPw);
      show(codeForm, false);
      sw.textContent = usingPw ? 'Use an email code instead' : 'Use a password instead';
      signinError('');
    });

    $('admSignOut').addEventListener('click', function () {
      if (session) call('POST', '/auth/v1/logout', null, true).catch(function () {});
      save(null);
      showSignin();
    });
  }

  function showSignin() {
    show($('admSignin'), true);
    show($('admInbox'), false);
    show($('admWho'), false);
  }

  // ---------------------------------------------------------------- the inbox

  function openInbox() {
    show($('admSignin'), false);
    show($('admInbox'), true);
    show($('admWho'), true);
    $('admWhoText').textContent = session && session.email ? 'Signed in as ' + session.email : 'Signed in';
    load();
  }

  function listError(msg) {
    var e = $('admListErr');
    e.textContent = msg || '';
    show(e, !!msg);
  }

  function load() {
    listError('');
    rpc('all_feature_requests', { status: filter || null })
      .then(function (j) {
        renderChips((j && j.counts) || {});
        renderList((j && j.requests) || []);
      })
      .catch(function (err) {
        if (err.status === 401) { save(null); showSignin(); return signinError('Your sign-in has ended. Sign in again.'); }
        if (err.status === 403 || err.code === '42501') {
          $('admList').textContent = '';
          return listError('This account is not on the Kuree team, so it cannot see the requests. Sign out and use the team email.');
        }
        listError(err.message);
      });
  }

  function renderChips(counts) {
    var box = $('admChips');
    box.textContent = '';
    STATUSES.forEach(function (s) {
      var b = el('button', 'adm__chip', s[1] + ' ');
      b.type = 'button';
      b.setAttribute('role', 'tab');
      b.setAttribute('aria-selected', String(filter === s[0]));
      b.appendChild(el('b', null, String(counts[s[0] || 'all'] || 0)));
      b.addEventListener('click', function () {
        if (filter === s[0]) return;
        filter = s[0];
        load();
      });
      box.appendChild(b);
    });
  }

  function when(iso) {
    var d = new Date(iso);
    if (isNaN(d)) return '';
    return d.toLocaleString('en-IN', { day: 'numeric', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit' });
  }

  function renderList(items) {
    var list = $('admList');
    list.textContent = '';
    if (!items.length) {
      list.appendChild(el('div', 'adm__card adm__empty', filter ? 'No ' + LABEL[filter].toLowerCase() + ' requests.' : 'No requests yet.'));
      return;
    }
    items.forEach(function (r) { list.appendChild(card(r)); });
  }

  function card(r) {
    var c = el('article', 'adm__card adm__req');
    var top = el('div', 'adm__top');
    top.appendChild(el('h3', null, r.title));
    var pill = el('span', 'adm__pill adm__pill--' + r.status, LABEL[r.status] || 'New');
    top.appendChild(pill);
    c.appendChild(top);
    if (r.details) c.appendChild(el('p', 'adm__details', r.details));

    var meta = el('div', 'adm__meta');
    var who = r.signed_up === false ? 'Account deleted'
      : [r.name, r.email || (r.phone ? '+' + r.phone : '')].filter(Boolean).join(', ');
    meta.appendChild(el('span', null, 'From ' + (who || 'someone')));
    meta.appendChild(el('span', null, when(r.created_at)));
    var app = [r.platform, r.app_version, r.language].filter(Boolean).join(' ');
    if (app) meta.appendChild(el('span', null, app));
    if (r.importance && IMPORTANCE[r.importance]) meta.appendChild(el('span', 'adm__pill adm__pill--imp', IMPORTANCE[r.importance]));
    c.appendChild(meta);

    var act = el('div', 'adm__act');
    var seg = el('div', 'adm__seg');
    var chosen = r.status;
    ['new', 'planned', 'done', 'declined'].forEach(function (s) {
      var b = el('button', 'adm__chip', LABEL[s]);
      b.type = 'button';
      b.setAttribute('aria-selected', String(s === chosen));
      b.addEventListener('click', function () {
        chosen = s;
        Array.prototype.forEach.call(seg.children, function (x) { x.setAttribute('aria-selected', String(x === b)); });
      });
      seg.appendChild(b);
    });
    act.appendChild(seg);
    var note = el('textarea', 'adm__note');
    note.maxLength = 500;
    note.placeholder = 'Note for the person who asked (optional)';
    note.value = r.owner_note || '';
    act.appendChild(note);
    var row = el('div', 'adm__row');
    var saveBtn = el('button', 'adm__btn adm__btn--sm', 'Save');
    saveBtn.type = 'button';
    var done = el('span', 'adm__saved');
    row.appendChild(saveBtn);
    row.appendChild(done);
    act.appendChild(row);
    c.appendChild(act);

    saveBtn.addEventListener('click', function () {
      saveBtn.disabled = true;
      done.textContent = '';
      rpc('set_feature_request_status', { id: r.id, status: chosen, note: note.value.trim() })
        .then(function (x) {
          r.status = x.status;
          r.owner_note = x.owner_note;
          pill.className = 'adm__pill adm__pill--' + x.status;
          pill.textContent = LABEL[x.status];
          done.textContent = 'Saved';
          if (filter && filter !== x.status) setTimeout(load, 700);
        })
        .catch(function (err) { done.textContent = err.message; })
        .then(function () { saveBtn.disabled = false; });
    });
    return c;
  }

  // ---------------------------------------------------------------- start

  function start() {
    setupSignin();
    session = restore();
    if (session && session.access) openInbox(); else showSignin();
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
})();
