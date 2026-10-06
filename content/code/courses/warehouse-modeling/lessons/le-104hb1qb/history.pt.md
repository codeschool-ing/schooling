---
title: O passado, sobrescrito
version: 1
---

Pergunte ao banco da rede quanto custa *The Salt Season IV*, e quanto ele cobrou pelo livro em cada
ano:

```sql
-- What the shop charged for one title, and what it says the title costs.
SELECT b.title, b.list_price_cents AS price_now,
       extract(year FROM o.ordered_at) AS year,
       min(l.unit_price_cents) AS charged_min, max(l.unit_price_cents) AS charged_max
FROM books b
JOIN order_lines l USING (book_id)
JOIN orders o      USING (order_id)
WHERE b.book_id = 2395 AND o.ordered_at < '2026-01-01'
GROUP BY 1, 2, 3 ORDER BY 3;
```

```
ana@lab:~/wh$ psql -f history.sql
       title        | price_now | year | charged_min | charged_max 
--------------------+-----------+------+-------------+-------------
 The Salt Season IV |     15990 | 2024 |       14890 |       14890
 The Salt Season IV |     15990 | 2025 |       15990 |       15990
(2 rows)
```

O livro custa R$ 159,90 hoje. Foi vendido a R$ 148,90 durante todo o 2024: os preços subiram em
primeiro de janeiro de 2025, e `books` guardou só o preço novo. Os pedidos sobreviveram, porque cada
linha anotou o preço cobrado. **Um fato registrado no momento em que aconteceu guarda o seu valor. A
descrição de alguma coisa guarda só o valor mais recente.**

Preços são o caso fácil, porque o caixa os copiou em cada linha. Clientes não. O cliente 2123 mora
em Londrina, no Paraná:

```
ana@lab:~/wh$ psql -c "SELECT customer_id, city, state FROM customers WHERE customer_id = 2123"
 customer_id |   city   | state 
-------------+----------+-------
        2123 | Londrina | PR
(1 row)

ana@lab:~/wh$ psql -c "SELECT changed_at, field, old_value, new_value FROM customer_changes WHERE customer_id = 2123 ORDER BY changed_at"
       changed_at       | field | old_value | new_value 
------------------------+-------+-----------+-----------
 2025-04-13 19:59:35-03 | city  | Contagem  | Londrina
 2025-04-13 19:59:35-03 | state | MG        | PR
(2 rows)
```

O cliente morava em Contagem, em Minas Gerais, até 13 de abril de 2025. Todo pedido feito antes
disso foi feito por alguém em Minas Gerais. Peça ao banco operacional "vendas de 2024 pelo estado do
cliente" e ele liga esses pedidos a `customers`, encontra `PR` e os conta no Paraná.

Quantos pedidos isso desloca?

```
ana@lab:~/wh$ psql -c "SELECT count(*) AS orders_2024, count(DISTINCT o.customer_id) AS customers FROM orders o JOIN customer_changes c USING (customer_id) WHERE c.field = 'state' AND o.ordered_at < '2025-01-01' AND c.changed_at >= '2025-01-01'"
 orders_2024 | customers 
-------------+-----------
        1404 |       196
(1 row)
```

**1.404 pedidos de 2024, de 196 clientes, são contados num estado onde eles não estavam quando
compraram.** Nada dá erro e nada parece errado; o total do Brasil está certo e a divisão por estado
não. Esta rede por acaso registra cada mudança em `customer_changes`, então o histórico *poderia* ser
reconstruído. A maioria dos bancos operacionais não guarda registro nenhum, e aí não pode.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo do cliente 2123 de janeiro de 2024 a dezembro de 2025. Até 13 de abril de 2025 o cliente morava em Contagem, Minas Gerais; depois, em Londrina, Paraná. O banco operacional guarda só Londrina, então todo pedido feito antes da mudança é contado no Paraná quando as vendas são divididas pelo estado do cliente.\"><text x=\"40\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o que aconteceu</text><rect x=\"40\" y=\"36\" width=\"410.6666666666667\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245.33333333333334\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Contagem, MG</text><rect x=\"450.6666666666667\" y=\"36\" width=\"229.33333333333331\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"565.3333333333334\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Londrina, PR</text><line x1=\"450.6666666666667\" y1=\"30\" x2=\"450.6666666666667\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"450.6666666666667\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mudou, 13 de abril de 2025</text><text x=\"40\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">o que a tabela customers diz</text><rect x=\"40\" y=\"116\" width=\"640\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Londrina, PR — para todo pedido, antes e depois</text><line x1=\"40.0\" y1=\"192\" x2=\"40.0\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"40.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2024</text><line x1=\"360.0\" y1=\"192\" x2=\"360.0\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"360.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2025</text><line x1=\"680.0\" y1=\"192\" x2=\"680.0\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"680.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2026</text><line x1=\"40\" y1=\"196\" x2=\"680\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line></svg>", "caption": "O cliente 2123 em dois anos. A linha operacional guarda a cidade mais recente, e todo pedido anterior a herda.", "same": ["Contagem, MG", "Londrina, PR"]}
```

**Guardar o passado é trabalho do warehouse, porque não é de mais ninguém.** O banco operacional faz
bem em sobrescrever: o caixa precisa entregar onde o cliente mora agora. A lição 5 trata inteira de
como um warehouse guarda as duas respostas: onde o cliente morava então, e onde mora agora.
