---
title: What an image is to a model
version: 1
---

**An image is a grid of numbers, and a model only ever reads the grid.** A photograph of 640 by 416 pixels in colour is 640 × 416 × 3 = 798,720 numbers between 0 and 255, one each for red, green and blue at every point. There is no "text" or "cat" in the file. What there is in the file is the pattern of numbers that a person reads as text or a cat, and a model is something trained to map those patterns to answers.

Two things follow, and both matter more than which model you choose.

**The model sees a fixed size.** Almost every image model resizes what it is given before reading it. MediaPipe's object detector works on a square of 320 pixels; a vision-language model cuts the picture into tiles or patches of a fixed size and pays for each one (lesson 8 counts them). What the model reads is the resized copy, so detail the resize throws away was never seen.

**Resolution is information, and below some size it is gone.** Here is the clean invoice, made smaller step by step and read by Tesseract each time:

```python
"""The clean invoice made smaller and smaller, and read each time."""
import subprocess

import jiwer
from PIL import Image

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())
page = Image.open("media/invoice-0931.png")
for width in (1240, 620, 413, 310):
    small = page.resize((width, round(page.height * width / page.width)), Image.LANCZOS)
    small.save(f"/tmp/invoice-{width}.png")
    out = subprocess.run(["tesseract", f"/tmp/invoice-{width}.png", "-", "--psm", "6"],
                         capture_output=True, text=True, check=True).stdout
    print(f"{width:5} px wide ({width * 150 // 1240:3} dpi)  CER {jiwer.cer(TRUTH, ' '.join(out.split())):6.1%}")
```

```
ana@lab:~/mm$ python shrink.py
 1240 px wide (150 dpi)  CER   0.4%
  620 px wide ( 75 dpi)  CER   1.4%
  413 px wide ( 49 dpi)  CER  20.7%
  310 px wide ( 37 dpi)  CER  92.7%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A bar chart of Tesseract&#x27;s character error rate on the clean invoice at four sizes. At 1240 pixels wide, 150 dpi, 0.4%. At 620 pixels, 75 dpi, 1.4%. At 413 pixels, 49 dpi, 20.7%. At 310 pixels, 37 dpi, 92.7%, nearly every character wrong.\"><line x1=\"80\" y1=\"190\" x2=\"690\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">character error rate</text><rect x=\"110\" y=\"188\" width=\"70\" height=\"2\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"145\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.4%</text><text x=\"145\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1240 px</text><text x=\"145\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150 dpi</text><rect x=\"260\" y=\"187.9\" width=\"70\" height=\"2.1\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"295\" y=\"177.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.4%</text><text x=\"295\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">620 px</text><text x=\"295\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75 dpi</text><rect x=\"410\" y=\"158.95\" width=\"70\" height=\"31.05\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"445\" y=\"148.95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20.7%</text><text x=\"445\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">413 px</text><text x=\"445\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">49 dpi</text><rect x=\"560\" y=\"50.94999999999999\" width=\"70\" height=\"139.05\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"595\" y=\"40.94999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">92.7%</text><text x=\"595\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">310 px</text><text x=\"595\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">37 dpi</text></svg>", "caption": "Halve the width and the error barely moves; halve it again and the letters are no longer there to read."}
```

Halving the width from 1240 to 620 pixels cost almost nothing: 0.4% of characters wrong became 1.4%. At 413 pixels a fifth of the characters are wrong, and at 310 nearly all of them. The page did not get harder to understand; the letters stopped being there. At 37 dots per inch a lower-case letter is three or four pixels tall, and no model can read a shape that is not in the grid.

The same arithmetic runs the other way when you are paying. A vision API charges by how much of the picture it reads, and sending a page at 4000 pixels wide when 1240 reads perfectly is paying for pixels that add nothing. Lesson 13 sends the smallest image that still reads, and this measurement is how to find it: shrink until the error starts to rise, then step back once.

## Where the numbers came from

The invoice was drawn by the lab at 150 dots per inch from a specification, so `media/truth/invoice-0931.txt` holds exactly what is printed on it, row by row. The **character error rate** (CER) in these transcripts is the number of characters you would have to change, delete or insert to turn the reading into the truth, divided by the length of the truth. `jiwer.cer` computes it. 0.4% of the 492 characters on the page is two characters, and the next section finds them.
