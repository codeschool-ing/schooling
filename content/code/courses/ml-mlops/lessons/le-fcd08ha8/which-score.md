---
title: Which score, for whom
version: 1
---

The lesson's numbers, for one model on one test month:

| score | value | what it would tell a manager |
| --- | --- | --- |
| accuracy | 86.0% | nothing: the model that knows nothing scores 83.1% |
| precision and recall at 0.5 | 0.685, 0.321 | a cut nobody chose |
| net value at 0.2 | R$ 11,900.00 | what acting on the model is worth, at marketing's prices |
| ROC AUC | 0.790 | the model orders members well |
| average precision | 0.522 against 0.169 | three times better than chance at finding lapses |
| precision at 300 | 195 of 300 | how good the list we can afford is |
| calibration | 0.176 said, 0.169 happened | its probabilities can be multiplied |

**Choosing among them is part of agreeing what the model is for**, and it belongs at the start of a
project, beside the label and the cutoff, not at the end when somebody needs a number for a slide.
Two rules hold almost everywhere.

**One score decides, several are watched.** A release is judged on the score that matches the use:
precision at the budget for the voucher list, net value if the costs are agreed. The others are
logged beside it, because a model can improve the deciding score while something else quietly
gets worse, and calibration is the usual casualty.

**Every score is logged with its baseline and its rows.** "AUC 0.790" means nothing without "on
the members as of 30 November, 530 of 3,130 lapsed". Lesson 7 records exactly that with every
training run, and lesson 9 keeps recording it once the model is live, which is when the labels for
its own predictions finally arrive.

**Whose job is that?** The modeller chooses which scores make sense. The platform guarantees that
they are computed the same way every time, on rows that were not used for choosing, and stored
where the next person can compare against them. A score computed differently each month is a
number that changes for reasons nobody can see.
