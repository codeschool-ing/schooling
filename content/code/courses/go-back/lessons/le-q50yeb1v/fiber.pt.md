---
title: Fiber
version: 1
---

As três primeiras versões desta API têm algo em comum que passa despercebido: **por baixo, todas são
`net/http`.** Os engines do Gin e do Echo são `http.Handler`s; um middleware padrão os envolve, um
`http.Server` os roda. O Fiber é a exceção. **Ele é construído sobre o `fasthttp`**, uma
implementação HTTP separada escrita para velocidade bruta, e sua API copia o Express, o framework do
Node.js, de propósito, para quem vem do JavaScript se sentir em casa. A versão aqui é a **v3.6.1**.

```go
// fw/fiber/main.go
package main

import (
	"log"
	"strconv"
	"sync"

	"github.com/gofiber/fiber/v3"
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
	app := fiber.New()
	app.Get("/events/:id", func(c fiber.Ctx) error {
		id, err := strconv.Atoi(c.Params("id"))
		if err != nil {
			return fiber.NewError(fiber.StatusBadRequest, "the event id must be a number")
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			return fiber.NewError(fiber.StatusNotFound, "no such event")
		}
		return c.JSON(e)
	})
	app.Post("/events/:id/tickets", func(c fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))
		var p purchase
		if err := c.Bind().JSON(&p); err != nil {
			return err
		}
		if p.Quantity < 1 || p.Quantity > 10 {
			return fiber.NewError(fiber.StatusUnprocessableEntity, "quantity must be between 1 and 10")
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			return fiber.NewError(fiber.StatusNotFound, "no such event")
		}
		if e.Seats-e.Sold < p.Quantity {
			return fiber.NewError(fiber.StatusConflict, "not enough seats left")
		}
		e.Sold += p.Quantity
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{"event_id": id, "remaining": e.Seats - e.Sold})
	})
	log.Fatal(app.Listen("localhost:8080"))
}
```

Ele se lê como o Echo: handlers devolvem um `error`, `fiber.NewError` carrega um status, e
`c.Status(201).JSON(...)` responde. `c.Bind().JSON(&p)` decodifica. O `Ctx` é um valor de interface
na v3, não um ponteiro.

## Compilando e perguntando

```
ana@vm:~/fw/fiber$ go mod tidy
go: finding module for package github.com/gofiber/fiber/v3
go: found github.com/gofiber/fiber/v3 in github.com/gofiber/fiber/v3 v3.6.1
ana@vm:~/fw/fiber$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 15285110 Oct 16 19:44 server
```

```
ana@vm:~/fw/fiber$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:44:32 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 56

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}ana@vm:~/fw/fiber$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}ana@vm:~/fw/fiber$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
quantity must be between 1 and 10ana@vm:~/fw/fiber$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
bind "quantity" from body: json: cannot unmarshal string into Go struct field purchase.quantity of type intana@vm:~/fw/fiber$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 405 Method Not Allowed
Date: Fri, 16 Oct 2026 22:44:32 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 18
Allow: GET, HEAD

Method Not Allowedana@vm:~/fw/fiber$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Date: Fri, 16 Oct 2026 22:44:32 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 9

Not Found
```

O sucesso e o evento são JSON. **Os erros são texto puro**, a mensagem e mais nada, porque o tratador
de erros padrão do Fiber escreve `err.Error()` como texto; uma API que quer erros em JSON instala o
próprio tratador no `fiber.Config`. O 405 é honesto e traz `Allow: GET, HEAD`, como o da biblioteca
padrão.

```
ana@vm:~/fw/fiber$ cat -v .server.log

    _______ __
   / ____(_) /_  ___  _____
  / /_  / / __ \/ _ \/ ___/
 / __/ / / /_/ /  __/ /
/_/   /_/_.___/\___/_/          v3.6.1
--------------------------------------------------
INFO Server started on: 	http://127.0.0.1:8080
INFO Total handlers: 		3
INFO Prefork: 			Disabled
INFO PID: 			23515
INFO Total process count: 	1
```

Um banner, o endereço e uma contagem de handlers. Nenhuma linha por requisição: o log do Fiber é um
middleware que você acrescenta.

## O que "não ser `net/http`" custa

O `fasthttp` ganha velocidade reaproveitando memória entre requisições, e isso vaza para as regras de
uso do Fiber. **Uma string lida de um `fiber.Ctx` pertence a um buffer que a próxima requisição
reaproveita**, então um valor guardado depois de o handler retornar, posto num mapa ou entregue a uma
goroutine, muda debaixo de você se não for copiado antes. A documentação do Fiber avisa disso, e tem
uma configuração que faz de todo valor uma cópia, ao custo de velocidade. E como um handler do Fiber
não é um `http.Handler`:

- **nenhum dos middlewares `net/http` do ecossistema Go encaixa diretamente**, os da aula 2
  incluídos; o Fiber traz um pacote adaptador para ligar os dois, e o próprio conjunto de middlewares;
- o `httptest`, que a aula 15 usa para testar handlers, não serve como está; o Fiber tem o `app.Test`
  no lugar;
- o `fasthttp` não fala HTTP/2, que o `net/http` fala sem ninguém pedir.

O binário tem **15.285.110 bytes**, com 25 módulos além do seu. **O Fiber é rápido**, e a velocidade
é real; a pergunta da aula 5 é se uma API que passa o tempo esperando um banco de dados chega a
perceber isso.
