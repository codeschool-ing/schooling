---
title: More sources is not more answers
version: 1
---

The obvious way to make sure the answer is in the prompt is to send more: raise `k`, and whatever the
search ranked fourth or eighth comes along too. `sweep.py` measures what that buys, for the 26
answerable questions of `eval.jsonl`, at six values of `k`:

```
ana@lab:~/rag$ python sweep.py
  k  found  tokens  alike  above floor
  1  20/26      60      0          1.0
  2  26/26     116      3          1.8
  3  26/26     171      3          2.6
  5  26/26     278      7          3.4
  8  26/26     441     12          4.1
 12  26/26     660     16          4.7
```

The columns are: how many questions had a fact of the answer somewhere in what was retrieved, the
tokens of source text per question, how many pairs of retrieved chunks were 0.8 similar or more, and
how many retrieved chunks on average would pass lesson 6's floor of 0.5.

**Retrieval stops improving at two.** With one source, 20 of 26 answers were in the prompt; with two,
all 26; after that, nothing more to find. **The tokens keep growing in a straight line**, 116 at two
and 660 at twelve, and so do the pairs of chunks that say nearly the same thing. Everything after
the second source is cost: the same answers, more text around them.

## What the extra text does to a model

extract-1 is not distracted by anything. It ranks every sentence by its similarity to the question
and copies the best, so a prompt with twelve sources gives it the same answer as a prompt with two,
and this lab cannot show what the extra text does to a language model. Two published measurements
can:

- **Irrelevant text lowers accuracy.** Shi and others, in *Large Language Models Can Be Easily
  Distracted by Irrelevant Context* (ICML 2023), added a sentence that had nothing to do with the
  question to arithmetic word problems, and the models they tested got noticeably more of them
  wrong.
- **Where the answer sits matters.** Liu and others, in *Lost in the Middle: How Language Models Use
  Long Contexts* (TACL 2024), put the passage with the answer at different positions among many
  others and found that models used it best at the beginning or the end of the input, and worst in
  the middle, including models built for long inputs.

Neither paper measured your model on your documents, and models have changed since. They are the
reason to treat every extra source as a cost until a measurement says otherwise, and the reason the
placement section exists. The test that decides it for a real deployment is lesson 8's, run against
the real model at two values of `k`.
