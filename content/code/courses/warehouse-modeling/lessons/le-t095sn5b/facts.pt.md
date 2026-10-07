---
title: Fatos: o que foi medido
version: 1
---

Uma **tabela fato** guarda medições de um processo de negócio, uma linha por evento na granularidade
declarada. Suas colunas são de dois tipos apenas: **chaves** que apontam para dimensões, e
**medidas**, os números.

A primeira da Ana registra a venda de livros:

```sql
-- The first fact table. Grain: one row per line of an order that was not
-- cancelled. Lesson 4 adds the customer.
CREATE TABLE fact_sales AS
SELECT d.date_key,
       s.shop_key,
       b.book_key,
       coalesce(l.promotion_id, 0)                        AS promotion_key,
       o.order_id,
       l.line_no,
       l.quantity,
       l.quantity * l.unit_price_cents                    AS gross_cents,
       l.discount_cents,
       l.quantity * l.unit_price_cents - l.discount_cents AS net_cents
FROM staging.order_lines l
JOIN staging.orders o USING (order_id)
JOIN dim_date d       ON d.date = CAST(o.ordered_at AS DATE)
JOIN dim_shop s       ON s.shop_id = o.shop_id
JOIN dim_book b       ON b.book_id = l.book_id
WHERE o.status <> 'cancelled'
ORDER BY o.order_id, l.line_no;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < fact_sales.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM fact_sales LIMIT 3"
┌──────────┬──────────┬──────────┬───────────────┬──────────┬─────────┬──────────┬─────────────┬────────────────┬───────────┐
│ date_key │ shop_key │ book_key │ promotion_key │ order_id │ line_no │ quantity │ gross_cents │ discount_cents │ net_cents │
│  int32   │  int64   │  int64   │     int64     │  int64   │  int64  │  int64   │    int64    │     int64      │   int64   │
├──────────┼──────────┼──────────┼───────────────┼──────────┼─────────┼──────────┼─────────────┼────────────────┼───────────┤
│ 20240101 │        5 │     2988 │             0 │   100001 │       1 │        1 │       11390 │              0 │     11390 │
│ 20240101 │        5 │     2958 │             0 │   100002 │       1 │        1 │        6190 │              0 │      6190 │
│ 20240101 │        5 │     1332 │             0 │   100003 │       1 │        1 │        9790 │              0 │      9790 │
└──────────┴──────────┴──────────┴───────────────┴──────────┴─────────┴──────────┴─────────────┴────────────────┴───────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS lines, sum(net_cents) AS net_cents FROM fact_sales"
┌────────┬────────────┐
│ lines  │ net_cents  │
│ int64  │   int128   │
├────────┼────────────┤
│ 887477 │ 9574389852 │
└────────┴────────────┘
```

Leia a primeira linha da esquerda para a direita. Em 1º de janeiro de 2024 (`date_key`), na loja de
chave 5 (`Online`), o livro de chave 2988 foi vendido sem promoção (`promotion_key` 0), como linha 1
do pedido 100001: um exemplar, R$ 113,90, sem desconto. **Cada coluna é um ponteiro para o contexto
ou um número**, e uma linha fato é só isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"A primeira estrela. No meio, fact_sales com as chaves date_key, shop_key, book_key e promotion_key, o número do pedido e da linha, e as medidas quantity, gross_cents, discount_cents e net_cents. Em volta, quatro dimensões, cada uma ligada por uma chave: dim_date com ano, mês, dia da semana e feriado; dim_shop com nome, cidade, estado, região e canal; dim_book com título, autores, formato, categoria, subcategoria, departamento e editora; e dim_promotion com código, nome e percentual.\"><line x1=\"360\" y1=\"200\" x2=\"95.0\" y2=\"61.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"200\" x2=\"625.0\" y2=\"61.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"200\" x2=\"95.0\" y2=\"296.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"200\" x2=\"625.0\" y2=\"303.5\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"265.0\" y=\"121.5\" width=\"190\" height=\"157\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">fact_sales</text><text x=\"275.0\" y=\"151.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">date_key</text><text x=\"275.0\" y=\"166.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shop_key</text><text x=\"275.0\" y=\"181.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">book_key</text><text x=\"275.0\" y=\"196.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">promotion_key</text><text x=\"275.0\" y=\"211.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">order_id, line_no</text><text x=\"275.0\" y=\"226.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">quantity</text><text x=\"275.0\" y=\"241.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gross_cents</text><text x=\"275.0\" y=\"256.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">discount_cents</text><text x=\"275.0\" y=\"271.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">net_cents</text><rect x=\"20\" y=\"20\" width=\"150\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dim_date</text><text x=\"30\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">date_key</text><text x=\"30\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">year, month</text><text x=\"30\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">day_name</text><text x=\"30\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">is_holiday</text><rect x=\"550\" y=\"20\" width=\"150\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dim_shop</text><text x=\"560\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shop_key</text><text x=\"560\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shop_name, city</text><text x=\"560\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">state, region</text><text x=\"560\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">channel</text><rect x=\"20\" y=\"255\" width=\"150\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dim_book</text><text x=\"30\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">book_key</text><text x=\"30\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">title, authors</text><text x=\"30\" y=\"315\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">category … department</text><text x=\"30\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">publisher</text><rect x=\"550\" y=\"270\" width=\"150\" height=\"67\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"283\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dim_promotion</text><text x=\"560\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">promotion_key</text><text x=\"560\" y=\"315\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">code, name</text><text x=\"560\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">percent_off</text><text x=\"360\" y=\"380\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">as chaves apontam para fora; as medidas ficam no meio</text></svg>", "caption": "O primeiro esquema estrela: uma tabela fato de linhas de pedido, e quatro dimensões a uma junção de distância."}
```

Quatro coisas nesse `CREATE` são decisões, e não mecânica:

- **A granularidade está escrita no primeiro comentário.** Uma linha por item de um pedido que não
  foi cancelado. Cada item é um livro, então `book_key` tem exatamente um valor por linha, que é o
  teste que uma dimensão precisa passar.
- **Os pedidos cancelados ficam de fora aqui, uma vez.** O relatório da lição 1 precisava lembrar
  `status <> 'cancelled'`; nada que leia esta tabela consegue esquecer.
- **As medidas são calculadas aqui, uma vez.** `net_cents` é quantidade vezes preço menos desconto.
  Dois analistas que teriam escrito essa fórmula de dois jeitos agora leem a mesma coluna.
- **O dinheiro fica em centavos inteiros.** `9574389852` é exatamente R$ 95.743.898,52. Um float
  teria somado os centavos de 887.477 linhas e chegado a algum lugar perto.

`order_id` e `line_no` são as duas colunas que não são nem uma coisa nem outra. Não apontam para
nenhuma tabela dimensão: o número do pedido fica porque alguém vai querer achar os itens de um
pedido, e não há mais nada a dizer sobre um pedido que as outras dimensões já não digam. A lição 4 dá
um nome a isso.

**A tabela fato é comprida e estreita**: 887.477 linhas de dez colunas pequenas, contra dimensões de
poucos milhares de linhas largas. Essa diferença de formato é o motivo de o armazenamento colunar da
lição 8 funcionar tão bem.
