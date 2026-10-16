---
title: The model, or the months
version: 1
---

A chance can be wrong for two quite different reasons. **The model may distort**: some algorithms
push their chances towards the middle or away from it, and some settings, like the class weights of
lesson 13, inflate them on purpose. Or **the world may move**: the model was right about the months
it learned from, and the months it is scored on are different. The two need different cures, and
the second has none in this lesson.

Telling them apart takes one more grouping, by month instead of by chance. Save this as
`by_month.py`:

```python
# by_month.py
import pandas as pd

scores = pd.read_csv("scores.csv")
months = scores.groupby("snapshot").agg(said=("chance", "mean"), happened=("churned", "mean"))
print(months.round(3).to_string())
```

```
ana@lab:~/ml$ python by_month.py
             said  happened
snapshot                   
2025-07-01  0.053     0.047
2025-08-01  0.053     0.050
2025-09-01  0.053     0.072
2025-10-01  0.050     0.069
2025-11-01  0.048     0.069
2025-12-01  0.048     0.060
```

**July and August are close**; if anything the model says a little too much. Then in September
the share who cancel jumps from 5.0% to 7.2%, and the model goes on saying 5%. That is the price rise
lesson 3 met: every box became 12% dearer on 1 September 2025, and for some months more people left.
The model learned from months before the rise. It had never seen what a sudden rise does, so it
had nothing to learn the jump from, and a rise felt by everybody at once moves the level of risk
far more than the order of who is most at risk.

So this model is not distorting. Its chances were honest about the world it learned from, and the
world changed under it. Two consequences follow, and both come back later in the course:

- **The ranking survived.** The months after the rise still put leavers above stayers, which is
  why the money held up at all. A shift that moves everybody's risk together leaves the order of
  the list alone, and the order is what a top-of-the-list policy uses.
- **The level did not.** Any decision that compares a chance with a fixed number, as the break-even
  cut does, inherits the error. Lesson 22 is about noticing this while it happens, from the scores
  and the labels as they arrive, rather than six months later in a lesson.

**Nobody could have fixed this in June.** The months before July were all the data there was, and
they said 5%. A cut of 0.2 won on the test months because of something that happened after the
cut had to be chosen. Picking 0.2 now, having seen the result, would be the leakage of lesson 4 in
a different coat.
