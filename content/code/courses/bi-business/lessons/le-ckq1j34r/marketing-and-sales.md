---
title: Marketing and sales: the funnel
version: 1
---

Marketing's job is to bring customers in and sales' job is to turn them into orders, so the two are
measured along one path. **The funnel is that path counted step by step: how many people arrived, how
many showed interest, how many bought.** Its value is not the shape, which every funnel has. It is
that a fall in sales can be traced to the step where people stopped.

## The online shop's funnel, 2025

Varanda's online shop counts every step, because every step is a page:

| | A | B |
|---|---|---|
| 1 | Step | Count |
| 2 | Visits | 6480000 |
| 3 | Carts | 498900 |
| 4 | Orders | 124000 |

A visit is one session on the site; a cart is a session in which something was put in the basket; an
order is a paid order. The rates between steps:

```localised
=ROUND(B3/B2*100,1)      7.7
=ROUND(B4/B3*100,1)      24.9
=ROUND(B4/B2*100,1)      1.9
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The online shop's funnel for 2025 as three bars of shrinking length: 6.48 million visits, 498,900 carts, 124,000 orders. Between visits and carts, 7.7%; between carts and orders, 24.9%; from visit to order, 1.9%.\" data-fig=\"l05-funnel\"><text x=\"136.0\" y=\"60.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">visits</text><path d=\"M150.0 34.0 H570.0 V74.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"580.0\" y=\"60.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">6.48 million</text><text x=\"136.0\" y=\"144.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">carts</text><path d=\"M150.0 118.0 H182.3 V158.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"192.3\" y=\"144.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">498,900</text><text x=\"136.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><path d=\"M150.0 202.0 H158.0 V242.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"168.0\" y=\"228.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">124,000</text><text x=\"156.0\" y=\"96.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">7.7% of visits put something in a cart</text><text x=\"156.0\" y=\"180.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">24.9% of carts become orders</text><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">1.9% of visits end in an order</text></svg>", "caption": "The online funnel, 2025. Each step loses most of the one before it; the conversion rate is the product of the steps."}
```

**7.7% of visits put something in a cart, 24.9% of carts became orders, and 1.9% of visits ended in
an order.** The last of these is the conversion rate, and it is the product of the steps before it:
7.7% of 24.9% is about 1.9%. That is why it is useful to keep the steps apart. A fall in conversion
from 1.9% to 1.6% could be fewer people reaching the cart, which points at the products and prices on
the page, or fewer carts being paid, which points at delivery costs, payment or a broken checkout.
The total cannot tell those apart; the steps can.

## Two more numbers marketing lives by

**The average ticket** is sales divided by orders. Online sales were R$ 15.61 million, from lesson 1:

```localised
=ROUND(15610*1000/124000,2)      125.89
```

R$ 125.89 an order online. Sales are visits times conversion times ticket, so any of the three can
move them, and a report that shows only sales hides which one did.

**The cost to acquire a customer** is what was spent to win new customers divided by how many were
won. In 2025 Varanda spent R$ 2.15 million on online marketing, and 79,600 people placed their first
ever online order, 41,200 of them in the first half, as lesson 3 counted:

```localised
=ROUND(2150*1000/79600,2)      27.01
```

About R$ 27 a new customer. **Read it with care: it charges all the online marketing to new customers,
though some of it reached people who had bought before.** It is a rough number, good for comparing one
year with the next if it is computed the same way each time, and lesson 17 sets a cost like this
against what a customer is worth.

## The store has a funnel too

A store's funnel is harder to count, because nobody logs in at the door. Six of Varanda's stores,
Contagem among them, have a counter at the entrance. In 2025 it counted 211,500 visitors at Contagem,
and the tills issued 51,480 receipts:

```localised
=ROUND(51480/211500*100,1)      24.3
=ROUND(12480*1000/51480,2)      242.42
```

**24.3% of visitors bought something, and the average receipt was R$ 242.42**, almost twice the
online ticket, because the large furniture is mostly bought in the store. A door counter counts
entries, not people: a couple counts as two, and a customer who goes out to the car and comes back
counts twice. Store conversion is therefore a number to compare with itself over time, not with the
online rate.
