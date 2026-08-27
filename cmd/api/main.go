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
	"github.com/codeschool-ing/schooling/internal/audit"
	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/codeschool-ing/schooling/internal/catalog"
	"github.com/codeschool-ing/schooling/internal/certificate"
	"github.com/codeschool-ing/schooling/internal/console"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/exam"
	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/job"
	netmail "net/mail"

	"github.com/codeschool-ing/schooling/internal/legal"
	"github.com/codeschool-ing/schooling/internal/notify"
	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/cloudrun"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/platform/geo"
	"github.com/codeschool-ing/schooling/internal/platform/geo/dbip"
	"github.com/codeschool-ing/schooling/internal/platform/logs"
	"github.com/codeschool-ing/schooling/internal/platform/mail"
	"github.com/codeschool-ing/schooling/internal/platform/pay/asaas"
	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/codeschool-ing/schooling/internal/practice"
	"github.com/codeschool-ing/schooling/internal/privacy"
	"github.com/codeschool-ing/schooling/internal/progress"
	"github.com/codeschool-ing/schooling/internal/report"
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

	log := logs.New(os.Stdout)

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

	/* THE COUNTRY DATABASE IS OPENED ONCE, AND A BROKEN ONE STOPS THE PROCESS.

	   It is embedded in this binary, so a failure here is not a bad day for a
	   dependency — it is this build being wrong about itself, and no request
	   can work around it. A deployment that carried on would resolve every
	   country to `unknown` while every health check passed, which is the
	   quietest possible way to lose a dimension.

	   ITS AGE IS SAID OUT LOUD AT START-UP for the same reason the version is:
	   a stale database answers everything, confidently, and this line is what
	   somebody reads when a distribution stops making sense. */
	countries, err := dbip.Open()
	if err != nil {
		return err
	}
	defer func() { _ = countries.Close() }()
	log.Info("country database", "built", countries.Built().Format(time.DateOnly))

	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router(pool, log, cfg, startsJobs(ctx, log, cfg), countries.Country),
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
/* WHICH CLOUD RUN JOB IS WHICH OF OURS, and the two names differ on purpose.

   `job_runs.job` is what a command calls ITSELF — `analyse` — and it is the
   word the console's screen and its audit entries carry. `schooling-analyse` is
   a resource in a Google project that also holds a database, a registry and two
   other jobs, where a bare `analyse` would be a name with no owner.

   THE MAP IS THE TRANSLATION AND IT IS ALSO THE GATE. A route that built the
   resource name by prefixing would start `schooling-migrate` for anybody who
   typed `migrate`, and there is exactly one entry here because there is exactly
   one job it is safe to begin by browsing. `console.Jobs.Startable` is the same
   list one layer up, refusing before Google is asked anything. */
var cloudRunJobs = map[string]string{job.Analyse: "schooling-analyse"}

/*
startsJobs works out, once, whether this process can start a Cloud Run job.

	IT IS NIL EVERYWHERE THAT IS NOT CLOUD RUN, which is every developer machine,
	the local stack and CI — and the console then draws no button rather than one
	that fails. A stub that always succeeded would put a control on a screen that
	does nothing, which is the exact failure the jobs screen exists to make
	visible one layer down.

	The probe is cheap and bounded, and it happens before the server listens, so
	a network that black-holes the metadata address delays a start-up by two
	seconds rather than hanging a request.
*/
func startsJobs(ctx context.Context, log *slog.Logger,
	cfg config.Config) func(context.Context, string) error {

	runner, err := cloudrun.Here(ctx)
	if err != nil {
		/* IN PRODUCTION THIS IS WORTH A RAISED VOICE. Off Google it is the
		   ordinary state and says nothing; on Cloud Run it means the metadata
		   server did not answer, and a deployment that quietly lost the ability
		   to start its own jobs should not have to be discovered from a screen. */
		if cfg.Environment == config.Production {
			log.Warn("this deployment cannot start jobs", "why", err)
		} else {
			log.Info("this deployment cannot start jobs", "why", err)
		}
		return nil
	}

	project, region := runner.Where()
	log.Info("this deployment can start jobs", "project", project, "region", region)

	return func(ctx context.Context, name string) error {
		resource, ok := cloudRunJobs[name]
		if !ok {
			// Unreachable through the console, which checks its own list first.
			// It is here because the two lists are written in two places and the
			// day they disagree this says which one was asked.
			return fmt.Errorf("no Cloud Run job is wired for %q", name)
		}
		return runner.Start(ctx, resource)
	}
}

/*
PROXIESINFRONT IS HOW MANY ENTRIES OUR OWN INFRASTRUCTURE APPENDS TO
`X-Forwarded-For`, and it is derived rather than configured.

	K-13 is that only something WITHOUT a right answer becomes a parameter. This
	has one, per environment: on Cloud Run behind a domain mapping the front end
	appends the address it saw, which is one entry, and anything the caller sent
	stays to the left of it. A laptop has nothing in front of it at all, and the
	header a caller sends there is the caller's own — read, it would make the
	country a field strangers fill in.

	SO A WRONG NUMBER IS A BUG AND NOT A SETTING. It cannot be fixed by an
	environment variable at three in the morning, which is the point: it is
	checked by tests, and `platform/geo` warns in production when the shape it
	meets is not the one this says.
*/
func proxiesInFront(cfg config.Config) int {
	if cfg.Environment == config.Production {
		return 1
	}
	return 0
}

