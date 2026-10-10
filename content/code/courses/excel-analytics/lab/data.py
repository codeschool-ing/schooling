#!/usr/bin/env python3
"""The data every number in excel-analytics is computed from, made once.

Café Serra does not exist: a small coffee roaster in Poços de Caldas, Minas
Gerais, that sells bags of coffee to cafés, shops and offices (Wholesale),
through its own web shop (Online) and over the counter of the roastery
(Shop). This script drew its sales, January 2025 to June 2026, from a seeded
generator, and printed the three tables that lesson 1 section `your-data`
gives the student to paste.

IT RAN ONCE. The tables in that section are now the source: `engine.py` reads
them back out of the lesson, so the data a capture computes from is the data
the student pasted, byte for byte. Running this again prints the same tables
(random() with a fixed seed), and `python3 data.py --check` says whether the
lesson still carries them unchanged.
"""
import random
import sys

PRODUCTS = [
    # code, name, origin, roast, grams, list price, unit cost
    # The list price is today's, which took effect on 1 January 2026.
    ("SUL250", "Sul de Minas 250 g", "Sul de Minas", "Medium", 250, 41, 21),
    ("SUL1K", "Sul de Minas 1 kg", "Sul de Minas", "Medium", 1000, 132, 72),
    ("CER250", "Cerrado 250 g", "Cerrado", "Dark", 250, 37, 18),
    ("CER1K", "Cerrado 1 kg", "Cerrado", "Dark", 1000, 118, 61),
    ("MOG250", "Mogiana Reserve 250 g", "Mogiana", "Light", 250, 55, 30),
    ("DEC250", "Decaf 250 g", "Sul de Minas", "Medium", 250, 45, 25),
]

CUSTOMERS = [
    # id, name, type, city, state, since
    ("C00", "Walk-in and web", "Individual", "", "", "2024-01-02"),
    ("C01", "Café Aroma", "Café", "Belo Horizonte", "MG", "2024-03-11"),
    ("C02", "Padaria Central", "Retail", "Juiz de Fora", "MG", "2024-05-20"),
    ("C03", "Empório Serra", "Retail", "Poços de Caldas", "MG", "2024-02-06"),
    ("C04", "Café do Largo", "Café", "São Paulo", "SP", "2024-08-14"),
    ("C05", "Mercado Bom Preço", "Retail", "Campinas", "SP", "2025-01-09"),
    ("C06", "Bistrô Lume", "Café", "Rio de Janeiro", "RJ", "2025-04-02"),
    ("C07", "Escritório Faro", "Office", "São Paulo", "SP", "2025-02-17"),
    ("C08", "Café Grão Fino", "Café", "Curitiba", "PR", "2025-07-21"),
    ("C09", "Loja Natural", "Retail", "Belo Horizonte", "MG", "2025-10-06"),
    ("C10", "Coworking Ponte", "Office", "Rio de Janeiro", "RJ", "2026-01-12"),
]

# What a bag cost at list during 2025, before the rise.
PRICE = {p[0]: p[5] - 3 for p in PRODUCTS}


def sales():
    rnd = random.Random(20250101)
    rows = []
    n = 1001
    for y, m in [(2025, m) for m in range(1, 13)] + [(2026, m) for m in range(1, 7)]:
        days = sorted(rnd.sample(range(2, 28), 6))
        for d in days:
            date = f"{y}-{m:02d}-{d:02d}"
            r = rnd.random()
            if r < 0.40:
                ch = "Wholesale"
                active = [c for c in CUSTOMERS[1:] if c[5] <= date]
                cust = active[int(rnd.random() * len(active))][0]
                prod = ["SUL1K", "CER1K", "SUL1K", "CER1K", "MOG250", "DEC250"][int(rnd.random() * 6)]
                bags = 4 + int(rnd.random() * (14 if y == 2025 else 18))
                price = round(PRICE[prod] * 0.9)
            elif r < 0.75:
                ch = "Online"
                cust = "C00"
                prod = PRODUCTS[int(rnd.random() * 6)][0]
                bags = 1 + int(rnd.random() * 5)
                price = PRICE[prod]
            else:
                ch = "Shop"
                cust = "C00"
                prod = ["SUL250", "CER250", "MOG250", "DEC250"][int(rnd.random() * 4)]
                bags = 1 + int(rnd.random() * 3)
                price = PRICE[prod]
            # Prices rose on 1 January 2026, by three reais a bag at list.
            if y == 2026:
                price += 3 if ch != "Wholesale" else 2
            rows.append((f"S{n}", date, cust, prod, bags, price, ch))
            n += 1
    return rows


def tsv(header, rows):
    return "\n".join(["\t".join(header)] + ["\t".join(str(v) for v in r) for r in rows])


def tables():
    return {
        "Sales": tsv(["Sale", "Date", "Customer", "Product", "Bags", "Price", "Channel"], sales()),
        "Products": tsv(["Code", "Product", "Origin", "Roast", "Grams", "List price", "Unit cost"], PRODUCTS),
        "Customers": tsv(["Customer", "Name", "Type", "City", "State", "Since"], CUSTOMERS),
    }


if __name__ == "__main__":
    t = tables()
    if sys.argv[1:] == ["--check"]:
        sys.path.insert(0, __import__("os").path.dirname(__file__))
        import engine
        got = engine.data_blocks()
        ok = all(got[k] == v for k, v in t.items())
        print("lesson 1 carries the generated tables unchanged" if ok else "LESSON 1 DIFFERS FROM THE GENERATOR")
        sys.exit(0 if ok else 1)
    for name, text in t.items():
        print(f"##### {name}")
        print(text)
