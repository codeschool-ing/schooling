---
title: goose: migrações como arquivos SQL numerados
version: 1
---

O goose é duas coisas: uma ferramenta de linha de comando que aplica migrações a um banco, e uma
biblioteca Go que faz o mesmo de dentro de um programa. **Primeiro a ferramenta de linha de comando**,
instalada como o sqlc na aula 8, numa versão fixada:

```
ana@vm:~$ go install github.com/pressly/goose/v3/cmd/goose@v3.29.0
ana@vm:~$ goose --version
goose version: v3.29.0
...
ana@vm:~$ go install github.com/pressly/goose/v3/cmd/goose@v3.29.0
ana@vm:~$ goose --version
goose version: v3.29.0
```

O `...` está no lugar de umas cinquenta linhas de download, cortadas aqui e mais nada: **o comando goose
suporta uma dúzia de bancos, e o `go install` baixou um driver para cada um**, ClickHouse, MySQL, SQL
Server e SQLite entre eles. Nada disso chega ao boxoffice, que vai importar só a biblioteca do goose e o
pgx que já tem; é o preço de uma ferramenta de uso geral no seu notebook.

## Duas migrações

O `schema.sql` da aula 6 vira a primeira migração, e a tabela de que esta aula precisa vira a segunda.
Elas moram em `~/boxoffice/migrations`, e **o número no começo de cada nome é a versão dela**:

```sql
-- boxoffice/migrations/00001_events.sql
-- +goose Up
CREATE TABLE events (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  text    NOT NULL UNIQUE CHECK (length(name) BETWEEN 1 AND 100),
    seats integer NOT NULL CHECK (seats > 0),
    sold  integer NOT NULL DEFAULT 0 CHECK (sold BETWEEN 0 AND seats)
);

INSERT INTO events (name, seats, sold) VALUES
    ('Jazz at the Docks', 120, 0),
    ('Chamber Choir', 80, 80);

-- +goose Down
DROP TABLE events;
```

```sql
-- boxoffice/migrations/00002_tickets.sql
-- +goose Up
CREATE TABLE tickets (
    id         integer     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id   integer     NOT NULL REFERENCES events (id),
    email      text        NOT NULL,
    quantity   integer     NOT NULL CHECK (quantity BETWEEN 1 AND 10),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX tickets_event_id ON tickets (event_id);

-- +goose Down
DROP TABLE tickets;
```

`-- +goose Up` e `-- +goose Down` são as marcas do goose, lidas por ele e comentários para todo o resto.
A primeira migração também insere os dois eventos com que toda aula começou, porque uma migração é só
SQL e as linhas fazem parte do estado inicial; um serviço de verdade deixaria dados de teste fora das
migrações e os carregaria à parte.

`tickets` registra cada venda: qual evento, quem, quantos e quando. `REFERENCES events (id)` é uma
chave estrangeira, então um ingresso só aponta para um evento que existe, e o `CHECK` repete o limite
de 10 por compra da API como uma regra que a tabela guarda.

## Começando de um banco vazio

O banco que a aula 6 montou à mão tem a tabela `events` e nenhum registro de como ela chegou lá, então o
goose tentaria criá-la de novo e falharia. **Numa máquina de desenvolvimento, o jeito mais simples é
começar de novo**; num banco de produção, você diria à ferramenta que a primeira migração já está
aplicada. O `schema.sql` agora é história, então apague-o:

```
ana@vm:~/boxoffice$ rm -f schema.sql && ls migrations
00001_events.sql
00002_tickets.sql
ana@vm:~/boxoffice$ dropdb boxoffice && createdb boxoffice
```

## Up, status, down

O goose recebe o diretório, o driver do banco e o endereço, aqui tirado do `DATABASE_URL` da aula 6:

