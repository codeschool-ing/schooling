---
title: Participação, e as três opções de um grant
version: 1
---

**Um grupo é um papel do qual outros papéis são membros**, e a participação é concedida com o mesmo
`GRANT` que concede uma tabela, com um papel no lugar da tabela. Os privilégios são então dados uma
vez, ao grupo, e uma pessoa os recebe entrando nele. Quando um analista sai, um `REVOKE` tira tudo,
em vez de uma caçada por todas as tabelas que ele um dia recebeu.

O que o PostgreSQL 16 acrescentou é uma resposta precisa para "recebe como". Uma participação agora
tem três opções próprias, e **cada uma responde a uma pergunta diferente**:

| opção | a pergunta que ela responde | padrão |
|---|---|---|
| `INHERIT` | o membro usa os privilégios do grupo sem pedir? | ligada, a partir do atributo `INHERIT` do membro |
| `SET` | o membro pode virar o grupo com `SET ROLE`? | ligada |
| `ADMIN` | o membro pode conceder o grupo a outros, e tirá-lo? | desligada |

## Herdando

Dê ao grupo um privilégio, um único `SELECT` em `customers` (a lição 12 é sobre `GRANT` em tabelas;
uma linha basta aqui), e ponha o `bruno` no grupo:

```
shop=# GRANT SELECT ON customers TO reporting;
GRANT

shop=# GRANT reporting TO bruno;
GRANT ROLE

shop=# \drg
               List of role grants
 Role name | Member of |   Options    | Grantor  
-----------+-----------+--------------+----------
 bruno     | reporting | INHERIT, SET | postgres
(1 row)

shop=# SET ROLE bruno;
SET

shop=> SELECT current_user, session_user;
 current_user | session_user 
--------------+--------------
 bruno        | ana
(1 row)

shop=> SELECT count(*) FROM customers;
 count 
-------
 50000
(1 row)

shop=> SELECT count(*) FROM orders;
ERROR:  permission denied for table orders

shop=> RESET ROLE;
RESET
```

O `\drg` é novo no psql 16 e lista as participações com suas opções; versões mais antigas do psql
mostravam uma coluna `Member of` no `\du`. Os padrões saíram como `INHERIT, SET`. O `bruno` leu
`customers` sem fazer nada, porque herda o privilégio do `reporting`, e foi recusado em `orders`,
que ninguém deu ao grupo.

Vale digitar `SELECT current_user, session_user` sempre que testar assim. **O `session_user` é quem
fez login; o `current_user` é de quem são os privilégios verificados.** O `SET ROLE` muda o segundo
e deixa o primeiro em paz.

Agora tire a herança e mantenha a participação:

```
shop=# GRANT reporting TO bruno WITH INHERIT FALSE;
GRANT ROLE

shop=# SET ROLE bruno;
SET

shop=> SELECT count(*) FROM customers;
ERROR:  permission denied for table customers

shop=> RESET ROLE;
RESET
```

Conceder uma participação que já existe muda as opções dela, então isso não criou uma segunda. O
`bruno` continua no `reporting`, e o privilégio não chega mais até ele sozinho. Ele precisa trocar
para o grupo com `SET ROLE reporting` antes, e é para isso que serve o `INHERIT FALSE`. Um grupo
perigoso, que pode apagar tabelas, é então usado de propósito e por um momento, e todos os outros
comandos rodam com os direitos comuns da pessoa.

## A única verificação que o SET ROLE não muda

O `SET` é o caso oposto: herdar os privilégios, mas nunca poder virar o grupo. Desligue-o e teste da
sessão da `ana`, do mesmo jeito de antes:

```
shop=# GRANT reporting TO bruno WITH INHERIT TRUE, SET FALSE;
GRANT ROLE

shop=# \drg
            List of role grants
 Role name | Member of | Options | Grantor  
-----------+-----------+---------+----------
 bruno     | reporting | INHERIT | postgres
(1 row)

shop=# SET ROLE bruno;
SET

shop=> SET ROLE reporting;
SET

shop=> SELECT current_user, session_user;
 current_user | session_user 
--------------+--------------
 reporting    | ana
(1 row)

shop=> RESET ROLE;
RESET
```

O `bruno` não tem a opção `SET` sobre o `reporting`, e a troca funcionou mesmo assim. **Quem decide
se você pode dar `SET ROLE` é o usuário da sessão, não o atual**, e o usuário da sessão aqui é a
`ana`, uma superusuária que pode virar qualquer um. Então o `SET ROLE` é um jeito fiel de testar o
que um papel pode fazer com tabelas, e um jeito inútil de testar o que ele pode fazer com suas
participações. O mesmo vale para tudo o que é verificado quando a conexão abre, e é por isso que a
próxima seção faz login como `bruno` de verdade e repete este teste.

## ADMIN, e servidores mais antigos

O `ADMIN` é a opção que o `steward` recebeu na seção anterior. Um membro com ela pode conceder o
grupo a outros papéis e revogá-lo deles, e é assim que um líder de equipe administra quem lê os
relatórios sem ser superusuário. Ela é dada com `GRANT reporting TO bruno WITH ADMIN TRUE`.

Antes da versão 16 não existia a opção `SET`, e o `INHERIT` não era uma propriedade da
participação: era só o atributo do papel membro, então um papel herdava de **todos** os seus grupos
ou de nenhum. O `WITH ADMIN OPTION` existia e significava o mesmo que hoje. O atributo continua
existindo na 16 e fornece o padrão para os grants novos; daí em diante, quem decide é o grant.
