---
title: Rateando para uma granularidade mais fina
version: 1
---

Para pôr um valor do pedido nos itens, dê a cada item uma parte. A regra aqui é a que a maioria das
lojas usa para frete: **proporcional ao valor de cada item.** Um livro de R$ 68,90 carrega mais do
frete que um de R$ 29,90.

Proporções produzem frações de centavo, e dinheiro é centavo inteiro. Arredondar cada parte sozinha
faria as partes de alguns pedidos somarem um centavo a mais ou a menos que o frete. Então o rateio
arredonda toda parte para baixo e entrega os centavos que sobram, um a cada, aos itens que mais
perderam no arredondamento:

```sql
-- Share each order's shipping among its lines, in proportion to their net
-- value, in whole cents; the cents left over go to the largest lines first.
CREATE TABLE fact_sales_shipping AS
WITH shares AS (
    SELECT f.order_id, f.line_no, f.net_cents, o.shipping_cents,
           o.shipping_cents * f.net_cents / sum(f.net_cents) OVER (PARTITION BY f.order_id)
               AS exact_share
    FROM fact_sales f JOIN staging.orders o USING (order_id)
    WHERE o.shipping_cents > 0
),
floored AS (
    SELECT *, CAST(floor(exact_share) AS BIGINT) AS cents,
           shipping_cents - sum(CAST(floor(exact_share) AS BIGINT))
               OVER (PARTITION BY order_id) AS left_over,
           row_number() OVER (PARTITION BY order_id
                              ORDER BY exact_share - floor(exact_share) DESC, line_no) AS place
    FROM shares
)
SELECT order_id, line_no, net_cents,
       cents + CASE WHEN place <= left_over THEN 1 ELSE 0 END AS shipping_cents
FROM floored;

SELECT * FROM fact_sales_shipping WHERE order_id = 112406 ORDER BY line_no;
SELECT sum(shipping_cents) AS allocated FROM fact_sales_shipping;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < allocate.sql
┌──────────┬─────────┬───────────┬────────────────┐
│ order_id │ line_no │ net_cents │ shipping_cents │
│  int64   │  int64  │   int64   │     int64      │
├──────────┼─────────┼───────────┼────────────────┤
│   112406 │       1 │      3290 │            372 │
│   112406 │       2 │      2990 │            338 │
│   112406 │       3 │      6890 │            780 │
└──────────┴─────────┴───────────┴────────────────┘
┌───────────┐
│ allocated │
│  int128   │
├───────────┤
│ 225246280 │
└───────────┘
```

O pedido 112406 tem três livros e pagou R$ 14,90 de frete. O livro de R$ 68,90 carrega R$ 7,80, cerca de
metade, porque é cerca de metade do pedido. **As três partes somam exatamente 1.490 centavos**, e o
total sobre todos os pedidos é 225.246.280: o frete que a rede de fato cobrou, até o centavo.

Duas escolhas nesse arquivo são decisões que alguém precisa assumir:

- **A base.** Valor é uma regra; peso, ou uma parte igual por item, são outras. Cada uma dá uma
  resposta diferente para "quanto de frete os livros infantis nos custaram?", e nenhuma está errada. O
  dicionário da lição 12 é onde a regra fica escrita ao lado da coluna.
- **O arredondamento.** Os centavos que sobram vão para as maiores partes fracionárias primeiro, com o
  número do item desempatando para o resultado ser o mesmo em toda execução. Esse é o método dos
  maiores restos; dar os centavos extras aos primeiros itens é outra regra que também fecha a conta, e
  as duas movem centavos isolados entre itens, nunca o total.

**Rateie quando as pessoas precisam somar o valor por coisas que só o item conhece**: o livro, o
departamento dele, a editora. Se ninguém pergunta "frete por departamento", a resposta da próxima
seção é mais simples.
