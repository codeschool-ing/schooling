---
title: A slow page, built on purpose
version: 1
---

Lighthouse needs a page to measure, and the box office has none yet: `~/boxoffice/static/` is
empty, and `app.py` serves whatever is put there. This section writes two pages that show the
same thing, the list of shows on sale under a picture of the stage. **The first is slow in four
ways that real pages are slow, one defect for each number the next section reads.** The second
fixes all four. Measuring both is the quickest way to see which number moves with which defect.

The four defects are the common ones, and each has a name you will meet in a Lighthouse report:

| defect | what it costs | the number that shows it |
|---|---|---|
| a script in `<head>` that blocks the parser | the page stays blank while it runs | First Contentful Paint |
| a heavy picture as the largest thing on the screen | the main content arrives last | Largest Contentful Paint |
| work on the main thread after the page appears | taps and keys wait | Total Blocking Time |
| content that moves after it is drawn | the reader loses their place, or taps the wrong thing | Cumulative Layout Shift |

## The pictures

A real hero image is a photograph, and a photograph barely compresses: most of its bytes are
detail. `make_hero.py` stands in for one without needing a camera or an image library. It writes
a PNG of random noise, which no compressor can shrink, and a second, smaller PNG of a smooth
gradient, which compresses to almost nothing. It is standard library only, like `app.py`. Create
it in `~/boxoffice` with `nano make_hero.py`:

```python
# boxoffice/make_hero.py
# Draws the two hero pictures the pages in static/ show, with nothing but
# the standard library. The heavy one is noise, which no compressor can
# shrink, the way a photograph barely shrinks; the light one is a gradient.
import os, random, struct, zlib

def png(path, width, height, pixel):
    rows = b"".join(b"\x00" + b"".join(pixel(x, y) for x in range(width))
                    for y in range(height))
    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data)))
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(rows, 9)))
        f.write(chunk(b"IEND", b""))
    print(f"{path}: {width}x{height}, {os.path.getsize(path)} bytes")

rnd = random.Random(7)
os.makedirs("static", exist_ok=True)
png("static/hero.png", 1200, 675, lambda x, y: rnd.randbytes(3))
png("static/hero-small.png", 800, 450, lambda x, y: bytes((60 + x // 8, 30 + y // 5, 90)))
```

The format is short enough to write by hand: a signature, a header chunk with the size, one
compressed chunk of pixel rows, and an end chunk, each chunk followed by a checksum. Run it:

```
ana@nft:~/boxoffice$ python3 make_hero.py
static/hero.png: 1200x675, 2431483 bytes
static/hero-small.png: 800x450, 20367 bytes
ana@nft:~/boxoffice$ ls -l static
total 2408
-rw-r--r-- 1 ana ana     950 Oct 10 04:33 fast.html
-rw-rw-r-- 1 ana ana   20367 Oct 10 04:34 hero-small.png
-rw-rw-r-- 1 ana ana 2431483 Oct 10 04:34 hero.png
-rw-r--r-- 1 ana ana    1239 Oct 10 04:33 index.html
-rw-r--r-- 1 ana ana     205 Oct 10 04:33 slow.js
```

**2,431,483 bytes against 20,367**, for two pictures the reader sees at the
same size on a phone. The light one is also smaller in pixels, 800 wide against 1200, because the
page's column is never wider than 40rem.

## The slow page

`slow.js` is the script that blocks. Write it with `nano static/slow.js`:

```javascript
// boxoffice/static/slow.js
// A script in the page's <head> that does nothing useful for 500 ms.
// While it runs, the browser draws nothing.
const until = Date.now() + 500;
while (Date.now() < until) {}
```

A loop that checks the clock until half a second has passed is the purest form of a script that
costs time: no network, no work, only the main thread kept busy. Real pages get the same effect
from a large framework bundle, a tag manager or a consent banner loaded the same way.

Then the page itself, `static/index.html`. The notes beside each part say which defect it is; the
copy button takes the whole file without them.

