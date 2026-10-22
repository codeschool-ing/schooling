---
title: O pool, e o tamanho que ele deve ter
version: 1
---

A aula 6 seção 05 disse que um `sql.DB` é um pool, e o `pgxpool.Pool` é a mesma ideia: um conjunto de
conexões abertas, emprestadas a quem pede e devolvidas quando terminam. **Uma conexão é cara dos dois
lados**: o PostgreSQL inicia um processo para cada uma, e abrir uma custa uma ida e volta e uma
autenticação. O pool existe para que um servidor ocupado abra algumas e as reutilize. O tamanho dele
decide duas coisas, quantas consultas rodam ao mesmo tempo e o que acontece com as outras.

## Um pool de duas, seis consultas

Este programa dá ao pool duas conexões e inicia seis consultas que levam um segundo cada, com um limite
de 2,5 segundos para cada uma:

```go
// poolwait/main.go
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	ctx := context.Background()
	cfg, err := pgxpool.ParseConfig(os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}
	cfg.MaxConns = 2
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	start := time.Now()
	var wg sync.WaitGroup
	for i := 1; i <= 6; i++ {
		wg.Go(func() {
			qctx, cancel := context.WithTimeout(ctx, 2500*time.Millisecond)
			defer cancel()
			_, err := pool.Exec(qctx, "SELECT pg_sleep(1)")
			fmt.Printf("query %d finished at %.1fs: %v\n", i, time.Since(start).Seconds(), err)
		})
	}
	wg.Wait()

	s := pool.Stat()
	fmt.Printf("max %d, acquired %d times, %d waited for a connection, %d gave up waiting\n",
		s.MaxConns(), s.AcquireCount(), s.EmptyAcquireCount(), s.CanceledAcquireCount())
}
```

```
ana@vm:~/poolwait$ psql boxoffice -c "SHOW max_connections"
 max_connections 
-----------------
 100
(1 row)

ana@vm:~/poolwait$ go run .
query 6 finished at 1.0s: <nil>
query 3 finished at 1.0s: <nil>
query 1 finished at 2.0s: <nil>
query 2 finished at 2.0s: <nil>
query 5 finished at 2.5s: timeout: context deadline exceeded
query 4 finished at 2.5s: timeout: context deadline exceeded
max 2, acquired 6 times, 6 waited for a connection, 0 gave up waiting
```

**Duas por vez, em ondas.** As duas primeiras terminaram em 1,0 s, as duas seguintes em 2,0 s, e as duas
últimas pegaram a conexão em 2,0 s com meio segundo restante dos seus 2,5, então as consultas foram
canceladas no meio, `timeout: context deadline exceeded`. **Uma consulta esperando conexão gasta o
próprio prazo esperando**, e nada no banco estava lento: era o pool. O `Stat` conta isso, seis
aquisições e todas as seis esperaram, que é como um pool pequeno demais para a carga parece visto de
dentro.

## De que tamanho

O `max_connections` é 100 neste servidor, o padrão do Ubuntu, e todo processo que se conecta ao banco
divide esse número. **A soma do máximo de todos os pools tem de ficar abaixo dele**, com espaço para o
`psql` e para as migrações: três cópias do boxoffice com `MaxConns` 10 usam 30. O máximo padrão do
pgxpool é quatro, ou o número de processadores se for maior; o boxoffice define 10 no `main`, seção 04,
e deixa conexões ociosas por cinco minutos antes de fechá-las. Maior não é melhor a partir de certo
ponto: o PostgreSQL faz trabalho de verdade por conexão, e **poucas conexões ocupadas costumam atender
mais consultas que muitas ociosas**.

## A linha que parou o pool

A seção 06 deixou um programa que manda vinte compradores ao mesmo tempo. Aqui está ele contra um evento
com cinco lugares, com o `pgStore` da seção 05:

```
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json '{"name": "Organ Recital", "seats": 5}' localhost:8080/admin/events
{"id":3,"name":"Organ Recital","seats":5,"sold":0,"available":5}
ana@vm:~/rush$ go run . 3
201: 5  409: 0  no answer in 5s: 15
ana@vm:~/rush$ curl -s -m 3 localhost:8080/events; echo "exit $?"
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118},{"id":2,"name":"Chamber Choir","seats":80,"sold":80,"available":0},{"id":3,"name":"Organ Recital","seats":5,"sold":5,"available":0}]
exit 0
ana@vm:~/rush$ psql boxoffice -c "SELECT count(*) FROM pg_stat_activity WHERE datname = 'boxoffice' AND state = 'idle in transaction'"
 count 
-------
     0
(1 row)

ana@vm:~/boxoffice$ tail -3 .server.log
2026/10/16 20:18:58 unexpected error: selling: context canceled
2026/10/16 20:18:58 POST /events/3/tickets 500 68B 5.000906s
2026/10/16 20:18:58 GET /events 200 207B 1.893ms
```

**Cinco vendas, e depois quinze requisições sem resposta nenhuma por cinco segundos.** Elas não tinham
falhado; estavam presas. O log mostra como terminaram: quando o `rush` desistiu, os clientes
desconectaram, o `net/http` cancelou o contexto de cada requisição, e as chamadas que esperavam
devolveram `context canceled` depois de 5.000906 s, como 500. Só então o `curl` recebeu a lista, e a
essa altura nenhuma transação estava mais aberta.

