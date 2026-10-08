---
title: What gets embedded
version: 2
---

Lesson 4 chose where to cut. Before a chunk becomes a vector there is one more choice, and it is
easy to make without noticing: **what text the embedding model actually reads.** The obvious answer
is the chunk's text. The better answer, measured below, is the chunk's text with its heading path in
front of it.

## The chunk's own text is not enough

Lesson 2 met the problem. The sentence "A key may make 120 requests per minute" lives under the
heading *Rate limits*, and the question asked about the rate limit; once the chunk is cut away from
its heading, nothing in it uses the words the question used. Lesson 4 showed the general version: a
chunk from the damaged-books paragraph says *a book* and *14 days* and never says it is about
Marginalia's returns policy.

The heading path from lesson 4, *Returns and refunds policy > Damaged, faulty and wrong items*, is
exactly the missing context, and it costs a dozen words. `header.py` embeds the structured chunks of
lesson 4 twice, once as text alone and once with the path on the line above, and runs the 26
answerable questions against each:

```schooling-example
{
  "language": "python",
  "file": "header.py",
  "parts": [
    {
      "code": "import json\n\nfrom chunking import load, structured\nfrom vectors import embed\n\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.split())\nqv = embed([q[\"question\"] for q in questions])",
      "note": "The 26 answerable questions, embedded once, as in lesson 4's `compare.py`."
    },
    {
      "code": "for size in (60, 120):\n    chunks = [(path, text) for _, body in load().values() for path, text in structured(body, size)]\n    for label, inputs in ((\"text only\", [t for _, t in chunks]),\n                          (\"path + text\", [p + \"\\n\" + t for p, t in chunks])):\n        scores = qv @ embed(inputs).T\n        found = sum(any(f in norm(chunks[i][1]) for i in s.argsort()[::-1][:3] for f in q[\"facts\"])\n                    for q, s in zip(questions, scores))\n        print(f\"structured {size:3}, {label:12} found {found}/{len(questions)}\")",
      "note": "Each size embedded twice, as text alone and with the heading path on the line above. The facts are looked for in the text alone either way, so the path cannot be what is found."
    }
  ]
}
```

```
ana@vm:~/rag$ python header.py
structured  60, text only    found 24/26
structured  60, path + text  found 26/26
structured 120, text only    found 25/26
structured 120, path + text  found 25/26
```

**With the path in front, the 60-word chunks found every answer**, up from 24. The 120-word chunks
stayed at 25: a larger chunk already carries more of its own context, so the path adds less. The
smaller chunks gain most because they lose most when cut.

## The decision this course makes

From here on, the index holds **structured chunks of up to 60 words, embedded with their heading
path**. Lesson 4's table gave structured 60 the cheapest context of the strategies that found more
than 15 answers, 170 tokens a question, and the path takes it to 26 of 26. It is the best result in
either lesson, on both counts.

Three details of how it is done matter more than they look.

**The path is embedded, and stored apart.** The text sent to the embedding model is `path + "\n" +
text`, and the database keeps `path` and `text` in separate columns. The prompt in lesson 7 can then
print the path as a source header, once, instead of repeating it inside every chunk's text.

**The question is embedded as it is.** Nothing is added to the question to make it look like a
chunk. The two are compared as they are, which works because the path is a few words beside a much
longer text and moves the chunk's vector towards its topic rather than towards a format.

**The same model, always.** A chunk embedded with `all-minilm` can only be compared with a question
embedded with `all-minilm`. Vectors from two models live in different spaces, and comparing them
produces numbers that look like similarities and mean nothing. The table in this lesson records the
model beside every vector, and the check at the end of the lesson refuses an index with more than
one.

## Other things people put in front

The heading path is the cheapest form of what is sometimes called **contextual chunk headers**. Two
more elaborate versions exist. One puts the document's title and a one-line summary of the document
in front of every chunk. Another, which Anthropic published as *contextual retrieval*, has a language
model write a sentence or two for each chunk explaining where it sits in the whole document, and
embeds that with the chunk. Both need a model call per chunk at indexing time, 137 of them for this corpus,
and neither was run here. The measurement above is the argument for trying the cheap
version first: on this corpus it closed the gap entirely.
