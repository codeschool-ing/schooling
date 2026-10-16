---
title: A camada, vista do Metabase
version: 1
---

Comece uma pergunta: **New**, depois **Question**, depois escolha os dados — **Lantern**, depois
**Orders**. O Metabase mostra as views da camada com nomes de negócio que ele faz a partir dos nomes
das views, e os comentários do `semantic.sql` como descrições. O que ele leu na sincronização, para
`orders`:

```
Orders | One row per order, without the test account. Money in reais.
   Order Date | The day the order was placed, in São Paulo, whatever the session's time zone.
   Net Revenue | Net revenue: gross minus discount for paid orders, zero for refunded ones. Sum it.
```

**Ninguém digitou essas descrições no Metabase.** Elas vieram do banco, onde a aula 2 pôs o hábito e
esta aula pôs o texto, então quem escolhe uma coluna num menu lê a mesma frase que quem lê o SQL.

Agora faça a pergunta em volta da qual o curso inteiro vem girando. No editor:

1. Em **Summarize**, escolha **Sum of ...**, depois **Net Revenue**.
2. Em **by**, escolha **Order Date**. O Metabase agrupa uma data por mês se ninguém disser o
   contrário, e diz isso: *Order Date: Month*.
3. **Visualize**.

Uma barra por mês, de janeiro de 2025 a junho de 2026. O editor tem um botão **View SQL**, que mostra
a consulta que o Metabase montou a partir dessas três escolhas:

```
SELECT
  CAST(
    DATE_TRUNC('month', "semantic"."orders"."order_date") AS date
  ) AS "order_date",
  SUM("semantic"."orders"."net_revenue") AS "sum"
FROM
  "semantic"."orders"
GROUP BY
  CAST(
    DATE_TRUNC('month', "semantic"."orders"."order_date") AS date
  )
ORDER BY
  CAST(
    DATE_TRUNC('month', "semantic"."orders"."order_date") AS date
  ) ASC
```

Salva como `metabase.sql` e rodada pelo shell com o mesmo papel que o Metabase usa, ela dá os números
embaixo das barras:

```
ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -f metabase.sql
 order_date |    sum    
------------+-----------
 2025-01-01 |    855.24
 2025-02-01 |   2970.23
 2025-03-01 |   9769.26
 2025-04-01 |  10706.84
 2025-05-01 |  21811.31
 2025-06-01 |  25889.76
 2025-07-01 |  29827.53
 2025-08-01 |  38485.73
 2025-09-01 |  52364.26
 2025-10-01 |  58003.23
 2025-11-01 |  90630.78
 2025-12-01 |  75501.85
 2026-01-01 |  87883.56
 2026-02-01 |  88361.90
 2026-03-01 | 117964.14
 2026-04-01 | 119821.78
 2026-05-01 | 140097.06
 2026-06-01 |  75811.94
(18 rows)
```

Janeiro, fevereiro e março de 2026 somam R$ 294.209,60 — o número do financeiro de novo, agora
alcançado por alguém que escolheu três coisas num menu e não escreveu SQL nenhum. Foi isso que a
camada comprou. O menu ofereceu `Net Revenue`, e somá-la era a definição.

Duas coisas na saída valem ser reconhecidas, porque voltam em aulas seguintes. Junho de 2026 está
baixo porque tem 17 dias, e a `calendar` da camada tem uma coluna `month_is_complete` que a aula 6
usa para dizer isso num gráfico. E a barra de agosto de 2025 está curta pelo dia que nunca chegou: a
camada consegue corrigir um defeito que entende, como as linhas com preço errado, e não consegue
inventar um dia de pedidos que ninguém carregou.
