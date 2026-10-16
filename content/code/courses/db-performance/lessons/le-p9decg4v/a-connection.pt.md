---
title: O que uma conexão custa ao servidor
version: 1
---

Uma aplicação abre uma conexão com o banco como um navegador abre uma página: sem pensar duas vezes.
A crença por trás disso é que **uma conexão é barata, um socket e alguns bytes**, e que um banco que
recusa conexões deveria receber mais. No PostgreSQL uma conexão não é nenhuma das duas coisas: cada
uma é **um processo inteiro do sistema operacional**, com memória própria e uma fatia dos
processadores, e o limite de quantas podem existir está ali por um motivo.

## Um processo por conexão

Pergunte ao sistema operacional quais processos pertencem ao usuário `postgres`, com a memória que
cada um ocupa:

```
ana@vm:~$ ps -u postgres -o pid,rss,cmd
    PID   RSS CMD
   5909 32856 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
   5910 132468 postgres: 16/main: checkpointer 
   5911 16132 postgres: 16/main: background writer 
   5913 10380 postgres: 16/main: walwriter 
   5914  9040 postgres: 16/main: autovacuum launcher 
   5915  8188 postgres: 16/main: logical replication launcher 
```

Seis processos, e nenhum deles é um cliente. O primeiro é o **postmaster**, o que escuta conexões;
os outros são os trabalhadores do próprio servidor — o checkpointer e o background writer gravando
páginas no disco, o WAL writer, os lançadores do autovacuum e da replicação lógica. `RSS` é a memória
residente em kilobytes, e sozinha ela engana, que é o assunto do próximo parágrafo.

Agora abra três sessões `psql` em `market` em três terminais, deixe-as no prompt e pergunte de novo:

```
ana@vm:~$ ps -u postgres -o pid,rss,cmd
    PID   RSS CMD
   5909 32856 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
   5910 132660 postgres: 16/main: checkpointer 
   5911 16132 postgres: 16/main: background writer 
   5913 10380 postgres: 16/main: walwriter 
   5914  9040 postgres: 16/main: autovacuum launcher 
   5915  8188 postgres: 16/main: logical replication launcher 
   6063 13820 postgres: 16/main: ana market [local] idle
   6069 13808 postgres: 16/main: ana market [local] idle
   6070 13812 postgres: 16/main: ana market [local] idle
```

**Três processos novos**, um por sessão, cada um com o nome do usuário, do banco, de onde se conectou
e do que está fazendo: `ana market [local] idle`. Quando um cliente se conecta, o postmaster inicia um
processo para ele, e esse processo atende aquele cliente e nenhum outro até ele desconectar. Mil
clientes são mil processos.

## O que cada um ocupa

O `RSS` diz que cada processo novo ocupa uns 13 MB, o que faria mil conexões ocuparem treze
gigabytes. Esse número conta páginas que o processo **compartilha** com os outros, sobretudo os shared
buffers do servidor, então somar a coluna conta a mesma memória muitas vezes. O sistema operacional
separa as partes em `/proc`:

```
ana@vm:~$ grep -E "^(VmRSS|RssAnon|RssShmem)" /proc/$(pgrep -f "ana market \[local\] idle" | head -1)/status
VmRSS:	   13820 kB
RssAnon:	    3244 kB
RssShmem:	    3864 kB
```

`RssAnon` é a memória só deste processo: **3244 kB** para uma sessão que não fez nada. `RssShmem` é a
memória compartilhada que ele tocou até agora, que não é dele. Então uma conexão ociosa custa alguns
megabytes, e uma ocupada custa mais: cada ordenação ou hash que ela roda pode ocupar até `work_mem`,
4 MB por padrão, por operação, e uma única consulta pode ter várias. A aula 6 de `db-administration`
é a conta dessa configuração; aqui o que importa é que ela vale **por conexão, por operação**, então
o total cresce com o número de conexões trabalhando ao mesmo tempo.

Memória não é o único custo. Iniciar um processo para cada conexão nova custa um fork, um login e
alguns milissegundos antes da primeira consulta, e é por isso que o `pgbench` informa o tempo de
conexão inicial à parte. E cada processo espera a sua vez nos processadores, que é a parte que a
próxima seção mede.

## O limite, e o erro nele

O servidor tem um teto rígido de processos para clientes:

```
market=# SHOW max_connections;
 max_connections 
-----------------
 100
(1 row)

Time: 0.526 ms

market=# SHOW superuser_reserved_connections;
 superuser_reserved_connections 
--------------------------------
 3
(1 row)

Time: 0.474 ms

market=# SELECT count(*) FROM pg_stat_activity;
 count 
-------
     9
(1 row)

Time: 2.444 ms
```

**100 conexões**, das quais **3 ficam reservadas para superusuários**, para que um administrador ainda
consiga entrar quando os clientes comuns tomaram o resto. As nove em `pg_stat_activity` são as três
sessões ociosas, esta e os processos de fundo do próprio servidor. A aula 10 de `db-administration` é
onde mora a configuração em si: o que mudá-la exige e o que ela custa na inicialização.

Peça mais do que isso, com o `pgbench` abrindo 110 clientes de uma vez:

```
ana@vm:~/workload$ pgbench -n -c 110 -j 4 -T 10 -f customer-orders.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
pgbench: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
pgbench: error: could not create connection for client 51
```

`FATAL: sorry, too many clients already`. O `pgbench` falhou enquanto ainda abria as conexões, e
desistiu da execução inteira. Uma aplicação nesse momento falha de outro jeito: as requisições começam
a receber erros, cada nova tentativa soma mais uma, e as pessoas atualizando a página somam mais
ainda. O reflexo é subir o `max_connections` para 500, e a próxima seção mede por que isso não compra
nada: passado um punhado de clientes, o servidor não faz mais trabalho, só enfileira o mesmo em mais
lugares.
