---
title: Os dois, nenhum, e o reinício que carrega o arquivo errado
version: 1
---

Snapshots e log não se excluem. **Um Redis com os dois ligados grava os dois, e na partida carrega só
um: o arquivo append-only.** Essa regra é inofensiva enquanto os dois estão ligados desde o começo, e
esvazia um banco no dia em que alguém liga o log numa instância que só tinha snapshots.

## Ligando o log do jeito errado

Uma instância só com snapshots, dois pedidos dentro, parada de forma limpa para que o snapshot final
os guarde:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-both:/data redis:7.4
33d3f2a10206c9d73ec3d459433f178362356623dffbb87af9f522b31defae5a
ana@vm:~$ docker exec redis redis-cli SET order:1001 paid
OK
ana@vm:~$ docker exec redis redis-cli SET order:1002 paid
OK
ana@vm:~$ docker stop redis
redis
ana@vm:~$ docker rm redis
redis
```

O jeito óbvio de acrescentar o log é subir o contêiner de novo com `--appendonly yes`:

```
ana@vm:~$ docker run -d --name redis --network nosql -v redis-both:/data redis:7.4 redis-server --appendonly yes
1b648c394ceb034a868f0586267715556e13a5402b950d945fb77ed03f08a1ce
ana@vm:~$ docker exec redis redis-cli DBSIZE
0
ana@vm:~$ docker logs redis 2>&1 | grep -E "AOF|loaded"
1:C 10 Oct 2026 19:40:12.255 * Configuration loaded
1:M 10 Oct 2026 19:40:12.261 * Creating AOF base file appendonly.aof.1.base.rdb on server start
1:M 10 Oct 2026 19:40:12.264 * Creating AOF incr file appendonly.aof.1.incr.aof on server start
ana@vm:~$ docker exec redis ls -l /data
total 8
drwx------ 2 redis redis 4096 Oct 10 19:40 appendonlydir
-rw------- 1 redis redis  128 Oct 10 19:40 dump.rdb
ana@vm:~$ docker stop redis
redis
ana@vm:~$ docker run --rm -v redis-both:/data redis:7.4 ls -l /data
total 8
drwx------ 2 redis redis 4096 Oct 10 19:40 appendonlydir
-rw------- 1 redis redis   89 Oct 10 19:40 dump.rdb
```

**O `DBSIZE` é 0.** Na partida, o Redis viu que o log estava ligado, não achou log nenhum, criou um
vazio e o carregou. O `dump.rdb` com os dois pedidos, 128 bytes, continuava ao lado e nunca foi lido.
Depois a parada limpa gravou por cima dele um snapshot final do que estava na memória, que era nada:
89 bytes, um conjunto de dados vazio. Os pedidos estavam num arquivo no volume até o momento em que
alguém fez a coisa cuidadosa e parou o servidor direito.

## Ligando do jeito certo

Peça ao servidor em execução que comece o log. `CONFIG SET appendonly yes` faz o Redis gravar um
arquivo base a partir do que está na memória agora, e só então liga o log:

```
ana@vm:~$ docker rm redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-safe:/data redis:7.4
355d804bec7924f0bae1a803c25222394ed35690d674ee573c063eee27bcbf8f
ana@vm:~$ docker exec redis redis-cli SET order:1001 paid
OK
ana@vm:~$ docker exec redis redis-cli SET order:1002 paid
OK
ana@vm:~$ docker exec redis redis-cli CONFIG SET appendonly yes
OK
ana@vm:~$ docker exec redis redis-cli INFO persistence | grep -E "^aof_(enabled|rewrite_in_progress|last_bgrewrite_status)"
aof_enabled:1
aof_rewrite_in_progress:0
aof_last_bgrewrite_status:ok
```

`aof_rewrite_in_progress:0` e `aof_last_bgrewrite_status:ok` dizem que o arquivo base está gravado.
Agora o contêiner pode subir com a opção, para que ela continue ligada:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-safe:/data redis:7.4 redis-server --appendonly yes
7dc13c8b1d98a859af3654f6adf2a050ebb34e5879c36994243c7c7b2581cace
ana@vm:~$ docker exec redis redis-cli DBSIZE
2
ana@vm:~$ docker logs redis 2>&1 | grep -E "loaded"
1:C 10 Oct 2026 19:40:16.664 * Configuration loaded
1:M 10 Oct 2026 19:40:16.672 * Done loading RDB, keys loaded: 2, keys expired: 0.
1:M 10 Oct 2026 19:40:16.672 * DB loaded from base file appendonly.aof.1.base.rdb: 0.003 seconds
1:M 10 Oct 2026 19:40:16.672 * DB loaded from append only file: 0.003 seconds
```