```
ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" status
2026/10/16 20:18:42     Applied At                  Migration
2026/10/16 20:18:42     =======================================
2026/10/16 20:18:42     Pending                  -- 00001_events.sql
2026/10/16 20:18:42     Pending                  -- 00002_tickets.sql
ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" up
2026/10/16 20:18:42 OK   00001_events.sql (6.63ms)
2026/10/16 20:18:42 OK   00002_tickets.sql (6.12ms)
2026/10/16 20:18:42 goose: successfully migrated database to version: 2
ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" status
2026/10/16 20:18:42     Applied At                  Migration
2026/10/16 20:18:42     =======================================
2026/10/16 20:18:42     Fri Oct 16 23:18:42 2026 -- 00001_events.sql
2026/10/16 20:18:42     Fri Oct 16 23:18:42 2026 -- 00002_tickets.sql
ana@vm:~/boxoffice$ psql boxoffice -c "SELECT version_id, is_applied, tstamp FROM goose_db_version ORDER BY id"
 version_id | is_applied |           tstamp           
------------+------------+----------------------------
          0 | t          | 2026-10-16 23:18:42.204698
          1 | t          | 2026-10-16 23:18:42.238623
          2 | t          | 2026-10-16 23:18:42.245531
(3 rows)

ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" down
2026/10/16 20:18:42 OK   00002_tickets.sql (9.94ms)
ana@vm:~/boxoffice$ psql boxoffice -c "\dt"
             List of relations
 Schema |       Name       | Type  | Owner 
--------+------------------+-------+-------
 public | events           | table | ana
 public | goose_db_version | table | ana
(2 rows)

ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" up
2026/10/16 20:18:42 OK   00002_tickets.sql (6.56ms)
2026/10/16 20:18:42 goose: successfully migrated database to version: 2
```

**O `status` lista toda migração e se este banco a tem**; o `up` aplicou as duas, em ordem, e informou
a versão em que o banco está agora. A tabela `goose_db_version` é a memória do goose: uma linha por
migração aplicada, mais uma linha para a versão 0 que o goose escreve na primeira vez. O `down` desfez
só a última migração, rodando a seção `Down` dela, e o `\dt` mostra que `tickets` sumiu; o segundo `up`
a trouxe de volta. **Cada passo é um arquivo**, e o banco sempre sabe quais arquivos já viu.

## O sqlc lê os mesmos arquivos

O `sqlc.yaml` pode apontar para o diretório de migrações em vez de um único arquivo de schema. O sqlc
entende as marcas do goose, lê toda seção `Up` em ordem e ignora as `Down`, então **as migrações são o
único lugar onde o schema é escrito**:

```yaml
# boxoffice/sqlc.yaml
version: "2"
sql:
  - engine: postgresql
    schema: migrations
    queries: queries.sql
    database:
      uri: ${DATABASE_URL}
    gen:
      go:
        package: db
        out: internal/db
        sql_package: pgx/v5
```

As consultas ganham uma para a tabela nova:

```sql
-- boxoffice/queries.sql

-- name: ListEvents :many
SELECT id, name, seats, sold FROM events ORDER BY id;

-- name: GetEvent :one
SELECT id, name, seats, sold FROM events WHERE id = $1;

-- name: AddEvent :one
INSERT INTO events (name, seats) VALUES ($1, $2)
RETURNING id, name, seats, sold;

-- name: SellSeats :one
UPDATE events SET sold = sold + sqlc.arg(quantity)
WHERE id = sqlc.arg(id) AND seats - sold >= sqlc.arg(quantity)
RETURNING id, name, seats, sold;

-- name: SearchEvents :many
SELECT id, name, seats, sold FROM events
WHERE (sqlc.narg(min_available)::int IS NULL OR seats - sold >= sqlc.narg(min_available)::int)
  AND (sqlc.narg(name_like)::text IS NULL OR name ILIKE sqlc.narg(name_like)::text)
ORDER BY id;

-- name: InsertTicket :one
INSERT INTO tickets (event_id, email, quantity) VALUES ($1, $2, $3)
RETURNING id;
```

```
ana@vm:~/boxoffice$ sqlc generate && ls internal/db
db.go
models.go
queries.sql.go
```
