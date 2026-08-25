package internal_test

import (
	"go/ast"
	"go/token"
	"strings"
	"testing"
)

/*
THE CALLER'S ADDRESS IS READ IN ONE PACKAGE, AND THIS IS WHAT SAYS SO.

	The published privacy policy promises, in these words, that we do not store
	the IP address and that the country is derived from the request and the
	address itself is discarded (K-05). That is not a promise anybody keeps by
	remembering it. It is kept by there being one function that touches the
	address, and by something that fails when a second one appears.

	`platform/geo` is that place. It reads `X-Forwarded-For`, hands the address
	to a resolver and returns two letters; the address never leaves the package,
	is never logged — not even in the line complaining about it — and is never
	returned to a caller who could put it in a column.

	SO THE RULE IS ABOUT THE READING AND NOT ABOUT THE STORING. A column would
	be caught by a migration review; a handler quietly reading `r.RemoteAddr`
	to rate-limit something, or to put in a log line "just while we debug
	this", would be caught by nobody. That is the shape this catches, and it is
	the shape it would actually take.

	THE HEADER IS SPELLED ONCE, IN `geo.HeaderForwardedFor`. This test caught
	the very next thing written after it: a sign-up test BUILDING a request with
	a forged entry in front of the real one, which is not a second reader of the
	address but is indistinguishable from one here. The constant is how such a
	test writes the request without writing the header, and it leaves the
	literal a thing only that package contains.

	It is not airtight and does not pretend to be: reading the header elsewhere
	THROUGH the constant would pass. What this catches is what somebody would
	actually type.
*/
func TestTheCallersAddressIsReadInOnePlace(t *testing.T) {
	// The package that may.
	const allowed = "internal/platform/geo/"

	/* AND THE FILE THAT STATES THE RULE, which found itself the first time it
	   ran: the header's name appears twice here, once in the pattern it looks
	   for and once in the sentence it prints. Rewording either to slip past
	   the match is precisely the "writing around the checker" that
	   `tree_test.go` explains this repository has already had to undo, so it
	   is named instead. */
	const statesTheRule = "internal/address_test.go"

	eachGoFile(t,
		func(rel string) bool {
			return strings.HasPrefix(rel, allowed) || rel == statesTheRule
		},
		func(rel string, file *ast.File) {
			ast.Inspect(file, func(n ast.Node) bool {
				switch node := n.(type) {
				case *ast.SelectorExpr:
					if node.Sel != nil && node.Sel.Name == "RemoteAddr" {
						t.Errorf("%s reads RemoteAddr — the caller's address is read in %s and "+
							"nowhere else, because that is what makes \"we do not store your IP "+
							"address\" a property of one function instead of a habit. What you "+
							"probably want is geo.FromContext(ctx), which answers the country",
							rel, strings.TrimSuffix(allowed, "/"))
					}
				case *ast.BasicLit:
					if node.Kind == token.STRING &&
						strings.Contains(strings.ToLower(node.Value), "x-forwarded-for") {
						t.Errorf("%s names the X-Forwarded-For header in code — reading it is %s's "+
							"job, and the entry that is the caller is not the one most readers "+
							"of that header reach for. See the package comment there, and "+
							"geo.HeaderForwardedFor if you are building a request rather than "+
							"reading one", rel, strings.TrimSuffix(allowed, "/"))
					}
				}
				return true
			})
		})
}
