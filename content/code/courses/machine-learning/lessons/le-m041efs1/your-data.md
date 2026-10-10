---
title: Your data, from a program you can read
version: 1
---

The data this course models is not a download. It comes from one Python program, printed in full
at the end of this section, which you save in `~/ml` and run once. It draws every subscriber,
delivery and review from a random number generator started with a fixed seed, so **your files
come out byte for byte the same as the ones in every transcript**, and every score in the course
is the score you get.

## The company

**Feira em Casa** does not exist. It sells a weekly box of fruit and vegetables by subscription
in five cities: São Paulo, Campinas, Rio de Janeiro, Belo Horizonte and Curitiba. A subscriber
picks a box size and a plan, weekly or fortnightly, can skip a week, rates what arrives, and can
cancel whenever they like. Ana is its first data scientist, and the program writes what its
systems would hand her:

| file | one row is | used in |
|---|---|---|
| `churn.csv` | a subscriber on the first day of a month, from July 2024 to December 2025, and whether they cancelled that month | most lessons |
| `churn_2026.csv` | the same, for January to March 2026, with no answer yet | lessons 15, 21 and 22 |
| `churn_2026_labels.csv` | the answers for those three months, which arrive later | lesson 22 |
| `deliveries.csv` | one delivery in 2025 and how many minutes it took | lessons 5, 7 and 12 |
| `reviews.csv` | a written review, its stars, and whether support filed it as a complaint | lessons 6 and 14 |
| `baskets.csv` | a customer and what share of their spending goes on each kind of food | lessons 16 and 17 |
| `addons.csv` | a customer, an extra product they added to a box, and how many times | lesson 18 |

**A warning before you scroll down to it.** The program decides what causes a cancellation, and
the code says so. Reading it now is reading the answers before the questions: lesson 4 asks you
to find two columns that should not be there, and lesson 22 asks you to notice that something
changed in 2026. Save it without studying it, and come back to it after lesson 22, when it reads
as a list of everything the course found.

## Making the files

Open a new file in `~/ml` called `make_data.py`, paste the program into it and save. Then run it.
It writes a folder called `data` and prints what is in it:

```
ana@lab:~/ml$ python make_data.py
addons.csv               15,389 rows
baskets.csv               1,200 rows
churn.csv                62,885 rows
churn_2026.csv           13,154 rows
churn_2026_labels.csv    13,154 rows
deliveries.csv            6,000 rows
reviews.csv               3,000 rows
```

To know that your copy is the one the course ran, compare these with yours. One character pasted
wrong changes a line here:

```
ana@lab:~/ml$ sha256sum data/*.csv
6cbcd7cd92e22db27fb35e6699cc38259c03291c6d50251f1ed5e9d909ceba8e  data/addons.csv
66d5de517cd78ffade1db2691ff7e535b525769add7fae95979e304a789734e2  data/baskets.csv
500d90cc1cfdfced677236baa90fb269e5c2731b344e36cd361e454b535c257a  data/churn.csv
fb6db78af315b7b13201b369d89594651e0c7aea1cebf56337c15b5cf58daa3e  data/churn_2026.csv
6c3fa978c83e3d207b23be0eaab1fc15c81a0c2824af0967a8b99b875b7d2afe  data/churn_2026_labels.csv
95cd6f29ab06edf738807dde741116b4f1b3096abd2d87c25ba55bdcd965b5e9  data/deliveries.csv
49ae3de8815e88429d121dbd927b6c991c56f9af37da3b5c176eab24f7a3d818  data/reviews.csv
```

If one line differs, the paste is the first suspect. The second is the libraries: NumPy's random
numbers are fixed for a given version, and `requirements.txt` pins it for exactly that reason.

## A first look

`head` shows the first lines of a file as they are on disk, before pandas has had an opinion
about them:

```
ana@lab:~/ml$ head -3 data/churn.csv
customer_id,snapshot,city,age,app_user,payment,plan,box,channel,tenure_months,price_month,orders_90d,skips_90d,late_90d,complaints_90d,support_calls_90d,rating_90d,days_since_login,days_since_last_order,cancel_reason,churned
C00001,2024-07-01,Rio de Janeiro,57,1,card,weekly,small,referral,5,356.0,11,1,2,3,1,3.56,1.0,536.0,delivery,1
C00003,2024-07-01,São Paulo,41,1,card,fortnightly,large,organic,9,338.0,6,0,0,0,0,5.0,12.0,8.0,,0
```

