---
title: stub
version: 1
---

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
