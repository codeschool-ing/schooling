package analysis_test

import (
	"fmt"
	"math"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/analysis"
)

// Every paper here is out of ten — this question and nine others — which is
// enough to put attempts in an order and keeps each test about the thing it is
// testing.
const questionsOnThePaper = 10

// One attempt's answer to this question, with the mark that attempt got on the
// REST of the paper.
//
// THE REST OF IT, BECAUSE THAT IS WHAT THE INDEX RANKS BY. These fixtures used
// to name the whole mark, which let a fixture say "scored ten out of ten and got
// this one wrong" — a paper nobody could have sat. It read as harmless while the
// ranking included this question in itself, and the correction to that is what
// made it worth saying: the total is now derived here, so every attempt below is
// one that could have existed.
func answer(attempt string, rest int, correct bool) analysis.Answer {
	score := rest
	if correct {
		score++
	}
	return analysis.Answer{
		ExerciseID: "q", Version: 1, Type: "quiz",
		AttemptID: attempt, Correct: correct,
		Score: score, Of: questionsOnThePaper,
		AnsweredAt: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
	}
}

// `strong` attempts who got all nine of the others right and `weak` ones who got
// none of them, with this question right for the given share of each.
func paper(strong, strongRight, weak, weakRight int) []analysis.Answer {
	var out []analysis.Answer
	for i := range strong {
		out = append(out, answer(fmt.Sprintf("s%d", i), 9, i < strongRight))
	}
	for i := range weak {
		out = append(out, answer(fmt.Sprintf("w%d", i), 0, i < weakRight))
	}
	return out
}

