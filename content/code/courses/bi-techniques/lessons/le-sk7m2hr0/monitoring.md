---
title: Monitoring, and the loop a model makes
version: 1
---

The audit of lesson 18 and the fix of this lesson were both done on one day's customers, 30 June 2025.
**A model that is fair today can stop being fair**, and nothing about it will announce the change.

- **The customers change.** A marketing push in the North, a new delivery route, a price rise like
  the one of September 2025: each changes who the customers are and how they behave, and the model
  was fitted to the old ones.
- **The decision changes.** The club was not the purpose the model was built for. Uses accumulate,
  and each one needs its own audit.
- **The model changes the data.** This is the **feedback loop** of lesson 18. Customers flagged for
  the retention offer get a discount, and some stay because of it. Next year, when the model is
  retrained, those customers are recorded as "stayed", and the model learns that customers like them
  stay. **It learns its own success as a fact about the customers**, and becomes worse at flagging
  exactly the people it used to save.

The defences are routine work, which is why they are often skipped.

- **Repeat the audit on a schedule**, every month or every retrain, with the same table, so a change
  is visible as a change. The audit program of lesson 18 is a dozen lines; it can run every night.
- **Keep a holdout.** A small random share of flagged customers, say one in ten, gets no offer. They
  show what the model's flagged customers do untouched, which keeps the training data honest, and
  they are the control group of an A/B test of the offer itself: the measurement of the save rate
  that lesson 17 called the most fragile number. Lessons 7 to 11 say how big it has to be and how to
  read it.
- **Watch the inputs, not only the outputs.** If the North's median gap moves from 14 days to 7
  because logistics opened a warehouse, the reason for the fix has gone, and the inputs table of
  lesson 18 shows it before any error rate does.

A holdout has a cost: one flagged customer in ten does not get an offer that might have kept them.
That cost is the price of knowing whether the offer works at all, and it should be decided openly, not
left out because it is uncomfortable to write down.
