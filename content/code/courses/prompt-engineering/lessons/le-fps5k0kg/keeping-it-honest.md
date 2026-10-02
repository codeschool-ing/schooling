---
title: Keeping the search honest
version: 1
---

A search that tries many prompts and keeps the top score will always find a top score. **What the
score cannot tell you on its own is whether the winner is good, or merely the one that happened to
fit these few examples.** Four habits keep the method honest, and the workbench shows three of
them.

## Score the winner on examples it was not chosen on

The winner was picked because it did best on `tests.tsv`. That makes its 4/4 an optimistic number:
the choice itself used those four examples up. The honest measure is a second set, kept back from
the start and never used to choose anything, a **held-out set**:

```
ana@lab:~/pe$ cat held.tsv
café	full
soup	tomato
cake	gone
ana@lab:~/pe$ ape best.txt held.tsv
1/3  the {x} is
        soup    wanted tomato  got hot
        cake    wanted gone    got sweet
best: the {x} is
```

Four out of four became one out of three. Nothing changed in the template or the model; only the
examples did. **The held-out score is the one to report**, and it is the one a user meets, because
users bring inputs nobody chose the prompt on.

The rule has a trap in it. Look at the miss on `soup`, edit the template to fix it, and score again
on `held.tsv`, and the held-out set has become a second set to choose on. Its score is optimistic
from then on, exactly as the first one was. A held-out set measures honestly once per decision;
after that you need fresh examples.

## Few examples, many candidates

Overfitting is the general name for a choice that fits the examples it was made on better than the
task. Two things make it worse, and APE has both by design. **The fewer the examples, the more a
lucky candidate can win by chance**, and four examples is very few. And the more candidates you
score, the more chances one of them has to be lucky. A search over a hundred proposals and a
dozen examples will find something that looks excellent on those twelve.

The remedy is boring and it works: more labelled examples than feels necessary, drawn from the
inputs the prompt will really see, with the held-out share kept large enough to mean something.

## The metric decides what "best" means

`ape` gives a point only when the first word matches exactly. Read the second miss again. The file
`toylm` learnt from says `the cake is sweet` three times and `the cake is gone by noon` twice, so
`sweet` is a true answer that the label did not list. **The metric scored a correct reply as
wrong**, and a search driven by that metric would push towards prompts that say `gone`, whether or
not that is what you wanted.

Every metric has a version of this. Exact match punishes a right answer in other words; a metric
that rewards length finds wordy prompts; a model asked to grade replies has preferences of its own.
Choosing the metric is choosing what the search will optimise, so write it down and check it on a
few replies by hand before trusting a ranking built on it.

## Keep a person reading the winner

The search reported `best: it is a cold day and the {x} is`. It tied with `the {x} is` at 4/4, and
`ape` keeps the first top score in the file. **A person reading the two sees at once that the extra
words do nothing**: `toylm` only ever looks at the last two, so the cold day never reaches it. The
held-out run above used the short one for that reason.

On a large model the reasons are less obvious and reading matters more. A winning prompt can carry
an assumption you would not sign, such as "always answer yes if unsure", that happened to score
well because most labels were yes. It can contain a phrase copied from one of the examples, which
works on that example and nowhere else. Nobody catches those from a score. The program proposes and
measures; **a person approves what goes into production**, the same division of work as the loop
in lesson 29 that holds an e-mail until somebody confirms it.

## Where the course ends

That is the last technique of this course. Every lesson since lesson 2 has said a prompt is
something you write, test and change, and this one hands part of the writing to a program while
keeping the testing yours.

::: track ai prompt
The next course in your track, `prompt-reliability`, starts from that testing: test sets,
evaluation metrics, and versioned prompts whose every change is measured.
`ai-security`, further along the track, returns to lesson 7 and treats prompt injection as the
security problem it is.
:::

::: track *
Two courses build directly on this one. `prompt-reliability` turns the testing in this lesson into
a practice: test sets, evaluation metrics, and versioned prompts.
`ai-security` returns to lesson 7 and treats prompt injection as the security problem it is,
and it is in every track that holds this course.
:::
