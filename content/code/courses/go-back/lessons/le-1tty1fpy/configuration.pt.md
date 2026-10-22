---
title: A configuração e as consultas
version: 1
---

Dois arquivos em `~/boxoffice` dizem ao sqlc o que fazer. Primeiro a configuração:

```yaml
# boxoffice/sqlc.yaml
version: "2"
sql:
  - engine: postgresql
    schema: schema.sql
    queries: queries.sql
    gen:
      go:
        package: db
        out: internal/db
        sql_package: pgx/v5
```

Leia de cima para baixo: **um "pacote" SQL para o PostgreSQL**, com as tabelas no `schema.sql` da aula
6, as consultas em `queries.sql`, e Go a ser gerado como um pacote chamado `db` em `internal/db`, usando
o pgx versão 5 em vez de `database/sql`. `internal/` é um nome de diretório que o comando go trata de
modo especial: o código debaixo dele só pode ser importado de dentro do módulo, então o pacote gerado
continua sendo só do boxoffice.

Depois as consultas, que são as quatro que o `pgStore` da aula 6 envia, tiradas das strings do Go e
postas num arquivo próprio:

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
```

**O comentário acima de cada consulta não é um comentário para o sqlc.** `-- name: SellSeats :one` dá
nome à função Go e diz o que ela devolve:

| anotação | a função gerada devolve |
|---|---|
| `:one` | uma linha como struct, ou `pgx.ErrNoRows` |
| `:many` | um slice de structs, vazio quando não há linhas |
| `:exec` | só um erro |
| `:execrows` | o número de linhas afetadas, e um erro |

Os parâmetros são `$1`, `$2` como na aula 6, e o sqlc dá a cada um o nome da coluna com que é comparado
ou na qual é inserido: o `$1` de `GetEvent` vira um argumento chamado `id`. Onde isso ficaria confuso,
como em `SellSeats`, em que a quantidade é usada duas vezes e comparada com uma expressão em vez de uma
coluna, **`sqlc.arg(quantity)` dá o nome explicitamente**, e o mesmo nome usado duas vezes é um
parâmetro só.

Não é preciso mais nada. O `schema.sql` é o arquivo que a aula 6 rodou com o `psql`, sem mudança; o
sqlc lê o `CREATE TABLE` dele para conhecer as colunas e seus tipos, e ignora o `INSERT`.
