#!/usr/bin/env python3
"""Lesson 7: the three tables, structured references, a table growing by one
row, the total row under a filter, and a lookup column between tables.

Calc calls a table a database range, and reads `Sales[Bags]`,
`Sales[#Headers]` and `Sales[[#This Row],[Bags]]` against one the way Excel
reads them against a table. Three things are written differently here, and
each is said where it happens:

- `[@Bags]` is Excel's short form of `Sales[[#This Row],[Bags]]`; Calc 24.2
  reads only the long form, so `this_row()` expands it.
- A Calc database range does not grow when a row is typed under it; Excel's
  table does. `grow()` moves the range's edge to where Excel would put it.
- XLOOKUP is not in this Calc. Row 2 of the Cost column is computed by
  `engine.xl` with the formula in addresses; the whole column is computed in
  Calc with INDEX and MATCH over the same structured references, and the
  script prints both so they can be compared.
"""
import re

import formulas
formulas.ExcelModel  # loaded before uno: its import hook breaks one of the imports behind this
import uno  # noqa: F401

from engine import Book, quoted, serial, table_cells, xl

L = "le-2yr9bsgy"

# XLOOKUP first, in addresses, before Calc starts.
cells = {**table_cells("Sales"), **table_cells("Products")}
x854 = xl(cells, "=Sales!E2*XLOOKUP(Sales!D2, Products!A2:A7, Products!G2:G7)")
print("== tables-and-lookups, by the Excel-compatible calculator")
print("   row 2 of Cost, =E2*XLOOKUP(D2, Products!A2:A7, Products!G2:G7) ->", x854)


def this_row(f, table="Sales"):
    return re.sub(r"\[@([^\]]+)\]", lambda m: f"{table}[[#This Row],[{m.group(1)}]]", f)


def calc(f):
    f = re.sub(r"\b([A-Za-z]+)!", r"$\1.", f)
    return f


