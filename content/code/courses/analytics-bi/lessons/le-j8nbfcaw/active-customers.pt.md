---
title: Quantos clientes ativos, e ativos como
version: 1
---

"Clientes ativos" é a métrica que todo negócio de assinatura e de recompra pede, e ela não tem
definição natural. Precisa de uma janela: ativo significa ter feito algo nos últimos *N* dias, a
partir de uma data. Perguntado à Lantern em 31 de maio de 2026, com três janelas:

```
lantern=# SELECT count(DISTINCT customer_id) FILTER (WHERE ordered_at >= date '2026-06-01' - 30) AS last_30_days,
lantern-#        count(DISTINCT customer_id) FILTER (WHERE ordered_at >= date '2026-06-01' - 90) AS last_90_days,
lantern-#        count(DISTINCT customer_id) AS ever_ordered
lantern-# FROM orders
lantern-# WHERE ordered_at < '2026-06-01' AND customer_id <> 1;
 last_30_days | last_90_days | ever_ordered 
--------------+--------------+--------------
          705 |         1308 |         2482
(1 row)
```

705, 1.308 ou 2.482, da mesma tabela, no mesmo dia. **A janela é a definição**, e a escolha não é
arbitrária: ela deve acompanhar a frequência com que um cliente normal compra. Os dias entre um
pedido e o seguinte do mesmo cliente dizem qual é essa frequência:

```
lantern=# SELECT percentile_cont(ARRAY[0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY gap) AS days_between_orders
lantern-# FROM (SELECT ordered_at::date - lag(ordered_at::date) OVER (PARTITION BY customer_id ORDER BY ordered_at) AS gap
lantern(#       FROM orders WHERE customer_id <> 1) AS g
lantern-# WHERE gap IS NOT NULL;
 days_between_orders 
---------------------
 {16,27,45}
(1 row)
```

Metade dos intervalos passa de 27 dias, e um quarto passa de 45. **Uma janela de 30 dias, então,
conta como perdida uma boa parte de clientes perfeitamente regulares** — qualquer um que esteja
num intervalo de 35 dias no dia 31. Uma janela de 90 dias tem o dobro do tamanho de três
intervalos em quatro, e fica mais perto do ritmo da loja. "Já pediu alguma vez" não mede atividade
nenhuma: só cresce, e reportaria o melhor mês da loja no dia em que o último cliente fosse embora.

Dois detalhes pertencem à definição e são fáceis de esquecer:

- **Qual ação conta.** Aqui é fazer um pedido. Uma loja que conta entrar na conta, abrir um e-mail
  ou visitar o site chega a um número maior e menos significativo.
- **A data de referência.** `date '2026-06-01' - 30` é 2 de maio, então a primeira coluna conta
  clientes com pedido de 2 a 31 de maio. Um painel que calcula "os últimos 30 dias" a partir de
  hoje anda toda manhã, e duas pessoas que olharam em dias diferentes citam números diferentes. Um
  relatório mensal fixa a data no fim do mês.

A conta de teste também fica de fora aqui. Um cliente não faz diferença visível em 1.308; ela é
excluída porque a definição manda, e uma definição aplicada só quando importa não é definição.
