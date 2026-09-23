package database_test

import (
	"context"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/platform/database"
)

/*
WHY THE LIMIT IS 8, HELD RATHER THAN WRITTEN DOWN.

	`infra/README.md` carries the table: every process that can hold a
	connection while another one does, what each holds, and the sum. A table in
	a README is prose, and prose renders perfectly whatever it says — so this
	builds the same table out of the three places its numbers actually live
	(the pool sizes here, the instance ceiling in `infra/run.tf`, and the
	release workflow's order) and fails when the sum stops fitting.

	THE LIMIT ITSELF IS NOT IN THIS REPOSITORY. It is a `CONNECTION LIMIT` on
	the database, set by whoever owns the instance, and it is 8 because the
	other tenant of that instance holds 14 of the 22 that are left once the
	superusers have their three. Until the move the instance this project owns
	accepts 25 and the sum is still 8, which is the point: the numbers are
	made to fit before the database starts refusing, not after.
*/
const theLimit = 8

type row struct {
	who   string
	each  int // connections one of them may hold
	count int // how many of them can be alive at once
}

func TestTheWorstCaseFitsTheDatabasesLimit(t *testing.T) {
	root := repoRoot(t)
	instances := apiInstanceCeiling(t, root)

	/* THE ROWS, IN THE ORDER THE README GIVES THEM.

	   BOTH REVISIONS, because a rollout starts the new one and moves traffic
	   before the old one's instances are gone, and each revision gets the
	   whole instance ceiling to itself.

	   ONE RELEASE JOB, because inside a deploy the migration and the load are
	   each waited on before the next step starts, and deploys are serialised by
	   the workflow's concurrency group. TestAReleaseHoldsOneJobAtATime holds
	   both halves of that.

	   BOTH NIGHTLY JOBS AT ONCE, AND AT THE SAME TIME AS A RELEASE. They are
	   thirty minutes apart on the clock, but an operator can start either one
	   from the console at any hour, and a release can be cut at any hour. The
	   table does not rely on the clock, so moving the schedule does not touch
	   it.

	   AND A PERSON. `cmd/staff`, `cmd/seed`, `cmd/reset`, a `psql` through the
	   Auth Proxy, the restore drill reading the live database: each is one
	   connection, and two people operate this. One is reserved, which is a
	   decision rather than a bound — see the README for what a second one
	   costs. */
	rows := []row{
		{"the API, the revision being replaced", database.APIConnections, instances},
		{"the API, the revision replacing it", database.APIConnections, instances},
		{"a release: migrate, then load", database.JobConnections, 1},
		{"analyse", database.JobConnections, 1},
		{"settle", database.JobConnections, 1},
		{"a person at a terminal", database.JobConnections, 1},
	}

	var b strings.Builder
	total := 0
	for _, r := range rows {
		held := r.each * r.count
		total += held
		fmt.Fprintf(&b, "  %-40s %d × %d = %d\n", r.who, r.count, r.each, held)
	}
	fmt.Fprintf(&b, "  %-40s %d\n", "total", total)

	if total > theLimit {
		t.Errorf("the worst case is %d connections and the database accepts %d:\n%s\n"+
			"Lower a pool in internal/platform/database or `max_instance_count` in infra/run.tf, "+
			"and correct the table in infra/README.md to match.", total, theLimit, b.String())
		return
	}
	t.Logf("the worst case is %d of %d:\n%s", total, theLimit, b.String())
}

// apiInstanceCeiling reads `max_instance_count` out of the API service, with
// the comments taken out first so that a sentence about the number cannot be
// read as the number.
func apiInstanceCeiling(t *testing.T, root string) int {
	t.Helper()
	body := resourceBlock(t, root, `resource "google_cloud_run_v2_service" "api"`)

	found := regexp.MustCompile(`(?m)^\s*max_instance_count\s*=\s*(\d+)\s*$`).FindAllStringSubmatch(body, -1)
	if len(found) != 1 {
		t.Fatalf("expected one `max_instance_count` in the API service and found %d — "+
			"a second one is a second ceiling, and this test would have to know which applies", len(found))
	}
	n, _ := strconv.Atoi(found[0][1])
	if n < 1 {
		t.Fatalf("the API's `max_instance_count` is %d, which is not a ceiling", n)
	}
	return n
}

// EVERY JOB IS ONE TASK. A job with `task_count` or `parallelism` above one runs
// that many containers per execution, each with its own pool, and its row in
// the table would be multiplied without anything saying so.
func TestEveryJobRunsOneContainer(t *testing.T) {
	root := repoRoot(t)
	body := stripHCLComments(read(t, filepath.Join(root, "infra", "run.tf")))

	for _, m := range regexp.MustCompile(`(?m)^\s*(task_count|parallelism)\s*=\s*(\d+)\s*$`).FindAllStringSubmatch(body, -1) {
		if n, _ := strconv.Atoi(m[2]); n > 1 {
			t.Errorf("a job in infra/run.tf sets %s = %d: that is %d pools per execution, "+
				"and the table in infra/README.md counts one", m[1], n, n)
		}
	}
}

