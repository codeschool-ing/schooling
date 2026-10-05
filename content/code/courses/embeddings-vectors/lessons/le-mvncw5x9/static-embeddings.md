---
title: Static embeddings
version: 1
---

Every model so far in this lesson runs a network over each text: the words go in, a stack of layers
works on them, and a vector comes out. It is easy to conclude that this is what an embedding model
*is*. **A static model has no layers to run at all.** It is a table with one row per token, and the
vector of a text is the average of its tokens' rows. Lesson 1 introduced WordLlama as one; this
section opens it and measures what the missing layers buy and cost.

```schooling-example
{
  "language": "python",
  "file": "static.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom wordllama import WordLlama\n\nwl = WordLlama.load()\nprint(wl.embedding.shape, wl.embedding.dtype)",
      "note": "`wl.embedding` is the model: a NumPy array with one row per token of the vocabulary."
    },
    {
      "code": "text = \"Is there a cheaper postage option for a single paperback?\"\nids = wl.tokenizer.encode(text, add_special_tokens=False).ids\nv = wl.embedding[ids].mean(axis=0)\nv /= np.linalg.norm(v)",
      "note": "Do by hand what `embed()` does: split the sentence into token ids, take their rows, average them, and divide by the length."
    },
    {
      "code": "print(len(ids), \"tokens\")\nprint(\"same as embed():\", np.allclose(v, wl.embed(text, norm=True)[0], atol=1e-6))",
      "note": "Compare the hand-made vector with the library's, allowing for rounding in the last digits."
    }
  ]
}
```

```
ana@lab:~/emb$ python static.py
(32000, 256) float32
14 tokens
same as embed(): True
ana@lab:~/emb$ ls -l /opt/emb/lib/python3.11/site-packages/wordllama/weights/ /opt/emb/share/all-MiniLM-L6-v2/model.onnx
-rw-r--r-- 1 root root 90387606 Oct  5 13:23 /opt/emb/share/all-MiniLM-L6-v2/model.onnx

/opt/emb/lib/python3.11/site-packages/wordllama/weights/:
total 16004
-rw-r--r-- 1 root root 16384096 Oct  5 13:21 l2_supercat_256.safetensors
```

**The table has 32000 rows of 256 numbers**, one row for every token in WordLlama's vocabulary.
Looking up the 14 tokens of the sentence, averaging their rows and dividing by the length gives
exactly what `embed()` returns: `same as embed(): True`. That is the whole model. The file on disk
is 16384096 bytes, which is 32000 × 256 × 2 bytes plus a small header: it stores each number in two
bytes, and the loader widens them to the `float32` the first line printed. all-MiniLM-L6-v2's
`model.onnx` is 90387606 bytes, about five and a half times larger, and it is mostly the weights of
the six layers WordLlama does not have.

WordLlama's README, inside the package the lab installed, says where the table came from: it
started from the token table of a large language model and was then trained, on a single GPU, as a
model with no context. Lesson 1 showed the price of having no context: *the dog bit the man* and
*the man bit the dog* get the same vector, because an average does not know about order.

## What it buys: speed

`speed.py` embeds the 150 customer messages in `tickets.jsonl` with both models, five times each,
and keeps the fastest run, so that a moment when the machine was busy does not count.

```schooling-example
{
  "language": "python",
  "file": "speed.py",
  "parts": [
    {
      "code": "import json\nimport time\nfrom minilm import embed\nfrom wordllama import WordLlama\n\ntexts = [t[\"text\"] for t in map(json.loads, open(\"data/tickets.jsonl\"))]\nwl = WordLlama.load()",
      "note": "The 150 ticket texts, and WordLlama loaded once, outside the timing."
    },
    {
      "code": "def best(f, runs=5):\n    times = []\n    for _ in range(runs):\n        t = time.perf_counter()\n        f()\n        times.append(time.perf_counter() - t)\n    return min(times)",
      "note": "Run a function five times and keep the fastest, so a moment when the machine was busy does not count against a model."
    },
    {
      "code": "m = best(lambda: embed(texts))\nw = best(lambda: wl.embed(texts, norm=True))\nprint(f\"{len(texts)} texts\")\nprint(f\"minilm     {m * 1000:7.1f} ms {len(texts) / m:8.0f} texts/s\")\nprint(f\"wordllama  {w * 1000:7.1f} ms {len(texts) / w:8.0f} texts/s\")\nprint(f\"wordllama is {m / w:.0f} times faster\")",
      "note": "Time both models on the same texts and print milliseconds, texts per second and the ratio."
    }
  ]
}
```

