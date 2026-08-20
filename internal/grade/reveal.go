package grade

import (
	"encoding/json"
	"fmt"
)

/*
What a student is shown AFTER they have answered.

# WHY THIS IS NOT SIMPLY "SEND THE PAYLOAD BACK"

The payload is written in the frame the question was AUTHORED in, and the
student answered in the frame they were SHOWN — a shuffled one. Sending the
original would put the tick on choice 2 of a list whose choices are in a
different order on their screen, and they would be told they were wrong while
looking at the answer they gave. So the key is expressed here in the shown
frame, by walking the same permutation the draw wrote down.

# WHY IT IS A SEPARATE CALL AND NOT PART OF GRADING

Because it must be possible to grade WITHOUT producing it. An exam grades every
answer at submit and reveals nothing until the paper closes; a drill reveals
immediately. One function that did both would make "mark this" and "show them
the answer" the same decision, and the safe direction — never reveal — would be
the one nobody could express.

# ONLY FOUR TYPES NEED ANYTHING

A cloze, a numeric, a labelling and an expression are revealed by their own
renderer out of what it already has: there is no arrangement to explain,
because nothing was shuffled. A type with no `revealer` answers an empty Reveal
rather than an error — "nothing to add" is a real answer here, not a gap.
*/

// Reveal is the answer key, in the frame the student saw it.
type Reveal struct {
	/*
		Expected is what a correct answer looks like, per type:

		  quiz             the position of the correct choice
		  multiple-choice  the positions of the correct choices
		  ordering         the items, in the order that is right
		  matching         the right-hand text belonging to each pair

		`any` because the four shapes have nothing in common, and inventing a
		union to hold them would be four wrappers to unwrap on the other side.
	*/
	Expected any `json:"expected,omitempty"`

	// Explanations is why each choice is what it is, by shown position. The
	// words are the question's; nothing here writes feedback.
	Explanations []string `json:"explanations,omitempty"`
}

// revealer is implemented by the graders whose key means something only
// alongside the arrangement the student was given.
type revealer interface {
	reveal(payload json.RawMessage, perm []int) (Reveal, error)
}

// Expected answers the key in the frame `perm` produced.
//
// IT IS THE CALLER'S JOB TO HAVE ANSWERED FIRST. Nothing here can tell a
// request that comes after an answer from one that comes instead of it, which
// is why the exam calls it at submit and the drill calls it in the same breath
// as marking — see both, and note that neither route can be reached without an
// answer arriving.
func Expected(questionType string, payload json.RawMessage, perm []int) (Reveal, error) {
	g, ok := graders[questionType]
	if !ok {
		return Reveal{}, fmt.Errorf("%w: %q", ErrUnknownType, questionType)
	}
	r, ok := g.(revealer)
	if !ok {
		return Reveal{}, nil
	}
	return r.reveal(payload, perm)
}

// shownAt answers where the original position `want` ended up, given the
// permutation that maps shown positions to original ones.
//
// IT IS THE INVERSE OF `through`, and it is a search rather than a stored
// inverse because a permutation of a question's choices is four or five long:
// building a second table to save four comparisons would be more code holding
// the same fact twice.
//
// A perm that does not contain the position answers -1, which every caller
// turns into "there is nothing to point at" rather than a wrong position.
func shownAt(perm []int, want int) int {
	for shown, original := range perm {
		if original == want {
			return shown
		}
	}
	return -1
}
