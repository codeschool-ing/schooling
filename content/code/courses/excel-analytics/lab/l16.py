#!/usr/bin/env python3
"""Lesson 16: DAX measures, computed the way the model evaluates them.

NOTHING HERE IS DAX. No DAX engine runs outside Excel, so each measure the
lesson defines is computed in plain Python as the model would compute it in a
pivot cell: the cell's filters (a row label, a column label, a slicer) pick
the rows of the dimension tables, the relationships of lesson 15 carry that
selection to Sales, and the measure's expression runs over the rows that are
left. CALCULATE replaces the filter on the columns it names; ALL removes it;
TOTALYTD and SAMEPERIODLASTYEAR move the Calendar dates of the cell.

What a spreadsheet CAN check is checked in Calc, with SUMIFS and COUNTIFS of
lesson 5 over the Revenue column of lesson 2: each formula is printed in the
lesson's `checking` section, and this script refuses one it does not print.
"""
import datetime
from collections import defaultdict

from engine import Book, quoted, rows

import re


def calc(formula):
    """Excel's `Sheet!A1:B2` as Calc's `$Sheet.A1:B2`; the rest is unchanged."""
    return re.sub(r"\b([A-Za-z]+)!([A-Z]+[0-9]+(?::[A-Z]+[0-9]+)?)", r"$\1.\2", formula)


L = "le-gc2hdv59"


def table(name):
    r = rows(name)
    return [dict(zip(r[0], x)) for x in r[1:]]


sales, products = table("Sales"), table("Products")
P = {p["Code"]: p for p in products}
for s in sales:
    s["Revenue"] = s["Bags"] * s["Price"]
    s["Origin"] = P[s["Product"]]["Origin"]
    s["Unit cost"] = P[s["Product"]]["Unit cost"]

CAL = []
d = datetime.date(2025, 1, 1)
while d <= datetime.date(2026, 12, 31):
    CAL.append(d)
    d += datetime.timedelta(days=1)


# A filter context: a predicate on a sale (from dimension columns or Sales
# columns) plus the set of Calendar dates visible.
def ctx(dates=None, **cols):
    return {"dates": set(dates) if dates is not None else set(CAL), "cols": cols}


def year(y):
    return [x for x in CAL if x.year == y]


def month(y, m):
    return [x for x in CAL if x.year == y and x.month == m]


def visible(c):
    out = []
    for s in sales:
        if s["Date"] not in c["dates"]:
            continue
        if all(s[k] == v for k, v in c["cols"].items()):
            out.append(s)
    return out


def total_revenue(c): return sum(s["Revenue"] for s in visible(c))
def bags_sold(c): return sum(s["Bags"] for s in visible(c))
def sales_count(c): return len(visible(c))
def customers_buying(c): return len({s["Customer"] for s in visible(c)})


def divide(a, b):
    return None if not b else a / b


def average_price(c): return divide(total_revenue(c), bags_sold(c))
def total_cost(c): return sum(s["Bags"] * s["Unit cost"] for s in visible(c))
def gross_margin(c): return total_revenue(c) - total_cost(c)
def margin_pct(c): return divide(gross_margin(c), total_revenue(c))


def calculate(measure, c, **override):
    n = {"dates": c["dates"], "cols": dict(c["cols"])}
    for k, v in override.items():
        if v is ALL:
            n["cols"].pop(k, None)
        else:
            n["cols"][k] = v
    return measure(n)


ALL = object()


def online_revenue(c): return calculate(total_revenue, c, Channel="Online")
def channel_share(c): return divide(total_revenue(c), calculate(total_revenue, c, Channel=ALL))


def ytd(c):
    last = max(c["dates"])
    dates = [x for x in CAL if x.year == last.year and x <= last]
    return total_revenue({"dates": set(dates), "cols": c["cols"]})


def sply(c):
    shifted = set()
    for x in c["dates"]:
        try:
            shifted.add(x.replace(year=x.year - 1))
        except ValueError:
            pass
    shifted &= set(CAL)
    return total_revenue({"dates": shifted, "cols": c["cols"]})


def yoy(c):
    ly = sply(c)
    return divide(total_revenue(c) - ly, ly) if ly else None


def pct(x):
    return "BLANK" if x is None else f"{100 * x:.1f}%"


print("== the whole model, no filter")
c = ctx()
print("Total Revenue", total_revenue(c), "Bags Sold", bags_sold(c), "Sales Count", sales_count(c),
      "Customers Buying", customers_buying(c))
print("Average Price", round(average_price(c), 2), "Total Cost", total_cost(c),
      "Gross Margin", gross_margin(c), "Margin %", pct(margin_pct(c)))

print("== by Calendar[Year]")
for y in (2025, 2026):
    c = ctx(year(y))
    print(y, "Revenue", total_revenue(c), "Sales", sales_count(c), "Bags", bags_sold(c),
          "Customers Buying", customers_buying(c), "Avg price", round(average_price(c), 2),
          "Margin %", pct(margin_pct(c)), "Gross Margin", gross_margin(c))

print("== by Sales[Channel]")
for ch in ("Online", "Shop", "Wholesale"):
    c = ctx(Channel=ch)
    print(ch, "Revenue", total_revenue(c), "Bags", bags_sold(c), "Sales", sales_count(c), "Customers Buying", customers_buying(c),
          "Online Revenue", online_revenue(c), "Channel Share", pct(channel_share(c)),
          "Avg price", round(average_price(c), 2), "Margin %", pct(margin_pct(c)))
