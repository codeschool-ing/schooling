---
title: Gin
version: 1
---

**O Gin é o framework web de Go mais conhecido**, com mais estrelas no GitHub que qualquer outro, e o
formato dele é aquele a que os outros reagem. Seus handlers recebem um único argumento, um
`*gin.Context`, que carrega a requisição, a resposta, os parâmetros da rota e um conjunto de
utilitários. Eis a API de referência escrita para ele:

```go
// fw/gin/main.go
package main

import (
	"net/http"
	"strconv"
	"sync"

	"github.com/gin-gonic/gin"
)

type event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

type purchase struct {
	Quantity int    `json:"quantity" binding:"required,min=1,max=10"`
	Email    string `json:"email" binding:"required,email"`
}

var (
	mu     sync.Mutex
	events = map[int]*event{1: {ID: 1, Name: "Jazz at the Docks", Seats: 120}}
)

func main() {
	r := gin.Default()
	r.GET("/events/:id", func(c *gin.Context) {
		id, err := strconv.Atoi(c.Param("id"))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "the event id must be a number"})
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			c.JSON(http.StatusNotFound, gin.H{"error": "no such event"})
			return
		}
		c.JSON(http.StatusOK, e)
	})
	r.POST("/events/:id/tickets", func(c *gin.Context) {
		id, _ := strconv.Atoi(c.Param("id"))
		var p purchase
		if err := c.ShouldBindJSON(&p); err != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			c.JSON(http.StatusNotFound, gin.H{"error": "no such event"})
			return
		}
		if e.Seats-e.Sold < p.Quantity {
			c.JSON(http.StatusConflict, gin.H{"error": "not enough seats left"})
			return
		}
		e.Sold += p.Quantity
		c.JSON(http.StatusCreated, gin.H{"event_id": id, "remaining": e.Seats - e.Sold})
	})
	r.Run("localhost:8080")
}
```

O que mudou em relação à versão padrão:

- **`gin.Default()`** monta o roteador com dois middlewares já acoplados, um log e uma recuperação
  de pânico, os dois que a aula 2 escreveu à mão.
- **`:id` no padrão** e `c.Param("id")` para lê-lo, a grafia do httprouter.
- **`c.JSON(status, value)`** define o tipo, o status e o corpo numa chamada só. `gin.H` é um
  `map[string]any` com nome mais curto.
- **`binding:"required,min=1,max=10"`** na struct, e `c.ShouldBindJSON(&p)` ao mesmo tempo decodifica
  o corpo e confere essas regras, usando a biblioteca `go-playground/validator` que a seção 04 da
  aula 3 citou. A verificação de quantidade deixou de ser código no handler.

## Compilando

```
ana@vm:~/fw/gin$ go mod tidy
go: finding module for package github.com/gin-gonic/gin
go: found github.com/gin-gonic/gin in github.com/gin-gonic/gin v1.12.0
ana@vm:~/fw/gin$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 31606863 Oct 16 19:44 server
```

O `go mod tidy` leu o import, achou a versão mais recente do Gin, **v1.12.0**, e escreveu ela e tudo
de que ela precisa no `go.mod` e no `go.sum`. O binário tem **31.606.863 bytes**; a versão da
biblioteca padrão tinha 9.807.673. A seção 07 conta o que compõe a diferença.

## Perguntando

```
ana@vm:~/fw/gin$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Date: Fri, 16 Oct 2026 22:44:21 GMT
Content-Length: 56

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}ana@vm:~/fw/gin$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}ana@vm:~/fw/gin$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"error":"Key: 'purchase.Quantity' Error:Field validation for 'Quantity' failed on the 'max' tag\nKey: 'purchase.Email' Error:Field validation for 'Email' failed on the 'email' tag"}ana@vm:~/fw/gin$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"error":"json: cannot unmarshal string into Go struct field purchase.quantity of type int"}ana@vm:~/fw/gin$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 404 Not Found
Content-Type: text/plain
Date: Fri, 16 Oct 2026 22:44:21 GMT
Content-Length: 18

404 page not foundana@vm:~/fw/gin$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: text/plain
Date: Fri, 16 Oct 2026 22:44:21 GMT
Content-Length: 18

404 page not found
```

