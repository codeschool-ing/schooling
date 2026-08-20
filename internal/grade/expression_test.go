package grade_test

import (
	"encoding/json"
	"errors"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/grade"
)

// A question and an answer, spelt out so each test reads as the thing it is
// checking rather than as JSON assembly.
func expression(accept string, variables ...string) json.RawMessage {
	vs := make([]map[string]any, 0, len(variables))
	for _, v := range variables {
		vs = append(vs, map[string]any{"name": v})
	}
	body, err := json.Marshal(map[string]any{
		"id": "e", "version": 1, "type": "expression-answer",
		"prompt": "Write it.", "accept": accept, "variables": vs,
	})
	if err != nil {
		panic(err)
	}
	return body
}

func answered(with string) json.RawMessage {
	body, err := json.Marshal(map[string]any{"expression": with})
	if err != nil {
		panic(err)
	}
	return body
}

func marks(t *testing.T, accept, given string, variables ...string) grade.Result {
	t.Helper()
	result, err := grade.Grade("expression-answer", expression(accept, variables...), answered(given))
	if err != nil {
		t.Fatalf("grading %q against %q: %v", given, accept, err)
	}
	return result
}

// THE WHOLE POINT: the same expression written differently is the same answer.
// A grader that failed this would be marking notation, and a student writing
// what their textbook writes would be told they are wrong.
func TestTheSameExpressionWrittenDifferentlyIsAccepted(t *testing.T) {
	for _, given := range []string{
		"2*x + 1",
		"1 + 2*x",
		"2x+1",
		"x + x + 1",
		"1 + x*2",
		"(4x + 2)/2",
		"2(x + 0.5)",
	} {
		if !marks(t, "2*x + 1", given, "x").Correct {
			t.Errorf("%q was marked wrong against `2*x + 1`", given)
		}
	}
}

// AND THE TRAP THE SAMPLING EXISTS TO AVOID. `x^2` and `2x` agree at 0 and at
// 2; sampling at round numbers would call them the same. The points are chosen
// so that a coincidence has to be a real agreement.
func TestExpressionsThatMerelyCoincideSomewhereAreNotAccepted(t *testing.T) {
	for _, pair := range [][2]string{
		{"x^2", "2*x"},         // agree at 0 and 2
		{"x^2", "x"},           // agree at 0 and 1
		{"x^3", "x"},           // agree at -1, 0 and 1
		{"sin(x)", "0"},        // agree at every multiple of pi
		{"x*(x-1)*(x-2)", "0"}, // agree at 0, 1 and 2
		{"abs(x)", "x"},        // agree everywhere above zero
	} {
		if marks(t, pair[0], pair[1], "x").Correct {
			t.Errorf("%q was accepted as %q — they coincide in places and are not the same",
				pair[1], pair[0])
		}
	}
}

// A STUDENT'S TYPO IS A BAD ANSWER, NOT A WRONG ONE. Marking it wrong would put
// a failure in their history for a slip they can see on the screen — and in a
// drill it would move a schedule.
func TestSomethingThatIsNotAnExpressionIsNotAWrongAnswer(t *testing.T) {
	for _, given := range []string{
		"2x +",
		"(x + 1",
		"x + )",
		"",
		"   ",
		"x @ 2",
		"wibble(x)",
		"sin x",
		"y + 1",
	} {
		_, err := grade.Grade("expression-answer", expression("2*x + 1", "x"), answered(given))
		if !errors.Is(err, grade.ErrBadAnswer) {
			t.Errorf("%q gave %v, want ErrBadAnswer — a student must be able to fix a typo "+
				"rather than have it recorded as a failure", given, err)
		}
	}
}

// A CAPITAL LETTER IS A DIFFERENT VARIABLE, AND A CAPITALISED FUNCTION IS NOT A
// DIFFERENT FUNCTION.
//
// Every name used to be folded to lower case, which made a question written
// with `T` unanswerable — nothing declared `t` — and would have made a question
// about a period `T` and a time `t` a question about one letter, marking an
// answer that confused the two as correct.
func TestVariablesKeepTheirCaseAndFunctionsDoNot(t *testing.T) {
	if !marks(t, "L + T/v", "T/v + L", "T", "v", "L").Correct {
		t.Error("a question written with capital letters could not be answered with them")
	}
	if marks(t, "T + 1", "t + 1", "T", "t").Correct {
		t.Error("`t` was accepted for `T` — two variables the question declares separately")
	}

	// The same sine, however it is spelt.
	if !marks(t, "sin(x)", "SIN(x)", "x").Correct {
		t.Error("`SIN(x)` was marked wrong against `sin(x)`")
	}
	if !marks(t, "2*pi*x", "2*Pi*x", "x").Correct {
		t.Error("`Pi` was not read as the constant")
	}
}

