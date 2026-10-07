---
title: Quando a memória acaba
version: 1
---

Tudo o que o Redis guarda está na memória, e a memória acaba. O que o Redis faz quando ela acaba é uma
configuração, `maxmemory-policy`, e escolhê-la é o momento em que se diz ao Redis se ele é um cache ou um
banco de dados. Para ver os dois comportamentos, dê a ele dois megabytes e um programinha que grava
valores de um kilobyte até ser parado:

```python
import sys

import redis

r = redis.Redis()
written = 0
try:
    for i in range(int(sys.argv[1])):
        r.set(f"filler:{i}", "x" * 1000)
        written += 1
except redis.exceptions.ResponseError as e:
    print("error after", written, "keys:", e)
print("written", written)
```

```
ana@web:~/work$ redis-cli CONFIG SET maxmemory 2mb; redis-cli CONFIG GET maxmemory-policy
OK
maxmemory-policy
noeviction
ana@web:~/work$ python3 fill.py 5000
error after 401 keys: OOM command not allowed when used memory > 'maxmemory'.
written 401
```

**`noeviction` é o padrão do Ubuntu, e quer dizer: recusar gravações.** Depois de 401 chaves, toda
gravação falha com `OOM command not allowed`, e as leituras continuam funcionando. Para o Redis usado
como banco, isso está certo: perder dados em silêncio seria pior que falhar alto. Para um cache está
errado, porque um cache que não aceita entradas novas faz a aplicação falhar por falta de uma cópia que
ela poderia ter buscado de novo.

```
ana@web:~/work$ redis-cli CONFIG SET maxmemory-policy allkeys-lru && python3 fill.py 5000
OK
written 5000
ana@web:~/work$ redis-cli INFO stats | grep -E '^evicted_keys'; redis-cli DBSIZE; redis-cli INFO memory | grep -E '^(used_memory_human|maxmemory_human|maxmemory_policy):'
evicted_keys:4608
402
used_memory_human:2.00M
maxmemory_human:2.00M
maxmemory_policy:allkeys-lru
ana@web:~/work$ redis-cli EXISTS bestsellers book:2
0
```

Com **`allkeys-lru`**, o Redis abre espaço despejando as chaves **usadas há mais tempo**, entre todas as
chaves, e cada uma das cinco mil gravações deu certo. 4.608 chaves foram despejadas para abrir espaço, a
memória está no limite, e os mais vendidos e o hash do livro das seções anteriores também sumiram,
porque ninguém os tinha lido recentemente. É o que um cache pode fazer e um banco não pode.

| política | quando a memória enche | para |
|---|---|---|
| `noeviction` | recusa gravações com erro | o Redis como banco ou fila |
| `allkeys-lru` | despeja a chave usada há mais tempo | um cache em que qualquer chave pode sair |
| `allkeys-lfu` | despeja a chave usada com menos frequência | um cache com um conjunto estável de chaves populares |
| `volatile-lru` / `volatile-ttl` | despeja só chaves com tempo de vida | um Redis com cache e dados juntos |

**Um Redis só para cache e dados é a armadilha da última linha.** Só funciona se toda chave de cache
tiver tempo de vida e nenhuma chave de dado tiver, e o primeiro valor em cache gravado sem `ex=` é um que
nunca poderá ser despejado. Dois Redis, um por papel, cada um com a política certa, custam alguns
megabytes e eliminam a questão.
