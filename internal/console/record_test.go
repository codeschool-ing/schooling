package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The student record, against fakes.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES. Whether a subscription is
   read correctly is `billing`'s test, against a real Postgres, and the same for
   progress, exams and certificates. What this file holds is the shape the
   console puts them in: that a school somebody has never touched is left out,
   that the answer says what it is scoped to, that an id belonging to nobody is
   a 404 rather than an empty page, and that a sitting never carries anything
   that would let an operator become the person they are looking at. */

var (
	somebody = uuid.MustParse("33333333-3333-4333-8333-333333333333")
	code     = console.School{ID: uuid.New(), Slug: "code", Name: "Programming"}
	math     = console.School{ID: uuid.New(), Slug: "math", Name: "Mathematics"}
)

type recordFake struct {
	person   console.Person
	found    bool
	sittings []console.Sitting
	at       map[string]console.AtSchool
	err      error
}

func (f *recordFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewRecordHandler(
		console.People{
			ByID: func(_ context.Context, id uuid.UUID) (console.Person, error) {
				if !f.found || id != f.person.ID {
					return console.Person{}, console.ErrNoPerson
				}
				return f.person, nil
			},
		},
		console.Records{
			Schools: func(context.Context) ([]console.School, error) {
				if f.err != nil {
					return nil, f.err
				}
				return []console.School{code, math}, nil
			},
			Sittings: func(context.Context, uuid.UUID) ([]console.Sitting, error) {
				return f.sittings, nil
			},
			At: func(_ context.Context, s console.School, _ uuid.UUID) (console.AtSchool, error) {
				return f.at[s.Slug], nil
			},
		},
	).Routes(mux)
	return mux
}

func aRecord() *recordFake {
	yesterday := time.Now().Add(-24 * time.Hour)
	paid := time.Now().Add(300 * 24 * time.Hour)
	return &recordFake{
		found:  true,
		person: console.Person{ID: somebody, Name: "Sam Oliveira", Email: "sam@example.tld"},
		sittings: []console.Sitting{
			{ID: uuid.New(), CreatedAt: yesterday, ExpiresAt: time.Now().Add(time.Hour),
				UserAgent: "a browser"},
			{ID: uuid.New(), CreatedAt: yesterday, ExpiresAt: yesterday, UserAgent: "an old one"},
		},
		at: map[string]console.AtSchool{
			"code": {
				Plan: "annual", State: "active", PaidThrough: &paid,
				Courses:      []console.Course{{CourseID: "co-1", Sections: 4}},
				Certificates: []console.Given{{Code: "CS-1", Title: "Web", IssuedAt: yesterday}},
			},
			// `math` is left at its zero value on purpose: somebody who has
			// never touched a school.
		},
	}
}

// A SCHOOL SOMEBODY HAS NEVER TOUCHED IS LEFT OUT.
//
// Drawing every school with four empty tables is a screen where the answer is
// buried in the part that says nothing — and with a school per subject, most of
// this platform will be that for most people.
func TestASchoolWithNothingInItIsLeftOut(t *testing.T) {
	f := aRecord()
	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")

	if rec.Code != http.StatusOK {
		t.Fatalf("the record answered %d, want 200", rec.Code)
	}

	var body struct {
		Schools []struct {
			School string `json:"school"`
		} `json:"schools"`
		Scope string `json:"scope"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("reading the record: %v", err)
	}

	if len(body.Schools) != 1 || body.Schools[0].School != "code" {
		t.Errorf("the record carries %d schools, want only the one they have anything at",
			len(body.Schools))
	}
	// AND IT SAYS WHAT IT IS SCOPED TO (K-18). One account crosses every school,
	// so a record that did not say so would be read as being about the school
	// whose name is nearest.
	if body.Scope != "every school" {
		t.Errorf("the record says its scope is %q", body.Scope)
	}
}

// A SITTING SAYS HOW MANY AND SINCE WHEN, NEVER HOW TO BECOME SOMEBODY.
//
// The session token's hash is in the same row and is not in the shape this
// package defines — so this is a test that the shape stays that way, which is
// the only moment it is cheap to hold.
func TestASittingCarriesNothingThatCouldBeUsed(t *testing.T) {
	f := aRecord()
	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")
	body := rec.Body.String()

	for _, leaked := range []string{"token", "hash", "secret"} {
		if strings.Contains(strings.ToLower(body), leaked) {
			t.Errorf("the record carries %q", leaked)
		}
	}

	var out struct {
		Sittings []struct {
			Live bool `json:"live"`
		} `json:"sittings"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatalf("reading the record: %v", err)
	}
	if len(out.Sittings) != 2 {
		t.Fatalf("the record carries %d sittings, want 2", len(out.Sittings))
	}
	// One is live and one expired yesterday. A screen that could not tell them
	// apart would report somebody as signed in on every browser they ever used.
	if !out.Sittings[0].Live || out.Sittings[1].Live {
		t.Errorf("live was computed as %v and %v, want true and false",
			out.Sittings[0].Live, out.Sittings[1].Live)
	}
}

// AN ID THAT BELONGS TO NOBODY IS A 404 AND NOT AN EMPTY RECORD.
//
// An empty record is what somebody who has done nothing looks like, and a
// screen must not show the same thing for "this person has nothing" and "there
// is no such person".
func TestARecordForNobodyIsNotFound(t *testing.T) {
	f := aRecord()
	f.found = false

	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")
	if rec.Code != http.StatusNotFound {
		t.Errorf("a record for nobody answered %d, want 404", rec.Code)
	}

	rec = get(t, f.handler(), "/console/api/v1/people/not-an-id/record")
	if rec.Code != http.StatusNotFound {
		t.Errorf("a record for a malformed id answered %d, want 404", rec.Code)
	}
}

// AND A READ THAT FAILED IS NOT A PERSON WITH NOTHING.
func TestAFailedRecordIsNotAnEmptyOne(t *testing.T) {
	f := aRecord()
	f.err = fmt.Errorf("the database is not there")

	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")
	if rec.Code == http.StatusOK {
		t.Error("a record that could not be read answered 200, which reads on the " +
			"screen as somebody who has nothing")
	}
}