func router(pool *pgxpool.Pool, log *slog.Logger, cfg config.Config,
	startJob func(ctx context.Context, name string) error,
	country geo.Resolve) http.Handler {
	mux := http.NewServeMux()

	/* WHETHER THIS DEPLOYMENT SENDS MAIL OR KEEPS IT, SAID OUT LOUD AT START-UP.

	   A platform that quietly stops confirming addresses looks exactly like one
	   that is confirming them, from every screen and every log, until somebody
	   asks why nobody has a tick beside their e-mail. This line is the answer to
	   that question, and it costs one field. */
	postman, sending := outbound(cfg, log)
	log.Info("mail", "sending", sending, "from", cfg.MailFrom)

	/* THE LINK IN A MESSAGE POINTS AT `my.`, WHICH IS THE ACCOUNT'S OWN HOST.

	   A confirmation token belongs to an account and an account crosses every
	   school (N-01), so a link into a school's host would have to pick one — and
	   would pick wrongly for anybody enrolled in two. `my.` is the one host in
	   K-17 that is the person's rather than a school's, the console's or the
	   platform's. */
	/* AND WHO WE MAY NOT WRITE TO, ASKED BEFORE EVERY MESSAGE.

	   The list is over the database and `notify` has none, so it arrives as the
	   one function it needs — the same shape as everything else crossing a
	   module boundary here. */
	suppressions := notify.NewSuppressions(pool)
	notifier := notify.New(postman, origin(cfg), suppressions.Barred)

	/* THE PROVIDER'S WAY BACK IN, MOUNTED ONLY WHEN THERE IS A CREDENTIAL.

	   No credential, no endpoint: an open one is a way for anybody to stop this
	   platform writing to an address of their choosing, and a deployment
	   without a provider has nothing to hear from anyway. `mux` and not one of
	   the per-school routers, because a delivery event belongs to no school —
	   it is the first arrival in the class the comment above `router` reserved
	   for the payment gateway.

	   THE ADDRESS CARRIES NOTHING SECRET ANY MORE. It did, and `config.go` says
	   why it stopped; what is left here is a fixed path and a header the
	   handler checks. */
	if cfg.MailHookPassword != "" {
		mux.Handle("POST "+web.Hooks+"mail",
			notify.Hook(cfg.MailHookUser, cfg.MailHookPassword, suppressions, log))
		log.Info("mail hook", "mounted", true)
	}

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
	/* THE PASS MARK, HANDED TO THE SCHOOL ROUTE. `exam` owns the number and
	   `tenant` may not import it, so this line is where the two are said to be
	   the same one — and it exists because the interface prints "minimum to
	   pass" on a course card, before any paper exists to carry it. It printed a
	   constant of its own until now. */
	tenant.NewHandler(exam.PassMark).Routes(scoped)

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
	//
	// AND THE FUNNEL'S TWO READERS, WHICH THE CONSOLE'S SCREEN NEEDS. The top of
	// that report is browsers and the bottom is accounts, so folding the two into
	// one person needs the link between them — `visitor` owns it, and neither of
	// the other two may reach for it. `cmd/analyse` wires the same pair for the
	// copy it prints to a log; here it is wired for a screen, and the difference
	// between the two is the next paragraph.
	items := analysis.NewStore(pool, nil, nil).WithStream(
		func(ctx context.Context, school uuid.UUID, names []string,
			since time.Time, who analysis.Counting) ([]analysis.Reach, error) {

			/* THE POPULATION IS PASSED THROUGH, and this is the one place in the
			   platform where it is not fixed at `real`.

			   What earns it that is what sits above it: a screen that REPORTS,
			   with the word it was asked for answered back and a banner on it.
			   `cmd/analyse` wires this same closure and then calls with
			   `CountingReal` and no flag, because it withdraws questions from
			   circulation and must never do so on the strength of students who
			   were invented (K-11). Reporting may look; acting may not. */
			reaches, err := events.Reached(ctx, school, names, since, counting(who))
			if err != nil {
				return nil, err
			}
			out := make([]analysis.Reach, 0, len(reaches))
			for _, r := range reaches {
				out = append(out, analysis.Reach{
					Name: r.Name, VisitorID: r.VisitorID, AccountID: r.AccountID,
				})
			}
			return out, nil
		},
		func(ctx context.Context, school uuid.UUID, names []string,
			since time.Time, who analysis.Counting) ([]analysis.Active, error) {

			months, err := events.Monthly(ctx, school, names, since, counting(who))
			if err != nil {
				return nil, err
			}
			out := make([]analysis.Active, 0, len(months))
			for _, m := range months {
				out = append(out, analysis.Active{
					Month: m.Month, VisitorID: m.VisitorID, AccountID: m.AccountID,
				})
			}
			return out, nil
		},

		/* WHERE THEY WERE, WHICH TAKES NO LIST OF NAMES. A funnel step and a
		   cohort's activity are definitions somebody chose, so both readers
		   above are told which events to look at. "Where are the people" is
		   not: anything a person did is evidence they were somewhere, and a
		   list here would be a filter nobody could explain. */
		func(ctx context.Context, school uuid.UUID, since time.Time,
			who analysis.Counting) ([]analysis.Origin, error) {

			places, err := events.Countries(ctx, school, since, counting(who))
			if err != nil {
				return nil, err
			}
			out := make([]analysis.Origin, 0, len(places))
			for _, p := range places {
				out = append(out, analysis.Origin{
					Country: p.Country, VisitorID: p.VisitorID, AccountID: p.AccountID,
				})
			}
			return out, nil
		},
		visitor.NewStore(pool).Links,
	)
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
	//
	// IT IS A VARIABLE because the console reads it too, for a student's
	// record: how far one person has got, at one school.
	studied := progress.NewStore(pool,
		courseOpen(courses, plan),
		func(ctx context.Context, courseID string) (map[string][]string, error) {
			school, ok := schoolID(ctx)
			if !ok {
				return nil, nil
			}
			return courses.SectionsOf(ctx, school, courseID)
		},
	)
	progress.NewHandler(
		studied, schoolID, identity.AccountID, studentEvents(events, log, plan),
	).Routes(scoped)

	/* SAYING SOMETHING IS WRONG WITH THE MATERIAL, which is the one direction
	   nothing else in this system runs in.

	   IT IS A VARIABLE because the console reads the other end of it. And the
	   coordinates are CHECKED against the catalogue before a row is written —
	   `report` may not import `catalog`, so this is the closure that joins them,
	   the same shape `progress` already uses one line above for the same reason.

	   NO PAYWALL QUESTION HERE, deliberately, and it is the one place that is
	   right. `progress` and `practice` both ask whether the course is open on
	   this plan, because writing progress for a course somebody cannot read is
	   a paywall discovered afterwards. A report is not a thing the student gets
	   — it is a thing they give, and refusing one because a subscription lapsed
	   would lose a wrong answer key to protect nothing. */
	reports := report.NewStore(pool,
		func(ctx context.Context, school uuid.UUID, course, lesson, section string) (bool, error) {
			sections, err := courses.SectionsOf(ctx, school, course)
			if err != nil {
				return false, err
			}
			for _, id := range sections[lesson] {
				if id == section {
					return true, nil
				}
			}
			return false, nil
		},

		/* AND WHERE A QUESTION LIVES, which is the other half and the one the
		   client cannot be asked for: a drilled card carries an exercise and no
		   path, because its queue spans courses. `report` may not import
		   `catalog` either, so this is the same closure shape one line up. */
		func(ctx context.Context, school uuid.UUID, exercise string) (
			string, string, string, int, error) {

			return courses.WhereIs(ctx, school, exercise)
		},
	)
	report.NewHandler(reports, schoolID, identity.AccountID).Routes(scoped)

	// PRACTICE ASKS THE SAME DOOR QUESTION, with the same closure. A card in a
	// course this student cannot open is not in their queue and is not
	// answerable — a queue that offered one and then refused it would be a
	// paywall discovered one question at a time.
	practice.NewHandler(
		practice.NewStore(pool, courseOpen(courses, plan), withdrawnFor(withdrawn)),
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
	}, signedUp(visitors, events, accounts, notifier, log),

		/* AND THE BANNER LEARNS WHEN AN ADDRESS HAS REFUSED US, from the same
		   list `notify` asks before every message. Two readers of one fact:
		   one decides whether to write, the other decides what to say about
		   having written. */
		suppressions.Barred,

		/* AND MOVING AN ACCOUNT TO A NEW ADDRESS PUTS A LINK IN THE POST, which
		   is `notify`'s work and not `identity`'s. Same shape as `signedUp`:
		   the store writes the row, the callback carries the message. */
		changeRequested(notifier, log))
	people.Routes(scoped)
	people.SecondFactorRoutes(scoped)

	/* SENDING THE LINK AGAIN, WHICH IS THE BANNER'S ONE BUTTON.

	   IT IS ON THE SCHOOL'S API AND NOT ON `my.` because that is where the
	   banner is: the study interface draws it, and a button that had to reach
	   another origin would need CORS for a request the browser already has a
	   session for. The link it sends still points at `my.` — where it LANDS and
	   who ASKS for it are different questions.

	   IT ANSWERS THE SAME WAY WHETHER OR NOT IT SENT ANYTHING. An address that
	   is already confirmed gets no second message and gets 204 anyway; so does
	   one whose provider refused. The screen's honest sentence is "if that
	   address is not confirmed, a link is on its way", and an endpoint that
	   distinguished the cases would be reporting on somebody's account to
	   whoever holds the session — which, on a shared machine, is not always
	   them. */
	scoped.HandleFunc("POST /api/v1/confirm/resend", resend(accounts, notifier))

	/* AND STARTING A PAYMENT, WHICH IS MOUNTED ONLY WHEN THERE IS A GATEWAY.

	   No key, no route — the same arrangement the delivery hook has and the
	   right failure for the same reason: a deployment that cannot take money
	   must offer nobody a way to try rather than a button that fails after
	   somebody has decided to pay. `secrets.tf` says this about the container
	   the key lives in, and this is the line that makes it true.

	   IT IS ON THE SCHOOL'S API, so the chain above applies: a viewing cannot
	   reach it (`identity.RefuseWrites`), which is K-02 doing its job on the one
	   route where an operator acting as somebody else would be spending their
	   money. */
	if cfg.AsaasKey != "" {
		billing.NewHandler(
			billing.NewCheckouts(pool, confirmedAddress(accounts)),
			billing.NewPrices(pool),
			viaAsaas(cfg, log),
			cfg.PlatformDomain,
			payerOf(accounts),
		).Routes(scoped)
	}

	mux.Handle("/api/v1/", web.Chain(scoped,
		tenant.Resolve(tenant.NewStore(pool)),
		visitor.Identify(visitors, schoolOf, visitor.Settings{
			// The parent domain, so somebody who reads about the platform and
			// then opens a school is one visitor rather than two.
			Domain: cfg.PlatformDomain,
			Secure: cfg.Environment == config.Production,
		}, arrived(events, log)),
		// `schoolID` IS THE HEARTBEAT'S HALF OF THIS: the session is recorded as
		// last seen on the school this request arrived at, which is what makes
		// "who is here now" answerable per school. It runs after `tenant.Resolve`
		// because that is what put the school on the context.
		identity.Authenticate(accounts, schoolID),
		viewingBelongsHere,
		identity.RefuseWrites,
	))

	/* THE HANDOFF, AT THE ROOT AND NOT UNDER `/api/v1/`.

	   `GET /view` turns a link into a host-only cookie and redirects; the stop
	   route ends one. Neither belongs under the API prefix: that chain carries
	   `RefuseWrites`, and a viewing that could not end itself would be a banner
	   whose only button the rule refuses.

	   They are registered before `mux.Handle("/", …)` below and are more
	   specific than it, so the interface still catches everything else. */
	people.ViewingRoutes(mux)

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

	/* AND THE ONE ASSET THAT IS THE SCHOOL'S OWN.

	   A more specific pattern than `/` above, so it wins on this mux and only
	   on this one — the console has its own icon in its own tree, and the
	   platform's address keeps the platform's mark.

	   `tenant.Resolve` IS IN FRONT OF THIS ROUTE AND NO OTHER OUTSIDE THE API.
	   Deciding which icon means knowing which school, which is a query; putting
	   that in front of the shell and every script would be paying for the
	   answer on every request that never asks. A browser asks for a favicon
	   about once per origin. See `ui.Icon`. */
	mux.Handle("GET /assets/favicon.svg", web.Chain(
		ui.Icon(interfaceVersion, schoolSlug),
		tenant.Resolve(tenant.NewStore(pool)),
	))

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
	records := privacy.NewStore(pool)
	entries := audit.NewStore(pool)

	staffAPI := http.NewServeMux()
	console.NewHandler(
		labelOf(accounts),
		identity.AccountID,
		func(ctx context.Context) (string, bool) {
			m, ok := identity.MemberFromContext(ctx)
			return string(m.Role), ok
		},
	).Routes(staffAPI)

	// THE PHASE-0 ITEM, WIRED. `console` may import neither `identity` nor
	// `privacy` nor `audit`, so it names the shapes it needs and this is where
	// they are filled in — the same wiring `visitor.SchoolOf` uses, and the
	// place `K-07`'s read layer starts.
	somebody := console.People{
		Find:  personAt(accounts),
		ByID:  personByID(accounts),
		Held:  records.Export,
		Erase: records.Erase,
	}

	console.NewPeopleHandler(
		somebody,
		recorded(entries),
		labelOf(accounts),
		identity.AccountID,
		// OPERATOR AND NOT READ-ONLY. The door asks for read-only because a
		// screen nobody can open is a screen nobody checks; an erasure cannot
		// be undone, and the ranks exist to say which is which.
		func(ctx context.Context) bool {
			m, ok := identity.MemberFromContext(ctx)
			return ok && m.Role.Covers(identity.RoleOperator)
		},
	).Routes(staffAPI)

	/* AND THE READ THAT MAKES THAT SCREEN SAFE TO USE. An operator who can
	   erase somebody and nobody who can see that they did is one half of an
	   arrangement; the entries have been written since phase 0 and could only
	   be read with a SQL client until now.

	   READ-ONLY IS ENOUGH, and deliberately so: the history is a read, the door
	   already asks for a live role and a second factor, and a console where
	   only the people who can act can see what was done would be an audit its
	   own subjects control. */
	console.NewHistoryHandler(history(entries)).Routes(staffAPI)

	/* AND THE OTHER READ THAT MAKES THE FIRST SCREEN USABLE: what a student
	   actually has. `Personal data` answers "is this the right person and how
	   much is held", which is what somebody needs before erasing and nothing
	   anybody needs before talking.

	   FOUR MODULES MEET HERE AND THE CONSOLE IMPORTS NONE OF THEM. It names one
	   function — a person at a school — and this is where billing, progress,
	   exams and certificates are asked the same question in turn. */
	/* AND THE ONE THING THE CONSOLE CHANGES RATHER THAN READS.

	   A school's colour has been a column since the first migration and was set
	   by hand in SQL, against production, with nothing recorded. It is also the
	   first of the "closed list of system parameters" the roadmap asks for —
	   audited with the actor, the old value and the new one — which is why the
	   seam carries both sides now.

	   OPERATOR AND NOT READ-ONLY, for the erase path's reason one notch down:
	   read-only opens the door so that a console nobody can look at is not a
	   console nobody checks, and changing what every student of a school sees is
	   not a thing a read-only role does. */
	console.NewSchoolsHandler(
		console.Schools{
			All:       schoolsFor(tenant.NewStore(pool)),
			SetAccent: accentOf(tenant.NewStore(pool)),
		},
		recorded(entries),
		labelOf(accounts),
		identity.AccountID,
		func(ctx context.Context) bool {
			m, ok := identity.MemberFromContext(ctx)
			return ok && m.Role.Covers(identity.RoleOperator)
		},
	).Routes(staffAPI)

	/* AND WHAT IT COSTS, WHICH IS NOT A SCHOOL'S SCREEN ANY MORE.

	   It was `PUT /schools/{id}/price` while `school_prices` was keyed by
	   school. One subscription opens every school (N-02), so `0041` moved the
	   table to the platform and this moved with it — a form on a school's page
	   would be a control whose effect is somewhere other than where it appears.

	   The same rank as the accent, one notch above read-only, and for a reason
	   that needs no argument: this is the number everybody pays. */
	console.NewPlanHandler(
		pricesOf(billing.NewPrices(pool)),
		recorded(entries),
		labelOf(accounts),
		identity.AccountID,
		func(ctx context.Context) bool {
			m, ok := identity.MemberFromContext(ctx)
			return ok && m.Role.Covers(identity.RoleOperator)
		},
	).Routes(staffAPI)

	/* AND THE FIRST SCREEN IN `Measure`, which is the group the rail has had a
	   name for and no entries in.

	   THE FUNNEL WAS ALREADY COMPUTED and was going into a log, because there was
	   no console to put it on when it was written. This is the third module
	   meeting the other two: `console` names a function, `analysis` does the
	   arithmetic and `event` owns the stream, and none of them imports another.

	   THE POPULATION IS TRANSLATED HERE, in the one line the module boundary
	   costs. `analysis.Reading` refuses a word it does not know; the handler has
	   already refused the same words, and the two together are why a chart of
	   real people can never come back under a heading saying otherwise. */
	console.NewUnderstandHandler(
		console.Schools{All: schoolsFor(tenant.NewStore(pool))},
		func(ctx context.Context, school uuid.UUID, since time.Time,
			word string) ([]console.Step, error) {

			who, known := analysis.Reading(word)
			if !known {
				return nil, fmt.Errorf("%q is not a population this counts", word)
			}
			steps, err := items.Funnel(ctx, school, since, who)
			if err != nil {
				return nil, err
			}
			out := make([]console.Step, 0, len(steps))
			for _, s := range steps {
				out = append(out, console.Step{
					Label: s.Label, People: s.People, Measured: s.Measured, Why: s.Why,
				})
			}
			return out, nil
		},

		/* AND THE OTHER HALF OF `Measure`: what the answers say about a
		   question. Three reads of one module, joined here because the console
		   may not import it and because they are one screen — the rollup, what
		   is out of circulation, and when the job last ran.

		   THE QUARANTINE IS NOT DERIVABLE FROM THE VERDICT and that is why it is
		   read separately. The sweep runs nightly, so a question flagged this
		   afternoon is flagged AND still being asked; one released by hand is in
		   circulation with the verdict it was condemned on. A screen that
		   inferred one from the other would be confidently wrong in both
		   directions.

		   THE THRESHOLDS COME FROM THE PACKAGE THAT APPLIED THEM, so the screen
		   never writes a bar of its own. A constant moving here has to move the
		   screen with it, which is the whole point of carrying them. */
		func(ctx context.Context, school uuid.UUID) (console.Rollup, error) {
			stats, err := items.Of(ctx, school)
			if err != nil {
				return console.Rollup{}, err
			}
			withdrawn, err := items.InForce(ctx, school)
			if err != nil {
				return console.Rollup{}, err
			}
			at, computed, err := items.ComputedAt(ctx, school)
			if err != nil {
				return console.Rollup{}, err
			}

			out := make([]console.Question, 0, len(stats))
			for _, s := range stats {
				out = append(out, console.Question{
					ExerciseID: s.ExerciseID, Version: s.Version, Type: s.Type,
					Attempts: s.Attempts, Correct: s.Correct,
					Difficulty: s.Difficulty, Discrimination: s.Discrimination,
					StrongGroup: s.StrongGroup, WeakGroup: s.WeakGroup,
					Verdict:       string(s.Verdict),
					MinimumSample: s.MinimumSample,
					Withdrawn: withdrawn[analysis.Question{
						ExerciseID: s.ExerciseID, Version: s.Version,
					}],
					FirstAnswer: s.FirstAnswer, LastAnswer: s.LastAnswer,
				})
			}

			return console.Rollup{
				Questions: out,
				Thresholds: console.Thresholds{
					MinimumSample: analysis.MinimumSample,
					GroupShare:    analysis.GroupShare,
					InvertedBelow: analysis.InvertedBelow,
					WeakBelow:     analysis.WeakBelow,
					TooEasyAbove:  analysis.TooEasyAbove,
					TooHardBelow:  analysis.TooHardBelow,
				},
				ComputedAt: at,
				Computed:   computed,
			}, nil
		},

		/* AND THE THIRD REPORT: who started when, and what became of them.

		   `now` IS PASSED IN because the width of that table is a fact about the
		   calendar — how far a cohort has been followed is how much time has
		   passed since it started. The first version derived it from the newest
		   INTAKE, which renders perfectly and is wrong: a school whose last
		   signup was in March would show every cohort one month wide.

		   WHAT "ACTIVE" MEANS COMES BACK WITH THE NUMBERS, for the reason the
		   item analysis's thresholds do — a table that means whatever that word
		   means, drawn without saying it, is a table nobody can argue with. */
		func(ctx context.Context, school uuid.UUID, months int,
			word string) ([]console.Cohort, string, error) {

			who, known := analysis.Reading(word)
			if !known {
				return nil, "", fmt.Errorf("%q is not a population this counts", word)
			}
			rows, err := items.Cohorts(ctx, school, months, time.Now().UTC(), who)
			if err != nil {
				return nil, "", err
			}
			out := make([]console.Cohort, 0, len(rows))
			for _, c := range rows {
				out = append(out, console.Cohort{
					Month: c.Month, People: c.People, Active: c.Active,
				})
			}
			return out, analysis.ActiveEvent, nil
		},

		/* AND THE FOURTH: where the people are.

		   IT FOLDS IDENTITIES INTO PEOPLE THE SAME WAY THE FUNNEL DOES, because
		   it is the same store and the same links. Two screens of one console
		   disagreeing about how many people there are would be worse than one of
		   them being wrong: both would be right by their own definition and
		   there would be nothing to fix. */
		func(ctx context.Context, school uuid.UUID, since time.Time,
			word string) (console.Where, error) {

			who, known := analysis.Reading(word)
			if !known {
				return console.Where{}, fmt.Errorf("%q is not a population this counts", word)
			}
			where, err := items.Countries(ctx, school, since, who)
			if err != nil {
				return console.Where{}, err
			}
			out := console.Where{
				People:    where.People,
				Countries: make([]console.Country, 0, len(where.Countries)),
			}
			for _, c := range where.Countries {
				out.Countries = append(out.Countries,
					console.Country{Code: c.Code, People: c.People})
			}
			return out, nil
		},
	).Routes(staffAPI)

	/* AND THE SUPPORT TOOL K-02 GIVES THREE RESTRAINTS TO.

	   Audited here, time-limited by `identity`, and with a banner the student
	   interface draws from `/api/v1/me`. A fourth that K-02 does not name and
	   should: `identity.RefuseWrites`, in the chain above, refuses a viewing
	   session anything but a GET — an operator who could answer an exam question
	   as a student could forge a pass.

	   THREE MODULES MEET AND THE CONSOLE IMPORTS NONE OF THEM: `identity` mints
	   the session, `tenant` says which address to send the operator to, and
	   `audit` takes the entry. */
	console.NewViewHandler(
		console.Viewings{
			Start:  accounts.StartViewing,
			HostOf: tenant.NewStore(pool).HostOf,
		},
		console.Schools{All: schoolsFor(tenant.NewStore(pool))},
		recorded(entries),
		labelOf(accounts),
		identity.AccountID,
		func(ctx context.Context) bool {
			m, ok := identity.MemberFromContext(ctx)
			return ok && m.Role.Covers(identity.RoleOperator)
		},
	).Routes(staffAPI)

	/* THE REPORTED-CONTENT QUEUE, whose other end is the lesson screen.

	   THE SENTINELS TRAVEL AS PREDICATES. The console may not import `report`,
	   so it cannot ask `errors.Is` about its errors — and the three cases it has
	   to tell apart are different answers to an operator: a verdict that is not
	   a word, somebody having settled it first, and a report that is not there.
	   Handing over three functions is how a module boundary carries a
	   distinction that a single `error` would flatten into "could not read
	   that". */
	console.NewContentHandler(
		console.Schools{All: schoolsFor(tenant.NewStore(pool))},
		console.Reports{
			Open: func(ctx context.Context, school uuid.UUID) ([]console.Report, error) {
				rows, err := reports.Open(ctx, school)
				if err != nil {
					return nil, err
				}
				out := make([]console.Report, 0, len(rows))
				for _, one := range rows {
					out = append(out, consoleReport(one))
				}
				return out, nil
			},
			About: func(ctx context.Context, id uuid.UUID) (console.Report, uuid.UUID, error) {
				one, err := reports.One(ctx, id)
				if err != nil {
					return console.Report{}, uuid.Nil, err
				}
				return consoleReport(one), one.School, nil
			},
			Settle:         reports.Settle,
			Verdicts:       report.Verdicts,
			Refused:        func(err error) bool { return errors.Is(err, report.ErrRefused) },
			AlreadySettled: func(err error) bool { return errors.Is(err, report.ErrAlreadySettled) },
			NotThere:       func(err error) bool { return errors.Is(err, report.ErrNoSuchReport) },
		},
		recorded(entries),
		labelOf(accounts),
		identity.AccountID,
		func(ctx context.Context) bool {
			m, ok := identity.MemberFromContext(ctx)
			return ok && m.Role.Covers(identity.RoleOperator)
		},
	).Routes(staffAPI)

	/* WHAT RAN LAST NIGHT, which is the console reporting on the console rather
	   than on students — whether the machinery behind another screen did its
	   work. `job` owns the table and this is the one line that says so. */
	console.NewJobsHandler(console.Jobs{
		Names: job.NewStore(pool).Names,
		Latest: func(ctx context.Context, name string, limit int) ([]console.Run, error) {
			runs, err := job.NewStore(pool).Latest(ctx, name, limit)
			if err != nil {
				return nil, err
			}
			now := time.Now().UTC()
			out := make([]console.Run, 0, len(runs))
			for _, one := range runs {
				out = append(out, console.Run{
					Job: one.Job, Version: one.Version,
					StartedAt: one.StartedAt, FinishedAt: one.FinishedAt,
					Outcome: string(one.Outcome), Detail: one.Detail,

					// DECIDED HERE AND NOT ON THE SCREEN, because it is a
					// judgement against a threshold and `job` owns both.
					Adrift: one.Adrift(now),
				})
			}
			return out, nil
		},
		AdriftAfter: job.Adrift,

		/* AND THE ONE THAT MAY BE STARTED BY HAND. It is the only job on a
		   schedule, so it is the only one whose failure means waiting a day —
		   `migrate` and `load` are gates a deploy waits for, and their failure
		   already stops a release in front of somebody. */
		Startable: []string{job.Analyse},
		Start:     startJob,
	},
		recorded(entries),
		labelOf(accounts),
		identity.AccountID,
		func(ctx context.Context) bool {
			m, ok := identity.MemberFromContext(ctx)
			return ok && m.Role.Covers(identity.RoleOperator)
		},
	).Routes(staffAPI)

	/* WHO IS HERE, which is the one console read that is current state rather
	   than the event stream — `identity/presence.go` says why that is K-06 and
	   not a hole in K-03.

	   The window and the cadence come from `identity` and travel to the screen
	   with the counts, so the two spans that make the number mean anything are
	   never a copy inside an interface (K-16). */
	console.NewWatchHandler(
		console.Schools{All: schoolsFor(tenant.NewStore(pool))},
		func(ctx context.Context) (console.Watching, error) {
			schools, everywhere, err := accounts.Presence(ctx, identity.PresenceWindow)
			if err != nil {
				return console.Watching{}, err
			}
			out := make([]console.Here, 0, len(schools))
			for _, one := range schools {
				out = append(out, console.Here{School: one.School, People: one.People})
			}
			return console.Watching{
				Schools:    out,
				Everywhere: everywhere,
				Window:     identity.PresenceWindow,
				Cadence:    identity.PresenceCadence,
			}, nil
		},
	).Routes(staffAPI)

	console.NewRecordHandler(somebody, console.Records{
		Schools:  schoolsFor(tenant.NewStore(pool)),
		Sittings: sittingsOf(accounts),
		At:       atSchool(subscriptions, studied, exams, certificates),
	}).Routes(staffAPI)

	/* THE GATE IS ON THE API AND NOT ON THE WHOLE HOST, and the difference
	   matters the moment this grows a screen: a console nobody can reach
	   without a role also cannot show a sign-in page, and a sign-in page behind
	   a sign-in check is a door locked from the inside.

	   So the shape is the school side's, exactly: a prefix carries the chain,
	   and the rest of the host is free to serve something a stranger may see.
	   Today there is nothing else, and anything but the API answers 404. */
	consoleMux := http.NewServeMux()

	// THE SCREEN, AND IT IS NOT BEHIND THE GATE. A console nobody can open
	// without a role also cannot tell somebody that they need one — so the
	// shell is served to anybody who asks, and its first request to the API
	// behind the gate is how it finds out who is here.
	consoleMux.Handle("/", console.Interface(interfaceVersion))

	consoleMux.Handle("/console/api/v1/", web.Chain(staffAPI,
		// NOWHERE, AND THAT IS AN ANSWER RATHER THAN A GAP. Staff at the console
		// are not people present in a school, and a console left open all day
		// would otherwise put the two people who run this platform into the
		// presence count of whichever school they last looked at — the same
		// mistake as a visitor row per console request, one screen along.
		identity.Authenticate(accounts, identity.Nowhere),
		// READ-ONLY IS THE FLOOR AND NOT THE CEILING. Everything this will grow
		// — an export, an erasure, a parameter change — asks for more at its own
		// route. What this says is that nobody without a live role and a second
		// factor already shown gets past the door at all.
		identity.RequireStaff(accounts, identity.RoleReadOnly),
	))

	/* ---------- and the third address ----------

	   `my.<platform domain>` IS THE STUDENT'S, AND IT IS NO SCHOOL'S. It exists
	   for the one question a school's host cannot be asked: what is due
	   everywhere this person practises. A request at `code.` is scoped to that
	   school before any module sees it — which is what makes every query in this
	   platform safe to write — so crossing schools is a second address rather
	   than a flag on a route that would put two meanings behind one door.

	   IT NEEDS NO NEW SIGN-IN. The session cookie has been on the parent domain
	   since it existed, so a student signed in at their school is signed in here
	   (N-01). That is the whole of the mechanism, and it was decided long before
	   there was anywhere to use it.

	   The chain is the school's minus the school. `tenant.Resolve` is not in it,
	   because it would answer this host with "no school answers at this address"
	   — correctly and uselessly. `identity.Nowhere` is the console's argument in
	   the same words: a session last seen HERE belongs in no school's presence
	   count, because somebody reading their review list is not in a classroom.
	   And there is no visitor identity, for the console's other reason — this
	   address is reached by people who are already students. */
	review := http.NewServeMux()
	practice.NewAcrossHandler(
		practice.NewStore(pool, courseOpen(courses, plan), withdrawnFor(withdrawn)),
		scopedTo(tenant.NewStore(pool)),
		whereSchoolsAre(tenant.NewStore(pool)),
		identity.AccountID,
	).Routes(review)

	/* IT IS `mineMux` AND NOT `platformMux`, WHICH IS WHAT IT USED TO BE CALLED.
	   The name was fine while the apex meant nothing and this was the only
	   address belonging to no school. It stopped being fine the moment the
	   platform got a front door of its own: two muxes would have read as the
	   same thing, and the one that answers `my.` is a student's, not the
	   platform's. */
	mineMux := http.NewServeMux()
	mineMux.Handle("/api/v1/", web.Chain(review,
		identity.Authenticate(accounts, identity.Nowhere),
		// A VIEWING MAY READ AND MAY NOT WRITE (K-02). Nothing here writes
		// today; the rule is applied anyway, because the day something does is
		// not the day to remember it.
		identity.RefuseWrites,
	))
	/* AND THE SCREEN, WHICH IS `ui.Mine` AND EMPHATICALLY NOT `ui.Handler`.

	   The obvious line was the study interface's shell, and it would have been
	   wrong: that shell boots by asking for its school, its catalogue and its
	   tracks, none of which exist here. It does not crash — all three fetches
	   carry a `.catch` — it renders, keeps the markup's default brand, and
	   shows the predecessor's name over an empty school. A screen that is wrong
	   in a way that looks deliberate is worse than no screen, which is why this
	   address answered 404 until there was one written for it. */
	/* THE CONFIRMATION LINK LANDS HERE, and it is a plain GET that redeems.

	   A GET THAT CHANGES SOMETHING IS NORMALLY A MISTAKE, and this one is
	   deliberate. The alternative is a page with a button that POSTs, which
	   exists to stop a link being spent by something that is not the person —
	   a mail scanner following every URL in a message, say. But a scanner
	   following this link fetched it FROM THE MAILBOX WE WROTE TO, which is
	   precisely and entirely what the link is there to prove. Spending it early
	   reaches the right conclusion by a slightly different route.

	   It costs nothing to be wrong about, either: confirming gates nothing. A
	   button in front of it would buy a distinction with no consequence, at the
	   price of a click on the one screen where somebody is already done. */
	mineMux.Handle("GET /confirm/{token}", confirmed(accounts, events, log))
	mineMux.Handle("GET /change/{token}", changed(accounts, notifier, events, log))
	mineMux.Handle("/", ui.Mine(interfaceVersion))

	/* ---------- and the front door, at the bare domain ----------

	   THE APEX ANSWERED "no school answers at this address" UNTIL NOW, which is
	   `tenant.Resolve` being right and useless: the one address somebody types
	   having heard the name and nothing else was the one that said nothing.

	   IT LISTS THE SCHOOLS AND THE SCHOOLS MAY NOT LIST THEMSELVES. `Store.All`
	   says so at its own definition — nothing on a school's host may enumerate,
	   because a school's screen showing another school's name is the failure
	   that rule prevents. The front door is the second address belonging to no
	   school, so it gets a handler of its own rather than a route added to the
	   school's: mounting either in the wrong mux is then a mistake with a name.

	   AND THE VISITOR IS IDENTIFIED HERE, which the console deliberately does
	   not do. The difference is who is at the door: staff opening the console
	   are not people who might become students, and somebody reading this page
	   is exactly that. The cookie is on the parent domain, so reading about the
	   platform and then opening a school is ONE visitor — and `schoolOf` finds
	   none here, so the arrival is recorded with no school on it rather than
	   with a guessed one. */
	frontMux := http.NewServeMux()
	frontMux.Handle("/", ui.Front(interfaceVersion))

	atConsole := console.Is(console.Settings{Host: console.HostOf(cfg.PlatformDomain)}, tenant.Normalise)
	atMine := console.Is(console.Settings{Host: practice.Host(cfg.PlatformDomain)}, tenant.Normalise)
	atFront := console.Is(console.Settings{Host: cfg.PlatformDomain}, tenant.Normalise)

	/* NO VISITOR IDENTITY HERE, and that is deliberate: the funnel counts
	   people who might become students, and staff opening the console are not
	   that. A visitor row per console request would put the two people who run
	   this platform in the denominator of their own conversion rate. */
	byHost := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if atConsole(r) {
			consoleMux.ServeHTTP(w, r)
			return
		}
		if atMine(r) {
			mineMux.ServeHTTP(w, r)
			return
		}
		if atFront(r) {
			frontMux.ServeHTTP(w, r)
			return
		}
		mux.ServeHTTP(w, r)
	})

	return web.Chain(byHost,
		web.RequestID,
		web.Logger(log),

		/* THE COUNTRY IS RESOLVED ONCE, HERE, FOR EVERY HOST.

		   Outside the split by host on purpose: a school, the console and the
		   platform's own address all emit events, and a middleware mounted per
		   mux would be three places for the rule to be different — which is
		   how a dimension ends up meaning one thing on one address and another
		   thing on the next.

		   It is also what makes the promise checkable. The address is read in
		   `platform/geo` and nowhere else in this repository, so "we do not
		   store your IP address" is a property of one function rather than of
		   everybody remembering. */
		geo.Country(geo.Settings{Hops: proxiesInFront(cfg), Resolve: country}, log),

		web.Recover,
		web.NoStore,
	)
}

