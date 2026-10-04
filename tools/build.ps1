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

# Checkout link: the item's buyUrl (e.g. a Stripe / PayPal payment link) or, until one is set, an order email.
function OrderUrl([string]$name, $price, [string]$buyUrl) {
  if ($buyUrl) { return $buyUrl }
  $subject = [Uri]::EscapeDataString("Order: $name ($(Money $price))")
  $bodyText = [Uri]::EscapeDataString("Hello, I would like to order: $name ($(Money $price)).`n`nMy name:`nShipping address:`n")
  return "mailto:$email" + "?subject=$subject&body=$bodyText"
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
      <a class="btn btn-accent" href="$(Enc (OrderUrl $x.name $x.price $x.buyUrl))">Buy bundle</a>
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

# ---------- Home ----------
$featured = @('parole-intrecciate-anziani-ipovedenti', 'mots-meles-seniors-malvoyants', 'giochi-di-memoria-per-anziani', 'cruciverba-per-nonni')
$featuredCards = (@($books | Where-Object { $featured -contains $_.id }) | ForEach-Object { Card $_ }) -join "`n"
$homeBundles = (@($bundles | Where-Object { @('french-word-search-duo', 'complete-french-collection', 'complete-collection') -contains $_.id }) | ForEach-Object { BundleCard $_ }) -join "`n"
$langTiles = ($languages | ForEach-Object {
  $n = LangCount $_.code
  $sub = if ($n -gt 0) { "$n book" + $(if ($n -ne 1) { 's' } else { '' }) } else { 'Coming soon' }
  $href = if ($_.code -eq 'more') { '/contact' } else { "/books?lang=$($_.code)" }
  "<a class=""lang-tile"" href=""$href""><span class=""flag"" aria-hidden=""true"">$($_.flag)</span><strong>$($_.name)</strong><span>$sub</span></a>"
}) -join "`n"

$homeBody = @"
<section class="hero">
  <div class="container">
    <div>
      <span class="eyebrow">Large print &middot; High contrast &middot; Gentle on the eyes</span>
      <h1>Puzzle books that are easy on the eyes and great for the mind</h1>
      <p class="lead">Word searches, crosswords and memory games in big, clear print, made for seniors, people with low vision and anyone who loves a good puzzle. Books from $(Money $minPrice).</p>
      <div class="hero-actions">
        <a class="btn btn-primary" href="/books">Browse all books</a>
        <a class="btn btn-ghost" href="/bundles">Save with bundles</a>
      </div>
    </div>
    <div class="hero-stack" aria-hidden="true">
      <img src="/assets/books/mots-meles-seniors-cover.jpg" alt="" width="600" height="783">
      <img src="/assets/books/parole-ipovedenti-cover.jpg" alt="" width="600" height="783">
      <img src="/assets/books/viaggio-italia-cover.jpg" alt="" width="600" height="783">
    </div>
  </div>
</section>

<section class="section-alt" aria-labelledby="why">
  <div class="container">
    <div class="section-head"><div><h2 id="why">Why readers love EasyEye books</h2><p>Every page is designed so it is comfortable to read, enjoyable to solve and good for the mind.</p></div></div>
    <div class="features">
      <div class="card"><div class="icon">$($icon.eye)</div><h3>Large, clear print</h3><p>Big letters, strong contrast and roomy grids mean less squinting and more fun.</p></div>
      <div class="card"><div class="icon">$($icon.brain)</div><h3>Keeps the mind active</h3><p>Puzzles at easy, medium and hard levels exercise memory, focus and vocabulary.</p></div>
      <div class="card"><div class="icon">$($icon.globe)</div><h3>In your language</h3><p>Puzzles written natively in Italian and French, with English and more languages on the way.</p></div>
      <div class="card"><div class="icon">$($icon.gift)</div><h3>A thoughtful gift</h3><p>Ideal for parents, grandparents, care homes and anyone who loves words.</p></div>
    </div>
  </div>
</section>

<section aria-labelledby="featured">
  <div class="container">
    <div class="section-head"><div><h2 id="featured">Popular books</h2><p>A few of our readers' favourites.</p></div><a class="btn btn-ghost" href="/books">See all $($books.Count) books</a></div>
    <div class="book-grid">
$featuredCards
    </div>
  </div>
</section>

<section class="section-alt" aria-labelledby="bundles-h">
  <div class="container">
    <div class="section-head"><div><h2 id="bundles-h">Bundle and save</h2><p>Buy more books together and pay less. Our biggest bundle saves $(Money ((BundleValue ($bundles | Where-Object { $_.id -eq 'complete-collection' })) - ($bundles | Where-Object { $_.id -eq 'complete-collection' }).price)).</p></div><a class="btn btn-ghost" href="/bundles">See all $($bundles.Count) bundles</a></div>
    <div class="bundle-grid">
$homeBundles
    </div>
  </div>
</section>

<section id="languages" aria-labelledby="langs-h">
  <div class="container">
    <div class="section-head"><div><h2 id="langs-h">Shop by language</h2><p>Puzzles feel more natural in the language you grew up with, and they make a lovely gift for family abroad.</p></div></div>
    <div class="langs">
$langTiles
    </div>
  </div>
</section>

<section class="section-alt" aria-labelledby="faq-h">
  <div class="container">
    <div class="section-head"><div><h2 id="faq-h">Frequently asked questions</h2></div></div>
    <div class="faq">
      <details><summary>Who are these books for?</summary><div><p>Our books are made for seniors, adults and anyone with low vision, including people living with macular degeneration (AMD). The large print and simple layout make them comfortable for everyone.</p></div></details>
      <details><summary>Is the website in English but the books in other languages?</summary><div><p>Yes. Each book page tells you the language of the puzzles. Today we publish books in <strong>Italian</strong> and <strong>French</strong>, and English and more languages are coming soon.</p></div></details>
      <details><summary>Are the solutions included?</summary><div><p>Yes, every book has a full solutions section at the back.</p></div></details>
      <details><summary>How do I order?</summary><div><p>Open any book or bundle and press <strong>Buy now</strong>. All prices are in US dollars.</p></div></details>
      <details><summary>Do you offer discounts?</summary><div><p>Yes. Our <a href="/bundles">bundles</a> group 2 to 11 books at a lower price than buying them one by one.</p></div></details>
    </div>
  </div>
</section>

<section>
  <div class="container">
    <div class="cta">
      <div><h2>Looking for a book in another language?</h2><p>Tell us which language and puzzle type you would like next, and we will let you know when it is ready.</p></div>
      <a class="btn btn-accent" href="/contact">Send us a request</a>
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
  $order = OrderUrl $b.title $b.price $b.buyUrl
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

# ---------- Sitemap & robots ----------
$urls = @('/', '/books', '/bundles', '/about', '/contact', '/privacy') + ($books | ForEach-Object { "/books/$($_.id)" })
$today = (Get-Date).ToString('yyyy-MM-dd')
$sm = "<?xml version=""1.0"" encoding=""UTF-8""?>`n<urlset xmlns=""http://www.sitemaps.org/schemas/sitemap/0.9"">`n" + (($urls | ForEach-Object { "  <url><loc>$site$_</loc><lastmod>$today</lastmod></url>" }) -join "`n") + "`n</urlset>`n"
WriteFile 'sitemap.xml' $sm
WriteFile 'robots.txt' "User-agent: *`nAllow: /`n`nSitemap: $site/sitemap.xml`n"

"Built $($books.Count) book pages and $($bundles.Count) bundles into $pub"
