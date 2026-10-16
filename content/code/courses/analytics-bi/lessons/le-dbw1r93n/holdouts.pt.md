---
title: A ação do segmento funcionou?
version: 1
---

A equipe de vendas liga para os 173 clientes frequentes que estão em risco. No trimestre seguinte, muitos
deles compraram de novo. As ligações funcionaram? Não dá para saber só por esse número, porque alguns
comprariam de qualquer jeito — são clientes frequentes, e uma fase quieta não é uma partida. O único jeito
de saber é **não ligar para alguns deles**, escolhidos ao acaso antes que alguém pegue o telefone, e
comparar.

Esse grupo é um **grupo de controle**, o *holdout*. A escolha precisa ser aleatória e estável: o mesmo
cliente tem de cair no mesmo grupo toda vez que a consulta roda, senão um cliente que recebeu ligação na
segunda poderia aparecer no grupo de fora na terça. Um hash do id do cliente faz as duas coisas, e não
precisa de tabela:

```
lantern=# SELECT CASE WHEN abs(hashtext(external_id)) % 5 = 0 THEN 'hold out' ELSE 'call' END AS arm,
lantern-#        count(*) AS customers, round(avg(net_revenue), 2) AS avg_net_revenue,
lantern-#        round(avg(orders), 2) AS avg_orders
lantern-# FROM activation.crm_contacts
lantern-# WHERE health = 'at risk' AND orders >= 4
lantern-# GROUP BY 1 ORDER BY 1;
   arm    | customers | avg_net_revenue | avg_orders 
----------+-----------+-----------------+------------
 call     |       136 |          861.51 |       5.73
 hold out |        37 |          971.67 |       5.57
(2 rows)
```

Um quinto do segmento, 37 clientes, fica de fora. `abs(hashtext(external_id)) % 5 = 0` põe um cliente no
grupo de fora dependendo só do id dele, então a execução de amanhã dá a mesma resposta para todo cliente
que ainda estiver no segmento. Um cuidado: `hashtext` é uma função que o PostgreSQL usa internamente, e os
valores dela não têm garantia de ficar iguais entre versões principais, então, para um programa que vai
durar meses, grave a divisão numa tabela no primeiro dia e leia dela.

Olhe as médias. Antes de qualquer ligação, os clientes do grupo de fora gastaram R$ 971,67 cada e os do
grupo que recebe ligação, R$ 861,51 — R$ 110 de diferença, só pelo acaso, porque 37 é um grupo pequeno e
alguns clientes grandes movem a média dele. **É isso que a comparação precisa superar.** Se no trimestre
seguinte o grupo que recebeu ligação comprar mais que o de fora por uma margem desse tamanho, as ligações
podem não ter feito nada.

Três regras, então:

- **Decida o grupo de fora antes da ação**, e nunca tire um cliente dele porque parece promissor. Isso é
  tudo o que o torna aleatório.
- **Compare a mudança, não o nível**: os pedidos de cada grupo depois das ligações contra os dele mesmo
  antes.
- **Segmentos pequenos dão respostas ruidosas.** Com 37 pessoas no grupo de fora, só um efeito grande
  aparece; um programa que dura vários trimestres, ou um segmento maior, consegue ver um menor.
