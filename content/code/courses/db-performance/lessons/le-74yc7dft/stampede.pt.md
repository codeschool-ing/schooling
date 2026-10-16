---
title: A debandada, quando some uma chave quente
version: 1
---

Um cache muda o formato da carga sobre um banco. Sem ele, a carga é proporcional ao tráfego. Com
ele, a carga são as faltas, e faltas não chegam espalhadas: chegam juntas, **no momento em que uma
chave popular expira**. A crença a corrigir é a de que um cache protege o banco das suas consultas
mais pesadas. Protege entre uma expiração e outra, e a cada expiração pode mandar todas de uma vez.

## Uma chave, cinquenta leitores

A tela de operações da aula 2 conta os pedidos pendentes, uma varredura sequencial de `orders` que
levou 222 milissegundos por execução sob a carga daquela aula, e todo mundo que tem a tela aberta a
recarrega. É a chave ideal para pôr em cache: um valor só, lido por todos, mudando devagar. Com
trinta segundos de cache, o banco roda a contagem duas vezes por minuto em vez de várias vezes por
segundo.

Agora acompanhe o momento em que a chave expira. Cinquenta pedidos chegam nos milissegundos
seguintes. Cada um olha no cache, não acha nada, e faz o que o cache-aside manda: roda a contagem.
Cinquenta cópias da mesma varredura sequencial começam juntas numa máquina com quatro processadores,
e cada uma roda bem mais devagar do que rodaria sozinha, por causa das outras quarenta e nove. Isso é
uma **debandada no cache** (cache stampede, ou thundering herd), e o programa abaixo a encena.
Cinquenta threads esperam numa barreira e são soltas juntas sobre uma chave vazia, com o cache-aside
puro ou com o conserto descrito depois. Salve-o como `stampede.py`:

```python
# stampede.py: fifty requests for one hot key, at the moment it is missing.
import statistics, sys, threading, time
import psycopg, redis

cache = redis.Redis()
KEY, LOCK = "pending-count", "lock:pending-count"
queries = 0
counted = threading.Lock()

def count_pending():
    global queries
    with counted:
        queries += 1
    with psycopg.connect("dbname=market") as db:
        return db.execute("SELECT count(*) FROM orders WHERE status = 'pending'").fetchone()[0]

def plain():
    value = cache.get(KEY)
    if value is None:
        value = count_pending()
        cache.set(KEY, value, ex=30)
    return int(value)

def single_flight():
    while True:
        value = cache.get(KEY)
        if value is not None:
            return int(value)
        if cache.set(LOCK, 1, nx=True, ex=10):  # only one caller gets the lock
            try:
                value = cache.get(KEY)  # filled while we were asking for the lock?
                if value is None:
                    value = count_pending()
                    cache.set(KEY, value, ex=30)
                return int(value)
            finally:
                cache.delete(LOCK)
        time.sleep(0.01)  # somebody else is computing it: wait and look again

read = single_flight if sys.argv[1:] == ["single-flight"] else plain
cache.delete(KEY, LOCK)
start, times = threading.Barrier(50), []

def request():
    start.wait()
    t = time.perf_counter()
    read()
    times.append(1000 * (time.perf_counter() - t))

threads = [threading.Thread(target=request) for _ in range(50)]
for t in threads: t.start()
for t in threads: t.join()
print(f"{read.__name__}: 50 requests, queries to the database: {queries}, "
      f"median {statistics.median(times):.0f} ms, slowest {max(times):.0f} ms")
```

Zere o `pg_stat_statements` para que ele conte só isto, rode a versão pura e pergunte ao placar:

```
ana@vm:~$ psql -q market -c 'SELECT pg_stat_statements_reset()' > /dev/null
ana@vm:~$ python3 stampede.py
plain: 50 requests, queries to the database: 50, median 1546 ms, slowest 1712 ms
ana@vm:~$ psql market -c "SELECT calls, round(mean_exec_time) AS mean_ms FROM pg_stat_statements WHERE query LIKE '%FROM orders WHERE status%'"
 calls | mean_ms 
-------+---------
    50 |    1321
(1 row)

Time: 1.065 ms
```

**Cinquenta pedidos, cinquenta consultas.** O pedido do meio esperou **1546 milissegundos** e o mais
lento **1712**, por uma contagem que leva 55 sozinha, como mostra a próxima rodada, e o placar
concorda do lado do servidor: **50 chamadas**, com média de **1321 milissegundos** cada. Por um
segundo e meio o banco não fez nada além de responder a mesma pergunta cinquenta vezes, e todas as
outras consultas da loja esperaram atrás disso. Num site de verdade, as respostas lentas fazem os
clientes tentarem de novo, o que soma pedidos, o que piora a próxima expiração.

## Um voo só

O conserto é deixar **um** pedido recalcular o valor enquanto os outros esperam por ele. A
`single_flight` faz isso com uma trava (lock) no Redis: o `SET` com `nx=True` só dá certo se a chave
não existe, então dos cinquenta exatamente um pega a trava. Esse olha no cache mais uma vez, porque o
valor pode ter chegado enquanto ele pedia a trava, depois roda a consulta, guarda o resultado e solta
a trava. Os outros quarenta e nove dormem dez milissegundos e olham no cache de novo, onde acham o
valor. A trava tem a própria expiração, `ex=10`, para que um processo que morra segurando-a não
bloqueie a chave para sempre.

A segunda olhada dentro da trava importa. Sem ela, um chamador que achou o cache vazio pode pegar a
trava **depois** que o primeiro dono guardou o valor e a soltou, e rodar a consulta uma segunda vez. Uma
trava solta deixa entrar o próximo, então quem a segura precisa conferir se o trabalho ainda é
necessário.

```
ana@vm:~$ psql -q market -c 'SELECT pg_stat_statements_reset()' > /dev/null
ana@vm:~$ python3 stampede.py single-flight
single_flight: 50 requests, queries to the database: 1, median 122 ms, slowest 130 ms
ana@vm:~$ psql market -c "SELECT calls, round(mean_exec_time) AS mean_ms FROM pg_stat_statements WHERE query LIKE '%FROM orders WHERE status%'"
 calls | mean_ms 
-------+---------
     1 |      55
(1 row)

Time: 1.720 ms
```

**Cinquenta pedidos, uma consulta**, o que o placar confirma: **1 chamada**, de **55
milissegundos**. O pedido do meio agora espera **122 milissegundos** e o mais lento **130**: a
consulta única, mais as voltas dos outros conferindo o cache. O banco viu uma contagem em vez de
cinquenta.

## Outros jeitos de contornar

- **Renovar antes de expirar.** Um job em segundo plano recalcula as chaves quentes a cada vinte
  segundos e as guarda com TTL de trinta, para que nunca expirem enquanto alguém lê. Os leitores
  nunca pagam uma falta; o preço é um job que recalcula valores que talvez ninguém esteja lendo.
- **Servir o valor velho enquanto um pedido o renova.** Guarde o valor com um TTL mais longo e um
  horário de "novo até" dentro dele. Um leitor que o acha vencido o serve mesmo assim e dispara uma
  única renovação.
- **Jitter**, da seção 03, para o problema vizinho de muitas chaves diferentes guardadas no mesmo
  momento, depois de uma implantação ou de um reinício, e expirando todas no mesmo momento também.

Um reinício do próprio Redis é a debandada no maior tamanho: todas as chaves faltando de uma vez. Um
cache sem o qual o site não vive passou a fazer parte da capacidade do banco, e a aula 23 o conta
assim.