A causa é uma linha do `Sell`, para um comprador que chega quando os lugares acabaram:

```go
if _, err := s.Get(ctx, id); err != nil {
```

Nesse momento a requisição **segura uma conexão, a da transação, e pede ao pool uma segunda** para o
`Get`. Dez requisições ao mesmo tempo, `MaxConns` de 10, cada uma segurando uma e esperando outra: o
pool está vazio, ninguém devolve conexão, e ninguém avança. **Um deadlock dentro do pool**, com cada
parte dele correta por si só. Sem o limite de cinco segundos do cliente, nada o teria encerrado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 255\" role=\"img\" aria-label=\"Um pool desenhado como dez vagas, todas ocupadas pela transação de uma venda. Abaixo, as mesmas dez vendas pedem ao pool uma segunda conexão, e as setas terminam no pool sem nada livre. Mais dez requisições esperam na fila atrás delas.\"><defs><marker id=\"gb-l9-poolwait-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"670\" height=\"70\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"25\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o pool, MaxConns 10: todas ocupadas</text><rect x=\"25\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"54\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 1</text><rect x=\"90\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"119\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 2</text><rect x=\"155\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"184\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 3</text><rect x=\"220\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"249\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 4</text><rect x=\"285\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"314\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 5</text><rect x=\"350\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"379\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 6</text><rect x=\"415\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 7</text><rect x=\"480\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"509\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 8</text><rect x=\"545\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"574\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 9</text><rect x=\"610\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"639\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 10</text><rect x=\"25\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 1</text><path d=\"M 54 130 L 54 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"90\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"119\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 2</text><path d=\"M 119 130 L 119 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"155\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"184\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 3</text><path d=\"M 184 130 L 184 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"220\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"249\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 4</text><path d=\"M 249 130 L 249 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"285\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"314\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 5</text><path d=\"M 314 130 L 314 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"350\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"379\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 6</text><path d=\"M 379 130 L 379 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"415\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"444\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 7</text><path d=\"M 444 130 L 444 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"480\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"509\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 8</text><path d=\"M 509 130 L 509 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"545\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"574\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 9</text><path d=\"M 574 130 L 574 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"610\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"639\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 10</text><path d=\"M 639 130 L 639 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><text x=\"350\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada venda pede uma segunda conexão, e espera</text><rect x=\"15\" y=\"205\" width=\"670\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"350\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais dez compradores, esperando a primeira conexão</text></svg>", "caption": "MaxConns é 10. Cada comprador que chega depois do esgotamento segura uma conexão e espera outra, então nenhuma volta ao pool."}
```

A correção é perguntar pela conexão que já está em mãos, a da transação:

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

// Sell takes quantity seats and records the ticket, both or neither.
func (s *pgStore) Sell(ctx context.Context, id, quantity int, email string) (Sale, error) {
	id32, err := eventID(id)
	if err != nil {
		return Sale{}, err
	}
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Sale{}, fmt.Errorf("selling: %w", err)
	}
	defer tx.Rollback(ctx)
	q := s.q().WithTx(tx)

	e, err := q.SellSeats(ctx, db.SellSeatsParams{ID: id32, Quantity: int32(quantity)})
	if errors.Is(err, pgx.ErrNoRows) {
		// Ask through the transaction's own connection: s.Get would wait for a
		// second one while this one is held.
		if _, err := q.GetEvent(ctx, id32); errors.Is(err, pgx.ErrNoRows) {
			return Sale{}, fmt.Errorf("event %d: %w", id, ErrNotFound)
		}
		return Sale{}, fmt.Errorf("event %d: %w", id, ErrSoldOut)
	}
	if err != nil {
		return Sale{}, fmt.Errorf("selling: %w", err)
	}
	ticket, err := q.InsertTicket(ctx, db.InsertTicketParams{
		EventID: id32, Email: email, Quantity: int32(quantity),
	})
	if err != nil {
		return Sale{}, fmt.Errorf("recording the ticket: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return Sale{}, fmt.Errorf("committing the sale: %w", err)
	}
	return Sale{TicketID: int(ticket), Event: fromRow(e)}, nil
}
```

```
ana@vm:~/rush$ go run . 3
201: 5  409: 15  no answer in 5s: 0
ana@vm:~/rush$ psql boxoffice -c "SELECT count(*), sum(quantity) FROM tickets WHERE event_id = 3" -c "SELECT sold, seats FROM events WHERE id = 3"
 count | sum 
-------+-----
     5 |   5
(1 row)

 sold | seats 
------+-------
    5 |     5
(1 row)

ana@vm:~/rush$ curl -s -m 3 localhost:8080/events/3
{"id":3,"name":"Organ Recital","seats":5,"sold":5,"available":0}
ana@vm:~/boxoffice$ grep -c "tickets 201" .server.log; grep -c "tickets 409" .server.log
5
15
```

**Cinco ingressos, quinze 409 honestos, e a tabela concorda: cinco vendidos de cinco.** A regra que fica
disso é curta. **Dentro de uma transação, toda consulta passa pela transação**, e de modo mais geral,
código que segura um recurso de um pool nunca pode esperar outro do mesmo pool.
