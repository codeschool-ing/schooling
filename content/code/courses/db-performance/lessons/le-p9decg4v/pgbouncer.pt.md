---
title: O PgBouncer na frente do servidor
version: 1
---

Um **pool de conexões** fica entre os clientes e o servidor. Os clientes se conectam a ele, quantos
quiserem, e ele mantém um número pequeno de conexões reais com o servidor e as empresta: um cliente
que tem algo para rodar recebe uma, roda e devolve. O PgBouncer é o pool que a maioria das
instalações de PostgreSQL usa, um processo pequeno que fala o protocolo do PostgreSQL dos dois lados,
então a aplicação muda a porta e mais nada. Esta seção o instala, o configura do jeito local mais
simples e honesto, e repete o experimento que o servidor recusou na seção 02.

## Instalando

O PgBouncer está no repositório do Ubuntu:

```sh
sudo apt install -y pgbouncer
```

O `apt` o instala como serviço, rodando como o usuário `postgres` do sistema operacional e lendo
`/etc/pgbouncer/pgbouncer.ini`. Confira o que veio:

```
ana@vm:~$ pgbouncer --version
PgBouncer 1.22.0
libevent 2.1.12-stable
adns: c-ares 1.27.0
tls: OpenSSL 3.0.13 30 Jan 2024
systemd: yes
```

## A configuração, inteira

O arquivo que o `apt` escreveu é longo e quase todo comentário. Guarde-o e troque-o pelo curto
abaixo:

```sh
sudo cp -p /etc/pgbouncer/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini.orig
```

O `-p` mantém o dono do arquivo, `postgres`, na cópia, o que importa quando ela voltar no fim da
aula: um arquivo de configuração que o serviço não consegue ler é um serviço que não sobe. Depois
abra `/etc/pgbouncer/pgbouncer.ini` com `sudo nano` e deixe-o exatamente assim:

```schooling-example
{"language": "ini", "file": "/etc/pgbouncer/pgbouncer.ini", "parts": [
 {"code": "[databases]\nmarket = host=127.0.0.1 port=5432 dbname=market\n", "note": "Os bancos que os clientes podem pedir, e onde cada um está de fato. Um cliente pede `market` ao PgBouncer, e o PgBouncer se conecta ao servidor na porta 5432 por TCP. TCP e não o socket, porque o PgBouncer roda como o usuário `postgres`, e a autenticação peer do socket o faria entrar como esse usuário em vez de como você."},
 {"code": "[pgbouncer]\nlisten_addr = 127.0.0.1\nlisten_port = 6432\nunix_socket_dir = /var/run/postgresql\n", "note": "Onde o PgBouncer escuta: só nesta máquina, na porta 6432, ao lado da 5432 do servidor e não no lugar dela. Levar uma aplicação para o pool é mudar a porta dela."},
 {"code": "auth_type = scram-sha-256\nauth_file = /etc/pgbouncer/userlist.txt\nadmin_users = ana\n", "note": "Os clientes provam quem são com uma senha, conferida contra o `userlist.txt`, que guarda o segredo SCRAM de cada papel — o mesmo segredo que o servidor guarda, nunca a senha em si. O PgBouncer então reaproveita a prova do cliente para entrar no servidor como o mesmo papel. O `admin_users` deixa `ana` entrar no console do próprio PgBouncer."},
 {"code": "pool_mode = transaction\ndefault_pool_size = 8\nmax_client_conn = 500\n", "note": "As três linhas que fazem dele um pool. Uma conexão com o servidor é emprestada por uma **transação** de cada vez; há no máximo **8** delas por banco e papel; e até **500** clientes podem se conectar. A seção 05 trata da primeira linha, a seção 06 da segunda."},
 {"code": "logfile = /var/log/postgresql/pgbouncer.log\npidfile = /var/run/postgresql/pgbouncer.pid", "note": "Onde ele grava o log e o id do processo: as duas linhas mantidas do arquivo que o `apt` escreveu."}
]}
```

## Uma senha, para um pool que precisa conferir uma

Até agora `ana` entrou sem senha: o `psql` se conecta pelo socket, e o servidor confia no que o
sistema operacional diz sobre quem está do outro lado. O PgBouncer é um programa separado falando por
TCP, então precisa de uma senha de verdade. Dê a `ana` a senha `market-lab`, que serve para uma
máquina que ninguém mais alcança e é errada em qualquer outro lugar (o `\password` do `psql` pede a
senha sem gravá-la no seu histórico):

