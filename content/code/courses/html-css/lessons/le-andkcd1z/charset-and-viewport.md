---
title: Two lines every head needs: charset and viewport
version: 2
---

Two `<meta>` elements appear in the head of practically every page on the web, and each fixes a problem that is invisible on the machine where the page was written.

## `charset`: which bytes are which letters

A file is bytes, and the letter *ã* in *São Paulo* is not one byte in every encoding. In **UTF-8**, which is what every modern editor saves, it is two bytes; in the older **ISO-8859-1**, it is one. The browser has to know which encoding the file uses before it can turn bytes into text, and `<meta charset="utf-8">` tells it.

Three versions of the same page show what happens. The first declares UTF-8 and is saved in UTF-8. The second declares UTF-8 and was saved in ISO-8859-1, which is what happens when a file passes through an old editor. The third declares nothing. Here is the first, `charset.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
  </head>
  <body>
    <p class="where">Pinheiros, São Paulo</p>
  </body>
</html>
```

For the second, save a copy as `latin1.html` in the Western encoding, ISO 8859-1. In VS Code, click *UTF-8* in the status bar at the bottom of the window, choose **Save with Encoding** and then *Western (ISO 8859-1)*. For the third, save another copy as `no-charset.html` and delete the line with `<meta charset>`.

```
ana@laptop:~/site$ probe charset.html text .where
p.where  "Pinheiros, São Paulo"
ana@laptop:~/site$ probe latin1.html text .where
p.where  "Pinheiros, S�o Paulo"
ana@laptop:~/site$ probe no-charset.html text .where
p.where  "Pinheiros, São Paulo"
```

The first is right. In the second, **the declaration lied**: the browser trusted it, met a byte that is not valid UTF-8 where the *ã* should be, and drew the replacement character, �, in its place. The third is right, and that deserves care: with no declaration, Chromium guessed the encoding from the bytes, and on this file the guess was correct. A guess is not a decision. Another browser, another file with fewer accented letters, or a server that sends its own encoding header can guess differently, and the page you checked on your machine is not the page your reader gets.

So the rule is to save every file as UTF-8 and say so, in the first 1024 bytes of the file, which in practice means **the first line inside `<head>`**. Put it before the title, because the title is text and the browser needs the encoding to read it.

## `viewport`: how wide the page is on a phone

When smartphones arrived, nearly every site was designed for a desktop screen around a thousand pixels wide. Drawn at its real size on a phone, such a page would show its top-left corner and nothing else. So mobile browsers pretend: **without instructions, they lay the page out as if the screen were 980 pixels wide, then shrink the result to fit.**

`probe --mobile` makes Chromium behave like a phone's browser, here one 390 pixels wide, which is an ordinary phone. The page is `skeleton.html` from section 07, saved as `viewport.html`, and `no-viewport.html` is a copy of it with the `<meta name="viewport">` line deleted. Without and with the viewport tag:

```
ana@laptop:~/site$ probe --mobile --width 390 --height 844 --dpr 3 no-viewport.html window box h1
window: 980×2121, device pixel ratio 3
h1  x 8      y 21.44  width 964    height 37
ana@laptop:~/site$ probe --mobile --width 390 --height 844 --dpr 3 viewport.html window box h1
window: 390×844, device pixel ratio 3
h1  x 8      y 21.44  width 374    height 37
```

Without the tag the window is 980 wide, and a 980-pixel layout is drawn on a 390-pixel screen at 390/980, which is 40 per cent of its size. The heading is 32 pixels in CSS and comes out about 13 on the glass, smaller than body text should be. With the tag the window is 390 wide, the page is laid out for that width, and the heading is drawn at its full 32.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 392\" role=\"img\" aria-label=\"Two phones, each 390 CSS pixels wide. On the left, a page without the viewport meta tag: the browser lays it out 980 pixels wide and shrinks it to fit, so the heading, 964 pixels wide, is drawn at 40 per cent of its size. On the right, the same page with the tag: it is laid out 390 wide and the heading, 374 wide, is drawn at full size.\"><text x=\"125\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">without the viewport tag</text><text x=\"125\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">window: 980×2121</text><rect x=\"30\" y=\"50\" width=\"190\" height=\"330\" rx=\"18\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"2\"></rect><rect x=\"40\" y=\"70\" width=\"170\" height=\"290\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"41.39\" y=\"73.72\" width=\"167.22\" height=\"6.42\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"125\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the h1, 964 wide,</text><text x=\"125\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shrunk to 40%</text><text x=\"425\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">with the viewport tag</text><text x=\"425\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">window: 390×844</text><rect x=\"330\" y=\"50\" width=\"190\" height=\"330\" rx=\"18\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"2\"></rect><rect x=\"340\" y=\"70\" width=\"170\" height=\"290\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"343.49\" y=\"79.35\" width=\"163.03\" height=\"16.13\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"425\" y=\"87.41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">h1</text><text x=\"425\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the h1, 374 wide,</text><text x=\"425\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">drawn at full size</text><text x=\"560\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Both phones are 390</text><text x=\"560\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">CSS pixels wide. Only</text><text x=\"560\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the page the browser</text><text x=\"560\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">lays out differs.</text></svg>", "caption": "The same 32px heading, read on the same phone: one page was laid out for a desktop and shrunk."}
```

The tag that does it is always the same:

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

`width=device-width` makes the layout width the phone's width, and `initial-scale=1` starts with no zoom. **Never add `maximum-scale=1` or `user-scalable=no`** to stop people zooming: somebody who cannot read small text zooms to read it, and that tag takes it away from them. Lesson 11 is where the rest of responsiveness lives; this one line is what makes any of it possible, because a page that is shrunk to fit cannot respond to anything.
