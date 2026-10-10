#!/usr/bin/env python3
"""Lesson 8: what a typo does to a total, the rules of the `New sales` sheet
tried on the values the lesson names, the names the drop-downs read, and the
count Circle Invalid Data shows.

The workbook is the one lesson 7 leaves: `Revenue` in Sales!H (lesson 2) and
the three ranges as tables named `Sales`, `Products` and `Customers`. Calc
calls a table a database range, and reads `Sales[Revenue]` against one the way
Excel reads it against a table.

A validation rule cannot be asked through Calc whether it would refuse a
value, so each rule's formula is put in a cell of the row it is written for,
beside the value the lesson tries, and its answer is the rule's verdict:
TRUE accepts, FALSE refuses, which is how Excel reads a custom rule.
"""
import re

import formulas
formulas.ExcelModel  # loaded before uno: its import hook breaks one of the imports behind this
import uno  # noqa: F401  (loads the bridge before com.sun.star imports)
from com.sun.star.table import CellAddress

from engine import Book, quoted, table_cells, xl

L = "le-2h4h3bzg"


def calc(formula):
    """Excel's `Sheet!A1` is Calc's `$Sheet.A1`; the rest is engine.api()."""
    out = []
    for part in re.split(r'("[^"]*")', formula):
        if not part.startswith('"'):
            part = re.sub(r"('[^']+'|[A-Za-z_][A-Za-z0-9_]*)!", lambda m: "$" + m.group(1) + ".", part)
        out.append(part)
    return "".join(out)


def lesson7_book():
    b = Book()
    sh = b.sheet("Sales")
    sh.getCellRangeByName("H1").setString("Revenue")
    b.set("Sales", "H2", "=E2*F2")
    b.fill("Sales", "H2", "H109")
    for name, rng in (("Sales", "A1:H109"), ("Products", "A1:G7"), ("Customers", "A1:F12")):
        b.doc.DatabaseRanges.addNewByName(name, b.sheet(name).getCellRangeByName(rng).getRangeAddress())
        b.doc.DatabaseRanges.getByName(name).ContainsHeader = True
    return b


b = lesson7_book()
try:
    q = lambda f: calc(quoted(L, f))  # noqa: E731
    print("== why-validate")
    online = '=SUMIFS(Sales[Revenue], Sales[Channel], "Online")'
    three = ('=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")+SUMIFS(Sales[Revenue], Sales[Channel], "Online")'
             '+SUMIFS(Sales[Revenue], Sales[Channel], "Shop")')
    total = "=SUM(Sales[Revenue])"
    for f in (online, three, total):
        print(f"{f}: {b.ev(q(f), 'Sales', 'K1')}")
    print("G4 is", b.value("Sales", "A4"), b.value("Sales", "G4"), "revenue", b.value("Sales", "H4"))
    b.sheet("Sales").getCellRangeByName("G4").setString("Online ")
    print("with 'Online ' (trailing space) in G4:")
    for f in (online, three, total):
        print(f"  {f}: {b.ev(q(f), 'Sales', 'K1')}")
    b.sheet("Sales").getCellRangeByName("G4").setString("online")
    print(f"with 'online' in G4, Online total: {b.ev(q(online), 'Sales', 'K1')}")
    b.sheet("Sales").getCellRangeByName("G4").setString("Online")

    print("== rules: the Sale rule on New sales, row by row")
    b.doc.Sheets.insertNewByName("New sales", b.doc.Sheets.getCount())
    b.put("New sales", [["Sale", "Date", "Customer", "Product", "Bags", "Price", "Channel"]])
    rule = "=AND(LEN(A2)=5, COUNTIF(Sales!A:A, A2)=0, COUNTIF(A:A, A2)=1)"
    quoted(L, rule)
    ns = b.sheet("New sales")
    for code in ("S1050", "S110", "S1109"):
        ns.getCellRangeByName("A2").setString(code)
        print(f"A2 = {code}: {b.ev(calc(rule), 'New sales', 'J2')}")
    ns.getCellRangeByName("A3").setString("S1109")
    row3 = rule.replace("A2", "A3")
    print(f"A2 = S1109 and A3 = S1109, the rule on row 3 {row3}: {b.ev(calc(row3), 'New sales', 'J3')}")
    print(f"  and on row 2 again: {b.ev(calc(rule), 'New sales', 'J2')}")
    for f in ("=DATE(2025,1,1)", "=TODAY()"):
        quoted(L, f)
    print("=DATE(2025,1,1) as a date serial:", b.ev("=DATE(2025,1,1)"))

    print("== drop-downs: names on table columns")
    names = b.doc.NamedRanges
    names.addNewByName("ProductCodes", "Products[Code]", CellAddress(0, 0, 0), 0)
    names.addNewByName("CustomerCodes", "Customers[Customer]", CellAddress(0, 0, 0), 0)
    for f in ("=ROWS(ProductCodes)", "=ROWS(CustomerCodes)"):
        print(f"{f}: {b.ev(q(f))}")
    print("=ROWS(Products!$A$2:$A$7):", b.ev(calc("=ROWS(Products!$A$2:$A$7)")))

    print("== messages: the Price rule (XLOOKUP, by the Excel-compatible calculator)")
    price = "=F2>=0.8*XLOOKUP(D2, Products!A:A, Products!F:F)"
    quoted(L, price)
    cells = table_cells("Products")
    print("bound for CER1K, =0.8*118:", b.ev("=0.8*118"))
    for p in (106, 18):
        c = dict(cells)
        c[("New sales", "D2")] = "CER1K"
        c[("New sales", "F2")] = p
        f = price.replace("F2", "'New sales'!F2").replace("D2", "'New sales'!D2")
        print(f"CER1K at {p}: {xl(c, f)}")
    c = dict(cells)
    c[("New sales", "F2")] = 106
    f = price.replace("F2", "'New sales'!F2").replace("D2", "'New sales'!D2")
    print(f"empty product, price 106: {xl(c, f)}")

    print("== what-validation-misses")
    f = '=COUNTIF(Sales[Bags], ">15")'
    print(f"{f}: {b.ev(q(f))}")
    for n in (16, 17, 18, 19, 20):
        print(f"  sales of exactly {n} bags: {b.ev(calc(f'=COUNTIF(Sales[Bags], {n})'))}")
finally:
    b.close()