```schooling-example
{"language": "html", "file": "boxoffice/static/index.html", "parts": [{"code": "<!-- boxoffice/static/index.html -->\n<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n<title>Box office</title>\n<script src=\"slow.js\"></script>", "note": "The script in the `<head>` is the first defect. A plain `<script src>` stops the parser until the file has arrived and run, and the browser draws nothing before the parser reaches `<body>`. `slow.js` spends 500 ms doing nothing, so the page stays blank for at least that long."}, {"code": "<style>\n  body { font-family: sans-serif; margin: 0 auto; max-width: 40rem; padding: 0 1rem; }\n  img { width: 100%; }\n  .banner { background: #fde68a; margin: 0; padding: 3rem 1rem; }\n  li { padding: 0.4rem 0; }\n</style>", "note": "`width: 100%` and no height. The browser cannot know how tall the picture will be until enough of the file has arrived to read its dimensions, so it lays the page out with the picture at zero height and moves everything below it when it learns."}, {"code": "</head>\n<body>\n<h1>Box office</h1>\n<img src=\"hero.png\" alt=\"The stage, lit for tonight's show\">\n<ul id=\"shows\"><li>Loading the shows...</li></ul>", "note": "The second defect is the `<img>` with no `width` and no `height` attributes, which would have told the browser the shape before a byte of the file arrived. The third is the file itself: `hero.png` is the heavy picture, 1200 pixels wide, drawn into a column at most 40rem wide."}, {"code": "<script>\n  fetch(\"/shows\").then(r => r.json()).then(shows => {\n    const until = Date.now() + 400;   // 400 ms of work before the list is drawn\n    while (Date.now() < until) {}\n    document.getElementById(\"shows\").innerHTML = shows.map(s =>\n      `<li>${s.title}, ${s.day}: R$ ${(s.price_cents / 100).toFixed(2)}</li>`).join(\"\");\n  });", "note": "The list arrives from `/shows`, and then the page spends 400 ms of work before it draws it. Here the work is a loop that only waits; on a real page it is a framework rendering, a carousel initialising or an analytics library parsing. While it runs the page cannot answer a tap."}, {"code": "  setTimeout(() => {                  // the promotion arrives a moment later\n    const banner = document.createElement(\"p\");\n    banner.className = \"banner\";\n    banner.textContent = \"Tonight only: two tickets for the price of one.\";\n    document.body.prepend(banner);\n  }, 1000);\n</script>\n</body>\n</html>", "note": "The fourth defect: a promotion inserted at the top of the page a second after the rest has been drawn. Everything already on the screen moves down by the banner's height, which is what Cumulative Layout Shift counts."}]}
```

**Nothing about it is broken in the functional sense**: the list arrives, the
prices are right, the banner says what it should. A functional test of this page passes.

## The fixed page

`static/fast.html` keeps the same content and removes the four defects:

```html
<!-- boxoffice/static/fast.html -->
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Box office</title>
<style>
  body { font-family: sans-serif; margin: 0 auto; max-width: 40rem; padding: 0 1rem; }
  img { width: 100%; height: auto; }
  .banner { background: #fde68a; margin: 0; padding: 3rem 1rem; }
  li { padding: 0.4rem 0; }
</style>
</head>
<body>
<p class="banner">Tonight only: two tickets for the price of one.</p>
<h1>Box office</h1>
<img src="hero-small.png" width="800" height="450" fetchpriority="high"
     alt="The stage, lit for tonight's show">
<ul id="shows"><li>Loading the shows...</li></ul>
<script>
  fetch("/shows").then(r => r.json()).then(shows => {
    document.getElementById("shows").innerHTML = shows.map(s =>
      `<li>${s.title}, ${s.day}: R$ ${(s.price_cents / 100).toFixed(2)}</li>`).join("");
  });
</script>
</body>
</html>
```

What changed, defect by defect:

- **No blocking script.** The work `slow.js` did was useless, so it is gone. A script that is
  needed would carry `defer`, which lets the parser carry on and runs the script once the page
  is parsed.
- **The light picture, with its shape declared.** `width="800" height="450"` gives the browser the
  aspect ratio before the file arrives, and `height: auto` in the stylesheet keeps the ratio when
  the width is 100%. `fetchpriority="high"` tells the browser this is the picture that matters.
- **No work before the list is drawn.** The rows go in as soon as `/shows` answers.
- **The banner is in the HTML**, above the heading, so it is drawn with everything else and moves
  nothing when it appears.

Both pages are served by the box office as it is, from the same directory. With the server
running in the first terminal, `localhost:8000/` is the slow page and `localhost:8000/fast.html`
the fixed one.
