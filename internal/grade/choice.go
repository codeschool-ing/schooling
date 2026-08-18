package grade

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"sort"
)

func newReader(body []byte) io.Reader { return bytes.NewReader(body) }

/* ---------- quiz and multiple-choice ---------- */

// choice grades both, and the only difference is how many answers are right.
//
// THEY ARE ONE GRADER BECAUSE THEY ARE ONE RULE: the set of choices the student
// picked has to equal the set marked correct. `quiz` additionally insists that
// set has exactly one member, which is a property of the QUESTION rather than
// of the grading — so it is checked where questions are checked.
type choice struct{ single bool }

type choicePayload struct {
	common

	Choices []struct {
		Text    string `json:"text"`
		Correct bool   `json:"correct"`
		Why     string `json:"why"`
	} `json:"choices"`
}

type choiceAnswer struct {
	// By position, which is safe because an exercise is immutable within a
	// version and an answer records the version. See the package comment.
	Chose []int `json:"chose"`
}

func (c choice) grade(payload, answer json.RawMessage) (Result, error) {
	var p choicePayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Result{}, err
	}
	var a choiceAnswer
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return Result{}, err
	}

	want := map[int]bool{}
	for i, one := range p.Choices {
		if one.Correct {
			want[i] = true
		}
	}

	got := map[int]bool{}
	for _, i := range a.Chose {
		if i < 0 || i >= len(p.Choices) {
			return Result{}, fmt.Errorf("%w: it picks choice %d of %d", ErrBadAnswer, i, len(p.Choices))
		}
		got[i] = true
	}

	if len(got) != len(want) {
		return Result{Correct: false, Why: whyOf(p, want)}, nil
	}
	for i := range want {
		if !got[i] {
			return Result{Correct: false, Why: whyOf(p, want)}, nil
		}
	}
	return Result{Correct: true}, nil
}

// whyOf collects the explanations attached to the correct choices. The words
// belong to the question; this only decides which of them to show.
func whyOf(p choicePayload, want map[int]bool) string {
	var out string
	for i, one := range p.Choices {
		if want[i] && one.Why != "" {
			if out != "" {
				out += " "
			}
			out += one.Why
		}
	}
	return out
}

func (c choice) key(payload json.RawMessage) (json.RawMessage, error) {
	var p choicePayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return nil, err
	}

	if len(p.Choices) < 2 {
		return nil, errors.New("a question with fewer than two choices is not a choice")
	}

	var correct []int
	for i, one := range p.Choices {
		if one.Correct {
			correct = append(correct, i)
		}
	}

	switch {
	case len(correct) == 0:
		return nil, errors.New("no choice is marked correct, so nobody can answer it")
	case c.single && len(correct) > 1:
		return nil, fmt.Errorf("a quiz has one correct choice and this has %d — either it is a "+
			"multiple-choice question, or one of them is marked wrongly", len(correct))
	case len(correct) == len(p.Choices):
		return nil, errors.New("every choice is marked correct, which asks nothing")
	}

	// Two choices with identical text is a question a person cannot answer even
	// knowing the material: they cannot tell which one they are picking.
	seen := map[string]bool{}
	for _, one := range p.Choices {
		if seen[one.Text] {
			return nil, fmt.Errorf("two choices read exactly the same: %q", one.Text)
		}
		seen[one.Text] = true
	}

	sort.Ints(correct)
	return json.Marshal(choiceAnswer{Chose: correct})
}
