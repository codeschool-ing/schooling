---
title: Fewer bits per weight
version: 1
---

The 4-bit column in section 03 is not a different model. It is the same weights **stored with less
precision**: each 16-bit number replaced by a 4-bit one, plus a little extra per group of weights
to say how to scale them back. That is **quantisation**, and it is the reason open models run on
ordinary hardware at all.

What it buys is in the table: the 8B goes from 16 GB to 4 GB, the 70B from 141 GB to 35 GB. What it
costs is **precision**. A 4-bit number can take sixteen values. The quantisation formats are clever
about which sixteen, and about keeping the most sensitive weights at higher precision, but some
information is gone.

## How much it costs, and why you measure it

The pattern reported across many models, by the people who build the formats, is roughly this:

- **8 bits** is close to indistinguishable from 16 for most tasks;
- **4 bits** loses a little: a point or two on benchmarks, more on some tasks than others;
- **below 4 bits** the losses grow quickly, and small models suffer more than large ones.

"A little on benchmarks" is the sentence lesson 1 section 09 warned about: somebody else's task.
The loss is uneven, and the tasks that suffer first are the precise ones: arithmetic, following a
strict output format, a language that was a small share of the training text. **Ana's extraction
task asks for exact JSON**, which is precisely the kind of thing to check rather than assume.

So a quantised model is **a different candidate** in lesson 5. `llama-3.1-8b at 16 bits` and
`llama-3.1-8b at 4 bits` are two rows in the evaluation, each with its own score, and the second
one is only cheaper if its score is still good enough.

## Where you meet it without choosing it

Lesson 2's `fp8` entries were quantisation done by a host, at 8 bits. Ollama's models (lesson 14)
are quantised by default, and the tag in the name says how. Whenever a price or a download size
looks remarkably small for the parameter count, the explanation is almost always here, and the
question to ask is **how many bits**.
