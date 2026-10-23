---
title: Onde o sqlc fica desajeitado: filtros opcionais
version: 1
---

O modelo do sqlc é um comando SQL fixo por função. Isso serve para quase tudo que uma API faz, e serve mal
para uma coisa que as APIs fazem o tempo todo: **uma busca em que todo filtro é opcional.** `GET
/events?available=10&name=jazz` pode mandar um filtro, o outro, os dois ou nenhum, o que dá quatro
cláusulas `WHERE` diferentes. Um ORM monta a cláusula em tempo de execução, acrescentando uma condição
para cada filtro presente; o sqlc não tem como, porque o SQL precisa existir antes do programa.

A resposta habitual é escrever um comando só, que ignora os filtros que não vieram. Eis o `queries.sql`
com uma quinta consulta acrescentada para essa busca:

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
```

Cada condição tem o formato **`(filtro IS NULL OR condição)`**: quando o filtro é `NULL`, a primeira
metade é verdadeira e a condição não importa. `sqlc.narg` é o `sqlc.arg` de um parâmetro que aceita
`NULL`, e os casts `::int` e `::text` dizem ao PostgreSQL o tipo do parâmetro, que ele não consegue deduzir
só do `IS NULL`. O sqlc gera os parâmetros como tipos capazes de dizer "sem valor":

```
ana@vm:~/boxoffice$ sqlc generate
ana@vm:~/boxoffice$ sed -n "/^type SearchEventsParams/,/^}/p;/^func (q \*Queries) SearchEvents/,+1p" internal/db/queries.sql.go
type SearchEventsParams struct {
	MinAvailable pgtype.Int4
	NameLike     pgtype.Text
}
func (q *Queries) SearchEvents(ctx context.Context, arg SearchEventsParams) ([]Event, error) {
	rows, err := q.db.Query(ctx, searchEvents, arg.MinAvailable, arg.NameLike)
ana@vm:~/boxoffice$ go build ./... && echo builds
builds
```

**`pgtype.Int4` e `pgtype.Text`** são os tipos anuláveis do pgx, vistos na seção 08 da aula 6; um campo
deixado no valor zero tem `Valid: false` e é enviado como `NULL`, então uma chamada com um
`SearchEventsParams{}` vazio listaria todos os eventos. O boxoffice ainda não tem rota para esta consulta,
e ela compila e gera sem problemas ao lado das outras.

## O que custa

Funciona, e tem dois custos que vale conhecer. **O SQL fica mais difícil de ler** do que qualquer uma das
quatro consultas simples que ele substitui, e ganha uma cláusula por filtro. E **o PostgreSQL planeja o
comando uma vez para todas as combinações**, então um índice que serviria bem a um filtro deixa de ser
usado quando o plano precisa cobrir o caso em que esse filtro não veio. Para uma tabela de eventos isso
não importa; para uma busca em milhões de linhas, é motivo para escrever as poucas combinações comuns como
consultas separadas, ou para montar esse comando em tempo de execução com um query builder e deixar o sqlc
com o resto.

**Este é o único lugar em que o desenho do sqlc trabalha contra você**, e vale saber disso antes de
escolhê-lo para um serviço cuja principal função é uma tela de busca.
