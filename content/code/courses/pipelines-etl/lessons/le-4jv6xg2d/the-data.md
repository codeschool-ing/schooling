---
title: The shop's database and its data
version: 1
---

**Every number in this course comes from the next two files, so they have to be exact.** Copy them
rather than retyping them. You do not need to read the generator to follow the lessons, but each
oddity a later lesson finds in the data, a duplicated event or one that arrives late, was put there
by a line of it, on purpose.

## shop.sql

The operational database: the shops, the books, the customers, and the orders with their lines and
payments. Save it as `~/pontofinal/shop.sql`:

```sql
-- The operational database of Ponto Final, the source every pipeline in the
-- course reads. The tills and the website write it; nothing in this course
-- does, except `shop day` playing back a day of trade.
CREATE TABLE shops (
  shop_id   integer PRIMARY KEY,
  name      text NOT NULL,
  city      text,
  state     text,
  channel   text NOT NULL CHECK (channel IN ('store', 'online'))
);
CREATE TABLE books (
  book_id          integer PRIMARY KEY,
  isbn             text NOT NULL UNIQUE,
  title            text NOT NULL,
  category         text NOT NULL,
  publisher        text NOT NULL,
  list_price_cents integer NOT NULL CHECK (list_price_cents > 0),
  updated_at       timestamptz NOT NULL
);
CREATE TABLE customers (
  customer_id integer PRIMARY KEY,
  name        text NOT NULL,
  email       text NOT NULL UNIQUE,
  city        text NOT NULL,
  state       text NOT NULL,
  created_at  timestamptz NOT NULL,
  updated_at  timestamptz NOT NULL
);
CREATE TABLE orders (
  order_id    integer PRIMARY KEY,
  shop_id     integer NOT NULL REFERENCES shops,
  customer_id integer REFERENCES customers,
  ordered_at  timestamptz NOT NULL,
  status      text NOT NULL CHECK (status IN ('completed', 'cancelled', 'refunded')),
  updated_at  timestamptz NOT NULL
);
CREATE INDEX orders_updated_at ON orders (updated_at);
CREATE TABLE order_lines (
  order_id         integer NOT NULL REFERENCES orders,
  line_no          integer NOT NULL,
  book_id          integer NOT NULL REFERENCES books,
  quantity         integer NOT NULL CHECK (quantity > 0),
  unit_price_cents integer NOT NULL CHECK (unit_price_cents > 0),
  PRIMARY KEY (order_id, line_no)
);
CREATE TABLE payments (
  payment_id   integer PRIMARY KEY,
  order_id     integer NOT NULL REFERENCES orders,
  method       text NOT NULL,
  amount_cents integer NOT NULL,
  paid_at      timestamptz NOT NULL
);
```

## generate.py

Three months of trade at Ponto Final, drawn a day at a time. It writes the shop as it stood on the
night of 28 February and every day of March as the SQL the tills ran, plus the website's events,
the distributor's stock files and the publishers' prices. Save it as `~/pontofinal/generate.py`:

