---
title: Tabelas ponte, e o peso nelas
version: 1
---

`bridge_book_author` é uma **tabela ponte** (bridge): fica entre uma tabela fato e uma dimensão, e
transforma uma chave da linha fato em várias linhas da dimensão. A construção dela é curta:

```sql
CREATE TABLE dim_author AS
SELECT row_number() OVER (ORDER BY author_id) AS author_key, author_id, name AS author_name,
       country
FROM staging.authors;

-- A book can have several authors, so the link is a table of its own. The
-- weight divides a book's sales between them and adds up to 1 per book.
CREATE TABLE bridge_book_author AS
SELECT b.book_key, a.author_key, ba.position,
       1.0 / count(*) OVER (PARTITION BY ba.book_id) AS weight
FROM staging.book_authors ba
JOIN dim_book b   ON b.book_id = ba.book_id
JOIN dim_author a ON a.author_id = ba.author_id;
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"fact_sales aponta para um livro com book_key. A tabela ponte bridge_book_author tem três linhas para esse livro, uma por autor, cada uma com peso um terço. Cada linha da ponte aponta para um autor na dim_author. Uma venda chega a três autores; com o peso, cada um fica com um terço, e os terços somam a venda de volta.\"><defs><marker id=\"ah-bridge\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"95\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">fact_sales</text><text x=\"95\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">book_key · net_cents</text><line x1=\"170\" y1=\"120\" x2=\"230\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-bridge)\"></line><text x=\"330\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">bridge_book_author</text><rect x=\"235\" y=\"44\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">book_key · author_key</text><text x=\"245\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">peso 0,333…</text><line x1=\"425\" y1=\"65\" x2=\"480\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-bridge)\"></line><rect x=\"485\" y=\"44\" width=\"215\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dim_author</text><text x=\"495\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Quentin Lindqvist</text><rect x=\"235\" y=\"102\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">book_key · author_key</text><text x=\"245\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">peso 0,333…</text><line x1=\"425\" y1=\"123\" x2=\"480\" y2=\"123\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-bridge)\"></line><rect x=\"485\" y=\"102\" width=\"215\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dim_author</text><text x=\"495\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Vera Grieg</text><rect x=\"235\" y=\"160\" width=\"190\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">book_key · author_key</text><text x=\"245\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">peso 0,333…</text><line x1=\"425\" y1=\"181\" x2=\"480\" y2=\"181\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-bridge)\"></line><rect x=\"485\" y=\"160\" width=\"215\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dim_author</text><text x=\"495\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tomás Paiva Bergman</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os três pesos de um livro somam 1</text></svg>", "caption": "Uma tabela ponte transforma o livro de uma venda nos seus autores; o peso divide a venda entre eles.", "same": ["Quentin Lindqvist", "Tomás Paiva Bergman", "Vera Grieg"]}
```

A coluna `weight` divide cada livro entre os seus autores: um terço para cada num livro com três, e os
pesos de todo livro somam 1. Multiplicar uma venda pelo peso antes de somar dá a cada autor uma parte,
e as partes somam a venda de volta. Por isso o total ponderado da seção anterior batia com o que a rede
vendeu.

Então qual está certo, ponderado ou não? **Os dois, para perguntas diferentes.** Estes são os cinco
autores do topo:

```sql
SELECT a.author_name,
       round(sum(f.net_cents) / 100, 2)             AS impact_brl,
       round(sum(f.net_cents * ba.weight) / 100, 2) AS weighted_brl
FROM fact_sales f
JOIN bridge_book_author ba USING (book_key)
JOIN dim_author a USING (author_key)
GROUP BY ALL
ORDER BY impact_brl DESC
LIMIT 5;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < top-authors.sql
┌───────────────────────┬────────────┬──────────────┐
│      author_name      │ impact_brl │ weighted_brl │
│        varchar        │   double   │    double    │
├───────────────────────┼────────────┼──────────────┤
│ Petra Dahl Torres     │ 3098982.11 │   3092387.91 │
│ Ada Sandberg          │ 2818705.13 │   2804291.94 │
│ Olga Fontes           │ 2638780.29 │   2638780.29 │
│ Rui Ibsen Orvalho     │ 2066709.72 │   2062143.18 │
│ Klara Bergman Lacerda │ 2053136.15 │   2053136.15 │
└───────────────────────┴────────────┴──────────────┘
```

- **A coluna ponderada é um rateio.** Responde "quanto da receita devemos atribuir a cada autor", para
  direitos autorais, para metas, para tudo o que precisa fechar com o total da rede. Petra Dahl Torres
  fica com R$ 3.092.387,91, a parte desse autor em todo livro com esse nome.
- **A coluna sem peso é o impacto.** Responde "quanto venderam os livros em que este autor trabalhou",
  para decidir quem convidar para um evento ou que catálogo antigo promover. Petra Dahl Torres está em
  R$ 3.098.982,11 de vendas. É uma afirmação verdadeira sobre esse autor, e os cinco números dessa
  coluna não somam nada.

Olga Fontes e Klara Bergman Lacerda têm o mesmo número nas duas colunas, porque nenhum livro desses dois autores tem
coautor.

**Um relatório tem de dizer qual dos dois é.** Uma tabela intitulada "receita por autor" com números sem
peso vai ser totalizada por alguém, e o total vai sair dezesseis milhões de reais alto demais. O
dicionário da lição 12 registra que colunas são rateios e quais são impactos, para a ferramenta de
relatório se recusar a totalizar a segunda.

A mesma estrutura aparece sempre que um fato encontra um conjunto: um paciente com vários diagnósticos,
uma conta bancária com vários titulares, um incidente atribuído a várias equipes. A ponte tem uma linha
por par, e um peso quando as partes precisam fechar.
