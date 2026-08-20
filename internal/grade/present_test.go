package grade_test

import (
	"encoding/json"
	"fmt"
	"math/rand/v2"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/grade"
)

// seeded is the deterministic source these tests use.
//
// A TEST WANTS A REPRODUCIBLE SHUFFLE, which is the opposite of what an exam
// wants — an exam uses grade.NewShuffler, seeded from crypto/rand. The
// exception is written once here rather than on each call.
func seeded(n uint64) *rand.Rand {
	return rand.New(rand.NewPCG(n, n)) //nolint:gosec // deterministic on purpose; see above
}

func rng() *rand.Rand { return seeded(1) }

// THE ONE THAT MATTERS, and it is stated as a property rather than as a list of
// field names — which is what makes it cover a type somebody adds later without
// reading any of this.
//
// A STUDENT WHO RUNS THE GRADER'S OWN KEY LOGIC OVER WHAT THEY RECEIVED MUST
// NOT GET A PASS. That is the whole claim. It is deliberately not "asking for
// the key must fail": for `ordering` and `numeric` it does not fail, it
// succeeds and produces something WRONG — the key of a shuffled ordering is
// "leave them as they are", and the key of a redacted numeric is zero. Both are
// answers; neither is the answer. Stating the property as a refusal rather than
// as a wrong result was my first attempt, and it failed on two fixtures that
// are perfectly safe.
func TestWhatCanBeDerivedFromAPresentedQuestionDoesNotPass(t *testing.T) {
	for name, f := range fixtures(t) {
		tried := 0

		for seed := uint64(1); seed <= 16; seed++ {
			presented, err := grade.Present(f.Type, f.Payload, seeded(seed))
			if err != nil {
				t.Errorf("%s: presenting: %v", name, err)
				break
			}
			// A shuffle that happens to land on the original order hides
			// nothing and is not the case under test.
			if identity(presented.Perm) {
				continue
			}
			tried++

			// Everything a student could work out from what they were sent.
			derived, err := grade.Key(f.Type, presented.Shown)
			if err != nil {
				continue // nothing derivable at all, which is the strongest answer
			}

			restored, err := grade.Restore(f.Type, derived, presented.Perm)
			if err != nil {
				continue
			}
			result, err := grade.Grade(f.Type, f.Payload, restored)
			if err == nil && result.Correct {
				t.Errorf("%s: an answer worked out from what the student was sent passes — "+
					"whatever the fields are called, the answer was sent\n  shown: %s",
					name, presented.Shown)
				break
			}
		}

		if tried == 0 && needsShuffling(f.Type) {
			t.Errorf("%s: sixteen draws all came back in the original order", name)
		}
	}
}

func identity(perm []int) bool {
	for i, at := range perm {
		if i != at {
			return false
		}
	}
	return true
}

// The types whose order is part of the answer, and which therefore have to be
// shuffled rather than merely redacted.
func needsShuffling(questionType string) bool {
	switch questionType {
	case "quiz", "multiple-choice", "ordering", "matching":
		return true
	}
	return false
}

// And the same thing said the blunt way, because the property above would still
// hold if a payload carried the answer under a name the grader ignores.
func TestNothingInAPresentedQuestionSaysWhichAnswerIsRight(t *testing.T) {
	// `"trap"` is on the list for the same reason as the rest: it names the
	// neighbouring pair students swap, which is the placement the question is
	// asking about. It is feedback once the answer is in, and the answer before.
	tells := []string{`"correct"`, `"why"`, `"accept"`, `"value"`, `"tolerance"`, `"radius"`, `"trap"`}

	for name, f := range fixtures(t) {
		presented, err := grade.Present(f.Type, f.Payload, rng())
		if err != nil {
			t.Errorf("%s: presenting: %v", name, err)
			continue
		}

		shown := string(presented.Shown)
		for _, tell := range tells {
			if strings.Contains(shown, tell) {
				t.Errorf("%s: the presented question still carries %s:\n  %s", name, tell, shown)
			}
		}
	}
}

