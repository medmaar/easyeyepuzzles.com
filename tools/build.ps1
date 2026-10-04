# Generates the static HTML pages in /public from data/books.json and data/bundles.json.
# Usage (from the repo root):  powershell -ExecutionPolicy Bypass -File tools/build.ps1
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$pub = Join-Path $repo 'public'
$site = 'https://easyeyepuzzles.com'
$email = 'help@easyeyepuzzles.com'
$year = (Get-Date).Year
$ver = (Get-Date).ToString('yyyyMMddHHmm')   # cache-busting for css/js
$utf8 = New-Object System.Text.UTF8Encoding($false)
$books = [IO.File]::ReadAllText((Join-Path $repo 'data\books.json'), $utf8) | ConvertFrom-Json
$bundles = [IO.File]::ReadAllText((Join-Path $repo 'data\bundles.json'), $utf8) | ConvertFrom-Json
$byId = @{}; foreach ($b in $books) { $byId[$b.id] = $b }
foreach ($x in $bundles) { foreach ($id in $x.books) { if (-not $byId.ContainsKey($id)) { throw "Bundle $($x.id) references unknown book '$id'" } } }

function Enc([string]$s) { [System.Net.WebUtility]::HtmlEncode($s) }
function WriteFile([string]$rel, [string]$content) {
  $path = Join-Path $pub $rel
  New-Item -ItemType Directory -Force (Split-Path -Parent $path) | Out-Null
  [IO.File]::WriteAllText($path, $content, $utf8)
}

$languages = @(
  @{ code = 'it'; name = 'Italian';  flag = '<i style="background:#009246"></i><i style="background:#fff"></i><i style="background:#ce2b37"></i>' },
  @{ code = 'fr'; name = 'French';   flag = '<i style="background:#0055a4"></i><i style="background:#fff"></i><i style="background:#ef4135"></i>' },
  @{ code = 'en'; name = 'English';  flag = '<i style="background:#012169"></i><i style="background:#fff"></i><i style="background:#c8102e"></i>' },
  @{ code = 'more'; name = 'More languages'; flag = '<i style="background:#ffc83d"></i><i style="background:#1d3a8a"></i><i style="background:#ffc83d"></i>' }
)
$types = @('Word Search', 'Crossword', 'Memory Games', 'Activity Book')
function TypeSlug([string]$t) { $t.ToLower().Replace(' ', '-') }
function LangCount([string]$code) { @($books | Where-Object { $_.lang -eq $code }).Count }
function Money($n) { '$' + $n }
function BundleValue($x) { $s = 0; foreach ($id in $x.books) { $s += $byId[$id].price }; $s }

# Checkout link: the item's buyUrl if set (e.g. an external payment link), otherwise our own /checkout/<id> page.
function OrderUrl([string]$id, [string]$buyUrl) {
  if ($buyUrl) { return $buyUrl }
  return "/checkout/$id"
}

$moon = '<svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor" aria-hidden="true"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>'

function Layout([string]$title, [string]$desc, [string]$path, [string]$active, [string]$body, [string]$extraHead = '', [string]$ogImage = '') {
  $navItems = @(
    @{ href = '/'; label = 'Home'; key = 'home' },
    @{ href = '/books'; label = 'All Books'; key = 'books' },
    @{ href = '/bundles'; label = 'Bundles'; key = 'bundles' },
    @{ href = '/about'; label = 'About'; key = 'about' },
    @{ href = '/contact'; label = 'Contact'; key = 'contact' }
  )
  $nav = ($navItems | ForEach-Object {
    $cur = if ($_.key -eq $active) { ' aria-current="page"' } else { '' }
    "<li><a href=""$($_.href)""$cur>$($_.label)</a></li>"
  }) -join ''
  $fullTitle = if ($path -eq '/') { $title } else { "$title | EasyEye Puzzles" }
  if (-not $ogImage) { $ogImage = "$site/assets/brand/og-image.jpg" }
@"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(Enc $fullTitle)</title>
<meta name="description" content="$(Enc $desc)">
<link rel="canonical" href="$site$path">
<meta property="og:type" content="website">
<meta property="og:site_name" content="EasyEye Puzzles">
<meta property="og:title" content="$(Enc $fullTitle)">
<meta property="og:description" content="$(Enc $desc)">
<meta property="og:url" content="$site$path">
<meta property="og:image" content="$ogImage">
<meta name="twitter:card" content="summary_large_image">
<meta name="cryptomus" content="9180402c" />
<meta name="theme-color" content="#14213d">
<link rel="icon" href="/favicon.png" type="image/png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/assets/css/style.css?v=$ver">
<script>try{var d=document.documentElement,s=localStorage.getItem('eep-size'),t=localStorage.getItem('eep-theme');if(s&&s!=='m')d.setAttribute('data-size',s);if(t==='night'||(!t&&window.matchMedia&&matchMedia('(prefers-color-scheme: dark)').matches))d.setAttribute('data-theme','night');}catch(e){}</script>
$extraHead
</head>
<body>
<a class="skip-link" href="#main">Skip to content</a>
<div class="a11y-bar"><div class="container" role="group" aria-label="Reading comfort">
  <span>Text size</span>
  <button class="a11y-btn" type="button" data-set-size="m" aria-label="Normal text size">A</button>
  <button class="a11y-btn" type="button" data-set-size="l" aria-label="Large text size">A+</button>
  <button class="a11y-btn" type="button" data-set-size="xl" aria-label="Extra large text size">A++</button>
  <button class="a11y-btn" type="button" data-toggle-night aria-pressed="false">$moon Night mode</button>
</div></div>
<header class="site-header">
  <div class="container">
    <a class="logo" href="/"><img src="/assets/brand/logo.png" alt="EasyEye Puzzles" width="640" height="189"></a>
    <button class="nav-toggle" type="button" aria-expanded="false" aria-controls="site-nav">Menu</button>
    <nav class="nav" id="site-nav" aria-label="Main"><ul>$nav</ul></nav>
  </div>
</header>
<main id="main">
$body
</main>
<footer class="site-footer">
  <div class="container">
    <div class="footer-grid">
      <div>
        <a class="footer-brand" href="/"><img src="/assets/brand/icon-512.png" alt="" width="56" height="56"><span>EasyEye Puzzles</span></a>
        <p style="margin-top:16px;max-width:42ch">Large print puzzle and activity books that are easy on the eyes and good for the mind. Available in Italian and French, with English and more languages coming soon.</p>
      </div>
      <div>
        <h3>Shop</h3>
        <ul>
          <li><a href="/books?lang=it">Italian books</a></li>
          <li><a href="/books?lang=fr">French books</a></li>
          <li><a href="/books?type=word-search">Word search</a></li>
          <li><a href="/books?type=crossword">Crosswords</a></li>
          <li><a href="/bundles">Bundles &amp; savings</a></li>
        </ul>
      </div>
      <div>
        <h3>Company</h3>
        <ul>
          <li><a href="/about">About us</a></li>
          <li><a href="/contact">Contact</a></li>
          <li>Sales &amp; help: <a href="mailto:$email">$email</a></li>
          <li><a href="/privacy">Privacy</a></li>
        </ul>
      </div>
    </div>
    <p class="copyright">&copy; $year EasyEye Puzzles. All rights reserved. Prices in US dollars.</p>
  </div>
</footer>
<script src="/assets/js/main.js?v=$ver" defer></script>
</body>
</html>
"@
}

