---
title: Um cache cheio, e uma manada na porta
version: 1
---

**Um cache tem um limite de memória, e o que ele faz ao chegar nele é uma configuração chamada
política de despejo.** Ou ele recusa escritas novas, ou joga chaves antigas fora para abrir espaço, e
quais chaves ele pode jogar fora é o resto da configuração. Errar nisso não parece um erro no cache.
Parece usuários deslogados ao acaso, ou um cache que de repente recusa toda escrita.

O Redis local não tem limite até você dar um. Dê 2 MB, pouco o bastante para encher em um segundo:

```
ana@laptop:~/gcp$ redis-cli CONFIG GET maxmemory-policy
1) "maxmemory-policy"
2) "noeviction"
ana@laptop:~/gcp$ redis-cli CONFIG SET maxmemory 2mb
OK
```

**`noeviction` é o padrão do próprio Redis**, e quer dizer o que diz: com a memória cheia, uma
escrita falha. Para encher o cache, aqui está um programa que escreve chaves de 1.000 bytes cada e
conta as escritas que o Redis recusa. Salve-o em `~/gcp` como `fill.py`:

```python
import sys

import redis

cache = redis.Redis(host='127.0.0.1', port=6379)
first, count = int(sys.argv[1]), int(sys.argv[2])
written = refused = 0
for i in range(first, first + count):
    try:
        cache.set(f'filler:{i}', 'x' * 1000)
        written += 1
    except redis.exceptions.OutOfMemoryError:
        refused += 1
print(f'written {written}, refused {refused}')
```

```
ana@laptop:~/gcp$ python3 fill.py 1 3000
written 866, refused 2134
ana@laptop:~/gcp$ redis-cli DBSIZE
(integer) 869
ana@laptop:~/gcp$ redis-cli SET product:p-102 990
(error) OOM command not allowed when used memory > 'maxmemory'.
```

**O Redis aceitou 866 chaves e recusou as outras 2.134**, e depois recusou uma escrita que
importava, o preço de um produto, com o erro que o `redis-cli` imprimiu. O `DBSIZE` conta 869 porque
três chaves estavam lá desde as seções anteriores. Nada se perdeu, e nada mais pode ser escrito
também. Para um cache esse é o comportamento errado: o programa tem de tratar toda escrita como uma
que pode falhar, e o cache para de fazer cache.

```
ana@laptop:~/gcp$ redis-cli CONFIG SET maxmemory-policy volatile-lru
OK
ana@laptop:~/gcp$ python3 fill.py 3001 1000
written 0, refused 1000
```

**`volatile-lru` despeja só chaves que têm tempo de vida**, a usada há mais tempo primeiro. Nenhuma
das chaves de enchimento tem, então não havia nada que ele pudesse despejar, e as 1.000 escritas
foram recusadas exatamente como no `noeviction`. Isso importa no Google Cloud, porque **o Memorystore for Redis
documenta `volatile-lru` como sua política padrão**. Um programa que escreve chaves sem validade numa
instância do Memorystore deixada no padrão encontra essa recusa, e a regra da seção anterior, um TTL
em toda chave, é o que a mantém longe. A política é uma das configurações do Redis que o Memorystore
deixa mudar, e a mudança é um comando, não executado aqui:

```sh
gcloud redis instances update quitanda-cache --region=southamerica-east1 \
  --update-redis-config maxmemory-policy=allkeys-lru
```

```
ana@laptop:~/gcp$ redis-cli CONFIG SET maxmemory-policy allkeys-lru
OK
ana@laptop:~/gcp$ python3 fill.py 3001 3000
written 3000, refused 0
ana@laptop:~/gcp$ redis-cli DBSIZE
(integer) 830
ana@laptop:~/gcp$ redis-cli INFO stats | grep evicted_keys
evicted_keys:3039
ana@laptop:~/gcp$ redis-cli EXISTS filler:1
(integer) 0
```

**`allkeys-lru` despeja qualquer chave, a usada há mais tempo primeiro**, e as 3.000 escritas deram
certo. O cache ficou no limite jogando fora 3.039 chaves, e agora guarda 830; `filler:1`, uma das
mais antigas, sumiu. Essa é a política de um cache que só guarda cópias: o que ele esquecer, o banco
ainda tem. O Redis encontra a "usada há mais tempo" sorteando algumas chaves de cada vez em vez de
manter todas em ordem, então a chave que ele despeja é antiga, mas nem sempre a mais antiga.

## Sessões não são cópias

