#!/usr/bin/env python3
"""Lesson 12: the numbers behind the charts and sparklines.

A chart draws numbers that a formula or a pivot table already computed, so
what is checked here is those numbers: the `Mix`, `Monthly` and `Trends`
sheets the lesson builds, each formula entered as printed and filled the way
the fill handle fills it, in a Calc workbook holding the pasted data with
lesson 2's Revenue column and lesson 7's table `Sales`. The product revenue a
PivotChart draws is Calc's own pivot table (l11.pivot), checked against SUMIFS.

What is NOT computed, because no number exists to compute: how Excel draws a
chart, where it puts an axis by itself, which chart Recommended Charts offers.
The lesson describes those in words, and every axis bound it mentions is one
the student sets.
"""
import datetime

from l11 import body, pivot, read, with_table
from engine import Book, date_of, quoted, serial

L = "le-60d383wz"


def put_date(book, sheet, addr, day):
    book.sheet(sheet).getCellRangeByName(addr).setValue(serial(day))


def fill_right(book, sheet, first, last):
    """Copy `first` across to `last` on one row, as dragging right does."""
    import re
    sh = book.sheet(sheet)
    src = sh.getCellRangeByName(first).getRangeAddress()
    row = re.search(r"\d+", first).group(0)
    c0 = ord(re.match(r"[A-Z]", first).group(0))
    c1 = ord(re.match(r"[A-Z]", last).group(0))
    for c in range(c0 + 1, c1 + 1):
        sh.copyRange(sh.getCellRangeByName(f"{chr(c)}{row}").getCellAddress(), src)


