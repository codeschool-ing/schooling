#!/usr/bin/env python3
"""Lesson 1: the checks a student runs after pasting, and the serial number
behind a date."""
from engine import Book, quoted

L = "le-drcqf3q5"
b = Book()
try:
    for f in ["=COUNTA(A:A)", "=SUM(E:E)", "=COUNT(B:B)"]:
        print(f"Sales!J1 {f}: {b.ev(quoted(L, f), 'Sales', 'J1')}")
    print(f"Products!J1 =COUNTA(A:A): {b.ev('=COUNTA(A:A)', 'Products', 'J1')}")
    print(f"Customers!J1 =COUNTA(A:A): {b.ev('=COUNTA(A:A)', 'Customers', 'J1')}")
    print(f"Sales!B2 as a number: {b.value('Sales', 'B2')}")
    for f in ["=ISNUMBER(B2)", "=ISNUMBER(D2)", "=ISTEXT(D2)"]:
        print(f"Sales!J2 {f}: {b.ev(quoted(L, f), 'Sales', 'J2')}")
    print(f"Customers =COUNTBLANK(D2:D12): {b.ev(quoted(L, '=COUNTBLANK(D2:D12)'), 'Customers', 'J1')}")
    # A number typed as text: the cell holds the characters 14, and SUM skips it.
    b.sheet("Sales").getCellRangeByName("E2").setString("14")
    print(f"with E2 typed as text, =SUM(E:E): {b.ev('=SUM(E:E)', 'Sales', 'J1')}")
    print(f"with E2 typed as text, =COUNT(E:E): {b.ev(quoted(L, '=COUNT(E:E)'), 'Sales', 'J1')}")
finally:
    b.close()
