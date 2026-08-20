package grade

import (
	"encoding/json"
	"errors"
	"fmt"
	"math/rand/v2"
)

/* ---------- ordering ---------- */

// ordering grades a sequence.
//
// THE DECLARED ARRAY IS THE CORRECT ORDER. The client shuffles for display and
// sends back the positions it ended up in, so the right answer is always
// 0, 1, 2, … — which means the content file never has to carry a separate
// "correct order" that could disagree with the list it sits beside.
type ordering struct{}

type orderingPayload struct {
	common

	Items []string `json:"items"`

	// Trap is what the question is actually measuring: which neighbouring pair
	// students swap, and why that swap is tempting.
	//
	// IT IS FEEDBACK AND NOT A HINT, which is why it is here and not in the
	// presented form. Shown before the answer it would BE the answer — "people
	// put the network layer before transport" names the very placement being
	// asked for. So it never leaves the server until a student has got it
	// wrong, and then it leaves as `Why`, the same field a quiz's wrong choice
	// speaks through.
	Trap string `json:"trap"`
}

type orderingAnswer struct {
	// The original positions, in the order the student put them.
	Order []int `json:"order"`
}

func (ordering) grade(payload, answer json.RawMessage) (Result, error) {
	var p orderingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Result{}, err
	}
	var a orderingAnswer
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return Result{}, err
	}

	if len(a.Order) != len(p.Items) {
		return Result{}, fmt.Errorf("%w: it arranges %d items and the question has %d",
			ErrBadAnswer, len(a.Order), len(p.Items))
	}

	seen := map[int]bool{}
	for _, at := range a.Order {
		if at < 0 || at >= len(p.Items) {
			return Result{}, fmt.Errorf("%w: it names item %d of %d", ErrBadAnswer, at, len(p.Items))
		}
		if seen[at] {
			return Result{}, fmt.Errorf("%w: it uses item %d twice", ErrBadAnswer, at)
		}
		seen[at] = true
	}

	for i, at := range a.Order {
		if i != at {
			return Result{Correct: false, Why: p.Trap}, nil
		}
	}
	return Result{Correct: true}, nil
}

func (ordering) key(payload json.RawMessage) (json.RawMessage, error) {
	var p orderingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return nil, err
	}
	if len(p.Items) < 2 {
		return nil, errors.New("an ordering of fewer than two items has nothing to order")
	}

	// Two identical items make the question unanswerable in a way that looks
	// answerable: whichever the student drags, one of the two placements is
	// marked wrong and both read the same on the screen.
	seen := map[string]bool{}
	for _, item := range p.Items {
		if seen[item] {
			return nil, fmt.Errorf("two items read exactly the same: %q — whichever the student "+
				"moves, one placement is wrong and they look identical", item)
		}
		seen[item] = true
	}

	order := make([]int, len(p.Items))
	for i := range order {
		order[i] = i
	}
	return json.Marshal(orderingAnswer{Order: order})
}

/* ---------- matching ---------- */

// matching grades pairs, and the declared pairing is the correct one for the
// same reason ordering's declared array is.
type matching struct{}

type matchingPayload struct {
	common

	Pairs []struct {
		Left  string `json:"left"`
		Right string `json:"right"`
	} `json:"pairs"`

	// RightDistractors are right-hand items that match nothing.
	//
	// WITHOUT THEM A MATCHING PARTLY GRADES ITSELF. Equal columns make the last
	// pair free — whatever is left over must go where the one remaining
	// left-hand item is — and the one before it nearly so. Somebody who knows
	// three of four scores four out of four, and the question stops measuring
	// where it was meant to start.
	//
	// They also make the prompt true. The matching questions written for this
	// platform say "there are options left over in the right-hand column",
	// because that is how they were authored; imported without the leftovers,
	// that sentence would be a lie printed above the question.
	//
	// THEY ARE NOT A THIRD COLUMN. The right-hand list a student sees is the
	// pairs' own right sides followed by these, shuffled together — so a
	// position past the last pair is a distractor, and choosing one is wrong in
	// the ordinary way rather than a case anybody has to handle.
	RightDistractors []string `json:"right_distractors"`
}

