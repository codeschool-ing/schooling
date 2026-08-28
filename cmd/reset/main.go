// Command reset empties this platform's history and keeps what it is.
//
// # WHAT IT IS FOR, AND THE DATE THAT DECIDES
//
// Before launch, everything in `events`, `visitors`, `accounts` and the rest is
// two people clicking around. It is development rubbish, it is nobody's, and
// throwing it away costs nothing. AFTER the first real student the identical
// command deletes somebody's practice history, the record of who changed what,
// and the ledger — the same act, and by then it is destruction of evidence.
//
// The difference between those two paragraphs is a date, and an improvised
// `DELETE` at a psql prompt does not know which side of it it is on. That is
// the whole reason this is a command with refusals rather than a paragraph in a
// runbook.
//
// # THE REFUSALS, CHEAPEST FIRST
//
//	--by            an audit entry with nobody against it is a log, not an
//	                audit (K-01), and this writes the first row of the new one.
//
//	THE DOMAIN      it has to be typed, and it has to match the database this
//	                process is configured against. Pressing up-arrow in the
//	                wrong terminal is the way this goes wrong, and a confirmation
//	                prompt does not help with it — the answer to "are you sure"
//	                is always yes. Naming the thing you are about to empty is
//	                the only check that fails for the person who is about to be
//	                wrong.
//
//	MONEY           a row in `ledger_entries` or `subscriptions` means somebody
//	                paid, which is the sharpest possible evidence that this is
//	                no longer a development database. There is no flag to
//	                override it, on purpose.
//
//	--keep NOT STAFF  the one account this will spare has to be an operator's.
//	                Sparing a student's would be keeping a person's data through
//	                an operation whose whole justification is that none of it is
//	                anybody's.
//
//	AN UNKNOWN TABLE  every table is either kept or emptied, and the two lists
//	                below have to add up to `privacy.Registry` exactly. A table
//	                added since this was written stops the reset rather than
//	                being guessed at in either direction.
//
// # WHAT IT KEEPS IS WHAT A FRESH DEPLOYMENT WOULD HAVE
//
// The schools, their addresses, their prices and the catalogue: everything
// `migrate` and `load` and an afternoon in the console would produce again.
// Everything else is a record of something happening, and that is what is being
// thrown away.
//
// # IT EMPTIES THE AUDIT AND THEN WRITES TO IT
//
// In one transaction, so the first row of the new history says the old one was
// erased, by whom, when and how much of it there was. An audit that could not
// say it had been emptied would be the one entry worth having.
//
// # ONE DOOR MAY BE LEFT OPEN
//
// `--keep <email>` spares an operator's account: the row, the password, the
// second factor and the role. Without it a reset locks everybody out and the
// way back in is signing up again and running `cmd/staff` — correct once, and
// tedious on the fifth reset of an afternoon.
//
// EVERYTHING ELSE ABOUT THAT PERSON STILL GOES: their sessions, their events,
// their progress, their notes. What is kept is the door, not the history.
//
//	reset <platform domain> --by <name> [--keep <email>]...
package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/audit"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/privacy"
)

// kept is what this platform IS, as opposed to what has happened to it.
//
// Every name here is checked against `privacy.Registry`, so a rename cannot
// leave a stale entry behind quietly.
var kept = map[string]string{
	"schema_migrations": "which migrations ran, which is a fact about the schema",
	"tenants":           "the schools themselves",
	"tenant_domains":    "the addresses they answer at",
	"plan_prices":       "what the platform charges, which is configuration written as history (K-14)",

	/* KEPT FOR THE REASON THE PRICE IS: it is the platform's own configuration
	   and not anybody's data. A reset that took it away would leave a
	   deployment publishing the seven-day right with nowhere to use it — and
	   the point of moving this value out of the environment was precisely that
	   it should stop vanishing when somebody runs something from elsewhere. */
	"support_contact": "where students are told to write to use the seven days, which is our " +
		"configuration and not anybody's data",

	// THE ONE PIECE OF HISTORY IN THIS MAP, and it is here because emptying it
	// is not a clean slate for us — it is a clean slate for the mailboxes that
	// already refused us, and writing to one again is the complaint we were
	// told not to repeat. It names nobody: a row holds a hash. A reset is meant
	// to cost this platform its data, not its standing with the providers who
	// decide whether anybody else's mail arrives.
	"mail_suppressions": "who refused our mail, as hashes and never addresses",

	"catalog_tracks":            "the catalogue, all of it",
	"catalog_track_forks":       "the catalogue",
	"catalog_track_courses":     "the catalogue",
	"catalog_track_links":       "the catalogue",
	"catalog_track_text":        "the catalogue",
	"catalog_track_fork_text":   "the catalogue",
	"catalog_courses":           "the catalogue",
	"catalog_course_requires":   "the catalogue",
	"catalog_course_topics":     "the catalogue",
	"catalog_course_text":       "the catalogue",
	"catalog_course_topic_text": "the catalogue",
	"catalog_lessons":           "the catalogue",
	"catalog_sections":          "the catalogue",
	"catalog_prose":             "the catalogue",
	"catalog_exercises":         "the catalogue",
	"catalog_exercise_text":     "the catalogue",
	"catalog_images":            "the catalogue",
}

