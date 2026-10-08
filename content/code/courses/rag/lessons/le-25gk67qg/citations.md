---
title: Citations
version: 2
---

A reply with `[1]` and `[3]` in it is half a citation. The other half is what a reader sees: a link
or a footnote saying which document, which section and how current it is. Turning the numbers into
that is the program's job, because the model only knows the numbers it was given.

```schooling-example
{
  "language": "python",
  "file": "answer.py",
  "parts": [
    {
      "code": "def ask(question, sources):\n    reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n        {\"role\": \"system\", \"content\": SYSTEM},\n        {\"role\": \"user\", \"content\": prompt(question, sources)}])\n    return reply.choices[0].message.content",
      "note": "One call, the system message and the numbered sources. Any OpenAI-compatible model can be swapped in by name."
    },
    {
      "code": "def answer(question, **filters):\n    \"\"\"The reply and its sources; with no source above the floor, the refusal, and no model call.\"\"\"\n    sources = sources_for(question, **filters)\n    if not sources:\n        return REFUSAL, []\n    return ask(question, sources), sources",
      "note": "With nothing above the floor, the refusal is returned by the code and the model is never called. The section on refusing shows why the instruction alone is not enough."
    },
    {
      "code": "def citations(reply, sources):\n    \"\"\"Each [n] in the reply, with the source it points at, or None if there is no such source.\"\"\"\n    return [(int(n), sources[int(n) - 1] if 0 < int(n) <= len(sources) else None)\n            for n in re.findall(r\"\\[(\\d+)\\]\", reply)]",
      "note": "Every `[n]` in the reply, paired with the source it points at. A number with no source behind it is kept as `None`, because a citation to nothing is a finding, not something to drop."
    },
    {
      "code": "if __name__ == \"__main__\":\n    reply, sources = answer(sys.argv[1])\n    print(reply)\n    shown = set()\n    for n, s in citations(reply, sources):\n        if n not in shown:\n            shown.add(n)\n            print(f\"  [{n}] {s['path']}, updated {s['updated']}\" if s else f\"  [{n}] points at no source\")",
      "note": "Run as a program: the reply, then each source it cited, once, with its path and date."
    }
  ]
}
```

## A reply, with its sources

```
ana@vm:~/rag$ python answer.py "How long after my return arrives will I get the refund?"
According to [1], the money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. This means that the refund processing time is at least 5-10 days after the return reaches the warehouse.

However, [2] states that the return window starts on the day the carrier records the parcel as delivered, not on the day you placed the order. This implies that the refund processing time may be shorter than 5-10 days, as it depends on when the carrier records the parcel as delivered.

To clarify, I would recommend checking the seller's policy, as mentioned in [3], as they may have a different return window and refund processing time.
  [1] Returns and refunds policy > Refunds, updated 2026-02-02
  [2] Returns and refunds policy > The return window, updated 2026-02-02
  [3] Returns and refunds policy > Items sold by marketplace sellers, updated 2026-02-02
```

**The reply cites all three sources, and the answer is in none of its sentences.** The refund
section, `[1]`, says two things: Marginalia refunds within three working days of the return reaching
the warehouse, and the bank may take another five to ten days. The model quoted the second and left
out the first, which is the one the customer asked about. Then it drew a conclusion of its own, *at
least 5-10 days after the return reaches the warehouse*, which no source says and which is wrong.
Then it brought in the return window from `[2]` and the marketplace sellers from `[3]`, true and
nothing to do with a refund.

The citations are what make this visible. A reader sees which sentences came from where, and the
sentences that cite nothing are the ones to doubt first. The next section turns that reading into a
program.

The printed footnotes are what a support assistant would render as links. They carry the path and
the date, so a customer reading *updated 2026-02-02* knows the rule is this year's, and a support lead
reading a complaint can open the exact section.

## What a citation should identify

| part | why |
| --- | --- |
| the document | so the reader can open it |
| the section, or the clause | so the reader does not have to search the document |
| the version or the date | so the reader knows it was in force |
| a link that resolves | so the citation is used, not admired |

A citation that names only a document is better than nothing and much worse than one that names the
section: lesson 2 found that legal readers need the clause, and the section on quoting below finds it.

## Citation is not decoration

Two habits turn citations into something people trust and then stop reading. **Citing a source the
reply did not use**, a common failure when a model is told to cite and pads the list. And **citing
the right source for the wrong sentence**, which looks perfect on screen. Both are detectable by a
program, and the next section writes it.
