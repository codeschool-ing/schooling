#!/usr/bin/env python3
"""Lesson 11: calculated fields and items, slicers, timelines, report
connections and GETPIVOTDATA, on the table `Sales` of lesson 7.

Every pivot table here is Calc's own (DataPilot), built through UNO on the
same range the student's table covers, A1:H109 of `Sales` with lesson 2's
Revenue column. What a pivot shows is printed as Calc laid it out, and the
SUMIFS that should agree with it is computed beside it.

WHAT CALC CANNOT DO, AND HOW THE NUMBER IS MADE INSTEAD:

- A calculated field. Calc's pivot table has none. Excel's documented rule is
  that a calculated field applies its formula to the SUMS of the fields it
  names, in every cell, the grand total included, so the number printed for
  `=Revenue/Bags` is Calc's Sum of Revenue divided by Calc's Sum of Bags, and
  for `=Price*Bags` the product of Calc's two sums. The SUMIFS cross-check is
  the independent half.
- A calculated item. Calc has none either. `Direct` is Calc's Online cell
  plus its Shop cell, and the grand total Excel shows with the item in place
  is Calc's grand total plus that item, because Excel's grand total adds every
  item in the field, the calculated one included.
- A slicer and a timeline. A slicer filters the pivot by a field's items, so
  here the field is a page field with the other items hidden; a timeline
  filters by a date range, so here the pivot's own filter keeps the dates
  inside it. GETPIVOTDATA reads the filtered pivot, as it does under a slicer.
- `[@Channel]`. Calc spells Excel's this-row reference
  `Sales[[#This Row],[Channel]]`; the lesson prints Excel's spelling, this
  checks that it is printed, and computes Calc's.
"""
import datetime
import sys

import uno  # noqa: F401  (the UNO bridge; com.sun.star below needs it)
from com.sun.star.sheet import DataPilotFieldGroupInfo, TableFilterField
from com.sun.star.sheet.DataPilotFieldGroupBy import YEARS
from com.sun.star.sheet.DataPilotFieldOrientation import COLUMN, DATA, PAGE, ROW
from com.sun.star.sheet.FilterConnection import AND
from com.sun.star.sheet.FilterOperator import GREATER_EQUAL, LESS_EQUAL
from com.sun.star.sheet.GeneralFunction import AVERAGE, SUM

from calcref import excelish
from engine import Book, quoted, rows, serial

L = "le-3nbj6hht"
FUNCS = {"sum": SUM, "average": AVERAGE}


def with_table(book):
    """Lesson 2's Revenue column and lesson 7's table `Sales` over A1:H109."""
    sh = book.sheet("Sales")
    sh.getCellRangeByName("H1").setString("Revenue")
    book.set("Sales", "H2", "=E2*F2")
    book.fill("Sales", "H2", "H109")
    book.doc.DatabaseRanges.addNewByName("Sales", sh.getCellRangeByName("A1:H109").getRangeAddress())
    excelish(book)
    return book


def _field(holder, name):
    fl = holder.getDataPilotFields()
    for i in range(fl.getCount()):
        x = fl.getByIndex(i)
        if x.getName() == name:
            return x
    raise SystemExit(f"no field {name}")


def pivot(book, sheet, at, name, rows, data, only=None, dates=None, years=False, source="A1:H109"):
    """A DataPilot from Sales!`source`. `rows` is one field; `data` a list of
    (field, "sum"|"average"); `only` = (field, [items kept]) as a slicer
    would; `dates` = (first, last) as a timeline would; `years` groups a
    date row field by years. Returns the DataPilot."""
    if sheet not in book.doc.Sheets.getElementNames():
        book.doc.Sheets.insertNewByName(sheet, book.doc.Sheets.getCount())
    sh = book.sheet(sheet)
    tabs = sh.getDataPilotTables()
    desc = tabs.createDataPilotDescriptor()
    desc.setSourceRange(book.sheet("Sales").getCellRangeByName(source).getRangeAddress())
    _field(desc, rows).Orientation = ROW
    for f, fn in data:
        d = _field(desc, f)
        d.Orientation = DATA
        d.Function = FUNCS[fn]
    if len(data) > 1:
        _field(desc, "Data").Orientation = COLUMN
    if only:
        _field(desc, only[0]).Orientation = PAGE
    if dates:
        fd = desc.getFilterDescriptor()
        out = []
        for op, day in ((GREATER_EQUAL, dates[0]), (LESS_EQUAL, dates[1])):
            t = TableFilterField()
            t.Connection, t.Field, t.Operator = AND, 1, op
            t.IsNumeric, t.NumericValue = True, serial(day)
            out.append(t)
        fd.setFilterFields(tuple(out))
    tabs.insertNewByName(name, sh.getCellRangeByName(at).getCellAddress(), desc)
    pt = tabs.getByName(name)
    if only:
        items = _field(pt, only[0]).getItems()
        for i in range(items.getCount()):
            it = items.getByIndex(i)
            it.IsHidden = it.getName() not in only[1]
    if years:
        gi = DataPilotFieldGroupInfo()
        gi.HasAutoStart = gi.HasAutoEnd = gi.HasDateValues = True
        gi.GroupBy = YEARS
        _field(pt, rows).createDateGroup(gi)
    book.doc.calculateAll()
    return pt


