---
title: Uma requisição HTTP
version: 1
---

As lições 10 e 11 montaram contextos sem nada de real em nenhuma das pontas. Um servidor web é o
lugar para o qual o mecanismo foi projetado, e no `net/http` **os dois lados de uma requisição já
carregam um contexto**: o servidor entrega um a cada handler, e o cliente recebe um a cada
requisição. Um programa que usa os dois é o jeito mais claro de ver o que cada um faz.

O programa abaixo é um servidor e o seu cliente num processo só. O handler leva dois segundos para
produzir um relatório, a menos que a requisição dele termine antes. O cliente não espera mais de
100 milissegundos. O servidor escuta em `127.0.0.1:8412`, um endereço que só esta máquina alcança.
Ele é salvo em `~/cases/abandon` como `abandon.go`:

```go
// Command abandon serves one slow request and gives up on it from the client side.
package main

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"time"
)

func main() {
	gone := make(chan string, 1)
	report := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		select {
		case <-time.After(2 * time.Second):
			fmt.Fprintln(w, "report ready")
			gone <- "server: finished the report"
		case <-r.Context().Done():
			gone <- fmt.Sprintf("server: client left after %v: %v",
				time.Since(start).Round(10*time.Millisecond), r.Context().Err())
		}
	})
	ln, err := net.Listen("tcp", "127.0.0.1:8412")
	if err != nil {
		fmt.Println(err)
		return
	}
	go http.Serve(ln, report)

	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, "GET", "http://127.0.0.1:8412/report", nil)
	if err != nil {
		fmt.Println(err)
		return
	}
	_, err = http.DefaultClient.Do(req)
	fmt.Println("client:", err)
	fmt.Println(<-gone)
}
```

```
ana@vm:~/cases$ go run ./abandon
client: Get "http://127.0.0.1:8412/report": context deadline exceeded
server: client left after 100ms: context canceled
```

Leia as duas linhas como duas metades de um mesmo acontecimento.

**O lado do cliente.** `http.NewRequestWithContext` prende `ctx` à requisição, e `Do` volta assim
que o contexto termina, faça o servidor o que fizer. O erro dá o endereço e o motivo,
`context deadline exceeded`, e `errors.Is(err, context.DeadlineExceeded)` o encontraria, porque o
cliente embrulha o erro do contexto em vez de substituí-lo. `http.NewRequest`, sem o contexto,
ainda existe, e é a requisição que espera o quanto o servidor demorar.

**O lado do servidor.** Quando o cliente desistiu, ele fechou a conexão. O servidor percebeu e
cancelou o contexto da requisição que aquela conexão carregava, `r.Context()`. O handler esperava
esse contexto no seu `select`, então parou depois de 100 milissegundos em vez de gastar dois
segundos num relatório que ninguém leria. O motivo dele é `context canceled`, e não o prazo do
cliente: **o servidor não sabe por que o cliente saiu, só que saiu.**

Um handler que ignora `r.Context()` ainda funciona, e termina cada relatório abandonado para
ninguém. Sob carga, essa é a diferença entre um servidor que larga o trabalho que os clientes
deixaram de querer e um que fica mais para trás a cada timeout. Num handler real o contexto desce
mais, para cada chamada que o handler faz, exatamente como `ctx` foi de `handle` a `fetch` na
lição 11.

Uma regra é fácil de esquecer: **`r.Context()` pertence àquela requisição e termina com ela.** Um
trabalho que o handler inicia numa goroutine própria, e que deve sobreviver à resposta, não pode
usar esse contexto, ou é cancelado no instante em que o handler retorna. É o caso do
`context.WithoutCancel`, da lição 11.
