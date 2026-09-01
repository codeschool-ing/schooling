package internal_test

import (
	"go/ast"
	"strconv"
	"strings"
	"testing"
)

/*
THE PAYWALL READS NO PARAMETER, AND THIS IS WHAT SAYS SO.

	K-15: access is an active subscription, a published course and the same
	school. Granting ONE named student access is a legitimate audited action; a
	global switch is not. `internal/catalog/access.go` opens by claiming exactly
	that — "there is no code here that could implement one" — and nothing held
	it to the claim.

	# THE SWITCH NOBODY WOULD CALL A SWITCH

	Nobody adds `paywall.enabled`. What somebody adds is a free preview during
	launch week, or a percentage of the catalogue open to visitors, or a date
	before which everything is free — each a sensible product idea, each landing
	in the registry because that is where a number that has no right answer
	goes, and each read from the package that decides a door. The moment it is
	read there, the answer to "does the paywall work" stops being a property of
	code with a test and becomes a property of a row.

	`setting.Store` makes that worse in a way its own package comment names: it
	keeps a snapshot and refreshes it when stale, so after a write another
	instance answers the old value for a while. For a pass mark that is a
	non-event. For a door it is a door that is open on one instance and shut on
	another, which is not a bug anybody reproduces.

	# WHY THIS IS NOT ALREADY CAUGHT

	`X-02` refuses a module that imports another module and SKIPS `platform` on
	purpose — thirteen packages read the registry, legitimately, for pass marks
	and presence windows and instalment ceilings. So `catalog` importing it
	would pass the architecture test, pass `TestEveryParameterCarriesItsArgument`
	(a well-formed declaration with a good sentence), and pass every test of the
	paywall itself, which would go on being right about whatever the row said.

	# AND THE RULE IS THE IMPORT, NOT THE NAME

	Matching parameter names against words like "access" or "paywall" would be a
	rule about prose, and prose is what somebody rewords. Whether the package
	that decides the door can reach the registry at all is structural, and there
	is no wording around it.
*/
func TestThePackageThatDecidesADoorCannotReadTheRegistry(t *testing.T) {
	// The package whose whole job is whether a student may open a course.
	const decidesTheDoor = "internal/catalog/"

	// What it may not reach, however it is spelled.
	const registry = "/internal/platform/setting"

	/* AND THE FILE THAT STATES THE RULE, which names both in its own prose —
	   `address_test.go` met this the first time it ran, and `tree_test.go`
	   explains that rewording to slip past a match is the "writing around the
	   checker" this repository has already had to undo. */
	const statesTheRule = "internal/paywall_test.go"

	var read int
	eachGoFile(t,
		func(rel string) bool {
			return rel == statesTheRule || !strings.HasPrefix(rel, decidesTheDoor)
		},
		func(rel string, file *ast.File) {
			read++
			for _, imp := range file.Imports {
				path, err := strconv.Unquote(imp.Path.Value)
				if err != nil || !strings.HasSuffix(path, registry) {
					continue
				}
				t.Errorf("%s imports the parameter registry — the paywall is not "+
					"configurable (K-15), and this is the package that decides whether a "+
					"door opens. A launch-week preview or a date before which everything "+
					"is free is a sensible idea and belongs somewhere a wrong value is a "+
					"preference, not here: the moment access is read from a row, \"does "+
					"the paywall work\" stops being something a test can answer. Granting "+
					"ONE student is the audited action that already exists", rel)
			}
		})

	/* THE WALK ITSELF IS ASSERTED, because a rule that reads nothing passes.
	   This one is a single package, so a rename that empties it would leave the
	   test green and the decision unheld — which is the failure mode of every
	   check whose subject can move out from under it. */
	if read == 0 {
		t.Fatalf("no file under %s was read — the package was renamed or moved, and this "+
			"rule is now checking nothing", decidesTheDoor)
	}
}
