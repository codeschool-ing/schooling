// Command analyse reads how people answered and says which questions are not
// doing their job.
//
// # IT IS A JOB BECAUSE THE ANSWER IS EXPENSIVE AND THE QUESTION IS ASKED ON A
// SCREEN
//
// Computing a discrimination index across every answer to every question, every
// time somebody opens the console, is a report that gets slower as the platform
// gets more useful. So it runs on a schedule, writes a rollup, and the console
// reads the rollup.
//
// THE SCHEDULE IS `infra/scheduler.tf`, at ten past three every morning in São
// Paulo. That sentence is named here because the paragraph above it was true of
// the design and false of the deployment for as long as this command existed:
// there was no job and no scheduler, and this had never run in production once.
// A comment describing machinery is a claim, and this one now says where to go
// and check it.
//
// # IT RECOMPUTES RATHER THAN RESUMING
//
// A resumable job would merge new answers into stored counts, and a merge is
// where a double-counted event lands — which is the one failure that would make
// a verdict wrong in the direction of condemning a question nobody complained
// about. Counting the stream from scratch cannot double-count, because the
// stream is what it counts.
//
// # AND THEN IT ACTS
//
// A question the strong students fail goes out of circulation, audited, with
// the numbers that decided it. Left in the pool it keeps being asked, and every
// student who meets it is marked on our mistake — and waiting for somebody to
// read a list is the same as not acting, because the list is read on the days
// somebody remembers to read it.
//
// The sweep is idempotent, so the count this prints is what CHANGED tonight
// rather than everything that is out of circulation.
package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/analysis"
	"github.com/codeschool-ing/schooling/internal/audit"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/job"
	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/visitor"
)

func main() {
	log := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	if err := run(log); err != nil {
		log.Error("the analysis failed", "error", err)
		os.Exit(1)
	}
}

func run(log *slog.Logger) error {
	// The window. A year by default, because a question edited eighteen months
	// ago should not be judged forever on answers to the version before it —
	// and because a window somebody has to remember to pass is a window nobody
	// passes.
	window := flag.Duration("window", 365*24*time.Hour,
		"how far back to read answers; 0 reads everything")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load()
	if err != nil {
		return err
	}

	info := build.Current()
	log.Info("analysing", "version", info.Version, "commit", info.Commit,
		"window", window.String(), "minimum_sample", analysis.MinimumSample)

	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	/* THAT THIS RUN HAPPENED, RECORDED BEFORE THE WORK AND CLOSED AFTER IT.

	   The console showed when the rollup was last WRITTEN, which answers a
	   different question: a job that failed at 03:10, a job somebody disabled in
	   March and a job that ran perfectly and changed nothing all look like a
	   stale `computed_at`. This says when it was last ATTEMPTED.

	   A FAILURE TO RECORD IS NOT A FAILURE TO RUN, which is the opposite of the
	   console's rule and right for the opposite reason. There, an action nobody
	   can account for must not happen. Here the work withdraws broken questions
	   from in front of students, and refusing to do it because a bookkeeping row
	   would not write is trading the thing that matters for the record of it. */
	runs := job.NewStore(pool)
	started, err := runs.Started(ctx, job.Analyse, info.Version)
	if err != nil {
		log.Error("this run is not being recorded", "error", err)
	}

	detail, failure := analyse(ctx, log, pool, *window)

	if started != uuid.Nil {
		/* `WithoutCancel` BECAUSE THE INTERESTING END IS THE INTERRUPTED ONE.
		   On SIGTERM the context is already cancelled, so writing through it
		   would fail and leave a row that says `running` for ever — which is
		   the shape reserved for a job that vanished without a word. A run that
		   was stopped knows it was stopped, and should say so. */
		if err := runs.Finished(context.WithoutCancel(ctx), started, failure, detail); err != nil {
			log.Error("the end of this run is not recorded", "error", err)
		}
	}
	return failure
}

