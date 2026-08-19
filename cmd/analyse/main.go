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
// # IT RECOMPUTES RATHER THAN RESUMING
//
// A resumable job would merge new answers into stored counts, and a merge is
// where a double-counted event lands — which is the one failure that would make
// a verdict wrong in the direction of condemning a question nobody complained
// about. Counting the stream from scratch cannot double-count, because the
// stream is what it counts.
//
// # WHAT IT DOES NOT DO
//
// It does not quarantine anything. Writing the verdict and acting on it are
// separate on purpose: the numbers had to exist and be looked at before
// anything was allowed to remove a question from a course on their say-so.
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

	"github.com/codeschool-ing/schooling/internal/analysis"
	"github.com/codeschool-ing/schooling/internal/audit"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
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

	events := event.NewStore(pool)

	// THE TWO MODULES MEET HERE AND NOWHERE ELSE. `event` owns the stream and
	// hands rows over as they are; `analysis` decides what they mean and never
	// touches that table. Each of these closures is one of them talking to the
	// other in a shape the other defined (X-02).
	items := analysis.NewStore(pool,
		func(ctx context.Context, school uuid.UUID, since time.Time) ([]analysis.Answer, error) {
			answers, err := events.ItemAnswers(ctx, school, since)
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
	).WithAudit(recordedBy(audit.NewStore(pool)))

	now := time.Now().UTC()
	since := time.Time{}
	if *window > 0 {
		since = now.Add(-*window)
	}

	written, err := items.Run(ctx, since, now)
	if err != nil {
		return err
	}

	// WHAT IT FOUND, SAID OUT LOUD. A job that writes rows and prints a count
	// is a job nobody reads the output of, and the row that matters is the one
	// saying a key is inverted.
	schools, err := events.Schools(ctx)
	if err != nil {
		return err
	}

	flagged := 0
	for _, school := range schools {
		bad, err := items.Flagged(ctx, school)
		if err != nil {
			return err
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
			return err
		}
		for _, q := range taken {
			took++
			log.Warn("taken out of circulation",
				"school", school, "exercise", q.ExerciseID, "version", q.Version)
		}
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
	return nil
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
