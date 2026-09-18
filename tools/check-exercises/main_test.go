package main

import (
	"strings"
	"testing"
)

// This file exists because the tool shipped without one and the gap had a
// consequence. `LongestShareCeiling` asked only whether the correct option was
// the LONGEST, three lessons of this catalogue went out with it the SHORTEST in
// 97%, 100% and 100% of their questions, and every run reported them clean.
// Nothing held the claim that the tool catches the length tell, so the claim
// was decoration.

// lesson builds a set of four-option questions where the correct option is put
// at the length rank the caller asks for. Rank 0 is the longest.
func lesson(n, rank int) []exercise {
	var out []exercise
	// Four texts of clearly different lengths, longest first.
	lengths := []int{80, 60, 40, 20}
	for i := 0; i < n; i++ {
		e := exercise{ID: "ex-test", Type: "quiz"}
		for k, l := range lengths {
			e.Choices = append(e.Choices, choice{
				Text:    strings.Repeat("x", l),
				Correct: k == rank,
			})
		}
		out = append(out, e)
	}
	return out
}

func ruled(t *testing.T, exs []exercise) bool {
	t.Helper()
	problems, _ := checkLesson("at", exs)
	for _, p := range problems {
		if strings.Contains(p, "pass with a ruler") {
			return true
		}
	}
	return false
}

// The tell the tool always caught. Kept so that fixing the other end did not
// quietly cost this one.
func TestTheCorrectOptionBeingLongestIsATell(t *testing.T) {
	if !ruled(t, lesson(40, 0)) {
		t.Fatal("a lesson whose correct option is always the longest was reported clean")
	}
}

// The tell it did not catch, which is why this file exists.
func TestTheCorrectOptionBeingShortestIsATellToo(t *testing.T) {
	if !ruled(t, lesson(40, 3)) {
		t.Fatal("a lesson whose correct option is always the shortest was reported clean")
	}
}

// And the rank a repair lands on when somebody trims the correct option until
// it stops being longest. A check that only watches one end pays for the repair
// by moving the habit rather than removing it.
func TestTheCorrectOptionBeingSecondLongestIsATellToo(t *testing.T) {
	if !ruled(t, lesson(40, 1)) {
		t.Fatal("a lesson whose correct option is always the second-longest was reported clean")
	}
}

// A lesson where length says nothing has to pass, or the tool cries wolf and
// the next person learns to skip its output.
func TestLengthSayingNothingIsNotATell(t *testing.T) {
	var exs []exercise
	for rank := 0; rank < 4; rank++ {
		exs = append(exs, lesson(10, rank)...)
	}
	if ruled(t, exs) {
		t.Fatal("a lesson with the correct option evenly spread across the ranks was flagged")
	}
}

// Four options of one length is the ideal rather than a failure: a ruler
// separates none of them. This catalogue has a question written that way on
// purpose, and counting it as a habit is what the tie rule prevents.
func TestOptionsOfEqualLengthAreNotATell(t *testing.T) {
	var exs []exercise
	for i := 0; i < 40; i++ {
		e := exercise{ID: "ex-test", Type: "quiz"}
		for k := 0; k < 4; k++ {
			e.Choices = append(e.Choices, choice{Text: strings.Repeat("x", 40), Correct: k == 0})
		}
		exs = append(exs, e)
	}
	if ruled(t, exs) {
		t.Fatal("a lesson whose options are all one length was flagged")
	}
}

// The end-to-end number has to name the strategy that actually scored, because
// a report that says "the longest option" while the paper is answerable by the
// shortest sends the reader to fix the wrong thing.
func TestTheReportNamesTheStrategyThatScored(t *testing.T) {
	_, report := checkLesson("at", lesson(40, 3))
	if !strings.Contains(report, "the shortest option") {
		t.Fatalf("report does not name the winning strategy: %s", report)
	}
}