// analyse is the work, split from the bookkeeping around it so that every
// early return is recorded by the one caller rather than by a defer that has to
// reach into a named result.
//
// IT ANSWERS A SENTENCE AS WELL AS AN ERROR. What the row says about a
// successful run is the only thing distinguishing "it ran and found nothing"
// from "it ran", and a screen that could not tell those apart would be the
// `computed_at` problem again one table along.
func analyse(ctx context.Context, log *slog.Logger,
	pool *pgxpool.Pool, window time.Duration) (string, error) {

	events := event.NewStore(pool)

	// THE TWO MODULES MEET HERE AND NOWHERE ELSE. `event` owns the stream and
	// hands rows over as they are; `analysis` decides what they mean and never
	// touches that table. Each of these closures is one of them talking to the
	// other in a shape the other defined (X-02).
	//
	// `CountingReal` IS NOT A DEFAULT HERE, IT IS A RULE, and there is
	// deliberately no flag to change it. This job does not only report: a
	// question the strong students fail goes out of circulation at the end of
	// it. Run over the seeded population it would quarantine real questions out
	// of real courses on the strength of students who were invented — which is
	// the exact damage K-11 names. What may look at the seeded history is
	// something that reports and says so, which this is not.
	items := analysis.NewStore(pool,
		func(ctx context.Context, school uuid.UUID, since time.Time) ([]analysis.Answer, error) {
			answers, err := events.ItemAnswers(ctx, school, since, event.CountingReal)
			if err != nil {
				return nil, err
			}
			out := make([]analysis.Answer, 0, len(answers))
			for _, a := range answers {
				out = append(out, analysis.Answer{
					ExerciseID: a.ExerciseID, Version: a.Version, Type: a.Type,
					AttemptID: a.AttemptID, Correct: a.Correct,
					Score: a.Score, Of: a.Of, AnsweredAt: a.AnsweredAt,
				})
			}
			return out, nil
		},
		events.Schools,
	).WithAudit(recordedBy(audit.NewStore(pool))).
		// AND THE THIRD MODULE THE FUNNEL NEEDS. The top of it is browsers and
		// the bottom is accounts, so folding the two into one person needs the
		// link between them — which `visitor` owns and neither of the others
		// may reach for.
		WithStream(
			func(ctx context.Context, school uuid.UUID, names []string,
				since time.Time, who analysis.Counting) ([]analysis.Reach, error) {

				/* THE WORD IS TRANSLATED FAITHFULLY HERE, AND FIXED AT THE CALL
				   SITE BELOW. A reader that quietly ignored `who` and always
				   asked for real people would be a lie the day somebody wired it
				   to a screen with a switch on it. What keeps this job off the
				   seeded population is that it passes `CountingReal` and has no
				   flag to pass anything else — the decision is visible where it
				   is made, not buried in a closure. */
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

	now := time.Now().UTC()
	since := time.Time{}
	if window > 0 {
		since = now.Add(-window)
	}

	written, err := items.Run(ctx, since, now)
	if err != nil {
		return "", err
	}

	// WHAT IT FOUND, SAID OUT LOUD. A job that writes rows and prints a count
	// is a job nobody reads the output of, and the row that matters is the one
	// saying a key is inverted.
	schools, err := events.Schools(ctx)
	if err != nil {
		return "", err
	}

	flagged := 0
	for _, school := range schools {
		bad, err := items.Flagged(ctx, school)
		if err != nil {
			return "", err
		}
		for _, one := range bad {
			flagged++
			log.Warn("a question the strong students fail",
				"school", school, "exercise", one.ExerciseID, "version", one.Version,
				"attempts", one.Attempts, "share_correct", fmt.Sprintf("%.2f", one.Difficulty),
				"discrimination", fmt.Sprintf("%.2f", one.Discrimination),
				"strong_group", one.StrongGroup, "weak_group", one.WeakGroup,
				"minimum_sample", one.MinimumSample)
		}
	}

	// AND THEN IT ACTS. Left in the pool, a question we already know is broken
	// keeps being asked, and every student who meets it is marked on our
	// mistake. Waiting for somebody to read a list is the same as not acting:
	// the list is read on the days somebody remembers to read it, and two
	// people run this.
	//
	// The sweep is idempotent, so this reports what CHANGED tonight rather than
	// everything that is out of circulation.
	took := 0
	for _, school := range schools {
		taken, err := items.Sweep(ctx, school, now)
		if err != nil {
			return "", err
		}
		for _, q := range taken {
			took++
			log.Warn("taken out of circulation",
				"school", school, "exercise", q.ExerciseID, "version", q.Version)
		}
	}

	// THE FUNNEL, PRINTED WHERE SOMEBODY WILL SEE IT. This used to say "there is
	// no console yet"; there is one now, and this stays anyway — for the reason
	// the reverse would be a mistake.
	//
	// The screen is a person asking. This is a run that happened, on a schedule,
	// against real people, with the numbers in the log beside the questions this
	// job took out of circulation on the same night. Deleted, the only record of
	// what the funnel looked like on the evening something changed would be a
	// screen nobody had open. It costs eight lines of output a day.
	quiet := 0
	for _, school := range schools {
		/* REAL PEOPLE, AND THIS JOB HAS NO WAY TO ASK FOR ANYTHING ELSE. It is
		   the job that WITHDRAWS a question, and a run that had a flag for the
		   seeded population would be one argument away from acting on invented
		   answers (K-11). The console's screen is where the other populations
		   may be looked at, because a screen can say on its face that it is
		   doing so and a cron job cannot. */
		funnel, err := items.Funnel(ctx, school, since, analysis.CountingReal)
		if err != nil {
			return "", err
		}

		// A SCHOOL WHERE NOBODY DID ANYTHING HAS NO FUNNEL TO SHOW, and
		// printing eight zeroes for each of them is how the one school with
		// numbers in it gets scrolled past.
		if reached(funnel) == 0 {
			quiet++
			continue
		}

		fmt.Printf("\nthe funnel, school %s, since %s\n", school, sinceSaid(since))
		for _, step := range funnel {
			if !step.Measured {
				// NOT A ZERO. A zero here reads as everybody dropping out, and
				// what is true is that nothing counts this step yet.
				fmt.Printf("  %-28s  no event yet — %s\n", step.Label, step.Why)
				continue
			}
			fmt.Printf("  %-28s  %d\n", step.Label, step.People)
		}
	}

	if quiet > 0 {
		fmt.Printf("\n%d school(s) had nobody reach any step in this window\n", quiet)
	}

	switch {
	case written == 0:
		fmt.Println("no exam has been sat yet, so there is nothing to say about any question")
	case flagged == 0:
		fmt.Printf("%d question(s) measured, none of them inverted\n", written)
	default:
		fmt.Printf("%d question(s) measured, %d inverted, %d newly out of circulation\n",
			written, flagged, took)
	}
	/* THE SENTENCE THE ROW KEEPS, and it is the same three cases the print above
	   distinguishes. A run that found nothing and a run that withdrew nine
	   questions are both successes and are not the same night, and a screen
	   showing only `ok` would make somebody open the logs to learn which. */
	said := fmt.Sprintf("%d question(s) measured, %d inverted, %d newly out of circulation",
		written, flagged, took)
	if written == 0 {
		said = "no exam has been sat yet, so there was nothing to measure"
	}
	return said, nil
}

// reached is how many people got to the widest step, which is what "did
// anything happen here" means for a funnel.
func reached(funnel []analysis.Step) int {
	most := 0
	for _, step := range funnel {
		if step.Measured && step.People > most {
			most = step.People
		}
	}
	return most
}

// sinceSaid is the window as a person reads it. The zero time means everything,
// and printing "0001-01-01" would be a report explaining itself in a way nobody
// can use.
func sinceSaid(since time.Time) string {
	if since.IsZero() {
		return "the beginning"
	}
	return since.Format(time.DateOnly)
}

// recordedBy turns this module's idea of an administrative action into the
// audit log's.
//
// THE ACTOR IS THE SYSTEM AND IT IS NAMED. A job acting on its own is a real
// actor rather than an absent one — an audit entry with a blank where the actor
// goes is the entry somebody finds a year later and cannot use.
func recordedBy(log *audit.Store) analysis.Audit {
	return func(ctx context.Context, action string, tenantID uuid.UUID,
		exerciseID string, version int, before, after any, reason string) error {

		school := tenantID
		return log.Record(ctx, audit.Entry{
			Actor:       audit.System("item analysis"),
			Action:      action,
			SubjectKind: "question",
			SubjectID:   fmt.Sprintf("%s@%d", exerciseID, version),
			Before:      before,
			After:       after,
			TenantID:    &school,
			Reason:      reason,
		})
	}
}

// counting says that this module's word for a population and the stream's are
// the same word.
//
// THE TWO TYPES EXIST BECAUSE A MODULE MAY NOT IMPORT A MODULE (X-02), and this
// is the one line that is the price of it. It is exhaustive on purpose rather
// than a cast: both sides fall back to `real` for a value they do not know, so
// the failure mode of a missed case is a narrower population and never a report
// about people that quietly counts invented ones.
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
