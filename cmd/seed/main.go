// Command seed writes a past.
//
// # WHY A POPULATION HAS TO BE INVENTED
//
// The console's next two screens are the funnel and item analysis, and neither
// can be built against what this platform contains. A funnel with four events in
// it is four boxes in a column; a discrimination index over three answers is
// noise with a label on it. Both screens are about SHAPE — where people fall
// out, which question the strong students fail — and shape does not exist below
// a population.
//
// That is what K-09 says a seeded student is for: so a screen can be built and
// checked before there is a population to make it legible. This is the thing
// that makes them.
//
// # WHAT IT WRITES, AND THE ONE THING IT BACKDATES
//
// It writes the EVENT STREAM, and that is the whole of the invented past.
// Everything else it creates — an account, a visitor, the link between them —
// exists so the stream has something real to point at, and each of those rows
// carries the moment this command ran, which is true.
//
// The reason is the first line of `internal/event`: statistics come from the
// stream and never from current state. A cohort by signup is `account.created`
// in the stream and not `accounts.created_at`, so backdating the accounts table
// would be inventing a past in the one place nothing reads it from.
//
// # AND THE THREE TABLES IT DELIBERATELY DOES NOT TOUCH
//
// No subscription, no transition, no ledger entry. Their timestamps are not
// settable and must not become settable: those three tables answer "what
// happened to this person's money", and a fabricated row in them is
// indistinguishable from one a payment produced. A seeded student can be told
// apart from a real one everywhere else, because every row this writes says
// `synthetic`; money that never moved would say nothing at all.
//
// The cost is written down rather than hidden: of the four behaviours the
// roadmap asks a seeder for — abandonment, returns, duplicate signups and
// refunds — this makes three. A refund is not representable in the stream today
// because nothing emits a subscription event into it, which is also why the
// funnel's last step comes back saying "not measured". The day a gateway puts
// those events in the stream, this gains the fourth by writing them.
//
// # IT CANNOT BE UNDONE
//
// `events` is append-only by trigger — no update, no delete, enforced by the
// database and not by a habit. So there is no `--clean`, and there cannot be
// one: a seeded past stays in the stream for as long as the stream does. Every
// read excludes it by default (K-11) and the two that can be told to include it
// have to be told by name, which is the protection that actually exists.
//
// Run it deliberately, on a database you meant, and read what it prints.
//
//	seed --school code --people 1000 --months 6 --by "Alexandre"
//
// # IT CHECKS ITSELF, AND THAT IS THE POINT OF THE LAST BLOCK
//
// One exam question is seeded with an INVERTED key: the students who did well on
// the paper get it wrong more often than the students who did badly. Then the
// command reads its own answers back and runs them through `analysis`, which is
// the same code the console will show and the nightly job acts on — and prints
// the verdict per question.
//
// If the planted question does not come back `inverted`, the machinery that is
// supposed to find a broken answer key does not find one, and this says so
// rather than exiting quietly. That is phase 4's `Done when` asked as a question
// every run answers.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"math/rand"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/analysis"
	"github.com/codeschool-ing/schooling/internal/audit"
	"github.com/codeschool-ing/schooling/internal/event"
	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/visitor"
)

