---
title: The shop, drawn by a program you keep
version: 1
---

A model is only as good as the rows it learns from, so the course needs rows, and real customers'
are not something a course may hand out. **The shop's data is drawn by one short program, from a
fixed seed**, so that the database on your computer is the same, row for row, as the one every
transcript in the course was recorded against.

Make the project's directory, and save the program below in it as `generate.py`. The copy button
on the block hands over the whole program without the notes.

```sh
mkdir ~/ml
cd ~/ml
```

```schooling-example
{
  "language": "python",
  "file": "generate.py",
  "parts": [
    {
      "code": "\"\"\"generate.py: two years of the Ponto Final card, drawn from a fixed seed.\n\n    python generate.py                     # the shop as it stood on 28 February 2026\n    python generate.py --until 2026-06-30  # the same history, four months further on\n\nWrites shop.db, an SQLite database with four tables: members, the people who\ncarry the shop's loyalty card; purchases, one row per visit to a till or to the\nwebsite; lines, one row per book in a purchase; and titles, the books. Nobody\nin it is real, and the same seed draws the same shop on every computer.\n\"\"\"\nimport argparse\nimport datetime as dt\nimport sqlite3\n\nimport numpy as np\n\n",
      "note": "The docstring says how to run it. With no argument it stops on 28 February 2026, the night this course begins on; `--until` lets lesson 10 read the same history further on."
    },
    {
      "code": "FIRST, LAST = dt.date(2024, 7, 1), dt.date(2026, 6, 30)\nSHOPS = [\"Paulista\", \"Pinheiros\", \"Cambuí\", \"Savassi\", \"Batel\", \"Moinhos\", \"Online\"]\nAGES = [\"18-24\", \"25-34\", \"35-49\", \"50-64\", \"65+\"]\nCATEGORIES = [\"crime\", \"fantasy\", \"literary\", \"children\", \"cooking\", \"history\",\n              \"science\", \"travel\"]\nWORDS = [\"Harbour\", \"River\", \"Garden\", \"Winter\", \"Letter\", \"Island\", \"Station\",\n         \"Mirror\", \"Lantern\", \"Orchard\"]\nSHIPPING_FREE = dt.date(2026, 3, 16)   # online orders stop paying postage\nRIVAL_OPENS = dt.date(2026, 4, 1)      # a book subscription launches in São Paulo\n\n",
      "note": "The shops are the ones from `pipelines-etl`. The two dates at the end are things that will happen to the shop after February. Nothing in the first nine lessons depends on them, and lesson 10 is about noticing them from the data alone."
    },
    {
      "code": "args = argparse.ArgumentParser()\nargs.add_argument(\"--until\", default=\"2026-02-28\")\nuntil = args.parse_args().until\nrng = np.random.default_rng(2026)\n\n",
      "note": "**One seed, `2026`, draws everything.** Change it and you get a different shop, with every number in the course different from yours."
    },
    {
      "code": "# 80 titles, ten to a category, each with a price in cents\ntitles = []\nfor t in range(80):\n    category = CATEGORIES[t // 10]\n    price = int(rng.choice([3990, 4990, 5990, 6990, 7990]))\n    titles.append((t, category, f\"The {WORDS[t % 10]} of {category.title()}\", price))\n\n",
      "note": "Eighty books, ten in each of eight categories, so that lesson 2 has something to recommend."
    },
    {
      "code": "members, purchases, lines = [], [], []\nfor m in range(1, 5001):\n    joined = FIRST + dt.timedelta(days=int(rng.integers(-365, (LAST - FIRST).days - 30)))\n    if joined >= dt.date(2025, 9, 1):                  # the app arrived in September 2025\n        channel = str(rng.choice([\"store\", \"web\", \"app\"], p=[0.45, 0.2, 0.35]))\n    else:\n        channel = str(rng.choice([\"store\", \"web\"], p=[0.7, 0.3]))\n    age = str(rng.choice(AGES, p=[0.14, 0.27, 0.31, 0.18, 0.10]))\n    home = 6 if channel != \"store\" else int(rng.choice(6, p=[0.27, 0.21, 0.13, 0.16, 0.12, 0.11]))\n",
      "note": "Each member gets a join date, the channel they signed up on, an age band and a home shop. The app only exists from September 2025, so nobody before that joined on it."
    },
    {
      "code": "    rate = rng.gamma(4.0, 1 / 100)                   # visits a day: one every 25 on average\n    life = 1500 * rng.exponential() * {\"18-24\": 0.5, \"25-34\": 0.8}.get(age, 1.0)\n    if channel == \"app\":\n        life *= 0.6\n    leaves = joined + dt.timedelta(days=int(life))\n    likes = rng.choice(8, size=2, replace=False)       # two favourite categories\n    members.append((m, joined.isoformat(), channel, age, SHOPS[home]))\n\n",
      "note": "Two hidden numbers decide a member's life: how often they visit, and how long they stay before they leave for good. Young members and app members leave sooner. **No column in the database records either number**, which is the situation every real model is in: it sees what people did, never why."
    },
    {
      "code": "    day = max(joined, FIRST)\n    while True:\n        day += dt.timedelta(days=int(rng.exponential(1 / rate)) + 1)\n        if day > min(leaves, LAST):\n            break\n        if (day >= RIVAL_OPENS and SHOPS[home] in (\"Paulista\", \"Pinheiros\")\n                and age in (\"18-24\", \"25-34\") and rng.random() < 0.35):\n            break                                      # gone to the rival\n        online = 0.15 + (0.6 if channel != \"store\" else 0) + (0.35 if day >= SHIPPING_FREE else 0)\n        if rng.random() < online:\n            shop = \"Online\"\n        else:\n            shop = SHOPS[home] if home != 6 else SHOPS[int(rng.integers(6))]\n        purchases.append((len(purchases) + 1, m, day.isoformat(), shop))\n        for _ in range(1 + rng.poisson(0.6)):\n            roll = rng.random()\n            category = likes[0] if roll < 0.5 else likes[1] if roll < 0.8 else rng.integers(8)\n            title = titles[int(category) * 10 + int(rng.integers(10))]\n            lines.append((len(purchases), title[0], title[3]))\n\n",
      "note": "Then the visits, one at a time, until the member leaves or the history ends. Each visit is in a shop or online, and holds one or more books, mostly from the member's two favourite categories."
    },
    {
      "code": "db = sqlite3.connect(\"shop.db\")\ndb.executescript(\"\"\"\nDROP TABLE IF EXISTS members; DROP TABLE IF EXISTS purchases;\nDROP TABLE IF EXISTS lines; DROP TABLE IF EXISTS titles;\nCREATE TABLE members (member_id INTEGER PRIMARY KEY, joined TEXT, channel TEXT,\n                      age_band TEXT, home_shop TEXT);\nCREATE TABLE purchases (purchase_id INTEGER PRIMARY KEY, member_id INTEGER,\n                        day TEXT, shop TEXT);\nCREATE TABLE lines (purchase_id INTEGER, title_id INTEGER, price_cents INTEGER);\nCREATE TABLE titles (title_id INTEGER PRIMARY KEY, category TEXT, title TEXT,\n                     price_cents INTEGER);\nCREATE INDEX purchases_by_member ON purchases (member_id, day);\nCREATE INDEX lines_by_purchase ON lines (purchase_id);\n\"\"\")\n",
      "note": "The tables are rewritten every time, so running it twice is safe. The two indexes are what make lesson 1's query take a second instead of minutes."
    },
    {
      "code": "kept = {p[0] for p in purchases if p[2] <= until}\ndb.executemany(\"INSERT INTO titles VALUES (?, ?, ?, ?)\", titles)\ndb.executemany(\"INSERT INTO members VALUES (?, ?, ?, ?, ?)\", [r for r in members if r[1] <= until])\ndb.executemany(\"INSERT INTO purchases VALUES (?, ?, ?, ?)\", [r for r in purchases if r[0] in kept])\ndb.executemany(\"INSERT INTO lines VALUES (?, ?, ?)\", [r for r in lines if r[0] in kept])\ndb.commit()\nfor table in (\"members\", \"purchases\", \"lines\", \"titles\"):\n    print(f\"{table:10} {db.execute(f'SELECT count(*) FROM {table}').fetchone()[0]:>7}\")\nprint(\"last day  \", db.execute(\"SELECT max(day) FROM purchases\").fetchone()[0])\n",
      "note": "**Only what happened by `--until` is written.** The whole two years are always drawn, so the first months come out identical whatever the date, and a later run only adds to them."
    }
  ]
}
```

