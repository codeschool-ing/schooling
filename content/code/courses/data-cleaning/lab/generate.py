"""The raw data of Quitanda Verde, an organic grocer that does not exist.

Writes the files the course cleans into the directory given as the only
argument: what the company's systems exported at the start of January 2026,
with every defect those systems would really leave behind, plus a `truth/`
directory saying where each planted defect is, so that a lesson can measure
how well a technique found them.

Everything is drawn from random.Random with fixed seeds, one generator per
file, so the same bytes come out on every run and on every machine, and
changing how one file is drawn does not move the numbers of another.

WHAT IS INVENTED AND WHAT IS NOT.

  invented  every person, order, product, price, store sale, survey answer,
            supplier invoice, sales target and exchange rate. The names come
            from word lists, the e-mail addresses are under example.com,
            example.net and example.org, which are reserved for examples, and
            the exchange rates are the ones a finance team booked for its own
            accounts, not the central bank's.
  real      ref/ibge_states.csv and ref/ibge_cities.csv carry IBGE's own
            codes for the 27 federative units and for the five cities the
            company serves; ref/holidays_2025.csv carries the national holidays
            and optional days of the federal government's published calendar
            for 2025. Lesson 14 says where each comes from.
"""

import collections
import csv
import datetime as dt
import math
import os
import random
import sys
import unicodedata

OUT = sys.argv[1]
TRUTH = os.path.join(OUT, "truth")
REF = os.path.join(OUT, "ref")
RAW = os.path.join(OUT, "raw")
for d in (TRUTH, REF, RAW):
    os.makedirs(d, exist_ok=True)

YEAR_FIRST = dt.date(2025, 1, 1)
YEAR_LAST = dt.date(2025, 12, 31)
CRM_EXPORTED = dt.date(2025, 12, 10)  # the customer file is older than the orders

CITIES = [
    # city, state, weight, CEP ranges, the store there
    ("São Paulo", "SP", 40, [(1000000, 5999999), (8000000, 8499999)], "Pinheiros"),
    ("Campinas", "SP", 13, [(13000001, 13139999)], "Cambuí"),
    ("Rio de Janeiro", "RJ", 20, [(20000000, 23799999)], "Botafogo"),
    ("Belo Horizonte", "MG", 14, [(30000000, 31999999)], "Savassi"),
    ("Curitiba", "PR", 13, [(80000000, 82999999)], "Batel"),
]
STORE_OF = {c[0]: c[4] for c in CITIES}

# How each city was typed, by whoever typed it. The first is the canonical.
CITY_VARIANTS = {
    "São Paulo": [("São Paulo", 70), ("Sao Paulo", 12), ("SAO PAULO", 6), ("são paulo", 5),
                  ("S. Paulo", 3), ("São Paulo ", 4)],
    "Campinas": [("Campinas", 85), ("campinas", 9), ("CAMPINAS", 6)],
    "Rio de Janeiro": [("Rio de Janeiro", 72), ("Rio De Janeiro", 12), ("RJ", 6),
                       ("rio de janeiro", 6), ("Rio", 4)],
    "Belo Horizonte": [("Belo Horizonte", 74), ("BH", 10), ("B. Horizonte", 5),
                       ("Belo Horizonte ", 6), ("belo horizonte", 5)],
    "Curitiba": [("Curitiba", 80), ("CURITIBA", 8), ("Curitiba - PR", 7), ("curitiba", 5)],
}
STATE_VARIANTS = {
    "SP": [("SP", 85), ("sp", 8), ("São Paulo", 4), ("S.P.", 3)],
    "RJ": [("RJ", 88), ("rj", 7), ("Rio de Janeiro", 5)],
    "MG": [("MG", 90), ("mg", 6), ("Minas Gerais", 4)],
    "PR": [("PR", 90), ("pr", 6), ("Paraná", 4)],
}

FIRST = """Ana Bruno Carla Daniel Eduarda Felipe Gabriela Henrique Isabela João Larissa
Lucas Mariana Mateus Natália Otávio Paula Rafael Sofia Tiago Valentina Vinícius Beatriz
Caio Débora Enzo Fernanda Gustavo Helena Igor Júlia Leonardo Luana Marcelo Nicole Pedro
Raquel Renato Sabrina Thiago Vitória Yuri Alice Arthur Camila Diego Elisa Fábio Giovana
Heitor Lívia Murilo Priscila Rodrigo Tatiana Ulisses Antônio Cecília Lúcia Mônica Sérgio
Márcia Rogério Patrícia Flávio Vânia Cláudio Simone André Joana Luís Teresa""".split()
LAST = """Silva Santos Oliveira Souza Rodrigues Ferreira Alves Pereira Lima Gomes Costa
Ribeiro Martins Carvalho Almeida Lopes Soares Fernandes Vieira Barbosa Rocha Dias
Nascimento Andrade Moreira Nunes Marques Machado Mendes Freitas Cardoso Ramos Gonçalves
Santana Teixeira Araújo Pinto Correia Moura Cavalcanti Monteiro Barros Campos Duarte
Farias Fonseca Brito Azevedo Castro Pires Simões Magalhães Guimarães Conceição Patrício
Antunes Leão Peixoto Sá Assunção""".split()
COMPANIES = ["Café Aurora Ltda", "Escritório Paulista de Contabilidade", "Clínica Bem Viver",
             "Colégio Monte Verde", "Agência Rota Norte", "Studio Trama Design"]
