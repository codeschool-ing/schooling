---
title: Servindo a cópia velha enquanto um atualiza
version: 1
---

Um lock faz os leitores esperarem uma cópia fresca. Para a página de um livro, uma cópia de alguns
segundos atrás serviria do mesmo jeito, e ninguém teria esperado. **Servir o velho enquanto revalida**
mantém a cópia depois do prazo de frescor, a entrega, e deixa um leitor atualizá-la em segundo plano. A
aula 6 fez isso no Nginx com `proxy_cache_use_stale updating`; esta é a mesma ideia na aplicação.

O truque são dois tempos de vida. O valor carrega o próprio `fresh_until`, cinco minutos, e a chave vive
uma hora a mais que isso, para que ainda haja uma cópia velha para servir:

```python
import json
import threading
import time

import redis

import catalogue

r = redis.Redis(decode_responses=True)
FRESH, STALE = 300, 3600
REFRESH_MS = 2000


def load(book_id):
    book = catalogue.get_book(book_id)
    entry = {"book": book, "fresh_until": time.time() + FRESH}
    r.set(f"book:{book_id}", json.dumps(entry), ex=FRESH + STALE)
    return book


def get_book(book_id):
    cached = r.get(f"book:{book_id}")
    if cached is None:
        return load(book_id)
    entry = json.loads(cached)
    if entry["fresh_until"] < time.time():
        if r.set(f"refresh:book:{book_id}", 1, nx=True, px=REFRESH_MS):
            threading.Thread(target=load, args=(book_id,)).start()
    return entry["book"]
```

A marca de atualização é um lock que ninguém libera: **ela simplesmente vence depois de dois segundos**,
o que também limita as atualizações de um livro a uma a cada dois segundos, mesmo que uma atualização
falhe.

Para ver, este programa planta uma cópia que ficou velha há um minuto, com o preço antigo, depois muda o
preço no banco e manda cinquenta leitores:

```python
import json
import threading
import time

import catalogue
import swrcache

book = catalogue.get_book(2)
stale = {"book": dict(book, price_cents=8990), "fresh_until": time.time() - 60}
swrcache.r.set("book:2", json.dumps(stale), ex=3600)
catalogue.set_price(2, 7990)

prices, slowest = set(), 0.0
before = catalogue.queries


def visitor():
    global slowest
    start = time.perf_counter()
    prices.add(swrcache.get_book(2)["price_cents"])
    slowest = max(slowest, (time.perf_counter() - start) * 1000)


threads = [threading.Thread(target=visitor) for _ in range(50)]
for t in threads:
    t.start()
for t in threads:
    t.join()
print(f"50 readers: prices {sorted(prices)}, slowest {slowest:.1f} ms")
time.sleep(0.3)
print(f"a moment later: {swrcache.get_book(2)['price_cents']}, queries {catalogue.queries - before}")
```

```
ana@web:~/work$ python3 stale_demo.py
50 readers: prices [8990], slowest 3.7 ms
a moment later: 7990, queries 1
```

**Os cinquenta leitores receberam resposta em menos de quatro milissegundos**, nenhum esperou o banco, e
todos receberam o preço velho, 8.990. Um deles começou a atualização, e um momento depois o cache tinha
7.990, ao custo de uma consulta.

Essa última parte é o preço: **por um momento, todo mundo vê o valor velho**. Para um preço, é a mesma
troca que o tempo de vida da aula 10 já fazia; para um estoque que acabou de chegar a zero, é a venda de
um livro que a loja não tem mais. Sirva o velho onde uma resposta velha é uma resposta aceitável, e use o
lock onde não é.