/*
A RELEASE HOLDS ONE JOB AT A TIME, which is two claims and both are here.

	Inside a run: every `gcloud run jobs execute` in the Deploy job carries
	`--wait`, so the load does not start until the migration has finished.
	Without it the step returns as soon as the execution is ACCEPTED, and the
	two would overlap on every release.

	Across runs: the Deploy job has a concurrency group that does not cancel
	what is in progress, so a second tag waits for the first deploy rather than
	running beside it.
*/
func TestAReleaseHoldsOneJobAtATime(t *testing.T) {
	root := repoRoot(t)
	workflow := read(t, filepath.Join(root, ".github", "workflows", "release.yml"))

	start := strings.Index(workflow, "\n  Deploy:\n")
	if start < 0 {
		t.Fatal("release.yml has no Deploy job — the table's release row describes one")
	}
	deploy := workflow[start+1:]
	if next := regexp.MustCompile(`\n  [A-Za-z][A-Za-z0-9_-]*:\n`).FindStringIndex(deploy[1:]); next != nil {
		deploy = deploy[:next[0]+1]
	}

	executes := regexp.MustCompile(`(?m)^[^#\n]*gcloud run jobs execute[^\n]*$`).FindAllString(deploy, -1)
	if len(executes) == 0 {
		t.Fatal("the Deploy job executes no job — the table's release row describes the migration and the load")
	}
	for _, line := range executes {
		if !strings.Contains(line, "--wait") {
			t.Errorf("this execution is not waited on, so the next step starts while it runs:\n  %s",
				strings.TrimSpace(line))
		}
	}

	group := regexp.MustCompile(`(?m)^    concurrency:\n      group: \S+\n      cancel-in-progress: false\n`)
	if !group.MatchString(deploy) {
		t.Error("the Deploy job has no concurrency group that keeps a running deploy running: " +
			"two tags pushed together would run two migrations or two loads at once")
	}
}

/*
EVERY COMMAND SAYS WHICH POOL IT TAKES, AND EVERY COMMAND IS IN THE TABLE.

	The size is an argument to database.Open, so it is at the call site. This
	holds which one: the service takes the API's size and nothing else does,
	because the API's is the one the instance ceiling multiplies.

	A command that opens the database and is not below is a process the table
	does not count. The failure asks for the row rather than for a line here.
*/
func TestEveryCommandSaysWhichPoolItTakes(t *testing.T) {
	root := repoRoot(t)

	rowOf := map[string]string{
		"api":     "the API",
		"migrate": "a release",
		"load":    "a release",
		"analyse": "analyse",
		"settle":  "settle",
		"staff":   "a person at a terminal",
		"seed":    "a person at a terminal",
		"reset":   "a person at a terminal",
	}

	seen := map[string]bool{}
	for _, dir := range []string{"cmd", "tools"} {
		err := filepath.WalkDir(filepath.Join(root, dir), func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() && d.Name() == "node_modules" {
				return filepath.SkipDir
			}
			if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
				return nil
			}

			file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
			if err != nil {
				return err
			}
			rel, _ := filepath.Rel(root, path)
			command := strings.Split(filepath.ToSlash(rel), "/")[1]

			ast.Inspect(file, func(n ast.Node) bool {
				call, ok := n.(*ast.CallExpr)
				if !ok || !isSelector(call.Fun, "database", "Open") {
					return true
				}

				if _, known := rowOf[command]; !known || dir != "cmd" {
					t.Errorf("%s opens the database and has no row in the table in infra/README.md — "+
						"it is a process that can hold a connection nobody counted", rel)
					return true
				}
				seen[command] = true

				want := "JobConnections"
				if command == "api" {
					want = "APIConnections"
				}
				if len(call.Args) != 3 || !isSelector(call.Args[2], "database", want) {
					t.Errorf("%s: %s must open its pool with database.%s", rel, command, want)
				}
				return true
			})
			return nil
		})
		if err != nil {
			t.Fatalf("walking %s: %v", dir, err)
		}
	}

	// A row nothing opens is a table counting a process that is gone — which
	// errs on the safe side, and still says something false.
	for command := range rowOf {
		if !seen[command] {
			t.Errorf("cmd/%s is in the table and no longer opens the database: take its row out", command)
		}
	}
}

func TestAPoolOfNothingIsRefused(t *testing.T) {
	for _, most := range []int32{0, -1} {
		if pool, err := database.Open(context.Background(), "postgres://nobody@127.0.0.1:1/none", most); err == nil {
			pool.Close()
			t.Errorf("a pool of %d was opened", most)
		}
	}
}

func isSelector(e ast.Expr, pkg, name string) bool {
	sel, ok := e.(*ast.SelectorExpr)
	if !ok || sel.Sel.Name != name {
		return false
	}
	id, ok := sel.X.(*ast.Ident)
	return ok && id.Name == pkg
}

func resourceBlock(t *testing.T, root, header string) string {
	t.Helper()
	body := stripHCLComments(read(t, filepath.Join(root, "infra", "run.tf")))
	start := strings.Index(body, header)
	if start < 0 {
		t.Fatalf("infra/run.tf has no %s", header)
	}
	body = body[start+len(header):]
	if end := strings.Index(body, "\nresource \""); end >= 0 {
		body = body[:end]
	}
	return body
}

func stripHCLComments(s string) string {
	s = regexp.MustCompile(`(?s)/\*.*?\*/`).ReplaceAllString(s, "")
	return regexp.MustCompile(`(?m)(^|\s)(//|#).*$`).ReplaceAllString(s, "$1")
}

func read(t *testing.T, path string) string {
	t.Helper()
	b, err := os.ReadFile(path) //nolint:gosec // a file of this repository, found from go.mod
	if err != nil {
		t.Fatalf("reading %s: %v", path, err)
	}
	return string(b)
}

func repoRoot(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	if err != nil {
		t.Fatalf("working directory: %v", err)
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatal("no go.mod above this test")
		}
		dir = parent
	}
}
