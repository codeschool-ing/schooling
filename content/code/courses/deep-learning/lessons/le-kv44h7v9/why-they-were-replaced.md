---
title: Why they were replaced
version: 1
---

For most of the 2010s the LSTM was the answer to almost every problem with a sequence in it, from
speech recognition to translation. Since 2017 that place has gone to the transformer, and the usual
explanation, that transformers are simply more accurate, leaves out the reason that mattered most.
**A recurrent network cannot compute step 50 before it has computed step 49.** Each step needs the state
the previous one wrote, so the steps of one sequence happen one after another, however much hardware is
waiting.

A batch does not have that problem. Sixty-four sequences side by side are sixty-four independent rows
of the same matrix product, and a processor can do them together. The program below reads the same
number of symbols both ways, and then longer sequences. Save as `~/dl/timing.py`:

```schooling-example
{
  "language": "python",
  "file": "timing.py",
  "parts": [
    {
      "code": "\"\"\"timing: the same number of symbols, read side by side or one after another.\"\"\"\nimport time\n\nimport torch\nimport torch.nn as nn\n\ntorch.set_num_threads(1)\ntorch.manual_seed(0)\nlstm = nn.LSTM(16, 64, batch_first=True)",
      "note": "One thread again, so that the comparison is between two ways of arranging the work and not between two ways of sharing it."
    },
    {
      "code": "def ms(batch, length, repeat=10):\n    \"\"\"The fastest of `repeat` forward passes, in milliseconds.\"\"\"\n    x = torch.randn(batch, length, 16)\n    best = float(\"inf\")\n    with torch.no_grad():\n        for _ in range(repeat):\n            start = time.perf_counter()\n            lstm(x)\n            best = min(best, time.perf_counter() - start)\n    return best * 1000",
      "note": "The fastest of ten runs, because anything else on the machine can only make a run slower, never faster. Only the forward pass is timed; a training step adds a backward pass that walks the same steps in reverse, one at a time as well."
    },
    {
      "code": "base = ms(64, 50)\nfor batch, length in ((64, 50), (1, 3200), (64, 100), (64, 200)):\n    t = ms(batch, length)\n    print(f\"{batch:2d} x {length:4d} steps = {batch * length:5d} symbols\"\n          f\"  {t:5.1f} ms  x{t / base:.1f}\")",
      "note": "The first two rows read the same 3,200 symbols, as 64 sequences side by side or as one long one. The last two keep the batch and make the sequences longer. The last column is each time divided by the first row's."
    }
  ]
}
```

```
PENDING timing
```

The timings are the course machine's and yours will differ; **the ratios are what to compare.** The
first two rows are the same 3,200 symbols, and reading them as one sequence of 3,200 steps took 3.2 times
as long as reading them as 64 sequences of 50. Both did the same multiplications. The long one did them
3,200 times on one row each, and the batch did them 50 times on 64 rows each, where one larger product is
cheaper than many small ones. The last two rows show the other half: doubling the length doubled the time,
2.0 and then 3.9 times the first row, because every extra step is one more turn of the loop.

That was one thread on a processor. **A graphics card makes the gap far wider**, because it runs
thousands of multiplications at once: the batch fills it, and a single long sequence leaves almost all of
it idle while the loop goes round. This was not run for this course, which has no graphics card, but the
arithmetic of the first two rows is the reason. Training on a large body of text means long sequences, and
a model whose speed is set by the length of the sequence, not by the size of the hardware, does not get
faster when the hardware does.

The second reason is in the previous section's table. **Everything a recurrent network knows about the
past has to fit in one state of fixed size**, rewritten at every step. The first symbol of a sequence of
50 reaches the end only if 49 rewrites leave it alone. A transformer lets every position look directly at
every other position, so the first symbol is one step from the last whatever the length. Lesson 15 builds
one and runs it on the same recall task.

Recurrent networks did not disappear. **Their cost per step is constant**: reading one more symbol costs
the same at symbol 10 as at symbol 10,000, and the state is all that has to be kept. Where data arrives
one sample at a time and has to be answered at once, a keyboard predicting the next word or a sensor on a
small device, that is exactly the property wanted. Some recent architectures, the state-space models
such as Mamba from 2023, keep a state with that constant cost per step and are built so that training
still runs over the whole sequence in parallel.
