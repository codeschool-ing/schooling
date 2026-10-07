---
title: O Memcached a partir do Python
version: 1
---

O cliente de Python é o `pymemcache`, empacotado como `python3-pymemcache`. O Memcached guarda bytes e
um número de flags, então **o cliente decide como um objeto vira bytes**, e as flags são onde ele anota o
que fez. Este programa guarda livros como JSON e se recusa a ler de volta qualquer coisa que não tenha
gravado:

```schooling-example
{"language": "python", "file": "memcache_books.py", "parts": [{"code": "import json\n\nfrom pymemcache.client.base import Client\n\nimport catalogue\n\n", "note": "`catalogue` é o banco lento do curso, em `~/work`."}, {"code": "JSON = 1\n\n\nclass JsonSerde:\n    def serialize(self, key, value):\n        return json.dumps(value).encode(), JSON\n\n    def deserialize(self, key, value, flags):\n        if flags != JSON:\n            raise ValueError(f\"{key}: flags {flags}, not JSON\")\n        return json.loads(value)\n\n\n", "note": "**Um serde transforma um valor em bytes e um número de flags, e de volta.** As flags registram que os bytes são JSON, e a leitura recusa qualquer outra coisa em vez de adivinhar."}, {"code": "mc = Client((\"127.0.0.1\", 11211), serde=JsonSerde(), default_noreply=False)\n\n", "note": "`default_noreply=False` faz todo armazenamento esperar a resposta do Memcached; o fim desta seção explica por quê."}, {"code": "mc.set(\"book:2\", catalogue.get_book(2), expire=60)\nprint(mc.get(\"book:2\")[\"title\"])\n\n", "note": "Uma leitura lenta do banco, guardada com tempo de vida de sessenta segundos, e lida de volta do Memcached."}, {"code": "print(\"add again:\", mc.add(\"book:2\", {}))\n\n", "note": "`add` numa chave que existe: o Memcached responde `NOT_STORED`, que chega aqui como `False`."}, {"code": "mc.set_many({f\"book:{i}\": catalogue.get_book(i) for i in (3, 4, 5)}, expire=60)\nfound = mc.get_many([\"book:3\", \"book:4\", \"book:99\"])\nprint(sorted(found), \"queries:\", catalogue.queries)\n", "note": "**Várias chaves numa ida e volta**, nos dois sentidos. O `book:99` nunca foi guardado."}], "output": "Grande Sertão: Veredas\nadd again: False\n['book:3', 'book:4'] queries: 4\n"}
```

```
ana@web:~/work$ python3 memcache_books.py
Grande Sertão: Veredas
add again: False
['book:3', 'book:4'] queries: 4
ana@web:~/work$ printf 'get book:2\r\n' | nc -q1 127.0.0.1 11211 | cut -c1-70
VALUE book:2 1 151
{"id": 2, "title": "Grande Sert\u00e3o: Veredas", "author": "Jo\u00e3o
END
```

Em `VALUE book:2 1 151`, o `1` são as flags que o serde escolheu e 151 é o tamanho do JSON. O `book:99`
nem aparece no resultado, porque **o `get_many` devolve só o que encontrou**: um erro de cache é uma chave
ausente do dicionário, não um `None`. O `queries: 4` conta as idas ao banco, uma para o livro 2 e três
para os outros.

O cliente foi criado com `default_noreply=False`, e isso importa mais do que parece:

```
ana@web:~/work$ python3 -c 'from pymemcache.client.base import Client; mc = Client(("127.0.0.1", 11211)); print(mc.add("book:2", b"{}"), mc.add("book:2", b"{}", noreply=False))'
True False
```

**O `pymemcache` envia os armazenamentos com `noreply`, a não ser que lhe digam o contrário.** Ele não
espera a resposta, então o `add` devolveu `True` tenha guardado algo ou não; o mesmo `add` esperando a
resposta disse `False`. Não esperar poupa uma ida e volta por gravação, e esconde junto o `NOT_STORED`,
o `object too large for cache` e toda outra recusa. Para um cache que só é preenchido, pode ser uma troca
justa. Para o `add` usado como lock, ou para o `cas`, está errado toda vez, porque a resposta é a razão
de ser desses comandos.