/*
WHAT IS OUT OF CIRCULATION, IN `practice`'s WORDS. The mapping is the one the

	school-scoped store already gets, lifted into a function so the platform's
	address wires the SAME quarantine rather than a second spelling of it — a
	question withdrawn for a school's own queue and offered by the cross-school
	one would be the platform contradicting itself about a broken question.
*/
func withdrawnFor(withdrawn func(context.Context, uuid.UUID) (map[analysis.Question]bool,
	error)) practice.Quarantined {

	return func(ctx context.Context, school uuid.UUID) (map[practice.Item]bool, error) {
		out, err := withdrawn(ctx, school)
		if err != nil {
			return nil, err
		}
		set := make(map[practice.Item]bool, len(out))
		for q := range out {
			set[practice.Item{ExerciseID: q.ExerciseID, Version: q.Version}] = true
		}
		return set, nil
	}
}

/*
PUTTING A SCHOOL ON A CONTEXT THAT DID NOT ARRIVE AT ITS HOST.

	This is the join that lets the cross-school queue ask the ordinary paywall
	question. `courseOpen` reads the school off the context and knows nothing
	about which address it is serving — which is the property worth having, and
	the reason this scopes rather than passing a school down a second path.

	A SCHOOL THAT CANNOT BE READ LEAVES THE CONTEXT ALONE, and the context
	without a school makes `courseOpen` answer false. That is the closed
	direction: a card whose school has gone is dropped from the queue rather than
	offered on the strength of a lookup that failed.
*/
func scopedTo(schools *tenant.Store) practice.In {
	return func(ctx context.Context, id uuid.UUID) context.Context {
		school, err := schools.ByID(ctx, id)
		if err != nil {
			web.LoggerFrom(ctx).Error("scoping a card to its school",
				"error", err, "school", id, "answering", "no school, which is the closed direction")
			return ctx
		}
		return tenant.Scoped(ctx, school)
	}
}

