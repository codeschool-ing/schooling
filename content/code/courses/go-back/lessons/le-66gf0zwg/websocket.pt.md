---
title: Um WebSocket do próprio boxoffice
version: 1
---

Um WebSocket começa como uma requisição HTTP e deixa de ser uma. O cliente manda um `GET` com
`Upgrade: websocket` e uma chave aleatória; o servidor concorda com o status **101 Switching Protocols**, e
dali em diante a mesma conexão TCP carrega frames de WebSocket nos dois sentidos, sem requisições e sem
respostas. Qualquer um dos lados manda uma mensagem a qualquer momento.

A biblioteca padrão do Go não tem servidor de WebSocket. O pacote `golang.org/x/net/websocket` existe, e
a própria documentação dele aponta outros dois como mais completos e mais bem mantidos:
**`github.com/gorilla/websocket`**, o mais antigo e mais usado, e **`github.com/coder/websocket`**, menor,
com toda chamada que bloqueia recebendo um contexto. O boxoffice usa o segundo, porque um contexto é o
jeito como todo o resto dele já para; a seção 06 encontra o primeiro, por baixo de uma biblioteca
construída sobre ele.

## O handler

```go
// boxoffice/ws.go
package main

import (
	"context"
	"net/http"
	"time"

	"github.com/coder/websocket"
	"github.com/coder/websocket/wsjson"
)

type availability struct {
	EventID   int `json:"event_id"`
	Available int `json:"available"`
}

// liveSocket sends an event's availability over a WebSocket, now and on every change.
func liveSocket(store Store, h *hub) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		ch, unsubscribe := h.subscribe(id) // before reading, so no sale falls between the two
		defer unsubscribe()
		e, err := store.Get(r.Context(), id)
		if err != nil {
			fail(w, err)
			return
		}
		c, err := websocket.Accept(w, r, &websocket.AcceptOptions{
			OriginPatterns: []string{"tickets.example.com"},
		})
		if err != nil {
			return // Accept has already answered the client
		}
		defer c.CloseNow()

		ctx := c.CloseRead(r.Context()) // nothing is read; a close from the client ends ctx
		send := func(n int) error {
			wctx, cancel := context.WithTimeout(ctx, 5*time.Second)
			defer cancel()
			return wsjson.Write(wctx, c, availability{EventID: id, Available: n})
		}
		if send(e.Seats-e.Sold) != nil {
			return
		}
		for {
			select {
			case <-ctx.Done():
				c.Close(websocket.StatusNormalClosure, "")
				return
			case n := <-ch:
				if send(n) != nil {
					return
				}
			}
		}
	}
}
```

Ele tem o formato do da seção 04, com três diferenças que são próprias dos WebSockets.

**`OriginPatterns` decide as páginas de quais sites podem se conectar.** Um navegador manda um cabeçalho
`Origin` em todo handshake de WebSocket, com o site cuja página o abriu, e aqui as regras de mesma origem
que protegem o `fetch` não valem: qualquer página de qualquer site abre um WebSocket para o boxoffice, e
se o boxoffice identificasse as pessoas por cookies, o navegador os anexaria. O middleware de CORS da seção
05 da aula 2 também não é consultado, já que o CORS rege o `fetch` e não isto. Então a verificação é do
servidor, e o `Accept` a faz: um `Origin` com o próprio host do servidor passa, um que bate com um padrão
da lista passa, e qualquer outro recebe 403. Uma requisição sem `Origin` nenhum passa, porque só
navegadores mandam um, e programas como o `curl` e o cliente da seção 05 não são de onde esse ataque vem.

**`CloseRead` continua lendo para que o protocolo continue funcionando.** O boxoffice não espera nada do
cliente, mas a conexão ainda precisa ser lida: um close ou um ping do cliente chega como um frame, e um
frame não lido é um frame sem resposta. O `CloseRead` lê numa goroutine própria, responde a esses frames
e devolve um contexto que termina quando a conexão fecha. Uma mensagem de dados vinda do cliente fecha a
conexão, porque nenhuma é esperada.

**Toda escrita tem cinco segundos.** Um cliente que para de ler deixa os buffers da conexão encherem, e
uma escrita depois disso esperaria para sempre. Com um prazo, a escrita falha, o handler retorna, e o
`CloseNow` e o `unsubscribe` adiados fazem a limpeza.

O que o handler não precisa é do `SetWriteDeadline` da seção 04. O `Accept` tira a conexão do net/http,
o que o net/http chama de hijack, e o net/http limpa os prazos da conexão ao entregá-la; dali em diante
eles são assunto do WebSocket. O `Accept` acha a conexão através do `statusRecorder` da aula 2 do mesmo
jeito que o `http.ResponseController` achou, chamando `Unwrap`.

## Um cliente para observar

O curl faz o handshake, mas não lê frames. Este cliente pequeno imprime toda mensagem que um WebSocket
envia durante um tempo, e antes manda os argumentos seguintes como mensagens de texto, o que as seções 06
e 07 vão usar:

```go
// boxoffice/cmd/watchws/main.go
package main

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"time"

	"github.com/coder/websocket"
)

// watchws prints what a WebSocket sends for a number of seconds.
func main() {
	limit, _ := time.ParseDuration(os.Args[2])
	ctx, cancel := context.WithTimeout(context.Background(), limit)
	defer cancel()
	c, resp, err := websocket.Dial(ctx, os.Args[1], nil)
	if err != nil {
		fmt.Println("error:", err)
		os.Exit(1)
	}
	defer c.CloseNow()
	fmt.Println("connected:", resp.Status)
	for _, msg := range os.Args[3:] {
		c.Write(ctx, websocket.MessageText, []byte(msg))
	}
	for {
		_, data, err := c.Read(ctx)
		if err != nil {
			fmt.Println("stopped:", ctx.Err())
			return
		}
		fmt.Printf("%s %s\n", time.Now().Format("15:04:05"), bytes.TrimSpace(data))
	}
}
```

