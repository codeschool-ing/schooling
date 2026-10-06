---
title: Packing the window
version: 1
---

The decisions of this lesson, in the order they have to happen, are one function in `context.py`:

```schooling-example
{
  "language": "python",
  "file": "context.py",
  "parts": [
    {
      "code": "\"\"\"What goes into the window, and in what order: lesson 12's decisions in one place.\"\"\"\nimport re\n\nimport tiktoken\nfrom answer import FLOOR, REFUSAL, ask\nfrom minilm import embed\nfrom search import conn, vector\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nSAME = 0.9      # two sources this similar say the same thing\nKEEP = 0.45     # a sentence this similar to the question stays in its source\nBUDGET = 200    # tokens of sources, headers included",
      "note": "The three settings this lesson measures, written where they can be found. `BUDGET` counts the sources with their headers; the instructions and the question are paid for in any case."
    },
    {
      "code": "def candidates(question, k=10, where=\"status = %s AND audience = %s\", params=(\"current\", \"public\")):\n    \"\"\"Up to K chunks above the floor, best first, with what a source header needs.\"\"\"\n    found = [r for r in vector(question, k, where, params) if r[3] >= FLOOR]\n    meta = {i: (u, v) for i, u, v in conn.execute(\n        \"SELECT id, updated, doc_version FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in found],))}\n    return [{\"id\": i, \"path\": p, \"text\": t, \"score\": s, \"updated\": meta[i][0], \"version\": meta[i][1]}\n            for i, p, t, s in found]",
      "note": "Lesson 7's `sources_for`, asking for ten instead of three: the floor, not `k`, now decides how many come back."
    },
    {
      "code": "def ends(sources):\n    \"\"\"Best first, second best last, the weakest in the middle.\"\"\"\n    return sources[0::2] + sources[1::2][::-1]\n\ndef header(n, source):\n    return f\"[{n}] {source['path']} (updated {source['updated']})\\n\"",
      "note": "`ends` puts the best source first and the second best last; `header` is the line lesson 7's prompt writes above each source."
    },
    {
      "code": "def pack(question, budget=BUDGET, k=10, **filters):\n    \"\"\"Floor, then duplicates out, then each source cut to what is about the question, then as many\n    as fit the budget, best first, and finally the strongest two at the two ends.\"\"\"\n    kept, used = [], 0\n    for s in dedupe(candidates(question, k, **filters)):\n        s = compress(question, s)\n        cost = tokens(header(0, s) + s[\"text\"])\n        if used + cost <= budget:\n            kept.append(s)\n            used += cost\n    return ends(kept)",
      "note": "The order of the steps is the point: duplicates go before anything is counted, each source is cut before it is priced, and the budget is spent best first, so a source that does not fit is always weaker than every source that did."
    },
    {
      "code": "def answer(question, **filters):\n    sources = pack(question, **filters)\n    if not sources:\n        return REFUSAL, []\n    return ask(question, sources), sources",
      "note": "The same contract as lesson 7's `answer`: nothing above the floor means the refusal, and no model call."
    }
  ]
}
```

The order is the design. Duplicates go first, so that a repeated source never takes a place another
could have had. Compression comes before pricing, so that a source is charged for the sentences it
will actually send. The budget is spent best first, so whatever does not fit is weaker than everything
that did. And the order of writing comes last, because it changes nothing but the sequence.

## One question, three windows

`three.py` builds the prompt for the gift card question three ways: the twelve nearest chunks with no
filter at all, lesson 7's three above the floor, and `pack`.

