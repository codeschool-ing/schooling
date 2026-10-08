---
title: Headers
version: 2
---

Each source in lesson 7's prompt has a line above it: its number, the path of headings it came from,
and the date its document was updated. The number makes a citation possible, the path tells the
reader of a citation where to look, and the date is what let lesson 7 prefer the newer of two sources
that disagreed. All three earn their place. They also cost tokens, and nobody had counted how many:

```schooling-example
{
  "language": "python",
  "file": "headers.py",
  "parts": [
    {
      "code": "import json\n\nfrom context import header, pack, tokens\n\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\"))]\nheads, texts = 0, 0\nfor q in questions:\n    for n, s in enumerate(pack(q[\"question\"], where=\"status = %s\", params=(\"current\",)), 1):\n        heads += tokens(header(n, s))\n        texts += tokens(s[\"text\"])\nprint(f\"headers {heads}, texts {texts}: headers are {heads / (heads + texts):.0%} of the sources' tokens\")",
      "note": "How much of the sources' tokens, over the test set, is spent on their headers."
    }
  ]
}
```

```
ana@vm:~/rag$ python headers.py
headers 1499, texts 2380: headers are 39% of the sources' tokens
```

**39% of the tokens spent on sources were spent on headers.** Across the 30 questions, packed by this
lesson's pipeline, the headers came to 1,499 tokens and the text to 2,380. The heading paths are long:
in the first section of this lesson, the header above the payments document's gift card section
was 22 tokens before a word of the source, and compression made it worse in proportion: it shortened the text and left the header as it was.

That does not mean cutting them; it means **deciding what each part of a header is for**:

- **The number** stays. Without it there is no citation, and lesson 7's checks have nothing to check.
- **The date** stays wherever two sources may disagree, which in a corpus of policies is everywhere.
  A source without its date cannot be preferred over an older one.
- **The path** is the one to weigh. The reader of a citation needs it, but the reader of a citation
  is a person looking at the program's output, and the program has the path already: it can show it
  next to the citation without the model ever reading it. A pipeline that keeps the source list on
  its side can send the model `[1] (updated 2025-10-27)` and show the customer the full path.

The pipeline in this course keeps the full header, because lesson 7's citation check and lesson 8's
test were built on it, and changing it now would change two measured things at once. The number above
is what a team would weigh against that, and it is the kind of number that only exists if somebody
counts the parts of the prompt instead of the prompt.
