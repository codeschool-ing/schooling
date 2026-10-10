#!/usr/bin/env python3
"""Lesson 17: every number on Café Serra's dashboard.

The dashboard reads the measures of lesson 16 out of the data model through
pivot tables, and neither has an engine outside Excel. So each measure is
computed here in plain Python from the sales the student pasted, for every
state of the slicer and the timeline the lesson describes. Revenue LY is
SAMEPERIODLASTYEAR over whole months: the same dates one year earlier.

The lesson then asks the student to check the dashboard's cells with
formulas on the `Sales` table, and those are computed by Calc, exactly as
printed, over a table named `Sales` holding lesson 2's `Revenue` column.
"""
import collections
import datetime

from engine import Book, date_of, quoted, rows

L = "le-c47zzck2"
D = datetime.date
SALES = rows("Sales")[1:]  # Sale, Date, Customer, Product, Bags, Price, Channel


def pick(start, end, channel=None):
    return [s for s in SALES if start <= s[1] <= end and (channel is None or s[6] == channel)]


def measures(start, end, channel=None):
    now = pick(start, end, channel)
    ly = pick(start.replace(year=start.year - 1), end.replace(year=end.year - 1), channel)
    rev = sum(s[4] * s[5] for s in now)
    rev_ly = sum(s[4] * s[5] for s in ly)
    bags, bags_ly = sum(s[4] for s in now), sum(s[4] for s in ly)
    return {
        "Total Revenue": rev, "Revenue LY": rev_ly,
        "Revenue YoY %": round(100 * (rev - rev_ly) / rev_ly, 1) if rev_ly else None,
        "Bags Sold": bags, "Bags Sold LY": bags_ly,
        "Bags change %": round(100 * (bags - bags_ly) / bags_ly, 1) if bags_ly else None,
        "Sales Count": len(now), "Sales Count LY": len(ly),
        "Average Sale": round(rev / len(now), 2) if now else None,
        "Average Sale LY": round(rev_ly / len(ly), 2) if ly else None,
        "Average Sale change %": round(100 * ((rev / len(now)) / (rev_ly / len(ly)) - 1), 1)
        if now and ly else None,
    }


H1 = (D(2026, 1, 1), D(2026, 6, 30))
Q1 = (D(2026, 1, 1), D(2026, 3, 31))
Q2 = (D(2026, 4, 1), D(2026, 6, 30))

print("== the KPI row, timeline January to June 2026")
for ch in (None, "Wholesale", "Online", "Shop"):
    print(f"  channel {ch or 'all'}: {measures(*H1, ch)}")
print("== the timeline moved")
print(f"  Jan-Mar 2026: {measures(*Q1)}")
print(f"  Apr-Jun 2026: {measures(*Q2)}")

full25 = sum(s[4] * s[5] for s in SALES if s[1].year == 2025)
print(f"== the wrong comparison: Jan-Jun 2026 {measures(*H1)['Total Revenue']} against all of 2025 {full25}: "
      f"{round(100 * (measures(*H1)['Total Revenue'] - full25) / full25, 1)}%")

print("== the monthly chart: revenue per month, 2025 and 2026")
for m in range(1, 7):
    a = sum(s[4] * s[5] for s in SALES if s[1].year == 2025 and s[1].month == m)
    b = sum(s[4] * s[5] for s in SALES if s[1].year == 2026 and s[1].month == m)
    print(f"  month {m}: 2025 {a}  2026 {b}")

print("== the breakdowns, January to June, 2026 against 2025")
for key, idx in (("channel", 6), ("product", 3)):
    now = collections.Counter()
    ly = collections.Counter()
    for s in SALES:
        if s[1].month <= 6 and s[1].year == 2026:
            now[s[idx]] += s[4] * s[5]
        if s[1].month <= 6 and s[1].year == 2025:
            ly[s[idx]] += s[4] * s[5]
    for k in sorted(set(now) | set(ly), key=lambda k: -now[k]):
        print(f"  {key} {k}: 2026 {now[k]}  2025 {ly[k]}  change {now[k] - ly[k]}")

print("== the checks the lesson prints, computed by Calc over table Sales")
b = Book()
try:
    sh = b.sheet("Sales")
    sh.getCellRangeByName("H1").setString("Revenue")
    b.set("Sales", "H2", "=E2*F2")
    b.fill("Sales", "H2", "H109")
    b.doc.DatabaseRanges.addNewByName("Sales", sh.getCellRangeByName("A1:H109").getRangeAddress())
    b.doc.DatabaseRanges.getByName("Sales").ContainsHeader = True
    for f in [
        '=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<"&DATE(2026,7,1))',
        '=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2025,1,1), Sales[Date], "<"&DATE(2025,7,1))',
        '=COUNTIFS(Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<"&DATE(2026,7,1))',
        '=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale", Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<"&DATE(2026,7,1))',
    ]:
        print(f"  {f}: {b.ev(quoted(L, f))}")
    v = b.ev(quoted(L, "=MAX(Sales[Date])"))
    print(f"  =MAX(Sales[Date]): {v} = {date_of(v)}")
    print(f"  =COUNTA(Sales[Sale]): {b.ev('=COUNTA(Sales[Sale])')}")
finally:
    b.close()

print("== against lesson 14's budget, January to June 2026")
import os
import re as _re
_t = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lessons", "le-sapssdn5", "unpivot.md"),
          encoding="utf-8").read()
_csv = _re.search(r"```\n(Channel,2026-01.*?)\n```", _t, _re.S).group(1).split("\n")
_months = _csv[0].split(",")[1:]
budget = {}
for line in _csv[1:]:
    f = line.split(",")
    budget[f[0]] = sum(int(v) for m, v in zip(_months, f[1:]) if m <= "2026-06")
tot_b = sum(budget.values())
tot_a = measures(*H1)["Total Revenue"]
print(f"  total: budget {tot_b}, actual {tot_a}, {100 * tot_a / tot_b:.1f}% of budget, "
      f"{100 * (tot_a - tot_b) / tot_b:+.1f}%")
for ch, bud in budget.items():
    act = measures(*H1, ch)["Total Revenue"]
    print(f"  {ch}: budget {bud}, actual {act}, {100 * act / bud:.1f}% of budget")
