---
title: The decision, as a checklist
version: 1
---

The lesson comes down to a few questions, asked in order, before anybody writes a training loop.
**Each one has a measurement behind it from this lesson or an earlier one**, so the answer can be
checked rather than argued.

| question | if yes | where it was measured |
| --- | --- | --- |
| Is the data rows and columns, each column a quantity somebody chose? | Start with boosting, and make the network beat it | the cancer and customer tables, this lesson |
| Do columns have holes, categories, wildly different scales? | Boosting takes them as they are; a network needs each one prepared | `baseline.py`, this lesson |
| Is the input raw and structured: pixels, audio, text? | A network, because the features have to be learnt | `moved.py`, this lesson; lessons 11 and 16 |
| Are there only tens of examples per class? | A simple model, or a pretrained network with a new head | `small.py`, this lesson; lessons 13 and 17 |
| Is the network's lead smaller than the spread between seeds? | It has not won; keep the cheaper model | lesson 18 |
| Does the gain pay for the hours and the hardware? | Train it; otherwise do not | lesson 19 |

**The first row is the one most often skipped.** A team that starts with a network on a table finds
out how good the network is, and never finds out whether a model trained in under a second would
have done as well. Run the baseline first, and the network's result has something to be compared
with on the day it arrives.

The questions do not argue against deep learning. The same checklist sends images, sound and text to
a network every time, and with a pretrained model it sends little data there too. What it refuses is
the habit of choosing the model before looking at the data.

## The end of the course

That closes the course. It began with a perceptron failing XOR in lesson 1 and built every piece a
network is made of by hand: the gradient, backpropagation, the losses, the optimisers, the
regularisers and the normalisations, in NumPy, before PyTorch did the same in a few lines from
lesson 9. Convolutions, sequences, attention and tokens followed, then transfer and fine-tuning, and
the last three lessons were about knowing what a result is worth: its spread, its price, and here,
whether a network was the right tool at all.

**Everything you ran is on your own machine**, in `~/dl`, and every program can be run again,
changed and broken on purpose. That is the best way to keep what the course taught.
