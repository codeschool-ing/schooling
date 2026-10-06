---
title: Duplicates
version: 1
---

A company writes the same rule in more than one place. Marginalia's returns policy has a section on
e-books and audiobooks, and the document about e-books and audiobooks has its own; both say when an
audiobook can be refunded. Both are current, both are public, and a search for that question finds
both, near the top. Sending both buys nothing: the second copy says what the first said, in the
place of a source that might have said something else.

`dedupe` walks the sources best first and drops one that is too similar to a source already kept:

```schooling-example
{
  "language": "python",
  "file": "context.py",
  "parts": [
    {
      "code": "def dedupe(sources, same=SAME):\n    \"\"\"Drop a source that says what a better one already said.\"\"\"\n    if not sources:\n        return []\n    v = embed([s[\"text\"] for s in sources])\n    kept = []\n    for i in range(len(sources)):\n        if all(v[i] @ v[j] < same for j in kept):\n            kept.append(i)\n    return [sources[i] for i in kept]",
      "note": "Walk the sources best first, and keep one only if it is less than `SAME`, 0.9, similar to every source already kept. A source that repeats a better one goes; the better one stays, because it came first."
    }
  ]
}
```

```
ana@lab:~/rag$ python alike.py "When can an audiobook be refunded?"
0.902  Returns and refunds policy > E-books and audiobooks
0.894  E-books and audiobooks > Audiobooks
0.831  Returns and refunds policy > E-books and audiobooks
0.812  E-books and audiobooks > Refunds for e-books
0.778  E-books and audiobooks > Refunds for e-books
0.666  Returns and refunds policy > Damaged, faulty and wrong items
0.626  Terms of sale > 8. Digital content
0.622  Returns and refunds policy > Damaged, faulty and wrong items
0.610  Returns and refunds policy > The return window
0.585  Returns and refunds policy > Damaged, faulty and wrong items
after dedupe:
0.902  Returns and refunds policy > E-books and audiobooks
0.831  Returns and refunds policy > E-books and audiobooks
0.778  E-books and audiobooks > Refunds for e-books
0.666  Returns and refunds policy > Damaged, faulty and wrong items
0.626  Terms of sale > 8. Digital content
0.622  Returns and refunds policy > Damaged, faulty and wrong items
0.610  Returns and refunds policy > The return window
0.585  Returns and refunds policy > Damaged, faulty and wrong items
```

**Ten sources passed the floor, and two were dropped**: the audiobooks section of the e-books document,
0.894 to the question, and one of the two chunks of its section on refunds for e-books, 0.812. Each
was 0.9 or more similar to a chunk of the returns policy that scored higher and was already kept. The
returns policy said it first, so the returns policy stays.

The threshold is the decision. At 0.9 only near-copies go, and across all 30 questions it is rare:

```
ana@lab:~/rag$ python removed.py
5 of 115 sources removed as duplicates, over 30 questions
```

Lower the threshold and it starts removing sources that
overlap without repeating, like a policy and an exception to it, which is the pair lesson 7 needed
both of. **A duplicate is two sources a reader could swap without noticing**, and the threshold should
remove only those. Lesson 11's Haystack duplicate, the same chunk stored twice with different
metadata, is the case it removes without any doubt: its similarity to itself is 1.

Two kinds of repetition are not this function's job. A superseded version of a document is not a
duplicate, it is a contradiction, and lesson 6's status filter removes it before it gets this far.
And two chunks cut from the same section, which the gift card prompt had as sources 2 and 3, are
neighbours rather than repeats; they are next to each other because the answer needed both.
