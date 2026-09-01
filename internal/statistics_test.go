package internal_test

import (
	"go/ast"
	"go/token"
	"regexp"
	"sort"
	"strings"
	"testing"
)

/*
THE STATISTICS READ THE STREAM, AND THIS IS WHAT SAYS SO.

	K-03: statistics come from `events` and never from current state. The reason
	is not purity — it is that a number derived from a live table answers a
	different question from one derived from the stream, and the two disagree in
	a way nobody can reconcile afterwards. A funnel counting rows in `accounts`
	counts who exists TODAY; the same funnel over `events` counts who arrived.
	Somebody deletes their account and the first number moves for last March.

	# X-02 GUARDS THE IMPORTS AND NOTHING GUARDED THE SQL

	`internal/architecture_test.go` already refuses a module that imports another
	module, and that stops the obvious version: `analysis` cannot reach into the
	package that owns accounts. But `analysis` holds a `*pgxpool.Pool`, and a
	`SELECT count(*) FROM accounts` written straight into it imports nothing,
	passes that test, is faster than the fold it replaces, and is wrong in the
	quietest possible way.

	That is the gap this closes. The rule is about the TABLE NAMES these two
	packages may write, because the table name is the thing somebody would
	actually type.

	# A DECLARED LIST, WITH A REASON EACH

	`analysis` reads its own rollup and the quarantine it writes; `event` reads
	the stream. Anything else is a number coming from somewhere this decision
	says it must not come from. A table added here is a decision somebody makes
	deliberately and can be argued with, which is the difference between a rule
	and a habit.

	It is not airtight and does not pretend to be — a query built by
	concatenation would pass, as would one in another package. What it catches
	is what somebody would actually type, which is the same claim
	`address_test.go` makes about its own rule.
*/
func TestTheStatisticsReadTheStreamAndNotTheLiveTables(t *testing.T) {
	// What each package may name, and why it may.
	mayRead := map[string]map[string]string{
		"internal/analysis/": {
			"item_statistics": "its own rollup — the cache this package writes and " +
				"rebuilds from the stream, which its store's comment calls a cache and " +
				"the stream the truth",
			"question_quarantine": "what it took out of circulation, which is this " +
				"package's own record of its own decisions",
		},
		"internal/event/": {
			"events": "the stream itself. This is the package that owns those rows and " +
				"hands them over as they are; every other package asks it through a " +
				"function type rather than reading the table (X-02)",
		},
	}

	/* AND THE FILE THAT STATES THE RULE. It names both packages and several
	   tables in its own prose, which is the shape `address_test.go` met the
	   first time it ran — rewording to slip past a match is the "writing around
	   the checker" `tree_test.go` says this repository has already had to undo,
	   so it is named instead. */
	const statesTheRule = "internal/statistics_test.go"

	/* `FROM x` and `JOIN x`, which is where a table name appears in the SQL
	   these packages write. A schema-qualified name is caught too: the capture
	   stops at the dot, and `public` is not on any list.

	   BUT ONLY IN A STRING THAT IS A QUERY. These packages write a great deal
	   of English, and English has the word "from" in it — the first run of this
	   test failed on `internal/event/event.go` for an error message reading "an
	   absent value from a lost one", and reported the table as `a`. So a
	   literal is read only if it also carries a statement's verb, which is the
	   cheapest thing that separates a query from a sentence. */
	isQuery := regexp.MustCompile(`(?i)\b(?:SELECT|INSERT\s+INTO|UPDATE|DELETE\s+FROM)\b`)
	reads := regexp.MustCompile(`(?i)\b(?:FROM|JOIN)\s+([a-z_][a-z0-9_]*)`)

	// SQL keywords that follow FROM and are not tables. `FROM (SELECT …)` and
	// `FROM LATERAL …` are the two this repository writes.
	notATable := map[string]bool{"lateral": true, "select": true, "unnest": true, "generate_series": true}

	watched := make([]string, 0, len(mayRead))
	for pkg := range mayRead {
		watched = append(watched, pkg)
	}
	sort.Strings(watched)

	eachGoFile(t,
		func(rel string) bool {
			if rel == statesTheRule || strings.HasSuffix(rel, "_test.go") {
				return true
			}
			for _, pkg := range watched {
				if strings.HasPrefix(rel, pkg) {
					return false // this one is read
				}
			}
			return true
		},
		func(rel string, file *ast.File) {
			var allowed map[string]string
			for _, pkg := range watched {
				if strings.HasPrefix(rel, pkg) {
					allowed = mayRead[pkg]
					break
				}
			}

			ast.Inspect(file, func(n ast.Node) bool {
				lit, ok := n.(*ast.BasicLit)
				if !ok || lit.Kind != token.STRING || !isQuery.MatchString(lit.Value) {
					return true
				}
				for _, m := range reads.FindAllStringSubmatch(lit.Value, -1) {
					table := strings.ToLower(m[1])
					if notATable[table] {
						continue
					}
					if _, ok := allowed[table]; ok {
						continue
					}
					t.Errorf("%s reads %q — statistics come from the event stream and never "+
						"from current state (K-03), and this package may name only %s. A "+
						"number from a live table answers who exists today, where the same "+
						"number from the stream answers what happened; the two disagree "+
						"about last March the first time somebody is erased. If the table "+
						"belongs here, say so in %s with the reason",
						rel, table, naming(allowed), statesTheRule)
				}
				return true
			})
		})
}

func naming(allowed map[string]string) string {
	out := make([]string, 0, len(allowed))
	for table := range allowed {
		out = append(out, table)
	}
	sort.Strings(out)
	return strings.Join(out, ", ")
}
