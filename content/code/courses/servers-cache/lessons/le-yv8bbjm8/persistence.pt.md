---
title: O que sobrevive a um reinício
version: 1
---

A memória some quando o processo para. O Redis consegue guardar uma cópia no disco de dois jeitos, e
para um cache puro pode não guardar nenhuma: **se um cache sobrevive a um reinício é uma escolha, não um
dado**, e ela decide quão lentos são os primeiros minutos depois de um reinício (aula 11).

## Snapshots

O arquivo **RDB** é uma fotografia do conjunto de dados inteiro num momento. A configuração do Ubuntu
tira uma depois de uma hora com qualquer mudança, cinco minutos com cem, ou um minuto com dez mil, e o
`BGSAVE` tira uma agora, num processo filho, sem parar o servidor:

```
ana@web:~$ redis-cli FLUSHALL && redis-cli CONFIG SET maxmemory 0 && redis-cli CONFIG SET maxmemory-policy noeviction
OK
OK
OK
ana@web:~$ redis-cli SET before-snapshot 1 && redis-cli BGSAVE && sleep 1 && sudo ls -l /var/lib/redis
OK
Background saving started
total 4
-rw-rw---- 1 redis redis 113 Oct  7 01:24 dump.rdb
ana@web:~$ redis-cli SET after-snapshot 2 && redis-cli DBSIZE
OK
2
ana@web:~$ redis-cli SHUTDOWN NOSAVE; sleep 1; sudo systemctl start redis-server; sleep 1; redis-cli KEYS "*"
before-snapshot
```

O `SHUTDOWN NOSAVE` para o Redis como uma queda pararia, sem a fotografia final que uma parada limpa
tira. Depois do reinício, **a chave gravada antes do snapshot voltou e a gravada depois dele se
perdeu.** Um snapshot é barato e compacto, e tudo desde o último está em risco.

## O arquivo append-only

O **AOF** grava num log todo comando que muda dados, e ao subir o Redis o repete. Ligado e salvo no
arquivo de configuração com `CONFIG REWRITE`, para a configuração também sobreviver ao reinício:

```
ana@web:~$ redis-cli CONFIG SET appendonly yes && redis-cli CONFIG REWRITE && sleep 2 && sudo ls /var/lib/redis /var/lib/redis/appendonlydir
OK
OK
/var/lib/redis:
appendonlydir
dump.rdb

/var/lib/redis/appendonlydir:
appendonly.aof.1.base.rdb
appendonly.aof.1.incr.aof
appendonly.aof.manifest
ana@web:~$ redis-cli SET after-aof 3 && sleep 1 && redis-cli SHUTDOWN NOSAVE; sleep 1; sudo systemctl start redis-server; sleep 1; redis-cli KEYS "*" | sort
OK
after-aof
before-snapshot
```

**A chave gravada um segundo antes da queda sobreviveu.** Com o padrão do Ubuntu, `appendfsync
everysec`, o log vai para o disco uma vez por segundo, então cerca de um segundo de gravações fica em
risco, ao custo de uma escrita no disco por segundo. Desde a versão 7, o AOF é um diretório: um snapshot
base, um log incremental e um manifesto que diz quais arquivos formam o estado atual.

| | snapshots RDB | AOF | nenhum |
|---|---|---|---|
| perdido numa queda | tudo desde o último snapshot | cerca de um segundo | tudo |
| reinício | rápido: carrega um arquivo | mais lento: repete o log | instantâneo, e vazio |
| para | um cache que deve subir aquecido | dados que não podem se perder | um cache que pode subir frio |

Para um cache, a pergunta honesta é **quanto custa um começo frio**. Se a aplicação consegue reconstruir
todo valor a partir do banco e o banco aguenta a carga, `save ""` e nenhum AOF é a configuração mais
simples. Se um cache frio mandaria uma enxurrada ao banco, mantenha os snapshots, e leia a aula 11.
