---
title: "The recall task: how far back each one remembers"
version: 1
---

A gradient that reaches 49 steps back is a promise, not a result. **To see what each cell can
actually learn, it needs a task whose answer is known and whose difficulty is one number: how far back
the answer sits.** This one is the plainest there is. A sequence of random symbols arrives, and at the
end the model has to say what the first symbol was. Everything in between is noise.

The task is a file of its own, `~/dl/seqtask.py`, because lesson 15 trains a transformer on the same
one:

```schooling-example
{
  "language": "python",
  "file": "seqtask.py",
  "parts": [
    {
      "code": "\"\"\"seqtask: a sequence task with a known answer: remember the first symbol until the end.\"\"\"\nimport torch\n\nSYMBOLS = 8",
      "note": "Lesson 15 uses this file again, unchanged, so that a transformer meets exactly the task the RNN and the LSTM meet here."
    },
    {
      "code": "def batch(n, length, generator):\n    \"\"\"n sequences of `length` random symbols; the label of each is its first symbol.\"\"\"\n    x = torch.randint(0, SYMBOLS, (n, length), generator=generator)\n    return x, x[:, 0].clone()",
      "note": "Every symbol after the first is noise, and the answer is asked for after the last one, so the model has to carry three bits of information across the whole sequence. The generator makes the data reproducible, and there is no end to it: every batch is new."
    }
  ]
}
```

A model that has learnt nothing guesses one symbol in eight, so chance is 0.125, and a model that has
solved it scores 1.000. The length decides how many steps the first symbol has to survive. The program
below trains an RNN and an LSTM, the same size and on the same data, at three lengths. Save as
`~/dl/recall.py`:

```schooling-example
{
  "language": "python",
  "file": "recall.py",
  "parts": [
    {
      "code": "\"\"\"recall: an RNN and an LSTM, trained to name the first symbol of a sequence at the end of it.\"\"\"\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\n\nimport seqtask\n\ntorch.set_num_threads(1)",
      "note": "One thread, on purpose. Each step of a small recurrent layer is too little work to share among four processors, and one thread keeps the run from slowing down when something else on the machine is busy."
    },
    {
      "code": "class Reader(nn.Module):\n    \"\"\"Embed each symbol, read the sequence, and predict from the state after the last step.\"\"\"\n\n    def __init__(self, cell, hidden=64):\n        super().__init__()\n        self.embed = nn.Embedding(seqtask.SYMBOLS, 16)\n        if cell == \"rnn\":\n            self.rnn = nn.RNN(16, hidden, batch_first=True)\n        else:\n            self.rnn = nn.LSTM(16, hidden, batch_first=True)\n            with torch.no_grad():\n                self.rnn.bias_hh_l0[hidden:2 * hidden] += 1.0\n        self.out = nn.Linear(hidden, seqtask.SYMBOLS)\n\n    def forward(self, x):\n        h, _ = self.rnn(self.embed(x))\n        return self.out(h[:, -1])",
      "note": "The same model for both cells: an embedding of 16, a recurrent layer of 64 and a dense layer reading only the last state. The LSTM's forget gate starts with 1 added to its bias, the usual starting point since 2015, which leaves it nearer to keeping than to forgetting."
    },
    {
      "code": "def train(cell, length, steps=3000, seed=0):\n    torch.manual_seed(seed)\n    model = Reader(cell)\n    opt = torch.optim.Adam(model.parameters(), lr=3e-3)\n    data = torch.Generator().manual_seed(seed)\n    x_test, y_test = seqtask.batch(1000, length, torch.Generator().manual_seed(1234))\n    scores = []",
      "note": "Adam at 0.003, 3,000 steps of 64 fresh sequences each. The test set is 1,000 sequences from a generator of its own, so no test sequence is one the model trained on, except by the chance of drawing the same symbols."
    },
    {
      "code": "    for step in range(1, steps + 1):\n        x, y = seqtask.batch(64, length, data)\n        loss = F.cross_entropy(model(x), y)\n        opt.zero_grad()\n        loss.backward()\n        opt.step()\n        if step % 1000 == 0:\n            with torch.no_grad():\n                scores.append((model(x_test).argmax(dim=1) == y_test).float().mean().item())\n    return scores",
      "note": "The five lines of lesson 9's loop, with a new batch drawn at every step instead of an epoch over a fixed set. Accuracy on the test sequences is taken every 1,000 steps."
    },
    {
      "code": "print(\"accuracy on 1,000 new sequences after 1,000, 2,000 and 3,000 steps (chance is 0.125)\")\nfor length in (5, 20, 50):\n    for cell in (\"rnn\", \"lstm\"):\n        scores = \"  \".join(f\"{s:.3f}\" for s in train(cell, length))\n        print(f\"{cell:4s}  length {length:2d}   {scores}\", flush=True)",
      "note": "Six runs: both cells at three lengths, with the same seed, the same data and the same number of steps. Guessing among eight symbols scores 0.125."
    }
  ]
}
```

```
ana@vm:~/dl$ time python recall.py
accuracy on 1,000 new sequences after 1,000, 2,000 and 3,000 steps (chance is 0.125)
rnn   length  5   1.000  1.000  1.000
lstm  length  5   1.000  1.000  1.000
rnn   length 20   0.134  0.416  0.482
lstm  length 20   1.000  1.000  1.000
rnn   length 50   0.122  0.136  0.118
lstm  length 50   0.120  0.122  0.144

real	2m2.026s
user	2m0.139s
sys	0m0.700s
```

The six runs took 2 minutes 2 seconds on the course's machine, on one thread.

| length | RNN after 3,000 steps | LSTM after 3,000 steps |
| --- | --- | --- |
| 5 | 1.000 | 1.000 |
| 20 | 0.482 | 1.000 |
| 50 | 0.118 | 0.144 |

**At length 5 both are perfect after the first thousand steps**: four steps back is near enough for an
RNN's gradient. **At length 20 the difference is the cell.** The LSTM was perfect at the first
measurement, after 1,000 steps. The RNN was at chance then, 0.134, and had climbed to 0.482 by the end,
right on less than half of the sequences. Its gradient reaches back twenty steps, faintly, and the
learning is slow in proportion.

**At length 50 neither learnt it** in 3,000 steps. The RNN never left chance. The LSTM ended at 0.144,
a little above chance, which may be the start of learning or may be noise in 1,000 test sequences, and
this run cannot tell which. More steps, a larger forget bias or a smaller learning rate might take it
further. None of that was tried here, so this lesson claims only what it measured: **under the same
budget, the LSTM reached 20 steps back and not 50.**

**A task whose difficulty is a single knob is the cheapest way to compare architectures.** The answer
is known, the data costs nothing, and the knob shows where each one stops. Lesson 15 turns the same knob
with the same file, the same steps and the same lengths, on a model that carries no state from step to
step at all.
