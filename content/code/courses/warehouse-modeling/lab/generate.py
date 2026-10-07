"""The operational data of Ponto Final, a chain of bookshops that does not exist.

Run it in ~/wh. It writes one CSV file per table of the shop's database into
data/, and the three monthly customer extracts of lesson 5 into extracts/.
Every table is drawn from its own random.Random with a fixed seed, so the same
files come out on every run and on every machine, and they are the files the
course was recorded with.

Nothing here is real. The people, the books, the authors and the publishers
are made from word lists; the e-mail addresses are under example.com,
example.net and example.org, which are reserved for examples.
"""

import bisect
import csv
import datetime as dt
import math
import os
import random

os.makedirs("data", exist_ok=True)
os.makedirs("extracts", exist_ok=True)
FIRST = dt.date(2024, 1, 1)
LAST = dt.date(2025, 12, 31)
TZ = "-03"  # America/Sao_Paulo has kept UTC-3 all year since 2019

SHOPS = [
    # id, name, city, state, channel, opened_on, base orders a day
    (1, "Paulista", "São Paulo", "SP", "store", dt.date(2012, 4, 2), 120),
    (2, "Pinheiros", "São Paulo", "SP", "store", dt.date(2019, 9, 14), 95),
    (3, "Cambuí", "Campinas", "SP", "store", dt.date(2016, 3, 5), 60),
    (4, "Savassi", "Belo Horizonte", "MG", "store", dt.date(2018, 6, 1), 70),
    (5, "Batel", "Curitiba", "PR", "store", dt.date(2021, 11, 20), 50),
    (6, "Moinhos", "Porto Alegre", "RS", "store", dt.date(2025, 3, 8), 45),
    (7, "Online", None, None, "online", dt.date(2020, 5, 4), 230),
]

CATEGORIES = {
    # top level, then the middle level with its leaves
    "Fiction": {
        "Crime": ["Detective", "Thriller", "Nordic noir"],
        "Literary fiction": ["Brazilian", "Translated", "Short stories"],
        "Science fiction": ["Space opera", "Dystopia"],
        "Fantasy": ["Epic fantasy", "Urban fantasy"],
        "Romance": ["Contemporary romance", "Historical romance"],
    },
    "Non-fiction": {
        "History": ["Brazilian history", "World history"],
        "Science": ["Physics", "Biology", "Mathematics"],
        "Business": ["Management", "Economics"],
        "Biography": ["Memoir", "Biography"],
        "Cooking": ["Brazilian cooking", "Baking"],
    },
    "Children": {
        "Picture books": ["Picture books"],
        "Young adult": ["Young adult"],
        "Early readers": ["Early readers"],
    },
    "Comics": {
        "Graphic novels": ["Graphic novels"],
        "Manga": ["Manga"],
    },
}

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
AUTHOR_FIRST = """Ada Bento Clara Dorian Edith Franz Greta Hugo Irene Jonas Klara
Lionel Marta Nils Olga Pablo Quentin Rosa Stellan Tomás Ursula Vera Walter Xenia Yara
Zeno Agnes Bruna Cecília Davi Emil Flora Gael Hilda Inês Jorge Karin Lauro Mirela
Noémia Osvaldo Petra Rui Selma Teodoro Úrsula Vasco Wanda""".split()
AUTHOR_LAST = """Abreu Bergman Carmo Dahl Esteves Falk Grieg Holm Ibsen Jansen Krog
Lindqvist Matos Nyberg Ottesen Paiva Quaresma Rasmussen Sandberg Tavares Uhl Valente
Wahl Xavier Ystad Zorn Amaral Bastos Coelho Dorneles Estrela Fontes Guerra Horta Inácio
Jardim Lacerda Meireles Neves Orvalho Prado Quintela Resende Serrano Torres Umbelino
Viana""".split()
TITLE_ADJ = """Silent Hidden Last Northern Burning Quiet Broken Golden Distant Forgotten
Secret Long Bright Second Little Cold Endless Narrow Paper Salt""".split()
TITLE_NOUN = """Harbour River Garden House Winter Letter Island Mountain Station Mirror
Kingdom Library Sea Bridge Lantern Forest City Road Archive Season Orchard Compass""".split()
PUBLISHERS = """Atlântida Borda Cais Duna Estuário Farol Granito Horizonte Ilha Jangada
Litoral Maré Norte Oásis Planalto Quilombo Restinga Serra Trilha Várzea Vertente Zênite
Aurora Brisa Cerrado""".split()
CITIES = {
    "SP": ["São Paulo", "São Paulo", "São Paulo", "Campinas", "Campinas", "Santos",
           "Guarulhos", "Sorocaba"],
    "MG": ["Belo Horizonte", "Belo Horizonte", "Contagem", "Uberlândia"],
    "PR": ["Curitiba", "Curitiba", "Londrina", "Maringá"],
    "RS": ["Porto Alegre", "Porto Alegre", "Canoas", "Caxias do Sul"],
    "RJ": ["Rio de Janeiro", "Niterói"],
    "BA": ["Salvador"],
    "PE": ["Recife"],
    "DF": ["Brasília"],
}
STATE_WEIGHT = {"SP": 46, "MG": 14, "PR": 11, "RS": 9, "RJ": 9, "BA": 4, "PE": 3, "DF": 4}
TIERS = ["reader", "regular", "patron"]
DOMAINS = ["example.com", "example.net", "example.org"]


