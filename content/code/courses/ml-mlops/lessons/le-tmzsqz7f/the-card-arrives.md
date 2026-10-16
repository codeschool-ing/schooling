---
title: The report card arrives
version: 1
---

The scores of 28 February closed on 29 May, and the shop's data now runs to 30 June. **The card
lesson 9 could not read can be read now**, and so can the one for 29 March, the last Sunday whose
90 days have passed:

```
ana@dev:~/ml$ python report_card.py 2026-02-28
{
  "night": "2026-02-28",
  "model_version": "1",
  "members": 3355,
  "lapsed": 624,
  "roc_auc": 0.779,
  "average_precision": 0.521,
  "lapsed_in_top_300": 191,
  "said": 0.174,
  "happened": 0.186
}
ana@dev:~/ml$ python report_card.py 2026-03-29
{
  "night": "2026-03-29",
  "model_version": "1",
  "members": 3429,
  "lapsed": 720,
  "roc_auc": 0.747,
  "average_precision": 0.496,
  "lapsed_in_top_300": 193,
  "said": 0.177,
  "happened": 0.21
}
```

| | test, 30 Nov 2025 | 28 Feb 2026 | 29 Mar 2026 |
| --- | --- | --- | --- |
| ROC AUC | 0.793 | 0.779 | 0.747 |
| average precision | 0.522 | 0.521 | 0.496 |
| lapsed in the top 300 | 190 | 191 | 193 |
| said | 0.177 | 0.174 | 0.177 |
| happened | 0.169 | 0.186 | 0.210 |

**The model got worse, and it got worse in a particular way.** The ranking slipped: AUC fell from
0.793 to 0.747. But the larger change is in the last two rows. The model kept saying about 17.5% of
members would lapse, and the share that actually lapsed rose from 16.9% to 21.0%. **Its probabilities
stopped being calibrated**, and lesson 4's threshold arithmetic, which turns a probability into a
voucher worth sending, rests on them.

The top 300 held up, 193 against 190, because the most likely lapsers are still the people with no
recent visits, and that relationship did not change. Whatever changed is somewhere the top of the
list does not reach.

**The inputs cannot say what changed; the outcomes can, split by group.** One number for 3,429
members averages a group that changed with the many that did not.
