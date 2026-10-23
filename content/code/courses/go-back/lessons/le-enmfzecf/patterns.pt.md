---
title: Métodos e curingas no padrão
version: 1
---

Até o Go 1.22, lançado em fevereiro de 2024, um padrão do `ServeMux` era um caminho e mais nada.
Ele não sabia dizer `GET` nem "qualquer id aqui", então um handler de `/events/` recebia todo
método e todo caminho abaixo dele e tinha de separá-los sozinho, com um `if` em `r.Method` e um
`strings.Split` do caminho. **Essa lacuna é a maior parte do motivo de existirem roteadores Go
fora da biblioteca padrão**, e a aula 4 volta a ela. Desde a 1.22 um padrão carrega mais três
coisas:

| escrito | quer dizer |
|---|---|
| `GET /events` | o método, um espaço, depois o caminho |
| `/events/{id}` | um **curinga**: um segmento inteiro do caminho, qualquer texto, lido de volta com `r.PathValue("id")` |
| `/files/{path...}` | um curinga que pega **o resto do caminho**, barras incluídas; só pode vir por último |
| `/{$}` | um caminho que termina exatamente aqui, com barra final e tudo |

Aqui estão eles num programa só:

```go
// routes/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "the home page, and nothing below it")
	})
	mux.HandleFunc("GET /events", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "every event")
	})
	mux.HandleFunc("POST /events", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "a new event")
	})
	mux.HandleFunc("GET /events/{id}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "event %q\n", r.PathValue("id"))
	})
	mux.HandleFunc("GET /events/latest", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "the latest event")
	})
	mux.HandleFunc("GET /files/{path...}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "file %q\n", r.PathValue("path"))
	})
	mux.HandleFunc("/static/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "under /static/: %s\n", r.URL.Path)
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

## O método

```
ana@vm:~/routes$ curl -s localhost:8080/events
every event
ana@vm:~/routes$ curl -s -X POST localhost:8080/events
a new event
ana@vm:~/routes$ curl -si -X DELETE localhost:8080/events
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD, POST
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:11:52 GMT
Content-Length: 19

Method Not Allowed
```

Um caminho, dois handlers, escolhidos pelo método. **A terceira requisição é o que o mux antigo
nunca fazia sozinho**: o caminho existe, o método não, e a resposta é `405` com um cabeçalho
`Allow` listando o que teria funcionado. Ninguém escreveu essa lista. O mux a montou a partir dos
padrões registrados para `/events`, e pôs `HEAD` nela também, porque **um padrão `GET` também
responde `HEAD`**:

```
ana@vm:~/routes$ curl -sI localhost:8080/events
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:11:52 GMT
Content-Length: 12
Content-Type: text/plain; charset=utf-8

```

O `curl -I` manda `HEAD`. O handler rodou e escreveu seus doze bytes, e o servidor os contou para
o `Content-Length` sem mandar nenhum deles, que é o que `HEAD` quer dizer.

## Os curingas

```
ana@vm:~/routes$ curl -s localhost:8080/events/42
event "42"
ana@vm:~/routes$ curl -s localhost:8080/files/posters/2026/jazz.png
file "posters/2026/jazz.png"
ana@vm:~/routes$ curl -s localhost:8080/events/42/tickets
404 page not found
```

`{id}` pegou `42`, e **é uma string**: o mux não sabe nada de números, e transformá-lo em número é
trabalho do handler, com resposta própria quando falha, que é o que o boxoffice faz na seção 09.
`{path...}` pegou três segmentos com as barras. A última requisição é um 404 porque `{id}` casa um
segmento e `42/tickets` são dois; nenhum padrão daqui cobre isso.

## As pontas de um caminho

```
ana@vm:~/routes$ curl -s localhost:8080/
the home page, and nothing below it
ana@vm:~/routes$ curl -si localhost:8080/about
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:11:52 GMT
Content-Length: 19

404 page not found
```

**`{$}` é o que impede o `/` de engolir o site.** Um padrão que termina em barra ainda quer dizer
"isto e tudo abaixo", como na seção 03, então só `GET /` teria respondido `/about` com a página
inicial. Com `{$}` ele responde `/` e mais nada, e `/about` é um 404 honesto.

O sentido antigo continua lá para quando você o quiser, e o `/static/` o usa:

```
ana@vm:~/routes$ curl -s localhost:8080/static/css/site.css
under /static/: /static/css/site.css
ana@vm:~/routes$ curl -si localhost:8080/static
HTTP/1.1 307 Temporary Redirect
Content-Type: text/html; charset=utf-8
Location: /static/
Date: Fri, 16 Oct 2026 22:11:52 GMT
Content-Length: 44

<a href="/static/">Temporary Redirect</a>.

```

Uma requisição a `/static`, sem a barra, não está debaixo de `/static/`, e **o mux a redireciona
para a forma com barra** em vez de responder 404. Isso ajuda num diretório de arquivos e
surpreende numa API, onde um cliente que não segue redirecionamentos vê um 307 que não esperava. O
padrão `/static/` também não tem método, então responde `DELETE` tão prontamente quanto `GET`: um
padrão sem método casa todo método, exatamente como antes da 1.22.

## Um padrão pode nomear um host

Existe mais uma parte, e este curso não a usa em lugar nenhum: um padrão pode começar com um nome de
host, `api.example.com/events`, e aí só casa requisições mandadas para esse nome. É assim que um
processo serve dois sites. **Um padrão com host é mais específico que um sem**, que é a primeira
das regras de que trata a próxima seção.
