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
//
// # AND WHAT A MODULE ACTUALLY IS
//
// A MODULE OWNS TABLES AND ROUTES. Not everything under `internal/` does:
// `grade` is the rules of grading, expressed as functions over JSON values,
// with no database, no handler and no state. Splitting `exam` into its own
// service would take `grade` with it AND leave a copy behind for the content
// checker, which is what a library is rather than a module two things happen
// to need.
//
// Those are named in `libraries` below, and the exception is checked rather
// than trusted: a package declared a library that touches a database, serves
// HTTP or reaches into a module fails, and a name with no package behind it
// fails too. The mechanism is deliberately the one the tenancy rules already
// use, because the alternative is a list of names that grows whenever the rule
// is inconvenient.
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

// libraries are the packages under internal/ that are not modules: rules over
// values, with no tables and no routes. Any module may depend on one.
//
// Adding a name here is adding an exception, and the test below is what makes
// it an expensive one to add wrongly — the property has to actually hold.
var libraries = map[string]string{
	"grade": "the rules of grading, as functions over JSON values. It owns no table and serves " +
		"no route; `exam` marks with it and so does the content checker, which is what a " +
		"library is rather than a module two things happen to need",
}

func isLibrary(imp string) bool {
	rest := strings.TrimPrefix(imp, module+"/internal/")
	name, _, _ := strings.Cut(rest, "/")
	_, ok := libraries[name]
	return ok
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
				case isLibrary(imp):
					continue // rules over values; see libraries above
				}
				rel, _ := filepath.Rel(root, pkgDir)
				t.Errorf("%s imports %s — modules talk through an interface the consumer defines, "+
					"wired together in cmd/, never by reaching into each other", rel, imp)
			}
		})
	}
}

// A DECLARED LIBRARY HAS TO ACTUALLY BE ONE.
//
// Without this, `libraries` is a list of packages somebody wanted to import and
// the rule above is a comment. What makes a library a library is that it holds
// nothing anything else could disagree with: no database, no HTTP surface, and
// no reach into a module. Each of those is visible in its imports, so each of
// them is checked here.
func TestALibraryIsActuallyOne(t *testing.T) {
	root := repoRoot(t)
	internal := filepath.Join(root, "internal")

	// What a library may not touch, and why in each case.
	forbidden := map[string]string{
		"github.com/jackc/pgx": "it would own rows, and a library owns no state",
		"database/sql":         "the same",
		"net/http":             "it would own a route, and a route belongs to a module",
	}

	for name, why := range libraries {
		dir := filepath.Join(internal, name)
		if _, err := os.Stat(dir); err != nil {
			t.Errorf("libraries names %q and there is no such package — an exception outlived the "+
				"thing it excused, and a stale one reads as current", name)
			continue
		}

		walk(t, dir, func(pkgDir string, imports []string) {
			rel, _ := filepath.Rel(root, pkgDir)
			for _, imp := range imports {
				for prefix, reason := range forbidden {
					if strings.HasPrefix(imp, prefix) {
						t.Errorf("%s is declared a library — %s — and it imports %s: %s",
							rel, why, imp, reason)
					}
				}

				if strings.HasPrefix(imp, module+"/internal/") &&
					!strings.HasPrefix(imp, module+"/internal/platform") &&
					!strings.HasPrefix(imp, module+"/internal/"+name) &&
					!isLibrary(imp) {
					t.Errorf("%s is declared a library and it imports %s — a library that reaches "+
						"into a module is a module with the label filed off", rel, imp)
				}
			}
		})
	}
}