// FLOATING POINT MAKES EXACT EQUALITY THE WRONG TEST. `(x/3)*3` and `x` are the
// same expression and differ in the last bit.
func TestExpressionsThatDifferOnlyInTheLastBitAreTheSame(t *testing.T) {
	for _, given := range []string{"(x/3)*3", "(x/7)*7", "sqrt(x^2)"} {
		// sqrt(x^2) is |x|, so it is only the same as x on a positive range —
		// which is what the range is for. Checked separately below.
		if given == "sqrt(x^2)" {
			continue
		}
		if !marks(t, "x", given, "x").Correct {
			t.Errorf("%q was marked wrong against `x`", given)
		}
	}
}

// A RANGE IS PART OF THE QUESTION. `ln(x)` says nothing below zero, and a
// question about it sampled from -4 would be undefined nearly everywhere — so
// the author declares where to look.
func TestARangeIsWhatMakesAQuestionAboutLogsAskable(t *testing.T) {
	from, to := 0.5, 20.0
	payload, err := json.Marshal(map[string]any{
		"id": "e", "version": 1, "type": "expression-answer",
		"prompt": "Simplify.", "accept": "ln(x) + ln(x)",
		"variables": []map[string]any{{"name": "x", "from": from, "to": to}},
	})
	if err != nil {
		t.Fatal(err)
	}

	result, err := grade.Grade("expression-answer", payload, answered("2*ln(x)"))
	if err != nil {
		t.Fatalf("grading: %v", err)
	}
	if !result.Correct {
		t.Error("`2*ln(x)` was marked wrong against `ln(x) + ln(x)`")
	}

	// And on that range |x| is x, which the default range would have refused.
	result, err = grade.Grade("expression-answer", payload, answered("ln(x^2)"))
	if err != nil {
		t.Fatalf("grading: %v", err)
	}
	if !result.Correct {
		t.Error("`ln(x^2)` was marked wrong against `ln(x) + ln(x)` on a positive range")
	}
}

// THE VERDICT MUST NOT MOVE. A grader that sampled randomly would mark the same
// answer differently on different days, and a student told they were right on
// Tuesday and wrong on Thursday cannot find out which was the mistake.
func TestTheSameAnswerIsMarkedTheSameWayEveryTime(t *testing.T) {
	for _, given := range []string{"2x + 1", "x^2", "1 + 2*x"} {
		first := marks(t, "2*x + 1", given, "x")
		for range 20 {
			if again := marks(t, "2*x + 1", given, "x"); again.Correct != first.Correct {
				t.Fatalf("%q was marked %v and then %v — the sampling is not fixed",
					given, first.Correct, again.Correct)
			}
		}
	}
}

// A question with two letters must not be sampled along `x == y`, or `x + y`
// and `2x` would look the same.
func TestTwoVariablesAreNotSampledAlongTheDiagonal(t *testing.T) {
	if marks(t, "x + y", "2*x", "x", "y").Correct {
		t.Error("`2x` was accepted as `x + y` — the two variables are being given the same " +
			"value at every sample, so every question about two letters is a question about one")
	}
	if !marks(t, "x + y", "y + x", "x", "y").Correct {
		t.Error("`y + x` was marked wrong against `x + y`")
	}
}

// AN ANSWER UNDEFINED WHERE THE KEY IS DEFINED IS WRONG, not skipped. Skipping
// would mark on the places they happen to agree and ignore the places they do
// not — which is how `sqrt(x)` would pass as `x`.
func TestAnAnswerUndefinedWhereTheKeyIsDefinedIsWrong(t *testing.T) {
	// The default range spans zero, so `sqrt(x)` has no value across half of it
	// while `x` has one everywhere.
	if marks(t, "x", "sqrt(x)", "x").Correct {
		t.Error("`sqrt(x)` was accepted as `x` — it has no value below zero, where `x` does")
	}
}

