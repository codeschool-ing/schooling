---
title: The frame, three months on
version: 1
---

Lesson 1's frame was written before any code: the decision, the row, the moment, the target, what a
mistake costs, what the model must beat, how it will be tested. Twenty-one lessons later Ana has a model
that beats the rules, a cut set by the costs, a fairness audit, a file, an address and three months of
evidence. The frame gains its last rows, and they are the ones that keep the others true:

| | Feira em Casa, churn |
|---|---|
| on the first of the month | `monthly.py` scores the snapshot with the named model and keeps the file; `inputs.py` runs on the same rows |
| an input alarm | a value never seen in training, a column suddenly missing, a stability index above 0.25 that nobody can explain |
| a month later | `labels.py` and `where.py` on the answers: AUC, mean chance against what happened, promised against delivered, the ratio by plan, city and age band |
| an outcome alarm | a group whose ratio stays clearly away from 1 for two months, or delivered value below half of promised |
| refitting | every quarter on everything labelled, and sooner when an alarm has a cause the data can fix |
| switching models | only after the new one beats the old on a month neither learned from, and with the old file kept |
| who is told | the retention team, when an alarm has a cause the columns do not describe |

None of the rows is clever. Each is the answer to something that happened in this lesson or in one of
the twenty-one before it, and each one is cheap now and expensive to add after the first time it was
needed.

**The last row is the one this course has been heading towards.** A model is a summary of how the world
behaved while its data was being collected. It cannot know that a competitor opened, that a price rose,
that a plan was launched; it can only, when the labels come in, show that something it did not know about
has happened, and to whom. The people who run the business know the things it cannot. What the course
has given you is the half that turns their knowledge and the model's evidence into one decision: the
frame that says what is being decided, the test that says whether the model helps, and the checks that
say, every month, whether it still does.

Two courses go further from here. **`deep-learning`** is the course built on this one: models
for images, text and sequences, where the features are learned rather than written, and everything from
lesson 1 to lesson 4 still applies unchanged. **`ml-mlops`** is the machinery around this lesson: the
monthly run on a schedule, models in a registry instead of a folder, alarms that page someone, and the
refit as a pipeline rather than an afternoon.
