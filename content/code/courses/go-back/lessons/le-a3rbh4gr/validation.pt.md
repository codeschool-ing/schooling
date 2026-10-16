---
title: Decodificado não é válido
version: 1
---

Um corpo que decodifica sem problema tem o formato certo. Ele ainda pode pedir quarenta ingressos,
ou zero, ou dar `ana` como endereço de e-mail. **O decoder responde "este é o JSON que eu esperava";
só o handler responde "isto faz sentido"**, porque só o handler sabe o que é uma compra. Essa
segunda verificação é a validação, e no boxoffice ela é um método do tipo da requisição, ao lado do
handler que o usa:

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

func listEvents(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		events := store.List()
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

func getEvent(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		e, err := store.Get(id)
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

func buyTickets(store *memStore) http.HandlerFunc {
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
		e, err := store.Sell(id, p.Quantity)
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

O `validate` olha cada campo e **junta todo problema antes de responder**, em vez de parar no
primeiro. Um cliente que ouve "a quantidade está errada", corrige, e depois ouve "e o e-mail
também" foi obrigado a mandar duas requisições para saber o que uma podia ter dito. As chaves do
mapa são os nomes JSON, não os do Go, porque elas são para o cliente.

O `buyTickets` então roda as verificações na ordem do custo: o id no caminho, depois o formato do
corpo, depois os valores, e só então o store. Cada passo que falha responde e retorna, então **o
store nunca vê uma requisição que falhou num passo anterior**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Quatro verificações em fila: o id no caminho, o JSON do corpo, os valores e a venda do store. Cada verificação que falha sai da fila para baixo com o próprio status: 400, 400, 422, e 404 ou 409. Só uma requisição que passa pelas quatro chega ao 201 Created à direita.\"><defs><marker id=\"gb-l3-gates-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pathID</text><text x=\"75\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">id no caminho</text><path d=\"M 75 90 L 75 133\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"30\" y=\"135\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">400</text><path d=\"M 135 65 L 153 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"155\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">decodeJSON</text><text x=\"215\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o JSON</text><path d=\"M 215 90 L 215 133\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"170\" y=\"135\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"215\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">400</text><path d=\"M 275 65 L 293 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"295\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">validate</text><text x=\"355\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os valores</text><path d=\"M 355 90 L 355 133\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"310\" y=\"135\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">422</text><path d=\"M 415 65 L 433 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"435\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"495\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">store.Sell</text><text x=\"495\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os lugares</text><path d=\"M 495 90 L 495 133\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"450\" y=\"135\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"495\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">404 / 409</text><path d=\"M 555 65 L 573 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"575\" y=\"40\" width=\"110\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">201 Created</text><text x=\"630\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um recibo</text><text x=\"15\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a verificação mais barata primeiro</text><text x=\"15\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma falha responde e retorna</text></svg>", "caption": "O buyTickets verifica do mais barato ao mais caro, e cada falha responde por conta própria."}
```

```
ana@vm:~/boxoffice$ curl -s --json '{}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"the purchase is not valid","errors":{"email":"is required","quantity":"must be between 1 and 10"}}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"the purchase is not valid","errors":{"email":"must be an e-mail address","quantity":"must be between 1 and 10"}}
ana@vm:~/boxoffice$ curl -si --json '{"quantity": 0, "email": "ana@example.com"}' localhost:8080/events/1/tickets
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/problem+json
Vary: Origin
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 153

{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"the purchase is not valid","errors":{"quantity":"must be between 1 and 10"}}
```

`{}` decodifica perfeitamente num `purchase`: os dois campos só ficam com seus valores zero, `0` e
`""`. **O `encoding/json` não distingue um campo ausente de um mandado como zero**, então "must be
between 1 and 10" cobre os dois casos aqui. Quando a diferença importa, num campo em que zero é um
valor legítimo e a ausência não é, o campo vira um ponteiro, `*int`, que fica `nil` quando a chave
falta.

## 400 ou 422

As falhas de decodificação da seção 03 foram 400 e estas são 422. **400 Bad Request diz que o
servidor não conseguiu ler a requisição; 422 Unprocessable Content diz que leu e os valores estão
errados.** (O `http.StatusText` do Go ainda imprime o nome antigo, Unprocessable Entity.) Muitas
APIs respondem 400 para os dois, e isso também está bem: o que importa é um cliente conseguir
distinguir "conserte o seu JSON" de "conserte os seus valores", aqui pelo status e pelo objeto
`errors` juntos.

## O que a verificação de e-mail não é

`strings.Contains(p.Email, "@")` pega quem digitou o nome no campo errado e nada mais. Isso é de
propósito. **O único teste real de um endereço de e-mail é mandar uma mensagem para ele**, e um
padrão mais rígido recusa endereços reais mais cedo ou mais tarde e ainda deixa passar erros de
digitação. A validação na borda de uma API é para erros que uma pessoa comete de boa-fé; as regras
do negócio, como se ainda há lugares, pertencem ao store, que é o assunto da seção 06.

## Tags de struct em vez de métodos

Muitos projetos Go escrevem as mesmas regras como tags, `validate:"required,min=1,max=10"`, e deixam
a biblioteca `go-playground/validator` lê-las por reflexão. A aula 4 a encontra, porque o Gin a usa.
O método acima dá mais trabalho de digitar e não tem mágica: é código comum que um teste consegue
chamar e um leitor consegue seguir sem conhecer uma linguagem de tags.
