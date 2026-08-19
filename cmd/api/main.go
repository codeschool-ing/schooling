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
	"github.com/codeschool-ing/schooling/internal/certificate"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/exam"
	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/codeschool-ing/schooling/internal/practice"
	"github.com/codeschool-ing/schooling/internal/progress"
	"github.com/codeschool-ing/schooling/internal/tenant"
	"github.com/codeschool-ing/schooling/internal/visitor"
	"github.com/codeschool-ing/schooling/ui"
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
	courses := catalog.NewStore(pool)
	catalog.NewHandler(courses, schoolID, planOf).Routes(scoped)

	// PROGRESS ASKS THE CATALOGUE TWO QUESTIONS and imports neither answer.
	// Whether a course is open, so the paywall is not a decoration on the
	// reading path; and which sections it has, so a client cannot complete a
	// course by inventing ids. Both are closures here, which is the only place
	// that knows about both modules.
	progress.NewHandler(
		progress.NewStore(pool,
			courseOpen(courses),
			func(ctx context.Context, courseID string) (map[string][]string, error) {
				school, ok := schoolID(ctx)
				if !ok {
					return nil, nil
				}
				return courses.SectionsOf(ctx, school, courseID)
			},
		),
		schoolID, identity.AccountID, studentEvents(events, log),
	).Routes(scoped)

	// PRACTICE ASKS THE SAME DOOR QUESTION, with the same closure. A card in a
	// course this student cannot open is not in their queue and is not
	// answerable — a queue that offered one and then refused it would be a
	// paywall discovered one question at a time.
	practice.NewHandler(
		practice.NewStore(pool, courseOpen(courses)),
		schoolID, identity.AccountID, practice.Emit(studentEvents(events, log)),
	).Routes(scoped)

	// AN EXAM ASKS THE SAME DOOR QUESTION AS A LESSON, and for a track it asks
	// it of every course the track contains. A track final that a student could
	// sit while half the track was locked would be a way to earn the
	// certificate without the material.
	exams := exam.NewStore(pool, maySit(courses))

	// A CERTIFICATE IS THREE FACTS THIS MODULE MAY NOT GO AND READ: whether the
	// exam was passed, which is `exam`; what to write as the student's name,
	// which is `identity`; and what the course is called, which is `catalog`.
	// Three closures, joined here, and none of the three packages knows the
	// others exist.
	certificates := certificate.NewStore(pool,
		passedExam(exams), nameOf(accounts), titleOf(courses))
	certificate.NewHandler(certificates, schoolNamed, identity.AccountID).Routes(scoped)

	exam.NewHandler(
		exams, schoolID, identity.AccountID, exam.Emit(studentEvents(events, log)),
		// Passing is what issues the document, at the moment it is earned.
		awarded(certificates, log),
	).Routes(scoped)
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

	// THE INTERFACE, FROM THE SAME BINARY AND THE SAME ORIGIN (P-03). It is
	// mounted last and at the root, so it catches what nothing above it claimed
	// — and `/api/v1/` is above it, which is what keeps an API typo answering as
	// an API rather than as a page. A test holds that, because the two are one
	// registration order apart.
	//
	// No school is resolved for it: the shell is the same bytes for every
	// school and asks the API which one it is showing. That is also what makes
	// it cacheable at all.
	//
	// A build that is not a release passes no version, and therefore offers no
	// ETag: every unstamped build calls itself `dev`, so caching against that
	// string means a browser keeps the first stylesheet it ever saw and
	// revalidates it happily against every later one.
	interfaceVersion := ""
	if info := build.Current(); info.Released {
		interfaceVersion = info.Version
	}
	mux.Handle("/", ui.Handler(interfaceVersion))

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

