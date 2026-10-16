---
title: Text as columns
version: 1
---

Lesson 6 turned reviews into columns by counting words, and noticed what that loses: *on* came out as a
word that suggests **no** complaint, because it only ever appears in *arrived on time*. It promised that
counting pairs of words would recover some of the order. This section does that, and one more thing.

- **Pairs of words**, also called bigrams, are every two neighbouring words in a review, counted as a
  column of their own: `arrived late`, `on time`, `box was`. `CountVectorizer(ngram_range=(1, 2))`
  makes single words and pairs together.
- **TF-IDF** (term frequency, inverse document frequency) weighs each count by how rare the word is
  across all reviews. A word in every review, such as *and*, says little about any one of them and gets
  a small weight; a word in few reviews gets a large one.

Save this as `text.py`; it trains the same logistic regression on three versions of the text columns,
on lesson 6's split of 2,400 reviews and 600:

```python
# text.py
import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

reviews = pd.read_csv("data/reviews.csv")
train, test = reviews.iloc[:2400], reviews.iloc[2400:]

print("columns from the text      columns   right    AUC")
for name, words in [("single words, counted", CountVectorizer()),
                    ("words and pairs, counted", CountVectorizer(ngram_range=(1, 2))),
                    ("words and pairs, tf-idf", TfidfVectorizer(ngram_range=(1, 2)))]:
    words.fit(train["text"])
    model = LogisticRegression(max_iter=1000).fit(words.transform(train["text"]),
                                                  train["complaint"])
    chance = model.predict_proba(words.transform(test["text"]))[:, 1]
    print(f"{name:25} {len(words.vocabulary_):8} {((chance >= 0.5) == test['complaint']).mean():7.1%}"
          f" {roc_auc_score(test['complaint'], chance):6.3f}")

weight = dict(zip(words.get_feature_names_out(), model.coef_[0]))
print("weights in the last model:", ", ".join(f"{w} {weight[w]:+.2f}" for w in
                                              ["arrived", "late", "arrived late", "on", "on time"]))
```

The vectoriser is fitted on the training reviews only, so the vocabulary, and TF-IDF's idea of which
words are rare, come from rows the test never touches.

```
ana@lab:~/ml$ python text.py
columns from the text      columns   right    AUC
single words, counted           39   94.2%  0.966
words and pairs, counted       524   94.3%  0.964
words and pairs, tf-idf        524   93.8%  0.967
weights in the last model: arrived +0.25, late +2.37, arrived late +2.37, on -1.27, on time -1.27
```

**The pairs made 485 new columns and changed nothing**: 94.2% right with single words, 94.3% with pairs,
an AUC that moved in the third decimal place. The last line says why. `on` and `on time` have exactly the
same weight, and so do `late` and `arrived late`. In these reviews *on* never appears without *time*,
and *late* never without *arrived*, so the pair says nothing the single word did not. The reviews were
written from a fixed set of phrases, and no phrase means something different with its words in another
order.

Real text is not like that. *"Not fresh"* and *"fresh, not bruised"* share both words and mean
opposite things, and there pairs earn their columns. The lesson is the same as for every feature in this
lesson: **add it, measure it, and keep it only if it moves the number that matters.** Here it did not,
and 485 columns that do nothing are 485 columns to compute, store and explain.

TF-IDF did no better either, for a similar reason: the reviews are all a few phrases long, so how often
a word appears in one review is nearly always once. On long documents, where *the* appears forty
times and *mouldy* once, the weighting matters a great deal.

Beyond counting, text can become columns through **embeddings**: a language model turns each review into
a few hundred numbers that place reviews with similar meanings near each other, *rotten* near *mouldy*
even if the model never saw them together. That is the subject of `deep-learning`, and of the courses
on language models after it.
