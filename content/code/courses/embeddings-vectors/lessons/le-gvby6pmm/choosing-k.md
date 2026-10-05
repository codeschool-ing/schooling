---
title: Choosing k
version: 1
---

A larger k finds more answers and hands on more text. Choosing k is choosing a point on that
trade, and both halves of it can be measured on the course's own 24 questions.

The tempting rule is *more is safer*: return ten and the right one is surely in there. The
measurement says that buys very little past the first few, and costs the same amount every time.

```schooling-example
{
  "language": "python",
  "file": "recall_k.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nimport tiktoken\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]",
      "note": "Read the 40 articles and the 24 questions, each of which carries the articles the course decided answer it."
    },
    {
      "code": "wl = WordLlama.load()\nmodels = {\"minilm\": embed, \"wordllama\": lambda t: wl.embed(t, norm=True)}\nranks = {}\nfor name, f in models.items():\n    S = f([q[\"text\"] for q in queries]) @ f(texts).T\n    ranks[name] = np.argsort(-S, axis=1)",
      "note": "Score every question against every article with both models, and keep each question's articles in order from the best score down."
    },
    {
      "code": "def found(rank, k):\n    return sum(any(ids[j] in q[\"relevant\"] for j in r[:k])\n               for r, q in zip(rank, queries))",
      "note": "A question counts as found at `k` when any of its right articles is among the first `k`."
    },
    {
      "code": "enc = tiktoken.get_encoding(\"cl100k_base\")\ntokens = np.array([len(enc.encode(t)) for t in texts])\nprint(\" k  minilm  wordllama  tokens\")\nfor k in range(1, 11):\n    t = tokens[ranks[\"minilm\"][:, :k]].sum(axis=1).mean()\n    print(f\"{k:2}  {found(ranks['minilm'], k):3}/24  {found(ranks['wordllama'], k):6}/24  {t:6.0f}\")",
      "note": "The last column is what the first `k` articles would cost to hand to a language model: their tokens in `cl100k_base`, averaged over the 24 questions."
    },
    {
      "code": "for r, q in zip(ranks[\"minilm\"], queries):\n    first = min(list(r).index(ids.index(a)) for a in q[\"relevant\"]) + 1\n    if first > 3:\n        print(f\"minilm puts the answer to {q['text']!r} at {first}\")",
      "note": "And the questions all-MiniLM-L6-v2 does not answer in its top 3: where the first right article actually landed."
    }
  ],
  "output": "ana@lab:~/emb$ python recall_k.py\n k  minilm  wordllama  tokens\n 1   19/24      20/24      55\n 2   22/24      23/24     109\n 3   22/24      24/24     162\n 4   23/24      24/24     217\n 5   23/24      24/24     272\n 6   23/24      24/24     326\n 7   23/24      24/24     379\n 8   23/24      24/24     434\n 9   23/24      24/24     488\n10   23/24      24/24     544\nminilm puts the answer to 'send books to another country' at 4\nminilm puts the answer to 'my order came in pieces' at 12"
}
```

The middle columns count questions with a right article somewhere in the first k. Lesson 3 called
the first and third rows **recall@1** and **recall@3**; this is the same measure for every k.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"A line chart of how many of the 24 questions find a right article among the first k results, for k from 1 to 10. all-MiniLM-L6-v2 finds 19 at k=1, 22 at k=2 and 23 from k=4 on. WordLlama finds 20 at k=1 and 24 from k=3 on. Both lines are flat after the first few values of k.\"><path d=\"M90 300 L680 300\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"300\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><path d=\"M90 235 L680 235\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"235\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M90 170 L680 170\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M90 105 L680 105\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"105\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><path d=\"M90 40 L680 40\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><path d=\"M90 300 L680 300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 300 L90 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"90\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">55</text><text x=\"155.6\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"155.6\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">109</text><text x=\"221.1\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"221.1\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">162</text><text x=\"286.7\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"286.7\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">217</text><text x=\"352.2\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"352.2\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">272</text><text x=\"417.8\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"417.8\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">326</text><text x=\"483.3\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><text x=\"483.3\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">379</text><text x=\"548.9\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"548.9\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">434</text><text x=\"614.4\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9</text><text x=\"614.4\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">488</text><text x=\"680\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"680\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">544</text><text x=\"385\" y=\"333\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">k, the number of articles returned</text><text x=\"90\" y=\"372\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">tokens handed on, all-MiniLM-L6-v2's top k</text><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">questions found (of 24)</text><path d=\"M90.0 170.0 L155.6 72.5 L221.1 40.0 L286.7 40.0 L352.2 40.0 L417.8 40.0 L483.3 40.0 L548.9 40.0 L614.4 40.0 L680.0 40.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"90\" cy=\"170\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"155.6\" cy=\"72.5\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"221.1\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"286.7\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"352.2\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"417.8\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"483.3\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"548.9\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"614.4\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><circle cx=\"680\" cy=\"40\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><path d=\"M90.0 202.5 L155.6 105.0 L221.1 105.0 L286.7 72.5 L352.2 72.5 L417.8 72.5 L483.3 72.5 L548.9 72.5 L614.4 72.5 L680.0 72.5\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"202.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"155.6\" cy=\"105\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"221.1\" cy=\"105\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"286.7\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"352.2\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"417.8\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"483.3\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"548.9\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"614.4\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"680\" cy=\"72.5\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><path d=\"M470 250 L500 250\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"485\" cy=\"250\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"508\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><path d=\"M470 274 L500 274\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"485\" cy=\"274\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.6\"></circle><text x=\"508\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WordLlama</text></svg>", "caption": "How many of the 24 questions find a right article in the first k results. Both curves flatten within a few steps, while the tokens handed on, in the row under the axis, keep growing with every article."}
```

## The curve flattens fast

**all-MiniLM-L6-v2 finds 19 of 24 at k = 1, 22 at k = 2, and 23 from k = 4 on.** Going from 4 to 10
finds nothing more. WordLlama reaches all 24 at k = 3 and stays there. Both curves do almost all
their climbing in the first two or three steps.

The last two lines of the output say why the curve stops where it does. *send books to another
country* has its answer at 4, which is the step from 22 to 23. *my order came in pieces* has its
answer at 12, beyond any k on the chart: raising k to 10 does not reach it, and a k large enough
to reach it would hand on twelve articles for every question to rescue one. That is a question the
model gets wrong, and k is the wrong tool for it. A second model is the right one: WordLlama has
all 24 by k = 3, and the section on reranking puts the two models to work together.

**The cost column grows in a straight line.** The articles are short, about 55 tokens each, so the
first article costs 55 tokens, three cost 162 and ten cost 544. Every one of those tokens is read
by whatever comes next:

- a language model, in the `rag` course, pays for every token of context and reads the noise as
  carefully as the answer. Ten articles where three would do is more than three times the bill for the same
  answers, and seven extra chances to quote the wrong one;
- a person, on a results page, reads the first few and stops. A screen has room for a handful
  of results, and the tenth is rarely seen;
- the next stage of the search, such as a reranker, takes time per candidate.

## A way to choose

Pick k from your own curve, not from habit. Measure found-at-k on questions with known answers, as
`recall_k.py` does, and take the smallest k after which the curve is flat. On this help centre
that is 2 or 3 for all-MiniLM-L6-v2 and 3 for WordLlama.

Two cautions keep that number honest. **24 questions is a small sample**: one question is about
four points of the total, and the step from 22 to 23 is one question. And the curve belongs to the
corpus and the model together. A help centre of 4,000 articles has more near-misses competing for
each place, so its curve climbs more slowly, and the measurement has to be made again on it.
