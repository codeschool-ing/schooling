package grade

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"math/rand/v2"
	"strings"
)

/* ---------- expression-answer ---------- */

// expressionAnswer marks an algebraic expression against another one.
//
// # SAMPLING, NOT SYMBOL PUSHING
//
// Two expressions over the reals are the same thing if they agree everywhere,
// and "everywhere" is sampled: both are evaluated at a spread of points and
// compared. `2x+1` and `1+2x` agree at every point; `x^2` and `2x` agree at 0
// and at 2 and nowhere else, so two dozen points separate them immediately.
//
// The failure direction is the safe one. A wrong answer is accepted only if it
// agrees with the right one at EVERY sample — for two different polynomials of
// degree n that can happen at n points, never at twenty-four spread across a
// range. What this cannot do is prove equality; what it does is make a false
// accept require a coincidence nobody could construct by being wrong.
//
// # THE SAMPLE POINTS ARE FIXED
//
// Not random. A grader that sampled randomly would give the same answer
// different verdicts on different days, and a student told they were right on
// Tuesday and wrong on Thursday has no way to find out which was the mistake.
// Randomness in a marking path is a defect, not a feature.
//
// # AND THEY ARE NOT ROUND NUMBERS
//
// The trap is sampling at integers. `x^2` and `2x` agree at 0 and 2; `sin(x)`
// and `0` agree at every multiple of pi. The offsets below are irrational
// enough that an accidental agreement has to be a real one.
//
// # WHAT IT CANNOT SEE, SAID PLAINLY
//
// A difference at a single point. `x` and `x + 0*(1/x)` are different functions
// — the second has a hole at zero — and no finite set of samples will land on
// it. This grader calls them the same.
//
// That is the honest limit of the technique and it is the right trade: the
// alternative is a computer algebra system in the path that marks a student's
// exam, and the answers it would newly reject are ones no student writes by
// accident. A question that turns on a removable singularity is a question for
// a type that does not exist yet.
type expressionAnswer struct{}

type expressionPayload struct {
	common

	// Accept is the expression a correct answer has to equal. One, not a list:
	// the whole point is that `2x+1` and `1+2x` are the same answer, so a list
	// would be somebody enumerating spellings the grader already handles.
	Accept string `json:"accept"`

	// The letters that are variables, and where to sample them. A range per
	// variable because `ln(x)` has nothing to say below zero, and a question
	// about it sampled from -5 would be undefined everywhere.
	Variables []expressionVariable `json:"variables"`

	// How close counts, relative to the size of the value. Zero takes the
	// default: floating point makes exact equality the wrong test — `(x/3)*3`
	// and `x` are the same expression and differ in the last bit.
	Tolerance float64 `json:"tolerance"`

	// What to say to somebody who got it wrong. One per question rather than
	// one per answer, because there is no list of wrong answers to attach it to
	// — an expression question has infinitely many. It is the AUTHOR's words,
	// as everywhere else: a grader that wrote its own feedback would be writing
	// content.
	Why string `json:"why"`
}

type expressionVariable struct {
	Name string   `json:"name"`
	From *float64 `json:"from"`
	To   *float64 `json:"to"`
}

// What a student sends. The expression as they typed it.
type expressionAnswerBody struct {
	Expression string `json:"expression"`
}

// What they are shown: the prompt, and which letters are variables. Not the
// range — it is an authoring detail, and showing it would invite answers
// written to pass the samples rather than to be right.
type expressionShown struct {
	common
	Variables []string `json:"variables"`
}

const (
	// Twenty-four points. Two different polynomials of degree n agree at most
	// at n of them, and a question whose answer is degree twenty-four is not a
	// question anybody is asking.
	samples = 24

	// The default range, and the default closeness. Both are overridable per
	// question because a question about `ln` needs a positive range and one
	// about a physical constant needs a looser tolerance.
	defaultFrom = -4.0
	defaultTo   = 4.0

	defaultTolerance = 1e-7

	// Below this many usable points the answer is not being compared, it is
	// being guessed at. A question whose accepted expression is undefined
	// almost everywhere is a question with a range somebody got wrong, and it
	// fails the content check rather than marking students on eight points.
	usablePoints = 8
)

