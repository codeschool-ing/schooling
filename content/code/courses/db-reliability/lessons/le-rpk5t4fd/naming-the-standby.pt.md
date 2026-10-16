---
title: Dando nome ao standby que o primário espera
version: 1
---

O primário só espera os standbys listados em `synchronous_standby_names`, pelo nome que cada um informa
ao se conectar, o seu `application_name`. O standby da lição 11 informava `16/standby`, emprestado do
nome do cluster; dê a ele um nome próprio ao construí-lo, passando uma string de conexão para o
`pg_basebackup` com `-d` em vez de opções separadas:

```
ana@vm:~$ sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5432 user=replicator application_name=standby1' -D /var/lib/postgresql/16/standby -R -C -S standby1 -X stream -c fast
ana@vm:~$ sudo grep -o "application_name=[a-z0-9]*" /var/lib/postgresql/16/standby/postgresql.auto.conf
application_name=standby1
ana@vm:~$ sudo pg_ctlcluster 16 standby start
```

O `-R` copiou o nome para o `primary_conninfo` do standby, então **ele vai se apresentar como `standby1`
toda vez que se conectar**. (O papel, o `.pgpass` dele e o servidor vazio na porta 5434 são feitos
exatamente como na lição 11.) Com um banco chamado `bench` preenchido por `pgbench -i -s 10`, o
benchmark que vem com o PostgreSQL, há algo para medir.

Agora faça o primário esperar por ele:

```
shop=# ALTER SYSTEM SET synchronous_standby_names = 'standby1';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# SELECT application_name, sync_state FROM pg_stat_replication;
 application_name | sync_state 
------------------+------------
 standby1         | sync
(1 row)
```

`sync_state: sync`. A partir deste reload, todo commit no primário espera até que o `standby1` tenha
feito o flush dele, e a próxima seção mede quanto isso custa.
