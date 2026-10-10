---
title: The spread of one configuration
version: 1
---

A single run answers *what did this seed get*. The question anybody actually asks is *what does
this configuration get*, and **one seed cannot answer it, because the seed moves the result too.**
The way to see by how much is to change nothing but the seed. Save as `~/dl/spread.py`:

```schooling-example
{
  "language": "python",
  "file": "spread.py",
  "parts": [
    {
      "code": "\"\"\"spread: one configuration, five seeds.\"\"\"\nimport statistics\n\nimport exp\n\nconfig = {\"hidden\": 32, \"lr\": 0.01, \"epochs\": 10, \"batch_size\": 32}\naccs = []\nfor seed in range(5):\n    _, acc = exp.run(config, seed)\n    accs.append(acc)\n    print(f\"seed {seed}  val acc {acc:.4f}  ({round(acc * 360)} of 360)\")",
      "note": "The configuration of `seeds.py`, with seeds 0 to 4. Accuracy on 360 images moves in steps of one image, so the program prints the count beside it."
    },
    {
      "code": "print(f\"min {min(accs):.4f}  max {max(accs):.4f}  mean {statistics.mean(accs):.4f}  \"\n      f\"sd {statistics.stdev(accs):.4f}\")",
      "note": "The range, the mean and the standard deviation of the five: the size of the noise one configuration makes all by itself."
    }
  ]
}
```

```
PENDING spread
```

**Five runs of one configuration landed between 0.9139 and 0.9250.** That is 329 to 333 correct
images out of 360: four images of difference, and none of it caused by anything a person chose.
Three of the five seeds tied on 333, which is a reminder of how coarse this measurement is.
**Accuracy on 360 images moves in steps of 1/360, about 0.0028**, so two runs that differ by one
step differ by one image.

Two numbers summarise the spread, and they say different things:

- **the range**, minimum to maximum, is what a single run could have shown you. Had you run only
  seed 2, you would have reported 0.9139; only seed 1, 0.9250.
- **the standard deviation**, here 0.0053, is the typical distance of a run from the mean. It is
  the yardstick a comparison of two configurations, two sections on, is measured against.

Five seeds is a small sample, and the standard deviation of five numbers is itself rough. It is
enough to see the size of the noise, which is the point here, and not enough to pin it down to the
third decimal. A published comparison would use more seeds, and the cost is one more training per
seed.

## Where the spread comes from

Each seed starts the network at a different point and feeds it the batches in a different order.
Gradient descent from those starts walks to different places, and a network that ends at a
different place classifies a few borderline digits differently. **The small validation set turns
that into a visible number**: with 360 images, a handful of borderline cases is a whole percentage
point.

The spread is also not a fixed property of the data. A higher learning rate, a different batch size
or more epochs can widen it or narrow it, so it belongs to a configuration. That is why the
comparison later in the lesson runs every configuration on several seeds, instead of measuring the
spread once and assuming it.
