package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// NOTHING HERE TOUCHES THE NETWORK. The fetch has one job — hand back the
// `using:` a commit declares — and a test that reached for it would be a test
// that fails when GitHub is slow, on a pull request about something else. What
// is worth holding is the reading and the verdict, and both take the runtime as
// an argument.

func workflow(t *testing.T, body string) []pin {
	t.Helper()
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "ci.yml"), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	pins, err := read(dir)
	if err != nil {
		t.Fatalf("reading the workflow: %v", err)
	}
	return pins
}

func says(t *testing.T, problems []string, fragment string) bool {
	t.Helper()
	for _, p := range problems {
		if strings.Contains(p, fragment) {
			return true
		}
	}
	return false
}

func TestAPinIsReadWithItsVersion(t *testing.T) {
	pins := workflow(t, "jobs:\n  go:\n    steps:\n"+
		"      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n")

	if len(pins) != 1 {
		t.Fatalf("read %d pins from one `uses:`", len(pins))
	}
	got := pins[0]
	if got.action != "actions/checkout" ||
		got.ref != "9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0" || got.version != "v7.0.0" {
		t.Errorf("read %+v", got)
	}
	if problems := pinned(pins); len(problems) > 0 {
		t.Errorf("a well-formed pin was reported:\n  - %s", strings.Join(problems, "\n  - "))
	}
}

// A STEP WITH A NAME ABOVE IT IS THE SAME STEP. Two of this repository's own
// uses are written that way — the one that exchanges a token for Google
// credentials is one of them — so a reader that only matched `- uses:` would
// skip exactly the action whose pin matters most.
func TestANamedStepIsRead(t *testing.T) {
	pins := workflow(t, "jobs:\n  deploy:\n    steps:\n"+
		"      - name: An hour of credentials\n"+
		"        uses: google-github-actions/auth@7c6bc770dae815cd3e89ee6cdf493a5fab2cc093 # v3.0.0\n")

	if len(pins) != 1 {
		t.Fatalf("a `uses:` under a `name:` read as %d pins", len(pins))
	}
	if pins[0].action != "google-github-actions/auth" {
		t.Errorf("read %+v", pins[0])
	}
}

// THIS REPOSITORY AT THIS COMMIT. `release.yml` calls `ci.yml` rather than
// repeating its steps, and there is no commit to pin that to — reporting it
// would be a problem with no fix, which is the kind of finding that teaches
// people to stop reading the output.
func TestALocalWorkflowIsNotAPin(t *testing.T) {
	pins := workflow(t, "jobs:\n  checks:\n    uses: ./.github/workflows/ci.yml\n")
	if len(pins) != 0 {
		t.Errorf("a local workflow call was read as a pin: %+v", pins)
	}
}

func TestAMovingTagIsRefused(t *testing.T) {
	pins := workflow(t, "jobs:\n  go:\n    steps:\n"+
		"      - uses: actions/checkout@v7 # v7.0.0\n")
	problems := pinned(pins)
	if !says(t, problems, "tag rather than a commit") {
		t.Errorf("`@v7` was not refused:\n  - %s", strings.Join(problems, "\n  - "))
	}
}

func TestACommitWithNoVersionIsRefused(t *testing.T) {
	pins := workflow(t, "jobs:\n  go:\n    steps:\n"+
		"      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0\n")
	problems := pinned(pins)
	if !says(t, problems, "no version beside it") {
		t.Errorf("a pin with no version was not refused:\n  - %s", strings.Join(problems, "\n  - "))
	}
}

// THE FAILURE THIS TOOL WAS WRITTEN FOR, in the shape it actually arrived in:
// the `auth` pin that went out with `v0.51.0`, green, with a warning under it.
func TestADeprecatedRuntimeIsRefused(t *testing.T) {
	pins := workflow(t, "jobs:\n  deploy:\n    steps:\n"+
		"      - uses: google-github-actions/auth@c200f3691d83b41bf9bbd8638997a462592937ed # v2.1.13\n")

	runtimes := map[string]string{
		"google-github-actions/auth@c200f3691d83b41bf9bbd8638997a462592937ed": "node20",
	}
	problems := obsolete(pins, runtimes)
	if !says(t, problems, "node20") {
		t.Errorf("a node20 action was not refused:\n  - %s", strings.Join(problems, "\n  - "))
	}
}

// AND THE NEWEST RUNTIME IS NOT A PROBLEM, which is worth its own test because
// the list is of what has been deprecated rather than of what is not newest. An
// entry added to it the day a runtime is announced is one line; a tool that
// failed on "not the latest" would go red on the morning of every upstream
// release.
func TestTheCurrentRuntimeIsFine(t *testing.T) {
	pins := workflow(t, "jobs:\n  go:\n    steps:\n"+
		"      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n")

	runtimes := map[string]string{
		"actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0": "node24",
	}
	if problems := obsolete(pins, runtimes); len(problems) > 0 {
		t.Errorf("node24 was reported:\n  - %s", strings.Join(problems, "\n  - "))
	}
}

// A COMPOSITE OR DOCKER ACTION IS NOT A JAVASCRIPT ACTION, and neither has a
// Node runtime to be deprecated. Reading `composite` as a bad runtime would
// make this tool refuse a whole class of action for having nothing wrong.
func TestAnActionThatIsNotJavaScriptIsFine(t *testing.T) {
	pins := workflow(t, "jobs:\n  go:\n    steps:\n"+
		"      - uses: some/composite@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v1.0.0\n")

	for _, using := range []string{"composite", "docker"} {
		runtimes := map[string]string{
			"some/composite@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0": using,
		}
		if problems := obsolete(pins, runtimes); len(problems) > 0 {
			t.Errorf("`using: %s` was reported:\n  - %s", using,
				strings.Join(problems, "\n  - "))
		}
	}
}

// ONE COMMIT USED SIX TIMES IS ONE FINDING. `actions/checkout` appears in every
// job here, and a tool that said the same sentence six times would bury the
// other five findings under one.
func TestOneCommitUsedTwiceIsReportedOnce(t *testing.T) {
	line := "      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n"
	pins := workflow(t, "jobs:\n  go:\n    steps:\n"+line+line+line)
	if len(pins) != 3 {
		t.Fatalf("read %d uses of one action", len(pins))
	}

	runtimes := map[string]string{
		"actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0": "node20",
	}
	if problems := obsolete(pins, runtimes); len(problems) != 1 {
		t.Errorf("three uses of one commit produced %d findings:\n  - %s",
			len(problems), strings.Join(problems, "\n  - "))
	}
}

// AND THE REAL WORKFLOWS, offline: every pin this repository actually ships is
// a commit with a version beside it. The runtime half needs the network and
// lives in the tool; this is the part that can be held on every run.
func TestThisRepositorysOwnWorkflowsArePinned(t *testing.T) {
	pins, err := read(filepath.Join("..", "..", ".github", "workflows"))
	if err != nil {
		t.Fatalf("reading the workflows: %v", err)
	}
	if len(pins) == 0 {
		t.Fatal("no action is used by any workflow, which cannot be right")
	}
	if problems := pinned(pins); len(problems) > 0 {
		t.Errorf("%d pin(s) in this repository:\n  - %s",
			len(problems), strings.Join(problems, "\n  - "))
	}
}
