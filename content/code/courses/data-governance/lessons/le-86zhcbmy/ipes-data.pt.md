---
title: Os dados da Ipê, gerados
version: 1
---

A Farmácia Ipê não existe, e ninguém no banco dela existe. **Toda linha é gerada por um programa a
partir de sementes fixas**, então a sua cópia é, byte a byte, aquela em que estas aulas foram
gravadas, e todo número que uma aula cita volta quando você roda a mesma consulta.

## As tabelas

Salve isto como `schema.sql` em `~/gov`. Ele cria o papel que vai ser dono de toda tabela, os três
schemas e as sete tabelas, e não concede nada a ninguém — todo privilégio do curso é acrescentado por
uma aula:

```sql
-- The database of Farmácia Ipê as the lab builds it, before any lesson has
-- touched it: three schemas, the tables the website and the shops write, and
-- not one grant. Every privilege in the course is added by a lesson.
--
-- Run as the superuser, in the database `ipe`. The CSV files generate.py
-- writes are loaded straight after.

CREATE ROLE ipe_owner NOLOGIN;
COMMENT ON ROLE ipe_owner IS 'owns every table; nobody logs in as it';

CREATE SCHEMA sales   AUTHORIZATION ipe_owner;
CREATE SCHEMA health  AUTHORIZATION ipe_owner;
CREATE SCHEMA support AUTHORIZATION ipe_owner;

-- A fresh database lets every role create objects in `public` before
-- PostgreSQL 15, and the habit outlived the default. Nothing here uses it.
REVOKE ALL ON SCHEMA public FROM PUBLIC;

SET ROLE ipe_owner;

CREATE TABLE sales.customers (
  customer_id      integer PRIMARY KEY,
  full_name        text        NOT NULL,
  email            text        NOT NULL,
  cpf              text        NOT NULL,
  birth_date       date        NOT NULL,
  sex              char(1)     NOT NULL CHECK (sex IN ('F', 'M')),
  cep              text        NOT NULL,
  city             text        NOT NULL,
  state            char(2)     NOT NULL,
  created_at       timestamptz NOT NULL,
  marketing_opt_in boolean     NOT NULL,
  consent_at       timestamptz
);

CREATE TABLE sales.products (
  product_id         integer PRIMARY KEY,
  name               text    NOT NULL,
  category           text    NOT NULL,
  needs_prescription boolean NOT NULL,
  controlled         boolean NOT NULL,
  price_cents        integer NOT NULL CHECK (price_cents > 0)
);

CREATE TABLE sales.orders (
  order_id    integer PRIMARY KEY,
  customer_id integer REFERENCES sales.customers,
  ordered_at  timestamptz NOT NULL,
  status      text        NOT NULL,
  total_cents integer     NOT NULL
);
CREATE INDEX ON sales.orders (customer_id);
CREATE INDEX ON sales.orders (ordered_at);

CREATE TABLE sales.order_items (
  order_id         integer REFERENCES sales.orders,
  line_no          smallint,
  product_id       integer NOT NULL REFERENCES sales.products,
  quantity         integer NOT NULL CHECK (quantity > 0),
  unit_price_cents integer NOT NULL,
  PRIMARY KEY (order_id, line_no)
);

CREATE TABLE sales.payments (
  order_id     integer PRIMARY KEY REFERENCES sales.orders,
  method       text    NOT NULL CHECK (method IN ('card', 'pix', 'boleto')),
  card_token   text,
  card_last4   char(4),
  amount_cents integer NOT NULL
);

CREATE TABLE health.prescriptions (
  prescription_id integer PRIMARY KEY,
  customer_id     integer NOT NULL REFERENCES sales.customers,
  order_id        integer NOT NULL REFERENCES sales.orders,
  product_id      integer NOT NULL REFERENCES sales.products,
  prescriber      text    NOT NULL,
  issued_on       date    NOT NULL,
  scan_path       text    NOT NULL
);
CREATE INDEX ON health.prescriptions (customer_id);

CREATE TABLE support.tickets (
  ticket_id   integer PRIMARY KEY,
  customer_id integer NOT NULL REFERENCES sales.customers,
  opened_at   timestamptz NOT NULL,
  status      text        NOT NULL,
  body        text        NOT NULL
);
CREATE INDEX ON support.tickets (customer_id);

RESET ROLE;
```

