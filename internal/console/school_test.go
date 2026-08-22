package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* Setting a school's colour, against fakes.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES. Whether the column is
   written correctly is `tenant`'s test against a real Postgres; whether the
   colour is readable once it is written is the interface's, in a browser, with
   axe. What this file holds is the part in between: that a colour is a colour,
   that a role that may not set one cannot, that the entry says what it was and
   what it became, and that a change nobody could record is a change that did
   not happen. */

type schoolsFake struct {
	schools []console.School
	entries []recorded
	set     []string
	failSet bool
	failLog bool
	mayNot  bool
}

func (f *schoolsFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewSchoolsHandler(
		console.Schools{
			All: func(context.Context) ([]console.School, error) { return f.schools, nil },
			SetAccent: func(_ context.Context, id uuid.UUID, accent string) (string, error) {
				if f.failSet {
					return "", fmt.Errorf("the database is not there")
				}
				for i, s := range f.schools {
					if s.ID == id {
						was := s.Accent
						f.schools[i].Accent = accent
						f.set = append(f.set, accent)
						return was, nil
					}
				}
				return "", console.ErrNoSchool
			},
		},
		func(_ context.Context, _ uuid.UUID, _, action string,
			subject console.Subject, what console.Changed, _ string) error {
			if f.failLog {
				return fmt.Errorf("the audit is not writable")
			}
			f.entries = append(f.entries, recorded{action: action, subject: subject, what: what})
			return nil
		},
		func(context.Context, uuid.UUID) (string, string, error) {
			return "Grace Hopper", "grace@example.tld", nil
		},
		func(context.Context) (uuid.UUID, bool) { return uuid.New(), true },
		func(context.Context) bool { return !f.mayNot },
	).Routes(mux)
	return mux
}

func aSchool() *schoolsFake {
	return &schoolsFake{schools: []console.School{
		{ID: uuid.MustParse("44444444-4444-4444-8444-444444444444"),
			Slug: "code", Name: "Programming", Accent: "#5b8cff"},
	}}
}

func (f *schoolsFake) set1(t *testing.T, id, accent string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPut,
		"/console/api/v1/schools/"+id+"/accent",
		strings.NewReader(`{"accent":`+strconv(accent)+`}`)))
	return rec
}

func strconv(s string) string {
	out, _ := json.Marshal(s)
	return string(out)
}

// A COLOUR IS SIX HEX DIGITS, AND ANYTHING ELSE IS A SCHOOL THAT SILENTLY STAYS
// AS IT WAS.
//
// The interface's reader accepts exactly that form. A shorthand or a name
// reaches it as "not a colour", the whole correction is skipped, and what a
// person sees is a school that did not change with nothing on the screen to say
// why. Refusing here is what turns that into a sentence.
func TestAColourIsSixHexDigits(t *testing.T) {
	for _, bad := range []string{"#abc", "red", "5b8cff", "#5b8cf", "#5b8cffff", "",
		"rgb(1,2,3)", "#zzzzzz"} {
		f := aSchool()
		rec := f.set1(t, f.schools[0].ID.String(), bad)

		if rec.Code != http.StatusBadRequest {
			t.Errorf("%q was answered %d, want 400", bad, rec.Code)
		}
		if len(f.set) != 0 || len(f.entries) != 0 {
			t.Errorf("%q was written or recorded", bad)
		}
	}

	// And one that is right, upper case, because a hex colour is not
	// case-sensitive and somebody pasting from a brand guide gets both.
	f := aSchool()
	if rec := f.set1(t, f.schools[0].ID.String(), "#10A06A"); rec.Code != http.StatusOK {
		t.Errorf("an upper-case colour was answered %d, want 200", rec.Code)
	}
	if len(f.set) != 1 || f.set[0] != "#10a06a" {
		t.Errorf("what was written is %v; a colour is stored in one case so two spellings "+
			"of it are one value", f.set)
	}
}

// THE ENTRY SAYS WHAT IT WAS AND WHAT IT BECAME.
//
// This is the first of the system parameters the roadmap asks to be audited
// "with actor, old and new value", and the old one is the half that makes a
// change reviewable: an entry saying only what a colour is now answers nothing
// that the row itself does not.
func TestTheEntryCarriesBothColours(t *testing.T) {
	f := aSchool()
	school := f.schools[0]

	if rec := f.set1(t, school.ID.String(), "#10a06a"); rec.Code != http.StatusOK {
		t.Fatalf("setting a colour answered %d", rec.Code)
	}
	if len(f.entries) != 1 {
		t.Fatalf("%d entries were written, want 1", len(f.entries))
	}

	entry := f.entries[0]
	switch {
	case entry.action != "school.accent.changed":
		t.Errorf("the action is %q", entry.action)
	case entry.subject.Kind != "school":
		t.Errorf("the subject is a %q — an audit that called a school an account would be "+
			"wrong in the column somebody searches by", entry.subject.Kind)
	case entry.subject.ID != school.ID.String():
		t.Errorf("the subject is %q, want the school's id", entry.subject.ID)
	case entry.what.Before != "#5b8cff":
		t.Errorf("the entry says it was %v, and it was %s", entry.what.Before, school.Accent)
	case entry.what.After != "#10a06a":
		t.Errorf("the entry says it became %v", entry.what.After)
	}
}

