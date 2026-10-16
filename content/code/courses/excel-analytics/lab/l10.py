#!/usr/bin/env python3
"""Lesson 10: every pivot table the lesson builds, computed by Calc's own pivot
table (DataPilot) over the Sales range, and every number of it checked
against a SUMIFS, COUNTIFS or AVERAGEIFS over the same range, in this run.

The workbook is the one lesson 7 leaves: Revenue in Sales!H (lesson 2) and
the ranges as tables named Sales, Products and Customers (a Calc database
range, which reads `Sales[Revenue]` as Excel reads it against a table). A
pivot is built from Sales!A1:H109, which is the table with its header.

Excel's pivot and Calc's DataPilot share the model the lesson teaches: fields
in rows, columns, data and page (Excel's Filters), sum and count and average,
grouping of dates into years and quarters and of numbers into equal bands,
a cache that a refresh re-reads. Their labels differ (`Total Result` for
`Grand Total`); the numbers are what the lesson quotes.
"""
import re

import uno  # noqa: F401  (loads the bridge before com.sun.star imports)
from com.sun.star.sheet import DataPilotFieldGroupInfo, DataPilotFieldReference
from com.sun.star.sheet.DataPilotFieldGroupBy import QUARTERS, YEARS
from com.sun.star.sheet.DataPilotFieldOrientation import COLUMN, DATA, PAGE, ROW
from com.sun.star.sheet.DataPilotFieldReferenceType import TOTAL_PERCENTAGE
from com.sun.star.sheet.GeneralFunction import AVERAGE, COUNT, SUM
from com.sun.star.table import CellAddress

from engine import Book, quoted

L = "le-82n1ygz3"


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


class Pivots:
    """DataPilot tables on one sheet, each well clear of the last."""

    def __init__(self, b):
        self.b = b
        b.doc.Sheets.insertNewByName("Pivots", b.doc.Sheets.getCount())
        self.sh = b.sheet("Pivots")
        self.tables = self.sh.getDataPilotTables()
        self.n = 0

    def make(self, rows=(), cols=(), data=(), page=(), reference=None):
        d = self.tables.createDataPilotDescriptor()
        d.setSourceRange(self.b.sheet("Sales").getCellRangeByName("A1:H109").getRangeAddress())
        f = d.getDataPilotFields()
        for x in rows:
            f.getByName(x).Orientation = ROW
        for x in cols:
            f.getByName(x).Orientation = COLUMN
        for x, fn in data:
            g = f.getByName(x)
            g.Orientation = DATA
            g.Function = fn
            if reference is not None:
                ref = DataPilotFieldReference()
                ref.ReferenceType = reference
                g.Reference = ref
        for x in page:
            f.getByName(x).Orientation = PAGE
        self.n += 1
        name = f"p{self.n}"
        self.tables.insertNewByName(name, CellAddress(self.sh.getRangeAddress().Sheet, 0, self.n * 150), d)
        return self.tables.getByName(name)

    def cells(self, t):
        o = t.getOutputRange()
        return [[self.sh.getCellByPosition(c, r).getString() for c in range(o.StartColumn, o.EndColumn + 1)]
                for r in range(o.StartRow, o.EndRow + 1)]

    def show(self, t, title):
        print(title)
        for row in self.cells(t):
            if any(row):
                print("   ", row)

    def body(self, t):
        """{(row label, column label): value} below the header row that names the columns."""
        rows = self.cells(t)
        head = next(i for i, r in enumerate(rows) if r[0] in ("Product", "Channel", "Years", "Bags", "Date"))
        cols = rows[head]
        out = {}
        for r in rows[head + 1:]:
            for c in range(1, len(cols)):
                out[(r[0], cols[c])] = r[c]
        return out


def only(t, field, keep):
    items = t.getDataPilotFields().getByName(field).getItems()
    for i in range(items.getCount()):
        it = items.getByIndex(i)
        it.IsHidden = it.Name != keep
    t.refresh()


