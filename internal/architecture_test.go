// The dependency graph between modules, enforced rather than agreed.
//
// IT EXISTS FROM THE FIRST MODULE ON PURPOSE. A rule like this only works if
// it was there before the first violation: added later, it fails on code that
// already ships, and the pressure is then to weaken the rule rather than fix
// the dependency. Written now, while there are three packages, it costs
// nothing and it is what turns "extract this into its own service" from a
// rewrite into a day's work.
//
// # THE TWO RULES
//
//  1. `platform` imports nothing else from this repository. Whatever lands
//     there is available to every module, so anything with an opinion about the
//     product does not belong in it — and an import pointing outwards is how
//     that opinion would arrive.
//
//  2. No module imports another module. They talk through interfaces the
//     consumer defines, and are wired together in `cmd/`. `platform` is the
//     exception every module may depend on, because that is what it is for.
//
// When a second module needs something from a first, the answer is not an
// import: it is an interface where it is used, satisfied by the other and
// passed in from `cmd/`. That is the whole discipline, and it is the reason a
// binary this small can be split later without archaeology.
package internal_test

import (
	"errors"
	"go/build"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const module = "github.com/codeschool-ing/schooling"

// modules are the top-level packages under internal/. A new directory here is
// a new module and is picked up without editing this test.
func modules(t *testing.T, root string) []string {
	t.Helper()
	entries, err := os.ReadDir(root)
	if err != nil {
		t.Fatalf("reading %s: %v", root, err)
	}
	var out []string
	for _, e := range entries {
		if e.IsDir() {
			out = append(out, e.Name())
		}
	}
	return out
}

func TestPlatformImportsNothingFromThisRepository(t *testing.T) {
	root := repoRoot(t)
	platform := filepath.Join(root, "internal", "platform")

	walk(t, platform, func(pkgDir string, imports []string) {
		for _, imp := range imports {
			if !strings.HasPrefix(imp, module) {
				continue
			}
			rel, _ := filepath.Rel(root, pkgDir)
			t.Errorf("%s imports %s — platform is the floor everything stands on and may not "+
				"reach upwards; move what it needs into platform, or invert the dependency", rel, imp)
		}
	})
}

func TestNoModuleImportsAnotherModule(t *testing.T) {
	root := repoRoot(t)
	internal := filepath.Join(root, "internal")

	for _, name := range modules(t, internal) {
		if name == "platform" {
			continue
		}
		self := module + "/internal/" + name

		walk(t, filepath.Join(internal, name), func(pkgDir string, imports []string) {
			for _, imp := range imports {
				switch {
				case !strings.HasPrefix(imp, module+"/internal/"):
					continue // the standard library, a dependency, or migrations
				case strings.HasPrefix(imp, module+"/internal/platform"):
					continue // the shared floor, which is what it is for
				case strings.HasPrefix(imp, self):
					continue // itself
				}
				rel, _ := filepath.Rel(root, pkgDir)
				t.Errorf("%s imports %s — modules talk through an interface the consumer defines, "+
					"wired together in cmd/, never by reaching into each other", rel, imp)
			}
		})
	}
}

// walk visits every package under dir and hands over its imports, test files
// included: a test that reaches across a boundary the code may not cross is the
// same coupling with a different file name.
func walk(t *testing.T, dir string, fn func(pkgDir string, imports []string)) {
	t.Helper()

	err := filepath.WalkDir(dir, func(path string, d os.DirEntry, err error) error {
		if err != nil || !d.IsDir() {
			return err
		}
		pkg, err := build.ImportDir(path, 0)
		if err != nil {
			// A directory with no Go files in it is not a package, and that is
			// not a failure. errors.As rather than a type assertion, because an
			// assertion misses the moment the error arrives wrapped.
			var empty *build.NoGoError
			if errors.As(err, &empty) {
				return nil
			}
			return err
		}
		fn(path, append(append([]string{}, pkg.Imports...), pkg.TestImports...))
		return nil
	})
	if err != nil {
		t.Fatalf("walking %s: %v", dir, err)
	}
}

func repoRoot(t *testing.T) string {
	t.Helper()
	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("working directory: %v", err)
	}
	// This file lives in internal/, so the repository is its parent.
	return filepath.Dir(wd)
}
