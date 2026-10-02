---
title: What sampling changes
version: 1
---

The same check, on a different run: one prompt, five samples per message at temperature 0.8, the
run from lesson 19 that voted worse than temperature 0.

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl
350 calls, prompt fbc4c9b1, written to runs/s5.jsonl
ana@lab:~/triage$ pl selfcheck runs/s5.jsonl | tail -n 4
               really wrong  really right
flagged                 102            16
not flagged              19           213
precision 0.86   recall 0.84
```

Recall goes from 0.57 to **0.84**, and precision from 0.73 to 0.86. The checker did not change. The
mistakes did.

## Slips and misconceptions

A sampled answer can be wrong in two ways. It can be a **slip**: the stand-in favoured the right
label, and the draw happened to land elsewhere. Or it can be a **misconception**: the stand-in
favours the wrong label, and the draw found it. The reviewer reads the message without sampling, so
it sees the label the stand-in favours. Two messages show both kinds:

```
ana@lab:~/triage$ pl selfcheck runs/s5.jsonl | grep -E "^(t37|h27)"
t37  wrong  WRONG: the category should be delivery
t37  wrong  WRONG: the category should be delivery
t37  wrong  WRONG: the category should be delivery
t37  wrong  WRONG: the category should be delivery
t37  right  WRONG: it could also be other
h27  wrong  OK
h27  wrong  OK
h27  wrong  OK
h27  right  WRONG: the category should be billing
h27  wrong  OK
```

`t37` is a slip four times over. Temperature 0 answers delivery, which is right, and four samples
drew something else; the reviewer says *the category should be delivery* to each one. The fifth
sample was right and got doubted, as on the temperature-0 run.

`h27` is the gift card again, and a misconception. Four samples said billing, the label the stand-in
believes, and the reviewer passed all four. One sample drew account, the person's label, and the
reviewer **argued it back to the wrong answer**: *the category should be billing*.

At temperature 0 every label mistake is a misconception, because the answer is the favoured label by
definition. That is why recall was 0.57 there and is 0.84 here. **Self-checking catches slips and
misses misconceptions**, and the share of each depends on the run, so a recall measured on one
configuration says little about another. Measure the check on the settings you will ship.

## Real models

The stand-in's rule makes this split exact. For real models the research is mixed, and one result
is worth knowing by name. *Large Language Models Cannot Self-Correct Reasoning Yet* (Huang and
others, 2023) asked models to review and revise their own answers to reasoning problems with no
outside information, and found that this often failed to improve them and sometimes made them
worse, by talking a right answer into a wrong one, as the reviewer did with `h27` above. The authors
also pointed out that some earlier reports of self-correction working had relied on knowing, from
outside the model, when an answer was wrong.

The reading this lesson takes from both is narrow: a model checking itself without new information
has only its own view to check against. Where that view is right and the answer slipped, it helps.
Where the view is wrong, it agrees.