/*
THE APPEND-ONLY TABLES THIS SUSPENDS, BY NAME.

	`0034` puts a `BEFORE TRUNCATE` trigger on six tables so that emptying one
	is refused the way editing a row already was. This is the one place allowed
	to turn them off, it does it inside the transaction that empties them, and
	it names each one — so the code says out loud that it is suspending a
	guarantee rather than finding a gap in it.
*/
var guards = map[string]string{
	"events":              "events_are_not_emptied",
	"practice_review":     "practice_review_is_not_emptied",
	"audit_log":           "audit_log_is_not_emptied",
	"ledger_entries":      "ledger_entries_are_not_emptied",
	"subscription_events": "subscription_events_are_not_emptied",
	"plan_prices":         "plan_prices_are_not_emptied",
}

/*
AND `wiped` IS THE OTHER HALF, WRITTEN OUT RATHER THAN DERIVED.

	The first version of this file computed it — everything in the registry that
	`kept` does not name — and the test that was supposed to force a decision
	about a new table passed happily, because a new table fell into the computed
	side and the two halves added up by construction. A probe row put into the
	registry proved it: green.

	So both halves are spelt, and `emptied` refuses when their union is not the
	registry exactly. A table added tomorrow fails a test on the day it is
	added, which is where somebody is already thinking about it — rather than on
	the night of a reset, which is where nobody is.
*/
var wiped = map[string]string{
	"job_runs":               "when a job last ran, which is history about the machinery",
	"accounts":               "the people, minus whoever --keep spares",
	"account_credentials":    "their passwords; cascades from accounts",
	"account_recovery_codes": "their second factor; cascades from accounts",

	// Kept out of the truncate for `account_credentials`' reason: emptying it
	// while a spared account sits there would leave the operator confirmed with
	// nothing on record saying so, and any link still in their inbox dead.
	"account_email_confirmations": "the links sent to prove an address; cascades from accounts",

	// Kept out of the truncate for the same reason as the line above: a spared
	// operator with a change in flight would otherwise have the row emptied
	// while their account stood, and the link in their inbox would move nothing.
	"account_email_changes": "the links sent to move an address; cascades from accounts",

	"staff":               "who operates the platform; cascades from accounts",
	"sessions":            "who was signed in",
	"visitors":            "the browsers that arrived",
	"account_visitors":    "which browser became which account",
	"events":              "the whole stream, which is what a reset is for",
	"practice_review":     "every answer anybody gave",
	"section_progress":    "what anybody finished",
	"practice_state":      "the schedule of every card",
	"practice_drawn":      "the cards as they were shown",
	"resume_pointer":      "where anybody left off",
	"notes":               "what anybody wrote",
	"content_reports":     "what anybody reported",
	"exam_attempts":       "every sitting",
	"exam_answers":        "every answer in one",
	"certificates":        "every certificate issued",
	"question_quarantine": "what a sweep withdrew, which is derived from answers that are going",
	"item_statistics":     "the rollup, which is derived from the same answers",
	"subscriptions":       "there are none, and the refusal above proves it",
	"subscription_events": "the same, and it is append-only for when there are",
	"ledger_entries":      "the same again, and this is the money",

	// EMPTIED RATHER THAN KEPT, ALTHOUGH THE GATEWAY WILL DISAGREE. A reset
	// costs this platform its data and not the processor's: the charges those
	// rows point at go on existing over there, and a person who paid on a
	// sandbox that was then reset has an invoice we can no longer explain. That
	// is what a reset IS, and it is a reason to run one only where the money is
	// not real.
	"checkout_intents":  "what anybody tried to buy",
	"payment_customers": "who anybody is at a gateway; cascades from accounts",
	"audit_log":         "the history of who did what, emptied and then written to",
}

