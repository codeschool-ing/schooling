---
title: Citations
version: 1
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
      "code": "def ask(question, sources):\n    reply = client.chat.completions.create(model=\"extract-1\", messages=[\n        {\"role\": \"system\", \"content\": SYSTEM},\n        {\"role\": \"user\", \"content\": prompt(question, sources)}])\n    return reply.choices[0].message.content",
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

## Two replies, with their sources

```
ana@lab:~/rag$ python answer.py "How long after my return arrives will I get the refund?"
We refund within three working days of the return reaching our warehouse. [1] Every seller must accept returns for at least 14 days from delivery, and many accept them for longer. [3] If a seller does not answer a return request within two working days, open a claim from the order and we decide it. [3]
  [1] Returns and refunds policy > Refunds, updated 2026-02-02
  [3] Returns and refunds policy > Items sold by marketplace sellers, updated 2026-02-02
```

**The answer is the first sentence, from `[1]`, the refund section.** The next two sentences are
about marketplace sellers, from `[3]`: true, cited, and nothing to do with the question. extract-1
picked them because they mention returns and timescales, and a real model given the same three
sources would be more likely to leave them out. The citations make the problem visible: a reader sees
that two thirds of the reply came from a section about marketplace sellers and can judge it.

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
