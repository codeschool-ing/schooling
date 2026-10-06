---
title: The prompt
version: 1
---

Lesson 1 built the smallest possible prompt: numbered sections and the question, under a one-line
instruction. That was enough to show the idea. A prompt a team would put in front of customers says
more, and every line it adds is there to make one failure less likely. `answer.py` is that prompt and
the code around it:

```schooling-example
{
  "language": "python",
  "file": "answer.py",
  "parts": [
    {
      "code": "import re\nimport sys\n\nfrom openai import OpenAI\nfrom search import conn, vector\n\nSYSTEM = \"\"\"You answer questions from Marginalia's customers, using only the numbered sources.\nCite every sentence with the number of the source it comes from, like [1].\nIf the sources do not answer the question, reply: \"I could not find that in our documents.\"\nIf two sources disagree, prefer the one updated most recently, and say so.\"\"\"\nFLOOR = 0.5\nREFUSAL = \"I could not find that in our documents.\"\nclient = OpenAI()",
      "note": "The instructions, in the system message. Each line asks for one behaviour this lesson then checks: answer from the sources, cite every sentence, say so when the sources are silent, and prefer the newer of two sources that disagree. `FLOOR` is the score lesson 6 chose."
    },
    {
      "code": "def sources_for(question, k=3, where=\"status = %s AND audience = %s\", params=(\"current\", \"public\")):\n    \"\"\"The chunks worth showing the model: filtered, and above the floor lesson 6 chose.\"\"\"\n    found = [r for r in vector(question, k, where, params) if r[3] >= FLOOR]\n    meta = {i: (u, v) for i, u, v in conn.execute(\n        \"SELECT id, updated, doc_version FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in found],))}\n    return [{\"id\": i, \"path\": p, \"text\": t, \"score\": s, \"updated\": meta[i][0], \"version\": meta[i][1]}\n            for i, p, t, s in found]",
      "note": "The search of lesson 6, filtered to current public documents, with anything under the floor dropped. The date and version of each chunk's document come from the table too, because the prompt shows them."
    },
    {
      "code": "def prompt(question, sources):\n    blocks = [f\"[{n}] {s['path']} (updated {s['updated']})\\n{s['text']}\" for n, s in enumerate(sources, 1)]\n    return \"\\n\\n\".join(blocks + [f\"Question: {question}\"])",
      "note": "Each source gets a number, its heading path and its date on one line, and its text below. The question comes last."
    }
  ]
}
```

## What the model is sent

`show_prompt.py` prints exactly what `ask` sends for one question, the system message and then the
user message:

```
ana@lab:~/rag$ python show_prompt.py "How long after my return arrives will I get the refund?"
You answer questions from Marginalia's customers, using only the numbered sources.
Cite every sentence with the number of the source it comes from, like [1].
If the sources do not answer the question, reply: "I could not find that in our documents."
If two sources disagree, prefer the one updated most recently, and say so.
---
[1] Returns and refunds policy > Refunds (updated 2026-02-02)
We refund within three working days of the return reaching our warehouse. The money goes back to
the card or account you paid with, and your bank may take another five to ten days to show it.
Delivery costs are refunded when you return the whole order; when you return part of it, they are
not.

[2] Returns and refunds policy > The return window (updated 2026-02-02)
You have 30 days from delivery to return a printed book in the condition you received it. The 30
days start on the day the carrier records the parcel as delivered, not on the day you placed the
order. For an order that arrived in several parcels, each parcel has its own 30 days.

[3] Returns and refunds policy > Items sold by marketplace sellers (updated 2026-02-02)
Items marked Sold by, followed by a seller's name, are returned to the seller and not to us. Every
seller must accept returns for at least 14 days from delivery, and many accept them for longer. The
seller's own policy is on their page. If a seller does not answer a return request within two
working days, open a claim from the order and we decide it.

Question: How long after my return arrives will I get the refund?
```

Three sources survived the filter and the floor, all from the current returns policy. Only the first
holds the answer; the other two scored above 0.5 and are about returns in general. Lesson 12 is about
what to do with sources like those. This lesson takes them as they come.

## Why each part is there

**The sources are numbered**, so that a sentence can point at one and a program can follow the
pointer. A number is better than a title for that, because a title can contain any character and a
model reproduces a short number exactly.

**Each source carries its path and its date.** The path tells the model, and anybody reading a
citation later, which document and which section a passage comes from. The date is what makes the
fourth instruction possible: a model cannot prefer the newer of two sources it cannot date.

**The question comes last.** Instructions and sources first, question at the end, so that the last
thing the model reads before it writes is what it was asked. Lesson 12 comes back to placement.

**The instructions are few and checkable.** Four lines, each describing a behaviour this lesson then
tests: answers come from the sources, every sentence is cited, silence is admitted, and conflicts are
resolved by date. An instruction nobody checks is a wish.

## What extract-1 does with it

Of the four instructions, extract-1 follows two by construction: it only ever copies sentences from
the sources, and it cites each one. It follows the third only partly, because its refusal comes from
its own similarity threshold, though it does use the refusal sentence the prompt gives it. It ignores
the fourth entirely; it has no notion of a date. A real model reads all four and follows them most of
the time, which is a different statement from always. The rest of this lesson is about the code that
checks.
