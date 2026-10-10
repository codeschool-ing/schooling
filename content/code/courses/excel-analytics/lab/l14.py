#!/usr/bin/env python3
"""Lesson 14: what each transformation produces, on lesson 13's files, the
budget file this lesson prints, and the Sales and Products tables.

Power Query was not run (pqfiles.py says why). Each function below is one
step of the lesson, applied in Python to the same rows. The one formula the
lesson prints, a SUMIFS that reconciles a grouped total, is put into a Calc
cell like every formula of lessons 1 to 12."""
from collections import Counter, OrderedDict

from calcref import calc
from engine import Book, quoted
from pqfiles import L14, both, en, files, freight, products, sales, split, web_orders

# --- cleaning-steps --------------------------------------------------------
raw = web_orders()
print("WebOrders as lesson 13 left it:", len(raw), "rows")
paid = [r for r in raw if r["Status"] == "paid"]
print("Filtered Rows, Status = paid:", len(paid))
up = [dict(r, SKU=r["SKU"].upper()) for r in paid]
clean = [OrderedDict([("Order", r["Order"]), ("Date", r["Date"]), ("Product", r["SKU"]),
                      ("Bags", r["Qty"]), ("Price", r["Unit price"]),
                      ("Revenue", r["Qty"] * r["Unit price"])]) for r in up]
print("columns after cleaning:", list(clean[0]))
both("clean bags", sum(r["Bags"] for r in clean))
both("clean revenue", sum(r["Revenue"] for r in clean))
both("all 24 rows, bags (no filter)", sum(r["Qty"] for r in raw))
print("distinct products before upper:", sorted({r["SKU"] for r in paid}))
print("distinct products after upper:", sorted({r["Product"] for r in clean}))

# --- merge -------------------------------------------------------------------
prod = {p["Code"]: p for p in products()}


def left_outer(left, right_rows, lkey, rkey):
    out = []
    for l in left:
        m = [r for r in right_rows if r[rkey] == l[lkey]]
        out += [(l, r) for r in m] or [(l, None)]
    return out


plist = list(prod.values())
m = left_outer(clean, plist, "Product", "Code")
print("merge with Products, rows:", len(m), "unmatched:", sum(1 for _, r in m if r is None))
margin = sum(l["Revenue"] - l["Bags"] * r["Unit cost"] for l, r in m)
both("margin, Revenue - Bags x Unit cost", margin)
both("cost", sum(l["Bags"] * r["Unit cost"] for l, r in m))
# Before the uppercase step: Power Query's merge compares text exactly.
m0 = left_outer([dict(r, Product=r["SKU"]) for r in paid], plist, "Product", "Code")
print("merge BEFORE uppercase, unmatched:", [l["Order"] for l, r in m0 if r is None])

fr = freight()
keys_l = [r["Order"] for r in clean]
keys_r = [r["Order"] for r in fr]
inner = [(a, b) for a in keys_l for b in keys_r if a == b]
lo = left_outer(clean, fr, "Order", "Order")
lanti = [k for k in keys_l if k not in keys_r]
ranti = [k for k in keys_r if k not in keys_l]
right_outer = len(inner) + len(ranti)
full = len(inner) + len(lanti) + len(ranti)
print(f"join kinds WebOrders(22) x Freight({len(fr)}): left outer {len(lo)}, right outer {right_outer}, "
      f"full outer {full}, inner {len(inner)}, left anti {len(lanti)} {lanti}, right anti {len(ranti)}")
print("duplicated key in Freight:", [k for k, n in Counter(keys_r).items() if n > 1])
both("revenue summed after left outer with Freight", sum(l["Revenue"] for l, _ in lo))
w2014 = [l for l in clean if l["Order"] == "W2014"][0]
both("W2014 revenue", w2014["Revenue"])
both("freight summed after left outer", sum(r["Freight"] for _, r in lo if r))

fg = OrderedDict()
for r in fr:
    fg[r["Order"]] = fg.get(r["Order"], 0) + r["Freight"]
fgl = [{"Order": k, "Freight": v} for k, v in fg.items()]
lo2 = left_outer(clean, fgl, "Order", "Order")
print("Freight grouped by Order:", len(fgl), "rows; merged left outer:", len(lo2), "rows")
both("revenue after merging the grouped freight", sum(l["Revenue"] for l, _ in lo2))

