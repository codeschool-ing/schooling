---
title: De onde esta lição parte
version: 1
---

Esta lição usa os três papéis que a lição 11 criou nas suas duas últimas seções: **`reporting`**,
um grupo que não pode fazer login; **`bruno`**, um analista que pode, e é membro do `reporting`; e
**`app`**, a aplicação. Os dois papéis de login têm senha, guardada no `~/.pgpass` para que o psql
possa usá-las sem perguntar. Se você seguiu a lição 11 no seu servidor, está tudo lá e você pode
pular para a conferência no fim desta seção.

Se você está começando aqui, conecte ao `shop` como `ana` com `psql shop` e crie os papéis:

```sql
-- where lesson 12 starts: lesson 11's three roles, run in shop as ana
CREATE ROLE reporting;
CREATE ROLE bruno LOGIN IN ROLE reporting;
CREATE ROLE app LOGIN;
```

O `IN ROLE reporting` torna o `bruno` membro do grupo com as opções padrão. Depois dê as senhas aos
dois papéis de login com o `\password` do psql, que pergunta duas vezes e não mostra nada: digite
`bruno-lab-only` depois de `\password bruno` e `app-lab-only` depois de `\password app`. A seção de
senhas da lição 11 explica por que uma senha se define assim e nunca dentro de um comando
`ALTER ROLE`.

Por último, abra o `~/.pgpass` num editor, ponha estas linhas nele e deixe-o legível só por você com
`chmod 600 ~/.pgpass`. Do contrário, a libpq ignora o arquivo.

```conf
# ~/.pgpass: hostname:port:database:username:password
localhost:5432:*:bruno:bruno-lab-only
localhost:5432:*:app:app-lab-only
```

Seja qual for o caminho por onde você chegou, este é o estado para comparar. Se você veio da lição
11, o `app` também traz `Password valid until infinity`, o que não muda nada.

```
shop=# \du
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 ana       | Superuser, Create role, Create DB
 app       | 
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

**Todo teste de outro papel nesta lição faz login como esse papel de verdade**, com
`psql -h localhost -U bruno shop`: pela porta de rede, com a senha do `~/.pgpass`, do jeito que a
aplicação conecta. A lição 11 mostrou por que um `SET ROLE` na sessão de um superusuário não basta
aqui: a primeira porta desta lição é verificada quando a conexão abre, e o `SET ROLE` nunca abre
uma.
