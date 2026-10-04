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
