---
title: Over time
version: 1
---

Revenue by month, with the corporate orders in a column of their own:

```
ana@lab:~/clean$ python -c "from explore import delivered as d; t = d.pivot_table(index='month', columns='corporate', values='total', aggfunc='sum', fill_value=0); t.columns = ['households', 'corporate']; print(t.round(2).to_string())"
         households  corporate
month                         
2025-01   124345.55        0.0
2025-02   125994.10        0.0
2025-03   164724.00        0.0
2025-04   183386.20        0.0
2025-05   206236.00        0.0
2025-06   198896.40        0.0
2025-07   234079.30        0.0
2025-08   217824.80        0.0
2025-09   202106.80        0.0
2025-10   196915.80        0.0
2025-11   225730.60        0.0
2025-12   300498.10   112810.5
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-months\" aria-label=\"A stacked bar chart of revenue from delivered orders by month in 2025. Household revenue grows from about R$ 124 thousand in January to R$ 226 thousand in November and R$ 300 thousand in December; the corporate orders, only in December, add about R$ 113 thousand on top.\"><rect x=\"87.1\" y=\"177.1\" width=\"36.6\" height=\"52.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"138.0\" y=\"176.4\" width=\"36.6\" height=\"53.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"188.8\" y=\"159.9\" width=\"36.6\" height=\"70.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"239.6\" y=\"151.9\" width=\"36.6\" height=\"78.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"290.4\" y=\"142.2\" width=\"36.6\" height=\"87.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"341.3\" y=\"145.3\" width=\"36.6\" height=\"84.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"392.1\" y=\"130.4\" width=\"36.6\" height=\"99.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"442.9\" y=\"137.3\" width=\"36.6\" height=\"92.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"493.8\" y=\"144.0\" width=\"36.6\" height=\"86.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"544.6\" y=\"146.2\" width=\"36.6\" height=\"83.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"595.5\" y=\"133.9\" width=\"36.6\" height=\"96.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"646.3\" y=\"102.1\" width=\"36.6\" height=\"127.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"646.3\" y=\"54.1\" width=\"36.6\" height=\"48.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M80.0 40.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 230.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0k</text><path d=\"M76.0 187.4 L80.0 187.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"187.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100k</text><path d=\"M76.0 144.9 L80.0 144.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"144.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200k</text><path d=\"M76.0 102.3 L80.0 102.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"102.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300k</text><path d=\"M76.0 59.7 L80.0 59.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"59.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400k</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">revenue, R$</text><path d=\"M80.0 230.0 L690.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"105.4\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jan</text><text x=\"156.2\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Feb</text><text x=\"207.1\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mar</text><text x=\"257.9\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Apr</text><text x=\"308.8\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">May</text><text x=\"359.6\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jun</text><text x=\"410.4\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jul</text><text x=\"461.2\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Aug</text><text x=\"512.1\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sep</text><text x=\"562.9\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Oct</text><text x=\"613.8\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Nov</text><text x=\"664.6\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Dec</text><rect x=\"90.0\" y=\"272.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"108.0\" y=\"278.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">households</text><rect x=\"220.0\" y=\"272.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"238.0\" y=\"278.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">corporate</text></svg>", "caption": "December is two stories, and the flag from lesson 9 is what keeps them apart."}
```

Three things stand out, and each is a question rather than an answer yet.

- **Growth.** Household revenue roughly doubles over the year, from R$ 124,345.55 in January to
  R$ 225,730.60 in November. Whether that is more customers or bigger baskets is the next thing to
  look at, and lesson 12's `per_customer` table can say.
- **December.** Households alone reach R$ 300,498.10, a third above November, and the sixteen
  corporate orders add R$ 112,810.50 on top. The flag from lesson 9 is what lets the two be told
  apart: without it, December would look like an 83% jump in ordinary trade.
- **July.** Revenue rises in July and drops back in August. A single month proves little, but it is
  worth a look, and one product explains part of it.