/*
WHERE EACH SCHOOL IS, so a card can be answered somewhere.

	The address comes from `tenant_domains` and not from the slug and the
	platform domain, for the reason `HostOf` gives: deriving one would be a
	second copy of a rule the table already holds, and the copy is the one that
	is wrong the day a school gets a domain of its own.

	WHAT IT COSTS IS TWO QUERIES PER SCHOOL, and it is worth writing down: this
	grows with the number of schools a student practises in, which is one or two,
	and not with the size of their queue. The moment to reshape it is the moment
	somebody is enrolled in a dozen schools, and that moment will not arrive
	quietly — it will arrive with a person.
*/
func whereSchoolsAre(schools *tenant.Store) practice.Schools {
	return func(ctx context.Context, ids []uuid.UUID) ([]practice.Where, error) {
		out := make([]practice.Where, 0, len(ids))
		for _, id := range ids {
			school, err := schools.ByID(ctx, id)
			if err != nil {
				return nil, err
			}
			host, err := schools.HostOf(ctx, id)
			if err != nil {
				/* A SCHOOL WITH NO ADDRESS IS DROPPED rather than shown with
				   nowhere to go. It is a real state — a school row exists before
				   its domain is mapped — and a queue offering cards that cannot
				   be reached is worse than a queue that is one school short and
				   says nothing. */
				web.LoggerFrom(ctx).Warn("a school in a student's queue has no address",
					"school", school.Slug, "error", err)
				continue
			}
			out = append(out, practice.Where{
				ID: school.ID, Slug: school.Slug, Name: school.Name, Host: host,
			})
		}
		return out, nil
	}
}

