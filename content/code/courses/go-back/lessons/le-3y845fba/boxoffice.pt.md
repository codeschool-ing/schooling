---
title: O boxoffice no PostgreSQL
version: 1
---

A seção 06 escreveu o `pgStore`. Esta seção deixa os handlers capazes de usá-lo, o que é uma mudança no
formato deles e não no que fazem, e depois roda o resultado contra a tabela da seção 04.

## Uma interface onde estava o tipo

O arquivo do store mantém o store em memória, agora com um `context.Context` em todo método e um erro
em todo resultado, e ganha a interface que os dois stores satisfazem:

```go
// boxoffice/store.go
package main

import (
	"context"
	"errors"
	"slices"
	"sync"
)

var (
	ErrNotFound  = errors.New("no such event")
	ErrSoldOut   = errors.New("not enough seats left")
	ErrDuplicate = errors.New("an event with that name already exists")
)

// Event is one show the box office sells tickets for.
type Event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

// Store is what the handlers need from wherever the events are kept.
type Store interface {
	List(ctx context.Context) ([]Event, error)
	Get(ctx context.Context, id int) (Event, error)
	Add(ctx context.Context, name string, seats int) (Event, error)
	Sell(ctx context.Context, id, quantity int) (Event, error)
}

// memStore keeps the events in memory, for as long as the process runs.
type memStore struct {
	mu     sync.RWMutex
	events map[int]Event
	nextID int
}

func newMemStore() *memStore {
	return &memStore{nextID: 3, events: map[int]Event{
		1: {ID: 1, Name: "Jazz at the Docks", Seats: 120, Sold: 0},
		2: {ID: 2, Name: "Chamber Choir", Seats: 80, Sold: 80},
	}}
}

func (s *memStore) List(ctx context.Context) ([]Event, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]Event, 0, len(s.events))
	for _, e := range s.events {
		out = append(out, e)
	}
	slices.SortFunc(out, func(a, b Event) int { return a.ID - b.ID })
	return out, nil
}

func (s *memStore) Get(ctx context.Context, id int) (Event, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	e, ok := s.events[id]
	if !ok {
		return Event{}, ErrNotFound
	}
	return e, nil
}

func (s *memStore) Add(ctx context.Context, name string, seats int) (Event, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, e := range s.events {
		if e.Name == name {
			return Event{}, ErrDuplicate
		}
	}
	e := Event{ID: s.nextID, Name: name, Seats: seats}
	s.events[e.ID] = e
	s.nextID++
	return e, nil
}

// Sell takes quantity seats of event id, or none at all.
func (s *memStore) Sell(ctx context.Context, id, quantity int) (Event, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	e, ok := s.events[id]
	if !ok {
		return Event{}, ErrNotFound
	}
	if e.Seats-e.Sold < quantity {
		return e, ErrSoldOut
	}
	e.Sold += quantity
	s.events[id] = e
	return e, nil
}
```

**O `Store` é definido onde é usado, pelo pacote que precisa dele**, com exatamente os quatro métodos que
os handlers chamam. É o hábito da interface pequena que a aula 27 do `go` ensinou, e ele rende duas
vezes: os handlers rodam contra o PostgreSQL ou a memória sem saber qual, e os testes da aula 15 os rodam
contra o `memStore` sem banco nenhum. O `memStore.Add` agora recusa um nome duplicado, para que os dois
stores concordem em toda regra.

O `fail` aprende o erro novo. Um duplicado é um conflito com o que já existe, então divide o 409 com uma
venda que não cabe:

```go
// boxoffice/problem.go
package main

import (
	"errors"
	"log"
	"net/http"
)

// problem is an error response in the shape RFC 9457 describes.
type problem struct {
	Type   string            `json:"type"`
	Title  string            `json:"title"`
	Status int               `json:"status"`
	Detail string            `json:"detail,omitempty"`
	Errors map[string]string `json:"errors,omitempty"`
}

// writeProblem sends an error as application/problem+json.
func writeProblem(w http.ResponseWriter, status int, detail string, fields map[string]string) {
	w.Header().Set("Content-Type", "application/problem+json")
	writeJSON(w, status, problem{
		Type:   "about:blank",
		Title:  http.StatusText(status),
		Status: status,
		Detail: detail,
		Errors: fields,
	})
}

// fail turns an error from the store into the response it deserves.
func fail(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		writeProblem(w, http.StatusNotFound, err.Error(), nil)
	case errors.Is(err, ErrSoldOut), errors.Is(err, ErrDuplicate):
		writeProblem(w, http.StatusConflict, err.Error(), nil)
	default:
		log.Printf("unexpected error: %v", err)
		writeProblem(w, http.StatusInternalServerError, "", nil)
	}
}
```

## Handlers que repassam o contexto da requisição

Todo handler agora chama o store com `r.Context()` e trata um erro de toda chamada, inclusive do `List`,
que não tinha como falhar quando era um mapa:

