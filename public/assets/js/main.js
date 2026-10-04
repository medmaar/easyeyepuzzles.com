(function () {
  var root = document.documentElement;

  function save(key, value) { try { localStorage.setItem(key, value); } catch (e) {} }

  // Text size and night mode controls
  function syncA11y() {
    var size = root.getAttribute('data-size') || 'm';
    var night = root.getAttribute('data-theme') === 'night';
    document.querySelectorAll('[data-set-size]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-set-size') === size));
    });
    document.querySelectorAll('[data-toggle-night]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(night));
    });
  }
  document.querySelectorAll('[data-set-size]').forEach(function (b) {
    b.addEventListener('click', function () {
      var s = b.getAttribute('data-set-size');
      if (s === 'm') root.removeAttribute('data-size'); else root.setAttribute('data-size', s);
      save('eep-size', s);
      syncA11y();
    });
  });
  document.querySelectorAll('[data-toggle-night]').forEach(function (b) {
    b.addEventListener('click', function () {
      var on = root.getAttribute('data-theme') !== 'night';
      if (on) root.setAttribute('data-theme', 'night'); else root.removeAttribute('data-theme');
      save('eep-theme', on ? 'night' : 'day');
      syncA11y();
    });
  });
  syncA11y();

  // Mobile navigation
  var toggle = document.querySelector('.nav-toggle');
  var nav = document.getElementById('site-nav');
  if (toggle && nav) {
    toggle.addEventListener('click', function () {
      var open = nav.classList.toggle('open');
      toggle.setAttribute('aria-expanded', String(open));
    });
  }

  // Catalog filters
  var grid = document.querySelector('[data-catalog]');
  if (grid) {
    var state = { lang: 'all', type: 'all' };
    var params = new URLSearchParams(location.search);
    if (params.get('lang')) state.lang = params.get('lang');
    if (params.get('type')) state.type = params.get('type');
    var cards = Array.prototype.slice.call(grid.querySelectorAll('.book-card'));
    var count = document.querySelector('[data-result-count]');
    var soon = document.querySelector('[data-coming-soon]');

    function apply() {
      var shown = 0;
      cards.forEach(function (c) {
        var ok = (state.lang === 'all' || c.dataset.lang === state.lang) &&
                 (state.type === 'all' || c.dataset.type === state.type);
        c.hidden = !ok;
        if (ok) shown++;
      });
      document.querySelectorAll('[data-filter]').forEach(function (b) {
        b.setAttribute('aria-pressed', String(state[b.dataset.filter] === b.dataset.value));
      });
      if (count) count.textContent = shown === 1 ? 'Showing 1 book' : 'Showing ' + shown + ' books';
      if (soon) soon.classList.toggle('show', shown === 0);
      var q = new URLSearchParams();
      if (state.lang !== 'all') q.set('lang', state.lang);
      if (state.type !== 'all') q.set('type', state.type);
      var qs = q.toString();
      history.replaceState(null, '', location.pathname + (qs ? '?' + qs : ''));
    }
    document.querySelectorAll('[data-filter]').forEach(function (b) {
      b.addEventListener('click', function () {
        state[b.dataset.filter] = b.dataset.value;
        apply();
      });
    });
    apply();
  }

  // Sample page lightbox
  var box = document.querySelector('.lightbox');
  if (box) {
    var big = box.querySelector('img');
    var closeBtn = box.querySelector('.close');
    var opener = null;
    function close() { box.classList.remove('open'); if (opener) opener.focus(); }
    document.querySelectorAll('[data-zoom]').forEach(function (b) {
      b.addEventListener('click', function () {
        opener = b;
        big.src = b.getAttribute('data-zoom');
        big.alt = b.querySelector('img').alt;
        box.classList.add('open');
        closeBtn.focus();
      });
    });
    closeBtn.addEventListener('click', close);
    box.addEventListener('click', function (e) { if (e.target === box) close(); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && box.classList.contains('open')) close(); });
  }
})();

// Homepage: mini word search
(function () {
  var grid = document.querySelector('[data-ws]');
  if (!grid) return;
  var WORDS = ['PUZZLE', 'WORDS', 'SMILE', 'BRAIN', 'EYES'];
  var cells = Array.prototype.slice.call(grid.querySelectorAll('.ws-cell'));
  var status = document.querySelector('[data-ws-status]');
  var win = document.querySelector('[data-ws-win]');
  var found = {};
  var start = null;

  function cellAt(r, c) { return cells[r * 8 + c]; }
  function pos(cell) { return { r: +cell.dataset.r, c: +cell.dataset.c }; }
  function count() { return Object.keys(found).length; }

  function update() {
    status.textContent = count() + ' of ' + WORDS.length + ' words found';
    if (count() === WORDS.length) { win.hidden = false; var a = win.querySelector('a'); if (a) a.focus(); }
  }

  function pick(cell) {
    if (!start) { start = cell; cell.classList.add('start'); return; }
    var a = pos(start), b = pos(cell);
    start.classList.remove('start');
    if (start === cell) { start = null; return; }
    var dr = b.r - a.r, dc = b.c - a.c;
    var len = Math.max(Math.abs(dr), Math.abs(dc));
    var line = [];
    if (dr === 0 || dc === 0 || Math.abs(dr) === Math.abs(dc)) {
      var sr = Math.sign(dr), sc = Math.sign(dc);
      for (var i = 0; i <= len; i++) line.push(cellAt(a.r + sr * i, a.c + sc * i));
    }
    var text = line.map(function (x) { return x.textContent; }).join('');
    var back = text.split('').reverse().join('');
    var hit = WORDS.filter(function (w) { return !found[w] && (w === text || w === back); })[0];
    if (hit) {
      found[hit] = true;
      line.forEach(function (x) { x.classList.add('found'); });
      var li = document.querySelector('.ws-words [data-word="' + hit + '"]');
      if (li) li.classList.add('found');
      update();
    } else {
      [start, cell].forEach(function (x) { x.classList.add('miss'); setTimeout(function () { x.classList.remove('miss'); }, 400); });
    }
    start = null;
  }

  cells.forEach(function (cell, i) {
    if (i === 0) cell.tabIndex = 0;
    cell.addEventListener('click', function () { pick(cell); });
    cell.addEventListener('keydown', function (e) {
      var p = pos(cell), r = p.r, c = p.c;
      if (e.key === 'ArrowRight') c = Math.min(7, c + 1);
      else if (e.key === 'ArrowLeft') c = Math.max(0, c - 1);
      else if (e.key === 'ArrowDown') r = Math.min(7, r + 1);
      else if (e.key === 'ArrowUp') r = Math.max(0, r - 1);
      else return;
      e.preventDefault();
      cell.tabIndex = -1;
      var next = cellAt(r, c); next.tabIndex = 0; next.focus();
    });
  });

  var reset = document.querySelector('[data-ws-reset]');
  if (reset) reset.addEventListener('click', function () {
    found = {}; start = null; win.hidden = true;
    cells.forEach(function (x) { x.classList.remove('found', 'start'); });
    document.querySelectorAll('.ws-words li').forEach(function (li) { li.classList.remove('found'); });
    update();
  });
})();

// Gentle fade-in of sections as they scroll into view
(function () {
  if (!('IntersectionObserver' in window)) return;
  if (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var items = document.querySelectorAll('main > section:not(.hero):not(.stats-band) .container');
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
  }, { rootMargin: '0px 0px -60px 0px' });
  items.forEach(function (el) {
    var r = el.getBoundingClientRect();
    if (r.top < window.innerHeight) return; // already visible: leave as is
    el.classList.add('reveal');
    io.observe(el);
  });
})();