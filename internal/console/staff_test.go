package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The roster's half of the contract, against a fake.

   Whether the rows are the right rows is `identity`'s test against a real
   Postgres. What this file holds is what the CONSOLE decides about them: that a
   revoked row survives the trip, that a role without a second factor arrives as
   a false rather than as a missing key, and that somebody who has never opened
   the console is absent rather than dated to the year 1. */

func staffHandler(people []console.Operator, fail bool) http.Handler {
	mux := http.NewServeMux()
	console.NewStaffHandler(func(context.Context) ([]console.Operator, error) {
		if fail {
			return nil, fmt.Errorf("the database is not there")
		}
		return people, nil
	}).Routes(mux)
	return mux
}

func askStaff(t *testing.T, people []console.Operator, fail bool) (int, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	staffHandler(people, fail).ServeHTTP(rec,
		httptest.NewRequest(http.MethodGet, "/console/api/v1/staff", nil))

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, rec.Body.String())
	}
	return rec.Code, body
}

// rows pulls the list out of the answer, as a client would.
func rows(t *testing.T, body map[string]any) []map[string]any {
	t.Helper()
	list, ok := body["staff"].([]any)
	if !ok {
		t.Fatalf("no staff in %v", body)
	}
	out := make([]map[string]any, 0, len(list))
	for _, one := range list {
		row, ok := one.(map[string]any)
		if !ok {
			t.Fatalf("a row is not an object: %v", one)
		}
		out = append(out, row)
	}
	return out
}

func anOwner() console.Operator {
	return console.Operator{
		AccountID: uuid.New(), Name: "Grace Hopper", Email: "grace@example.tld",
		Role: "owner", GrantedAt: time.Now().Add(-30 * 24 * time.Hour),
		SecondFactor: true,
	}
}

/*
TestARoleWithNoSecondFactorSaysSoRatherThanSayingNothing.

	This is the whole reason a role and access are two facts on this screen. The
	check happens at the door — an account with a role and no second factor
	cannot reach a staff route — so a roster that sent `second_factor` only when
	it was true would draw an operator who opens nothing exactly like one who
	opens everything, and the missing key would be indistinguishable from a
	field the interface failed to read.
*/
func TestARoleWithNoSecondFactorSaysSoRatherThanSayingNothing(t *testing.T) {
	one := anOwner()
	one.SecondFactor = false

	code, body := askStaff(t, []console.Operator{one}, false)
	if code != http.StatusOK {
		t.Fatalf("the roster answered %d", code)
	}

	row := rows(t, body)[0]
	got, present := row["second_factor"]
	if !present {
		t.Fatal("a role with no second factor sent no `second_factor` key at all, which a " +
			"screen cannot tell from a field it failed to read — and this is the row that " +
			"matters most, because that role opens nothing")
	}
	if got != false {
		t.Fatalf("`second_factor` is %v on somebody who has not enrolled one", got)
	}
}

/*
TestSomebodyWhoNeverOpenedItIsAbsentRatherThanDatedToTheYearOne.

	`last_opened_console` is a nil time on somebody who has never presented a
	second factor, and a zero `time.Time` marshals as `0001-01-01T00:00:00Z` —
	which a screen would print as a date. The row an access review is looking for
	would then read as the oldest login on the list rather than as no login.
*/
func TestSomebodyWhoNeverOpenedItIsAbsentRatherThanDatedToTheYearOne(t *testing.T) {
	_, body := askStaff(t, []console.Operator{anOwner()}, false)

	if got, present := rows(t, body)[0]["last_opened_console"]; present {
		t.Fatalf("somebody who has never opened the console carries a date: %v", got)
	}
}

/*
TestARevokedRowSurvivesTheTrip.

	`0005` keeps a revoked row rather than deleting it, so that somebody who left
	is distinguishable from somebody who was never staff. That guarantee is worth
	nothing if the screen that reads them drops the column on the way out.
*/
func TestARevokedRowSurvivesTheTrip(t *testing.T) {
	left := anOwner()
	left.Role = "operator"
	gone := time.Now().Add(-24 * time.Hour)
	left.RevokedAt = &gone

	_, body := askStaff(t, []console.Operator{anOwner(), left}, false)

	found := rows(t, body)
	if len(found) != 2 {
		t.Fatalf("%d rows came back, wanted the current one and the revoked one", len(found))
	}
	if _, present := found[0]["revoked_at"]; present {
		t.Fatal("somebody still here carries a revoked date")
	}
	if _, present := found[1]["revoked_at"]; !present {
		t.Fatal("somebody who left came back looking current, which is the one thing the " +
			"row was kept to prevent")
	}
}

/*
TestTheFirstOwnerHasNobodyAboveThem.

	`staff.granted_by` is null for exactly one row in any deployment's life, and
	that null is the design: the first owner is granted from a terminal by
	somebody who is not in this system. A screen has to draw that as "nobody"
	rather than as a blank where a name goes.
*/
func TestTheFirstOwnerHasNobodyAboveThem(t *testing.T) {
	_, body := askStaff(t, []console.Operator{anOwner()}, false)

	row := rows(t, body)[0]
	if _, present := row["granted_by_email"]; present {
		t.Fatalf("the first owner was granted by somebody: %v", row["granted_by_email"])
	}
}

/*
TestAnUnreadableRosterIsNotAnEmptyOne.

	The dangerous shape here is a 200 with no rows, because this screen's empty
	state is "nobody can open this console" — which is a sentence somebody would
	act on. A database that blinked answers 503.
*/
func TestAnUnreadableRosterIsNotAnEmptyOne(t *testing.T) {
	code, _ := askStaff(t, nil, true)
	if code != http.StatusServiceUnavailable {
		t.Fatalf("an unreadable roster answered %d, which a screen would draw as a list "+
			"with nobody on it", code)
	}
}

/*
TestTheRosterSaysWhereAGrantLives.

	The screen has no form, deliberately, and somebody reading a list of who can
	get in is one thought away from wanting to change it. The sentence is the
	server's rather than the page's for the reason every other sentence in this
	console is: it is a statement about how the system works, and a copy in an
	interface is a copy that keeps saying yesterday's answer.
*/
func TestTheRosterSaysWhereAGrantLives(t *testing.T) {
	_, body := askStaff(t, []console.Operator{anOwner()}, false)

	said, _ := body["how_to_change_it"].(string)
	if said == "" {
		t.Fatal("the roster does not say where a role is granted, so the absence of a form " +
			"reads as something nobody has built yet")
	}
}