DOMAINS = ["example.com", "example.net", "example.org"]


def pick(rng, weighted):
    total = sum(w for _, w in weighted)
    x = rng.uniform(0, total)
    for v, w in weighted:
        x -= w
        if x <= 0:
            return v
    return weighted[-1][0]


def strip_accents(s):
    return "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))


def nfd(s):
    return unicodedata.normalize("NFD", s)


def mojibake(s):
    # UTF-8 bytes read back as Latin-1 by the 2023 migration, then saved as UTF-8
    return s.encode("utf-8").decode("latin-1")


def cep_text(n):
    s = f"{n:08d}"
    return s[:5] + "-" + s[5:]


def money(cents):
    return f"{cents / 100:.2f}"


def brl(cents):
    # R$ 1.234,56 — how the old till prints money
    reais, c = divmod(cents, 100)
    r = f"{reais:,}".replace(",", ".")
    return f"R$ {r},{c:02d}"


def write(path, header, rows, encoding="utf-8", delimiter=","):
    with open(path, "w", newline="", encoding=encoding) as f:
        w = csv.writer(f, delimiter=delimiter, lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)


def days(a, b):
    return (b - a).days


# --------------------------------------------------------------------------
# Products

rng = random.Random(1101)
CATS = {
    # canonical category: products (name, unit, price in cents)
    "Frutas": [("Banana prata", "kg", 690), ("Maçã fuji", "kg", 1290), ("Laranja pera", "kg", 590),
               ("Mamão formosa", "kg", 790), ("Manga palmer", "kg", 990), ("Abacaxi pérola", "un", 890),
               ("Limão tahiti", "kg", 650), ("Morango", "un", 1190), ("Uva niágara", "kg", 1590),
               ("Abacate", "kg", 890), ("Maracujá", "kg", 1090), ("Melancia", "kg", 390),
               ("Pera williams", "kg", 1490), ("Goiaba", "kg", 990), ("Tangerina ponkan", "kg", 790)],
    "Verduras": [("Alface crespa", "un", 450), ("Rúcula", "un", 490), ("Couve manteiga", "un", 450),
                 ("Espinafre", "un", 590), ("Agrião", "un", 490), ("Cheiro-verde", "un", 350),
                 ("Manjericão", "un", 490), ("Repolho", "kg", 450), ("Acelga", "un", 590),
                 ("Brócolis ninja", "un", 890), ("Couve-flor", "un", 890), ("Alho-poró", "un", 690)],
    "Legumes": [("Tomate italiano", "kg", 990), ("Cenoura", "kg", 590), ("Batata inglesa", "kg", 590),
                ("Cebola", "kg", 590), ("Abobrinha", "kg", 690), ("Berinjela", "kg", 790),
                ("Pimentão vermelho", "kg", 1490), ("Pepino", "kg", 590), ("Beterraba", "kg", 590),
                ("Mandioca", "kg", 690), ("Batata-doce", "kg", 590), ("Abóbora cabotiá", "kg", 490),
                ("Chuchu", "kg", 450), ("Quiabo", "kg", 990), ("Vagem", "kg", 1190)],
    "Ovos e laticínios": [("Ovos caipira (dúzia)", "un", 1690), ("Queijo minas frescal", "kg", 4990),
                          ("Iogurte natural", "un", 990), ("Manteiga", "un", 1890),
                          ("Leite integral", "un", 790), ("Ricota", "kg", 3990),
                          ("Ovos brancos (dúzia)", "un", 1290)],
    "Grãos e cereais": [("Arroz integral 1 kg", "un", 1190), ("Feijão carioca 1 kg", "un", 990),
                        ("Feijão preto 1 kg", "un", 1090), ("Lentilha 500 g", "un", 1290),
                        ("Grão-de-bico 500 g", "un", 1390), ("Aveia em flocos 500 g", "un", 890),
                        ("Quinoa 500 g", "un", 2190), ("Milho para pipoca 500 g", "un", 690)],
    "Mercearia": [("Mel silvestre 500 g", "un", 3290), ("Café torrado 500 g", "un", 3490),
                  ("Azeite extravirgem 500 ml", "un", 4590), ("Açúcar mascavo 1 kg", "un", 1290),
                  ("Granola 500 g", "un", 2490), ("Castanha-do-pará 200 g", "un", 2890),
                  ("Geleia de morango", "un", 1890), ("Pão de fermentação natural", "un", 2290)],
    "Cestas": [("Cesta pequena da semana", "un", 7990), ("Cesta média da semana", "un", 11990),
               ("Cesta grande da semana", "un", 15990), ("Cesta de frutas", "un", 8990)],
}
CAT_VARIANTS = {
    "Frutas": [("Frutas", 50), ("frutas", 15), ("FRUTAS", 10), ("Fruta", 10), ("Frutas ", 8), ("Fruits", 7)],
    "Verduras": [("Verduras", 60), ("verduras", 15), ("Folhas", 15), ("VERDURAS", 10)],
    "Legumes": [("Legumes", 60), ("legumes", 20), ("Legume", 10), ("LEGUMES", 10)],
    "Ovos e laticínios": [("Ovos e laticínios", 50), ("Ovos e Laticínios", 20), ("Laticínios", 15),
                          ("ovos e laticinios", 15)],
    "Grãos e cereais": [("Grãos e cereais", 50), ("Graos e cereais", 25), ("Grãos", 25)],
    "Mercearia": [("Mercearia", 70), ("mercearia", 15), ("Empório", 15)],
    "Cestas": [("Cestas", 80), ("Cesta", 20)],
}
codes = rng.sample(range(101, 990), sum(len(v) for v in CATS.values()) + 2)
PRODUCTS = []  # (code, name, canonical category, unit, price)
i = 0
for cat, items in CATS.items():
    for name, unit, price in items:
        PRODUCTS.append((f"{codes[i]:05d}", name, cat, unit, price))
        i += 1