# --- append ------------------------------------------------------------------
S = sales()
print("Sales rows:", len(S), "columns:", list(S[0]))
naive_cols = list(S[0]) + [c for c in clean[0] if c not in S[0]]
print("naive append columns:", naive_cols, "rows:", len(S) + len(clean))
web_as_sales = [OrderedDict([("Sale", r["Order"]), ("Date", r["Date"]), ("Customer", "C00"),
                             ("Product", r["Product"]), ("Bags", r["Bags"]), ("Price", r["Price"]),
                             ("Channel", "Online"), ("Revenue", r["Revenue"])]) for r in clean]
allsales = S + web_as_sales
print("AllSales rows:", len(allsales))
both("AllSales bags", sum(r["Bags"] for r in allsales))
both("AllSales revenue", sum(r["Revenue"] for r in allsales))
both("Sales revenue", sum(r["Revenue"] for r in S))
print("AllSales Online rows:", sum(1 for r in allsales if r["Channel"] == "Online"),
      "Sales Online rows:", sum(1 for r in S if r["Channel"] == "Online"))

# --- unpivot -----------------------------------------------------------------
b = split("budget-2026.csv", ",")
months = [k for k in b[0] if k != "Channel"]
print("budget file:", len(b), "rows x", len(b[0]), "columns")
long = [OrderedDict([("Channel", r["Channel"]), ("Month", m + "-01"), ("Budget", int(r[m]))])
        for r in b for m in months]
print("unpivoted rows:", len(long), "first:", dict(long[0]), "last:", dict(long[-1]))
for ch in ["Wholesale", "Online", "Shop"]:
    year = sum(x["Budget"] for x in long if x["Channel"] == ch)
    h1 = sum(x["Budget"] for x in long if x["Channel"] == ch and x["Month"] < "2026-07-01")
    both(f"budget {ch} year", year)
    both(f"budget {ch} H1", h1)
both("budget total year", sum(x["Budget"] for x in long))
both("budget total H1", sum(x["Budget"] for x in long if x["Month"] < "2026-07-01"))

# --- group-by ------------------------------------------------------------------
g = OrderedDict()
for r in clean:
    x = g.setdefault(r["Product"], {"Orders": 0, "Bags": 0, "Revenue": 0})
    x["Orders"] += 1
    x["Bags"] += r["Bags"]
    x["Revenue"] += r["Revenue"]
for k, v in sorted(g.items(), key=lambda kv: -kv[1]["Revenue"]):
    print(f"  {k:7} orders {v['Orders']:2} bags {v['Bags']:3} revenue {en(v['Revenue'])}  pt {v['Revenue']}")
print("products:", len(g))
# Without the filter: grouping counts the cancelled orders too.
g0 = Counter()
for r in raw:
    g0[r["SKU"].upper()] += r["Qty"]
print("bags per product if the filter came after the grouping:", dict(g0))
# Sales of 2026 by channel, and budget vs actual for January to June.
act = OrderedDict((ch, 0) for ch in ["Wholesale", "Online", "Shop"])
for r in S:
    if r["Date"].year == 2026:
        act[r["Channel"]] += r["Revenue"]
print("2026 Sales rows:", sum(1 for r in S if r["Date"].year == 2026))
for ch, a in act.items():
    bud = sum(x["Budget"] for x in long if x["Channel"] == ch and x["Month"] < "2026-07-01")
    print(f"  {ch:9} budget {en(bud)} actual {en(a)} variance {en(a - bud)}  pct {100 * (a - bud) / bud:.1f}%")
print("  total     budget", en(sum(x["Budget"] for x in long if x["Month"] < "2026-07-01")),
      "actual", en(sum(act.values())))
print("last Sales date:", max(r["Date"] for r in S))

# The SUMIFS that reconciles the Online figure, in a Calc cell over the
# pasted Sales sheet with lesson 2's Revenue column.
bk = Book()
try:
    sh = bk.sheet("Sales")
    sh.getCellRangeByName("H1").setString("Revenue")
    bk.set("Sales", "H2", "=E2*F2")
    bk.fill("Sales", "H2", "H109")
    for ch in ["Online", "Wholesale"]:
        f = quoted(L14, f'=SUMIFS(Sales!H:H, Sales!G:G, "{ch}", Sales!B:B, ">="&DATE(2026,1,1))')
        print(f"Calc {f}: {bk.ev(calc(f))}")
finally:
    bk.close()
print("files:", sorted(files()))
