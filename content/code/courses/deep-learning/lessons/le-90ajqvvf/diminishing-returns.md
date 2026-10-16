---
title: Diminishing returns
version: 1
---

The last question about cost is what it buys. More training seldom makes a network worse, so it is easy
to keep paying for it. **Each doubling of the work buys less than the one before**, and the useful
question is when the next doubling stops being worth its price.

There are two ways to spend more on lesson 9's network: more epochs on the same images, or more images.
The program below does both, and then spends one fixed amount of arithmetic in different ways. It uses
the `digits.py` of lesson 1 and the `tdigits.py`, `loop.py` and `mlp.py` of lesson 9. Save as
`~/dl/returns.py`:

```schooling-example
{
  "language": "python",
  "file": "returns.py",
  "parts": [
    {
      "code": "\"\"\"returns: what more epochs, and more data, buy lesson 9's MLP.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\n(x, y), val, _ = tdigits.load()\n\n\ndef run(images, epochs):\n    \"\"\"Lesson 9's recipe on the first `images` training images; the history of every epoch.\"\"\"\n    torch.manual_seed(0)\n    model = make_mlp()\n    opt = torch.optim.SGD(model.parameters(), lr=0.1)\n    return loop.fit(model, opt, (x[:images], y[:images]), val, epochs, every=epochs + 1)",
      "note": "Every run is lesson 9's: the same seed, SGD at 0.1, batches of 32. Only the number of training images and the number of epochs change. `digits.py` shuffled the images before splitting them, so the first 135 are a random 135. `every=epochs + 1` keeps `fit` quiet."
    },
    {
      "code": "print(\"more epochs, all 1,077 images\")\nlast = None\nfor epoch, _, val_loss, val_acc in run(1077, 128):\n    if epoch in (1, 2, 4, 8, 16, 32, 64, 128):\n        gain = \"\" if last is None else f\"  {100 * (val_acc - last):+.1f} points\"\n        print(f\"  {epoch:3d} epochs  {epoch * 1077:7,d} examples seen  val acc {val_acc:.3f}{gain}\")\n        last = val_acc",
      "note": "One run of 128 epochs, read at every doubling. Each line has twice the arithmetic of the line above it, and the last column is what that doubling bought, in percentage points."
    },
    {
      "code": "print(\"more images, 30 epochs\")\nlast = None\nfor images in (135, 270, 540, 1077):\n    val_acc = run(images, 30)[-1][3]\n    gain = \"\" if last is None else f\"  {100 * (val_acc - last):+.1f} points\"\n    print(f\"  {images:4d} images  {images * 30:7,d} examples seen  val acc {val_acc:.3f}{gain}\")\n    last = val_acc\n\nprint(\"the same arithmetic as 1,077 images for 30 epochs, spent on fewer images\")\nfor images, epochs in ((270, 120), (135, 240)):\n    print(f\"  {images:4d} images for {epochs} epochs: val acc {run(images, epochs)[-1][3]:.3f}\")",
      "note": "Then the other way to spend more: the same 30 epochs on twice as many images each time. The last two runs spend exactly the arithmetic of the full run, 1,077 images for 30 epochs, on a quarter and an eighth of the images, going round them more often."
    }
  ]
}
```

