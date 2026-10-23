---
title: O boxoffice fala JSON
version: 1
---

As seções 02 a 06 acrescentaram quatro arquivos, `json.go`, `decode.go`, `problem.go` e o novo
`store.go` e `events.go`. Esta seção muda o resto para combinar, acrescenta a única rota que faltava
à equipe e roda tudo. **As rotas da equipe também passam a falar JSON**, e ganham um jeito de criar
um evento:

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

func createEvent(store *memStore) http.HandlerFunc {
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
		e := store.Add(n.Name, n.Seats)
		w.Header().Set("Location", fmt.Sprintf("/events/%d", e.ID))
		writeJSON(w, http.StatusCreated, view(e))
	}
}

func salesReport(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireManager(w, r) {
			return
		}
		writeJSON(w, http.StatusOK, store.List())
	}
}
```

O `requireManager` é a verificação de papel da aula 2 tirada para um helper, porque agora dois
handlers precisam dela. O `createEvent` segue os mesmos quatro passos do `buyTickets`, e responde
**201 Created com um cabeçalho `Location`** dizendo onde o evento novo pode ser lido, que é o que um
201 promete a um cliente.

Os dois middlewares que escreviam texto na aula 2 agora escrevem problemas. No `requireStaff` só a
recusa mudou:

```go
// boxoffice/auth.go
package main

import (
	"context"
	"crypto/subtle"
	"net/http"
	"strings"
)

type roleKey struct{}

// requireStaff lets a request through only if it carries one of the tokens,
// and puts the role that token belongs to into the request's context.
func requireStaff(tokens map[string]string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			role := ""
			if got, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer "); ok {
				for token, owner := range tokens {
					if subtle.ConstantTimeCompare([]byte(got), []byte(token)) == 1 {
						role = owner
					}
				}
			}
			if role == "" {
				w.Header().Set("WWW-Authenticate", `Bearer realm="boxoffice"`)
				writeProblem(w, http.StatusUnauthorized, "a staff token is required", nil)
				return
			}
			ctx := context.WithValue(r.Context(), roleKey{}, role)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// staffRole is the role requireStaff found, or "" outside it.
func staffRole(ctx context.Context) string {
	role, _ := ctx.Value(roleKey{}).(string)
	return role
}
```

E no `recoverPanics`, o `http.Error` virou um `writeProblem` sem detalhe, pelo motivo que a seção 05
deu:

```go
// boxoffice/recover.go
package main

import (
	"log"
	"net/http"
	"runtime/debug"
)

func recoverPanics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			v := recover()
			if v == nil {
				return
			}
			if v == http.ErrAbortHandler {
				panic(v)
			}
			log.Printf("panic serving %s %s: %v\n%s", r.Method, r.URL.Path, v, debug.Stack())
			writeProblem(w, http.StatusInternalServerError, "", nil)
		}()
		next.ServeHTTP(w, r)
	})
}
```

As rotas ganham a compra e a nova rota da equipe:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store *memStore, tokens map[string]string) http.Handler {
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

O `main.go` é o da aula 2, sem mudança.

## Rodando

```
ana@vm:~/boxoffice$ ls
admin.go
auth.go
cors.go
decode.go
events.go
go.mod
json.go
main.go
middleware.go
problem.go
recover.go
routes.go
store.go
ana@vm:~/boxoffice$ go vet ./...
```

Treze arquivos, ainda um pacote só. Com os dois tokens exportados como na aula 2:

```
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_DOOR_TOKEN" --json '{"name": "Organ Recital", "seats": 60}' localhost:8080/admin/events
{"type":"about:blank","title":"Forbidden","status":403,"detail":"only a manager may do this"}
ana@vm:~/boxoffice$ curl -si -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json '{"name": "Organ Recital", "seats": 60}' localhost:8080/admin/events
HTTP/1.1 201 Created
Content-Type: application/json
Location: /events/3
Vary: Origin
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 67

{"id":3,"name":"Organ Recital","seats":60,"sold":0,"available":60}
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json '{"name": "", "seats": 0}' localhost:8080/admin/events
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"the event is not valid","errors":{"name":"is required","seats":"must be between 1 and 10000"}}
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" localhost:8080/admin/report
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2},{"id":2,"name":"Chamber Choir","seats":80,"sold":80},{"id":3,"name":"Organ Recital","seats":60,"sold":0}]
```

O token da portaria é recusado com um problema, o do gerente cria **o evento 3 com o seu
`Location`**, um evento vazio é recusado com os dois campos nomeados, e o relatório agora lista o
evento novo e os dois ingressos que a seção 06 vendeu. O log do servidor guarda toda requisição
desta aula, em ordem:

```
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 19:36:33 boxoffice listening on localhost:8080
2026/10/16 19:36:33 GET /events 200 142B 115µs
2026/10/16 19:36:33 GET /events/1 200 73B 41µs
2026/10/16 19:36:33 POST /events/1/tickets 400 87B 84µs
2026/10/16 19:36:33 POST /events/1/tickets 400 109B 87µs
2026/10/16 19:36:33 POST /events/1/tickets 400 113B 50µs
2026/10/16 19:36:33 POST /events/1/tickets 400 121B 91µs
2026/10/16 19:36:33 POST /events/1/tickets 400 108B 74µs
2026/10/16 19:36:33 POST /events/1/tickets 400 125B 50µs
2026/10/16 19:36:33 POST /events/1/tickets 400 107B 4.845ms
2026/10/16 19:36:33 POST /events/1/tickets 422 175B 36µs
2026/10/16 19:36:33 POST /events/1/tickets 422 189B 54µs
2026/10/16 19:36:33 POST /events/1/tickets 422 153B 62µs
2026/10/16 19:36:33 POST /events/1/tickets 201 70B 49µs
2026/10/16 19:36:33 POST /events/2/tickets 409 88B 49µs
2026/10/16 19:36:33 POST /events/9/tickets 404 81B 31µs
2026/10/16 19:36:33 POST /events/nine/tickets 400 99B 30µs
2026/10/16 19:36:33 GET /events/1 200 73B 25µs
2026/10/16 19:36:33 POST /admin/events 401 96B 21µs
2026/10/16 19:36:33 POST /admin/events 403 94B 29µs
2026/10/16 19:36:33 POST /admin/events 201 67B 80µs
2026/10/16 19:36:33 POST /admin/events 422 171B 71µs
2026/10/16 19:36:33 GET /admin/report 200 164B 84µs
2026/10/16 19:36:33 DELETE /events 405 19B 32µs
```

**Todo status desta aula está nesse log, e só o 405 não foi escrito pelo boxoffice.** O que nada
disso sobrevive é a um reinício: pare o servidor e o Organ Recital e os dois ingressos somem, porque
o store é um mapa em memória. A aula 6 o põe no PostgreSQL. Antes disso, as aulas 4 e 5 param para
perguntar se este tanto de código escrito à mão foi o jeito certo de chegar aqui.
