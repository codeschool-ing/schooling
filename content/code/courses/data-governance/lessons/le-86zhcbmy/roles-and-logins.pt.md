---
title: Papéis, e o papel que faz login
version: 1
---

O PostgreSQL tem um tipo só de principal e o chama de **papel** (*role*). Um papel que pode abrir
conexão é o que outros sistemas chamam de usuário; um que não pode é o que chamam de grupo. É um
conceito só, com um atributo, `LOGIN`, e isso acaba sendo útil: um papel pode ser concedido a
outro papel, então um grupo é só um papel de que alguém é membro.

O cluster novo tem dois:

```
ana@lab:~/gov$ sudo -u postgres psql -c "\du"
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 ipe_owner | Cannot login
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
```

`postgres` é o **superusuário**. Um superusuário pula toda verificação de permissão do banco — as
concessões, as políticas de linha, tudo — e no Ubuntu só é alcançável pelo usuário `postgres` do
próprio sistema operacional, via `sudo`. `ipe_owner` é o papel dono das tabelas da Ipê, e ele não
pode logar. Ninguém nunca *é* `ipe_owner`; as pessoas *viram* ele, de propósito, quando o schema
precisa mudar.

## O login da própria Ana

Ana é a engenheira de dados. Ela precisa criar os outros papéis e, de vez em quando, mudar o
schema — mas não deveria carregar os privilégios do dono o dia inteiro, porque um `DROP` digitado
errado passaria:

```sql
-- Ana's own login. She creates and manages the other roles, and may
-- become the owner of the tables when she chooses to, never by default.
CREATE ROLE ana LOGIN CREATEROLE;
GRANT ipe_owner TO ana WITH INHERIT FALSE;
```

```
ana@lab:~/gov$ sudo -u postgres psql -d ipe < ana.sql
CREATE ROLE
GRANT ROLE
ana@lab:~/gov$ psql -c "SELECT current_user, session_user"
 current_user | session_user 
--------------+--------------
 ana          | ana
(1 row)
```

Dois atributos carregam o desenho.

**`CREATEROLE` deixa a Ana criar papéis e administrar os que ela criou.** Desde o PostgreSQL 16 é
só isso que ele deixa: um papel criado por outra pessoa não é dela para alterar, e ela não pode
distribuir `SUPERUSER`, que não tem. Antes da 16, `CREATEROLE` era quase um superusuário
disfarçado.

**`WITH INHERIT FALSE` faz da posse um passo que ela dá.** Ana é membro de `ipe_owner`, mas os
privilégios dele não chegam a ela automaticamente. Quando o schema precisa mudar ela digita
`SET ROLE ipe_owner`, e a mudança é feita sob esse nome; quando ela está lendo dados ela é só
`ana`. A diferença aparece no log e em toda mensagem de erro.

## Um login por pessoa, um por programa

```sql
-- One login per person and one per program. No passwords here: a password
-- typed into SQL travels to the server as text and can land in a log.
CREATE ROLE bruno LOGIN;                          -- analyst, BI
CREATE ROLE carla LOGIN;                          -- customer support
CREATE ROLE davi  LOGIN;                          -- the DPO (encarregado)
CREATE ROLE lia   LOGIN VALID UNTIL '2026-06-30'; -- intern, contract ended
CREATE ROLE site_app   LOGIN CONNECTION LIMIT 3;  -- the website
CREATE ROLE etl_loader LOGIN;                     -- the nightly pipeline
```

```
ana@lab:~/gov$ psql -f logins.sql
CREATE ROLE
CREATE ROLE
CREATE ROLE
CREATE ROLE
CREATE ROLE
CREATE ROLE
```

Seis papéis, e cada um representa exatamente uma pessoa ou um programa. **Essa é a decisão que torna
possível todo o resto do curso.** Uma trilha de auditoria só diz o que `bruno` fez se `bruno` for o
Bruno. Uma permissão só pode ser revogada da estagiária que saiu se ela tinha login próprio. E a
pergunta da aula 10 — quem leu a tabela de receitas em maio — só tem resposta se a resposta for um
nome.

Dois deles têm atributos que os outros não têm, e a seção 12 usa os dois: a senha de `lia` para de
funcionar em 30 de junho, e `site_app` nunca segura mais de três conexões ao mesmo tempo.

```
ana@lab:~/gov$ psql -c "\du"
                              List of roles
 Role name  |                         Attributes                         
------------+------------------------------------------------------------
 ana        | Create role
 bruno      | 
 carla      | 
 davi       | 
 etl_loader | 
 ipe_owner  | Cannot login
 lia        | Password valid until 2026-06-30 00:00:00-03
 postgres   | Superuser, Create role, Create DB, Replication, Bypass RLS
 site_app   | 3 connections
```

Nenhum deles tem senha ainda, então nenhum consegue logar pela rede. A próxima seção dá uma a
cada um.
