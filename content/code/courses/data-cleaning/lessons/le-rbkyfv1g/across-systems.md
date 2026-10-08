---
title: The same category in two systems
version: 1
---

**When two systems record the same thing, each with its own vocabulary, a mapping table is also how
they are joined.** Payment methods are the example: the website and the app write English codes,
the shops' till writes Portuguese words, and nobody chose either to match the other.

```
ana@lab:~/clean$ psql -c 'SELECT payment, count(*) FROM raw.orders GROUP BY 1 ORDER BY 2 DESC'
 payment | count 
---------+-------
 card    | 15767
 pix     | 11365
 boleto  |  1419
(3 rows)

ana@lab:~/clean$ psql -c 'SELECT pagamento, count(*) FROM raw.store_sales GROUP BY 1 ORDER BY 2 DESC'
 pagamento | count 
-----------+-------
 Cartão    | 10654
 Pix       |  5871
 Dinheiro  |  2367
 PIX       |  2319
 pix       |  1203
 cartao    |  1180
(6 rows)
```

Three online methods; six store spellings of three store methods. Cash exists only in the shops and
boleto only online. **Adding the two columns as they are would produce nine payment methods for
four.**

The table for this has one more column than the category map, because the same raw word can mean
different things in different systems — `pix` happens to agree here, but there is no guarantee that
the next system's `card` means what the website's does:

```
source,raw,method
online,card,card
online,pix,pix
online,boleto,boleto
store,Cartão,card
store,cartao,card
store,Pix,pix
store,PIX,pix
store,pix,pix
store,Dinheiro,cash
```

**The key is the pair `(source, raw)`**, never the raw value alone. Applied to every online order
and every store sale, it gives one vocabulary for both channels:

```
ana@lab:~/clean$ psql -c "SELECT m.method, sum(CASE WHEN s.source = 'store' THEN 1 ELSE 0 END) AS store, sum(CASE WHEN s.source = 'online' THEN 1 ELSE 0 END) AS online FROM (SELECT 'store' AS source, pagamento AS raw FROM raw.store_sales UNION ALL SELECT 'online', payment FROM (SELECT DISTINCT * FROM raw.orders) o) s LEFT JOIN payment_map m USING (source, raw) GROUP BY 1 ORDER BY 1"
 method | store | online 
--------+-------+--------
 boleto |     0 |   1419
 card   | 11834 |  15754
 cash   |  2367 |      0
 pix    |  9393 |  11353
(4 rows)
```

Now the two channels can be compared: Pix is 9,393 store sales against 11,353 online, cash exists
only at the counter, and the business can ask whether boleto customers would pay by Pix in a shop.
None of those questions could be asked of nine labels.
