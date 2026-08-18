// Command api is the server: one binary, every route, and — from phase 1 — the
// embedded frontend on the same origin.
//
// ONE ORIGIN IS THE POINT. Serving the app and the API from the same host
// removes CORS entirely and lets the session cookie be HttpOnly, which means
// the token never touches JavaScript. It also removes a static host from the
// picture, and with it a class of problem the predecessor met: an edge cache
// handing a browser one module from before a deploy and another from after.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/codeschool-ing/schooling/internal/tenant"
)

func main() {
	// `--version` and nothing else. It is not a command-line interface and is
	// not becoming one — configuration arrives through the environment, which
	// is what the platform sets. This exists because the release workflow asks
	// the binary what it is, rather than trusting that a string in a build
	// command ended up where it was aimed. It costs four lines and turns a
	// stamp that silently missed into a failed release instead of a wrong
	// answer during an incident.
	if len(os.Args) > 1 && os.Args[1] == "--version" {
		fmt.Println(build.Version)
		return
	}

	log := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	if err := run(log); err != nil {
		log.Error("the server stopped", "error", err)
		os.Exit(1)
	}
}

func run(log *slog.Logger) error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load()
	if err != nil {
		return err
	}
	info := build.Current()
	log.Info("starting",
		"version", info.Version,
		"commit", info.Commit,
		"environment", cfg.Environment,
		"platform_domain", cfg.PlatformDomain,
	)

	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router(pool, log),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      60 * time.Second,
		IdleTimeout:       90 * time.Second,
	}

	errc := make(chan error, 1)
	go func() {
		log.Info("listening", "port", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errc <- err
		}
	}()

	select {
	case err := <-errc:
		return err
	case <-ctx.Done():
		log.Info("shutting down")
	}

	// Stop listening for the signal first, so a second interrupt kills the
	// process outright instead of being swallowed by the graceful path.
	stop()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	return srv.Shutdown(shutdownCtx)
}

// router builds the whole handler.
//
// TWO CLASSES OF ROUTE, and the difference is which school they belong to.
// `/readyz` and `/version` belong to none: they are asked by the platform and
// by whoever is holding a pager, at an address that may not be any school's.
// Everything under `/api/v1/` belongs to exactly one, resolved from the Host
// before the handler runs.
//
// The webhooks the payment gateway will call are the second member of the
// first class, and they arrive at a fixed address the gateway knows. Keeping
// the split from the first day is what stops that from being a surprise.
func router(pool *pgxpool.Pool, log *slog.Logger) http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := pool.Ping(ctx); err != nil {
			web.LoggerFrom(r.Context()).Error("readiness", "error", err)
			web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "the database is unreachable")
			return
		}
		web.JSON(w, http.StatusOK, map[string]string{"status": "ready"})
	})

	/* Which build is answering. It is an operational question, not a
	   student's, and it is the one nobody can answer during an incident
	   without shelling into the machine. No database, so that it replies even
	   when everything else is down — which is when it is asked. A test holds
	   that property, because it is one line of a handler away from being lost. */
	mux.HandleFunc("GET /version", func(w http.ResponseWriter, _ *http.Request) {
		web.JSON(w, http.StatusOK, build.Current())
	})

	// The school-scoped half. Its own mux, so that mounting a route outside
	// the middleware has to be deliberate rather than a line in the wrong
	// place.
	scoped := http.NewServeMux()
	tenant.NewHandler().Routes(scoped)
	mux.Handle("/api/v1/", web.Chain(scoped, tenant.Resolve(tenant.NewStore(pool))))

	return web.Chain(mux,
		web.RequestID,
		web.Logger(log),
		web.Recover,
		web.NoStore,
	)
}
