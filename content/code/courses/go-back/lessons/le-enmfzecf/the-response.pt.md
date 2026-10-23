---
title: Escrevendo a resposta, na ordem certa
version: 1
---

Uma resposta HTTP sai numa ordem fixa: **a linha de status, depois os cabeçalhos, depois o
corpo**. Quando o primeiro byte do corpo sai, o status e os cabeçalhos já saíram com ele, e nada
pode mudá-los. O `ResponseWriter` segue essa ordem à risca, e seus três métodos são as três partes:

| método | faz |
|---|---|
| `w.Header()` | devolve o mapa de cabeçalhos, para ser alterado **antes** de qualquer envio |
| `w.WriteHeader(code)` | manda a linha de status e os cabeçalhos, uma vez |
| `w.Write(bytes)` | manda corpo; se o `WriteHeader` não foi chamado, chama-o com 200 antes |

**A maioria dos erros com um `ResponseWriter` são esses três chamados na ordem errada**, e nenhum
deles é erro de compilação. Este programa comete cada um de propósito:

```go
// reply/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /created", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Location", "/events/7")
		w.WriteHeader(http.StatusCreated)
		fmt.Fprintln(w, "event 7 created")
	})
	mux.HandleFunc("GET /late", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "the body went first")
		w.Header().Set("X-Seats", "40")
		w.WriteHeader(http.StatusAccepted)
	})
	mux.HandleFunc("GET /sniffed", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "<h1>boxoffice</h1>")
	})
	mux.HandleFunc("GET /declared", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprint(w, "<h1>boxoffice</h1>")
	})
	mux.HandleFunc("GET /missing", func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "no such seat", http.StatusNotFound)
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

## A ordem certa, e a errada

```
ana@vm:~/reply$ curl -si localhost:8080/created
HTTP/1.1 201 Created
Location: /events/7
Date: Fri, 16 Oct 2026 22:11:56 GMT
Content-Length: 16
Content-Type: text/plain; charset=utf-8

event 7 created
ana@vm:~/reply$ curl -si localhost:8080/late
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:11:56 GMT
Content-Length: 20
Content-Type: text/plain; charset=utf-8

the body went first
```

`/created` definiu um cabeçalho, escolheu um status, depois escreveu: o cliente recebeu os três.
`/late` escreveu primeiro, e **a escrita mandou um 200 sozinha**, então o cabeçalho `X-Seats`
definido depois não foi a lugar nenhum e o `202` chegou tarde demais para ser status. Nenhum dos
dois erros chegou ao cliente como erro. Um deles chegou ao terminal do próprio servidor:

```
ana@vm:~/reply$ go run .
2026/10/16 19:11:56 http: superfluous response.WriteHeader call from main.main.func2 (main.go:20)
```

**`superfluous response.WriteHeader call` é a linha a procurar** quando o código de status de um
handler "não faz nada". Ela nomeia a função e a linha, aqui o `WriteHeader(http.StatusAccepted)` da
linha 20; `main.main.func2` é como o Go chama a segunda função literal dentro do `main`. O cabeçalho
que sumiu não produziu linha nenhuma.

## O tipo adivinhado

```
ana@vm:~/reply$ curl -si localhost:8080/sniffed
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:11:56 GMT
Content-Length: 18
Content-Type: text/html; charset=utf-8

<h1>boxoffice</h1>ana@vm:~/reply$ curl -si localhost:8080/declared
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Date: Fri, 16 Oct 2026 22:11:56 GMT
Content-Length: 18

<h1>boxoffice</h1>ana@vm:~/reply$ curl -si localhost:8080/missing
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:11:57 GMT
Content-Length: 13

no such seat
```

(O prompt cai na mesma linha do corpo porque o `Fprint`, diferente do `Fprintln`, não escreveu
quebra de linha, e o `curl` deixou o cursor onde o corpo terminou.)

Quando um handler não define `Content-Type`, **o `net/http` lê os primeiros 512 bytes do corpo e
chuta**, com a função `http.DetectContentType`. Ele viu `<h1>` e disse `text/html`, e um navegador
desenharia o título. `/declared` mandou os mesmos bytes com o tipo definido à mão, e um navegador
mostraria as tags como texto. **Um servidor que responde JSON deve dizer isso ele mesmo**, e da
aula 3 em diante toda resposta que este curso escreve diz: um chute está certo até o dia em que um
valor por acaso começa com algo parecido com HTML.

O `http.Error` é o atalho do pacote para uma falha. Ele define `text/plain`, acrescenta
`X-Content-Type-Options: nosniff` para o navegador não duvidar desse tipo, escreve o status e depois
a mensagem com uma quebra de linha. Ele não retorna do seu handler, então **a linha depois do
`http.Error` quase sempre é `return`**, como no boxoffice da seção 09.
