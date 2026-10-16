#!/usr/bin/env python3
"""Lesson 2: the Revenue column, shares of the total, a grid of discounted
prices, defined names, and three ways a reference breaks.

Every formula is the lesson's own (`quoted`), put into the cell the lesson
names and copied the way the fill handle copies it (`Book.fill`, or
`copyRange` across), so a relative reference moves here as it moves in Excel.
"""
from engine import Book, quoted
from calcref import calc, excelish, name

L = "le-433n908v"
b = excelish(Book())


def put(sheet, addr, formula):
    b.set(sheet, addr, calc(quoted(L, formula)))
    return b.value(sheet, addr)


def across(sheet, src, dests):
    sh = b.sheet(sheet)
    a = sh.getCellRangeByName(src).getRangeAddress()
    for d in dests:
        sh.copyRange(sh.getCellRangeByName(d).getCellAddress(), a)


def formula(sheet, addr):
    return b.sheet(sheet).getCellRangeByName(addr).getFormula()


def pct(v):
    return f"{100 * v:.1f}%"


try:
    # relative
    b.put("Sales", [["Revenue"]], 0, 7)
    print("H2 =E2*F2:", put("Sales", "H2", "=E2*F2"))
    b.fill("Sales", "H2", "H109")
    print("H3 holds", formula("Sales", "H3"), "| H109 holds", formula("Sales", "H109"),
          "=", b.value("Sales", "H109"), "| row 109:", [b.value("Sales", f"{c}109") for c in "AEF"])
    print("J1 =SUM(H2:H109):", put("Sales", "J1", "=SUM(H2:H109)"))
    b.sheet("Sales").getCellRangeByName("J1").setString("")
    across("Sales", "H2", ["I2"])
    print("H2 pasted in I2:", formula("Sales", "I2"), "=", b.value("Sales", "I2"))
    b.sheet("Sales").getCellRangeByName("I2").setString("")

    # absolute
    b.put("Sales", [["Share", "", "Total"]], 0, 9)
    print("L2 =SUM(H2:H109):", put("Sales", "L2", "=SUM(H2:H109)"))
    print("J2 =H2/L2:", put("Sales", "J2", "=H2/L2"))
    b.fill("Sales", "J2", "J109")
    print("filled: J3", formula("Sales", "J3"), "=", b.value("Sales", "J3"),
          "| J109 =", b.value("Sales", "J109"))
    print("J2 =H2/$L$2:", pct(put("Sales", "J2", "=H2/$L$2")))
    b.fill("Sales", "J2", "J109")
    print("filled: J3", formula("Sales", "J3"), "=", pct(b.value("Sales", "J3")),
          "| J109 =", pct(b.value("Sales", "J109")))
    print("=SUM(J2:J109):", put("Sales", "N1", "=SUM(J2:J109)"))
    big = b.ev("=MAX(J2:J109)", "Sales", "N2")
    row = 1 + b.ev("=MATCH(MAX(J2:J109);J2:J109;0)", "Sales", "N2")
    print("largest share", pct(big), "on row", row, [b.value("Sales", f"{c}{row}") for c in "ABCDEFGH"])
    print("largest revenue =MAX(H2:H109):", b.ev("=MAX(H2:H109)", "Sales", "N1"))
    b.sheet("Sales").getCellRangeByName("N1").setString("")
    b.sheet("Sales").getCellRangeByName("N2").setString("")
    # the same mistake, with the total inside the formula
    print("K2 =H2/SUM(H2:H109):", pct(put("Sales", "K2", "=H2/SUM(H2:H109)")))
    b.fill("Sales", "K2", "K109")
    print("filled: K3", formula("Sales", "K3"), "=", pct(b.value("Sales", "K3")),
          "| K109", formula("Sales", "K109"), "=", pct(b.value("Sales", "K109")),
          "| column adds to", pct(b.ev("=SUM(K2:K109)", "Sales", "N1")))
    b.sheet("Sales").getCellRangeByName("N1").setString("")
    for r in range(2, 110):
        b.sheet("Sales").getCellRangeByName(f"K{r}").setString("")

    # mixed: the grid on Products
    b.put("Products", [[0.05, 0.1, 0.15]], 0, 8)
    print("I2 =ROUND($F2*(1-I$1),0):", put("Products", "I2", "=ROUND($F2*(1-I$1),0)"))
    across("Products", "I2", [f"{c}{r}" for c in "IJK" for r in range(2, 8) if (c, r) != ("I", 2)])
    grid = [[b.value("Products", f"{c}{r}") for c in "AFIJK"] for r in range(1, 8)]
    for g in grid:
        print("grid", g)
    print("K7 holds", formula("Products", "K7"))
    quoted(L, "=ROUND($F7*(1-K$1),0)")
    # without the dollars, in a spare column with its own 5% above it
    b.put("Products", [[0.05]], 0, 12)
    b.set("Products", "M2", calc(quoted(L, "=ROUND(F2*(1-I1),0)").replace("I1", "M1")))
    across("Products", "M2", ["M3"])
    print("no dollars, copied down: M3", formula("Products", "M3"), "=", b.value("Products", "M3"))
    quoted(L, "=ROUND(F3*(1-I2),0)")
    print("2026 wholesale SUL1K prices paid:",
          sorted({b.value("Sales", f"F{r}") for r in range(2, 110)
                  if b.value("Sales", f"D{r}") == "SUL1K" and b.value("Sales", f"G{r}") == "Wholesale"
                  and b.value("Sales", f"B{r}") >= 46023}))
    print("S1074:", [b.value("Sales", f"{c}75") for c in "ABCDEFG"])

    # names
    name(b, "TotalRevenue", "Sales!$L$2")
    name(b, "Revenue", "Sales!$H$2:$H$109")
    name(b, "Discount", "0.1")
    print("J2 =H2/TotalRevenue:", pct(put("Sales", "J2", "=H2/TotalRevenue")))
    b.fill("Sales", "J2", "J109")
    print("filled: J3 =", pct(b.value("Sales", "J3")), "| J109 =", pct(b.value("Sales", "J109")))
    print("=SUM(Revenue):", put("Sales", "N1", "=SUM(Revenue)"))
    b.sheet("Sales").getCellRangeByName("N1").setString("")
    print("Products =ROUND(F2*(1-Discount),0):", put("Products", "O2", "=ROUND(F2*(1-Discount),0)"))

    # what goes wrong: a row deleted inside the range
    b.set("Sales", "J2", calc(quoted(L, "=H2/$L$2")))
    b.fill("Sales", "J2", "J109")
    print("row 50 before deleting:", [b.value("Sales", f"{c}50") for c in "ABDEFH"])
    b.sheet("Sales").Rows.removeByIndex(49, 1)
    print("after deleting row 50: L2 holds", formula("Sales", "L2"), "=", b.value("Sales", "L2"))
    b.sheet("Sales").Rows.insertByIndex(49, 1)
    b.put("Sales", [["S1049", 45909, "C01", "SUL1K", 9, 116, "Wholesale"]], 49, 0)
    b.set("Sales", "H50", "=E50*F50")
    b.set("Sales", "L2", calc("=SUM(H2:H109)"))
    print("restored: L2 =", b.value("Sales", "L2"), "| B50 is", b.value("Sales", "B50"))
    # a deleted column under an absolute reference
    b.sheet("Sales").Columns.removeByIndex(11, 1)
    print("after deleting column L: J2 =", b.value("Sales", "J2"), "| J3 =", b.value("Sales", "J3"))
    b.sheet("Sales").Columns.insertByIndex(11, 1)
    b.put("Sales", [["Total"]], 0, 11)
    b.set("Sales", "L2", calc("=SUM(H2:H109)"))
    # a circular reference: Calc reports Err:522 where Excel shows 0 and a warning
    print("H110 =SUM(H2:H110):", put("Sales", "H110", "=SUM(H2:H110)"))
    b.sheet("Sales").getCellRangeByName("H110").setString("")
    # a typed number over a formula
    b.sheet("Sales").getCellRangeByName("H50").setValue(1044)
    b.sheet("Sales").getCellRangeByName("E50").setValue(10)
    print("H50 typed 1044, E50 = 10: total", b.value("Sales", "L2"))
    b.set("Sales", "H50", "=E50*F50")
    print("H50 formula again, E50 = 10: H50", b.value("Sales", "H50"), "total", b.value("Sales", "L2"),
          "difference", b.value("Sales", "L2") - 51494)
finally:
    b.close()
