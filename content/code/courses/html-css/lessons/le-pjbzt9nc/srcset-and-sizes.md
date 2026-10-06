---
title: Offering the browser several files
version: 1
---

A photograph across the full width of a large monitor needs a big file. The same photograph on a phone needs a fraction of it, and sending the big one anyway costs the reader time and mobile data. **`srcset` lists several files of the same picture at different widths, and `sizes` tells the browser how wide it will be drawn**, so that the browser can choose.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>The shop · Andorinha Books</title>
    <style>
      body { margin: 0; }
      img { width: 100%; height: auto; }
      @media (min-width: 800px) { img { width: 50%; } }
    </style>
  </head>
  <body>
    <img src="shelves-960.png"
         srcset="shelves-480.png 480w, shelves-960.png 960w, shelves-1600.png 1600w"
         sizes="(min-width: 800px) 50vw, 100vw"
         width="960" height="640"
         alt="The shelves of the shop, floor to ceiling">
  </body>
</html>
```

The three files are the same picture at 480, 960 and 1600 pixels wide, and `srcset` says so with a `w` after each width. `sizes` says how wide the image will be drawn: `(min-width: 800px) 50vw` means half the window on a window at least 800 pixels wide, and `100vw` means the whole width otherwise. It repeats what the CSS in the `<style>` says, because the browser chooses the file before it has worked out the layout. `src` stays as the file for any browser that does not read `srcset`.

## What the browser chose

On a phone-sized window 360 pixels wide, at three pixel densities:

```
ana@laptop:~/site$ probe --width 360 --dpr 1 srcset.html img img
img  chose shelves-480.png (480×320 pixels), drawn 360 wide
ana@laptop:~/site$ probe --width 360 --dpr 2 srcset.html img img
img  chose shelves-960.png (960×640 pixels), drawn 360 wide
ana@laptop:~/site$ probe --width 360 --dpr 3 srcset.html img img
img  chose shelves-1600.png (1600×1067 pixels), drawn 360 wide
```

And on a window 1280 wide, where the picture is drawn at half that:

```
ana@laptop:~/site$ probe --width 1280 --dpr 1 srcset.html img img
img  chose shelves-960.png (960×640 pixels), drawn 640 wide
ana@laptop:~/site$ probe --width 1280 --dpr 2 srcset.html img img
img  chose shelves-1600.png (1600×1067 pixels), drawn 640 wide
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A ruler of pixels from 0 to 1600 with the three files on offer drawn as bars 480, 960 and 1600 wide. Below, five needs measured by probe, each the width drawn times the device pixel ratio: 360, 720, 1080, 640 and 1280. For each, the browser chose the smallest file at least that wide: 480, 960, 1600, 960 and 1600.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the files on offer</text><rect x=\"150\" y=\"32\" width=\"144\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">480w</text><rect x=\"150\" y=\"54\" width=\"288\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">960w</text><rect x=\"150\" y=\"76\" width=\"480\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"636\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1600w</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">needed</text><text x=\"20\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">width × density</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">360 × 1</text><line x1=\"150\" y1=\"152\" x2=\"258\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"255\" y=\"149\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"268\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chose 480w</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">360 × 2</text><line x1=\"150\" y1=\"172\" x2=\"366\" y2=\"172\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"363\" y=\"169\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"376\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chose 960w</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">360 × 3</text><line x1=\"150\" y1=\"192\" x2=\"474\" y2=\"192\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"471\" y=\"189\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"484\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chose 1600w</text><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">640 × 1</text><line x1=\"150\" y1=\"212\" x2=\"342\" y2=\"212\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"339\" y=\"209\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"352\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chose 960w</text><text x=\"20\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">640 × 2</text><line x1=\"150\" y1=\"232\" x2=\"534\" y2=\"232\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"531\" y=\"229\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"544\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">chose 1600w</text><line x1=\"150\" y1=\"262\" x2=\"645\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"150\" y1=\"258\" x2=\"150\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"150\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"270\" y1=\"258\" x2=\"270\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"270\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><line x1=\"390\" y1=\"258\" x2=\"390\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"390\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">800</text><line x1=\"510\" y1=\"258\" x2=\"510\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"510\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1200</text><line x1=\"630\" y1=\"258\" x2=\"630\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"630\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1600</text></svg>", "caption": "Each need is met by the narrowest file that reaches past it."}
```

The **device pixel ratio**, `--dpr` in these commands, is how many physical pixels a screen has per CSS pixel: 1 on an ordinary monitor, 2 or 3 on most phones. A picture drawn 360 CSS pixels wide on a screen with a ratio of 3 is 1080 physical pixels wide, and a 480-pixel file would look soft. So the browser multiplies, and in all five runs Chromium took **the narrowest file at least as wide as that product**: 480 for 360, 960 for 720 and for 640, 1600 for 1080 and for 1280.

That is what Chromium did here, not a rule the page can rely on. **The standard lets the browser choose any candidate**, and a browser may take a smaller file on a slow connection or keep a larger one it already has in its cache. Your job is to offer sensible files and tell the truth in `sizes`; the choice is the browser's.

## When `sizes` is wrong

`sizes` is a promise about the layout, and nothing checks it. Leave it out and the browser assumes `100vw`, the full window width, so on the 1280 window above it would have picked a file for 1280 or 2560 pixels to draw a picture 640 wide. Getting `sizes` right after a layout change is the step people forget, and DevTools shows the cost: the Network panel lists the file that was actually fetched, which is the test.