```go
// boxoffice/events.go
package main

import (
	"net/http"
	"strconv"
	"strings"
)

// eventView is what a client sees of an event.
type eventView struct {
	Event
	Available int `json:"available"`
}

func view(e Event) eventView {
	return eventView{Event: e, Available: e.Seats - e.Sold}
}

func listEvents(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		events, err := store.List(r.Context())
		if err != nil {
			fail(w, err)
			return
		}
		out := make([]eventView, 0, len(events))
		for _, e := range events {
			out = append(out, view(e))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

// pathID reads the {id} wildcard, and answers 400 itself when it is not a number.
func pathID(w http.ResponseWriter, r *http.Request) (int, bool) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeProblem(w, http.StatusBadRequest, "the event id must be a number", nil)
		return 0, false
	}
	return id, true
}

func getEvent(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		e, err := store.Get(r.Context(), id)
		if err != nil {
			fail(w, err)
			return
		}
		writeJSON(w, http.StatusOK, view(e))
	}
}

// purchase is the body of POST /events/{id}/tickets.
type purchase struct {
	Quantity int    `json:"quantity"`
	Email    string `json:"email"`
}

func (p purchase) validate() map[string]string {
	errs := map[string]string{}
	if p.Quantity < 1 || p.Quantity > 10 {
		errs["quantity"] = "must be between 1 and 10"
	}
	if p.Email == "" {
		errs["email"] = "is required"
	} else if !strings.Contains(p.Email, "@") {
		errs["email"] = "must be an e-mail address"
	}
	return errs
}

// receipt is what a successful purchase answers.
type receipt struct {
	EventID   int    `json:"event_id"`
	Quantity  int    `json:"quantity"`
	Email     string `json:"email"`
	Remaining int    `json:"remaining"`
}

func buyTickets(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		var p purchase
		if err := decodeJSON(w, r, &p); err != nil {
			writeProblem(w, http.StatusBadRequest, err.Error(), nil)
			return
		}
		if errs := p.validate(); len(errs) > 0 {
			writeProblem(w, http.StatusUnprocessableEntity, "the purchase is not valid", errs)
			return
		}
		e, err := store.Sell(r.Context(), id, p.Quantity)
		if err != nil {
			fail(w, err)
			return
		}
		writeJSON(w, http.StatusCreated, receipt{
			EventID: id, Quantity: p.Quantity, Email: p.Email, Remaining: e.Seats - e.Sold,
		})
	}
}
```

Os handlers da equipe mudam do mesmo jeito:

```go
// boxoffice/admin.go
package main

import (
	"fmt"
	"net/http"
	"strings"
)

// newEvent is the body of POST /admin/events.
type newEvent struct {
	Name  string `json:"name"`
	Seats int    `json:"seats"`
}

func (n newEvent) validate() map[string]string {
	errs := map[string]string{}
	if strings.TrimSpace(n.Name) == "" {
		errs["name"] = "is required"
	} else if len(n.Name) > 100 {
		errs["name"] = "must be at most 100 bytes"
	}
	if n.Seats < 1 || n.Seats > 10000 {
		errs["seats"] = "must be between 1 and 10000"
	}
	return errs
}

// requireManager answers 403 itself unless the caller is a manager.
func requireManager(w http.ResponseWriter, r *http.Request) bool {
	if staffRole(r.Context()) != "manager" {
		writeProblem(w, http.StatusForbidden, "only a manager may do this", nil)
		return false
	}
	return true
}

func createEvent(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireManager(w, r) {
			return
		}
		var n newEvent
		if err := decodeJSON(w, r, &n); err != nil {
			writeProblem(w, http.StatusBadRequest, err.Error(), nil)
			return
		}
		if errs := n.validate(); len(errs) > 0 {
			writeProblem(w, http.StatusUnprocessableEntity, "the event is not valid", errs)
			return
		}
		e, err := store.Add(r.Context(), n.Name, n.Seats)
		if err != nil {
			fail(w, err)
			return
		}
		w.Header().Set("Location", fmt.Sprintf("/events/%d", e.ID))
		writeJSON(w, http.StatusCreated, view(e))
	}
}

func salesReport(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireManager(w, r) {
			return
		}
		events, err := store.List(r.Context())
		if err != nil {
			fail(w, err)
			return
		}
		writeJSON(w, http.StatusOK, events)
	}
}
```

O `routes` recebe um `Store` em vez de um `*memStore`, e nada mais muda nele:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store Store, tokens map[string]string) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	mux.HandleFunc("POST /events/{id}/tickets", buyTickets(store))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	admin.HandleFunc("POST /admin/events", createEvent(store))
	mux.Handle("/admin/", requireStaff(tokens)(admin))

	return chain(mux, logRequests, recoverPanics, cors("https://tickets.example.com"))
}
```

## O `main` abre o pool

```go
// boxoffice/main.go
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	tokens := map[string]string{}
	for role, name := range map[string]string{
		"manager": "BOXOFFICE_MANAGER_TOKEN",
		"door":    "BOXOFFICE_DOOR_TOKEN",
	} {
		if t := os.Getenv(name); t != "" {
			tokens[t] = role
		}
	}
	if len(tokens) == 0 {
		log.Fatal("no staff tokens: set BOXOFFICE_MANAGER_TOKEN")
	}

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("no database: set DATABASE_URL")
	}
	pool, err := pgxpool.New(context.Background(), url)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(context.Background()); err != nil {
		log.Fatalf("database: %v", err)
	}

	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(&pgStore{pool: pool}, tokens),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

