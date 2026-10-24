---
title: Letting the browser choose
version: 1
---

**The page does not know the screen; the browser does.** So the HTML offers every copy and says how
wide the picture will be drawn, and the browser picks the copy that fits. Three pieces of markup do
it:

- **`srcset`** lists the copies with their widths: `/covers/git-400.jpg 400w, /covers/git-800.jpg
  800w, …`. The `w` is the file's width in pixels, written by whoever made the files.
- **`sizes`** says how wide the picture will be drawn, in CSS, for each kind of window. The browser
  needs it before it has laid out the page, which is why it cannot measure it itself.
- **`<picture>`** wraps the `<img>` with one `<source>` per format, in order of preference. The browser
  takes the first type it can read and ignores the rest, and the `<img>` inside is what a browser that
  reads none of them shows.

For the planner, `sizes` is the column: forty rems once the window is wide enough to have margins
around it, and otherwise the window less the two rems of padding. In `src/view.ts`, add this function
right after the line that defines `day`:

```typescript
// The cover in three widths and three formats. The browser takes the first format it
// can read, and in it the smallest width that fills the space sizes describes.
const cover = (slug: string) => {
  const set = (ext: string) => [400, 800, 1600].map((w) => `/covers/${slug}-${w}.${ext} ${w}w`).join(", ");
  const sizes = "(min-width: 42rem) 40rem, calc(100vw - 2rem)";
  return `<picture>
  <source type="image/avif" srcset="${set("avif")}" sizes="${sizes}">
  <source type="image/webp" srcset="${set("webp")}" sizes="${sizes}">
  <img class="cover" src="/covers/${slug}-800.jpg" srcset="${set("jpg")}" sizes="${sizes}" alt="">
</picture>`;
};
```

and in `coursePage`, replace the `<img>` line with a call to it:

```typescript
${cover(course.slug)}
```

## What each screen chose

`tools/chosen.ts` opens the course page as four kinds of screen and asks the page which file its
picture came from: `currentSrc`, the address the browser picked. Save it in `tools/`:

```typescript
// tools/chosen.ts: open a page as four kinds of screen and say which file of the
// cover each one downloaded.
//
//   node tools/chosen.ts URL
import { chromium } from "playwright";

const url = process.argv[2];
const screens = [
  { name: "phone", width: 390, height: 844, scale: 3 },
  { name: "older phone", width: 390, height: 844, scale: 1 },
  { name: "laptop", width: 1280, height: 800, scale: 1 },
  { name: "laptop, sharp", width: 1280, height: 800, scale: 2 },
];
const browser = await chromium.launch();
for (const s of screens) {
  // A context of its own for each, so no screen finds the file another one downloaded.
  const context = await browser.newContext({ viewport: { width: s.width, height: s.height }, deviceScaleFactor: s.scale });
  const page = await context.newPage();
  await page.goto(url, { waitUntil: "networkidle" });
  const src = await page.$eval("img.cover", (img) => (img as HTMLImageElement).currentSrc);
  console.log(`${s.name.padEnd(14)} ${String(s.width).padStart(4)} px x${s.scale}  ${new URL(src).pathname}`);
  await context.close();
}
await browser.close();
```

Build, restart `server.ts`, and ask:

```
ana@dev:~/planner$ node tools/chosen.ts http://localhost:3000/courses/git
phone           390 px x3  /covers/git-1600.avif
older phone     390 px x1  /covers/git-400.avif
laptop         1280 px x1  /covers/git-800.avif
laptop, sharp  1280 px x2  /covers/git-1600.avif
```

**One tag, three different files, all of them AVIF.** The phone draws the picture about 360 CSS pixels
wide, which at three device pixels each is about a thousand, so it takes the 1600. The older phone,
one device pixel each, takes the 400. The laptop draws 640 and takes the 800, and the sharp laptop needs
1280 and takes the 1600. The choice is the browser's, and it can weigh things the page cannot see: a
browser may take a smaller copy on a slow connection, or keep using a larger one it already has.

## And Lighthouse

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP|CLS|insight'
performance 100, throttling simulate
  LCP  1.3 s    weight 25
  CLS  0        weight 25
  insight: Use efficient cache lifetimes, Est savings of 45 KiB
  insight: Improve image delivery, Est savings of 29 KiB
  insight: LCP request discovery
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
```

**From almost forty seconds to 1.3.** The simulated phone downloaded an AVIF of under forty
kilobytes instead of a PNG of eight megabytes. And the CLS is zero again, which is less good news than
it looks: the small file arrived before the first paint, on a computer with no network in between, so
nothing moved this time. The section after next measures it on a slow network, where it does.
