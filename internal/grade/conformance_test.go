package grade_test

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"

	"github.com/codeschool-ing/schooling/internal/grade"
)

// The conformance fixtures: the contract between the grader and the questions.
//
// THEY WERE WRITTEN FOR A DIFFERENT REASON, and the old one is gone. A-09
// promised two graders — the client marking for immediate feedback, the server
// marking exams — which had to agree or the same answer would score differently
// in two places. There is no client grader and there is not going to be one: a
// question is PRESENTED rather than sent, so a client that could mark an answer
// is a client holding the key, and the second implementation could only have
// existed by undoing what keeps an exam an exam.
//
// THE FILES ARE WORTH AS MUCH AS THEY EVER WERE, for the reason that was always
// underneath the other one. Each is a question with the answers that should
// pass and the answers that should fail, written by somebody deliberately — so
// a change in here that alters a verdict has to change one of them, in a diff
// where a reviewer can see the verdict change.
//
// A gradable type with no fixture fails the build. "I will add the fixture
// afterwards" is the door a silent behaviour change walks through, and the last
// test in this file is what keeps it shut.

type fixture struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
	Cases   []struct {
		Name    string          `json:"name"`
		Answer  json.RawMessage `json:"answer"`
		Correct bool            `json:"correct"`

		// "bad-answer" for an answer that is not an answer — a client sending
		// nonsense, which is a different thing from a student being wrong.
		Error string `json:"error"`
	} `json:"cases"`
}

func fixtures(t *testing.T) map[string]fixture {
	t.Helper()

	names, err := filepath.Glob("testdata/conformance/*.json")
	if err != nil {
		t.Fatalf("listing the fixtures: %v", err)
	}
	if len(names) == 0 {
		t.Fatal("no conformance fixtures at all, so this test proves nothing")
	}

	out := map[string]fixture{}
	for _, name := range names {
		body, err := os.ReadFile(name) //nolint:gosec // a path this test's own glob produced
		if err != nil {
			t.Fatalf("reading %s: %v", name, err)
		}
		var f fixture
		if err := json.Unmarshal(body, &f); err != nil {
			t.Fatalf("%s: %v", name, err)
		}
		out[filepath.Base(name)] = f
	}
	return out
}

func TestEveryConformanceCaseGradesAsItSays(t *testing.T) {
	for name, f := range fixtures(t) {
		if len(f.Cases) == 0 {
			t.Errorf("%s has no cases", name)
			continue
		}

		for _, c := range f.Cases {
			result, err := grade.Grade(f.Type, f.Payload, c.Answer)

			if c.Error != "" {
				if !errors.Is(err, grade.ErrBadAnswer) {
					t.Errorf("%s / %q: expected a refusal and got %v (correct=%v)",
						name, c.Name, err, result.Correct)
				}
				continue
			}

			if err != nil {
				t.Errorf("%s / %q: %v", name, c.Name, err)
				continue
			}
			if result.Correct != c.Correct {
				t.Errorf("%s / %q: graded correct=%v, the fixture says %v",
					name, c.Name, result.Correct, c.Correct)
			}
		}
	}
}

// THE ONE THAT MATTERS.
//
// Every fixture's own answer key has to grade as correct. This is the check a
// schema cannot do: a quiz with two correct choices, an ordering of one item, a
// cloze whose accepted set is empty once normalised — each passes a shape check
// and cannot be answered by anybody, and the failure reaches a student as a
// question they cannot get right however well they know the material (C-12).
func TestEveryFixtureCanBeAnsweredCorrectly(t *testing.T) {
	for name, f := range fixtures(t) {
		if err := grade.CheckKey(f.Type, f.Payload); err != nil {
			t.Errorf("%s: %v", name, err)
		}
	}
}

// And the fixture's declared correct case must be the key. A fixture that says
// a different answer is right than the grader's own key would mean the two
// halves of the contract disagree about the question rather than about an
// answer.
func TestTheKeyIsAmongTheCasesTheFixtureCallsCorrect(t *testing.T) {
	for name, f := range fixtures(t) {
		key, err := grade.Key(f.Type, f.Payload)
		if err != nil {
			t.Errorf("%s: %v", name, err)
			continue
		}

		result, err := grade.Grade(f.Type, f.Payload, key)
		if err != nil || !result.Correct {
			t.Errorf("%s: the key does not grade as correct: %v %+v", name, err, result)
			continue
		}

		found := false
		for _, c := range f.Cases {
			if c.Correct {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("%s has no case it calls correct, so nothing checks that the question can "+
				"be passed", name)
		}
	}
}

// EVERY TYPE THIS BUILD GRADES HAS A FIXTURE.
//
// Adding a grader without one leaves the client free to disagree with it and
// nothing to notice — which is the whole failure the fixtures exist to prevent,
// arriving through the door marked "I will add the fixture afterwards".
func TestEveryGradableTypeHasAConformanceFixture(t *testing.T) {
	covered := map[string]bool{}
	for _, f := range fixtures(t) {
		covered[f.Type] = true
	}

	for _, questionType := range grade.Types() {
		if !covered[questionType] {
			t.Errorf("%q can be graded and has no conformance fixture — its verdicts can be "+
				"changed by an edit in here and nothing would say so", questionType)
		}
	}
}

// A type nobody wrote a grader for is an error, never a pass.
//
// "Unknown type, give them the mark" is the direction a lenient default always
// goes, and it would turn a typo in a content file into a question every
// student gets right.
func TestATypeWithNoGraderIsRefusedRatherThanPassed(t *testing.T) {
	for _, questionType := range []string{
		"", "essay", "code", "expected-output", "Quiz",
	} {
		result, err := grade.Grade(questionType, json.RawMessage(`{}`), json.RawMessage(`{}`))
		if !errors.Is(err, grade.ErrUnknownType) {
			t.Errorf("the type %q was graded rather than refused: %v %+v", questionType, err, result)
		}
		if result.Correct {
			t.Errorf("the type %q was marked correct", questionType)
		}
	}
}