// personAt is the console's one way of reaching somebody: an exact address, and
// one person or none (K-22).
func personAt(accounts *identity.Store) func(context.Context, string) (console.Person, error) {
	return func(ctx context.Context, email string) (console.Person, error) {
		account, err := accounts.ByEmail(ctx, email)
		if errors.Is(err, identity.ErrNoAccount) {
			return console.Person{}, console.ErrNoPerson
		}
		if err != nil {
			return console.Person{}, err
		}
		return console.Person{
			ID: account.ID, Name: account.Name, Email: account.Email,
			CreatedAt: account.CreatedAt, Synthetic: account.Synthetic,
		}, nil
	}
}

// recorded turns the console's shape into an audit entry.
//
// `TenantID` IS ABSENT AND THAT IS CORRECT for an account: one belongs to no
// school (N-01), so exporting or erasing it is a platform-wide action, which
// the column is nullable for. A school's own row is the same shape from the
// other direction — the subject IS the school, and naming it twice would put
// the same id in two columns.
//
// THE KIND COMES FROM THE CONSOLE NOW. It used to be the constant "account"
// here, which was true of everything the console could do and stopped being
// true the moment it could set a school's colour.
func recorded(entries *audit.Store) console.Record {
	return func(ctx context.Context, actor uuid.UUID, actorLabel, action string,
		subject console.Subject, what console.Changed, requestID string) error {
		return entries.Record(ctx, audit.Entry{
			Actor:       audit.Staff(actor, actorLabel),
			Action:      action,
			SubjectKind: subject.Kind,
			SubjectID:   subject.ID,
			// Counts, never contents: see `console.Record`.
			Before:    what.Before,
			After:     what.After,
			RequestID: requestID,
		})
	}
}