def read(book, pt):
    """The pivot's body as Calc drew it: {row label: [values]}, header and
    'Total Result' included, read from the header row down."""
    r = pt.getOutputRange()
    sh = book.doc.Sheets.getByIndex(r.Sheet)
    grid = [[sh.getCellByPosition(c, y).getString() for c in range(r.StartColumn, r.EndColumn + 1)]
            for y in range(r.StartRow, r.EndRow + 1)]
    return grid


def show(title, grid):
    print(f"== {title}")
    for row in grid:
        if any(row):
            print("   " + " | ".join(row))


def body(grid, first_col_name):
    out, on = {}, False
    for row in grid:
        if row[0] == first_col_name:
            on = True
            continue
        if on and row[0]:
            out[row[0]] = [float(v) if v not in ("",) else None for v in row[1:]]
    return out


if __name__ == "__main__":
    b = with_table(Book())
    try:
        # --- calculated fields -------------------------------------------
        p1 = pivot(b, "Prices", "A3", "prices", "Product",
                   [("Revenue", "sum"), ("Bags", "sum"), ("Price", "sum"), ("Price", "average")])
        g = read(b, p1)
        show("Prices: Product × Sum Revenue, Sum Bags, Sum Price, Average Price", g)
        rows_ = body(g, "Product")
        print("== the calculated fields Excel would show, from those sums")
        print("   product | =Revenue/Bags | Average of Price | =Price*Bags (SumPrice*SumBags) | real revenue")
        for k, (rev, bags, sp, avgp) in rows_.items():
            print(f"   {k} | {rev / bags:.2f} | {avgp:.2f} | {sp * bags:,.0f} | {rev:,.0f}")
        for code in ("SUL1K", "CER250"):
            print(f"   sales of {code}:", sum(1 for r in rows("Sales")[1:] if r[3] == code))
        print("   S1002:", rows("Sales")[2])
        tot = rows_["Total Result"]
        cer = rows_["CER250"]
        print(f"   =Price*Bags against the real revenue: total {tot[2] * tot[1] / tot[0]:.2f} times,"
              f" CER250 {cer[2] * cer[1] / cer[0]:.2f} times")
        for f in ['=SUMIFS(Sales[Revenue], Sales[Product], "SUL1K")/SUMIFS(Sales[Bags], Sales[Product], "SUL1K")',
                  '=AVERAGEIFS(Sales[Price], Sales[Product], "SUL1K")',
                  '=SUMIFS(Sales[Price], Sales[Product], "CER250")',
                  '=SUMIFS(Sales[Bags], Sales[Product], "CER250")',
                  '=SUMIFS(Sales[Revenue], Sales[Product], "CER250")']:
            v = b.ev(quoted(L, f), "Sales", "K1")
            print(f"   check {f}: {v:.4f}" if isinstance(v, float) else f"   check {f}: {v}")

        # --- calculated items ----------------------------------------------
        p2 = pivot(b, "Channels", "A3", "channels", "Channel", [("Revenue", "sum")])
        g = read(b, p2)
        show("Channels: Channel × Sum Revenue", g)
        ch = body(g, "Channel")
        direct = ch["Online"][0] + ch["Shop"][0]
        print(f"   calculated item Direct = Online + Shop = {direct:,.0f}")
        print(f"   grand total with the item in the field = {ch['Total Result'][0] + direct:,.0f}"
              f" (true total {ch['Total Result'][0]:,.0f}; over by {direct:,.0f},"
              f" {100 * direct / ch['Total Result'][0]:.1f}%)")
        # Grouping Online and Shop instead: Calc's own name group.
        _field(p2, "Channel").createNameGroup(("Online", "Shop"))
        b.doc.calculateAll()
        show("Channels after grouping Online and Shop (Calc names it as Excel does: Channel2, Group1)",
             read(b, p2))
        # The helper column, in Calc's spelling of Excel's [@Channel].
        quoted(L, '=IF([@Channel]="Wholesale", "Wholesale", "Direct")')
        sh = b.sheet("Sales")
        sh.getCellRangeByName("I1").setString("Route")
        b.doc.DatabaseRanges.removeByName("Sales")
        b.doc.DatabaseRanges.addNewByName("Sales", sh.getCellRangeByName("A1:I109").getRangeAddress())
        b.set("Sales", "I2", '=IF(Sales[[#This Row],[Channel]]="Wholesale", "Wholesale", "Direct")')
        b.fill("Sales", "I2", "I109")
        for f in ['=SUMIFS(Sales[Revenue], Sales[Route], "Direct")',
                  '=COUNTIFS(Sales[Route], "Direct")']:
            print(f"   check {f}: {b.ev(quoted(L, f), 'Sales', 'K1')}")
        # Back to the eight columns the rest of the course assumes.
        b.doc.DatabaseRanges.removeByName("Sales")
        sh.getCellRangeByName("I1:I109").clearContents(1 | 2 | 4 | 16)
        b.doc.DatabaseRanges.addNewByName("Sales", sh.getCellRangeByName("A1:H109").getRangeAddress())

        # --- slicers ---------------------------------------------------------
        p3 = pivot(b, "Report", "A3", "report", "Product", [("Revenue", "sum")])
        full = read(b, p3)
        show("Report: Product × Sum Revenue, no slicer", full)
        for keep in (["Wholesale"], ["Online", "Shop"]):
            pt = pivot(b, "Slice" + "".join(keep), "A3", "s" + "".join(keep), "Product", [("Revenue", "sum")],
                       only=("Channel", keep))
            show(f"Report with the Channel slicer on {' + '.join(keep)}", read(b, pt))
        for f in ['=SUMIFS(Sales[Revenue], Sales[Product], "SUL1K", Sales[Channel], "Wholesale")',
                  '=SUMIFS(Sales[Revenue], Sales[Product], "CER1K", Sales[Channel], "Wholesale")']:
            print(f"   check {f}: {b.ev(quoted(L, f), 'Sales', 'K1')}")

        # --- timelines -------------------------------------------------------
        h, hp = {}, {}
        print("   distinct dates in Sales:", len({r[1] for r in rows("Sales")[1:]}))
        for y in (2025, 2026):
            span = (datetime.date(y, 1, 1), datetime.date(y, 6, 30))
            pt = pivot(b, f"H{y}", "A3", f"h{y}", "Product", [("Revenue", "sum")], dates=span)
            g = read(b, pt)
            show(f"Report with the timeline on January to June {y}", g)
            hp[y] = body(g, "Product")
            h[y] = hp[y]["Total Result"][0]
            pt = pivot(b, f"HW{y}", "A3", f"hw{y}", "Product", [("Revenue", "sum")], dates=span,
                       only=("Channel", ["Wholesale"]))
            show(f"... and the Channel slicer on Wholesale too, {y}", read(b, pt))
        for k in hp[2025]:
            if k in hp[2026]:
                print(f"   {k}: {hp[2025][k][0]:,.0f} -> {hp[2026][k][0]:,.0f}"
                      f" ({100 * (hp[2026][k][0] - hp[2025][k][0]) / hp[2025][k][0]:+.1f}%)")
        print(f"   change, first half 2026 against 2025: {h[2026] - h[2025]:,.0f}"
              f" ({100 * (h[2026] - h[2025]) / h[2025]:.1f}%)")
        f = '=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<="&DATE(2026,6,30))'
        print(f"   check {f}: {b.ev(quoted(L, f), 'Sales', 'K1')}")

        # --- report connections ---------------------------------------------
        for keep in (None, ["Wholesale"]):
            pt = pivot(b, "Years" + ("W" if keep else ""), "A3", "y" + ("W" if keep else ""), "Date",
                       [("Bags", "sum")], only=("Channel", keep) if keep else None, years=True)
            show("Second pivot: Date grouped by years × Sum of Bags" + (", slicer on Wholesale" if keep else ""),
                 read(b, pt))

        pt = pivot(b, "YearsRev", "A3", "yrev", "Date", [("Revenue", "sum")], years=True)
        show("Date grouped by years × Sum of Revenue (whole years, to compare with the halves)", read(b, pt))

        # --- GETPIVOTDATA ----------------------------------------------------
        # The pivots are at A3 of their sheets, as Excel's New Worksheet puts
        # them, so `$A$3` is a cell of the pivot in Calc as in Excel.
        for f in ['=GETPIVOTDATA("Revenue",$A$3,"Product","CER1K")',
                  '=GETPIVOTDATA("Revenue",$A$3,"Product","CER250")',
                  '=GETPIVOTDATA("Revenue",$A$3)']:
            q = quoted(L, f)
            print(f"   Report (no slicer) {f}: {b.ev(q, 'Report', 'F1')}")
            print(f"   Report (slicer on Wholesale) {f}: {b.ev(q, 'SliceWholesale', 'F1')}")
        # The second product row, which a plain reference to it would read.
        g = body(read(b, b.sheet("SliceWholesale").getDataPilotTables().getByName("sWholesale")), "Product")
        print("   second product row under Wholesale:", list(g.items())[1])
        g = body(full, "Product")
        print("   second product row with no slicer:", list(g.items())[1])
        b.sheet("Report").getCellRangeByName("F3").setString("SUL1K")
        f = '=GETPIVOTDATA("Revenue",$A$3,"Product",F3)'
        print(f"   Report, F3 = SUL1K, {f}: {b.ev(quoted(L, f), 'Report', 'G3')}")
    finally:
        b.close()
    sys.exit(0)