// AND WHAT SAMPLING CANNOT SEE, pinned so that the limit is a decision rather
// than a surprise. `x` and `x + 0*(1/x)` differ at exactly one point, and no
// finite set of samples lands on it.
//
// This test asserts the CURRENT behaviour, which is to accept. It is here so
// that anybody who makes this stricter finds a test saying what they changed,
// and anybody who trips over it in the wild finds the reason written down —
// see the package comment for why the trade is the right one.
func TestADifferenceAtASinglePointIsNotSeen(t *testing.T) {
	if !marks(t, "x", "x + 0*(1/x)", "x").Correct {
		t.Error("this now catches a removable singularity. That is an improvement, not a " +
			"failure — update this test and the note in expression.go about what sampling cannot see")
	}
}

// THE KEY GOES BACK THROUGH THE GRADER (C-12). A question whose accepted
// expression does not parse, or whose variables are wrong, is a question no
// student can answer — and it has to fail on a pull request rather than on a
// screen.
func TestTheContentCheckCatchesABrokenQuestion(t *testing.T) {
	for _, broken := range []struct {
		name    string
		payload map[string]any
	}{
		{"an accepted expression that does not parse", map[string]any{
			"accept": "2x +", "variables": []map[string]any{{"name": "x"}}}},
		{"nothing to accept", map[string]any{
			"accept": "", "variables": []map[string]any{{"name": "x"}}}},
		{"no variables, so it is a number", map[string]any{
			"accept": "42", "variables": []map[string]any{}}},
		{"a variable named after a constant", map[string]any{
			"accept": "2*pi", "variables": []map[string]any{{"name": "pi"}}}},
		{"the same variable twice", map[string]any{
			"accept": "x", "variables": []map[string]any{{"name": "x"}, {"name": "x"}}}},
		{"a backwards range", map[string]any{
			"accept": "x", "variables": []map[string]any{{"name": "x", "from": 5.0, "to": 1.0}}}},
	} {
		body := map[string]any{"id": "e", "version": 1, "type": "expression-answer", "prompt": "?"}
		for k, v := range broken.payload {
			body[k] = v
		}
		payload, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}

		if _, err := grade.Key("expression-answer", payload); err == nil {
			t.Errorf("%s was accepted as a question", broken.name)
		}
	}
}

// And the other direction: a good question's own answer passes its own grader,
// which is what the content check actually runs.
func TestAGoodQuestionsKeyPassesItsOwnGrader(t *testing.T) {
	payload := expression("x^2 + 2*x + 1", "x")

	key, err := grade.Key("expression-answer", payload)
	if err != nil {
		t.Fatalf("producing the key: %v", err)
	}

	result, err := grade.Grade("expression-answer", payload, key)
	if err != nil {
		t.Fatalf("grading the key: %v", err)
	}
	if !result.Correct {
		t.Error("a question's own accepted expression was marked wrong")
	}
}

// NOTHING IN WHAT A STUDENT IS SHOWN SAYS WHAT THE ANSWER IS. The whole point of
// presenting: `accept` is the answer, and the ranges are an authoring detail
// that would invite answers written to pass the samples.
func TestWhatIsShownCarriesNeitherTheAnswerNorTheRanges(t *testing.T) {
	from, to := 0.5, 20.0
	payload, err := json.Marshal(map[string]any{
		"id": "e", "version": 1, "type": "expression-answer",
		"prompt": "Simplify.", "accept": "2*ln(x)", "why": "Logs add.",
		"variables": []map[string]any{{"name": "x", "from": from, "to": to}},
	})
	if err != nil {
		t.Fatal(err)
	}

	shown, err := grade.Present("expression-answer", payload, grade.NewShuffler())
	if err != nil {
		t.Fatalf("presenting: %v", err)
	}

	text := string(shown.Shown)
	for _, leak := range []string{"2*ln(x)", "accept", "0.5", "20", "Logs add"} {
		if strings.Contains(text, leak) {
			t.Errorf("what the student is shown contains %q:\n%s", leak, text)
		}
	}
	if !strings.Contains(text, `"x"`) {
		t.Errorf("the student is not told which letter is the variable:\n%s", text)
	}
}
