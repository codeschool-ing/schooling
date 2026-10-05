---
title: Speed on a processor
version: 1
---

With a provider, how fast the model runs is the provider's problem and a line in their pricing.
With an open model it is yours, and it decides how long the first indexing takes, how many
messages a second a pipeline keeps up with, and whether you need a graphics card at all. It is also
easy to get wrong by guessing, so measure it on the machine that will run it.

That machine, for every number below:

```
ana@lab:~/emb$ nproc
4
ana@lab:~/emb$ grep -m1 "model name" /proc/cpuinfo
model name	: Intel(R) Xeon(R) Processor @ 2.10GHz
ana@lab:~/emb$ grep -n "num_threads" /opt/emb/lib/python3.11/site-packages/minilm.py
33:_opts.intra_op_num_threads = 1
34:_opts.inter_op_num_threads = 1
```

Four processors, and **`minilm.py` uses one of them**: the two lines `grep` found tell onnxruntime
to use a single thread. That keeps the course's timings comparable with each other while other
work runs on the same machine, and it means the numbers below are what one core does. Other
processes were running during this measurement, so another run prints other numbers.

`speed.py` embeds the 150 tickets, three times for each setting, and keeps the fastest run:

```schooling-example
{
  "language": "python",
  "file": "speed.py",
  "parts": [
    {
      "code": "import json\nimport time\nfrom minilm import embed\nfrom wordllama import WordLlama\n\ntexts = [json.loads(line)[\"text\"] for line in open(\"data/tickets.jsonl\")]\nwl = WordLlama.load()",
      "note": "The 150 tickets, and both models loaded before any timing starts."
    },
    {
      "code": "def rate(f, items, runs=3):\n    best = float(\"inf\")\n    for _ in range(runs):\n        t = time.perf_counter()\n        f(items)\n        best = min(best, time.perf_counter() - t)\n    return len(items) / best",
      "note": "Texts per second for one embedding function: run it three times and keep the fastest, which is the run least disturbed by anything else."
    },
    {
      "code": "minilm = []\nfor b in (1, 8, 32, 150):\n    minilm.append(rate(lambda t: embed(t, batch=b), texts))\n    print(f\"all-MiniLM-L6-v2  batch {b:3}           {minilm[-1]:7.0f} texts/s\")",
      "note": "MiniLM at four batch sizes, the last of them all 150 tickets at once."
    },
    {
      "code": "minilm.append(rate(lambda t: embed(t, batch=32), sorted(texts, key=len)))\nprint(f\"all-MiniLM-L6-v2  batch  32, sorted   {minilm[-1]:7.0f} texts/s\")\nstatic = rate(lambda t: wl.embed(t, norm=True), texts)\nprint(f\"WordLlama         batch  64           {static:7.0f} texts/s\")",
      "note": "Batch 32 again, with the tickets sorted by length first, and WordLlama at its default batch of 64."
    },
    {
      "code": "fastest = max(minilm)\nprint(f\"WordLlama / fastest MiniLM: {static / fastest:.0f} times\")\nprint(f\"a million texts at the fastest MiniLM rate: {1e6 / fastest / 60:.0f} minutes\")",
      "note": "The two numbers the section uses: how many times faster the static model was than the fastest MiniLM line, and how long a million texts would take at that MiniLM rate."
    }
  ],
  "output": "ana@lab:~/emb$ python speed.py\nall-MiniLM-L6-v2  batch   1               222 texts/s\nall-MiniLM-L6-v2  batch   8               245 texts/s\nall-MiniLM-L6-v2  batch  32               200 texts/s\nall-MiniLM-L6-v2  batch 150               193 texts/s\nall-MiniLM-L6-v2  batch  32, sorted       231 texts/s\nWordLlama         batch  64             21776 texts/s\nWordLlama / fastest MiniLM: 89 times\na million texts at the fastest MiniLM rate: 68 minutes"
}
```

## Batching on one thread

The common advice is that larger batches are faster, and on a graphics card or many threads it
usually holds: one call does many texts' arithmetic at once. **Here, on one thread, batch 1 ran at
292 texts a second and batch 150 at 198.** Batching saves the overhead of each call, which is small,
and costs **padding**, which is not. A batch is one rectangle as wide as its longest text, so every
shorter ticket in it is filled out with `[PAD]` pieces, and the transformer does the full arithmetic
on every one of them before the mask throws the result away. The larger the batch, the more likely
it holds one long ticket that makes everything else in it pay.

**Sorting the texts by length before batching removes most of the padding**: batch 32 went from 209
texts a second to 309, the fastest MiniLM line. sentence-transformers sorts by length inside
`encode` for exactly this reason and hands the vectors back in your order; a hand-written loop has
to do it on purpose.

## The static model

**WordLlama embedded 25,561 tickets a second**, about 83 times the fastest MiniLM line. There is no
transformer to run: each token's vector is looked up in a table and averaged, which is the
difference lesson 1 drew between a static model and a contextual one. The previous section found
it as accurate as MiniLM on the help centre's questions, so here the cheaper model is also the
much faster one. Lesson 10 measures static models further and asks what they give up.

## What the numbers are for

At 309 texts a second, the 40 articles take well under a second and a million documents take
about 54 minutes of one core. That arithmetic, texts divided by measured rate, is how to size a
re-indexing job before starting it, and lesson 18 uses it for the bill. Measure with your own
texts: the tickets are short, and a model's time grows with the length of what it reads, up to the
limit where it stops reading.