```python
"""Three months of trade at Ponto Final, a chain of bookshops that does not exist.

The same shops as warehouse-modeling, and a smaller, newer slice of their life:
1 January to 31 March 2026. What a pipeline course needs from its data is not
size but CHANGE — rows that are inserted, updated and deleted while the
pipeline is reading them — so this draws a day at a time and writes down what
each day did.

    python3 generate.py OUT

writes into OUT:

  initial/<table>.csv   the operational database as it stood at the end of
                        28 February 2026, one CSV per table
  days/<date>.sql       for each day of March, the transactions the tills, the
                        website and the back office ran that day, in the order
                        they ran, each with its own timestamps
  events/<date>.jsonl   the website's click events for that day, as its
                        collector wrote them: a few duplicated, a few late
  stock/<date>.csv      the distributor's stock file for that day
  prices.json           the publishers' list prices prices_api.py serves

Everything is drawn from random.Random with fixed seeds, so the same files
come out on every run and on every machine. Nothing here is real: the people
and the books are made from word lists and the e-mail addresses are under
example.com, example.net and example.org, which are reserved for examples.
"""

import csv
import datetime as dt
import json
import os
import random
import sys

OUT = sys.argv[1]
FIRST = dt.date(2026, 1, 1)
CUT = dt.date(2026, 2, 28)       # the database is handed over as of this night
LAST = dt.date(2026, 3, 31)
TZ = dt.timezone(dt.timedelta(hours=-3))  # America/Sao_Paulo, no DST since 2019

SHOPS = [
    # id, name, city, state, channel, base orders a day
    (1, "Paulista", "São Paulo", "SP", "store", 52),
    (2, "Pinheiros", "São Paulo", "SP", "store", 40),
    (3, "Cambuí", "Campinas", "SP", "store", 25),
    (4, "Savassi", "Belo Horizonte", "MG", "store", 30),
    (5, "Batel", "Curitiba", "PR", "store", 21),
    (6, "Moinhos", "Porto Alegre", "RS", "store", 19),
    (7, "Online", None, None, "online", 96),
]
CATEGORIES = ["Crime", "Literary fiction", "Science fiction", "Fantasy", "Romance",
              "History", "Science", "Business", "Biography", "Cooking",
              "Picture books", "Young adult", "Graphic novels", "Manga"]
FIRST_NAMES = """Ana Bruno Carla Daniel Eduarda Felipe Gabriela Henrique Isabela João
Larissa Lucas Mariana Mateus Natália Otávio Paula Rafael Sofia Tiago Valentina Vinícius
Beatriz Caio Débora Enzo Fernanda Gustavo Helena Igor Júlia Leonardo Luana Marcelo Nicole
Pedro Raquel Renato Sabrina Thiago Vitória Yuri Alice Arthur Camila Diego Elisa Fábio
Giovana Heitor Lívia Murilo Priscila Rodrigo Tatiana Ulisses""".split()
SURNAMES = """Silva Santos Oliveira Souza Rodrigues Ferreira Alves Pereira Lima Gomes
Costa Ribeiro Martins Carvalho Almeida Lopes Soares Fernandes Vieira Barbosa Rocha Dias
Nascimento Andrade Moreira Nunes Marques Machado Mendes Freitas Cardoso Ramos Gonçalves
Santana Teixeira Araújo Pinto Correia Moura Cavalcanti Monteiro Barros Campos Duarte
Farias Fonseca Brito Azevedo Castro Pires""".split()
TITLE_ADJ = """Silent Hidden Last Northern Burning Quiet Broken Golden Distant Forgotten
Secret Long Bright Second Little Cold Endless Narrow Paper Salt""".split()
TITLE_NOUN = """Harbour River Garden House Winter Letter Island Mountain Station Mirror
Kingdom Library Sea Bridge Lantern Forest City Road Archive Season Orchard Compass""".split()
PUBLISHERS = """Atlântida Borda Cais Duna Estuário Farol Granito Horizonte Ilha Jangada
Litoral Maré Norte Oásis""".split()
CITIES = {
    "SP": ["São Paulo", "São Paulo", "São Paulo", "Campinas", "Santos", "Guarulhos"],
    "MG": ["Belo Horizonte", "Belo Horizonte", "Contagem", "Uberlândia"],
    "PR": ["Curitiba", "Curitiba", "Londrina"],
    "RS": ["Porto Alegre", "Porto Alegre", "Canoas"],
    "RJ": ["Rio de Janeiro", "Niterói"],
    "PE": ["Recife"],
}
STATE_WEIGHT = {"SP": 50, "MG": 15, "PR": 12, "RS": 10, "RJ": 9, "PE": 4}
DOMAINS = ["example.com", "example.net", "example.org"]
METHODS = [("pix", 45), ("credit", 35), ("debit", 15), ("cash", 5)]


def days(a, b):
    d = a
    while d <= b:
        yield d
        d += dt.timedelta(days=1)


def at(d, rng, lo=9, hi=21):
    s = rng.randrange(lo * 3600, hi * 3600)
    return dt.datetime(d.year, d.month, d.day, tzinfo=TZ) + dt.timedelta(seconds=s)


def ts(t):
    return t.isoformat(sep=" ")


def isbn13(rng):
    body = "97865" + "".join(str(rng.randrange(10)) for _ in range(7))
    s = sum(int(c) * (1 if i % 2 == 0 else 3) for i, c in enumerate(body))
    return body + str((10 - s % 10) % 10)


def weighted(rng, pairs):
    return rng.choices([p[0] for p in pairs], [p[1] for p in pairs])[0]


# ------------------------------------------------------------------ books
rb = random.Random(101)
books = {}
seen_titles = set()
for book_id in range(1, 1201):
    while True:
        title = f"The {rb.choice(TITLE_ADJ)} {rb.choice(TITLE_NOUN)}"
        if rb.random() < 0.5:
            title += f" of {rb.choice(TITLE_NOUN)}s"
        if title not in seen_titles:
            seen_titles.add(title)
            break
    price = rb.choice([3990, 4490, 4990, 5490, 5990, 6990, 7990, 8990, 9990, 12990])
    books[book_id] = {
        "book_id": book_id, "isbn": isbn13(rb), "title": title,
        "category": rb.choice(CATEGORIES), "publisher": rb.choice(PUBLISHERS),
        "list_price_cents": price,
        "updated_at": ts(dt.datetime(2025, 12, 1, 8, 0, tzinfo=TZ)),
    }
popular = list(books)
book_weight = [1.0 / (i ** 0.8) for i in range(1, len(popular) + 1)]
rb.shuffle(popular)

# -------------------------------------------------------------- customers
rc = random.Random(202)
customers = {}
next_customer = 1


def new_customer(created):
    global next_customer
    cid = next_customer
    next_customer += 1
    first, last = rc.choice(FIRST_NAMES), rc.choice(SURNAMES)
    state = weighted(rc, list(STATE_WEIGHT.items()))
    customers[cid] = {
        "customer_id": cid, "name": f"{first} {last}",
        "email": f"{first.lower()}.{last.lower()}{cid}@{rc.choice(DOMAINS)}",
        "city": rc.choice(CITIES[state]), "state": state,
        "created_at": ts(created), "updated_at": ts(created),
    }
    return cid


for _ in range(4000):
    new_customer(dt.datetime(2025, rc.randrange(1, 13), rc.randrange(1, 29), 12, 0,
                             tzinfo=TZ))

# ------------------------------------------------------------------- trade
ro = random.Random(303)
orders, lines, payments = {}, [], []
next_order, next_payment = 100001, 500001
erased = set()
recent_ids = []


def sql_lit(v):
    if v is None:
        return "NULL"
    if isinstance(v, int):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def insert(table, row):
    cols = ", ".join(row)
    vals = ", ".join(sql_lit(v) for v in row.values())
    return f"INSERT INTO {table} ({cols}) VALUES ({vals});"


day_sql = {}
for d in days(FIRST, LAST):
    out = []  # (time, statement block) for this day
    weekday = d.weekday()
    factor = {5: 1.35, 6: 0.8}.get(weekday, 1.0)
    # new customers sign up through the day
    for _ in range(ro.randrange(12, 25)):
        t = at(d, ro, 8, 23)
        cid = new_customer(t)
        out.append((t, [insert("customers", customers[cid])]))
    # orders, numbered in the order they were placed, as a sequence would
    drafts = []
    for shop_id, _, _, _, channel, base in SHOPS:
        n = max(0, int(ro.gauss(base * factor, base * 0.12)))
        for _ in range(n):
            t = at(d, ro, 0 if channel == "online" else 10, 24 if channel == "online" else 22)
            drafts.append((t, shop_id, channel))
    drafts.sort()
    for t, shop_id, channel in drafts:
        oid = next_order
        next_order += 1
        cust = None
        if channel == "online" or ro.random() < 0.55:
            while True:
                cust = ro.randrange(1, next_customer)
                if cust not in erased and customers[cust]["created_at"] <= ts(t):
                    break
        o = {"order_id": oid, "shop_id": shop_id, "customer_id": cust,
             "ordered_at": ts(t), "status": "completed", "updated_at": ts(t)}
        orders[oid] = o
        recent_ids.append(oid)
        stmts = [insert("orders", o)]
        total = 0
        nl = weighted(ro, [(1, 60), (2, 27), (3, 10), (4, 3)])
        chosen = set()
        for ln in range(1, nl + 1):
            while True:
                b = ro.choices(popular, book_weight)[0]
                if b not in chosen:
                    chosen.add(b)
                    break
            q = 1 if ro.random() < 0.92 else 2
            price = books[b]["list_price_cents"]
            if ro.random() < 0.1:
                price = int(round(price * 0.9, -1))
            line = {"order_id": oid, "line_no": ln, "book_id": b, "quantity": q,
                    "unit_price_cents": price}
            lines.append(line)
            stmts.append(insert("order_lines", line))
            total += q * price
        p = {"payment_id": next_payment, "order_id": oid,
             "method": weighted(ro, METHODS if channel == "store" else METHODS[:3]),
             "amount_cents": total, "paid_at": ts(t + dt.timedelta(seconds=ro.randrange(20, 90)))}
        next_payment += 1
        payments.append(p)
        stmts.append(insert("payments", p))
        out.append((t, stmts))
    # back office: cancellations and refunds of recent orders
    horizon = ts(dt.datetime(d.year, d.month, d.day, tzinfo=TZ) - dt.timedelta(days=14))
    recent_ids[:] = [i for i in recent_ids if orders[i]["ordered_at"] >= horizon]
    recent = [orders[i] for i in recent_ids if orders[i]["status"] == "completed"]
    for o in ro.sample(recent, min(len(recent), ro.randrange(3, 9))):
        t = at(d, ro, 9, 18)
        if o["ordered_at"] >= ts(t):
            continue
        o["status"] = "refunded" if ro.random() < 0.6 else "cancelled"
        o["updated_at"] = ts(t)
        out.append((t, [f"UPDATE orders SET status = '{o['status']}', updated_at = "
                        f"{sql_lit(ts(t))} WHERE order_id = {o['order_id']};"]))
    # customers move
    for _ in range(ro.randrange(2, 6)):
        cid = ro.randrange(1, next_customer)
        if cid in erased:
            continue
        t = at(d, ro, 8, 22)
        c = customers[cid]
        if c["created_at"] >= ts(t):
            continue
        ns = weighted(ro, list(STATE_WEIGHT.items()))
        c["state"], c["city"], c["updated_at"] = ns, ro.choice(CITIES[ns]), ts(t)
        out.append((t, [f"UPDATE customers SET city = {sql_lit(c['city'])}, state = "
                        f"'{ns}', updated_at = {sql_lit(ts(t))} WHERE customer_id = {cid};"]))
    # a publisher changes a list price
    for _ in range(ro.randrange(0, 4)):
        b = books[ro.randrange(1, 1201)]
        t = at(d, ro, 7, 9)
        b["list_price_cents"] = b["list_price_cents"] + ro.choice([500, 1000, -500])
        b["updated_at"] = ts(t)
        out.append((t, [f"UPDATE books SET list_price_cents = {b['list_price_cents']}, "
                        f"updated_at = {sql_lit(ts(t))} WHERE book_id = {b['book_id']};"]))
    # somebody asks to be forgotten, about once a week
    if ro.random() < 0.15:
        cid = ro.randrange(1, next_customer - 50)
        if cid not in erased:
            t = at(d, ro, 10, 17)
            erased.add(cid)
            stmts = [f"UPDATE orders SET customer_id = NULL, updated_at = {sql_lit(ts(t))} "
                     f"WHERE customer_id = {cid};",
                     f"DELETE FROM customers WHERE customer_id = {cid};"]
            for o in orders.values():
                if o["customer_id"] == cid:
                    o["customer_id"], o["updated_at"] = None, ts(t)
            del customers[cid]
            out.append((t, stmts))
    out.sort(key=lambda x: x[0])
    if d == CUT:
        snapshot = (
            {k: dict(v) for k, v in customers.items()},
            {k: dict(v) for k, v in orders.items()},
            list(lines), list(payments), {k: dict(v) for k, v in books.items()})
    if d > CUT:
        day_sql[d] = out

# ---------------------------------------------------------------- writing
os.makedirs(os.path.join(OUT, "initial"), exist_ok=True)
os.makedirs(os.path.join(OUT, "days"), exist_ok=True)
os.makedirs(os.path.join(OUT, "events"), exist_ok=True)
os.makedirs(os.path.join(OUT, "stock"), exist_ok=True)


def write(name, header, rows):
    with open(os.path.join(OUT, "initial", name + ".csv"), "w", newline="",
              encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(header)
        for r in rows:
            w.writerow(["" if r[h] is None else r[h] for h in header])


s_customers, s_orders, s_lines, s_payments, s_books = snapshot
write("shops", ["shop_id", "name", "city", "state", "channel"],
      [dict(zip(["shop_id", "name", "city", "state", "channel"], s[:5])) for s in SHOPS])
write("books", ["book_id", "isbn", "title", "category", "publisher", "list_price_cents",
                "updated_at"], s_books.values())
write("customers", ["customer_id", "name", "email", "city", "state", "created_at",
                    "updated_at"], sorted(s_customers.values(), key=lambda c: c["customer_id"]))
write("orders", ["order_id", "shop_id", "customer_id", "ordered_at", "status", "updated_at"],
      sorted(s_orders.values(), key=lambda o: o["order_id"]))
write("order_lines", ["order_id", "line_no", "book_id", "quantity", "unit_price_cents"], s_lines)
write("payments", ["payment_id", "order_id", "method", "amount_cents", "paid_at"], s_payments)

for d, out in day_sql.items():
    with open(os.path.join(OUT, "days", f"{d}.sql"), "w", encoding="utf-8") as f:
        f.write(f"-- {d}: what the tills, the website and the back office did that day\n")
        for t, stmts in out:
            f.write(f"-- {t.strftime('%H:%M:%S')}\nBEGIN;\n" + "\n".join(stmts) + "\nCOMMIT;\n")

# --------------------------------------------------------- website events
re_ = random.Random(404)
seq = 0
spill = []
for d in days(dt.date(2026, 3, 1), LAST):
    rows = spill
    spill = []
    for _ in range(int(re_.gauss(2600, 200))):
        seq += 1
        t = at(d, re_, 0, 24)
        ev = {"event_id": f"e{seq:07d}", "occurred_at": t.isoformat(),
              "session": f"s{re_.randrange(1, 900000):06d}",
              "type": weighted(re_, [("view", 80), ("add_to_cart", 15), ("purchase", 5)]),
              "book_id": re_.choices(popular, book_weight)[0]}
        late = re_.random() < 0.01 and t.hour == 23
        (spill if late else rows).append((t, ev))
        if re_.random() < 0.004:  # the collector retried and both copies landed
            rows.append((t + dt.timedelta(seconds=2), ev))
    rows.sort(key=lambda x: x[0])
    with open(os.path.join(OUT, "events", f"{d}.jsonl"), "w", encoding="utf-8") as f:
        for _, ev in rows:
            f.write(json.dumps(ev, separators=(",", ":")) + "\n")

# ------------------------------------------------------ distributor stock
rs = random.Random(505)
level = {b: rs.randrange(0, 40) for b in books}
for d in days(dt.date(2026, 3, 1), LAST):
    for b in level:
        level[b] = max(0, level[b] + rs.randrange(-3, 4))
        # On 5 March the distributor moved to a new system, and its export changed
    # without warning: Latin-1, semicolons, Portuguese headers. From the 6th it
    # is back to what it was. Lesson 3 meets the file.
    changed = d == dt.date(2026, 3, 5)
    with open(os.path.join(OUT, "stock", f"{d}.csv"), "w", newline="",
              encoding="latin-1" if changed else "utf-8") as f:
        w = csv.writer(f, lineterminator="\n", delimiter=";" if changed else ",")
        w.writerow(["isbn", "disponível", "data"] if changed else ["isbn", "available", "as_of"])
        for b in sorted(level):
            w.writerow([books[b]["isbn"], level[b],
                        f"{d.strftime('%d/%m/%Y')} 06:00" if changed else f"{d}T06:00:00-03:00"])

# ------------------------------------------------------ publishers' prices
rp = random.Random(606)
prices = []
for b in sorted(books):
    changed = dt.datetime(2026, 1, 1, tzinfo=TZ) + dt.timedelta(minutes=rp.randrange(0, 89 * 1440))
    prices.append({"isbn": books[b]["isbn"], "publisher": books[b]["publisher"],
                   "list_price_cents": books[b]["list_price_cents"] + rp.choice([0, 0, 500, 1000]),
                   "currency": "BRL", "updated_at": changed.isoformat()})
# Three publishers send their feed the way real feeds arrive: Maré writes ISBNs
# with hyphens, Farol sends the price as a string and the currency in lower
# case, and Granito's name carries a trailing space. Four prices are missing.
for p in prices:
    if p["publisher"] == "Maré":
        i = p["isbn"]
        p["isbn"] = f"{i[:3]}-{i[3:5]}-{i[5:10]}-{i[10:12]}-{i[12]}"
    elif p["publisher"] == "Farol":
        p["list_price_cents"], p["currency"] = str(p["list_price_cents"]), "brl"
    elif p["publisher"] == "Granito":
        p["publisher"] = "Granito "
for p in rp.sample(prices, 4):
    p["list_price_cents"] = None
prices.sort(key=lambda p: (p["updated_at"], p["isbn"]))
with open(os.path.join(OUT, "prices.json"), "w", encoding="utf-8") as f:
    json.dump(prices, f, indent=0)
print(f"customers {len(s_customers)}, orders {len(s_orders)}, lines {len(s_lines)} at {CUT}; "
      f"{len(day_sql)} days of changes")
```

**It uses fixed seeds, so it draws the same three months on every machine.** That is what lets a
transcript in lesson 12 show the number your own terminal will show.
