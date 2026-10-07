---
title: Guardando o que não existe
version: 1
---

O cache-aside guarda o que o banco devolveu. Quando ele não devolveu nada, um livro que não existe, o
código acima não guarda nada, e **toda requisição por esse livro vai ao banco**. Um link quebrado, um
robô chutando ids ou um cliente em loop num item apagado viram uma carga constante que o cache nunca
absorve.

A correção é guardar a ausência, com um marcador que não se confunda com um valor de verdade e um tempo
de vida curto, só dele:

```python
import json

import catalogue
from bookcache import r

MISSING = "missing"


def get_book(book_id, negative_ttl=None):
    key = f"book:{book_id}"
    cached = r.get(key)
    if cached == MISSING:
        return None
    if cached is not None:
        return json.loads(cached)
    book = catalogue.get_book(book_id)
    if book is None:
        if negative_ttl:
            r.set(key, MISSING, ex=negative_ttl)
        return None
    r.set(key, json.dumps(book), ex=300)
    return book


for negative_ttl in (None, 30):
    r.delete("book:99")
    before = catalogue.queries
    for _ in range(10):
        get_book(99, negative_ttl)
    print(f"negative_ttl={negative_ttl}: 10 reads of book 99, queries: {catalogue.queries - before}")
```

```
ana@web:~/work$ python3 missing.py
negative_ttl=None: 10 reads of book 99, queries: 10
negative_ttl=30: 10 reads of book 99, queries: 1
ana@web:~/work$ redis-cli GET book:99; redis-cli TTL book:99
missing
30
```

**Dez leituras de um livro que não existe custam dez consultas sem o marcador e uma com ele.** O tempo
de vida do marcador é mais curto que o de um valor de verdade, 30 segundos contra 300, porque o custo de
errar é outro: um livro acrescentado um minuto depois de alguém pedir por ele não deveria ficar
invisível por cinco. E o código que criar o livro 99 apaga o `book:99`, exatamente como o
`update_price` faz, então o marcador nunca precisa esperar o próprio tempo de vida.
