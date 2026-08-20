package catalog

import (
	"encoding/json"
	"fmt"
)

/*
Translated answers a question as it reads in one other language.

# FIELD BY FIELD, AND WHAT NOBODY TRANSLATED STAYS ENGLISH

This is C-11 applied to a payload instead of to a struct. A translation carries
what somebody translated and no more, so a question whose prompt was translated
and whose options were not keeps the English options rather than losing them.
`nil` is "nobody wrote this", which an empty string cannot say — which is why
every scalar in ExerciseText is a pointer.

# IT WRITES INTO THE PAYLOAD RATHER THAN BESIDE IT

The alternative is to keep the translation as its own object and merge it in
whoever serves a question. That is the same merge, done in every reader instead
of once here, and the day one of them forgets is the day a screen is half
translated. The mirror holds a COMPLETE payload per locale: the grader, the
presenter and the offline bundle all take one payload and never ask which
language they are in.

# THE ANSWER IS NOT REACHABLE FROM HERE

Only the fields ExerciseText declares are written, and it declares none of the
ones grading reads. That is worth stating as a property rather than a habit: a
merge that copied unknown keys across would let a `pt.json` set `correct` or
`accept`, and a question would then be marked differently depending on the
language it was answered in. Nobody would find that — both screens read fine.
*/
func Translated(raw json.RawMessage, text ExerciseText) (json.RawMessage, error) {
	var payload map[string]any
	if err := json.Unmarshal(raw, &payload); err != nil {
		return nil, fmt.Errorf("catalog: reading a question to translate it: %w", err)
	}

	set(payload, "prompt", text.Prompt)
	set(payload, "hint", text.Hint)
	set(payload, "trap", text.Trap)

	for i, choice := range text.Choices {
		if at, ok := object(payload, "choices", i); ok {
			set(at, "text", choice.Text)
			set(at, "why", choice.Why)
		}
	}
	for i, pair := range text.Pairs {
		if at, ok := object(payload, "pairs", i); ok {
			set(at, "left", pair.Left)
			set(at, "right", pair.Right)
		}
	}
	for i, label := range text.Labels {
		if at, ok := object(payload, "labels", i); ok {
			set(at, "text", &label)
		}
	}

	replace(payload, "items", text.Items)
	replace(payload, "right_distractors", text.RightDistractors)

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("catalog: writing a translated question: %w", err)
	}
	return body, nil
}

func set(into map[string]any, key string, value *string) {
	if value != nil {
		into[key] = *value
	}
}

// object answers the i-th entry of a list of objects, and whether it is there.
//
// A translation longer than what it translates is refused by `Validate` and
// cannot reach here — but it answers `false` rather than panicking, because a
// loader that crashed on a bad file would take down the load of every OTHER
// school in the same run.
func object(payload map[string]any, key string, i int) (map[string]any, bool) {
	list, ok := payload[key].([]any)
	if !ok || i >= len(list) {
		return nil, false
	}
	at, ok := list[i].(map[string]any)
	return at, ok
}

// replace swaps a list of plain strings whole, which is what a list of plain
// strings is: `items` IS the answer key of an ordering, in the sense that its
// order is, and the order is not the translator's to change — so the entries
// are written back in the order they arrived.
func replace(payload map[string]any, key string, values []string) {
	if len(values) == 0 {
		return
	}
	list, ok := payload[key].([]any)
	if !ok || len(list) != len(values) {
		return
	}
	for i, v := range values {
		list[i] = v
	}
}
