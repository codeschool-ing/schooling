---
title: What a picture costs
version: 2
---

Lesson 8 measured the GPT-4o tile rule on one cover. This program applies it, and Google's rule for Gemini, to three pictures of very different sizes. The third is `cat_and_dog.jpg` scaled up to 4032 by 3024 pixels, the size a 12-megapixel phone camera saves, so that a phone photo has a stand-in. One line makes it:

```
ana@lab:~/mm$ python -c "from PIL import Image; Image.open(\"media/cat_and_dog.jpg\").resize((4032, 3024)).save(\"media/phone.jpg\", quality=90)"; stat -c "%s %n" media/phone.jpg
883497 media/phone.jpg
```

The program reads the token rules from lesson 4's `tokens.py`:

```python
"""What one picture costs to send, by the token rules of lesson 8 and the sheet's input prices."""
import sys

from tokens import gemini_tokens, gpt4o_tokens
from PIL import Image

GPT4O = 2.5e-06          # sheet: gpt-4o input_cost_per_token
FLASH = 3e-07            # sheet: gemini/gemini-2.5-flash input_cost_per_token

print("%-22s %11s %7s %8s %7s %9s" % ("file", "pixels", "detail", "tokens", "$/1000", "gemini $/1000"))
for path in sys.argv[1:]:
    w, h = Image.open(path).size
    for detail in ("low", "high"):
        t, _ = gpt4o_tokens(w, h, detail)
        g = gemini_tokens(w, h) if detail == "high" else None
        line = "%-22s %11s %7s %8d %7.2f %9s" % (path.split("/")[-1], f"{w}x{h}", detail, t, t * GPT4O * 1000,
                                                "%.2f" % (g * FLASH * 1000) if g else "")
        print(line.rstrip())
```

```
ana@lab:~/mm$ python picture_cost.py media/cover-b39.png media/invoice-0931.png media/phone.jpg
file                        pixels  detail   tokens  $/1000 gemini $/1000
cover-b39.png              600x900     low       85    0.21
cover-b39.png              600x900    high      765    1.91      0.15
invoice-0931.png         1240x1754     low       85    0.21
invoice-0931.png         1240x1754    high     1105    2.76      0.46
phone.jpg                4032x3024     low       85    0.21
phone.jpg                4032x3024    high      765    1.91      1.86
```

Read the `tokens` column first.

- **`low` is 85 tokens for every picture**, the phone photo included. It is the cheap default when the question is about the whole scene rather than its details.
- **`high` is not proportional to pixels.** The phone photo has more than 22 times the cover's pixels and the same 765 tokens, because OpenAI first fits it inside 2048 and then shrinks the short side to 768, which leaves 1024 by 768 and four tiles. The invoice is tall, so the same steps leave six tiles and 1,105 tokens.
- **Gemini's rule does not shrink first.** It counts 258 tokens per 768-pixel tile of the picture as sent, so the phone photo is 24 tiles and 6,192 tokens. Its price per token is much lower, and still the phone photo is its most expensive picture by far.

**The same picture can be cheap on one provider and dear on another**, and the ranking can flip. The cover costs $0.15 per thousand on Gemini and $1.91 at high detail on GPT-4o; the phone photo costs about the same on both. An estimate made with one provider's rule says nothing about the other's. These are the rules `tokens.py` writes out, from the providers' documents; a real bill is the provider's own count, in the `usage` of each reply.
