---
title: The viewport, and what a phone says about itself
version: 1
---

The usual first idea of testing on a phone is a narrow window: make the browser 390 pixels wide
and call it an iPhone. **The width is one of six options Playwright sets for a phone**, and one of
the others decides whether the page is laid out at that width at all. This section names them,
prints what Playwright sets for one phone, and measures what a page sees.

## Two kinds of pixel

A stylesheet is written in **CSS pixels**, a unit of length the browser decides, and the screen is
made of **device pixels**, the dots on the glass. On a desktop monitor the two are usually the
same. A phone packs several device pixels into one CSS pixel, so that text is sharp and still a
readable size; the ratio between them is the **device pixel ratio**. An iPhone 13 is 390 CSS
pixels wide at a ratio of 3, which is 1170 dots across. Every width in this lesson, in the
stylesheet and in the tests, is in CSS pixels. The ratio matters to a screenshot, which lesson 16
is about, and almost never to whether a button works.

## The viewport tag

The window a page is laid out in is the **viewport**. Phones were built for a web of pages
designed for desktops, so a phone browser lays out a page as if its window were about 980 CSS
pixels wide and then shrinks the result to fit the glass: everything is there, and everything is
tiny. A page written for phones says so with one line in its head, which the shop's `index.html`
has carried since lesson 1:

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

`width=device-width` asks for a viewport as wide as the phone, 390 rather than 980, and
`initial-scale=1` asks not to be shrunk. **Without that line, no stylesheet rule written for a
narrow window ever applies on a phone**, because the window the phone reports is not narrow.

## What a device descriptor sets

Playwright carries a list of phones, tablets and desktops called `devices`, each a set of options
for a new browser context. Print one from the copy installed in your project rather than trusting
a table in a blog post, because the list changes between versions:

```
%%CAP descriptor%%
```

Six options, and each one changes something different:

- **`viewport`** is the window, 390 by 664: the 844 of the `screen`, less the browser's own bars;
- **`userAgent`** is the name the browser gives every server it asks, and it is only a string.
  This one says iOS 15 and Safari 26 at once, and no server can tell;
- **`deviceScaleFactor`** is the device pixel ratio;
- **`isMobile`** makes the browser honour the viewport tag, and its absence, the way a phone does;
  a desktop browser ignores the tag entirely;
- **`hasTouch`** turns on touch events and makes the CSS question `(pointer: coarse)`, *is the
  pointer a finger?*, answer yes;
- **`defaultBrowserType`** says which engine the real device runs: Safari on an iPhone is WebKit.

## Measuring what the page sees

This script opens one page in three Chromium contexts: a desktop window 1280 wide, a desktop
window 390 wide, and the iPhone 13 descriptor without its `defaultBrowserType`, for a reason the
adaptive section gives. In each it asks the page what it measures. Save it as `viewport.mjs`:

```javascript
// What a page measures in three browsers that differ only in what they
// say about themselves. Run it with the shop started:
//   node viewport.mjs [path]
import { chromium, devices } from '@playwright/test';

const path = process.argv[2] ?? '/';
// The iPhone 13 descriptor asks for WebKit. This keeps everything else
// it sets and runs it in Chromium.
const { defaultBrowserType, ...iPhone13 } = devices['iPhone 13'];
const browsers = {
  'desktop, 1280 wide': { viewport: { width: 1280, height: 720 } },
  'desktop, 390 wide': { viewport: { width: 390, height: 664 } },
  'iPhone 13': iPhone13,
};

const browser = await chromium.launch();
for (const [name, options] of Object.entries(browsers)) {
  const context = await browser.newContext(options);
  const page = await context.newPage();
  await page.goto('http://localhost:3000' + path);
  const seen = await page.evaluate(() => ({
    screen: screen.width,
    innerWidth,
    scrollWidth: document.documentElement.scrollWidth,
    devicePixelRatio,
    touch: matchMedia('(pointer: coarse)').matches,
    says: document.querySelector('h1 + p')?.textContent,
  }));
  console.log(name.padEnd(19), JSON.stringify(seen));
  await context.close();
}
await browser.close();
```

With the shop started in another terminal:

```
%%CAP viewport-root%%
```

The narrow desktop window and the phone have the same screen, 390, and differ in everything else:
three times the pixels, a finger for a pointer, and a window of **400**, wider than the screen it
is on. The page is 400 wide, and a phone that is honouring the viewport tag widens its window to
fit what is there rather than cut it off. The desktop window does not, which is the first sign
that the two are different tests. The overflow section is about where those 400 pixels come from.

The same script on the deals page, which the adaptive section adds to the shop:

```
%%CAP viewport-deals%%
```

**The phone lays this page out 980 pixels wide.** Its HTML has no viewport tag, so the phone falls
back to a desktop-sized window and shrinks it, while the desktop window 390 wide lays it out at
390. A test that only narrowed a desktop window would never see this, and on a phone every word of
the page is drawn at about two fifths of its intended size, 390 over 980.