## O gerador

Salve isto como `generate.py` em `~/gov`. Ele usa só a biblioteca padrão do Python. A docstring dele
diz o que foi feito para não poder ser real (todo CPF falha no dígito verificador, todo e-mail está
num domínio reservado para exemplos) e o que foi plantado para as aulas seguintes acharem:

```python
#!/usr/bin/env python3
"""The data of Farmácia Ipê, the online pharmacy the data-governance course
governs. Ipê does not exist, and neither does anybody in these files.

    python3 generate.py DIR      # writes one CSV per table into DIR

Everything is drawn from random.Random with fixed seeds, so two runs on two
machines write the same bytes, and every number a lesson quotes comes back.

WHAT IS MADE SO THAT IT CANNOT BE REAL

  - Every CPF has a WRONG second check digit, on purpose. A number with a
    valid check digit might be somebody's; one that fails the check cannot
    be. Lesson 6 measures it, and says why test data is built so.
  - Every e-mail address is under example.com, example.net or example.org,
    the domains reserved for examples.
  - Names are a first name and two surnames drawn from lists of common ones.
    The combination is chance and names nobody in particular.
  - No telephone number is generated: Brazil reserves no range for fiction.
  - Card numbers are never stored. A payment carries a token and the last
    four digits, the way lesson 5 says a payment should.

WHAT IS PLANTED, AND WHICH LESSON FINDS IT

  - a few customers under eighteen (lesson 6, art. 14 of the LGPD)
  - CPFs and e-mail addresses typed into support tickets (lesson 6)
  - duplicate customers differing only in the case of the e-mail, malformed
    addresses, orders with a date after the lab's today (lesson 9)
  - seven years of orders, so a five-year retention rule has rows to purge
    (lesson 10)
"""
import csv
import datetime as dt
import os
import random
import sys

TODAY = dt.date(2026, 7, 1)  # the lab's today; the lessons say so

FIRST = """Ana Beatriz Bruno Camila Carlos Daniela Davi Eduardo Elisa Fábio Fernanda
Gabriel Gustavo Helena Heitor Igor Isabela Joana João Júlia Larissa Leonardo
Letícia Lucas Luana Luiz Marcela Marcos Mariana Mateus Natália Nicolas Otávio
Paula Pedro Rafael Raquel Renata Rodrigo Sabrina Samuel Sofia Tatiana Thiago
Valentina Vitor Yasmin Arthur Bianca Caio Clara Diego Elaine Felipe Giovana
Henrique Ingrid Jorge Karina Lívia Manuela Miguel Noemi Patrícia Priscila
Ricardo Rosana Sérgio Simone Tânia Vanessa Wagner""".split()
LAST = """Silva Santos Oliveira Souza Rodrigues Ferreira Alves Pereira Lima Gomes
Costa Ribeiro Martins Carvalho Almeida Lopes Soares Fernandes Vieira Barbosa
Rocha Dias Nascimento Andrade Moreira Nunes Marques Machado Mendes Freitas
Cardoso Ramos Gonçalves Santana Teixeira Araújo Pinto Correia Moura Cavalcanti
Batista Campos Duarte Monteiro Rezende Siqueira Tavares Xavier Prado Farias""".split()
# (city, state, the first two digits of its CEPs, weight)
CITIES = [
    ("São Paulo", "SP", "01", 30), ("Campinas", "SP", "13", 8),
    ("Santos", "SP", "11", 4), ("Rio de Janeiro", "RJ", "20", 16),
    ("Niterói", "RJ", "24", 3), ("Belo Horizonte", "MG", "30", 9),
    ("Curitiba", "PR", "80", 7), ("Porto Alegre", "RS", "90", 6),
    ("Florianópolis", "SC", "88", 4), ("Salvador", "BA", "40", 5),
    ("Recife", "PE", "50", 4), ("Fortaleza", "CE", "60", 3),
    ("Brasília", "DF", "70", 5), ("Goiânia", "GO", "74", 2),
    ("Manaus", "AM", "69", 1), ("Belém", "PA", "66", 1),
    ("Vitória", "ES", "29", 1), ("Natal", "RN", "59", 1),
]
DOMAINS = ["example.com", "example.net", "example.org"]

# (name, category, needs a prescription, controlled substance, price in cents)
PRODUCTS = [
    ("Dipirona 500 mg, 10 comprimidos", "analgesic", False, False, 690),
    ("Paracetamol 750 mg, 20 comprimidos", "analgesic", False, False, 1290),
    ("Ibuprofeno 400 mg, 10 cápsulas", "analgesic", False, False, 1590),
    ("Protetor solar FPS 50, 200 ml", "personal care", False, False, 6990),
    ("Hidratante corporal, 400 ml", "personal care", False, False, 3290),
    ("Escova dental macia", "personal care", False, False, 990),
    ("Creme dental 90 g", "personal care", False, False, 590),
    ("Vitamina D 2000 UI, 60 cápsulas", "supplement", False, False, 4590),
    ("Vitamina C 1 g, 30 comprimidos", "supplement", False, False, 2890),
    ("Ômega 3, 60 cápsulas", "supplement", False, False, 5990),
    ("Soro fisiológico 500 ml", "first aid", False, False, 890),
    ("Curativo adesivo, 40 unidades", "first aid", False, False, 1190),
    ("Termômetro digital", "first aid", False, False, 2490),
    ("Teste de gravidez", "diagnostic", False, False, 1990),
    ("Fralda infantil M, 30 unidades", "baby", False, False, 4990),
    ("Amoxicilina 500 mg, 21 cápsulas", "antibiotic", True, False, 3490),
    ("Azitromicina 500 mg, 3 comprimidos", "antibiotic", True, False, 2990),
    ("Losartana 50 mg, 30 comprimidos", "cardiovascular", True, False, 1890),
    ("Atenolol 25 mg, 30 comprimidos", "cardiovascular", True, False, 1490),
    ("Metformina 850 mg, 30 comprimidos", "diabetes", True, False, 1390),
    ("Insulina NPH, frasco 10 ml", "diabetes", True, False, 5990),
    ("Levotiroxina 50 mcg, 30 comprimidos", "thyroid", True, False, 1690),
    ("Sertralina 50 mg, 30 comprimidos", "psychiatric", True, True, 4290),
    ("Fluoxetina 20 mg, 30 cápsulas", "psychiatric", True, True, 2790),
    ("Clonazepam 2 mg, 30 comprimidos", "psychiatric", True, True, 1990),
    ("Zolpidem 10 mg, 20 comprimidos", "psychiatric", True, True, 3890),
    ("Anticoncepcional oral, 21 comprimidos", "contraceptive", True, False, 2490),
    ("Sumatriptana 50 mg, 2 comprimidos", "neurology", True, False, 3190),
]

TICKET_TEXT = [
    "My order has not arrived yet.",
    "I was charged twice for the same order.",
    "The box arrived damaged.",
    "How do I change my delivery address?",
    "I want to cancel my order.",
    "The prescription upload keeps failing.",
    "Please stop sending me promotions.",
    "I want a copy of all the data you hold about me.",
    "Please delete my account.",
    "The product I received is not the one I ordered.",
]


def cpf(rnd):
    """Nine digits, the right first check digit and a WRONG second one."""
    d = [rnd.randrange(10) for _ in range(9)]
    if len(set(d)) == 1:
        d[0] = (d[0] + 1) % 10
    s = sum(v * w for v, w in zip(d, range(10, 1, -1)))
    d1 = (s * 10 % 11) % 10
    d.append(d1)
    s = sum(v * w for v, w in zip(d, range(11, 1, -1)))
    d2 = (s * 10 % 11) % 10
    d.append((d2 + 1 + rnd.randrange(9)) % 10)  # never the right one
    t = "".join(map(str, d))
    return f"{t[:3]}.{t[3:6]}.{t[6:9]}-{t[9:]}"


def strip(s):
    table = str.maketrans("áâãàéêíóôõúçÁÂÃÉÍÓÔÚÇ", "aaaaeeiooouc" + "AAAEIOOUC")
    return s.translate(table).lower()


def ts(d, rnd):
    t = dt.datetime.combine(d, dt.time(rnd.randrange(7, 23), rnd.randrange(60),
                                       rnd.randrange(60)))
    return t.strftime("%Y-%m-%d %H:%M:%S-03")


def main(out):
    os.makedirs(out, exist_ok=True)
    rnd = random.Random(20260701)

    def write(name, header, rows):
        with open(os.path.join(out, name + ".csv"), "w", newline="") as f:
            w = csv.writer(f, lineterminator="\n")
            w.writerow(header)
            w.writerows(rows)

    # products
    prows = []
    for i, (n, c, rx, ctl, p) in enumerate(PRODUCTS, start=1):
        prows.append([i, n, c, "t" if rx else "f", "t" if ctl else "f", p])
    write("products", ["product_id", "name", "category", "needs_prescription",
                       "controlled", "price_cents"], prows)

    # customers
    weights = [c[3] for c in CITIES]
    customers = []
    seen_email = set()
    start = dt.date(2019, 1, 1)
    span = (dt.date(2026, 6, 30) - start).days
    for cid in range(1, 6001):
        first = rnd.choice(FIRST)
        last1, last2 = rnd.sample(LAST, 2)
        name = f"{first} {last1} {last2}"
        city, state, cep2, _ = rnd.choices(CITIES, weights)[0]
        cep = f"{cep2}{rnd.randrange(1000):03d}-{rnd.randrange(1000):03d}"
        sex = "F" if first.endswith("a") or first in (
            "Elisa", "Helena", "Isabela", "Joana", "Clara", "Elaine", "Ingrid",
            "Noemi", "Simone", "Raquel", "Sofia") else "M"
        created = start + dt.timedelta(days=int(span * rnd.random() ** 0.8))
        age = rnd.choices([rnd.randrange(16, 18), rnd.randrange(18, 30),
                           rnd.randrange(30, 50), rnd.randrange(50, 70),
                           rnd.randrange(70, 92)], [0.0015, 0.25, 0.38, 0.25, 0.12])[0]
        birth = dt.date(created.year - age, 1, 1) + dt.timedelta(days=rnd.randrange(365))
        if age < 18:  # a minor at sign-up stays one in the data the lab sees
            birth = dt.date(TODAY.year - age, 1, 1) + dt.timedelta(days=rnd.randrange(180))
            created = dt.date(2026, 1, 1) + dt.timedelta(days=rnd.randrange(180))
        base = f"{strip(first)}.{strip(last1)}"
        email = f"{base}@{rnd.choice(DOMAINS)}"
        n = 1
        while email.lower() in seen_email:
            n += 1
            email = f"{base}{n}@{rnd.choice(DOMAINS)}"
        seen_email.add(email.lower())
        roll = rnd.random()
        if roll < 0.004:
            email = email.replace("@", "")            # malformed: no @
        elif roll < 0.008:
            email = email.replace(".com", ".con")     # malformed: a typo
        opt_in = rnd.random() < 0.42
        consent_at = ts(created, rnd) if opt_in else ""
        customers.append([cid, name, email, cpf(rnd), birth.isoformat(), sex, cep,
                          city, state, ts(created, rnd), "t" if opt_in else "f",
                          consent_at])
    # twelve duplicates: the same person signing up again, the address in capitals
    for k in range(12):
        src = customers[rnd.randrange(len(customers))]
        cid = len(customers) + 1
        dup = list(src)
        dup[0] = cid
        dup[2] = src[2].upper()
        created = dt.date.fromisoformat(src[9][:10]) + dt.timedelta(days=rnd.randrange(30, 400))
        if created > dt.date(2026, 6, 30):
            created = dt.date(2026, 6, 30)
        dup[9] = ts(created, rnd)
        customers.append(dup)
    write("customers", ["customer_id", "full_name", "email", "cpf", "birth_date", "sex",
                        "cep", "city", "state", "created_at", "marketing_opt_in",
                        "consent_at"], customers)

    # orders, items, payments, prescriptions
    orders, items, pays, rxs = [], [], [], []
    oid = 100000
    rxid = 0
    doctors = [f"CRM-{st} {rnd.randrange(10000, 199999)}" for st in
               ("SP", "SP", "SP", "RJ", "RJ", "MG", "PR", "RS", "BA", "DF", "PE", "SC")]
    for c in customers:
        cid = c[0]
        created = dt.date.fromisoformat(c[9][:10])
        n = min(int(rnd.expovariate(1 / 6.5)), 60)
        for _ in range(n):
            days = (dt.date(2026, 6, 30) - created).days
            if days <= 0:
                break
            d = created + dt.timedelta(days=rnd.randrange(days + 1))
            oid += 1
            status = rnd.choices(["delivered", "cancelled", "returned"], [0.93, 0.05, 0.02])[0]
            lines = rnd.choices([1, 2, 3, 4], [0.5, 0.3, 0.15, 0.05])[0]
            picks = rnd.sample(range(len(PRODUCTS)), lines)
            total = 0
            for ln, p in enumerate(picks, start=1):
                q = rnd.choices([1, 2, 3], [0.8, 0.15, 0.05])[0]
                price = PRODUCTS[p][4]
                items.append([oid, ln, p + 1, q, price])
                total += q * price
                if PRODUCTS[p][2]:
                    rxid += 1
                    rxs.append([rxid, cid, oid, p + 1, rnd.choice(doctors),
                                (d - dt.timedelta(days=rnd.randrange(0, 20))).isoformat(),
                                f"rx/{d.year}/{rxid:06d}.pdf"])
            orders.append([oid, cid, ts(d, rnd), status, total])
            method = rnd.choices(["card", "pix", "boleto"], [0.55, 0.38, 0.07])[0]
            if method == "card":
                tok = "tok_" + "".join(rnd.choice("0123456789abcdef") for _ in range(16))
                last4 = f"{rnd.randrange(10000):04d}"
            else:
                tok, last4 = "", ""
            pays.append([oid, method, tok, last4, total])
    # three orders the source system dated in the future
    for k in range(3):
        o = orders[rnd.randrange(len(orders))]
        o[2] = "2027-0%d-1%d 10:00:00-03" % (k + 2, k)
    # orders with no customer: guest checkouts the old site allowed until 2020
    for o in orders:
        if o[2] < "2020-01-01" and rnd.random() < 0.06:
            o[1] = ""
    write("orders", ["order_id", "customer_id", "ordered_at", "status", "total_cents"], orders)
    write("order_items", ["order_id", "line_no", "product_id", "quantity", "unit_price_cents"],
          items)
    write("payments", ["order_id", "method", "card_token", "card_last4", "amount_cents"], pays)
    write("prescriptions", ["prescription_id", "customer_id", "order_id", "product_id",
                            "prescriber", "issued_on", "scan_path"], rxs)

    # support tickets: free text, and some customers type what they should not
    tickets = []
    for tid in range(1, 1501):
        c = customers[rnd.randrange(len(customers))]
        created = dt.date.fromisoformat(c[9][:10])
        days = max((dt.date(2026, 6, 30) - created).days, 1)
        d = created + dt.timedelta(days=rnd.randrange(days))
        body = rnd.choice(TICKET_TEXT)
        roll = rnd.random()
        if roll < 0.05:
            body += f" My CPF is {c[3]}."
        elif roll < 0.09:
            body += f" Write to me at {c[2].lower()} please."
        elif roll < 0.11:
            body += " I take sertraline and need it before Friday."
        tickets.append([tid, c[0], ts(d, rnd), rnd.choice(["open", "closed", "closed", "closed"]),
                        body])
    write("tickets", ["ticket_id", "customer_id", "opened_at", "status", "body"], tickets)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "data")
```

