package console

import (
	"context"
	"net/http"
	"sort"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* Watch — the third of the four jobs a console does, and the one measured in
   seconds.

   `PLAN.md` says operate, understand, watch and audit must not be served from
   the same queries, because that is how every console rots: a screen that has
   to be right to the second and a screen that may be a day stale end up sharing
   a read, and then the stale one is refreshed for nothing or the live one is
   cached until it is a lie. This file is the live one, and it shares nothing
   with `understand.go` except the package.

   # THE RAIL FOLDS THEM AND THE CODE DOES NOT

   `sections.js` puts this under `Measure` beside the funnel, and says why: two
   groups of one entry each is a rail that is harder to read for being more
   correct. That is a decision about a list of links. It is not a reason to
   compute presence anywhere near the aggregates, which is why this is its own
   file, its own route and its own read.

   # WHAT IT WILL NOT SHOW

   Who they are. K-22 was amended and a listing of people now exists — bounded,
   minimal, counted and named — and this would be none of the four. The one that
   settles it is COUNTED: this screen refreshes on a timer, so there is no
   moment at which anybody asked, and an entry per poll would be an audit of a
   clock rather than of a person.

   So there is no shape here that can carry a name. The answer is counts, and an
   operator who needs a name has `Personal data`, which asks them what they are
   looking for and writes down that they asked.
*/

// Here is one school and how many people are in it right now.
type Here struct {
	School uuid.UUID
	People int
}

// Watching is what this package may not import: `identity` owns sessions, and
// presence is the one console number that is current state rather than the
// event stream.
//
// The window and the cadence come back WITH the counts rather than being known
// here, for the reason every threshold does (K-16): a screen holding its own
// copy of "five minutes" keeps saying five minutes on the day it becomes three.
type Watching struct {
	Schools    []Here
	Everywhere int
	Window     time.Duration
	Cadence    time.Duration
}

// Presence answers who is here.
type Presence func(ctx context.Context) (Watching, error)

// WatchHandler answers the live screens. Like the aggregates it reads and never
// writes, so it carries no audit seam and no second rank.
type WatchHandler struct {
	schools  Schools
	presence Presence
}

func NewWatchHandler(schools Schools, presence Presence) *WatchHandler {
	return &WatchHandler{schools: schools, presence: presence}
}

func (h *WatchHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/watch/presence", h.here)
}

// hereBody is one school on the answer. Every school appears, including the
// empty ones: "nobody is in that school right now" is a fact, and a school that
// dropped out of the list when it emptied would read as a school that stopped
// existing — which is the same failure as a funnel step with no bar.
type hereBody struct {
	ID     uuid.UUID `json:"id"`
	Name   string    `json:"name"`
	Slug   string    `json:"slug"`
	People int       `json:"people"`
}

func (h *WatchHandler) here(w http.ResponseWriter, r *http.Request) {
	/* THE SCHOOLS ARE READ FIRST, so that a platform with three schools and
	   nobody in any of them draws three zeroes rather than nothing at all. The
	   presence read knows about schools somebody is in and cannot name the
	   others; this is where the two meet. */
	all, err := h.schools.All(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	seen, err := h.presence(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is here", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	people := make(map[uuid.UUID]int, len(seen.Schools))
	for _, one := range seen.Schools {
		people[one.School] = one.People
	}

	schools := make([]hereBody, 0, len(all))
	for _, s := range all {
		schools = append(schools, hereBody{
			ID: s.ID, Name: s.Name, Slug: s.Slug, People: people[s.ID],
		})
	}
	/* ORDERED BY WHERE PEOPLE ARE, not by name. This screen is looked at to
	   answer "is anything happening", and a busy school sorted under Q is a
	   busy school somebody scrolls past. Ties keep the order `All` gave, which
	   is stable, so an idle platform does not shuffle itself every refresh. */
	sort.SliceStable(schools, func(i, j int) bool { return schools[i].People > schools[j].People })

	web.JSON(w, http.StatusOK, map[string]any{
		"as_of":      time.Now().UTC(),
		"everywhere": seen.Everywhere,
		"schools":    schools,

		// THE TWO SPANS THAT MAKE THE NUMBER MEAN SOMETHING, on the answer
		// rather than in the screen (K-16). The window is what "here" means;
		// the cadence is how good the number can possibly be.
		"window_seconds":  int(seen.Window / time.Second),
		"cadence_seconds": int(seen.Cadence / time.Second),

		// WHAT THIS COUNT LEAVES OUT, said by the thing that left it out. A
		// number of people present that quietly excludes everybody reading
		// without an account is not wrong, but it is answering a narrower
		// question than the one somebody reads off the screen.
		"not_counted": "People signed in, and only them: somebody reading a course " +
			"without an account is not counted, because a visitor's heartbeat is " +
			"hourly and answers a different question. Nor is an operator viewing a " +
			"student's screens, nor a seeded student — who never signs in at all.",
	})
}
