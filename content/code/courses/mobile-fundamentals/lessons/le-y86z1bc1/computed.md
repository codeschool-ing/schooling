---
title: The planner's button, worked out for every screen
version: 1
---

**The planner's screen for a course has an "add session" button: a touch target of 48 dp with a
24 dp icon in it.** Android's accessibility guidance recommends that every touch target be at
least 48 dp by 48 dp, and the icon is half of that. This program takes those two sizes and works
out what they become in pixels on every Android bucket, on a screen between two buckets, and on
an iPhone at each scale factor, and then lists the image files one raster icon would need. Save
it as `density.ts` in `~/planner`:

```typescript
// density.ts: one size in density-independent units, as the pixels each screen needs
const target = 48; // a touch target, in dp on Android and pt on iOS
const icon = 24; // an icon inside it

// Android: px = dp * dpi / 160, for each density bucket
const buckets = [
  { name: "mdpi", dpi: 160 },
  { name: "hdpi", dpi: 240 },
  { name: "xhdpi", dpi: 320 },
  { name: "xxhdpi", dpi: 480 },
  { name: "xxxhdpi", dpi: 640 },
];
const px = (dp: number, dpi: number) => (dp * dpi) / 160;
const row = (...cells: (string | number)[]) =>
  console.log(cells.map((c, i) => (i === 0 ? String(c).padEnd(8) : String(c).padStart(7))).join(""));

row("bucket", "dpi", "scale", "48 dp", "24 dp");
for (const b of buckets) {
  row(b.name, b.dpi, `${b.dpi / 160}x`, `${px(target, b.dpi)} px`, `${px(icon, b.dpi)} px`);
}

// A screen between two buckets: the sum still works, and no file is that size
console.log(`\n420 dpi: 48 dp = ${px(target, 420)} px, 24 dp = ${px(icon, 420)} px\n`);

// iOS: px = pt * scale
row("scale", "48 pt", "24 pt");
for (const s of [1, 2, 3]) row(`@${s}x`, `${target * s} px`, `${icon * s} px`);

// The raster files one 24-unit icon needs, when it is not a vector
console.log("\nfiles for one raster icon:");
for (const b of buckets) {
  console.log(`  ${`drawable-${b.name}/ic_session.png`.padEnd(32)} ${px(icon, b.dpi)}x${px(icon, b.dpi)}`);
}
for (const s of [2, 3]) {
  console.log(`  ${`ic_session@${s}x.png`.padEnd(32)} ${icon * s}x${icon * s}`);
}
```

It needs nothing from the planner's other files. Run it:

```
ana@dev:~/planner$ node density.ts
bucket      dpi  scale  48 dp  24 dp
mdpi        160     1x  48 px  24 px
hdpi        240   1.5x  72 px  36 px
xhdpi       320     2x  96 px  48 px
xxhdpi      480     3x 144 px  72 px
xxxhdpi     640     4x 192 px  96 px

420 dpi: 48 dp = 126 px, 24 dp = 63 px

scale     48 pt  24 pt
@1x       48 px  24 px
@2x       96 px  48 px
@3x      144 px  72 px

files for one raster icon:
  drawable-mdpi/ic_session.png     24x24
  drawable-hdpi/ic_session.png     36x36
  drawable-xhdpi/ic_session.png    48x48
  drawable-xxhdpi/ic_session.png   72x72
  drawable-xxxhdpi/ic_session.png  96x96
  ic_session@2x.png                48x48
  ic_session@3x.png                72x72
```

## Reading the table

**The first table is the formula of the previous sections, five times.** 48 dp is 48 pixels at
mdpi, the baseline, and 144 at xxhdpi, three times as many in each direction, so nine times as
many pixels in the square. The icon follows the same column at half the size. Nothing in the
table is measured; it is arithmetic, and that is the reason to trust it.

**The 420 dpi line is the case the buckets hide.** 48 dp on that screen is 126 pixels, a size no
bucket's file has. The sum works for any density, because the system multiplies by the screen's
own density. Only a file has to come in fixed sizes, and when there is no file for 420 dpi the
system takes the closest bucket's and scales it, a little down from xxhdpi's 144 or a lot up from
xhdpi's 96.

**The iOS table is shorter because the steps are.** @2x and @3x are the scale factors iPhones use,
so the same button is 96 or 144 pixels, the same counts as Android's xhdpi and xxhdpi. The @1x row
is there to show the baseline the guidelines define, one pixel for one point.

## Why not just give every screen the biggest file?

The last block of the output answers it. **One raster icon is seven files**: five for Android's
buckets and two for iOS's scale factors, with 24x24 pixels at the bottom and 96x96 at the top. A
single 96x96 file shrunk on every screen would look acceptable, and it would also make a phone at
mdpi decode sixteen times the pixels it shows, for every icon, every time. Supplying each size,
or drawing the icon once as a vector, are the two honest answers, and the next section weighs
them.
