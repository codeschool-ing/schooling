#!/usr/bin/env python3
"""Lesson 13: what each import produces, from the files the lesson prints.

Power Query was not run (pqfiles.py says why): every count and total below is
the same step applied to the same text in Python, and the lesson says so."""
from collections import Counter

from pqfiles import Error, both, date, freight, number, split, web_file, web_orders, files

print("files printed in the lesson:", ", ".join(sorted(files())))

# Section 03: the July file, typed with English (United States).
jul = web_file("web-2026-07.csv")
print("July rows:", len(jul))
both("July bags", sum(r["Qty"] for r in jul))
both("July value, Qty x Unit price", sum(r["Qty"] * r["Unit price"] for r in jul))
# The same file read as Portuguese (Brazil): the full stop is a thousands separator.
jul_pt = web_file("web-2026-07.csv", "pt-BR")
print("July, first price read as pt-BR:", jul_pt[0]["Unit price"])
both("July value if read as pt-BR", sum(r["Qty"] * r["Unit price"] for r in jul_pt))

# The courier's file, typed with Portuguese (Brazil).
fr = freight()
print("Freight rows:", len(fr))
both("Freight total", sum(r["Freight"] for r in fr))
print("Freight, distinct orders:", len({r["Order"] for r in fr}))
# The same file read as English (United States).
fr_us = freight("en-US")
silent = sum(1 for a, b in zip(fr, fr_us) if not isinstance(b["Shipped"], Error) and a["Shipped"] != b["Shipped"])
same = sum(1 for a, b in zip(fr, fr_us) if a["Shipped"] == b["Shipped"])
errors = sum(1 for b in fr_us if isinstance(b["Shipped"], Error))
print(f"Shipped read as en-US: {silent} silently wrong, {errors} errors, {same} the same")
print("0,75 as en-US:", number("0,75", "en-US"), " 18,90 as en-US:", number("18,90", "en-US"))
print("45.00 as pt-BR:", number("45.00", "pt-BR"))
print("03/07/2026 as en-US:", date("03/07/2026", "en-US"), " 16/07/2026 as en-US:", date("16/07/2026", "en-US"))
both("Freight total if read as en-US", sum(r["Freight"] for r in fr_us if not isinstance(r["Freight"], Error)))

# Section 04: From Folder.
web = web_orders()
per = Counter(r["Source.Name"] for r in web)
print("WebOrders rows:", len(web), dict(per))
both("WebOrders bags", sum(r["Qty"] for r in web))
both("WebOrders value", sum(r["Qty"] * r["Unit price"] for r in web))
print("cancelled:", [r["Order"] for r in web if r["Status"] != "paid"])
print("lower-case SKU:", [(r["Order"], r["SKU"]) for r in web if r["SKU"] != r["SKU"].upper()])
# The courier file wrongly saved into the folder, split at commas.
bad = split("freight-2026-q3.csv", ";")
print("freight lines split at commas, first:", "W2001;03/07/2026;0,75;18,90".split(","))

# Section 05: the Sales table and the original workbook.
from engine import rows
s = rows("Sales")
print("Sales rows:", len(s) - 1, "columns in the original:", len(s[0]), "+ Revenue in the table")
print("Products rows:", len(rows("Products")) - 1)
