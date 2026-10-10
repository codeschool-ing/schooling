#!/usr/bin/env python3
"""Lesson 18: the size of a sheet, what past the edge costs, and the same
question asked of a database.

The grid's size is asked of the spreadsheet with the formulas the lesson
prints. Calc 24.2 has Excel's grid, 1,048,576 rows by 16,384 columns, which is
why it can answer; the .xls limits the lesson quotes are Excel's documented
ones and are not computed. The arithmetic about filling a sheet is plain
Python on those numbers. The SQL query the lesson prints is run in SQLite over
the pasted sales, and checked against the SUMIFS the lesson prints.
"""
import re
import sqlite3

from engine import Book, quoted, rows

L = "le-ebk0a11h"

b = Book()
try:
    sh = b.sheet("Sales")
    sh.getCellRangeByName("H1").setString("Revenue")
    b.set("Sales", "H2", "=E2*F2")
    b.fill("Sales", "H2", "H109")
    b.doc.DatabaseRanges.addNewByName("Sales", sh.getCellRangeByName("A1:H109").getRangeAddress())
    b.doc.DatabaseRanges.getByName("Sales").ContainsHeader = True
    nrows = b.ev(quoted(L, "=ROWS(A:A)"))
    ncols = b.ev(quoted(L, "=COLUMNS(1:1)"))
    used = b.ev("=COUNTA(A:A)", "Sales", "J1")
    sums = {}
    for ch in ("Wholesale", "Online", "Shop"):
        f = f'=SUMIFS(Sales[Revenue], Sales[Channel], "{ch}")'
        if ch == "Wholesale":
            f = quoted(L, f)
        sums[ch] = b.ev(f)
    print(f"=ROWS(A:A): {nrows}")
    print(f"=COLUMNS(1:1): {ncols}")
    print(f"Sales =COUNTA(A:A): {used}, a share of the rows of {100 * used / nrows:.4f}%")
    for ch, v in sums.items():
        print(f'=SUMIFS(Sales[Revenue], Sales[Channel], "{ch}"): {v}')
finally:
    b.close()

print("== past the edge")
per_day = 1000
days = (nrows - 1) / per_day
print(f"{per_day} rows a day fill the {nrows - 1} rows under a header in {days:.1f} days = {days / 365:.2f} years")
lines = 1_200_000
print(f"a CSV of {lines} lines, header included, loses {lines - nrows} of them")
print(f"xlsx against xls: {nrows // 65536} times the rows, {ncols // 256} times the columns")

print("== the same question asked of a database (SQLite)")
text = open("../lessons/" + L + "/where-next.md", encoding="utf-8").read()
query = re.search(r"```sql\n(.*?)\n```", text, re.S).group(1)
db = sqlite3.connect(":memory:")
head = rows("Sales")[0]
db.execute("CREATE TABLE Sales (Sale TEXT, Date TEXT, Customer TEXT, Product TEXT, Bags INTEGER, "
           "Price INTEGER, Channel TEXT)")
db.executemany("INSERT INTO Sales VALUES (?,?,?,?,?,?,?)",
               [[str(v) if i == 1 else v for i, v in enumerate(r)] for r in rows("Sales")[1:]])
print(query)
for r in db.execute(query):
    print("  ", r, "| SUMIFS agrees:", sums[r[0]] == r[2])
