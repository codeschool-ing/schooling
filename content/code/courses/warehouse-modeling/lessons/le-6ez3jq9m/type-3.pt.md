---
title: Tipo 3, um passo de histórico numa coluna
version: 1
---

**O tipo 3 guarda o valor anterior numa segunda coluna**, ao lado do atual. Uma linha por cliente,
como no tipo 1, e um passo de memória:

```sql
-- Type 3: one extra column holding the value before the latest change.
CREATE TABLE dim_customer_t3 AS
SELECT c.customer_id, c.city,
       (SELECT old_value FROM staging.customer_changes x
         WHERE x.customer_id = c.customer_id AND x.field = 'city'
         ORDER BY x.changed_at DESC LIMIT 1) AS previous_city
FROM staging.customers c;

SELECT * FROM dim_customer_t3 WHERE customer_id IN (1, 2123) ORDER BY customer_id;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < type3.sql
┌─────────────┬──────────┬───────────────┐
│ customer_id │   city   │ previous_city │
│    int64    │ varchar  │    varchar    │
├─────────────┼──────────┼───────────────┤
│           1 │ Recife   │ NULL          │
│        2123 │ Londrina │ Contagem      │
└─────────────┴──────────┴───────────────┘
```

O cliente 2123 mora em Londrina e já morou em Contagem. O cliente 1 nunca se mudou, e não tem cidade
anterior.

O que o tipo 3 responde é estreito e real: **uma comparação entre o arranjo antes de uma mudança e o
arranjo depois dela.** O uso clássico é uma reorganização. Se a rede redesenhasse as regiões de venda em
2025, colunas `region` e `previous_region` na `dim_shop` deixariam todo relatório mostrar o arranjo antigo
e o novo lado a lado, para todo ano, enquanto as pessoas se acostumam com o novo.

O que ele não consegue é acompanhar mais de uma mudança. Um cliente que se mudou duas vezes perdeu a
primeira cidade. E ele não liga um fato à versão que valia quando aconteceu: toda venda de 2024 do
cliente 2123 vê as duas colunas, Londrina e Contagem, e nada diz qual valia no dia.

Então o tipo 3 é um recurso de apresentação para uma transição específica, e raro. Na dúvida entre tipo
2 e tipo 3, o tipo 2 sempre consegue produzir as colunas do tipo 3 (a versão anterior está uma linha
atrás), e o tipo 3 nunca consegue produzir as do tipo 2.
