---
title: What a phone actually downloads
version: 1
---

**An app bundle is not what a phone downloads; it is what Google Play cuts into the pieces each phone
needs.** Lesson 1 met this from the signing side: bundletool made the APKs and signed them. Here the
same tool answers the size question. An app that ships a picture in five densities stores five
copies in the bundle, and a phone downloads one.

## A cover picture in five densities

The planner shows a cover picture for the week. A real one is a photograph, and a photograph hardly
compresses. To have one here at exact sizes, this program writes a PNG of seeded noise, which
compresses as badly as a photograph does. Save it as `photo.ts` in `~/planner`:

```typescript
// photo.ts: write a PNG of seeded noise, WIDTH x HEIGHT, which compresses like a photograph: hardly at all
import { deflateSync } from "node:zlib";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const [file, width, height] = [process.argv[2], Number(process.argv[3]), Number(process.argv[4])];
let seed = width * 7919 + height;
function next(): number {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) & 0xff;
}

const table = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc(bytes: Buffer): number {
  let c = 0xffffffff;
  for (const b of bytes) c = table[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type: string, data: Buffer): Buffer {
  const head = Buffer.alloc(8);
  head.writeUInt32BE(data.length, 0);
  head.write(type, 4, "ascii");
  const tail = Buffer.alloc(4);
  tail.writeUInt32BE(crc(Buffer.concat([head.subarray(4), data])), 0);
  return Buffer.concat([head, data, tail]);
}

const header = Buffer.alloc(13);
header.writeUInt32BE(width, 0);
header.writeUInt32BE(height, 4);
header[8] = 8; // bits per channel
header[9] = 2; // colour type: RGB
const rows: Buffer[] = [];
for (let y = 0; y < height; y++) {
  const row = Buffer.alloc(1 + width * 3);
  for (let i = 1; i < row.length; i++) row[i] = next();
  rows.push(row);
}
mkdirSync(dirname(file), { recursive: true });
writeFileSync(file, Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk("IHDR", header), chunk("IDAT", deflateSync(Buffer.concat(rows))), chunk("IEND", Buffer.alloc(0)),
]));
```

## The bundle, cut and measured

The steps are lesson 1's, with one more input: a `res` folder holding the picture once per density,
compiled by `aapt2` and linked into the module. `get-size total` then reports the download size per
screen density, and the `--mode=universal` build is the single APK a phone would get if the app were
shipped as one file for everybody:

```
ana@dev:~/size$ for d in mdpi:240 hdpi:360 xhdpi:480 xxhdpi:720 xxxhdpi:960; do node ~/planner/photo.ts res/drawable-${d%%:*}/cover.png ${d##*:} ${d##*:}; done; ls -l res/*/cover.png
-rw-r--r-- 1 ana ana  389343 Oct 30 16:24 res/drawable-hdpi/cover.png
-rw-r--r-- 1 ana ana  173158 Oct 30 16:24 res/drawable-mdpi/cover.png
-rw-r--r-- 1 ana ana  691958 Oct 30 16:24 res/drawable-xhdpi/cover.png
-rw-r--r-- 1 ana ana 1556458 Oct 30 16:24 res/drawable-xxhdpi/cover.png
-rw-r--r-- 1 ana ana 2766668 Oct 30 16:24 res/drawable-xxxhdpi/cover.png
ana@dev:~/size$ aapt2 compile --dir res -o res.zip --no-crunch && aapt2 link --proto-format -o base.apk --manifest AndroidManifest.xml -I $ANDROID_HOME/platforms/android-36/android.jar --min-sdk-version 24 --target-sdk-version 36 res.zip
ana@dev:~/size$ java -jar ~/android/bundletool.jar build-bundle --modules=base.zip --output=planner.aab && ls -l planner.aab
-rw------- 1 ana ana 5581234 Oct 30 16:24 planner.aab
ana@dev:~/size$ java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=planner.apks --ks=$HOME/signing/play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS
ana@dev:~/size$ java -jar ~/android/bundletool.jar get-size total --apks=planner.apks --dimensions=SCREEN_DENSITY
SCREEN_DENSITY,MIN,MAX
XXXHDPI,2774535,2774535
LDPI,180233,180233
TVDPI,569794,569794
XXHDPI,1564019,1564023
MDPI,180231,180232
HDPI,396486,396492
XHDPI,699188,699191
ana@dev:~/size$ java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=universal.apks --mode=universal --ks=$HOME/signing/play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS
ana@dev:~/size$ java -jar ~/android/bundletool.jar get-size total --apks=universal.apks
MIN,MAX
5583525,5583525
```

## Reading it

**The bundle is 5.6 MB, and no phone downloads that.** A phone with an `xxhdpi` screen, the density of
many current phones, downloads 1.6 MB; an `mdpi` one, 0.2 MB. The
universal APK is 5.6 MB for every phone, because it carries all five pictures and each phone uses
one. **Shipping the bundle cut the typical download to less than a third**, with no change to the
app.

Two details in the table are worth a second look. `LDPI` and `TVDPI` are densities the bundle had no
picture for, and bundletool built their splits out of the pictures it did have. And the minimum and maximum differ by a
few bytes for some densities, because the two variants of lesson 1, for older and newer Android
versions, are signed differently.

## On iOS and in React Native

Apple does the same cutting, called **app thinning**: the App Store delivers each device the assets
of its own scale, `@2x` or `@3x`, from an asset catalogue. A React Native app's images benefit only
when they reach the native asset systems, which Expo and React Native do for images referenced with
`require`, and do not do for images downloaded at run time. *Neither was measured for this course.*
