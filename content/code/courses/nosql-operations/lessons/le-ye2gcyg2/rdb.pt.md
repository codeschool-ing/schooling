---
title: Snapshots, e o que uma queda leva junto
version: 1
---

O Redis guarda tudo na memória, e a memória some quando o processo para. **Persistência é quanto
disso o Redis grava em algum lugar que sobrevive**, e o Redis oferece dois jeitos, que diferem no que
uma queda custa. O primeiro é o snapshot: de tempos em tempos, o conjunto de dados inteiro é gravado
num arquivo, o `dump.rdb`. O que foi escrito depois do último snapshot só existe na memória.

A ideia errada é que o Redis "salva em disco" como um banco relacional, cada escrita confirmada no
disco antes de o cliente ouvir `OK`. Com snapshots, não salva, e esta seção mostra o buraco matando o
servidor de propósito.

## Um contêiner cujos arquivos vivem mais que ele

A aula 12 usou um contêiner sem nada que valesse guardar. Aqui o diretório de dados, `/data` na imagem
oficial, fica num **volume com nome**, e assim sobrevive à remoção do contêiner:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-data:/data redis:7.4
5122ba40164c08121fb0571e80e3188ef11b545d67639c53f7ebe822ef13f320
```

`-v redis-data:/data` cria o volume no primeiro uso. Todo contêiner desta aula usa um, e cada seção dá
nome ao seu, para que não se misturem.

## Quando um snapshot é tirado

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET save
1) "save"
2) "3600 1 300 100 60 10000"
127.0.0.1:6379> CONFIG GET dir
1) "dir"
2) "/data"
127.0.0.1:6379> EVAL "for i = 1, 100000 do redis.call('SET', 'order:' .. i, 'paid') end return redis.call('DBSIZE')" 0
(integer) 100000
127.0.0.1:6379> BGSAVE
Background saving started
127.0.0.1:6379> LASTSAVE
(integer) 1791661190
127.0.0.1:6379> SET order:100001 paid
OK
127.0.0.1:6379> SET order:100002 paid
OK
```

`save` guarda as regras dos snapshots automáticos em pares de números: `3600 1 300 100 60 10000` quer
dizer "depois de 3.600 segundos se pelo menos 1 chave mudou, depois de 300 segundos se pelo menos 100
mudaram, depois de 60 segundos se pelo menos 10.000 mudaram". São os padrões do Redis, e a imagem
oficial começa com eles. `dir` é para onde o arquivo vai.

O `EVAL` gravou 100.000 pedidos num laço em Lua, o jeito mais rápido de ter um conjunto de dados que
valha salvar. O `BGSAVE` pediu um snapshot agora, em segundo plano; o `LASTSAVE` responde quando o
último terminou, em tempo Unix. Depois chegaram mais dois pedidos. O que o Redis sabe deles:

```
ana@vm:~$ docker exec redis redis-cli INFO persistence | grep -E "^rdb_(changes_since_last_save|last_bgsave_status|last_cow_size)"
rdb_changes_since_last_save:2
rdb_last_bgsave_status:ok
rdb_last_cow_size:339968
ana@vm:~$ docker exec redis ls -l /data
total 1748
-rw------- 1 redis redis 1788993 Oct 10 19:39 dump.rdb
```

**`rdb_changes_since_last_save` é o número de escritas que uma queda perderia agora**: os dois pedidos
gravados depois do snapshot. O arquivo no volume tem os outros 100.000.

## A queda

`docker kill` manda `SIGKILL`, que encerra o processo sem chance de fazer nada antes: o mais perto que
um contêiner chega de um servidor que perde energia, embora a memória e o disco da própria máquina
continuem funcionando.

```
ana@vm:~$ docker kill redis
redis
ana@vm:~$ docker start redis
redis
ana@vm:~$ docker exec redis redis-cli DBSIZE
100000
ana@vm:~$ docker exec redis redis-cli EXISTS order:100001 order:100002
0
ana@vm:~$ docker logs redis 2>&1 | grep -E "RDB|loaded"
28:C 10 Oct 2026 19:39:50.339 * Fork CoW for RDB: current 0 MB, peak 0 MB, average 0 MB
1:M 10 Oct 2026 19:39:52.924 * Loading RDB produced by version 7.4.11
1:M 10 Oct 2026 19:39:52.924 * RDB age 2 seconds
1:M 10 Oct 2026 19:39:52.924 * RDB memory usage when created 8.23 Mb
1:M 10 Oct 2026 19:39:52.995 * Done loading RDB, keys loaded: 100000, keys expired: 0.
1:M 10 Oct 2026 19:39:52.995 * DB loaded from disk: 0.072 seconds
```

**Voltaram 100.000 chaves, e os pedidos 100001 e 100002 não.** Os dois tinham sido confirmados com
`OK`; nenhum estava no snapshot. O log diz de onde vieram os dados: um arquivo RDB, produzido pela
7.4.11, com dois segundos de idade quando foi carregado.

## Uma parada limpa não é o teste

A mesma experiência com `docker stop`, que manda `SIGTERM` e espera:

```
ana@vm:~$ docker exec redis redis-cli SET order:100001 paid
OK
ana@vm:~$ docker stop redis
redis
ana@vm:~$ docker start redis
redis
ana@vm:~$ docker exec redis redis-cli DBSIZE
100001
ana@vm:~$ docker logs redis 2>&1 | grep -E "shutdown|final RDB"
1:signal-handler (1791661193) Received SIGTERM scheduling shutdown...
1:M 10 Oct 2026 19:39:53.402 * User requested shutdown...
1:M 10 Oct 2026 19:39:53.402 * Saving the final RDB snapshot before exiting.
```

Nada se perdeu, porque o Redis ouviu o sinal, gravou um snapshot final e só então saiu. É o caso que
faz os snapshots parecerem seguros: todo reinício que alguém faz de propósito é limpo. **Uma queda, uma
morte por falta de memória ou uma máquina que perde energia não avisam**, e são esses os reinícios
para os quais a persistência existe. Teste com `docker kill`, nunca com `docker stop`.

## O que um snapshot custa

O `BGSAVE` faz um fork do processo do Redis. O filho grava o arquivo a partir de uma cópia congelada da
memória enquanto o pai continua atendendo clientes, e o sistema operacional compartilha as duas cópias
até o pai alterar uma página, que então precisa ser copiada. Numa instância ocupada com escritas, um
snapshot pode precisar por um instante de bem mais memória que o próprio conjunto de dados, e o
`rdb_last_cow_size` do `INFO persistence` diz quanto foi copiado da última vez. Um snapshot de alguns
gigabytes também leva segundos para ser gravado, então os snapshots são tirados com minutos de
distância, e minutos de escritas é o que eles arriscam.
