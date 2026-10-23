---
title: Escrevendo JSON
version: 1
---

A aula 1 fez o boxoffice responder em texto separado por tabulação, e todo cliente teria de partir
linhas e contar tabulações para lê-lo. **JSON é o que uma API HTTP fala por padrão hoje em dia**:
toda linguagem tem um parser para ele, um navegador o lê nativamente, e uma pessoa ainda consegue
lê-lo num terminal. A aula 19 do `go-concurrency` tratou do `encoding/json` em si, das tags e do
`omitempty`; esta aula trata dos dois lugares em que ele encontra o HTTP, a resposta e a
requisição, e do que pode dar errado em cada um.

## A struct é o contrato

O tipo `Event` ganha uma tag em cada campo, na versão do store da seção 06:

```go
type Event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}
```

**As tags decidem os nomes que um cliente vê**, então os nomes em Go podem mudar sem quebrar
ninguém. Sem elas as chaves JSON seriam `ID` e `Name`, a grafia do Go, o que é válido e incomum o
bastante para clientes em outras linguagens tropeçarem. E um cliente nunca vê um número que ninguém
guardou: quantos lugares sobram é `Seats - Sold`, calculado quando a resposta é montada, então os
handlers mandam um `eventView` que embute o `Event` e acrescenta `available`. **Os campos de uma
struct embutida aparecem no JSON como se fossem da struct de fora**, e é por isso que a resposta
abaixo é um objeto plano.

## Codificar primeiro, depois enviar

```go
// boxoffice/json.go
package main

import (
	"encoding/json"
	"log"
	"net/http"
)

// writeJSON sends v as JSON with the status given. The value is encoded
// before anything is sent, so a value that cannot be encoded becomes a 500
// rather than half a response.
func writeJSON(w http.ResponseWriter, status int, v any) {
	body, err := json.Marshal(v)
	if err != nil {
		log.Printf("encoding %T: %v", v, err)
		http.Error(w, "internal server error", http.StatusInternalServerError)
		return
	}
	if w.Header().Get("Content-Type") == "" {
		w.Header().Set("Content-Type", "application/json")
	}
	w.WriteHeader(status)
	w.Write(append(body, '\n'))
}
```

A função toma uma decisão que importa. **Ela transforma o valor em bytes antes de enviar qualquer
coisa.** O `json.Marshal` pode falhar, com um canal, uma função ou um ponteiro cíclico no valor, e
se falhasse no meio da escrita em `w` o status já seria 200 e meio corpo estaria no fio. Codificar
em memória primeiro quer dizer que uma falha ainda pode virar um 500 honesto, com o motivo no log e
não na resposta.

Ela também define o `Content-Type` por conta própria, porque a seção 07 da aula 1 mostrou o que o
`net/http` chuta para um corpo que começa com `[` ou `{`: texto puro. Quem chamar com um tipo mais
preciso já definido o mantém, e a seção 05 precisa disso. A quebra de linha no fim é para pessoas:
sem ela, o `curl` deixa o prompt na linha do último byte.

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120},{"id":2,"name":"Chamber Choir","seats":80,"sold":80,"available":0}]
ana@vm:~/boxoffice$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json
Vary: Origin
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 73

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120}
```

**O `available` fica ao lado dos campos guardados, e o `sold` é honesto sobre o Chamber Choir**: 80
de 80. A lista voltou como um array JSON em ordem de id, porque o `List` ordena.

## Quando transmitir em fluxo é a escolha melhor

`json.NewEncoder(w).Encode(v)` escreve direto na resposta sem montar os bytes antes, e para uma
lista de cem mil linhas isso poupa guardar todas em memória de uma vez. O preço é o que o
`writeJSON` evita: um erro no meio chega depois do 200. **Para as respostas pequenas de uma API,
codifique primeiro; para exportações medidas em megabytes, transmita em fluxo, e aceite que uma
falha apareça como um corpo truncado** que o cliente tem de detectar.
