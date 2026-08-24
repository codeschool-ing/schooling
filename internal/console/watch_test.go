package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The presence screen's half of the contract, against a fake.

   Whether the SQL counts the right sessions is `identity`'s test against a real
   Postgres. What this file holds is what the CONSOLE decides on top of it:
   which schools appear, in what order, what travels beside the number, and —
   the one that is a rule rather than a preference — that nothing here can carry
   a name. */

type presenceFake struct {
	schools []console.School
	seen    console.Watching
	fail    bool
	asked   bool
}

func (f *presenceFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewWatchHandler(
		console.Schools{
			All: func(context.Context) ([]console.School, error) {
				if f.fail {
					return nil, fmt.Errorf("the schools are not there")
				}
				return f.schools, nil
			},
		},
		func(context.Context) (console.Watching, error) {
			f.asked = true
			if f.fail {
				return console.Watching{}, fmt.Errorf("the sessions are not there")
			}
			return f.seen, nil
		},
	).Routes(mux)
	return mux
}

func askPresence(t *testing.T, f *presenceFake) (int, map[string]any, string) {
	t.Helper()
	r := httptest.NewRequest(http.MethodGet, "/console/api/v1/watch/presence", nil)
	w := httptest.NewRecorder()
	f.handler().ServeHTTP(w, r)

	var body map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, w.Body.String())
	}
	return w.Code, body, w.Body.String()
}

func twoSchools() (console.School, console.School) {
	return console.School{ID: uuid.New(), Slug: "code", Name: "Programming"},
		console.School{ID: uuid.New(), Slug: "math", Name: "Mathematics"}
}

// AN EMPTY SCHOOL IS A SCHOOL WITH NOBODY IN IT, not a school that is missing.
// The presence read can only name the schools somebody is in; a list that
// therefore showed only those would make an idle school look deleted, which is
// the same failure as a funnel step drawn with no bar.
func TestEverySchoolAppearsIncludingTheEmptyOnes(t *testing.T) {
	code, math := twoSchools()
	f := &presenceFake{
		schools: []console.School{code, math},
		seen: console.Watching{
			Schools:    []console.Here{{School: code.ID, People: 3}},
			Everywhere: 3,
			Window:     5 * time.Minute,
			Cadence:    time.Minute,
		},
	}

	status, body, _ := askPresence(t, f)
	if status != http.StatusOK {
		t.Fatalf("asking who is here answered %d: %v", status, body)
	}

	rows, _ := body["schools"].([]any)
	if len(rows) != 2 {
		t.Fatalf("two schools exist and %d came back: %v", len(rows), body["schools"])
	}

	found := map[string]float64{}
	for _, row := range rows {
		one, _ := row.(map[string]any)
		slug, _ := one["slug"].(string)
		people, _ := one["people"].(float64)
		found[slug] = people
	}
	if found["code"] != 3 {
		t.Errorf("three people are in `code` and the answer says %v", found["code"])
	}
	if _, there := found["math"]; !there {
		t.Errorf("the empty school fell out of the answer: %v", found)
	}
	if found["math"] != 0 {
		t.Errorf("nobody is in `math` and the answer says %v", found["math"])
	}
}

// BUSIEST FIRST. This screen is opened to answer "is anything happening", and a
// busy school sorted alphabetically under M is a busy school somebody scrolls
// past.
func TestTheBusiestSchoolIsFirst(t *testing.T) {
	code, math := twoSchools()
	f := &presenceFake{
		schools: []console.School{code, math}, // `code` first, and it is the quiet one
		seen: console.Watching{
			Schools:    []console.Here{{School: math.ID, People: 9}, {School: code.ID, People: 1}},
			Everywhere: 10,
			Window:     5 * time.Minute,
			Cadence:    time.Minute,
		},
	}

	_, body, _ := askPresence(t, f)
	rows, _ := body["schools"].([]any)
	first, _ := rows[0].(map[string]any)
	if first["slug"] != "math" {
		t.Errorf("nine people are in `math` and the answer put %v first", first["slug"])
	}
}

// THE TWO SPANS TRAVEL WITH THE NUMBER (K-16). "Three people" means nothing
// without "seen in the last five minutes", and the screen must not be the place
// that remembers which five.
func TestTheWindowAndTheCadenceComeBackWithTheCount(t *testing.T) {
	code, _ := twoSchools()
	f := &presenceFake{
		schools: []console.School{code},
		seen: console.Watching{
			Schools:    []console.Here{{School: code.ID, People: 2}},
			Everywhere: 2,
			Window:     5 * time.Minute,
			Cadence:    time.Minute,
		},
	}

	_, body, _ := askPresence(t, f)
	if body["window_seconds"] != float64(300) {
		t.Errorf("the window came back as %v", body["window_seconds"])
	}
	if body["cadence_seconds"] != float64(60) {
		t.Errorf("the cadence came back as %v", body["cadence_seconds"])
	}
	if body["everywhere"] != float64(2) {
		t.Errorf("two people are here and the answer says %v", body["everywhere"])
	}
}

/*
THE PLATFORM FIGURE IS NOT THE SUM OF THE SCHOOLS, and it must survive somebody
"fixing" it into one. A person studying in two schools is present in both and is
one person on the platform, so these two numbers legitimately disagree — and the
console passes the total through rather than adding the columns up.
*/
func TestThePlatformTotalIsNotTheSumOfTheSchools(t *testing.T) {
	code, math := twoSchools()
	f := &presenceFake{
		schools: []console.School{code, math},
		seen: console.Watching{
			Schools:    []console.Here{{School: code.ID, People: 2}, {School: math.ID, People: 2}},
			Everywhere: 3, // one of them has both open
			Window:     5 * time.Minute,
			Cadence:    time.Minute,
		},
	}

	_, body, _ := askPresence(t, f)
	if body["everywhere"] != float64(3) {
		t.Errorf("three people are here across two schools of two and the answer says %v",
			body["everywhere"])
	}
}

/*
K-22, HELD BY A TEST THAT READS THE RESPONSE FOR THE WORDS.

A person is found by an exact address and never listed, and "who is online" is
the most natural place in a console for that rule to be broken by somebody being
helpful. The check is on the bytes rather than on the type, because the way this
would come back is a field somebody added — not a shape somebody changed.
*/
func TestPresenceNamesNobody(t *testing.T) {
	code, _ := twoSchools()
	f := &presenceFake{
		schools: []console.School{code},
		seen: console.Watching{
			Schools:    []console.Here{{School: code.ID, People: 2}},
			Everywhere: 2,
			Window:     5 * time.Minute,
			Cadence:    time.Minute,
		},
	}

	_, _, raw := askPresence(t, f)

	// `name` IS NOT ON THIS LIST AND CANNOT BE: a school has one, and it is the
	// heading over the number. What a person has and a school does not is an
	// address, which is also the only thing that would let this become a lookup.
	for _, word := range []string{"email", "@"} {
		if strings.Contains(raw, word) {
			t.Errorf("the answer contains %q, and presence is a count and never a list "+
				"of people (K-22): %s", word, raw)
		}
	}
}

// A READ THAT FAILED IS NOT AN EMPTY PLATFORM. Zero people everywhere is a
// legitimate answer and looks exactly like a database that did not respond, so
// the failure has to be the failure.
func TestAPresenceReadThatFailedIsNotNobodyBeingHere(t *testing.T) {
	code, _ := twoSchools()
	f := &presenceFake{schools: []console.School{code}, fail: true}

	status, body, _ := askPresence(t, f)
	if status != http.StatusServiceUnavailable {
		t.Fatalf("a read that failed answered %d: %v", status, body)
	}
}
