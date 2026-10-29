---
title: Icons
version: 1
---

**An installed app is drawn by its icon**, in places the page never sees: the home screen, the list of
applications, the switcher between windows, the splash screen while it opens. The manifest names three, and
`tools/icons.ts` draws them with sharp from a little SVG: a page with three lines and a tick, on the planner's
blue. Save it in `tools/`:

```typescript
// tools/icons.ts: draw the planner's app icons: one at 192 and one at 512 pixels for
// ordinary use, and one maskable, whose drawing stays inside the circle every system's
// mask keeps.
//
//   node tools/icons.ts
import sharp from "sharp";
import { mkdir } from "node:fs/promises";

// A page with three lines and a tick, drawn on a square of 100 by 100, scaled by `size`
// around the centre: 1 fills the square, 0.6 keeps it inside the maskable safe zone.
const mark = (size: number) => `<g transform="translate(50 50) scale(${size}) translate(-50 -50)">
  <rect x="22" y="14" width="56" height="72" rx="6" fill="#ffffff"/>
  <rect x="32" y="30" width="36" height="5" rx="2.5" fill="#93c5fd"/>
  <rect x="32" y="42" width="36" height="5" rx="2.5" fill="#93c5fd"/>
  <rect x="32" y="54" width="22" height="5" rx="2.5" fill="#93c5fd"/>
  <path d="M40 69 l7 7 l14 -16" stroke="#1d4ed8" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
</g>`;
const icon = (rounded: boolean, size: number) => Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" rx="${rounded ? 18 : 0}" fill="#1d4ed8"/>${mark(size)}</svg>`);

await mkdir("public/icons", { recursive: true });
for (const [file, svg, px] of [
  ["icon-192.png", icon(true, 0.9), 192],
  ["icon-512.png", icon(true, 0.9), 512],
  // A mask may cut away everything outside a circle of 80% of the width, so the drawing
  // shrinks to fit inside it and the square is filled edge to edge.
  ["maskable-512.png", icon(false, 0.6), 512],
] as const) {
  const info = await sharp(svg, { density: 72 * px / 100 }).resize(px, px).png().toFile(`public/icons/${file}`);
  console.log(`public/icons/${file} ${info.width}x${info.height} ${info.size} B`);
}
```

```
ana@dev:~/planner$ node tools/icons.ts
public/icons/icon-192.png 192x192 3602 B
public/icons/icon-512.png 512x512 13522 B
public/icons/maskable-512.png 512x512 9843 B
```

## Two sizes and a mask

- **192 and 512 pixels** are the two sizes Chromium uses most: the first on the home screen, the second for the
  splash screen that shows while the app opens. A system that needs another size scales the nearest.
- **`"purpose": "maskable"`** marks an icon drawn for a system that cuts icons into its own shape, a circle, a
  rounded square, a drop. Such a system may keep only the circle in the middle, 80 per cent of the width, so a
  maskable icon fills the whole square with its background and keeps the drawing inside that circle. The
  ordinary icons have their own rounded corners; the maskable one has none, because the mask makes the corners.

An icon without `maskable` is shown as it is, inside a plate the system draws, which is why the two kinds are
separate files. Build, restart, and ask again:

```
ana@dev:~/planner$ node tools/installable.ts http://localhost:3000/
manifest: http://localhost:3000/manifest.webmanifest
not installable: no-acceptable-icon (minimum-icon-size-in-pixels=144)
```

**Installable.** In Chrome or Edge on your own computer, the address bar now shows an install icon for
`localhost:3000`, and the developer tools' **Application** panel shows the manifest as the browser read it,
with every icon and every problem it found.
