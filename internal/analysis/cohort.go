package analysis

import (
	"context"
	"fmt"
	"sort"
	"time"

	"github.com/google/uuid"
)

/* Cohorts: people grouped by the month they started, followed forward.

   # WHY THIS IS NOT THE FUNNEL WITH A DATE ON IT

   A funnel is a photograph: of everybody who ever arrived, how many reached each
   step. It mixes somebody who arrived yesterday with somebody who arrived a year
   ago, and that mixing is the thing this exists to undo.

   Improve the first lesson in August and the all-time funnel barely moves,
   because it is dominated by everybody who came before. A cohort table shows
   August's group behaving differently from July's AT THE SAME AGE, which is the
   only way a change to the product is visible in a number.

   And some questions a total cannot answer at all. "Are students still studying
   after three months" is not a fact about everybody — somebody who signed up last
   week has not had three months, and averaging them in produces a number about
   nobody.

   # WHAT COUNTS AS ACTIVE IS A DECISION AND IT IS WRITTEN DOWN

   A cohort table means whatever "active" means, so the choice is the whole thing:
   too loose and every cell is full and says nothing, too strict and the table is
   empty. `section.completed` is the smallest signal that somebody actually
   STUDIED — opening a page is a click, finishing a course is rare enough to be a
   different report. It is a constant here rather than a parameter for the reason
   K-13 gives: there is a right answer, so it lives in code where a test holds it.

   # ONLY BY SIGNUP, AND THE OTHER HALF SAYS WHY NOT

   The roadmap asks for two: by signup and by subscription start. Nothing writes a
   subscription into the stream — there is no payment gateway yet — so grouping by
   it would mean grouping by a moment nothing records. It comes back saying so,
   the way the funnel's last step does, rather than as an empty table that reads
   as "nobody ever subscribed".

   # A PERSON, NOT AN IDENTITY

   Same fold as the funnel, and for the same reason: a cohort of accounts measured
   against activity recorded under a visitor would lose the activity. `personOf`
   is shared with it deliberately — two different answers to "who is this" is how
   a conversion rate becomes a ratio between two populations.
*/

const (
	// SignupEvent is what puts somebody in a cohort: the month their account was
	// created.
	SignupEvent = "account.created"

	// ActiveEvent is what counts as having studied in a month.
	//
	// FINISHING A SECTION AND NOT OPENING A PAGE. An `opened` event is a click,
	// and a retention curve built on clicks flatters itself — it would count
	// somebody who loaded a lesson, read nothing and left. Finishing a course is
	// the opposite mistake: rare enough that most cells would be empty and the
	// shape would be noise.
	ActiveEvent = "section.completed"
)

// Cohort is one month's intake, and what became of it.
type Cohort struct {
	// Month is the month they signed up, first instant, UTC.
	Month time.Time

	// People is how many signed up that month. The denominator of every cell.
	People int

	// Active is how many of them finished a section in each month since, where
	// index 0 is the month they signed up. It is as long as the cohort is old,
	// so the newest cohort has one entry — the table is triangular because the
	// future has not happened, and filling it with zeroes would draw a cliff.
	Active []int
}

