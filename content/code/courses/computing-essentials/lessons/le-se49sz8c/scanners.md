---
title: Scanners, and the resolution number that is not a measurement
version: 1
---

A scanner is a monitor run backwards. A bar carrying a lamp and a row of sensors travels the
length of the glass, reading one thin stripe of the page at a time, and the stripes are stacked
into an image. The lid is not a cover; it is a white backing that stops the room appearing in
your scan.

## Optical resolution is the real one

A scanner quotes two resolutions and only one of them is a fact.

- **Optical resolution** — `600 × 1200 dpi`, say — is how many sensors there physically are per
  inch across the bar, and how many stripes the bar stops at per inch as it travels. This is
  measured.
- **Interpolated** — `9600 dpi` on the same box — is software inventing pixels between the ones
  actually read. It makes a bigger file out of the same information.

**Interpolation is never more detail.** If a box gives one large number and one small one, the
small one is the scanner.

## What resolution you actually want

More is not better here either, because a scan at twice the resolution is four times the file and
four times the wait, for detail nobody will look at.

| what you are scanning | sensible resolution | why |
|---|---|---|
| a document to read or e-mail | 200–300 dpi | above 300 you are storing paper texture |
| a document for text recognition | 300 dpi | what almost every OCR engine is tuned for |
| a photograph to keep | 600 dpi | grain, and room to crop |
| a photograph to enlarge | 1200 dpi | the only honest reason to go high |
| a 35 mm slide or negative | 2400 dpi and up | the original is tiny, so every inch counts |

`300 dpi` covers most of a life. The habit of scanning everything at maximum produces a folder of
enormous files that are slower to open, slower to send, and no more readable.

## OCR, and what it is actually doing

**Optical character recognition** turns the picture of a page into text you can search and copy.
A scan without it is a photograph of words — you can read it and the computer cannot.

Two things decide whether it works: the resolution (300 dpi is the floor) and whether the page is
straight. It is much better than it used to be on printed text and still poor on handwriting, and
it silently invents plausible words when it fails, which is the failure mode to watch for. **An
OCR error does not look like an error.**

## Colour depth, and the three modes

- **Black and white**, one bit per pixel — for line art and forms. Tiny files, no grey.
- **Greyscale**, 8 bits — the right choice for almost every text document.
- **Colour**, 24 bits — for anything where the colour is information.

Scanning a typed page in colour triples the file to record the fact that the paper is slightly
yellow.

## Flatbed, sheet-fed and the phone in your pocket

A **flatbed** scans anything you can lay flat, including a book. A **sheet-fed** scanner or the
feeder on a multifunction device pulls pages through and is far faster for a stack, and cannot
take a book or a fragile original.

And honestly: **a phone camera with a document app beats a flatbed for a single page.** It
corrects the perspective, finds the edges, thresholds it to clean white and runs OCR, in the time
it takes to warm a lamp up. The scanner wins on a stack, on a book, and on anything where the
original has to be reproduced rather than read.

## Multifunction devices, and the one honest warning

A printer-scanner-copier in one box is genuinely convenient and has one property worth knowing
before you rely on it: **it is one device, so it fails as one.** A blocked print head or an empty
cartridge is enough to make several models refuse to scan as well, which is a repair queue of one
for two jobs you thought were separate.
