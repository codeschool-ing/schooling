---
title: Beego
version: 1
---

Gin, Echo e Fiber são frameworks web: roteamento, binding, middleware, e o resto é seu. **O Beego é
um framework full-stack na tradição do Ruby on Rails e do Django.** Ele traz uma estrutura MVC com
controllers, um ORM próprio, um sistema de configuração, sessões, um cache, um agendador de tarefas,
uma página de administração e uma ferramenta de linha de comando, o `bee`, que gera o esqueleto de
um projeto. É mais usado na China, onde foi escrito, e a versão aqui é a **v2.3.10**.

As rotas funcionais dele são o mais perto que ele chega dos outros, então é o que esta versão usa:

```go
// fw/beego/main.go
package main

import (
	"encoding/json"
	"net/http"
	"strconv"
	"sync"

	"github.com/beego/beego/v2/server/web"
	"github.com/beego/beego/v2/server/web/context"
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

func fail(ctx *context.Context, status int, msg string) {
	ctx.Output.SetStatus(status)
	ctx.Output.JSON(map[string]string{"error": msg}, false, false)
}

func main() {
	web.BConfig.CopyRequestBody = true
	web.Get("/events/:id", func(ctx *context.Context) {
		id, err := strconv.Atoi(ctx.Input.Param(":id"))
		if err != nil {
			fail(ctx, http.StatusBadRequest, "the event id must be a number")
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			fail(ctx, http.StatusNotFound, "no such event")
			return
		}
		ctx.Output.JSON(e, false, false)
	})
	web.Post("/events/:id/tickets", func(ctx *context.Context) {
		id, _ := strconv.Atoi(ctx.Input.Param(":id"))
		var p purchase
		if err := json.Unmarshal(ctx.Input.RequestBody, &p); err != nil {
			fail(ctx, http.StatusBadRequest, err.Error())
			return
		}
		if p.Quantity < 1 || p.Quantity > 10 {
			fail(ctx, http.StatusUnprocessableEntity, "quantity must be between 1 and 10")
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			fail(ctx, http.StatusNotFound, "no such event")
			return
		}
		if e.Seats-e.Sold < p.Quantity {
			fail(ctx, http.StatusConflict, "not enough seats left")
			return
		}
		e.Sold += p.Quantity
		ctx.Output.SetStatus(http.StatusCreated)
		ctx.Output.JSON(map[string]int{"event_id": id, "remaining": e.Seats - e.Sold}, false, false)
	})
	web.Run("localhost:8080")
}
```

Duas coisas mostram a herança full-stack. **`web.BConfig.CopyRequestBody = true`** é necessário para
o `ctx.Input.RequestBody` conter o corpo, uma configuração que pertence ao objeto de configuração
global do Beego. E o parâmetro é lido como `ctx.Input.Param(":id")`, com os dois-pontos.

## Compilando e perguntando

```
ana@vm:~/fw/beego$ go mod tidy
go: finding module for package github.com/beego/beego/v2/server/web
go: finding module for package github.com/beego/beego/v2/server/web/context
go: found github.com/beego/beego/v2/server/web in github.com/beego/beego/v2 v2.3.10
go: found github.com/beego/beego/v2/server/web/context in github.com/beego/beego/v2 v2.3.10
go: finding module for package github.com/kr/text
go: found github.com/kr/text in github.com/kr/text v0.2.0
ana@vm:~/fw/beego$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 21684349 Oct 16 19:44 server
```

```
ana@vm:~/fw/beego$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Length: 56
Content-Type: application/json; charset=utf-8
Date: Fri, 16 Oct 2026 22:44:37 GMT

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}ana@vm:~/fw/beego$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}ana@vm:~/fw/beego$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"error":"quantity must be between 1 and 10"}ana@vm:~/fw/beego$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"error":"json: cannot unmarshal string into Go struct field purchase.quantity of type int"}ana@vm:~/fw/beego$ curl -si -X DELETE localhost:8080/events/1 | head -5
HTTP/1.1 404 Not Found
Date: Fri, 16 Oct 2026 22:44:37 GMT
Content-Length: 2000
Content-Type: text/html; charset=utf-8

ana@vm:~/fw/beego$ curl -s localhost:8080/nothing | grep -i -e title -e powered
		<title>Not Found</title>
					<a href="/" title="Home" class="button">Go Home</a><br />
					<br>Powered by beego 2.0.0
```

As rotas respondem como as dos outros. **As duas falhas que ninguém escreveu são onde o Beego se
mostra**: o método errado e o caminho desconhecido recebem um 404 que é uma **página HTML de 2.000
bytes**, com folha de estilo, um botão "Go Home" e uma linha dizendo que foi feita com beego 2.0.0,
embora o módulo seja o 2.3.10. Um cliente de uma API JSON recebe uma página web feita para uma pessoa
num navegador. Ela é substituível, registrando tratadores de erro no Beego, e é um retrato justo da
troca: **um framework full-stack responde a muitas perguntas antes de você fazê-las**, e cada
resposta tem de ser encontrada e mudada quando não é a que você queria.

```
ana@vm:~/fw/beego$ cat -v .server.log
init global config instance failed. If you do not use this, just ignore it.  open conf/app.conf: no such file or directory
2026/10/16 19:44:37.207 ^[[1;34m[I]^[[0m  http server Running on http://localhost:8080
```

A primeira linha reclama que `conf/app.conf` não existe, porque o Beego espera um projeto organizado
do jeito dele. A segunda traz códigos de cor de terminal mesmo sem ninguém olhando um terminal: o
`cat -v` os mostra como `^[`. **Um log feito para ser lido por máquina não deveria contê-los**, e a
aula 12 trata de logs que uma máquina lê.

O binário tem **21.684.349 bytes**, e `go list -m all` nomeia **102 módulos além do seu**, de longe o
maior número dos quatro, porque o ORM, o cache e o resto vêm junto quer este programa os use ou não.