## Gerando e carregando

Os arquivos CSV vão para um diretório próprio, legível pelo usuário `postgres`, que os carrega. O
banco é criado, o schema é lido da entrada padrão, porque o `postgres` não consegue ler a pasta
pessoal da Ana e não precisa, e cada arquivo é copiado para a sua tabela:

```sh
sudo mkdir -p /var/lib/ipe-data
sudo python3 generate.py /var/lib/ipe-data
sudo chmod -R a+rX /var/lib/ipe-data
sudo -u postgres psql -d postgres -c "CREATE DATABASE ipe"
sudo -u postgres psql -d ipe -v ON_ERROR_STOP=1 < schema.sql
for t in sales.customers sales.products sales.orders sales.order_items \
         sales.payments health.prescriptions support.tickets; do
  sudo -u postgres psql -d ipe -c "\copy $t FROM '/var/lib/ipe-data/${t#*.}.csv' WITH (FORMAT csv, HEADER true)"
done
sudo -u postgres psql -d ipe -c "VACUUM ANALYZE"
```

Os arquivos, e a prova de que o gerador é determinístico — uma segunda execução noutro diretório
escreve os mesmos bytes:

```
ana@lab:~/gov$ ls /var/lib/ipe-data
customers.csv
order_items.csv
orders.csv
payments.csv
prescriptions.csv
products.csv
tickets.csv
ana@lab:~/gov$ wc -l /var/lib/ipe-data/*.csv
   6013 /var/lib/ipe-data/customers.csv
  63473 /var/lib/ipe-data/order_items.csv
  36425 /var/lib/ipe-data/orders.csv
  36425 /var/lib/ipe-data/payments.csv
  29353 /var/lib/ipe-data/prescriptions.csv
     29 /var/lib/ipe-data/products.csv
   1501 /var/lib/ipe-data/tickets.csv
 173219 total
ana@lab:~/gov$ python3 generate.py /tmp/again && sha256sum /tmp/again/customers.csv /var/lib/ipe-data/customers.csv
310990355c9eb2bea6d2b286b2b089148e7273fd09c45e52f4db1907873898f2  /tmp/again/customers.csv
310990355c9eb2bea6d2b286b2b089148e7273fd09c45e52f4db1907873898f2  /var/lib/ipe-data/customers.csv
```

E o que o banco guarda:

```
ana@lab:~/gov$ sudo -u postgres psql -c "SELECT (SELECT count(*) FROM sales.customers) AS customers, (SELECT count(*) FROM sales.products) AS products, (SELECT count(*) FROM sales.orders) AS orders, (SELECT count(*) FROM sales.order_items) AS items, (SELECT count(*) FROM health.prescriptions) AS prescriptions, (SELECT count(*) FROM support.tickets) AS tickets"
 customers | products | orders | items | prescriptions | tickets 
-----------+----------+--------+-------+---------------+---------
      6012 |       28 |  36424 | 63472 |         29352 |    1500
(1 row)
```

Cada arquivo tem uma linha a mais do que a tabela tem linhas: o cabeçalho. A aula 6 volta ao
`/var/lib/ipe-data/customers.csv` depois que a aula 5 tirou os CPFs do banco.
