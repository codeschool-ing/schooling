---
title: Os logs do boxoffice, estruturados
version: 1
---

O boxoffice passa para o slog em três passos: um logger para o processo inteiro, um id de requisição com
um logger para cada requisição, e o log de acesso da aula 2 reescrito como campos.

```go
// boxoffice/logging.go
package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"io"
	"log/slog"
	"net/http"
)

// newLogger writes JSON lines, one object per event, to w.
func newLogger(w io.Writer) *slog.Logger {
	return slog.New(slog.NewJSONHandler(w, nil))
}

type loggerKey struct{}

// logger is the request's own logger, or the default one outside a request.
func logger(ctx context.Context) *slog.Logger {
	if l, ok := ctx.Value(loggerKey{}).(*slog.Logger); ok {
		return l
	}
	return slog.Default()
}

// requestID gives every request an id, sends it back in X-Request-ID, and
// puts a logger carrying it into the request's context.
func requestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b := make([]byte, 8)
		rand.Read(b)
		id := hex.EncodeToString(b)
		w.Header().Set("X-Request-ID", id)
		l := slog.Default().With("request_id", id)
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), loggerKey{}, l)))
	})
}
```

- **`newLogger`** é um handler JSON sobre o writer que recebe; o `main` lhe dá a saída padrão, onde uma
  plataforma de containers, na aula 16, coleta tudo o que um programa imprime.
- **`requestID`** é um middleware novo. Ele transforma oito bytes aleatórios num id de 16 caracteres, manda
  esse id ao cliente em `X-Request-ID` e guarda no contexto um logger que o carrega. Um cliente que relata
  um problema com esse id deixa um operador encontrar toda linha daquela requisição.
- **`logger(ctx)`** devolve o logger da requisição, ou o padrão do processo quando não há requisição, então
  qualquer código com um contexto pode registrar com o id da requisição anexado.

O log de acesso mantém o formato da aula 2 e muda o que escreve:

```go
// boxoffice/middleware.go
package main

import (
	"log/slog"
	"net/http"
	"slices"
	"time"
)

// chain wraps h in the middlewares given, the first one outermost.
func chain(h http.Handler, mws ...func(http.Handler) http.Handler) http.Handler {
	for _, mw := range slices.Backward(mws) {
		h = mw(h)
	}
	return h
}

// statusRecorder remembers the status and the size of what a handler wrote.
type statusRecorder struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (s *statusRecorder) WriteHeader(code int) {
	if s.status == 0 {
		s.status = code
	}
	s.ResponseWriter.WriteHeader(code)
}

func (s *statusRecorder) Write(b []byte) (int, error) {
	if s.status == 0 {
		s.status = http.StatusOK
	}
	n, err := s.ResponseWriter.Write(b)
	s.bytes += n
	return n, err
}

// Unwrap lets http.ResponseController reach the writer underneath.
func (s *statusRecorder) Unwrap() http.ResponseWriter {
	return s.ResponseWriter
}

func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w}
		next.ServeHTTP(rec, r)
		if rec.status == 0 {
			rec.status = http.StatusOK
		}
		level := slog.LevelInfo
		if rec.status >= 500 {
			level = slog.LevelError
		}
		logger(r.Context()).Log(r.Context(), level, "request",
			"method", r.Method,
			"path", r.URL.Path,
			"status", rec.status,
			"bytes", rec.bytes,
			"duration_ms", float64(time.Since(start).Microseconds())/1000,
		)
	})
}
```

**Uma mensagem constante, `"request"`, e as partes variáveis em campos.** Uma resposta 500 ou acima é
registrada como `ERROR`, todo o resto como `INFO`, então "mostre os erros" é um filtro em `level`. A duração
é um número de milissegundos, sempre, com três casas decimais.

