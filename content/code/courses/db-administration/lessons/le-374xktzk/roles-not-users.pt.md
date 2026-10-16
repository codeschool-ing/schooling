---
title: Um papel, não um usuário
version: 1
---

O PostgreSQL tem **um tipo só de conta, e chama de papel** (role). Um papel que pode fazer login é
o que outros sistemas chamam de usuário; um papel que não pode é o que eles chamam de grupo; e o
mesmo papel pode ser as duas coisas ao mesmo tempo. Os papéis moram dentro do cluster e não têm
nada a ver com as contas do `/etc/passwd`, mesmo quando os nomes coincidem.

A imagem errada é a que a lição 3 deixou: seu usuário do sistema operacional é `ana`, seu papel é
`ana`, então os dois devem ser uma coisa só. São duas coisas com o mesmo nome, e o servidor só junta
as duas na porta, quando alguém conecta. O resto desta lição as mantém separadas de propósito.

## Duas listas que não têm nada em comum

A máquina não tem usuário chamado `bruno`, e o cluster tem dois papéis próprios além dos
predefinidos `pg_`:

```
ana@db:~$ id bruno
id: 'bruno': no such user
shop=# SELECT rolname FROM pg_roles WHERE rolname !~ '^pg_';
 rolname  
----------
 postgres
 ana
(2 rows)

shop=# CREATE ROLE reporting;
CREATE ROLE

shop=# CREATE USER bruno;
CREATE ROLE

shop=# CREATE USER app;
CREATE ROLE

shop=# \du
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 ana       | Superuser, Create role, Create DB
 app       | 
 bruno     | 
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
 reporting | Cannot login
```

O `CREATE USER` respondeu `CREATE ROLE`, porque é só isso que ele é: **`CREATE USER` é `CREATE ROLE`
com `LOGIN` ligado**. A única diferença entre `reporting` e `bruno` nessa listagem é o `Cannot login`
ao lado do primeiro. Existe também o `CREATE GROUP`, uma terceira grafia de `CREATE ROLE` mantida
para scripts antigos. Use `CREATE ROLE` e escreva `LOGIN` quando quiser dizer isso, para que o
comando diga o que faz.

Os três papéis têm funções nas próximas três lições. **`reporting` é um grupo** que vai receber
acesso de leitura; **`bruno` é uma pessoa**, um analista que vai entrar nesse grupo; **`app` é a
aplicação**, que conecta com senha e grava pedidos. Nenhum deles consegue fazer nada ainda.

O `bruno` não ganhou conta na máquina, e não precisa de uma. Ele vai conectar ao banco de onde
estiver trabalhando, e o servidor nunca vai perguntar ao sistema operacional se ele existe.

## Um papel pertence ao cluster, uma tabela a um banco

Uma tabela mora num banco. Um papel não: ele fica guardado no `pg_authid`, uma das poucas tabelas
do catálogo **compartilhadas por todos os bancos do cluster**, assim como a própria lista de bancos.

```
shop=# SELECT relname, relisshared FROM pg_class WHERE relname IN ('pg_authid', 'pg_database', 'pg_class', 'customers');
   relname   | relisshared 
-------------+-------------
 customers   | f
 pg_authid   | t
 pg_class    | f
 pg_database | t
(4 rows)

shop=# \c ana
You are now connected to database "ana" as user "ana".

ana=# SELECT rolname FROM pg_roles WHERE rolname = 'bruno';
 rolname 
---------
 bruno
(1 row)
```

O `bruno` foi criado com a conexão no `shop` e está igualmente presente no `ana`. O que ele pode
FAZER em cada banco é outra questão, decidida por grants que moram dentro de cada um; a lição 12 é
sobre eles. O `pg_roles` é a visão legível sobre o `pg_authid`, com a coluna de senha apagada, e é
ela que se consulta por hábito.

## A mesma ideia nos outros três motores

Cada um dos motores que a lição 2 apresentou traça essa linha num lugar diferente, e o vocabulário
confunde quem passa de um para o outro:

| motor | uma conta é | pertence a |
|---|---|---|
| PostgreSQL | um papel, com `LOGIN` ou não | o cluster |
| MySQL | `'user'@'host'`: o mesmo nome vindo de dois hosts são duas contas | o servidor |
| SQL Server | um login no servidor, mapeado para um usuário em cada banco | os dois, em duas etapas |
| Oracle | um usuário, que também é um esquema com os objetos desse usuário | o banco |

As duas etapas do SQL Server são o que há de mais próximo da separação do PostgreSQL entre um papel
e seus grants, e a do Oracle é a mais distante: lá, criar um usuário cria um lugar para tabelas, e
aqui um papel não é dono de nada até criar alguma coisa.
