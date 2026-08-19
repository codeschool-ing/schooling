package practice_test

import (
	"math"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/practice"
)

// The published schedule, from a new card: 1 day, then 6, then the interval
// times the ease. It is written out as a sequence rather than as three separate
// tests because the sequence IS the algorithm — each step's input is the last
// step's output, and a test of one step in isolation would pass against a
// scheduler that never advanced.
func TestAnAnsweredCardWalksTheSequence(t *testing.T) {
	s := practice.New()

	s = practice.After(s, 5)
	if s.Interval != 1 || s.Repetition != 1 {
		t.Fatalf("first correct answer: interval %d, repetition %d — want 1 and 1",
			s.Interval, s.Repetition)
	}

	s = practice.After(s, 5)
	if s.Interval != 6 || s.Repetition != 2 {
		t.Fatalf("second: interval %d, repetition %d — want 6 and 2", s.Interval, s.Repetition)
	}

	before := s.Interval
	s = practice.After(s, 5)
	if s.Interval <= before {
		t.Errorf("third: interval %d, and the one before it was %d — after two correct answers "+
			"a card has to move further out, or it is asked for ever", s.Interval, before)
	}
}

// A CARD THAT IS MISSED COMES BACK TOMORROW. The whole value of the algorithm
// is here: leaving something just forgotten for a fortnight is the failure a
// schedule exists to prevent.
func TestAMissedCardComesBackTomorrow(t *testing.T) {
	s := practice.New()
	for range 4 {
		s = practice.After(s, 5) // out to a long interval
	}
	if s.Interval < 6 {
		t.Fatalf("the setup did not reach a long interval: %d", s.Interval)
	}

	s = practice.After(s, practice.Quality(false, time.Second))
	if s.Interval != 1 {
		t.Errorf("a missed card is due in %d days, want 1", s.Interval)
	}
	if s.Repetition != 0 {
		t.Errorf("a missed card kept %d repetitions — they reset, or the next answer "+
			"jumps it straight back out to where it was", s.Repetition)
	}
}

// A LAPSE IS FORGETTING SOMETHING LEARNT, not failing to know it the first
// time. Counting the first encounter would make "how hard is this for this
// person" mostly a count of cards they have just met.
func TestMissingACardOnTheFirstAttemptIsNotALapse(t *testing.T) {
	fresh := practice.After(practice.New(), 1)
	if fresh.Lapses != 0 {
		t.Errorf("a card missed on its first showing counted %d lapses, want 0", fresh.Lapses)
	}

	learnt := practice.After(practice.After(practice.New(), 5), 5)
	missed := practice.After(learnt, 1)
	if missed.Lapses != 1 {
		t.Errorf("a learnt card that was missed counted %d lapses, want 1", missed.Lapses)
	}
}

// The ease has a floor, and a card that is missed over and over has to reach
// it rather than fall through it. Below 1.3 the interval stops growing at all
// and the card is asked every day for ever, which is not a schedule — it is a
// punishment for finding something hard.
func TestTheEaseHasAFloorAndAHardCardReachesIt(t *testing.T) {
	s := practice.New()
	for range 20 {
		s = practice.After(s, 1)
	}

	if s.Ease < 1.3 {
		t.Errorf("ease fell to %.2f — the floor is 1.3", s.Ease)
	}
	if s.Ease > 1.3+1e-9 {
		t.Errorf("ease settled at %.2f — twenty wrong answers should reach the floor", s.Ease)
	}
}

// AN INTERVAL THAT ROUNDS BACK TO ITSELF IS A CARD ASKED FOR EVER. At the ease
// floor the multiplication is 1.3, so an interval of 1 that reached the
// multiplying branch would round to 1 again and stay there. It cannot happen
// through the front door — a one-day interval is always repetition 0 or 1 —
// which is exactly why it is worth pinning: the guard is in the branch that can
// produce it and nowhere else.
func TestAnIntervalAlwaysAdvancesOnceItIsMultiplied(t *testing.T) {
	s := practice.State{Interval: 1, Ease: 1.3, Repetition: 5}

	out := practice.After(s, 3)
	if out.Interval <= s.Interval {
		t.Errorf("a multiplied interval came back as %d from %d — the card would be asked "+
			"every day however well it was known", out.Interval, s.Interval)
	}
}

