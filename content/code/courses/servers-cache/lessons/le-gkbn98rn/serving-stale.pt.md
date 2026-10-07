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

```schooling-example
{"language": "python", "file": "swrcache.py", "parts": [{"code": "import json\nimport threading\nimport time\n\nimport redis\n\nimport catalogue\n\nr = redis.Redis(decode_responses=True)\nFRESH, STALE = 300, 3600\nREFRESH_MS = 2000\n\n\ndef load(book_id):\n    book = catalogue.get_book(book_id)\n    entry = {\"book\": book, \"fresh_until\": time.time() + FRESH}\n    r.set(f\"book:{book_id}\", json.dumps(entry), ex=FRESH + STALE)\n    return book\n\n\ndef get_book(book_id):\n    cached = r.get(f\"book:{book_id}\")\n    if cached is None:\n        return load(book_id)\n    entry = json.loads(cached)\n    if entry[\"fresh_until\"] < time.time():\n        if r.set(f\"refresh:book:{book_id}\", 1, nx=True, px=REFRESH_MS):\n            threading.Thread(target=load, args=(book_id,)).start()\n    return entry[\"book\"]\n", "note": "Serve uma cópia velha na hora e a atualiza em segundo plano, no máximo uma vez a cada dois segundos."}]}
```

A marca de atualização é um lock que ninguém libera: **ela simplesmente vence depois de dois segundos**,
o que também limita as atualizações de um livro a uma a cada dois segundos, mesmo que uma atualização
falhe.

Para ver, este programa planta uma cópia que ficou velha há um minuto, com o preço antigo, depois muda o
preço no banco e manda cinquenta leitores:

```schooling-example
{"language": "python", "file": "stale_demo.py", "parts": [{"code": "import json\nimport threading\nimport time\n\nimport catalogue\nimport swrcache\n\nbook = catalogue.get_book(2)\nstale = {\"book\": dict(book, price_cents=8990), \"fresh_until\": time.time() - 60}\nswrcache.r.set(\"book:2\", json.dumps(stale), ex=3600)\ncatalogue.set_price(2, 7990)\n\nprices, slowest = set(), 0.0\nbefore = catalogue.queries\n\n\ndef visitor():\n    global slowest\n    start = time.perf_counter()\n    prices.add(swrcache.get_book(2)[\"price_cents\"])\n    slowest = max(slowest, (time.perf_counter() - start) * 1000)\n\n\nthreads = [threading.Thread(target=visitor) for _ in range(50)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nprint(f\"50 readers: prices {sorted(prices)}, slowest {slowest:.1f} ms\")\ntime.sleep(0.3)\nprint(f\"a moment later: {swrcache.get_book(2)['price_cents']}, queries {catalogue.queries - before}\")\n", "note": "Planta uma cópia que ficou velha há um minuto, muda o preço e manda cinquenta leitores."}]}
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