b = lesson7_book()
try:
    q = lambda f: calc(quoted(L, f))  # noqa: E731
    ev = lambda f: b.ev(f, "Scratch", "Z1")  # noqa: E731
    P = Pivots(b)

    print("== first-pivot: Channel in Rows, Sum of Revenue")
    t = P.make(rows=["Channel"], data=[("Revenue", SUM)])
    P.show(t, "pivot:")
    for f in ('=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")', "=SUM(Sales[Revenue])"):
        print(f"{f}: {ev(q(f))}")
    for ch, v in P.body(t).items():
        if ch[0] in ("Online", "Shop", "Wholesale"):
            assert float(v) == ev(calc(f'=SUMIFS(Sales[Revenue], Sales[Channel], "{ch[0]}")')), ch
    print("every channel total equals its SUMIFS")

    print("== four-areas: Product in Rows, Channel in Columns, Customer in Filters")
    t = P.make(rows=["Product"], cols=["Channel"], data=[("Revenue", SUM)], page=["Customer"])
    P.show(t, "pivot, Customer (All):")
    checked = 0
    for (prod, ch), v in P.body(t).items():
        if prod in ("Total Result", "") or ch in ("Total Result", ""):
            continue
        s = ev(calc(f'=SUMIFS(Sales[Revenue], Sales[Product], "{prod}", Sales[Channel], "{ch}")'))
        assert (float(v) if v else 0) == s, (prod, ch, v, s)
        checked += 1
    print(f"all {checked} product-by-channel cells equal their SUMIFS (blank where it is 0)")
    f = '=SUMIFS(Sales[Revenue], Sales[Product], "CER1K", Sales[Channel], "Wholesale")'
    print(f"{f}: {ev(q(f))}")
    only(t, "Customer", "C00")
    P.show(t, "pivot, Customer = C00:")
    f = '=SUMIFS(Sales[Revenue], Sales[Customer], "C00")'
    print(f"{f}: {ev(q(f))}")
    for ch in ("Online", "Shop", "Wholesale"):
        print(f"  {ch}: sales to C00 {ev(calc(f'=COUNTIFS(Sales[Channel], {chr(34)}{ch}{chr(34)}, Sales[Customer], {chr(34)}C00{chr(34)})'))}"
              f" of {ev(calc(f'=COUNTIFS(Sales[Channel], {chr(34)}{ch}{chr(34)})'))}")

    print("== summarise-by")
    for fn, label in ((COUNT, "Count"), (AVERAGE, "Average")):
        P.show(P.make(rows=["Channel"], data=[("Revenue", fn)]), f"{label} of Revenue:")
    for f in ('=COUNTIFS(Sales[Channel], "Online")', '=AVERAGEIFS(Sales[Revenue], Sales[Channel], "Wholesale")'):
        print(f"{f}: {ev(q(f))}")
    for ch in ("Online", "Shop"):
        print(f"  average {ch}: {ev(calc(f'=AVERAGEIFS(Sales[Revenue], Sales[Channel], {chr(34)}{ch}{chr(34)})'))}")
    print("  average, all:", ev(calc("=AVERAGE(Sales[Revenue])")))
    P.show(P.make(rows=["Channel"], data=[("Price", SUM)]), "Sum of Price (the summary that means nothing):")
    P.show(P.make(rows=["Channel"], data=[("Revenue", SUM)], reference=TOTAL_PERCENTAGE), "% of Grand Total:")

    print("== grouping: dates")
    print("distinct days in Date:", ev("=SUMPRODUCT(1/COUNTIF($Sales.B2:B109;$Sales.B2:B109))"))
    t = P.make(rows=["Date"], data=[("Revenue", SUM)])
    gi = DataPilotFieldGroupInfo()
    gi.HasAutoStart, gi.HasAutoEnd, gi.HasDateValues, gi.GroupBy = True, True, True, YEARS
    t.getDataPilotFields().getByName("Date").createDateGroup(gi)
    t.refresh()
    P.show(t, "Years:")
    f = '=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2025,1,1), Sales[Date], "<="&DATE(2025,6,30))'
    print(f"{f}: {ev(q(f))}")
    print("first half of 2026:", ev(calc('=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<="&DATE(2026,6,30))')))
    t = P.make(rows=["Date"], cols=["Channel"], data=[("Revenue", SUM)])
    df = t.getDataPilotFields().getByName("Date")
    for g in (QUARTERS, YEARS):
        gi = DataPilotFieldGroupInfo()
        gi.HasAutoStart, gi.HasAutoEnd, gi.HasDateValues, gi.GroupBy = True, True, True, g
        df.createDateGroup(gi)
    t.refresh()
    P.show(t, "Years and quarters by channel:")
    year = None
    for row in P.cells(t):
        if row[1] in ("Q1", "Q2", "Q3", "Q4"):
            year = row[0] or year
            qn = int(row[1][1])
            start, end = f"DATE({year},{3 * qn - 2},1)", f"EOMONTH(DATE({year},{3 * qn},1),0)"
            for i, ch in enumerate(("Online", "Shop", "Wholesale")):
                s = ev(calc(f'=SUMIFS(Sales[Revenue], Sales[Channel], "{ch}", Sales[Date], ">="&{start}, Sales[Date], "<="&{end})'))
                assert (float(row[2 + i]) if row[2 + i] else 0) == s, (year, qn, ch)
    print("every quarter-by-channel cell equals its SUMIFS")
    f = ('=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale", Sales[Date], ">="&DATE(2026,4,1), '
         'Sales[Date], "<="&DATE(2026,6,30))')
    print(f"{f}: {ev(q(f))}")

    print("== grouping: Bags in bands of 5 from 1 to 20, Count of Sale")
    t = P.make(rows=["Bags"], data=[("Sale", COUNT)])
    gi = DataPilotFieldGroupInfo()
    gi.HasAutoStart, gi.HasAutoEnd, gi.HasDateValues = False, False, False
    gi.Start, gi.End, gi.Step, gi.GroupBy = 1, 20, 5, 0
    t.getDataPilotFields().getByName("Bags").GroupInfo = gi
    t.refresh()
    P.show(t, "pivot:")
    f = '=COUNTIFS(Sales[Bags], ">=1", Sales[Bags], "<=5")'
    print(f"{f}: {ev(q(f))}")
    for lo in (6, 11, 16):
        print(f"  {lo}-{lo + 4}: {ev(calc(f'=COUNTIFS(Sales[Bags], {chr(34)}>={lo}{chr(34)}, Sales[Bags], {chr(34)}<={lo + 4}{chr(34)})'))}")

    print("== refresh: S1001's bags 14 -> 15")
    t = P.make(rows=["Channel"], data=[("Revenue", SUM)])
    f = '=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")'
    quoted(L, f)
    b.sheet("Sales").getCellRangeByName("E2").setValue(15)
    b.doc.calculateAll()
    print("H2 now:", b.value("Sales", "H2"))
    print(f"formula at once: {ev(calc(f))}")
    P.show(t, "pivot before Refresh:")
    t.refresh()
    P.show(t, "pivot after Refresh:")
    b.sheet("Sales").getCellRangeByName("E2").setValue(14)
    t.refresh()
    P.show(t, "E2 back to 14, refreshed:")

    print("== first-pivot: a misspelt channel is a fourth channel")
    b.sheet("Sales").getCellRangeByName("G4").setString("Onlnie")
    t = P.make(rows=["Channel"], data=[("Revenue", SUM)])
    t.refresh()  # a new pivot on the same range shares the cache the earlier ones read
    P.show(t, "pivot with 'Onlnie' in G4:")
    b.sheet("Sales").getCellRangeByName("G4").setString("Online")
finally:
    b.close()