DISCONTINUED = [(f"{codes[i]:05d}", "Kiwi", "Frutas", "kg", 1890),
                (f"{codes[i + 1]:05d}", "Palmito pupunha", "Mercearia", "un", 2690)]
# Three products changed price on 1 July; the catalogue export lists both prices
# and no date, so the code appears twice.
REPRICED = {PRODUCTS[0][0]: 790, PRODUCTS[16][0]: 520, PRODUCTS[60][0]: 13490}
REPRICED_ON = dt.date(2025, 7, 1)

prows = []
for code, name, cat, unit, price in PRODUCTS:
    prows.append([code, name, pick(rng, CAT_VARIANTS[cat]), unit, money(price)])
    if code in REPRICED:
        prows.append([code, name, pick(rng, CAT_VARIANTS[cat]), unit, money(REPRICED[code])])
rng.shuffle(prows)
write(os.path.join(RAW, "products.csv"), ["product_code", "name", "category", "unit", "price"], prows)
write(os.path.join(TRUTH, "categories.csv"), ["product_code", "category"],
      sorted([p[0], p[2]] for p in PRODUCTS))
POP = [(p, 6 if p[2] in ("Frutas", "Legumes", "Verduras") else 3 if p[2] != "Cestas" else 4)
       for p in PRODUCTS] + [(DISCONTINUED[0], 2), (DISCONTINUED[1], 2)]

# --------------------------------------------------------------------------
# Customers

rng = random.Random(2202)
people = []  # dicts, the truth about each person


def new_person(pid, signed, city=None, company=None):
    c = city or pick(rng, [(x, x[2]) for x in CITIES])
    first, last = rng.choice(FIRST), rng.choice(LAST)
    if rng.random() < 0.35:
        last = rng.choice(LAST) + " " + last
    name = company or f"{first} {last}"
    handle = strip_accents((company or f"{first}.{last}").lower()).replace(" ", ".")
    lo, hi = rng.choice(c[3])
    return {
        "pid": pid, "name": name, "city": c[0], "state": c[1],
        "email": f"{handle}{rng.randint(1, 99)}@{rng.choice(DOMAINS)}",
        "cep": rng.randint(lo, hi), "signed": signed,
        "birth": None if company else rng.randint(1952, 2006),
        "company": bool(company),
        "channel": pick(rng, [("site", 45), ("app", 30), ("store", 25)]),
        "optin": rng.random() < 0.55,
    }


def signup_date(r):
    # two years of growth, more people each month
    span = days(dt.date(2023, 1, 1), dt.date(2025, 12, 31))
    return dt.date(2023, 1, 1) + dt.timedelta(days=int(span * math.sqrt(r.random())))


N_PEOPLE = 2400
for k in range(N_PEOPLE):
    people.append(new_person(k, signup_date(rng)))
for k, co in enumerate(COMPANIES):
    p = new_person(N_PEOPLE + k, dt.date(2024, 3, 1) + dt.timedelta(days=rng.randint(0, 500)),
                   company=co)
    p["channel"] = "site"
    people.append(p)