def writer(name, header, folder="data"):
    f = open(os.path.join(folder, name + ".csv"), "w", newline="", encoding="utf-8")
    w = csv.writer(f, lineterminator="\n")
    w.writerow(header)
    return f, w


def ts(d, seconds):
    """A timestamp with the shop's offset, seconds after midnight of day d."""
    t = dt.datetime.combine(d, dt.time()) + dt.timedelta(seconds=seconds)
    return t.strftime("%Y-%m-%d %H:%M:%S") + TZ


def days(a, b):
    return [a + dt.timedelta(n) for n in range((b - a).days + 1)]


def isbn13(rng):
    body = "97865" + "".join(str(rng.randrange(10)) for _ in range(7))
    s = sum(int(c) * (1 if i % 2 == 0 else 3) for i, c in enumerate(body))
    return body + str((10 - s % 10) % 10)


def strip_accents(s):
    table = str.maketrans("áàâãéêíóôõúüçÁÉÍÓÚÇ", "aaaaeeiooouucAEIOUC")
    return s.translate(table).lower()


# ---- shops ---------------------------------------------------------------
f, w = writer("shops", ["shop_id", "name", "city", "state", "channel", "opened_on"])
for s in SHOPS:
    w.writerow([s[0], s[1], s[2] or "", s[3] or "", s[4], s[5]])
f.close()

# ---- categories -----------------------------------------------------------
f, w = writer("categories", ["category_id", "name", "parent_id"])
leaves = []  # (category_id, top name)
cid = 0
for top, mids in CATEGORIES.items():
    cid += 1
    top_id = cid
    w.writerow([top_id, top, ""])
    for mid, lvs in mids.items():
        cid += 1
        mid_id = cid
        w.writerow([mid_id, mid, top_id])
        for leaf in lvs:
            if leaf == mid:
                # a two-level branch: the middle level is also where books sit
                leaves.append((mid_id, top))
                continue
            cid += 1
            w.writerow([cid, leaf, mid_id])
            leaves.append((cid, top))
f.close()

# ---- publishers and authors -----------------------------------------------
f, w = writer("publishers", ["publisher_id", "name"])
for i, p in enumerate(PUBLISHERS, 1):
    w.writerow([i, "Editora " + p])
f.close()

