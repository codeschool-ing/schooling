#!/usr/bin/env python3
"""Lesson 3: comparisons, IF and IFS, AND/OR/NOT, IFERROR and flag columns.

Each formula the lesson prints goes into J2 (or the cell the lesson names),
is filled down to J109 the way the fill handle fills it, and the column is
counted. Counting is done here with COUNTIF, which the lesson only names.

TWO NUMBERS COME FROM `engine.xl`, NOT FROM CALC, because Calc and Excel
differ on them: a logical value is a number in Calc, so `=4<=E2<10` there
compares 1 with 10 and `SUM` over a column of TRUE adds it up. Excel ranks a
logical value above every number and skips logical values in a range, and
`xl` (the Excel-compatible calculator lab.sh pins) does what Excel does.
`xl` runs first, because the UNO bridge Calc needs replaces Python's import
machinery in a way that `formulas` cannot load under.
"""
from engine import Book, quoted, table_cells, xl
from calcref import calc, excelish

L = "le-s4cnwxmz"

# --- Excel's semantics, from the calculator -------------------------------
c = table_cells("Sales")
for r in range(2, 110):
    c[("Sales", f"J{r}")] = c[("Sales", f"E{r}")] >= 10   # the flag as =E2>=10
quoted(L, "=4<=E2<10")
print("=4<=E2<10 on rows with", {c[("Sales", f"E{r}")] for r in (2, 4, 8, 13)}, "bags:",
      {xl(c, f"=4<=Sales!E{r}<10") for r in (2, 4, 8, 13)})
quoted(L, "=SUM(J2:J109)")
print("J holding =E2>=10: =SUM(J2:J109) ->", xl(c, "=SUM(Sales!J2:J109)"))
quoted(L, "=COUNTIF(J2:J109,TRUE)")
print("J holding =E2>=10: =COUNTIF(J2:J109,TRUE) ->", xl(c, "=COUNTIF(Sales!J2:J109,TRUE)"))
print("=IF(E4>=10,\"Large\") on 1 bag ->", xl(c, '=IF(Sales!E4>=10,"Large")'))
print("IFS with no TRUE pair, 1 bag ->", xl(c, '=IFS(Sales!E4>=10,"Large",Sales!E4>=4,"Medium")'))

# --- Calc -----------------------------------------------------------------
b = excelish(Book())


def ev(f, addr="Z1", check=True):
    b.set("Sales", addr, calc(quoted(L, f) if check else f))
    return b.value("Sales", addr)


def col(f, letter="J"):
    b.set("Sales", f"{letter}2", calc(quoted(L, f)))
    b.fill("Sales", f"{letter}2", f"{letter}109")


def count(what, letter="J"):
    w = "TRUE()" if what is True else f'"{what}"'
    return b.ev(f"=COUNTIF({letter}2:{letter}109;{w})", "Sales", "Z9")


def tf(v):
    return {1: "TRUE", 0: "FALSE"}.get(v, v)


