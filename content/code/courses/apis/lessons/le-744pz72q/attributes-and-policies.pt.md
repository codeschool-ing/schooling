---
title: Atributos e políticas
version: 1
---

**Algumas regras não são sobre quem você é, e sim sobre a coisa, o momento ou as circunstâncias.** A
livraria só estorna um pedido até 30 dias depois de ele ser feito. Nenhum papel diz isso. A Carla
pode estornar, e se ela pode estornar *este* pedido depende de uma data guardada no pedido e da data
de hoje, que mudam enquanto o papel dela continua o mesmo.

Regras assim são **controle de acesso baseado em atributos**, ABAC (*attribute-based access
control*). A decisão lê atributos da pessoa (papel, departamento, país), do objeto (dono, idade,
valor, status), da ação, e do ambiente (a hora, de onde veio a requisição), e uma **política**
combina esses atributos. O RBAC é o caso particular em que o único atributo que alguém lê é o papel.

O `orders.py` tem uma regra assim, em `refund_order`. A Carla estorna o pedido 2 da Ana, que tem 10
dias, e depois tenta o pedido 4, que tem 45:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/2/refund
{"id": 2, "customer": "ana", "book_id": 5, "quantity": 2, "total_cents": 11980, "status": "refunded", "placed_on": "2026-09-30", "note": ""}
200
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/4/refund
{"error": "refunds close 30 days after an order; order 4 is 45 days old"}
403
```

A administradora recebe a mesma resposta, porque a política não é uma permissão que falta a ela. É
uma regra sobre o pedido:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-dora' localhost:8000/orders/4/refund
{"error": "refunds close 30 days after an order; order 4 is 45 days old"}
403
```

Um segundo estorno do pedido 2 é um 409, já que o pedido não está mais num estado que pode ser
estornado:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/2/refund
{"error": "order 2 is refunded"}
409
```

São três recusas diferentes. O 403 é para uma regra que pedir de novo não muda, e a mensagem nomeia
a regra. O 409 é para o estado do objeto, como no cancelamento de "De quem é o objeto?". O 200 só veio
depois de todas as checagens terem sido feitas.

## Quando papéis deixam de bastar

O sinal é um papel cujo nome começou a descrever uma regra: `staff_refund_under_30_days`,
`manager_own_region`, `support_eu_only`. Cada condição nova multiplica os papéis, e a tabela que era
para ser lida num relance vira uma lista de exceções. **É o momento de manter os papéis para o que um
tipo de pessoa faz, e levar as condições para uma política que lê atributos.**

Uma política escrita no handler, como aqui, serve para uma regra. Sistemas com muitas tiram as
políticas do código e as levam para um motor com linguagem própria: o Open Policy Agent com Rego,
ou o Cedar da Amazon. Ali as regras são lidas, testadas e alteradas num lugar só. A
ideia é a que o `REFUND_DAYS` já tem: a regra tem um nome, é escrita uma vez, e toda requisição é
julgada por ela.
