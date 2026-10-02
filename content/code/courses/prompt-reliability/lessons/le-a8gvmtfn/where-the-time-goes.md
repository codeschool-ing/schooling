---
title: Where the time goes
version: 1
---

The intuitive picture is that a longer prompt is a slower prompt: more to send, more to read, a
longer wait. **For the wait a person feels, the length of the answer matters far more than the
length of the prompt**, and the lab can show why, because its latencies are arithmetic.

## The stand-in's clock

The stand-in does not measure how long a call takes. `promptlab/model.py` computes a latency for
every call from a handful of declared numbers, so that two runs of the same prompt print the same
thing:

```
ana@lab:~/triage$ grep -n "^LATENCY" promptlab/model.py
23:LATENCY = {"per_call": 300, "per_input": 0.4, "per_cached": 0.04, "per_output": 20.0, "jitter": 150}
```

Each call costs 300 ms however small it is, 0.4 ms for every input token, 20 ms for every output
token, and up to 150 ms of jitter that depends on the prompt. **These are the course's numbers, not
any provider's.** What they copy is a shape. A model reads its whole input in one pass that runs in
parallel, and then writes its answer one token at a time, each token waiting for the one before it,
which is how the decoder in *Attention Is All You Need* (Vaswani and others, 2017) generates text.
OpenAI's published guide to latency optimisation makes the practical point: it lists generating
fewer tokens among its first principles, and says that cutting input tokens usually helps far
less.

## Three prompts, timed

`pl latency` summarises a run's latencies, and here are three prompts from earlier lessons over the
same forty messages:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/v8.jsonl
40 calls, prompt d0591569, written to runs/v8.jsonl
ana@lab:~/triage$ pl latency runs/v2.jsonl
calls 40
p50 1186 ms   p95 1397 ms   max 1468 ms
output tokens: mean 39.9, max 50
ana@lab:~/triage$ pl latency runs/v3.jsonl
calls 40
p50 1230 ms   p95 1341 ms   max 1371 ms
output tokens: mean 37.4, max 46
ana@lab:~/triage$ pl latency runs/v8.jsonl
calls 40
p50 1238 ms   p95 1450 ms   max 1503 ms
output tokens: mean 38.4, max 50
```

`p50` is the median: half the calls were faster. `p95` is the time that 95 in a hundred calls beat,
which on forty calls means only two were slower. `max` is the single slowest.

Now the per-call tokens of the first two:

```
ana@lab:~/triage$ pl cost runs/v2.jsonl | head -n 5
tokens          count   per call
input            3139       78.5
cache_read          0        0.0
cache_write         0        0.0
output           1595       39.9
ana@lab:~/triage$ pl cost runs/v3.jsonl | head -n 5
tokens          count   per call
input            9539      238.5
cache_read          0        0.0
cache_write         0        0.0
output           1497       37.4
```

`v3-examples` sends three times the input of `v2-json`, 238.5 tokens a call against 78.5, and its
median is only 44 ms higher. Its p95 is lower, 1341 ms against 1397, because it writes less: 37.4
output tokens a call against 39.9, and a maximum of 46 against 50. `v8-guide` has the highest p95 of
the three, 1450 ms, and its longest answer is 50 tokens like `v2-json`'s.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Where the time of an average call goes, in the stand-in, for two prompts. v2-json: 300 ms fixed, 31 ms reading 78.5 input tokens, 798 ms writing 39.9 output tokens, 1129 ms in all. v3-examples: 300 ms fixed, 95 ms reading 238.5 input tokens, 748 ms writing 37.4 output tokens, 1143 ms in all. Each call also gets up to 150 ms of jitter.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">an average call, in milliseconds, before jitter</text><text x=\"128\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v2-json</text><rect x=\"140\" y=\"50\" width=\"129.0\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"269.0\" y=\"50\" width=\"13.5\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"282.5\" y=\"50\" width=\"343.1\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"635.6\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1129 ms</text><text x=\"140\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 + 31 + 798 = 1129</text><text x=\"128\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v3-examples</text><rect x=\"140\" y=\"122\" width=\"129.0\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"269.0\" y=\"122\" width=\"41.0\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"310.0\" y=\"122\" width=\"321.6\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"641.7\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1143 ms</text><text x=\"140\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 + 95 + 748 = 1143</text><rect x=\"140\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"158\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fixed, per call</text><rect x=\"320\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"338\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reading the input</text><rect x=\"500\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"518\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">writing the output</text></svg>", "caption": "Three times the input adds 64 ms to the reading; 2.5 fewer output tokens take 50 ms off the writing. The totals land 14 ms apart. The numbers are the stand-in's, from model.py and pl cost; the shape is the one real models have."}
```

**Every output token costs fifty times what an input token does** in this clock, so 2.5 fewer
tokens of answer almost cancel 160 more tokens of prompt. The ratio is the course's, and a real model's
will be different. The direction is not: if you want an answer sooner, look at what the model
writes before you look at what you send.
