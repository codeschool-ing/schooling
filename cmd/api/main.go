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
	"github.com/codeschool-ing/schooling/internal/legal"
	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
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
			SetPrice:  priceOf(tenant.NewStore(pool)),
			Prices:    pricesOf(tenant.NewStore(pool)),
			Refused:   func(err error) bool { return errors.Is(err, tenant.ErrNotAPrice) },
		},
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
	}).Routes(staffAPI)

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
			cents, currency := s.Price()
			out = append(out, console.School{
				ID: s.ID, Slug: s.Slug, Name: s.Name, Accent: s.Accent,
				PriceCents: cents, Currency: currency,
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

// priceOf and pricesOf are the console's other two writes and reads against a
// school. `SetPrice` APPENDS — see `tenant.SetPrice` and K-14 — and the shape of
// this closure is the only place that difference is invisible, which is why the
// seam it fills is documented as a series rather than as a setter.
func priceOf(schools *tenant.Store) func(context.Context, uuid.UUID, int, string) (int, string, error) {
	return func(ctx context.Context, id uuid.UUID, cents int, currency string) (int, string, error) {
		was, wasCurrency, err := schools.SetPrice(ctx, id, cents, currency)
		if errors.Is(err, tenant.ErrNoSchool) {
			return 0, "", console.ErrNoSchool
		}
		return was, wasCurrency, err
	}
}

func pricesOf(schools *tenant.Store) func(context.Context, uuid.UUID) ([]console.Price, error) {
	return func(ctx context.Context, id uuid.UUID) ([]console.Price, error) {
		rows, err := schools.Prices(ctx, id)
		if err != nil {
			return nil, err
		}
		out := make([]console.Price, 0, len(rows))
		for _, one := range rows {
			out = append(out, console.Price{
				Cents: one.Cents, Currency: one.Currency, From: one.From,
			})
		}
		return out, nil
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
