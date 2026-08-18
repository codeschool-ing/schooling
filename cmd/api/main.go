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

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/catalog"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/codeschool-ing/schooling/internal/tenant"
	"github.com/codeschool-ing/schooling/internal/visitor"
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
		Handler:           router(pool, log, cfg),
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
func router(pool *pgxpool.Pool, log *slog.Logger, cfg config.Config) http.Handler {
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
	//
	// THE ORDER OF THE TWO MIDDLEWARES IS THE POINT. The school is resolved
	// first, so that a visitor being issued an identity can have the school
	// they arrived at recorded as their first touch — which is the question
	// the funnel exists to answer and the one that cannot be reconstructed.
	visitors := visitor.NewStore(pool)
	accounts := identity.NewStore(pool)
	events := event.NewStore(pool)

	scoped := http.NewServeMux()
	tenant.NewHandler().Routes(scoped)
	catalog.NewHandler(catalog.NewStore(pool), schoolID, planOf).Routes(scoped)
	people := identity.NewHandler(accounts, identity.Settings{
		Domain: cfg.PlatformDomain,
		Secure: cfg.Environment == config.Production,
	}, signedUp(visitors, events, log))
	people.Routes(scoped)
	people.SecondFactorRoutes(scoped)

	mux.Handle("/api/v1/", web.Chain(scoped,
		tenant.Resolve(tenant.NewStore(pool)),
		visitor.Identify(visitors, schoolOf, visitor.Settings{
			// The parent domain, so somebody who reads about the platform and
			// then opens a school is one visitor rather than two.
			Domain: cfg.PlatformDomain,
			Secure: cfg.Environment == config.Production,
		}),
		identity.Authenticate(accounts),
	))

	return web.Chain(mux,
		web.RequestID,
		web.Logger(log),
		web.Recover,
		web.NoStore,
	)
}

// schoolOf is the wiring the module boundary asks for, and it is four lines
// rather than an import.
//
// `visitor` needs to know which school a request arrived at, and may not reach
// into `tenant` to find out — modules talk through what the consumer defines,
// joined together here in cmd/. This is what that discipline looks like in
// practice: the consumer names a function shape, the producer already satisfies
// it, and the only place that knows about both is this one.
func schoolOf(ctx context.Context) (uuid.UUID, string, bool) {
	s, ok := tenant.FromContext(ctx)
	if !ok {
		return uuid.Nil, "", false
	}
	return s.ID, s.Slug, true
}

// schoolID is schoolOf with the parts `catalog` does not need. Two shapes
// rather than one that covers both: a consumer defines what it uses, and a
// package that took a slug it never reads would have to be given one.
func schoolID(ctx context.Context) (uuid.UUID, bool) {
	s, ok := tenant.FromContext(ctx)
	return s.ID, ok
}

// planOf is what somebody is paying for, and today it is always nothing.
//
// IT IS WIRED IN ANYWAY, and that is the point of it existing before billing
// does: the paywall is computed from a plan on every request from the first
// day, so the day subscriptions arrive the change is this function and nothing
// above it. A paywall added later is a paywall added to code that was written
// as though there was not one.
func planOf(ctx context.Context) catalog.Plan {
	if _, ok := identity.FromContext(ctx); !ok {
		return catalog.PlanNone
	}
	// Billing does not exist yet. Answering "none" for a signed-in student is
	// the fail-closed direction: they see the free tier, which is what an
	// account with no subscription is entitled to.
	return catalog.PlanNone
}

// signedUp is the moment the visitor who arrived becomes a student.
//
// IT IS THE JOIN THE WHOLE FUNNEL RESTS ON (K-10), and it is the second place
// the module boundary shows its shape: `identity` may not import `visitor` or
// `event`, so it names a callback and this is what fills it in — the only
// function in the repository that knows about all three.
//
// NEITHER FAILURE STOPS A SIGN-UP. A funnel that cannot record somebody
// arriving must not be able to stop them arriving; both are logged and the
// student carries on. That is the opposite of the rule for a student's own
// data, and the difference is who pays for the failure.
func signedUp(visitors *visitor.Store, events *event.Store, log *slog.Logger) identity.SignedUp {
	return func(ctx context.Context, account identity.Account) {
		if id, ok := visitor.FromContext(ctx); ok {
			if err := visitors.Link(ctx, account.ID, id); err != nil {
				log.Error("linking a visitor to a new account", "error", err, "account", account.ID)
			}
		}

		dimensions := event.ForPlatform(event.PlanNone, account.Country, account.Locale)
		if id, slug, ok := schoolOf(ctx); ok {
			dimensions = event.ForSchool(id, slug, event.PlanNone, account.Country, account.Locale)
		}

		e := event.Event{
			Name:       "account.created",
			Dimensions: dimensions,
			AccountID:  &account.ID,
			RequestID:  web.RequestIDFrom(ctx),
		}
		if id, ok := visitor.FromContext(ctx); ok {
			e.VisitorID = &id
		}

		if err := events.Emit(ctx, e); err != nil {
			log.Error("counting a sign-up", "error", err, "account", account.ID)
		}
	}
}