rng = random.Random(1801)
f, w = writer("authors", ["author_id", "name", "country"])
author_names = set()
N_AUTHORS = 1800
countries = ["BR"] * 9 + ["PT", "SE", "NO", "DK", "US", "GB", "FR", "AR", "DE"]
aid = 0
while aid < N_AUTHORS:
    name = rng.choice(AUTHOR_FIRST) + " " + rng.choice(AUTHOR_LAST)
    if rng.random() < 0.35:
        name = name.split()[0] + " " + rng.choice(AUTHOR_LAST) + " " + name.split()[1]
    if name in author_names:
        continue
    author_names.add(name)
    aid += 1
    w.writerow([aid, name, rng.choice(countries)])
f.close()

# ---- books ---------------------------------------------------------------
rng = random.Random(3000)
N_BOOKS = 3000
books = []  # (book_id, category_id, list_price_cents_2024, published_on, top)
f, w = writer("books", ["book_id", "isbn", "title", "category_id", "publisher_id",
                        "format", "list_price_cents", "published_on"])
fb, wb = writer("book_authors", ["book_id", "author_id", "position"])
isbns = set()
titles = {}
for bid in range(1, N_BOOKS + 1):
    leaf, top = rng.choice(leaves)
    title = "The " + rng.choice(TITLE_ADJ) + " " + rng.choice(TITLE_NOUN)
    titles[title] = titles.get(title, 0) + 1
    if titles[title] > 1:
        title += " " + ["II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"][min(titles[title] - 2, 8)] \
            if titles[title] <= 10 else " (" + str(titles[title]) + ")"
    code = isbn13(rng)
    while code in isbns:
        code = isbn13(rng)
    isbns.add(code)
    fmt = rng.choices(["paperback", "hardcover", "ebook"], [70, 20, 10])[0]
    base = {"Children": 4990, "Comics": 6990}.get(top, 7490)
    price = base + rng.randrange(-20, 60) * 100
    if fmt == "hardcover":
        price += 3000
    if fmt == "ebook":
        price = price // 2
    price = price - price % 100 + 90  # every price ends in ,90
    # two in three titles were out before the period; the rest come out during it
    if rng.random() < 0.67:
        pub = dt.date(2005, 1, 1) + dt.timedelta(rng.randrange((dt.date(2023, 12, 31) - dt.date(2005, 1, 1)).days))
    else:
        pub = FIRST + dt.timedelta(rng.randrange((LAST - FIRST).days - 30))
    books.append((bid, leaf, price, pub, top, fmt))
    publisher = rng.randrange(1, len(PUBLISHERS) + 1)
    # the 2025 list price is the 2024 one plus 7%, rounded down to end in ,90
    p25 = int(price * 1.07)
    p25 = p25 - p25 % 100 + 90
    w.writerow([bid, code, title, leaf, publisher, fmt, p25, pub])
    n = rng.choices([1, 2, 3], [85, 12, 3])[0]
    for pos, a in enumerate(rng.sample(range(1, N_AUTHORS + 1), n), 1):
        wb.writerow([bid, a, pos])
f.close()
fb.close()

PRICE_RISE = dt.date(2025, 1, 1)


def unit_price(book, d):
    p = book[2]
    if d >= PRICE_RISE:
        p = int(p * 1.07)
        p = p - p % 100 + 90
    return p


# popularity: a Zipf-like weight by a shuffled rank, so a few titles sell most
rng = random.Random(77)
rank = list(range(N_BOOKS))
rng.shuffle(rank)
popularity = [1.0 / (r + 8) ** 1.1 for r in rank]

# ---- customers and their history -------------------------------------------
rng = random.Random(4000)
N_CUSTOMERS = 40000
states = list(STATE_WEIGHT)
customers = []
emails = set()
f, w = writer("customers", ["customer_id", "email", "name", "city", "state", "tier",
                            "created_at", "updated_at"])
fc, wc = writer("customer_changes", ["change_id", "customer_id", "changed_at", "field",
                                     "old_value", "new_value"])
