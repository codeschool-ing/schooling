---
title: A bad scan, and what helps
version: 1
---

The second copy of the invoice is the first one after a cheap scanner: turned 1.8 degrees, blurred, sprinkled with noise, reduced to 100 dots per inch and saved as a JPEG at low quality. Every one of those steps is written in `make_media.py` from lesson 1, so the damage is known exactly. Read with the default mode, the table comes apart:

```
ana@lab:~/mm$ tesseract media/invoice-0931-scan.jpg - 2>/dev/null | sed -n "/Qty/,/Total/p"
Qty Unit Amount
2 18.50 222.00

8 21.00 168.00

5 32.90 164,50

10 15.90 159,00

Subtotal 713.50

Shipping 45.00

Total BRL 758.50
```

**The first quantity is `2`.** The page says 12. In the default mode Tesseract put the numbers in a block of their own, and the `1` at the edge of that block was lost. Nothing in the output says a character is missing; a program reading it would order two copies of *Dom Casmurro* and pay for twelve. Two amounts also came back with a comma.

Row mode does much better, and still not perfectly:

```
ana@lab:~/mm$ tesseract media/invoice-0931-scan.jpg - --psm 6 2>/dev/null | sed -n "6,16p"
Marginalia Books
‘Av. Exemplo 1000, Sao Paulo SP
Title Qty Unit Amount
Dom Casmurro 12 18.50 222,00
The Posthumous Memoirs of Bras Cubas 8 21.00 168.00
Bleak House 5 32.90 164.50
The Secret Garden 10 15.96 159.00
Subtotal 713,50
Shipping 45.00
Total BRL 758.50
Payment by bank transfer within 30 days. Thank you for your business.
```

`222,00` and `713,50` with commas, and **`15.96` where the page says `15.90`**. The blur made a 0 look like a 6. And with Portuguese added:

```
ana@lab:~/mm$ tesseract media/invoice-0931-scan.jpg - --psm 6 -l eng+por 2>/dev/null | sed -n "6,16p"
Marginalia Books
‘Av. Exemplo 1000, São Paulo SP
Title Qty Unit Amount
Dom Casmurro 12 18.50 222.00
The Posthumous Memoirs of Brás Cubas 8 21.00 168.00
Bleak House 5 32.90 164.50
The Secret Garden 10 15.90 159.00
Subtotal 713,50
Shipping 45.00
Total BRL 758.50
Payment by bank transfer within 30 days. Thank you for your business.
```

The accents are back and the `15.90` is right. Only the comma in `713,50` and a stray mark before *Av.* remain.

## The cures people reach for

Two fixes are suggested for every bad scan: make it bigger, and turn it straight. Both were measured, with the setting that read best.

`tidy.py`:

```python
"""Two cures people reach for on a bad scan: make it bigger, and turn it straight."""
import subprocess

import jiwer
from PIL import Image

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())
scan = Image.open("media/invoice-0931-scan.jpg")
tries = {
    "as scanned": scan,
    "twice the size": scan.resize((scan.width * 2, scan.height * 2), Image.LANCZOS),
    "turned 1.8 degrees back": scan.rotate(-1.8, resample=Image.BICUBIC, fillcolor=255),
}
for name, img in tries.items():
    img.save("/tmp/try.png")
    out = subprocess.run(["tesseract", "/tmp/try.png", "-", "--psm", "6", "-l", "eng+por"],
                         capture_output=True, text=True, check=True).stdout
    print(f"{name:24} CER {jiwer.cer(TRUTH, ' '.join(out.split())):6.1%}")
```

```
ana@lab:~/mm$ python tidy.py
as scanned               CER   0.4%
twice the size           CER   1.0%
turned 1.8 degrees back  CER   0.4%
```

**Doubling the size made it worse**, 0.4% to 1.0%. Enlarging a blurred image enlarges the blur; Tesseract was already reading it at a size it handles well. **Turning it back changed nothing measurable**: Tesseract corrects small rotations itself. On a different page either could help; the lesson here is to measure each change rather than apply a recipe, because a cure that is right in a tutorial can be wrong for your scanner.

## How sure was it?

Tesseract gives every word a confidence between 0 and 100, and its `tsv` output adds where on the page the word is:

```python
"""Every word Tesseract read with less than 90% confidence, and where it is on the page."""
import csv
import io
import subprocess
import sys

lang = sys.argv[2] if len(sys.argv) > 2 else "eng+por"
tsv = subprocess.run(["tesseract", sys.argv[1], "-", "--psm", "6", "-l", lang, "tsv"],
                     capture_output=True, text=True, check=True).stdout
rows = list(csv.DictReader(io.StringIO(tsv), delimiter="\t", quoting=csv.QUOTE_NONE))
words = [r for r in rows if r["text"].strip()]
print(f"{len(words)} words")
for r in words:
    if float(r["conf"]) < 90:
        print(f"  {r['text']:14} conf {float(r['conf']):5.1f}  at x={r['left']:>4} y={r['top']:>4}")
```

```
ana@lab:~/mm$ python doubt.py media/invoice-0931-scan.jpg
76 words
  Palmeiras      conf  82.8  at x= 115 y= 118
  billing@lanternquill.example.com conf  69.9  at x=  47 y= 133
  Bill           conf  90.0  at x=  50 y= 233
  to             conf  90.0  at x=  83 y= 233
  ‘Av.           conf  78.9  at x=  51 y= 283
  Casmurro       conf  89.9  at x=  97 y= 393
  10             conf  83.7  at x= 513 y= 476
  713,50         conf  86.1  at x= 708 y= 527
ana@lab:~/mm$ python doubt.py media/invoice-0931-scan.jpg eng | grep -E "15|222|713|words"
76 words
  Palmeiras      conf  24.4  at x= 115 y= 118
  222,00         conf  86.2  at x= 704 y= 368
  15.96          conf  61.6  at x= 598 y= 472
  713,50         conf  86.1  at x= 708 y= 527
```

`713,50` is on the list, at 86.1: the comma it should not have was a doubtful read. So is `10`, which is right, and so is *Palmeiras*, which is also right. The second command reads with English only, where the price came back as `15.96`, and keeps the lines that matter: the wrong price is there at 61.6, and *Palmeiras*, which is right, is lower still at 24.4.

**Confidence is a hint about where to look, not a verdict.** A low score flags a word worth checking, and it flags right words too; a high score does not prove a word is right, and `222,00` with its stray comma scored 86.2. The next section uses a check that does not depend on how sure the model felt.
