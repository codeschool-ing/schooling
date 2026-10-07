---
title: Detail, tiles and what a picture costs
version: 1
---

A vision model does not charge by the byte. It charges by how much of the picture it reads, and OpenAI published the rule for GPT-4o: **85 tokens for the picture as a whole, plus 170 for every tile of 512 by 512 pixels** that covers it, after two resizes. Lesson 4's `tokens.py` counts by that rule, so the numbers below are what the rule gives; nothing is sent to compute them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The invoice at three sizes, drawn to scale. First as sent, 1240 by 1754 pixels. Then shrunk until its short side is 768, giving 768 by 1086. Then that copy covered by a grid of 512-pixel tiles, two across and three down, six tiles in all; the tiles in the last column and row hang past the edge of the page. Beside it: 85 plus 6 times 170 is 1105 tokens.\"><defs><marker id=\"l08til-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08til-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"161.20000000000002\" height=\"228.02\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1240 x 1754</text><line x1=\"189.20000000000002\" y1=\"140\" x2=\"221.20000000000002\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l08til-ah-phosphor)\"></line><rect x=\"230\" y=\"30\" width=\"99.84\" height=\"141.18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">768 x 1086</text><line x1=\"337.84000000000003\" y1=\"100\" x2=\"369.84000000000003\" y2=\"100\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l08til-ah-amber)\"></line><rect x=\"380\" y=\"30\" width=\"99.84\" height=\"141.18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"380.0\" y=\"30.0\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"380.0\" y=\"96.56\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"380.0\" y=\"163.12\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"30.0\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"96.56\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"163.12\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">6 tiles of 512</text><text x=\"540\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fit in 2048 x 2048</text><text x=\"540\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(already does)</text><text x=\"540\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">short side to 768</text><text x=\"540\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1240 -&gt; 768</text><text x=\"540\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">count 512 tiles</text><text x=\"540\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 x 3 = 6</text><text x=\"540\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">85 + 6 x 170</text><text x=\"540\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">= 1105 tokens</text><text x=\"20\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">At detail low the model sees one small copy, and it costs 85 whatever the size.</text></svg>", "caption": "The tile rule OpenAI published for GPT-4o, as lesson 4's tokens.py counts it: the page is resized twice before anything is charged."}
```

For the invoice, 1240 by 1754 pixels:

1. **Fit inside 2048 by 2048.** It already does.
2. **Shrink until the short side is at most 768.** 1240 becomes 768, and 1754 becomes 1086.
3. **Count the 512-pixel tiles that cover it.** Two across, three down: 6.
4. **85 + 6 × 170 = 1,105 tokens.**

With `detail: "low"` none of that happens: the model sees one small copy of the picture and it costs **85 tokens**, whatever its size. With `"auto"` (the default) the provider chooses. A program can compute all of it before sending anything:

```python
"""What a picture costs a vision model by the tile rule, before anything is sent."""
from tokens import gpt4o_tokens

PRICE = 2.5 / 1_000_000          # gpt-4o, dollars per input token, from the sheet
SIZES = [("the cover", 600, 900), ("the invoice", 1240, 1754), ("the invoice, half size", 620, 877),
         ("the photograph", 640, 416), ("a phone photo", 4000, 3000), ("a video frame", 1280, 720)]
print(f"{'':24}{'high':>6} {'tiles':>5} {'low':>5}   per 1,000 at high")
for name, w, h in SIZES:
    high, tiles = gpt4o_tokens(w, h, "high")
    low, _ = gpt4o_tokens(w, h, "low")
    print(f"{name:24}{high:6} {tiles:5} {low:5}   ${high * 1000 * PRICE:.2f}")
```

```
ana@lab:~/mm$ python tiles.py
                          high tiles   low   per 1,000 at high
the cover                  765     4    85   $1.91
the invoice               1105     6    85   $2.76
the invoice, half size     765     4    85   $1.91
the photograph             425     2    85   $1.06
a phone photo              765     4    85   $1.91
a video frame             1105     6    85   $2.76
```

Three lessons sit in that table. **A phone photo of 4000 by 3000 costs the same 765 tokens as the cover**: the resize throws away most of its 12 million pixels before anything is counted, so sending it at full size pays for the upload and buys nothing. **The invoice at half its width costs 765 instead of 1,105**, and lesson 2 measured that it still reads at 1.4% character error. And **every 1,000 invoices cost $2.76 at gpt-4o's input price** of 2.5 dollars per million tokens, read from the sheet. That is cheap per page and it is the floor: the prompt, the reply and any retries come on top (lesson 13).

## Low detail is a reading choice

With `detail: "low"` OpenAI's model reads one small copy of the picture. **Ollama ignores the `detail` field**, so the course's model cannot show the setting itself; what it can show is what the setting does, because a small copy is something you can make yourself. The invoice at its own width, at half and at a quarter, each asked for its total.

`sizes.py`:

```python
"""The invoice at three widths: how many tokens the model is charged, and whether it still reads the total."""
import base64
import io

from openai import OpenAI
from PIL import Image

page = Image.open("media/invoice-0931.png")
client = OpenAI()
for width in (1240, 620, 310):
    small = page.resize((width, round(page.height * width / page.width)), Image.LANCZOS)
    buf = io.BytesIO()
    small.save(buf, "PNG")
    url = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
    reply = client.chat.completions.create(
        model="qwen2.5vl:3b", temperature=0, seed=1,
        messages=[{"role": "user", "content": [
            {"type": "text", "text": "What is the total on this invoice? Answer with the amount only."},
            {"type": "image_url", "image_url": {"url": url}},
        ]}])
    print(f"{width:5} x {small.height:4}  {reply.usage.prompt_tokens:5} tokens in   {reply.choices[0].message.content.strip()}")
```

```
ana@lab:~/mm$ python sizes.py
 1240 x 1754   2807 tokens in   758.50
  620 x  877   1088 tokens in   758.50
  310 x  438   1088 tokens in   758.50
```

**This model counts by pixels, with a floor.** The full page cost 2,807 tokens and half its width cost 1,088, about two fifths. A quarter of the width cost the same 1,088, because Qwen2.5-VL enlarges a picture below its minimum size before reading it, so past that point a smaller picture stops being cheaper. That is this model's rule, as the tile rule is GPT-4o's, and every provider has one.

**And it read the total at every size**, even at 310 pixels wide, where lesson 2's Tesseract got nine characters in ten wrong. A vision-language model copes with a small, blurred page far better than OCR does, and that is exactly what makes its answer hard to doubt: on a page where a person can no longer read the digits, it still answers in the same confident tone. Here the answer is right. The invoice's own arithmetic, in the next section, is how you would find out if it were not.

So low detail is a reading choice. A small copy is enough for *what is this picture?*; for *what does it say?* it is a risk you measure on your own pages, not a setting you trust.

**Other models count differently.** gpt-4o-mini charges many more tokens for the same tiles at a lower price per token, newer models count in small patches rather than tiles, and Gemini has its own rule (lesson 9). The method is the one to keep: read the provider's rule, compute the cost of your typical picture before you send it, and resize to the smallest size that still answers the question.