change_id = 0
history = {}  # customer_id -> list of (date, field, old, new)
start = dt.date(2019, 1, 1)
span = (dt.date(2025, 11, 30) - start).days
for cid_ in range(1, N_CUSTOMERS + 1):
    first, last = rng.choice(FIRST_NAMES), rng.choice(SURNAMES)
    if rng.random() < 0.4:
        last = rng.choice(SURNAMES) + " " + last
    name = first + " " + last
    local = strip_accents(first + "." + last.split()[-1])
    email = f"{local}@{rng.choice(DOMAINS)}"
    k = 1
    while email in emails:
        k += 1
        email = f"{local}{k}@{email.split('@')[1]}"
    emails.add(email)
    state = rng.choices(states, [STATE_WEIGHT[s] for s in states])[0]
    city = rng.choice(CITIES[state])
    # more people joined recently
    created = start + dt.timedelta(int(span * math.sqrt(rng.random())))
    created_s = rng.randrange(8 * 3600, 22 * 3600)
    tier = "reader"
    events = []
    # tier upgrades
    if rng.random() < 0.22:
        d = created + dt.timedelta(rng.randrange(60, 900))
        if d <= LAST:
            events.append((d, "tier", "reader", "regular"))
            if rng.random() < 0.35:
                d2 = d + dt.timedelta(rng.randrange(60, 700))
                if d2 <= LAST:
                    events.append((d2, "tier", "regular", "patron"))
    # a move to another city, sometimes another state
    if rng.random() < 0.08:
        d = created + dt.timedelta(rng.randrange(30, 1500))
        if d <= LAST:
            ns = state if rng.random() < 0.5 else rng.choices(states, [STATE_WEIGHT[s] for s in states])[0]
            nc = rng.choice([c for c in CITIES[ns] if c != city] or CITIES[ns])
            if nc != city:
                events.append((d, "city", city, nc))
                if ns != state:
                    events.append((d, "state", state, ns))
    # a new e-mail address
    if rng.random() < 0.04:
        d = created + dt.timedelta(rng.randrange(30, 1500))
        if d <= LAST:
            new_email = f"{local}.{rng.randrange(10, 99)}@{rng.choice(DOMAINS)}"
            if new_email not in emails:
                emails.add(new_email)
                events.append((d, "email", email, new_email))
    # the name was mistyped at the till when the record was made, and fixed later
    if rng.random() < 0.015 and "a" in name[1:]:
        d = created + dt.timedelta(rng.randrange(1, 400))
        if d <= LAST:
            wrong = name[0] + name[1:].replace("a", "", 1)
            events.append((d, "name", wrong, name))
            name = wrong
    events.sort()
    cur = {"tier": tier, "city": city, "state": state, "email": email, "name": name}
    updated = dt.datetime.combine(created, dt.time()) + dt.timedelta(seconds=created_s)
    at = {}  # one moment per day: a move changes the city and the state together
    for d, field, old, new in events:
        change_id += 1
        secs = at.setdefault(d, rng.randrange(8 * 3600, 22 * 3600))
        wc.writerow([change_id, cid_, ts(d, secs), field, old, new])
        cur[field] = new
        updated = dt.datetime.combine(d, dt.time()) + dt.timedelta(seconds=secs)
    history[cid_] = {"created": created, "first": {"tier": tier, "city": city, "state": state,
                                                    "email": email, "name": name},
                     "events": events}
    w.writerow([cid_, cur["email"], cur["name"], cur["city"], cur["state"], cur["tier"],
                ts(created, created_s), updated.strftime("%Y-%m-%d %H:%M:%S") + TZ])
    customers.append((cid_, created, state))
f.close()
fc.close()


def as_of(cid_, d):
    h = history[cid_]
    cur = dict(h["first"])
    for ed, field, old, new in h["events"]:
        if ed < d:
            cur[field] = new
    return cur


