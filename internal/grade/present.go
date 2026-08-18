package grade

import (
	cryptorand "crypto/rand"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"math/rand/v2"
)

// Turning a question into what a student is allowed to see.
//
// # THE ANSWER MUST NOT LEAVE THE SERVER
//
// A `quiz` payload carries `correct: true` on a choice. An `ordering` payload
// carries the correct order as the array itself. A `numeric` carries the value.
// Serving any of them to a student sitting an exam hands over the answer to
// anybody who opens the network tab — which is not an exotic attack, it is the
// second thing a curious programming student does.
//
// So a question is PRESENTED rather than sent: the answer is removed, and where
// the order IS the answer it is shuffled. What the server keeps is the
// permutation, so an answer given against the shuffled form can be mapped back
// and graded against the original.
//
// # WHY A PERMUTATION AND NOT A SECOND PAYLOAD
//
// Storing a shuffled copy WITH its answers would mean two payloads that can
// disagree, and a grader that has to be told which one it is looking at. A
// permutation is a list of small integers that means nothing on its own and
// cannot drift from the question it belongs to.
//
// # THE TEST THAT MAKES THIS REAL
//
// A student who runs the grader's own key logic over what they received must
// not get a pass. That is the property, and it is stated that way rather than
// as "asking for the key must fail" — because for `ordering` and `numeric` it
// does not fail: it succeeds and produces something WRONG. The key of a
// shuffled ordering is "leave them as they are"; the key of a redacted numeric
// is zero. Both are answers; neither is the answer.
//
// It runs over every conformance fixture, so it covers a type somebody adds
// later without reading this.

// NewShuffler is the source of randomness an exam should use.
//
// THE SEED COMES FROM crypto/rand AND THE SEQUENCE FROM math/rand. That split
// is the point: the shuffle needs to be unpredictable, not cryptographically
// strong, and what makes it unpredictable is the seed rather than the
// generator. A `math/rand` sequence with a seed anybody could guess — the time,
// an attempt number — is a permutation an attacker can reproduce, and somebody
// who has already sat the exam could then map their answers onto somebody
// else's paper.
//
// It exists so that a caller cannot get this wrong by reaching for the obvious
// thing. Tests pass their own seeded source, which is what a test wants.
func NewShuffler() *rand.Rand {
	var seed [16]byte
	if _, err := cryptorand.Read(seed[:]); err != nil {
		// The only way this fails is a broken random source, and everything
		// else in this binary — session tokens, salts — is already relying on
		// it. Carrying on with a guessable exam is the worse of the two.
		panic("grade: no randomness for an exam shuffle: " + err.Error())
	}
	//nolint:gosec // the sequence is math/rand and the SEED is crypto/rand,
	// which is the split this function exists to make; see above.
	return rand.New(rand.NewPCG(
		binary.LittleEndian.Uint64(seed[:8]),
		binary.LittleEndian.Uint64(seed[8:]),
	))
}

// Presented is a question a student may be shown.
type Presented struct {
	// Shown is what goes over the wire.
	Shown json.RawMessage

	// Perm maps a position in the shown form to the position it had in the
	// original. It is nil when there was nothing to shuffle.
	Perm []int
}

// presenter is implemented by the graders whose questions need shuffling or
// redacting — which is all of them, because all of them carry the answer.
type presenter interface {
	present(payload json.RawMessage, rnd *rand.Rand) (Presented, error)

	// restore maps an answer given against the shown form back to the original
	// frame, so it can be graded against the question as it was written.
	restore(answer json.RawMessage, perm []int) (json.RawMessage, error)
}

// Present prepares a question for a student.
//
// The source of randomness is passed in rather than taken from the package, so
// a caller that needs a reproducible draw — a test, or an attempt being rebuilt
// — gets one. Exams take a fresh one per attempt.
func Present(questionType string, payload json.RawMessage, rnd *rand.Rand) (Presented, error) {
	g, ok := graders[questionType]
	if !ok {
		return Presented{}, fmt.Errorf("%w: %q", ErrUnknownType, questionType)
	}
	p, ok := g.(presenter)
	if !ok {
		// A grader with no way to hide its answer must not be served in an
		// exam. Refusing is the only safe direction: the alternative is a
		// question whose answer is in the response body.
		return Presented{}, fmt.Errorf("grade: %q cannot be presented without its answer", questionType)
	}
	return p.present(payload, rnd)
}

// Restore maps an answer back into the frame the question was written in.
func Restore(questionType string, answer json.RawMessage, perm []int) (json.RawMessage, error) {
	g, ok := graders[questionType]
	if !ok {
		return nil, fmt.Errorf("%w: %q", ErrUnknownType, questionType)
	}
	p, ok := g.(presenter)
	if !ok {
		return nil, fmt.Errorf("grade: %q cannot be presented", questionType)
	}
	return p.restore(answer, perm)
}

// shuffle answers a permutation of 0..n-1.
//
// perm[i] is the ORIGINAL position of the item shown at i. Reading it the other
// way round is the mistake this comment exists to prevent, and it produces an
// exam that marks correct answers wrong for everybody at once.
func shuffle(n int, rnd *rand.Rand) []int {
	perm := make([]int, n)
	for i := range perm {
		perm[i] = i
	}
	if rnd != nil {
		rnd.Shuffle(n, func(i, j int) { perm[i], perm[j] = perm[j], perm[i] })
	}
	return perm
}

// through maps a position in the shown form to the original, and refuses
// anything outside it.
func through(perm []int, at int) (int, error) {
	if at < 0 || at >= len(perm) {
		return 0, fmt.Errorf("%w: it names position %d of %d", ErrBadAnswer, at, len(perm))
	}
	return perm[at], nil
}
