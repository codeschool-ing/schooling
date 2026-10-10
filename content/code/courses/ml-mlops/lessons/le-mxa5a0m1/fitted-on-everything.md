---
title: Preprocessing fitted on everything
version: 1
---

The fourth shape is the quietest. **Every preprocessing step that learns something from the data is
a small model**, and it leaks if it learns from the test rows.

`StandardScaler` learns a mean and a spread per column. Fitted on all the rows before they are
split, it has seen the test rows' values, and the training rows are scaled with knowledge of them.
`OneHotEncoder` learns which values exist, so fitted on everything it knows about a category that
first appears in the test period. A step that fills missing values with the average learns that
average from whatever rows it is given.

For the scaler, with three thousand rows of stable data, the effect on a score is too small to
measure honestly, and this lesson does not pretend otherwise with a number. **Two preprocessing
steps leak badly, and both are common:**

- **target encoding**, which replaces a category with the average label of the rows that have it,
  so "home shop Paulista" becomes "0.21". Fitted on all rows, it writes the test labels into the
  features;
- **feature selection by correlation with the label**, done once over all the data before the
  split, which picks the columns that happen to fit the test rows too.

**The protection is structural, and lesson 2 already used it.** `classify.py` put the scaler and the
encoder inside the pipeline with the model, so `fit` on the training rows fits all three and
`predict_proba` on new rows only applies them. Nothing can be fitted on the test rows because
nothing is fitted outside `fit`. When a data engineer is handed preprocessing code to put into
production, the question to ask is whether the transformations are part of the model object or
were computed in a notebook beforehand. **Only the first can be retrained the same way twice.**
