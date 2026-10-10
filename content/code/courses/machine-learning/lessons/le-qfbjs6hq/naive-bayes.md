---
title: Naive Bayes, for counting words
version: 1
---

The reviews in `reviews.csv` are short sentences, *"Bruised bananas, box was damaged"*, and support
marks some of them as complaints. Turning text into columns is lesson 14's subject; the simplest way
is to **count the words**, giving one column per word in the vocabulary and, for each review, how
many times it uses each. `CountVectorizer` does that.

**Naive Bayes** is a classifier built for exactly this shape of data. It asks, for each class, how
often each word appears in reviews of that class, and scores a new review by multiplying the
evidence of its words together, starting from how common each class is. Fitting is counting, so it
is fast on any amount of text. Save this as `bayes.py`; it trains on the first 2,400 reviews and
tests on the last 600:

```python
# bayes.py
import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB

reviews = pd.read_csv("data/reviews.csv")
train, test = reviews.iloc[:2400], reviews.iloc[2400:]

words = CountVectorizer().fit(train["text"])
bayes = MultinomialNB().fit(words.transform(train["text"]), train["complaint"])
said = bayes.predict(words.transform(test["text"]))
print(f"{len(words.vocabulary_)} words; right on {(said == test['complaint']).mean():.1%} "
      f"of {len(test)} test reviews (always 'no complaint': {1 - test['complaint'].mean():.1%})")

ratio = bayes.feature_log_prob_[1] - bayes.feature_log_prob_[0]   # log P(word|complaint) - log P(word|not)
vocab = np.array(words.get_feature_names_out())
print("words that most suggest a complaint:", ", ".join(vocab[np.argsort(-ratio)[:6]]))
print("words that most suggest the opposite:", ", ".join(vocab[np.argsort(ratio)[:6]]))

chance = bayes.predict_proba(words.transform(test["text"]))[:, 1]
print(f"test reviews scored below 1% or above 99%: {((chance < 0.01) | (chance > 0.99)).mean():.1%}")
```

```
ana@lab:~/ml$ python bayes.py
39 words; right on 92.3% of 600 test reviews (always 'no complaint': 78.2%)
words that most suggest a complaint: bruised, wilted, late, soggy, rotten, missing
words that most suggest the opposite: ripe, lovely, crisp, sweet, tasty, on
test reviews scored below 1% or above 99%: 56.8%
```

**92.3% right**, against 78.2% for a model that never says *complaint*. Because naive Bayes is
counts, it can be read: the words that most suggest a complaint are the ones a person would pick,
*bruised*, *wilted*, *late*, *soggy*, *rotten*, *missing*, and on the other side *ripe*, *lovely*,
*crisp*. The difference of log-probabilities computed in the program is how much more often each
word appears in complaints than in the rest.

The vocabulary is 39 words because the reviews were generated from short phrases. Real reviews have
thousands of words, many of them rare, and naive Bayes copes with that well: every word gets its
own count, and the counts never interact.

Notice that *on* is among the words that suggest **no** complaint. It comes from *arrived on time*,
and the model has no idea that *on* is part of a phrase. It counts words one at a time, and any
meaning that lives in their order is lost, which is the price of turning text into counts; lesson 14
counts pairs of words to recover some of it.