func main() {
	args, by, keep := flags(os.Args[1:])

	if err := run(args, by, keep); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

// flags pulls --by and --keep out of the arguments wherever they appear. It is
// `cmd/staff`'s `takeBy` with one more flag, for the reason given there: the
// flag package stops at the first non-flag argument, so the documented
// invocation would silently leave them empty.
//
// `--keep` REPEATS rather than taking a list, because two people operate this
// and a comma-separated one is where the second address gets a space in front
// of it.
func flags(args []string) (rest []string, by string, keep []string) {
	rest = make([]string, 0, len(args))
	for i := 0; i < len(args); i++ {
		switch arg := args[i]; {
		case arg == "--by" || arg == "-by":
			if i+1 < len(args) {
				by = args[i+1]
				i++
			}
		case strings.HasPrefix(arg, "--by="):
			by = strings.TrimPrefix(arg, "--by=")
		case strings.HasPrefix(arg, "-by="):
			by = strings.TrimPrefix(arg, "-by=")

		case arg == "--keep" || arg == "-keep":
			if i+1 < len(args) {
				keep = append(keep, args[i+1])
				i++
			}
		case strings.HasPrefix(arg, "--keep="):
			keep = append(keep, strings.TrimPrefix(arg, "--keep="))
		case strings.HasPrefix(arg, "-keep="):
			keep = append(keep, strings.TrimPrefix(arg, "-keep="))

		default:
			rest = append(rest, arg)
		}
	}
	return rest, by, keep
}

func run(args []string, by string, keep []string) error {
	if len(args) != 1 {
		return errors.New("usage: reset <platform domain> --by <name> [--keep <email>]...\n\n" +
			"The domain is the one this process is configured against, and it has to be " +
			"typed: pressing up-arrow in the wrong terminal is how this goes wrong, and " +
			"naming what you are about to empty is the only check that catches it")
	}
	if by == "" {
		return errors.New("--by is required: this writes the first row of the new history, " +
			"and an entry with nobody against it is a log rather than an audit")
	}

	ctx := context.Background()
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	if named, is := strings.ToLower(strings.TrimSpace(args[0])), strings.ToLower(cfg.PlatformDomain); named != is {
		return fmt.Errorf("this process is configured against %q and you named %q — "+
			"one of the two is not the database you meant", is, named)
	}

	empty, err := emptied()
	if err != nil {
		return err
	}

	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	if err := nobodyHasPaid(ctx, pool); err != nil {
		return err
	}

	spared, err := doorsHeldOpen(ctx, pool, keep)
	if err != nil {
		return err
	}

	counted, err := erase(ctx, pool, empty, spared, by, cfg.PlatformDomain)
	if err != nil {
		return err
	}

	fmt.Printf("emptied %d tables at %s, %d rows in all\n",
		len(empty), cfg.PlatformDomain, total(counted))
	for _, name := range sorted(counted) {
		if counted[name] > 0 {
			fmt.Printf("  %-24s %d\n", name, counted[name])
		}
	}
	fmt.Print("\nThe schools, their prices and the catalogue are untouched.\n")
	if len(spared) == 0 {
		fmt.Print("Nobody is staff any more, including you: sign up again and then run\n" +
			"`staff grant <email> owner --by \"<name>\"`.\n")
		return nil
	}
	for _, s := range spared {
		fmt.Printf("%s is still an operator, with their password and second factor.\n", s.email)
	}
	return nil
}

// door is an account this reset spares: the row, the password, the second
// factor and the role.
type door struct {
	id    string
	email string
	role  string
}

/*
THE ONE ACCOUNT THAT MAY BE SPARED HAS TO BE AN OPERATOR'S.

	The justification for this whole command is that none of what it deletes is
	anybody's yet. Sparing a student's account would be keeping a person's data
	through an operation that is only defensible because there are no people in
	it — so the check is not a nicety, it is the thing that keeps the argument
	honest.

	WHAT IS SPARED IS THE DOOR AND NOT THE HISTORY. Their sessions, events,
	progress and notes go with everybody else's. What survives is the ability to
	sign in tomorrow without doing the sign-up dance again, which is the whole
	reason the flag exists.
*/
func doorsHeldOpen(ctx context.Context, pool *pgxpool.Pool, keep []string) ([]door, error) {
	var out []door

	for _, email := range keep {
		email = strings.ToLower(strings.TrimSpace(email))
		if email == "" {
			continue
		}

		var d door
		err := pool.QueryRow(ctx, `
			SELECT a.id::text, a.email, coalesce(s.role, '')
			  FROM accounts a
			  LEFT JOIN staff s ON s.account_id = a.id
			 WHERE a.email = $1
		`, email).Scan(&d.id, &d.email, &d.role)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("there is no account for %q, so there is no door to hold "+
				"open — check the address before emptying everything else", email)
		}
		if err != nil {
			return nil, fmt.Errorf("looking up %s: %w", email, err)
		}
		if d.role == "" {
			return nil, fmt.Errorf("%s is not staff, and only an operator's account may be "+
				"spared: this command is defensible because nothing it deletes is anybody's, "+
				"and keeping a student's account would be the exception that ends that", email)
		}
		out = append(out, d)
	}
	return out, nil
}

