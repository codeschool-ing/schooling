---
title: Senhas, e onde elas não podem parar
version: 1
---

A autenticação peer funciona para quem está sentado no servidor. Todos os outros, a aplicação em
outra máquina e o analista no notebook dele, chegam pela rede, e o `pg_hba.conf` do Ubuntu pede a
uma conexão de rede uma **senha verificada com `scram-sha-256`**. Três coisas importam nessa senha:
como o servidor a guarda, como você a define sem deixá-la largada por aí, e como um programa a
fornece sem ninguém digitar.

## Como o servidor a guarda

**O servidor não guarda a senha.** Ele guarda um verificador SCRAM: um valor com sal, derivado da
senha por milhares de rodadas de hash, do qual a senha não pode ser recuperada. Com ele, o cliente e
o servidor provam um ao outro que conhecem a senha sem enviá-la. Defina duas com o `\password` do
psql, digitando `bruno-lab-only` para o `bruno` e `app-lab-only` para o `app`; as próximas lições
fazem login com elas:

```
shop=# SHOW password_encryption;
 password_encryption 
---------------------
 scram-sha-256
(1 row)

shop=# \password bruno
Enter new password for user "bruno": 
Enter it again: 
shop=# \password app
Enter new password for user "app": 
Enter it again: 
shop=# SELECT rolname, split_part(rolpassword, ':', 1) AS stored FROM pg_authid WHERE rolname IN ('bruno', 'app');
 rolname |       stored       
---------+--------------------
 bruno   | SCRAM-SHA-256$4096
 app     | SCRAM-SHA-256$4096
(2 rows)
```

A consulta mostra só o começo do que foi guardado, o método e as 4096 rodadas de hash; o resto é o
sal e as duas chaves. Só um superusuário pode ler o `pg_authid`.

**O `password_encryption` é `scram-sha-256` por padrão desde a versão 14.** Antes era `md5`, um
esquema mais fraco cujo valor guardado vale tanto quanto a senha para quem o roubar. Um cluster
atualizado de uma versão antiga mantém cada valor `md5` até que aquela senha seja definida de novo.
O `SELECT rolname FROM pg_authid WHERE rolpassword LIKE 'md5%'` encontra esses papéis, e o
PostgreSQL 18 avisa sempre que um novo é definido.

## Onde uma senha não pode parar

O `\password` perguntou duas vezes, não mostrou nada e mandou ao servidor um verificador calculado
pelo psql: **a senha em si nunca atravessou a conexão e nunca fez parte de comando nenhum**. O outro
jeito de definir uma é `ALTER ROLE bruno PASSWORD '…'`, e esse comando leva a senha em texto puro a
todo lugar aonde um comando pode ir. Aqui está um, com um erro de digitação no nome do papel:

```
shop=# ALTER ROLE brunno PASSWORD 'bruno-lab-only';
ERROR:  role "brunno" does not exist
ana@db:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:06.155 -03 [320] ana@shop ERROR:  role "brunno" does not exist
2026-10-10 04:26:06.155 -03 [320] ana@shop STATEMENT:  ALTER ROLE brunno PASSWORD 'bruno-lab-only';
```

O servidor registra no log, por padrão, o texto de um comando que falha, então o erro veio com a
senha do `bruno` ao lado, num arquivo que todo administrador lê e todo coletor de logs envia para
outro lugar. Num servidor de verdade, essa senha agora é de conhecimento de outras pessoas, e a única
correção é uma nova. Comandos que dão certo também chegam ao log quando o `log_statement` da lição 19
é aumentado, e o psql interativo guarda tudo o que você digita em `~/.psql_history`. Digitar
`psql -c "ALTER ROLE … PASSWORD '…'"` no shell acrescenta o `~/.bash_history` à lista.

**Então uma senha se define com `\password`, ou por um programa que envia um verificador, e nunca é
escrita à mão dentro de um comando.**

## Um arquivo de senhas para programas

Uma pessoa digita a senha no prompt. Um programa não consegue, e uma senha colada em cada script que
conecta é mais uma cópia em cada repositório e backup aonde esses scripts chegam. A libpq, a
biblioteca por baixo do psql e da maioria dos drivers, lê o **`~/.pgpass`** no lugar: uma linha por
conexão, cinco campos separados por dois-pontos, e `*` casando com qualquer coisa. Escreva-o com um
editor, para que as senhas não vão para histórico de shell nenhum:

