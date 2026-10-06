---
title: Summarising: what to hand the model
version: 1
---

A summary of a video is written by a language model, and the decision that matters is **what you give it to read**. There are three options, and their costs are not close:

```python
"""What each way of handing this video to a model would cost, in input tokens."""
import json

import tiktoken
from labmm import gpt4o_tokens

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

The image numbers come from the tile rule OpenAI published for GPT-4o, as implemented in the lab's stand-in. A 1280 by 720 frame is six tiles of 512 pixels, 85 + 6 × 170 = 1,105 tokens at high detail, and 85 at low detail, where the model sees a small copy. Nothing was sent anywhere; the program only counts.

- **Every frame** is 900,575 tokens at high detail, for a 32-second video. Nobody does this, and the number is there to show why.
- **One frame a second** is 36,465 tokens, and it missed the card.
- **One frame per scene** is 7,735 tokens and saw every slide.
- **The timeline as text** is 321 tokens. It holds every title and every word that was said.

**For a video made of slides and speech, the timeline is the right thing to send**: 24 times cheaper than the scene frames and nothing that matters lost, because the slides are text and OCR already read them. Add frames only for what text cannot carry: a chart, a photograph, the look of a damaged book. At low detail a frame costs 85 tokens, so one or two frames beside the timeline are cheap.

Models that take video directly, such as Gemini, do the sampling themselves; Google's documentation describes sampling one frame per second by default. That is convenient and it is the fixed-rate rule of section 03, with its blind spot: a card shown for 0.4 seconds would be missed there too.

## What a summary from this timeline looks like

No language model runs in this lab. Here is a summary written by the course from the timeline above, to show the shape, not produced by any model:

> *Marginalia's returns video explains four steps: open the order under Account › Orders, press Return this item and choose a reason, print the prepaid label sent by e-mail and tape it over the old address, and drop the parcel at a post office, keeping the receipt. Refunds go to the card used; damaged books are refunded in full with shipping, within 30 days of delivery. A code, RETURN30, is shown briefly for customers who call.*

**Check a summary against its timeline, line by line.** Every claim in that paragraph should point at an entry. *Within 30 days* and *RETURN30* come from what was shown; *the card used* from what was said. And one detail is wrong in a way the timeline exposes: OCR read the code with a letter O, and a summary that "corrected" it to a zero did so on its own authority. Here the slide does say 30, so the correction is right, and a summariser that silently corrects its input is a summariser that will one day correct it wrongly. Lesson 14 needs the same discipline for captions.
