---
title: Benchmarks, and your own data
version: 1
---

A leaderboard answers *which model does well on average over many tasks that are not yours*. The
question you have is narrower: **which model finds the right article for your customers'
questions.** The only way to answer it is the measurement this course has been running since lesson
3, on the 24 questions the course wrote down with the articles that answer them.

Here are the two models the lab runs, side by side, with the questions each got wrong at rank 1:

```schooling-example
{
  "language": "python",
  "file": "bench.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]\ndocs = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nwl = WordLlama.load()",
      "note": "The articles as title and body, the 24 questions, and WordLlama loaded beside MiniLM."
    },
    {
      "code": "models = {\n    \"all-MiniLM-L6-v2\": embed,\n    \"WordLlama\": lambda texts: wl.embed(texts, norm=True),\n}",
      "note": "Each model as a function from a list of texts to unit-length vectors."
    },
    {
      "code": "for name, f in models.items():\n    D, Q = f(docs), f([q[\"text\"] for q in queries])\n    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]\n    first = [ids[t[0]] in q[\"relevant\"] for t, q in zip(top, queries)]\n    three = [any(ids[j] in q[\"relevant\"] for j in t) for t, q in zip(top, queries)]\n    wrong = [q[\"id\"] for q, ok in zip(queries, first) if not ok]\n    print(f\"{name:17} top 1: {sum(first)}/24  top 3: {sum(three)}/24  wrong at 1: {' '.join(wrong)}\")",
      "note": "For each model: embed both sides, rank the articles for every question, and count the questions with a relevant article first and in the top 3. List the ones wrong at rank 1."
    }
  ],
  "output": "ana@lab:~/emb$ python bench.py\nall-MiniLM-L6-v2  top 1: 19/24  top 3: 22/24  wrong at 1: q01 q08 q17 q19 q21\nWordLlama         top 1: 20/24  top 3: 24/24  wrong at 1: q02 q11 q13 q23"
}
```

## What it shows

**WordLlama put a relevant article first for 20 of the 24 questions and in the top 3 for all 24.
all-MiniLM-L6-v2 managed 19 and 22.** On these questions the static model, with no transformer at
all, did at least as well as the contextual one. That is a real result, and a surprising one if
the picture you hold is that bigger and more sophisticated always wins.

## What it does not show

Read the last column before the first. **The two models got different questions wrong.** MiniLM
missed q01, q08, q17, q19 and q21; WordLlama missed q02, q11, q13 and q23; no question is on both
lists. So the gap of one at rank 1 is not one model being better at the same thing. It is two
models with different blind spots, and four or five questions deciding the score.

Three limits follow, and each one is a reason not to generalise:

- 24 questions is small. One question is about four points of the score, and two re-worded questions
  could reverse the ranking at rank 1.
- One domain. A bookshop's help centre has short, plainly written articles in one register. Lesson 1
  showed WordLlama scoring *the dog bit the man* and *the man bit the dog* as the same text, and a
  corpus where word order matters could reverse the result.
- The articles are short. None is longer than 102 pieces, so MiniLM's limit never came into play,
  and neither did any advantage a contextual model has on long texts.

So the result is not *WordLlama is the better model*. It is **on this help centre, with these
questions, the cheaper model is good enough**, and that is the kind of statement a choice of
model should rest on. Lesson 10 adds the cost side to it, and the next section measures the speed
that makes it matter.

## Building your own set

Twenty-four questions is a start. The useful set grows from real use: the questions
customers typed that found nothing useful, each written down with the article that should have
answered it. **Keep the set beside the code, run it whenever the model, the chunking or the text
changes**, and compare models on it before comparing them on anything else. Lesson 16 uses the same
measurement to choose how many results to return.
