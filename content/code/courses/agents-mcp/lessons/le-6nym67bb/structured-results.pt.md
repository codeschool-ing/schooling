---
title: Resultados estruturados
version: 1
---

O `get_order` devolve um `Order`, não uma string. Três chamadas, uma boa e duas que falham:

```
ana@lab:~/agents$ python try_server.py calls 2> server.log
M-1043: isError=False
  structured: {"id": "M-1043", "status": "shipped", "placed_on": "2026-09-28", "delivered_on": null, "tracking": "BR5512340003", "lines": [{"book_id": "b13", "quant
M-9999: isError=True
  text: Error executing tool get_order: no order M-9999; check the number on the confirmation email
1043: isError=True
  text: Error executing tool get_order: 1 validation error for get_orderArguments order_id   String should match pattern '^M-[0-9]{4}$' [type=string_pattern_m
```

A chamada boa voltou com **`structuredContent`**: um objeto JSON que bate com o esquema de saída, que um hospedeiro pode usar sem interpretar texto. O SDK também manda os mesmos dados como texto em `content`, para clientes e modelos que só leem isso.

Agora compare os campos com o que o `shop.get_order` devolve. A linha do banco tem `customer_id` e `shipping`; o resultado estruturado não. O `Order.model_validate(found)` manteve os campos que o `Order` declara e descartou o resto. **O tipo de saída é uma lista de permitidos**: um campo só chega ao cliente se alguém o escreveu no tipo. Um servidor que devolvesse a linha do banco como veio mandaria toda coluna que ela já ganhou a todo modelo que o chamasse, inclusive as que ninguém considerou quando a ferramenta foi escrita. Aqui o id de um cliente está no banco e nunca sai do servidor, e a seção 08 tem um teste que diz isso.

É o mesmo hábito das observações da aula 3 e da pergunta da aula 12 sobre o que um servidor recebe, virado ao contrário: decida o que um servidor **manda**, campo por campo.
