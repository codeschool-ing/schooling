---
title: Um segundo banco, feito para ser lido
version: 1
---

Um **data warehouse** é um banco cujo único trabalho é responder perguntas sobre o negócio. Ele é
carregado a partir dos sistemas operacionais, numa agenda, e lido por pessoas e relatórios. Ninguém
digita nele.

Bill Inmon, que cunhou o termo no começo dos anos 1990, deu a ele quatro propriedades, e cada uma é
o oposto de algo das seções 05 e 08:

- **Orientado a assunto.** Organizado em torno do que o negócio pergunta, como vendas, estoque e
  clientes, e não em torno das telas da aplicação que gravou os dados.
- **Integrado.** Uma definição de cliente, de loja, de receita, mesmo quando os dados vieram de
  vários sistemas que discordavam.
- **Variante no tempo.** Cada linha sabe o período que descreve, e o passado é guardado.
- **Não volátil.** Carregado e depois lido. Quem lê não edita as linhas.

O laboratório da Ana já tem um, construído a partir do banco da rede. As lições 2 a 5 o constroem
peça por peça; aqui ele vem pronto, para receber a pergunta da seção 04:

```sql
-- The same question, asked of the warehouse.
.timer on
SELECT d.year, b.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_book b USING (book_key)
GROUP BY ALL
ORDER BY ALL;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < wh-report.sql
┌───────┬─────────────┬─────────────┐
│ year  │ department  │ revenue_brl │
│ int64 │   varchar   │   double    │
├───────┼─────────────┼─────────────┤
│  2024 │ Children    │   2987810.7 │
│  2024 │ Comics      │  2553516.52 │
│  2024 │ Fiction     │ 18389500.17 │
│  2024 │ Non-fiction │ 17796358.42 │
│  2025 │ Children    │  4046265.63 │
│  2025 │ Comics      │  3018557.77 │
│  2025 │ Fiction     │ 22994642.78 │
│  2025 │ Non-fiction │ 23957246.53 │
└───────┴─────────────┴─────────────┘
Run Time (s): real 0.020 user 0.051812 sys 0.013116
```

**Os mesmos oito totais, até o centavo**, em 0,020 segundo em vez de 1,6. O DuckDB imprime
`2987810.7` onde o PostgreSQL imprimiu `2987810.70`, porque o resultado dele é um número de ponto
flutuante e o do PostgreSQL era um decimal exato; o valor é o mesmo.

A velocidade é o menos interessante. Olhe a consulta. Ela cita três tabelas, liga cada uma à do meio
por uma única chave, e o departamento é uma coluna do livro. Ninguém precisou saber que a árvore de
categorias é irregular, que pedidos cancelados ficam de fora ou que receita é quantidade vezes preço
menos desconto. **Essas decisões foram tomadas uma vez, quando o warehouse foi carregado, e toda
consulta depois disso as herda.**

Estas são as tabelas que ele guarda:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT table_name, estimated_size AS rows FROM duckdb_tables() WHERE schema_name = 'main' ORDER BY table_name"
┌───────────────────────┬────────┐
│      table_name       │  rows  │
│        varchar        │ int64  │
├───────────────────────┼────────┤
│ bridge_book_author    │   3570 │
│ dim_author            │   1800 │
│ dim_book              │   3000 │
│ dim_customer          │  49309 │
│ dim_date              │    732 │
│ dim_promotion         │     11 │
│ dim_shop              │      7 │
│ fact_event_attendance │   2923 │
│ fact_fulfilment       │ 244275 │
│ fact_inventory        │ 197574 │
│ fact_payments         │ 586405 │
│ fact_sales            │ 887477 │
└───────────────────────┴────────┘
  12 rows              2 columns
```

Dois tipos de nome. As tabelas `fact_` guardam eventos e medições: uma venda, uma contagem de estoque
no fim do mês, um pagamento. As tabelas `dim_` guardam o contexto que descreve esses eventos: a data,
o livro, a loja, o cliente. Essa divisão é a **modelagem dimensional**, e é o assunto da lição 2.
