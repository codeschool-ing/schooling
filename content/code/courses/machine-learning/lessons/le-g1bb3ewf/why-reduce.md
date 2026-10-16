---
title: Why fewer columns
version: 1
---

Lesson 16 grouped customers in eight columns and could only describe the groups in tables, because
nobody can look at eight dimensions. **Dimensionality reduction** makes fewer columns out of many while
keeping as much of what matters as it can. There are three reasons to want that, and they ask for
different methods.

- **To look.** Two columns can be drawn. A map of the customers on a page shows groups, gaps, outliers
  and mistakes that no table shows, and a picture is what the marketing team will remember.
- **To feed a model fewer columns.** Lesson 6 met the curse of dimensionality: in many columns every row
  is far from every other, and methods that measure distance suffer. Fewer, denser columns can help, and
  they also make a model faster.
- **To remove redundancy.** Columns that move together say the same thing twice. Folding them into one
  removes the repetition, and sometimes the noise with it.

This lesson has three methods. **PCA** draws new straight axes through the data and keeps the ones along
which the rows spread most; it is linear, fast, exact and can be read. **t-SNE** and **UMAP** bend space
to keep each row near its neighbours; they draw much better pictures and are much worse at everything
else. Knowing which question each one answers is most of using them well.

One thing does not change from lesson 16: **scale first.** Every method here works on distances or
variances, and an unscaled basket in reais would again decide everything by itself.