Each row of `churn.csv` is **one subscriber on one day**, with what they did in the 90 days before
it and, in the last column, whether they cancelled in the month that followed. The same subscriber
appears once a month for as long as they stay. Keep that in mind: it is the subject of lesson 3.

## The program

```python
# make_data.py
"""Feira em Casa's files, drawn from fixed seeds: the same bytes on every computer."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else "data")
OUT.mkdir(exist_ok=True)
rng = np.random.default_rng(20250101)


def sigmoid(z):
    return 1 / (1 + np.exp(-z))


# ---------------------------------------------------------------- churn
CITIES = ["São Paulo", "Campinas", "Rio de Janeiro", "Belo Horizonte", "Curitiba"]
MONTHS = pd.date_range("2023-01-01", "2026-03-01", freq="MS")
BOX = {"small": 89.0, "medium": 129.0, "large": 169.0}
PER_MONTH = {"weekly": 4, "fortnightly": 2, "monthly": 1}
FIRST = pd.Timestamp("2024-07-01")   # the first month anybody kept a snapshot
EXPORT = pd.Timestamp("2026-01-01")  # the day churn.csv was exported
RISE = pd.Timestamp("2025-09-01")    # every box costs 12% more from here on
RIVAL = pd.Timestamp("2026-01-01")   # a competitor opens in two cities

n = 9000
weight = np.linspace(1, 3, len(MONTHS) - 1)
joined = rng.choice(len(MONTHS) - 1, n, p=weight / weight.sum()) + 1
age = np.clip(rng.normal(39, 12, n), 18, 78).round().astype(int)
people = pd.DataFrame({
    "customer_id": [f"C{i:05d}" for i in range(1, n + 1)],
    "city": rng.choice(CITIES, n, p=[0.38, 0.14, 0.22, 0.13, 0.13]),
    "age": age,
    "app_user": (rng.random(n) < sigmoid(2.0 - 0.08 * (age - 30))).astype(int),
    "payment": rng.choice(["card", "pix"], n, p=[0.6, 0.4]),
    "plan": rng.choice(["weekly", "fortnightly"], n, p=[0.6, 0.4]),
    "box": rng.choice(list(BOX), n, p=[0.35, 0.45, 0.20]),
    "channel": rng.choice(["ads", "referral", "organic"], n, p=[0.45, 0.25, 0.30]),
})
people.loc[rng.random(n) < 0.04 + 0.006 * (age - 18), "payment"] = "boleto"
people.loc[(MONTHS[joined] >= RIVAL) & (rng.random(n) < 0.45), "plan"] = "monthly"
mood = rng.normal(0, 1, n)                      # how much they like the boxes
per_month = people["plan"].map(PER_MONTH).to_numpy()
p_late = np.where(people["city"] == "Rio de Janeiro", 0.13, 0.06)
login = np.where(people["app_user"] == 1, rng.gamma(2.0, 4.0, n), np.nan)

active = np.zeros(n, bool)
left = np.full(n, np.datetime64("NaT", "s"))
window, snaps = [], []
for t, month in enumerate(MONTHS):
    active |= joined == t
    if month >= FIRST:
        w = sum(window[-3:])
        tenure = t - joined
        rated = w["rated"].to_numpy()
        rating = np.where(rated > 0, w["stars"] / np.maximum(rated, 1), np.nan)
        price = people["box"].map(BOX).to_numpy() * per_month * (1.12 if month >= RISE else 1)
        stars_or_4 = np.nan_to_num(rating, nan=4.0)
        z = (-4.1 + 0.20 * w["skips"] + 0.50 * (w["skips"] >= 3) + 0.45 * w["complaints"]
             + 0.22 * w["late"] - 0.55 * (stars_or_4 - 4) - 0.9 * np.minimum(tenure, 24) / 24
             + 0.45 * (people["payment"] == "boleto") - 0.25 * people["app_user"]
             + 0.30 * (people["age"] < 25) + 0.004 * price / per_month
             + 0.45 * (RISE <= month < RISE + pd.DateOffset(months=4))
             + 0.70 * ((month >= RIVAL) & people["city"].isin(["Curitiba", "Belo Horizonte"]))
             + 1.20 * (stars_or_4 < 3.6) + 0.60 * w["late"] * (tenure < 6)
             + 1.00 * (login * np.exp(0.25 * w["skips"]) > 21) - 0.35 * mood)
        keep = active & (tenure >= 1)
        churn = keep & (rng.random(n) < sigmoid(z.to_numpy()))
        rows = people[keep].copy()
        rows.insert(1, "snapshot", month)
        rows["tenure_months"] = tenure[keep]
        rows["price_month"] = price[keep].round(2)
        for col in ["orders", "skips", "late", "complaints", "support_calls"]:
            rows[f"{col}_90d"] = w[col][keep].astype(int)
        rows["rating_90d"] = rating[keep].round(2)
        rows["days_since_login"] = (login[keep] * np.exp(0.25 * w["skips"][keep])).round()
        rows["churned"] = churn[keep].astype(int)
        snaps.append(rows)
        left[churn] = month + pd.Timedelta(days=int(rng.integers(3, 27)))
        active &= ~churn
    want = per_month * active
    skips = rng.binomial(want, sigmoid(-2.2 - 0.5 * mood))
    orders = want - skips
    late = rng.binomial(orders, p_late)
    rated = rng.binomial(orders, 0.35)
    stars = np.clip(4.2 + 0.4 * mood - 1.2 * late / np.maximum(orders, 1)
                    + rng.normal(0, 0.3, n), 1, 5)
    window.append(pd.DataFrame({
        "orders": orders, "skips": skips, "late": late, "rated": rated,
        "stars": rated * stars, "complaints": rng.poisson(0.03 + 0.35 * late),
        "support_calls": rng.poisson(0.05 + 0.2 * skips + 0.3 * late)}))

snap = pd.concat(snaps)
who = snap.index.to_numpy()
gone = pd.to_datetime(left[who])
old = (snap["snapshot"] < EXPORT).to_numpy()
quiet = rng.integers(0, 7 * snap["plan"].map(PER_MONTH).rdiv(4).to_numpy())
since_export = np.where(gone < EXPORT, (EXPORT - gone).days, quiet)
reasons = np.array(["price", "quality", "delivery", "moving", "other"])
snap["days_since_last_order"] = np.where(old, since_export, quiet)
snap["cancel_reason"] = np.where(snap["churned"] == 1,
                                 rng.choice(reasons, len(snap), p=[0.3, 0.2, 0.2, 0.15, 0.15]), "")
cols = [c for c in snap.columns if c != "churned"] + ["churned"]
snap[old][cols].to_csv(OUT / "churn.csv", index=False)
new = snap[~old].drop(columns="cancel_reason")
new.drop(columns="churned").to_csv(OUT / "churn_2026.csv", index=False)
new[["customer_id", "snapshot", "churned"]].to_csv(OUT / "churn_2026_labels.csv", index=False)

# ----------------------------------------------------------- deliveries
m = 6000
day = pd.Timestamp("2025-01-01") + pd.to_timedelta(rng.integers(0, 365, m), unit="D")
hour = rng.choice(np.arange(8, 21), m)
km = np.round(rng.gamma(2.2, 2.6, m) + 0.3, 1)
items = rng.integers(4, 31, m)
rain = (rng.random(m) < np.where(day.month.isin([1, 2, 3, 12]), 0.35, 0.12)).astype(int)
driving = rng.integers(0, 61, m)
rush = np.isin(hour, [11, 12, 17, 18, 19])
minutes = (14 + 2.4 * km + 0.35 * items + 9 * rush + rain * (5 + 1.1 * km)
           - 0.12 * np.minimum(driving, 36) + rng.gamma(2.0, 2.5, m))
stuck = rng.random(m) < 0.03                    # a flat tyre, a wrong address
minutes = np.round(minutes + stuck * rng.uniform(30, 120, m)).astype(int)
pd.DataFrame({
    "delivery_id": [f"D{i:05d}" for i in range(1, m + 1)], "date": day.date,
    "hour": hour, "city": rng.choice(CITIES, m, p=[0.38, 0.14, 0.22, 0.13, 0.13]),
    "distance_km": km, "items": items, "rain": rain, "driver_months": driving,
    "minutes": minutes}).sort_values(["date", "hour"]).to_csv(OUT / "deliveries.csv", index=False)

# -------------------------------------------------------------- reviews
GOOD = ["fresh {}", "crisp {}", "sweet {}", "ripe {}", "lovely {}", "tasty {}",
        "arrived on time", "well packed", "friendly driver", "generous box"]
BAD = ["bruised {}", "rotten {}", "wilted {}", "missing {}", "mouldy {}", "soggy {}",
       "arrived late", "box was damaged", "wrong order", "rude driver", "want a refund"]
FOOD = ["tomatoes", "bananas", "lettuce", "mangoes", "carrots", "eggs", "bread",
        "strawberries", "kale", "papaya"]
k = 3000
bad = rng.random(k) < 0.22
texts, stars = [], []
for b in bad:
    picks = rng.random(rng.integers(2, 5)) < (0.75 if b else 0.08)
    words = [rng.choice(BAD if x else GOOD).format(rng.choice(FOOD)) for x in picks]
    texts.append(", ".join(dict.fromkeys(words)).capitalize())
    stars.append(int(rng.choice([1, 2, 3], p=[0.5, 0.35, 0.15]) if b
                     else rng.choice([3, 4, 5], p=[0.1, 0.35, 0.55])))
reviews = pd.DataFrame({"review_id": [f"R{i:05d}" for i in range(1, k + 1)], "stars": stars,
                        "text": texts, "complaint": bad.astype(int)})
reviews.to_csv(OUT / "reviews.csv", index=False)

# -------------------------------------------------------------- baskets
SHARE = ["fruit", "vegetables", "greens", "eggs_dairy", "bakery", "extras"]
TASTE = np.array([[45, 25, 10, 10, 5, 5],      # four kinds of household, which
                  [15, 40, 25, 10, 5, 5],      # the files never name
                  [15, 20, 10, 20, 25, 10],
                  [20, 20, 15, 15, 10, 20]], float)
SPEND = [(2.0, 140), (3.5, 210), (4.0, 260), (1.2, 330)]
c = 1200
kind = rng.choice(4, c, p=[0.3, 0.3, 0.25, 0.15])
shares = np.array([rng.dirichlet(TASTE[g]) for g in kind])
basket = pd.DataFrame((shares * 100).round(1), columns=SHARE)
often = np.round([rng.normal(SPEND[g][0], 0.4) for g in kind], 1).clip(0.5)
basket.insert(0, "orders_month", often)
basket.insert(1, "avg_basket", np.round([rng.normal(SPEND[g][1], 25) for g in kind], 2))
chosen = rng.choice(np.arange(1, n + 1), c, replace=False)
basket.insert(0, "customer_id", [f"C{i:05d}" for i in chosen])
basket.sort_values("customer_id").to_csv(OUT / "baskets.csv", index=False)

# --------------------------------------------------------------- add-ons
ADDONS = {"baking": ["flour", "yeast", "butter", "cocoa", "vanilla", "oats"],
          "breakfast": ["granola", "honey", "yoghurt", "coffee", "jam", "papaya"],
          "cooking": ["garlic", "ginger", "olive oil", "chilli", "coriander", "lime"],
          "everyone": ["sourdough", "eggs", "cheese", "avocado"]}
names = [p for group in ADDONS.values() for p in group]
group_of = np.array([g for g, ps in ADDONS.items() for _ in ps])
buyers = 1500
likes = rng.dirichlet([0.4, 0.4, 0.4], buyers)
rows = []
for b in range(buyers):
    taste = dict(zip(["baking", "breakfast", "cooking"], likes[b]), everyone=0.5)
    rate = np.array([taste[g] for g in group_of]) * rng.gamma(2, 0.5)
    times = rng.poisson(rate * 3)
    for p in np.flatnonzero(times):
        rows.append((f"C{b + 1:05d}", names[p], int(times[p])))
addons = pd.DataFrame(rows, columns=["customer_id", "product", "times"])
addons.to_csv(OUT / "addons.csv", index=False)

for f in sorted(OUT.glob("*.csv")):
    print(f"{f.name:24}{len(pd.read_csv(f)):>7,} rows")
```
