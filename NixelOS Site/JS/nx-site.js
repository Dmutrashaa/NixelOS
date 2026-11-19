/* NixelOS: site search */
(function () {
  'use strict';
  var SRC = document.currentScript && document.currentScript.src;
  var ROOT = SRC ? new URL('../', SRC).href : new URL(/\/Auth\/[^\/]*$/i.test(location.pathname) ? '../' : './', location.href).href;

  /* ---------- 2. CSS: perf overrides + search styles ---------- */
  var css = [
    '.toplink:has(>svg:only-child){padding:8px;margin:-8px}',
    /* search */
    '.nx-search{position:relative;flex:1 1 auto;max-width:420px;min-width:0;margin:0 16px}',
    '.nx-sbox{display:flex;align-items:center;gap:8px;height:38px;padding:0 12px;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ebff;transition:border-color .2s,background .2s,box-shadow .2s}',
    '.nx-sbox:focus-within{border-color:rgba(130,150,255,.7);background:rgba(255,255,255,.1);box-shadow:0 0 0 3px rgba(79,111,255,.2)}',
    '.nx-sbox svg{flex:none;width:17px;height:17px;opacity:.75}',
    '.nx-sbox input{flex:1;min-width:0;border:0;outline:0;background:transparent;color:inherit;font:inherit;font-size:14px}',
    '.nx-sbox input::placeholder{color:inherit;opacity:.55}',
    '.nx-sbox input::-webkit-search-cancel-button{display:none}',
    '.nx-res{position:absolute;top:calc(100% + 8px);left:0;right:0;min-width:min(420px,calc(100vw - 28px));max-height:min(70vh,520px);overflow:auto;padding:6px;border-radius:16px;border:1px solid rgba(255,255,255,.14);background:rgba(16,18,30,.97);box-shadow:0 20px 60px rgba(0,0,0,.5);display:none;z-index:60}',
    '.nx-res.open{display:block}',
    '.nx-item{display:block;padding:10px 12px;border-radius:11px;color:#e8ebff;text-decoration:none;cursor:pointer}',
    '.nx-item:hover,.nx-item.act{background:rgba(110,130,255,.2)}',
    '.nx-page{font-size:11px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:#9fb0ff;margin-bottom:3px}',
    '.nx-snip{font-size:13.5px;line-height:1.45;opacity:.92;overflow-wrap:anywhere}',
    '.nx-snip b{color:#fff;background:rgba(110,130,255,.45);border-radius:3px;padding:0 2px;font-weight:700}',
    '.nx-empty{padding:14px 12px;font-size:13.5px;opacity:.7}',
    ':root[data-theme="light"] .nx-sbox{border-color:rgba(20,24,60,.18);background:rgba(20,24,60,.05);color:#1a1d33}',
    ':root[data-theme="light"] .nx-sbox:focus-within{border-color:#4a5bd8;background:#fff;box-shadow:0 0 0 3px rgba(74,91,216,.18)}',
    ':root[data-theme="light"] .nx-res{background:rgba(252,253,255,.98);border-color:rgba(20,24,60,.14);box-shadow:0 20px 60px rgba(20,24,60,.22)}',
    ':root[data-theme="light"] .nx-item{color:#1a1d33}',
    ':root[data-theme="light"] .nx-item:hover,:root[data-theme="light"] .nx-item.act{background:rgba(74,91,216,.12)}',
    ':root[data-theme="light"] .nx-page{color:#4a5bd8}',
    ':root[data-theme="light"] .nx-snip b{color:#1a1d33;background:rgba(74,91,216,.25)}',
    'mark.nx-hl{background:rgba(255,214,90,.75);color:#111;border-radius:3px;padding:0 2px;box-shadow:0 0 0 4px rgba(255,214,90,.35);transition:background .6s,box-shadow .6s}',
    'mark.nx-hl.fade{background:transparent;box-shadow:none;color:inherit}',
    '@media(max-width:620px){.nx-search{margin:0 8px}.nx-sbox input{font-size:16px}.topbar .brand-name{display:none}}'
  ].join('\n');
  var st = document.createElement('style');
  st.id = 'nx-site-css';
  st.textContent = css;
  document.head.appendChild(st);

  /* ---------- 3. Search ---------- */
  var PAGES = [
    { f: 'index.html',     t: { en: 'Home', ru: 'Главная', uk: 'Головна' } },
    { f: 'downloads.html', t: { en: 'Downloads', ru: 'Загрузки', uk: 'Завантаження' } },
    { f: 'news.html',      t: { en: 'News', ru: 'Новости', uk: 'Новини' } },
    { f: 'min-req.html',   t: { en: 'Min. Requirements', ru: 'Мин. требования', uk: 'Мін. вимоги' } },
    { f: 'faq.html',       t: { en: 'FAQ', ru: 'FAQ', uk: 'FAQ' } },
    { f: 'Users.html',     t: { en: 'Users', ru: 'Пользователи', uk: 'Користувачі' } },
    { f: 'chat.html',      t: { en: 'OS Chat', ru: 'OS Чат', uk: 'OS Чат' } }
  ];
  var PH = { en: 'Search the whole site', ru: 'Поиск по всему сайту', uk: 'Пошук по всьому сайту' };
  var NONE = { en: 'Nothing found', ru: 'Ничего не найдено', uk: 'Нічого не знайдено' };
  var LOADING = { en: 'Loading…', ru: 'Загрузка…', uk: 'Завантаження…' };
  var SKIP_KEY = /^(nav|lang|open|close|back|theme|logo|menu|acc|foot|aria)/i;
  var CACHE_KEY = 'nx-search-v1';

  function lang() {
    var l = document.documentElement.lang;
    if (!PH[l]) { try { l = localStorage.getItem('nixelos-lang'); } catch (e) {} }
    return PH[l] ? l : 'en';
  }
  function norm(s) { return s.toLowerCase().replace(/ё/g, 'е').replace(/\s+/g, ' ').trim(); }
  function esc(s) { return s.replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function pageTitle(p) { return p.t[lang()] || p.t.en; }

  var index = null, loadingP = null;

  function extract(html, pageIdx) {
    var out = [];
    var doc = new DOMParser().parseFromString(html, 'text/html');
    // dictionaries from inline scripts (translations)
    doc.querySelectorAll('script:not([src])').forEach(function (sc) {
      var t = sc.textContent;
      if (!/\b(ru|uk)\s*:\s*\{/.test(t)) return;
      var re = /([A-Za-z0-9_]+)\s*:\s*("(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*')/g, m;
      while ((m = re.exec(t))) {
        if (SKIP_KEY.test(m[1])) continue;
        var v = m[2], s;
        try { s = v[0] === '"' ? JSON.parse(v) : v.slice(1, -1).replace(/\\'/g, "'"); } catch (e) { continue; }
        s = s.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
        if (s.length < 3 || !/[A-Za-zА-Яа-яІіЇїЄєҐґ]/.test(s)) continue;
        if (!/\s/.test(s) && s.length > 18) continue;
        if (/^[#.\/\w-]+\.(html|js|css|png|jpg|svg)/i.test(s)) continue;
        out.push({ p: pageIdx, s: s, w: 1 });
      }
    });
    doc.querySelectorAll('script,style,svg,noscript,canvas,header,aside,nav,template,input,select,textarea').forEach(function (n) { n.remove(); });
    var seen = {};
    doc.querySelectorAll('h1,h2,h3,h4,h5,p,li,td,th,summary,figcaption,label,button,a,dt,dd,blockquote,span,div').forEach(function (el) {
      var isBlock = /^(H\d|P|LI|TD|TH|SUMMARY|FIGCAPTION|DT|DD|BLOCKQUOTE)$/.test(el.tagName);
      if (!isBlock) {
        // leaf-ish elements only, to avoid giant concatenations
        if (el.children.length > 0 && el.textContent.length > 160) return;
      }
      var s = el.textContent.replace(/\s+/g, ' ').trim();
      if (s.length < 3 || s.length > 600 || seen[s]) return;
      if (!isBlock && el.querySelector('h1,h2,h3,h4,p,li,div')) return;
      seen[s] = 1;
      out.push({ p: pageIdx, s: s, w: /^H\d$/.test(el.tagName) ? 3 : 1 });
    });
    return out;
  }

  function buildIndex() {
    if (index) return Promise.resolve(index);
    if (loadingP) return loadingP;
    try {
      var c = JSON.parse(sessionStorage.getItem(CACHE_KEY) || 'null');
      if (c && c.length) { index = c; return Promise.resolve(index); }
    } catch (e) {}
    loadingP = Promise.all(PAGES.map(function (p, i) {
      return fetch(ROOT + p.f, { credentials: 'same-origin' }).then(function (r) { return r.ok ? r.text() : ''; })
        .then(function (h) { return h ? extract(h, i) : []; })
        .catch(function () { return []; });
    })).then(function (lists) {
      var all = [].concat.apply([], lists), count = {};
      all.forEach(function (e) { var k = norm(e.s); (count[k] = count[k] || {})[e.p] = 1; });
      all = all.filter(function (e) { return Object.keys(count[norm(e.s)]).length < 3; }); // drop shared menu/footer strings
      var seen = {};
      all = all.filter(function (e) { var k = e.p + '|' + norm(e.s); if (seen[k]) return false; seen[k] = 1; return true; });
      all.forEach(function (e) { e.n = norm(e.s); });
      index = all;
      try { sessionStorage.setItem(CACHE_KEY, JSON.stringify(all)); } catch (e) {}
      return index;
    });
    return loadingP;
  }

  function run(q) {
    var words = norm(q).split(' ').filter(Boolean), res = [];
    if (!words.length || norm(q).length < 2) return res;
    // page titles
    PAGES.forEach(function (p, i) {
      var tn = norm(pageTitle(p) + ' ' + p.t.en + ' ' + p.t.ru + ' ' + p.t.uk);
      if (words.every(function (w) { return tn.indexOf(w) > -1; })) res.push({ p: i, s: pageTitle(p), score: 100, title: true });
    });
    (index || []).forEach(function (e) {
      for (var i = 0; i < words.length; i++) if (e.n.indexOf(words[i]) < 0) return;
      var sc = e.w + (e.n.indexOf(norm(q)) > -1 ? 2 : 0) - Math.min(e.s.length, 300) / 600;
      res.push({ p: e.p, s: e.s, score: sc });
    });
    res.sort(function (a, b) { return b.score - a.score; });
    var per = {}, out = [];
    res.forEach(function (r) {
      per[r.p] = (per[r.p] || 0) + 1;
      if (per[r.p] <= 3 && out.length < 12) out.push(r);
    });
    return out;
  }

  function snippet(s, q) {
    var words = norm(q).split(' ').filter(Boolean), low = s.toLowerCase().replace(/ё/g, 'е'), pos = -1;
    for (var i = 0; i < words.length; i++) { pos = low.indexOf(words[i]); if (pos > -1) break; }
    var a = Math.max(0, pos - 45), b = Math.min(s.length, pos + 110);
    var t = (a > 0 ? '…' : '') + s.slice(a, b) + (b < s.length ? '…' : '');
    var h = esc(t);
    words.forEach(function (w) {
      if (!w) return;
      var re = new RegExp('(' + w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/е/g, '[её]') + ')', 'gi');
      h = h.replace(re, '<b>$1</b>');
    });
    return h;
  }

  function mount() {
    var header = document.querySelector('header');
    var toggle = document.getElementById('menu-toggle');
    if (!header || !toggle || document.getElementById('nx-search')) return;
    var anchor = toggle.closest('.top-actions') || toggle;
    var wrap = document.createElement('div');
    wrap.className = 'nx-search';
    wrap.id = 'nx-search';
    wrap.setAttribute('role', 'search');
    wrap.innerHTML =
      '<label class="nx-sbox"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="6.5"></circle><path d="m20 20-4-4"></path></svg>' +
      '<input type="search" autocomplete="off" spellcheck="false" enterkeyhint="search"></label>' +
      '<div class="nx-res" role="listbox"></div>';
    anchor.parentNode.insertBefore(wrap, anchor);
    var input = wrap.querySelector('input'), box = wrap.querySelector('.nx-res'), cur = -1, timer;

    function setPh() { input.placeholder = PH[lang()]; input.setAttribute('aria-label', PH[lang()]); }
    setPh();
    document.addEventListener('click', function (e) {
      if (e.target.closest && e.target.closest('.lang-button')) setTimeout(function () { setPh(); if (input.value) render(); }, 60);
    });

    function items() { return box.querySelectorAll('.nx-item'); }
    function mark(i) {
      var it = items(); if (!it.length) return;
      cur = (i + it.length) % it.length;
      it.forEach(function (n, k) { n.classList.toggle('act', k === cur); });
      it[cur].scrollIntoView({ block: 'nearest' });
    }
    function render() {
      var q = input.value.trim();
      if (q.length < 2) { box.classList.remove('open'); return; }
      if (!index) { box.innerHTML = '<div class="nx-empty">' + LOADING[lang()] + '</div>'; box.classList.add('open'); }
      buildIndex().then(function () {
        if (input.value.trim() !== q) return;
        var r = run(q);
        cur = -1;
        if (!r.length) box.innerHTML = '<div class="nx-empty">' + NONE[lang()] + '</div>';
        else box.innerHTML = r.map(function (x) {
          return '<a class="nx-item" role="option" href="' + ROOT + PAGES[x.p].f + '" data-q="' + esc(q) + '">' +
            '<div class="nx-page">' + esc(pageTitle(PAGES[x.p])) + '</div>' +
            (x.title ? '' : '<div class="nx-snip">' + snippet(x.s, q) + '</div>') + '</a>';
        }).join('');
        box.classList.add('open');
      });
    }
    input.addEventListener('input', function () { clearTimeout(timer); timer = setTimeout(render, 120); });
    input.addEventListener('focus', function () { buildIndex(); if (input.value.trim().length > 1) render(); });
    input.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowDown') { e.preventDefault(); mark(cur + 1); }
      else if (e.key === 'ArrowUp') { e.preventDefault(); mark(cur - 1); }
      else if (e.key === 'Escape') { box.classList.remove('open'); input.blur(); }
      else if (e.key === 'Enter') {
        var it = items(); if (!it.length) return;
        e.preventDefault(); (it[cur > -1 ? cur : 0]).click();
      }
    });
    box.addEventListener('click', function (e) {
      var a = e.target.closest('.nx-item'); if (!a) return;
      try { sessionStorage.setItem('nx-hl', a.getAttribute('data-q') || ''); } catch (er) {}
    });
    document.addEventListener('pointerdown', function (e) { if (!wrap.contains(e.target)) box.classList.remove('open'); });
    document.addEventListener('keydown', function (e) {
      if (e.key === '/' && !/^(INPUT|TEXTAREA|SELECT)$/.test((document.activeElement || {}).tagName || '') && !(document.activeElement || {}).isContentEditable) {
        e.preventDefault(); input.focus();
      }
    });
  }

  /* highlight the found text on the target page */
  function highlight() {
    var q;
    try { q = sessionStorage.getItem('nx-hl'); sessionStorage.removeItem('nx-hl'); } catch (e) {}
    if (!q) return;
    var words = norm(q).split(' ').filter(Boolean);
    if (!words.length) return;
    setTimeout(function () {
      var w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
        acceptNode: function (n) {
          var p = n.parentElement;
          if (!p || p.closest('header,aside,script,style,.nx-search,canvas')) return NodeFilter.FILTER_REJECT;
          return n.nodeValue.trim().length > 1 ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
        }
      }), n, hit = null, at = 0, word;
      while ((n = w.nextNode())) {
        var low = n.nodeValue.toLowerCase().replace(/ё/g, 'е');
        for (var i = 0; i < words.length; i++) { at = low.indexOf(words[i]); if (at > -1) { word = words[i]; break; } }
        if (at > -1) { hit = n; break; }
      }
      if (!hit) return;
      try {
        var r = document.createRange();
        r.setStart(hit, at); r.setEnd(hit, at + word.length);
        var m = document.createElement('mark'); m.className = 'nx-hl';
        r.surroundContents(m);
        m.scrollIntoView({ block: 'center', behavior: 'smooth' });
        setTimeout(function () { m.classList.add('fade'); }, 3500);
        setTimeout(function () { if (m.parentNode) { m.replaceWith.apply(m, m.childNodes); } }, 4300);
      } catch (e) {}
    }, 700);
  }

  function ready(fn) { if (document.readyState !== 'loading') fn(); else document.addEventListener('DOMContentLoaded', fn); }
  ready(function () { mount(); highlight(); });
})();
      