// history is the read side of the seam `recorded` is the write side of.
//
// TWO SHAPES AND NOT ONE STORE. `console` names `Page` and `One` because that
// is what a screen does — a list, then one entry — and `audit` answers them
// with the two queries its indexes already sort. Handing the console the store
// itself would be the import the module boundary refuses, and would hand it
// `Record` besides, which a screen that reads history has no business holding.
func history(entries *audit.Store) console.History {
	return console.History{
		Page: func(ctx context.Context, ask console.Ask) ([]console.Deed, error) {
			q := audit.Query{
				ActorID:     ask.ActorID,
				SubjectKind: ask.SubjectKind,
				SubjectID:   ask.SubjectID,
				Limit:       ask.Limit,
			}
			if ask.AfterTime != nil {
				q.After = &audit.Cursor{At: *ask.AfterTime, ID: ask.AfterID}
			}
			rows, err := entries.Recent(ctx, q)
			if err != nil {
				return nil, err
			}
			out := make([]console.Deed, 0, len(rows))
			for _, row := range rows {
				out = append(out, deed(row))
			}
			return out, nil
		},
		One: func(ctx context.Context, id int64) (console.Deed, error) {
			row, err := entries.One(ctx, id)
			switch {
			case errors.Is(err, audit.ErrNoEntry):
				return console.Deed{}, console.ErrNoEntry
			case err != nil:
				return console.Deed{}, err
			}
			return deed(row), nil
		},
	}
}

