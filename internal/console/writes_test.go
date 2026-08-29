package console_test

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The list of what this console can change, held to the source.

   WITHOUT THIS THE LIST IS PROSE. K-13 asks for a CLOSED list of system
   parameters, and a list nothing checks is closed the way a door nobody locked
   is closed — it stays shut until the first person who does not know about it.
   What makes this one closed is that adding a write to the package fails here
   until somebody writes the sentence for it, and writing that sentence for a
   parameter means arguing that the value has no right answer.

   IT READS THE SOURCE AND NOT THE ROUTER. A mux would answer with what was
   registered by whichever handlers a test happened to construct, which is a
   test that passes by not wiring something up. The registrations are literals
   in this package's own files, and that is what is scanned. */

// Exactly the shape every route in this package is registered with. Anchored on
// `mux.HandleFunc(` so a string that merely looks like a route — in a comment,
// in an error message, in a test — is not mistaken for one.
var registered = regexp.MustCompile(
	`mux\.HandleFunc\("(POST|PUT|PATCH|DELETE) ([^"]+)"`)

func routesInSource(t *testing.T) map[string]string {
	t.Helper()

	entries, err := os.ReadDir(".")
	if err != nil {
		t.Fatalf("reading the package: %v", err)
	}

	out := map[string]string{}
	for _, e := range entries {
		name := e.Name()
		if e.IsDir() || !strings.HasSuffix(name, ".go") || strings.HasSuffix(name, "_test.go") {
			continue
		}
		body, err := os.ReadFile(filepath.Clean(name))
		if err != nil {
			t.Fatalf("reading %s: %v", name, err)
		}
		for _, m := range registered.FindAllStringSubmatch(string(body), -1) {
			out[m[1]+" "+m[2]] = name
		}
	}

	// A scanner that found nothing would pass every assertion below. This
	// package has had writes since the erase path, so zero means the pattern
	// stopped matching rather than that the console became read-only.
	if len(out) == 0 {
		t.Fatal("no write routes found in this package — the console has had them since the " +
			"erase path, so this is the scanner having stopped matching")
	}
	return out
}

// EVERY WRITE IS DECLARED. This is the direction that closes the list: a new
// route costs a sentence, and for a parameter that sentence is an argument.
func TestEveryConsoleWriteIsDeclared(t *testing.T) {
	declared := map[string]bool{}
	for _, w := range console.Writes {
		declared[w.Route] = true
	}

	for route, file := range routesInSource(t) {
		if !declared[route] {
			t.Errorf("%s registers %q and `Writes` does not name it. Add it, and say which "+
				"kind it is: a PARAMETER persists and needs the argument that it has no "+
				"right answer (K-13), an ACTION happens once and leaves no setting behind",
				file, route)
		}
	}
}

// AND NO DECLARATION OUTLIVES ITS ROUTE. The same rule the tenancy exceptions
// and the interface's dictionaries follow, for the same reason: a stale entry
// reads as current, survives every rename around it, and teaches the next
// person that the console can do something it cannot.
func TestNoDeclaredWriteIsGone(t *testing.T) {
	inSource := routesInSource(t)

	for _, w := range console.Writes {
		if _, there := inSource[w.Route]; !there {
			t.Errorf("`Writes` names %q and nothing registers it — an entry that outlived "+
				"its route is worse than a missing one, because it reads as current", w.Route)
		}
	}
}

// A KIND IS ONE OF THE TWO, AND A REASON IS A SENTENCE. Weak checks on their
// own; what they hold is the shape of the cost — an entry added to silence the
// test above cannot be added blank.
func TestEveryDeclaredWriteSaysWhatItIsAndWhy(t *testing.T) {
	for _, w := range console.Writes {
		if w.Kind != console.Parameter && w.Kind != console.Action {
			t.Errorf("%q is a %q, which is neither a parameter nor an action", w.Route, w.Kind)
		}
		if len(w.Why) < 40 {
			t.Errorf("%q is declared with %q, which is not the argument for it",
				w.Route, w.Why)
		}
	}
}

/*
THE LIST IS SHORT, AND THAT IS THE FEATURE RATHER THAN A COINCIDENCE.

K-13's whole claim is that a configuration surface grows to fill the space it is
given. A test cannot know whether a colour has a right answer — but it can
notice that the set of things this platform lets somebody configure has grown,
which is the moment the claim is worth re-reading rather than a moment to reach
for a settings row.

WHAT THIS NUMBER COUNTS CHANGED WITH `0046`, and the difference is worth being
exact about, because a count that quietly stopped counting the same thing is a
ratchet that has come loose.

It counts WRITE ROUTES of the parameter kind, and it always did. Three of the
four are one value each — a school's accent, the price of a term, where a
student writes. The fourth is `settings/{name}`, which is every other knob this
platform has, and it is ONE entry here because it is one route: what closes the
set behind it is not this file but `internal/platform/setting`, where each name
is a declaration in the module that owns the decision, and `cmd/api`'s
`TestEveryParameterCarriesItsArgument`, which fails a declaration without an
argument, without a fence, or with a fence it cannot move inside.

So this test no longer holds the number of knobs. It holds the number of DOORS,
and a fifth one is still a diff saying K-13 was read first.

The number is what it is today. Passing it is not permission to raise it.
*/
func TestTheParameterRoutesAreStillFew(t *testing.T) {
	/* FOUR SINCE THE REGISTRY, and this is the diff saying K-13 was read first.
	   The argument is in `writes.go` beside the entry, in `0046` at length, and
	   in `internal/platform/setting`'s package comment; the short version is
	   that the guarantee moved from "a knob costs a table" to "a knob costs a
	   declaration and an argument", which is the same cost in the place that
	   was actually paying it.

	   The growth this watches for is a fifth ROUTE that writes a persisting
	   value outside the registry — which is somebody routing around the
	   declaration rather than writing one. */
	const known = 4

	if got := len(console.Parameters()); got != known {
		t.Errorf("this console has %d parameter routes and had %d. If that is right, read "+
			"K-13 and change this number in the same commit — and check first whether what "+
			"you want is a `setting.Declared` beside the code that reads it, which is where "+
			"a new knob goes and costs no route at all",
			got, known)
	}
}
