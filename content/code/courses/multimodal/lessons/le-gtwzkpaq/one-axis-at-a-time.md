---
title: Change one thing, then look
version: 1
---

**Prompting an image model is an experiment, and it has the rules of one.** Change one thing at a time, keep everything else fixed, look at the result, and write down what you changed. Change the medium and the light together, and when the picture improves you will not know which change did it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The banner prompt cut into six named parts, each in its own box: subject, medium, style, composition, light and palette. Under the medium box are its three tried values, watercolour illustration, linocut print and photograph; under the light box, its three, late afternoon sun, overcast daylight and a desk lamp at night. Every other box keeps its one value.\"><rect x=\"20\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">subject</text><rect x=\"135\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"145\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">medium</text><rect x=\"250\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">style</text><rect x=\"365\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"375\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">composition</text><rect x=\"480\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">light</text><rect x=\"595\" y=\"20\" width=\"105\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">palette</text><text x=\"145\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">watercolour</text><text x=\"145\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">linocut</text><text x=\"145\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">photograph</text><text x=\"490\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">afternoon sun</text><text x=\"490\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">overcast</text><text x=\"490\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">desk lamp</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Change one box at a time, keep every other box as it was, and look at what moved.</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Two boxes changed at once and you cannot tell which one did it.</text></svg>", "caption": "A prompt with named parts is a prompt you can vary on purpose."}
```

The prompt from the previous section, as a program that keeps its parts named and builds a grid of variants, one part changed per row:

```python
"""A banner prompt as named parts, and a grid that changes one part at a time."""
import json
import sys

BASE = {
    "subject": "a stack of second-hand books on a café table",
    "medium": "watercolour illustration",
    "style": "loose brushwork, soft edges",
    "composition": "wide banner, books on the left third, empty space on the right",
    "light": "late afternoon sun from the left",
    "palette": "warm ochre and deep green",
}
TRIES = {
    "medium": ["watercolour illustration", "linocut print", "photograph, 35 mm lens"],
    "light": ["late afternoon sun from the left", "overcast daylight", "a single desk lamp at night"],
}


def prompt(parts):
    return ", ".join(parts[k] for k in BASE)


rows = [{"axis": "base", "value": "", "prompt": prompt(BASE)}]
for axis, values in TRIES.items():
    for v in values:
        if v != BASE[axis]:
            rows.append({"axis": axis, "value": v, "prompt": prompt(dict(BASE, **{axis: v}))})
json.dump(rows, open("grid.json", "w"), indent=1)
for r in rows:
    print(f"{r['axis']:7} {r['value'] or '(as above)':36} {len(r['prompt'])} characters")
print(rows[0]["prompt"], file=sys.stderr)
```

```
ana@lab:~/mm$ python axes.py
a stack of second-hand books on a café table, watercolour illustration, loose brushwork, soft edges, wide banner, books on the left third, empty space on the right, late afternoon sun from the left, warm ochre and deep green
base    (as above)                           224 characters
medium  linocut print                        213 characters
medium  photograph, 35 mm lens               222 characters
light   overcast daylight                    209 characters
light   a single desk lamp at night          219 characters
```

Five prompts: the base, two other media, two other lights. Nothing else moves between them, and the program says how long each one is, which matters for the models that stop reading at 77 tokens.

Then every prompt is sent, **twice**, because one picture of a prompt is not a measurement of it. The Images API has no seed (section 02), so asking for `n=2` per prompt is how you tell "this prompt gives cold light" from "this one picture happened to come out cold":

```python
"""Send every prompt in grid.json, twice, and keep each picture with what asked for it."""
import base64
import csv
import json
import os

from openai import OpenAI

client = OpenAI()
os.makedirs("grid", exist_ok=True)
with open("grid/log.csv", "w", newline="") as f:
    log = csv.writer(f)
    log.writerow(["file", "axis", "value", "prompt"])
    for i, row in enumerate(json.load(open("grid.json"))):
        result = client.images.generate(model="lab-image-1", prompt=row["prompt"], size="1536x1024", n=2)
        for k, image in enumerate(result.data):
            name = f"grid/{i:02}-{k}.png"
            open(name, "wb").write(base64.b64decode(image.b64_json))
            log.writerow([name, row["axis"], row["value"], row["prompt"]])
print(open("grid/log.csv").read().count("\n") - 1, "pictures,", len(os.listdir("grid")) - 1, "files")
```

```
ana@lab:~/mm$ python grid.py
10 pictures, 10 files
ana@lab:~/mm$ tail -n 2 /var/log/labmm/requests.jsonl | python -c "import json, sys; [print({k: r[k] for k in (\"n\", \"path\", \"size\", \"images\", \"bytes\")}) for r in map(json.loads, sys.stdin)]"
{'n': 5, 'path': '/v1/images/generations', 'size': '1536x1024', 'images': 2, 'bytes': [41599, 41532]}
{'n': 6, 'path': '/v1/images/generations', 'size': '1536x1024', 'images': 2, 'bytes': [41650, 41586]}
```

**The pictures that came back are not pictures of books.** labmm is the course's stand-in, and `lab-image-1` returns a grey card at the size asked for, with the prompt written on it and the line *no model drew this*. The request, the log and the files on disk are real; the drawing is not. What this lab can teach about image generation is the method around the model, and the method is what survives when the model changes.

## What to keep for each run

`grid/log.csv` has one row per picture: the file, which part changed, its value and the whole prompt. Without that row a good picture is a lucky accident nobody can make again. Add three more things when you run this against a real model:

- **the model and its version**, because the same prompt on next quarter's model is a different experiment;
- **the seed**, where the model exposes one;
- **the verdict**: did the picture meet the requirement (empty space on the right, no text, the right light)? A column of yes and no is what turns a folder of pictures into a decision.

Two rounds of this usually settle the parts that matter. Then fix those, and spend the next round on the next part.
