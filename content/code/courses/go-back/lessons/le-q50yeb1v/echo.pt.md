---
title: Echo
version: 1
---

**A grande ideia do Echo é que um handler devolve um erro.** Onde um handler padrão e um do Gin
escrevem a falha e dão `return`, um handler do Echo dá `return` na falha, e uma função para o
servidor inteiro, o tratador de erros HTTP, a transforma em resposta. É o formato que a aula 3
construiu à mão com o `fail`, levado para dentro do framework. A versão usada aqui é a **v5.4.0**, a
quinta versão maior, em que o contexto virou uma struct passada por ponteiro, `*echo.Context`.

```go
// fw/echo/main.go
package main

import (
	"net/http"
	"strconv"
	"sync"

	"github.com/labstack/echo/v5"
	"github.com/labstack/echo/v5/middleware"
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

func main() {
	e := echo.New()
	e.Use(middleware.RequestLogger())
	e.GET("/events/:id", func(c *echo.Context) error {
		id, err := strconv.Atoi(c.Param("id"))
		if err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, "the event id must be a number")
		}
		mu.Lock()
		defer mu.Unlock()
		ev, ok := events[id]
		if !ok {
			return echo.NewHTTPError(http.StatusNotFound, "no such event")
		}
		return c.JSON(http.StatusOK, ev)
	})
	e.POST("/events/:id/tickets", func(c *echo.Context) error {
		id, _ := strconv.Atoi(c.Param("id"))
		var p purchase
		if err := c.Bind(&p); err != nil {
			return err
		}
		if p.Quantity < 1 || p.Quantity > 10 {
			return echo.NewHTTPError(http.StatusUnprocessableEntity, "quantity must be between 1 and 10")
		}
		mu.Lock()
		defer mu.Unlock()
		ev, ok := events[id]
		if !ok {
			return echo.NewHTTPError(http.StatusNotFound, "no such event")
		}
		if ev.Seats-ev.Sold < p.Quantity {
			return echo.NewHTTPError(http.StatusConflict, "not enough seats left")
		}
		ev.Sold += p.Quantity
		return c.JSON(http.StatusCreated, map[string]int{"event_id": id, "remaining": ev.Seats - ev.Sold})
	})
	if err := e.Start("localhost:8080"); err != nil {
		e.Logger.Error("server stopped", "error", err)
	}
}
```

- **`return echo.NewHTTPError(status, message)`** é a falha, e o handler para ali.
- **`return c.JSON(status, value)`** é o sucesso, porque a escrita também pode falhar.
- **`c.Bind(&p)`** decodifica o corpo; o Echo não tem validação própria, então a verificação de
  quantidade ficou no handler.
- **`middleware.RequestLogger()`** é o log de acesso, escolhido em vez de acoplado por padrão.

## Compilando e perguntando

```
ana@vm:~/fw/echo$ go mod tidy
go: finding module for package github.com/labstack/echo/v5/middleware
go: finding module for package github.com/labstack/echo/v5
go: found github.com/labstack/echo/v5 in github.com/labstack/echo/v5 v5.4.0
go: found github.com/labstack/echo/v5/middleware in github.com/labstack/echo/v5 v5.4.0
ana@vm:~/fw/echo$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 11094543 Oct 16 19:44 server
```

```
ana@vm:~/fw/echo$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json
Date: Fri, 16 Oct 2026 22:44:26 GMT
Content-Length: 57

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}
ana@vm:~/fw/echo$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}
ana@vm:~/fw/echo$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"message":"quantity must be between 1 and 10"}
ana@vm:~/fw/echo$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"message":"Bad Request"}
ana@vm:~/fw/echo$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 405 Method Not Allowed
Allow: OPTIONS, GET
Content-Type: application/json
Date: Fri, 16 Oct 2026 22:44:26 GMT
Content-Length: 33

{"message":"Method Not Allowed"}
ana@vm:~/fw/echo$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: application/json
Date: Fri, 16 Oct 2026 22:44:26 GMT
Content-Length: 24

{"message":"Not Found"}
```

**Todo erro voltou como JSON, `{"message": ...}`, sem ninguém escrever um formato**: o 422, o 405, o
404 de um caminho que ninguém registrou. É o tratador central de erros trabalhando, e é o que a
seção 05 da aula 3 não conseguiu do `ServeMux` sem perder o 405. O Echo o manteve, com um cabeçalho
`Allow` que lista `OPTIONS` e `GET`.

**O erro de tipo é o interessante.** O cliente ouviu só `Bad Request`. O detalhe, qual campo e qual
tipo, ficou retido. Eis por quê:

```
ana@vm:~/fw/echo$ cat -v .server.log
{"time":"2026-10-16T19:44:26.383712874-03:00","level":"INFO","msg":"Echo (v5.4.0). High performance, minimalist Go web framework https://echo.labstack.com","version":"5.4.0"}
{"time":"2026-10-16T19:44:26.383770378-03:00","level":"INFO","msg":"http(s) server started","address":"127.0.0.1:8080"}
{"time":"2026-10-16T19:44:26.591283396-03:00","level":"INFO","msg":"REQUEST","method":"GET","uri":"/events/1","status":200,"latency":116616,"host":"localhost:8080","bytes_in":"","bytes_out":57,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":""}
{"time":"2026-10-16T19:44:26.612118897-03:00","level":"INFO","msg":"REQUEST","method":"POST","uri":"/events/1/tickets","status":201,"latency":168526,"host":"localhost:8080","bytes_in":"43","bytes_out":31,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":""}
{"time":"2026-10-16T19:44:26.628513814-03:00","level":"ERROR","msg":"REQUEST_ERROR","method":"POST","uri":"/events/1/tickets","status":422,"latency":60899,"host":"localhost:8080","bytes_in":"32","bytes_out":48,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":"","error":"code=422, message=quantity must be between 1 and 10"}
{"time":"2026-10-16T19:44:26.643519826-03:00","level":"ERROR","msg":"REQUEST_ERROR","method":"POST","uri":"/events/1/tickets","status":400,"latency":41588,"host":"localhost:8080","bytes_in":"19","bytes_out":26,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":"","error":"code=400, message=Bad Request, err=json: cannot unmarshal string into Go struct field purchase.quantity of type int"}
{"time":"2026-10-16T19:44:26.659903952-03:00","level":"ERROR","msg":"REQUEST_ERROR","method":"DELETE","uri":"/events/1","status":405,"latency":29069,"host":"localhost:8080","bytes_in":"","bytes_out":33,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":"","error":"Method Not Allowed"}
{"time":"2026-10-16T19:44:26.676634416-03:00","level":"ERROR","msg":"REQUEST_ERROR","method":"GET","uri":"/nothing","status":404,"latency":23047,"host":"localhost:8080","bytes_in":"","bytes_out":24,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":"","error":"Not Found"}
```

O log é JSON, um objeto por linha, e a linha do 400 traz a história inteira em `error`:
`json: cannot unmarshal string into Go struct field purchase.quantity of type int`. **O Echo decidiu
que o texto de um erro de decodificação é para o operador, não para quem chamou**, o que é o padrão
cauteloso; a aula 3 decidiu o contrário para as próprias mensagens reescritas, porque elas não diziam
nada sobre o código. As duas posições se defendem; o que importa é que o framework fez a escolha e
você precisa saber qual.

O binário tem **11.094.543 bytes**, e `go list -m all` nomeia oito módulos além do seu, o menor
número dos quatro. O Echo mantém as dependências curtas de propósito, e muito do que ele não inclui,
como validação, fica com você.