func summarised(t *testing.T, answers []analysis.Answer) analysis.Statistics {
	t.Helper()
	s, err := analysis.Summarise(answers, analysis.MinimumSample.Fallback)
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
	short := analysis.MinimumSample.Fallback - 1
	s := summarised(t, paper(short/2, 0, short-short/2, short-short/2))

	if s.Attempts >= analysis.MinimumSample.Fallback {
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

/*
AND WHERE THE MINIMUM SITS IS THE PARAMETER'S TO SAY, which is the half the two
tests around this one cannot see: both wire the shipped thirty.

	THE SAME ANSWERS, TWO THRESHOLDS, TWO VERDICTS. Twenty answers say nothing
	at a sample of thirty and are judged at a sample of ten — and the statistics
	carry the number they were judged against either way, which is what makes
	moving it safe. A rollup written in March explains itself with the bar that
	produced it and not with today's, exactly as an exam attempt does with its
	pass mark.

	THE FIXTURE IS AS INVERTED AS A QUESTION GETS, so the verdict at ten is not
	merely "computed" but "condemned" — which is the outcome that actually costs
	something, because it takes a question out of circulation.
*/
func TestTheMinimumIsWhereTheParameterSaysItIs(t *testing.T) {
	answers := paper(10, 0, 10, 10) // the strong students all wrong, the weak all right

	silent, err := analysis.Summarise(answers, 30)
	if err != nil {
		t.Fatalf("summarising at thirty: %v", err)
	}
	if silent.Verdict != analysis.VerdictInsufficient {
		t.Errorf("twenty answers at a sample of thirty gave %q", silent.Verdict)
	}
	if silent.MinimumSample != 30 {
		t.Errorf("the statistics say the sample was %d, not the 30 they were judged against",
			silent.MinimumSample)
	}

	judged, err := analysis.Summarise(answers, 10)
	if err != nil {
		t.Fatalf("summarising at ten: %v", err)
	}
	if judged.Verdict == analysis.VerdictInsufficient {
		t.Error("twenty answers at a sample of ten still said nothing")
	}
	if !judged.Verdict.Flagged() {
		t.Errorf("a question the strong students all got wrong came back %q", judged.Verdict)
	}
	if judged.MinimumSample != 10 {
		t.Errorf("the statistics say the sample was %d, not the 10 they were judged against",
			judged.MinimumSample)
	}
}

// THE THRESHOLD TRAVELS WITH THE NUMBER IT PRODUCED (K-16). A verdict that
// arrives without saying what it was measured against invites somebody to lower
// the bar until the dashboard finally shows something.
func TestEveryVerdictSaysWhatItWasMeasuredAgainst(t *testing.T) {
	s := summarised(t, paper(20, 18, 20, 4))

	if s.MinimumSample != analysis.MinimumSample.Fallback {
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
	// Forty attempts, every one getting six of the other nine right except one
	// who got all nine and one who got none.
	var answers []analysis.Answer
	answers = append(answers, answer("top", 9, true))
	answers = append(answers, answer("bottom", 0, false))
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

	grouped, err := analysis.Group(append(before, after...), analysis.MinimumSample.Fallback)
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
	if _, err := analysis.Summarise(append(before, after...), analysis.MinimumSample.Fallback); err == nil {
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

	grouped, err := analysis.Group(answers, analysis.MinimumSample.Fallback)
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
	if _, err := analysis.Summarise(nil, analysis.MinimumSample.Fallback); err == nil {
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

// AN INVERTED KEY ON A SHORT PAPER, WHICH IS THE ONLY KIND OF PAPER THIS
// PLATFORM SETS.
//
// This is the case the index used to miss entirely. Ranking attempts by their
// WHOLE mark ranks them partly by this question: getting it right adds a point
// to the total that decides which group the answer lands in. On a four-question
// paper that contribution is a quarter of the ranking, and here it exactly
// cancels the difference it was supposed to reveal — every attempt lands on the
// same total, the groups collapse, and the answer comes back "the paper
// separated nobody".
//
// Twenty students got two of the other three right and this one wrong. Twenty
// got one of the other three right and this one right. That is a key that is
// backwards, in the plainest form it comes in, and the uncorrected index called
// it `insufficient`.
func TestAnInvertedKeyIsFoundOnAShortPaper(t *testing.T) {
	s := summarised(t, shortPaper(20, 2, false, 20, 1, true))

	if s.Verdict != analysis.VerdictInverted {
		t.Errorf("the verdict is %q at %+.2f — the students who did better on the rest "+
			"of the paper got this one right less often, which is what a backwards key "+
			"looks like from the outside", s.Verdict, s.Discrimination)
	}
	if s.StrongGroup == 0 || s.WeakGroup == 0 {
		t.Errorf("the groups came out %d and %d, so nothing was compared with anything",
			s.StrongGroup, s.WeakGroup)
	}
}

// AND THE SAME SHORT PAPER DOES NOT CONDEMN A QUESTION THAT WORKS.
//
// The correction removes a bias that was always positive, so it can only ever
// move an index down — which makes this the half worth holding: a fix that found
// the question above by calling every question inverted would have found
// nothing at all.
func TestAGoodQuestionOnAShortPaperIsStillFine(t *testing.T) {
	s := summarised(t, shortPaper(20, 2, true, 20, 1, false))

	if s.Verdict != analysis.VerdictFine {
		t.Errorf("the verdict is %q at %+.2f, and the students who did better on the "+
			"rest of the paper are the ones who got this right", s.Verdict, s.Discrimination)
	}
}

// shortPaper is a four-question exam: this question and three others.
//
// Each half is `n` attempts who got `rest` of the other three right and this one
// right or wrong as given — which is enough to say what the two tests above
// describe and no more.
func shortPaper(n, rest int, right bool, m, otherRest int, otherRight bool) []analysis.Answer {
	const of = 4
	one := func(attempt string, rest int, correct bool) analysis.Answer {
		score := rest
		if correct {
			score++
		}
		return analysis.Answer{
			ExerciseID: "q", Version: 1, Type: "quiz",
			AttemptID: attempt, Correct: correct, Score: score, Of: of,
			AnsweredAt: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
		}
	}

	var out []analysis.Answer
	for i := range n {
		out = append(out, one(fmt.Sprintf("a%d", i), rest, right))
	}
	for i := range m {
		out = append(out, one(fmt.Sprintf("b%d", i), otherRest, otherRight))
	}
	return out
}