// THE THIRD RULE: only the load job writes the catalogue.
//
// The files in `content/` are the source of truth and the tables are a derived
// mirror (C-01); the console reads and never writes (C-07). That holds for
// exactly as long as nobody adds a screen that fixes a typo directly — and the
// first time somebody does, the files silently stop being the truth and the
// next load quietly undoes their fix.
//
// So it is checked rather than agreed. Test files are exempt: a test may seed a
// mirror to exercise a reader, and that is not a console editing a course.
func TestOnlyTheLoadJobWritesTheCatalogue(t *testing.T) {
	root := repoRoot(t)

	err := filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
		switch {
		case err != nil:
			return err
		case d.IsDir() && (d.Name() == ".git" || d.Name() == "testdata"):
			return filepath.SkipDir
		case d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go"):
			return nil
		}

		rel, _ := filepath.Rel(root, path)
		if strings.HasPrefix(filepath.ToSlash(rel), "cmd/load/") {
			return nil
		}

		body, err := os.ReadFile(path) //nolint:gosec // a path this walk produced from the repository
		if err != nil {
			return err
		}
		text := string(body)

		for _, verb := range []string{"INSERT INTO catalog_", "UPDATE catalog_", "DELETE FROM catalog_"} {
			if strings.Contains(text, verb) {
				t.Errorf("%s contains %q — the catalogue is a mirror of the files, and the "+
					"moment a second thing writes it the files stop being the truth: the next "+
					"load undoes whatever was written here, silently", rel, verb)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walking the repository: %v", err)
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

// DECAYED STRENGTH NEVER REACHES A PROGRESS BAR.
//
// `section_progress` answers "what have I done" and is set-true and never
// toggled (A-05). `practice_state` answers "how well do I still know this" and
// DECAYS. They are two questions, and the whole reason they are two tables is
// that one number made of both would fall for a student who did nothing wrong —
// which is the most demoralising thing a study platform can do.
//
// The module graph already stops the packages importing each other. This is the
// other half: neither may reach the other's TABLE, which no import graph can
// see because SQL is a string. Written as a scan for exactly that reason.
//
// It is not hypothetical. The obvious feature request is "show mastery on the
// course page", and the obvious implementation is one query in the progress
// store that joins the two. It would be a one-line change and nothing else in
// this repository would object.
func TestMasteryAndProgressNeverMeetInOneQuery(t *testing.T) {
	forbidden := map[string]string{
		"internal/progress": "practice_state",
		"internal/practice": "section_progress",
	}

	for dir, table := range forbidden {
		for _, path := range goFilesUnder(t, filepath.Join(repoRoot(t), dir)) {
			body, err := os.ReadFile(path) //nolint:gosec // a path this test produced
			if err != nil {
				t.Fatalf("reading %s: %v", path, err)
			}
			if strings.Contains(string(body), table) {
				rel, _ := filepath.Rel(repoRoot(t), path)
				t.Errorf("%s mentions %q.\n"+
					"Progress is what a student has done and never goes down; mastery decays. "+
					"A bar built from both falls for somebody who did nothing wrong — see A-05 "+
					"and the comments at the top of both migrations.", rel, table)
			}
		}
	}
}

// PRACTICE EARNS NOTHING.
//
// A certificate says somebody passed an exam on a day. Drilling is not an exam:
// nothing is sealed, the client says whether it was right, and the whole point
// is to answer the same question many times until it sticks. If practice could
// contribute to eligibility, the document would mean "answered this enough
// times", which is not what it says on it.
//
// So neither the module that issues certificates nor the one that decides an
// exam was passed may read anything of practice's. Again a scan and not an
// import check: the coupling that would do the damage is a query.
func TestNothingAboutPracticeReachesACertificate(t *testing.T) {
	for _, dir := range []string{"internal/certificate", "internal/exam"} {
		for _, path := range goFilesUnder(t, filepath.Join(repoRoot(t), dir)) {
			body, err := os.ReadFile(path) //nolint:gosec // a path this test produced
			if err != nil {
				t.Fatalf("reading %s: %v", path, err)
			}

			for _, table := range []string{"practice_state", "practice_review"} {
				if strings.Contains(string(body), table) {
					rel, _ := filepath.Rel(repoRoot(t), path)
					t.Errorf("%s mentions %q — a certificate says an exam was passed on a day, "+
						"and drilling is not an exam", rel, table)
				}
			}
		}
	}
}

// Every .go file under a directory, tests included: a test that crosses a
// boundary the code may not cross is the same coupling with a different file
// name.
func goFilesUnder(t *testing.T, dir string) []string {
	t.Helper()

	var found []string
	err := filepath.WalkDir(dir, func(path string, d os.DirEntry, err error) error {
		switch {
		case err != nil:
			return err
		case d.IsDir() && d.Name() == "testdata":
			return filepath.SkipDir
		case !d.IsDir() && strings.HasSuffix(path, ".go"):
			found = append(found, path)
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walking %s: %v", dir, err)
	}
	if len(found) == 0 {
		t.Fatalf("no Go files under %s — this test is checking nothing", dir)
	}
	return found
}
