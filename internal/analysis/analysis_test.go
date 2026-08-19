package analysis_test

import (
	"fmt"
	"math"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/analysis"
)

// Every paper here is out of ten, which is enough to put attempts in an order
// and keeps each test about the thing it is testing.
const questionsOnThePaper = 10

// One attempt's answer to this question, with the mark that attempt got on the
// paper. Spelt out so each test reads as the situation it is describing.
func answer(attempt string, score int, correct bool) analysis.Answer {
	return analysis.Answer{
		ExerciseID: "q", Version: 1, Type: "quiz",
		AttemptID: attempt, Correct: correct,
		Score: score, Of: questionsOnThePaper,
		AnsweredAt: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
	}
}

// `strong` attempts scoring 10/10 and `weak` ones scoring 1/10, with this
// question right for the given share of each.
func paper(strong, strongRight, weak, weakRight int) []analysis.Answer {
	var out []analysis.Answer
	for i := range strong {
		out = append(out, answer(fmt.Sprintf("s%d", i), 10, i < strongRight))
	}
	for i := range weak {
		out = append(out, answer(fmt.Sprintf("w%d", i), 1, i < weakRight))
	}
	return out
}

func summarised(t *testing.T, answers []analysis.Answer) analysis.Statistics {
	t.Helper()
	s, err := analysis.Summarise(answers)
	if err != nil {
		t.Fatalf("summarising: %v", err)
	}
	return s
}

// THE ONE THIS EXISTS FOR. A question the strong students fail and the weak ones
// pass is not hard — it is wrong, or its key is inverted. It is the only failure
// this system can find without a person reading the question.
func TestAQuestionTheStrongStudentsFailIsCalledInverted(t *testing.T) {
	// Twenty who aced the paper and got this one wrong; twenty who failed the
	// paper and got this one right.
	s := summarised(t, paper(20, 0, 20, 20))

	if s.Verdict != analysis.VerdictInverted {
		t.Errorf("the verdict is %q, want inverted — the students who did well on the "+
			"paper got this one right less often than the students who did badly", s.Verdict)
	}
	if s.Discrimination > -0.9 {
		t.Errorf("the discrimination index is %.2f; it should be close to -1", s.Discrimination)
	}
	if !s.Verdict.Flagged() {
		t.Error("an inverted question is not flagged as something to act on")
	}
}

// AND THE SAME QUESTION THE RIGHT WAY ROUND IS FINE, which is what makes the
// test above a distinction rather than a grader that always complains.
func TestAQuestionTheStrongStudentsPassIsFine(t *testing.T) {
	s := summarised(t, paper(20, 18, 20, 4))

	if s.Verdict != analysis.VerdictFine {
		t.Errorf("the verdict is %q, want fine (discrimination %.2f, difficulty %.2f)",
			s.Verdict, s.Discrimination, s.Difficulty)
	}
	if s.Verdict.Flagged() {
		t.Error("a good question is flagged as something to act on")
	}
}

// NOTHING IS SAID BELOW THE MINIMUM SAMPLE, and `insufficient` is a third answer
// rather than a quiet "fine". A question quarantined on four answers is a
// question removed from a course because two people misread it.
func TestNothingIsDecidedBelowTheMinimumSample(t *testing.T) {
	// As inverted as a question can be, and one answer short of the sample.
	short := analysis.MinimumSample - 1
	s := summarised(t, paper(short/2, 0, short-short/2, short-short/2))

	if s.Attempts >= analysis.MinimumSample {
		t.Fatalf("the fixture has %d attempts, which is not below the sample", s.Attempts)
	}
	if s.Verdict != analysis.VerdictInsufficient {
		t.Errorf("%d answers gave the verdict %q; below the sample the answer is "+
			"insufficient, which is not the same as fine", s.Attempts, s.Verdict)
	}
	if s.Verdict.Flagged() {
		t.Error("a question with too few answers was flagged")
	}

	// AND NO NUMBER IS PRODUCED EITHER. A discrimination index on a screen is
	// read as a finding whatever the label beside it says.
	if s.Discrimination != 0 {
		t.Errorf("a discrimination index of %.2f was computed from %d answers",
			s.Discrimination, s.Attempts)
	}

	// Difficulty IS computed, because "half of eleven people got it right" is a
	// description rather than a judgement.
	if s.Difficulty == 0 {
		t.Error("the share correct was not computed; it is a description, not a verdict")
	}
}

