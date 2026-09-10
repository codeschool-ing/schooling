---
format: 5
course: deep-learning
---

# deep-learning

**Deep Learning: Neural Networks in Practice** · `co-mhd8vjg2` · 70 h declared · advanced · 20 lessons · `data` · paid

## Reach

In **1 track** — `data-science`(10).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `machine-learning` — the whole of it. Baselines, metrics, overfitting and the discipline of a split. This course is architectures on that foundation.

**Leaves ready:** **nothing.** It is the end of its chain and nothing requires it.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 20 |
| **hours per lesson** | **3.50** |
| section budget | ~150, about 7.5 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **Python with PyTorch, and a GPU** — the first course in the catalogue that needs one |
| browser · database | a notebook · no |
| exercises **blocked** | **~600 (80%), and by something no sandbox design has yet contemplated** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~70 — a perceptron, a computation graph, backpropagation drawn step by step, a convolution moving, attention as a matrix |

## Ageing

**Moderate to severe, and unusually fast.** Lesson 15 is the transformer and lesson 20 is when not to use deep learning — both stable — but the framework surface, the model names and the price of a GPU-hour all move within a year.

## Flags

**1 ·** **The first course in the catalogue that needs a GPU, and it changes the shape of the sandbox question.** Every environment the sweep has found so far is a thing you provision once and share: a shell, a container daemon, a cluster, a database, a topology. **A GPU is metered, per student, per hour, and it is the only environment in the catalogue whose cost scales with enrolment.** A free-tier student running a training loop in a loop is a bill, not a load problem. Nothing in `PLAN.md` or `ROADMAP.md` prices this.

**2 ·** **And the course knows.** Lesson 10 is *"the GPU sitting idle waiting for data"* and lesson 19 is *"Cost: GPU, mixed precision, and training time against the gain"*. Cost is part of the subject, which is the same argument the vendor data courses make: the thing that has to be felt cannot be taught from a description.

**3 ·** **Eighty per cent blocked, the sweep's record, and it beats `python-data` (70%).** Between them, `python-data`, `machine-learning` and `deep-learning` are 230 hours at 70–80% blocked on a runtime — the densest concentration of unbuildable practice in the catalogue, all inside one track and one chain.

**4 ·** **Or it is written as a reading course and says so.** Backpropagation, attention and the classic architectures can be taught with diagrams and pre-computed outputs, honestly, to somebody who will fine-tune rather than train. That is a smaller course than the lesson list promises, and choosing it deliberately beats discovering it after 150 sections are written.
