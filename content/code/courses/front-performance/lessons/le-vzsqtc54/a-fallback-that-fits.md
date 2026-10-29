---
title: A fallback that takes the same room
version: 1
---

**A swap moves text because the fallback and the font are different sizes.** The same sentence in two
typefaces is two widths, and where a line breaks depends on the width. If the fallback were the same
width as the font, the swap would change the letters and move nothing.

`tools/fallback.ts` measures that. It opens a page, sets the notice's sentence in IBM Plex Sans and in a
font this computer has, and says how much the second would have to be scaled to match the first. Save
it in `tools/`:

```typescript
// tools/fallback.ts: how wide the notice's sentence is in IBM Plex Sans, in a font
// this computer has, and in the page's adjusted fallback if it defines one: the
// number that makes a fallback take the room the web font will take.
//
//   node tools/fallback.ts URL "FONT"
import { chromium } from "playwright";

const [url, local] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url, { waitUntil: "networkidle" });
const widths = await page.evaluate(async (local) => {
  const text = document.getElementById("notice")!.textContent!;
  const measure = (family: string) => {
    const span = Object.assign(document.createElement("span"), { textContent: text });
    span.style.cssText = `font: 16px ${family}; white-space: nowrap`;
    document.body.append(span);
    const width = span.getBoundingClientRect().width;
    span.remove();
    return width;
  };
  await document.fonts.load('16px "Plex fallback"');
  const adjusted = [...document.fonts].some((f) => f.family === '"Plex fallback"' || f.family === "Plex fallback");
  return { plex: measure('"IBM Plex Sans"'), local: measure(`"${local}"`), adjusted: adjusted ? measure('"Plex fallback"') : null };
}, local);
await browser.close();
console.log(`IBM Plex Sans    ${widths.plex.toFixed(1)} px`);
console.log(`${local.padEnd(16)} ${widths.local.toFixed(1)} px: size-adjust ${(100 * widths.plex / widths.local).toFixed(1)}% would match`);
if (widths.adjusted !== null) console.log(`Plex fallback    ${widths.adjusted.toFixed(1)} px`);
```

Measure the two fonts the planner's visitors are likely to fall back to. DejaVu Sans is what many Linux
systems give `sans-serif`; Arial is on every Windows and macOS computer, and on Linux the name Arial
usually leads to Liberation Sans, which was drawn to have Arial's widths:

```
ana@dev:~/planner$ node tools/fallback.ts http://localhost:3000/ "DejaVu Sans"
IBM Plex Sans    467.8 px
DejaVu Sans      529.8 px: size-adjust 88.3% would match
ana@dev:~/planner$ node tools/fallback.ts http://localhost:3000/ "Arial"
IBM Plex Sans    467.8 px
Arial            470.5 px: size-adjust 99.4% would match
```

**DejaVu Sans is about an eighth wider than Plex**, enough to move a line break in most paragraphs.
**Arial is within one per cent.** So the first fix is to name it: a fallback stack that says Arial gets
a near match on most computers, where `sans-serif` alone gets whatever the system likes.

## size-adjust

The last per cent is a descriptor. **An `@font-face` rule can give a local font a new name and a
correction**: `size-adjust` scales every glyph, and `ascent-override`, `descent-override` and
`line-gap-override` correct the line height, which matters when the two fonts sit differently on their
lines. Add this rule at the end of `src/style.css`, with the number the tool printed:

```css
@font-face { font-family: "Plex fallback"; src: local("Arial"), local("Liberation Sans"); size-adjust: 99.4%; }
```

and put it in the body's list, between the font and the generic family, replacing the first line:

```css
body { font: 16px/1.5 "IBM Plex Sans", "Plex fallback", sans-serif; margin: 0 auto; max-width: 40rem; padding: 1rem; }
```

`system-ui` has gone from the list: it is the operating system's own interface font, a different shape
on every system, which is the opposite of a fallback chosen to match. Build, restart, and measure again:

```
ana@dev:~/planner$ node tools/fallback.ts http://localhost:3000/ "Arial"
IBM Plex Sans    467.8 px
Arial            470.5 px: size-adjust 99.4% would match
Plex fallback    467.3 px
```

**The adjusted fallback is the font's width to a fraction of a pixel.** A visitor whose font is late
sees Arial, scaled, in exactly the room Plex will take, and the swap moves nothing.

## The number is per font

`size-adjust` is a ratio between two particular fonts, so it is right for the fallback it was measured
on and wrong for any other. That is why the rule names `local("Arial")` and not `sans-serif`, and why
the frameworks that do this for you, in the section "What the frameworks do", pick Arial or Times New
Roman too: they are the fonts nearly every visitor has. The ratio also depends on the text; a tool that
computes it from the font files, rather than from one sentence, averages over the alphabet instead.
