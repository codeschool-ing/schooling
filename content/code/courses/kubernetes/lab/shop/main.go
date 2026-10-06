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
