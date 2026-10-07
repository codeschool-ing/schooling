---
title: A loja, montada a partir do código-fonte
version: 1
---

**Toda aula implanta a mesma aplicação, e você a monta aqui, a partir dos arquivos abaixo.** Ela se
chama `shop`: um pequeno servidor web em Go que responde com a sua versão e o nome da máquina em que
roda, para que uma transcrição sempre mostre qual cópia respondeu. Fora isso, de propósito, ela não faz
nada útil. Os outros endereços dela existem para que as aulas seguintes tenham algo de verdade sobre o
que agir: um faz o health check falhar, um faz a loja parar de aceitar tráfego, um gasta CPU e um enche
a memória. Toda configuração é uma variável de ambiente, porque é assim que se configura um pod sem uma
imagem nova (aula 13).

Você não precisa ter Go instalado. A imagem é montada dentro de um container que tem Go, que é o build
em múltiplos estágios que o curso `docker` ensina. Copie cada arquivo com o botão no canto dele para
`~/shop`, com o nome escrito acima dele.

`main.go`, o programa inteiro:

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

O primeiro estágio transforma `main.go` num módulo chamado `shop`, que não precisa de nada fora da
biblioteca padrão do Go, e o compila; `-X main.version=$VERSION` escreve a versão na variável `version`
do começo de `main.go`, então um código-fonte produz três imagens que só diferem no número que imprimem.
O segundo estágio começa de `scratch`, uma imagem sem nada dentro, e guarda só o programa: sem shell,
sem gerenciador de pacotes, e com um usuário que não é root.

`build.sh`, que monta as três versões que as aulas usam:

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

**Três imagens de um código-fonte, 12,7 MB cada uma no disco**, quase tudo isso o programa em Go. A
linha por imagem é o id que o `-q` deixa para trás. Os três builds levaram 44 segundos aqui, com a
imagem do Go já na máquina; na primeira vez na sua, o Docker baixa essa imagem também, uma vez só, e
isso demora mais. Cada build depois do primeiro reaproveita a imagem do Go e repete só a compilação,
porque a versão faz parte dela. Os rollouts da aula 10 em diante levam a loja de 1.0 para 1.1, e as
aulas 35 e 36 para 2.0; esse é o único motivo de existirem três.

Antes de qualquer cluster, dá para experimentar a loja como um container comum:

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

`shop 1.1`, da imagem dessa tag, `on` um hostname que é o começo do id do container.
