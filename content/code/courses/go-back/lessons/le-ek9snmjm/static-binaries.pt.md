---
title: Um arquivo, sem nada a procurar na execução
version: 1
---

Um programa ligado dinamicamente não contém todo o seu código. Parte dele mora em bibliotecas
compartilhadas na máquina, e quando o programa começa, o interpretador nomeado no seu cabeçalho, o loader
dinâmico, as encontra e as liga. O `ldd` lista o que um binário vai pedir:

```
ana@vm:~/boxoffice$ go env CGO_ENABLED; ldd dist/try-linux-amd64
1
	linux-vdso.so.1 (0x00007f0c60d45000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f0c60a00000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f0c60d47000)
```

**O `CGO_ENABLED` é 1**, então o cgo, a ponte do Go para o C, estava ligado no build nativo. O boxoffice
não tem código C próprio, mas dois pacotes da biblioteca padrão usam a biblioteca C quando o cgo está
disponível: o `net`, para resolver nomes do jeito que a biblioteca C do sistema resolve, e o `os/user`,
para procurar usuários. Então o binário pede a biblioteca C, `libc.so.6`, e o loader que a liga. Um build
cruzado desliga o cgo sozinho, já que não há compilador C para o alvo, e é por isso que o binário `arm64`
da seção 04 saiu estático.

Desligue-o também no build nativo:

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 go build -o dist/try-static . && file dist/try-static && ldd dist/try-static
dist/try-static: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=brHFb65M7IPel69O60F0/h8_CJ9KM6Hjo_CsgadlU/WCHBwM2-xcpdhM2-aY-W/XZeaOla_RjcYTJOdbYty, BuildID[sha1]=9cb3ba1ee765cfe91c556aeadafae0a1e73696ec, with debug_info, not stripped
	not a dynamic executable
```

**`statically linked`, e `not a dynamic executable`**: tudo de que o programa precisa está no arquivo. O
`net` e o `os/user` voltam às suas implementações em Go puro, que leem o `/etc/hosts`, o
`/etc/resolv.conf` e o `/etc/passwd` por conta própria. Para um servidor que pergunta nomes ao DNS e se
conecta a eles, a diferença não aparece; ela aparece em máquinas configuradas para resolver nomes por algo
que só a biblioteca C conhece, o que um container não é.

## Um build que vale entregar

Mais três flags fazem do binário uma versão de release:

- **`-trimpath`** tira do binário os caminhos da sua máquina. Sem ele, o stack trace de um pânico nomeia
  `/home/ana/boxoffice/events.go`; com ele, `example.com/boxoffice/events.go`, que é igual em toda
  máquina que o gera.
- **`-ldflags "-s -w"`** diz ao linker para deixar de fora a tabela de símbolos e a informação de
  depuração. Pânicos ainda imprimem os seus stack traces, que usam outras tabelas; o que sai é o que um
  depurador precisa.
- **`-ldflags "-X main.version=v0.16.0"`** define uma variável string na hora da ligação. Ela precisa de
  uma variável para definir, então o boxoffice ganha uma:

```go
// boxoffice/version.go
package main

// version is set when a release is built:
//
//	go build -ldflags "-X main.version=v0.16.0"
//
// A build without the flag says "dev", so no binary claims a version it is not.
var version = "dev"
```

O `main` a registra na sua primeira linha, ao lado da configuração:

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

	ctx := context.Background()
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
	go func() {
		log.Printf("grpc listening on %s", lis.Addr())
		if err := newGRPCServer(store).Serve(lis); err != nil {
			log.Fatalf("grpc: %v", err)
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
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

**O linker não reclama se o `-X` nomeia uma variável que não existe**; o build dá certo e o valor não vai a
lugar nenhum. Um `main.verison` digitado errado dá um binário que diz `dev` para sempre, e é por isso que o
padrão é uma palavra que ninguém confunde com uma versão.

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-amd64 . && ls -l dist/try-static dist/boxoffice-linux-amd64
-rwxr-xr-x 1 ana ana 17768608 Oct 22 20:01 dist/boxoffice-linux-amd64
-rwxr-xr-x 1 ana ana 25993843 Oct 22 20:01 dist/try-static
```

O build de release tem 17,8 MB contra 26,0 MB, um terço menor, sem nada que um servidor rodando use. O
binário também carrega como foi gerado, o que o `go version -m` lê de volta:

```
ana@vm:~/boxoffice$ go version -m dist/boxoffice-linux-amd64 | grep -e "^dist" -e build
dist/boxoffice-linux-amd64: go1.27.1
	build	-buildmode=exe
	build	-compiler=gc
	build	-trimpath=true
	build	CGO_ENABLED=0
	build	GOARCH=amd64
	build	GOOS=linux
	build	GOAMD64=v1
```

A versão do Go, e cada configuração que decide o que o build produz: `-trimpath`, `CGO_ENABLED=0`, o alvo.
O `go version -m` também lista cada módulo compilado junto, com a sua versão, que é o que um scanner de
vulnerabilidades lê de um binário quando o código não está à mão. E a string de versão chega aonde devia:

```
ana@vm:~/boxoffice$ DATABASE_URL=postgres:///nowhere?host=/nowhere BOXOFFICE_MANAGER_TOKEN=x ./dist/boxoffice-linux-amd64 2>&1 | head -1
{"time":"2026-10-22T20:01:14.62495058-03:00","level":"INFO","msg":"starting","version":"v0.16.0","config":{"http":"localhost:8080","grpc":"localhost:9090","max_conns":10,"write_timeout":"10s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
```

A primeira linha do log nomeia a versão, `v0.16.0`. O banco desse comando não existe, e a segunda linha,
cortada pelo `head`, é a falha ao alcançá-lo; a primeira já tinha dito qual build falhou.
