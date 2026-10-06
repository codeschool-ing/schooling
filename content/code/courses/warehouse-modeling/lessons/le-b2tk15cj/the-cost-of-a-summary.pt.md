---
title: Quando o resumo e o detalhe discordam
version: 1
---

Um agregado é uma cópia, e toda cópia precisa ficar em sincronia com aquilo de que foi copiada. Suponha
que se descubra um erro de caixa: o terceiro item do pedido 112406 foi registrado com R$ 10,00 a mais, e
a tabela fato é corrigida.

```sql
-- A correction reaches the fact table: one line of order 112406 was
-- registered at the wrong price, and is fixed.
UPDATE fact_sales SET net_cents = net_cents - 1000, gross_cents = gross_cents - 1000
WHERE order_id = 112406 AND line_no = 3;

SELECT (SELECT sum(net_cents) FROM fact_sales)      AS fact_total,
       (SELECT sum(net_cents) FROM agg_sales_month) AS aggregate_total;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < correction.sql
┌────────────┬─────────────────┐
│ fact_total │ aggregate_total │
│   int128   │     int128      │
├────────────┼─────────────────┤
│ 9574388852 │      9574389852 │
└────────────┴─────────────────┘
```

**A tabela fato agora diz 9.574.388.852 centavos. O agregado ainda diz 9.574.389.852.** Um relatório lê
um e outro relatório lê o outro, e o gerente passa a ter dois números de receita, dez reais de
diferença, do mesmo warehouse. Nada está quebrado. O agregado simplesmente tem a idade da última
reconstrução.

As defesas são as mesmas de qualquer tabela derivada:

- **Reconstrua depois de toda mudança naquilo de que ele é feito**, como parte da mesma carga e na mesma
  transação quando o banco permite. Aí a janela em que os dois discordam é zero.
- **Ou deixe o banco mantê-lo.** Uma materialized view que o banco atualiza sabe de onde foi construída.
  Quão atual ela fica depende do produto: algumas se atualizam a cada mudança, outras numa agenda, outras
  só quando alguém manda.
- **Confira.** Uma carga que termina comparando o total do agregado com o da tabela fato, e falha se
  diferirem, transforma uma discordância silenciosa num erro que alguém vê.

**O que um agregado custa é o dever de mantê-lo verdadeiro.** Construa um quando uma
consulta medida estiver lenta demais para quem espera por ela, e não antes.
