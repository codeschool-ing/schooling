---
title: The typed totals, found by consistency
version: 1
---

**The strongest check for a wrong value is a second record of the same fact.** Every order's total
can be computed from its lines: quantity times price, summed, less the discount, plus the delivery
fee. Lesson 7 built that computation to test its conversions and found 28,519 orders that agree to
the centavo and 7 that do not. Here are the seven:

```schooling-example
{
  "language": "python",
  "file": "typos.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom lines import lines\nfrom orders import orders\n\n",
      "note": "Lesson 7's order lines, converted, and the orders."
    },
    {
      "code": "cents = lambda col: (pd.to_numeric(orders[col].fillna(\"0\")) * 100).round().astype(int)\n",
      "note": "A column of reais as integer cents, blanks counted as zero."
    },
    {
      "code": "orders[\"expected\"] = (orders[\"order_id\"].map(lines.groupby(\"order_id\")[\"line_cents\"].sum())\n                      - cents(\"discount\") + cents(\"delivery_fee\")) / 100\n",
      "note": "**What each total should be**: its lines, less the discount, plus the fee."
    },
    {
      "code": "wrong = orders[(orders[\"total\"] - orders[\"expected\"]).abs() > 0.005].copy()\nwrong[\"ratio\"] = (wrong[\"total\"] / wrong[\"expected\"]).round(2)\n\n",
      "note": "Every order whose total disagrees with its lines by more than half a centavo, and by what factor."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(wrong[[\"order_id\", \"total\", \"expected\", \"ratio\", \"status\"]].to_string(index=False))\n"
    }
  ]
}
```

```
ana@lab:~/clean$ python typos.py
order_id  total  expected  ratio    status
  100592 2516.0    251.60   10.0 delivered
  106842  458.5     45.85   10.0 delivered
  111955 2721.5    272.15   10.0 delivered
  118299 1807.0    180.70   10.0 delivered
  121020  336.5     33.65   10.0 delivered
  122133  118.5     11.85   10.0 delivered
  125535 1370.0    137.00   10.0 delivered
```

**Every one is exactly ten times its lines.** Customer service corrected these orders by hand and
typed a zero too many, which is the commonest slip there is with money. The ratio says what
happened; the lines say what the total should be.

Look at order 122133: R$ 118.50 against R$ 11.85. A total of R$ 118.50 is an ordinary order, well
inside every rule in the previous section — **no outlier test would ever flag it**, and it is wrong by
the same factor as the R$ 2,721.50 one. The consistency check finds both, because it does not care
how far a value is from the others, only whether it agrees with itself.

The correction is not a judgement here, and that is what makes it safe: the total is replaced by
the value its own lines give, the row is flagged so the change is visible, and the original typed
value stays in the raw file. When a second record exists, **trust the more detailed one** — seven
lines of quantities and prices are harder to mistype in a consistent way than one number.
