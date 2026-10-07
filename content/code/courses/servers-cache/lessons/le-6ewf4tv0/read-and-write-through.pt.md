---
title: Read-through e write-through
version: 1
---

No cache-aside a aplicação faz o trabalho do cache: confere, carrega, guarda. O **read-through** leva
esse trabalho para um lugar só, uma camada de cache que a aplicação chama no lugar do banco, e o
**write-through** faz o mesmo com as gravações: toda gravação passa pela camada, que grava o banco e
depois o cache.

```python
import json

import redis

import catalogue


class BookCache:
    """Read-through and write-through: the application talks only to this."""

    def __init__(self, client, ttl=300):
        self.r, self.ttl = client, ttl

    def get(self, book_id):
        cached = self.r.get(f"book:{book_id}")
        if cached is not None:
            return json.loads(cached)
        book = catalogue.get_book(book_id)
        self.r.set(f"book:{book_id}", json.dumps(book), ex=self.ttl)
        return book

    def set_price(self, book_id, price_cents):
        catalogue.set_price(book_id, price_cents)
        book = catalogue.get_book(book_id)
        self.r.set(f"book:{book_id}", json.dumps(book), ex=self.ttl)


books = BookCache(redis.Redis(decode_responses=True))
books.r.delete("book:2")
books.set_price(2, 5990)
print("after the write: ttl", books.r.ttl("book:2"), "queries", catalogue.queries)
print("read:", books.get(2)["price_cents"], "queries", catalogue.queries)
```

```
ana@web:~/work$ python3 through.py
after the write: ttl 300 queries 1
read: 5990 queries 1
```

**A gravação deixou uma cópia fresca para trás, então a primeira leitura depois dela foi um acerto.** É
isso que o write-through compra: nenhum erro de cache depois de uma mudança. O que ele custa é uma
leitura do banco a cada gravação, aqui a única consulta contada, e um cache cheio de valores gravados
mas talvez nunca lidos.

O método `get` é o cache-aside, linha por linha. **O read-through é a mesma lógica num lugar
diferente**, e o lugar é a questão: uma classe pela qual toda parte da aplicação passa pode ser
corrigida uma vez, medida uma vez e trocada uma vez. O Nginx e o Varnish, nas aulas 5 a 7, eram caches
read-through por conta própria: num erro de cache eles mesmos buscavam na origem. O Redis e o Memcached
só guardam o que recebem.

O write-through também traz de volta o problema da penúltima seção: o `set_price` termina com um `set`,
então dois escritores em duas cópias da aplicação ainda podem deixar o preço mais velho no cache. **O
write-through é seguro com um escritor por vez**, ou com um lock em volta da gravação, que a aula 11
constrói.
