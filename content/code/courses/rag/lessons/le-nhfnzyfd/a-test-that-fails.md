---
title: A test that fails the build
version: 1
---

A test that a person has to remember to run is run when somebody remembers. The last step is to make
the evaluation part of every change: run it automatically, and make it **fail** when quality drops
below a line, so that the change cannot be deployed until somebody looks.

## The held-out run, at last

The comparisons above were all on the dev split. The decision they support, keeping the floor at 0.5
and three sources, is now made, so the held-out third can be used, once, to check it:

```
ana@lab:~/rag$ python evaluate.py --split held-out --min-correct 0.7; echo "exit $?"
held-out: 10 questions, 8 answerable, floor 0.5, k 3
retrieval  recall@1 7/8  recall@3 8/8  recall@5 8/8  MRR 0.94
answers    correct 9/10  refused rightly 2/2  faithful 10/10
exit 0
```

**9 of 10 correct on questions that played no part in any decision**, both unanswerable ones refused,
and exit status 0. The dev split said 15 of 20; held-out says 9 of 10. With ten questions the two are
not meaningfully different, and that is what one hopes for: a held-out score far below the dev score
would say the choices were fitted to the dev questions.

## A change that should not ship

Suppose somebody raises the floor to 0.7 to make the assistant more cautious:

```
ana@lab:~/rag$ python evaluate.py --split held-out --min-correct 0.7 --floor 0.7; echo "exit $?"
held-out: 10 questions, 8 answerable, floor 0.7, k 3
retrieval  recall@1 7/8  recall@3 8/8  recall@5 8/8  MRR 0.94
answers    correct 6/10  refused rightly 2/2  faithful 10/10
FAIL: 6/10 correct is below 70%
exit 1
```

**Correctness fell to 6 of 10 and the run exited with status 1.** Retrieval did not change, recall@3
is still 8 of 8; what changed is that the floor now refuses answerable questions whose best chunk
scores between 0.5 and 0.7. A continuous integration job that runs this command on every pull request
blocks that change with a message saying why.

## What the bar should be

The `--min-correct 0.7` is a judgement, like every threshold in this course. Three ways of setting it,
in increasing order of care:

- **Below today's score, by a margin**: the test stops regressions without demanding improvements.
  Here, 9 of 10 today and a bar of 0.7 leaves room for one question to flip on a small set.
- **Per property**: separate bars for recall@3, correctness and faithfulness, so a drop in one is not
  hidden by a gain in another.
- **Per kind of question**: the identifier questions of lesson 6 and the customer questions here can
  have their own bars, because a change can help one and hurt the other.

## What it costs to run

The evaluation calls the search and the generator once per question. Against a real provider that is
a real bill, small for thirty questions and noticeable for three thousand, and a judge doubles it.
Two common arrangements: the full set nightly, and a fixed sample of a few dozen on every pull request.
Lesson 17 counts what a query costs, and an evaluation run is just that many queries.

Lesson 5's `check_index.py` checks the index; this checks the answers. Together they are what lets a
team change the chunker, the model or the prompt on an ordinary afternoon and know by the evening
whether it made things better.
