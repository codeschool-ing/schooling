---
title: Atributos, e o que o CREATEROLE deixou de significar
version: 1
---

Um papel carrega dois tipos de poder, e eles ficam em lugares diferentes. **Atributos** são poderes
sobre o cluster inteiro: se o papel pode fazer login, criar bancos, criar outros papéis ou pular
todas as verificações. **Privilégios** são direitos sobre um objeto: uma tabela, um esquema, um
banco. Atributos são definidos com `CREATE ROLE` e `ALTER ROLE` e mostrados pelo `\du`; privilégios
são o assunto da lição 12.

## Os atributos

| atributo | o que ele deixa o papel fazer | o `\du` mostra |
|---|---|---|
| `LOGIN` | conectar, simplesmente | `Cannot login` quando falta |
| `SUPERUSER` | qualquer coisa, sem verificação nenhuma | `Superuser` |
| `CREATEDB` | criar bancos | `Create DB` |
| `CREATEROLE` | criar papéis, e administrar aqueles sobre os quais tem ADMIN | `Create role` |
| `INHERIT` | usar os privilégios dos papéis de que é membro, por padrão | `No inheritance` quando está desligado |
| `REPLICATION` | conectar como cliente de replicação | `Replication` |
| `BYPASSRLS` | ignorar as políticas de segurança por linha | `Bypass RLS` |
| `CONNECTION LIMIT n` | no máximo n sessões ao mesmo tempo | `n connections` |
| `VALID UNTIL 'momento'` | usar a senha até então | `Password valid until …` |

Cada um tem uma forma com `NO`, e `ALTER ROLE bruno NOLOGIN` é como se desliga uma conta sem
apagar o que ela possui. O `REPLICATION` pertence à lição 11 de db-reliability; o `BYPASSRLS`
encontra a segurança por linha na lição 12; o `VALID UNTIL` é a última seção desta lição.

**`SUPERUSER` não é um conjunto maior de privilégios; é a ausência da verificação.** Um
superusuário pode ler qualquer tabela, mudar qualquer papel, ler arquivos do servidor pelo `COPY` e
rodar programas nele como o usuário `postgres`. A `ana` tem esse atributo porque é a administradora
de um servidor que existe para ser administrado. Uma aplicação, um analista e uma ferramenta de
monitoramento nunca precisam dele, e cada uma das próximas três lições mostra a coisa mais estreita
de que eles precisam no lugar.

## O CREATEROLE no PostgreSQL 16

Um papel com `CREATEROLE` pode criar papéis. O que ele pode fazer com papéis **que não criou** é a
parte que mudou na versão 16, e a mudança é o motivo de uma equipe agora poder entregar esse
atributo a alguém que não é superusuário.

Crie um papel `steward` com ele, vire esse papel com `SET ROLE` e tente quatro coisas:

```
shop=# CREATE ROLE steward LOGIN CREATEROLE;
CREATE ROLE

shop=# SET ROLE steward;
SET

shop=> CREATE ROLE intern LOGIN;
CREATE ROLE

shop=> ALTER ROLE bruno CREATEDB;
ERROR:  permission denied to alter role
DETAIL:  Only roles with the CREATEROLE attribute and the ADMIN option on role "bruno" may alter this role.

shop=> ALTER ROLE intern SUPERUSER;
ERROR:  permission denied to alter role
DETAIL:  Only roles with the SUPERUSER attribute may change the SUPERUSER attribute.

shop=> GRANT pg_read_all_data TO intern;
ERROR:  permission denied to grant role "pg_read_all_data"
DETAIL:  Only roles with the ADMIN option on role "pg_read_all_data" may grant this role.

shop=> RESET ROLE;
RESET

shop=# \drg
            List of role grants
 Role name | Member of | Options | Grantor  
-----------+-----------+---------+----------
 steward   | intern    | ADMIN   | postgres
(1 row)
```

O prompt mudou de `#` para `>` porque o papel atual deixou de ser superusuário. O `steward` criou o
`intern`, e **criá-lo deu ao `steward` a opção ADMIN sobre ele**, que é a linha que o `\drg`
imprimiu: o `steward` é membro do `intern` com `ADMIN`, concedido por `postgres`, o superusuário de
bootstrap, porque foi o próprio servidor que fez esse grant. Com ADMIN sobre o `intern`, o
`steward` pode alterá-lo, renomeá-lo, apagá-lo e concedê-lo a outros. Sobre o `bruno`, que outra
pessoa criou, não pode nada disso. E nenhum papel com `CREATEROLE` consegue distribuir um atributo
que não tem ou um papel sobre o qual não tem ADMIN, então ele não consegue criar um superusuário nem
se pôr dentro de um papel predefinido como o `pg_read_all_data`.

**No PostgreSQL 15 e anteriores, o `CREATEROLE` podia alterar ou apagar qualquer papel que não
fosse superusuário, e conceder participação em qualquer papel**, inclusive os papéis predefinidos
que leem e escrevem os arquivos do servidor e rodam programas nele. A documentação dessas versões
mandava tratá-lo como quase um superusuário, e tinha razão. Se você administra um servidor mais
antigo, um papel com `CREATEROLE` ali merece a mesma desconfiança que um com `SUPERUSER`.

O `steward` consegue arrumar a própria bagunça, e a `ana` remove o `steward`:

```
shop=# SET ROLE steward;
SET

shop=> DROP ROLE intern;
DROP ROLE

shop=> RESET ROLE;
RESET

shop=# DROP ROLE steward;
DROP ROLE
```

O `SET ROLE` foi a ferramenta honesta aqui, porque cada recusa acima é uma verificação dos
privilégios do papel atual, e o `SET ROLE` muda exatamente isso. A próxima seção encontra a única
verificação que ele não muda.

## Parâmetros por papel

O `ALTER ROLE` faz mais uma coisa que não tem nada a ver com poder: ele define um **parâmetro para
toda sessão daquele papel**. `ALTER ROLE bruno SET statement_timeout = '5min'` impede qualquer
relatório dele de rodar por uma hora, e `ALTER ROLE app SET idle_in_transaction_session_timeout =
'1min'` aplica o timeout da lição 10 só à aplicação. A configuração vale a partir do próximo login
do papel, e só para o papel que fez login: uma configuração no grupo `reporting` não chega a nenhum
dos seus membros, porque ninguém faz login como grupo. A lição 5 mostra onde isso fica em relação
aos outros lugares de onde um parâmetro pode vir.
