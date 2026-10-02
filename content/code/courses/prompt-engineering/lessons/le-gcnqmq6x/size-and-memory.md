---
title: How many bytes a model needs
version: 1
---

It is tempting to read a model's size as a feeling: 70B sounds big, 7B sounds small, and whether
either runs on your machine sounds like something you find out by trying. **It is arithmetic, and
it takes one line: the number of weights times the bytes each weight takes.** Everything else in
this section is where the second number comes from.

`toylm` needed 7478 bytes for its 436 counts, about 17 bytes each, because it stores them as text
with the words beside them. A large model stores its weights as binary numbers of a fixed width,
and the width is chosen:

| width | bytes per weight | what it is |
|---|---|---|
| 32 bits | 4 | full precision |
| 16 bits | 2 | the usual width a model's weights are published at |
| 8 bits | 1 | quantised: each weight rounded to one of at most 256 values |
| 4 bits | ½ | quantised harder: each weight rounded to one of at most 16 values |

## The worked example

`size.py` is the multiplication, written once so it can be run for any size:

```python
import sys

weights = float(sys.argv[1])
for bits in (32, 16, 8, 4):
    print("%2d bits: %6.1f GB" % (bits, weights * bits / 8 / 1e9))
```

Bits divided by 8 is bytes, and dividing by 10⁹ gives gigabytes. For a 7B model and a 70B one:

```
ana@lab:~/pe$ python3 size.py 7e9
32 bits:   28.0 GB
16 bits:   14.0 GB
 8 bits:    7.0 GB
 4 bits:    3.5 GB
ana@lab:~/pe$ python3 size.py 70e9
32 bits:  280.0 GB
16 bits:  140.0 GB
 8 bits:   70.0 GB
 4 bits:   35.0 GB
```

**A 7B model at 16 bits needs 14 GB for its weights alone**, and at 4 bits it needs 3.5. Those are
the same seven billion weights, stored at a quarter of the width.

The weights are the floor, not the total. A running model also needs working memory for the text
it is processing, and that part grows with the length of the context (lesson 4). A model whose
weights only just fit has no room left to read a long document.

## Quantisation, and what it costs

Storing a weight in fewer bits means rounding it to a coarser set of values. `quant.py` does that
to four numbers made up to stand in for weights. It finds the largest one, divides the range into
the steps the width allows, and rounds every weight to the nearest step:

```python
w = [0.0173, -0.4121, 0.2958, -0.0846]
print("original:", " ".join("%+.4f" % x for x in w))
for bits in (8, 4):
    levels = 2 ** (bits - 1) - 1
    step = max(abs(x) for x in w) / levels
    back = [round(x / step) * step for x in w]
    err = max(abs(a - b) for a, b in zip(w, back))
    print("%d bits:  " % bits, " ".join("%+.4f" % x for x in back), " largest error %.4f" % err)
```

```
ana@lab:~/pe$ python3 quant.py
original: +0.0173 -0.4121 +0.2958 -0.0846
8 bits:   +0.0162 -0.4121 +0.2953 -0.0844  largest error 0.0011
4 bits:   +0.0000 -0.4121 +0.2944 -0.0589  largest error 0.0257
```

At 8 bits every weight moved by at most 0.0011. At 4 bits the error is more than twenty times
larger, and **the smallest weight, `0.0173`, became exactly zero**: whatever it contributed is gone.
Real quantisation methods are cleverer than this one, rounding in small groups and protecting the
weights that matter most, but the trade is the same. **Fewer bits buys memory and costs a little
quality**, and the loss grows as the width shrinks. How much quality a given model loses at a given
width is measured, not assumed: look for that measurement wherever the quantised version is
published.

## Why this decides where a model runs

Take a laptop with 16 GB of memory, which also has to hold the operating system and everything
else open on it. The 7B model at 16 bits, 14 GB, does not fit with room to spare. At 4 bits, 3.5
GB, it does. The 70B model needs 35 GB even at 4 bits, which is a workstation or a server.

That is the practical meaning of parameters. **The count, times the width, says what hardware a
model needs**, and the width is a choice you make with quality in the other pan of the scales.
When you call a model through an API none of this is yours to solve: the provider holds the weights
and you pay per token, which is lesson 3. When you download the weights and run them yourself, it
is the first thing to work out, and lesson 12 is about which providers let you.
