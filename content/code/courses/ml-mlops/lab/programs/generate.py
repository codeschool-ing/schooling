"""generate.py: two years of the Ponto Final card, drawn from a fixed seed.

    python generate.py                     # the shop as it stood on 28 February 2026
    python generate.py --until 2026-06-30  # the same history, four months further on

Writes shop.db, an SQLite database with four tables: members, the people who
carry the shop's loyalty card; purchases, one row per visit to a till or to the
website; lines, one row per book in a purchase; and titles, the books. Nobody
in it is real, and the same seed draws the same shop on every computer.
"""
import argparse
import datetime as dt
import sqlite3

import numpy as np

FIRST, LAST = dt.date(2024, 7, 1), dt.date(2026, 6, 30)
SHOPS = ["Paulista", "Pinheiros", "Cambuí", "Savassi", "Batel", "Moinhos", "Online"]
AGES = ["18-24", "25-34", "35-49", "50-64", "65+"]
CATEGORIES = ["crime", "fantasy", "literary", "children", "cooking", "history",
              "science", "travel"]
WORDS = ["Harbour", "River", "Garden", "Winter", "Letter", "Island", "Station",
         "Mirror", "Lantern", "Orchard"]
SHIPPING_FREE = dt.date(2026, 3, 16)   # online orders stop paying postage
RIVAL_OPENS = dt.date(2026, 4, 1)      # a book subscription launches in São Paulo

args = argparse.ArgumentParser()
args.add_argument("--until", default="2026-02-28")
until = args.parse_args().until
rng = np.random.default_rng(2026)

# 80 titles, ten to a category, each with a price in cents
titles = []
for t in range(80):
    category = CATEGORIES[t // 10]
    price = int(rng.choice([3990, 4990, 5990, 6990, 7990]))
    titles.append((t, category, f"The {WORDS[t % 10]} of {category.title()}", price))

members, purchases, lines = [], [], []
for m in range(1, 5001):
    joined = FIRST + dt.timedelta(days=int(rng.integers(-365, (LAST - FIRST).days - 30)))
    if joined >= dt.date(2025, 9, 1):                  # the app arrived in September 2025
        channel = str(rng.choice(["store", "web", "app"], p=[0.45, 0.2, 0.35]))
    else:
        channel = str(rng.choice(["store", "web"], p=[0.7, 0.3]))
    age = str(rng.choice(AGES, p=[0.14, 0.27, 0.31, 0.18, 0.10]))
    home = 6 if channel != "store" else int(rng.choice(6, p=[0.27, 0.21, 0.13, 0.16, 0.12, 0.11]))
    rate = rng.gamma(4.0, 1 / 100)                   # visits a day: one every 25 on average
    life = 1500 * rng.exponential() * {"18-24": 0.5, "25-34": 0.8}.get(age, 1.0)
    if channel == "app":
        life *= 0.6
    leaves = joined + dt.timedelta(days=int(life))
    likes = rng.choice(8, size=2, replace=False)       # two favourite categories
    members.append((m, joined.isoformat(), channel, age, SHOPS[home]))

    day = max(joined, FIRST)
    while True:
        day += dt.timedelta(days=int(rng.exponential(1 / rate)) + 1)
        if day > min(leaves, LAST):
            break
        if (day >= RIVAL_OPENS and SHOPS[home] in ("Paulista", "Pinheiros")
                and age in ("18-24", "25-34") and rng.random() < 0.35):
            break                                      # gone to the rival
        online = 0.15 + (0.6 if channel != "store" else 0) + (0.35 if day >= SHIPPING_FREE else 0)
        if rng.random() < online:
            shop = "Online"
        else:
            shop = SHOPS[home] if home != 6 else SHOPS[int(rng.integers(6))]
        purchases.append((len(purchases) + 1, m, day.isoformat(), shop))
        for _ in range(1 + rng.poisson(0.6)):
            roll = rng.random()
            category = likes[0] if roll < 0.5 else likes[1] if roll < 0.8 else rng.integers(8)
            title = titles[int(category) * 10 + int(rng.integers(10))]
            lines.append((len(purchases), title[0], title[3]))

db = sqlite3.connect("shop.db")
db.executescript("""
DROP TABLE IF EXISTS members; DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS lines; DROP TABLE IF EXISTS titles;
CREATE TABLE members (member_id INTEGER PRIMARY KEY, joined TEXT, channel TEXT,
                      age_band TEXT, home_shop TEXT);
CREATE TABLE purchases (purchase_id INTEGER PRIMARY KEY, member_id INTEGER,
                        day TEXT, shop TEXT);
CREATE TABLE lines (purchase_id INTEGER, title_id INTEGER, price_cents INTEGER);
CREATE TABLE titles (title_id INTEGER PRIMARY KEY, category TEXT, title TEXT,
                     price_cents INTEGER);
CREATE INDEX purchases_by_member ON purchases (member_id, day);
CREATE INDEX lines_by_purchase ON lines (purchase_id);
""")
kept = {p[0] for p in purchases if p[2] <= until}
db.executemany("INSERT INTO titles VALUES (?, ?, ?, ?)", titles)
db.executemany("INSERT INTO members VALUES (?, ?, ?, ?, ?)", [r for r in members if r[1] <= until])
db.executemany("INSERT INTO purchases VALUES (?, ?, ?, ?)", [r for r in purchases if r[0] in kept])
db.executemany("INSERT INTO lines VALUES (?, ?, ?)", [r for r in lines if r[0] in kept])
db.commit()
for table in ("members", "purchases", "lines", "titles"):
    print(f"{table:10} {db.execute(f'SELECT count(*) FROM {table}').fetchone()[0]:>7}")
print("last day  ", db.execute("SELECT max(day) FROM purchases").fetchone()[0])
