---
title: Write-behind
version: 1
---

O **write-behind**, também chamado de write-back, inverte a ordem: a gravação vai para o cache na hora
e chega ao banco depois, em segundo plano. A aplicação recebe resposta na velocidade da memória, e o
banco vê gravações menos numerosas e maiores, no seu próprio ritmo.

```schooling-example
{"language": "python", "file": "behind.py", "parts": [{"code": "import json\n\nimport redis\n\nimport catalogue\n\nr = redis.Redis(decode_responses=True)\n\n\ndef set_price(book_id, price_cents):\n    with r.pipeline() as pipe:          # MULTI ... EXEC: both or neither\n        pipe.set(f\"price:{book_id}\", price_cents)\n        pipe.rpush(\"pending-prices\", json.dumps([book_id, price_cents]))\n        pipe.execute()\n\n\ndef flush():\n    written = 0\n    while (item := r.lpop(\"pending-prices\")) is not None:\n        catalogue.set_price(*json.loads(item))\n        written += 1\n    return written\n\n\nr.delete(\"pending-prices\")\nfor price in (5490, 4990, 4490):\n    set_price(2, price)\nprint(\"cache\", r.get(\"price:2\"), \"| database\", catalogue.get_book(2)[\"price_cents\"], \"| pending\", r.llen(\"pending-prices\"))\nprint(\"flushed\", flush(), \"writes | database\", catalogue.get_book(2)[\"price_cents\"])\n", "note": "As gravações vão para o Redis e para uma fila na hora; o `flush` repete a fila no banco."}]}
```

```
ana@web:~/work$ python3 behind.py
cache 4490 | database 5990 | pending 3
flushed 3 writes | database 4490
```

Três mudanças de preço chegaram ao cache e esperaram numa lista do Redis; o banco ainda dizia 5.990 até
o `flush` repeti-las. **Enquanto a lista não estiver vazia, o cache é o único lugar onde o preço mais
novo existe.** Essa é a troca, e é grande:

- **Perca o Redis e você perde as gravações**, não cópias delas. A seção de persistência da aula 8 disse
  o que uma queda custa com RDB e com AOF; aqui esse custo deixa de ser uma página mais lenta e passa a
  ser uma mudança de preço que ninguém fez.
- **Todo o resto que lê o banco fica atrasado.** Um relatório, uma segunda aplicação, a própria API da
  loja em outro servidor: todos veem 5.990 até o flush.
- **O flush é um programa que não pode parar**, com monitoramento, novas tentativas e uma resposta para
  uma gravação que o banco recusa.

O write-behind compensa onde as gravações são muitas e cada uma vale pouco: contadores de visualização,
horários de último acesso, curtidas. Trezentos incrementos de um contador viram um `UPDATE` com o total.
**Preços são o exemplo errado para ele de propósito**, e uma loja que lida com dinheiro nunca deveria
deixar o cache ser a única cópia de um.
