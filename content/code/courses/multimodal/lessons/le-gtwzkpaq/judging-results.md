---
title: Judging the pictures, and what an accepted one costs
version: 2
---

A grid of pictures does not decide anything by itself. Somebody looks at it, and the looking goes better with a list written before the first picture arrives, because a striking picture that misses the requirement is still a miss.

For the banner, the list is the requirement and the style guide:

1. Is the right third empty enough for a headline?
2. Is there any text, or anything that tries to be text?
3. Is there a face, or anything that could be read as a real person or a real brand?
4. Are the medium and palette the guide's?
5. Would a reader see a pile of books, quickly, at the size the newsletter shows it?

Each picture gets a yes or no per line, and only a picture with five yeses is a candidate. Writing the list first is what stops the judging from turning into taste.

## The cost of an accepted picture

Image generation is priced per picture. This course reads prices from one place, a sheet the open-source library LiteLLM keeps of every model it can call, and reads it with a short program. The sheet is a third party's copy of the providers' own pages, and the program pins one version of it, so the numbers below stay the same however long after today you run it.

`prices.py`, which lessons 9, 10 and 13 use as well:

```python
"""prices: what LiteLLM's price sheet says about a model, read at one pinned commit.

    python prices.py show NAME                every field of one entry
    python prices.py find TEXT [MODE]         every entry whose name contains TEXT

LiteLLM is an open-source library that calls a hundred providers through one
interface, and it keeps one JSON file of every model's prices to do it. It is a
third party's copy of the providers' pages, so every number this course takes
from it says so. The commit is pinned, so the same file comes out next year.
"""
import json
import os
import sys
import urllib.request

COMMIT = "21881c571181fc0e409dd717b8a277e5b43152a7"
URL = f"https://raw.githubusercontent.com/BerriAI/litellm/{COMMIT}/model_prices_and_context_window.json"
CACHE = os.path.expanduser(f"~/mm/data/litellm-{COMMIT[:8]}.json")

if not os.path.exists(CACHE):                       # downloaded once, then read from disk
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    urllib.request.urlretrieve(URL, CACHE)
sheet = json.load(open(CACHE))

if sys.argv[1] == "show":
    for key, value in sorted(sheet[sys.argv[2]].items()):
        print(f"{key:42} {value}")
elif sys.argv[1] == "find":
    mode = sys.argv[3] if len(sys.argv) > 3 else None
    for name, entry in sorted(sheet.items()):
        if sys.argv[2] in name and mode in (None, entry.get("mode")):
            print(f"{name:44} {entry.get('litellm_provider', ''):26} {entry.get('deprecation_date', '')}")
```

What it says about Google's image model:

```
ana@lab:~/mm$ python prices.py show gemini/gemini-2.5-flash-image | grep -E "output_cost_per_image|deprecation|source"
deprecation_date                           2026-10-02
output_cost_per_image                      0.039
output_cost_per_image_token                3e-05
source                                     https://ai.google.dev/gemini-api/docs/pricing
ana@lab:~/mm$ python -c "print(round(0.039 * 4, 3), round(0.039 * 12, 3))"
0.156 0.468
```

**0.039 dollars a picture**, and a **deprecation date of 2 October 2026**, five days before this lesson was recorded. Both are facts about one day of one provider, read from a third party's copy of Google's pricing page, and both will be different when you read this. Lesson 9 looks at what that date means for code that names the model.

The price that matters is not per picture but **per accepted picture**. If one picture in four passes the list, each banner costs four generations: 0.156 dollars. If the team generates two per variant, across five variants, and keeps one, it costs 0.468 dollars for that one banner, as the second line above computes. That is still cheap for a banner and it is not cheap as a feature that a customer presses again and again, which is the design sheet's warning about this whole course and the subject of lesson 13.
