#!/usr/bin/env python3
"""Lesson 6: cleaning the old system's export with text and date functions,
and taking the dates of Sales apart.

The export is read out of the lesson (section `messy-list`), like the data of
lesson 1, and typed the way Excel types a pasted value: `00841` becomes the
number 841, `6 un` stays text, and spaces inside a field are kept."""
import os
import re

import engine
from engine import Book, quoted

L = "le-taj9583x"


def export():
    text = open(os.path.join(engine.LESSONS, L, "messy-list.md"), encoding="utf-8").read()
    body = next(b for b in re.findall(r"```\n(.*?)\n```", text, re.S) if b.startswith("Order\t"))
    lines = body.split("\n")
    return [lines[0].split("\t")] + [[engine.parse(f) for f in l.split("\t")] for l in lines[1:]]


def calc(f):
    return re.sub(r"\b([A-Za-z]+)!", r"$\1.", f)


b = Book(extra={"Old export": export()})
# Excel compares text ignoring case (`="a"="A"` is TRUE); a new Calc document
# compares it case-sensitively unless told otherwise.
b.doc.IgnoreCase = True
try:
    O = "Old export"

    def q(f, sheet=O, addr="P1", show=None):
        v = b.ev(calc(quoted(L, f)), sheet, addr)
        if show == "bool":
            v = "TRUE" if v == 1 else "FALSE"
        print(f"{sheet}!{addr} {f}  ->  {v!r}")
        return v

    def fill(sheet, col, formula, last=13):
        b.set(sheet, f"{col}2", calc(quoted(L, formula)))
        b.fill(sheet, f"{col}2", f"{col}{last}")
        return [b.value(sheet, f"{col}{r}") for r in range(2, last + 1)]

    print("== messy-list")
    print("   A2 as pasted ->", b.value(O, "A2"), "  B2 ->", b.value(O, "B2"))
    q("=COUNT(E2:E13)")
    q("=SUM(E2:E13)")
    q('=COUNTIFS(F2:F13, "Wholesale")')
    print("   2 December 2024 as a day number ->", b.ev("=DATE(2024,12,2)", O, "P1"))

    print("== trim-and-case")
    q("=LEN(C3)")
    q("=LEN(TRIM(C3))")
    print("   I:", fill(O, "I", "=TRIM(C2)"))
    print("   J:", fill(O, "J", "=PROPER(TRIM(F2))"))
    q('=COUNTIFS(J2:J13, "Wholesale")')
    for ch in ("Online", "Shop"):
        print(f"   COUNTIFS J {ch} ->", b.ev(f'=COUNTIFS(J2:J13, "{ch}")', O, "P1"))
    q("=PROPER(TRIM(C9))")
    q("=MATCH(TRIM(C3), Customers!B2:B12, 0)")
    q("=MATCH(TRIM(C7), Customers!B2:B12, 0)")
    print("   every row, MATCH(TRIM(C)) ->",
          [b.ev(calc(f"=MATCH(TRIM(C{r}), Customers!B2:B12, 0)"), O, "P1") for r in range(2, 14)])
    print("   EXACT(C2, C13) ->", b.ev("=EXACT(C2, C13)", O, "P1"), " EXACT(C2, C3) ->",
          b.ev("=EXACT(C2, C3)", O, "P1"), " =C2=C3 ->", b.ev("=C2=C3", O, "P1"),
          " =C2=TRIM(C3) ->", b.ev("=C2=TRIM(C3)", O, "P1"), " (1 is TRUE, 0 is FALSE)")

    print("== split-and-join")
    q('=FIND(" - ", D2)')
    print("   K:", fill(O, "K", '=UPPER(LEFT(D2, FIND(" - ", D2)-1))'))
    q('=MID(D2, FIND(" - ", D2)+3, 100)')
    q('=K2&" x "&E2')
    # TEXTBEFORE and TEXTAFTER are not in this Calc; the prose says what they
    # return, and this is the definition applied to D2.
    d2 = b.value(O, "D2")
    print("   TEXTBEFORE(D2, \" - \"), by definition ->", d2.split(" - ", 1)[0],
          "  TEXTAFTER ->", d2.split(" - ", 1)[1])

    print("== numbers-as-text")
    print("   L:", fill(O, "L", '=VALUE(SUBSTITUTE(E2, " un", ""))'))
    q("=COUNT(L2:L13)")
    q("=SUM(L2:L13)")
    print("   =--E2 ->", b.ev("=--E2", O, "P1"), "  =--E3 ->", b.ev("=--E3", O, "P1"))
    b.sheet(O).getCellRangeByName("P8").setString("7 bags")
    print("   drill: a quantity written 7 bags, =VALUE(SUBSTITUTE(P8, \" un\", \"\")) ->",
          b.ev('=VALUE(SUBSTITUTE(P8, " un", ""))', O, "P9"))
    print("   M:", fill(O, "M", '=TEXT(A2, "00000")'))
    print("   bags by channel, cleaned:", [(c, b.ev(f'=SUMIFS(L2:L13, J2:J13, "{c}")', O, "P1"))
                                         for c in ("Wholesale", "Online", "Shop")])
    print("   revenue of the export, cleaned ->", b.ev("=SUMPRODUCT(L2:L13, G2:G13)", O, "P1"))

    print("== dates")
    print("   N:", fill(O, "N", "=DATE(LEFT(B2,4), MID(B2,5,2), RIGHT(B2,2))"))
    q("=COUNT(N2:N13)")
    q("=MIN(N2:N13)")
    q("=MAX(N2:N13)")
    print("   as dates:", engine.date_of(b.value(O, "N2")), "..", engine.date_of(b.ev("=MAX(N2:N13)", O, "P1")))
    for f in ["=YEAR(B2)", "=MONTH(B2)", "=DAY(B2)", "=DATE(YEAR(B2), MONTH(B2), 1)", "=EOMONTH(B2, 0)",
              "=DAY(EOMONTH(B2, 0))", "=B109-B2"]:
        q(f, "Sales", "J2")
    print("   45658, 45688 as dates:", engine.date_of(45658), engine.date_of(45688),
          "  B109:", b.value("Sales", "B109"), engine.date_of(b.value("Sales", "B109")))
    # The apostrophe makes the cell text; the lab types the text itself.
    b.sheet(O).getCellRangeByName("P6").setString("03/12/2024")
    v = q("=DATEVALUE(P6)", O, "P7")
    print("     this Calc reads month first (en-US):", engine.date_of(v))
    v = q("=DATE(RIGHT(P6,4), MID(P6,4,2), LEFT(P6,2))", O, "P7")
    print("     ->", engine.date_of(v))
    for tx in ("03/12/2024", "05/12/2024", "10/12/2024", "16/12/2024", "23/12/2024"):
        b.sheet(O).getCellRangeByName("P6").setString(tx)
        v = b.ev("=DATEVALUE(P6)", O, "P7")
        print(f"   figure l06-dates: DATEVALUE({tx}) month first ->", v,
              engine.date_of(v) if isinstance(v, int) else "(not a date)")
finally:
    b.close()