b = Book()
b.doc.IgnoreCase = True
try:
    sh = b.sheet("Sales")
    sh.getCellRangeByName("H1").setString("Revenue")
    b.set("Sales", "H2", "=E2*F2")
    b.fill("Sales", "H2", "H109")
    dr = b.doc.DatabaseRanges
    for name, rng in (("Sales", "A1:H109"), ("Products", "A1:G7"), ("Customers", "A1:F12")):
        dr.addNewByName(name, b.sheet(name).getCellRangeByName(rng).getRangeAddress())
        dr.getByName(name).ContainsHeader = True

    def grow(name, rng):
        dr.getByName(name).setDataArea(b.sheet(name).getCellRangeByName(rng).getRangeAddress())

    def q(f, sheet="Sales", addr="K1"):
        v = b.ev(calc(this_row(quoted(L, f))), sheet, addr)
        print(f"{sheet}!{addr} {f}  ->  {v}")
        return v

    print("== make-a-table")
    b.set("Sales", "H2", calc(this_row(quoted(L, "=[@Bags]*[@Price]"))))
    b.fill("Sales", "H2", "H109")
    print("   H2 now reads", sh.getCellRangeByName("H2").getFormula(), "->", b.value("Sales", "H2"))
    q("=SUM(Sales[Revenue])")

    print("== structured-references")
    q("=SUM(Sales[Bags])")
    q('=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")')
    q("=ROWS(Sales[Sale])")
    print("   drill: =AVERAGEIFS(Sales[Revenue], Sales[Channel], \"Wholesale\") ->",
          b.ev('=AVERAGEIFS(Sales[Revenue], Sales[Channel], "Wholesale")', "Sales", "K1"))
    import datetime
    b.doc.Sheets.insertNewByName("Report", b.doc.Sheets.getCount())
    rp = b.sheet("Report")
    for i, c in enumerate(["SUL250", "CER250", "MOG250", "DEC250", "SUL1K", "CER1K"]):
        rp.getCellByPosition(0, 2 + i).setString(c)
    for i, m in enumerate((1, 2, 3)):
        rp.getCellByPosition(1 + i, 1).setValue(serial(datetime.date(2025, m, 1)))
    grid = quoted(L, '=SUMIFS(Sales[Bags], Sales[Product], $A3, Sales[Date], ">="&B$2, Sales[Date], '
                     '"<"&EDATE(B$2, 1))')
    # Each cell gets the formula as copy and paste gives it: the $ references
    # move as usual and the table references stay.
    for r in range(3, 9):
        for c in "BCD":
            b.set("Report", f"{c}{r}", grid.replace("$A3", f"$A{r}").replace("B$2", f"{c}$2"))
    b.set("Report", "E9", "=SUM(B3:D8)")
    print("   Report grid with table references, grand total ->", b.value("Report", "E9"))

    print("== growing")
    b.put("Sales", [["S1109", datetime.date(2026, 6, 29), "C01", "CER1K", 6, 106, "Wholesale"]], top=109)
    grow("Sales", "A1:H110")   # what Excel's table does when a row is typed under it
    b.set("Sales", "H110", calc(this_row("=[@Bags]*[@Price]")))  # the calculated column's formula
    print("   H110 ->", b.value("Sales", "H110"))
    q("=SUM(Sales[Bags])")
    q("=SUM(E2:E109)")
    q("=ROWS(Sales[Sale])")
    print("   =SUM(Sales[Revenue]) ->", b.ev("=SUM(Sales[Revenue])", "Sales", "K1"))
    sh.getRows().removeByIndex(109, 1)   # Delete › Table Rows
    grow("Sales", "A1:H109")
    q("=SUM(Sales[Bags])")
    print("   =ROWS(Sales[Sale]) ->", b.ev("=ROWS(Sales[Sale])", "Sales", "K1"))

    print("== total-row")
    tot = quoted(L, "=SUBTOTAL(109,[Bags])").replace("[Bags]", "Sales[Bags]")
    print("   total row under Bags, unfiltered:", b.ev(tot, "Sales", "K1"),
          " under Revenue:", b.ev("=SUBTOTAL(109,Sales[Revenue])", "Sales", "K1"))
    from com.sun.star.sheet.FilterOperator import EQUAL
    rng = sh.getCellRangeByName("A1:H109")
    fd = rng.createFilterDescriptor(True)
    ff = uno.createUnoStruct("com.sun.star.sheet.TableFilterField")
    ff.Field, ff.Operator, ff.IsNumeric, ff.StringValue = 6, EQUAL, False, "Wholesale"
    fd.setFilterFields((ff,))
    fd.ContainsHeader = True
    rng.filter(fd)
    print("   filtered to Wholesale: total row under Bags", b.ev(tot, "Sales", "K1"),
          " under Revenue", b.ev("=SUBTOTAL(109,Sales[Revenue])", "Sales", "K1"))
    q("=SUM(Sales[Bags])")
    q("=SUBTOTAL(109, Sales[Bags])")
    q("=SUBTOTAL(103, Sales[Sale])")
    print("   SUBTOTAL(9) on the same filter ->", b.ev("=SUBTOTAL(9, Sales[Bags])", "Sales", "K1"))
    fd.setFilterFields(())
    rng.filter(fd)
    print("   filter cleared, =SUBTOTAL(109, Sales[Bags]) ->", b.ev("=SUBTOTAL(109, Sales[Bags])", "Sales", "K1"))

    print("== tables-and-lookups")
    quoted(L, "=[@Bags]*XLOOKUP([@Product], Products[Code], Products[Unit cost])")
    grow("Sales", "A1:I109")
    sh.getCellRangeByName("I1").setString("Cost")
    same = "=[@Bags]*INDEX(Products[Unit cost], MATCH([@Product], Products[Code], 0))"
    b.set("Sales", "I2", calc(this_row(same)))
    b.fill("Sales", "I2", "I109")
    print(f"   the Cost column in Calc as {same}: I2 ->", b.value("Sales", "I2"), "(XLOOKUP gave", x854, ")")
    q("=SUM(Sales[Cost])")
    q("=SUM(Sales[Revenue])-SUM(Sales[Cost])")
    print("   margin as a share of revenue ->", b.ev("=1-SUM(Sales[Cost])/SUM(Sales[Revenue])", "Sales", "K1"))
    vl = quoted(L, "=VLOOKUP([@Product], Products, 7, FALSE)")
    print(f"   {vl} on row 2 ->", b.ev(calc(this_row(vl)).replace("FALSE", "FALSE()"), "Sales", "K2"))
    ps = b.sheet("Products")
    ps.Columns.insertByIndex(4, 1)     # Insert › Table Columns to the Left of Grams
    ps.getCellRangeByName("E1").setString("Supplier")
    print("   with Supplier inserted before Grams: VLOOKUP on row 2 ->",
          b.ev(calc(this_row(vl)).replace("FALSE", "FALSE()"), "Sales", "K2"),
          " Cost I2 ->", b.value("Sales", "I2"), " =SUM(Sales[Cost]) ->", b.ev("=SUM(Sales[Cost])", "Sales", "K1"))
finally:
    b.close()