// emptied is the list to empty, and the check that the two halves are the whole.
//
// A TABLE IN NEITHER STOPS THE RESET. Defaulting either way is worse: kept by
// default leaves somebody's history in a database somebody believes is empty,
// and emptied by default throws away a configuration table on the one run
// nobody is watching closely. The registry already forces every new table to be
// classified for privacy; this makes it force one more decision, in the same
// place.
func emptied() ([]string, error) {
	var missing, both []string
	for _, t := range privacy.Registry {
		_, keep := kept[t.Name]
		_, wipe := wiped[t.Name]
		switch {
		case keep && wipe:
			both = append(both, t.Name)
		case !keep && !wipe:
			missing = append(missing, t.Name)
		}
	}
	if len(missing) > 0 {
		sort.Strings(missing)
		return nil, fmt.Errorf("this command has no opinion about %s — every table is either "+
			"kept or emptied, and a new one has to be decided rather than guessed at in "+
			"either direction", strings.Join(missing, ", "))
	}
	if len(both) > 0 {
		sort.Strings(both)
		return nil, fmt.Errorf("%s is in both lists", strings.Join(both, ", "))
	}

	var stale []string
	for _, names := range []map[string]string{kept, wiped} {
		for name := range names {
			if _, known := privacy.ByName(name); !known {
				stale = append(stale, name)
			}
		}
	}
	if len(stale) > 0 {
		sort.Strings(stale)
		return nil, fmt.Errorf("this command names %s, which the registry does not have — "+
			"a renamed table leaves an entry here that reads as a decision and is a typo",
			strings.Join(stale, ", "))
	}

	out := make([]string, 0, len(wiped))
	for name := range wiped {
		out = append(out, name)
	}
	sort.Strings(out)
	return out, nil
}

// nobodyHasPaid is the refusal with no flag to get past it.
func nobodyHasPaid(ctx context.Context, pool *pgxpool.Pool) error {
	for _, table := range []string{"ledger_entries", "subscriptions"} {
		var rows int
		// The name comes from the literal slice above and from nowhere else.
		if err := pool.QueryRow(ctx, `SELECT count(*) FROM `+table).Scan(&rows); err != nil {
			return fmt.Errorf("counting %s: %w", table, err)
		}
		if rows > 0 {
			return fmt.Errorf("%s has %d rows, so somebody has paid and this is not a "+
				"development database any more. There is no flag for this one", table, rows)
		}
	}
	return nil
}

