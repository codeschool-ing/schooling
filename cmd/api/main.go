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

	"github.com/codeschool-ing/schooling/internal/analysis"
	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/codeschool-ing/schooling/internal/catalog"
	"github.com/codeschool-ing/schooling/internal/certificate"
	"github.com/codeschool-ing/schooling/internal/console"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/exam"
	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/legal"
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

	// THE TWO DOCUMENTS, MOUNTED INSIDE THE SCHOOL-SCOPED MUX AND SCOPED TO NO
	// SCHOOL. They are the platform's rather than a school's, and they are the
	// same in every one — but a browser only ever reaches this server through a
	// school's host, so the route has to be here to be reachable at all. It
	// asks the request for nothing.
	legal.NewHandler().Routes(scoped)
	courses := catalog.NewStore(pool)

	// THE PAYWALL, IN ONE PLACE. `plan` is the only thing that turns a
	// subscription into a door, and every question below that depends on money
	// goes through it — the catalogue's locks, the exam a student may sit, and
	// the dimension an event carries so the funnel can tell somebody who never
	// subscribed from somebody who did and stopped coming.
	subscriptions := billing.NewStore(pool)
	plan := planOf(subscriptions)

	// WHAT IS OUT OF CIRCULATION, ASKED BY BOTH PLACES A QUESTION IS SERVED.
	// `analysis` decides it from how people answered; `exam` and `practice`
	// only need the set, and neither may import the module that knows. This is
	// the closure that joins them, and the mapping is here rather than in
	// either of them so that neither has to name the other's type.
	items := analysis.NewStore(pool, nil, nil)
	withdrawn := func(ctx context.Context, school uuid.UUID) (map[analysis.Question]bool, error) {
		return items.InForce(ctx, school)
	}

	// THE CATALOGUE COUNTS ONE THING: opening a track, which is the funnel's
	// "chose a track". It uses the visitor recorder rather than the student one
	// because somebody choosing a track usually has no account yet — that is
	// the whole point of the step.
	catalog.NewHandler(courses, schoolID, plan, visitorEvents(events, log, plan)).Routes(scoped)

	// PROGRESS ASKS THE CATALOGUE TWO QUESTIONS and imports neither answer.
	// Whether a course is open, so the paywall is not a decoration on the
	// reading path; and which sections it has, so a client cannot complete a
	// course by inventing ids. Both are closures here, which is the only place
	// that knows about both modules.
	progress.NewHandler(
		progress.NewStore(pool,
			courseOpen(courses, plan),
			func(ctx context.Context, courseID string) (map[string][]string, error) {
				school, ok := schoolID(ctx)
				if !ok {
					return nil, nil
				}
				return courses.SectionsOf(ctx, school, courseID)
			},
		),
		schoolID, identity.AccountID, studentEvents(events, log, plan),
	).Routes(scoped)

	// PRACTICE ASKS THE SAME DOOR QUESTION, with the same closure. A card in a
	// course this student cannot open is not in their queue and is not
	// answerable — a queue that offered one and then refused it would be a
	// paywall discovered one question at a time.
	practice.NewHandler(
		practice.NewStore(pool, courseOpen(courses, plan),
			func(ctx context.Context, school uuid.UUID) (map[practice.Item]bool, error) {
				out, err := withdrawn(ctx, school)
				if err != nil {
					return nil, err
				}
				set := make(map[practice.Item]bool, len(out))
				for q := range out {
					set[practice.Item{ExerciseID: q.ExerciseID, Version: q.Version}] = true
				}
				return set, nil
			}),
		schoolID, identity.AccountID, practice.Emit(studentEvents(events, log, plan)),
	).Routes(scoped)

	// AN EXAM ASKS THE SAME DOOR QUESTION AS A LESSON, and for a track it asks
	// it of every course the track contains. A track final that a student could
	// sit while half the track was locked would be a way to earn the
	// certificate without the material.
	exams := exam.NewStore(pool, maySit(courses, plan),
		func(ctx context.Context, school uuid.UUID) (map[exam.Item]bool, error) {
			out, err := withdrawn(ctx, school)
			if err != nil {
				return nil, err
			}
			set := make(map[exam.Item]bool, len(out))
			for q := range out {
				set[exam.Item{ExerciseID: q.ExerciseID, Version: q.Version}] = true
			}
			return set, nil
		})

	// A CERTIFICATE IS THREE FACTS THIS MODULE MAY NOT GO AND READ: whether the
	// exam was passed, which is `exam`; what to write as the student's name,
	// which is `identity`; and what the course is called, which is `catalog`.
	// Three closures, joined here, and none of the three packages knows the
	// others exist.
	certificates := certificate.NewStore(pool,
		passedExam(exams), nameOf(accounts), titleOf(courses, plan))
	certificate.NewHandler(certificates, schoolNamed, identity.AccountID).Routes(scoped)

	exam.NewHandler(
		exams, schoolID, identity.AccountID, exam.Emit(studentEvents(events, log, plan)),
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
		}, arrived(events, log)),
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

	/* ---------- and the other address ----------

	   A HOST IS A SCHOOL'S, OR THE CONSOLE'S, OR A 404 (K-17). Three cases, and
	   this is where the second one is separated from the first — before any of
	   the school routes above, because `tenant.Resolve` would answer the
	   console's host with "no school answers at this address", correctly and
	   uselessly.

	   The split is by HOST and not by path, which is what makes it two gates
	   rather than one long one: a console route cannot be reached at a school's
	   address even if somebody registers it in the wrong mux, and a school route
	   cannot be reached at the console's. Everything on the console side is then
	   wrapped in `identity.RequireStaff`, which is the second gate and fails for
	   a different reason than the first. */
	staffAPI := http.NewServeMux()
	console.NewHandler(
		labelOf(accounts),
		identity.AccountID,
		func(ctx context.Context) (string, bool) {
			m, ok := identity.MemberFromContext(ctx)
			return string(m.Role), ok
		},
	).Routes(staffAPI)

	/* THE GATE IS ON THE API AND NOT ON THE WHOLE HOST, and the difference
	   matters the moment this grows a screen: a console nobody can reach
	   without a role also cannot show a sign-in page, and a sign-in page behind
	   a sign-in check is a door locked from the inside.

	   So the shape is the school side's, exactly: a prefix carries the chain,
	   and the rest of the host is free to serve something a stranger may see.
	   Today there is nothing else, and anything but the API answers 404. */
	consoleMux := http.NewServeMux()
	consoleMux.Handle("/console/api/v1/", web.Chain(staffAPI,
		identity.Authenticate(accounts),
		// READ-ONLY IS THE FLOOR AND NOT THE CEILING. Everything this will grow
		// — an export, an erasure, a parameter change — asks for more at its own
		// route. What this says is that nobody without a live role and a second
		// factor already shown gets past the door at all.
		identity.RequireStaff(accounts, identity.RoleReadOnly),
	))

	atConsole := console.Is(console.Settings{Host: console.HostOf(cfg.PlatformDomain)}, tenant.Normalise)

	/* NO VISITOR IDENTITY HERE, and that is deliberate: the funnel counts
	   people who might become students, and staff opening the console are not
	   that. A visitor row per console request would put the two people who run
	   this platform in the denominator of their own conversion rate. */
	byHost := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if atConsole(r) {
			consoleMux.ServeHTTP(w, r)
			return
		}
		mux.ServeHTTP(w, r)
	})

	return web.Chain(byHost,
		web.RequestID,
		web.Logger(log),
		web.Recover,
		web.NoStore,
	)
}

