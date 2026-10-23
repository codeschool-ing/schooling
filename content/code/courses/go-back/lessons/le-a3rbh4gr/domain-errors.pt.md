---
title: Erros do store, e o status que cada um merece
version: 1
---

O store é onde moram as regras do boxoffice: um evento existe ou não existe, e uma venda cabe nos
lugares que sobram ou não acontece. **Essas recusas não são erros HTTP, e o store não deve falar
HTTP.** Ele será apoiado no PostgreSQL na aula 6 e chamado pelo gRPC na aula 10, e nenhum dos dois
tem 404. Então o store diz o que deu errado com as próprias palavras, como erros, e uma função na
borda traduz.

```go
// boxoffice/store.go
package main

import (
	"errors"
	"slices"
	"sync"
)

var (
	ErrNotFound = errors.New("no such event")
	ErrSoldOut  = errors.New("not enough seats left")
)

// Event is one show the box office sells tickets for.
type Event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
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

func (s *memStore) List() []Event {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]Event, 0, len(s.events))
	for _, e := range s.events {
		out = append(out, e)
	}
	slices.SortFunc(out, func(a, b Event) int { return a.ID - b.ID })
	return out
}

func (s *memStore) Get(id int) (Event, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	e, ok := s.events[id]
	if !ok {
		return Event{}, ErrNotFound
	}
	return e, nil
}

func (s *memStore) Add(name string, seats int) Event {
	s.mu.Lock()
	defer s.mu.Unlock()
	e := Event{ID: s.nextID, Name: name, Seats: seats}
	s.events[e.ID] = e
	s.nextID++
	return e
}

// Sell takes quantity seats of event id, or none at all.
func (s *memStore) Sell(id, quantity int) (Event, error) {
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

Os dois erros no topo são **erros sentinela**, valores declarados uma vez e comparados pela
identidade, o padrão que a aula 35 do `go` apresentou. O `Get` agora devolve `ErrNotFound` em vez do
booleano da aula 1, e o `Sell` devolve `ErrSoldOut` quando sobram menos lugares do que foram pedidos.

O `Sell` faz a verificação e a mudança **sob um lock só, da leitura à escrita**. Se ele lesse o
evento, soltasse o lock e depois escrevesse, dois compradores do último lugar poderiam ler "sobra
um", passar os dois pela verificação e os dois levarem o lugar. Segurar o lock de escrita pela
função inteira torna a venda tudo ou nada. A aula 9 encontra a mesma corrida no PostgreSQL, onde um
mutex num processo não basta mais.

## Um lugar que traduz

O `fail`, no `problem.go` da seção 05, é a tradução:

```go
func fail(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		writeProblem(w, http.StatusNotFound, err.Error(), nil)
	case errors.Is(err, ErrSoldOut):
		writeProblem(w, http.StatusConflict, err.Error(), nil)
	default:
		log.Printf("unexpected error: %v", err)
		writeProblem(w, http.StatusInternalServerError, "", nil)
	}
}
```

**`errors.Is` e não `==`**, porque da aula 6 em diante o store vai embrulhar os erros com contexto,
`fmt.Errorf("event %d: %w", id, ErrNotFound)`, e o `errors.Is` enxerga através do embrulho onde o
`==` não enxergaria; isso é a aula 34 do `go`. **409 Conflict para uma venda que não cabe**: a
requisição estava bem formada e válida, e conflita com o estado atual do evento. A mesma requisição
poderia dar certo amanhã se um reembolso liberasse lugares, que é a diferença para um 422. E o caso
`default` é o que pega todo erro que ninguém planejou: registrado inteiro no log, respondido com um
500 sem nada.

```
ana@vm:~/boxoffice$ curl -si --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
HTTP/1.1 201 Created
Content-Type: application/json
Vary: Origin
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 70

{"event_id":1,"quantity":2,"email":"ana@example.com","remaining":118}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/2/tickets
{"type":"about:blank","title":"Conflict","status":409,"detail":"not enough seats left"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/9/tickets
{"type":"about:blank","title":"Not Found","status":404,"detail":"no such event"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/nine/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the event id must be a number"}
ana@vm:~/boxoffice$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118}
```

A primeira compra passou, **201 Created com um recibo**, e o evento agora mostra 2 vendidos e 118
disponíveis. O Chamber Choir recusou com 409, um evento que não existe com 404, e um id que não é
número com 400 antes de o store ser consultado. Quatro desfechos da mesma rota, cada um com o
próprio status, e todo handler que chama o store daqui em diante os recebe chamando o `fail`.
