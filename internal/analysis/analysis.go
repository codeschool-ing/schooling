// Package analysis is the reviewer this system does not have as a person.
//
// # WHY IT EXISTS
//
// The material is written and checked by machine, and nobody reads a course
// before a student does. What stands between a wrong answer key and a student
// is two things: the content check, which runs every key back through the
// grader before publication, and this — which reads how people actually
// answered and says which questions are not doing their job.
//
// # THE THREE NUMBERS, AND WHAT EACH ONE CANNOT SAY ALONE
//
//   - ATTEMPTS. Not a judgement, and the reason nothing is judged without it:
//     three people answering a question tells you about those three people.
//
//   - PERCENTAGE CORRECT, which is difficulty. A question everybody gets right
//     measures nothing; one everybody gets wrong is either excellent or broken,
//     and this number cannot tell you which.
//
//   - THE DISCRIMINATION INDEX, which is the one that can. It asks whether the
//     students who did well on THE REST OF the paper got THIS question right
//     more often than the students who did badly. A good question separates
//     them. One that the strong students fail and the weak ones pass is not
//     hard — it is wrong, or its key is inverted, and it is the only failure
//     this system can detect without a person.
//
//     The rest of the paper, and not the whole of it: a question included in
//     its own ranking flatters its own index, and on a paper of the length this
//     platform sets, that alone is enough to hide a key that is backwards.
//
// # NOTHING IS DECIDED BELOW THE MINIMUM SAMPLE
//
// A verdict from four answers is noise with a label on it, and the damage it
// does is specific: a question quarantined on four answers is a question
// removed from a course because two people misread it. So the answer below the
// sample is not "fine" and not "flagged" — it is `insufficient`, which is a
// third thing, and every screen and job has to handle it as one.
//
// The threshold travels with the number it produced (K-16). A verdict that
// arrives without saying what it was measured against invites somebody to lower
// the bar until the dashboard finally shows something, which breaks the
// guarantee rather than configures the system.
package analysis

import (
	"fmt"
	"sort"
	"time"
)

// Answer is one person's answer to one question, with the mark that person got
// on the paper it was on.
//
// THE SCORE IS ON THE ANSWER RATHER THAN LOOKED UP. It is carried on the event
// at emission for the reason every dimension is: a number joined afterwards is
// a number that answers with today's value rather than the one that was true,
// and here "afterwards" would also mean tolerating an event that arrived twice.
type Answer struct {
	ExerciseID string
	Version    int
	Type       string

	// AttemptID is which sitting this answer belonged to. Two answers from one
	// attempt are one student, and the groups below are built from students.
	AttemptID string

	Correct bool

	// Score and Of are the whole paper's mark, out of its questions.
	Score int
	Of    int

	AnsweredAt time.Time
}

// The thresholds. They are constants and not settings, because each has a right
// answer that a test can hold — and only something WITHOUT a right answer
// becomes a parameter (K-13). Changing one of these changes what the system
// asserts about a question, which is a decision that belongs in a diff.
const (
	// MinimumSample is how many answers a question needs before anything is
	// said about it. Thirty is the number classical item analysis uses, and it
	// is where the discrimination index stops being dominated by which
	// particular people happened to sit the paper.
	MinimumSample = 30

	// GroupShare is the fraction of attempts taken from each end to form the
	// strong and weak groups. 27% is the classical choice: it is the split that
	// maximises the difference between the groups for a normal distribution,
	// and taking halves instead would dilute both ends with the middle.
	GroupShare = 0.27

	// InvertedBelow is the discrimination index at or under which a question is
	// wrong rather than hard. Zero would mean "the strong students did no
	// better", which is already a bad question; the bar is set slightly below it
	// so that a question sitting exactly on the noise floor is reported rather
	// than condemned.
	InvertedBelow = -0.10

	// WeakBelow is where a question stops separating students usefully. Between
	// this and InvertedBelow a question is worth a look and is not evidence of
	// a broken key.
	WeakBelow = 0.15

	// TooEasyAbove and TooHardBelow are difficulty, which is a different
	// complaint: a question everybody gets right measures nothing, and one
	// almost nobody gets right may be excellent — so the second is only ever
	// reported, never condemned on its own.
	TooEasyAbove = 0.95
	TooHardBelow = 0.05
)

// Verdict is what the numbers say about a question.
//
// A CLOSED LIST, and `Insufficient` is a member of it rather than the absence
// of one. The failure this shape prevents is a screen that shows a question
// with no verdict as though it had passed.
type Verdict string

const (
	// VerdictInsufficient is not enough answers to say anything. It is the
	// starting state of every question and it is not a criticism.
	VerdictInsufficient Verdict = "insufficient"

	// VerdictFine is a question doing its job.
	VerdictFine Verdict = "fine"

	// VerdictTooEasy is one almost everybody gets right. It measures nothing,
	// which is a content problem rather than a broken question.
	VerdictTooEasy Verdict = "too-easy"

	// VerdictWeak is one that barely separates students. Worth a look.
	VerdictWeak Verdict = "weak"

	// VerdictInverted is the one that matters: the students who did well on the
	// paper got it right LESS often than the students who did badly. That is
	// not difficulty. It is a wrong key, an ambiguous prompt, or a question
	// asking something other than what it looks like — and it is the only
	// failure this system can find without a person.
	VerdictInverted Verdict = "inverted"
)

