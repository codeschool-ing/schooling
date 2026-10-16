---
title: Missing values, properly
version: 1
---

Two columns of `churn.csv` have gaps: `rating_90d` is empty for 4,977 rows and `days_since_login` for
15,912. Lesson 3 filled them with −1 so that a tree had a number, and lesson 5 with the training
median so that a sum could include them. Both were placeholders. Doing it properly means asking, for
each column, **why the value is missing**, because the reason decides what to fill in.

- **Missing because it does not exist.** `days_since_login` is empty for every subscriber who does not
  use the app. There is no number of days to find out; the subscriber has never logged in.
- **Missing because nobody recorded it.** `rating_90d` is empty when the subscriber rated no box in
  ninety days. A rating exists in the sense that they liked the boxes more or less, but nobody asked.
- **Missing by accident.** A form field that failed to save, a feed that dropped a day. Here the gap
  carries no information, and filling it with a typical value is right.

The first two kinds can be **information in themselves**. A subscriber who never rates may be one who
does not care, or one who is too happy to bother. That is why `with_gaps` in the previous section added
a 0-or-1 column for each, `no_rating` and `no_login`, beside the median-filled value. scikit-learn
does the same with `SimpleImputer(strategy="median", add_indicator=True)`, which the pipeline of lesson
15 uses.

And in the table those two columns **changed nothing**: R$ 16,424 to R$ 16,360 for the logistic
regression, an AUC that did not move. Both have reasons, and both are worth knowing:

- `no_login` is the same column as `app_user`, upside down. Every non-user has no login and every user
  has one, so the indicator repeated something the model already had.
- `no_rating` does separate two groups, 4.2% against 5.8% cancelling, in lesson 5's training months.
  But with the median filled in, a missing rating already sits in the middle of the scale, where the
  churn rate is about the same, so the line had little left to learn from the flag.

That is a normal result, and the habit is still worth keeping: an indicator costs one column, and on a
dataset where the gaps are not random it can carry a great deal. **The mistake is the opposite one**:
filling a gap that means something with a value that hides it, and then concluding from the model that
the column did not matter.

Two rules about the filling itself. **Compute the fill value from the training rows**, never from all
of them, which is lesson 4's preparation leak. And **for trees, leave the gaps alone**:
`HistGradientBoostingClassifier` learns at each split which side the missing values should go to, so
it uses the gap as information without being told. Filling it in first throws that away.
