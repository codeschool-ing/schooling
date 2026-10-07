---
title: Quando o banco muda
version: 1
---

Um preço muda no banco. A cópia em cache não sabe:

```schooling-example
{"language": "python", "file": "stale.py", "parts": [{"code": "import catalogue\nfrom bookcache import get_book, r, update_price\n\nr.delete(\"book:2\")\nprint(\"cached:\", get_book(2)[\"price_cents\"])\n\ncatalogue.set_price(2, 7990)\nprint(\"database changed, cache says:\", get_book(2)[\"price_cents\"], \"for\", r.ttl(\"book:2\"), \"more seconds\")\n\nupdate_price(2, 6990)\nprint(\"update_price, cache says:\", get_book(2)[\"price_cents\"])\n", "note": "Põe o livro 2 em cache, muda o preço pelas costas do cache, e depois muda de novo pelo `update_price`."}]}
```

```
ana@web:~/work$ python3 stale.py
cached: 8990
database changed, cache says: 8990 for 300 more seconds
update_price, cache says: 6990
```

**Depois do `catalogue.set_price`, o cache continuou respondendo 8.990 com ainda 300 segundos pela
frente.** Todo visitante dos próximos cinco minutos vê um preço que a loja não cobra mais. A aula 6
encontrou isso na camada HTTP e a resposta aqui é a mesma: quem muda os dados avisa o cache. O
`update_price` do `bookcache.py` grava o banco e depois apaga a chave, e a leitura seguinte errou, foi
ao banco e encontrou 6.990.

A ordem dentro do `update_price` importa: **primeiro o banco, depois o cache**. Apagar primeiro deixa
uma brecha em que um leitor erra o cache, lê a linha velha e a guarda de novo, antes mesmo de a
atualização acontecer.

Apagar se chama **invalidação**, e tem um custo fácil de esquecer: a próxima leitura é um erro de
cache. Num livro lido duas vezes por dia isso não é nada. Na página inicial de uma loja, lida centenas de
vezes por segundo, o erro depois de cada invalidação é uma rajada de leituras chegando juntas ao banco,
e a aula 11 trata exatamente disso.