# The account that cycles refunds: opened in August, 23 orders in three days.
abuser = new_person(len(people), dt.date(2025, 8, 11), city=CITIES[0])
abuser["channel"] = "app"
people.append(abuser)
# A legacy batch migrated from the 2023 system, whose accents came back mangled.
for p in people:
    p["legacy"] = p["signed"] < dt.date(2023, 10, 1) and rng.random() < 0.3
people.sort(key=lambda p: (p["signed"], p["pid"]))
for n, p in enumerate(people, 1):
    p["cid"] = f"C{n:05d}"

# Homonyms: six different people who share a name with somebody else.
homonyms = []
others = [p for p in people if not p["company"]]
for a in rng.sample(others, 6):
    b = rng.choice([q for q in others if q["city"] != a["city"] and q is not a])
    b["name"] = a["name"]
    homonyms.append((a["cid"], b["cid"]))

# Erased on request (LGPD): their orders stay, their row leaves the export.
ERASED = set(p["cid"] for p in rng.sample([p for p in others if p["signed"] < dt.date(2025, 1, 1)], 12))


def typed_name(p, r):
    n = p["name"]
    if p["legacy"]:
        return mojibake(n)
    if p["channel"] == "app":
        n = nfd(n)
    elif p["channel"] == "store" and r.random() < 0.3:
        n = n.upper()
    return n


def typed_city(p, r):
    c = pick(r, CITY_VARIANTS[p["city"]])
    if p["legacy"]:
        return mojibake(c)
    if p["channel"] == "app":
        c = nfd(c)
    return c


def typed_cep(p, r):
    s = cep_text(p["cep"])
    if p["channel"] == "store":
        return s.replace("-", "") if r.random() < 0.5 else s
    if p["channel"] == "app":
        return str(p["cep"])  # through a spreadsheet: a number, leading zero gone
    return s


def typed_date(p):
    d = p["signed"]
    if p["channel"] == "store":
        return d.strftime("%d/%m/%Y")
    if p["channel"] == "app":
        return d.strftime("%m/%d/%Y")  # the app was built with a US locale
    return d.isoformat()


def typed_birth(p, r):
    if p["birth"] is None:
        return ""
    if p["channel"] == "store":
        return "1900" if r.random() < 0.55 else ("" if r.random() < 0.5 else str(p["birth"]))
    if p["channel"] == "app" and r.random() < 0.15:
        return str(p["birth"])[2:]
    if p["channel"] == "site" and r.random() < 0.2:
        return ""
    return str(p["birth"])


def typed_optin(p, r):
    v = p["optin"]
    if p["channel"] == "site":
        return "true" if v else "false"
    if p["channel"] == "app":
        return "1" if v else "0"
    return r.choice(["S", "sim", "Sim"]) if v else (r.choice(["N", "não", "nao"]) if r.random() < 0.8 else "")


def typed_email(p, r):
    if p["channel"] == "store" and r.random() < 0.45:
        return ""
    e = p["email"]
    if r.random() < 0.06:
        e = e.upper()
    if r.random() < 0.04:
        e = " " + e
    return e


def crm_row(p, r):
    return [p["cid"], typed_name(p, r), typed_email(p, r), typed_cep(p, r), typed_city(p, r),
            pick(r, STATE_VARIANTS[p["state"]]), typed_date(p), typed_birth(p, r),
            "import-2023" if p["legacy"] else p["channel"], typed_optin(p, r)]


rows = []
for p in people:
    if p["cid"] in ERASED or p["signed"] > CRM_EXPORTED:
        continue
    rows.append(crm_row(p, rng))

# Near-duplicates: somebody signs up again, in another channel, a while later.
VARIANTS = []
pool = [p for p in people if not p["company"] and p["cid"] not in ERASED
        and p["signed"] < dt.date(2025, 9, 1) and p is not abuser]
dups = rng.sample(pool, 58)
next_n = len(people) + 1
for p in dups:
    q = dict(p)
    q["channel"] = rng.choice([c for c in ("site", "app", "store") if c != p["channel"]])
    q["legacy"] = False
    q["signed"] = p["signed"] + dt.timedelta(days=rng.randint(20, 300))
    if q["signed"] > CRM_EXPORTED:
        q["signed"] = CRM_EXPORTED - dt.timedelta(days=rng.randint(1, 30))
    how = rng.choice(["accents", "space", "case", "middle", "email", "typo"])
    n = p["name"]
    if how == "accents":
        n = strip_accents(n)
    elif how == "space":
        n = n.replace(" ", "  ", 1)
    elif how == "case":
        n = n.lower()
    elif how == "middle" and len(n.split()) > 2:
        parts = n.split()
        n = " ".join([parts[0], parts[1][0] + "."] + parts[2:])
    elif how == "typo":
        j = rng.randint(1, len(n) - 2)
        n = n[:j] + n[j + 1] + n[j] + n[j + 2:]
    q["name"] = n
    if how == "email":
        q["email"] = q["email"].split("@")[0] + "@" + rng.choice([d for d in DOMAINS if not q["email"].endswith(d)])
    q["cid"] = f"C{next_n:05d}"
    next_n += 1
    rows.append(crm_row(q, rng))
    VARIANTS.append((p["cid"], q["cid"], how))