function Tags($b) {
  $t = "<span class=""tag tag-$($b.lang)"">$(Enc $b.language)</span><span class=""tag"">$(Enc $b.type)</span>"
  if ($b.lowVision) { $t += '<span class="tag tag-lv">Low vision</span>' }
  "<div class=""tags"">$t</div>"
}

function Card($b) {
@"
<article class="book-card" data-lang="$($b.lang)" data-type="$(TypeSlug $b.type)">
  <div class="cover"><img src="/assets/books/$($b.img)-cover.jpg" alt="Cover of $(Enc $b.title)" width="600" height="783" loading="lazy"></div>
  <div class="body">
    $(Tags $b)
    <h3><a href="/books/$($b.id)">$(Enc $b.title)</a></h3>
    <p class="sub">$(Enc $b.english)</p>
    <div class="card-foot"><span class="price">$(Money $b.price)</span><span class="more" aria-hidden="true">See inside &rarr;</span></div>
  </div>
</article>
"@
}

function CoverStack($x) {
  $ids = @($x.books | Select-Object -First 4)
  $imgs = ($ids | ForEach-Object { "<img src=""/assets/books/$($byId[$_].img)-cover.jpg"" alt="""" width=""600"" height=""783"" loading=""lazy"">" }) -join ''
  "<div class=""cover-stack n$($ids.Count)"" aria-hidden=""true"">$imgs</div>"
}

function BundleCard($x) {
  $value = BundleValue $x
  $save = $value - $x.price
  $items = ($x.books | ForEach-Object { $bk = $byId[$_]; "<li><a href=""/books/$($bk.id)"">$(Enc $bk.title)</a> <span class=""muted"">($(Enc $bk.language), $(Money $bk.price))</span></li>" }) -join ''
  $n = @($x.books).Count
@"
<article class="bundle-card" id="$($x.id)">
  $(CoverStack $x)
  <div class="bundle-body">
    <div class="tags"><span class="tag tag-lv">$n books</span><span class="tag">Save $(Money $save)</span></div>
    <h3>$(Enc $x.name)</h3>
    <p class="sub">$(Enc $x.tagline)</p>
    <details class="included"><summary>What's included</summary><ul>$items</ul></details>
    <div class="bundle-buy">
      <div class="price-block"><span class="price">$(Money $x.price)</span><s class="was" aria-label="Regular price $(Money $value)">$(Money $value)</s></div>
      <a class="btn btn-accent" href="$(Enc (OrderUrl $x.id $x.buyUrl))">Buy bundle</a>
    </div>
  </div>
</article>
"@
}

$icon = @{
  eye = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>'
  brain = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 4a3 3 0 0 0-3 3 3 3 0 0 0-2 5 3 3 0 0 0 2 5 3 3 0 0 0 6 1V5a3 3 0 0 0-3-1z"/><path d="M15 4a3 3 0 0 1 3 3 3 3 0 0 1 2 5 3 3 0 0 1-2 5 3 3 0 0 1-6 1"/></svg>'
  globe = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20"/></svg>'
  gift = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="8" width="18" height="13" rx="2"/><path d="M12 8v13M3 12h18M12 8S10 3 7.5 4 9 8 12 8zm0 0s2-5 4.5-4S15 8 12 8z"/></svg>'
}

$minPrice = ($books | Measure-Object price -Minimum).Minimum
$totalPages = ($books | Measure-Object pages -Sum).Sum
$langCount = @($books | Select-Object -ExpandProperty lang -Unique).Count
$lowVisionCount = @($books | Where-Object { $_.lowVision }).Count

$icon += @{
  grid = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18M15 3v18"/><path d="M5.5 5.5l13 13" stroke-width="3" opacity=".45"/></svg>'
  cross = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"><path d="M8 2h4v4H8zM8 6h4v4H8zM4 10h4v4H4zM8 10h4v4H8zM12 10h4v4h-4zM16 10h4v4h-4zM8 14h4v4H8zM8 18h4v4H8z"/></svg>'
  compass = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M16.2 7.8l-2.1 6.3-6.3 2.1 2.1-6.3z"/></svg>'
  user = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-8 8-8s8 3.6 8 8"/></svg>'
  home = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10.5 12 3l9 7.5V21H3z"/><path d="M9 21v-6h6v6"/></svg>'
  check = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"/></svg>'
  star = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.5l2.9 6 6.6.8-4.9 4.6 1.3 6.6L12 17.3 6.1 20.5l1.3-6.6L2.5 9.3l6.6-.8z"/></svg>'
}

# ---------- Home ----------
$featured = @('parole-intrecciate-anziani-ipovedenti', 'mots-meles-seniors-malvoyants', 'giochi-di-memoria-per-anziani', 'cruciverba-per-nonni')
$featuredCards = (@($books | Where-Object { $featured -contains $_.id }) | ForEach-Object { Card $_ }) -join "`n"
$homeBundles = (@($bundles | Where-Object { @('french-word-search-duo', 'complete-french-collection', 'complete-collection') -contains $_.id }) | ForEach-Object { BundleCard $_ }) -join "`n"
$biggest = $bundles | Where-Object { $_.id -eq 'complete-collection' }
$biggestSave = (BundleValue $biggest) - $biggest.price
$langTiles = ($languages | ForEach-Object {
  $n = LangCount $_.code
  $sub = if ($n -gt 0) { "$n book" + $(if ($n -ne 1) { 's' } else { '' }) } else { 'Coming soon' }
  $href = if ($_.code -eq 'more') { '/contact' } else { "/books?lang=$($_.code)" }
  "<a class=""lang-tile"" href=""$href""><span class=""flag"" aria-hidden=""true"">$($_.flag)</span><strong>$($_.name)</strong><span>$sub</span></a>"
}) -join "`n"

# Scrolling strip of every cover (list duplicated so the loop is seamless)
$coverItems = ($books | ForEach-Object { "<a href=""/books/$($_.id)"" tabindex=""-1""><img src=""/assets/books/$($_.img)-cover.jpg"" alt="""" width=""600"" height=""783"" loading=""lazy""></a>" }) -join ''
$marquee = "<div class=""marquee"" aria-hidden=""true""><div class=""marquee-track"">$coverItems$coverItems</div></div>"

# Shop by puzzle type
$typeInfo = @(
  @{ name = 'Word Search'; icon = $icon.grid; text = 'Find hidden words in big, bold letter grids.' },
  @{ name = 'Crossword'; icon = $icon.cross; text = 'Classic crosswords with clear, readable clues.' },
  @{ name = 'Memory Games'; icon = $icon.brain; text = 'Anagrams, cryptograms, sudoku and more.' },
  @{ name = 'Activity Book'; icon = $icon.compass; text = 'A mix of puzzles on a journey through Italy.' }
)
$typeTiles = ($typeInfo | ForEach-Object {
  $t = $_; $list = @($books | Where-Object { $_.type -eq $t.name })
  $n = $list.Count
  $from = ($list | Measure-Object price -Minimum).Minimum
  $sample = "/assets/books/$($list[0].img)-sample1.jpg"
  "<a class=""type-tile"" href=""/books?type=$(TypeSlug $t.name)""><div class=""type-art"" style=""background-image:url('$sample')""></div><div class=""type-body""><span class=""type-icon"">$($t.icon)</span><h3>$($t.name)</h3><p>$($t.text)</p><span class=""type-meta"">$n book$(if ($n -ne 1) { 's' }) &middot; from $(Money $from) <b aria-hidden=""true"">&rarr;</b></span></div></a>"
}) -join "`n"

# Spotlight book
$spot = $byId['parole-intrecciate-anziani-ipovedenti']
$spotFeats = ($spot.features | Select-Object -First 4 | ForEach-Object { "<li>$(Enc $_)</li>" }) -join ''

# Playable mini word search (8x8); words: PUZZLE, WORDS, SMILE, BRAIN, EYES
$gridRows = @('PUZZLETA', 'KOHARNCW', 'DSFBTMUO', 'GMOIREHR', 'VITNLAPD', 'JLQCMUIS', 'OEYESKFN', 'WTRGBHAL')
$cells = ''
for ($r = 0; $r -lt 8; $r++) { for ($c = 0; $c -lt 8; $c++) { $ch = $gridRows[$r][$c]; $cells += "<button type=""button"" class=""ws-cell"" data-r=""$r"" data-c=""$c"" tabindex=""-1"" aria-label=""$ch, row $($r + 1), column $($c + 1)"">$ch</button>" } }
$wordList = (@('PUZZLE', 'WORDS', 'SMILE', 'BRAIN', 'EYES') | ForEach-Object { "<li data-word=""$_"">$_</li>" }) -join ''

# Regular vs EasyEye print comparison
$smallLetters = (('QWERTYUIOPASDFGHJKLZXCVBNMLETTERSWORDSPUZZLEBRAINSMILEGRIDMEMORYCLUEFINDHIDEQUIZ').ToCharArray() | Select-Object -First 96 | ForEach-Object { "<span>$_</span>" }) -join ''
$bigLetters = (('EASYREADPUZZLESMILE').ToCharArray() | Select-Object -First 18 | ForEach-Object { "<span>$_</span>" }) -join ''

$homeBody = @"
<section class="hero hero-v2">
  <div class="container">
    <div class="hero-copy">
      <span class="eyebrow">$($icon.star) Large print puzzle books</span>
      <h1>Puzzle books that are <span class="hl">easy on the eyes</span> and great for the mind</h1>
      <p class="lead">Word searches, crosswords and memory games in big, clear print, made for seniors, readers with low vision and anyone who loves a good puzzle.</p>
      <div class="hero-actions">
        <a class="btn btn-primary btn-lg" href="/books">Browse all books</a>
        <a class="btn btn-ghost btn-lg" href="/bundles">Save with bundles</a>
      </div>
      <ul class="hero-checks">
        <li>$($icon.check) Extra-large letters</li>
        <li>$($icon.check) Solutions included</li>
        <li>$($icon.check) Books from $(Money $minPrice)</li>
      </ul>
    </div>
    <div class="hero-visual" aria-hidden="true">
      <div class="hero-blob"></div>
      <div class="hero-fan">
        <img src="/assets/books/mots-meles-seniors-cover.jpg" alt="" width="600" height="783">
        <img src="/assets/books/parole-ipovedenti-cover.jpg" alt="" width="600" height="783">
        <img src="/assets/books/viaggio-italia-cover.jpg" alt="" width="600" height="783">
      </div>
      <span class="float-chip chip-a">$($icon.eye) XL print</span>
      <span class="float-chip chip-b">$($icon.brain) 3 difficulty levels</span>
      <span class="float-chip chip-c">$($icon.globe) Italian &amp; French</span>
    </div>
  </div>
</section>

<section class="stats-band" aria-label="EasyEye Puzzles in numbers">
  <div class="container stats">
    <div><strong>$($books.Count)</strong><span>puzzle books</span></div>
    <div><strong>$('{0:N0}' -f $totalPages)+</strong><span>pages of puzzles</span></div>
    <div><strong>$langCount</strong><span>languages, more coming</span></div>
    <div><strong>$lowVisionCount</strong><span>low vision editions</span></div>
  </div>
</section>

$marquee

<section aria-labelledby="diff-h">
  <div class="container">
    <div class="section-head center"><div><span class="kicker">See the difference</span><h2 id="diff-h">Made for comfortable reading</h2><p>Most puzzle books cram tiny letters into crowded grids. Ours give every letter room to breathe.</p></div></div>
    <div class="compare">
      <figure class="compare-card compare-bad">
        <figcaption><span class="pill pill-bad">Typical puzzle book</span>Small type, cramped grid, low contrast</figcaption>
        <div class="letters-small">$smallLetters</div>
      </figure>
      <figure class="compare-card compare-good">
        <figcaption><span class="pill pill-good">EasyEye Puzzles</span>Extra-large letters, airy grid, strong contrast</figcaption>
        <div class="letters-big">$bigLetters</div>
      </figure>
    </div>
  </div>
</section>

<section class="section-alt" aria-labelledby="why">
  <div class="container">
    <div class="section-head center"><div><span class="kicker">Why EasyEye</span><h2 id="why">Why readers love our books</h2><p>Every page is designed to be comfortable to read, enjoyable to solve and good for the mind.</p></div></div>
    <div class="features">
      <div class="card"><div class="icon">$($icon.eye)</div><h3>Large, clear print</h3><p>Big letters, strong contrast and roomy grids mean less squinting and more fun.</p></div>
      <div class="card"><div class="icon">$($icon.brain)</div><h3>Keeps the mind active</h3><p>Easy, medium and hard puzzles exercise memory, focus and vocabulary.</p></div>
      <div class="card"><div class="icon">$($icon.globe)</div><h3>In your language</h3><p>Written natively in Italian and French, with English and more languages on the way.</p></div>
      <div class="card"><div class="icon">$($icon.gift)</div><h3>A thoughtful gift</h3><p>Ideal for parents, grandparents, care homes and anyone who loves words.</p></div>
    </div>
  </div>
</section>

<section aria-labelledby="types-h">
  <div class="container">
    <div class="section-head"><div><span class="kicker">Shop by puzzle type</span><h2 id="types-h">What do you like to solve?</h2></div><a class="btn btn-ghost" href="/books">All books</a></div>
    <div class="type-grid">
$typeTiles
    </div>
  </div>
</section>

<section class="play-section" aria-labelledby="play-h">
  <div class="container play">
    <div class="play-copy">
      <span class="kicker">Try it now</span>
      <h2 id="play-h">Solve a mini word search</h2>
      <p>This is the kind of large, clear grid you'll find in our books. Find the 5 hidden words: click the <strong>first letter</strong> of a word, then its <strong>last letter</strong>. Words can go across, down or diagonally.</p>
      <ul class="ws-words" aria-label="Words to find">$wordList</ul>
      <p class="ws-status" aria-live="polite" data-ws-status>0 of 5 words found</p>
      <button type="button" class="btn btn-ghost" data-ws-reset>Start again</button>
    </div>
    <div class="ws-wrap">
      <div class="ws-grid" role="grid" aria-label="Mini word search, 8 by 8 letters" data-ws>$cells</div>
      <div class="ws-win" data-ws-win hidden>
        <strong>Well done!</strong>
        <p>You found all 5 words. Ready for 90 more grids?</p>
        <a class="btn btn-accent" href="/books?type=word-search">See word search books</a>
      </div>
    </div>
  </div>
</section>

<section aria-labelledby="featured">
  <div class="container">
    <div class="section-head"><div><span class="kicker">Bestsellers</span><h2 id="featured">Popular books</h2><p>A few of our readers' favourites.</p></div><a class="btn btn-ghost" href="/books">See all $($books.Count) books</a></div>
    <div class="book-grid">
$featuredCards
    </div>
  </div>
</section>

<section class="spotlight-section" aria-labelledby="spot-h">
  <div class="container spotlight">
    <div class="spot-images">
      <img class="spot-cover" src="/assets/books/$($spot.img)-cover.jpg" alt="Cover of $(Enc $spot.title)" width="600" height="783" loading="lazy">
      <img class="spot-page" src="/assets/books/$($spot.img)-sample1.jpg" alt="A large print word search page from the book" width="700" height="913" loading="lazy">
    </div>
    <div class="spot-copy">
      <span class="kicker">Book spotlight</span>
      <h2 id="spot-h">$(Enc $spot.english)</h2>
      <p class="original" lang="$($spot.lang)">$(Enc $spot.title)</p>
      <p>$(Enc $spot.description[0])</p>
      <ul class="check-list">$spotFeats</ul>
      <div class="spot-buy">
        <span class="price price-lg">$(Money $spot.price)</span>
        <a class="btn btn-accent" href="/checkout/$($spot.id)">Buy now</a>
        <a class="btn btn-ghost" href="/books/$($spot.id)">Look inside</a>
      </div>
    </div>
  </div>
</section>

<section aria-labelledby="who-h">
  <div class="container">
    <div class="section-head center"><div><span class="kicker">Who it's for</span><h2 id="who-h">Made for people who love puzzles</h2></div></div>
    <div class="who-grid">
      <div class="who"><span class="who-icon">$($icon.user)</span><h3>Seniors &amp; retirees</h3><p>A relaxing daily habit that keeps memory and vocabulary sharp.</p></div>
      <div class="who"><span class="who-icon">$($icon.eye)</span><h3>Readers with low vision</h3><p>Extra-large, high-contrast pages for macular degeneration and tired eyes.</p></div>
      <div class="who"><span class="who-icon">$($icon.gift)</span><h3>Families &amp; gift givers</h3><p>A caring present for parents and grandparents, in their own language.</p></div>
      <div class="who"><span class="who-icon">$($icon.home)</span><h3>Care homes &amp; libraries</h3><p>Group activities everyone can join. <a href="/contact">Ask about bulk orders</a>.</p></div>
    </div>
  </div>
</section>

<section class="section-alt" aria-labelledby="bundles-h">
  <div class="container">
    <div class="section-head"><div><span class="kicker">Bundle &amp; save</span><h2 id="bundles-h">Get more puzzles for less</h2><p>Buy books together and pay less. The Complete Collection saves you $(Money $biggestSave).</p></div><a class="btn btn-ghost" href="/bundles">See all $($bundles.Count) bundles</a></div>
    <div class="bundle-grid">
$homeBundles
    </div>
  </div>
</section>

<section aria-labelledby="how-h">
  <div class="container">
    <div class="section-head center"><div><span class="kicker">Simple ordering</span><h2 id="how-h">How it works</h2></div></div>
    <ol class="steps">
      <li><span class="step-num">1</span><h3>Choose your book</h3><p>Browse by language or puzzle type, look inside, and pick a book or a bundle.</p></li>
      <li><span class="step-num">2</span><h3>Fill in a short form</h3><p>Just your name, email and phone number. No account needed.</p></li>
      <li><span class="step-num">3</span><h3>We confirm by email</h3><p>We contact you to confirm your order and payment, and help with any question.</p></li>
    </ol>
  </div>
</section>

<section id="languages" class="section-alt" aria-labelledby="langs-h">
  <div class="container">
    <div class="section-head"><div><span class="kicker">Shop by language</span><h2 id="langs-h">Puzzles in your language</h2><p>Puzzles feel more natural in the language you grew up with, and they make a lovely gift for family abroad.</p></div></div>
    <div class="langs">
$langTiles
    </div>
  </div>
</section>

<section aria-labelledby="faq-h">
  <div class="container faq-wrap">
    <div class="section-head"><div><span class="kicker">Questions</span><h2 id="faq-h">Frequently asked questions</h2><p>Can't find your answer? Email us at <a href="mailto:$email">$email</a>.</p></div></div>
    <div class="faq">
      <details><summary>Who are these books for?</summary><div><p>Our books are made for seniors, adults and anyone with low vision, including people living with macular degeneration (AMD). The large print and simple layout make them comfortable for everyone.</p></div></details>
      <details><summary>Is the website in English but the books in other languages?</summary><div><p>Yes. Each book page tells you the language of the puzzles. Today we publish books in <strong>Italian</strong> and <strong>French</strong>, and English and more languages are coming soon.</p></div></details>
      <details><summary>Are the solutions included?</summary><div><p>Yes, every book has a full solutions section at the back.</p></div></details>
      <details><summary>How do I order?</summary><div><p>Open any book or bundle and press <strong>Buy now</strong>. Fill in your name, email and phone number, and we'll contact you to confirm your order and payment. All prices are in US dollars.</p></div></details>
      <details><summary>Do you offer discounts?</summary><div><p>Yes. Our <a href="/bundles">bundles</a> group 2 to 11 books at a lower price than buying them one by one.</p></div></details>
      <details><summary>Can I order for a care home, school or library?</summary><div><p>Of course. <a href="/contact">Contact us</a> with the books and quantities you need and we'll prepare an offer.</p></div></details>
    </div>
  </div>
</section>

<section class="final-cta-section">
  <div class="container">
    <div class="cta cta-v2">
      <div>
        <h2>Give your eyes a rest, and your mind a workout</h2>
        <p>Choose from $($books.Count) large print puzzle books in Italian and French, or save with a bundle.</p>
      </div>
      <div class="cta-actions">
        <a class="btn btn-accent btn-lg" href="/books">Shop all books</a>
        <a class="btn btn-outline-light btn-lg" href="/contact">Request a language</a>
      </div>
    </div>
  </div>
</section>
"@

$orgLd = @"
<script type="application/ld+json">{"@context":"https://schema.org","@type":"Organization","name":"EasyEye Puzzles","url":"$site","logo":"$site/assets/brand/icon-512.png"}</script>
"@
WriteFile 'index.html' (Layout 'EasyEye Puzzles: Large Print Puzzle Books for Seniors & Low Vision' 'Large print word search, crossword and memory game books for seniors and people with low vision. Italian and French activity books, with more languages coming soon.' '/' 'home' $homeBody $orgLd)

# ---------- Catalog ----------
$allCards = ($books | ForEach-Object { Card $_ }) -join "`n"
$langChips = '<button class="chip" type="button" data-filter="lang" data-value="all">All languages</button>' + (($languages | Where-Object { $_.code -ne 'more' } | ForEach-Object { "<button class=""chip"" type=""button"" data-filter=""lang"" data-value=""$($_.code)"">$($_.name) ($(LangCount $_.code))</button>" }) -join '')
$typeChips = '<button class="chip" type="button" data-filter="type" data-value="all">All types</button>' + (($types | ForEach-Object { "<button class=""chip"" type=""button"" data-filter=""type"" data-value=""$(TypeSlug $_)"">$_</button>" }) -join '')
$catalogBody = @"
<section>
  <div class="container">
    <h1>All puzzle &amp; activity books</h1>
    <p class="lead" style="max-width:60ch;color:var(--ink-soft)">Large print puzzle books in several languages. Use the buttons below to filter by language or puzzle type. Want more than one book? <a href="/bundles">Save with a bundle</a>.</p>
    <div class="filter-group" role="group" aria-label="Filter by language"><span class="label">Language:</span>$langChips</div>
    <div class="filter-group" role="group" aria-label="Filter by puzzle type"><span class="label">Puzzle type:</span>$typeChips</div>
    <p class="result-count" data-result-count aria-live="polite"></p>
    <div class="coming-soon" data-coming-soon>
      <h2>Coming soon</h2>
      <p>We don't have a book that matches yet, but new languages and puzzle types are on the way.</p>
      <a class="btn btn-primary" href="/contact">Ask us to tell you when it's ready</a>
    </div>
    <div class="book-grid" data-catalog>
$allCards
    </div>
  </div>
</section>
"@
WriteFile 'books.html' (Layout 'All Large Print Puzzle Books' 'Browse every EasyEye Puzzles book: large print word search, crosswords, memory games and activity books in Italian and French.' '/books' 'books' $catalogBody)

# ---------- Bundles ----------
$allBundles = ($bundles | ForEach-Object { BundleCard $_ }) -join "`n"
$bundlesBody = @"
<section>
  <div class="container">
    <h1>Bundles &amp; savings</h1>
    <p class="lead" style="max-width:62ch;color:var(--ink-soft)">Buy books together and save. Each bundle shows its regular price (the books bought one by one) and how much you save.</p>
    <div class="bundle-grid">
$allBundles
    </div>
  </div>
</section>
"@
WriteFile 'bundles.html' (Layout 'Bundles & Savings' 'Save on large print puzzle books with EasyEye Puzzles bundles: from 2-book duos to the complete 11-book collection.' '/bundles' 'bundles' $bundlesBody)

# ---------- Book pages ----------
foreach ($b in $books) {
  $paras = ($b.description | ForEach-Object { "<p>$(Enc $_)</p>" }) -join "`n"
  $feats = ($b.features | ForEach-Object { "<li>$(Enc $_)</li>" }) -join ''
  $themes = ($b.themes | ForEach-Object { "<span class=""tag"">$(Enc $_)</span>" }) -join ''
  $order = OrderUrl $b.id $b.buyUrl
  $samples = @(1, 2) | ForEach-Object {
    $src = "/assets/books/$($b.img)-sample$_.jpg"
    "<figure><button type=""button"" data-zoom=""$src"" aria-label=""Enlarge sample page $_""><img src=""$src"" alt=""Sample page $_ from $(Enc $b.title)"" width=""700"" height=""913"" loading=""lazy""></button><figcaption>Sample page $_. Click to enlarge.</figcaption></figure>"
  }
  $inBundles = @($bundles | Where-Object { $_.books -contains $b.id } | Select-Object -First 3)
  $bundleSection = ''
  if ($inBundles.Count -gt 0) {
    $bundleSection = @"
<section aria-labelledby="save">
  <div class="container">
    <div class="section-head"><div><h2 id="save">Save with a bundle</h2><p>This book is part of these bundles.</p></div><a class="btn btn-ghost" href="/bundles">All bundles</a></div>
    <div class="bundle-grid">
$(($inBundles | ForEach-Object { BundleCard $_ }) -join "`n")
    </div>
  </div>
</section>
"@
  }
  $related = ($books | Where-Object { $_.id -ne $b.id -and ($_.lang -eq $b.lang -or $_.type -eq $b.type) } | Select-Object -First 4 | ForEach-Object { Card $_ }) -join "`n"
  $lvText = if ($b.lowVision) { 'Yes, extra large print' } else { 'Clear, readable print' }
  $body = @"
<section>
  <div class="container">
    <nav class="breadcrumb" aria-label="Breadcrumb"><a href="/">Home</a> &rsaquo; <a href="/books">Books</a> &rsaquo; <a href="/books?lang=$($b.lang)">$(Enc $b.language)</a> &rsaquo; $(Enc $b.title)</nav>
    <div class="book-detail">
      <div class="cover-lg"><img src="/assets/books/$($b.img)-cover.jpg" alt="Cover of $(Enc $b.title)" width="600" height="783"></div>
      <div>
        $(Tags $b)
        <h1 style="margin-top:14px">$(Enc $b.english)</h1>
        <p class="original" lang="$($b.lang)">$(Enc $b.title)</p>
        <p style="font-size:1.15rem">$(Enc $b.tagline)</p>
        <div class="buy-box">
          <div class="price-block"><span class="price price-lg">$(Money $b.price)</span><span class="muted">USD</span></div>
          <a class="btn btn-accent" href="$(Enc $order)">Buy now</a>
        </div>
        <ul class="facts">
          <li><b>Language</b>$(Enc $b.language)</li>
          <li><b>Puzzle type</b>$(Enc $b.type)</li>
          <li><b>Pages</b>$($b.pages)</li>
          <li><b>Format</b>Large 8.5 x 11 in</li>
          <li><b>Print</b>$lvText</li>
        </ul>
        <h2>About this book</h2>
        $paras
        <h2>What's inside</h2>
        <ul class="check-list">$feats</ul>
        <h3>Themes</h3>
        <div class="tags" style="margin-bottom:8px">$themes</div>
        <p style="margin-top:16px;color:var(--ink-soft)"><em>Note: the puzzles in this book are written in $(Enc $b.language).</em></p>
      </div>
    </div>
  </div>
</section>
<section class="section-alt" aria-labelledby="look">
  <div class="container">
    <div class="section-head"><div><h2 id="look">Look inside</h2><p>Real pages from the book. Click a page to see it larger.</p></div></div>
    <div class="samples">
$($samples -join "`n")
    </div>
  </div>
</section>
$bundleSection
<section class="section-alt" aria-labelledby="related">
  <div class="container">
    <div class="section-head"><div><h2 id="related">You may also like</h2></div><a class="btn btn-ghost" href="/books">All books</a></div>
    <div class="book-grid">
$related
    </div>
  </div>
</section>
<div class="lightbox" role="dialog" aria-modal="true" aria-label="Enlarged sample page"><button class="btn btn-accent close" type="button">Close</button><img src="" alt=""></div>
"@
  $ld = @{
    '@context' = 'https://schema.org'; '@type' = 'Book'; name = $b.title; alternateName = $b.english
    inLanguage = $b.lang; numberOfPages = $b.pages; bookFormat = 'https://schema.org/Paperback'
    image = "$site/assets/books/$($b.img)-cover.jpg"; description = $b.tagline; url = "$site/books/$($b.id)"
    publisher = @{ '@type' = 'Organization'; name = 'EasyEye Puzzles' }
    offers = @{ '@type' = 'Offer'; price = "$($b.price).00"; priceCurrency = 'USD'; availability = 'https://schema.org/InStock'; url = "$site/books/$($b.id)" }
  } | ConvertTo-Json -Compress -Depth 5
  $extra = "<script type=""application/ld+json"">$ld</script>"
  WriteFile "books\$($b.id).html" (Layout "$($b.english) ($($b.language))" "$($b.tagline) $($b.pages) pages, in $($b.language). $(Money $b.price)." "/books/$($b.id)" 'books' $body $extra "$site/assets/books/$($b.img)-cover.jpg")
}

# ---------- About ----------
$aboutBody = @"
<section>
  <div class="container prose">
    <h1>About EasyEye Puzzles</h1>
    <p style="font-size:1.15rem">We create puzzle and activity books that everyone can enjoy, especially readers whose eyes need a little extra comfort.</p>
    <h2>Our story</h2>
    <p>Many puzzle books are printed with tiny letters and crowded grids. For seniors and people with low vision, that turns a relaxing hobby into a strain. EasyEye Puzzles was started to fix that, with books that use big, clear print, strong contrast and plenty of white space.</p>
    <h2>Puzzles in your own language</h2>
    <p>A puzzle feels best in the language you grew up with. That is why our books are written natively, not translated, with themes taken from each culture: Italian monuments and cuisine, French heritage and Francophone festivals, and more to come.</p>
    <h2>What makes our books different</h2>
    <ul class="check-list">
      <li>Large print and high contrast on every page</li>
      <li>Three difficulty levels so everyone can progress</li>
      <li>Culture-rich themes that bring back memories and start conversations</li>
      <li>Large 8.5 x 11 inch format that is easy to hold and write in</li>
      <li>Full solutions included</li>
    </ul>
    <p><a class="btn btn-primary" href="/books">Explore our books</a></p>
  </div>
</section>
"@
WriteFile 'about.html' (Layout 'About Us' 'EasyEye Puzzles creates large print puzzle and activity books for seniors and readers with low vision, in Italian, French and more languages.' '/about' 'about' $aboutBody)

# ---------- Contact ----------
$contactBody = @"
<section>
  <div class="container">
    <h1>Contact us</h1>
    <div class="two-col">
      <div class="panel">
        <h2>Sales &amp; help</h2>
        <p>Questions about a book or an order, bulk orders for care homes or libraries, or a request for a new language? We'd love to hear from you.</p>
        <p style="font-size:1.2rem"><a href="mailto:$email">$email</a></p>
        <a class="btn btn-primary" href="mailto:$email?subject=Question%20about%20EasyEye%20Puzzles">Send an email</a>
      </div>
      <div class="panel">
        <h2>Request a language</h2>
        <p>We are working on new books in <strong>English</strong> and other languages. Tell us which language and puzzle type you would like (word search, crosswords, memory games or mixed activities), and we will let you know when it is published.</p>
        <a class="btn btn-ghost" href="mailto:$email?subject=Language%20request">Request a language</a>
      </div>
    </div>
  </div>
</section>
"@
WriteFile 'contact.html' (Layout 'Contact' 'Contact EasyEye Puzzles about our large print puzzle books, orders, bulk orders, or to request a new language.' '/contact' 'contact' $contactBody)

# ---------- Privacy ----------
$privacyBody = @"
<section>
  <div class="container prose">
    <h1>Privacy policy</h1>
    <p>This website does not use advertising or tracking cookies and does not ask you to create an account.</p>
    <h2>Preferences</h2>
    <p>If you change the text size or turn on night mode, that choice is saved only in your own browser (local storage) so the site remembers it on your next visit. It is never sent to us.</p>
    <h2>Orders</h2>
    <p>When you place an order, we use the details you give us (such as your name, email and shipping address) only to process and deliver your order and to answer your questions. Payments are handled by our payment provider, and we never see or store your card details.</p>
    <h2>Fonts and hosting</h2>
    <p>The site is hosted on Cloudflare and uses Google Fonts to display the Atkinson Hyperlegible typeface. These providers may process technical data such as your IP address to deliver the pages.</p>
    <h2>Contact</h2>
    <p>For any privacy question, email <a href="mailto:$email">$email</a>.</p>
  </div>
</section>
"@
WriteFile 'privacy.html' (Layout 'Privacy Policy' 'Privacy policy for EasyEye Puzzles.' '/privacy' '' $privacyBody)

# ---------- 404 ----------
$nfBody = @"
<section><div class="container prose" style="text-align:center;margin-inline:auto">
  <h1>Page not found</h1>
  <p>Sorry, we couldn't find that page. It may have moved.</p>
  <p><a class="btn btn-primary" href="/books">Browse all books</a> <a class="btn btn-ghost" href="/">Go to the home page</a></p>
</div></section>
"@
WriteFile '404.html' (Layout 'Page not found' 'Page not found.' '/404' '' $nfBody)

# ---------- Checkout pages (one per product, no site header/footer) ----------
function CheckoutPage([string]$id, [string]$name, [string]$subtitle, $price, [string]$kind, [string]$backUrl, [string]$imgHtml) {
  $productUrl = "$site$backUrl"
@"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Checkout: $(Enc $name) | EasyEye Puzzles</title>
<meta name="robots" content="noindex, nofollow">
<meta name="theme-color" content="#14213d">
<link rel="icon" href="/favicon.png" type="image/png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible:wght@400;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/assets/css/style.css?v=$ver">
<script>try{var d=document.documentElement,s=localStorage.getItem('eep-size'),t=localStorage.getItem('eep-theme');if(s&&s!=='m')d.setAttribute('data-size',s);if(t==='night'||(!t&&window.matchMedia&&matchMedia('(prefers-color-scheme: dark)').matches))d.setAttribute('data-theme','night');}catch(e){}</script>
</head>
<body class="checkout-body">
<main class="checkout">
  <a class="checkout-back" href="$backUrl">&larr; Back</a>
  <div class="checkout-card">
    <div class="checkout-product">
      $imgHtml
      <div>
        <p class="checkout-kind">$(Enc $kind)</p>
        <h1>$(Enc $name)</h1>
        $(if ($subtitle) { "<p class=""checkout-sub"">$(Enc $subtitle)</p>" })
        <p class="checkout-price">$(Money $price) <span>USD</span></p>
      </div>
    </div>

    <form id="checkout-form" novalidate data-product="$(Enc $name)" data-price="$(Money $price)" data-kind="$(Enc $kind)" data-url="$productUrl">
      <div class="field">
        <label for="name">Full name</label>
        <input id="name" name="name" type="text" autocomplete="name" required>
      </div>
      <div class="field">
        <label for="email">Email</label>
        <input id="email" name="email" type="email" autocomplete="email" inputmode="email" required>
      </div>
      <div class="field">
        <label for="phone">Phone number</label>
        <input id="phone" name="phone" type="tel" autocomplete="tel" inputmode="tel" required>
      </div>
      <div class="hp" aria-hidden="true"><label for="website">Leave this empty</label><input id="website" name="website" type="text" tabindex="-1" autocomplete="off"></div>
      <p id="form-error" class="form-error" role="alert" tabindex="-1" hidden></p>
      <button class="btn btn-accent checkout-submit" type="submit">Submit order &middot; $(Money $price)</button>
      <p class="checkout-note">We will contact you by email to confirm your order and payment.</p>
    </form>

    <div id="order-done" class="order-done" tabindex="-1" hidden>
      <div class="done-icon" aria-hidden="true">&#10003;</div>
      <h2>Thank you, your order is received!</h2>
      <p>Order number: <strong id="done-id"></strong></p>
      <p>We will contact you at <strong id="done-email"></strong> to confirm your order and payment.</p>
      <a class="btn btn-primary" href="/">Back to EasyEye Puzzles</a>
    </div>
  </div>
</main>
<script src="https://cdn.jsdelivr.net/npm/@emailjs/browser@4/dist/email.min.js"></script>
<script src="/assets/js/checkout.js?v=$ver"></script>
</body>
</html>
"@
}

foreach ($b in $books) {
  $img = "<img class=""checkout-cover"" src=""/assets/books/$($b.img)-cover.jpg"" alt="""" width=""600"" height=""783"">"
  WriteFile "checkout\$($b.id).html" (CheckoutPage $b.id $b.title $b.english $b.price "$($b.language) book" "/books/$($b.id)" $img)
}
foreach ($x in $bundles) {
  $n = @($x.books).Count
  $titles = ($x.books | ForEach-Object { $byId[$_].title }) -join ', '
  $covers = '<div class="checkout-covers" aria-hidden="true">' + (($x.books | Select-Object -First 3 | ForEach-Object { "<img src=""/assets/books/$($byId[$_].img)-cover.jpg"" alt="""" width=""600"" height=""783"">" }) -join '') + $(if ($n -gt 3) { "<span>+$($n - 3)</span>" } else { '' }) + '</div>'
  WriteFile "checkout\$($x.id).html" (CheckoutPage $x.id $x.name "Includes: $titles" $x.price "Bundle of $n books" "/bundles#$($x.id)" $covers)
}

# ---------- Sitemap & robots ----------
$urls = @('/', '/books', '/bundles', '/about', '/contact', '/privacy') + ($books | ForEach-Object { "/books/$($_.id)" })
$today = (Get-Date).ToString('yyyy-MM-dd')
$sm = "<?xml version=""1.0"" encoding=""UTF-8""?>`n<urlset xmlns=""http://www.sitemaps.org/schemas/sitemap/0.9"">`n" + (($urls | ForEach-Object { "  <url><loc>$site$_</loc><lastmod>$today</lastmod></url>" }) -join "`n") + "`n</urlset>`n"
WriteFile 'sitemap.xml' $sm
WriteFile 'robots.txt' "User-agent: *`nAllow: /`nDisallow: /checkout/`n`nSitemap: $site/sitemap.xml`n"

"Built $($books.Count) book pages and $($bundles.Count) bundles into $pub"
