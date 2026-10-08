---
title: Shrinking a picture before sending it
version: 2
---

If a provider counts tokens from width and height, the obvious saving is to send a smaller picture. This program makes three smaller copies of the invoice and asks two questions of each: what would it cost, and **can it still be read**? Tesseract stands in for the reader, and two measures stand in for the answer: the share of the page's words it found, in any order, and how many of the page's 11 money values it read exactly.

```python
"""The invoice, made smaller three ways: does Tesseract still read it, and what does each copy cost?"""
import io
import re
import subprocess
from collections import Counter

from tokens import gpt4o_tokens
from PIL import Image

truth = open("media/truth/invoice-0931.txt").read()
amounts = re.findall(r"\d+\.\d\d", truth)                  # the 11 money values on the page
page = Image.open("media/invoice-0931.png")


def read(data):
    return subprocess.run(["tesseract", "-", "-"], input=data, capture_output=True).stdout.decode()


def copy(img, fmt, **kw):
    buf = io.BytesIO()
    img.save(buf, fmt, **kw)
    return buf.getvalue()


print("%-26s %9s %7s %7s %8s" % ("copy", "bytes", "tokens", "words", "amounts"))
for name, short, fmt, kw in (("original png", 1240, "PNG", {}),
                             ("png, short side 768", 768, "PNG", {}),
                             ("jpeg q75, short side 768", 768, "JPEG", {"quality": 75}),
                             ("jpeg q75, short side 512", 512, "JPEG", {"quality": 75})):
    s = short / page.width
    img = page.resize((round(page.width * s), round(page.height * s)), Image.LANCZOS)
    data = copy(img.convert("RGB"), fmt, **kw) if short < 1240 else open("media/invoice-0931.png", "rb").read()
    tokens, _ = gpt4o_tokens(img.width, img.height, "high")
    text = read(data)
    found = sum((Counter(truth.split()) & Counter(text.split())).values()) / len(truth.split())
    print("%-26s %9d %7d %6.0f%% %5d/%d" % (name, len(data), tokens, 100 * found,
                                           sum(a in text for a in amounts), len(amounts)))
```

```
ana@lab:~/mm$ python shrink.py
copy                           bytes  tokens   words  amounts
original png                   87530    1105     97%    11/11
png, short side 768           106098    1105     91%    11/11
jpeg q75, short side 768       50761    1105     92%    11/11
jpeg q75, short side 512       26832     425     76%     4/11
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Four copies of the invoice as bars. Original PNG: 87,530 bytes, 1,105 tokens, 11 of 11 amounts read. PNG with the short side at 768: 106,098 bytes, 1,105 tokens, 11 of 11. JPEG quality 75 at 768: 50,761 bytes, 1,105 tokens, 11 of 11. JPEG quality 75 at 512: 26,832 bytes, 425 tokens, 4 of 11. The token bar only drops for the last copy, and that is the copy that lost most of the amounts.\"><text x=\"170\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">bytes</text><text x=\"370\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens</text><text x=\"570\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">amounts read</text><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">original png</text><rect x=\"170\" y=\"44\" width=\"148.49855793700164\" height=\"22\" rx=\"3\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">87,530</text><rect x=\"370\" y=\"44\" width=\"180.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,105</text><rect x=\"570\" y=\"44\" width=\"130.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11/11</text><text x=\"20\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">png, 768</text><rect x=\"170\" y=\"92\" width=\"180.0\" height=\"22\" rx=\"3\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">106,098</text><rect x=\"370\" y=\"92\" width=\"180.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,105</text><rect x=\"570\" y=\"92\" width=\"130.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11/11</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">jpeg q75, 768</text><rect x=\"170\" y=\"140\" width=\"86.11830571735565\" height=\"22\" rx=\"3\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50,761</text><rect x=\"370\" y=\"140\" width=\"180.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,105</text><rect x=\"570\" y=\"140\" width=\"130.0\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11/11</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">jpeg q75, 512</text><rect x=\"170\" y=\"188\" width=\"45.52168749646553\" height=\"22\" rx=\"3\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26,832</text><rect x=\"370\" y=\"188\" width=\"69.23076923076923\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">425</text><rect x=\"570\" y=\"188\" width=\"47.27272727272727\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4/11</text></svg>", "caption": "Shrinking to 768 changed the bytes and nothing else; going below it changed the tokens and the answers together."}
```

**Shrinking to 768 saved nothing.** The tokens stayed at 1,105, because 768 on the short side is where OpenAI's rule puts the picture anyway: the provider was going to do this resize itself. The PNG even got bigger, 106,098 bytes against 87,530, because resizing a black-and-white page adds grey edges that PNG compresses badly. JPEG at the same size halved the bytes, which makes the upload faster and changes nothing on the bill.

**Going below the rule's size saved tokens and lost the invoice.** At 512 the copy costs 425 tokens, 62% fewer, and only 4 of the 11 amounts came back right. A model reading that copy would be reading the same blur.

So the rule for pictures is short. **Resize down to what the provider will use anyway**, which saves upload time and bytes against a limit. Go no further unless a measurement on the task says the smaller copy still answers. "Still answers" is about the task: here, the amounts. Bytes saved are easy to see, and the answers lost are only visible to a check like this one.
