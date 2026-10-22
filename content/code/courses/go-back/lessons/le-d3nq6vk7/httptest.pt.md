---
title: Um handler, uma requisição e um recorder
version: 1
---

A distância mais curta chama um handler como uma função. O `httptest.NewRequest` monta uma requisição sem
rede nenhuma, o `httptest.NewRecorder` é um `ResponseWriter` que guarda o que o handler escreveu, e o
handler é chamado com os dois. Os handlers do boxoffice são criados por funções que recebem o store, então
o teste entrega a cada um um `newMemStore()` novo, com os dois eventos da aula 1:

```go
// boxoffice/events_test.go
package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestGetEvent(t *testing.T) {
	tests := []struct {
		name   string
		id     string
		status int
	}{
		{"an event that exists", "1", http.StatusOK},
		{"an event that does not", "9", http.StatusNotFound},
		{"an id that is not a number", "one", http.StatusBadRequest},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/events/"+tt.id, nil)
			req.SetPathValue("id", tt.id) // no mux here to fill it in
			rec := httptest.NewRecorder()

			getEvent(newMemStore())(rec, req)

			if rec.Code != tt.status {
				t.Fatalf("status %d, want %d; body %s", rec.Code, tt.status, rec.Body)
			}
		})
	}
}

func TestBuyTickets(t *testing.T) {
	tests := []struct {
		name   string
		id     string
		body   string
		status int
		want   string // a piece of the body that must be there
	}{
		{"a good purchase", "1", `{"quantity": 2, "email": "ana@example.com"}`, http.StatusCreated, `"remaining":118`},
		{"too many at once", "1", `{"quantity": 11, "email": "ana@example.com"}`, http.StatusUnprocessableEntity, `"quantity":"must be between 1 and 10"`},
		{"a sold-out event", "2", `{"quantity": 1, "email": "ana@example.com"}`, http.StatusConflict, `not enough seats left`},
		{"a field nobody declared", "1", `{"quantity": 1, "email": "ana@example.com", "price": 0}`, http.StatusBadRequest, `unknown field \"price\"`},
		{"an event that does not exist", "9", `{"quantity": 1, "email": "ana@example.com"}`, http.StatusNotFound, `no such event`},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("POST", "/events/"+tt.id+"/tickets", strings.NewReader(tt.body))
			req.SetPathValue("id", tt.id)
			rec := httptest.NewRecorder()

			buyTickets(newMemStore())(rec, req)

			if rec.Code != tt.status {
				t.Fatalf("status %d, want %d; body %s", rec.Code, tt.status, rec.Body)
			}
			if !strings.Contains(rec.Body.String(), tt.want) {
				t.Errorf("body %s does not contain %s", rec.Body, tt.want)
			}
			if rec.Code >= 400 {
				var p problem
				if err := json.Unmarshal(rec.Body.Bytes(), &p); err != nil || p.Status != rec.Code {
					t.Errorf("not a problem document for %d: %s", rec.Code, rec.Body)
				}
				if ct := rec.Header().Get("Content-Type"); ct != "application/problem+json" {
					t.Errorf("Content-Type %q", ct)
				}
			}
		})
	}
}
```

Três detalhes carregam a maior parte do peso.

- **O `SetPathValue` faz o papel do mux.** O `getEvent` lê `r.PathValue("id")`, e esse valor é posto ali
  pelo `ServeMux` quando ele casa o padrão `/events/{id}`. Chamar o handler diretamente pula o mux, então
  o teste define o valor à mão; esqueça isso, e o `PathValue`
  devolve uma string vazia, que o `pathID` recusa: todo caso responderia 400.
- **Cada caso ganha o seu próprio store.** A compra de dois lugares muda o store, e um store compartilhado
  entre os casos faria o resultado de um depender da ordem em que eles rodam.
- **Um erro é verificado como documento de problema**, não só pelo status. A aula 3 prometeu que todo erro
  responde `application/problem+json` com um `status` igual ao da resposta; a tabela verifica essa promessa
  uma vez para cada caso de falha, então um handler que respondesse com o texto puro do `http.Error`
  falharia aqui.

Cada caso é uma linha numa tabela, nomeada em palavras, e o `t.Run` transforma cada uma num subteste
próprio:

```
ana@vm:~/boxoffice$ go vet ./... && go test -run "TestGetEvent|TestBuyTickets" -v .
=== RUN   TestGetEvent
=== RUN   TestGetEvent/an_event_that_exists
=== RUN   TestGetEvent/an_event_that_does_not
=== RUN   TestGetEvent/an_id_that_is_not_a_number
--- PASS: TestGetEvent (0.00s)
    --- PASS: TestGetEvent/an_event_that_exists (0.00s)
    --- PASS: TestGetEvent/an_event_that_does_not (0.00s)
    --- PASS: TestGetEvent/an_id_that_is_not_a_number (0.00s)
=== RUN   TestBuyTickets
=== RUN   TestBuyTickets/a_good_purchase
=== RUN   TestBuyTickets/too_many_at_once
=== RUN   TestBuyTickets/a_sold-out_event
=== RUN   TestBuyTickets/a_field_nobody_declared
=== RUN   TestBuyTickets/an_event_that_does_not_exist
--- PASS: TestBuyTickets (0.00s)
    --- PASS: TestBuyTickets/a_good_purchase (0.00s)
    --- PASS: TestBuyTickets/too_many_at_once (0.00s)
    --- PASS: TestBuyTickets/a_sold-out_event (0.00s)
    --- PASS: TestBuyTickets/a_field_nobody_declared (0.00s)
    --- PASS: TestBuyTickets/an_event_that_does_not_exist (0.00s)
PASS
ok  	example.com/boxoffice	(cached)
```

O `go vet` rodou primeiro e não disse nada, que é o que ele deve dizer. Os nomes na saída são os nomes da
tabela com os espaços trocados por sublinhados, e **um único caso pode rodar sozinho** com
`-run 'TestBuyTickets/a_sold-out_event'`. Quando um falha, o `t.Fatalf` imprime o status e o corpo, então a
falha diz o que voltou em vez de só dizer que estava errado.