try:
    b.put("Sales", [["Revenue"]], 0, 7)
    b.set("Sales", "H2", "=E2*F2")
    b.fill("Sales", "H2", "H109")
    # comparisons, on row 2
    for f in ['=G2="Wholesale"', '=D2<>"CER1K"', "=F2>100", "=B2<DATE(2026,1,1)", "=E2>=10", "=E2<=10",
              '=G2="wholesale"', '=EXACT(G2,"wholesale")', "=B2>=DATE(2026,1,1)", '="14"=14',
              '="Online"<"Shop"']:
        print(f, "->", tf(ev(f)))
    # IF
    col('=IF(G2="Wholesale","Trade","Retail")')
    print("J2", b.value("Sales", "J2"), "| Trade rows", count("Trade"), "| Wholesale rows",
          b.ev('=COUNTIF(G2:G109;"Wholesale")', "Sales", "Z9"))
    col('=IF(G2="Wholesale",H2,0)')
    print("wholesale revenue =SUM(J2:J109):", ev("=SUM(J2:J109)"), "of", b.ev("=SUM(H2:H109)", "Sales", "Z2"))
    quoted(L, '=IF(E2>=10,"Large")')
    for f in ['=IF(E2>=10,"Large",IF(E2>=4,"Medium","Small"))',
              '=IF(E2>=4,"Medium",IF(E2>=10,"Large","Small"))',
              '=IFS(E2>=10,"Large",E2>=4,"Medium",TRUE,"Small")']:
        col(f)
        n = [count(x) for x in ("Large", "Medium", "Small")]
        print(f, "Large/Medium/Small", n, "sum", sum(n), "| row 2 (14 bags):", b.value("Sales", "J2"))
    # AND, OR, NOT
    col('=AND(G2="Wholesale",E2<10)')
    print('=AND(G2="Wholesale",E2<10) row 2:', tf(b.value("Sales", "J2")), "| TRUE rows", count(True))
    col("=AND(E2>=4,E2<10)")
    print("=AND(E2>=4,E2<10) TRUE rows", count(True))
    col('=OR(D2="DEC250",D2="MOG250")')
    print('=OR(D2="DEC250",D2="MOG250") TRUE rows', count(True))
    col('=NOT(G2="Online")')
    a = count(True)
    col('=G2<>"Online"')
    print('=NOT(G2="Online") TRUE rows', a, '| =G2<>"Online" TRUE rows', count(True))
    col('=NOT(OR(D2="DEC250",D2="MOG250"))')
    print("NOT(OR(...)) TRUE rows", count(True))
    col('=IF(AND(G2="Wholesale",E2<10),"Small trade order","")')
    print("Small trade order rows", count("Small trade order"))
    col('=AND(G2="Wholesale",E2>=10)')
    a = count(True)
    col("=E2>=10")
    print('=AND(G2="Wholesale",E2>=10) TRUE rows', a, "| =E2>=10 TRUE rows", count(True))
    # IFERROR
    col("=H2/E2")
    print("=H2/E2 J2", b.value("Sales", "J2"), "| rows where it differs from Price:",
          b.ev("=SUMPRODUCT(J2:J109<>F2:F109)", "Sales", "Z9"))
    b.set("Sales", "J110", "=H110/E110")
    print("J110 =H110/E110 on the empty row:", b.value("Sales", "J110"))
    print('=IFERROR(H110/E110,"") empty row:', repr(ev('=IFERROR(H110/E110,"")', "J110")))
    b.sheet("Sales").getCellRangeByName("E110").setString("5 bags")
    print("E110 = '5 bags': =H110/E110", ev("=H110/E110", "J110", False),
          '| IFERROR', repr(ev('=IFERROR(H110/E110,"")', "J110")),
          '| IF(E110="",...)', ev('=IF(E110="","",H110/E110)', "J110"))
    b.sheet("Sales").getCellRangeByName("E110").setString("")
    print('=IF(E110="","",H110/E110) empty row:', repr(ev('=IF(E110="","",H110/E110)', "J110")))
    print('=IFNA(H110/E110,"") empty row:', ev('=IFNA(H110/E110,"")', "J110"))
    b.sheet("Sales").getCellRangeByName("J110").setString("")
    print("=H2/E2O:", ev("=H2/E2O", check=False), "| =IFERROR(H2/E2O,0):", ev("=IFERROR(H2/E2O,0)"))
    # flags
    b.put("Sales", [["Big", "In 2026", "Both", "Big revenue"]], 0, 9)
    col("=IF(E2>=10,1,0)", "J")
    col("=IF(B2>=DATE(2026,1,1),1,0)", "K")
    col("=J2*K2", "L")
    b.set("Sales", "M2", "=H2*J2")
    b.fill("Sales", "M2", "M109")
    for f in ["=SUM(J2:J109)", "=AVERAGE(J2:J109)", "=SUM(K2:K109)", "=SUM(L2:L109)"]:
        print(f, "->", ev(f, "O1"))
    print("big revenue =SUM(M2:M109):", b.ev("=SUM(M2:M109)", "Sales", "O1"), "of",
          b.ev("=SUM(H2:H109)", "Sales", "O1"))
finally:
    b.close()
