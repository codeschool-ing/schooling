---
title: What sampling changes
version: 2
---

The same check, on a different run: one prompt, five samples per message at temperature 0.8, over
the forty dev messages.

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl
200 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/s5.jsonl
ana@lab:~/triage$ python3 selfcheck.py runs/s5.jsonl | tail -n 4
                 really wrong  really right
flagged                    33            84
not flagged                13            70
precision 0.28   recall 0.72
```

Of 200 replies, 46 were really wrong. The reviewer flagged 117 and caught 33 of the 46: recall 0.72,
precision 0.28. Against a coin, flagging 117 of 200 at random would give a precision of 46 out of
200, 0.23, and a recall of 0.59. The check is a little better than chance here too, and not much.

## Slips and misconceptions

There is a reason to expect sampling to help a reviewer. A sampled answer can be wrong in two ways.
It can be a **slip**: the model favoured the right label, and the draw happened to land elsewhere.
Or it can be a **misconception**: the model favours the wrong label, and the draw found it. A
reviewer that reads the message without sampling sees the label the model favours, so it should
catch slips and pass misconceptions. At temperature 0 every label mistake is a misconception, since
the answer is the favoured label by definition, and so a reviewer ought to do better on a sampled
run than on a run at 0.

Here recall went from 0.69 to 0.72 and precision fell from 0.40 to 0.28. Lesson 19 found why there
was little for the argument to work on: the samples agreed on most messages, so most sampled
mistakes were the same misconceptions temperature 0 made. And a reviewer that flags most replies for
an invented reason does not get better when the mistakes get easier. **Whether self-checking helps
is a measurement on your model and your settings**, and this one says it barely helps here. A
recall measured on one configuration says little about another, so measure the check on the
settings you will ship.

## What others found

For larger models the research is mixed, and one result is worth knowing by name. *Large Language
Models Cannot Self-Correct Reasoning Yet* (Huang and others, 2023) asked models to review and revise
their own answers to reasoning problems with no outside information. It found that this often failed
to improve them and sometimes made them worse, by talking a right answer into a wrong one. The
authors also pointed out that some earlier reports of self-correction working had relied on knowing,
from outside the model, when an answer was wrong.

The reading this lesson takes from both is narrow: a model checking itself without new information
has only its own view to check against. Where that view is right and the answer slipped, it can
help. Where the view is wrong, it agrees. And where, as here, the model is small, it may not
be checking much at all.
