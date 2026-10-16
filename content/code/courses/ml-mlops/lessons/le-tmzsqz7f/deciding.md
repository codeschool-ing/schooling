---
title: Deciding, and what the team does instead
version: 1
---

The two models, on the same night, with the same outcomes:

| 29 March 2026 | champion, version 1 | challenger, version 3 |
| --- | --- | --- |
| trained on | 31 August 2025 | 28 December 2025 |
| ROC AUC | 0.747 | 0.745 |
| average precision | 0.496 | 0.500 |
| lapsed in the top 300 | 193 | 196 |
| said, against 0.210 that happened | 0.177 | 0.175 |

**A tie.** Four months newer, and no better at March: the challenger's labels closed on 28 March,
before the rival opened, so it learned the same world the champion did. Neither is calibrated,
because the change that broke calibration is not in the labels of either. The policy says promote
only a challenger that wins, so the alias stays where it is, and the registry says so:

```
ana@dev:~/ml$ python champion.py | head -n 3
version 1  aliases ['champion']  commit c87382e  average precision 0.522  said 0.177
version 2  aliases []  commit 71633df  average precision 0.519  said 0.426
version 3  aliases []  commit 5d9b036  average precision 0.5  said 0.175
```

**On the day a challenger does win, promotion is one command and so is the way back.** The batch
picks up the new version on its next run; the service on its next restart, because lesson 8 pinned
the model at start-up:

```sh
python champion.py 3      # promote: the alias moves, nothing is copied
python champion.py 1      # roll back: the same command, the old number
```

Both versions stay in the registry with their commits and their data, which is what makes the second
line safe: going back is pointing at something that never left.

**And on 30 June, with no model that can be shown to be better, the team still acts:**

- **the split card goes to marketing**, who can answer the young members of Paulista and Pinheiros
  with something a model cannot, an offer that competes with a subscription;
- **`segments.py` joins the nightly checks**, so the gap is watched as each new night's outcomes
  close, and the "retrain early" rule fires the night a strict test can see it;
- **the calendar is written down**: a training night after 1 April closes in July, and a test night
  90 days after that closes in October. That is the first night the evidence can exist.

**That is the honest end of the lifecycle this course has followed.** A model is built from the past,
checked against a later past, and served into a present that keeps moving. Monitoring cannot stop the
present from moving; what it does is make each change visible at the earliest moment the evidence
allows, and keep every version, every score and every outcome, so that the next decision is made with
numbers rather than a guess.