```
ana@lab:~/clean$ python -c "from explore import sold, delivered; s = sold[sold['code'] == '00343'].merge(delivered[['order_id', 'month']], on='order_id'); print(s.groupby('month')['unit_price'].agg(['size', 'min', 'max']).to_string())"
         size    min    max
month                      
2025-01    48   12.9   12.9
2025-02    42   12.9   12.9
2025-03    56   12.9   12.9
2025-04    70   12.9   12.9
2025-05    78   12.9   12.9
2025-06    81   12.9   12.9
2025-07    75  134.9  134.9
2025-08    83  134.9  134.9
2025-09    73  134.9  134.9
2025-10    68  134.9  134.9
2025-11    71  134.9  134.9
2025-12   100  134.9  134.9
```

Every bag of sugar was sold at R$ 12.90 until June and at R$ 134.90 from July, more than ten times
as much. Lesson 9 traced it to the catalogue's typed price and lesson 11 found it as a repeated key.
**Here it shows up as a step in a time series**, which is how a business user would have noticed it:
not as a key or a typo, but as a product whose revenue jumped overnight with no rise in sales.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l15-sugar\" aria-label=\"A step chart of the price charged for a bag of sugar each month of 2025: R$ 12.90 from January to June, then R$ 134.90 from July to December, with no month in between.\"><path d=\"M80.0 186.2 L130.8 186.2 L130.8 186.2 L181.7 186.2 L181.7 186.2 L232.5 186.2 L232.5 186.2 L283.3 186.2 L283.3 186.2 L334.2 186.2 L334.2 186.2 L385.0 186.2 L385.0 56.1 L435.8 56.1 L435.8 56.1 L486.7 56.1 L486.7 56.1 L537.5 56.1 L537.5 56.1 L588.3 56.1 L588.3 56.1 L639.2 56.1 L639.2 56.1 L690.0 56.1\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"105.4\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"156.2\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"207.1\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"257.9\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"308.8\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"359.6\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"410.4\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"461.2\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"512.1\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"562.9\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"613.8\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"664.6\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><path d=\"M80.0 40.0 L80.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 200.0 L80.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 146.7 L690.0 146.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 146.7 L80.0 146.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"146.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M80.0 93.3 L690.0 93.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 93.3 L80.0 93.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"93.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M80.0 40.0 L690.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 40.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">price, R$</text><path d=\"M80.0 200.0 L690.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"105.4\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jan</text><text x=\"156.2\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Feb</text><text x=\"207.1\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mar</text><text x=\"257.9\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Apr</text><text x=\"308.8\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">May</text><text x=\"359.6\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jun</text><text x=\"410.4\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jul</text><text x=\"461.2\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Aug</text><text x=\"512.1\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sep</text><text x=\"562.9\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Oct</text><text x=\"613.8\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Nov</text><text x=\"664.6\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Dec</text><text x=\"232.5\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">12.90</text><text x=\"537.5\" y=\"72.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">134.90</text></svg>", "caption": "The catalogue typo of lesson 9, as a business user would first meet it: a product whose price jumped overnight."}
```

Charts like these are what the next course, `visualization`, is about. For exploration, a quick
chart saved to a file is enough, and matplotlib, installed in lesson 1, draws one in a few lines:

```python
import matplotlib

matplotlib.use("Agg")  # draw to a file; there is no screen here
import matplotlib.pyplot as plt

from explore import delivered

monthly = delivered.pivot_table(index="month", columns="corporate", values="total",
                                aggfunc="sum", fill_value=0)
fig, ax = plt.subplots(figsize=(8, 4))
monthly.plot.bar(stacked=True, ax=ax, color=["#4a7fd4", "#e0a030"])
ax.set_xlabel("")
ax.set_ylabel("revenue, R$")
ax.legend(["households", "corporate"])
fig.tight_layout()
fig.savefig("months.png", dpi=120)
print("months.png:", monthly.shape[0], "months")
```

```
ana@lab:~/clean$ python plots.py
months.png: 12 months
ana@lab:~/clean$ file months.png
months.png: PNG image data, 960 x 480, 8-bit/color RGBA, non-interlaced
```

`matplotlib.use("Agg")` tells it to draw into a file rather than a window, because the lab has no
screen. The figures on this page are drawn from the same numbers by the course itself, so they look
the same in both themes; the PNG is what you would attach to a message or open on your own machine.
