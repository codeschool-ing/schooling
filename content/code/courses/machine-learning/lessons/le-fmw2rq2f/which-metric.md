---
title: Which metric, for which question
version: 1
---

Each metric in this lesson answers one question, and the mistakes come from asking it a different
one. Ana keeps this table next to the frame from lesson 1:

| question | metric | needs a cut? | at Feira em Casa |
|---|---|---|---|
| does acting on the model make money? | **net value** | yes | R$ 21,672 at the break-even cut |
| of the credits sent, how many were worth sending? | **precision** | yes | 0.489 |
| of the leavers, how many were reached? | **recall** | yes | 0.235 |
| one number when the two errors cost the same | **F1** | yes | 0.317 |
| does the model rank leavers above stayers? | **ROC AUC** | no | 0.804 |
| how good is the ranking at the top, on a rare class? | **average precision** | no | 0.322 |
| is the model right more often than not? | **accuracy** | yes | 0.938, and meaningless here |

Three habits follow.

**Report the business metric first, and the rest as explanation.** The retention team asked how much
money the credits make. Precision and recall explain how that number was made; AUC and average precision
say how good the ranking underneath every cut is. None of them replaces it.

**Never quote a cut-dependent metric without the cut.** "Recall of 0.33" means nothing until it is
"recall of 0.33 at a cut of 0.2, with precision 0.42". A number without its cut can be made as large as
anybody wants.

**Compare models on the same rows, with the same metric, and with lesson 2's bootstrap.** A metric
is a measurement with noise in it. Two models whose AUCs differ in the third decimal place have not been
told apart; the interval says whether they have.

One more thing the table shows: at 0.2 the model made R$ 23,448, more than at the break-even cut that
lesson 2 derived from the costs. If the model's chances were honest probabilities, the break-even cut
would be the best one by construction. That it is not means the chances are not quite what they claim,
and that is the first subject of lesson 11.
