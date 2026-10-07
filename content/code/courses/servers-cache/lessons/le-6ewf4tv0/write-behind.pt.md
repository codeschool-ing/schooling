---
title: Write-behind
version: 1
---

O **write-behind**, também chamado de write-back, inverte a ordem: a gravação vai para o cache na hora
e chega ao banco depois, em segundo plano. A aplicação recebe resposta na velocidade da memória, e o
banco vê gravações menos numerosas e maiores, no seu próprio ritmo.

```python
import json

import redis

import catalogue

r = redis.Redis(decode_responses=True)


def set_price(book_id, price_cents):
    with r.pipeline() as pipe:          # MULTI ... EXEC: both or neither
        pipe.set(f"price:{book_id}", price_cents)
        pipe.rpush("pending-prices", json.dumps([book_id, price_cents]))
        pipe.execute()


def flush():
    written = 0
    while (item := r.lpop("pending-prices")) is not None:
        catalogue.set_price(*json.loads(item))
        written += 1
    return written


r.delete("pending-prices")
for price in (5490, 4990, 4490):
    set_price(2, price)
print("cache", r.get("price:2"), "| database", catalogue.get_book(2)["price_cents"], "| pending", r.llen("pending-prices"))
print("flushed", flush(), "writes | database", catalogue.get_book(2)["price_cents"])
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