// THE QUALITY IS DERIVED, NEVER ASKED (A-04). A person rating their own recall
// rates their mood, so what the platform observes is what it uses.
func TestQualityComesFromWhatHappenedRatherThanFromAnOpinion(t *testing.T) {
	if q := practice.Quality(true, time.Second); q != 5 {
		t.Errorf("right and immediate scored %d, want 5", q)
	}
	if q := practice.Quality(true, 30*time.Second); q != 4 {
		t.Errorf("right after thinking scored %d, want 4", q)
	}
	if q := practice.Quality(true, 5*time.Minute); q != 3 {
		t.Errorf("right but slow scored %d, want 3", q)
	}

	// Every wrong answer is the same quality, whatever it cost. Splitting the
	// 0..2 band means deciding whether somebody "nearly knew it", which is a
	// judgement only they can make and which this design refuses to ask for.
	for _, took := range []time.Duration{time.Second, time.Minute, time.Hour} {
		if q := practice.Quality(false, took); q != 1 {
			t.Errorf("a wrong answer after %s scored %d, want 1", took, q)
		}
	}
}

// A wrong answer must score below the threshold that counts as remembering, or
// missing a card would schedule it further away. The two functions are written
// in different places and this is the seam between them.
func TestAWrongAnswerScoresBelowTheRememberedThreshold(t *testing.T) {
	learnt := practice.After(practice.After(practice.New(), 5), 5)
	after := practice.After(learnt, practice.Quality(false, 2*time.Second))

	if after.Interval >= learnt.Interval {
		t.Errorf("missing a card moved it from %d days to %d — the quality a wrong answer "+
			"gets is being read as remembering it", learnt.Interval, after.Interval)
	}
}

// The due date is days from the day it was answered, and nothing else. It is
// separate from the arithmetic because "today" is a question about a time zone
// and the scheduler has no opinion on one.
func TestDueIsTheIntervalInDaysFromTheAnswer(t *testing.T) {
	on := time.Date(2026, 8, 19, 23, 40, 0, 0, time.UTC)
	got := practice.Due(on, practice.State{Interval: 6})

	if want := time.Date(2026, 8, 25, 23, 40, 0, 0, time.UTC); !got.Equal(want) {
		t.Errorf("due %s, want %s", got, want)
	}
}

// A card with no ease at all is one that was never initialised — a row written
// before this column existed, a struct built by a caller that forgot. Treating
// the zero as an ease would multiply every interval to nothing, and the card
// would be asked for ever with no sign of why.
func TestACardWithNoEaseIsTreatedAsANewOne(t *testing.T) {
	out := practice.After(practice.State{Interval: 6, Repetition: 3}, 5)

	if out.Ease < 1.3 {
		t.Errorf("a card with a zero ease came out at %.2f", out.Ease)
	}
	if out.Interval <= 6 {
		t.Errorf("its interval went from 6 to %d", out.Interval)
	}
}

// The published ease formula, checked against the paper rather than against
// somebody's memory of it. Written out here so that a change to the expression
// has to be a deliberate one.
func TestTheEaseFormulaIsThePublishedOne(t *testing.T) {
	for _, q := range []int{3, 4, 5} {
		want := 2.5 + (0.1 - float64(5-q)*(0.08+float64(5-q)*0.02))
		got := practice.After(practice.New(), q).Ease

		if math.Abs(got-want) > 1e-9 {
			t.Errorf("quality %d moved the ease to %.4f, want %.4f", q, got, want)
		}
	}
}