// Flagged answers whether a verdict is one somebody has to act on. Weak is not:
// it is a note. Inverted is.
func (v Verdict) Flagged() bool { return v == VerdictInverted }

// Statistics are what one question's answers came to.
//
// EVERY FIELD THAT IS A JUDGEMENT CARRIES WHAT IT WAS MEASURED AGAINST (K-16).
// `Verdict` is meaningless without `Attempts` and `MinimumSample` beside it, so
// they travel together rather than being looked up by whoever displays it.
type Statistics struct {
	ExerciseID string
	Version    int
	Type       string

	Attempts int
	Correct  int

	// Difficulty is the share who got it right, 0 to 1. Named for what item
	// analysis calls it, which is the opposite of what the word suggests: a
	// HIGH difficulty is an EASY question. The name is the field's, and the
	// comment is why nobody should trust their instinct about it.
	Difficulty float64

	// Discrimination is the strong group's share correct minus the weak
	// group's, −1 to 1. Zero below the minimum sample, where it means nothing.
	//
	// The groups are ranked by the rest of the paper rather than by the whole
	// of it — see `discrimination`. Ranking by the whole includes this question
	// in its own ranking, which biases every index upward and hides an inverted
	// key on any paper short enough to be an exam here.
	Discrimination float64

	// The two groups, so that a number can be read back to the answers it came
	// from rather than taken on trust.
	StrongGroup int
	WeakGroup   int

	Verdict       Verdict
	MinimumSample int

	FirstAnswer time.Time
	LastAnswer  time.Time
}

// Summarise folds one question's answers into its statistics.
//
// It is a pure function: no clock, no database. Every threshold above is applied
// here and nowhere else, so "why was this flagged" has one answer and a test can
// hold each edge of it.
func Summarise(answers []Answer) (Statistics, error) {
	if len(answers) == 0 {
		return Statistics{}, fmt.Errorf("analysis: nothing to summarise")
	}

	s := Statistics{
		ExerciseID:    answers[0].ExerciseID,
		Version:       answers[0].Version,
		Type:          answers[0].Type,
		Attempts:      len(answers),
		MinimumSample: MinimumSample,
		Verdict:       VerdictInsufficient,
		FirstAnswer:   answers[0].AnsweredAt,
		LastAnswer:    answers[0].AnsweredAt,
	}

	for _, a := range answers {
		if a.ExerciseID != s.ExerciseID || a.Version != s.Version {
			// One question, one version. Folding two versions together would
			// average a question with the question it was edited into, and the
			// fix that corrected a wrong key would be hidden by the answers
			// given before it.
			return Statistics{}, fmt.Errorf(
				"analysis: %s v%d and %s v%d are not the same question",
				s.ExerciseID, s.Version, a.ExerciseID, a.Version)
		}
		if a.Correct {
			s.Correct++
		}
		if a.AnsweredAt.Before(s.FirstAnswer) {
			s.FirstAnswer = a.AnsweredAt
		}
		if a.AnsweredAt.After(s.LastAnswer) {
			s.LastAnswer = a.AnsweredAt
		}
	}

	s.Difficulty = float64(s.Correct) / float64(s.Attempts)

	if s.Attempts < MinimumSample {
		// AND NOTHING ELSE IS COMPUTED. A discrimination index from eleven
		// answers is a number, and a number on a screen is read as a finding
		// whatever the label beside it says.
		return s, nil
	}

	s.Discrimination, s.StrongGroup, s.WeakGroup = discrimination(answers)
	s.Verdict = verdictOf(s)
	return s, nil
}

// verdictOf applies the thresholds, in the order that makes the strongest
// statement win. A question can be both too easy and weakly discriminating —
// almost every too-easy question is — and reporting it as weak would send
// somebody looking for a broken key in a question that is merely trivial.
//
// # AN INDEX OF ZERO IS NOT ALWAYS A MEASUREMENT
//
// When the paper separated nobody there are no two groups to compare, and
// `Discrimination` is zero because nothing was computed rather than because
// nothing was found. Reading that as "weak" blames the question for the paper —
// and it is the shape of mistake this package exists to avoid, one level up.
//
// So the group sizes decide whether the discrimination thresholds may be
// applied at all. Difficulty still may: "thirty-nine of forty got it right" is
// true however the paper as a whole came out.
func verdictOf(s Statistics) Verdict {
	measured := s.StrongGroup > 0 && s.WeakGroup > 0

	switch {
	case measured && s.Discrimination <= InvertedBelow:
		return VerdictInverted
	case s.Difficulty >= TooEasyAbove:
		return VerdictTooEasy
	case !measured:
		return VerdictInsufficient
	case s.Discrimination < WeakBelow:
		return VerdictWeak
	default:
		return VerdictFine
	}
}

