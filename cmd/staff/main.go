// Command staff grants and revokes the roles that operate this platform.
//
// WHY A COMMAND AND NOT A SCREEN. The first owner cannot be granted a role by
// the console, because reaching the console needs one — so there has to be one
// door that does not go through the product, and it is this. It runs where the
// database is reachable, which is a deliberate limit: whoever can run it can
// already read every row.
//
// IT WRITES TO THE AUDIT, and that is not decoration. "Every administrative
// write records the actor" (K-01) is either true of every path or it is true of
// none, and a command-line tool that quietly grants an owner is exactly the
// path that makes it none. The actor is the system, with the name of the person
// who ran it — passed in, because the process cannot know it and a guess is
// worse than a question.
//
//	staff grant   <email> <owner|operator|read-only> --by "Alexandre"
//	staff revoke  <email>                            --by "Alexandre"
//	staff list
package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/audit"
	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
)

func main() {
	args, by := takeBy(os.Args[1:])

	if err := run(args, by); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

// takeBy pulls --by out of the arguments wherever it appears.
//
// THE FLAG PACKAGE WOULD NOT DO. It stops parsing at the first non-flag
// argument, so `staff grant ana@example.tld owner --by "Alexandre"` — the form
// written at the top of this file, and the form anybody would type — silently
// leaves `by` empty. A documented invocation that does not work is worse than
// no documentation, and fifteen lines here is cheaper than teaching two people
// that the flag goes first.
func takeBy(args []string) (rest []string, by string) {
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
		default:
			rest = append(rest, arg)
		}
	}
	return rest, by
}

func run(args []string, by string) error {
	if len(args) == 0 {
		return errors.New("usage: staff grant <email> <role> --by <name> | " +
			"staff revoke <email> --by <name> | staff list")
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

	accounts := identity.NewStore(pool)
	entries := audit.NewStore(pool)

	switch args[0] {
	case "grant":
		if len(args) != 3 {
			return errors.New("usage: staff grant <email> <owner|operator|read-only> --by <name>")
		}
		return grant(ctx, pool, accounts, entries, args[1], identity.Role(args[2]), by)

	case "revoke":
		if len(args) != 2 {
			return errors.New("usage: staff revoke <email> --by <name>")
		}
		return revoke(ctx, pool, accounts, entries, args[1], by)

	case "list":
		return list(ctx, pool)

	default:
		return fmt.Errorf("%q is not one of grant, revoke, list", args[0])
	}
}

func grant(ctx context.Context, pool *pgxpool.Pool, accounts *identity.Store,
	entries *audit.Store, email string, role identity.Role, by string) error {

	if by == "" {
		return errors.New("--by is required: an entry in the audit with nobody against it is " +
			"a log, and this is the one path where the process cannot work out who you are")
	}

	id, err := accountID(ctx, pool, email)
	if err != nil {
		return err
	}

	// What it was, so the entry says what changed rather than what it became.
	var before any
	if was, err := accounts.StaffOf(ctx, id); err == nil {
		before = map[string]any{"role": string(was.Role)}
	} else if !errors.Is(err, identity.ErrNotStaff) {
		return err
	}

	if err := accounts.Grant(ctx, id, role, uuid.Nil); err != nil {
		return err
	}

	if err := entries.Record(ctx, audit.Entry{
		Actor:       audit.System("the staff command, run by " + by),
		Action:      "staff.role.granted",
		SubjectKind: "account",
		SubjectID:   id.String(),
		Before:      before,
		After:       map[string]any{"role": string(role)},
		Reason:      "granted from the command line, which is the only door before the console exists",
	}); err != nil {
		// The grant already happened. Failing here would leave the caller
		// believing it did not, which is worse than an audit gap they are told
		// about — so it is reported and the exit code says something went wrong.
		return fmt.Errorf("%s is now %s, but the audit entry failed and that is a defect: %w",
			email, role, err)
	}

	fmt.Printf("%s is now %s\n", email, role)
	if role == identity.RoleOwner || role == identity.RoleOperator {
		fmt.Println("They cannot reach a staff route until they enrol a second factor and " +
			"present it on the session they are using.")
	}
	return nil
}

func revoke(ctx context.Context, pool *pgxpool.Pool, accounts *identity.Store,
	entries *audit.Store, email, by string) error {

	if by == "" {
		return errors.New("--by is required, for the audit")
	}

	id, err := accountID(ctx, pool, email)
	if err != nil {
		return err
	}

	was, err := accounts.StaffOf(ctx, id)
	if errors.Is(err, identity.ErrNotStaff) {
		return fmt.Errorf("%s is not staff", email)
	}
	if err != nil {
		return err
	}

	if err := accounts.RevokeStaff(ctx, id); err != nil {
		return err
	}

	if err := entries.Record(ctx, audit.Entry{
		Actor:       audit.System("the staff command, run by " + by),
		Action:      "staff.role.revoked",
		SubjectKind: "account",
		SubjectID:   id.String(),
		Before:      map[string]any{"role": string(was.Role)},
		Reason:      "revoked from the command line",
	}); err != nil {
		return fmt.Errorf("%s is no longer staff, but the audit entry failed: %w", email, err)
	}

	fmt.Printf("%s is no longer staff, and every session they had is ended\n", email)
	return nil
}

func list(ctx context.Context, pool *pgxpool.Pool) error {
	rows, err := pool.Query(ctx, `
		SELECT a.email, s.role, s.granted_at,
		       EXISTS (SELECT 1 FROM account_credentials c
		               WHERE c.account_id = a.id AND c.kind = 'totp') AS enrolled
		FROM staff s JOIN accounts a ON a.id = s.account_id
		WHERE s.revoked_at IS NULL
		ORDER BY s.role, a.email
	`)
	if err != nil {
		return fmt.Errorf("reading the staff: %w", err)
	}
	defer rows.Close()

	found := false
	for rows.Next() {
		var email, role string
		var granted any
		var enrolled bool
		if err := rows.Scan(&email, &role, &granted, &enrolled); err != nil {
			return fmt.Errorf("reading the staff: %w", err)
		}
		found = true

		// Whether they can actually get in is the thing worth showing beside a
		// role, because a role without a second factor opens nothing.
		second := "NO second factor — cannot reach a staff route"
		if enrolled {
			second = "second factor enrolled"
		}
		fmt.Printf("  %-12s %-40s %s\n", role, email, second)
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("reading the staff: %w", err)
	}
	if !found {
		fmt.Println("  nobody — grant the first owner with `staff grant <email> owner --by <name>`")
	}
	return nil
}

func accountID(ctx context.Context, pool *pgxpool.Pool, email string) (uuid.UUID, error) {
	var id uuid.UUID
	err := pool.QueryRow(ctx,
		`SELECT id FROM accounts WHERE lower(email) = lower($1)`,
		identity.NormaliseEmail(email)).Scan(&id)
	if err != nil {
		return uuid.Nil, fmt.Errorf("no account for %s — they sign up first, then get a role", email)
	}
	return id, nil
}
