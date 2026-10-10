#!/usr/bin/env python3
"""Lesson 15: the data model, its relationships and the Calendar table.

NOTHING HERE IS POWER PIVOT. Power Pivot has no engine outside Excel, so what
a pivot table built on the model shows is computed in plain Python from the
tables lesson 1 gives the student, following the relationships the lesson
draws: Sales[Product] -> Products[Code], Sales[Customer] ->
Customers[Customer], Sales[Date] -> Calendar[Date], each filtering from the
one side to the many side. The prose says so where it quotes a result.

What a spreadsheet CAN check is checked in Calc: the length of the calendar
and the grand total of the Revenue column of lesson 2.
"""
import datetime
from collections import Counter, defaultdict

from engine import Book, quoted, rows

import re


def calc(formula):
    """Excel's `Sheet!A1:B2` as Calc's `$Sheet.A1:B2`; the rest is unchanged."""
    return re.sub(r"\b([A-Za-z]+)!([A-Z]+[0-9]+(?::[A-Z]+[0-9]+)?)", r"$\1.\2", formula)


L = "le-etrcy5ny"


def table(name):
    r = rows(name)
    return [dict(zip(r[0], x)) for x in r[1:]]


sales, products, customers = table("Sales"), table("Products"), table("Customers")
for s in sales:
    s["Revenue"] = s["Bags"] * s["Price"]  # lesson 2's column H, =E2*F2

start, end = datetime.date(2025, 1, 1), datetime.date(2026, 12, 31)
calendar = []
d = start
while d <= end:
    calendar.append({"Date": d, "Year": d.year, "Month": d.month,
                     "Month name": d.strftime("%b"), "Quarter": f"Q{(d.month + 2) // 3}"})
    d += datetime.timedelta(days=1)

P = {p["Code"]: p for p in products}
C = {c["Customer"]: c for c in customers}
K = {c["Date"]: c for c in calendar}

print("== rows in each model table")
print(f"Sales {len(sales)}, Products {len(products)}, Customers {len(customers)}, Calendar {len(calendar)}")
print("calendar per year:", dict(Counter(c["Year"] for c in calendar)))

print("== the one side of each relationship is unique")
for name, col, t in (("Products", "Code", products), ("Customers", "Customer", customers),
                     ("Calendar", "Date", calendar)):
    vals = [x[col] for x in t]
    print(f"{name}[{col}]: {len(vals)} values, {len(set(vals))} distinct")

print("== every key on the many side finds its row")
print("Sales[Product] not in Products:", [s["Sale"] for s in sales if s["Product"] not in P])
print("Sales[Customer] not in Customers:", [s["Sale"] for s in sales if s["Customer"] not in C])
print("Sales[Date] not in Calendar:", [s["Sale"] for s in sales if s["Date"] not in K])
print("distinct products sold:", len({s["Product"] for s in sales}),
      "distinct customers buying:", len({s["Customer"] for s in sales}),
      "distinct sale dates:", len({s["Date"] for s in sales}))
print("first and last sale:", min(s["Date"] for s in sales), max(s["Date"] for s in sales))
print("Products[Code] values per Sales rows:", dict(Counter(s["Product"] for s in sales)))

total = sum(s["Revenue"] for s in sales)
print("== grand total of Revenue:", total)


def pivot(row_of, col_of=None, value=lambda s: s["Revenue"]):
    g = defaultdict(int)
    for s in sales:
        g[(row_of(s), col_of(s) if col_of else None)] += value(s)
    return dict(sorted(g.items(), key=lambda kv: (str(kv[0][0]), str(kv[0][1]))))


print("== Revenue by Products[Origin] x Calendar[Year]")
pv = pivot(lambda s: P[s["Product"]]["Origin"], lambda s: K[s["Date"]]["Year"])
for k, v in pv.items():
    print(k, v)
origin_tot = defaultdict(int)
year_tot = defaultdict(int)
for (o, y), v in pv.items():
    origin_tot[o] += v
    year_tot[y] += v
print("origin totals:", dict(origin_tot), "year totals:", dict(year_tot))

print("== Revenue by Products[Roast]")
print(pivot(lambda s: P[s["Product"]]["Roast"]))
print("== Bags by Products[Roast]")
print(pivot(lambda s: P[s["Product"]]["Roast"], value=lambda s: s["Bags"]))

print("== Revenue by Customers[Type]")
print(pivot(lambda s: C[s["Customer"]]["Type"]))
print("== Revenue by Customers[State] (C00 has none: the pivot shows (blank))")
print(pivot(lambda s: C[s["Customer"]]["State"] or "(blank)"))
print("C00 sales:", sum(1 for s in sales if s["Customer"] == "C00"),
      "revenue:", sum(s["Revenue"] for s in sales if s["Customer"] == "C00"))

print("== no relationship: every Origin row shows the grand total")
for o in sorted({p["Origin"] for p in products}):
    print(o, total)

print("== Channel rows with Count of Products[Code]: the filter does not climb to the one side")
for ch in sorted({s["Channel"] for s in sales}):
    print(ch, "count of Code =", len(products), "| sales:", sum(1 for s in sales if s["Channel"] == ch))

print("== Calendar[Month name] sorted as text, then by Month")
names = sorted({c["Month name"] for c in calendar})
print("as text:", names)
print("by Month:", [datetime.date(2025, m, 1).strftime("%b") for m in range(1, 13)])
print("Revenue by Month name, 2025:")
for m in range(1, 13):
    print(m, datetime.date(2025, m, 1).strftime("%b"),
          sum(s["Revenue"] for s in sales if s["Date"].year == 2025 and s["Date"].month == m))
print("Revenue by Quarter x Year:")
print(pivot(lambda s: K[s["Date"]]["Quarter"], lambda s: s["Date"].year))
print("months of 2026 with no sale:", [m for m in range(1, 13)
                                       if not any(s["Date"].year == 2026 and s["Date"].month == m for s in sales)])

ex = K[datetime.date(2025, 8, 15)]
print("== the calendar row for 15 August 2025:", ex)
print("serial of 2025-01-01:", (start - datetime.date(1899, 12, 30)).days)
PT = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
print("Portuguese short names sorted as text:", sorted(PT))
print("days of 2025-2026 with no sale:", len(calendar) - len({s["Date"] for s in sales}))
print("== the lookup column the model replaces: Origin looked up on all rows")
print("Sales rows that would carry a copy of Origin:", len(sales))

b = Book()
try:
    print("== Calc")
    print("=DATE(2026,12,31)-DATE(2025,1,1)+1:", b.ev(quoted(L, "=DATE(2026,12,31)-DATE(2025,1,1)+1")))
    b.sheet("Sales").getCellRangeByName("H1").setString("Revenue")
    b.set("Sales", "H2", "=E2*F2")
    b.fill("Sales", "H2", "H109")
    print("=SUM(Sales!H2:H109):", b.ev(calc(quoted(L, "=SUM(Sales!H2:H109)"))))
    print("=YEAR(DATE(2025,1,1)) check:", b.ev("=YEAR(DATE(2025,1,1))"))
finally:
    b.close()