O prompt cai na mesma linha de cada corpo porque **o Gin escreve JSON sem quebra de linha final**, o
que só importa a quem lê o `curl`. Três respostas importam mais:

- **A mensagem de validação é a da biblioteca, palavra por palavra**: `Key: 'purchase.Quantity'
  Error:Field validation for 'Quantity' failed on the 'max' tag`. Ela nomeia campos da struct Go e
  nomes de tag, não as chaves JSON que o cliente mandou. O Gin te dá as regras de graça e deixa a
  mensagem com você; uma API de verdade traduziria esses erros para algo como o mapa `errors` da
  aula 3.
- **`DELETE /events/1` recebeu 404, não 405.** O roteador do Gin sabe responder 405, e não o faz por
  padrão: a configuração `HandleMethodNotAllowed` fica desligada até você ligá-la. Um cliente que
  manda o método errado ouve que o evento não existe.
- O tipo errado recebeu a mensagem do próprio `encoding/json`, porque o Gin decodifica com ele.

## O que ele disse ao subir

```
ana@vm:~/fw/gin$ cat -v .server.log
[GIN-debug] [WARNING] Creating an Engine instance with the Logger and Recovery middleware already attached.

[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:	export GIN_MODE=release
 - using code:	gin.SetMode(gin.ReleaseMode)

[GIN-debug] GET    /events/:id               --> main.main.func1 (3 handlers)
[GIN-debug] POST   /events/:id/tickets       --> main.main.func2 (3 handlers)
[GIN-debug] [WARNING] You trusted all proxies, this is NOT safe. We recommend you to set a value.
Please check https://github.com/gin-gonic/gin/blob/master/docs/doc.md#dont-trust-all-proxies for details.
[GIN-debug] Listening and serving HTTP on localhost:8080
[GIN] 2026/10/16 - 19:44:21 | 200 | 75.499M-BM-5s |       127.0.0.1 | GET      "/events/1"
[GIN] 2026/10/16 - 19:44:21 | 201 | 291.122M-BM-5s |       127.0.0.1 | POST     "/events/1/tickets"
[GIN] 2026/10/16 - 19:44:21 | 422 | 87.433M-BM-5s |       127.0.0.1 | POST     "/events/1/tickets"
[GIN] 2026/10/16 - 19:44:21 | 422 | 56.053M-BM-5s |       127.0.0.1 | POST     "/events/1/tickets"
[GIN] 2026/10/16 - 19:44:21 | 404 |    398ns |       127.0.0.1 | DELETE   "/events/1"
[GIN] 2026/10/16 - 19:44:21 | 404 |    422ns |       127.0.0.1 | GET      "/nothing"
```

**Leia os avisos, porque cada um é uma decisão que o Gin tomou por você.** O modo debug imprime as
rotas e estas notas; `GIN_MODE=release` as cala. O aviso sobre proxies é questão de segurança: por
padrão, `c.ClientIP()` acredita no cabeçalho `X-Forwarded-For` de qualquer um, então qualquer
cliente se diz de qualquer endereço, e um limite de taxa ou um log de auditoria baseado nele é
enganado. `SetTrustedProxies` nomeia os proxies cuja palavra vale.

Mais uma coisa não aparece no log. **`r.Run` inicia o servidor com `http.ListenAndServe`**, que a
seção 08 da aula 1 mostrou não ter timeout nenhum. Um engine do Gin é um `http.Handler`, então o
conserto é o que o boxoffice já usa: monte um `http.Server` com os quatro prazos, ponha o engine no
campo `Handler` dele e nunca chame `Run`.