O `main` se recusa a subir sem um `DATABASE_URL`, como faz sem um token. O `pgxpool.New` monta o pool
sem conectar, como o `sql.Open`; **o `Ping` faz uma conexão de verdade**, para que um endereço errado ou
um servidor parado barrem o programa no início, com as mensagens da seção 03, e não na primeira
requisição. O `defer pool.Close()` devolve as conexões quando o `main` termina normalmente; o `log.Fatal`
sai sem rodar as chamadas adiadas, e o sistema operacional fecha os sockets de qualquer forma. A aula 17
deixa esse fim ordenado.

## Rodando

```
ana@vm:~/boxoffice$ go mod tidy
go: finding module for package github.com/jackc/pgx/v5/pgxpool
go: finding module for package github.com/jackc/pgx/v5/pgconn
go: finding module for package github.com/jackc/pgx/v5
go: found github.com/jackc/pgx/v5 in github.com/jackc/pgx/v5 v5.11.0
go: found github.com/jackc/pgx/v5/pgconn in github.com/jackc/pgx/v5 v5.11.0
go: found github.com/jackc/pgx/v5/pgxpool in github.com/jackc/pgx/v5 v5.11.0
ana@vm:~/boxoffice$ go vet ./...
```

Com os tokens e o `DATABASE_URL` exportados, `go run .` num terminal, e no outro:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120},{"id":2,"name":"Chamber Choir","seats":80,"sold":80,"available":0}]
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"quantity":2,"email":"ana@example.com","remaining":118}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/2/tickets
{"type":"about:blank","title":"Conflict","status":409,"detail":"event 2: not enough seats left"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/9/tickets
{"type":"about:blank","title":"Not Found","status":404,"detail":"event 9: no such event"}
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json '{"name": "Chamber Choir", "seats": 10}' localhost:8080/admin/events
{"type":"about:blank","title":"Conflict","status":409,"detail":"\"Chamber Choir\": an event with that name already exists"}
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json '{"name": "Organ Recital", "seats": 60}' localhost:8080/admin/events
{"id":5,"name":"Organ Recital","seats":60,"sold":0,"available":60}
```

Toda resposta é a da aula 3, só que cada uma agora vem do PostgreSQL. **As duas recusas trazem o id no
detail**, `event 2: not enough seats left`, porque o `pgStore` embrulha os erros com contexto e o `fail`
usa a mensagem embrulhada. E o nome duplicado é um 409 que vem da restrição `UNIQUE` da tabela, pelo
SQLSTATE `23505`, pelo `ErrDuplicate`.

**O Organ Recital é o evento 5, não o 3.** Nada foi apagado: a coluna de identidade pega o próximo número
de uma sequência antes de a linha ser inserida, e uma inserção que falha não devolve o número. O programa
da seção 08 gastou o 3 no duplicado que falhou, e o 409 acima gastou o 4. **Números de identidade são
únicos e crescentes, nunca sem buracos**, e uma API não deve prometer o contrário.

```
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 19:56:32 boxoffice listening on localhost:8080
2026/10/16 19:56:33 GET /events 200 142B 4.03ms
2026/10/16 19:56:33 POST /events/1/tickets 201 70B 2.974ms
2026/10/16 19:56:33 POST /events/2/tickets 409 97B 839µs
2026/10/16 19:56:33 POST /events/9/tickets 404 90B 444µs
2026/10/16 19:56:33 POST /admin/events 409 124B 781µs
2026/10/16 19:56:33 POST /admin/events 201 67B 2.753ms
```

**Milissegundos onde a aula 2 registrava microssegundos.** A primeira requisição, com 4.03 ms, também
abriu a primeira conexão do pool; as outras a reaproveitaram. Uma ida e volta ao PostgreSQL na mesma
máquina leva algumas centenas de microssegundos, e a venda e a criação do evento, que gravam em disco,
custam mais.

## E depois de reiniciar

Pare o servidor com Ctrl+C e inicie de novo. Desta vez os dados continuam lá:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118},{"id":2,"name":"Chamber Choir","seats":80,"sold":80,"available":0},{"id":5,"name":"Organ Recital","seats":60,"sold":0,"available":60}]
ana@vm:~/boxoffice$ psql boxoffice -c "SELECT * FROM events ORDER BY id"
 id |       name        | seats | sold 
----+-------------------+-------+------
  1 | Jazz at the Docks |   120 |    2
  2 | Chamber Choir     |    80 |   80
  5 | Organ Recital     |    60 |    0
(3 rows)
```

**Pela primeira vez, o boxoffice se lembra.** Os dois ingressos vendidos, o coral esgotado e o recital
novo sobreviveram ao reinício, porque moram no banco e não no processo. O que ainda falta ao boxoffice é
um jeito de mudar essa tabela com segurança quando ela já guarda vendas de verdade, e um registro de
quem comprou o quê; as aulas 7 a 9 olham três jeitos de escrever essa camada de dados, e depois dão a
ela migrações e transações.
