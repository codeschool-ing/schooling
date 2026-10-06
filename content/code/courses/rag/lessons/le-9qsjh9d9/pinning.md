---
title: Pinning what must survive
version: 1
---

If the details that matter are the ones a summary drops, they should not go through the summary.
**Pinning** keeps certain sentences word for word, and summarises only what is left:

```schooling-example
{
  "language": "python",
  "file": "compact.py",
  "parts": [
    {
      "code": "\"\"\"Making a long conversation short: pin what must survive word for word, summarise the rest, keep the\nlatest turns as they were.\"\"\"\nimport re\n\nimport tiktoken\nfrom memory import ORDER\nfrom openai import OpenAI",
      "note": "A sentence is pinned when it carries an order number or one of a few words that mark a choice. The rule is written down beside the code, so it can be read, argued with and tested."
    },
    {
      "code": "def pinned(turns):\n    return [s for t in turns for s in sentences(t) if PIN.search(s)]",
      "note": "Pinned sentences are kept word for word, never summarised."
    },
    {
      "code": "def compact(turns, words=30, keep=KEEP):\n    \"\"\"The pinned sentences of the older turns, a summary of what is left of them, and the last KEEP\n    turns as they were.\"\"\"\n    older, recent = turns[:-keep], turns[-keep:]\n    pins = pinned(older)\n    rest = [s for t in older for s in sentences(t) if s not in pins]\n    return {\"pinned\": pins, \"summary\": summarise(rest, words) if rest else \"\", \"recent\": recent}",
      "note": "The older turns are split: what is pinned stays, the rest goes to the summariser. The last three turns stay as they were, because the next reply is most likely to be about them."
    }
  ]
}
```

```
ana@lab:~/rag$ python compacted.py
pinned:
   Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.
   Please write to me by email only.
   For Persuasion I would like a replacement, not a refund.
   For Middlemarch I want my money back.
   Also, I am moving house next week, so the replacement should go to Rua das Flores 120, Curitiba.
summary:
   The order had two books. The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. I have photographs of the damaged cover next to the box.
recent:
   Do I need to send the damaged copy back to you?
   How do I send back Mansfield Park?
   How long will the refund for Middlemarch take?
148 tokens, essentials 6/6
```

**Six of six, in 148 tokens**, against 182 for the turns themselves and four of six for the best
summary. Five sentences were pinned: the one with the order number, the email-only request, the two
choices about the books, and the new address. The summary covered what was left, and the last three
turns stayed as they were.

The saving here is modest, 34 tokens, because Beatriz writes short messages and the pinned sentences
are most of what she said. In a conversation with long messages, pasted text or the assistant's own
replies, the summarised part is most of the history and the pinned part stays small. What does not
change is the result: **the facts a rule can recognise survive because they never depended on the
summariser.**

The rule is the weak point and should be treated as code. It recognises an order number by its exact
shape, which is reliable, and a choice by a handful of words, `only`, `please`, `would like`, `want`,
`instead`, `should go to`, which is a guess about how customers write. It caught all five here; it will
miss a choice written another way, and pin sentences that only look like choices. A team using it
writes conversations that test it, exactly as the essentials test the summary. A model can do the
pinning too, by being asked for named fields rather than a paragraph, which makes it a structured
extraction with a list to check against, rather than a summary to hope about.
