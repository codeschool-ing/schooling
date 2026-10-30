---
title: Android's dp, its five buckets, and sp for text
version: 1
---

**On Android, one dp is one pixel on a screen of 160 dots per inch, and every other density is a
multiple of that.** Android's documentation on screen densities gives the conversion as a single
line:

```
px = dp * (dpi / 160)
```

So on a 320 dpi screen one dp is two pixels, and on a 480 dpi screen it is three. The same page
adds a warning worth keeping: an app should not write that sum into its own code, because the
platform has a function that does it, `TypedValue.applyDimension()`, and Compose does it for you
whenever a size is written as `48.dp`.

## The buckets

**Screens are sorted into density buckets, and each bucket has a name that turns up in folder
names.** The documentation's table of density qualifiers lists these, each with an approximate
dpi:

| bucket | about | scale against mdpi | what the documentation says of it |
|---|---|---|---|
| `ldpi` | 120 dpi | 0.75x | low density |
| `mdpi` | 160 dpi | 1x | medium density, the baseline |
| `hdpi` | 240 dpi | 1.5x | high density |
| `xhdpi` | 320 dpi | 2x | extra-high density |
| `xxhdpi` | 480 dpi | 3x | extra-extra-high density |
| `xxxhdpi` | 640 dpi | 4x | extra-extra-extra-high density |

The documentation sums up the ladder as a ratio, 3:4:6:8:12:16 across the six, which is the same
column of scales multiplied by four. **A real screen is rarely exactly on a step.** A phone at 420
dpi exists in no bucket; the system uses its true density to turn dp into pixels, and picks the
nearest bucket only when it has to choose an image file, which the last section of this lesson
comes back to.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l07-buckets\" aria-label=\"Five squares side by side, drawn to scale in pixels: the files for one 24 dp icon. mdpi at 160 dpi is 24 by 24 pixels, scale 1x; hdpi at 240 dpi is 36 by 36, 1.5x; xhdpi at 320 dpi is 48 by 48, 2x; xxhdpi at 480 dpi is 72 by 72, 3x; xxxhdpi at 640 dpi is 96 by 96, 4x.\"><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one 24 dp icon as a raster file per bucket, drawn to scale</text><rect x=\"60\" y=\"126\" width=\"24\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"72.0\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">24 x 24</text><text x=\"72.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mdpi</text><text x=\"72.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">160 dpi</text><text x=\"72.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1x</text><rect x=\"180\" y=\"114\" width=\"36\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"198.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">36 x 36</text><text x=\"198.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hdpi</text><text x=\"198.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">240 dpi</text><text x=\"198.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.5x</text><rect x=\"300\" y=\"102\" width=\"48\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"324.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">48 x 48</text><text x=\"324.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">xhdpi</text><text x=\"324.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">320 dpi</text><text x=\"324.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2x</text><rect x=\"420\" y=\"78\" width=\"72\" height=\"72\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"456.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">72 x 72</text><text x=\"456.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">xxhdpi</text><text x=\"456.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">480 dpi</text><text x=\"456.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3x</text><rect x=\"542\" y=\"54\" width=\"96\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">96 x 96</text><text x=\"590.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">xxxhdpi</text><text x=\"590.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">640 dpi</text><text x=\"590.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4x</text></svg>", "caption": "Android's buckets as a ladder. Each step is a folder with its own copy of the image, and the largest copy has sixteen times the pixels of the smallest."}
```

## Text gets its own unit: sp

A layout size in dp stays the same when the user asks for larger text, and that is right for the
gap between two buttons. It is wrong for the text inside them. **For text, Android has the
scalable pixel, `sp`**: the same size as a dp by default, but it grows and shrinks with the
user's preferred text size. Android's documentation draws the line in two sentences: use sp for
text sizes, and never use sp for layout sizes.

| write this in | dp | sp |
|---|---|---|
| a button's height, a margin, an icon | yes | no: the layout would grow when only the words should |
| the size of a session's title | no: it would ignore the user's text setting | yes |

The consequence lands on the layout. A row 48 dp tall holding text in sp is fine at the default
text size and cuts the text off when the user doubles it, so a row that holds text should be
allowed to grow. **That is the first place this lesson touches lesson 19**, and the two
fragments of the next section show the same split on iOS and in React Native.

Neither unit is a promise about millimetres. "About the same physical size" is the design, and a
dp on two phones in the same bucket can still differ slightly, because the true density of each
screen is not exactly the bucket's number. What dp removes is the factor of three or four
between a low-density and a high-density screen, which is the difference a user's finger notices.
