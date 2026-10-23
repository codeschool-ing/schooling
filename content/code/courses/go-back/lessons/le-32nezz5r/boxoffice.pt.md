---
title: O boxoffice, pronto
version: 1
---

Duas configurações entram na configuração da aula 14, o endereço de ops e o timeout de desligamento:

```go
// boxoffice/config.go
package main

import (
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net/url"
	"os"
	"strings"
	"time"
)

// config is everything boxoffice reads from outside. Each setting has a
// default, a BOXOFFICE_* variable that overrides it, and a flag that
// overrides both. Secrets have no flag.
type config struct {
	HTTPAddr        string
	GRPCAddr        string
	OpsAddr         string
	MaxConns        int
	WriteTimeout    time.Duration
	ShutdownTimeout time.Duration
	Origin          string
	DatabaseURL     secret
	Tokens          map[string]string // token → role
}

// secret is a string that does not show itself in a log or a Printf.
type secret string

func (secret) LogValue() slog.Value { return slog.StringValue("[hidden]") }
func (secret) String() string       { return "[hidden]" }

func load(args []string, getenv func(string) string) (config, error) {
	c := config{Tokens: map[string]string{}}
	fs := flag.NewFlagSet("boxoffice", flag.ContinueOnError)
	fs.StringVar(&c.HTTPAddr, "http", "localhost:8080", "`address` the HTTP API listens on")
	fs.StringVar(&c.GRPCAddr, "grpc", "localhost:9090", "`address` the gRPC service listens on")
	fs.StringVar(&c.OpsAddr, "ops", "localhost:9100", "`address` for health checks and metrics, never public")
	fs.IntVar(&c.MaxConns, "max-conns", 10, "most database connections open at once")
	fs.DurationVar(&c.WriteTimeout, "write-timeout", 10*time.Second, "longest an ordinary response may take to write")
	fs.DurationVar(&c.ShutdownTimeout, "shutdown-timeout", 8*time.Second, "longest to wait for requests in flight when stopping")
	fs.StringVar(&c.Origin, "origin", "https://tickets.example.com", "the `site` whose pages may call the API")

	var errs []error
	fs.VisitAll(func(f *flag.Flag) {
		name := "BOXOFFICE_" + strings.ToUpper(strings.ReplaceAll(f.Name, "-", "_"))
		f.Usage += " ($" + name + ")"
		if v := getenv(name); v != "" {
			if err := fs.Set(f.Name, v); err != nil {
				errs = append(errs, fmt.Errorf("%s=%q: %w", name, v, err))
			}
		}
	})
	if err := fs.Parse(args); err != nil {
		return c, errors.Join(append(errs, err)...)
	}

	// A slice, not a map, so the roles are read in the same order every time.
	for _, s := range []struct{ name, role string }{
		{"BOXOFFICE_MANAGER_TOKEN", "manager"},
		{"BOXOFFICE_DOOR_TOKEN", "door"},
	} {
		t, err := secretFrom(getenv, s.name)
		switch {
		case err != nil:
			errs = append(errs, err)
		case t == "":
		case c.Tokens[string(t)] != "":
			errs = append(errs, fmt.Errorf("%s: the same token as the %s's", s.name, c.Tokens[string(t)]))
		default:
			c.Tokens[string(t)] = s.role
		}
	}
	dbURL, err := secretFrom(getenv, "DATABASE_URL")
	if err != nil {
		errs = append(errs, err)
	}
	c.DatabaseURL = dbURL

	if c.DatabaseURL == "" && err == nil {
		errs = append(errs, errors.New("DATABASE_URL: not set"))
	}
	if len(c.Tokens) == 0 {
		errs = append(errs, errors.New("BOXOFFICE_MANAGER_TOKEN: not set, so no staff could sign in"))
	}
	if c.MaxConns < 2 {
		errs = append(errs, fmt.Errorf("max-conns %d: at least 2 are needed, one for LISTEN and one for queries", c.MaxConns))
	} else if c.MaxConns > 100 {
		errs = append(errs, fmt.Errorf("max-conns %d: PostgreSQL accepts 100 connections unless it is told otherwise", c.MaxConns))
	}
	if u, err := url.Parse(c.Origin); err != nil || (u.Scheme != "https" && u.Scheme != "http") || u.Host == "" {
		errs = append(errs, fmt.Errorf("origin %q: want a site such as https://tickets.example.com", c.Origin))
	}
	return c, errors.Join(errs...)
}

// secretFrom reads a secret from the variable name, or from the file that
// name_FILE points to, which is how container platforms hand secrets over.
func secretFrom(getenv func(string) string, name string) (secret, error) {
	if path := getenv(name + "_FILE"); path != "" {
		b, err := os.ReadFile(path)
		if err != nil {
			return "", fmt.Errorf("%s_FILE: %w", name, err)
		}
		return secret(strings.TrimSpace(string(b))), nil
	}
	return secret(getenv(name)), nil
}

// LogValue is the configuration as a log shows it, secrets hidden.
func (c config) LogValue() slog.Value {
	return slog.GroupValue(
		slog.String("http", c.HTTPAddr),
		slog.String("grpc", c.GRPCAddr),
		slog.String("ops", c.OpsAddr),
		slog.Int("max_conns", c.MaxConns),
		slog.String("write_timeout", c.WriteTimeout.String()),
		slog.String("shutdown_timeout", c.ShutdownTimeout.String()),
		slog.String("origin", c.Origin),
		slog.Any("database_url", c.DatabaseURL),
		slog.Int("staff_tokens", len(c.Tokens)),
	)
}
```