# the three monthly extracts of lesson 5: the customer table as the source
# system held it at midnight on the first of each month
for d in (dt.date(2025, 10, 1), dt.date(2025, 11, 1), dt.date(2025, 12, 1)):
    f, w = writer(f"customers_{d}", ["customer_id", "email", "name", "city", "state", "tier"],
                  "extracts")
    for cid_, created, _ in customers:
        if created < d:
            c = as_of(cid_, d)
            w.writerow([cid_, c["email"], c["name"], c["city"], c["state"], c["tier"]])
    f.close()

# customers by state, ordered by the day they joined, to pick a known buyer
by_state = {s: [] for s in states}
for cid_, created, state in customers:
    by_state[state].append((created, cid_))
everyone = sorted((created, cid_) for cid_, created, _ in customers)
for s in by_state:
    by_state[s].sort()
by_state_days = {s: [c for c, _ in v] for s, v in by_state.items()}
everyone_days = [c for c, _ in everyone]


def pick_customer(rng, d, state):
    if state and rng.random() < 0.85:
        pool, pdays = by_state[state], by_state_days[state]
    else:
        pool, pdays = everyone, everyone_days
    n = bisect.bisect_left(pdays, d)  # joined on an earlier day
    if n == 0:
        return None
    # recent joiners and a core of regulars buy more: a skew towards both ends
    i = int(n * (rng.random() ** 0.6))
    return pool[min(i, n - 1)][1]


# ---- promotions --------------------------------------------------------------
PROMOS = [
    (1, "CARNAVAL24", "Carnival reading", 15, dt.date(2024, 2, 5), dt.date(2024, 2, 18), "Fiction"),
    (2, "FERIAS24", "Winter holidays", 20, dt.date(2024, 7, 1), dt.date(2024, 7, 31), "Children"),
    (3, "BIENAL24", "Book fair week", 25, dt.date(2024, 9, 6), dt.date(2024, 9, 15), None),
    (4, "BLACK24", "Black Friday", 30, dt.date(2024, 11, 29), dt.date(2024, 12, 1), None),
    (5, "NATAL24", "Christmas comics", 10, dt.date(2024, 12, 10), dt.date(2024, 12, 24), "Comics"),
    (6, "CARNAVAL25", "Carnival reading", 15, dt.date(2025, 2, 24), dt.date(2025, 3, 9), "Fiction"),
    (7, "FERIAS25", "Winter holidays", 20, dt.date(2025, 7, 1), dt.date(2025, 7, 31), "Children"),
    (8, "BIENAL25", "Book fair week", 25, dt.date(2025, 9, 5), dt.date(2025, 9, 14), None),
    (9, "BLACK25", "Black Friday", 30, dt.date(2025, 11, 28), dt.date(2025, 11, 30), None),
    (10, "NATAL25", "Christmas comics", 10, dt.date(2025, 12, 10), dt.date(2025, 12, 24), "Comics"),
]
f, w = writer("promotions", ["promotion_id", "code", "name", "percent_off", "starts_on",
                             "ends_on", "category"])
for p in PROMOS:
    w.writerow([p[0], p[1], p[2], p[3], p[4], p[5], p[6] or ""])
f.close()


def promo_for(d, top):
    for p in PROMOS:
        if p[4] <= d <= p[5] and (p[6] is None or p[6] == top):
            return p
    return None


# ---- orders, lines and payments ---------------------------------------------
rng = random.Random(2024)
fo, wo = writer("orders", ["order_id", "shop_id", "customer_id", "ordered_at", "status",
                           "shipping_cents", "paid_at", "shipped_at", "delivered_at"])
fl, wl = writer("order_lines", ["order_id", "line_no", "book_id", "quantity",
                                "unit_price_cents", "discount_cents", "promotion_id"])
fp, wp = writer("payments", ["payment_id", "order_id", "method", "installments",
                             "amount_cents"])
