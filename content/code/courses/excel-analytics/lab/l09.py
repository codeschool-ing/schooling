#!/usr/bin/env python3
"""Lesson 9: what each conditional-format rule the lesson builds colours, on
the workbook lesson 7 leaves (Revenue in Sales!H, the tables Sales, Products
and Customers), and the month-by-channel grid the lesson shades.

HOW A RULE IS ASKED. Calc applies conditional formats but cannot be asked
which cells one painted, so a rule is evaluated the way Excel evaluates it:
its formula, written for the top-left cell of the range, is put in the
top-left cell of a grid of the same shape on a scratch sheet, with its
references pointed at `Sales`, and copied to every other cell of the grid as
a fill would copy it, relative references moving and `$` ones staying. A cell
of the grid answering TRUE is a cell the rule colours. The ready-made rules
(Greater Than, Top 10 Items, Above Average, the icon thresholds) are counted
with the COUNTIF the lesson prints beside each one.
"""
import re

import uno  # noqa: F401  (loads the bridge before com.sun.star imports)
from com.sun.star.table import CellAddress

from engine import Book, quoted, rows

L = "le-09t3gbje"
REF = re.compile(r"(\$?[A-Z]{1,3}\$?\d+)")


def calc(formula):
    """Excel's `Sheet!A1` is Calc's `$Sheet.A1`; the rest is engine.api()."""
    out = []
    for part in re.split(r'("[^"]*")', formula):
        if not part.startswith('"'):
            part = re.sub(r"('[^']+'|[A-Za-z_][A-Za-z0-9_]*)!", lambda m: "$" + m.group(1) + ".", part)
        out.append(part)
    return "".join(out)


def on_sheet(formula, sheet):
    """Every cell reference in a rule's formula, pointed at `sheet`."""
    out = []
    for part in re.split(r'("[^"]*")', formula):
        if not part.startswith('"'):
            part = REF.sub(lambda m: f"${sheet}." + m.group(1), part)
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


def rule_grid(b, rule, sheet, ncols, nrows, grid="Scratch"):
    """The rule, evaluated for each cell of a range ncols wide and nrows tall
    whose top-left cell is A2 of `sheet`: a list of rows of booleans."""
    g = b.sheet(grid)
    g.clearContents(1023)
    b.set(grid, "A2", on_sheet(rule, sheet))
    src = g.getCellRangeByName("A2").getRangeAddress()
    for r in range(nrows):
        for c in range(ncols):
            if r or c:
                g.copyRange(g.getCellByPosition(c, 1 + r).getCellAddress(), src)
    b.doc.calculateAll()
    return [[g.getCellByPosition(c, 1 + r).getValue() == 1 for c in range(ncols)] for r in range(nrows)]


def count(grid):
    return sum(v for row in grid for v in row)