# Exact duplicates: the export's pages overlapped.
exact = rng.sample(rows, 37)
for r_ in exact:
    rows.insert(rng.randint(0, len(rows)), list(r_))
rows.sort(key=lambda r_: r_[0])
write(os.path.join(RAW, "customers.csv"),
      ["customer_id", "name", "email", "cep", "city", "state", "signed_up", "birth_year",
       "signup_channel", "marketing_opt_in"], rows)
write(os.path.join(TRUTH, "duplicates.csv"), ["customer_id", "same_as", "how"],
      sorted([b, a, h] for a, b, h in VARIANTS))
write(os.path.join(TRUTH, "homonyms.csv"), ["customer_id", "other"], sorted(homonyms))
write(os.path.join(TRUTH, "erased.csv"), ["customer_id"], sorted([c] for c in ERASED))
write(os.path.join(TRUTH, "people.csv"),
      ["customer_id", "name", "city", "state", "signed_up", "birth_year", "company"],
      [[p["cid"], p["name"], p["city"], p["state"], p["signed"].isoformat(),
        p["birth"] or "", int(p["company"])] for p in people])

# --------------------------------------------------------------------------
# Orders and their lines

rng = random.Random(3303)
BLACK_FRIDAY = dt.date(2025, 11, 28)
CLOSED = {dt.date(2025, m, d) for m, d in [(1, 1), (4, 18), (4, 21), (5, 1), (9, 7), (10, 12),
                                           (11, 2), (11, 15), (11, 20), (12, 25)]}


def day_weight(d):
    w = 1.0 + 0.25 * math.sin((d.timetuple().tm_yday - 30) / 365 * 2 * math.pi)
    if d.weekday() in (4, 5):
        w *= 1.35
    if d.weekday() == 6:
        w *= 0.7
    if d == BLACK_FRIDAY:
        w *= 3.2
    if d.month == 12 and d.day <= 23:
        w *= 1.3
    return w


ALL_DAYS = [YEAR_FIRST + dt.timedelta(days=k) for k in range(days(YEAR_FIRST, YEAR_LAST) + 1)]
HOURS = [(h, w) for h, w in [(7, 2), (8, 4), (9, 6), (10, 8), (11, 8), (12, 7), (13, 6), (14, 6),
                             (15, 6), (16, 6), (17, 7), (18, 9), (19, 10), (20, 9), (21, 6), (22, 3)]]

orders, lines, survey = [], [], []
truth_orders = []
oid = 100000
active = [p for p in people if not p["company"] and p is not abuser]


def kg_line(r, prod):
    code, name, cat, unit, price = prod
    return code, unit, price


def draw_lines(r, d, big=False):
    out = []
    n = r.randint(8, 14) if big else max(1, min(9, int(r.gauss(4, 1.8))))
    chosen = set()
    for _ in range(n):
        prod = pick(r, POP)
        if prod[0] in chosen:
            continue
        chosen.add(prod[0])
        code, name, cat, unit, price = prod
        if code in REPRICED and d >= REPRICED_ON:
            price = REPRICED[code]
        if unit == "kg":
            qty = r.choice([0.5, 1, 1, 1, 1.5, 2]) * (r.choice([10, 20, 25]) if big else 1)
        else:
            qty = r.choice([1, 1, 1, 2, 2, 3]) * (r.choice([10, 20, 30, 40]) if big else 1)
        out.append((code, unit, qty, price, cat))
    return out


def place_order(p, when, channel, fulfil, big=False, status=None, r=rng):
    global oid
    oid += 1
    d = when.date()
    ls = draw_lines(r, d, big)
    sub = sum(round(q * pr) for _, _, q, pr, _ in ls)
    disc = 0
    if not big and r.random() < 0.12:
        disc = r.choice([500, 1000, 1500, 2000])
    fee = 0 if fulfil == "pickup" or sub >= 20000 else 990
    total = sub - disc + fee
    st = status or pick(r, [("delivered", 93), ("cancelled", 4), ("refunded", 3)])
    courier, minutes = "", ""
    if fulfil == "delivery":
        courier = pick(r, [("propria", 70), ("Rapidex", 30)])
        if courier == "propria" and st != "cancelled":
            m = int(round(math.exp(r.gauss(math.log(52), 0.38))))
            if when.hour in (18, 19, 20):
                m = int(m * 1.25)
            if p["city"] == "São Paulo":
                m = int(m * 1.1)
            minutes = "" if m >= 120 else str(m)  # the device stops timing at two hours
            truth_orders.append((oid, "minutes", m))
    return {"oid": oid, "p": p, "when": when, "channel": channel, "fulfil": fulfil, "lines": ls,
            "sub": sub, "disc": disc, "fee": fee, "total": total, "status": st,
            "courier": courier, "minutes": minutes}