// discrimination is the classical index, corrected: the strong group's share
// correct minus the weak group's, where strong and weak are decided by how the
// attempt did on the REST of the paper.
//
// # THE GROUPS ARE ATTEMPTS, NOT ANSWERS
//
// One student answering one question once contributes one answer, and their
// standing comes from the mark on the paper that answer was on. Ranking answers
// directly would put the same student in both groups on different questions.
//
// # A TIE AT THE BOUNDARY TAKES EVERYBODY ON IT
//
// If the 27th percentile falls inside a run of equal marks, taking part of that
// run and leaving the rest would make the index depend on the order rows came
// back in — the same data would produce a different verdict on a different day.
// So the boundary is a SCORE rather than a position, and everybody at it joins
// the group. The groups can then be larger than 27%, which is the right trade:
// stable and slightly blunt beats sharp and irreproducible.
//
// When there are too few distinct marks for two groups that do not overlap, the
// answer is zero — not because the question discriminated nothing, but because
// the paper did not separate anybody to discriminate between.
func discrimination(answers []Answer) (index float64, strong, weak int) {
	/* THE MARK IS THE REST OF THE PAPER, WITH THIS QUESTION TAKEN OUT OF IT, and
	   that correction is the difference between finding an inverted key and
	   calling it merely weak.

	   # WHY THE UNCORRECTED INDEX CANNOT SEE THE THING THIS PACKAGE IS FOR

	   Ranking attempts by their whole mark ranks them partly by THIS question:
	   getting it right adds a point to the very total that decides which group
	   the answer lands in. That pushes every question's index upward, by an
	   amount that depends on how long the paper is — on a six-question paper the
	   question is a sixth of its own ranking.

	   For a good question the bias is harmless, because the index is already
	   positive. For a question whose key is inverted it is fatal: the item's own
	   contribution is positive and its correlation with the rest is negative and
	   divided among the other questions, so on a short paper the two cancel and
	   the index lands near zero — `weak`, which is a note nobody acts on, or
	   `insufficient`, which reads as not enough data.

	   Simulated against a population whose answers to one question were
	   deliberately anti-correlated with ability, the uncorrected index came out
	   at +0.03 on a six-question paper, −0.05 on ten, −0.06 on sixteen, and only
	   reached `inverted` at twenty-four. Corrected, it was between −0.25 and
	   −0.35 at every one of those lengths, and the good questions stayed between
	   +0.39 and +0.55. Every exam this platform has is in the range where the
	   uncorrected number is wrong.

	   # IT CANNOT CONDEMN A GOOD QUESTION

	   The correction removes a POSITIVE bias, so a question that separates
	   students correctly stays positive. What it fixes is the false negative —
	   which is the one that matters, because nobody goes looking for it. */
	marks := map[string]float64{}
	for _, a := range answers {
		// A one-question paper cannot rank anybody by the rest of it, because
		// there is no rest of it.
		if a.Of <= 1 {
			continue
		}
		rest := float64(a.Score)
		if a.Correct {
			rest--
		}
		marks[a.AttemptID] = rest / float64(a.Of-1)
	}
	if len(marks) == 0 {
		return 0, 0, 0
	}

	ranked := make([]float64, 0, len(marks))
	for _, mark := range marks {
		ranked = append(ranked, mark)
	}
	sort.Float64s(ranked)

	size := int(float64(len(ranked)) * GroupShare)
	if size < 1 {
		size = 1
	}

	// The two boundary MARKS. Everybody at or above the top one is the strong
	// group, everybody at or below the bottom one is the weak group.
	weakEdge := ranked[size-1]
	strongEdge := ranked[len(ranked)-size]

	if strongEdge <= weakEdge {
		// The two groups would overlap, which means there are not enough
		// distinct marks to have two. Somebody would otherwise be counted in
		// both, and the index would compare a set of students with itself.
		return 0, 0, 0
	}

	var strongRight, weakRight int
	for _, a := range answers {
		mark, ok := marks[a.AttemptID]
		if !ok {
			continue
		}
		switch {
		case mark >= strongEdge:
			strong++
			if a.Correct {
				strongRight++
			}
		case mark <= weakEdge:
			weak++
			if a.Correct {
				weakRight++
			}
		}
	}

	if strong == 0 || weak == 0 {
		return 0, strong, weak
	}
	return float64(strongRight)/float64(strong) - float64(weakRight)/float64(weak), strong, weak
}

// Group folds a flat list of answers into one Statistics per question and
// version, sorted so the output of a job is stable between runs.
func Group(answers []Answer) ([]Statistics, error) {
	type key struct {
		id      string
		version int
	}

	byQuestion := map[key][]Answer{}
	for _, a := range answers {
		k := key{a.ExerciseID, a.Version}
		byQuestion[k] = append(byQuestion[k], a)
	}

	out := make([]Statistics, 0, len(byQuestion))
	for _, group := range byQuestion {
		s, err := Summarise(group)
		if err != nil {
			return nil, err
		}
		out = append(out, s)
	}

	sort.Slice(out, func(i, j int) bool {
		if out[i].ExerciseID != out[j].ExerciseID {
			return out[i].ExerciseID < out[j].ExerciseID
		}
		return out[i].Version < out[j].Version
	})
	return out, nil
}