Run it from `~/ml`, with the environment active:

```
ana@dev:~/ml$ python generate.py
members       4558
purchases    57422
lines        91963
titles          80
last day   2026-02-28
```

**Those four counts are the check that your copy is right.** A line missing from the program still
runs, and draws a different shop; if yours differ, copy the file again.

## The four tables

`members` is one row per card holder, `purchases` one row per visit to a till or the website,
`lines` one row per book bought in a visit, and `titles` the eighty books. A look at each, with the
`sqlite3` command and its `-header -column` flags, which print a table the way a person reads one:

```
ana@dev:~/ml$ sqlite3 -header -column shop.db "SELECT * FROM members LIMIT 3"
member_id  joined      channel  age_band  home_shop
---------  ----------  -------  --------  ---------
1          2024-09-08  store    25-34     Savassi  
2          2024-11-17  store    25-34     Savassi  
3          2024-11-19  store    35-49     Pinheiros
ana@dev:~/ml$ sqlite3 -header -column shop.db "SELECT * FROM purchases WHERE member_id = 2"
purchase_id  member_id  day         shop   
-----------  ---------  ----------  -------
10           2          2024-11-24  Savassi
11           2          2024-12-23  Online 
12           2          2025-01-03  Savassi
13           2          2025-02-23  Savassi
14           2          2025-04-05  Savassi
15           2          2025-05-21  Online 
16           2          2025-06-13  Savassi
17           2          2025-09-26  Online 
18           2          2025-11-08  Savassi
19           2          2025-11-30  Savassi
20           2          2026-02-25  Savassi
ana@dev:~/ml$ sqlite3 -header -column shop.db "SELECT * FROM lines JOIN titles USING (title_id) WHERE purchase_id = 12"
purchase_id  title_id  price_cents  category  title                   price_cents
-----------  --------  -----------  --------  ----------------------  -----------
12           8         6990         crime     The Lantern of Crime    6990       
12           3         6990         crime     The Winter of Crime     6990       
12           22        6990         literary  The Garden of Literary  6990       
```

Three things in there matter for the rest of the course.

**Nothing says whether a member has left.** There is no column `lapsed` and no date of leaving:
the shop only sees visits, and a member who stopped coming looks exactly like one who has not come
yet. Every label in this course is *computed*, from what happened after a chosen day, and lesson 3
shows what goes wrong when that computation reads a day too far.

**Money is in cents**, as an integer, the way `pipelines-etl` kept it. `price_cents` 5990 is
R$ 59.90.

**The last purchase is on 28 February 2026.** That is "today" for the first nine lessons. In
lesson 10 you will run the same program with `--until 2026-06-30`, and four more months of the same
shop arrive, drawn from the same seed, so everything before March stays exactly as it is now.