dw = [(d, day_weight(d)) for d in ALL_DAYS]
for p in active:
    first = max(p["signed"], YEAR_FIRST)
    if first > YEAR_LAST:
        continue
    span = days(first, YEAR_LAST) + 1
    rate = rng.choice([0.5, 0.7, 1, 1, 1.5, 2, 3]) / 30  # orders a day
    n = sum(1 for _ in range(span) if rng.random() < rate)
    my_days = [x for x in dw if x[0] >= first]
    pref = "app" if p["channel"] == "app" else ("site" if p["channel"] == "site" else rng.choice(["site", "app"]))
    for _ in range(n):
        d = pick(rng, my_days)
        h = pick(rng, HOURS)
        when = dt.datetime(d.year, d.month, d.day, h, rng.randint(0, 59), rng.randint(0, 59))
        ch = pref if rng.random() < 0.85 else ("site" if pref == "app" else "app")
        fulfil = "pickup" if rng.random() < 0.2 else "delivery"
        orders.append(place_order(p, when, ch, fulfil))

# The corporate orders before Christmas: real, large, and correct.
for co in [p for p in people if p["company"]]:
    for _ in range(rng.choice([2, 2, 3])):
        d = dt.date(2025, 12, rng.randint(8, 19))
        when = dt.datetime(2025, 12, d.day, rng.randint(9, 16), rng.randint(0, 59), 0)
        o = place_order(co, when, "site", "delivery", big=True, status="delivered")
        orders.append(o)
        truth_orders.append((o["oid"], "corporate", o["total"]))