// THE THRESHOLD TRAVELS WITH THE NUMBER IT PRODUCED (K-16). A verdict that
// arrives without saying what it was measured against invites somebody to lower
// the bar until the dashboard finally shows something.
func TestEveryVerdictSaysWhatItWasMeasuredAgainst(t *testing.T) {
	s := summarised(t, paper(20, 18, 20, 4))

	if s.MinimumSample != analysis.MinimumSample {
		t.Errorf("the statistics say the minimum sample is %d", s.MinimumSample)
	}
	if s.Attempts != 40 || s.StrongGroup == 0 || s.WeakGroup == 0 {
		t.Errorf("the groups behind the index are not reported: %d attempts, "+
			"%d strong, %d weak", s.Attempts, s.StrongGroup, s.WeakGroup)
	}
}

// A QUESTION EVERYBODY GETS RIGHT MEASURES NOTHING, and that is a different
// complaint from a broken one — so it gets its own verdict rather than being
// reported as weakly discriminating, which would send somebody hunting for a
// wrong key in a question that is merely trivial.
func TestAQuestionAlmostEverybodyGetsRightIsCalledTooEasy(t *testing.T) {
	s := summarised(t, paper(20, 20, 20, 19))

	if s.Verdict != analysis.VerdictTooEasy {
		t.Errorf("the verdict is %q, want too-easy (difficulty %.2f)", s.Verdict, s.Difficulty)
	}
	if s.Verdict.Flagged() {
		t.Error("a trivial question is flagged as something to act on; it is a content " +
			"problem rather than a broken question")
	}
}

// A QUESTION ALMOST NOBODY GETS RIGHT IS NOT CONDEMNED ON THAT ALONE. It is
// either excellent or broken, and difficulty cannot tell you which — only the
// discrimination index can, so that is what decides.
func TestAHardQuestionIsNotFlaggedForBeingHard(t *testing.T) {
	// Four of the twenty strong students got it; none of the weak ones did.
	// Two people in forty: very hard, and it separates them correctly.
	s := summarised(t, paper(20, 4, 20, 0))

	if s.Verdict.Flagged() {
		t.Errorf("a hard question that separates students was flagged as %q "+
			"(difficulty %.2f, discrimination %.2f)", s.Verdict, s.Difficulty, s.Discrimination)
	}
}

// THE SAME ANSWERS GIVE THE SAME VERDICT, whatever order they arrive in. A
// boundary rule that depended on row order would produce a different answer on
// a different day, and a question quarantined by a `sort` is not a finding.
func TestTheOrderAnswersArriveInChangesNothing(t *testing.T) {
	answers := paper(20, 15, 20, 5)
	want := summarised(t, answers)

	for shift := 1; shift < len(answers); shift++ {
		rotated := append(append([]analysis.Answer{}, answers[shift:]...), answers[:shift]...)

		got := summarised(t, rotated)
		if got.Verdict != want.Verdict || math.Abs(got.Discrimination-want.Discrimination) > 1e-9 {
			t.Fatalf("rotated by %d the verdict is %q at %.4f, and unrotated it is %q at %.4f",
				shift, got.Verdict, got.Discrimination, want.Verdict, want.Discrimination)
		}
	}
}

// A TIE ACROSS THE BOUNDARY TAKES EVERYBODY ON IT. Half a run of equal marks in
// the strong group and half in the middle would be a verdict that depends on
// which row came back first.
func TestARunOfEqualMarksIsNotSplitAcrossTheBoundary(t *testing.T) {
	// Forty attempts, every one scoring 6/10 except one at 10 and one at 1.
	var answers []analysis.Answer
	answers = append(answers, answer("top", 10, true))
	answers = append(answers, answer("bottom", 1, false))
	for i := range 38 {
		answers = append(answers, answer(fmt.Sprintf("m%d", i), 6, i%2 == 0))
	}

	s := summarised(t, answers)

	// The middle run is at both boundaries, so the groups would overlap: the
	// honest answer is that the paper did not separate anybody.
	if s.Discrimination != 0 {
		t.Errorf("the index is %.4f; with one distinct mark between the ends there are "+
			"no two groups to compare", s.Discrimination)
	}
}

// EVERYBODY SCORING THE SAME IS NOT A BAD QUESTION. The paper separated nobody,
// so there is nothing for the question to have discriminated between — and
// reporting that as "weak" would blame the question for the paper.
func TestAPaperThatSeparatesNobodyProducesNoIndex(t *testing.T) {
	var answers []analysis.Answer
	for i := range 40 {
		answers = append(answers, answer(fmt.Sprintf("a%d", i), 5, i%2 == 0))
	}

	s := summarised(t, answers)
	if s.Discrimination != 0 {
		t.Errorf("the index is %.4f where every attempt scored the same", s.Discrimination)
	}
}

