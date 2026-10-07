---
title: The December orders: large, and real
version: 1
---

**The largest orders of the year are not errors, and the evidence is in the rows around them.** The
twelve largest:

```
ana@lab:~/clean$ python -c "from orders import orders as o; print(o.nlargest(12, 'total')[['order_id', 'ordered_at', 'name', 'total', 'status']].to_string(index=False))"
order_id           ordered_at                                 name    total    status
  126473 2025-12-13T15:58:00Z                    Clínica Bem Viver 26928.50 delivered
  126336 2025-12-12T15:28:00Z Escritório Paulista de Contabilidade 12167.00 delivered
  126316 2025-12-12T13:44:00Z Escritório Paulista de Contabilidade 12120.75 delivered
  127072 2025-12-18T17:06:00Z                     Café Aurora Ltda 11832.00 delivered
  126192 2025-12-11T12:29:00Z                    Clínica Bem Viver  8594.00 delivered
  126011 2025-12-09T14:55:00Z                  Studio Trama Design  8488.25 delivered
  126227 2025-12-11T15:47:00Z                   Agência Rota Norte  4859.25 delivered
  126813 2025-12-16T14:52:00Z Escritório Paulista de Contabilidade  4394.75 delivered
  126504 2025-12-13T18:31:00Z                  Colégio Monte Verde  4060.00 delivered
  127204 2025-12-19T18:57:00Z                   Agência Rota Norte  3919.00 delivered
  126024 2025-12-09T17:55:00Z                   Agência Rota Norte  3893.00 delivered
  127172 2025-12-19T14:23:00Z                     Café Aurora Ltda  3770.00 delivered
```

Every one is from December, every one was delivered, and every name is a business. Every order above
R$ 1,000, grouped by who placed it:

```
ana@lab:~/clean$ python -c "from orders import orders as o; big = o[o['total'] > 1000]; print(big.groupby('name')['total'].agg(['count', 'min', 'max']).round(2).to_string()); print(big['ordered_at'].str[:10].min(), big['ordered_at'].str[:10].max())"
                                      count      min       max
name                                                          
Agência Rota Norte                        3  3893.00   4859.25
Café Aurora Ltda                          2  3770.00  11832.00
Clínica Bem Viver                         2  8594.00  26928.50
Colégio Monte Verde                       3  1210.00   4060.00
Enzo Simões Santana                       1  1807.00   1807.00
Escritório Paulista de Contabilidade      3  4394.75  12167.00
Luana Lopes                               1  2721.50   2721.50
Marcelo Monteiro                          1  2516.00   2516.00
Murilo Santos                             1  1370.00   1370.00
Studio Trama Design                       3  1664.00   8488.25
Tiago Teixeira Ribeiro                    1  1333.90   1333.90
2025-01-14 2025-12-19
```

Six of the names are companies — an accountancy office, a clinic, a school, a café, an agency, a
design studio — with two or three orders each. The remaining five rows are people, and four of them
are the typed totals of the previous section, already explained. The fifth, R$ 1,333.90, is a
household order of eight baskets and three bags of sugar, which the section on the catalogue comes back
to.

The companies' orders are all in December, in the fortnight before Christmas, and their lines look
like what they are:

```
ana@lab:~/clean$ python -c "from lines import lines as l; from orders import orders as o; big = o[(o['total'] > 1000) & o['name'].str.contains('Ltda', na=False)]['order_id'].iloc[0]; print(l[l['order_id'] == big][['code', 'quantity', 'unit', 'unit_price', 'line_cents']].to_string(index=False))"
 code  quantity unit  unit_price  line_cents
00284      60.0   un       119.9      719400
00165      40.0   un        12.9       51600
00675      37.5   kg         8.9       33375
00831      90.0   un        28.9      260100
00502      60.0   un         4.9       29400
00248      30.0   un        11.9       35700
00374      10.0   kg         4.5        4500
00900      20.0   un        16.9       33800
00731       5.0   kg         5.9        2950
00322      12.5   kg         9.9       12375
```

Sixty baskets, ninety packs of one product, thirty-seven and a half kilos of another: **an
office buying Christmas baskets for its staff.** Every line is consistent with the total, the
customer is a business, and the date fits the purpose.

So these orders are kept, unchanged. What they need is a label rather than a correction, because
they answer some questions and distort others:

- for **revenue**, they belong in: the money arrived;
- for **the typical household order**, they do not: one clinic's R$ 26,928.50 moves an average of
  ordinary baskets, and a marketing team planning a campaign for families should not see it;
- for **December's growth**, they need saying out loud: a manager comparing December with November
  should know how much of the jump was sixteen corporate orders.

A flag such as `corporate order` lets each report choose, and lesson 12 turns that kind of label into
a column. **Deleting them would have made every report wrong in the same direction; keeping them
unlabelled makes some reports wrong without anybody noticing.**