# Refund cycling, from one account, over three days in August.
for k in range(23):
    when = dt.datetime(2025, 8, 12 + k // 8, rng.randint(9, 22), rng.randint(0, 59), rng.randint(0, 59))
    o = place_order(abuser, when, "app", "delivery", status="refunded")
    orders.append(o)
    truth_orders.append((o["oid"], "refund-cycling", o["total"]))

orders.sort(key=lambda o: (o["when"], o["oid"]))
# Renumber in time order, so an order number says roughly when.
remap = {}
for n, o in enumerate(orders, 100001):
    remap[o["oid"]] = n
    o["oid"] = n
truth_orders = [(remap[a], b, c) for a, b, c in truth_orders]

# Typed by customer service with a zero too many.
typos = rng.sample([o for o in orders if o["status"] == "delivered" and not o["p"]["company"]], 7)
for o in typos:
    o["typed_total"] = o["total"] * 10
    truth_orders.append((o["oid"], "typo-x10", o["total"]))

OFFSET = dt.timedelta(hours=3)  # America/Sao_Paulo is UTC-3 all year since 2019
orows, lrows = [], []
for o in orders:
    p = o["p"]
    if o["channel"] == "site":
        ts = (o["when"] + OFFSET).strftime("%Y-%m-%dT%H:%M:%SZ")
        disc = money(o["disc"]) if o["disc"] else ""
    else:
        ts = o["when"].strftime("%Y-%m-%d %H:%M:%S")
        disc = money(o["disc"]) if o["disc"] else "0"
    total = o.get("typed_total", o["total"])
    orows.append([o["oid"], p["cid"], o["channel"], ts, o["fulfil"], money(total), disc,
                  money(o["fee"]), pick(rng, [("card", 55), ("pix", 40), ("boleto", 5)]),
                  o["status"], o["courier"], o["minutes"]])
    for ln, (code, unit, qty, price, cat) in enumerate(o["lines"], 1):
        if o["channel"] == "app":
            c = str(int(code))  # the app's export went through a spreadsheet
        else:
            c = code
        u, q = unit, qty
        if unit == "kg":
            if o["channel"] == "app" and rng.random() < 0.4:
                u, q = rng.choice(["g", "gr"]), int(qty * 1000)
            else:
                u = pick(rng, [("kg", 80), ("KG", 12), ("Kg", 8)])
        else:
            u = pick(rng, [("un", 85), ("UN", 10), ("unid", 5)])
        qs = f"{q:g}"
        if o["channel"] == "site" and "." in qs and rng.random() < 0.3:
            qs = qs.replace(".", ",")
        lrows.append([o["oid"], ln, c, qs, u, money(price)])

# The app retried some submissions and both copies reached the export.
for o in rng.sample([r_ for r_ in orows if r_[2] == "app"], 25):
    orows.insert(orows.index(o) + 1, list(o))

write(os.path.join(RAW, "orders.csv"),
      ["order_id", "customer_id", "channel", "ordered_at", "fulfilment", "total", "discount",
       "delivery_fee", "payment", "status", "courier", "delivery_minutes"], orows)
write(os.path.join(RAW, "order_items.csv"),
      ["order_id", "line_no", "product_code", "quantity", "unit", "unit_price"], lrows)
write(os.path.join(TRUTH, "orders.csv"), ["order_id", "what", "value"], sorted(truth_orders))

# The satisfaction survey, sent the day after every delivered online order.
# Whether somebody answers depends on how it went, which the file cannot show.
srows = []
for o in orders:
    if o["status"] != "delivered" or o["p"]["company"]:
        continue
    late = o["minutes"] == "" and o["courier"] == "propria"
    m = int(o["minutes"]) if o["minutes"] else (130 if late else 60)
    base = 9.2 - max(0, m - 45) / 18
    score = max(0, min(10, int(round(rng.gauss(base, 1.4)))))
    answers = rng.random() < (0.12 + 0.03 * score)
    sent = o["when"] + dt.timedelta(days=1)
    srows.append([o["oid"], sent.strftime("%Y-%m-%d"),
                  (sent + dt.timedelta(hours=rng.randint(1, 60))).strftime("%Y-%m-%d") if answers else "",
                  score if answers else ""])
    truth_orders.append((o["oid"], "nps", score))
write(os.path.join(RAW, "survey.csv"), ["order_id", "sent_on", "answered_on", "nps"], srows)
write(os.path.join(TRUTH, "nps.csv"), ["order_id", "nps"],
      sorted([a, c] for a, b, c in truth_orders if b == "nps"))

# --------------------------------------------------------------------------
# The stores' old till: Latin-1, semicolons, decimal commas, Portuguese headers.

rng = random.Random(4404)
STORES = [c[4] for c in CITIES]
loyal = [p for p in active]
srows = []
sale = 0
for d in ALL_DAYS:
    if d.weekday() == 6 or d in CLOSED:
        continue  # the shops close on Sundays and on national holidays
    for s, (city, st, w, _, store) in zip(STORES, CITIES):
        n = int(rng.gauss(w * 0.7 * day_weight(d), 2))
        for _ in range(max(0, n)):
            sale += 1
            h = rng.randint(8, 19)
            items = max(1, int(rng.gauss(5, 2)))
            cents = max(390, int(rng.gauss(items * 1450, 1500)))
            cents = cents - cents % 10
            cust = ""
            if rng.random() < 0.35:
                cust = rng.choice([p for p in loyal if p["city"] == city and p["signed"] <= d] or [loyal[0]])["cid"]
            pay = pick(rng, [("Cartão", 45), ("cartao", 5), ("Pix", 25), ("PIX", 10), ("pix", 5), ("Dinheiro", 10)])
            srows.append([f"V{sale:06d}", store, d.strftime("%d/%m/%Y"), f"{h:02d}:{rng.randint(0, 59):02d}",
                          cust, brl(cents), pay, items])
srows_store = srows
write(os.path.join(RAW, "store_sales.csv"),
      ["venda", "loja", "data", "hora", "cliente", "total", "pagamento", "itens"],
      srows, encoding="latin-1", delimiter=";")

# --------------------------------------------------------------------------
# Supplier invoices, in three currencies and three units of weight.

rng = random.Random(5505)
SUPPLIERS = [
    # supplier, currency, how it writes a date, how it writes weight
    ("Sítio Boa Terra", "BRL", "%d/%m/%Y", "kg"),
    ("Cooperativa Vale Verde", "BRL", "%d/%m/%Y", "kg"),
    ("Fazenda Santa Clara", "BRL", "%Y-%m-%d", "t"),
    ("Green Valley Seeds Inc.", "USD", "%m/%d/%Y", "lb"),
    ("Oliveira Hermanos SL", "EUR", "%d.%m.%Y", "kg"),
]
# The rates finance booked for each month: written for the course.
FX = {}
usd, eur = 5.41, 5.92
for m in range(1, 13):
    usd = round(usd + rng.uniform(-0.12, 0.10), 4)
    eur = round(eur + rng.uniform(-0.10, 0.12), 4)
    FX[m] = (usd, eur)
write(os.path.join(RAW, "fx_rates_2025.csv"), ["month", "usd_brl", "eur_brl"],
      [[f"2025-{m:02d}", f"{FX[m][0]:.4f}", f"{FX[m][1]:.4f}"] for m in range(1, 13)])
irows = []
for k in range(1, 61):
    sup, cur, fmt, wu = rng.choice(SUPPLIERS)
    d = YEAR_FIRST + dt.timedelta(days=rng.randint(0, 364))
    kg = rng.randint(80, 2400)
    if cur == "BRL":
        amount = round(kg * rng.uniform(3.5, 9.0), 2)
    elif cur == "USD":
        amount = round(kg * rng.uniform(1.2, 3.0), 2)
    else:
        amount = round(kg * rng.uniform(1.0, 2.6), 2)
    weight = {"kg": f"{kg}", "t": f"{kg / 1000:g}", "lb": f"{kg * 2.20462:.0f}"}[wu]
    irows.append([f"NF-{k:04d}", sup, d.strftime(fmt), cur, f"{amount:.2f}", weight, wu])
write(os.path.join(RAW, "invoices.csv"),
      ["invoice", "supplier", "issued", "currency", "amount", "weight", "weight_unit"], irows)

# --------------------------------------------------------------------------
# The sales targets, as the commercial team keeps them: one row per shop,
# one column per month, and a total at the end. Each starts near what the shop
# or the site sells in a month, a little below or above, and rises 4% a quarter.

rng = random.Random(6606)
MESES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
yearly = collections.Counter()
for r in srows_store:
    yearly[r[1]] += int(r[5][3:].replace(".", "").replace(",", ""))
for o in orders:
    if o["status"] == "delivered":
        yearly["Online"] += o["total"]
trows = []
for store in STORES + ["Online"]:
    base = yearly[store] / 100 / 12 * rng.uniform(0.86, 1.0)
    vals = [int(base * (1 + 0.04 * (m // 3)) // 1000 * 1000) for m in range(12)]
    trows.append([store] + vals + [sum(vals)])
write(os.path.join(RAW, "targets_2025.csv"), ["loja"] + [f"{m}/25" for m in MESES] + ["Total"], trows)

# --------------------------------------------------------------------------
# Reference data from outside the company. These are real.

write(os.path.join(REF, "ibge_states.csv"), ["code", "uf", "name", "region"], [
    [11, "RO", "Rondônia", "Norte"], [12, "AC", "Acre", "Norte"], [13, "AM", "Amazonas", "Norte"],
    [14, "RR", "Roraima", "Norte"], [15, "PA", "Pará", "Norte"], [16, "AP", "Amapá", "Norte"],
    [17, "TO", "Tocantins", "Norte"], [21, "MA", "Maranhão", "Nordeste"], [22, "PI", "Piauí", "Nordeste"],
    [23, "CE", "Ceará", "Nordeste"], [24, "RN", "Rio Grande do Norte", "Nordeste"],
    [25, "PB", "Paraíba", "Nordeste"], [26, "PE", "Pernambuco", "Nordeste"], [27, "AL", "Alagoas", "Nordeste"],
    [28, "SE", "Sergipe", "Nordeste"], [29, "BA", "Bahia", "Nordeste"], [31, "MG", "Minas Gerais", "Sudeste"],
    [32, "ES", "Espírito Santo", "Sudeste"], [33, "RJ", "Rio de Janeiro", "Sudeste"],
    [35, "SP", "São Paulo", "Sudeste"], [41, "PR", "Paraná", "Sul"], [42, "SC", "Santa Catarina", "Sul"],
    [43, "RS", "Rio Grande do Sul", "Sul"], [50, "MS", "Mato Grosso do Sul", "Centro-Oeste"],
    [51, "MT", "Mato Grosso", "Centro-Oeste"], [52, "GO", "Goiás", "Centro-Oeste"],
    [53, "DF", "Distrito Federal", "Centro-Oeste"]])
write(os.path.join(REF, "ibge_cities.csv"), ["code", "name", "uf"], [
    [3550308, "São Paulo", "SP"], [3509502, "Campinas", "SP"], [3304557, "Rio de Janeiro", "RJ"],
    [3106200, "Belo Horizonte", "MG"], [4106902, "Curitiba", "PR"]])
write(os.path.join(REF, "holidays_2025.csv"), ["date", "name", "kind"], [
    ["2025-01-01", "Confraternização Universal", "holiday"],
    ["2025-03-03", "Carnaval", "optional"], ["2025-03-04", "Carnaval", "optional"],
    ["2025-03-05", "Quarta-feira de Cinzas (até as 14h)", "optional"],
    ["2025-04-18", "Paixão de Cristo", "holiday"], ["2025-04-21", "Tiradentes", "holiday"],
    ["2025-05-01", "Dia Mundial do Trabalho", "holiday"], ["2025-06-19", "Corpus Christi", "optional"],
    ["2025-09-07", "Independência do Brasil", "holiday"],
    ["2025-10-12", "Nossa Senhora Aparecida", "holiday"],
    ["2025-11-02", "Finados", "holiday"], ["2025-11-15", "Proclamação da República", "holiday"],
    ["2025-11-20", "Dia Nacional de Zumbi e da Consciência Negra", "holiday"],
    ["2025-12-25", "Natal", "holiday"]])
