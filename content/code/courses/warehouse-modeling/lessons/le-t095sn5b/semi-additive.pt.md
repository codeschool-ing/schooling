---
title: Semiaditiva: o estoque na prateleira
version: 1
---

Vender livros é um processo de negócio. **Contá-los é outro**: no fim de cada mês, alguém em cada
loja conta os exemplares de cada título nas prateleiras. A granularidade é uma linha por loja, por
livro que ela tem, por contagem de fim de mês, e há uma medida, `on_hand`.

```sql
-- Grain: one row per shop, per book it stocks, per month-end count.
CREATE TABLE fact_inventory AS
SELECT d.date_key, s.shop_key, b.book_key, sc.on_hand
FROM staging.stock_counts sc
JOIN dim_date d ON d.date = sc.count_date
JOIN dim_shop s ON s.shop_id = sc.shop_id
JOIN dim_book b ON b.book_id = sc.book_id
ORDER BY d.date_key, s.shop_key, b.book_key;
```

Quantos livros havia nas prateleiras da Paulista em 2024? Some, e veja o que sai:

```sql
-- Books on the shelves of Paulista, two ways.
SELECT d.year,
       sum(i.on_hand)                                   AS summed_over_months,
       sum(i.on_hand) FILTER (WHERE d.month = 12)       AS at_year_end,
       round(sum(i.on_hand) / count(DISTINCT d.month))  AS average_month_end
FROM fact_inventory i
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
WHERE s.shop_name = 'Paulista'
GROUP BY d.year ORDER BY d.year;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < stock.sql
┌───────┬────────────────────┬─────────────┬───────────────────┐
│ year  │ summed_over_months │ at_year_end │ average_month_end │
│ int64 │       int128       │   int128    │      double       │
├───────┼────────────────────┼─────────────┼───────────────────┤
│  2024 │             170458 │       15635 │           14205.0 │
│  2025 │             205531 │       18337 │           17128.0 │
└───────┴────────────────────┴─────────────┴───────────────────┘
```

**170.458 não é um número de livros.** São doze contagens de fim de mês somadas, o mesmo exemplar
contado de novo a cada mês em que ficou na prateleira. A Paulista tinha 15.635 livros no fim de
dezembro de 2024, e 14.205 num fim de mês médio. As duas são respostas verdadeiras; a soma não
responde a nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma grade de contagens de estoque no fim do mês, lojas na lateral e meses no topo. Somar uma coluna, entre lojas num mesmo fim de mês, dá os livros da rede naquela data. Somar uma linha, entre os meses de uma loja, conta as mesmas cópias várias vezes: na Paulista, doze contagens de 2024 somam 170.458, enquanto as prateleiras tinham 15.635 livros no fim de dezembro.\"><defs><marker id=\"ah-semi-additive\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"138.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">jan</text><text x=\"194.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fev</text><text x=\"250.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mar</text><text x=\"306.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">…</text><text x=\"362.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nov</text><text x=\"418.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dez</text><text x=\"98\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Paulista</text><rect x=\"113\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"393\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"98\" y=\"98.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pinheiros</text><rect x=\"113\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"393\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"98\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Cambuí</text><rect x=\"113\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"393\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"98\" y=\"162.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">…</text><rect x=\"113\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"393\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"454\" y1=\"66.0\" x2=\"486\" y2=\"66.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah-semi-additive)\"></line><text x=\"494\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">entre meses: 170.458</text><text x=\"494\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as mesmas cópias, contadas de novo</text><line x1=\"418.0\" y1=\"182\" x2=\"418.0\" y2=\"214\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah-semi-additive)\"></line><text x=\"418.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">entre lojas numa data: um total verdadeiro</text><text x=\"418.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só a Paulista, fim de dezembro de 2024: 15.635</text></svg>", "caption": "`on_hand` soma entre lojas numa mesma data, e não entre datas.", "same": ["Cambuí", "Paulista", "Pinheiros"]}
```

`on_hand` é **semiaditiva**: soma entre lojas e entre livros, porque os exemplares da Paulista e os do
Batel são exemplares diferentes. Não soma no tempo, porque um saldo no fim de março e um no fim de
abril contam quase os mesmos exemplares. No tempo ela precisa de outra agregação: o valor na última
data do período, a média do período, ou o mínimo.

Todo saldo se comporta assim: estoque, dinheiro numa conta, lugares restantes num voo, alunos
matriculados. **Uma tabela de vendas mede um fluxo, o que se moveu no período; uma tabela de estoque
mede um nível, o que havia num instante.** Fluxos somam no tempo. Níveis não.

Uma ferramenta de relatório não distingue os dois olhando a coluna: ambos são inteiros com nomes
razoáveis. Essa é uma das coisas que o dicionário da lição 12 registra para cada medida.
