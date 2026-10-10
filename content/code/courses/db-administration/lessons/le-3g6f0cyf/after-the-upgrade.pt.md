---
title: Depois do upgrade
version: 1
---

O upgrade terminar não é o trabalho terminar. As últimas linhas do próprio `pg_upgrade` citaram duas
coisas que ele deixou por fazer, e mais duas decorrem de como o método funciona. Esta seção cuida
delas no `17/rehearsal` e depois desmonta tudo o que a lição construiu.

## Estatísticas

O `pg_upgrade` leva tabelas, linhas e índices, e **não as estatísticas do planejador** — a amostra
de cada coluna que a lição 16 leu em `pg_stats`. Um cluster novo sem estatísticas planeja cada
consulta no chute, e a primeira hora depois de um upgrade é quando aparecem planos lentos, num
servidor que acabou de virar o que todo mundo usa.

O `pg_upgradecluster` já cuidou disso: as linhas do `vacuumdb` no fim da saída dele eram o passo de
análise, rodando `vacuumdb --all --analyze-in-stages`. As tabelas dizem quando foram analisadas:

```
ana@db:~$ psql -p 5433 shop
shop=# SELECT relname, last_analyze FROM pg_stat_user_tables ORDER BY relname;
  relname  |         last_analyze          
-----------+-------------------------------
 customers | 2026-10-10 16:41:19.983082-03
 orders    | 2026-10-10 16:41:19.861384-03
(2 rows)
```

**Em etapas** significa três passadas por cada banco: primeiro com alvo de estatísticas 1, que dá
ao planejador alguma coisa em segundos, depois 10, depois o padrão completo. Um banco grande fica
utilizável depois da primeira passada, e não depois da última. Se você rodou o `pg_upgrade` à mão,
ou restaurou um dump, ninguém rodou isso por você:

```sh
vacuumdb --all --analyze-in-stages
```

## Extensões

Os pacotes da versão nova trazem versões novas dos arquivos de uma extensão, mas o banco registra
qual versão foi **instalada**, e isso não muda sozinho. O `pg_upgrade` percebeu e escreveu um
script:

```
ana@db:~$ sudo find /var/log/postgresql -name update_extensions.sql -exec cat {} +
\connect shop
ALTER EXTENSION "pg_stat_statements" UPDATE;
```

```
shop=# \dx pg_stat_statements
                                          List of installed extensions
        Name        | Version | Schema |                              Description                               
--------------------+---------+--------+------------------------------------------------------------------------
 pg_stat_statements | 1.10    | public | track planning and execution statistics of all SQL statements executed
(1 row)

shop=# ALTER EXTENSION pg_stat_statements UPDATE;
ALTER EXTENSION

shop=# \dx pg_stat_statements
                                          List of installed extensions
        Name        | Version | Schema |                              Description                               
--------------------+---------+--------+------------------------------------------------------------------------
 pg_stat_statements | 1.11    | public | track planning and execution statistics of all SQL statements executed
(1 row)

shop=# \q
```

A `pg_stat_statements` foi de 1.10 para 1.11, a versão que o 17 traz. Rode o script, ou o
`ALTER EXTENSION … UPDATE` que ele contém, em cada banco que ele cita. A lição 18 terminou falando
de manter as extensões em dia, e este é o momento para o qual ela preparava.

## O resto a conferir

- A aplicação. Aponte uma cópia de teste dela para o ensaio já atualizado e rode o que ela faz. As
  notas de versão da versão maior nova têm uma seção de *incompatibilidades*, e ela é lida contra o
  seu próprio código antes da noite de verdade, não durante.
- A configuração. O `pg_upgradecluster` copiou o `postgresql.conf`. Um parâmetro que foi removido
  ou renomeado na versão nova impede o servidor de subir, e o log diz qual é.
- Réplicas e backups. Um standby físico não consegue seguir um primário de outra versão maior, e um
  backup base feito pelo 16 não restaura no 17. Os dois são refeitos depois do upgrade; as lições 1
  a 10 e 11 a 13 de db-reliability dizem como.

## Removendo o cluster antigo

Só depois de conferir o cluster novo é que o antigo vai embora. O `pg_upgrade` deixou um script
chamado `delete_old_cluster.sh`, e no Ubuntu você usa o `pg_dropcluster` no lugar dele, que também
remove a configuração e o log:

```
ana@db:~$ sudo pg_dropcluster 16 rehearsal
ana@db:~$ sudo du -sh /var/lib/postgresql/17/rehearsal
165M	/var/lib/postgresql/17/rehearsal
ana@db:~$ psql -p 5433 -Atc "SELECT count(*) FROM orders;" shop
1000000
```

**Os dados continuam lá depois que o diretório antigo foi apagado.** Cada arquivo tinha dois nomes,
e o `pg_dropcluster` removeu um deles; o outro, no `17/rehearsal`, mantém o arquivo vivo. O `du`
agora conta tudo sob o diretório novo, e os pedidos estão todos presentes.

## Deixando o servidor como você o encontrou

O ensaio já cumpriu seu papel, e o `17/main` e o publicador também. Remova os três:

```
ana@db:~$ sudo pg_dropcluster --stop 17 rehearsal
ana@db:~$ sudo pg_dropcluster --stop 17 main
ana@db:~$ sudo pg_dropcluster --stop 16 source
ana@db:~$ pg_lsclusters -h
16 main 5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

**Um cluster, `16/main`, como no começo da lição.** Pergunte a ele o que ele é:

```
ana@db:~$ psql -c "SHOW server_version;" -c "SELECT pg_postmaster_start_time();"
            server_version             
---------------------------------------
 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
(1 row)

   pg_postmaster_start_time    
-------------------------------
 2026-10-10 16:40:20.370122-03
(1 row)
```

Ainda 16.15, e a hora de início não se mexeu desde o upgrade menor do começo da gravação: nada no meio
o reiniciou, atualizou ou escreveu nele. No seu servidor, compare com a hora que você anotou na
seção 04; deve ser a mesma. Os programas do PostgreSQL 17 continuam instalados, o que custa algum
espaço em disco e mais nada; `sudo apt remove postgresql-17` os tira se você preferir, e este curso
não precisa mais deles.