```
ana@vm:~/dl$ python returns.py
more epochs, all 1,077 images
    1 epochs    1,077 examples seen  val acc 0.336
    2 epochs    2,154 examples seen  val acc 0.719  +38.3 points
    4 epochs    4,308 examples seen  val acc 0.839  +11.9 points
    8 epochs    8,616 examples seen  val acc 0.914  +7.5 points
   16 epochs   17,232 examples seen  val acc 0.939  +2.5 points
   32 epochs   34,464 examples seen  val acc 0.956  +1.7 points
   64 epochs   68,928 examples seen  val acc 0.964  +0.8 points
  128 epochs  137,856 examples seen  val acc 0.969  +0.6 points
more images, 30 epochs
   135 images    4,050 examples seen  val acc 0.861
   270 images    8,100 examples seen  val acc 0.903  +4.2 points
   540 images   16,200 examples seen  val acc 0.931  +2.8 points
  1077 images   32,310 examples seen  val acc 0.950  +1.9 points
the same arithmetic as 1,077 images for 30 epochs, spent on fewer images
   270 images for 120 epochs: val acc 0.942
   135 images for 240 epochs: val acc 0.922
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 360\" role=\"img\" aria-label=\"Validation accuracy of lesson 9&#x27;s network against the number of training examples it has seen, on a doubling scale. One line adds epochs on all 1,077 images, from 4 epochs to 128; its rises shrink at each doubling and it flattens near the top. The other line adds images at 30 epochs, from 135 to 1,077, and is still rising steeply when the images run out. Two marks show runs that spend the arithmetic of 1,077 images for 30 epochs on a quarter and an eighth of the images; both sit below the full run.\"><path d=\"M70 257.5 L650 257.5\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"257.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.84</text><path d=\"M70 192.49999999999994 L650 192.49999999999994\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"192.49999999999994\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.88</text><path d=\"M70 127.49999999999989 L650 127.49999999999989\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"127.49999999999989\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.92</text><path d=\"M70 62.50000000000003 L650 62.50000000000003\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"62.50000000000003\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.96</text><path d=\"M81.87086196820171 30 L81.87086196820171 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"81.87086196820171\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4,308</text><path d=\"M192.7945780752896 30 L192.7945780752896 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"192.7945780752896\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8,616</text><path d=\"M303.71829418237746 30 L303.71829418237746 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"303.71829418237746\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">17,232</text><path d=\"M414.64201028946536 30 L414.64201028946536 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"414.64201028946536\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">34,464</text><path d=\"M525.5657263965535 30 L525.5657263965535 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"525.5657263965535\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">68,928</text><path d=\"M636.4894425036414 30 L636.4894425036414 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"636.4894425036414\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">137,856</text><path d=\"M70 290 L650 290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 30 L70 290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360.0\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">examples seen, doubling at each grid line</text><text x=\"30\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">validation accuracy</text><path d=\"M81.9 259.1 L192.8 137.2 L303.7 96.6 L414.6 69.0 L525.6 56.0 L636.5 47.9\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"81.9\" cy=\"259.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"192.8\" cy=\"137.2\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"303.7\" cy=\"96.6\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"414.6\" cy=\"69.0\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"525.6\" cy=\"56.0\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"636.5\" cy=\"47.9\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"630.4894425036414\" y=\"31.87500000000003\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">all 1,077 images, more epochs</text><path d=\"M72.0 223.4 L182.9 155.1 L293.8 109.6 L404.3 78.8\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"7 4\"></path><circle cx=\"72.0\" cy=\"223.4\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><circle cx=\"182.9\" cy=\"155.1\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><circle cx=\"293.8\" cy=\"109.6\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><circle cx=\"404.3\" cy=\"78.8\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"196.9116807418736\" y=\"185.12499999999991\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">30 epochs, more images</text><rect x=\"400.8\" y=\"87.8\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"414.8\" y=\"91.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">270 × 120</text><rect x=\"400.8\" y=\"120.2\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"414.8\" y=\"124.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">135 × 240</text><text x=\"414.7591129560494\" y=\"146.2499999999999\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the same arithmetic on fewer images</text></svg>", "caption": "Each doubling of the epochs buys less than the one before. Adding images was still paying when the images ran out."}
```

## Epochs

**The doublings of the epochs pay less each time.** From 4 to 8 epochs the accuracy climbed from 0.839
to 0.914, 7.5 points. The next three doublings bought 2.5, 1.7 and 0.8 points, and the last, from 64
epochs to 128, bought 0.6, for as much arithmetic as all the epochs before it together. The 30-epoch
recipe of lesson 9 sits between the 16 and the 32 of this table, at the point where the gains have
already become small.

## Images

**More images were still paying when they ran out.** At 30 epochs, going from 135 images to 270 bought
4.2 points, and the next two doublings 2.8 and 1.9. The last of those is more than the matching doubling
of the epochs bought. The curve points to more digits as the next thing worth paying for, and the 1,077
of the training set are all there are.

The last two lines spend the arithmetic of the full run, 1,077 images for 30 epochs, on fewer images
seen more often. **Both come out below it**: 0.942 with a quarter of the images and 0.922 with an
eighth. Going round a small set again is worth less than seeing new examples, because the network learns
the examples it has rather than the digits they stand for, the overfitting of lesson 7.

## Where to stop

Large models show the same shape, measured over many more doublings. Studies of language models since
2020 found the loss falling smoothly as a power of the compute, the data and the size of the model. On a
doubling scale that is a curve whose gains shrink at every step and do not reach zero, so the curve
itself never says stop. **The decision is economic**: the next doubling costs as much as everything spent
so far, and buys less than the last one did. Whether 0.6 of a point is worth that depends on what the
point is worth to whoever uses the model, and that number is not in any capture.

What the curves do say is where the money goes furthest. When the epochs have flattened and the images
have not, the next budget belongs to data, collected or labelled, not to a longer run or a larger card.
Lesson 20 asks the question from the other side: when the data is small, whether a network was the
right model at all.
