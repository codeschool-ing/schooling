---
title: When the team can only make so many calls
version: 1
---

So far a credit has been free to send in any number: an e-mail with a code in it. Change one fact.
**The retention team decides the credit works better offered on the phone**, and it has people for
150 calls a month. Now the question is not "who is above the cut" but "who are the 150 most worth
calling", and a cut that selects 400 people in one month and 90 in the next is no use to anybody
planning shifts.

**A budget turns the cut into a count.** Rank each month's subscribers by chance and take the top
of the list. Save this as `capacity.py`:

```python
# capacity.py
import pandas as pd

from feira import net_value

scores = pd.read_csv("scores.csv")
rank = scores.groupby("snapshot")["chance"].rank(ascending=False, method="first")
print("calls a month   sent   precision   net value")
for calls in [50, 100, 150, 200, 300]:
    send = rank <= calls
    print(f"{calls:13}  {send.sum():5,}  {scores.loc[send, 'churned'].mean():9.3f}"
          f"   R$ {net_value(scores['churned'], send):8,.0f}")
```

`method="first"` breaks ties by order of appearance, so every month gets exactly the number asked
for. Here every call still costs R$ 40 and is worth R$ 144 when it reaches a leaver; on a real
phone campaign both numbers would be different, and the frame is where they get written down.

```
ana@lab:~/ml$ python capacity.py
calls a month   sent   precision   net value
           50    300      0.607   R$   14,208
          100    600      0.505   R$   19,632
          150    900      0.460   R$   23,616
          200  1,200      0.415   R$   23,712
          300  1,800      0.342   R$   16,560
```

**At 150 calls a month the list makes R$ 23,616**, more than the break-even cut did, and for a
reason worth seeing. A count per month is immune to the September problem: when risk rose for
everybody, the cut let fewer people through than it should have, while the top 150 is the top 150
whatever the level of the chances. **A list uses only the ranking, and the ranking is what
survived.**

Precision falls as the list grows, from 0.607 at 50 calls to 0.342 at 300. Each extra call reaches
somebody less likely to leave than the call before it, and the list stops paying where the share
of leavers among the extra calls falls below 0.278: the break-even line again, in another form.
Between 150 and 200 calls the money barely moves, and by 300 it has lost more than R$ 7,000. So the
team's 150 is a sensible size, and the table is the argument to bring if somebody proposes hiring
for 300.

Two consequences for how a model is judged when it will be used this way:

- **Calibration no longer matters for who is called.** Only the order is used. A model with
  distorted chances and a good ranking is as useful as a calibrated one.
- **The metric to compare models on is the value of the top of the list**: precision among the
  first 150 each month, or the money it makes. Average precision from lesson 10 weighs the whole
  curve, and here only the first few hundred places count.