// schoolNamed is the third shape, and the name is not decoration: a certificate
// says which school issued it, and it says so in the words the school used on
// the day rather than by holding a reference to a row that can be edited.
func schoolNamed(ctx context.Context) (uuid.UUID, string, bool) {
	s, ok := tenant.FromContext(ctx)
	return s.ID, s.Name, ok
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

// courseOpen is the paywall, asked as a question two other modules can hold.
//
// It is here rather than in either of them because the answer belongs to the
// catalogue and neither `progress` nor `exam` may import it. A course the
// catalogue does not have is closed rather than an error: from the outside,
// "there is no such course" and "you may not open it" are the same door.
func courseOpen(courses *catalog.Store) func(context.Context, string) (bool, error) {
	return func(ctx context.Context, courseID string) (bool, error) {
		school, ok := schoolID(ctx)
		if !ok {
			return false, nil
		}
		course, err := courses.Course(ctx, school, courseID, planOf(ctx))
		if errors.Is(err, catalog.ErrNotFound) {
			return false, nil
		}
		if err != nil {
			return false, err
		}
		return !course.Locked, nil
	}
}

// maySit is the same door, asked of an exam.
//
// A COURSE EXAM IS THE COURSE'S DOOR. A TRACK FINAL IS EVERY DOOR IN THE TRACK
// — otherwise the certificate the final issues could be earned while half the
// material was still behind the paywall, which is the shape of hole somebody
// finds rather than reports.
//
// A fork is the one place it is not simply "all of them": a student takes one
// branch and not the others, so a fork is open when ANY of its options is open
// end to end. Requiring every branch would lock the final for everybody in a
// track that offers a choice.
func maySit(courses *catalog.Store) exam.MaySit {
	open := courseOpen(courses)

	return func(ctx context.Context, scope exam.Scope, id string) (bool, error) {
		if scope == exam.ScopeCourse {
			return open(ctx, id)
		}

		school, ok := schoolID(ctx)
		if !ok {
			return false, nil
		}
		track, err := courses.Track(ctx, school, id)
		if errors.Is(err, catalog.ErrNotFound) {
			return false, nil
		}
		if err != nil {
			return false, err
		}

		all := func(ids []string) (bool, error) {
			for _, courseID := range ids {
				ok, err := open(ctx, courseID)
				if err != nil || !ok {
					return false, err
				}
			}
			return true, nil
		}

		for _, step := range track.Steps {
			if len(step.Options) == 0 {
				ok, err := all([]string{step.Course})
				if err != nil || !ok {
					return false, err
				}
				continue
			}

			any := false
			for _, option := range step.Options {
				ok, err := all(option.Courses)
				if err != nil {
					return false, err
				}
				if ok {
					any = true
					break
				}
			}
			if !any {
				return false, nil
			}
		}
		return true, nil
	}
}

/* ---------- what a certificate has to be told ---------- */

// passedExam is `exam`'s answer, in the shape `certificate` asked for.
//
// The two Scope types are deliberately separate: each module names its own,
// because a shared one would be an import between them. Converting is one line
// and it is this one.
func passedExam(exams *exam.Store) certificate.Passed {
	return func(ctx context.Context, scope certificate.Scope, id string) (uuid.UUID, bool, error) {
		school, ok := schoolID(ctx)
		if !ok {
			return uuid.Nil, false, nil
		}
		student, ok := identity.AccountID(ctx)
		if !ok {
			return uuid.Nil, false, nil
		}
		return exams.Passed(ctx, school, student, exam.Scope(scope), id)
	}
}

// nameOf is what goes on the document.
//
// BY ID AND NOT FROM THE REQUEST'S OWN ACCOUNT, even though today's only caller
// passes the requester. A closure that ignored the id and read the session
// would answer the wrong name the first time anything issues a certificate on
// somebody else's behalf, and it would be right until then.
func nameOf(accounts *identity.Store) certificate.NameOf {
	return func(ctx context.Context, accountID uuid.UUID) (string, error) {
		account, err := accounts.ByID(ctx, accountID)
		if err != nil {
			return "", err
		}
		return account.Name, nil
	}
}

// titleOf is what the course or track is called, today. The certificate keeps a
// copy, because the catalogue is a mirror and the load job prunes it.
func titleOf(courses *catalog.Store) certificate.TitleOf {
	return func(ctx context.Context, scope certificate.Scope, id string) (string, error) {
		school, ok := schoolID(ctx)
		if !ok {
			return "", nil
		}

		if scope == certificate.ScopeTrack {
			track, err := courses.Track(ctx, school, id)
			if errors.Is(err, catalog.ErrNotFound) {
				return "", nil
			}
			if err != nil {
				return "", err
			}
			return track.Name, nil
		}

		// The plan a course is read under does not change its name, and a
		// certificate is issued for a course the student has already sat the
		// exam of — so this asks for the name and nothing else.
		course, err := courses.Course(ctx, school, id, planOf(ctx))
		if errors.Is(err, catalog.ErrNotFound) {
			return "", nil
		}
		if err != nil {
			return "", err
		}
		return course.Name, nil
	}
}

// awarded issues the certificate the moment an exam is passed.
//
// IT NEVER FAILS THE REQUEST, and the two reasons it can decline are different
// in kind. A student with no name on their account cannot have a document yet —
// that is expected, not an error, and they collect it from the claim route once
// they have given one. Anything else is logged: the pass is on the attempt
// either way, and losing an exam result while writing a certificate would be
// the worse trade by a long way.
func awarded(certificates *certificate.Store, log *slog.Logger) exam.Awarded {
	return func(ctx context.Context, scope exam.Scope, id string) {
		school, name, ok := schoolNamed(ctx)
		if !ok {
			return
		}
		student, ok := identity.AccountID(ctx)
		if !ok {
			return
		}

		_, err := certificates.Issue(ctx, school, student, name, certificate.Scope(scope), id)
		switch {
		case err == nil, errors.Is(err, certificate.ErrNoName):
		default:
			log.Error("issuing a certificate for a passed exam",
				"error", err, "scope", scope, "exam", id)
		}
	}
}

// studentEvents emits what a student did, with the dimensions every event
// carries (K-04).
//
// IT NEVER FAILS THE REQUEST. Counting something is not the thing the student
// asked for, and a section that was completed and not counted is a hole in a
// report; a section that was not completed because counting failed is a person
// doing the work twice.
func studentEvents(events *event.Store, log *slog.Logger) progress.Emit {
	return func(ctx context.Context, name string, payload map[string]any) {
		school, slug, ok := schoolOf(ctx)
		if !ok {
			return
		}

		account, signedIn := identity.FromContext(ctx)
		if !signedIn {
			return
		}

		e := event.Event{
			Name: name,
			Dimensions: event.ForSchool(school, slug,
				event.PlanNone, account.Country, account.Locale),
			AccountID: &account.ID,
			Payload:   payload,
			RequestID: web.RequestIDFrom(ctx),
		}
		if id, ok := visitor.FromContext(ctx); ok {
			e.VisitorID = &id
		}

		if err := events.Emit(ctx, e); err != nil {
			log.Error("counting what a student did", "error", err, "event", name)
		}
	}
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
