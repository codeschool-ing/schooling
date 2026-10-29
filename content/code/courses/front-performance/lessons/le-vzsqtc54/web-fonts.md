---
title: A web font, and what it costs while it loads
version: 1
---

**A web font is a file the page downloads before it can draw its text in that typeface.** Until then
the browser has two choices, and the page picks with the `font-display` descriptor of its
`@font-face` rule:

| `font-display` | while the font loads | the cost |
|---|---|---|
| `block` | the text is drawn invisibly, for up to three seconds | a page with no words; the LCP waits for the font |
| `swap` | the text is drawn at once in a fallback, then redrawn in the font | the text changes under the reader, and can move |
| `optional` | like `swap`, but the font is used only if it arrives almost at once | the font may not show on a first visit at all |

Leaving it out lets the browser decide, and browsers have not always decided alike, so say which one.

## IBM Plex Sans in the planner

The typeface for the planner is IBM Plex Sans, which is free under the SIL Open Font License. The
Fontsource project publishes it, and every other open font, as npm packages with the files ready to
serve, so it can be pinned like any tool:

```
ana@dev:~/planner$ npm install --save-exact --save-dev @fontsource/ibm-plex-sans@5.3.0

added 3 packages, and audited 146 packages in 739ms

34 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

The package carries every weight in every alphabet. The planner needs two files, the regular and the
bold, for the Latin alphabet; copy those into `public/fonts/`:

```
ana@dev:~/planner$ mkdir -p public/fonts && for w in 400 700; do cp node_modules/@fontsource/ibm-plex-sans/files/ibm-plex-sans-latin-$w-normal.woff2 public/fonts/plex-$w.woff2; done
```

**WOFF2 is the format to serve**: a font compressed for the web, read by every current browser.
Serving the planner's own copy, rather than linking to a font service, keeps the font on the same
server as the page, with no second connection to open and no other company told which page was read.

In `src/style.css`, put the font first in the body's list, replacing the first line:

```css
body { font: 16px/1.5 "IBM Plex Sans", system-ui, sans-serif; margin: 0 auto; max-width: 40rem; padding: 1rem; }
```

and add the two faces at the end, with `block` first, to see it:

```css
@font-face { font-family: "IBM Plex Sans"; src: url("/fonts/plex-400.woff2") format("woff2"); font-weight: 400; font-display: block; }
@font-face { font-family: "IBM Plex Sans"; src: url("/fonts/plex-700.woff2") format("woff2"); font-weight: 700; font-display: block; }
```

Build, restart, and measure the home page, whose LCP is the notice's text, on a phone with every
request 300 milliseconds slower:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/ --phone --slow
[vitals] CLS 0.000 good 
[vitals] LCP 944 ms good #notice
```

## Block, then swap

**The LCP waited for the font.** The text was there, laid out and invisible, until the font arrived.
The waterfall says when that was:

```
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:3000/ --slow
/                              305 ms     691 B  ######
/assets/index-Du7rLN0M.js      619 ms    6918 B        ######
/assets/index-B7yWkOCo.css     618 ms     385 B        ######
/fonts/plex-400.woff2          945 ms   22611 B               ######
/fonts/plex-700.woff2          946 ms   22842 B               ######
```

**The fonts start only after the stylesheet has arrived**: the browser learns about a font from a
`@font-face` rule, and only asks for it once it knows some text on the page uses it. So the font is a
third step after the HTML and the CSS. Change both `font-display: block` to `font-display: swap`,
build, restart, measure:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/ --phone --slow
[vitals] LCP 640 ms good #notice
[vitals] CLS 0.001 good #app>ul.courses>li>TEXT
```

**Three hundred milliseconds earlier, and a CLS that is no longer zero.** The text was painted in the
fallback and then redrawn in Plex, whose letters are not the same width, and a line of the course list
moved. Tiny here; on a page of paragraphs, every line whose wrapping changes moves every line below it.

## Asking for it early

The step the font waits for is the stylesheet. **`<link rel="preload">`** tells the browser about a file
before anything refers to it, so it is requested with the HTML's other files. In `index.html`, add these
two lines just before the `<title>`:

```html
    <link rel="preload" href="/fonts/plex-400.woff2" as="font" type="font/woff2" crossorigin />
    <link rel="preload" href="/fonts/plex-700.woff2" as="font" type="font/woff2" crossorigin />
```

`as="font"` gives it a font's priority, and `crossorigin` is required even on the same server, because
fonts are always requested in CORS mode and a preload without it would be fetched a second time.
Build, restart, measure:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/ --phone --slow
[vitals] LCP 636 ms good #notice
[vitals] CLS 0.000 good 
```

**The fonts now arrive with the stylesheet**, the text is painted once, in Plex, and nothing moves. On
a real phone network a font may still be late, and then the swap still happens: what makes it harmless
is the next section.
