---
title: Chaves, tempos de vida e versões
version: 1
---

Tudo até aqui apagou uma chave por vez, porque o escritor sabia qual chave tinha deixado velha. Algumas
mudanças não têm uma chave só: um imposto novo aplicado a todo preço, uma mudança no formato do JSON,
um deploy que renomeia um campo. O Redis acha chaves por padrão, a aula 8 mostrou o `--scan`, mas
percorrer um espaço de chaves grande a cada deploy é lento e corre contra os leitores que o reabastecem.

A resposta mais barata é **pôr uma versão em toda chave e mudar a versão**:

```schooling-example
{"language": "python", "file": "versions.py", "parts": [{"code": "import json\n\nimport catalogue\nfrom bookcache import r\n\nr.set(\"catalogue:version\", 1, nx=True)\n\n\ndef key(book_id):\n    return f\"v{r.get('catalogue:version')}:book:{book_id}\"\n\n\ndef get_book(book_id):\n    cached = r.get(key(book_id))\n    if cached is not None:\n        return json.loads(cached)\n    book = catalogue.get_book(book_id)\n    r.set(key(book_id), json.dumps(book), ex=300)\n    return book\n\n\ndef read_three():\n    before = catalogue.queries\n    for book_id in (1, 2, 3):\n        get_book(book_id)\n    return catalogue.queries - before\n\n\nprint(\"first pass, queries:\", read_three())\nprint(\"second pass, queries:\", read_three())\nprint(\"version is now\", r.incr(\"catalogue:version\"))\nprint(\"third pass, queries:\", read_three())\n", "note": "Toda chave carrega a versão do catálogo, e um `INCR` aposenta todas."}]}
```

```
ana@web:~/work$ python3 versions.py
first pass, queries: 3
second pass, queries: 0
version is now 2
third pass, queries: 3
ana@web:~/work$ redis-cli --scan --pattern 'v*:book:*' | sort
v1:book:1
v1:book:2
v1:book:3
v2:book:1
v2:book:2
v2:book:3
```

**Um `INCR` transformou todo livro em cache num erro de cache**, sem apagar nada: os leitores
simplesmente pararam de pedir as chaves `v1:`. Elas continuam no Redis e vão embora sozinhas quando os
300 segundos delas acabarem, e é por isso que **um tempo de vida em toda chave** é o que torna este
padrão seguro. Sem ele, cada mudança de versão deixaria para trás uma cópia inteira do cache, para
sempre, até a memória acabar.

Os hábitos de chaves que esta aula usou o tempo todo valem ser ditos uma vez:

| hábito | exemplo | por quê |
|---|---|---|
| um prefixo com o tipo da coisa | `book:2`, `price:2` | legível no `--scan`, e um padrão de ACL o casa |
| o id do banco, nunca um título | `book:2`, não `book:grande-sertao` | um título muda e a chave não mudaria |
| uma versão onde o formato pode mudar | `v2:book:2` | um `INCR` aposenta todas |
| um tempo de vida em toda chave | `ex=300` | todo erro expira |

**E o próprio tempo de vida é uma escolha sobre quanto atraso é aceitável**, feita por tipo de valor:
segundos para um estoque, minutos para um preço, horas para a biografia de um autor. Um tempo maior
poupa mais consultas e fica errado por mais tempo; um menor faz o contrário. Não existe número certo, só
a pergunta sobre o que perde um visitante que vê um valor velho.
