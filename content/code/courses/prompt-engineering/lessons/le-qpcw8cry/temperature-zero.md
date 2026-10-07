---
title: Temperature 0 and the same answer twice
version: 2
---

At temperature 0 there is no draw. **The word with the highest score is taken every time**, and
that rule has a name, greedy decoding. `toylm dist` shows what is left to choose from:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 0
context: trigram after 'coffee is'
  hot      100.0%  ########################################
```

One word with all of the share. The seed decides how a draw comes out, so two runs with
different seeds are the way to check whether anything was drawn at all:

```
ana@lab:~/pe$ toylm generate "the coffee is" --temperature 0 --seed 1
hot.
-- finish: end, prompt 3 tokens, output 2 tokens
ana@lab:~/pe$ toylm generate "the coffee is" --temperature 0 --seed 2
hot.
-- finish: end, prompt 3 tokens, output 2 tokens
```

The same text, the same stop, the same count. At temperature 1 the same seeds give different
sentences, because there the seed is doing work:

```
ana@lab:~/pe$ toylm generate "the coffee is" --temperature 1 --samples 3
[seed 1] hot.
[seed 2] cold and the cat wakes.
[seed 3] hot.
```

**At temperature 0, `toylm` is deterministic: the same prompt gives the same output on every run,
on every machine.** That is what you want from a test, a pipeline that extracts fields from
documents, or anything whose output another program reads.

## When two words tie

Greedy decoding needs a winner, and sometimes there is none:

```
ana@lab:~/pe$ toylm next "is the"
context: trigram after 'is the'
  bread     33.3%  #############
  coffee    33.3%  #############
  soup      33.3%  #############
ana@lab:~/pe$ toylm dist "is the" --temperature 0
context: trigram after 'is the'
  bread    100.0%  ########################################
```

Three words share the top score exactly, and `toylm` took `bread`. Nothing about the café chose
it. The program sorts tied words alphabetically, so `bread` wins every time, and the output stays
the same because the tie is broken by a rule.

## On a hosted model, close to deterministic and not guaranteed

**A model behind an API at temperature 0 is close to deterministic, and providers do not promise
more than that.** Two requests with the same prompt usually return the same text, and sometimes
they do not. The reasons are in the machinery around the model, not in the idea of temperature:

- a large model computes its scores with floating-point arithmetic on many processors at once,
  and the order in which partial sums are added can differ between requests. When two tokens
  are nearly tied, a difference in the last digit can change which one is on top. After one
  different token, the rest of the text follows a different path;
- requests are often grouped with other people's requests and run together, and how a batch is
  formed can change the arithmetic;
- the model behind a name can be updated, which changes everything at once.

Some APIs also accept a seed, which makes sampled output repeatable more often. Read what the
provider's documentation says it guarantees, and the date on that page, before you build on it.
Measure it on yours: send the same prompt several times at temperature 0 and compare. On the local
model, ten times:

```
ana@lab:~/pe$ for i in 1 2 3 4 5 6 7 8 9 10; do ask "In one sentence, describe the coffee at a small café." --temperature 0 --plain; done | sort | uniq -c
     10 The café's coffee is a specialty blend of expertly roasted beans, carefully selected to bring out a rich, smooth flavor with hints of chocolate and a subtle acidity that complements the cozy, intimate atmosphere of the small café.
```

Ten replies, one text. That is one short prompt on one machine, and it is not a rate. While this
course was recorded, the same model at temperature 0 did give two different replies to the same longer prompt on two runs, in lessons 4, 6 and 7. Each transcript there is one run, and the
sentence under it describes that run.

**The practical rule: temperature 0 makes variation rare, and your code still has to handle it.**
A program that breaks when two answers differ by one word was going to break anyway, on the day
the model behind the name changed.

Temperature 0 also does not make an answer right. It makes the model give its most likely answer
every time. When the most likely answer is wrong, you get the same wrong answer on every run, and
a wrong answer that never changes looks like a fact. Lesson 5 is about why likely and true can
part company.
