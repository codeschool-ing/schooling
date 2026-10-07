---
title: The shop, built from its source
version: 1
---

**Every lesson deploys the same application, and you build it here, from the files below.** It is
called `shop`: a small web server in Go that answers with its version and the name of the machine
it runs on, so a transcript always shows which copy answered. Beyond that it does nothing useful on
purpose. Its other addresses exist so that later lessons have something real to act on: one makes
its health check fail, one makes it stop accepting traffic, one burns CPU and one fills memory.
Every setting is an environment variable, because that is how a pod is configured without a new
image (lesson 13).

You do not need Go installed. The image is built inside a container that has it, which is the
multi-stage build the `docker` course teaches. Copy each file with the button in its corner into
`~/shop`, under the name written above it.

`main.go`, the whole program:

```go
// Command shop is the application every lesson of the kubernetes course
// deploys: a small HTTP server whose behaviour a manifest can change, so that
// a probe, a limit or a rollout has something real to act on.
//
// Every knob is an environment variable, because that is how a pod is told
// things without rebuilding the image (lesson 13).
package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"syscall"
	"time"
)

// version is stamped at build time: go build -ldflags "-X main.version=1.1".
var version = "dev"

var (
	mu      sync.Mutex
	broken  bool     // set by /break: /healthz starts failing
	ready   = true   // set by /drain: /ready starts failing
	hoard   [][]byte // what /eat allocated, kept so it is not collected
	started = time.Now()
)

func env(name, fallback string) string {
	if v := os.Getenv(name); v != "" {
		return v
	}
	return fallback
}

func seconds(name string) time.Duration {
	n, _ := strconv.Atoi(os.Getenv(name))
	return time.Duration(n) * time.Second
}

func main() {
	host, _ := os.Hostname()
	log.SetFlags(0)
	logf := func(format string, args ...any) {
		log.Printf("%s %s", time.Now().UTC().Format(time.RFC3339), fmt.Sprintf(format, args...))
	}

	if os.Getenv("CRASH") != "" {
		logf("shop %s: CRASH is set, exiting with status 1", version)
		os.Exit(1)
	}
	if d := seconds("STARTUP_DELAY"); d > 0 {
		logf("shop %s: warming up for %s", version, d)
		time.Sleep(d)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "%s %s on %s\n", env("GREETING", "shop"), version, host)
	})
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		if broken {
			http.Error(w, "broken", http.StatusInternalServerError)
			return
		}
		fmt.Fprintln(w, "ok")
	})
	mux.HandleFunc("/ready", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		if !ready || time.Since(started) < seconds("READY_AFTER") {
			http.Error(w, "not ready", http.StatusServiceUnavailable)
			return
		}
		fmt.Fprintln(w, "ready")
	})
	mux.HandleFunc("/break", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		broken = true
		mu.Unlock()
		logf("shop %s: /healthz will fail from now on", version)
		fmt.Fprintln(w, "broken")
	})
	mux.HandleFunc("/drain", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		ready = false
		mu.Unlock()
		logf("shop %s: /ready will fail from now on", version)
		fmt.Fprintln(w, "draining")
	})
	mux.HandleFunc("/work", func(w http.ResponseWriter, r *http.Request) {
		ms, _ := strconv.Atoi(r.URL.Query().Get("ms"))
		if ms <= 0 {
			ms = 100
		}
		end := time.Now().Add(time.Duration(ms) * time.Millisecond)
		n := 0
		for time.Now().Before(end) {
			n++
		}
		fmt.Fprintf(w, "worked %dms, %d loops, on %s\n", ms, n, host)
	})
	mux.HandleFunc("/eat", func(w http.ResponseWriter, r *http.Request) {
		mb, _ := strconv.Atoi(r.URL.Query().Get("mb"))
		block := make([]byte, mb<<20)
		for i := range block {
			block[i] = 1
		}
		mu.Lock()
		hoard = append(hoard, block)
		total := 0
		for _, b := range hoard {
			total += len(b)
		}
		mu.Unlock()
		logf("shop %s: holding %d MiB", version, total>>20)
		fmt.Fprintf(w, "holding %d MiB on %s\n", total>>20, host)
	})
	mux.HandleFunc("/config", func(w http.ResponseWriter, r *http.Request) {
		file := env("CONFIG_FILE", "/etc/shop/greeting")
		body, err := os.ReadFile(file)
		if err != nil {
			body = []byte("(" + err.Error() + ")\n")
		}
		fmt.Fprintf(w, "GREETING=%s\n%s: %s", os.Getenv("GREETING"), file, body)
	})

	addr := ":" + env("PORT", "8080")
	srv := &http.Server{Addr: addr, Handler: logged(mux, logf)}

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGTERM, syscall.SIGINT)
	go func() {
		sig := <-stop
		logf("shop %s: got %s, finishing open requests", version, sig)
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		_ = srv.Shutdown(ctx)
	}()

	logf("shop %s listening on %s", version, addr)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logf("shop %s: %v", version, err)
		os.Exit(1)
	}
	logf("shop %s: stopped", version)
}

// logged writes one line per request, except the probes, which would drown
// everything else: a kubelet asks every few seconds.
func logged(next http.Handler, logf func(string, ...any)) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next.ServeHTTP(w, r)
		if r.URL.Path != "/healthz" && r.URL.Path != "/ready" {
			logf("%s %s from %s", r.Method, r.URL.RequestURI(), r.RemoteAddr)
		}
	})
}
```

