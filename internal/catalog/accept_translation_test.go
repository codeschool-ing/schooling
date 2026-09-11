package catalog_test

import (
	"encoding/json"
	"testing"

	"github.com/codeschool-ing/schooling/internal/catalog"
	"github.com/codeschool-ing/schooling/internal/grade"
)

// The whole point, end to end: a cloze translated into Portuguese accepts the
// Portuguese answer and the English one is untouched by it.
func TestAClozeIsGradedInTheLanguageItWasAsked(t *testing.T) {
	english := json.RawMessage(`{"id":"ex-1","version":1,"type":"cloze",
		"prompt":"every host is a ___","blanks":[{"accept":["node"],"ignore_case":true}]}`)

	pt := catalog.ExerciseText{Blanks: []catalog.BlankText{{Accept: []string{"nó", "no"}}}}
	translated, err := catalog.Translated(english, pt)
	if err != nil {
		t.Fatalf("translating: %v", err)
	}

	say := func(payload json.RawMessage, filled string) bool {
		r, err := grade.Grade("cloze", payload, json.RawMessage(`{"filled":["`+filled+`"]}`))
		if err != nil {
			t.Fatalf("grading %q: %v", filled, err)
		}
		return r.Correct
	}

	if !say(translated, "nó") {
		t.Error("the Portuguese question refused the Portuguese answer — which is the defect")
	}
	if !say(english, "node") {
		t.Error("the English question stopped accepting its own answer")
	}
	if say(english, "nó") {
		t.Error("the English question accepted the Portuguese answer: the translation reached " +
			"the shared payload, which is the thing the rule protects against")
	}
	if say(translated, "node") {
		t.Error("the Portuguese question still accepts the English key, so `accept` was added " +
			"to rather than replaced")
	}
}
