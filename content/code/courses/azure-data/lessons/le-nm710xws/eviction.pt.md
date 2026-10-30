---
title: Quando o cache enche
version: 1
---

**Um cache é menor que os dados por trás dele de propósito, e a política de despejo decide o que
acontece quando ele enche.** O Redis tem oito, nomeadas por duas escolhas: que chaves podem sair, todas
ou só as *voláteis* que têm time to live, e como escolher entre elas, a usada há mais tempo, a menos
frequente, ao acaso ou a que expira mais cedo. A nona resposta é `noeviction`, que guarda tudo e recusa
escritas novas.

O `fill.py` põe o Redis local em 4 MB, escolhe uma política, e grava 10.000 valores de 1.000 bytes, com
ou sem time to live, depois informa quantas escritas foram recusadas, quantas chaves restaram e quantas
foram despejadas. Ele usa o `resp.py` da seção anterior:

`fill.py`:

```python
import sys

from resp import Redis

policy, with_ttl = sys.argv[1], "--ttl" in sys.argv
r = Redis()
r("FLUSHALL")
r("CONFIG", "SET", "maxmemory", "4mb")
r("CONFIG", "SET", "maxmemory-policy", policy)
r("CONFIG", "RESETSTAT")

written, refused = 0, 0
for i in range(10_000):
    args = ["SET", f"product:{i:05d}", "x" * 1000] + (["EX", 3600] if with_ttl else [])
    try:
        r(*args)
        written += 1
    except RuntimeError as e:
        refused += 1
        first = first if refused > 1 else str(e)
stats = dict(l.split(":", 1) for l in r("INFO", "stats").splitlines() if ":" in l)
print(f"{policy:12} ttl={'yes' if with_ttl else 'no ':3} written {written:5}  refused {refused:5}  "
      f"kept {r('DBSIZE'):5}  evicted {stats['evicted_keys']}")
if refused:
    print("   first refusal:", first)
```

```
ana@laptop:~/azure$ python fill.py noeviction
noeviction   ttl=no  written  2987  refused  7013  kept  2987  evicted 0
   first refusal: OOM command not allowed when used memory > 'maxmemory'.
ana@laptop:~/azure$ python fill.py allkeys-lru
allkeys-lru  ttl=no  written 10000  refused     0  kept  2955  evicted 7022
ana@laptop:~/azure$ python fill.py volatile-lru
volatile-lru ttl=no  written  2987  refused  7013  kept  2987  evicted 0
   first refusal: OOM command not allowed when used memory > 'maxmemory'.
ana@laptop:~/azure$ python fill.py volatile-lru --ttl
volatile-lru ttl=yes written 10000  refused     0  kept  2881  evicted 7096
```

**O `noeviction` recusou 7.013 das 10.000 escritas** com erro de falta de memória, depois que 2.987
valores encheram os 4 MB. Para um cache essa é a resposta errada: um programa escrito como cache-aside
agora falha em *guardar no cache* e, se não tratar o erro, falha a requisição.

**O `allkeys-lru` aceitou toda escrita e despejou 7.022 chaves**, as lidas há mais tempo, guardando
2.955. Para um cache em que toda chave é cópia de algo do Cosmos DB, essa é a política que combina com a
ideia: qualquer coisa pode sair, e o banco ainda tem.

**O `volatile-lru` sem time to live se comporta exatamente como o `noeviction`**, as mesmas 2.987
guardadas e 7.013 recusadas, porque ele só pode despejar chaves que têm um, e nenhuma tinha. Com `--ttl`
ele despejou 7.096 e não recusou nada. Essa é a política que a documentação dá como padrão do Azure
Cache for Redis, e é uma armadilha para um programa que grava chaves sem time to live: o cache enche, não
despeja nada, e recusa escritas. Um cache usado só como cache quer `allkeys-lru`, ou toda chave gravada
com expiração.

As contagens exatas mudam algumas chaves de uma execução para outra, porque o Redis amostra candidatas
em vez de procurar em todas as chaves; o formato não muda.
