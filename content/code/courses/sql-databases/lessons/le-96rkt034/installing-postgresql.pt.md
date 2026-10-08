---
title: Instalando o PostgreSQL, e a primeira conversa com ele
version: 1
---

No prompt da sua máquina Ubuntu, dois comandos instalam o servidor, o cliente `psql` e tudo de que
eles precisam:

```sh
sudo apt update
sudo apt install -y postgresql
```

O `sudo` pede sua senha, e o `apt` imprime uma tela de progresso por um ou dois minutos. As últimas
linhas falam de criar um **cluster**, que é a palavra do PostgreSQL para um servidor rodando e o
diretório onde ficam os seus dados. Pergunte o que você ganhou:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Versão 16, um cluster chamado `main`, escutando na porta 5432, **`online`**. A última coluna é onde
ele escreve o log, e é o primeiro lugar para olhar quando algo dá errado.

## Você, como o banco conhece você

O PostgreSQL mantém sua própria lista de quem pode se conectar, separada dos usuários do
computador. O instalador pôs exatamente um nome nela, `postgres`, e você não é ele:

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

Um **role** é um usuário do banco. Crie um com o seu nome, como `postgres`, que tem permissão para
isso:

```
ana@vm:~$ sudo -u postgres createuser --superuser $USER
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "ana" does not exist
```

O `createuser` não imprimiu nada, que é como ele diz que funcionou. `--superuser` deixa o seu role
fazer qualquer coisa neste servidor — certo para uma máquina que é sua e de mais ninguém, e errado
em qualquer outro lugar. `$USER` é o seu nome de usuário, preenchido pelo shell.

A segunda recusa é outra, e é um progresso. Você entrou; não havia onde entrar. O `psql` sem nome
se conecta a um **banco de dados** chamado igual a você, e não existe nenhum. Um servidor guarda
muitos bancos, e este curso usa um chamado `shop`:

```
ana@vm:~$ createdb shop
```

## Uma linha de configuração

O `psql` imprime um valor ausente como nada, o que parece exatamente um texto vazio. A aula 1 está
prestes a gastar uma etapa inteira com essa diferença, então torne-a visível. Isto escreve um
arquivo que o `psql` lê toda vez que abre:

```sh
cat > ~/.psqlrc <<'RC'
\set QUIET on
\pset null NULL
\unset QUIET
RC
```

A linha do meio é a configuração — mostrar um valor ausente como a palavra `NULL`. As linhas em
volta impedem o `psql` de anunciar a mudança toda vez que você o abre.

## A primeira conversa

```
ana@vm:~$ psql shop
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
Type "help" for help.

shop=# SELECT 1 + 1 AS two;
 two 
-----
   2
(1 row)

shop=# SELECT NULL AS nothing;
 nothing 
---------
 NULL
(1 row)

shop=# \q
```

**`shop=#` é o prompt**: o banco em que você está, e `#` porque o seu role é superusuário. Um
comando termina no ponto e vírgula, e até você digitar um o `psql` espera, com o prompt virado em
`shop-#` para dizer que ainda está escutando. Comandos que começam com barra invertida são do
próprio `psql`, não SQL, não precisam de ponto e vírgula, e `\q` é o que sai.

Esse é o ambiente inteiro. As tabelas da loja chegam no fim desta aula, quando você já souber o que
é uma tabela.
