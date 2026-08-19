package practice

import (
	"math"
	"time"
)

// SM-2, and the one decision that is not SM-2.
//
// # THE QUALITY IS DERIVED, NEVER ASKED
//
// The published algorithm takes a 0..5 self-rating: the student says how well
// they remembered. This does not ask, and that is deliberate (A-04). A person
// rating their own recall rates their mood — somebody tired marks everything a
// 3, somebody pleased with themselves marks everything a 5, and the schedule
// then follows how the day is going rather than what they know.
//
// What the platform actually observes is whether the answer was right and how
// long it took, so that is what the quality is made of.
//
// # THE THRESHOLDS ARE A FIRST GUESS AND ARE MEANT TO BE FITTED
//
// Ten seconds and forty-five are not measurements. They are a starting point
// chosen to be roughly right for a quiz and roughly wrong for a `labelling`
// question, which takes longer to answer for reasons that have nothing to do
// with knowing the answer.
//
// This is exactly why `practice_review` has been written since Fase 0, with the
// values from BEFORE each answer as well as after: the numbers below can be
// fitted against real history rather than argued about, and the fitting needs
// history that only exists if it was being recorded all along. Changing them is
// a change to `scheduler` in that log too, so a run of rows from a different
// one is distinguishable rather than silently mixed in.
const (
	quick      = 10 * time.Second
	considered = 45 * time.Second
)

// The name recorded against every answer, so rows produced by a later scheduler
// are not mixed into these.
const Scheduler = "sm2"

// The ease floor from the algorithm. Below it, a card that keeps being missed
// collapses to reviewing every day forever, which is not a schedule.
const easeFloor = 1.3

// The ease a new card starts at.
const easeStart = 2.5

// Quality is SM-2's 0..5, worked out from what happened rather than asked.
//
// ONLY FOUR OF THE SIX VALUES ARE REACHABLE, and that is honest rather than
// incomplete. The 0..2 band is meant to separate "no idea" from "recognised it
// once shown", which is a distinction only the student can make — so this uses
// one value for wrong and spends its resolution on the correct end, where the
// elapsed time is evidence about fluency rather than about mood.
func Quality(correct bool, elapsed time.Duration) int {
	if !correct {
		return 1
	}
	switch {
	case elapsed <= quick:
		return 5
	case elapsed <= considered:
		return 4
	default:
		return 3
	}
}

// State is where a card is: SM-2's three numbers, and the count of times it has
// been forgotten after being learnt.
type State struct {
	Interval   int     // days until it comes back
	Ease       float64 // how fast the interval grows
	Repetition int     // consecutive correct answers
	Lapses     int
}

// New is a card nobody has answered yet.
func New() State {
	return State{Ease: easeStart}
}

// After answers where a card lands once it has been answered.
//
// It is a pure function of the state and the quality: no clock, no database,
// no randomness. The due DATE is the caller's to compute, because "today" is a
// question about a time zone and this file should not have an opinion on one.
func After(s State, quality int) State {
	out := s
	if out.Ease == 0 {
		// A zero ease is a card that was never initialised rather than one with
		// no ease. Treating it as the start is right; treating it as zero would
		// multiply every interval to nothing.
		out.Ease = easeStart
	}

	/* THE EASE MOVES ON EVERY ANSWER, including a wrong one, and it is
	   computed from the OLD ease rather than from the new interval. The
	   published formula, kept as published so it can be checked against the
	   paper rather than against somebody's memory of it. */
	out.Ease += 0.1 - float64(5-quality)*(0.08+float64(5-quality)*0.02)
	if out.Ease < easeFloor {
		out.Ease = easeFloor
	}

	if quality < 3 {
		/* FORGOTTEN. The repetitions reset and it comes back tomorrow — the
		   whole point of the algorithm is that a card you have just missed is
		   not one to leave for a fortnight.

		   A lapse is only counted for a card that had been LEARNT. Missing
		   something on the first attempt is not forgetting it; counting it
		   would make "how hard is this for this person" mostly a count of
		   first encounters. */
		if out.Repetition > 0 {
			out.Lapses++
		}
		out.Repetition = 0
		out.Interval = 1
		return out
	}

	switch out.Repetition {
	case 0:
		// The first correct answer, whether the card is new or has just been
		// missed: tomorrow. Not "one more day than last time" — a card that has
		// been forgotten starts again, which is the point of resetting.
		out.Interval = 1
	case 1:
		out.Interval = 6
	default:
		/* A ROUNDED INTERVAL CAN FAIL TO ADVANCE. Six days at the ease floor is
		   6 × 1.3 = 7.8, which rounds up; but a one-day interval that reached
		   here would give 1 × 1.3 = 1.3, rounding to 1, and the card would be
		   asked every day for ever however well it was known. The guard belongs
		   to this branch and to no other. */
		out.Interval = int(math.Round(float64(out.Interval) * out.Ease))
		if out.Interval <= s.Interval {
			out.Interval = s.Interval + 1
		}
	}
	out.Repetition++
	return out
}

// Due is the day a card in this state should come back, counting from the day
// it was answered.
func Due(on time.Time, s State) time.Time {
	return on.AddDate(0, 0, s.Interval)
}
