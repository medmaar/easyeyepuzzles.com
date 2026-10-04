# easyeyepuzzles.com

Website for **EasyEye Puzzles**: large print puzzle and activity books for seniors and readers with low vision (Italian, French, and more languages coming).

It's a static site hosted on **Cloudflare Pages** and deployed automatically on every push to `main`.

## Structure

```
data/books.json      # the book catalog (titles, descriptions, features, Amazon links)
tools/build.ps1      # generates the HTML pages in public/ from data/books.json
public/              # the website (Cloudflare Pages output directory)
  assets/books/      # covers (<img>-cover.jpg) and sample pages (<img>-sample1/2.jpg)
  assets/css, assets/js
```

## Add or edit a book

1. Edit `data/books.json`. To add a book, copy an existing entry and give it a new `id` (the URL slug) and `img` (the image file prefix).
2. Add the images to `public/assets/books/`: `<img>-cover.jpg` (600 px wide) and `<img>-sample1.jpg` / `<img>-sample2.jpg` (700 px wide).
3. Set `"buyUrl"` to the book's Amazon page. Without it, the button links to an Amazon search for the title.
4. Regenerate the pages, then commit and push:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build.ps1
```

## Cloudflare Pages settings

- Framework preset: None
- Build command: *(empty)*
- Build output directory: `public`
