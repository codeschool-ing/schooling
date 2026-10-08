---
title: How often questions repeat
version: 2
---

Lesson 9 called a semantic cache added before measuring repeated questions premature. Here is the
measurement:

```schooling-example
{
  "language": "python",
  "file": "repeats.py",
  "parts": [
    {
      "code": "import collections\nimport json\nimport re\n\nLOG = [json.loads(line) for line in open(\"data/querylog.jsonl\")]\nnorm = lambda t: re.sub(r\"[^a-z0-9 ]\", \"\", t.lower()).strip()\nprint(f\"{len(LOG)} questions, {len({q['text'] for q in LOG})} distinct as typed, \"\n      f\"{len({norm(q['text']) for q in LOG})} after lower-casing and dropping punctuation, \"\n      f\"{len({q['topic'] for q in LOG})} topics\")\nfor text, n in collections.Counter(q[\"text\"] for q in LOG).most_common(5):\n    print(f\"{n:4}  {text}\")",
      "note": "How many of the 500 questions are different, as typed and after the lightest normalisation, and the five asked most often."
    }
  ]
}
```

```
ana@vm:~/rag$ python repeats.py
500 questions, 40 distinct as typed, 38 after lower-casing and dropping punctuation, 12 topics
  41  how many days do I have to return a printed book?
  34  how long do I have to return a book
  32  How many days do I have to return a printed book?
  32  Can I still return a book I got 3 weeks ago?
  28  return window for books
```

**500 questions, 40 distinct as typed, 38 once case and punctuation are ignored, 12 topics.** The most
common phrasing was asked 41 times, and the five most common are all about the return window.

That is far more repetition than a real queue has, and the reason is in the log's own header: it was
drawn from forty phrasings the course wrote. A real support log has the same head, a few questions
asked constantly, and a long tail of questions asked once, with typos, in other languages, with an
order number in them. **The shape is what transfers**, not the numbers: a team measures its own log the
same way, distinct questions over all questions, before deciding a cache is worth having, and expects a
much smaller share than 92%.

The three numbers also say which kind of cache could help. Forty distinct texts and thirty-eight after
normalising: an **exact** cache, matching the same words, catches nearly everything a normalising one
does. Thirty-eight against twelve topics: a cache that matched **meaning** could, in principle, answer
with twelve calls instead of thirty-eight. The next two sections try both.