// labelOf is the wiring `console` asks for rather than an import: who somebody
// is, for the screen and for the audit entry the console will write.
func labelOf(accounts *identity.Store) console.Label {
	return func(ctx context.Context, accountID uuid.UUID) (string, string, error) {
		account, err := accounts.ByID(ctx, accountID)
		if err != nil {
			return "", "", err
		}
		return account.Name, account.Email, nil
	}
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

// planOf is what somebody is paying for, and it is now the subscription that
// says so.
//
// IT WAS WIRED IN BEFORE THERE WAS ANYTHING TO WIRE, and that turned out to be
// the whole point: the paywall has been computed from a plan on every request
// since the first day, so arriving at billing meant changing this function and
// nothing above it. A paywall added later is a paywall added to code that was
// written as though there was not one.
//
// This is the only place `catalog` and `billing` meet, which is the rule (X-02)
// and also why neither ever had to know about the other: the catalogue decides
// which door a plan opens, and billing decides which plan somebody has.
//
// # IT FAILS CLOSED, INCLUDING ON AN OUTAGE
//
// A database that cannot be read answers "no plan". The alternative is an
// outage that quietly makes every paid course free — and unlike an unreadable
// catalogue, which shows a student an error they will report, this one shows
// them something that works.
func planOf(subscriptions *billing.Store) func(context.Context) catalog.Plan {
	return func(ctx context.Context) catalog.Plan {
		account, ok := identity.FromContext(ctx)
		if !ok {
			return catalog.PlanNone
		}

		open, err := subscriptions.Opens(ctx, account.ID, time.Now())
		if err != nil {
			web.LoggerFrom(ctx).Error("reading a subscription for the paywall",
				"error", err, "answering", "no plan, which is the closed direction")
			return catalog.PlanNone
		}
		if open {
			return catalog.PlanFull
		}
		return catalog.PlanNone
	}
}

// courseOpen is the paywall, asked as a question two other modules can hold.
//
// It is here rather than in either of them because the answer belongs to the
// catalogue and neither `progress` nor `exam` may import it. A course the
// catalogue does not have is closed rather than an error: from the outside,
// "there is no such course" and "you may not open it" are the same door.
func courseOpen(courses *catalog.Store, plan catalog.PlanOf) func(context.Context, string) (bool, error) {
	return func(ctx context.Context, courseID string) (bool, error) {
		school, ok := schoolID(ctx)
		if !ok {
			return false, nil
		}
		// English, and nothing here is read: this asks whether the course may be
		// opened at all, which no translation changes.
		course, err := courses.Course(ctx, school, courseID, "en", plan(ctx))
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
func maySit(courses *catalog.Store, plan catalog.PlanOf) exam.MaySit {
	open := courseOpen(courses, plan)

	return func(ctx context.Context, scope exam.Scope, id string) (bool, error) {
		if scope == exam.ScopeCourse {
			return open(ctx, id)
		}

		school, ok := schoolID(ctx)
		if !ok {
			return false, nil
		}
		// English, and it does not matter: this reads the track's SHAPE — which
		// courses are on it — to decide whether somebody may sit its exam. No
		// word of what comes back is shown to anybody.
		track, err := courses.Track(ctx, school, id, "en")
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
func titleOf(courses *catalog.Store, plan catalog.PlanOf) certificate.TitleOf {
	return func(ctx context.Context, scope certificate.Scope, id string) (string, error) {
		school, ok := schoolID(ctx)
		if !ok {
			return "", nil
		}

		if scope == certificate.ScopeTrack {
			// English, and it does not matter: this reads the track's SHAPE — which
			// courses are on it — to decide whether somebody may sit its exam. No
			// word of what comes back is shown to anybody.
			track, err := courses.Track(ctx, school, id, "en")
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
		//
		// IN THE SOURCE LANGUAGE, AND THAT IS A LIMITATION WORTH NAMING. A
		// certificate is a statement made on a day and the name is written into
		// it, so it cannot follow the reader's language later — and this path
		// does not carry the language the student was studying in. Somebody who
		// read the whole course in Portuguese gets a certificate naming it in
		// English. Fixing it means recording the locale with the issue, which
		// is a change to what a certificate IS rather than to this line.
		course, err := courses.Course(ctx, school, id, "en", plan(ctx))
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
//
// THE PLAN IS THE REAL ONE, and that is what the dimension is for: "did not
// subscribe" and "subscribed and stopped coming" are different answers, and an
// event stream that recorded everybody as unsubscribed could not tell them
// apart afterwards. It goes through the same `plan` as the paywall, so a
// student who could open a course is never counted as somebody who could not.
func studentEvents(events *event.Store, log *slog.Logger, plan catalog.PlanOf) progress.Emit {
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
				string(plan(ctx)), account.Country, account.Locale, who(account)),
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

// visitorEvents counts something somebody did before they are a student, or
// while signed in — either way.
//
// IT CARRIES WHICHEVER IDENTITY IS THERE. A funnel step reached by a signed-out
// visitor and one reached by a student are the same step, and an emitter that
// needed an account would drop exactly the half the funnel is about.
func visitorEvents(events *event.Store, log *slog.Logger, plan catalog.PlanOf) catalog.Emit {
	return func(ctx context.Context, name string, payload map[string]any) {
		school, slug, ok := schoolOf(ctx)
		if !ok {
			return
		}

		e := event.Event{
			Name:      name,
			Payload:   payload,
			RequestID: web.RequestIDFrom(ctx),
		}

		// The plan and the person's own dimensions come from the account when
		// there is one, and are the honest "we do not know" when there is not.
		if account, signedIn := identity.FromContext(ctx); signedIn {
			e.Dimensions = event.ForSchool(school, slug,
				string(plan(ctx)), account.Country, account.Locale, who(account))
			e.AccountID = &account.ID
		} else {
			// A SIGNED-OUT BROWSER IS A REAL ONE. Nothing seeded reaches this
			// code path: a synthetic population is written by the seeder, with
			// the flag on every row it writes.
			e.Dimensions = event.ForSchool(school, slug,
				event.PlanNone, event.Unknown, event.Unknown, event.Real)
		}
		if id, ok := visitor.FromContext(ctx); ok {
			e.VisitorID = &id
		}

		if err := events.Emit(ctx, e); err != nil {
			log.Error("counting what a visitor did", "error", err, "event", name)
		}
	}
}

// who says whether an account is a real student or a seeded one.
//
// IT IS ONE FUNCTION BECAUSE THE ANSWER HAS TO BE THE SAME EVERYWHERE. A
// seeded student counted as real in one event and synthetic in another would
// appear in half of every report — and a report that is half wrong is worse
// than one that is wrong, because the number still looks plausible.
func who(account identity.Account) event.Population {
	if account.Synthetic {
		return event.Synthetic
	}
	return event.Real
}

// arrived is the first step of the funnel, and the only one that cannot be
// reconstructed afterwards (K-10).
//
// IT IS THE THIRD PLACE THE MODULE BOUNDARY SHOWS ITS SHAPE. `visitor` may not
// import `event`, so it names a callback and this fills it in — the same
// arrangement as `signedUp` below, for the same reason.
//
// NO SCHOOL IS A REAL ANSWER HERE. Somebody reaching the platform's own address
// arrived at the platform and not at a school, and forcing a school onto the
// event would put every one of those into whichever school the code guessed.
//
// A FAILURE TO COUNT NEVER REACHES THE VISITOR. They are already being served
// by the time this runs; the whole point of the middleware is that a funnel
// which cannot record an arrival must not be able to prevent one.
func arrived(events *event.Store, log *slog.Logger) visitor.Arrived {
	return func(ctx context.Context, visitorID uuid.UUID) {
		// REAL, because there is no account yet to be synthetic. A browser
		// reaching this middleware came here on its own.
		dimensions := event.ForPlatform(event.PlanNone, event.Unknown, event.Unknown, event.Real)
		if id, slug, ok := schoolOf(ctx); ok {
			dimensions = event.ForSchool(id, slug,
				event.PlanNone, event.Unknown, event.Unknown, event.Real)
		}

		e := event.Event{
			Name:       "visitor.arrived",
			Dimensions: dimensions,
			VisitorID:  &visitorID,
			RequestID:  web.RequestIDFrom(ctx),
		}
		if err := events.Emit(ctx, e); err != nil {
			log.Error("counting an arrival", "error", err, "visitor", visitorID)
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

		dimensions := event.ForPlatform(event.PlanNone,
			account.Country, account.Locale, who(account))
		if id, slug, ok := schoolOf(ctx); ok {
			dimensions = event.ForSchool(id, slug, event.PlanNone,
				account.Country, account.Locale, who(account))
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
