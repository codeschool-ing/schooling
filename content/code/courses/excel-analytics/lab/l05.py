#!/usr/bin/env python3
"""Lesson 5: SUMIFS, COUNTIFS and AVERAGEIFS on the pasted sales, the
condition language, and the Report grid rebuilt with mixed references.

Lesson 2 adds Sales!H1 `Revenue` and H2 `=E2*F2` filled down to H109; this
script adds that column itself before computing, exactly as lesson 2 tells
the student to."""
import datetime
import re

from engine import Book, quoted, serial

L = "le-bwtf4ey0"


def calc(f):
    """A reference to another sheet, Excel's `Sales!E2`, in Calc's API
    grammar, `$Sales.E2`. Nothing else in the formula changes."""
    return re.sub(r"\b([A-Za-z]+)!", r"$\1.", f)


b = Book()
try:
    sh = b.sheet("Sales")
    sh.getCellRangeByName("H1").setString("Revenue")
    b.set("Sales", "H2", "=E2*F2")
    b.fill("Sales", "H2", "H109")

    def q(f, sheet="Sales", addr="J2"):
        v = b.ev(calc(quoted(L, f)), sheet, addr)
        print(f"{sheet}!{addr} {f}  ->  {v}")
        return v

    print("== sumifs")
    q("=SUMIFS(H2:H109, G2:G109, \"Wholesale\")")
    print("   (G2:G108, one row short: Calc answers", b.ev('=SUMIFS(H2:H109, G2:G108, "Online")', "Sales", "J2"),
          "- its own code for the error Excel shows as #VALUE!)")
    q("=SUMIFS(H2:H109, D2:D109, \"SUL1K\", G2:G109, \"Wholesale\")")
    q("=SUMIFS(H2:H109, G2:G109, \"Online\")")
    q("=SUMIFS(H2:H109, G2:G109, \"Shop\")")
    print("   =SUM(H2:H109) ->", b.ev("=SUM(H2:H109)", "Sales", "J2"))
    q("=SUMIFS(H2:H109, G2:G109, \"Wholesal\")")
    print("   \"online\" in lower case ->", b.ev('=SUMIFS(H2:H109, G2:G109, "online")', "Sales", "J2"))
    print("   wholesale share of revenue ->",
          b.ev('=SUMIFS(H2:H109, G2:G109, "Wholesale")/SUM(H2:H109)', "Sales", "J2"))
    print("   figure l05-sumifs: =SUMIFS(H2:H11, D2:D11, \"CER1K\", G2:G11, \"Online\") ->",
          b.ev('=SUMIFS(H2:H11, D2:D11, "CER1K", G2:G11, "Online")', "Sales", "J2"))

    print("== countifs")
    q("=COUNTIFS(G2:G109, \"Online\")")
    q("=SUMIFS(E2:E109, G2:G109, \"Online\")")
    for ch in ("Wholesale", "Shop"):
        print(f"   COUNTIFS {ch} ->", b.ev(f'=COUNTIFS(G2:G109, "{ch}")', "Sales", "J2"))
    q("=COUNTIFS(G2:G109, \"Wholesale\", E2:E109, \">=10\")")
    print("   with \"<10\" ->", b.ev('=COUNTIFS(G2:G109, "Wholesale", E2:E109, "<10")', "Sales", "J2"))
    q("=COUNTIFS(C2:C109, \"C00\")")
    q("=COUNTIFS(D2:D12, \"\")", "Customers")
    q("=COUNTIFS(D2:D12, \"<>\")", "Customers")

    print("== averageifs")
    q("=AVERAGEIFS(E2:E109, G2:G109, \"Wholesale\")")
    for ch in ("Online", "Shop"):
        print(f"   AVERAGEIFS bags {ch} ->", b.ev(f'=AVERAGEIFS(E2:E109, G2:G109, "{ch}")', "Sales", "J2"))
    q("=SUMIFS(E2:E109, G2:G109, \"Wholesale\")/COUNTIFS(G2:G109, \"Wholesale\")")
    print("   bags wholesale ->", b.ev('=SUMIFS(E2:E109, G2:G109, "Wholesale")', "Sales", "J2"))
    q("=AVERAGEIFS(E2:E109, D2:D109, \"CER1K\", G2:G109, \"Shop\")")
    q("=AVERAGEIFS(F2:F109, D2:D109, \"CER1K\")")
    q("=SUMIFS(H2:H109, D2:D109, \"CER1K\")/SUMIFS(E2:E109, D2:D109, \"CER1K\")")
    print("   CER1K revenue, bags ->", b.ev('=SUMIFS(H2:H109, D2:D109, "CER1K")', "Sales", "J2"),
          b.ev('=SUMIFS(E2:E109, D2:D109, "CER1K")', "Sales", "J2"))
    print("   average of the three channel averages ->", b.ev(
        '=(AVERAGEIFS(E2:E109, G2:G109, "Wholesale")+AVERAGEIFS(E2:E109, G2:G109, "Online")'
        '+AVERAGEIFS(E2:E109, G2:G109, "Shop"))/3', "Sales", "J2"))
    q("=AVERAGE(E2:E109)")

    print("== criteria")
    q("=SUMIFS(H2:H109, G2:G109, \"<>Wholesale\")")
    q("=SUMIFS(E2:E109, D2:D109, \"*250\")")
    q("=SUMIFS(E2:E109, D2:D109, \"*1K\")")
    print("   DATE(2026,1,1) ->", b.ev("=DATE(2026,1,1)", "Sales", "J2"))
    q("=SUMIFS(H2:H109, B2:B109, \">=\"&DATE(2026,1,1))")
    q("=SUMIFS(H2:H109, B2:B109, \">=\"&DATE(2025,1,1), B2:B109, \"<\"&DATE(2026,1,1))")
    for j, k in ((datetime.date(2026, 1, 1), datetime.date(2026, 7, 1)),
                 (datetime.date(2025, 1, 1), datetime.date(2025, 7, 1))):
        sh.getCellRangeByName("J1").setValue(serial(j))
        sh.getCellRangeByName("K1").setValue(serial(k))
        print(f"   J1={j} K1={k}:", end=" ")
        q("=SUMIFS(H2:H109, B2:B109, \">=\"&J1, B2:B109, \"<\"&K1)")
    print("   first half 2026 against 2025, change ->", b.ev(
        '=SUMIFS(H2:H109, B2:B109, ">="&DATE(2026,1,1), B2:B109, "<"&DATE(2026,7,1))'
        '-SUMIFS(H2:H109, B2:B109, ">="&DATE(2025,1,1), B2:B109, "<"&DATE(2025,7,1))', "Sales", "J2"),
        b.ev('=SUMIFS(H2:H109, B2:B109, ">="&DATE(2026,1,1), B2:B109, "<"&DATE(2026,7,1))'
             '/SUMIFS(H2:H109, B2:B109, ">="&DATE(2025,1,1), B2:B109, "<"&DATE(2025,7,1))-1', "Sales", "J2"))
    q("=SUMIFS(H2:H109, B2:B109, \">=J1\")")
    print("   channel x year revenue and sales:")
    for ch in ("Online", "Wholesale", "Shop"):
        for y in (2025, 2026):
            c = f'G2:G109, "{ch}", B2:B109, ">="&DATE({y},1,1), B2:B109, "<"&DATE({y + 1},1,1)'
            print(f"     {ch} {y}:", b.ev(f"=SUMIFS(H2:H109, {c})", "Sales", "J2"),
                  b.ev(f"=COUNTIFS({c})", "Sales", "J2"))

    print("== summary-grid")
    b.doc.Sheets.insertNewByName("Report", b.doc.Sheets.getCount())
    rp = b.sheet("Report")
    rp.getCellRangeByName("A2").setString("Product")
    codes = ["SUL250", "CER250", "MOG250", "DEC250", "SUL1K", "CER1K"]
    for i, c in enumerate(codes):
        rp.getCellByPosition(0, 2 + i).setString(c)
    grid = quoted(L, '=SUMIFS(Sales!$E$2:$E$109, Sales!$D$2:$D$109, $A3, Sales!$B$2:$B$109, ">="&B$2, '
                     'Sales!$B$2:$B$109, "<"&EDATE(B$2, 1))')
    b.set("Report", "B3", calc(grid))
    src = rp.getCellRangeByName("B3").getRangeAddress()
    for r in range(3, 9):
        for c in "BCD":
            if (r, c) != (3, "B"):
                rp.copyRange(rp.getCellRangeByName(f"{c}{r}").getCellAddress(), src)
    for r in range(3, 9):
        b.set("Report", f"E{r}", f"=SUM(B{r}:D{r})")
    for c in "BCDE":
        b.set("Report", f"{c}9", f"=SUM({c}3:{c}8)")
    for y in (2025, 2026):
        for i, m in enumerate((1, 2, 3)):
            rp.getCellByPosition(1 + i, 1).setValue(serial(datetime.date(y, m, 1)))
        print(f"   {y} Q1:")
        for r in range(3, 10):
            print("    ", [b.value("Report", f"{c}{r}") for c in "ABCDE"])
    for i, m in enumerate((1, 2, 3)):
        rp.getCellByPosition(1 + i, 1).setValue(serial(datetime.date(2025, m, 1)))
    q('=SUMIFS(Sales!E2:E109, Sales!B2:B109, ">="&DATE(2025,1,1), Sales!B2:B109, "<"&DATE(2025,4,1))',
      "Report", "J1")
    # One dollar sign missing: A3 instead of $A3, filled right to C3.
    b.set("Report", "B3", calc(grid.replace("$A3", "A3")))
    rp.copyRange(rp.getCellRangeByName("C3").getCellAddress(), rp.getCellRangeByName("B3").getRangeAddress())
    print("   with A3 for $A3, C3 reads", rp.getCellRangeByName("C3").getFormula(), "->", b.value("Report", "C3"))
finally:
    b.close()
