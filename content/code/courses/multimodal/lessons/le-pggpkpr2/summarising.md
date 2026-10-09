---
title: Summarising: what to hand the model
version: 2
---

A summary of a video is written by a language model, and the decision that matters is **what you give it to read**. There are three options, and their costs are not close:

The image numbers come from the rule OpenAI published for GPT-4o, written out as a small module that lessons 8 and 13 use again. Lesson 8 explains the rule step by step.

`tokens.py`:

```python
"""What a picture costs a vision model, by the rules OpenAI published for GPT-4o and Google for Gemini."""
import math


def gpt4o_tokens(w, h, detail="high"):
    """85 for the picture, plus 170 for every 512-pixel tile after two resizes: (tokens, tiles)."""
    if detail == "low":                       # one small copy of the picture, whatever its size
        return 85, 0
    if max(w, h) > 2048:                      # first, fit inside 2048 x 2048
        s = 2048 / max(w, h)
        w, h = int(w * s), int(h * s)
    if min(w, h) > 768:                       # then shrink until the short side is 768
        s = 768 / min(w, h)
        w, h = int(w * s), int(h * s)
    tiles = math.ceil(w / 512) * math.ceil(h / 512)
    return 85 + 170 * tiles, tiles


def gemini_tokens(w, h):
    """258 for a picture with both sides at most 384, otherwise 258 for every 768-pixel tile."""
    if w <= 384 and h <= 384:
        return 258
    return 258 * math.ceil(w / 768) * math.ceil(h / 768)
```

`budget.py`, which only counts:

```python
"""What each way of handing this video to a model would cost, in input tokens."""
import json

import tiktoken
from tokens import gpt4o_tokens

high, _ = gpt4o_tokens(1280, 720, "high")
low, _ = gpt4o_tokens(1280, 720, "low")
text = json.dumps(json.load(open("timeline.json")))
enc = tiktoken.get_encoding("o200k_base")
print(f"one 1280x720 frame: {high} tokens at high detail, {low} at low")
for name, frames in (("every frame", 815), ("one a second", 33), ("one per scene", 7)):
    print(f"{name:14} {frames:4} frames  {frames * high:7,} tokens high  {frames * low:6,} low")
print(f"{'the timeline':14} as text      {len(enc.encode(text)):7,} tokens")
```

```
ana@lab:~/mm$ python budget.py
one 1280x720 frame: 1105 tokens at high detail, 85 at low
every frame     815 frames  900,575 tokens high  69,275 low
one a second     33 frames   36,465 tokens high   2,805 low
one per scene     7 frames    7,735 tokens high     595 low
the timeline   as text          334 tokens
```

By that rule a 1280 by 720 frame is six tiles of 512 pixels, 85 + 6 × 170 = 1,105 tokens at high detail, and 85 at low detail, where the model sees a small copy. Nothing was sent anywhere; the program only counts.

- **Every frame** is 900,575 tokens at high detail, for a 32-second video. Nobody does this, and the number is there to show why.
- **One frame a second** is 36,465 tokens, and it missed the card.
- **One frame per scene** is 7,735 tokens and saw every slide.
- **The timeline as text** is 334 tokens. It holds every title and every word that was said.

**For a video made of slides and speech, the timeline is the right thing to send**: 23 times cheaper than the scene frames and nothing that matters lost, because the slides are text and OCR already read them. Add frames only for what text cannot carry: a chart, a photograph, the look of a damaged book. At low detail a frame costs 85 tokens, so one or two frames beside the timeline are cheap.

Models that take video directly, such as Gemini, do the sampling themselves; Google's documentation describes sampling one frame per second by default. That is convenient and it is the fixed-rate rule of section 03, with its blind spot: a card shown for 0.4 seconds would be missed there too.

## What a summary from this timeline looks like

The timeline is text, so any language model can summarise it, and the course's text model, `llama3.2:3b`, runs on your machine. `temperature=0` and a fixed `seed` make it give the same answer every time on one machine; on yours the wording may still differ, and the checks below are what matter.

`summary.py`:

```python
"""A summary of the returns video, written by llama3.2:3b from the timeline alone."""
import json

from openai import OpenAI

timeline = json.load(open("timeline.json"))
reply = OpenAI().chat.completions.create(
    model="llama3.2:3b", temperature=0, seed=1,
    messages=[{"role": "system", "content": "Summarise this video for a customer in one paragraph. "
                                            "Use only what the timeline says was shown or said."},
              {"role": "user", "content": json.dumps(timeline)}])
print(reply.choices[0].message.content)
```

```
ana@lab:~/mm$ python summary.py
Here's a summary of the video for a customer: To return a book purchased from Marginelia, follow these four easy steps. First, open the order and sign it, then choose a reason for return from the list. Next, print the prepared label and tape it over the old address. Finally, drop the parcel off at any post office and keep the receipt until your refund arrives, which will be credited back to the original payment card, including any shipping costs.
```

**Check a summary against its timeline, line by line.** Every claim in that paragraph should point at an entry, and this one shows the two ways a summary goes wrong without a single sentence that looks wrong.

**It repeated its sources' mistakes.** *Marginelia* is Whisper's spelling, not the shop's, though the first slide's title has it right. *Prepared label* is Whisper's too, for *prepaid*. And *open the order and sign it* is the model making sense of Whisper's *sign and end open the order*: a garbled phrase in, a confident wrong instruction out. The timeline kept both streams side by side, and the model took the spoken one each time.

**It left out what was only shown.** Nothing about the code RETURN30, the 30 days or the label that is valid for 7 days, all of which are in the timeline's `shown` entries. And it stretched the one condition it kept: the video refunds shipping for a *damaged* book, and the summary says every refund includes *any shipping costs*. That is the error a customer would act on.

The fixes are checks, not a better prompt: ask for every claim with the time it comes from, and compare the summary's facts with the slides' text, which OCR already has. Lesson 14 needs the same discipline for captions.