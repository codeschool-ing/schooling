package main

import (
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
