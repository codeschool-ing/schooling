---
title: O Redis a partir da aplicação
version: 1
---

O `redis-cli` é para olhar. A aplicação fala com o Redis por uma biblioteca cliente, e para Python é a
`redis-py`, que o Ubuntu empacota como `python3-redis` e a aula 1 instalou. **Todo programa das aulas 8 a 11 é salvo em `~/work`**, com o nome escrito acima dele, e rodado de
lá. Eles chegam ao banco da loja por um módulo pequeno, o `catalogue.py`, que faz o que a loja faz:
dorme 120 milissegundos antes de cada consulta e conta as consultas que fez, para que um programa
possa dizer quantas vezes chegou ao banco. Crie o diretório e salve o módulo primeiro:

```sh
mkdir -p ~/work
```

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [{"code": "\"\"\"The bookshop's database, as a module, for the cache code of lessons 8 to 11.\n\nEvery call sleeps QUERY_MS first, as the shop's API does, and counts itself in\n`queries`, so a script can say how many times it reached the database.\"\"\"\nimport sqlite3, threading, time\n\nDB = \"/var/lib/shop/catalogue.db\"\nQUERY_MS = 120\nqueries = 0\n_lock = threading.Lock()\n\n\ndef get_book(book_id):\n    global queries\n    time.sleep(QUERY_MS / 1000)\n    with _lock:\n        queries += 1\n    with sqlite3.connect(DB) as db:\n        db.row_factory = sqlite3.Row\n        row = db.execute(\"SELECT * FROM books WHERE id = ?\", (book_id,)).fetchone()\n        return dict(row) if row else None\n\n\ndef set_price(book_id, price_cents):\n    with sqlite3.connect(DB) as db:\n        db.execute(\"UPDATE books SET price_cents = ?, updated_at = ? WHERE id = ?\",\n                   (price_cents, int(time.time()), book_id))\n", "note": "**O banco da loja, do jeito lento.** Toda chamada dorme antes e se conta em `queries`."}]}
```

O `set_price` grava no banco como você, e é para isso que serviu o grupo `shop` da aula 1.

Este programa guarda o livro que o `catalogue.py` lê do banco lento, o lê de volta e atualiza os mais
vendidos:

```schooling-example
{"language": "python", "file": "redis_books.py", "parts": [{"code": "import json\n\nimport redis\n\nfrom catalogue import get_book\n\n", "note": "`redis` é a biblioteca cliente; `catalogue` é o banco lento do curso, em `~/work`."}, {"code": "r = redis.Redis(host=\"127.0.0.1\", port=6379, decode_responses=True)\n\n", "note": "**Um objeto de conexão para o programa inteiro.** `decode_responses=True` transforma os bytes que o Redis devolve em strings do Python."}, {"code": "book = get_book(2)\nr.set(\"book:2:json\", json.dumps(book), ex=60)\nprint(\"ttl\", r.ttl(\"book:2:json\"))\n\n", "note": "Lê o livro do banco, do jeito lento, e guarda como JSON com `ex=60`: **todo valor em cache ganha um tempo de vida.** O `ttl` o lê de volta."}, {"code": "cached = json.loads(r.get(\"book:2:json\"))\nprint(cached[\"title\"], cached[\"price_cents\"])\n\n", "note": "Ler de volta é um `GET` e um `json.loads`; o banco não participa."}, {"code": "with r.pipeline() as pipe:\n    for book_id in (1, 3, 5):\n        pipe.zincrby(\"bestsellers\", 1, f\"book:{book_id}\")\n    pipe.zrevrange(\"bestsellers\", 0, 2, withscores=True)\n    print(pipe.execute()[-1])\n", "note": "**Um pipeline manda vários comandos numa ida e volta** e devolve todas as respostas no fim; a última resposta é o ranking."}], "output": "ttl 60\nGrande Sertão: Veredas 8990\n[('book:9', 5.0), ('book:2', 5.0), ('book:4', 4.0)]\n"}
```

Rode a partir de `~/work`, onde mora o `catalogue.py`, e veja o que ele deixou:

```
ana@web:~/work$ python3 redis_books.py
ttl 60
Grande Sertão: Veredas 8990
[('book:9', 5.0), ('book:2', 5.0), ('book:4', 4.0)]
ana@web:~/work$ redis-cli GET book:2:json
{"id": 2, "title": "Grande Sert\u00e3o: Veredas", "author": "Jo\u00e3o Guimar\u00e3es Rosa", "price_cents": 8990, "stock": 4, "updated_at": 1788267600}
```

O valor é uma string de JSON, exatamente o texto que o `json.dumps` produziu, com os acentos escapados
como `\u00e3`, que é o padrão do JSON e custa alguns bytes por acento. **O Redis não sabe nem se importa
que é JSON**: para o Redis são bytes com um tempo de vida. Esse é o jeito comum de guardar um objeto que
é sempre lido e gravado inteiro, e um hash, da seção anterior, é o jeito comum para um cujos campos
mudam separados.

Dois hábitos deste programa seguem para todas as aulas depois dela. **Todo valor em cache ganha um tempo
de vida**, aqui `ex=60`, para que, dê errado o que der, o valor vá embora. E **comandos relacionados vão
num pipeline**, para que uma dúzia de comandos custe uma ida e volta; no loopback a diferença é pequena,
e numa rede até um Redis gerenciado é a maior parte do tempo que uma aplicação passa ali.