// THE SECOND ONE THAT MATTERS.
//
// Hiding the answer is only half of it: an answer given against the shuffled
// form has to grade correctly against the question as it was written. Get the
// permutation backwards and every student's correct answer is marked wrong, all
// at once, and the exam looks impossibly hard rather than broken.
func TestACorrectAnswerSurvivesBeingShuffledAndPutBack(t *testing.T) {
	for name, f := range fixtures(t) {
		presented, err := grade.Present(f.Type, f.Payload, rng())
		if err != nil {
			t.Errorf("%s: presenting: %v", name, err)
			continue
		}

		// The correct answer, expressed against the shown form.
		key, err := grade.Key(f.Type, f.Payload)
		if err != nil {
			t.Errorf("%s: %v", name, err)
			continue
		}
		inShownFrame, err := intoShownFrame(f.Type, key, presented.Perm)
		if err != nil {
			t.Errorf("%s: %v", name, err)
			continue
		}

		restored, err := grade.Restore(f.Type, inShownFrame, presented.Perm)
		if err != nil {
			t.Errorf("%s: restoring: %v", name, err)
			continue
		}

		result, err := grade.Grade(f.Type, f.Payload, restored)
		if err != nil {
			t.Errorf("%s: grading the restored answer: %v", name, err)
			continue
		}
		if !result.Correct {
			t.Errorf("%s: the correct answer was marked wrong after being shuffled and put "+
				"back — every student's right answer fails at once, and the exam looks hard "+
				"rather than broken\n  perm: %v\n  shown frame: %s\n  restored: %s",
				name, presented.Perm, inShownFrame, restored)
		}
	}
}

// A question really is shuffled, for the types where the order is the answer.
// A permutation that is always the identity would pass every test above and
// hide nothing.
func TestTheOrderActuallyMoves(t *testing.T) {
	for name, f := range fixtures(t) {
		if f.Type != "ordering" && f.Type != "quiz" &&
			f.Type != "multiple-choice" && f.Type != "matching" {
			continue
		}

		moved := false
		// Several draws, because one shuffle can legitimately land on the
		// identity and a test that failed on that would be a flake.
		for seed := uint64(1); seed <= 8 && !moved; seed++ {
			presented, err := grade.Present(f.Type, f.Payload, seeded(seed))
			if err != nil {
				t.Fatalf("%s: %v", name, err)
			}
			for i, at := range presented.Perm {
				if i != at {
					moved = true
					break
				}
			}
		}
		if !moved {
			t.Errorf("%s: eight draws all came back in the original order, so nothing is being "+
				"hidden", name)
		}
	}
}

// intoShownFrame expresses a correct answer the way a student would have given
// it against the shuffled question. It is the inverse of Restore, written out
// here rather than exported, because nothing in the product needs it — only a
// test that wants to play the part of a student who knows the material.
func intoShownFrame(questionType string, key json.RawMessage, perm []int) (json.RawMessage, error) {
	if perm == nil {
		return key, nil
	}

	inverse := make([]int, len(perm))
	for shown, original := range perm {
		inverse[original] = shown
	}

	var decoded map[string][]int
	if err := json.Unmarshal(key, &decoded); err != nil {
		return nil, err
	}
	for field, positions := range decoded {
		moved := make([]int, len(positions))
		for i, at := range positions {
			moved[i] = inverse[at]
		}
		decoded[field] = moved
	}

	// `ordering` is the one where the answer is a sequence rather than a set:
	// the student arranges the shown items, so the arrangement that is right is
	// the shown positions in the original's order.
	if questionType == "ordering" {
		decoded["order"] = inverse
	}
	return json.Marshal(decoded)
}

// A type that cannot hide its answer must not be presentable at all. Refusing
// is the only safe direction — the alternative is a question whose answer is in
// the response body.
func TestAnUnknownTypeCannotBePresented(t *testing.T) {
	for _, questionType := range []string{"", "code", "essay"} {
		if _, err := grade.Present(questionType, json.RawMessage(`{}`), rng()); err == nil {
			t.Errorf("%q was presented, and nothing knows how to hide its answer", questionType)
		}
	}
}

/* ---------- and what is revealed afterwards ---------- */