// AND A SCHOOL THAT HAD NO COLOUR SAYS SO IN WORDS.
//
// An empty `before` in a history reads as a value nobody wrote down. A school
// with no accent wears the palette's own blue, which is a state and not a gap.
func TestASchoolWithNoColourSaysSoRatherThanNothing(t *testing.T) {
	f := aSchool()
	f.schools[0].Accent = ""

	if rec := f.set1(t, f.schools[0].ID.String(), "#10a06a"); rec.Code != http.StatusOK {
		t.Fatalf("setting a colour answered %d", rec.Code)
	}
	if before, _ := f.entries[0].what.Before.(string); !strings.Contains(before, "none") {
		t.Errorf("the entry says it was %q, and it was nothing at all", before)
	}
}

// A READ-ONLY ROLE MAY LOOK AND MAY NOT SET.
//
// The door asks for read-only, because a console nobody can open is a console
// nobody checks. Changing what every student of a school sees is not a thing
// that rank does, and the screen hiding the button is not the check.
func TestARoleThatMayNotSetIsRefused(t *testing.T) {
	f := aSchool()
	f.mayNot = true

	rec := f.set1(t, f.schools[0].ID.String(), "#10a06a")
	if rec.Code != http.StatusForbidden {
		t.Errorf("a read-only role setting a colour was answered %d, want 403", rec.Code)
	}
	if len(f.set) != 0 || len(f.entries) != 0 {
		t.Error("a refused change was written or recorded anyway")
	}

	// And reading is still allowed: this screen is worth looking at without
	// being able to act on it.
	list := httptest.NewRecorder()
	f.handler().ServeHTTP(list, httptest.NewRequest(http.MethodGet, "/console/api/v1/schools", nil))
	if list.Code != http.StatusOK {
		t.Errorf("listing the schools answered %d for a read-only role", list.Code)
	}
}

// AN ID THAT BELONGS TO NO SCHOOL IS A 404 AND NOT AN ENTRY.
func TestSettingTheColourOfNoSchool(t *testing.T) {
	f := aSchool()

	for _, id := range []string{uuid.New().String(), "not-an-id"} {
		rec := f.set1(t, id, "#10a06a")
		if rec.Code != http.StatusNotFound {
			t.Errorf("%s was answered %d, want 404", id, rec.Code)
		}
	}
	if len(f.entries) != 0 {
		t.Error("an entry was written about a school that does not exist")
	}
}

// THE SAME COLOUR AGAIN IS NOT A CHANGE.
//
// Pressing save twice is not a mistake and an entry per press would make the
// history a log of somebody's clicking — which is the kind of noise that gets
// an audit skimmed.
func TestSettingTheColourItAlreadyHasRecordsNothing(t *testing.T) {
	f := aSchool()

	rec := f.set1(t, f.schools[0].ID.String(), "#5B8CFF")
	if rec.Code != http.StatusOK {
		t.Fatalf("setting the same colour answered %d, want 200", rec.Code)
	}
	if len(f.entries) != 0 || len(f.set) != 0 {
		t.Errorf("setting the colour it already has wrote %d entries and %d values",
			len(f.entries), len(f.set))
	}
}

// A CHANGE THAT COULD NOT BE RECORDED DID NOT HAPPEN.
//
// The erase path's rule, and the same reason: the entry is what makes the
// change reviewable. The order is deliberate and its cost is the other way
// round — a write that then fails leaves an entry for something that did not
// happen — which is why that failure says so instead of reporting a colour.
func TestAColourThatCouldNotBeRecordedIsNotSet(t *testing.T) {
	f := aSchool()
	f.failLog = true

	rec := f.set1(t, f.schools[0].ID.String(), "#10a06a")
	if rec.Code != http.StatusServiceUnavailable {
		t.Errorf("a change with no audit answered %d, want 503", rec.Code)
	}
	if len(f.set) != 0 {
		t.Error("the colour was written with no entry to account for it")
	}

	// And the other way round, which cannot be prevented and must not be
	// reported as success.
	g := aSchool()
	g.failSet = true
	if rec := g.set1(t, g.schools[0].ID.String(), "#10a06a"); rec.Code == http.StatusOK {
		t.Error("a colour that could not be written answered 200")
	}
}

// THE LIST SAYS WHAT IT IS SCOPED TO (K-18).
//
// One account crosses every school and so does this screen. A list that did not
// say so would be read as being about the school whose name is nearest.
func TestTheListOfSchoolsSaysItIsEveryone(t *testing.T) {
	f := aSchool()

	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/console/api/v1/schools", nil))

	var body struct {
		Schools []struct {
			Slug   string `json:"slug"`
			Accent string `json:"accent"`
		} `json:"schools"`
		Scope string `json:"scope"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("reading the list: %v", err)
	}
	if body.Scope != "every school" {
		t.Errorf("the list says its scope is %q", body.Scope)
	}
	if len(body.Schools) != 1 || body.Schools[0].Accent != "#5b8cff" {
		t.Errorf("the list came back as %+v, and the colour is what the screen is for",
			body.Schools)
	}
}