func main() {
	if err := run(os.Args[1:], os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

type options struct {
	school string
	people int
	months int
	rand   int64
	by     string
}

func run(args []string, out io.Writer) error {
	var o options
	fs := flag.NewFlagSet("seed", flag.ContinueOnError)
	fs.StringVar(&o.school, "school", "", "the slug of the school to seed a past for")
	fs.IntVar(&o.people, "people", 1000, "how many people arrive over the window")
	fs.IntVar(&o.months, "months", 6, "how far back the window reaches")
	fs.Int64Var(&o.rand, "rand", 1, "the random seed, so a run can be repeated")
	fs.StringVar(&o.by, "by", "", "who is running this, for the audit entry")
	if err := fs.Parse(args); err != nil {
		return err
	}

	switch {
	case o.school == "":
		return errors.New("say which school: --school <slug>")
	case o.by == "":
		// The same argument `cmd/staff` makes: the process cannot know who ran
		// it, and a guess is worse than a question.
		return errors.New("say who is running this: --by \"your name\". " +
			"Seeding a population is an administrative write and it is audited like every other")
	case o.people < 1 || o.months < 1:
		return errors.New("--people and --months are both counts of at least one")
	}

	ctx := context.Background()
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	shape, err := shapeOf(ctx, pool, o.school)
	if err != nil {
		return err
	}

	/* HOW MANY PEOPLE IT TAKES IS ARITHMETIC AND IS SAID BEFORE ANYTHING IS
	   WRITTEN. Item analysis says nothing at all below thirty answers to a
	   question, and a population that lands under it produces a screen of
	   `insufficient` — which looks like the analysis is broken rather than like
	   the sample is small. The stream cannot be un-written, so this refuses
	   first rather than reporting afterwards. */
	if sitters := int(float64(o.people) * reachesTheExam); sitters < analysis.MinimumSample {
		return fmt.Errorf(
			"%d people would put about %d of them through an exam, and item analysis says "+
				"nothing below %d answers to a question — ask for at least %d people, or accept "+
				"a population nothing can be read from",
			o.people, sitters, analysis.MinimumSample, enoughPeople)
	}

	now := time.Now().UTC()
	//nolint:gosec // G404: a seeded population has to be repeatable, which is the
	// opposite of what a cryptographic source is for. Nothing here is a secret:
	// it decides which invented student abandoned a course in March.
	lives := populate(rand.New(rand.NewSource(o.rand)), shape,
		now.AddDate(0, -o.months, 0), now, o.people)

	written, err := write(ctx, pool, shape, lives)
	if err != nil {
		return err
	}

	if err := audit.NewStore(pool).Record(ctx, audit.Entry{
		Actor:       audit.System("the seed command, run by " + o.by),
		Action:      "population.seeded",
		SubjectKind: "school",
		SubjectID:   shape.slug,
		TenantID:    &shape.id,
		After: map[string]any{
			"people": o.people, "months": o.months, "rand": o.rand,
			"accounts": written.accounts, "events": written.events,
			"inverted_key_planted_on": shape.broken,
		},
		Reason: "a seeded population, so the funnel and item analysis can be built against " +
			"a shape rather than against four events",
	}); err != nil {
		// The past is already written and cannot be taken back, so this is
		// reported rather than swallowed — and it is a defect, not a warning.
		return fmt.Errorf("the population was seeded and the audit entry failed, "+
			"which is a defect: %w", err)
	}

	report(out, o, shape, written)
	return verify(ctx, pool, shape, out)
}

/* ---------- writing it ---------- */

type written struct {
	visitors int
	accounts int
	events   int
}

// write puts one planned life at a time into the database.
//
// ONE PERSON AT A TIME AND NOT ONE BATCH. It is slower and it is the shape that
// can be interrupted: a run stopped halfway has written whole people rather than
// every visitor and no account, and a stream where an account.created has no
// arrival before it is a funnel with a step that reads as impossible.
func write(ctx context.Context, pool *pgxpool.Pool, shape shape, lives []life) (written, error) {
	var out written

	visitors := visitor.NewStore(pool)
	accounts := identity.NewStore(pool)
	events := event.NewStore(pool)

	for _, l := range lives {
		here := make([]uuid.UUID, len(l.visitors))
		for i, v := range l.visitors {
			id, _, err := visitors.Create(ctx, uuid.New(), visitor.FirstTouch{
				TenantID: &shape.id, Path: v.path, Referrer: v.referrer,
				Source: v.source, Medium: v.medium, Campaign: v.campaign,
				Country: l.country, Locale: l.locale,
			})
			if err != nil {
				return out, fmt.Errorf("seeding a visitor: %w", err)
			}
			here[i] = id
			out.visitors++
		}

		mine := make([]uuid.UUID, len(l.accounts))
		for i, a := range l.accounts {
			account, err := accounts.Create(ctx, identity.NewAccount{
				Email: a.email, Name: a.name,
				// Long enough to pass, and nobody signs in as these: they are a
				// population, not people with a way back in.
				Password:  "a seeded account that nobody signs in as",
				Locale:    l.locale,
				Country:   l.country,
				Synthetic: true,
			})
			if err != nil {
				return out, fmt.Errorf("seeding an account: %w", err)
			}
			mine[i] = account.ID
			out.accounts++

			// The link is what makes the top and the bottom of the funnel count
			// the same people (K-10), and a duplicate signup links the SAME
			// visitor to a second account — which is the case the funnel's
			// person-definition has to survive rather than one it can assume
			// away.
			if err := visitors.Link(ctx, account.ID, here[a.visitor]); err != nil {
				return out, fmt.Errorf("linking a seeded account: %w", err)
			}
		}

		for _, m := range l.moments {
			e := event.Event{
				Name:    m.name,
				At:      m.at,
				Payload: m.payload,
				Dimensions: event.ForSchool(shape.id, shape.slug, m.plan,
					l.country, l.locale, event.Synthetic),
			}
			if m.visitor >= 0 {
				e.VisitorID = &here[m.visitor]
			}
			if m.account >= 0 {
				e.AccountID = &mine[m.account]
			}
			if err := events.Emit(ctx, e); err != nil {
				return out, fmt.Errorf("seeding an event: %w", err)
			}
			out.events++
		}
	}
	return out, nil
}

/* ---------- what it did, and whether it worked ---------- */

func report(out io.Writer, o options, shape shape, w written) {
	say(out, "%d people over %d months in %s: %d visitors, %d accounts, %d events\n",
		o.people, o.months, shape.slug, w.visitors, w.accounts, w.events)
	say(out, "every one of them is flagged synthetic, which every read excludes "+
		"unless it is told otherwise\n")
	if shape.broken != "" {
		say(out, "the inverted key was planted on %s\n", shape.broken)
	}
}

// verify reads the seeded answers back and asks `analysis` what they say.
//
// THE SAME CODE THE CONSOLE WILL SHOW, and deliberately not a second opinion
// written here: a seeder that checked its own work with its own arithmetic would
// agree with itself about a question the real analysis cannot see.
//
// It REPORTS and does not act. `cmd/analyse` withdraws a flagged question from
// circulation, which is why that job may never look at this population — a real
// question removed from a real course on the strength of invented students is
// the exact damage K-11 exists to prevent.
func verify(ctx context.Context, pool *pgxpool.Pool, shape shape, out io.Writer) error {
	if shape.broken == "" {
		say(out, "%s\n", "this school has no exam questions, so there was nothing to plant "+
			"a broken key on and item analysis has nothing to find")
		return nil
	}

	answers, err := event.NewStore(pool).ItemAnswers(ctx, shape.id, time.Time{},
		event.CountingSeeded)
	if err != nil {
		return err
	}

	byQuestion := map[string][]analysis.Answer{}
	for _, a := range answers {
		byQuestion[a.ExerciseID] = append(byQuestion[a.ExerciseID], analysis.Answer{
			ExerciseID: a.ExerciseID, Version: a.Version, Type: a.Type,
			AttemptID: a.AttemptID, Correct: a.Correct,
			Score: a.Score, Of: a.Of, AnsweredAt: a.AnsweredAt,
		})
	}

	ids := make([]string, 0, len(byQuestion))
	for id := range byQuestion {
		ids = append(ids, id)
	}
	sort.Strings(ids)

	say(out, "%s\n", "\nwhat the statistics say about the questions this population answered:")
	var found bool
	for _, id := range ids {
		s, err := analysis.Summarise(byQuestion[id])
		if err != nil {
			return err
		}
		mark := "  "
		if id == shape.broken {
			mark = "→ "
		}
		say(out, "%s%-16s %-14s %3d answers  difficulty %.2f  discrimination %+.2f\n",
			mark, id, s.Verdict, s.Attempts, s.Difficulty, s.Discrimination)
		if id == shape.broken && s.Verdict == analysis.VerdictInverted {
			found = true
		}
	}

	if !found {
		return fmt.Errorf(
			"\nthe key on %s was seeded inverted and the analysis did not call it inverted. "+
				"The population is written either way — it cannot be taken back — but the thing "+
				"this run was meant to demonstrate did not happen, and a screen built on it "+
				"would be showing a verdict nobody has seen work", shape.broken)
	}
	say(out, "\nthe planted key was found: %s came back inverted, which is what a broken "+
		"answer key looks like from the outside\n", shape.broken)
	return nil
}

// say writes one line of the report.
//
// The error is dropped, deliberately and in one place rather than at fifteen: a
// write to the terminal that fails has nowhere left to be reported to.
func say(out io.Writer, format string, args ...any) {
	_, _ = fmt.Fprintf(out, format, args...)
}

// name is a seeded person's name and address, from a small list crossed with a
// number.
//
// THE DOMAIN IS `.invalid`, WHICH IS RESERVED (RFC 2606) and can never belong to
// anybody. A seeded population with plausible addresses in it is a population
// somebody eventually sends mail to.
func name(r *rand.Rand, run string, n int) (string, string) {
	given := []string{"Ada", "Alan", "Grace", "Edsger", "Barbara", "Ken", "Frances",
		"Donald", "Margaret", "Tony", "Radia", "Leslie"}
	family := []string{"Oliveira", "Souza", "Lovelace", "Hopper", "Liskov", "Perlman",
		"Ferreira", "Almeida", "Knuth", "Hamilton", "Lamport", "Costa"}

	full := given[r.Intn(len(given))] + " " + family[r.Intn(len(family))]
	address := strings.ToLower(strings.ReplaceAll(full, " ", ".")) +
		fmt.Sprintf(".%s.%d@seed.invalid", run, n)
	return full, address
}
