---
title: What fine-tuning forgets
version: 1
---

Fine-tuning changes weights that were already doing a job. **If the old job still matters, the
question is what is left of it afterwards**, and the cases where it matters are common: a model
that gains new classes and must keep the old ones, a deployed model extended to a second task, a
language model taught a narrow skill that should still answer everything else.

`base.pt` makes the question easy to ask. Its own head, `Linear(64, 5)` for the digits 0 to 4, can
be set aside before the new head replaces it and put back on the fine-tuned body at any moment.
If the body still computes what that head expects, the old digits are still recognised. The
program fine-tunes on 5 to 9 with 10 images per class, five ways, and measures the old task as it
goes. Save as `~/dl/forget.py`:

```schooling-example
{
  "language": "python",
  "file": "forget.py",
  "parts": [
    {
      "code": "\"\"\"forget: what fine-tuning on 5 to 9 does to the digits 0 to 4 that base.pt knew.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nnew_val = xv[yv >= 5], yv[yv >= 5] - 5\nold_val = xv[yv < 5], yv[yv < 5]\nidx = torch.cat([torch.nonzero(y == d).flatten()[:10] for d in range(5, 10)])\ntrain = x[idx], y[idx] - 5",
      "note": "Two validation sets this time: the new digits, and the 180 images of 0 to 4 that `base.pt` scored 0.989 on in lesson 13."
    },
    {
      "code": "def old_task(model, old_head):\n    \"\"\"The body as it is now, with base.pt's own head put back: accuracy on 0 to 4.\"\"\"\n    return loop.evaluate(nn.Sequential(*model[:8], old_head), *old_val)[1]",
      "note": "The fine-tuned body with `base.pt`'s original head on top, built as a new `Sequential` that shares the body's layers. If the body still computes what the old head expects, the old task still works."
    },
    {
      "code": "SETUPS = {                 # layers that learn, body rate, head rate\n    \"head only\":            ([8], None, 1e-3),\n    \"last block\":           ([6, 8], 1e-3, 1e-3),\n    \"everything\":           ([0, 2, 6, 8], 1e-3, 1e-3),\n    \"everything at 1e-2\":   ([0, 2, 6, 8], 1e-2, 1e-2),\n    \"body 1e-4, head 1e-3\": ([0, 2, 6, 8], 1e-4, 1e-3),\n}\nCHECK = (1, 2, 5, 10, 20, 50, 100)\nprint(\"accuracy on 0 to 4 with base.pt's head put back, after epoch\")\nprint(\" \" * 23 + \"  \".join(f\"{e:5d}\" for e in (0,) + CHECK) + \"   new task\")",
      "note": "Five ways of fine-tuning, taken from the two sections before: the three depths at 1e-3, everything at the rate that moved furthest, and everything with a slow body."
    },
    {
      "code": "for name, (learns, body_lr, head_lr) in SETUPS.items():\n    torch.manual_seed(0)\n    model = cnn.make_cnn(5)\n    model.load_state_dict(torch.load(\"base.pt\"))\n    old_head, model[8] = model[8], nn.Linear(64, 5)\n    for i, layer in enumerate(model):\n        for p in layer.parameters():\n            p.requires_grad = i in learns\n    groups = [{\"params\": model[8].parameters(), \"lr\": head_lr}]\n    if body_lr:\n        groups.append({\"params\": [p for p in model[:8].parameters() if p.requires_grad], \"lr\": body_lr})\n    opt = torch.optim.Adam(groups)\n    row = [old_task(model, old_head)]\n    for epoch in range(1, 101):\n        history = loop.fit(model, opt, train, new_val, epochs=1, seed=epoch, every=1000)\n        if epoch in CHECK:\n            row.append(old_task(model, old_head))\n    print(f\"{name:21s}  \" + \"  \".join(f\"{a:.3f}\" for a in row) + f\"   {history[-1][3]:.3f}\")",
      "note": "One seed per setup, and the old head is set aside before the new one replaces it. Training runs one epoch per call to `loop.fit`, with `seed=epoch` so each epoch is shuffled differently, and the old task is measured at the epochs in `CHECK`. The last column is the new task at the end."
    }
  ]
}
```

```
PENDING forget
```