// rightAt is the right-hand item at a combined position: the pairs' own rights
// first, the distractors after them. The one place that order is decided, so
// `present`, `grade` and `key` cannot come to disagree about it.
func (p matchingPayload) rightAt(at int) (string, bool) {
	switch {
	case at < 0:
		return "", false
	case at < len(p.Pairs):
		return p.Pairs[at].Right, true
	case at < p.rights():
		return p.RightDistractors[at-len(p.Pairs)], true
	default:
		return "", false
	}
}

// rights is how many items the right-hand column has.
func (p matchingPayload) rights() int { return len(p.Pairs) + len(p.RightDistractors) }

type matchingAnswer struct {
	// Matched[i] is the right-hand item the student attached to left item i.
	Matched []int `json:"matched"`
}

func (matching) grade(payload, answer json.RawMessage) (Result, error) {
	var p matchingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Result{}, err
	}
	var a matchingAnswer
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return Result{}, err
	}

	if len(a.Matched) != len(p.Pairs) {
		return Result{}, fmt.Errorf("%w: it matches %d pairs and the question has %d",
			ErrBadAnswer, len(a.Matched), len(p.Pairs))
	}

	for i, at := range a.Matched {
		chosen, ok := p.rightAt(at)
		if !ok {
			return Result{}, fmt.Errorf("%w: it names right-hand item %d of %d",
				ErrBadAnswer, at, p.rights())
		}
		// A right-hand item that reads identically to the one they should have
		// picked counts: two identical labels are the question's fault, and the
		// key check refuses those — distractors included — before anybody sees
		// them. A distractor is simply not equal, so it is wrong here without
		// being a case of its own.
		if chosen != p.Pairs[i].Right {
			return Result{Correct: false}, nil
		}
	}
	return Result{Correct: true}, nil
}

func (matching) key(payload json.RawMessage) (json.RawMessage, error) {
	var p matchingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return nil, err
	}
	if len(p.Pairs) < 2 {
		return nil, errors.New("a matching of fewer than two pairs matches nothing")
	}

	// A repeated right-hand side makes two lefts indistinguishable, and a
	// repeated left is two questions with one answer between them.
	left, right := map[string]bool{}, map[string]bool{}
	for _, pair := range p.Pairs {
		if pair.Left == "" || pair.Right == "" {
			return nil, errors.New("a pair has an empty side")
		}
		if left[pair.Left] {
			return nil, fmt.Errorf("the left-hand item %q appears twice", pair.Left)
		}
		if right[pair.Right] {
			return nil, fmt.Errorf("the right-hand item %q appears twice — two left-hand items "+
				"then have the same answer and the student cannot tell which is wanted", pair.Right)
		}
		left[pair.Left], right[pair.Right] = true, true
	}

	/* A DISTRACTOR THAT READS LIKE AN ANSWER IS NOT A DISTRACTOR, it is a second
	   correct option that scores zero. It goes through the same column check as
	   the pairs, because it stands in the same column and a student cannot tell
	   the two kinds apart — which is the whole point of it. */
	for _, d := range p.RightDistractors {
		if d == "" {
			return nil, errors.New("a right-hand distractor is empty")
		}
		if right[d] {
			return nil, fmt.Errorf("the right-hand distractor %q also answers a pair — it is a "+
				"correct option that is marked wrong wherever it is put", d)
		}
		right[d] = true
	}

	matched := make([]int, len(p.Pairs))
	for i := range matched {
		matched[i] = i
	}
	return json.Marshal(matchingAnswer{Matched: matched})
}

// The items, shuffled. There is nothing to redact — the shuffle IS the
// redaction, because in this type the declared order is the answer.
type orderingShown struct {
	common

	Items []string `json:"items"`
}

