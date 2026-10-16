---
title: O arquivo append-only
version: 1
---

O outro jeito é um log. **Com o arquivo append-only ligado, todo comando de escrita é acrescentado a um
arquivo assim que é executado**, e um reinício repete o arquivo para reconstruir a memória. A pergunta
deixa de ser "quando foi o último snapshot" e passa a ser "até onde o sistema operacional chegou ao
gravar o log no disco", e o Redis deixa você escolher isso com uma configuração.

## A mesma queda, com o log ligado

Um contêiner novo num volume novo, com `--appendonly yes` depois do nome da imagem. Tudo o que vem
depois da imagem é passado ao `redis-server` como configuração:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-aof:/data redis:7.4 redis-server --appendonly yes
b3b2813b5dd4836267c387ac61ea284aaa8b670a5b9dba7fa5e8f4607b571e43
```

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET appendonly
1) "appendonly"
2) "yes"
127.0.0.1:6379> CONFIG GET appendfsync
1) "appendfsync"
2) "everysec"
127.0.0.1:6379> SET order:1001 paid
OK
127.0.0.1:6379> SET order:1002 paid
OK
127.0.0.1:6379> INCR stock:KB-101
(integer) 1
```

O `appendfsync` é `everysec`, o padrão: o Redis grava cada comando no arquivo na hora e pede ao sistema
operacional que descarregue o arquivo no disco uma vez por segundo. Agora o mesmo `docker kill`:

```
ana@vm:~$ docker kill redis
redis
ana@vm:~$ docker start redis
redis
ana@vm:~$ docker exec redis redis-cli DBSIZE
3
ana@vm:~$ docker logs redis 2>&1 | grep -E "loaded"
1:C 10 Oct 2026 19:39:54.517 * Configuration loaded
1:C 10 Oct 2026 19:39:55.152 * Configuration loaded
1:M 10 Oct 2026 19:39:55.157 * Done loading RDB, keys loaded: 0, keys expired: 0.
1:M 10 Oct 2026 19:39:55.157 * DB loaded from base file appendonly.aof.1.base.rdb: 0.001 seconds
1:M 10 Oct 2026 19:39:55.157 * DB loaded from incr file appendonly.aof.1.incr.aof: 0.000 seconds
1:M 10 Oct 2026 19:39:55.157 * DB loaded from append only file: 0.001 seconds
```

**As três chaves sobreviveram a uma morte que não deu aviso nenhum ao Redis.** O log mostra a
reprodução: primeiro um arquivo base, depois um arquivo incremental por cima dele. São dois dos três
arquivos de que o append-only é feito desde o Redis 7.

## Três arquivos, não um

```
ana@vm:~$ docker exec redis ls -l /data/appendonlydir
total 12
-rw------- 1 redis redis  89 Oct 10 19:39 appendonly.aof.1.base.rdb
-rw------- 1 redis redis 136 Oct 10 19:39 appendonly.aof.1.incr.aof
-rw------- 1 redis redis  88 Oct 10 19:39 appendonly.aof.manifest
ana@vm:~$ docker exec redis cat /data/appendonlydir/appendonly.aof.manifest
file appendonly.aof.1.base.rdb seq 1 type b
file appendonly.aof.1.incr.aof seq 1 type i
ana@vm:~$ docker exec redis cat /data/appendonlydir/appendonly.aof.1.incr.aof
*2
$6
SELECT
$1
0
*3
$3
SET
$10
order:1001
$4
paid
*3
$3
SET
$10
order:1002
$4
paid
*2
$4
INCR
$12
stock:KB-101
```

O **manifesto** lista os arquivos e a ordem deles. A **base** é um snapshot do conjunto de dados no
momento em que o log começou, em formato RDB, e é por isso que termina em `.rdb`; aqui está quase
vazia, porque o log começou com o conjunto de dados vazio. O arquivo **incremental** guarda toda
escrita desde então, no mesmo protocolo que um cliente usa para falar com o Redis: `*3` é um comando de
três partes, `$10` uma string de 10 bytes. Dá para lê-lo e, numa emergência, editá-lo: um `FLUSHALL`
que alguém digitou por engano é o último comando deste arquivo, e removê-lo antes de um reinício, e
antes da próxima reescrita, traz os dados de volta.

## Por que o log precisa ser reescrito

Um log de comandos cresce a cada comando, mesmo quando os dados não crescem. Dez mil incrementos de um
contador:

```
ana@vm:~$ docker exec redis redis-cli EVAL "for i = 1, 10000 do redis.call('INCR', 'stock:KB-101') end" 0

ana@vm:~$ docker exec redis ls -l /data/appendonlydir
total 332
-rw------- 1 redis redis     89 Oct 10 19:39 appendonly.aof.1.base.rdb
-rw------- 1 redis redis 330188 Oct 10 19:39 appendonly.aof.1.incr.aof
-rw------- 1 redis redis     88 Oct 10 19:39 appendonly.aof.manifest
```

Uma chave com um número dentro, e o arquivo incremental foi de 136 bytes para 330.188, porque guarda
dez mil comandos `INCR`. Repeti-los num reinício dá a resposta certa, devagar. O `BGREWRITEAOF` grava
uma base nova a partir do que está na memória, começa um arquivo incremental novo e vazio e apaga o par
antigo:

```
ana@vm:~$ docker exec redis redis-cli BGREWRITEAOF
Background append only file rewriting started
ana@vm:~$ docker exec redis ls -l /data/appendonlydir
total 8
-rw------- 1 redis redis 145 Oct 10 19:39 appendonly.aof.2.base.rdb
-rw------- 1 redis redis   0 Oct 10 19:39 appendonly.aof.2.incr.aof
-rw------- 1 redis redis  88 Oct 10 19:39 appendonly.aof.manifest
ana@vm:~$ docker exec redis cat /data/appendonlydir/appendonly.aof.manifest
file appendonly.aof.2.base.rdb seq 2 type b
file appendonly.aof.2.incr.aof seq 2 type i
ana@vm:~$ docker exec redis redis-cli GET stock:KB-101
10001
```

**O número de sequência foi de 1 para 2**, a base agora guarda o valor do contador, 10001, e os
incrementos sumiram porque o valor já os inclui. O Redis reescreve o log sozinho quando ele dobrou
desde a última reescrita e tem pelo menos 64 MB, os padrões de `auto-aof-rewrite-percentage` e
`auto-aof-rewrite-min-size`. Uma reescrita faz fork, como um snapshot, e custa memória do mesmo jeito.