// erase does the whole thing in one transaction: count, suspend the guards,
// empty, restore the guards, and write the first row of the new history.
func erase(ctx context.Context, pool *pgxpool.Pool, empty []string, spared []door,
	by, domain string) (map[string]int, error) {

	counted := map[string]int{}

	/* THE FOUR TABLES A SPARED OPERATOR LIVES IN COME OUT OF THE TRUNCATE, and
	   `accounts` is emptied with a DELETE instead. The other three follow it
	   without being named: `account_credentials`, `account_recovery_codes` and
	   `staff` all reference `accounts(id)` with ON DELETE CASCADE, so deleting
	   a person deletes their password, their second factor and their role.
	   Naming them here as well would be a second copy of a rule the schema
	   already holds — and the copy is the one that stops matching. */
	var truncate []string
	for _, table := range empty {
		if _, byCascade := viaAccounts[table]; !byCascade {
			truncate = append(truncate, table)
		}
	}

	ids := make([]string, 0, len(spared))
	for _, d := range spared {
		ids = append(ids, d.id)
	}

	err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		for _, table := range empty {
			var rows int
			var args []any
			if _, byCascade := viaAccounts[table]; byCascade {
				args = append(args, ids)
			}
			if err := tx.QueryRow(ctx, counting(table), args...).Scan(&rows); err != nil {
				return fmt.Errorf("counting %s: %w", table, err)
			}
			counted[table] = rows
		}

		for table, guard := range guards {
			if _, isKept := kept[table]; isKept {
				continue
			}
			if _, err := tx.Exec(ctx, `ALTER TABLE `+table+` DISABLE TRIGGER `+guard); err != nil {
				return fmt.Errorf("suspending %s: %w", guard, err)
			}
		}

		/* ONE STATEMENT, WHICH IS WHAT MAKES THE ORDER SOMEBODY ELSE'S PROBLEM.
		   `TRUNCATE a, b, c` satisfies the foreign keys between them as a set,
		   so there is no ordering to get right and no `CASCADE` that could
		   reach a table this is supposed to keep. If something kept references
		   something emptied, this fails loudly — which is the correct outcome
		   and not one worth working around. */
		if _, err := tx.Exec(ctx,
			`TRUNCATE `+strings.Join(truncate, ", ")+` RESTART IDENTITY`); err != nil {
			return fmt.Errorf("emptying: %w", err)
		}

		/* AND THE PEOPLE, BY DELETE, SO THE SPARED ONES SURVIVE. An empty list
		   deletes everybody, which is the same outcome the truncate would have
		   had — so there is no branch here and no second path to get wrong. */
		if _, err := tx.Exec(ctx,
			`DELETE FROM accounts WHERE id <> ALL($1::uuid[])`, ids); err != nil {
			return fmt.Errorf("emptying accounts: %w", err)
		}

		for table, guard := range guards {
			if _, isKept := kept[table]; isKept {
				continue
			}
			if _, err := tx.Exec(ctx, `ALTER TABLE `+table+` ENABLE TRIGGER `+guard); err != nil {
				return fmt.Errorf("restoring %s: %w", guard, err)
			}
		}

		/* AND THE FIRST ROW OF THE NEW HISTORY SAYS THE OLD ONE WENT. It is
		   written after the table it goes into was emptied, in the same
		   transaction, which is the only order that leaves an audit able to
		   account for its own emptiness. */
		return audit.RecordIn(ctx, tx, audit.Entry{
			Actor:       audit.System(by),
			Action:      "platform.reset",
			SubjectKind: "platform",
			SubjectID:   domain,
			Before:      counted,
			After:       map[string]any{"kept": emails(spared)},
			Reason: "the development history was emptied before launch: no ledger entry " +
				"and no subscription existed, so nothing here was anybody's",
		})
	})
	if err != nil {
		return nil, err
	}
	return counted, nil
}

/*
COUNTING WHAT GOES, WHICH IS NOT THE SAME AS COUNTING WHAT IS THERE.

	The report and the audit entry both say how many rows this reset REMOVED, so
	the four tables a spared operator lives in have to count around them. The
	first version subtracted the spared people from `accounts` alone and counted
	the other three raw, which reported the operator's own password and their own
	`staff` row as removed — on the one run where somebody is reading the numbers
	to decide whether it did what they meant.

	It reads as a rounding error and is not: the audit entry that opens the new
	history is the one row nobody can go back and check against the old one,
	because the old one is what just went.

	`<> ALL('{}')` is true of every row, so a reset that spares nobody counts
	everything without a second path through here to get wrong.
*/
func counting(table string) string {
	query := `SELECT count(*) FROM ` + table
	// Every name came out of `privacy.Registry` and every column out of the map
	// below, both literals in this repository — there is no path from an
	// argument to here.
	if column, byCascade := viaAccounts[table]; byCascade {
		query += ` WHERE ` + column + ` <> ALL($1::uuid[])`
	}
	return query
}

/*
WHERE A SPARED OPERATOR LIVES, AND WHY ONLY ONE OF THE FOUR IS DELETED IN CODE.

	`accounts` is emptied with a DELETE so the spared rows survive. The other
	three go with it through ON DELETE CASCADE, which the schema has said since
	`0004`, `0005` and `0026` — repeating that here would be a second copy of the
	rule, and the copy is the one that stops matching the day somebody changes
	the foreign key.

	They are listed anyway for two reasons. They have to come OUT of the
	truncate: a `TRUNCATE account_credentials` would empty the spared operator's
	password while their account row sat there, which is a door with the lock
	taken out. And the value is the column that points at `accounts`, which is
	what lets `counting` ask each of them how many rows are about to go rather
	than how many exist.
*/
var viaAccounts = map[string]string{
	"accounts":                    "id",
	"account_credentials":         "account_id",
	"account_recovery_codes":      "account_id",
	"account_email_confirmations": "account_id",
	"account_email_changes":       "account_id",
	"staff":                       "account_id",
}

func emails(spared []door) []string {
	out := make([]string, 0, len(spared))
	for _, d := range spared {
		out = append(out, d.email)
	}
	return out
}

func total(counted map[string]int) int {
	var n int
	for _, rows := range counted {
		n += rows
	}
	return n
}

func sorted(counted map[string]int) []string {
	out := make([]string, 0, len(counted))
	for name := range counted {
		out = append(out, name)
	}
	sort.Strings(out)
	return out
}
