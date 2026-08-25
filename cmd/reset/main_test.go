package main

import (
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/privacy"
)

/*
EVERY TABLE IS EITHER KEPT OR EMPTIED, AND THE TWO ADD UP TO THE REGISTRY.

	This is the check the whole command rests on. `privacy.Registry` is every
	table in the database and a test already holds it to that, so a table added
	tomorrow appears there — and the moment it does, this decides what a reset
	does with it.

	DEFAULTING EITHER WAY WOULD BE WORSE. Kept by default leaves somebody's
	history in a database somebody believes is empty; emptied by default throws
	away a configuration table on the one run nobody is watching closely. So a
	new table lands in `emptied()` and this test is what makes somebody look at
	it — the failure arrives when the table is added, not on the night of the
	reset.
*/
func TestEveryTableIsEitherKeptOrEmptied(t *testing.T) {
	if _, err := emptied(); err != nil {
		t.Fatalf("the two halves do not add up to the registry: %v", err)
	}

	for name := range kept {
		if wiped[name] != "" {
			t.Errorf("%s is in both lists", name)
		}
	}
	if len(kept)+len(wiped) != len(privacy.Registry) {
		t.Errorf("this command names %d tables and the registry has %d",
			len(kept)+len(wiped), len(privacy.Registry))
	}
}

// AND EVERY NAME THIS FILE SPELLS IS A REAL TABLE. A rename leaves an entry
// that reads as a decision and is a typo — kept silently, emptied silently, or
// a trigger that is never suspended and stops the whole reset at three in the
// morning.
func TestEveryNameSpeltHereIsATable(t *testing.T) {
	for _, names := range []map[string]string{kept, wiped, guards, viaAccounts} {
		for name := range names {
			if _, known := privacy.ByName(name); !known {
				t.Errorf("%s is not in the registry", name)
			}
		}
	}
}

// THE FOUR TABLES A SPARED OPERATOR LIVES IN ARE NOT TRUNCATED. Truncating
// `account_credentials` while the account row survives is a door with the lock
// taken out — it would look like it worked and refuse the password.
func TestASparedOperatorsTablesAreNotTruncated(t *testing.T) {
	for name := range viaAccounts {
		if kept[name] != "" {
			t.Errorf("%s is in `kept`, so it would never be emptied at all", name)
		}
		if wiped[name] == "" {
			t.Errorf("%s is not in `wiped`, so nothing empties it", name)
		}
		if _, isGuarded := guards[name]; isGuarded {
			t.Errorf("%s carries an append-only guard and is also deleted by row, which "+
				"is a combination this command does not handle", name)
		}
	}
}

/*
THE COUNT IS WHAT GOES, AND FOR THREE TABLES IT WAS WHAT WAS THERE.

	`accounts` had the spared people subtracted from it and the three tables that
	cascade from it did not, so a reset sparing one operator reported their own
	password and their own `staff` row as removed. The run that found it printed
	`staff 1` and, in the next line, that the operator still had their role —
	both from the same command, and only one of them true.

	It is the audit entry that makes it matter rather than the printout. That row
	opens the new history and is the one nobody can ever check against the old
	one, because the old one is what just went.
*/
func TestTheCountAsksWhatGoesAndNotWhatIsThere(t *testing.T) {
	for table, column := range viaAccounts {
		query := counting(table)

		if !strings.Contains(query, column+" <> ALL") {
			t.Errorf("counting %s is %q — a spared operator's rows are in that number "+
				"and they are not going anywhere", table, query)
		}
	}

	// AND EVERY OTHER TABLE COUNTS ALL OF ITSELF, because all of it goes. A
	// `WHERE` here would be a filter nobody asked for, quietly under-reporting
	// the half of the history that has no account on it at all.
	for _, table := range []string{"events", "visitors", "sessions"} {
		if query := counting(table); strings.Contains(query, "WHERE") {
			t.Errorf("counting %s is %q, and every row of it goes", table, query)
		}
	}
}

// AND THE COLUMN NAMED IS THE ONE THE SCHEMA POINTS AT `accounts` WITH. A typo
// here is not a wrong number: `counting` puts it straight into SQL, so the
// count fails and takes the whole reset with it, inside the transaction, at
// the worst possible moment.
func TestEveryCascadeNamesItsOwnColumn(t *testing.T) {
	for table, column := range viaAccounts {
		want := "account_id"
		if table == "accounts" {
			want = "id"
		}
		if column != want {
			t.Errorf("%s points at accounts with %q, want %q", table, column, want)
		}
	}
}

func TestTheFlagsAreReadWhereverTheyAppear(t *testing.T) {
	for _, c := range []struct {
		name     string
		args     []string
		wantRest []string
		wantBy   string
		wantKeep []string
	}{
		{"after the argument, as documented",
			[]string{"example.tld", "--by", "Alexandre"},
			[]string{"example.tld"}, "Alexandre", nil},

		{"before it",
			[]string{"--by", "Alexandre", "example.tld"},
			[]string{"example.tld"}, "Alexandre", nil},

		{"with equals signs",
			[]string{"example.tld", "--by=Alexandre", "--keep=ana@example.tld"},
			[]string{"example.tld"}, "Alexandre", []string{"ana@example.tld"}},

		// TWO PEOPLE OPERATE THIS, so the flag repeats. A comma-separated list
		// is where the second address gets a space in front of it.
		{"two doors held open",
			[]string{"example.tld", "--by", "Alexandre",
				"--keep", "ana@example.tld", "--keep", "bruno@example.tld"},
			[]string{"example.tld"}, "Alexandre",
			[]string{"ana@example.tld", "bruno@example.tld"}},

		{"nothing at all", nil, []string{}, "", nil},
	} {
		t.Run(c.name, func(t *testing.T) {
			rest, by, keep := flags(c.args)

			if by != c.wantBy {
				t.Errorf("--by = %q, want %q", by, c.wantBy)
			}
			if len(rest) != len(c.wantRest) {
				t.Fatalf("the arguments left are %v, want %v", rest, c.wantRest)
			}
			for i := range rest {
				if rest[i] != c.wantRest[i] {
					t.Errorf("argument %d is %q, want %q", i, rest[i], c.wantRest[i])
				}
			}
			if len(keep) != len(c.wantKeep) {
				t.Fatalf("--keep = %v, want %v", keep, c.wantKeep)
			}
			for i := range keep {
				if keep[i] != c.wantKeep[i] {
					t.Errorf("--keep %d is %q, want %q", i, keep[i], c.wantKeep[i])
				}
			}
		})
	}
}
