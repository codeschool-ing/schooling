---
title: O que o pacote fez, e um papel com o seu nome
version: 1
---

Além de copiar programas, o instalador fez três coisas na máquina, e cada uma explica uma recusa
que você está prestes a encontrar.

Ele criou um **usuário do sistema operacional chamado `postgres`**. O servidor roda como esse
usuário, é dono de todos os arquivos de dados como esse usuário, e ninguém mais na máquina consegue
lê-los — nem você, sem `sudo`. Isso é uma fronteira de segurança, e é também por isso que os
arquivos do servidor sobrevivem a um erro seu na sua pasta pessoal.

Ele criou um **papel de banco chamado `postgres`**, o primeiro e único, com todos os privilégios
que existem. Um **papel** (role) é a ideia que o banco tem de um usuário, guardada dentro do cluster
e separada dos usuários do computador. A lição 11 é sobre a diferença.

E ele escreveu uma regra dizendo que **uma conexão desta máquina, pelo socket local, só é
permitida para o papel de banco cujo nome bate com o do usuário do sistema que a faz**. Essa regra
se chama **autenticação peer**, e é por ela que a primeira tentativa falha:

```
ana@db:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

O servidor está rodando e não conhece você. Ele conhece `postgres`, e a autenticação peer deixa o
usuário `postgres` do sistema entrar como esse papel. O `sudo -u postgres` roda um comando como
esse usuário:

```
ana@db:~$ sudo -u postgres psql -c "SELECT current_user, version();"
 current_user |                                                                 version                                                                  
--------------+------------------------------------------------------------------------------------------------------------------------------------------
 postgres     | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
(1 row)
```

Essa é a porta que um administrador sempre tem num servidor de pacote. Use-a agora para dar a si
mesmo um papel seu, e um banco onde cair:

```
ana@db:~$ sudo -u postgres createuser --superuser $USER
ana@db:~$ createdb $USER
ana@db:~$ psql
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
Type "help" for help.

ana=# \conninfo
You are connected to database "ana" as user "ana" via socket in "/var/run/postgresql" at port "5432".

ana=# SHOW data_directory;
       data_directory        
-----------------------------
 /var/lib/postgresql/16/main
(1 row)

ana=# SHOW config_file;
               config_file               
-----------------------------------------
 /etc/postgresql/16/main/postgresql.conf
(1 row)

ana=# \q
```

O `createuser` não imprimiu nada, que é como ele diz que funcionou, e o `createdb` também não. O
`$USER` é o seu nome de usuário, preenchido pelo shell, então o papel tem o nome que você tem. O
`--superuser` deixa esse papel fazer qualquer coisa neste cluster. **Num servidor seu, que você está
aqui para administrar, isso está certo. Em qualquer outro lugar está errado**, e as lições 11 e 12
tratam de como os papéis recebem exatamente o que precisam e nada mais.

O `psql` sem argumentos conecta como o papel com o seu nome, no banco com o seu nome, e por isso o
`createdb $USER` veio antes. O prompt `ana=#` é o banco em que você está, e o `#` diz que o papel é
superusuário; um papel comum vê `>`.

**`data_directory` e `config_file` ficam em lugares diferentes**, uma escolha que o Debian e o
Ubuntu fazem e o projeto PostgreSQL não. Na origem, a configuração mora dentro do diretório de
dados. A lição 4 abre o primeiro e a lição 5 o segundo.

## Os processos, vistos de fora

O mesmo servidor, visto pelo sistema operacional em vez do systemd:

```
ana@db:~$ ps -u postgres -o pid,cmd
    PID CMD
   2487 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
   2488 postgres: 16/main: checkpointer 
   2489 postgres: 16/main: background writer 
   2491 postgres: 16/main: walwriter 
   2492 postgres: 16/main: autovacuum launcher 
   2493 postgres: 16/main: logical replication launcher 
```

Todo processo pertence ao usuário `postgres`. Nada está conectado agora, então há só o postmaster e
seus processos de fundo. Os números de processo na sua máquina serão outros.

## Duas recusas que vale reconhecer agora

O socket dessas mensagens de erro, `/var/run/postgresql/.s.PGSQL.5432`, é um arquivo que o servidor
cria quando sobe. É por ele que um cliente na mesma máquina o encontra, e a regra acima é a regra
dessa porta. Pedir para conectar como alguém que você não é recebe uma recusa nela:

```
ana@db:~$ psql -U postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

E a outra porta, a de rede na porta 5432, tem outra regra: **uma senha**. Seu papel não tem
nenhuma, então o servidor pede e não recebe nada:

```
ana@db:~$ psql -h localhost
Password for user ana: 
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: fe_sendauth: no password supplied
```

O `-h localhost` fez o `psql` conectar por TCP em vez do socket, mesmo com o servidor na mesma
máquina. As duas regras vêm de um arquivo só, o `pg_hba.conf`, e a lição 5 o lê linha por linha.
Para este curso, o socket e a autenticação peer bastam.
