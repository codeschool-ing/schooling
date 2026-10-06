---
title: Reading printed text with Tesseract
version: 1
---

**Optical character recognition (OCR) turns a picture of printed text into text.** Tesseract is the open-source OCR engine most programs that read text from images are built on, and version 5 uses a small neural network trained per language. It does one job and does not pretend to do others: it will not tell you that a page is an invoice or that the total looks wrong.

It does that job in two steps, and the first one fails more often than the second. **First it decides where the text is**: which areas of the page are blocks, which lines are in them, and in what order to read them. **Then it reads each line.** The default, *page segmentation mode* 3, assumes it does not know the layout and works it out. On the lab's invoice it worked it out like this:

```
ana@lab:~/mm$ tesseract media/invoice-0931.png - 2>/dev/null | sed -n "9,20p"
Av. Exemplo 1000, Sao Paulo SP

INVOICE

Number: INV-0931
Date: 2026-09-15
Due: 2026-10-15

Title Qty Unit Amount
Dom Casmurro 12 18.50 222.00
The Posthumous Memoirs of Bras Cubas 8 21.00 168.00
Bleak House 5 32.90 164.50
```

Every character is right except two letters (*Sao* and *Bras*, about which below). But the address of the shop comes before the word INVOICE, which sits at the top of the page, and the table came out whole only because this page is clean. Tesseract found blocks, and it read each block on its own, top to bottom.

Mode 6 tells it to assume **one uniform block of text**, read as rows:

```
ana@lab:~/mm$ tesseract media/invoice-0931.png - --psm 6 2>/dev/null | sed -n "8,13p"
Title Qty Unit Amount
Dom Casmurro 12 18.50 222.00
The Posthumous Memoirs of Bras Cubas 8 21.00 168.00
Bleak House 5 32.90 164.50
The Secret Garden 10 15.90 159.00
Subtotal 713.50
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two copies of the invoice&#x27;s table seen by Tesseract. On the left, the default page mode splits the page into blocks: a column of titles and, separately, a column of quantities, prices and amounts, so the numbers come out after all the titles. On the right, page mode 6 treats the page as one block of rows, and each title comes out on the same line as its numbers.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">psm 3, the default: blocks</text><rect x=\"20\" y=\"30\" width=\"170\" height=\"130\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"200\" y=\"30\" width=\"150\" height=\"130\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dom Casmurro</text><text x=\"210\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12  18.50  222.00</text><text x=\"30\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">The Posthumous…</text><text x=\"210\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8  21.00  168.00</text><text x=\"30\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bleak House</text><text x=\"210\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5  32.90  164.50</text><text x=\"30\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">The Secret Garden</text><text x=\"210\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10  15.90  159.00</text><text x=\"30\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">block 1, read first</text><text x=\"210\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">block 2, read after it</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">psm 6: one block of rows</text><rect x=\"380\" y=\"36\" width=\"320\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dom Casmurro</text><text x=\"560\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12  18.50  222.00</text><rect x=\"380\" y=\"64\" width=\"320\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">The Posthumous…</text><text x=\"560\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8  21.00  168.00</text><rect x=\"380\" y=\"92\" width=\"320\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bleak House</text><text x=\"560\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5  32.90  164.50</text><rect x=\"380\" y=\"120\" width=\"320\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">The Secret Garden</text><text x=\"560\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10  15.90  159.00</text><text x=\"380\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">each row read left to right</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Same page, same model. Only the assumption about the layout changed: 24.0% of the characters wrong against 0.4%.</text></svg>", "caption": "Tesseract first decides where the text is, then reads it, and the first decision can be the one that fails."}
```

On a form, a table or an invoice, rows are the structure you want, and telling Tesseract so is the cheapest improvement available. The two modes on both copies of the invoice, measured against the truth:

```python
"""How far an OCR reading is from the truth: the character error rate, per setting."""
import subprocess
import sys

import jiwer

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())


def read(path, psm, lang):
    out = subprocess.run(["tesseract", path, "-", "--psm", psm, "-l", lang],
                         capture_output=True, text=True, check=True).stdout
    return " ".join(out.split())


for path in sys.argv[1:]:
    for psm, lang in (("3", "eng"), ("6", "eng"), ("6", "eng+por")):
        cer = jiwer.cer(TRUTH, read(path, psm, lang))
        print(f"{path:28} psm {psm}  {lang:8} CER {cer:6.1%}")
```

```
ana@lab:~/mm$ python score.py media/invoice-0931.png media/invoice-0931-scan.jpg
media/invoice-0931.png       psm 3  eng      CER  24.0%
media/invoice-0931.png       psm 6  eng      CER   0.4%
media/invoice-0931.png       psm 6  eng+por  CER   0.4%
media/invoice-0931-scan.jpg  psm 3  eng      CER  57.1%
media/invoice-0931-scan.jpg  psm 6  eng      CER   1.2%
media/invoice-0931-scan.jpg  psm 6  eng+por  CER   0.4%
```

Three findings, in order of size.

**Choosing the page mode moved the error from 24.0% to 0.4%** on the clean page and from 57.1% to 1.2% on the scan. Most of the "error" in mode 3 is text in the wrong order, which a person reads past and a program that parses rows does not.

**The language data matters for the characters it knows.** `eng` has no *ã* or *á*, so *São Paulo* and *Brás Cubas* came out as *Sao* and *Bras*. Adding Portuguese (`-l eng+por`, the package `tesseract-ocr-por`, which the lab installs) fixed both on the scan. An invoice from a Brazilian supplier with English titles needs both languages.

**The clean page is not the scan.** The next section is about the difference.
