---
title: Um leitor busca, os outros esperam
version: 1
---

A correção direta é um lock: **o primeiro leitor a errar o cache o pega e busca; os outros esperam a
cópia.** A aula 8 apresentou a ferramenta, o `SET … NX`, que só um cliente consegue ganhar. Aqui ele
ganha um tempo de vida próprio e um token, por motivos que a última transcrição desta seção mostra:

```schooling-example
{"language": "python", "file": "lockcache.py", "parts": [{"code": "import json\nimport secrets\nimport time\n\nimport redis\n\nimport catalogue\n\n"}, {"code": "r = redis.Redis(decode_responses=True)\nTTL = 300\nLOCK_MS = 2000\n\n", "note": "A cópia vive cinco minutos; **o lock vive dois segundos no máximo**."}, {"code": "RELEASE = r.register_script(\"\"\"\nif redis.call(\"get\", KEYS[1]) == ARGV[1] then\n    return redis.call(\"del\", KEYS[1])\nend\nreturn 0\n\"\"\")\n\n\n", "note": "**Libere só o próprio lock.** O script compara o token e apaga num passo só, dentro do Redis."}, {"code": "def get_book(book_id):\n    key, lock = f\"book:{book_id}\", f\"lock:book:{book_id}\"\n    while True:\n        cached = r.get(key)\n        if cached is not None:\n            return json.loads(cached)\n", "note": "Um acerto volta na hora, como na aula 10."}, {"code": "        token = secrets.token_hex(8)\n        if r.set(lock, token, nx=True, px=LOCK_MS):\n", "note": "Um erro tenta pegar o lock: `nx=True` quer dizer que só um leitor ganha, `px` dá a ele um tempo de vida."}, {"code": "            try:\n                cached = r.get(key)\n                if cached is not None:\n                    return json.loads(cached)\n                book = catalogue.get_book(book_id)\n                r.set(key, json.dumps(book), ex=TTL)\n                return book\n            finally:\n                RELEASE(keys=[lock], args=[token])\n", "note": "O vencedor olha mais uma vez, busca, guarda e libera o lock aconteça o que acontecer."}, {"code": "        time.sleep(0.02)\n", "note": "Todos os outros esperam vinte milissegundos e começam de novo do topo."}]}
```

```
ana@web:~/work$ python3 stampede.py 50 lockcache
lockcache, readers at once: 50, database queries: 1, 145 ms
```

**Cinquenta leitores, uma consulta**, e a rajada levou o mesmo tempo que uma leitura: os outros quarenta
e nove passaram esse tempo esperando em passos de vinte milissegundos e depois encontraram a cópia. Essa
espera é o custo desta abordagem, e todo leitor que chega durante uma atualização a paga.

Três detalhes carregam o peso, e cada um responde a um jeito de isto dar errado:

- **O lock tem tempo de vida**, `px=LOCK_MS`. Um leitor que pega o lock e morre, derrubado por um deploy
  ou preso numa chamada de rede, não pode deixar todo mundo esperando para sempre.
- **O token** garante que um leitor libera só o próprio lock. Sem ele, um leitor que demorasse mais que
  o tempo de vida do lock apagaria o lock que outro pegou depois que o dele venceu. A conferência e o
  apagamento rodam como um script Lua só, então nada acontece entre os dois.
- **A segunda olhada dentro do lock.** Um leitor que esperou o lock pode pegá-lo logo depois de o dono
  anterior guardar a cópia, e buscar de novo seria uma consulta desperdiçada.

O tempo de vida é o que vale ver funcionando. Aqui um lock fica para trás, deixado por um leitor que
caiu, e ninguém o libera:

```
ana@web:~/work$ redis-cli SET lock:book:2 crashed PX 2000 && python3 stampede.py 50 lockcache
OK
lockcache, readers at once: 50, database queries: 1, 2043 ms
```

**Todo leitor esperou os dois segundos inteiros** até o lock abandonado vencer, e então um deles buscou.
Dois segundos é o pior caso que este código permite, e deve ser escolhido como tal: longo o bastante para
uma consulta lenta terminar, curto o bastante para que um dono caído custe uma pausa e não uma queda.