**Uma sessão de login guardada num cache com `allkeys-lru` é uma sessão que o cache pode jogar
fora**, e o usuário dono dela é deslogado no meio de uma compra sem motivo que ele consiga ver. Uma
sessão não tem cópia num banco para recorrer; ela é o original. Se a Quitanda guarda as sessões no
Memorystore, elas vão para uma instância do nível Standard só delas, dimensionada para nunca chegar
ao limite, com `noeviction` para que um cache cheio falhe alto em vez de esquecer, e com a réplica
em outra zona. Ou vão para o Firestore, onde um documento fica até algo apagá-lo e as políticas de
tempo de vida do próprio Firestore cuidam de expirar.

## A manada

**Quando uma chave popular expira, toda requisição que chega antes de ela ser reconstruída falta ao
mesmo tempo**, e cada uma delas roda a mesma consulta no banco. Essa é a manada (thundering herd), e
ela acontece no pior momento: quanto mais movimentada a página, maior a manada. O programa abaixo
manda 50 requisições por uma página no mesmo instante, uma vez do jeito ingênuo e uma vez com uma
trava. Uma pausa de 200 ms faz o papel de uma consulta lenta, para que as requisições se sobreponham
como num site movimentado. Salve-o como `~/gcp/herd.py`:

```schooling-example
{"language": "python", "file": "herd.py", "parts": [{"code": "import sys\nimport threading\nimport time\n\nimport redis\n\ncache = redis.Redis(host='127.0.0.1', port=6379, decode_responses=True)\nreads = 0\ncounting = threading.Lock()\n\n\n", "note": "Um cliente para todas as threads; o pacote `redis` compartilha as conexões entre elas com segurança. `reads` conta as consultas, e `counting` impede que duas threads somem nele ao mesmo tempo."}, {"code": "def slow_query():\n    global reads\n    with counting:\n        reads += 1\n    time.sleep(0.2)\n    return 'catalogue page 1'\n\n\n", "note": "O banco de dados, para este programa: toda chamada é contada, e a pausa de 0,2 segundo faz o papel de uma consulta que leva 200 ms."}, {"code": "def naive():\n    page = cache.get('page:1')\n    if page is None:\n        page = slow_query()\n        cache.set('page:1', page, ex=300)\n    return page\n\n\n", "note": "Cache-aside exatamente como na seção anterior. Toda requisição que encontra a chave faltando roda a consulta."}, {"code": "def with_lock():\n    while True:\n        page = cache.get('page:1')\n        if page is not None:\n            return page\n        if cache.set('lock:page:1', 'mine', nx=True, ex=10):\n            page = slow_query()\n            cache.set('page:1', page, ex=300)\n            cache.delete('lock:page:1')\n            return page\n        time.sleep(0.05)\n\n\n", "note": "**O mesmo, com uma trava na frente da consulta.** `nx=True` grava a trava só se ninguém a tiver, então uma requisição roda a consulta e as outras esperam 50 ms e olham o cache de novo."}, {"code": "fetch = with_lock if sys.argv[1:] == ['lock'] else naive\ncache.delete('page:1')\nthreads = [threading.Thread(target=fetch) for _ in range(50)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nprint(f'{len(threads)} requests, {reads} database reads')\n", "note": "A página começa faltando, como no segundo depois de a chave expirar, e 50 threads pedem por ela de uma vez. `python3 herd.py` é o jeito ingênuo e `python3 herd.py lock` o outro."}]}
```

```
ana@laptop:~/gcp$ python3 herd.py
50 requests, 50 database reads
ana@laptop:~/gcp$ python3 herd.py lock
50 requests, 1 database reads
```

**Cinquenta requisições fizeram cinquenta leituras no banco, e com a trava fizeram uma.** A trava é
uma chave comum do Redis gravada com `nx=True`, que só dá certo se a chave ainda não existir, então
exatamente uma requisição ganha e reconstrói a página enquanto as outras 49 esperam e leem a cópia
que ela deixa. O `ex=10` da própria trava é o que impede uma requisição que morra segurando a trava
de bloquear todo mundo para sempre.

Dois hábitos menores também ajudam. **Dê a chaves do mesmo tipo vidas um pouco diferentes**, 300
segundos mais alguns ao acaso, para que mil chaves gravadas pela mesma importação não expirem todas
no mesmo segundo. E para as poucas páginas que estão sempre movimentadas, renove a cópia pouco antes
de ela expirar em vez de esperar a falta.
