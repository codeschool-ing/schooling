---
title: Por que o Go tem roteadores e frameworks
version: 1
---

A aula 1 construiu o boxoffice só com o `net/http`, e as aulas 2 e 3 acrescentaram à mão o que
faltava: uma cadeia de middlewares, um escritor de JSON, um decodificador que recusa corpos ruins,
um formato único para erros. **A maioria dos serviços web em Go em produção não foi escrita assim.**
Eles usam um roteador ou um framework de fora da biblioteca padrão, e por muito tempo houve um bom
motivo para isso.

## O que faltava antes da 1.22

Até fevereiro de 2024, o `ServeMux` não roteava por método e não tinha curingas, como disse a seção
05 da aula 1. Uma rota como `GET /events/{id}` tinha de ser um handler só para a subárvore
`/events/`, com um `if r.Method != "GET"` no topo e um `strings.TrimPrefix` para tirar o id do
caminho. Três projetos preencheram essa lacuna e moldaram tudo o que veio depois:

| projeto | desde | o que trouxe |
|---|---|---|
| `julienschmidt/httprouter` | 2013 | métodos e parâmetros `:id`, casados numa árvore, muito rápido; o roteador do Gin começou como uma cópia dele |
| `gorilla/mux` | 2012 | métodos, variáveis `{id}`, expressões regulares, casamento por host; arquivado em 2022, assumido por novos mantenedores em 2023 |
| `go-chi/chi` | 2016 | um roteador cujos handlers continuam `http.Handler`, com middleware no formato padrão |

**Um framework vai além de um roteador.** Além do roteamento, ele traz um tipo próprio de requisição
que carrega também a resposta, funções que decodificam um corpo direto numa struct e o validam a
partir de tags, um lugar central onde erros viram respostas, e um catálogo de middlewares prontos.
Esta aula constrói a mesma API pequena quatro vezes, em Gin, Echo, Fiber e Beego, e a aula 5 julga o
que isso comprou.

## A régua

Para comparar, é preciso uma base. Eis a API que toda versão implementa, na biblioteca padrão e mais
nada, no estilo simples com que a aula 1 começou, e não no do boxoffice:

```go
// fw/std/main.go
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"
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
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events/{id}", func(w http.ResponseWriter, r *http.Request) {
		id, err := strconv.Atoi(r.PathValue("id"))
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
	mux.HandleFunc("POST /events/{id}/tickets", func(w http.ResponseWriter, r *http.Request) {
		id, _ := strconv.Atoi(r.PathValue("id"))
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
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

Duas rotas, um mutex em volta de um mapa, uma verificação de quantidade e quatro status. Cada versão
com framework abaixo mantém o mesmo store, a mesma verificação e os mesmos status, para que o que
muda seja o framework. Toda versão foi então compilada e recebeu as mesmas seis perguntas:

```
ana@vm:~/fw/std$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 9807673 Oct 16 19:42 server
```

```
ana@vm:~/fw/std$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json
Date: Fri, 16 Oct 2026 22:42:48 GMT
Content-Length: 57

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}
ana@vm:~/fw/std$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}
ana@vm:~/fw/std$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"error":"quantity must be between 1 and 10"}
ana@vm:~/fw/std$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"error":"json: cannot unmarshal string into Go struct field purchase.quantity of type int"}
ana@vm:~/fw/std$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:42:48 GMT
Content-Length: 19

Method Not Allowed
ana@vm:~/fw/std$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:42:48 GMT
Content-Length: 19

404 page not found
```

Um evento, uma compra, uma quantidade inválida, uma string onde cabe um número, o método errado e um
caminho que não existe. **Guarde as duas últimas respostas**: o 405 com seu cabeçalho `Allow` e o
404 simples são da biblioteca padrão, e cada um dos quatro frameworks os responde de um jeito
diferente.