O `requestID` precisa rodar antes do `logRequests`, então vai primeiro na cadeia:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store Store, tokens map[string]string) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	mux.HandleFunc("POST /events/{id}/tickets", buyTickets(store))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	admin.HandleFunc("POST /admin/events", createEvent(store))
	mux.Handle("/admin/", requireStaff(tokens)(admin))

	return chain(mux, requestID, logRequests, recoverPanics, cors("https://tickets.example.com"))
}
```

E o `main` torna o logger JSON o padrão antes de qualquer outra coisa acontecer:

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
		Handler:           routes(store, tokens),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

**O `slog.SetDefault` também redireciona o velho pacote `log`.** Todo `log.Printf` que sobrou no boxoffice, no
`fail`, no `recoverPanics`, no interceptor gRPC, no próprio `main`, agora sai como uma linha JSON com o texto
como mensagem. Isso é uma ponte e não um fim: essas linhas não têm campos nem id de requisição, e
convertê-las uma a uma para `logger(ctx).Error(...)` é o resto do trabalho.

## O que ele escreve

```
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json
Vary: Origin
X-Request-Id: 24c08efa258fe0dd
Date: Thu, 22 Oct 2026 22:20:34 GMT
Content-Length: 73

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/2/tickets
{"type":"about:blank","title":"Conflict","status":409,"detail":"event 2: not enough seats left"}
ana@vm:~/boxoffice$ curl -s localhost:8080/events/9
{"type":"about:blank","title":"Not Found","status":404,"detail":"event 9: no such event"}
ana@vm:~/boxoffice$ go run ./cmd/seats get 1
1 Jazz at the Docks: 0 of 120 sold
```

**A resposta traz `X-Request-Id`**: nomes de cabeçalho não diferenciam maiúsculas, e o Go os escreve nessa
forma. O log do servidor:

```
ana@vm:~/boxoffice$ cat .server.log
{"time":"2026-10-22T19:20:33.919517197-03:00","level":"INFO","msg":"boxoffice listening on localhost:8080"}
{"time":"2026-10-22T19:20:33.919646505-03:00","level":"INFO","msg":"grpc listening on 127.0.0.1:9090"}
{"time":"2026-10-22T19:20:34.135077884-03:00","level":"INFO","msg":"request","request_id":"24c08efa258fe0dd","method":"GET","path":"/events/1","status":200,"bytes":73,"duration_ms":1.775}
{"time":"2026-10-22T19:20:34.155486245-03:00","level":"INFO","msg":"request","request_id":"0329f53ae45a1fdd","method":"POST","path":"/events/2/tickets","status":409,"bytes":97,"duration_ms":1.828}
{"time":"2026-10-22T19:20:34.174057337-03:00","level":"INFO","msg":"request","request_id":"44deb15d6639f7b7","method":"GET","path":"/events/9","status":404,"bytes":90,"duration_ms":0.277}
{"time":"2026-10-22T19:20:34.332776729-03:00","level":"INFO","msg":"grpc /boxoffice.v1.Seats/GetEvent OK 2.712ms"}
ana@vm:~/boxoffice$ grep "\"status\":409" .server.log
{"time":"2026-10-22T19:20:34.155486245-03:00","level":"INFO","msg":"request","request_id":"0329f53ae45a1fdd","method":"POST","path":"/events/2/tickets","status":409,"bytes":97,"duration_ms":1.828}
ana@vm:~/boxoffice$ python3 -c "import json,sys; [print(json.loads(l)[\"path\"], json.loads(l)[\"status\"]) for l in open(\".server.log\") if \"\\\"msg\\\":\\\"request\\\"\" in l]"
/events/1 200
/events/2/tickets 409
/events/9 404
```

As duas primeiras linhas e a linha gRPC são as velhas chamadas `log.Printf` passando pelo `SetDefault`, com a
mensagem guardando o texto inteiro. As três linhas de requisição são campos de ponta a ponta, cada uma com o
próprio id, e **achar o conflito é um `grep` por um campo em vez de um palpite sobre uma coluna**. O último
comando lê o arquivo como JSON, o que qualquer linguagem faz, e imprime dois campos de cada requisição; uma
plataforma de logs faz o mesmo em escala.
