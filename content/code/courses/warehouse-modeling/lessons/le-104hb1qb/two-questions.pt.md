---
title: Duas perguntas feitas ao mesmo banco
version: 1
---

O banco da Ana responde a dois tipos de pergunta o dia inteiro, e elas parecem iguais porque as
duas são SQL.

A primeira vem de um caixa. Um cliente na Paulista compra dois livros e paga por Pix, e o caixa
registra:

```sql
-- One sale at the Paulista till: two books, paid by Pix.
BEGIN;
INSERT INTO orders (order_id, shop_id, customer_id, ordered_at, status)
VALUES (900001, 1, 31579, '2026-01-02 10:14:00-03', 'completed');
INSERT INTO order_lines (order_id, line_no, book_id, quantity, unit_price_cents)
VALUES (900001, 1, 2395, 1, 15990),
       (900001, 2, 1036, 1, 12590);
INSERT INTO payments (payment_id, order_id, method, installments, amount_cents)
VALUES (2000001, 900001, 'pix', 1, 28580);
COMMIT;
```

```
ana@lab:~/wh$ psql -f sale.sql
BEGIN
INSERT 0 1
INSERT 0 2
INSERT 0 1
COMMIT
```

Quatro linhas em três tabelas, numa transação, e o banco terminou. **O caixa pergunta "registre
isto"**, e um instante depois pergunta "mostre aquele pedido", pelo número. Toda pergunta dele nomeia
um pedido, um cliente, um livro.

A segunda vem do gerente, uma vez por mês. **"Quanto cada departamento vendeu, este ano contra o
ano passado?"** Ela não nomeia pedido nenhum. Precisa de todas as linhas que a rede já gravou,
ligadas ao livro vendido, à categoria em que o livro está e ao departamento acima dela:

```sql
-- Revenue by year and department, from the shop's own database.
SELECT extract(year FROM o.ordered_at) AS year,
       coalesce(top.name, mid.name)    AS department,
       round(sum(l.quantity * l.unit_price_cents - l.discount_cents) / 100.0, 2)
                                       AS revenue_brl
FROM orders o
JOIN order_lines l          USING (order_id)
JOIN books b                USING (book_id)
JOIN categories leaf        ON leaf.category_id = b.category_id
JOIN categories mid         ON mid.category_id = leaf.parent_id
LEFT JOIN categories top    ON top.category_id = mid.parent_id
WHERE o.status <> 'cancelled' AND o.ordered_at < '2026-01-01'
GROUP BY 1, 2
ORDER BY 1, 2;
```

```
ana@lab:~/wh$ psql -c "\timing on" -f report.sql
Timing is on.
 year | department  | revenue_brl 
------+-------------+-------------
 2024 | Children    |  2987810.70
 2024 | Comics      |  2553516.52
 2024 | Fiction     | 18389500.17
 2024 | Non-fiction | 17796358.42
 2025 | Children    |  4046265.63
 2025 | Comics      |  3018557.77
 2025 | Fiction     | 22994642.78
 2025 | Non-fiction | 23957246.53
(8 rows)

Time: 1607.639 ms (00:01.608)
```

Oito linhas de resposta. Para produzi-las, o PostgreSQL leu as 893.235 linhas de pedido e todos os
pedidos a que elas pertencem, e levou 1,6 segundo numa máquina ociosa, sem ninguém mais pedindo
nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas perguntas às mesmas tabelas. À esquerda, o caixa: um pedido e suas duas linhas, encontrados por dois índices, onze páginas lidas em 0,192 milissegundo. À direita, o relatório: todas as linhas de pedidos e de itens lidas, 12.518 páginas da memória e outras 14.571 gravadas em arquivos temporários e relidas, em 1,6 segundo, para produzir oito linhas.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">o caixa: registre isto, mostre aquilo</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">o relatório: resuma tudo</text><rect x=\"40\" y=\"50\" width=\"120\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"48\" y=\"80\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"91\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"102\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"113\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"124\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"135\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"146\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"157\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"168\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"179\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"190\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"201\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"212\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"223\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"50\" width=\"120\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">order_lines</text><rect x=\"208\" y=\"80\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"91\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"102\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"113\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"124\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"135\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"146\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"157\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"168\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"179\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"190\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"201\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"212\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"223\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"180\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3 linhas achadas pela chave</text><text x=\"180\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">11 páginas · 0,192 ms</text><rect x=\"400\" y=\"50\" width=\"120\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"408\" y=\"80\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"91\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"102\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"113\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"124\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"135\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"146\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"157\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"168\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"179\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"190\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"201\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"212\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"223\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"560\" y=\"50\" width=\"120\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">order_lines</text><rect x=\"568\" y=\"80\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"91\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"102\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"113\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"124\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"135\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"146\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"157\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"168\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"179\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"190\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"201\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"212\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"223\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">todas as linhas lidas, 8 saem</text><text x=\"540\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">12.518 páginas + temporários · 1,6 s</text><line x1=\"360\" y1=\"50\" x2=\"360\" y2=\"280\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line></svg>", "caption": "A pergunta do caixa e a do relatório, nas mesmas duas tabelas. As linhas destacadas são as que cada uma precisou ler."}
```

**As duas perguntas diferem na forma, não na dificuldade.** O caixa toca um punhado de linhas e
precisa delas agora; o relatório toca todas e pode esperar um pouco. Um grava, o outro só lê. Um se
importa com hoje, o outro compara este ano com o anterior. As duas próximas seções desmontam cada
forma, porque o projeto inteiro de um warehouse decorre da diferença.
