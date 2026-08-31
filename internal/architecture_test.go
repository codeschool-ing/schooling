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
	"fmt"
	"go/ast"
	"go/build"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"testing"

	/* THIS FILE IMPORTS MODULES, AND THAT IS NOT THE THING IT FORBIDS. Rule 2
	   is about what the SHIPPED packages import, which is why both scans below
	   skip `_test.go`. A test is the one place two modules that may not know
	   about each other can be held to the same string —
	   `TestTheStreamsNamesAreWrittenAtBothEnds`, at the foot of this file. */
	"github.com/codeschool-ing/schooling/internal/analysis"
	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/codeschool-ing/schooling/internal/legal"
	"github.com/codeschool-ing/schooling/internal/privacy"
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

// THE PRIVACY POLICY IS CHECKED AGAINST THE REGISTRY.
//
// The registry already guarantees that no table exists without somebody having
// decided what it holds. This is the layer above: that no table holding
// personal data exists without the published policy accounting for it.
//
// It is the same failure shape one level up, and it is worse. A table nobody
// classified fails CI; a table nobody wrote into the policy fails nothing at
// all — the document keeps rendering, keeps looking finished, and is quietly
// wrong from the day the migration lands until somebody happens to reread it
// against the schema. Nobody rereads a privacy policy against a schema.
//
// The policy names its tables in a `covers:` line in the front matter rather
// than in the prose, because a person reading a privacy policy does not want a
// table name. The check is exact and the reading is human.
//
// IT LIVES HERE because `legal` and `privacy` are both modules, and modules do
// not import each other — including in tests. This file is not in a module and
// is the one place both can be seen at once, which is the same reason `cmd/`
// is where they would be wired together.
func TestThePrivacyPolicyAccountsForEveryTableThatHoldsPersonalData(t *testing.T) {
	// EVERY LANGUAGE COVERS EXACTLY THE SAME TABLES, and the comparison is
	// against English rather than against the union of all of them. A union
	// would let one language carry a table the other omits and still satisfy
	// the registry below — a policy that is complete in English and incomplete
	// in Portuguese, which is the version half the students read.
	covered := map[string]bool{}
	for _, table := range mustRead(t, legal.Fallback).Covers {
		covered[table] = true
	}

	for _, locale := range legal.Locales(legal.Privacy) {
		if locale == legal.Fallback {
			continue
		}

		here := map[string]bool{}
		for _, table := range mustRead(t, locale).Covers {
			here[table] = true
			if !covered[table] {
				t.Errorf("the %s policy accounts for %q and the English one does not",
					locale, table)
			}
		}
		for table := range covered {
			if !here[table] {
				t.Errorf("the %s policy does not account for %q and the English one does",
					locale, table)
			}
		}
	}

	for _, table := range privacy.Registry {
		if table.Holds == privacy.HoldsNothing {
			continue
		}
		if !covered[table.Name] {
			t.Errorf("%q holds personal data (%s) and the privacy policy does not account "+
				"for it. Open internal/legal/documents/privacy.*.md, say in plain words what "+
				"is in it and what happens to it on an erasure, and add the table to the "+
				"`covers:` line of every language",
				table.Name, table.Holds)
		}
	}

	// And the other direction: a name in `covers:` that is not a table is a
	// paragraph describing something that no longer exists, which is the same
	// document being wrong in the other direction.
	inRegistry := map[string]bool{}
	for _, table := range privacy.Registry {
		inRegistry[table.Name] = true
	}
	for table := range covered {
		if !inRegistry[table] {
			t.Errorf("the privacy policy accounts for %q, which is not a table in the "+
				"registry — either it was renamed or the policy describes something that "+
				"is gone", table)
		}
	}
}

func mustRead(t *testing.T, locale string) legal.Document {
	t.Helper()
	doc, err := legal.Read(legal.Privacy, locale)
	if err != nil {
		t.Fatalf("reading the privacy policy in %s: %v", locale, err)
	}
	return doc
}