The last column is the new task at the end of each run. It differs from the matching row of
`depths.py` or `rates.py` by a little, because one long call to `loop.fit` and a hundred short
ones with `seed=epoch` shuffle the batches differently.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 300\" role=\"img\" aria-label=\"A line chart of accuracy on the digits 0 to 4 against the epoch of fine-tuning on 5 to 9, at epochs 0, 1, 2, 5, 10, 20, 50 and 100. Head only and body 1e-4, head 1e-3 stay at 0.989 throughout. Last block and everything at 1e-3 drift down to 0.944 and 0.939. Everything at 1e-2 falls from 0.989 to 0.294, with a low of 0.250 at epoch 20.\"><text x=\"48\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">accuracy on 0 to 4, old head put back</text><path d=\"M56 240 L456 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M56 140.0 L456 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"48\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M56 40.0 L456 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"48\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0</text><text x=\"56.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"113.14285714285714\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"170.28571428571428\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"227.42857142857142\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"284.57142857142856\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"341.7142857142857\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"398.85714285714283\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50</text><text x=\"456.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100</text><text x=\"256.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">epoch</text><path d=\"M56.0 42.2 L113.1 41.2 L170.3 42.2 L227.4 45.6 L284.6 42.2 L341.7 45.6 L398.9 50.0 L456.0 51.2\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M56.0 42.2 L113.1 41.2 L170.3 44.4 L227.4 50.0 L284.6 44.4 L341.7 48.8 L398.9 52.2 L456.0 52.2\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M56.0 42.2 L113.1 42.2 L170.3 42.2 L227.4 42.2 L284.6 42.2 L341.7 42.2 L398.9 42.2 L456.0 42.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M56.0 42.2 L113.1 42.2 L170.3 42.2 L227.4 42.2 L284.6 42.2 L341.7 41.2 L398.9 42.2 L456.0 42.2\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M56.0 42.2 L113.1 72.2 L170.3 68.8 L227.4 156.6 L284.6 74.4 L341.7 190.0 L398.9 177.8 L456.0 181.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M474 40 L498 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"506\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">head only</text><path d=\"M474 58 L498 58\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"506\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">body 1e-4, head 1e-3</text><path d=\"M474 76 L498 76\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"506\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">last block</text><path d=\"M474 94 L498 94\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"506\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">everything</text><path d=\"M474 181.2 L498 181.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"506\" y=\"181.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">everything at 1e-2</text></svg>", "caption": "How much of 0 to 4 survives fine-tuning on 5 to 9, from the forget.py run."}
```

## Three outcomes

**Where the body barely moved, nothing was forgotten.** Head only leaves the body exactly as `base.pt` had it,
so 0 to 4 stay at 0.989 throughout: nothing that computes them was touched. The slow body, at
1e-4, ends at 0.989 too, having moved 0.04 of its size in `rates.py`. The price is on the new task,
0.667 and 0.822, the two lowest numbers in the last column.

**At 1e-3 the old task erodes slowly.** The last block and everything both end around 0.94, five
points down from 0.989, while reaching 0.900 and 0.917 on the new digits. The body has drifted
towards 5 to 9 and the old head reads it a little less well each epoch.

**At 1e-2 the old task collapses.** Everything at the high rate was down to 0.839 after a single
epoch and ends at 0.294, while it scores 0.922 on the new task, the best in the column. This is
**catastrophic forgetting**: the weights that recognised 0 to 4 were rewritten to recognise 5 to 9,
and nothing in the training asked them to keep the first job. The curve also jumps about, 0.417 at
epoch 5 and 0.828 at epoch 10, because the old task is not what the steps are aiming at; where it
lands at any epoch is a by-product.

## What to do about it

The figure is the whole trade: **the setups that kept the old task are the ones that learnt the new
one least well**, because both depend on how far the body moves. The ways out each change that:

- **Freeze more, or lower the body's rate.** Cheap and reliable, and it gives up what moving would
  have bought on the new task, as the two flat lines did here.
- **Rehearse.** Mix some of the old training data into the new training, with a head that answers
  all ten digits, so the loss itself asks for both tasks. It needs the old data, which is often the
  thing you do not have.
- **Keep the original weights untouched and learn a separate correction.** The next section builds
  one, and removing it gives the old model back exactly.
