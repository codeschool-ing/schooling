package grade_test

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/grade"
)

// A matching question, spelt out so each test below reads as the thing it is
// checking rather than as JSON assembly.
func matching(pairs [][2]string, distractors ...string) json.RawMessage {
	ps := make([]map[string]string, 0, len(pairs))
	for _, p := range pairs {
		ps = append(ps, map[string]string{"left": p[0], "right": p[1]})
	}
	body, err := json.Marshal(map[string]any{
		"id": "m", "version": 1, "section": "s", "type": "matching",
		"prompt": "Match each one.", "pairs": ps, "right_distractors": distractors,
	})
	if err != nil {
		panic(err)
	}
	return body
}

var threePairs = [][2]string{
	{"client", "asks"},
	{"server", "answers"},
	{"host", "has an address"},
}

// A DISTRACTOR THAT ANSWERS A PAIR IS NOT A DISTRACTOR, it is a second correct
// option that scores zero wherever it is put — and the student has no way to
// tell the two apart, which is the whole point of it being in that column.
//
// It is the same rule the pairs already had for each other, applied to the
// column rather than to half of it, and it is checked where every other answer
// key is: before anybody sees the question.
func TestADistractorThatAlsoAnswersAPairIsRefused(t *testing.T) {
	_, err := grade.Key("matching", matching(threePairs, "answers"))
	if err == nil {
		t.Fatal("a distractor identical to a pair's right-hand side was accepted")
	}
	if !strings.Contains(err.Error(), "answers") {
		t.Errorf("the refusal does not name the offending item: %v", err)
	}
}

func TestAnEmptyDistractorIsRefused(t *testing.T) {
	if _, err := grade.Key("matching", matching(threePairs, "")); err == nil {
		t.Fatal("an empty distractor was accepted")
	}
}

// THE LEFTOVERS ARE SHUFFLED IN, NOT APPENDED.
//
// Putting the distractors after the answers would leave every one of them at
// the bottom of the column — and a distractor a student can spot by where it
// sits is not a distractor, it is decoration. This is the property that a
// version of `present` which shuffled only the pairs would fail, and it would
// fail nothing else: the grading is right either way.
func TestTheDistractorsAreShuffledInWithTheAnswers(t *testing.T) {
	payload := matching(threePairs, "a cable", "a name server")

	// The last position holding something other than a distractor is the whole
	// of the evidence. Several draws, because one shuffle may leave it there by
	// chance — with five items that is a fifth of the time.
	movedUp := false
	for seed := uint64(0); seed < 24 && !movedUp; seed++ {
		presented, err := grade.Present("matching", payload, seeded(seed))
		if err != nil {
			t.Fatalf("presenting: %v", err)
		}
		var shown struct {
			Left  []string `json:"left"`
			Right []string `json:"right"`
		}
		if err := json.Unmarshal(presented.Shown, &shown); err != nil {
			t.Fatalf("reading the presented question: %v", err)
		}

		if len(shown.Left) != 3 {
			t.Fatalf("the left-hand column has %d items, want the three pairs", len(shown.Left))
		}
		if len(shown.Right) != 5 {
			t.Fatalf("the right-hand column has %d items, want three answers and two leftovers",
				len(shown.Right))
		}

		last := shown.Right[len(shown.Right)-1]
		if last != "a cable" && last != "a name server" {
			movedUp = true
		}
	}
	if !movedUp {
		t.Error("twenty-four draws all ended with a distractor last — the leftovers are being " +
			"appended rather than shuffled in, and their position gives them away")
	}
}

// And the column a student is shown never says which of it is which: the
// distractors read exactly like the answers, because they are in the same list
// with nothing marking them.
func TestThePresentedColumnDoesNotSayWhichItemsAreLeftovers(t *testing.T) {
	presented, err := grade.Present("matching", matching(threePairs, "a cable"), rng())
	if err != nil {
		t.Fatalf("presenting: %v", err)
	}
	for _, tell := range []string{"distractor", "right_distractors"} {
		if strings.Contains(string(presented.Shown), tell) {
			t.Errorf("the presented question carries %q: %s", tell, presented.Shown)
		}
	}
}