```conf
# ~/.pgpass: hostname:port:database:username:password
localhost:5432:*:bruno:bruno-lab-only
localhost:5432:*:app:app-lab-only
```

O `-h localhost` faz o psql usar a porta de rede, onde a senha é pedida, e o `-w` diz para ele nunca
perguntar, então uma senha faltando vira erro na hora em vez de uma pergunta que ninguém responde. A
primeira tentativa falha por um motivo que aparece na tela e passa despercebido com facilidade:

```
ana@db:~$ ls -l ~/.pgpass
-rw-rw-r-- 1 ana ana 126 Oct 10 04:26 /home/ana/.pgpass
ana@db:~$ psql -w -h localhost -U app shop -c "SELECT current_user;"
WARNING: password file "/home/ana/.pgpass" has group or world access; permissions should be u=rw (0600) or less
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: fe_sendauth: no password supplied
ana@db:~$ chmod 600 ~/.pgpass
ana@db:~$ psql -w -h localhost -U app shop -c "SELECT current_user;"
 current_user 
--------------
 app
(1 row)

ana@db:~$ psql -w -h localhost -U bruno shop -c "SELECT current_user;"
 current_user 
--------------
 bruno
(1 row)
```

**A libpq ignora um arquivo de senhas que outros usuários conseguem ler**, e avisa com um warning em
vez de um erro. Num script que joga fora os warnings, só sobra o `no password supplied`, que manda as
pessoas procurarem o problema no servidor. Daqui em diante, `psql -h localhost -U bruno shop` é como
este curso faz login como outra pessoa, com a senha que o papel realmente tem, pela mesma porta que a
aplicação usa.

## Uma senha com data de validade

O `VALID UNTIL` põe uma data de expiração na senha de um papel. Defina uma no passado para o `app`:

```
shop=# ALTER ROLE app VALID UNTIL '2026-01-01';
ALTER ROLE

shop=# \du app
                      List of roles
 Role name |                 Attributes                  
-----------+---------------------------------------------
 app       | Password valid until 2026-01-01 00:00:00-03
ana@db:~$ psql -w -h localhost -U app shop
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "app"
password retrieved from file "/home/ana/.pgpass"
connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "app"
password retrieved from file "/home/ana/.pgpass"
ana@db:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:07.883 -03 [334] app@shop FATAL:  password authentication failed for user "app"
2026-10-10 04:26:07.883 -03 [334] app@shop DETAIL:  User "app" has an expired password.
	Connection matched file "/etc/postgresql/16/main/pg_hba.conf" line 125: "host    all             all             127.0.0.1/32            scram-sha-256"
```

O cliente só fica sabendo que a autenticação falhou, duas vezes, porque o psql tentou uma vez com
criptografia e outra sem. **O motivo está no log do servidor e só lá**: a senha estava certa e
expirou, e a conexão casou com a linha 125 do `pg_hba.conf`. Contar a um estranho qual parte do
login estava errada ajudaria o estranho, então o servidor guarda isso para quem lê o log, e esse é o
primeiro lugar para olhar quando um login falha.

O `VALID UNTIL` trata da senha e de mais nada. Um papel que faz login por peer, como a `ana`, não é
afetado, e uma sessão que já está aberta também não. É uma data para uma credencial, não uma conta
que se desliga sozinha; isso é o `NOLOGIN`. Ponha o `app` de volta:

```
shop=# ALTER ROLE app VALID UNTIL 'infinity';
ALTER ROLE

shop=# \du
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 ana       | Superuser, Create role, Create DB
 app       | Password valid until infinity
 bruno     | 
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
 reporting | Cannot login

shop=# \drg
               List of role grants
 Role name | Member of |   Options    | Grantor  
-----------+-----------+--------------+----------
 bruno     | reporting | INHERIT, SET | postgres
(1 row)
```

É daí que a lição 12 parte: um grupo sem privilégios, um analista nele com as opções padrão e uma
aplicação. O analista e a aplicação têm senhas, e as duas estão no `~/.pgpass`.
