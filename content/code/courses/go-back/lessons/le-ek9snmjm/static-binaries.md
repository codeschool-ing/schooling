---
title: One file, with nothing to find at run time
version: 1
---

A dynamically linked program does not contain all of its code. Some of it lives in shared libraries on the
machine, and when the program starts, the interpreter named in its header, the dynamic loader, finds them
and links them in. `ldd` lists what a binary will ask for:

```
ana@vm:~/boxoffice$ go env CGO_ENABLED; ldd dist/try-linux-amd64
1
	linux-vdso.so.1 (0x00007f0c60d45000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f0c60a00000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f0c60d47000)
```

**`CGO_ENABLED` is 1**, so cgo, Go's bridge to C, was on for the native build. boxoffice has no C code of
its own, but two packages of the standard library use the C library when cgo is available: `net`, to
resolve names the way the system's C library does, and `os/user`, to look up users. So the binary asks for
the C library, `libc.so.6`, and the loader that links it. A cross-compiled build turns cgo off by itself,
since there is no C compiler for the target, which is why section 04's `arm64` binary came out static.

Turn it off for the native build too:

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 go build -o dist/try-static . && file dist/try-static && ldd dist/try-static
dist/try-static: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=brHFb65M7IPel69O60F0/h8_CJ9KM6Hjo_CsgadlU/WCHBwM2-xcpdhM2-aY-W/XZeaOla_RjcYTJOdbYty, BuildID[sha1]=9cb3ba1ee765cfe91c556aeadafae0a1e73696ec, with debug_info, not stripped
	not a dynamic executable
```

**`statically linked`, and `not a dynamic executable`**: everything the program needs is in the file.
`net` and `os/user` fall back to their pure-Go implementations, which read `/etc/hosts`,
`/etc/resolv.conf` and `/etc/passwd` themselves. For a server that asks DNS for names and connects to
them, the difference does not show; it shows on machines configured to resolve names through something
only the C library knows about, which a container is not.

## A build worth shipping

Three more flags make the binary a release:

- **`-trimpath`** removes the paths of your machine from the binary. Without it, a panic's stack trace
  names `/home/ana/boxoffice/events.go`; with it, `example.com/boxoffice/events.go`, which is the same on
  every machine that builds it.
- **`-ldflags "-s -w"`** tells the linker to leave out the symbol table and the debugging information.
  Panics still print their stack traces, which use other tables; what goes is what a debugger needs.
- **`-ldflags "-X main.version=v0.16.0"`** sets a string variable at link time. It needs a variable to
  set, so boxoffice gets one:

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

`main` logs it in its first line, beside the configuration:

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

**The linker does not complain if `-X` names a variable that does not exist**; the build succeeds and the
value goes nowhere. A misspelt `main.verison` gives a binary that says `dev` forever, which is why the
default is a word that cannot be mistaken for a release.

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-amd64 . && ls -l dist/try-static dist/boxoffice-linux-amd64
-rwxr-xr-x 1 ana ana 17768608 Oct 22 20:01 dist/boxoffice-linux-amd64
-rwxr-xr-x 1 ana ana 25993843 Oct 22 20:01 dist/try-static
```

The release build is 17.8 MB against 26.0 MB, a third smaller, with nothing a running server uses
removed. The binary also carries how it was built, which `go version -m` reads back:

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

The Go version, and every setting that decides what the build produces: `-trimpath`, `CGO_ENABLED=0`, the
target. `go version -m` also lists every module compiled in, with its version, which is what a
vulnerability scanner reads from a binary when the source is not at hand. And the version string arrives
where it was meant to:

```
ana@vm:~/boxoffice$ DATABASE_URL=postgres:///nowhere?host=/nowhere BOXOFFICE_MANAGER_TOKEN=x ./dist/boxoffice-linux-amd64 2>&1 | head -1
{"time":"2026-10-22T20:01:14.62495058-03:00","level":"INFO","msg":"starting","version":"v0.16.0","config":{"http":"localhost:8080","grpc":"localhost:9090","max_conns":10,"write_timeout":"10s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
```

The first line of the log names the release, `v0.16.0`. The database in that command does not exist, and
the second line, cut off by `head`, is the failure to reach it; the first had already said which build
failed.
