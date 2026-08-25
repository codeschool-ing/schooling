package internal_test

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

/* Facts about the repository that no compiler checks.

   `architecture_test.go` beside this one holds the dependency graph for the
   reason given at the top of it: a rule like that only works if it was there
   before the first violation. This file is the same idea about the working
   tree — what may be committed at all — and it exists because the answer was a
   list of names and the list went stale.
*/

// tracked is what git says is in the repository, from the repository's root.
func tracked(t *testing.T) []string {
	t.Helper()

	root, err := filepath.Abs("..")
	if err != nil {
		t.Fatalf("finding the repository root: %v", err)
	}

	//nolint:gosec // `root` is this test file's own directory, resolved above
	out, err := exec.Command("git", "-C", root, "ls-files", "-z").Output()
	if err != nil {
		// A tarball with no `.git` is a real way to get here, and it is not a
		// failure of the rule — there is simply nothing to ask.
		t.Skipf("git could not list the tracked files, so there is nothing to check: %v", err)
	}

	var files []string
	for _, name := range strings.Split(string(out), "\x00") {
		if name != "" {
			files = append(files, filepath.Join(root, name))
		}
	}
	if len(files) == 0 {
		t.Skip("git listed no files")
	}
	return files
}

/*
NOTHING COMPILED IS COMMITTED, AND THE CHECK IS THE BYTES AND NOT THE NAME.

	`go build ./tools/<x>` drops the binary in the working directory under the
	package's own name. `.gitignore` listed the names that had happened, which
	worked until somebody built a tool whose name was not on the list — and then
	3.3 MB of `check-interface` went in with a `git add -A`, in the very pull
	request that was fixing that tool.

	A LIST OF NAMES CANNOT BE THE DEFENCE, because the list is written after each
	accident and the next tool is always the one nobody thought of. This reads
	the first bytes instead: an ELF header, a Mach-O header, a PE header or a Java
	class file is a compiled artefact whatever it is called.

	WHAT IT DELIBERATELY DOES NOT DO is judge by size or by extension. The fonts
	are large and belong here; the images in `content/` are binary and belong
	here; an offline bundle is a megabyte of HTML and is ignored elsewhere for a
	different reason. What none of those is is executable.
*/
func TestNothingCompiledIsCommitted(t *testing.T) {
	// The first bytes of the four formats a Go toolchain on any developer's
	// machine or CI runner can produce.
	magic := map[string][]byte{
		"an ELF binary (Linux)":        {0x7f, 'E', 'L', 'F'},
		"a Mach-O binary (macOS)":      {0xcf, 0xfa, 0xed, 0xfe},
		"a 32-bit Mach-O binary":       {0xce, 0xfa, 0xed, 0xfe},
		"a universal Mach-O binary":    {0xca, 0xfe, 0xba, 0xbe},
		"a Windows executable":         {'M', 'Z'},
		"a Java class file":            {0xca, 0xfe, 0xba, 0xbe},
		"a Mach-O binary (big endian)": {0xfe, 0xed, 0xfa, 0xcf},
	}

	for _, path := range tracked(t) {
		file, err := os.Open(path) //nolint:gosec // a path from git's own listing
		if err != nil {
			// A file listed and not present is a checkout mid-operation, not a
			// verdict about this rule.
			continue
		}
		head := make([]byte, 4)
		n, _ := file.Read(head)
		_ = file.Close()
		if n < 2 {
			continue
		}
		head = head[:n]

		for what, prefix := range magic {
			if len(head) >= len(prefix) && bytes.Equal(head[:len(prefix)], prefix) {
				name, _ := filepath.Rel(filepath.Dir(path), path)
				t.Errorf("%s is %s and is committed.\n"+
					"    `go build ./tools/<x>` and `go build ./cmd/<x>` write the binary into "+
					"the working directory under the package's own name, and `git add -A` "+
					"then takes it. Remove it with `git rm --cached %s` and add the name to "+
					"`.gitignore` — the ignore list is for a quiet `git status`, and this test "+
					"is what actually holds the rule.", path, what, name)
				break
			}
		}
	}
}

/*
AND THE IGNORE LIST STILL COVERS EVERY COMMAND, which is the other half.

	The test above is the defence and this is the hygiene: a binary sitting
	untracked in the working directory makes `git status` noisy, and a noisy
	status is one nobody reads — which is how the accident happens in the first
	place. Every directory under `cmd/` and `tools/` can produce one, so every
	one of them should be named.

	`tools/lib` is the exception and is skipped: it holds shared JavaScript for
	the browser suites and builds nothing.
*/
func TestEveryCommandsBinaryIsIgnored(t *testing.T) {
	root, err := filepath.Abs("..")
	if err != nil {
		t.Fatalf("finding the repository root: %v", err)
	}

	//nolint:gosec // the repository's own .gitignore, at a path derived from this file
	ignore, err := os.ReadFile(filepath.Join(root, ".gitignore"))
	if err != nil {
		t.Fatalf("reading .gitignore: %v", err)
	}
	lines := map[string]bool{}
	for _, line := range strings.Split(string(ignore), "\n") {
		lines[strings.TrimSpace(line)] = true
	}

	for _, where := range []string{"cmd", "tools"} {
		entries, err := os.ReadDir(filepath.Join(root, where))
		if err != nil {
			t.Fatalf("reading %s: %v", where, err)
		}
		for _, entry := range entries {
			if !entry.IsDir() || entry.Name() == "lib" {
				continue
			}
			// Only a directory holding Go source builds a binary.
			source, _ := filepath.Glob(filepath.Join(root, where, entry.Name(), "*.go"))
			if len(source) == 0 {
				continue
			}
			if !lines["/"+entry.Name()] {
				t.Errorf("`go build ./%s/%s` writes ./%s and .gitignore does not carry "+
					"`/%s` — the next `git add -A` in a dirty tree takes it",
					where, entry.Name(), entry.Name(), entry.Name())
			}
		}
	}
}
