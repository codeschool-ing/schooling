---
title: A linha de ninguém
version: 1
---

A maioria das vendas nas lojas físicas não tem cliente: alguém paga no caixa sem cartão de fidelidade.
O banco operacional registra isso como um `customer_id` vazio. O warehouse poderia copiar o valor vazio
para a `fact_sales`. Em vez disso, aponta essas vendas para uma linha:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM dim_customer WHERE customer_key = 0"
┌──────────────┬─────────────┬─────────────────────────┬─────────┬─────────┬─────────┬──────────────────────────┬──────────────────────────┬────────────┐
│ customer_key │ customer_id │          name           │  tier   │  city   │  state  │        valid_from        │         valid_to         │ is_current │
│    int64     │    int64    │         varchar         │ varchar │ varchar │ varchar │ timestamp with time zone │ timestamp with time zone │  boolean   │
├──────────────┼─────────────┼─────────────────────────┼─────────┼─────────┼─────────┼──────────────────────────┼──────────────────────────┼────────────┤
│            0 │        NULL │ Walk-in, not identified │ none    │ Unknown │ --      │ 1970-01-01 00:00:00-03   │ 9999-12-31 00:00:00-03   │ true       │
└──────────────┴─────────────┴─────────────────────────┴─────────┴─────────┴─────────┴──────────────────────────┴──────────────────────────┴────────────┘
```

Chave 0, *Walk-in, not identified*. Ela se chama **membro desconhecido** (unknown member), e toda
dimensão que pode faltar a um fato ganha uma. Para ver por quê, construa a alternativa, uma cópia da
tabela de vendas com a chave vazia onde estava o zero, e ligue cada uma à dimensão de clientes:

```sql
-- What happens if walk-in sales carry no customer at all.
CREATE TABLE sales_null_customer AS
SELECT * REPLACE (CASE WHEN customer_key = 0 THEN NULL ELSE customer_key END AS customer_key)
FROM fact_sales;

SELECT 'with key 0' AS version, count(*) AS lines, sum(net_cents) AS net_cents
FROM fact_sales f JOIN dim_customer c USING (customer_key)
UNION ALL
SELECT 'with NULL', count(*), sum(net_cents)
FROM sales_null_customer f JOIN dim_customer c USING (customer_key);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < null-keys.sql
┌────────────┬────────┬────────────┐
│  version   │ lines  │ net_cents  │
│  varchar   │ int64  │   int128   │
├────────────┼────────┼────────────┤
│ with key 0 │ 887477 │ 9574389852 │
│ with NULL  │ 658707 │ 7095730697 │
└────────────┴────────┴────────────┘
```

**228.770 itens e R$ 24.786.591,55 em vendas somem da segunda versão.** Uma junção interna só mantém
linhas cuja chave encontra par, e uma chave vazia não encontra nada, nem outra chave vazia. Todo
relatório que liga vendas a clientes, que é a maioria, deixaria de fora um quarto da receita da rede
sem avisar. Nada dá erro; o total simplesmente fica menor.

Com o membro desconhecido:

- **Toda junção mantém toda linha.** As vendas de balcão caem na chave 0 e são contadas.
- **O desconhecido é um valor que se lê.** Um relatório agrupado por nível mostra uma linha chamada
  `none`, com um quarto da receita, o que diz ao gerente algo verdadeiro sobre o negócio: que muitos
  compradores não estão no programa de fidelidade.
- **"Desconhecido" e "não se aplica" podem ser distinguidos.** Uma dimensão pode ter mais de uma linha
  especial: uma para um valor que faltou, outra para um que não se aplica. A data *Not yet* da lição 2
  é um terceiro tipo, para um valor que ainda não aconteceu.

**A regra: uma chave estrangeira numa tabela fato nunca fica vazia.** Se o valor falta, ela aponta
para uma linha que diz isso.
