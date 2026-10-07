---
title: Em SQL
version: 1
---

```sql
WITH orders AS (
  SELECT DISTINCT * FROM raw.orders
), delivered AS (
  SELECT channel, greatest(total::numeric, 0) AS total,
         CASE WHEN channel = 'site'
              THEN ordered_at::timestamptz AT TIME ZONE 'America/Sao_Paulo'
              ELSE ordered_at::timestamp END AS placed
  FROM orders
  WHERE status = 'delivered'
)
SELECT channel, count(*) AS orders, sum(total) AS revenue,
       sum(total) FILTER (WHERE placed >= '2025-12-01') AS december
FROM delivered
GROUP BY channel
ORDER BY channel;
```

```
ana@lab:~/clean$ psql -f task.sql
 channel | orders |  revenue   | december  
---------+--------+------------+-----------
 app     |  11851 | 1065555.60 | 132925.45
 site    |  14659 | 1436387.75 | 281616.15
(2 rows)
```

Cada cláusula da tarefa é uma linha da consulta, na ordem em que quem lê a procuraria:

- `SELECT DISTINCT *` tira as linhas repetidas exatas, comparando todas as colunas.
- `greatest(total::numeric, 0)` transforma um total negativo em zero, e o cast para `numeric` mantém
  o dinheiro exato, sem ponto flutuante em lugar nenhum.
- O `CASE` lê os dois relógios. `ordered_at::timestamptz` entende o `Z` como UTC, e `AT TIME ZONE
  'America/Sao_Paulo'` dá o horário local; os horários do aplicativo já são locais e só passam pelo
  cast.
- `FILTER (WHERE placed >= '2025-12-01')` soma dezembro sem uma segunda consulta.

**Os pontos fortes do SQL aqui são os mesmos de que as aulas 10 e 11 dependeram.** Um cast que não
consegue ler um valor para a consulta em vez de inventar um vazio, o trabalho acontece onde os
dados já estão, e a transformação inteira é um arquivo de texto que pode ser revisado linha a
linha. A fraqueza aparece nas cláusulas `WITH`: uma limpeza longa vira uma longa corrente de passos
com nome, o que é legível com cinco e trabalhoso com cinquenta.