// ONLY THE SEEDER SAYS WHEN AN EVENT HAPPENED.
//
// `event.Event.At` lets a caller write an event with a time of its own choosing,
// and exactly one caller has a reason to: the seeder, which invents a past
// because abandonment, coming back after a month and a funnel that narrows are
// shapes in TIME, and a history written at `now()` has none of them.
//
// For everything else the column's default is the truth, and an argument for it
// would only ever be a chance to disagree with the clock. The hazard is the
// ordinary one for a field like this: an event stream whose times cannot be
// trusted answers every question with a number that looks fine.
//
// So it is checked rather than left to a comment. Test files are exempt — a test
// that seeds a stream to exercise a reader is not a request path lying about
// when something happened.
func TestOnlyTheSeederSaysWhenAnEventHappened(t *testing.T) {
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

		rel := filepath.ToSlash(mustRel(t, root, path))
		if strings.HasPrefix(rel, "cmd/seed/") || strings.HasPrefix(rel, "internal/event/") {
			return nil // the one caller, and the package that defines the field
		}

		parsed, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
		if err != nil {
			return fmt.Errorf("parsing %s: %w", rel, err)
		}

		ast.Inspect(parsed, func(n ast.Node) bool {
			lit, ok := n.(*ast.CompositeLit)
			if !ok {
				return true
			}
			named, ok := lit.Type.(*ast.SelectorExpr)
			if !ok || named.Sel.Name != "Event" {
				return true
			}
			if pkg, ok := named.X.(*ast.Ident); !ok || pkg.Name != "event" {
				return true
			}
			for _, field := range lit.Elts {
				kv, ok := field.(*ast.KeyValueExpr)
				if !ok {
					continue
				}
				if key, ok := kv.Key.(*ast.Ident); ok && key.Name == "At" {
					t.Errorf("%s writes an event with a time of its own choosing. Only the "+
						"seeder may do that: everything else emits as it happens, and a "+
						"stream whose times can be argued with is one nothing can be "+
						"counted from", rel)
				}
			}
			return true
		})
		return nil
	})
	if err != nil {
		t.Fatalf("walking the repository: %v", err)
	}
}

func mustRel(t *testing.T, root, path string) string {
	t.Helper()
	rel, err := filepath.Rel(root, path)
	if err != nil {
		t.Fatalf("%s is not under %s: %v", path, root, err)
	}
	return rel
}

/*
TestTheStreamsNamesAreWrittenAtBothEnds holds the one contract the module
boundary cannot.

	# WHY THE NAMES ARE DUPLICATED IN THE FIRST PLACE

	Rule 2 above: modules do not import modules. So the end that EMITS an event
	and the end that READS it cannot share a constant — `progress` writes
	"section.completed" and `analysis` writes it again, and the same is true of
	every other name in the stream. That is not a wart to be fixed by relaxing
	the rule: a name in an append-only stream is a contract with rows written
	years ago, not a variable one package owns.

	# WHAT GOES WRONG WITHOUT THIS TEST

	A rename that reaches only one end. Nothing fails to compile, nothing errors
	at run time, and the query simply matches no rows — so a report says nobody
	ever did the thing. It is the failure this whole area is written against:
	confident, plausible, and zero.

	# WHY IT IS A PAIR AND NOT A SCAN

	Reading every string literal in the repository and guessing which are event
	names would flag the prose in comments and miss anything built at run time.
	These are the pairs that exist, listed; a name added without a line here is
	a name whose two ends nothing compares, and that is a review's job to catch
	rather than a regular expression's.
*/
func TestTheStreamsNamesAreWrittenAtBothEnds(t *testing.T) {
	for _, pair := range []struct {
		what            string
		emitted, read   string
		emitter, reader string
	}{
		{
			what:    "a subscription starting",
			emitted: billing.EventStarted,
			read:    analysis.SubscribedEvent,
			emitter: "billing.EventStarted",
			reader:  "analysis.SubscribedEvent",
		},
	} {
		if pair.emitted != pair.read {
			t.Errorf("%s: %s is %q and %s is %q — the two ends of one name have "+
				"drifted, so the report reads no rows and says nobody ever did it",
				pair.what, pair.emitter, pair.emitted, pair.reader, pair.read)
		}
	}
}
