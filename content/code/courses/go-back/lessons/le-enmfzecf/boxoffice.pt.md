---
title: boxoffice, o serviço que este curso constrói
version: 1
---

Toda aula daqui até a aula 17 acrescenta algo a um programa só: **o boxoffice, o back end de uma
casa de espetáculos pequena que vende ingressos para os seus eventos.** Ele começa em memória e em
texto puro, porque é o que esta aula ensinou, e termina como um binário único num container, lendo
o PostgreSQL, respondendo JSON e gRPC, empurrando contagens de lugares para navegadores e desligando
sem perder uma venda. Cada arquivo aparece inteiro toda vez que muda, então o projeto no seu disco
é sempre o de que a aula está falando.

Ele começa como quatro arquivos em `~/boxoffice`, o diretório que a seção 02 criou. **O store**
guarda os eventos e não sabe nada de HTTP:

```go
// boxoffice/store.go
package main

import (
	"slices"
	"sync"
)

// Event is one show the box office sells tickets for.
type Event struct {
	ID    int
	Name  string
	Seats int
	Sold  int
}

// memStore keeps the events in memory, for as long as the process runs.
type memStore struct {
	mu     sync.RWMutex
	events map[int]Event
}

func newMemStore() *memStore {
	return &memStore{events: map[int]Event{
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

func (s *memStore) Get(id int) (Event, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	e, ok := s.events[id]
	return e, ok
}
```

Dois detalhes estão ali de propósito. O mapa é protegido por um `sync.RWMutex` porque, como a seção
04 mostrou, toda requisição roda na própria goroutine; leituras pegam o lock compartilhado e podem
rodar juntas. E o `List` ordena, porque **um mapa em Go não tem ordem e percorrê-lo duas vezes pode
dar duas ordens**, o que uma API que lista eventos nunca pode fazer.

**Os handlers** transformam requisições em chamadas ao store. Cada um é uma função que recebe o
store e devolve um `http.HandlerFunc`, um closure, para o store chegar ao handler sem variável
global:

```go
// boxoffice/events.go
package main

import (
	"fmt"
	"net/http"
	"strconv"
)

func listEvents(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		for _, e := range store.List() {
			fmt.Fprintf(w, "%d\t%s\t%d of %d seats left\n", e.ID, e.Name, e.Seats-e.Sold, e.Seats)
		}
	}
}

func getEvent(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, err := strconv.Atoi(r.PathValue("id"))
		if err != nil {
			http.Error(w, "event id must be a number", http.StatusBadRequest)
			return
		}
		e, ok := store.Get(id)
		if !ok {
			http.Error(w, "no such event", http.StatusNotFound)
			return
		}
		fmt.Fprintf(w, "%s: %d of %d seats left\n", e.Name, e.Seats-e.Sold, e.Seats)
	}
}
```

O `getEvent` lê o curinga, e **responde 400 quando o id não é número e 404 quando é um número que
ninguém tem**, dois erros diferentes com dois status diferentes. Cada `http.Error` é seguido de
`return`, o costume que a seção 07 pediu.

**As rotas** são uma função que monta o mux, para a API inteira poder ser lida num lugar só:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store *memStore) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	return mux
}
```

**E o `main`** monta o servidor com os quatro prazos da seção 08 e o inicia:

```go
// boxoffice/main.go
package main

import (
	"log"
	"net/http"
	"time"
)

func main() {
	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(newMemStore()),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

## Rodando

```
ana@vm:~/boxoffice$ ls
events.go
go.mod
main.go
routes.go
store.go
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ go run .
2026/10/16 19:12:17 boxoffice listening on localhost:8080
```

O `go vet` não imprimiu nada, que é o jeito dele de não encontrar nada. **Os quatro arquivos são
`package main` num mesmo diretório, então o `go run .` os compila como um programa só**; a ordem dos
arquivos não importa. Do segundo terminal:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events
1	Jazz at the Docks	120 of 120 seats left
2	Chamber Choir	0 of 80 seats left
ana@vm:~/boxoffice$ curl -s localhost:8080/events/2
Chamber Choir: 0 of 80 seats left
ana@vm:~/boxoffice$ curl -si localhost:8080/events/9
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:12:18 GMT
Content-Length: 14

no such event
ana@vm:~/boxoffice$ curl -si localhost:8080/events/nine
HTTP/1.1 400 Bad Request
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:12:18 GMT
Content-Length: 26

event id must be a number
ana@vm:~/boxoffice$ curl -si -X POST localhost:8080/events
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:12:18 GMT
Content-Length: 19

Method Not Allowed
```

Toda resposta é uma que a aula previu: a lista em ordem de id, um evento por id, **404 para um id
que não existe, 400 para algo que não é id**, e 405 com cabeçalho `Allow` para um método que ninguém
registrou. O Chamber Choir já começa esgotado, o que dá à aula 3 uma venda para recusar.

O que ele ainda não sabe fazer está igualmente claro. Ele fala texto separado por tabulação que
nenhum programa deveria ter de interpretar, nada registra quem pediu o quê, e qualquer um pode
chamar qualquer coisa. **A aula 2 envolve estes handlers em middleware, e a aula 3 os faz falar
JSON.**