// TWO VERSIONS OF A QUESTION ARE TWO QUESTIONS. Folding them together would
// average a question with the question it was edited into — so the fix that
// corrected a wrong key would be hidden by the answers given before it, which is
// exactly the case this whole package exists to surface.
func TestTwoVersionsOfAQuestionAreNeverFoldedTogether(t *testing.T) {
	before := paper(20, 0, 20, 20) // inverted
	after := paper(20, 18, 20, 4)  // fixed
	for i := range after {
		after[i].Version = 2
	}

	grouped, err := analysis.Group(append(before, after...))
	if err != nil {
		t.Fatal(err)
	}
	if len(grouped) != 2 {
		t.Fatalf("two versions came back as %d row(s)", len(grouped))
	}

	if grouped[0].Version != 1 || grouped[0].Verdict != analysis.VerdictInverted {
		t.Errorf("version 1 came back as %q; it is the broken one", grouped[0].Verdict)
	}
	if grouped[1].Version != 2 || grouped[1].Verdict != analysis.VerdictFine {
		t.Errorf("version 2 came back as %q; it is the fixed one", grouped[1].Verdict)
	}

	// And summarising them as one is refused rather than averaged.
	if _, err := analysis.Summarise(append(before, after...)); err == nil {
		t.Error("two versions were summarised into one set of statistics")
	}
}

// The output of a job is stable between runs, so a diff of two nights is a diff
// of what changed rather than of what order a map happened to iterate in.
func TestTheGroupedOutputIsInAStableOrder(t *testing.T) {
	var answers []analysis.Answer
	for _, id := range []string{"zeta", "alpha", "mu"} {
		for _, v := range []int{2, 1} {
			a := answer(id+fmt.Sprint(v), 5, true)
			a.ExerciseID, a.Version = id, v
			answers = append(answers, a)
		}
	}

	grouped, err := analysis.Group(answers)
	if err != nil {
		t.Fatal(err)
	}

	want := []string{"alpha1", "alpha2", "mu1", "mu2", "zeta1", "zeta2"}
	for i, s := range grouped {
		if got := fmt.Sprintf("%s%d", s.ExerciseID, s.Version); got != want[i] {
			t.Errorf("position %d is %s, want %s", i, got, want[i])
		}
	}
}

// Nothing at all is not a question with no answers; it is a call that should not
// have been made, and it says so rather than answering zeroes.
func TestSummarisingNothingIsAnError(t *testing.T) {
	if _, err := analysis.Summarise(nil); err == nil {
		t.Error("summarising no answers produced statistics")
	}
}

// AN INDEX OF ZERO BECAUSE NOTHING WAS MEASURED IS NOT A WEAK QUESTION.
//
// This is the mistake this package exists to avoid, one level up. When the paper
// separated nobody there are no two groups to compare, so the index is zero
// because nothing was computed — and calling that "weak" blames the question for
// the paper. It was the first thing I got wrong here: the tests above asserted
// the index and not the verdict, and the verdict was "weak" for both of them.
func TestAnIndexThatCouldNotBeMeasuredIsNotReportedAsAFinding(t *testing.T) {
	// Forty attempts, all scoring the same, half getting this question right.
	var same []analysis.Answer
	for i := range 40 {
		same = append(same, answer(fmt.Sprintf("a%d", i), 5, i%2 == 0))
	}

	s := summarised(t, same)
	if s.Verdict != analysis.VerdictInsufficient {
		t.Errorf("the verdict is %q where the paper separated nobody; there were no two "+
			"groups to compare, so nothing can be said about the question", s.Verdict)
	}
	if s.Verdict.Flagged() {
		t.Error("a question was flagged on an index that was never measured")
	}

	// And difficulty still speaks, because "thirty-nine of forty got it right"
	// is true however the paper as a whole came out.
	var easy []analysis.Answer
	for i := range 40 {
		easy = append(easy, answer(fmt.Sprintf("b%d", i), 5, i > 0))
	}
	if got := summarised(t, easy).Verdict; got != analysis.VerdictTooEasy {
		t.Errorf("the verdict is %q; a question nearly everybody got right is too easy "+
			"whether or not the paper separated anybody", got)
	}
}