```
ana@lab:~/emb$ nproc; grep -m1 "model name" /proc/cpuinfo
4
model name	: Intel(R) Xeon(R) Processor @ 2.10GHz
ana@lab:~/emb$ python speed.py
150 texts
minilm       723.6 ms      207 texts/s
wordllama      5.7 ms    26489 texts/s
wordllama is 128 times faster
```

**WordLlama embedded the 150 messages 128 times faster**: 5.7 ms against 723.6 ms, or 26489 texts a
second against 207. `minilm.py` runs the model on one thread, and this machine has four cores. Even
a perfect fourfold gain from using all of them would leave MiniLM about 32 times slower, so the gap
is a property of the two models, not of the setting.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three pairs of bars comparing all-MiniLM-L6-v2 with WordLlama on this machine. Texts embedded per second: MiniLM 207, WordLlama 26489. Help-centre questions with a right article in the top three, of 24: MiniLM 22, WordLlama 24. Test tickets labelled correctly by the nearest training ticket, of 50: MiniLM 46, WordLlama 40.\"><rect x=\"470\" y=\"18\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"25\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><rect x=\"620\" y=\"18\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"25\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WordLlama</text><text x=\"30\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">texts embedded per second</text><rect x=\"30\" y=\"74\" width=\"4.4\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"42.4\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">207</text><rect x=\"30\" y=\"98\" width=\"560\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"598\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">26489</text><text x=\"30\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">questions with a right article in the top 3, of 24</text><rect x=\"30\" y=\"160\" width=\"513.3\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"551.3\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">22</text><rect x=\"30\" y=\"184\" width=\"560\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"598\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">24</text><text x=\"30\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">test tickets labelled right, of 50</text><rect x=\"30\" y=\"246\" width=\"560\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"598\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">46</text><rect x=\"30\" y=\"270\" width=\"487\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"525\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">40</text><text x=\"690\" y=\"316\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each row is scaled to its own largest value</text></svg>", "caption": "Measured on this machine with the course's data. WordLlama is two orders of magnitude faster and holds its own on the short help-centre questions; on whole-sentence tickets it gets six fewer right."}
```

A lookup and an average cost almost nothing next to six layers in which every piece looks at every
other. That is what makes static models fit where a transformer does not: a first pass over
millions of documents, removing near-duplicates, a phone, or a server with no GPU and a tight
budget.

## What it costs: measured on the course's data

Speed is only worth something if the vectors still do the job. `quality.py` measures two jobs with
both models. The first is the search of lesson 3: for each of the 24 questions in `queries.jsonl`,
does a right article come first, or in the top three? The second is a plain classifier for the 50
test tickets, which gives each one the label of the most similar of the 100 training tickets. Lesson
4 builds it, and better ones; this one is enough to compare two models.

```schooling-example
{
  "language": "python",
  "file": "quality.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nwl = WordLlama.load()\nmodels = {\"minilm\": embed, \"wordllama\": lambda t: wl.embed(t, norm=True)}\nrows = lambda f: [json.loads(l) for l in open(f)]\nhelp, queries, tickets = rows(\"data/help.jsonl\"), rows(\"data/queries.jsonl\"), rows(\"data/tickets.jsonl\")\ntrain = [t for t in tickets if t[\"split\"] == \"train\"]\ntest = [t for t in tickets if t[\"split\"] == \"test\"]\nids = [h[\"id\"] for h in help]",
      "note": "Both models behind one function each, so the measurement is written once. The articles, the 24 questions, and the tickets split into the 100 to learn from and the 50 to test on."
    },
    {
      "code": "for name, f in models.items():\n    D = f([h[\"title\"] + \". \" + h[\"body\"] for h in help])\n    Q = f([q[\"text\"] for q in queries])\n    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]\n    r1 = sum(ids[t[0]] in q[\"relevant\"] for t, q in zip(top, queries))\n    r3 = sum(any(ids[i] in q[\"relevant\"] for i in t) for t, q in zip(top, queries))",
      "note": "The search: every question against every article, the three best for each, and how many questions had a right article first and in the top three."
    },
    {
      "code": "    A, B = f([t[\"text\"] for t in train]), f([t[\"text\"] for t in test])\n    near = (B @ A.T).argmax(axis=1)\n    ok = sum(train[j][\"label\"] == t[\"label\"] for j, t in zip(near, test))\n    print(f\"{name:10} top-1 {r1}/24  top-3 {r3}/24  tickets {ok}/50\")",
      "note": "The classifier: each test ticket takes the label of the most similar training ticket. Count how many got their own label."
    }
  ]
}
```

```
ana@lab:~/emb$ python quality.py
minilm     top-1 19/24  top-3 22/24  tickets 46/50
wordllama  top-1 20/24  top-3 24/24  tickets 40/50
```

**On the search, WordLlama did as well as MiniLM or better**: 20 against 19 at the top, 24 against
22 in the top three. **On the tickets it got 6 fewer right**, 40 of 50 against 46. Two results in
opposite directions, from data written for this course, and both small enough that one question or
one ticket moves them. So look at the tickets themselves:

```schooling-example
{
  "language": "python",
  "file": "misses.py",
  "parts": [
    {
      "code": "import json\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nwl = WordLlama.load()\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\ntrain = [t for t in tickets if t[\"split\"] == \"train\"]\nA = {\"minilm\": embed([t[\"text\"] for t in train]),\n     \"wordllama\": wl.embed([t[\"text\"] for t in train], norm=True)}\nfor t in tickets:\n    if t[\"id\"] not in (\"t026\", \"t120\"):\n        continue\n    print(f\"{t['id']} [{t['label']}] {t['text']}\")\n    for name, f in ((\"minilm\", embed), (\"wordllama\", lambda x: wl.embed(x, norm=True))):\n        n = train[int((A[name] @ f([t[\"text\"]])[0]).argmax())]\n        print(f\"  {name:10} [{n['label']}] {n['text']}\")",
      "note": "Two test tickets WordLlama labelled wrongly and MiniLM labelled rightly. For each, print the nearest training ticket according to each model, with its label."
    }
  ]
}
```

```
ana@lab:~/emb$ python misses.py
t026 [shipping] Is there a cheaper postage option for a single paperback?
  minilm     [shipping] Is free postage still over 40 or did that change?
  wordllama  [returns] Can I swap the paperback for the hardcover?
t120 [account] My wishlist is empty after I signed in on my laptop.
  minilm     [account] My reading lists disappeared from my profile.
  wordllama  [ebooks] My e-book library is empty on my new tablet.
```

**WordLlama matched on a shared word and missed the meaning.** A question about cheaper postage for
a paperback went to a ticket about swapping a paperback for a hardcover. A wishlist that is empty
after signing in went to an e-book library that is empty on a tablet. The words *paperback* and
*empty* dominate an average of a dozen tokens. MiniLM, whose layers combine the words before the
average, found tickets that share the situation instead: postage, and lists that disappeared from
a profile.

The help-centre questions are short and their key words name the topic, which is the case an
average handles well. The tickets are whole sentences whose meaning is in how the words combine,
and that is where the layers earn their cost.

## Model2Vec, described and not run

WordLlama is one way to make a static model. **Model2Vec** is another: it takes an existing sentence
transformer, runs every token of its vocabulary through it once, and keeps the outputs as the table,
shrunk with principal component analysis. The result inherits some of what the transformer knew,
including multilingual versions. WordLlama 0.4 can load them with `WordLlama.load_m2v(...)`,
according to its own README. The models are hosted on Hugging Face, out of reach from this machine,
so none was loaded or measured here.