print("grand total row: Online Revenue", online_revenue(ctx()), "Channel Share", pct(channel_share(ctx())))
print("sum of the three Customers Buying rows:",
      sum(customers_buying(ctx(Channel=ch)) for ch in ("Online", "Shop", "Wholesale")))

print("== Channel x Year: Total Revenue and Channel Share")
for y in (2025, 2026):
    for ch in ("Online", "Shop", "Wholesale"):
        c = ctx(year(y), Channel=ch)
        print(y, ch, total_revenue(c), pct(channel_share(c)), "online rev", online_revenue(c))

print("== the cell Origin=Cerrado, Year=2025 (the filter-context figure)")
c = ctx(year(2025), Origin="Cerrado")
v = visible(c)
print("rows", len(v), "products", sorted({s["Product"] for s in v}), "Total Revenue", total_revenue(c))
print("first rows:", [(s["Sale"], str(s["Date"]), s["Product"], s["Revenue"]) for s in v[:4]])
print("CER1K 2025:", total_revenue(ctx(year(2025), Product="CER1K")),
      "CER250 2025:", total_revenue(ctx(year(2025), Product="CER250")))

print("== average price: AVERAGE(Sales[Price]) against the ratio of sums")
for code in ("CER1K", "SUL1K", None):
    vv = [s for s in sales if code is None or s["Product"] == code]
    avg = sum(s["Price"] for s in vv) / len(vv)
    rat = sum(s["Revenue"] for s in vv) / sum(s["Bags"] for s in vv)
    print(code or "all", "rows", len(vv), "AVERAGE(Price)", round(avg, 2), "Revenue/Bags", round(rat, 2))

for g in ("1K", "250"):
    vv = [s for s in sales if s["Product"].endswith(g)]
    print("bags per sale,", g, round(sum(s["Bags"] for s in vv) / len(vv), 2), "rows", len(vv),
          "bags", sum(s["Bags"] for s in vv), "avg price", round(sum(s["Price"] for s in vv) / len(vv), 2))
print("== a per-row Margin % column summed by a pivot")
row_pct = [(s["Revenue"] - s["Bags"] * s["Unit cost"]) / s["Revenue"] for s in sales]
print("sum of 108 row percentages:", f"{100 * sum(row_pct):.1f}%", "average:", f"{100 * sum(row_pct) / len(row_pct):.1f}%")
print("the measure over all rows:", pct(margin_pct(ctx())))

print("== DISTINCTCOUNT by Customers in 2026 / channel")
for y in (2025, 2026):
    for ch in ("Online", "Shop", "Wholesale"):
        print(y, ch, customers_buying(ctx(year(y), Channel=ch)))
print("customers who bought in 2026:", sorted({s["Customer"] for s in sales if s["Date"].year == 2026}))
print("customers who bought in 2025:", sorted({s["Customer"] for s in sales if s["Date"].year == 2025}))

print("== time intelligence by month")
for y in (2025, 2026):
    for m in range(1, 13):
        c = ctx(month(y, m))
        print(y, m, "Rev", total_revenue(c), "YTD", ytd(c), "LY", sply(c), "YoY", pct(yoy(c)))
print("== by year")
for y in (2025, 2026):
    c = ctx(year(y))
    print(y, "Rev", total_revenue(c), "YTD", ytd(c), "LY", sply(c), "YoY", pct(yoy(c)))
print("== a slicer on Calendar[Month] 1 to 6")
for y in (2025, 2026):
    c = ctx([x for x in year(y) if x.month <= 6])
    print(y, "Jan-Jun Rev", total_revenue(c), "LY", sply(c), "YoY", pct(yoy(c)))
print("== quarters")
for y in (2025, 2026):
    for q in range(1, 5):
        c = ctx([x for x in year(y) if (x.month + 2) // 3 == q])
        print(y, f"Q{q}", total_revenue(c), "LY", sply(c), "YoY", pct(yoy(c)))
print("== Online, Jan-Jun, by year")
for y in (2025, 2026):
    c = ctx([x for x in year(y) if x.month <= 6], Channel="Online")
    print(y, "Online Jan-Jun", total_revenue(c), "LY", sply(c), "YoY", pct(yoy(c)))

b = Book()
try:
    sh = b.sheet("Sales")
    sh.getCellRangeByName("H1").setString("Revenue")
    b.set("Sales", "H2", "=E2*F2")
    b.fill("Sales", "H2", "H109")
    print("== Calc, the checks the lesson prints")
    for f in [
        '=SUMIFS(Sales!H2:H109,Sales!G2:G109,"Online",Sales!B2:B109,">="&DATE(2026,1,1))',
        '=SUMIFS(Sales!H2:H109,Sales!B2:B109,">="&DATE(2025,1,1),Sales!B2:B109,"<"&DATE(2025,7,1))',
        '=SUMIFS(Sales!H2:H109,Sales!B2:B109,">="&DATE(2026,1,1),Sales!B2:B109,"<"&DATE(2026,4,1))',
        '=COUNTIFS(Sales!B2:B109,">="&DATE(2026,1,1))',
        '=SUM(Sales!H2:H109)',
    ]:
        print(f, "->", b.ev(calc(quoted(L, f))))
    print("python: Online 2026", total_revenue(ctx(year(2026), Channel="Online")),
          "| Jan-Jun 2025", total_revenue(ctx([x for x in year(2025) if x.month <= 6])),
          "| YTD Mar 2026", ytd(ctx(month(2026, 3))),
          "| Sales Count 2026", sales_count(ctx(year(2026))))
finally:
    b.close()
