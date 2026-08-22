package console

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* The funnel, on a screen: of the people who arrived at a school, how many got
   to each step.

   # UNTIL NOW IT WAS PRINTED BY A CRON JOB

   `cmd/analyse` computes this every night and writes it to a log, with a comment
   admitting why — there was no console to put it on. A report that lives in a
   log is read on the days somebody remembers to read a log, which for two people
   operating a platform is approximately never. This is the screen it was waiting
   for.

   # THE POPULATION IS PART OF THE QUESTION, AND THE SCREEN SAYS WHICH ONE

   `cmd/seed` writes a history of students who do not exist, so that the machinery
   can be exercised before there is a public. Every aggregate excludes them by
   default (K-11) — and a seeded population nothing can look at is a seeder that
   proves nothing, so this screen can be told to count them, in one of three
   ways, and it is the ONLY read in the platform that offers the choice.

   What earns it the choice is that it only reports. `cmd/analyse` withdraws a
   question from circulation and is fixed on real people with no flag to change
   it; a screen can show a demonstration and say on its face that it is showing
   one, which is what the banner is for and why `everybody` and `seeded` are
   answered with a sentence rather than only a number.

   # THE THREE WORDS ARE VALIDATED HERE AND NOT ONLY DOWNSTREAM

   The SQL falls back to real people for a word it does not recognise, which is
   the right thing for SQL to do and the wrong thing for a screen to do quietly:
   `?counting=everbody` would draw a chart of real people under a banner saying
   the seeded ones were included. So a word that is not one of the three is a
   refusal with the three written out, rather than a chart that is subtly about
   somebody else.
*/

// Step is one step of the funnel as this screen shows it.
//
// `Measured` IS A FIELD AND NOT `People == 0`. Two of the eight steps have no
// event to count yet — verifying an address, and subscribing — and reported as
// zero they read as everybody dropping out there. "Nobody got here" and
// "nothing counts this" are different facts, and a screen that showed them
// alike would report a missing feature as the platform's worst drop-off.
type Step struct {
	Label    string
	People   int
	Measured bool
	Why      string
}

// Funnel is what this package may not import: `analysis` owns the arithmetic
// and `event` owns the stream. `counting` is one of the three words below,
// already checked.
type Funnel func(ctx context.Context, school uuid.UUID, since time.Time,
	counting string) ([]Step, error)

// UnderstandHandler answers the aggregates. It reads and never writes, so it
// carries no audit seam and no second rank — every staff role may look.
type UnderstandHandler struct {
	schools Schools
	funnel  Funnel
}

func NewUnderstandHandler(schools Schools, funnel Funnel) *UnderstandHandler {
	return &UnderstandHandler{schools: schools, funnel: funnel}
}

func (h *UnderstandHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/schools/{id}/funnel", h.funnelOf)
}

/*
THE THREE POPULATIONS, WITH WHAT THE SCREEN HAS TO SAY ABOUT EACH.

	The sentence travels with the number rather than being written on the screen
	beside it, because the screen and the answer can disagree — a request that
	asked for one population and was answered about another is exactly the failure
	this map exists to prevent, and it cannot happen when the words come back
	together. An empty sentence is the default and needs no banner.
*/
var populations = map[string]string{
	"real": "",
	"seeded": "These are the seeded students and nobody else. They were written by " +
		"`cmd/seed` to exercise this machinery and none of them exists.",
	"everybody": "This counts the seeded students as well as the real ones. The shape " +
		"of it is a demonstration, not a measurement of anybody's behaviour.",
}

// The order they are offered in, which the map cannot hold. Real first because
// it is the default and the true one.
var populationOrder = []string{"real", "seeded", "everybody"}

type stepBody struct {
	Label    string `json:"label"`
	People   int    `json:"people"`
	Measured bool   `json:"measured"`
	Why      string `json:"why,omitempty"`
}

func (h *UnderstandHandler) funnelOf(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
		return
	}

	counting := r.URL.Query().Get("counting")
	if counting == "" {
		counting = "real"
	}
	banner, known := populations[counting]
	if !known {
		web.Fail(w, http.StatusBadRequest, "not_a_population",
			"the population is one of real, seeded or everybody — a word this does not know "+
				"would be answered about real people under a heading saying otherwise, which is "+
				"worse than refusing")
		return
	}

	since, ok := windowFrom(r)
	if !ok {
		web.Fail(w, http.StatusBadRequest, "not_a_window",
			"`days` is a whole number of days, and 0 or nothing means since the beginning")
		return
	}

	/* THE SCHOOL IS RESOLVED BEFORE IT IS COUNTED, so an id belonging to nobody
	   is a 404 rather than a funnel of eight zeroes — which would read as a
	   school where everybody left. */
	all, err := h.schools.All(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}
	var school School
	for _, s := range all {
		if s.ID == id {
			school = s
		}
	}
	if school.ID == uuid.Nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
		return
	}

	steps, err := h.funnel(r.Context(), school.ID, since, counting)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the funnel",
			"error", err, "school", school.Slug, "counting", counting)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	/* THE CONVERSION IS SAFE BECAUSE THE COMPILER CHECKS IT. `stepBody` exists
	   to hold the JSON names, and the two types having the same fields is what
	   makes this one expression rather than four — the day they stop matching,
	   this line stops building rather than quietly dropping a field. */
	out := make([]stepBody, 0, len(steps))
	for _, s := range steps {
		out = append(out, stepBody(s))
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"school": schoolBody{
			ID: school.ID.String(), Slug: school.Slug, Name: school.Name, Accent: school.Accent,
		},
		"steps": out,

		// WHAT WAS COUNTED, ANSWERED BACK. The screen does not assume its own
		// switch was obeyed — K-18 is the same rule about scope, and this is
		// the reason the banner is here rather than in the interface's own copy
		// of the three words.
		"counting":    counting,
		"banner":      banner,
		"populations": populationOrder,

		// K-18 again: this screen is about ONE school, and a screen that did not
		// say so reads as being about the platform.
		"scope": "one school",
	})
}

// windowFrom reads `?days=N`, where nothing and zero both mean the beginning.
//
// A NEGATIVE NUMBER IS A REFUSAL AND NOT AN ABSOLUTE VALUE. `days=-30` is
// somebody meaning something; answering it with the last thirty days is a guess
// dressed as an answer, and answering it with everything is worse.
func windowFrom(r *http.Request) (time.Time, bool) {
	raw := r.URL.Query().Get("days")
	if raw == "" {
		return time.Time{}, true
	}
	days, err := strconv.Atoi(raw)
	if err != nil || days < 0 {
		return time.Time{}, false
	}
	if days == 0 {
		return time.Time{}, true
	}
	return time.Now().UTC().AddDate(0, 0, -days), true
}
