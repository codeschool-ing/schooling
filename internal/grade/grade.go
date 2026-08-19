// Package grade judges an answer against a question, and answers what a
// correct answer looks like.
//
// # ONE IMPLEMENTATION, AND IT IS THIS ONE
//
// A-09 promised two — the client marking for immediate feedback, the server
// marking exams, held to each other by a conformance test. It is retired, and
// the reason is the rule beside it in this package: a question is PRESENTED
// rather than sent. A client that could mark an answer is a client holding the
// key, so the second implementation could only have existed by undoing what
// keeps an exam an exam. The last place it might have lived — feedback on a
// drill — is marked here too.
//
// The fixtures in testdata/conformance stay. They are the contract between this
// grader and the questions rather than between two graders: each is a question
// with the answers that should pass and the answers that should fail, so a
// change here that alters a verdict has to change one of them where a reviewer
// can see it. A gradable type with no fixture fails the build.
//
// # WHY Key EXISTS
//
// A schema check would pass a question whose answer key is wrong, and that is
// the one failure this system cannot absorb (C-12). So every grader can produce
// the answer its own payload says is correct — and the content check feeds that
// straight back into Grade and insists on a pass. A quiz with two correct
// choices, a matching with a duplicated right-hand side, an ordering of one
// item: each of them is a question that looks fine and cannot be answered
// correctly, and each is caught by asking the grader rather than by asking a
// schema.
//
// # BINARY, NOT PARTIAL
//
// A question is right or it is not. Partial credit is a decision about
// assessment that has to be made once and applied to every type — what half of
// a matching is worth, whether an ordering with two items swapped beats one
// reversed — and nobody has made it. A grader that invented its own would make
// two exams incomparable, quietly.
//
// # AN ANSWER IS MEANINGFUL ONLY AGAINST ITS VERSION
//
// Choices are referred to by position, which is exactly the join this project
// refuses everywhere else — and it is safe here for one reason: an exercise is
// immutable within a version, and a student's answer records the version it
// answered (C-16). Editing choices means a new version, and the old answers
// stay attached to the old one.
package grade

import (
	"encoding/json"
	"errors"
	"fmt"
	"sort"
)

// Result is the judgement.
type Result struct {
	Correct bool `json:"correct"`

	// Why is shown to the student when it is wrong, and it comes from the
	// question rather than from this code: a grader that wrote its own feedback
	// would be writing content, which is not its job.
	Why string `json:"why,omitempty"`
}

// ErrUnknownType is a question this build cannot grade.
//
// IT IS AN ERROR AND NOT A PASS. A type nobody wrote a grader for must not
// become a question every student gets right — which is what "unknown type,
// give them the mark" would mean, and it is the direction a lenient default
// always goes.
var ErrUnknownType = errors.New("grade: no grader for that type of question")

// ErrBadPayload is a question whose own definition cannot be read.
var ErrBadPayload = errors.New("grade: the question is not shaped like its type")

// ErrBadAnswer is an answer that is not shaped like an answer to this type. It
// is deliberately distinct from a wrong answer: one is a client sending
// nonsense, the other is a student being wrong.
var ErrBadAnswer = errors.New("grade: that is not an answer to this question")

// A grader judges one type of question.
type grader interface {
	grade(payload, answer json.RawMessage) (Result, error)

	// key answers what a correct answer to this payload looks like, and
	// refuses a payload that has no correct answer at all.
	key(payload json.RawMessage) (json.RawMessage, error)
}

// The types this build can grade.
//
// `code`, `expected-output` and `expression-answer` are absent on purpose: the
// first two need a sandbox that runs a student's program, and the third needs a
// computer algebra system. Each is its own piece of work, and a stub that
// guessed would be worse than the honest refusal ErrUnknownType gives.
var graders = map[string]grader{
	"quiz":            choice{single: true},
	"multiple-choice": choice{},
	"ordering":        ordering{},
	"matching":        matching{},
	"cloze":           cloze{},
	"numeric":         numeric{},
	"labelling":       labelling{},
}

// Types answers every type this build can grade, sorted.
func Types() []string {
	out := make([]string, 0, len(graders))
	for name := range graders {
		out = append(out, name)
	}
	sort.Strings(out)
	return out
}

// Grade judges an answer.
func Grade(questionType string, payload, answer json.RawMessage) (Result, error) {
	g, ok := graders[questionType]
	if !ok {
		return Result{}, fmt.Errorf("%w: %q", ErrUnknownType, questionType)
	}
	return g.grade(payload, answer)
}

// Key answers what a correct answer to this question looks like.
func Key(questionType string, payload json.RawMessage) (json.RawMessage, error) {
	g, ok := graders[questionType]
	if !ok {
		return nil, fmt.Errorf("%w: %q", ErrUnknownType, questionType)
	}
	return g.key(payload)
}

// CheckKey proves a question can be answered correctly, by asking its grader
// for the right answer and grading it.
//
// THIS IS THE CHECK THE SCHEMA CANNOT DO. A quiz with two correct choices, an
// ordering with one item, a cloze whose accepted set is empty once normalised —
// every one of them passes a shape check and cannot be answered. The content
// checker runs this over every exercise before anything reaches a student.
func CheckKey(questionType string, payload json.RawMessage) error {
	answer, err := Key(questionType, payload)
	if err != nil {
		return err
	}

	result, err := Grade(questionType, payload, answer)
	if err != nil {
		return fmt.Errorf("its own answer key could not be graded: %w", err)
	}
	if !result.Correct {
		return errors.New("its own answer key grades as wrong — the question cannot be " +
			"answered correctly by anybody")
	}
	return nil
}

// common is what every exercise carries, whatever its type.
//
// IT IS DECLARED HERE SO THAT DisallowUnknownFields STAYS ON. The payload a
// grader receives is the whole exercise as it was written — `id`, `prompt` and
// the type-specific fields side by side, which is the format `content/` uses
// and the format a person reads. Listing the common fields once means an
// unrecognised field is still what it should be: a typo, or a fact somebody
// wrote down that nothing reads.
type common struct {
	ID         string `json:"id"`
	Version    int    `json:"version"`
	Section    string `json:"section"`
	Type       string `json:"type"`
	Difficulty string `json:"difficulty"`
	Drillable  bool   `json:"drillable"`
	Prompt     string `json:"prompt"`
	Hint       string `json:"hint"`
}

// decode reads a payload or an answer, and refuses anything it does not
// recognise. An unknown field in a question is a fact somebody wrote down and
// nothing reads.
func decode(body json.RawMessage, into any, kind error) error {
	if len(body) == 0 {
		return fmt.Errorf("%w: it is empty", kind)
	}
	decoder := json.NewDecoder(newReader(body))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(into); err != nil {
		return fmt.Errorf("%w: %w", kind, err)
	}
	return nil
}
