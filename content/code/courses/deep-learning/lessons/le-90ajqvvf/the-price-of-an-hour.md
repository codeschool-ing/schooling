---
title: The price of an hour
version: 1
---

Whoever rents a machine to train on is charged for hours, not for operations. **The bill is the time the
run took times the price of an hour**, and the time is decided by everything this lesson has measured:
the arithmetic, the overhead around it, the precision, the batch.

Start with a run of this course. Lesson 11's `compare.py` trains lesson 9's MLP, a wider MLP and the CNN,
30 epochs each: the whole of lesson 11's comparison in one command. Put `time` in front of the command and
the shell reports how long it took:

```
ana@vm:~/dl$ time python compare.py
dense, lesson 9: 2410 parameters
epoch  10  train loss 0.3170  val loss 0.3068  val acc 0.922
epoch  20  train loss 0.1661  val loss 0.2004  val acc 0.936
epoch  30  train loss 0.1205  val loss 0.1461  val acc 0.950
dense, 512 wide: 38410 parameters
epoch  10  train loss 0.2126  val loss 0.2165  val acc 0.936
epoch  20  train loss 0.1238  val loss 0.1642  val acc 0.944
epoch  30  train loss 0.0921  val loss 0.1223  val acc 0.961
convolutional: 38282 parameters
epoch  10  train loss 0.1558  val loss 0.1291  val acc 0.969
epoch  20  train loss 0.0249  val loss 0.1526  val acc 0.947
epoch  30  train loss 0.0055  val loss 0.0776  val acc 0.978
4800 of them in the two convolutions

real	0m10.857s
user	0m24.827s
sys	0m0.778s
```

`real` is the time on the clock, from start to finish. `user` is processor time, added up over all the
processors the program used, which is why it can come out larger than `real`: PyTorch splits a large
product across the four processors of the machine. These are the course machine's figures, and
yours will differ.

## A price is a variable

The program below turns a time into a bill. **The price at its top is illustrative**: 2.50 an hour, in
no currency, chosen in October 2026 to make the arithmetic easy to follow. It is not what any provider
charges, and prices for the same machine differ between providers and change from month to month. Put in
the price you are quoted on the day. Save as `~/dl/bill.py`:

```schooling-example
{
  "language": "python",
  "file": "bill.py",
  "parts": [
    {
      "code": "\"\"\"bill: what training costs, from a time and a price per hour that you look up yourself.\"\"\"\nimport sys\n\nPRICE_PER_HOUR = 2.50   # ILLUSTRATIVE, set in October 2026 for the arithmetic. Not a quote.\n\nseconds = float(sys.argv[1])\nhours = seconds / 3600\nprint(f\"this run: {seconds:.0f} s = {hours:.4f} h, {hours * PRICE_PER_HOUR:.4f} at {PRICE_PER_HOUR:.2f} an hour\")",
      "note": "The price is a variable at the top, in no currency, because it is the one number here that you have to supply. 2.50 an hour was picked to make the arithmetic readable, in October 2026, and is not what any provider charges. The time of a run comes in on the command line."
    },
    {
      "code": "# A large language model, by the 6 x N x D rule. Every number below is an assumption.\nN = 7e9         # parameters\nD = 20 * N      # training tokens, about twenty per parameter\nPEAK = 1e15     # FLOP/s that a card's data sheet promises in bfloat16\nKEPT = 0.40     # the share of that peak a real training job sustains\n\nflops = 6 * N * D\ncard_hours = flops / (PEAK * KEPT) / 3600\nprint(f\"6 x N x D = {flops:.2e} FLOPs\")\nprint(f\"{card_hours:,.0f} card-hours, {card_hours * PRICE_PER_HOUR:,.0f} at {PRICE_PER_HOUR:.2f} an hour\")\nfor cards in (8, 256):\n    print(f\"  on {cards:3d} cards: {card_hours / cards / 24:5.1f} days\")",
      "note": "Four assumptions, each on its own line so it can be changed. Twenty tokens per parameter is the ratio a 2022 study by Hoffmann and colleagues found to be the best use of a fixed budget. A thousand million million operations a second is the order of magnitude data sheets gave for large cards in bfloat16, and 40% of it is a share real jobs reach when they are well tuned."
    }
  ]
}
```

Run it with the seconds of the `real` line above, rounded:

```
ana@vm:~/dl$ python bill.py 11
this run: 11 s = 0.0031 h, 0.0076 at 2.50 an hour
6 x N x D = 5.88e+21 FLOPs
4,083 card-hours, 10,208 at 2.50 an hour
  on   8 cards:  21.3 days
  on 256 cards:   0.7 days
```

**The course's run costs 0.0076 at that price**, a small fraction of one unit of whatever the
currency is. The second half is the same
arithmetic for a model that does need a budget, worked out before it is trained, with the 6 × N × D rule
from the first section. A model of 7 billion parameters trained on 20 tokens per parameter needs 5.88e+21
operations. On cards that sustain 40% of a peak of 1e15 per second, that is 4,083 card-hours, or 10,208
at the illustrative price.

**More cards buy time, not money.** Eight cards take 21.3 days and 256 take 0.7 days, and the card-hours,
so the bill, are the same 4,083 either way. In practice the larger group costs somewhat more, because the
cards spend part of each step exchanging gradients, which `KEPT` would have to absorb.

## The assumption that moves the bill most

Every line under the comment in `bill.py` is an assumption, and the bill scales with each of them, up
or down. The one most often wrong is `KEPT`, the share of the card's peak that the job actually sustains.
The first section of this lesson measured one reason it falls, the overhead around small matrices, and
lesson 10 another, waiting for data. At 20% instead of 40% the same model costs twice as much, and
nothing on the data sheet says so.

Two habits follow. **Measure before you budget**: train for a few hundred steps, time them, and work out
the full run from that rather than from a data sheet. And **save as you go**, the weights and the
optimiser's state, with the `state_dict` of lesson 9. The cheapest rented machines are the ones the
provider can take back at short notice, and a run
that can resume from its last save loses minutes when that happens, not days.