E o `main` junta a aula: o contexto do sinal, o listener de ops com `/healthz`, `/readyz` e `/metrics`, o
`RegisterOnShutdown` para os streams, e a sequência de desligamento da seção 06 no fim:

```go
// boxoffice/main.go
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	slog.SetDefault(newLogger(os.Stdout))

	cfg, err := load(os.Args[1:], os.Getenv)
	if errors.Is(err, flag.ErrHelp) {
		return
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "boxoffice: %v\n", err)
		os.Exit(2)
	}
	slog.Info("starting", "version", version, "config", cfg)

	// ctx ends at the first SIGINT or SIGTERM; a second one kills the process.
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	if err := migrate(ctx, string(cfg.DatabaseURL)); err != nil {
		log.Fatalf("database: %v", err)
	}
	pcfg, err := pgxpool.ParseConfig(string(cfg.DatabaseURL))
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	pcfg.MaxConns = int32(cfg.MaxConns)
	pcfg.MaxConnIdleTime = 5 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, pcfg)
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

	lis, err := net.Listen("tcp", cfg.GRPCAddr)
	if err != nil {
		log.Fatalf("grpc: %v", err)
	}
	grpcSrv := newGRPCServer(store)
	go func() {
		log.Printf("grpc listening on %s", lis.Addr())
		if err := grpcSrv.Serve(lis); err != nil {
			log.Fatalf("grpc: %v", err)
		}
	}()

	hc := &health{pool: pool}
	ops := http.NewServeMux()
	ops.HandleFunc("GET /healthz", hc.live)
	ops.HandleFunc("GET /readyz", hc.ready)
	ops.Handle("GET /metrics", metricsHandler(pool, live))
	opsSrv := &http.Server{Addr: cfg.OpsAddr, Handler: ops, ReadHeaderTimeout: 2 * time.Second}
	go func() {
		if err := opsSrv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("ops: %v", err)
		}
	}()

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           routes(store, cfg, live),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      cfg.WriteTimeout,
		IdleTimeout:       60 * time.Second,
	}
	srv.RegisterOnShutdown(live.close) // streams never finish by themselves
	go func() {
		log.Printf("boxoffice listening on %s", srv.Addr)
		if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("http: %v", err)
		}
	}()

	<-ctx.Done()
	stop()
	slog.Info("shutting down", "timeout", cfg.ShutdownTimeout.String())
	hc.draining.Store(true)
	sctx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(sctx); err != nil {
		slog.Error("http shutdown", "err", err)
	}
	done := make(chan struct{})
	go func() {
		grpcSrv.GracefulStop() // waits for calls in flight, Watch streams included
		close(done)
	}()
	select {
	case <-done:
	case <-sctx.Done():
		grpcSrv.Stop()
	}
	if err := opsSrv.Shutdown(sctx); err != nil {
		slog.Error("ops shutdown", "err", err)
	}
	slog.Info("stopped")
}
```

Os servidores agora rodam em goroutines e o `main` espera o sinal em vez do `ListenAndServe`, então o
`ErrServerClosed` do `ListenAndServe`, que ele devolve quando o `Shutdown` é chamado, é esperado e não
fatal. **O `GracefulStop` espera as chamadas gRPC em andamento, e os streams `Watch` da aula 10 nunca
terminam sozinhos**, então ele roda numa goroutine, e o `Stop`, que os corta, assume quando o prazo passa.

A imagem precisa que a porta de ops escute em todas as interfaces, como as outras duas:

```dockerfile
# boxoffice/Dockerfile
FROM gcr.io/distroless/static-debian12:nonroot
ARG TARGETARCH
COPY dist/boxoffice-linux-${TARGETARCH} /boxoffice
ENV BOXOFFICE_HTTP=:8080 BOXOFFICE_GRPC=:9090 BOXOFFICE_OPS=:9100
EXPOSE 8080 9090 9100
ENTRYPOINT ["/boxoffice"]
```

## No container

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=v0.17.0" -o dist/boxoffice-linux-amd64 . && docker build -q -t boxoffice:v0.17.0 .
sha256:ad825502590175387f78927c67203af1a697a48e9033d6eea0d74a595e8e55df
ana@vm:~$ docker run -d --name boxoffice -p 8080:8080 -p 9100:9100 --user "$(id -u):$(id -g)" -v /var/run/postgresql:/var/run/postgresql -v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro -e BOXOFFICE_MANAGER_TOKEN_FILE=/run/secrets/manager-token -e DATABASE_URL="postgres://$USER@/boxoffice?host=/var/run/postgresql" -e TZ=America/Sao_Paulo boxoffice:v0.17.0
f5812f9dce35a1cf5895d99f08deac38523a5e95d1e243ceb749a9a671760cb4
```

```
ana@vm:~$ curl -s localhost:9100/readyz; curl -s localhost:9100/healthz
{"status":"ready"}
{"status":"ok","version":"v0.17.0"}
ana@vm:~$ time docker stop boxoffice
boxoffice

real	0m0.257s
user	0m0.020s
sys	0m0.005s
```

**Pronto, vivo, e com a versão que o `-X` carimbou.** As duas portas foram publicadas aqui para que o
`curl` na máquina do laboratório as alcance; num servidor, a porta de operação é publicada só para a rede
interna, ou presa ao `127.0.0.1` com `-p 127.0.0.1:9100:9100`, que é o que a seção 02 quer dizer com nunca
publicada na internet. O `docker stop` leva um quarto de segundo, e desta vez é porque não havia nada a
esperar; o log diz isso:

```
ana@vm:~$ docker logs boxoffice | tail -2
{"time":"2026-10-22T20:13:04.078366225-03:00","level":"INFO","msg":"shutting down","timeout":"8s"}
{"time":"2026-10-22T20:13:04.078575767-03:00","level":"INFO","msg":"stopped"}
```

`shutting down` e `stopped`, nessa ordem. Com uma requisição em andamento, a segunda linha teria esperado
por ela, como na seção 06.

## Numa plataforma

O Kubernetes, o lugar mais comum onde um serviço como este vai parar, recebe as duas verificações como
probes na definição do container. Esta é a parte relevante de uma, não executada neste curso:

```yaml
containers:
  - name: boxoffice
    image: registry.example.com/boxoffice:v0.17.0
    ports:
      - containerPort: 8080
      - containerPort: 9100
    livenessProbe:
      httpGet: { path: /healthz, port: 9100 }
      periodSeconds: 10
      failureThreshold: 3
    readinessProbe:
      httpGet: { path: /readyz, port: 9100 }
      periodSeconds: 5
terminationGracePeriodSeconds: 30
```

Liveness a cada dez segundos, e três falhas seguidas antes de um reinício, para uma resposta lenta não
matar o pod; readiness a cada cinco. O `terminationGracePeriodSeconds` fica no pod, não no container, e
trinta segundos dão folga de sobra aos oito do boxoffice.

## O que o boxoffice é agora

Dezessete aulas atrás, o boxoffice era alguns handlers sobre dois eventos guardados em memória. Agora ele
valida o que recebe e responde erros num formato padrão. Guarda os dados no PostgreSQL por meio de consultas
geradas e verificadas e de migrações numeradas, e oferece os mesmos dados por gRPC. Empurra mudanças para
páginas abertas e registra log em JSON, com um request id em cada linha. Lê a configuração de flags,
variáveis e arquivos, e recusa uma ruim antes de abrir uma porta. É testado em três distâncias, detector de
corrida incluído. Sai como um arquivo estático numa imagem de sete megabytes, e diz à plataforma em volta
quando está vivo, quando está pronto, o que está fazendo e quando está saindo. **Quase tudo é a
biblioteca padrão**, que era o argumento da aula 5. O que não é, pgx, sqlc, goose, gRPC, uma biblioteca de
WebSocket e um cliente de Prometheus, chegou porque a biblioteca padrão não tem resposta para aquele
trabalho específico.