func (ordering) present(payload json.RawMessage, rnd *rand.Rand) (Presented, error) {
	var p orderingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Presented{}, err
	}

	perm := shuffle(len(p.Items), rnd)

	shown := orderingShown{common: p.common}
	for _, at := range perm {
		shown.Items = append(shown.Items, p.Items[at])
	}

	body, err := json.Marshal(shown)
	if err != nil {
		return Presented{}, fmt.Errorf("grade: presenting an ordering: %w", err)
	}
	return Presented{Shown: body, Perm: perm}, nil
}

func (ordering) restore(answer json.RawMessage, perm []int) (json.RawMessage, error) {
	var a orderingAnswer
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return nil, err
	}

	var out orderingAnswer
	for _, at := range a.Order {
		original, err := through(perm, at)
		if err != nil {
			return nil, err
		}
		out.Order = append(out.Order, original)
	}
	return json.Marshal(out)
}

// The left-hand items in the order they were written, and the right-hand ones
// shuffled. Only one side needs shuffling: pairing i with i is the answer, and
// breaking that on either side is enough.
type matchingShown struct {
	common

	Left  []string `json:"left"`
	Right []string `json:"right"`
}

func (matching) present(payload json.RawMessage, rnd *rand.Rand) (Presented, error) {
	var p matchingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Presented{}, err
	}

	/* OVER THE WHOLE COLUMN, distractors included. Shuffling only the pairs and
	   appending the leftovers would put every distractor at the bottom, which
	   is a tell — and a tell is exactly what a distractor must not be. */
	perm := shuffle(p.rights(), rnd)

	shown := matchingShown{common: p.common}
	for _, pair := range p.Pairs {
		shown.Left = append(shown.Left, pair.Left)
	}
	for _, at := range perm {
		right, ok := p.rightAt(at)
		if !ok {
			return Presented{}, fmt.Errorf("grade: presenting a matching: no right-hand item %d", at)
		}
		shown.Right = append(shown.Right, right)
	}

	body, err := json.Marshal(shown)
	if err != nil {
		return Presented{}, fmt.Errorf("grade: presenting a matching: %w", err)
	}
	return Presented{Shown: body, Perm: perm}, nil
}

func (matching) restore(answer json.RawMessage, perm []int) (json.RawMessage, error) {
	var a matchingAnswer
	if err := decode(answer, &a, ErrBadAnswer); err != nil {
		return nil, err
	}

	var out matchingAnswer
	for _, at := range a.Matched {
		original, err := through(perm, at)
		if err != nil {
			return nil, err
		}
		out.Matched = append(out.Matched, original)
	}
	return json.Marshal(out)
}

// The items in the order that is right.
//
// TEXTS AND NOT POSITIONS, and that is what makes the permutation irrelevant
// here: a position means one thing in the shown frame and another in the
// written one, and a text means the same in both. The renderer compares the
// item it is holding against the item that belongs where it sits, which is a
// comparison neither side can get the wrong way round.
func (ordering) reveal(payload json.RawMessage, _ []int) (Reveal, error) {
	var p orderingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Reveal{}, err
	}
	return Reveal{Expected: p.Items}, nil
}

// The right-hand text belonging to each pair, in the order the pairs are shown.
//
// The left-hand column is never shuffled — `present` says why — so pair `i` is
// pair `i` on both sides of the wire, and the leftovers are absent from this
// entirely: a distractor belongs to no pair, and naming it here would be naming
// it as an answer to something.
func (matching) reveal(payload json.RawMessage, _ []int) (Reveal, error) {
	var p matchingPayload
	if err := decode(payload, &p, ErrBadPayload); err != nil {
		return Reveal{}, err
	}

	rights := make([]string, 0, len(p.Pairs))
	for _, pair := range p.Pairs {
		rights = append(rights, pair.Right)
	}
	return Reveal{Expected: rights}, nil
}