Os dois pedidos voltaram, carregados do arquivo base do log. **O `CONFIG SET` muda só o processo em
execução**: um contêiner que subisse sem a opção subiria sem o log, e carregaria o snapshot de novo.
Com um arquivo de configuração em vez de opções, o `CONFIG REWRITE` grava a mudança no arquivo.

## Nenhum: o Redis como cache

Um Redis que guarda só cópias de dados mantidos em outro lugar, como páginas renderizadas, não tem nada
a salvar. Um `save` vazio desliga os snapshots, e o log continua desligado:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql redis:7.4 redis-server --save "" --appendonly no
b7539768319ce3f836267b7382de19b816dd6d4e455c2eba1ae56d317c0309f2
ana@vm:~$ docker exec redis redis-cli CONFIG GET save
save

ana@vm:~$ docker exec redis redis-cli SET page:/product/KB-101 "<html>…</html>"
OK
ana@vm:~$ docker stop redis
redis
ana@vm:~$ docker start redis
redis
ana@vm:~$ docker exec redis redis-cli DBSIZE
0
```

A página sumiu depois de uma parada limpa, e é essa a ideia. O reinício de um cache puro começa vazio e
se enche de novo a partir do sistema por trás. Também começa na hora, sem arquivo para carregar; uma
instância que salva gastaria forks e disco com dados que ninguém quer de volta. A aula 14 trata da
outra configuração de que um cache precisa, o que jogar fora quando a memória enche.

## Quando salvar falha

Um snapshot que não consegue ser gravado faz mais que registrar um erro. Um volume somente leitura faz
aqui o papel da causa real mais comum, um disco cheio:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-data:/data:ro redis:7.4
90a96891797bf0d436b0ae86971bb264ee1988bf6d949ad1445000a7a151e836
ana@vm:~$ docker exec redis redis-cli BGSAVE
Background saving started
ana@vm:~$ docker exec redis redis-cli SET order:100003 paid
MISCONF Redis is configured to save RDB snapshots, but it's currently unable to persist to disk. Commands that may modify the data set are disabled, because this instance is configured to report errors during writes if RDB snapshotting fails (stop-writes-on-bgsave-error option). Please check the Redis logs for details about the RDB error.

ana@vm:~$ docker logs redis 2>&1 | grep -E "Failed opening"
27:C 10 Oct 2026 19:40:19.356 # Failed opening the temp RDB file temp-27.rdb (in server root dir /data) for saving: Read-only file system
```

**O Redis recusou a escrita.** Por padrão, depois que um snapshot falha, o Redis recusa toda escrita
até um dar certo, `stop-writes-on-bgsave-error yes`, porque aceitar escritas que não consegue salvar
seria prometer uma durabilidade que não tem. Parece uma indisponibilidade, e é uma; o remédio é o
disco, não a configuração. A linha do log diz o arquivo e o motivo.

## Os campos que vale ler

O `INFO persistence` tem uns trinta campos. Um punhado responde às perguntas que um operador faz:

```
ana@vm:~$ docker exec redis redis-cli INFO persistence | grep -E "^(loading|rdb_changes_since_last_save|rdb_bgsave_in_progress|rdb_last_bgsave_status|aof_enabled|aof_rewrite_in_progress|aof_last_bgrewrite_status|aof_last_write_status):"
loading:0
rdb_changes_since_last_save:0
rdb_bgsave_in_progress:0
rdb_last_bgsave_status:err
aof_enabled:0
aof_rewrite_in_progress:0
aof_last_bgrewrite_status:ok
aof_last_write_status:ok
```

| campo | o que ele diz |
| --- | --- |
| `loading` | `1` enquanto um reinício ainda está lendo o arquivo; até lá o Redis responde com erros `LOADING` |
| `rdb_changes_since_last_save` | as escritas que uma queda perderia se só houver snapshots |
| `rdb_bgsave_in_progress` | um snapshot está sendo gravado, e o fork está usando memória |
| `rdb_last_bgsave_status` | `err` aqui é o `MISCONF` acima, antes da primeira escrita recusada |
| `aof_enabled` | se o log está ligado no processo em execução, diga o que disser o arquivo de configuração |
| `aof_rewrite_in_progress`, `aof_last_bgrewrite_status` | uma reescrita em andamento, e se a última funcionou |
| `aof_last_write_status` | `err` quer dizer que uma escrita no log falhou, e o disco é o lugar para olhar |

**`rdb_last_bgsave_status` e `aof_last_write_status` são os dois para alertar**, assunto que faz parte da
aula 20.
