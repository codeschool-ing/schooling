---
title: O que o sqlc pega, e quando
version: 1
---

A promessa da seção 02 era que o Go não consegue se descolar do SQL. O próprio SQL ainda pode estar
errado, e a pergunta interessante é **quando você descobre: no `sqlc generate`, no `go build`, ou quando
um cliente aperta Comprar.** Eis um erro de digitação, `sould` no lugar de `sold`, digitado na consulta
`SellSeats` com a configuração da seção 04:

```
ana@vm:~/boxoffice$ sed -i 's/seats - sold >= sqlc.arg(quantity)/seats - sould >= sqlc.arg(quantity)/' queries.sql && sqlc generate && go build ./... && echo built
built
```

**O sqlc gerou, o Go compilou, e nada reclamou.** O erro está dentro do `WHERE`, numa expressão, e a
análise que o próprio sqlc faz da consulta não conferiu cada nome usado ali. O programa subiu, e a
primeira compra o encontrou:

```
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Internal Server Error","status":500}
ana@vm:~/boxoffice$ tail -2 .server.log
2026/10/16 20:08:24 unexpected error: ERROR: column "sould" does not exist (SQLSTATE 42703)
2026/10/16 20:08:24 POST /events/1/tickets 500 68B 2.732ms
```

O PostgreSQL recusou o comando com SQLSTATE `42703`, coluna indefinida, e o cliente recebeu um 500. É um
lugar melhor que uma resposta errada em silêncio, e pior que o seu próprio terminal.

## Perguntando ao banco

O sqlc faz melhor se puder **perguntar ao próprio PostgreSQL**. Com um banco onde se conectar, ele prepara
cada consulta contra ele durante o `generate`, e o PostgreSQL confere cada nome, cada tipo e cada
parâmetro exatamente como faria em tempo de execução. É um bloco a mais na configuração:

```yaml
# boxoffice/sqlc.yaml
version: "2"
sql:
  - engine: postgresql
    schema: schema.sql
    queries: queries.sql
    database:
      uri: ${DATABASE_URL}
    gen:
      go:
        package: db
        out: internal/db
        sql_package: pgx/v5
```

O `${DATABASE_URL}` é lido do ambiente, a mesma variável que a seção 02 da aula 6 mandou você pôr no
`~/.profile`, então nenhum endereço fica escrito no arquivo. Com ele:

```
ana@vm:~/boxoffice$ sqlc generate
# package db
queries.sql:15:12: column "sould" does not exist
ana@vm:~/boxoffice$ sed -i 's/seats - sould/seats - sold/' queries.sql && sqlc generate && echo clean
clean
ana@vm:~/boxoffice$ sed -i 's/VALUES ($1, $2)/VALUES ($1)/' queries.sql && sqlc generate
# package db
queries.sql:10:27: INSERT has more target columns than expressions
ana@vm:~/boxoffice$ sed -i 's/VALUES ($1)/VALUES ($1, $2)/' queries.sql && sqlc generate && echo clean
clean
ana@vm:~/boxoffice$ env -u DATABASE_URL sqlc generate 2>&1 | head -2
# package db
queries.sql:1:1: failed to connect to `user=ana database=`: /var/run/postgresql/.s.PGSQL.5432 (/var/run/postgresql): server error: FATAL: database "ana" does not exist (SQLSTATE 3D000)
```

**O erro de digitação agora é um erro do `generate`, com linha e coluna**, `queries.sql:15:12`, antes de
qualquer Go ser compilado. Um valor faltando num `INSERT` é pego do mesmo jeito. O último comando mostra o
custo: **sem um banco a quem perguntar, o `generate` nem roda**, então o banco tem de existir e já ter as
tabelas. Na aula 9, as migrações garantem isso antes de qualquer outra coisa rodar, e num pipeline de
integração contínua isso quer dizer um PostgreSQL rodando ao lado do build.

## O que ele não pega

Nenhuma das duas análises sabe para que serve a consulta. Um `WHERE seats - sold >= $1` escrito como `<=`
é SQL válido, gera código limpo e vende lugares que não existem, até o `CHECK` da tabela da aula 6 recusar
a linha. **O sqlc confere se o SQL quer dizer alguma coisa; só os testes conferem se quer dizer a coisa
certa**, e a aula 15 os escreve contra um banco de verdade exatamente por isso.
