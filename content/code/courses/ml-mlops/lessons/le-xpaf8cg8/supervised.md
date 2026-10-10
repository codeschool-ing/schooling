---
title: Supervised learning, from answers already known
version: 1
---

**Supervised learning is learning from examples that come with the answer.** Each row is a member
described in numbers, and beside it the thing that later happened to them. The algorithm's job is
to find a function from the numbers to the answer that is right as often as possible on rows it was
given, in the hope that it stays right on rows it was not.

The hope is the interesting part, and the word *supervised* hides it. The supervisor is not a
person; it is the past. You can only supervise with answers you already have, so **every
supervised model learns from a time when the outcome was over**, and is then used at a time when
it is not. Everything that goes wrong between those two times is the subject of lessons 3 and 10.

## The examples

The first program turns the shop into examples. Save it in `~/ml` as `features.py`; every later
program in the lesson imports it.

```schooling-example
{
  "language": "python",
  "file": "features.py",
  "parts": [
    {
      "code": "\"\"\"features.py: one row per active member as of a cutoff day, and whether they lapsed.\n\nA member is active at the cutoff if they bought something in the 180 days\nbefore it, and lapsed if they then bought nothing in the 90 days after it.\n\"\"\"\nimport sqlite3\n\nimport pandas as pd\n\n",
      "note": "The definitions this whole course runs on. **Active** means bought something in the 180 days up to the cutoff; **lapsed** means bought nothing in the 90 days after it."
    },
    {
      "code": "QUERY = \"\"\"\nWITH recent AS (\n  SELECT p.member_id, p.day, p.shop,\n         (SELECT sum(price_cents) FROM lines l WHERE l.purchase_id = p.purchase_id) AS cents\n  FROM purchases p\n  WHERE p.day > date(:cutoff, '-180 days') AND p.day <= :cutoff\n)\n",
      "note": "`recent` is every visit in the 180 days up to `:cutoff`, with what it cost. Only members with a row here appear in the result, which is what makes them active."
    },
    {
      "code": "SELECT m.member_id, m.channel, m.age_band, m.home_shop,\n       julianday(:cutoff) - julianday(m.joined)        AS tenure_days,\n       julianday(:cutoff) - julianday(max(r.day))      AS recency_days,\n       count(*)                                        AS visits_180d,\n       sum(r.cents)                                    AS spend_180d,\n       avg(r.cents)                                    AS basket_avg,\n       avg(r.shop = 'Online')                          AS online_share,\n       count(DISTINCT r.shop)                          AS shops_180d,\n",
      "note": "The features: one number per member, each computed from days on or before the cutoff and never after it."
    },
    {
      "code": "       NOT EXISTS (SELECT 1 FROM purchases f WHERE f.member_id = m.member_id\n                   AND f.day > :cutoff AND f.day <= date(:cutoff, '+90 days')) AS lapsed\nFROM members m JOIN recent r USING (member_id)\nGROUP BY m.member_id\n\"\"\"\n\n",
      "note": "The label, and the only line that reads the future: a purchase in the 90 days after the cutoff. **For a cutoff less than 90 days ago the future is not over yet**, and this line answers 1 for members who simply have not had time to come back. Lesson 3 is about that."
    },
    {
      "code": "NUMERIC = [\"tenure_days\", \"recency_days\", \"visits_180d\", \"spend_180d\", \"basket_avg\",\n           \"online_share\", \"shops_180d\"]\nCATEGORICAL = [\"channel\", \"age_band\", \"home_shop\"]\n\n\ndef build(cutoff, path=\"shop.db\"):\n    with sqlite3.connect(path) as db:\n        return pd.read_sql_query(QUERY, db, params={\"cutoff\": cutoff})\n",
      "note": "Two lists the later programs use to pick columns, and the one function they call. A cutoff is a date as text, `2025-09-30`."
    }
  ]
}
```

**A cutoff is the day the examples are described as of.** Everything to the left of it becomes
features, everything in the 90 days to its right becomes the label. Pick 30 September 2025, and the
90 days after it ended on 29 December, long before the database's last day: every label is known.

## The model

Now the learning. Save this as `supervised.py`:

```python
"""supervised.py: learn who lapses, from members whose outcome is already known."""
from sklearn.linear_model import LogisticRegression

import features

COLUMNS = ["recency_days", "visits_180d", "spend_180d"]

past = features.build("2025-09-30")   # the 90 days after this cutoff are history
model = LogisticRegression(max_iter=1000).fit(past[COLUMNS], past["lapsed"])
print(f"learned from {len(past)} members; {past['lapsed'].mean():.1%} of them lapsed")

now = features.build("2025-11-30")    # two months later: other members, other days
now["p_lapse"] = model.predict_proba(now[COLUMNS])[:, 1].round(2)
riskiest = now.sort_values("p_lapse", ascending=False).head(5)
print(riskiest[["member_id", *COLUMNS, "p_lapse", "lapsed"]].to_string(index=False))
```

`LogisticRegression` is one of the oldest learning algorithms and still one of the most used: it
finds one weight per feature and turns their weighted sum into a probability between 0 and 1.
**`fit` is the training**; it reads the examples from 30 September. **`predict_proba` is the
prediction**; it is asked about the members as they stood on 30 November, two months later, which
the model never saw. Their real outcome is printed beside the guess, because for a cutoff that old
the database already knows it.

```
ana@dev:~/ml$ python supervised.py
learned from 2940 members; 17.0% of them lapsed
 member_id  recency_days  visits_180d  spend_180d  p_lapse  lapsed
      1670         178.0            1        9980     0.86       1
      1470         179.0            1        6990     0.86       1
      1569         178.0            1        3990     0.86       1
      3022         179.0            1        9980     0.86       1
       418         179.0            1       12980     0.86       1
```

Read the columns of one row. Member 1670 had not visited in 178 days, had come once in six months,
and the model gave them 0.86. They did not come back. The five at the top of the list all have a
recency close to 180 days, the edge of what counts as active, and one visit: the model has learned
that the longer since the last visit, the likelier the member is gone, which is what a person would
have guessed.

**What a person would not have guessed is the number.** The rule from the first section, "120 days
means lapsed", says yes or no. The model says 0.86 for these five and something smaller for the
member with recency 150 and four visits, and lesson 4 shows that a probability is what lets the
marketing team choose how many vouchers to send.

Two words for later. **Classification** is supervised learning where the answer is a category,
like this one. **Regression** is supervised learning where the answer is a quantity, like how much
a member will spend next month. Lesson 2 does both.
