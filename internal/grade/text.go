package grade

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

/* ---------- cloze ---------- */

// cloze grades a blank against a set of accepted answers.
//
// THE NORMALISATION IS DECLARED PER QUESTION, not chosen here. Whether case
// matters is a property of what is being asked: `SELECT` and `select` are the
// same keyword, and `Paris` and `paris` are the same city, but in a question
// about naming conventions the difference is the entire point. A grader that
// decided for everybody would be answering a pedagogical question with a
// default.
type cloze struct{}

type clozePayload struct {
	common

	Blanks []clozeBlank `json:"blanks"`
}

type clozeBlank struct {
	Accept []string `json:"accept"`

	// Both default to false, which is the strict direction. A question that
	// wants to be forgiving says so, and one that says nothing is taken at its
	// word rather than quietly loosened.
	IgnoreCase    bool `json:"ignore_case"`
	IgnoreAccents bool `json:"ignore_accents"`
}

type clozeAnswer struct {
	Filled []string `json:"filled"`
}

func (cloze) grade(payload, answer json.RawMessage) (Result, error) {
	var p clozePayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Result{}, err
	}
	var a clozeAnswer
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return Result{}, err
	}

	if len(a.Filled) != len(p.Blanks) {
		return Result{}, fmt.Errorf("%w: it fills %d blanks and the question has %d",
			ErrBadAnswer, len(a.Filled), len(p.Blanks))
	}

	for i, blank := range p.Blanks {
		if !accepts(blank, a.Filled[i]) {
			return Result{Correct: false}, nil
		}
	}
	return Result{Correct: true}, nil
}

func accepts(blank clozeBlank, given string) bool {
	got := normalise(given, blank)
	for _, want := range blank.Accept {
		if normalise(want, blank) == got {
			return true
		}
	}
	return false
}

// normalise collapses what nobody meant to type differently.
//
// Whitespace always: a trailing space is not a wrong answer, in any subject,
// and a student who typed one has not made the mistake the question is about.
// Case and accents only when the question says so.
func normalise(s string, blank clozeBlank) string {
	s = strings.Join(strings.Fields(s), " ")
	if blank.IgnoreCase {
		s = strings.ToLower(s)
	}
	if blank.IgnoreAccents {
		s = stripAccents(s)
	}
	return s
}

// stripAccents removes combining marks, which is what makes `funções` and
// `funcoes` the same answer to a question that is not about spelling.
//
// DECOMPOSE FIRST. `ç` is one rune, not a `c` with a mark beside it, until NFD
// pulls it apart — so stripping marks off the string as typed removes nothing
// and the two answers stay different, which is the bug this exists to avoid.
func stripAccents(s string) string {
	var b strings.Builder
	for _, r := range norm.NFD.String(s) {
		if unicode.Is(unicode.Mn, r) {
			continue
		}
		b.WriteRune(r)
	}
	return norm.NFC.String(b.String())
}

func (cloze) key(payload json.RawMessage) (json.RawMessage, error) {
	var p clozePayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return nil, err
	}
	if len(p.Blanks) == 0 {
		return nil, errors.New("a cloze with no blanks asks nothing")
	}

	filled := make([]string, len(p.Blanks))
	for i, blank := range p.Blanks {
		if len(blank.Accept) == 0 {
			return nil, fmt.Errorf("blank %d accepts nothing, so it cannot be answered", i+1)
		}

		// A blank whose accepted answers are empty ONCE NORMALISED is the case a
		// shape check passes: `accept: [" "]` is a non-empty list of nothing.
		usable := 0
		for _, one := range blank.Accept {
			if normalise(one, blank) != "" {
				usable++
			}
		}
		if usable == 0 {
			return nil, fmt.Errorf("blank %d accepts only blank answers once normalised", i+1)
		}

		filled[i] = blank.Accept[0]
	}
	return json.Marshal(clozeAnswer{Filled: filled})
}