func deed(r audit.Row) console.Deed {
	return console.Deed{
		ID: r.ID, OccurredAt: r.OccurredAt,
		ActorID: r.ActorID, ActorKind: r.ActorKind, ActorLabel: r.ActorLabel,
		Action: r.Action, SubjectKind: r.SubjectKind, SubjectID: r.SubjectID,
		TenantID: r.TenantID, Reason: r.Reason, RequestID: r.RequestID,
		Before: r.Before, After: r.After,
	}
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
// schoolSlug is `schoolOf` with the two parts an icon does not need, and an
// empty string where there is no school — which is a real answer here rather
// than a failure, and the reason `ui.Icon` takes a plain string.
func schoolSlug(ctx context.Context) string {
	s, ok := tenant.FromContext(ctx)
	if !ok {
		return ""
	}
	return s.Slug
}

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
				string(plan(ctx)), geo.FromContext(ctx), account.Locale, who(account)),
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
				string(plan(ctx)), geo.FromContext(ctx), account.Locale, who(account))
			e.AccountID = &account.ID
		} else {
			// A SIGNED-OUT BROWSER IS A REAL ONE. Nothing seeded reaches this
			// code path: a synthetic population is written by the seeder, with
			// the flag on every row it writes.
			e.Dimensions = event.ForSchool(school, slug,
				event.PlanNone, geo.FromContext(ctx), event.Unknown, event.Real)
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
		dimensions := event.ForPlatform(event.PlanNone,
			geo.FromContext(ctx), event.Unknown, event.Real)
		if id, slug, ok := schoolOf(ctx); ok {
			dimensions = event.ForSchool(id, slug,
				event.PlanNone, geo.FromContext(ctx), event.Unknown, event.Real)
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
func signedUp(visitors *visitor.Store, events *event.Store, accounts *identity.Store,
	notifier *notify.Notifier, log *slog.Logger) identity.SignedUp {
	return func(ctx context.Context, account identity.Account) {
		/* AND NEITHER DOES A MESSAGE THAT DOES NOT GO OUT. The rule above is
		   about a funnel; this is about a provider having an afternoon, which is
		   the same shape of failure and gets the same answer. An address that
		   was never confirmed costs us knowing we can reach somebody; a sign-up
		   that failed because a third party was down costs them the lesson they
		   came for, and mail does not get to decide who may study here.

		   The person can ask again — the banner's Resend is exactly this call —
		   which is why this is logged and dropped rather than retried here. */
		confirm(ctx, accounts, notifier, account, log)

		if id, ok := visitor.FromContext(ctx); ok {
			if err := visitors.Link(ctx, account.ID, id); err != nil {
				log.Error("linking a visitor to a new account", "error", err, "account", account.ID)
			}
		}

		dimensions := event.ForPlatform(event.PlanNone,
			geo.FromContext(ctx), account.Locale, who(account))
		if id, slug, ok := schoolOf(ctx); ok {
			dimensions = event.ForSchool(id, slug, event.PlanNone,
				geo.FromContext(ctx), account.Locale, who(account))
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

/*
confirmed is where the link in the message lands.

	IT REDIRECTS RATHER THAN RENDERING. This address serves one shell, and a
	handler that wrote its own page here would be a second interface — with its
	own markup, its own language and its own way of being out of date. So it
	spends the token and sends the browser to the screen, carrying the one fact
	the screen needs.

	AND IT SAYS THE SAME THING WHEN THE LINK IS NO GOOD. Never issued, already
	spent, expired, or for an address the account has since left: all four are
	`confirmed=no`, because telling them apart would confirm to somebody guessing
	that a token is real, and would say nothing the person could act on. The
	screen offers to send another, which is the useful sentence in all four
	cases.
*/
func confirmed(accounts *identity.Store, events *event.Store, log *slog.Logger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		account, err := accounts.ConfirmEmail(r.Context(), r.PathValue("token"))
		if err != nil {
			if !errors.Is(err, identity.ErrNoConfirmation) {
				log.Error("confirming an address", "error", err)
			}
			http.Redirect(w, r, "/?confirmed=no", http.StatusSeeOther)
			return
		}

		/* THE STEP GOES INTO THE STREAM, and a stream that could not record it
		   must not be able to undo it. The address is confirmed either way; what
		   fails here is a number on a screen, which is `signedUp`'s rule and the
		   same trade. */
		e := event.Event{
			Name: "account.confirmed",
			Dimensions: event.ForPlatform(event.PlanNone,
				geo.FromContext(r.Context()), account.Locale, who(account)),
			AccountID: &account.ID,
			RequestID: web.RequestIDFrom(r.Context()),
		}
		if id, ok := visitor.FromContext(r.Context()); ok {
			e.VisitorID = &id
		}
		if err := events.Emit(r.Context(), e); err != nil {
			log.Error("counting a confirmed address", "error", err, "account", account.ID)
		}

		http.Redirect(w, r, "/?confirmed=yes", http.StatusSeeOther)
	}
}

/*
changed is where the link in a change message lands.

	IT IS ON `my.` BESIDE `confirmed`, because a change belongs to the account
	rather than to any one school (N-01), and the link was built against the same
	origin.

	THE OLD ADDRESS IS TOLD HERE AND NOT IN THE STORE. The store's job ended when
	the row moved; who gets written to afterwards is a decision about messages,
	and this is where the two meet.
*/
func changed(accounts *identity.Store, notifier *notify.Notifier,
	events *event.Store, log *slog.Logger) http.HandlerFunc {

	return func(w http.ResponseWriter, r *http.Request) {
		account, previous, err := accounts.ConfirmEmailChange(r.Context(), r.PathValue("token"))
		switch {
		case errors.Is(err, identity.ErrTaken):
			/* SOMEBODY TOOK THE ADDRESS BETWEEN THE ASKING AND THE CLICKING.
			   Its own answer, because "that link is no good" would send
			   somebody looking for a broken link when what they need is a
			   different address. */
			http.Redirect(w, r, "/?changed=taken", http.StatusSeeOther)
			return
		case err != nil:
			if !errors.Is(err, identity.ErrNoChange) {
				log.Error("changing an address", "error", err)
			}
			http.Redirect(w, r, "/?changed=no", http.StatusSeeOther)
			return
		}

		/* THE OLD ADDRESS IS TOLD, AND A REFUSAL THERE IS NOT A FAILURE. The
		   commonest reason to be here at all is that the old address bounced —
		   so `notify` refusing to write to it is this feature working, not
		   breaking, and the change has already happened either way. */
		if err := notifier.AddressChanged(r.Context(), notify.Person{
			Name: account.Name, Email: previous, Locale: account.Locale,
		}, account.Email); err != nil {
			if errors.Is(err, notify.ErrRefused) {
				log.Info("not telling an old address that it was replaced, because it refused our mail",
					"account", account.ID)
			} else {
				log.Error("telling an old address that it was replaced", "error", err,
					"account", account.ID)
			}
		}

		e := event.Event{
			Name: "account.address_changed",
			Dimensions: event.ForPlatform(event.PlanNone,
				geo.FromContext(r.Context()), account.Locale, who(account)),
			AccountID: &account.ID,
			RequestID: web.RequestIDFrom(r.Context()),
		}
		if id, ok := visitor.FromContext(r.Context()); ok {
			e.VisitorID = &id
		}
		if err := events.Emit(r.Context(), e); err != nil {
			log.Error("counting an address change", "error", err, "account", account.ID)
		}

		http.Redirect(w, r, "/?changed=yes", http.StatusSeeOther)
	}
}

/*
changeRequested puts the link for a new address in the post.

	IT LOGS AND RETURNS NOTHING, like `signedUp`. A message that could not be
	composed must not be able to fail the request that asked for it — the row is
	written, the link is live, and what is lost is one delivery that the person
	can ask for again.
*/
func changeRequested(notifier *notify.Notifier, log *slog.Logger) identity.ChangeRequested {
	return func(ctx context.Context, account identity.Account, change identity.Change) {
		/* THE TOKEN IS NOT IN ANY LOG LINE HERE. Anybody holding it can move
		   this account onto an address of their choosing without reading the
		   mail, which is the one thing the link exists to prove. */
		if err := notifier.ChangeAddress(ctx, notify.Person{
			Name: account.Name, Email: change.Email, Locale: account.Locale,
		}, change.Token); err != nil {
			log.Error("sending a link to a new address", "error", err, "account", account.ID)
		}
	}
}

/*
resend is the banner's button.

	204 WHATEVER HAPPENS, short of not being signed in. See the note where this
	is routed: an endpoint that reported whether a message went out would be
	reporting on an account to whoever holds the session, and the screen's
	sentence does not need it.
*/
/*
viaAsaas is the payment gateway, wired into the seam `billing` declares.

	NEITHER SIDE IMPORTS THE OTHER. `billing` holds no provider and the provider
	holds no domain — this function is the whole of what joins them, which is
	what makes the second gateway a second one of these rather than a rewrite.

	THE HOST IS READ OFF THE KEY AND IS NOT A SETTING. It followed `SCHOOLING_ENV`
	first, which is one setting and is the wrong one: it would have made a
	production deployment unable to reach the sandbox, so the first end-to-end
	run of this integration would have been with real money. `asaas.HostFor` puts
	the question to the thing that actually answers it.
*/
func viaAsaas(cfg config.Config, log *slog.Logger) billing.Gateway {
	client := asaas.New(cfg.AsaasKey, asaas.HostFor(cfg.AsaasKey))

	/* A REAL DEPLOYMENT ON A PRETEND GATEWAY IS ALLOWED AND IS SAID OUT LOUD.

	   It is the rehearsal this arrangement exists to make possible — the whole
	   path, in the real service, before an account with real money exists. What
	   it must never be is quiet: somebody reading a log has to be able to tell
	   why a month of subscriptions is worth nothing. The payer sees it too,
	   because the invoice they are sent to is on the sandbox's own domain. */
	if cfg.Environment == config.Production && asaas.IsSandbox(cfg.AsaasKey) {
		log.Warn("the payment gateway is the SANDBOX in a production deployment — " +
			"checkouts will complete and no money will move")
	}

	return billing.Gateway{
		Name: "asaas",

		NewCustomer: func(ctx context.Context, name, email, taxID string) (string, error) {
			one, err := client.CreateCustomer(ctx, asaas.Customer{
				Name: name, Email: email, TaxID: taxID,
			})
			if err != nil {
				return "", err
			}
			return one.ID, nil
		},

		NewCharge: func(ctx context.Context, in billing.Charge) (string, string, error) {
			method := asaas.Pix
			if in.Method == billing.MethodCard {
				method = asaas.Card
			}
			charge, err := client.CreateCharge(ctx, asaas.Charge{
				CustomerID:  in.CustomerID,
				Method:      method,
				Cents:       in.Cents,
				Due:         in.Due,
				Reference:   in.Reference,
				Description: in.Describes,
				Instalments: in.Instalments,
			})
			if err != nil {
				return "", "", err
			}
			return charge.ID, charge.InvoiceURL, nil
		},

		/* A REFUSAL IS THEIRS AND A SENTENCE IS OURS. `asaas.Refused` carries a
		   generic code and Portuguese prose; this says only whether the caller
		   can fix it, and `billing` picks the words in the language the buyer
		   reads. */
		Refused: func(err error) bool {
			var refused *asaas.Refused
			return errors.As(err, &refused) && refused.Status < 500
		},
	}
}

/*
confirmedAddress is the gate `billing.Open` will not run without.

	IT ANSWERS ONE QUESTION AND NOT "IS THIS PERSON ALLOWED TO PAY". Whether a
	suppressed address should also stop a checkout is a decision nobody has made;
	what ROADMAP.md settled is confirmation, and this is exactly that.
*/
func confirmedAddress(accounts *identity.Store) billing.Confirmed {
	return func(ctx context.Context, id uuid.UUID) (bool, error) {
		account, err := accounts.ByID(ctx, id)
		if err != nil {
			return false, err
		}
		return account.EmailVerifiedAt != nil, nil
	}
}

/*
payerOf is who is buying, in the two words a gateway wants.

	THE NAME AND THE ADDRESS COME FROM THE SESSION AND NOT FROM THE REQUEST. A
	checkout that took them from the body would let somebody register a payer
	under a name they do not have, at a gateway that keeps it.
*/
func payerOf(accounts *identity.Store) func(context.Context) (uuid.UUID, string, string, bool) {
	return func(ctx context.Context) (uuid.UUID, string, string, bool) {
		account, ok := identity.FromContext(ctx)
		if !ok {
			return uuid.Nil, "", "", false
		}
		return account.ID, account.Name, account.Email, true
	}
}

func resend(accounts *identity.Store, notifier *notify.Notifier) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := identity.AccountID(r.Context())
		if !ok {
			web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
			return
		}

		log := web.LoggerFrom(r.Context())
		account, err := accounts.ByID(r.Context(), id)
		if err != nil {
			log.Error("reading an account to resend its confirmation", "error", err, "account", id)
			w.WriteHeader(http.StatusNoContent)
			return
		}

		// ALREADY CONFIRMED IS NOT AN ERROR AND IS NOT A SECOND MESSAGE. A stale
		// tab still showing the banner is the ordinary way to arrive here.
		if account.EmailVerifiedAt == nil {
			confirm(r.Context(), accounts, notifier, account, log)
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

/*
confirm issues a link for an address and puts it in the post.

	IT IS TWO CALLS AND EITHER CAN FAIL INDEPENDENTLY, which is why they are
	logged separately: a token written with no message sent is a person waiting
	for mail that is not coming, and a message that could not be composed is a
	token nobody will ever spend. They read differently in a log and they have
	different fixes.
*/
func confirm(ctx context.Context, accounts *identity.Store, notifier *notify.Notifier,
	account identity.Account, log *slog.Logger) {
	link, err := accounts.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		log.Error("issuing a confirmation link", "error", err, "account", account.ID)
		return
	}

	/* THE TOKEN IS NOT IN THIS LOG LINE AND MUST NEVER BE. It is the whole
	   secret: anybody holding it can confirm the address without reading the
	   mail, which is the one thing the link exists to prove. */
	if err := notifier.ConfirmAddress(ctx, notify.Person{
		Name: account.Name, Email: link.Email, Locale: account.Locale,
	}, link.Token); err != nil {
		/* A REFUSED ADDRESS IS NOT AN INCIDENT AND IS NOT LOGGED AS ONE.

		   It is this platform doing exactly what it was told: the mailbox is
		   gone, or somebody marked us as spam, and nothing on our side is
		   broken. Logged at Error it would be an alert firing on correct
		   behaviour, which is how a log stops being read — and the one thing it
		   still has to do is answer "why did nothing arrive", which it does at
		   Info just as well. */
		if errors.Is(err, notify.ErrRefused) {
			log.Info("not writing to an address that refused our mail", "account", account.ID)
			return
		}
		log.Error("sending a confirmation link", "error", err, "account", account.ID)
	}
}

/*
outbound is who posts this platform's mail, and whether anybody does.

	NO KEY IS NOT AN ERROR, IT IS THE OTHER IMPLEMENTATION. Every laptop, every
	test run and CI has no mail account, and a platform that refused to start
	without one would make "run it locally" mean "get a key first". What it must
	not do is drop the messages, because a dropped one is indistinguishable from
	a delivered one until somebody complains — so `mail.Outbox` keeps them.
*/
func outbound(cfg config.Config, log *slog.Logger) (mail.Sender, bool) {
	if cfg.MailKey == "" {
		if cfg.Environment == config.Production {
			log.Warn("no mail key in production — addresses will not be confirmed, " +
				"and every message this platform would send is being kept instead of sent")
		}
		return &mail.Outbox{}, false
	}
	return mail.ViaBrevo(cfg.MailKey, address(cfg.MailFrom), address(cfg.MailReplyTo)), true
}

// address reads `Name <box@domain>` or a bare address. A malformed one has
// already failed `config.Load`, which checks for the `@`; anything that gets
// past that and past `net/mail` is used as the address alone rather than
// dropped, because a message with a slightly odd From is worth more than no
// message.
func address(s string) mail.Address {
	if s == "" {
		return mail.Address{}
	}
	if parsed, err := netmail.ParseAddress(s); err == nil {
		return mail.Address{Name: parsed.Name, Email: parsed.Address}
	}
	return mail.Address{Email: s}
}

/*
origin is where a link in a message points.

	HTTPS EVERYWHERE EXCEPT DEVELOPMENT, mirroring the session cookie's `Secure`
	one screen up rather than inventing a second rule. A development deployment
	keeps its mail rather than sending it, so the scheme there is about what a
	person reads in the outbox and not about what a browser will do with it.
*/
func origin(cfg config.Config) string {
	scheme := "http://"
	if cfg.Environment == config.Production {
		scheme = "https://"
	}
	return scheme + practice.Host(cfg.PlatformDomain)
}

// personByID is the other half of `personAt`: the console's screens find
// somebody by address and then keep the id in the address bar.
func personByID(accounts *identity.Store) func(context.Context, uuid.UUID) (console.Person, error) {
	return func(ctx context.Context, id uuid.UUID) (console.Person, error) {
		account, err := accounts.ByID(ctx, id)
		if errors.Is(err, identity.ErrNoAccount) {
			return console.Person{}, console.ErrNoPerson
		}
		if err != nil {
			return console.Person{}, err
		}
		return console.Person{
			ID: account.ID, Name: account.Name, Email: account.Email,
			CreatedAt: account.CreatedAt, Synthetic: account.Synthetic,
		}, nil
	}
}

// schoolsFor is the loop a record is gathered across.
//
// `tenant.All` exists for this and for nothing on the school side: a request on
// a school's host resolves exactly one school and must never enumerate them.
func schoolsFor(schools *tenant.Store) func(context.Context) ([]console.School, error) {
	return func(ctx context.Context) ([]console.School, error) {
		all, err := schools.All(ctx)
		if err != nil {
			return nil, err
		}
		out := make([]console.School, 0, len(all))
		for _, s := range all {
			out = append(out, console.School{
				ID: s.ID, Slug: s.Slug, Name: s.Name, Accent: s.Accent,
			})
		}
		return out, nil
	}
}

// accentOf is the console's one write to a school, mapped onto the module that
// owns the row — including the refusal, which `console` names for itself so
// that it never has to import `tenant` to recognise one.
func accentOf(schools *tenant.Store) func(context.Context, uuid.UUID, string) (string, error) {
	return func(ctx context.Context, id uuid.UUID, accent string) (string, error) {
		was, err := schools.SetAccent(ctx, id, accent)
		if errors.Is(err, tenant.ErrNoSchool) {
			return "", console.ErrNoSchool
		}
		return was, err
	}
}

/*
THE PLAN'S PRICE, MAPPED ONTO THE MODULE THAT OWNS IT.

	These were `priceOf` and `pricesOf` against `tenant`, because the table hung
	off a school. `0041` moved it to the platform and `billing` took the code with
	it; the seams are the same shape and point somewhere else.

	`Set` APPENDS — see `billing.Prices.Set` and K-14 — and this closure is the
	only place that difference is invisible, which is why the field it fills is
	documented as a series rather than as a setter.
*/
func pricesOf(prices *billing.Prices) console.Plan {
	return console.Plan{
		Set: func(ctx context.Context, termMonths, cents int, currency string) (console.Price, error) {
			was, err := prices.Set(ctx, billing.ScopeEverything, termMonths, cents, currency)
			if err != nil {
				return console.Price{}, err
			}
			return console.Price{
				TermMonths: was.TermMonths, Cents: was.Cents,
				Currency: was.Currency, From: was.From,
			}, nil
		},

		// A TERM NOBODY HAS PRICED IS A ZERO AND NOT AN ERROR. The handler asks
		// this to name what a change replaced, and "nothing" is the true answer
		// the first time a term is priced.
		InForce: func(ctx context.Context, termMonths int) (console.Price, error) {
			one, err := prices.InForce(ctx, billing.ScopeEverything, termMonths)
			if errors.Is(err, billing.ErrNoOffer) {
				return console.Price{}, nil
			}
			if err != nil {
				return console.Price{}, err
			}
			return console.Price{
				TermMonths: one.TermMonths, Cents: one.Cents,
				Currency: one.Currency, From: one.From,
			}, nil
		},

		Series: func(ctx context.Context) ([]console.Price, error) {
			rows, err := prices.Series(ctx, billing.ScopeEverything)
			if err != nil {
				return nil, err
			}
			out := make([]console.Price, 0, len(rows))
			for _, one := range rows {
				out = append(out, console.Price{
					TermMonths: one.TermMonths, Cents: one.Cents,
					Currency: one.Currency, From: one.From,
				})
			}
			return out, nil
		},

		Refused: func(err error) bool { return errors.Is(err, billing.ErrNotAPrice) },
	}
}

func sittingsOf(accounts *identity.Store) func(context.Context, uuid.UUID) ([]console.Sitting, error) {
	return func(ctx context.Context, accountID uuid.UUID) ([]console.Sitting, error) {
		sittings, err := accounts.Sittings(ctx, accountID)
		if err != nil {
			return nil, err
		}
		out := make([]console.Sitting, 0, len(sittings))
		for _, s := range sittings {
			out = append(out, console.Sitting{
				ID: s.ID, CreatedAt: s.CreatedAt, LastSeenAt: s.LastSeenAt,
				ExpiresAt: s.ExpiresAt, RevokedAt: s.RevokedAt, UserAgent: s.UserAgent,
			})
		}
		return out, nil
	}
}

/*
atSchool asks four modules the same question about one person, at one school.

	THIS IS WHAT THE MODULE BOUNDARY BUYS. `console` names one function; nothing
	in it knows that a subscription is `billing`'s or that a certificate is
	`certificate`'s, and none of those four knows the console exists. The joining
	is here, which is where `planOf`, `maySit` and `passedExam` already join the
	same modules for the student's own screens.

	A SUBSCRIPTION IS SCOPED TO THE SCHOOL, and `billing.Of` takes that scope as
	a string — the school's slug, which is what the student side passes. Reading
	it with the wrong scope would answer "no plan" for somebody who is paying.
*/
func atSchool(
	subscriptions *billing.Store,
	studied *progress.Store,
	exams *exam.Store,
	certificates *certificate.Store,
) func(context.Context, console.School, uuid.UUID) (console.AtSchool, error) {
	return func(ctx context.Context, school console.School, accountID uuid.UUID) (console.AtSchool, error) {
		out := console.AtSchool{School: school}

		held, err := subscriptions.Of(ctx, accountID, school.Slug, time.Now())
		switch {
		case errors.Is(err, billing.ErrNoSubscription):
			// Not an error and not a gap: most people at most schools have
			// never held anything there.
		case err != nil:
			return console.AtSchool{}, err
		default:
			out.Plan = string(held.Model)
			out.State = string(held.State)
			if !held.PaidThrough.IsZero() {
				paid := held.PaidThrough
				out.PaidThrough = &paid
			}
		}

		done, err := studied.Summary(ctx, school.ID, accountID)
		if err != nil {
			return console.AtSchool{}, err
		}
		for _, d := range done {
			out.Courses = append(out.Courses, console.Course{CourseID: d.CourseID, Sections: d.Sections})
		}

		sat, err := exams.History(ctx, school.ID, accountID)
		if err != nil {
			return console.AtSchool{}, err
		}
		for _, e := range sat {
			one := console.Sat{
				Scope: string(e.Scope), ScopeID: e.ScopeID,
				StartedAt: e.StartedAt, HandedIn: e.HandedIn,
			}
			if e.Result != nil {
				passed := e.Result.Passed
				score := e.Result.Score
				one.Passed, one.Score = &passed, &score
			}
			out.Exams = append(out.Exams, one)
		}

		given, err := certificates.All(ctx, school.ID, accountID)
		if err != nil {
			return console.AtSchool{}, err
		}
		for _, c := range given {
			out.Certificates = append(out.Certificates, console.Given{
				Code: c.Code, Title: c.Title, IssuedAt: c.IssuedAt,
			})
		}
		return out, nil
	}
}

// counting says that `analysis`'s word for a population and the stream's are the
// same word.
//
// TWO TYPES BECAUSE A MODULE MAY NOT IMPORT A MODULE (X-02), and this is the one
// line that is the price of it — `cmd/analyse` carries the same one, for the
// same reason and over the same three values. It is exhaustive rather than a
// cast: both sides fall back to `real` for a value they do not know, so a missed
// case narrows the population and never widens a report about people into one
// that quietly counts invented ones.
func counting(who analysis.Counting) event.Counting {
	switch who {
	case analysis.CountingSeeded:
		return event.CountingSeeded
	case analysis.CountingEverybody:
		return event.CountingEverybody
	default:
		return event.CountingReal
	}
}

// viewingBelongsHere drops a viewing that was started for another school.
//
// # THE COOKIE ALREADY SAYS SO AND THAT IS NOT ENOUGH
//
// A viewing cookie is host-only, so a browser will not send `code`'s to `math`.
// This is the same rule where a copied cookie cannot argue with it: the session
// row records which school the viewing was opened on, and a request arriving at
// a different one is answered as if there were no session at all.
//
// # IT IS HERE AND NOT IN `identity` BECAUSE OF THE BOUNDARY
//
// `tenant` owns which school a host is and `identity` may not import it (X-02).
// `cmd/api` is where the two meet, which is the same reason every other seam in
// this file exists — and it runs AFTER `Authenticate`, because there is nothing
// to check until a session has been read.
//
// THE ACCOUNT GOES WITH IT. Keeping the student authenticated while dropping the
// viewing would be the worst outcome available: a session acting as the student,
// on a school nobody authorised, with no banner and no write refusal.
func viewingBelongsHere(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		seeing, viewing := identity.ViewingFromContext(r.Context())
		if !viewing {
			next.ServeHTTP(w, r)
			return
		}

		school, ok := tenant.FromContext(r.Context())
		if !ok || school.ID != seeing.School {
			web.LoggerFrom(r.Context()).Warn("a viewing arrived at another school",
				"opened_on", seeing.School, "arrived_at", school.ID)
			web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
				"that viewing was opened on a different school")
			return
		}
		next.ServeHTTP(w, r)
	})
}

// consoleReport is the one shape crossing from `report` to `console`, written
// once because both directions of the queue need it — reading it and settling
// one. It drops the account deliberately: `console.Report` has no field for it,
// so a report cannot arrive on a screen carrying who wrote it (K-22).
func consoleReport(one report.Report) console.Report {
	return console.Report{
		ID:         one.ID,
		CourseID:   one.CourseID,
		LessonID:   one.LessonID,
		SectionID:  one.SectionID,
		ExerciseID: one.ExerciseID,
		Version:    one.Version,
		Reason:     one.Reason,
		Note:       one.Note,
		ReportedAt: one.ReportedAt,
	}
}
