---
title: A cover picture, as it was handed over
version: 1
---

**Every course in the planner gets a cover picture**, at the top of its page. Pictures arrive in
projects the way this one will: as the file the designer exported, at the size of their screen, in
the format their tool saves by default.

The tool this lesson uses for pictures is **sharp**, a Node library around libvips, an image library
written in C. It reads and writes PNG, JPEG, WebP and AVIF, resizes, and is fast. Install it into the
planner as a development tool:

```
ana@dev:~/planner$ npm install --save-exact --save-dev sharp@0.35.5

added 7 packages, and audited 143 packages in 2s

31 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

sharp comes with libvips already compiled for Linux, macOS and Windows, so the install downloads it
and builds nothing; if it complains, its error names the platform it could not find a build for.

## Drawing the covers

The planner has no designer, so `tools/covers.ts` draws the covers itself: a sky, a sun and three
hills in a colour of each course's own, with a photograph's grain over them, saved as a PNG of 2400 by
1200 pixels. The grain matters: a flat drawing compresses to almost nothing, and a photograph does not.
Save it in `tools/`:

```typescript
// tools/covers.ts: draw a cover picture for each course, the way a designer
// would hand one over: one large PNG, 2400 by 1200, with a photograph's grain.
//
//   node tools/covers.ts
import sharp from "sharp";
import { mkdir, readFile } from "node:fs/promises";

const plan = JSON.parse(await readFile("public/courses.json", "utf8"));
const [w, h] = [2400, 1200];
await mkdir("public/covers", { recursive: true });
for (const [i, course] of plan.courses.entries()) {
  // A sky, a sun and three hills, in a colour of each course's own.
  const hue = (i * 137) % 360;
  const hill = (y: number, light: number) =>
    `<path d="M0 ${y} C ${w * 0.3} ${y - 220}, ${w * 0.6} ${y + 160}, ${w} ${y - 80} V ${h} H 0 Z" fill="hsl(${hue} 45% ${light}%)"/>`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">
    <defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="hsl(${hue} 70% 82%)"/><stop offset="1" stop-color="hsl(${(hue + 40) % 360} 60% 60%)"/>
    </linearGradient></defs>
    <rect width="${w}" height="${h}" fill="url(#sky)"/>
    <circle cx="${w * 0.72}" cy="${h * 0.3}" r="150" fill="hsl(45 95% 70%)"/>
    ${hill(h * 0.62, 55)}${hill(h * 0.75, 42)}${hill(h * 0.88, 30)}
  </svg>`;
  // The grain: a photograph's texture, coarse enough to survive being made smaller.
  const grain = await sharp({ create: { width: w / 4, height: h / 4, channels: 3, noise: { type: "gaussian", mean: 128, sigma: 24 } } })
    .resize(w, h).png().toBuffer();
  const file = `public/covers/${course.slug}.png`;
  const info = await sharp(Buffer.from(svg)).composite([{ input: grain, blend: "overlay" }]).png().toFile(file);
  console.log(`${file} ${info.width}x${info.height} ${info.size} B`);
}
```

```
ana@dev:~/planner$ node tools/covers.ts
public/covers/html-css.png 2400x1200 7838807 B
public/covers/javascript.png 2400x1200 7909342 B
public/covers/git.png 2400x1200 7886740 B
```

**Eight megabytes each.** PNG keeps every pixel exactly, which is right for a screenshot or a logo and
wrong for a photograph, whose grain is exactly the detail nobody would miss.

## On the page

In `src/view.ts`, the course page shows the cover under its heading. Replace the line that draws the
heading in `coursePage` with these two:

```typescript
<h1>${esc(course.title)}</h1>
<img class="cover" src="/covers/${esc(course.slug)}.png" alt="">
```

The `alt` is empty on purpose: the picture is decoration, and a screen reader should skip it rather
than announce a sky. And one rule at the end of `src/style.css`, so the picture is as wide as the text
and no wider:

```css
.cover { width: 100%; height: auto; border-radius: 0.5rem; }
```

Vite copies everything in `public/` into `dist/`, so a build puts the covers where `server.ts` serves
them. Build, restart `server.ts`, and ask Lighthouse, with the default method:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json
performance 74, throttling simulate
  FCP  0.9 s    weight 10
  LCP  39.8 s   weight 25
  TBT  0 ms     weight 30
  CLS  0.061    weight 25
  SI   0.9 s    weight 10
  insight: Use efficient cache lifetimes, Est savings of 7,712 KiB
  insight: Improve image delivery, Est savings of 7,690 KiB
  insight: LCP request discovery
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
  request /courses/git                 done at    20 ms, 997 B
  request /assets/index-DuClgeFY.js    done at    38 ms, 6931 B
  request /assets/index-DmgXiBYI.css   done at    40 ms, 495 B
  request /covers/git.png              done at   258 ms, 7889204 B
  request /favicon.svg                 done at   281 ms, 1709 B
```

**An LCP of almost forty seconds**, on the simulated phone and its 1.6 megabits a second. The LCP is
now the picture, and the picture is eight megabytes. Three insights name it:

- **Improve image delivery** estimates the saving at nearly the whole file: the wrong format, and far
  more pixels than the phone draws;
- **LCP request discovery** says the picture was found in the HTML, which is good, and was not marked
  as the most important request, which the section "The LCP image" fixes;
- the **CLS** is no longer zero. The picture arrived after the page was painted, and the form below it
  moved down when it did, because nothing said how tall the picture would be.

The next three sections take those in order.
