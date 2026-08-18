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
			return Result{Correct: false}, nil
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
}

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

	for _, at := range a.Matched {
		if at < 0 || at >= len(p.Pairs) {
			return Result{}, fmt.Errorf("%w: it names right-hand item %d of %d",
				ErrBadAnswer, at, len(p.Pairs))
		}
	}

	for i, at := range a.Matched {
		// A right-hand item that reads identically to the one they should have
		// picked counts: two identical labels are the question's fault, and the
		// key check refuses those before anybody sees them.
		if p.Pairs[at].Right != p.Pairs[i].Right {
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

	perm := shuffle(len(p.Pairs), rnd)

	shown := matchingShown{common: p.common}
	for _, pair := range p.Pairs {
		shown.Left = append(shown.Left, pair.Left)
	}
	for _, at := range perm {
		shown.Right = append(shown.Right, p.Pairs[at].Right)
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
