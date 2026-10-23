---
title: O caminho do meio: bibliotecas, não um framework
version: 1
---

Entre escrever tudo e adotar um framework há um terceiro caminho, e é o que este curso recomenda
para as necessidades que a seção 02 deixou abertas. **Uma biblioteca faz uma coisa e deixa a forma
do seu programa em paz; um framework decide a forma e deixa você preenchê-la.** O teste é a
assinatura do handler: se ela continua `func(w http.ResponseWriter, r *http.Request)`, todo o resto
deste curso continua funcionando.

## Um roteador que continua roteador

O `chi` é o exemplo mais claro. Ele é um roteador e um conjunto de middlewares, mais nada, e as rotas
dele recebem `http.HandlerFunc` comuns. Eis a API de referência da aula 4 com o `chi` no lugar do
`ServeMux`:

```go
// fw/chi/main.go
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

type event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

type purchase struct {
	Quantity int    `json:"quantity"`
	Email    string `json:"email"`
}

var (
	mu     sync.Mutex
	events = map[int]*event{1: {ID: 1, Name: "Jazz at the Docks", Seats: 120}}
)

func send(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func fail(w http.ResponseWriter, status int, msg string) {
	send(w, status, map[string]string{"error": msg})
}

func main() {
	router := chi.NewRouter()
	router.Use(middleware.Logger)
	router.Get("/events/{id}", func(w http.ResponseWriter, r *http.Request) {
		id, err := strconv.Atoi(chi.URLParam(r, "id"))
		if err != nil {
			fail(w, http.StatusBadRequest, "the event id must be a number")
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			fail(w, http.StatusNotFound, "no such event")
			return
		}
		send(w, http.StatusOK, e)
	})
	router.Post("/events/{id}/tickets", func(w http.ResponseWriter, r *http.Request) {
		id, _ := strconv.Atoi(chi.URLParam(r, "id"))
		var p purchase
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			fail(w, http.StatusBadRequest, err.Error())
			return
		}
		if p.Quantity < 1 || p.Quantity > 10 {
			fail(w, http.StatusUnprocessableEntity, "quantity must be between 1 and 10")
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			fail(w, http.StatusNotFound, "no such event")
			return
		}
		if e.Seats-e.Sold < p.Quantity {
			fail(w, http.StatusConflict, "not enough seats left")
			return
		}
		e.Sold += p.Quantity
		send(w, http.StatusCreated, map[string]int{"event_id": id, "remaining": e.Seats - e.Sold})
	})
	log.Fatal(http.ListenAndServe("localhost:8080", router))
}
```

Só as linhas de roteamento mudaram: `chi.NewRouter()`, `router.Get` e `router.Post`, e
`chi.URLParam(r, "id")` onde a biblioteca padrão diz `r.PathValue("id")`. Os handlers são os da
biblioteca padrão, palavra por palavra, e os helpers também.

```
ana@vm:~/fw/chi$ go mod tidy
go: finding module for package github.com/go-chi/chi/v5
go: finding module for package github.com/go-chi/chi/v5/middleware
go: downloading github.com/go-chi/chi/v5 v5.5.0
go: downloading github.com/go-chi/chi v1.5.5
go: found github.com/go-chi/chi/v5 in github.com/go-chi/chi/v5 v5.5.0
go: found github.com/go-chi/chi/v5/middleware in github.com/go-chi/chi/v5 v5.5.0
ana@vm:~/fw/chi$ go build -o server . && ls -l server && go list -m all
-rwxr-xr-x 1 ana ana 11216898 Oct 16 19:48 server
example.com/fw/chi
github.com/go-chi/chi/v5 v5.5.0
ana@vm:~/fw/chi$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}
ana@vm:~/fw/chi$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"error":"quantity must be between 1 and 10"}
ana@vm:~/fw/chi$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 405 Method Not Allowed
Allow: GET
Date: Fri, 16 Oct 2026 22:48:53 GMT
Content-Length: 0

ana@vm:~/fw/chi$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:48:53 GMT
Content-Length: 19

404 page not found
ana@vm:~/fw/chi$ cat .server.log
2026/10/16 19:48:53 "GET http://localhost:8080/events/1 HTTP/1.1" from 127.0.0.1:54580 - 200 57B in 106.817µs
2026/10/16 19:48:53 "POST http://localhost:8080/events/1/tickets HTTP/1.1" from 127.0.0.1:54594 - 422 46B in 145.349µs
2026/10/16 19:48:53 "DELETE http://localhost:8080/events/1 HTTP/1.1" from 127.0.0.1:54604 - 405 0B in 5.274µs
2026/10/16 19:48:53 "GET http://localhost:8080/nothing HTTP/1.1" from 127.0.0.1:54608 - 404 19B in 11.089µs
```

**Um módulo além do seu**, o próprio `chi`, e um binário de 11,2 MB contra os 9,8 da biblioteca
padrão. As respostas batem com as da versão padrão, salvo dois detalhes: o 405 do chi lista só `GET`,
não o `HEAD` que o `ServeMux` acrescenta, e não manda corpo. A linha de log veio do
`middleware.Logger`, um dos middlewares que o `chi` traz, que tem o formato padrão e envolveria um
`ServeMux` do mesmo jeito.

## Quando o roteador vale a pena

Com os padrões do Go 1.22, um roteador como o `chi` paga o seu módulo quando você precisa do que o
`ServeMux` ainda não faz: padrões com expressões regulares, como `{id:[0-9]+}`, ou grupos de rotas
montados com os próprios middlewares em poucas linhas. **Se nada disso é necessário, o roteador é o
`ServeMux`**, e o boxoffice fica com ele.

## A mesma ideia para todo o resto

O mesmo raciocínio vale para cada lacuna da lista da seção 02. Validação: o `go-playground/validator`
sozinho, chamado de um handler, ou métodos, como faz o boxoffice. Limite de taxa: o
`golang.org/x/time/rate`, um pacote pequeno do time do Go, dentro de um middleware no formato padrão.
Ids de requisição, compressão, timeouts: middlewares no formato padrão, de uma biblioteca ou escritos
em trinta linhas. **Cada peça é substituível sozinha, e nenhuma delas é dona dos seus handlers.**