## Ligando tudo

As duas rotas novas vão no `routes.go`, que agora recebe também o hub:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store Store, tokens map[string]string, live *hub) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	mux.HandleFunc("POST /events/{id}/tickets", buyTickets(store))
	mux.HandleFunc("GET /events/{id}/live", liveEvents(store, live))
	mux.HandleFunc("GET /events/{id}/ws", liveSocket(store, live))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	admin.HandleFunc("POST /admin/events", createEvent(store))
	mux.Handle("/admin/", requireStaff(tokens)(admin))

	return chain(mux, requestID, logRequests, recoverPanics, cors("https://tickets.example.com"))
}
```

E o `main.go` cria o hub e inicia o listener antes de começar a atender:

```go
// boxoffice/main.go
package main

import (
	"context"
	"log"
	"log/slog"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	slog.SetDefault(newLogger(os.Stdout))

	tokens := map[string]string{}
	for role, name := range map[string]string{
		"manager": "BOXOFFICE_MANAGER_TOKEN",
		"door":    "BOXOFFICE_DOOR_TOKEN",
	} {
		if t := os.Getenv(name); t != "" {
			tokens[t] = role
		}
	}
	if len(tokens) == 0 {
		log.Fatal("no staff tokens: set BOXOFFICE_MANAGER_TOKEN")
	}

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("no database: set DATABASE_URL")
	}
	ctx := context.Background()
	if err := migrate(ctx, url); err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg.MaxConns = 10
	cfg.MaxConnIdleTime = 5 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("database: %v", err)
	}
	store := &pgStore{pool: pool}
	live := newHub()
	go func() {
		if err := listen(ctx, pool, live); err != nil {
			slog.Error("listening for availability", "err", err)
		}
	}()

	lis, err := net.Listen("tcp", "localhost:9090")
	if err != nil {
		log.Fatalf("grpc: %v", err)
	}
	go func() {
		log.Printf("grpc listening on %s", lis.Addr())
		if err := newGRPCServer(store).Serve(lis); err != nil {
			log.Fatalf("grpc: %v", err)
		}
	}()

	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(store, tokens, live),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

Se o `listen` falha, o erro vai para o log e o servidor continua respondendo, com páginas ao vivo que não
mudam mais. É uma troca deliberada por enquanto, e a seção 08 volta a ela.

## O handshake, à mão

O `curl` manda os quatro cabeçalhos de que um handshake precisa. A chave abaixo é o exemplo da RFC 6455, a
especificação do WebSocket, e a resposta é a que a RFC imprime: o servidor calcula o hash da chave junto
com uma string fixa e o devolve, o que prova que o servidor entendeu que a requisição era um WebSocket.

```
ana@vm:~/boxoffice$ curl -s -D - -o /dev/null -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -m 2 localhost:8080/events/1/ws
HTTP/1.1 101 Switching Protocols
Connection: Upgrade
Sec-Websocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
Upgrade: websocket
Vary: Origin
X-Request-Id: c5f5c495ac74eb8e
Date: Thu, 22 Oct 2026 22:35:50 GMT

```

A mesma requisição com um `Origin` de outro site é recusada antes de qualquer upgrade, com o motivo no
corpo:

```
ana@vm:~/boxoffice$ curl -si -H "Origin: https://elsewhere.example.net" -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -m 2 localhost:8080/events/1/ws
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
Vary: Origin
X-Content-Type-Options: nosniff
X-Request-Id: 0127182e3c8046a8
Date: Thu, 22 Oct 2026 22:35:52 GMT
Content-Length: 83

request Origin "elsewhere.example.net" is not authorized for Host "localhost:8080"
```

E o cliente vê a disponibilidade ao se conectar, e depois uma compra de dois lugares feita enquanto ele
observava:

```
ana@vm:~/boxoffice$ ./watchws ws://localhost:8080/events/1/ws 3s
connected: 101 Switching Protocols
19:35:52 {"event_id":1,"available":114}
19:35:53 {"event_id":1,"available":112}
stopped: context deadline exceeded
```

As três requisições, e o fluxo da seção 04, estão no log de acesso, com status 101 para os upgrades e uma
duração que é o tempo em que a conexão ficou aberta:

```
ana@vm:~/boxoffice$ grep -e /live -e /ws .server.log
{"time":"2026-10-22T19:35:49.505524262-03:00","level":"INFO","msg":"request","request_id":"08468f766a8feb95","method":"GET","path":"/events/1/live","status":200,"bytes":33,"duration_ms":13996.947}
{"time":"2026-10-22T19:35:52.576858836-03:00","level":"INFO","msg":"request","request_id":"c5f5c495ac74eb8e","method":"GET","path":"/events/1/ws","status":101,"bytes":0,"duration_ms":2002.501}
{"time":"2026-10-22T19:35:52.597473794-03:00","level":"INFO","msg":"request","request_id":"0127182e3c8046a8","method":"GET","path":"/events/1/ws","status":403,"bytes":83,"duration_ms":0.531}
{"time":"2026-10-22T19:35:55.614706057-03:00","level":"INFO","msg":"request","request_id":"96819eed763c7dac","method":"GET","path":"/events/1/ws","status":101,"bytes":0,"duration_ms":3001.872}
```