// THE KEY POINTS AT THE THING THE STUDENT IS LOOKING AT.
//
// A reveal is expressed in the frame the question was SHOWN in, and the payload
// is written in the frame it was AUTHORED in. Get that backwards and the tick
// lands on choice 2 of a list whose choices are in a different order on screen:
// a student who answered correctly is shown their own answer marked wrong,
// which is the worst way for this to fail — it looks like the grader, not like
// the arrangement.
//
// So the reveal is turned back into an answer and graded. If what it points at
// is right, that answer passes; if it is off by a permutation, it does not.
func TestWhatIsRevealedIsTheAnswerInTheFrameTheStudentSaw(t *testing.T) {
	for name, f := range fixtures(t) {
		presented, err := grade.Present(f.Type, f.Payload, rng())
		if err != nil {
			t.Errorf("%s: presenting: %v", name, err)
			continue
		}

		revealed, err := grade.Expected(f.Type, f.Payload, presented.Perm)
		if err != nil {
			t.Errorf("%s: revealing: %v", name, err)
			continue
		}
		if revealed.Expected == nil {
			// A type whose renderer needs nothing — see reveal.go. There is no
			// arrangement to explain, so there is nothing here to check.
			continue
		}

		answer, err := revealAsAnswer(f.Type, revealed, presented.Shown)
		if err != nil {
			t.Errorf("%s: %v", name, err)
			continue
		}

		restored, err := grade.Restore(f.Type, answer, presented.Perm)
		if err != nil {
			t.Errorf("%s: restoring: %v", name, err)
			continue
		}
		result, err := grade.Grade(f.Type, f.Payload, restored)
		if err != nil {
			t.Errorf("%s: grading what was revealed: %v", name, err)
			continue
		}
		if !result.Correct {
			t.Errorf("%s: what is revealed as the answer does not grade as correct — a "+
				"student is being shown one thing and marked on another\n  perm: %v\n"+
				"  shown: %s\n  revealed: %+v", name, presented.Perm, presented.Shown, revealed)
		}
	}
}

// revealAsAnswer writes a reveal back as the answer a student would have given
// to earn it, in the shown frame — which is the only frame it is expressed in.
func revealAsAnswer(questionType string, r grade.Reveal, shown json.RawMessage) (json.RawMessage, error) {
	var seen struct {
		Items []string `json:"items"`
		Right []string `json:"right"`
	}
	if err := json.Unmarshal(shown, &seen); err != nil {
		return nil, err
	}

	// The reveal has been through JSON on its way to a client, so it is read
	// back the way a client reads it rather than as the Go types that built it.
	body, err := json.Marshal(r.Expected)
	if err != nil {
		return nil, err
	}

	switch questionType {
	case "quiz":
		var at int
		if err := json.Unmarshal(body, &at); err != nil {
			return nil, err
		}
		return json.Marshal(map[string][]int{"chose": {at}})

	case "multiple-choice":
		var at []int
		if err := json.Unmarshal(body, &at); err != nil {
			return nil, err
		}
		return json.Marshal(map[string][]int{"chose": at})

	case "ordering":
		var want []string
		if err := json.Unmarshal(body, &want); err != nil {
			return nil, err
		}
		order, err := positionsOf(want, seen.Items)
		if err != nil {
			return nil, err
		}
		return json.Marshal(map[string][]int{"order": order})

	case "matching":
		var want []string
		if err := json.Unmarshal(body, &want); err != nil {
			return nil, err
		}
		matched, err := positionsOf(want, seen.Right)
		if err != nil {
			return nil, err
		}
		return json.Marshal(map[string][]int{"matched": matched})
	}
	return nil, fmt.Errorf("%s revealed %v and nothing here knows what to do with it",
		questionType, r.Expected)
}

// Where each of `want` sits in `among`. A text that is not there at all is the
// failure this whole test exists to catch, so it is an error rather than a -1
// quietly graded as wrong.
func positionsOf(want, among []string) ([]int, error) {
	out := make([]int, 0, len(want))
	for _, one := range want {
		at := -1
		for i, candidate := range among {
			if candidate == one {
				at = i
				break
			}
		}
		if at < 0 {
			return nil, fmt.Errorf("the reveal names %q, which is not among what was shown: %v",
				one, among)
		}
		out = append(out, at)
	}
	return out, nil
}
