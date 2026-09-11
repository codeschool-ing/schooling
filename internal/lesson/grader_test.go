package lesson_test

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/grade"
)

// The grader contract this package leans on, WITHOUT A DATABASE.
//
// IT EXISTS BECAUSE OF A FAILURE. The seven store tests below need Postgres,
// and the environment they were written in has none — so their first run was
// on the server, and it found that a `quiz` answer is `{"chose":[n]}` and not
// `n`. Every test that answered a question had come back with ErrBadAnswer
// instead of a verdict.
//
// This asserts the same outcomes one layer down: present, restore through the
// permutation, grade, reveal. It is not a duplicate of the store tests — it
// cannot see the SQL, and they cannot run everywhere. When both are red the
// fault is in the contract; when only they are, it is in the wiring.
func TestTheGraderContractThisPackageDependsOn(t *testing.T) {
	payload := json.RawMessage(quiz("ex-probe"))

	p, err := grade.Present("quiz", payload, grade.NewShuffler())
	if err != nil {
		t.Fatalf("presenting: %v", err)
	}
	if strings.Contains(string(p.Shown), `"correct"`) || strings.Contains(string(p.Shown), `"why"`) {
		t.Fatalf("the presented form leaks: %s", p.Shown)
	}

	var shown struct {
		Choices []struct {
			Text string `json:"text"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(p.Shown, &shown); err != nil {
		t.Fatalf("reading the presented form: %v", err)
	}

	right, wrong := -1, -1
	for i, c := range shown.Choices {
		if strings.HasPrefix(c.Text, "the client") {
			right = i
		}
		if strings.HasPrefix(c.Text, "the server") {
			wrong = i
		}
	}
	if right < 0 || wrong < 0 {
		t.Fatalf("the options under test are not among %d shown", len(shown.Choices))
	}

	for _, tc := range []struct {
		name string
		at   int
		want bool
	}{{"the right one", right, true}, {"a wrong one", wrong, false}} {
		original, err := grade.Restore("quiz", chose(tc.at), p.Perm)
		if err != nil {
			t.Fatalf("%s: restoring: %v", tc.name, err)
		}
		got, err := grade.Grade("quiz", payload, original)
		if err != nil {
			t.Fatalf("%s: grading: %v", tc.name, err)
		}
		if got.Correct != tc.want {
			t.Errorf("%s: correct=%v, want %v (perm=%v, chose %d)", tc.name, got.Correct, tc.want, p.Perm, tc.at)
		}
		if !tc.want && got.Why == "" {
			t.Error("a wrong answer came back with no reason")
		}
	}

	rev, err := grade.Expected("quiz", payload, p.Perm)
	if err != nil {
		t.Fatalf("revealing: %v", err)
	}
	if rev.Expected == nil {
		t.Error("nothing was revealed")
	}
}
