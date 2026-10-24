---
title: Sizes and formats
version: 1
---

**A picture has two sizes that matter, and neither is the one it was exported at.** One is how many
CSS pixels wide the page draws it: on a phone, the width of the screen less the margins, about 360;
on a laptop, the 640 of the planner's column. The other is how many device pixels that is: a phone
has two or three for every CSS pixel, so a sharp picture there is three times as wide again. 2400
pixels is more than any of them needs, and the right size depends on the screen.

**And a photograph has a right format, which PNG is not.** Three formats compress photographs by
throwing away what the eye does not see, each at a quality you choose:

| format | what it is | where it works |
|---|---|---|
| **JPEG** | the format of every camera since the 1990s | everywhere |
| **WebP** | Google's, smaller than JPEG at the same look | every current browser |
| **AVIF** | from the AV1 video codec, smaller again | every current browser; slower to encode |

## Making the copies

`tools/images.ts` reads every cover and writes nine copies of it: 400, 800 and 1600 pixels wide, each
in AVIF, WebP and JPEG. The qualities are the ones each encoder is usually run at for photographs; a
quality is a number per encoder, so 50 in AVIF and 75 in JPEG look about the same. Save it in `tools/`:

```typescript
// tools/images.ts: make, from each cover a designer handed over, the copies a
// browser can choose from: three widths, in three formats.
//
//   node tools/images.ts
import sharp from "sharp";
import { readdir } from "node:fs/promises";

const widths = [400, 800, 1600];
// Each format at the quality its own encoder is usually run at for photographs.
const formats = {
  avif: (s: sharp.Sharp) => s.avif({ quality: 50 }),
  webp: (s: sharp.Sharp) => s.webp({ quality: 75 }),
  jpg: (s: sharp.Sharp) => s.jpeg({ quality: 75, mozjpeg: true }),
};
for (const file of (await readdir("public/covers")).filter((f) => /^[a-z-]+\.png$/.test(f))) {
  const name = file.replace(".png", "");
  const sizes: string[] = [];
  for (const w of widths) {
    for (const [ext, encode] of Object.entries(formats)) {
      const info = await encode(sharp(`public/covers/${file}`).resize(w)).toFile(`public/covers/${name}-${w}.${ext}`);
      sizes.push(`${w}.${ext} ${Math.round(info.size / 1024)} KB`);
    }
  }
  console.log(`${name}: ${sizes.join(", ")}`);
}
```

```
ana@dev:~/planner$ node tools/images.ts
git: 400.avif 6 KB, 400.webp 9 KB, 400.jpg 7 KB, 800.avif 37 KB, 800.webp 51 KB, 800.jpg 44 KB, 1600.avif 111 KB, 1600.webp 160 KB, 1600.jpg 171 KB
html-css: 400.avif 5 KB, 400.webp 6 KB, 400.jpg 6 KB, 800.avif 34 KB, 800.webp 44 KB, 800.jpg 39 KB, 1600.avif 112 KB, 1600.webp 144 KB, 1600.jpg 158 KB
javascript: 400.avif 5 KB, 400.webp 6 KB, 400.jpg 6 KB, 800.avif 32 KB, 800.webp 40 KB, 800.jpg 37 KB, 1600.avif 108 KB, 1600.webp 133 KB, 1600.jpg 153 KB
```

**The copy a phone needs is a few dozen kilobytes.** Two things did the work, and the first did most
of it: fewer pixels, because a picture 800 pixels wide has a ninth of the pixels of one 2400 wide, and
a format made for photographs. Between the three formats the difference is smaller, AVIF ahead, WebP
and JPEG close, and at 400 pixels it hardly matters.

## How many widths

Three is a choice, not a rule. Each extra width is a file to make and store, and buys a closer fit for
some screen. Widths that differ by about a factor of two, as these do, waste at most half the bytes of
the file chosen, and usually much less. What to avoid is the one size of the start of this lesson: a
single file big enough for the largest screen, sent to every screen.

The copies go into `public/covers/` beside the originals, so the next build copies them into `dist/`.
In a real project the originals would stay out of `public/` altogether, where nothing can serve them by
mistake.