func (expressionAnswer) grade(payload, answer json.RawMessage) (Result, error) {
	p, err := decodeExpressionPayload(payload)
	if err != nil {
		return Result{}, err
	}

	var a expressionAnswerBody
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return Result{}, err
	}
	if strings.TrimSpace(a.Expression) == "" {
		return Result{}, fmt.Errorf("%w: it is empty", ErrBadAnswer)
	}

	theirs, err := parse(a.Expression)
	if err != nil {
		/* A STUDENT'S TYPO IS A BAD ANSWER, NOT A WRONG ONE. `2x +` is not an
		   expression, and marking it wrong would put a failure in their history
		   for a slip they could see on the screen. The caller turns this into
		   "that is not an expression" and lets them fix it. */
		return Result{}, fmt.Errorf("%w: %w", ErrBadAnswer, err)
	}

	ours, err := parse(p.Accept)
	if err != nil {
		// The question is broken, not the answer. A different error, because a
		// student must never be told their answer is malformed when it is the
		// question that is.
		return Result{}, fmt.Errorf("%w: the accepted expression does not parse: %w", ErrBadPayload, err)
	}

	same, compared, err := agree(ours, theirs, p)
	if err != nil {
		return Result{}, err
	}

	/* A DISAGREEMENT NEEDS ONE POINT AND AN AGREEMENT NEEDS MANY, which is the
	   asymmetry this check exists for. Finding one place where two expressions
	   differ settles it — nothing more can be learnt by looking further, and
	   the loop stops there. Finding no such place only means something if there
	   were places to look: "they agreed everywhere we could see" is worth
	   nothing when we could see almost nowhere.

	   Applied to both, this turned three correct verdicts of WRONG into "the
	   question is broken", because the loop had stopped at the first
	   disagreement and one point had been compared. */
	if same && compared < usablePoints {
		return Result{}, fmt.Errorf(
			"%w: the accepted expression has a value at only %d of %d sample points, so "+
				"an answer agreeing with it everywhere visible means very little — the range "+
				"this question declares is one its own answer barely lives in",
			ErrBadPayload, compared, samples)
	}

	if same {
		return Result{Correct: true}, nil
	}
	return Result{Correct: false, Why: p.Why}, nil
}

// agree answers whether two expressions take the same value everywhere it was
// possible to look, and how many places that was.
func agree(ours, theirs node, p expressionPayload) (same bool, compared int, err error) {
	tolerance := p.Tolerance
	if tolerance <= 0 {
		tolerance = defaultTolerance
	}

	for i := range samples {
		at := map[string]float64{}
		for v, variable := range p.Variables {
			at[variable.Name] = sampleAt(i, v, variable)
		}

		want, errOurs := ours.eval(at)
		got, errTheirs := theirs.eval(at)

		switch {
		case errors.Is(errOurs, errUndefined):
			// Nothing to compare here. If the student's is defined and ours is
			// not, that is not a disagreement we can see — `1/x` at zero says
			// nothing about anybody.
			continue

		case errOurs != nil:
			return false, 0, fmt.Errorf("%w: the accepted expression: %w", ErrBadPayload, errOurs)

		case errors.Is(errTheirs, errUndefined):
			/* THEIRS HAS NO VALUE WHERE OURS DOES, which is a real difference:
			   `1/x` and `x` differ at zero, and one of them is undefined there.
			   Wrong rather than skipped. */
			return false, compared, nil

		case errTheirs != nil:
			// A letter the question did not declare, a function that does not
			// exist: their answer, and their mistake to see and fix.
			return false, 0, fmt.Errorf("%w: %w", ErrBadAnswer, errTheirs)
		}

		compared++
		if !withinTolerance(want, got, tolerance) {
			return false, compared, nil
		}
	}
	return true, compared, nil
}

// withinTolerance compares with a tolerance that scales, because floating point does.
// `(x/3)*3` and `x` are the same expression and differ in the last bit, and at
// x = 1e6 that difference is not 1e-7.
func withinTolerance(a, b, tolerance float64) bool {
	if a == b {
		return true
	}
	scale := math.Max(math.Abs(a), math.Abs(b))
	return math.Abs(a-b) <= tolerance*math.Max(1, scale)
}

