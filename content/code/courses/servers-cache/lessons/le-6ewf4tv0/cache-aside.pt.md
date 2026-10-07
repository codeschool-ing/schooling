---
title: Cache-aside, o padrão que você já escreveu
version: 1
---

As aulas 8 e 9 guardaram valores e os leram de volta. O que transforma isso num cache é uma regra sobre
**quem o enche e quando**, e a regra que a maioria das aplicações usa se chama **cache-aside**: a
aplicação pergunta primeiro ao cache e, num erro de cache, lê ela mesma o banco e deixa uma cópia para o
próximo leitor. O cache fica ao lado do caminho da aplicação, e não dentro dele, que é de onde vem o
nome.

```schooling-example
{"language": "python", "file": "bookcache.py", "parts": [{"code": "import json\nimport time\n\nimport redis\n\nimport catalogue\n\n", "note": "`catalogue` é o banco lento, 120 ms por consulta."}, {"code": "r = redis.Redis(decode_responses=True)\nTTL = 300\n\n\n", "note": "Uma conexão e um tempo de vida para toda cópia, cinco minutos."}, {"code": "def get_book(book_id):\n    key = f\"book:{book_id}\"\n    cached = r.get(key)\n    if cached is not None:\n        return json.loads(cached)\n    book = catalogue.get_book(book_id)\n    r.set(key, json.dumps(book), ex=TTL)\n    return book\n\n\n", "note": "**Cache-aside.** Pergunta ao cache; num erro de cache, lê o banco e deixa uma cópia com tempo de vida."}, {"code": "def update_price(book_id, price_cents):\n    catalogue.set_price(book_id, price_cents)\n    r.delete(f\"book:{book_id}\")\n\n\n", "note": "**Uma gravação muda o banco primeiro, depois apaga a cópia.** A seção seguinte diz por que apaga em vez de gravar."}, {"code": "if __name__ == \"__main__\":\n    r.delete(\"book:2\")\n    for attempt in (1, 2, 3):\n        start = time.perf_counter()\n        book = get_book(2)\n        ms = (time.perf_counter() - start) * 1000\n        print(f\"read {attempt}: {book['price_cents']} in {ms:.1f} ms, queries {catalogue.queries}\")\n", "note": "Rodado como programa, lê o livro 2 três vezes e cronometra cada leitura."}], "output": "read 1: 8990 in 121.1 ms, queries 1\nread 2: 8990 in 0.2 ms, queries 1\nread 3: 8990 in 0.1 ms, queries 1\n"}
```

Três leituras do livro 2, começando do zero:

```
ana@web:~/work$ python3 bookcache.py
read 1: 8990 in 121.1 ms, queries 1
read 2: 8990 in 0.2 ms, queries 1
read 3: 8990 in 0.1 ms, queries 1
ana@web:~/work$ redis-cli TTL book:2
300
```

**A primeira leitura pagou os 120 milissegundos do banco e as duas seguintes pagaram um décimo de
milissegundo**, com a contagem de consultas ainda em um. A cópia agora tem 300 segundos de vida. Esse
número é toda a honestidade deste padrão sobre mudanças: o que quer que o banco faça nos próximos cinco
minutos, o cache não vai ficar sabendo sozinho.

O cache-aside tem duas propriedades que vale nomear. **O cache guarda só o que alguém pediu**, então a
memória vai para os livros que de fato são lidos. E **um cache fora do ar custa velocidade, não
correção**: se o Redis para de responder, uma aplicação escrita assim pode voltar a ler o banco toda
vez, mais devagar mas certa. As duas coisas explicam por que ele é o padrão, e o resto desta aula trata
da única coisa que ele deixa em aberto, o que acontece quando os dados mudam.