b = with_table(Book())
try:
    # --- the channel mix (titles-axes-labels) ------------------------------
    b.doc.Sheets.insertNewByName("Mix", b.doc.Sheets.getCount())
    b.put("Mix", [["Channel", "Revenue", "Share"], ["Wholesale"], ["Online"], ["Shop"]])
    b.set("Mix", "B2", quoted(L, '=SUMIFS(Sales[Revenue], Sales[Channel], A2)'))
    b.fill("Mix", "B2", "B4")
    b.set("Mix", "C2", quoted(L, "=B2/SUM($B$2:$B$4)"))
    b.fill("Mix", "C2", "C4")
    print("== Mix")
    mix = {}
    for r in range(2, 5):
        ch, rev, sh = b.value("Mix", f"A{r}"), b.value("Mix", f"B{r}"), b.value("Mix", f"C{r}")
        mix[ch] = rev
        print(f"   {ch}: {rev:,} ({100 * sh:.1f}%)")
    w, o, s = mix["Wholesale"], mix["Online"], mix["Shop"]
    print(f"   bars from zero: Wholesale / Online = {w / o:.2f}, Wholesale / Shop = {w / s:.1f}")
    print(f"   axis from 10,000: Wholesale bar {w - 10000:,} tall, Online {o - 10000:,}, ratio {(w - 10000) / (o - 10000):.1f};"
          f" Shop {s:,} is below the axis")

    # --- product revenue, as the PivotChart draws it (building) ------------
    pt = pivot(b, "ByProduct", "A3", "byproduct", "Product", [("Revenue", "sum")])
    prod = body(read(b, pt), "Product")
    total = prod.pop("Total Result")[0]
    print("== ByProduct, largest first (Calc's pivot, sorted)")
    for k, v in sorted(prod.items(), key=lambda kv: -kv[1][0]):
        print(f"   {k}: {v[0]:,.0f} ({100 * v[0] / total:.1f}%)")
    f = '=SUMIFS(Sales[Revenue], Sales[Product], "CER1K")-SUMIFS(Sales[Revenue], Sales[Product], "SUL1K")'
    print(f"   check {f}: {b.ev(quoted(L, f), 'Sales', 'K1')}")

    # --- the monthly sheet (building, combo) --------------------------------
    b.doc.Sheets.insertNewByName("Monthly", b.doc.Sheets.getCount())
    b.put("Monthly", [["Month", "Revenue", "Bags", "3-month average"]])
    put_date(b, "Monthly", "A2", datetime.date(2025, 1, 1))
    b.set("Monthly", "A3", quoted(L, "=EDATE(A2,1)"))
    b.fill("Monthly", "A3", "A19")
    b.set("Monthly", "B2", quoted(L, '=SUMIFS(Sales[Revenue], Sales[Date], ">="&A2, Sales[Date], "<"&EDATE(A2,1))'))
    b.fill("Monthly", "B2", "B19")
    b.set("Monthly", "C2", quoted(L, '=SUMIFS(Sales[Bags], Sales[Date], ">="&A2, Sales[Date], "<"&EDATE(A2,1))'))
    b.fill("Monthly", "C2", "C19")
    b.set("Monthly", "D4", quoted(L, "=AVERAGE(B2:B4)"))
    b.fill("Monthly", "D4", "D19")
    b.set("Monthly", "E2", quoted(L, "=B2/C2"))
    b.fill("Monthly", "E2", "E19")
    print("== Monthly")
    for r in range(2, 20):
        d = datetime.date(1899, 12, 30) + datetime.timedelta(days=int(b.value("Monthly", f"A{r}")))
        avg = b.value("Monthly", f"D{r}") if r >= 4 else ""
        print(f"   A{r} {d:%Y-%m}: revenue {b.value('Monthly', f'B{r}'):,}  bags {b.value('Monthly', f'C{r}')}"
              f"  per bag {b.value('Monthly', f'E{r}'):.2f}"
              + (f"  3-month average {avg:,.1f}" if avg != "" else ""))
    f = '=COUNTIFS(Sales[Channel], "Wholesale", Sales[Date], ">="&DATE(2026,4,1), Sales[Date], "<"&DATE(2026,6,1))'
    print(f"   check {f}: {b.ev(quoted(L, f), 'Sales', 'K1')}")
    for f in ["=MAX(E2:E19)", "=MIN(E2:E19)", "=MAX(D4:D19)"]:
        print(f"   {f}: {b.ev(f, 'Monthly', 'G2')}")
    for f in ["=SUM(B2:B19)", "=SUM(C2:C19)"]:
        print(f"   check {f}: {b.ev(quoted(L, f), 'Monthly', 'G1')}")

    # --- relationship (choosing) -------------------------------------------
    for f in ['=MINIFS(Sales[Bags], Sales[Channel], "Wholesale")',
              '=MAXIFS(Sales[Bags], Sales[Channel], "<>Wholesale")']:
        print(f"   {f}: {b.ev(quoted(L, f), 'Sales', 'K1')}")

    # --- the trends grid (sparklines) ---------------------------------------
    b.doc.Sheets.insertNewByName("Trends", b.doc.Sheets.getCount())
    b.put("Trends", [["Product"], ["CER1K"], ["CER250"], ["DEC250"], ["MOG250"], ["SUL1K"], ["SUL250"]])
    put_date(b, "Trends", "B1", datetime.date(2025, 1, 1))
    b.set("Trends", "C1", quoted(L, "=EDATE(B1,1)"))
    fill_right(b, "Trends", "C1", "S1")
    b.set("Trends", "B2", quoted(L, '=SUMIFS(Sales[Bags], Sales[Product], $A2, Sales[Date], ">="&B$1, Sales[Date], "<"&EDATE(B$1,1))'))
    fill_right(b, "Trends", "B2", "S2")
    for r in range(3, 8):
        for c in range(ord("B"), ord("S") + 1):
            sh = b.sheet("Trends")
            sh.copyRange(sh.getCellRangeByName(f"{chr(c)}{r}").getCellAddress(),
                         sh.getCellRangeByName(f"{chr(c)}2").getRangeAddress())
    print("== Trends (bags per product per month, January 2025 to June 2026)")
    for r in range(2, 8):
        vals = [b.value("Trends", f"{chr(c)}{r}") for c in range(ord("B"), ord("S") + 1)]
        mx = b.ev(f"=MAX(B{r}:S{r})", "Trends", f"U{r}")
        print(f"   {b.value('Trends', f'A{r}')}: {vals}  max {mx}  sum {sum(vals)}"
              f"  first best month {date_of(b.value('Trends', chr(ord('B') + vals.index(mx)) + '1')):%Y-%m}")
    print(f"   check =SUM(B2:S7): {b.ev(quoted(L, '=SUM(B2:S7)'), 'Trends', 'U1')}")
finally:
    b.close()
