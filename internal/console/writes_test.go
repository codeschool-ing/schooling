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

The number is what it is today. Passing it is not permission to raise it: what
it asks for is that somebody who wants a third parameter says here, in a diff,
that they read K-13 first.
*/
func TestTheParametersAreStillFew(t *testing.T) {
	/* THREE SINCE THE SUPPORT ADDRESS, and this is the diff saying K-13 was read
	   first. The argument for it is in `writes.go` beside the entry and in
	   `0044` at length; the short version is that it is a fact about who is
	   answering rather than about the platform, and that it was already
	   settable — from a gitignored file on one machine, where an apply run from
	   anywhere else planned it back to empty and took a published legal right's
	   only channel off the screen with nothing failing.

	   Moving a value that already had no right answer is not the growth this
	   test watches for. The growth would be a fourth entry whose sentence reads
	   "so it can be configured". */
	const known = 3

	if got := len(console.Parameters()); got != known {
		t.Errorf("this console has %d parameters and had %d. If that is right, read K-13 "+
			"and change this number in the same commit: a value with a right answer belongs "+
			"in code where a test holds it, and only something without one becomes a knob",
			got, known)
	}
}
