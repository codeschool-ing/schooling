---
title: Finding it before it is indexed
version: 2
---

A listing is written once and read by every question that retrieves it. That makes ingestion the
cheapest place to look at it, once, before it reaches any prompt:

```schooling-example
{
  "language": "python",
  "file": "scan.py",
  "parts": [
    {
      "code": "import json\nimport re",
      "note": "The listings as sellers submitted them."
    },
    {
      "code": "# Words that address a reader of the text rather than describe a book. A seller has no reason to\n# write them; finding them is a reason for a person to look, not proof of anything.\nSUSPECT = re.compile(r\"\\b(ignore|disregard)\\b.{0,40}\\b(question|instructions?|above|previous)\\b\"\n                     r\"|\\breply with\\b|\\b(assistant|AI|model) reading this\\b\", re.I)\nfor line in open(\"data/listings.jsonl\"):\n    listing = json.loads(line)\n    found = SUSPECT.search(listing[\"description\"])\n    print(f\"{listing['id']}  {'HOLD  ' + repr(found.group(0)) if found else 'ok'}\")",
      "note": "A pattern for text that talks to a reader instead of describing a book. A match puts the listing on hold for a person to look at; it decides nothing on its own."
    }
  ]
}
```

```
ana@vm:~/rag$ python scan.py
L01  ok
L02  ok
L03  ok
L04  HOLD  'assistant reading this'
L05  ok
L06  ok
```

**L04 is held**, on the words "assistant reading this", and the other five pass. A held listing is not
deleted and not published; it waits for a person, who sees the match and decides. Most matches will be
harmless, a seller writing "ignore the creases on the cover", and the rule costs a person a few seconds
each time.

This layer is the weakest of the four, and it is stated plainly so that nobody leans on it. A pattern
catches the phrasings somebody thought of. An injection can be written in another language, split
across fields, hidden in words that only mean something to a model, and a filter of known phrases will
miss it. The scan earns its place by catching the careless and the copied, and by producing a record:
a held listing with its match is evidence that somebody tried, which is worth knowing about a seller.

What it must never become is a gate that decides by itself what is safe. A listing that passes the scan
is a listing the scan did not recognise, nothing more.
