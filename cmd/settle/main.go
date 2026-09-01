/*
Command settle brings lapsed subscriptions up to date.

# THE JOB THAT DESCRIBED ITSELF AND NOBODY RAN

`billing.Store.Settle` has said "IT IS A JOB AND NOT A READ" since it was
written, and nothing in `cmd/` called it. That is the same shape `cmd/analyse`
was in before `infra/scheduler.tf` existed — a comment describing machinery is a
claim, and this one was false for as long as it stood.

# WHAT WAS ACTUALLY BROKEN, GIVEN THAT ACCESS WAS ALWAYS RIGHT

Nothing a student could see. `Settle` is a pure function applied on every read,
so a lapsed subscription opens nothing from the moment it lapses whether or not
a row says so. Three other things were wrong and each is invisible from a
screen:

THE TABLE DISAGREED WITH THE CLOCK. `subscriptions.state` said `active` for
terms that ended months ago, so any query counting active subscribers — a SQL
client, a future screen, an export — answered with a number that was never true.

THE HISTORY HAD A HOLE IN IT. `subscription_events` is the answer to "I was
locked out on Tuesday and I had paid", and the ordinary way a subscription ends
on this platform is a term running out. That transition was never written, so
the log recorded every dramatic ending and none of the common one.

AND THE STREAM NEVER SAW ANYBODY STOP. `subscription.ended` reaches the stream
from here and from `Advance`, and `Advance` only carries endings somebody
CAUSED. An instalment plan does not renew itself (N-08), so most endings are a
term elapsing — which meant a retention report read off the stream would have
described a platform nobody ever leaves.

# IT IS ITS OWN COMMAND AND NOT A SECOND HALF OF `analyse`

That job's first line says what it is: "reads how people answered and says which
questions are not doing their job". Settling subscriptions is not that, and a
job whose name describes half of what it does is a name somebody reads and is
wrong about — on the screen that lists jobs, in the log, and in the row this
records.

# IT IS SAFE TO RUN AT ANY TIME AND ANY NUMBER OF TIMES

Settling something already settled changes nothing, which is `Settle`'s own
claim and is why a night that failed simply runs again tomorrow. The count it
prints is what MOVED, not what is lapsed.
*/
package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/codeschool-ing/schooling/internal/catalog"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/job"
	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/platform/logs"
)

func main() {
	log := logs.New(os.Stdout)

	if err := run(log); err != nil {
		log.Error("settling failed", "error", err)
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

	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	log.Info("settling", "version", info.Version, "commit", info.Commit)

	/* THAT THIS RUN HAPPENED, RECORDED BEFORE THE WORK AND CLOSED AFTER IT —
	   the same arrangement `cmd/analyse` makes and for the same reason. A
	   failure to record is not a failure to run: refusing to bring the table
	   into agreement with the clock because a bookkeeping row would not write
	   is trading the thing that matters for the record of it. */
	runs := job.NewStore(pool)
	started, err := runs.Started(ctx, job.Settle, info.Version)
	if err != nil {
		log.Error("this run is not being recorded", "error", err)
	}

	detail, failure := settle(ctx, log, pool)

	if started != uuid.Nil {
		// `WithoutCancel` because the interesting end is the interrupted one:
		// through a cancelled context this write fails and leaves a row saying
		// `running` for ever, which is the shape reserved for a job that
		// vanished without a word.
		if err := runs.Finished(context.WithoutCancel(ctx), started, failure, detail); err != nil {
			log.Error("the end of this run is not recorded", "error", err)
		}
	}
	return failure
}

// settle is the work, split from the bookkeeping around it so that every early
// return is recorded by the one caller.
func settle(ctx context.Context, log *slog.Logger, pool *pgxpool.Pool) (string, error) {
	accounts := identity.NewStore(pool)
	events := event.NewStore(pool)

	/* THE STREAM IS WIRED HERE OR THE POINT IS LOST. This job's whole reason
	   for existing, beyond a tidy table, is that a term running out is the
	   ordinary way a subscription ends and nothing recorded it. A settle
	   without the emitter would fix the table and leave every report reading
	   the stream still describing a platform nobody leaves. */
	plans := billing.NewStore(pool).WithStream(subscriptionEvents(events, accounts, log))

	moved, err := plans.Settle(ctx, time.Now().UTC())
	if err != nil {
		return "", err
	}

	// WHAT MOVED AND NOT WHAT IS LAPSED, which is the honest number for an
	// idempotent sweep: run twice in an hour the second says nothing happened,
	// because nothing did.
	if moved == 1 {
		return "one subscription reached the end of what it had paid for", nil
	}
	return fmt.Sprintf("%d subscriptions reached the end of what they had paid for",
		moved), nil
}

/*
subscriptionEvents counts a subscription's life into the stream.

	IT IS A SECOND COPY OF `cmd/api`'s, and the duplication is the shape this
	repository already uses: `cmd/` is where modules are wired together, each
	command wires the ones it needs, and `cmd/analyse` carries its own copy of
	the same closures `cmd/api` builds the analysis store from. A shared helper
	would be a package under `internal/` whose only job is to know about three
	modules at once, which is the arrangement X-02 exists to prevent.

	WHAT THE TWO MUST AGREE ABOUT is the dimensions, and there is one caller
	here so there is one thing to get right: an ending. `plan` is `none`,
	because that is what a lapsed subscription leaves somebody on, and the
	population comes from the account because K-11 turns on it — a seeded
	student whose term ran out must not appear in a report about real people.

	THE SCHOOL IS ABSENT AND THAT IS THE ANSWER. One subscription covers every
	school (N-02), so `ForPlatform` is the honest dimension.

	IT FAILS NOTHING. A subscription that lapsed and was not counted is a hole
	in a report; a sweep that stopped because a count failed would leave the
	table disagreeing with the clock, which is the thing this job exists to fix.
*/
func subscriptionEvents(events *event.Store, accounts *identity.Store,
	log *slog.Logger) billing.Emit {

	return func(ctx context.Context, name string, accountID uuid.UUID,
		payload map[string]any) {

		account, err := accounts.ByID(ctx, accountID)
		if err != nil {
			log.Error("counting a subscription", "error", err,
				"event", name, "account", accountID)
			return
		}

		/* `PlanNone` WITHOUT A SWITCH ON THE NAME, unlike the copy in `cmd/api`.
		   That one wires every transition and has to derive the plan from which
		   one it is; this job only ever emits an ending, so a switch here would
		   be a branch nothing can take — and the day something else is emitted
		   from this command, a plan that silently said `none` would be worse
		   than a compile error. */
		if name != billing.EventEnded {
			log.Error("this job emitted something other than an ending, and the "+
				"dimensions below are written for an ending", "event", name)
			return
		}

		e := event.Event{
			Name: name,
			Dimensions: event.ForPlatform(string(catalog.PlanNone),
				event.Unknown, account.Locale, who(account)),
			AccountID: &account.ID,
			Payload:   payload,
		}
		if err := events.Emit(ctx, e); err != nil {
			log.Error("counting a subscription", "error", err,
				"event", name, "account", accountID)
		}
	}
}

// who is whether the person this event is about is a real one. K-11 turns on
// it: a seeded student whose term ran out must not reach a report about people.
func who(account identity.Account) event.Population {
	if account.Synthetic {
		return event.Synthetic
	}
	return event.Real
}