SEASON = {1: 0.8, 2: 0.9, 3: 0.95, 4: 1.0, 5: 1.05, 6: 1.0, 7: 1.1, 8: 0.95, 9: 1.05,
          10: 1.0, 11: 1.15, 12: 1.7}
STORE_WEEKDAY = [0.85, 0.85, 0.9, 0.95, 1.1, 1.55, 0.8]
ONLINE_WEEKDAY = [1.1, 1.05, 1.0, 1.0, 0.95, 0.9, 1.0]
DELIVERY_DAYS = {"SP": (1, 3), "MG": (2, 5), "PR": (2, 5), "RS": (3, 6), "RJ": (2, 4),
                 "BA": (4, 8), "PE": (4, 9), "DF": (3, 6)}
SHIPPING = 1490
FREE_FROM = 15000

# cumulative popularity per day: only books already published can be sold
pub_order = sorted(range(N_BOOKS), key=lambda i: books[i][3])
pub_days = [books[i][3] for i in pub_order]
cum = []
acc = 0.0
for i in pub_order:
    acc += popularity[i]
    cum.append(acc)


def pick_book(rng, d):
    n = bisect.bisect_right(pub_days, d)
    x = rng.random() * cum[n - 1]
    return books[pub_order[bisect.bisect_left(cum, x, 0, n)]]


def business_days_after(d, n):
    while n > 0:
        d += dt.timedelta(1)
        if d.weekday() < 5:
            n -= 1
    return d


order_id = 100000
payment_id = 500000
for d in days(FIRST, LAST):
    years = (d - FIRST).days / 365.0
    todays = []
    for shop in SHOPS:
        sid, _, _, sstate, channel, opened, base = shop
        if d < opened:
            continue
        if channel == "store":
            mean = base * SEASON[d.month] * STORE_WEEKDAY[d.weekday()] * (1 + 0.04 * years)
            if d.month == 12 and d.day in (24, 31):
                mean *= 0.6
            if (d.month, d.day) in ((1, 1), (12, 25)):
                continue
        else:
            mean = base * SEASON[d.month] * ONLINE_WEEKDAY[d.weekday()] * (1 + 0.35 * years)
            if promo_for(d, None) and promo_for(d, None)[1].startswith("BLACK"):
                mean *= 4.0
        n_orders = max(0, int(rng.gauss(mean, math.sqrt(mean))))
        for _ in range(n_orders):
            if channel == "store":
                secs = rng.randrange(9 * 3600, 21 * 3600 + 1800)
            else:
                secs = int(rng.triangular(0, 86399, 20 * 3600))
            todays.append((secs, shop))
    # the till and the website draw order numbers from one sequence, so the
    # numbers rise with the time an order was placed
    todays.sort(key=lambda o: (o[0], o[1][0]))
    for secs, shop in todays:
        sid, _, _, sstate, channel, opened, base = shop
        order_id += 1
        if channel == "store":
            cust = pick_customer(rng, d, sstate) if rng.random() < 0.55 else None
        else:
            cust = pick_customer(rng, d, None)
        ordered = ts(d, secs)
        n_lines = rng.choices([1, 2, 3, 4, 5, 6], [65, 22, 8, 3, 1.4, 0.6])[0]
        chosen = set()
        total = 0
        line_no = 0
        for _ in range(n_lines):
            b = pick_book(rng, d)
            if b[0] in chosen:
                continue
            chosen.add(b[0])
            line_no += 1
            q = rng.choices([1, 2, 3], [92, 6, 2])[0]
            up = unit_price(b, d)
            p = promo_for(d, b[4])
            disc, pid = 0, ""
            if p and rng.random() < (0.3 if channel == "store" else 0.6):
                disc = round(up * q * p[3] / 100)
                pid = p[0]
            total += up * q - disc
            wl.writerow([order_id, line_no, b[0], q, up, disc, pid])
        status = "completed"
        ship = 0
        paid = shipped = delivered = ""
        if channel == "online":
            ship = SHIPPING if total < FREE_FROM else 0
            total += ship
            pt = dt.datetime.combine(d, dt.time()) + dt.timedelta(seconds=secs + rng.randrange(20, 3600))
            paid = pt.strftime("%Y-%m-%d %H:%M:%S") + TZ
            r = rng.random()
            cstate = history[cust]["first"]["state"] if cust else "SP"
            if r < 0.02:
                status = "cancelled"
                paid = ""
            else:
                sd = business_days_after(pt.date(), rng.choice([1, 1, 1, 2, 2, 3]))
                lo, hi = DELIVERY_DAYS[cstate]
                dd = business_days_after(sd, rng.randint(lo, hi))
                shipped = ts(sd, rng.randrange(14 * 3600, 18 * 3600))
                if sd > LAST:
                    status, shipped = "paid", ""
                elif dd > LAST:
                    status = "shipped"
                else:
                    delivered = ts(dd, rng.randrange(9 * 3600, 19 * 3600))
                    status = "returned" if r > 0.99 else "delivered"
        wo.writerow([order_id, sid, cust or "", ordered, status, ship, paid, shipped, delivered])
        if status == "cancelled":
            continue
        # payments: usually one, sometimes a gift card and a card for the rest
        if rng.random() < 0.025 and total > 4000:
            payment_id += 1
            gift = min(total - 1000, rng.choice([3000, 5000, 10000]))
            wp.writerow([payment_id, order_id, "gift_card", 1, gift])
            rest = total - gift
        else:
            rest = total
        if channel == "store":
            method = rng.choices(["card", "pix", "cash"], [58, 28, 14])[0]
        else:
            method = rng.choices(["card", "pix"], [55, 45])[0]
        inst = 1
        if method == "card" and rest > 10000:
            inst = rng.choices([1, 2, 3, 4, 5, 6], [40, 20, 20, 8, 6, 6])[0]
        payment_id += 1
        wp.writerow([payment_id, order_id, method, inst, rest])
