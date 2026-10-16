---
title: O período parcial, e a data em que os dados terminam
version: 1
---

A última seção terminou em junho de 2026 a −45,9% contra maio. Um leitor que vê isso num cartão numa
segunda-feira convoca uma reunião. Antes que alguém o faça, o painel precisa dizer uma coisa que em
geral omite: **quando os dados terminam**.

```
lantern=# SELECT max(order_date) AS data_until FROM semantic.orders;
 data_until 
------------
 2026-06-17
(1 row)
```

17 de junho. Junho tem 30 dias, e o cartão comparou 17 deles com os 31 de maio. A comparação que
significa algo põe os mesmos dias lado a lado:

```sql
SELECT sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-06-01' AND '2026-06-17') AS june_1_to_17,
       sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-05-01' AND '2026-05-17') AS may_1_to_17,
       sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-05-01' AND '2026-05-31') AS may_whole
FROM semantic.orders;
```

```
lantern=# SELECT sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-06-01' AND '2026-06-17') AS june_1_to_17,
lantern-#        sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-05-01' AND '2026-05-17') AS may_1_to_17,
lantern-#        sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-05-01' AND '2026-05-31') AS may_whole
lantern-# FROM semantic.orders;
 june_1_to_17 | may_1_to_17 | may_whole 
--------------+-------------+-----------
     75811.94 |    82271.16 | 140097.06
(1 row)
```

Os primeiros dezessete dias de junho contra os primeiros dezessete de maio: R$ 75.811,94 contra R$
82.271,16, cerca de 8% a menos. Isso merece atenção — e é uma conversa diferente da que −45,9% teria
começado. Se 8% é uma desaceleração real ou o ruído de dois períodos curtos é pergunta para os dados da
semana que vem, e não para uma manchete.

Três hábitos acabam com a armadilha de vez:

- **Mostre "dados até" na página**, a partir dos próprios dados — `max(order_date)` — e nunca do
  calendário. No dia em que uma carga falha, o calendário diz hoje e os dados dizem ontem, e só o
  segundo é verdade.
- **Compare um período parcial com a mesma parte do anterior** — o mês até agora contra os mesmos dias
  do mês passado — ou deixe o período atual fora da tendência até ele fechar. A `calendar` da camada
  tem uma coluna `month_is_complete` exatamente para esse filtro.
- **Marque a barra parcial** quando ela precisar aparecer: um tom mais claro, um contorno tracejado, um
  rótulo dizendo "até 17 de junho". A aula 10 volta a isso como um dos jeitos de um gráfico verdadeiro
  enganar.