b = lesson7_book()
try:
    q = lambda f: calc(quoted(L, f))  # noqa: E731
    ev = lambda f: b.ev(q(f), "Scratch", "Z1")  # noqa: E731

    print("== highlight-rules")
    for f in ['=COUNTIF(Sales[Revenue], ">1000")', "=LARGE(Sales[Revenue], 10)",
              '=COUNTIF(Sales[Revenue], ">="&LARGE(Sales[Revenue], 10))', "=AVERAGE(Sales[Revenue])",
              '=COUNTIF(Sales[Revenue], ">"&AVERAGE(Sales[Revenue]))']:
        print(f"{f}: {ev(f)}")
    print("sales whose revenue equals the tenth largest:",
          b.ev(calc("=COUNTIF(Sales[Revenue], LARGE(Sales[Revenue], 10))"), "Scratch", "Z1"))
    print("Duplicate Values, Sale codes appearing more than once:",
          b.ev("=SUMPRODUCT(--(COUNTIF($Sales.A2:A109;$Sales.A2:A109)>1))", "Scratch", "Z1"))
    print("Duplicate Values, Customer cells whose code appears more than once:",
          b.ev("=SUMPRODUCT(--(COUNTIF($Sales.C2:C109;$Sales.C2:C109)>1))", "Scratch", "Z1"))

    print("== formula-rules: the rule's formula evaluated over A2:H109 of Sales")
    f = '=COUNTIF(Sales[Channel], "Wholesale")'
    print(f"{f}: {ev(f)}")
    for rule in ('=$G2="Wholesale"', '=G2="Wholesale"', '=$G$2="Wholesale"'):
        quoted(L, rule)
        g = rule_grid(b, rule, "Sales", 8, 108)
        cols = [sum(g[r][c] for r in range(108)) for c in range(8)]
        print(f"{rule}: {count(g)} cells coloured; per column A..H {cols}")
    print("G2 holds:", b.value("Sales", "G2"))
    thr = b.sheet("Sales").getCellRangeByName("K1")
    b.doc.NamedRanges.addNewByName("Threshold", "$Sales.$K$1", CellAddress(0, 0, 0), 0)
    rule = "=$H2>=Threshold"
    quoted(L, rule)
    for v in (1500, 1000):
        thr.setValue(v)
        g = rule_grid(b, rule, "Sales", 8, 108)
        print(f"Threshold {v}: {rule} colours {sum(row[0] for row in g)} rows ({count(g)} cells)")
    print("sales of exactly 1000:", b.ev('=COUNTIF($Sales.H2:H109;1000)', "Scratch", "Z1"))
    thr.setString("")

    print("== formula-rules: the gap rule on a NewSales row")
    b.doc.Sheets.insertNewByName("New sales", b.doc.Sheets.getCount())
    ns = [["Sale", "Date", "Customer", "Product", "Bags", "Price", "Channel"]]
    gap = '=AND($A2<>"", A2="")'
    quoted(L, gap)
    for label, row in (("untouched row", [None] * 7),
                       ("started row: S1109, C04, CER1K, nothing else", ["S1109", None, "C04", "CER1K", None, None, None])):
        b.put("New sales", ns + [row])
        b.sheet("New sales").getCellRangeByName("A2:G2").clearContents(1023)
        b.put("New sales", ns + [row])
        g = rule_grid(b, gap, "'New sales'", 7, 1)
        print(f"{label}: coloured columns {[ch for ch, v in zip('ABCDEFG', g[0]) if v]}")

    print("== scales-bars-icons: the By month grid")
    b.doc.Sheets.insertNewByName("By month", b.doc.Sheets.getCount())
    b.put("By month", [["Month", "Wholesale", "Online", "Shop", "Total"]])
    for addr, f in (("A2", "=DATE(2025,1,1)"), ("A3", "=EDATE(A2, 1)")):
        b.set("By month", addr, quoted(L, f))
    b.fill("By month", "A3", "A19")
    cell = quoted(L, '=SUMIFS(Sales[Revenue], Sales[Channel], B$1, Sales[Date], ">="&$A2, Sales[Date], "<="&EOMONTH($A2, 0))')
    b.set("By month", "B2", cell)
    sh = b.sheet("By month")
    src = sh.getCellRangeByName("B2").getRangeAddress()
    for r in range(1, 19):
        for c in range(1, 4):
            if (r, c) != (1, 1):
                sh.copyRange(sh.getCellByPosition(c, r).getCellAddress(), src)
    b.set("By month", "E2", "=SUM(B2:D2)")
    b.fill("By month", "E2", "E19")
    grid = []
    for r in range(2, 20):
        vals = [b.value("By month", f"{c}{r}") for c in "ABCDE"]
        print(f"  row {r}: month serial {vals[0]}, Wholesale/Online/Shop/Total {vals[1:]}")
        grid.append(vals[1:4])
    print("grand total of column E:", b.ev("=SUM($'By month'.E2:E19)", "Scratch", "Z1"))
    print("largest cell of B2:D19:", b.ev("=MAX($'By month'.B2:D19)", "Scratch", "Z1"),
          " largest Shop month:", b.ev("=MAX($'By month'.D2:D19)", "Scratch", "Z1"))
    print("column E max/min:", b.ev("=MAX($'By month'.E2:E19)", "Scratch", "Z1"),
          b.ev("=MIN($'By month'.E2:E19)", "Scratch", "Z1"))
    # The figure draws the grid from the pasted data in Python; it must be the grid Calc computed.
    from collections import defaultdict
    py = defaultdict(int)
    for s in rows("Sales")[1:]:
        py[(s[1].year, s[1].month, s[6])] += s[4] * s[5]
    months = [(2025 + (i // 12), i % 12 + 1) for i in range(18)]
    assert grid == [[py[(y, m, ch)] for ch in ("Wholesale", "Online", "Shop")] for y, m in months], "figure grid differs"
    print("the figure's grid matches Calc's")

    print("== icon thresholds")
    lo, hi = ("=MIN(Sales[Revenue])+0.33*(MAX(Sales[Revenue])-MIN(Sales[Revenue]))",
              "=MIN(Sales[Revenue])+0.67*(MAX(Sales[Revenue])-MIN(Sales[Revenue]))")
    print("min, max:", b.ev(calc("=MIN(Sales[Revenue])"), "Scratch", "Z1"), b.ev(calc("=MAX(Sales[Revenue])"), "Scratch", "Z1"))
    print(f"{hi}: {ev(hi)}")
    print(f"{lo}: {ev(lo)}")
    red = '=COUNTIF(Sales[Revenue], "<"&(MIN(Sales[Revenue])+0.33*(MAX(Sales[Revenue])-MIN(Sales[Revenue]))))'
    print(f"red arrows {red}: {ev(red)}")
    print("green arrows (>= the 67% line):", b.ev(calc('=COUNTIF(Sales[Revenue], ">="&(' + hi[1:] + "))"), "Scratch", "Z1"))
    print("yellow arrows:", b.ev(calc('=COUNTIFS(Sales[Revenue], ">="&(' + lo[1:] + '), Sales[Revenue], "<"&(' + hi[1:] + "))"), "Scratch", "Z1"))

    print("sales below the 67% line:", b.ev(calc('=COUNTIF(Sales[Revenue], "<"&(' + hi[1:] + "))"), "Scratch", "Z1"),
          " 67% of the largest sale:", b.ev("=0.67*2120", "Scratch", "Z1"))

    print("== drill (questions only)")
    print("H2 holds:", b.value("Sales", "H2"))
    g = rule_grid(b, "=$H$2>=1500", "Sales", 8, 108)
    print(f"=$H$2>=1500 over A2:H109 colours {count(g)} cells")

    print("== managing-rules")
    for f in ('=COUNTIF(Sales[Revenue], ">=1500")', '=COUNTIF(Sales[Revenue], ">=1000")'):
        print(f"{f}: {ev(f)}")
finally:
    b.close()
