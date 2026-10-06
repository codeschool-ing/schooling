---
title: Um livro com três autores
version: 1
---

O gerente pede a receita por autor. Um livro tem uma linha na `dim_book`, e os autores estão escritos
ali como uma string, `Petra Dahl Torres`, ou para alguns livros três nomes separados por ponto e
vírgula. Essa string é boa para imprimir num relatório e inútil para agrupar, porque "Vera Grieg"
sozinha não é um valor dela.

A relação é **muitos para muitos**: um livro pode ter vários autores, um autor pode escrever vários
livros. Ela também não pode ser uma coluna da tabela fato, já que um item de venda tem um livro e
possivelmente três autores, o que reprova no teste da granularidade. Então ela ganha uma tabela
própria, uma linha por par de livro e autor, e a carga da lição 2 a construiu:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT b.title, a.author_name, ba.position, ba.weight FROM bridge_book_author ba JOIN dim_book b USING (book_key) JOIN dim_author a USING (author_key) WHERE b.book_id = 600"
┌────────────────────┬─────────────────────┬──────────┬────────────────────┐
│       title        │     author_name     │ position │       weight       │
│      varchar       │       varchar       │  int64   │       double       │
├────────────────────┼─────────────────────┼──────────┼────────────────────┤
│ The Silent Road II │ Tomás Paiva Bergman │        3 │ 0.3333333333333333 │
│ The Silent Road II │ Vera Grieg          │        2 │ 0.3333333333333333 │
│ The Silent Road II │ Quentin Lindqvist   │        1 │ 0.3333333333333333 │
└────────────────────┴─────────────────────┴──────────┴────────────────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS books, count(*) FILTER (WHERE n > 1) AS with_more_than_one FROM (SELECT book_key, count(*) AS n FROM bridge_book_author GROUP BY book_key)"
┌───────┬────────────────────┐
│ books │ with_more_than_one │
│ int64 │       int64        │
├───────┼────────────────────┤
│  3000 │                468 │
└───────┴────────────────────┘
```

*The Silent Road II* tem três autores; 468 dos 3.000 livros da rede têm mais de um. Agora ligue as
vendas aos autores por essa tabela e some:

```sql
-- Revenue by author, through the bridge, with and without its weight.
SELECT round(sum(f.net_cents) / 100, 2)             AS total_through_bridge,
       round(sum(f.net_cents * ba.weight) / 100, 2) AS total_weighted,
       (SELECT round(sum(net_cents) / 100, 2) FROM fact_sales) AS total_sold
FROM fact_sales f
JOIN bridge_book_author ba USING (book_key);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < by-author.sql
┌──────────────────────┬────────────────┬─────────────┐
│ total_through_bridge │ total_weighted │ total_sold  │
│        double        │     double     │   double    │
├──────────────────────┼────────────────┼─────────────┤
│         111745133.05 │    95743898.52 │ 95743898.52 │
└──────────────────────┴────────────────┴─────────────┘
```

**Pela ponte, a rede vendeu R$ 111.745.133,05. Ela vendeu R$ 95.743.898,52.** Uma venda de *The
Silent Road II* agora aparece três vezes, uma com cada autor, e somar todos os autores a conta três
vezes. Os R$ 16.001.234,53 a mais são toda venda de livro com vários autores, contada de novo para cada
autor a mais.

A terceira coluna, `total_weighted`, já concorda com o que foi vendido. A próxima seção é sobre a
coluna `weight` que a faz concordar, e sobre quando você a quer e quando não.