`Dockerfile`:

```dockerfile
# The shop's image, in two stages: Go compiles the program in the first, and
# the second keeps only the binary, with nothing else beside it.
FROM golang:1.25 AS build
ARG VERSION=dev
WORKDIR /src
COPY main.go ./
RUN go mod init shop && CGO_ENABLED=0 go build -trimpath -ldflags "-X main.version=$VERSION" -o /shop .

FROM scratch
COPY --from=build /shop /shop
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/shop"]
```

The first stage makes `main.go` a module called `shop`, which needs nothing outside Go's standard
library, and compiles it. `-X main.version=$VERSION` writes the version into the variable `version`
at the top of `main.go`, so one source makes three images that differ only in the number they print.
The second stage starts from `scratch`, an image with nothing in it, and keeps the program alone:
no shell, no package manager, and a user that is not root.

`build.sh`, which builds the three versions the lessons use:

```sh
#!/bin/sh
# Build the three versions of the shop the lessons deploy. They differ only in
# the version the program prints, which is how a rollout shows which one answered.
set -e
cd "$(dirname "$0")"
for v in 1.0 1.1 2.0; do
  docker build -q --build-arg VERSION="$v" -t "shop:$v" .
done
```

```
ana@laptop:~/shop$ chmod +x build.sh
ana@laptop:~/shop$ time ./build.sh
sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57
sha256:bc6abd85e770d347b7672be119ad44c8f1206b60818de53b7329d91137a0725a
sha256:101822b3a919de746e60a47700783084331e9bf6932d9787cc53421d46054b3b

real	0m44.015s
user	0m0.342s
sys	0m0.296s
ana@laptop:~/shop$ docker images shop
IMAGE      ID             DISK USAGE   CONTENT SIZE   EXTRA
shop:1.0   8ec5c8c026d8       12.7MB         4.56MB        
shop:1.1   bc6abd85e770       12.7MB         4.56MB        
shop:2.0   101822b3a919       12.7MB         4.56MB        
shop:dev   692fbddc6601       12.7MB         4.56MB        
```

**Three images from one source, 12.7 MB each on disk**, almost all of it the Go program. One line per
image is the id `-q` leaves behind. The three builds took 44 seconds here, with the Go image already
on the machine; the first time on yours, Docker downloads that image too, once, and that takes longer.
Each build after the first reuses the Go image and repeats only the compilation, because the version
is part of it. Rollouts from lesson 10 on move the shop from 1.0 to 1.1, and lessons
35 and 36 to 2.0; that is the only reason three exist.

Before any cluster, the shop can be tried as an ordinary container:

```
ana@laptop:~/shop$ docker run -d --rm --name try -p 8080:8080 shop:1.1
4ab7d5e4f20b0804d5fba8412c598ff17963f3c1b5b0d62d99f9798b733821d1
ana@laptop:~/shop$ curl -s localhost:8080
shop 1.1 on 4ab7d5e4f20b
ana@laptop:~/shop$ docker stop try
try
services:
  web:
    image: shop:1.0
    ports:
      - "8080:8080"
    restart: always
```

`shop 1.1`, from the image of that tag, `on` a hostname that is the start of the container's id.
