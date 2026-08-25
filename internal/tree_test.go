package internal_test

import (
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

/*
Reading every Go file in the repository, which two rules here need.

	THE RULES ARE ABOUT SYNTAX AND NOT ABOUT TEXT. A grep would call a comment
	explaining a rule a violation of it, and teach everybody to write around the
	checker instead of in plain English — which this repository has already done
	once, in `tools/check-interface`, and had to undo. Parsing drops the comments
	for free.

	AND IT WALKS THE TREE RATHER THAN THE INDEX. `repository_test.go` asks git
	what is committed, because what it is about IS what is committed. These are
	about the code, and a file written but not yet added is code — the first
	version of the address rule passed with a probe sitting unstaged beside it. A
	rule that is quiet until you remember to `git add` is a rule you meet at the
	end instead of at the start.
*/
func eachGoFile(t *testing.T, skip func(rel string) bool, visit func(rel string, file *ast.File)) {
	t.Helper()

	eachFile(t, ".go", skip, func(rel, path string, _ []byte) {
		file, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.SkipObjectResolution)
		if err != nil {
			// Not these rules' business. Something that does not parse fails
			// the build long before it fails a rule about privacy or logging.
			return
		}
		visit(rel, file)
	})
}

// eachFile is the walk itself, over one extension.
//
// IT IS SEPARATE FROM THE PARSING because the third rule to want it is not
// about Go at all: every SVG in the repository has to be well-formed XML, and
// the walk is the same walk. Two copies of it were about to exist in the pull
// request that added the second one.
func eachFile(t *testing.T, ext string, skip func(rel string) bool,
	visit func(rel, path string, source []byte)) {

	t.Helper()

	root, err := filepath.Abs("..")
	if err != nil {
		t.Fatalf("finding the repository root: %v", err)
	}

	var read int
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
		if filepath.Ext(path) != ext {
			return nil
		}

		rel, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		rel = filepath.ToSlash(rel)
		if skip != nil && skip(rel) {
			return nil
		}

		source, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		read++
		visit(rel, path, source)
		return nil
	})
	if err != nil {
		t.Fatalf("reading the repository: %v", err)
	}

	// A walk that found nothing would pass forever and say nothing, which is
	// the failure mode of every check that reads a tree.
	if read == 0 {
		t.Fatal("no " + ext + " file was read at all, which cannot be right")
	}
}

// calls answers whether a node is a call to `package.Function`.
func calls(n ast.Node, pkg, function string) bool {
	call, ok := n.(*ast.CallExpr)
	if !ok {
		return false
	}
	selector, ok := call.Fun.(*ast.SelectorExpr)
	if !ok || selector.Sel == nil || selector.Sel.Name != function {
		return false
	}
	ident, ok := selector.X.(*ast.Ident)
	return ok && ident.Name == pkg
}

func isTest(rel string) bool { return strings.HasSuffix(rel, "_test.go") }