// sampleAt is the value of one variable at one sample.
//
// A FIXED, IRREGULAR SPREAD. The i-th point walks the range by an irrational
// fraction of it and wraps — which lands nowhere near the round numbers where
// different expressions coincide, spreads evenly however many points are taken,
// and gives every variable a different walk so that a two-variable question is
// not sampled along the diagonal `x == y`.
func sampleAt(i, which int, v expressionVariable) float64 {
	from, to := defaultFrom, defaultTo
	if v.From != nil {
		from = *v.From
	}
	if v.To != nil {
		to = *v.To
	}
	if to <= from {
		// A range somebody wrote backwards. The content check catches it; here
		// it must not divide by a negative width and produce points outside.
		from, to = defaultFrom, defaultTo
	}

	// The golden ratio's fractional part, and a different offset per variable.
	// Any irrational does; this one distributes best for small counts.
	const phi = 0.6180339887498949
	at := math.Mod(phi*float64(i+1)+0.37*float64(which+1), 1)
	return from + at*(to-from)
}

// present strips the answer and says which letters are variables.
//
// NOTHING IS SHUFFLED, so there is no permutation to keep: an expression
// question has no order that could give the answer away. What matters is what
// is REMOVED — `accept` is the answer, and the ranges are an authoring detail
// that would invite answers written to pass the samples rather than to be
// right.
func (expressionAnswer) present(payload json.RawMessage, _ *rand.Rand) (Presented, error) {
	p, err := decodeExpressionPayload(payload)
	if err != nil {
		return Presented{}, err
	}

	shown := expressionShown{common: p.common}
	for _, v := range p.Variables {
		shown.Variables = append(shown.Variables, v.Name)
	}

	body, err := json.Marshal(shown)
	if err != nil {
		return Presented{}, fmt.Errorf("grade: presenting an expression question: %w", err)
	}
	return Presented{Shown: body}, nil
}

// restore has nothing to undo: the answer is text the student typed, in no
// frame but their own.
func (expressionAnswer) restore(answer json.RawMessage, _ []int) (json.RawMessage, error) {
	return answer, nil
}

func (expressionAnswer) key(payload json.RawMessage) (json.RawMessage, error) {
	p, err := decodeExpressionPayload(payload)
	if err != nil {
		return nil, err
	}

	if strings.TrimSpace(p.Accept) == "" {
		return nil, errors.New("an expression question with nothing to accept cannot be answered")
	}
	if len(p.Variables) == 0 {
		return nil, errors.New("no variables, so the question is a number and belongs in `numeric`")
	}

	if _, err := parse(p.Accept); err != nil {
		// The one thing this check exists for. A question whose own answer does
		// not parse cannot be answered by anybody, and a schema check passes it.
		return nil, fmt.Errorf("the accepted expression does not parse: %w", err)
	}

	seen := map[string]bool{}
	for _, v := range p.Variables {
		switch {
		case strings.TrimSpace(v.Name) == "":
			return nil, errors.New("a variable with no name")
		case seen[v.Name]:
			return nil, fmt.Errorf("the variable %q is declared twice", v.Name)
		case isConstant(v.Name):
			return nil, fmt.Errorf("%q is a constant here, so an expression using it would mean "+
				"two things at once", v.Name)
		}
		seen[v.Name] = true

		if v.From != nil && v.To != nil && *v.To <= *v.From {
			return nil, fmt.Errorf("the range for %q is %v to %v, which is empty or backwards",
				v.Name, *v.From, *v.To)
		}
	}

	// THE KEY IS THE ACCEPTED EXPRESSION ITSELF, which is what makes the
	// content check meaningful: it feeds this straight back into Grade, so a
	// question whose accepted expression does not parse, or is undefined across
	// the range it declares, fails on a pull request rather than in front of a
	// student (C-12).
	return json.Marshal(expressionAnswerBody{Expression: p.Accept})
}

// A variable may not be named after a constant. `pi` meaning both the number
// and a letter to substitute is an expression nobody can read, and the
// two-value lookup rather than a comparison to zero because a constant that
// happened to be zero would otherwise slip through.
func isConstant(name string) bool {
	_, taken := constants[strings.ToLower(name)]
	return taken
}

func decodeExpressionPayload(payload json.RawMessage) (expressionPayload, error) {
	var p expressionPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return expressionPayload{}, err
	}
	return p, nil
}
