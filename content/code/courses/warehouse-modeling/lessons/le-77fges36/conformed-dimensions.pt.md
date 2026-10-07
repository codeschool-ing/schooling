---
title: Dimensões conformadas: uma loja para toda tabela fato
version: 1
---

O warehouse da Ana tem cinco tabelas fato, e `fact_sales` e `fact_inventory` apontam as duas para a
`dim_shop`. Não para duas cópias que por acaso se parecem: para a mesma tabela, com as mesmas chaves e
os mesmos valores de atributo. Uma dimensão usada assim é **conformada**.

Isso importa no momento em que uma pergunta precisa de dois processos de negócio de uma vez. Quantos
meses de estoque cada loja tinha no fim de 2025, no ritmo de vendas de dezembro? São vendas de uma
tabela fato e estoque de outra:

```sql
-- Two fact tables, one conformed shop dimension: December 2025 sales against
-- the stock counted at the end of that month.
WITH sold AS (
    SELECT f.shop_key, sum(f.quantity) AS books_sold
    FROM fact_sales f JOIN dim_date d USING (date_key)
    WHERE d.year = 2025 AND d.month = 12
    GROUP BY f.shop_key
),
counted AS (
    SELECT i.shop_key, sum(i.on_hand) AS books_on_shelf
    FROM fact_inventory i
    WHERE i.date_key = 20251231
    GROUP BY i.shop_key
)
SELECT s.shop_name, sold.books_sold, counted.books_on_shelf,
       round(counted.books_on_shelf / sold.books_sold, 1) AS months_of_stock
FROM sold
JOIN counted USING (shop_key)
JOIN dim_shop s USING (shop_key)
ORDER BY months_of_stock;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < drill-across.sql
┌───────────┬────────────┬────────────────┬─────────────────┐
│ shop_name │ books_sold │ books_on_shelf │ months_of_stock │
│  varchar  │   int128   │     int128     │     double      │
├───────────┼────────────┼────────────────┼─────────────────┤
│ Online    │      33931 │          34092 │             1.0 │
│ Pinheiros │       8879 │          14529 │             1.6 │
│ Paulista  │      10771 │          18337 │             1.7 │
│ Savassi   │       6461 │          10888 │             1.7 │
│ Batel     │       4593 │           7989 │             1.7 │
│ Cambuí    │       5292 │           9528 │             1.8 │
│ Moinhos   │       3994 │           7471 │             1.9 │
└───────────┴────────────┴────────────────┴─────────────────┘
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Drill-across em duas tabelas fato. fact_sales é somada em dezembro de 2025 para uma linha por loja, livros vendidos. fact_inventory é somada em 31 de dezembro de 2025 para uma linha por loja, livros na prateleira. Os dois resultados, cada um com uma linha por loja, são ligados por shop_key, a chave da dimensão conformada dim_shop, dando os meses de estoque por loja.\"><defs><marker id=\"ah-drill-across\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><rect x=\"20\" y=\"160\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_inventory</text><line x1=\"170\" y1=\"60\" x2=\"230\" y2=\"60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-drill-across)\"></line><line x1=\"170\" y1=\"180\" x2=\"230\" y2=\"180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-drill-across)\"></line><rect x=\"235\" y=\"35\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"335\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">soma por loja, dezembro</text><text x=\"335\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7 linhas: books_sold</text><rect x=\"235\" y=\"155\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"335\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">soma por loja, 31 de dezembro</text><text x=\"335\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7 linhas: books_on_shelf</text><line x1=\"435\" y1=\"60\" x2=\"500\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-drill-across)\"></line><line x1=\"435\" y1=\"180\" x2=\"500\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-drill-across)\"></line><rect x=\"505\" y=\"95\" width=\"195\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">junção por shop_key</text><text x=\"602\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7 linhas: meses de estoque</text><text x=\"360\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">some cada tabela fato até a granularidade comum, depois junte</text></svg>", "caption": "Drill-across: cada tabela fato é somada até a mesma granularidade antes de a chave conformada ligá-las."}
```

**Cada tabela fato é somada sozinha primeiro, até a mesma granularidade, e os dois resultados são
ligados pela chave conformada.** Isso se chama **drill-across**. Ligar as duas tabelas fato linha a
linha, em vez disso, multiplicaria cada venda por cada linha de estoque da mesma loja e produziria um
número sem significado. Somar primeiro e depois ligar por `shop_key` dá uma linha por loja de cada lado.

A resposta é útil: o site tem cerca de um mês de estoque e cada loja física entre 1,6 e 1,9, que é como
seria de esperar de um depósito que despacha no dia seguinte e de lojas que precisam encher
prateleiras.

## O que conformar exige

- **As mesmas chaves.** `shop_key` 5 é o site em toda tabela fato que menciona uma loja.
- **Os mesmos valores de atributo.** Se a região do time de vendas dissesse `South` e a do time de
  estoque dissesse `Sul`, um relatório comparando os dois mostraria duas regiões com metade dos dados
  cada.
- **A mesma granularidade, ou uma cópia agregada dela.** Uma tabela fato mensal pode compartilhar uma
  dimensão de meses que concorde com a `dim_date` em todo atributo que guarda. Isso ainda é conformado.

A lição 11 volta a isso, porque dimensões conformadas são o que faz de um warehouse um warehouse, e não
vários data marts que não se comparam, e a **matriz de barramento** (bus matrix) de Kimball é a tabela
que as planeja.