// Cohorts answers, per signup month, how many of that month's students were
// still finishing sections in the months after.
//
// `months` bounds how far forward any cohort is followed, so the oldest one does
// not grow a column a month forever.
//
// `now` IS A PARAMETER BECAUSE THE WIDTH OF THIS TABLE IS A FACT ABOUT THE
// CALENDAR. How far a cohort has been followed is how much time has passed since
// it started — not how recently somebody else signed up, which is what the first
// version of this used and which is wrong in a way that renders perfectly: a
// school whose last new student arrived in March would show EVERY cohort one
// month wide, and every month of retention after that would be missing with
// nothing to say so.
func (s *Store) Cohorts(ctx context.Context, tenantID uuid.UUID,
	months int, now time.Time, who Counting) ([]Cohort, error) {

	if s.monthly == nil || s.links == nil {
		return nil, fmt.Errorf("analysis: this store was built without the stream to read")
	}
	if months < 1 {
		months = 1
	}

	links, err := s.links(ctx)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading which visitors belong to an account: %w", err)
	}

	signups, err := s.monthly(ctx, tenantID, []string{SignupEvent}, time.Time{}, who)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading who signed up when: %w", err)
	}
	studied, err := s.monthly(ctx, tenantID, []string{ActiveEvent}, time.Time{}, who)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading who studied when: %w", err)
	}

	/* THE MONTH SOMEBODY JOINED, AND THE EARLIEST ONE WINS.

	   An account is created once, so this is normally one row per person — but
	   the stream is append-only and a replayed or duplicated event is a thing
	   that happens. Taking the earliest is the answer that cannot move somebody
	   forward into a younger cohort, which would quietly shrink an old intake
	   and inflate a new one. */
	joined := map[string]time.Time{}
	for _, a := range signups {
		who := personOf(Reach{VisitorID: a.VisitorID, AccountID: a.AccountID}, links)
		if who == "" {
			continue
		}
		if at, seen := joined[who]; !seen || a.Month.Before(at) {
			joined[who] = a.Month
		}
	}
	if len(joined) == 0 {
		return []Cohort{}, nil
	}

	// How many people each intake has, and which months each of them studied in.
	size := map[time.Time]int{}
	for _, at := range joined {
		size[at]++
	}

	active := map[time.Time]map[int]map[string]bool{}
	for _, a := range studied {
		person := personOf(Reach{VisitorID: a.VisitorID, AccountID: a.AccountID}, links)
		start, member := joined[person]
		if !member {
			// Studied here without ever having signed up here — which is a
			// person whose account was created before this school started
			// emitting the event, or in another school. They belong to no
			// cohort, and putting them in one would make a denominator that
			// nobody is under.
			continue
		}
		age := monthsBetween(start, a.Month)
		if age < 0 || age >= months {
			continue
		}
		if active[start] == nil {
			active[start] = map[int]map[string]bool{}
		}
		if active[start][age] == nil {
			active[start][age] = map[string]bool{}
		}
		active[start][age][person] = true
	}

	/* THE TABLE IS TRIANGULAR BECAUSE THE FUTURE HAS NOT HAPPENED.

	   A cohort is followed as far as it is OLD — to this month, bounded by the
	   window. Padding every row to the same width would put zeroes where there is
	   no data yet, and a zero in a retention table reads as "everybody left",
	   which is the same mistake the funnel's unmeasured steps exist to avoid.

	   The width is measured against the calendar and not against the newest
	   intake. That was the first version of this and it is wrong in the way that
	   is hardest to see: a school whose last signup was in March would show every
	   cohort one month wide, and every month of retention after March would
	   simply not be in the table. */
	thisMonth := time.Date(now.UTC().Year(), now.UTC().Month(), 1, 0, 0, 0, 0, time.UTC)

	out := make([]Cohort, 0, len(size))
	for at, n := range size {
		age := monthsBetween(at, thisMonth) + 1
		if age > months {
			age = months
		}
		if age < 1 {
			// A cohort dated after this month, which is a clock disagreeing with
			// the stream rather than a thing that happened. One column, so the
			// intake is still visible and nothing is invented after it.
			age = 1
		}
		one := Cohort{Month: at, People: n, Active: make([]int, age)}
		for i := range one.Active {
			one.Active[i] = len(active[at][i])
		}
		out = append(out, one)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Month.Before(out[j].Month) })
	return out, nil
}

// monthsBetween counts whole months from one bucket to another.
//
// IT IS ARITHMETIC ON THE FIELDS AND NOT A DIVISION OF A DURATION. Months are not
// all the same length, so `to.Sub(from) / (30 * 24 * time.Hour)` drifts — by
// February it is already wrong, and the error is a person landing in the column
// beside the right one, which nothing about the output would reveal.
func monthsBetween(from, to time.Time) int {
	return (to.Year()-from.Year())*12 + int(to.Month()) - int(from.Month())
}

// Monthly is one identity's activity at the grain of a month, defined here and
// satisfied by the module that owns the stream.
//
// A MONTH RATHER THAN A MOMENT, because that is the grain of the answer and
// collapsing to it in SQL is the difference between one row per person per month
// and one row per lesson anybody ever opened.
type Monthly func(ctx context.Context, tenantID uuid.UUID, names []string,
	since time.Time, who Counting) ([]Active, error)

// Active is one identity that did something in one month, as the stream reports
// it. The same shape `event.Active` has, named here because a module may not
// import a module (X-02).
type Active struct {
	Month     time.Time
	VisitorID *uuid.UUID
	AccountID *uuid.UUID
}
