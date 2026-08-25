package internal_test

import (
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"path/filepath"
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

	IT READS THE SYNTAX AND NOT THE TEXT. `cmd/api` explains the header in a
	comment, and a grep would call that a violation and teach everybody to
	write around the checker instead of in plain English — which this repository
	has already done once, in `tools/check-interface`, and had to undo.

	THE HEADER IS SPELLED ONCE, IN `geo.HeaderForwardedFor`. This test caught
	the very next thing written after it: a sign-up test BUILDING a request with
	a forged entry in front of the real one, which is not a second reader of the
	address but is indistinguishable from one here. The constant is how such a
	test writes the request without writing the header, and it leaves the
	literal a thing only that package contains.

	It is not airtight and does not pretend to be: reading the header elsewhere
	THROUGH the constant would pass. What this catches is what somebody would
	actually type.

	AND IT WALKS THE TREE RATHER THAN THE INDEX. The test beside this one asks
	git what is committed, because what it is about IS what is committed. This
	is about the code, and a file that has been written but not yet added is
	code — it was written that way first, passed, and only failed once the
	probe proving it was staged. A rule that is quiet until you remember to
	`git add` is a rule you meet at the end instead of at the start.
*/
func TestTheCallersAddressIsReadInOnePlace(t *testing.T) {
	// The package that may, and the one test file that is allowed to build the
	// requests it reads. Anything else naming these is the thing this test is
	// for.
	const allowed = "internal/platform/geo"

	/* AND THE FILE THAT STATES THE RULE, which found itself the first time it
	   ran: the header's name appears twice here, once in the pattern it looks
	   for and once in the sentence it prints. Rewording either to slip past
	   the match is precisely the "writing around the checker" the paragraph
	   above condemns, so it is named instead. */
	const statesTheRule = "internal/address_test.go"

	root, err := filepath.Abs("..")
	if err != nil {
		t.Fatalf("finding the repository root: %v", err)
	}

	var checked int
	err = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			// Neither is ours to answer for, and one of them is enormous.
			if name := d.Name(); name == ".git" || name == "node_modules" {
				return fs.SkipDir
			}
			return nil
		}
		if filepath.Ext(path) != ".go" {
			return nil
		}
		rel, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		rel = filepath.ToSlash(rel)
		if strings.HasPrefix(rel, allowed+"/") || rel == statesTheRule {
			return nil
		}
		checked++

		// Comments are dropped: the rule is about code that reads an address,
		// and prose explaining why it may not is the opposite of a violation.
		file, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.SkipObjectResolution)
		if err != nil {
			// Not this test's business. Something that does not parse fails
			// the build long before it fails a rule about privacy.
			return nil
		}

		ast.Inspect(file, func(n ast.Node) bool {
			switch node := n.(type) {
			case *ast.SelectorExpr:
				if node.Sel != nil && node.Sel.Name == "RemoteAddr" {
					t.Errorf("%s reads RemoteAddr — the caller's address is read in %s and "+
						"nowhere else, because that is what makes \"we do not store your IP "+
						"address\" a property of one function instead of a habit. What you "+
						"probably want is geo.FromContext(ctx), which answers the country",
						rel, allowed)
				}
			case *ast.BasicLit:
				if node.Kind == token.STRING &&
					strings.Contains(strings.ToLower(node.Value), "x-forwarded-for") {
					t.Errorf("%s names the X-Forwarded-For header in code — reading it is %s's "+
						"job, and the entry that is the caller is not the one most readers "+
						"of that header reach for. See the package comment there", rel, allowed)
				}
			}
			return true
		})
		return nil
	})
	if err != nil {
		t.Fatalf("reading the repository: %v", err)
	}

	// A walk that found nothing would pass forever and say nothing, which is
	// the failure mode of every check that reads a tree.
	if checked == 0 {
		t.Fatal("no Go file outside " + allowed + " was read, which cannot be right")
	}
}