```
market=# ALTER ROLE ana PASSWORD 'market-lab';
ALTER ROLE
Time: 5.691 ms
```

Grave o segredo SCRAM que o servidor agora guarda na lista de usuários do PgBouncer, e a senha em
`~/.pgpass`, onde o `psql` e o `pgbench` a procuram para você não digitá-la toda vez:

```sh
psql -XAt market -c "SELECT concat('\"', rolname, '\" \"', rolpassword, '\"') FROM pg_authid WHERE rolname = 'ana'" | sudo tee /etc/pgbouncer/userlist.txt > /dev/null
```

```sh
cat > ~/.pgpass <<'PW'
127.0.0.1:6432:*:ana:market-lab
PW
chmod 600 ~/.pgpass
```

A primeira linha de `userlist.txt` é o papel e o seu segredo, ambos entre aspas duplas. O segredo
começa pelo método e o número de iterações, depois o sal e as chaves; eis os primeiros quarenta
caracteres:

```
ana@vm:~$ sudo cut -c1-40 /etc/pgbouncer/userlist.txt
"ana" "SCRAM-SHA-256$4096:lk1o3Pr6bDk1+M
```

## Ligando, e passando por ele

```
ana@vm:~$ sudo systemctl restart pgbouncer
ana@vm:~$ systemctl is-active pgbouncer
active
```

Agora abra `psql -h 127.0.0.1 -p 6432 market`: o `-h` e o `-p` o mandam para o PgBouncer em vez do
servidor. Pergunte quem você é e qual porta o **servidor** vê:

```
market=# SELECT current_user, inet_server_port(), pg_backend_pid();
 current_user | inet_server_port | pg_backend_pid 
--------------+------------------+----------------
 ana          |             5432 |           8617
(1 row)

Time: 1.459 ms
```

Você é `ana`, e o servidor respondeu pela porta 5432: a consulta passou pelo PgBouncer e chegou como
uma conexão comum. Nada no SQL mudou.

## Duzentos clientes

A seção 03 parou em noventa clientes porque o servidor não aceita mais. Direto no servidor, duzentos
são recusados como antes:

```
ana@vm:~/workload$ pgbench -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market 2>&1 | head -4
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
pgbench: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
pgbench: error: could not create connection for client 24
```

Pelo PgBouncer, os mesmos duzentos, enquanto o console do PgBouncer mostra o pool no meio da execução:

```
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E "^(number of clients|number of transactions|latency average|tps)"
number of clients: 200
number of transactions actually processed: 25428
latency average = 149.040 ms
tps = 1341.920895 (without initial connection time)
```

```
pgbouncer=# SHOW POOLS;
 database  |   user    | cl_active | cl_waiting | cl_active_cancel_req | cl_waiting_cancel_req | sv_active | sv_active_cancel | sv_being_canceled | sv_idle | sv_used | sv_tested | sv_login | maxwait | maxwait_us |  pool_mode  
-----------+-----------+-----------+------------+----------------------+-----------------------+-----------+------------------+-------------------+---------+---------+-----------+----------+---------+------------+-------------
 market    | ana       |         8 |        192 |                    0 |                     0 |         8 |                0 |                 0 |       0 |       0 |         0 |        0 |       0 |     156374 | transaction
 pgbouncer | pgbouncer |         1 |          0 |                    0 |                     0 |         0 |                0 |                 0 |       0 |       0 |         0 |        0 |       0 |          0 | statement
(2 rows)

Time: 10.980 ms
```

**200 clientes, 1342 transações por segundo, nenhum recusado.** O `SHOW POOLS` explica: 8 clientes
ativos, **192 esperando**, e **8 conexões com o servidor** ativas, o `default_pool_size`. O servidor
nunca viu mais de oito clientes vindos do pool, e a contagem dele de conexões em `market` confirma:

```
market=# SELECT count(*) FROM pg_stat_activity WHERE datname = 'market';
 count 
-------
     9
(1 row)

Time: 3.541 ms
```

Nove: as oito do PgBouncer e este `psql`. A espera aconteceu no PgBouncer, onde um cliente esperando
custa alguns kilobytes em vez de um processo, e a latência, 149 milissegundos em média, é quase toda
essa espera — a mesma espera que a seção 03 mediu com noventa clientes, levada para um lugar mais
barato. Um pool não deixa o servidor mais rápido. Ele faz os clientes além do que o servidor consegue
usar deixarem de custar alguma coisa enquanto esperam.
