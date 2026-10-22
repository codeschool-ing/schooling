---
title: O store do boxoffice, gerado
version: 1
---

O `pgStore` mantém o trabalho de satisfazer o `Store` da aula 6, e deixa de escrever SQL. Cada método agora
chama uma função gerada e converte o resultado, então o `pgstore.go` é reescrito. **Os handlers, as rotas
e o `main` não mudam nada**, porque eles só enxergavam a interface:

```go
// boxoffice/pgstore.go
package main

import (
	"context"
	"errors"
	"fmt"

	"example.com/boxoffice/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// pgStore keeps the events in PostgreSQL, through the code sqlc generated.
type pgStore struct {
	pool *pgxpool.Pool
}

func (s *pgStore) q() *db.Queries {
	return db.New(s.pool)
}

func fromRow(e db.Event) Event {
	return Event{ID: int(e.ID), Name: e.Name, Seats: int(e.Seats), Sold: int(e.Sold)}
}

func (s *pgStore) List(ctx context.Context) ([]Event, error) {
	rows, err := s.q().ListEvents(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing events: %w", err)
	}
	events := make([]Event, 0, len(rows))
	for _, r := range rows {
		events = append(events, fromRow(r))
	}
	return events, nil
}

func (s *pgStore) Get(ctx context.Context, id int) (Event, error) {
	e, err := s.q().GetEvent(ctx, int32(id))
	if errors.Is(err, pgx.ErrNoRows) {
		return Event{}, fmt.Errorf("event %d: %w", id, ErrNotFound)
	}
	return fromRow(e), err
}

func (s *pgStore) Add(ctx context.Context, name string, seats int) (Event, error) {
	e, err := s.q().AddEvent(ctx, db.AddEventParams{Name: name, Seats: int32(seats)})
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return Event{}, fmt.Errorf("%q: %w", name, ErrDuplicate)
	}
	return fromRow(e), err
}

// Sell takes quantity seats in one statement, so two buyers cannot both get the last one.
func (s *pgStore) Sell(ctx context.Context, id, quantity int) (Event, error) {
	e, err := s.q().SellSeats(ctx, db.SellSeatsParams{ID: int32(id), Quantity: int32(quantity)})
	if errors.Is(err, pgx.ErrNoRows) {
		if _, err := s.Get(ctx, id); err != nil {
			return Event{}, err
		}
		return Event{}, fmt.Errorf("event %d: %w", id, ErrSoldOut)
	}
	return fromRow(e), err
}
```

O `q()` envolve o pool no `Queries` gerado toda vez que é chamado, o que não custa mais que uma struct
pequena: o pool é a coisa cara, e é compartilhado. O `fromRow` converte o `Event` gerado no do boxoffice,
campo a campo. O tratamento de erros é o da aula 6, palavra por palavra.

`go mod tidy` e `go vet` ficam calados, e o servidor responde como na aula 6:

```
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ curl -s localhost:8080/events
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120},{"id":2,"name":"Chamber Choir","seats":80,"sold":80,"available":0}]
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"quantity":2,"email":"ana@example.com","remaining":118}
ana@vm:~/boxoffice$ curl -s localhost:8080/events/9
{"type":"about:blank","title":"Not Found","status":404,"detail":"event 9: no such event"}
```

## Um bug que nenhum teste acima encontraria

Há mais uma requisição que vale mandar. O id de um evento é um número no caminho, e a aula 1 o lê com
`strconv.Atoi`, que aceita qualquer coisa que caiba num `int` do Go, 64 bits aqui. **A coluna é `integer`,
32 bits, e a conversão `int32(id)` não confere nada**:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events/4294967297
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118}
```

**O evento 4294967297 não existe, e o boxoffice respondeu com o evento 1.** 4.294.967.297 é 2³² + 1, e
convertê-lo para `int32` guarda os 32 bits de baixo, que são o número 1. O Go define essa volta como o
resultado da conversão, então nada entra em pânico e nada vai para o log; a consulta pediu ao PostgreSQL,
muito corretamente, o evento 1.

O store escrito à mão da aula 6 não tinha esse bug: ele passava o `int` ao pgx, que confere se um valor
cabe no tipo da coluna e recusa o que não cabe, então a mesma requisição terminava num 500. Essa também não
era a resposta certa, mas não era o evento de outra pessoa. **O código gerado é tipado com mais precisão, e
a precisão levou a verificação para a linha em que você converte**, que é a linha que você escreve. O
conserto é uma função que recusa o que não cabe, e o store a usa onde quer que um id entre:

```go
// boxoffice/pgstore.go
package main

import (
	"context"
	"errors"
	"fmt"
	"math"

	"example.com/boxoffice/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// pgStore keeps the events in PostgreSQL, through the code sqlc generated.
type pgStore struct {
	pool *pgxpool.Pool
}

func (s *pgStore) q() *db.Queries {
	return db.New(s.pool)
}

func fromRow(e db.Event) Event {
	return Event{ID: int(e.ID), Name: e.Name, Seats: int(e.Seats), Sold: int(e.Sold)}
}

// eventID converts an id for the int4 column, refusing what does not fit.
func eventID(id int) (int32, error) {
	if id < 1 || id > math.MaxInt32 {
		return 0, fmt.Errorf("event %d: %w", id, ErrNotFound)
	}
	return int32(id), nil
}

func (s *pgStore) List(ctx context.Context) ([]Event, error) {
	rows, err := s.q().ListEvents(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing events: %w", err)
	}
	events := make([]Event, 0, len(rows))
	for _, r := range rows {
		events = append(events, fromRow(r))
	}
	return events, nil
}

func (s *pgStore) Get(ctx context.Context, id int) (Event, error) {
	id32, err := eventID(id)
	if err != nil {
		return Event{}, err
	}
	e, err := s.q().GetEvent(ctx, id32)
	if errors.Is(err, pgx.ErrNoRows) {
		return Event{}, fmt.Errorf("event %d: %w", id, ErrNotFound)
	}
	return fromRow(e), err
}

func (s *pgStore) Add(ctx context.Context, name string, seats int) (Event, error) {
	e, err := s.q().AddEvent(ctx, db.AddEventParams{Name: name, Seats: int32(seats)})
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return Event{}, fmt.Errorf("%q: %w", name, ErrDuplicate)
	}
	return fromRow(e), err
}

// Sell takes quantity seats in one statement, so two buyers cannot both get the last one.
func (s *pgStore) Sell(ctx context.Context, id, quantity int) (Event, error) {
	id32, err := eventID(id)
	if err != nil {
		return Event{}, err
	}
	e, err := s.q().SellSeats(ctx, db.SellSeatsParams{ID: id32, Quantity: int32(quantity)})
	if errors.Is(err, pgx.ErrNoRows) {
		if _, err := s.Get(ctx, id); err != nil {
			return Event{}, err
		}
		return Event{}, fmt.Errorf("event %d: %w", id, ErrSoldOut)
	}
	return fromRow(e), err
}
```

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events/4294967297
{"type":"about:blank","title":"Not Found","status":404,"detail":"event 4294967297: no such event"}
ana@vm:~/boxoffice$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118}
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 20:08:19 boxoffice listening on localhost:8080
2026/10/16 20:08:19 GET /events/4294967297 404 99B 1.013ms
2026/10/16 20:08:19 GET /events/1 200 73B 1.691ms
```

Um id fora da faixa da coluna agora é um evento que não existe, que é o que ele é. **Sempre que os tipos
gerados forem mais estreitos que os seus, é na conversão que se deve olhar**; o mesmo vale para `Seats` e
`quantity`, que a validação já mantém dentro de 10.000 e 10.