fo.close()
fl.close()
fp.close()

# ---- month-end stock counts ------------------------------------------------------
rng = random.Random(555)
f, w = writer("stock_counts", ["count_date", "shop_id", "book_id", "on_hand"])
month_ends = []
d = FIRST
while d <= LAST:
    nxt = dt.date(d.year + (d.month == 12), d.month % 12 + 1, 1)
    month_ends.append(nxt - dt.timedelta(1))
    d = nxt
by_pop = sorted(range(N_BOOKS), key=lambda i: -popularity[i])
for me in month_ends:
    for shop in SHOPS:
        sid, opened, base = shop[0], shop[5], shop[6]
        if me < opened:
            continue
        carried = 2400 if shop[4] == "online" else 900 + base * 8
        for i in by_pop[:carried]:
            b = books[i]
            if b[3] > me or b[5] == "ebook":
                continue
            expected = 2 + popularity[i] * base * 40
            w.writerow([me, sid, b[0], max(0, int(rng.gauss(expected, math.sqrt(expected))))])
f.close()

# ---- author events and who came ---------------------------------------------------
rng = random.Random(909)
f, w = writer("events", ["event_id", "shop_id", "author_id", "held_on"])
fa, wa = writer("event_attendance", ["event_id", "customer_id"])
eid = 0
for d in days(FIRST, LAST):
    if d.weekday() != 5:
        continue
    for shop in SHOPS[:6]:
        if d < shop[5] or rng.random() > 0.2:
            continue
        eid += 1
        w.writerow([eid, shop[0], rng.randrange(1, N_AUTHORS + 1), d])
        came = set()
        for _ in range(rng.randrange(8, 45)):
            c = pick_customer(rng, d, shop[3])
            if c and c not in came:
                came.add(c)
                wa.writerow([eid, c])
f.close()
fa.close()