```
ana@lab:~/rag$ python three.py "How long is a gift card valid?"
twelve nearest  instructions  71  headers 248  sources 671  question 10  total 1000  (12 sources)
lesson 7        instructions  71  headers  63  sources 167  question 10  total  311  (3 sources)
packed          instructions  71  headers  62  sources 116  question 10  total  259  (3 sources)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three bars, one prompt each for the question How long is a gift card valid, split into instructions, source headers, source text and the question. Twelve nearest chunks with no filter: 1,000 tokens, of which 671 are source text and 248 headers. Lesson 7&#x27;s three above the floor: 311. Packed: 259, with 116 tokens of source text.\"><text x=\"140\" y=\"45\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">twelve nearest</text><rect x=\"150.0\" y=\"30\" width=\"27.0\" height=\"30\" fill=\"var(--wire)\"></rect><rect x=\"177.0\" y=\"30\" width=\"94.2\" height=\"30\" fill=\"var(--amber)\"></rect><rect x=\"271.2\" y=\"30\" width=\"255.0\" height=\"30\" fill=\"var(--phosphor)\"></rect><rect x=\"526.2\" y=\"30\" width=\"3.8\" height=\"30\" fill=\"var(--paper-dim)\"></rect><text x=\"537.9999999999999\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1,000 tokens, 12 sources</text><text x=\"140\" y=\"103\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">lesson 7</text><rect x=\"150.0\" y=\"88\" width=\"27.0\" height=\"30\" fill=\"var(--wire)\"></rect><rect x=\"177.0\" y=\"88\" width=\"23.9\" height=\"30\" fill=\"var(--amber)\"></rect><rect x=\"200.9\" y=\"88\" width=\"63.5\" height=\"30\" fill=\"var(--phosphor)\"></rect><rect x=\"264.4\" y=\"88\" width=\"3.8\" height=\"30\" fill=\"var(--paper-dim)\"></rect><text x=\"276.18\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">311 tokens, 3 sources</text><text x=\"140\" y=\"161\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">packed</text><rect x=\"150.0\" y=\"146\" width=\"27.0\" height=\"30\" fill=\"var(--wire)\"></rect><rect x=\"177.0\" y=\"146\" width=\"23.6\" height=\"30\" fill=\"var(--amber)\"></rect><rect x=\"200.5\" y=\"146\" width=\"44.1\" height=\"30\" fill=\"var(--phosphor)\"></rect><rect x=\"244.6\" y=\"146\" width=\"3.8\" height=\"30\" fill=\"var(--paper-dim)\"></rect><text x=\"256.42\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">259 tokens, 3 sources</text><rect x=\"150\" y=\"210\" width=\"12\" height=\"12\" fill=\"var(--wire)\"></rect><text x=\"168\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instructions</text><rect x=\"288\" y=\"210\" width=\"12\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"306\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">headers</text><rect x=\"386\" y=\"210\" width=\"12\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"404\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sources</text><rect x=\"484\" y=\"210\" width=\"12\" height=\"12\" fill=\"var(--paper-dim)\"></rect><text x=\"502\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">question</text></svg>", "caption": "One question, three windows. The instructions and the question cost the same in all three; what changes is how many sources go in and how much of each. Packing kept three sources and cut their text from 167 tokens to 116."}
```

**From 1,000 tokens to 311 to 259.** Twelve sources with no filter cost three times lesson 7's prompt,
and almost all of the difference is source text the question did not need. `pack` kept the same three
sources lesson 7 sent and cut their text from 167 tokens to 116.

## Measured, over every question

`compare.py` runs both pipelines over the 30 questions of `eval.jsonl`, through extract-1, and scores
the replies with lesson 8's rules. A reply is correct when it contains a fact of the answer, or
refuses a question the documents do not answer, and faithful when every sentence is quoted or close
to its cited source.

```
ana@lab:~/rag$ python compare.py
pipeline  correct  refused  faithful  sources  prompt
plain       24/30      4/4     30/30      2.2     247
packed      24/30      4/4     30/30      2.3     198
```

**The same 24 correct, the same 30 faithful, and 198 tokens per prompt instead of 247**, a fifth
fewer, with a budget of 200 tokens of sources. That is the measurable half: same answers, smaller
bill, shorter reading time. The half that cannot be measured here is the one the research is about,
and it points the same way: less irrelevant text, and the strongest sources at the ends. A team with
a real model runs the same comparison against it and finds out whether that half holds too.

Every setting in the function, `SAME`, `KEEP`, `BUDGET` and the floor, is a number this lesson chose
by measuring this corpus. On another corpus they are where to start, never what to keep.
