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
	schools   Schools
	funnel    Funnel
	questions Questions
	cohorts   Cohorts
	countries Countries
}

func NewUnderstandHandler(schools Schools, funnel Funnel, questions Questions,
	cohorts Cohorts, countries Countries) *UnderstandHandler {
	return &UnderstandHandler{
		schools: schools, funnel: funnel, questions: questions,
		cohorts: cohorts, countries: countries,
	}
}

func (h *UnderstandHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/schools/{id}/funnel", h.funnelOf)
	mux.HandleFunc("GET /console/api/v1/schools/{id}/questions", h.questionsOf)
	mux.HandleFunc("GET /console/api/v1/schools/{id}/cohorts", h.cohortsOf)
	mux.HandleFunc("GET /console/api/v1/schools/{id}/countries", h.countriesOf)
}

// schoolFrom resolves the id in the path, or answers the request itself.
//
// THE SCHOOL IS RESOLVED BEFORE ANYTHING IS COUNTED, so an id belonging to
// nobody is a 404 rather than an empty report — a funnel of eight zeroes reads
// as a school everybody left, and an empty item analysis reads as a school whose
// questions are all fine.
func (h *UnderstandHandler) schoolFrom(w http.ResponseWriter, r *http.Request) (School, bool) {
	id, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
		return School{}, false
	}

	all, err := h.schools.All(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return School{}, false
	}
	for _, s := range all {
		if s.ID == id {
			return s, true
		}
	}
	web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
	return School{}, false
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
	school, ok := h.schoolFrom(w, r)
	if !ok {
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

	since, sane := windowFrom(r)
	if !sane {
		web.Fail(w, http.StatusBadRequest, "not_a_window",
			"`days` is a whole number of days, and 0 or nothing means since the beginning")
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

/* What the answers say about a question, on a screen.

   # THIS IS THE HALF OF PHASE 4 THAT `Done when` NAMES FIRST

   "A question with a broken answer key is found by the statistics." The finding
   works — it was proved by seeding a population with an inverted key planted in
   it — and until now the only way to see the result was to read a cron job's
   log or query the table by hand.

   # EVERY THRESHOLD TRAVELS WITH THE NUMBER IT PRODUCED

   A verdict is an opinion with a bar behind it, and the bar is in Go
   (`analysis`'s constants) where a test holds each edge of it. A screen that
   wrote `-0.10` into its own markup would be a second copy of a decision, and
   the copy is the one that goes wrong: the constant moves, the screen keeps
   saying what it used to be, and somebody reads a question as "just above the
   line" when it is under it.

   So the thresholds come back on the answer, from the same package that applied
   them. This is the roadmap's "every threshold displayed beside the number it
   produced", for these numbers.

   # AND WHEN IT WAS COMPUTED, WHICH IS THE FAILURE NOBODY SEES

   These rows are a cache of a nightly job. If it has been failing for a week,
   every number here is a week old and looks exactly like this morning's. The
   screen says when the rollup was made, and says so loudly when it was never
   made at all — a school with no statistics and a job that never ran look
   identical in the data and are different problems.

   # THERE IS NO POPULATION SWITCH HERE, AND THAT IS DELIBERATE

   The funnel next door has one. This does not, because it is not reading the
   stream: it is showing what `cmd/analyse` wrote, and that job counts real
   people only and has no flag to do otherwise (K-11) — it WITHDRAWS questions
   from circulation, and doing that on the strength of invented students would
   remove real questions from real courses. A switch here would be a control
   with nothing behind it. The screen says so rather than leaving its absence to
   be noticed.
*/

// Question is one question's statistics as this screen shows them.
type Question struct {
	ExerciseID string
	Version    int
	Type       string

	Attempts int
	Correct  int

	// Difficulty is the share who got it right, 0 to 1 — high is EASY, which is
	// what item analysis means by the word and the opposite of what it sounds
	// like. The screen writes it out in words for that reason.
	Difficulty float64

	// Discrimination is the strong group's share correct minus the weak
	// group's, ranked by the rest of the paper.
	Discrimination float64

	StrongGroup int
	WeakGroup   int

	Verdict       string
	MinimumSample int

	// Withdrawn is whether this question is out of circulation right now. It is
	// not derivable from the verdict: the sweep runs nightly, so a question
	// flagged this afternoon is flagged and still being asked, and one released
	// by hand is out of quarantine with the verdict it was condemned on.
	Withdrawn bool

	FirstAnswer time.Time
	LastAnswer  time.Time
}

// Thresholds are the bars `analysis` applied, carried so the screen never
// writes one of its own.
type Thresholds struct {
	MinimumSample int
	GroupShare    float64
	InvertedBelow float64
	WeakBelow     float64
	TooEasyAbove  float64
	TooHardBelow  float64
}

// Rollup is one school's item analysis, and when it was made.
type Rollup struct {
	Questions  []Question
	Thresholds Thresholds

	// ComputedAt is when the job last wrote this school's rows, and `Computed`
	// is whether it ever has. A zero time and "never run" must not read alike.
	ComputedAt time.Time
	Computed   bool
}

// Questions is what this package may not import: `analysis` owns the rollup and
// the quarantine.
type Questions func(ctx context.Context, school uuid.UUID) (Rollup, error)

type questionBody struct {
	ExerciseID     string  `json:"exercise_id"`
	Version        int     `json:"version"`
	Type           string  `json:"type"`
	Attempts       int     `json:"attempts"`
	Correct        int     `json:"correct"`
	Difficulty     float64 `json:"difficulty"`
	Discrimination float64 `json:"discrimination"`
	StrongGroup    int     `json:"strong_group"`
	WeakGroup      int     `json:"weak_group"`
	Verdict        string  `json:"verdict"`
	MinimumSample  int     `json:"minimum_sample"`
	Withdrawn      bool    `json:"withdrawn"`
	FirstAnswer    string  `json:"first_answer,omitempty"`
	LastAnswer     string  `json:"last_answer,omitempty"`
}

func (h *UnderstandHandler) questionsOf(w http.ResponseWriter, r *http.Request) {
	school, ok := h.schoolFrom(w, r)
	if !ok {
		return
	}

	rollup, err := h.questions(r.Context(), school.ID)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the item analysis",
			"error", err, "school", school.Slug)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]questionBody, 0, len(rollup.Questions))
	for _, q := range rollup.Questions {
		out = append(out, questionBody{
			ExerciseID: q.ExerciseID, Version: q.Version, Type: q.Type,
			Attempts: q.Attempts, Correct: q.Correct,
			Difficulty: q.Difficulty, Discrimination: q.Discrimination,
			StrongGroup: q.StrongGroup, WeakGroup: q.WeakGroup,
			Verdict: q.Verdict, MinimumSample: q.MinimumSample, Withdrawn: q.Withdrawn,
			FirstAnswer: when(q.FirstAnswer), LastAnswer: when(q.LastAnswer),
		})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"school": schoolBody{
			ID: school.ID.String(), Slug: school.Slug, Name: school.Name, Accent: school.Accent,
		},
		"questions": out,

		// THE BARS, FROM THE PACKAGE THAT APPLIED THEM. A screen writing these
		// numbers itself would be a second copy of a decision, and the copy is
		// the one that goes wrong when the constant moves.
		"thresholds": map[string]any{
			"minimum_sample": rollup.Thresholds.MinimumSample,
			"group_share":    rollup.Thresholds.GroupShare,
			"inverted_below": rollup.Thresholds.InvertedBelow,
			"weak_below":     rollup.Thresholds.WeakBelow,
			"too_easy_above": rollup.Thresholds.TooEasyAbove,
			"too_hard_below": rollup.Thresholds.TooHardBelow,
		},

		// WHEN, AND WHETHER EVER. A cache of a nightly job that has been failing
		// looks exactly like a cache that is current.
		"computed":    rollup.Computed,
		"computed_at": when(rollup.ComputedAt),

		// THERE IS NO SWITCH ON THIS SCREEN, said rather than left to be
		// noticed — the funnel beside it has one, and an operator who has seen
		// that would reasonably look for this.
		"counting": "real",
		"why_no_switch": "This is what the nightly job wrote, and that job counts real people " +
			"only — it takes questions out of circulation, which must never happen on the " +
			"strength of students who were invented.",

		"scope": "one school",
	})
}

// when is a time as the API says it, and the empty string for a zero — which is
// "there is none" rather than the first of January in year one.
func when(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.UTC().Format(time.RFC3339)
}

/* Cohorts: who started when, and what became of them.

   # THE FUNNEL IS A PHOTOGRAPH AND THIS IS A FILM

   That report mixes somebody who arrived yesterday with somebody who arrived a
   year ago. Improve the first lesson in August and it barely moves, because it
   is dominated by everybody who came before. This groups people by the month
   they signed up and follows each group forward, so August's intake can be
   compared with July's AT THE SAME AGE.

   # ONE HALF OF THE ROADMAP'S ITEM, AND THE OTHER SAYS WHY NOT

   It asks for two: by signup and by subscription start. Nothing writes a
   subscription into the stream — there is no payment gateway — so the second
   would be grouping by a moment nothing records. It comes back saying so, the
   way the funnel's unmeasured steps do, rather than as an empty table that reads
   as "nobody ever subscribed".
*/

// Cohort is one month's intake as this screen shows it.
type Cohort struct {
	// Month is the month they signed up, first instant, UTC.
	Month time.Time

	// People is how many signed up that month — the denominator of every cell.
	People int

	// Active is how many were still finishing sections in each month since,
	// index 0 being the month they joined. Shorter for a younger cohort: the
	// table is triangular because the future has not happened.
	Active []int
}

// Cohorts is what this package may not import.
type Cohorts func(ctx context.Context, school uuid.UUID, months int,
	counting string) (rows []Cohort, active string, err error)

type cohortBody struct {
	Month  string `json:"month"`
	People int    `json:"people"`
	Active []int  `json:"active"`
}

func (h *UnderstandHandler) cohortsOf(w http.ResponseWriter, r *http.Request) {
	school, ok := h.schoolFrom(w, r)
	if !ok {
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

	months, sane := monthsFrom(r)
	if !sane {
		web.Fail(w, http.StatusBadRequest, "not_a_window",
			"`months` is a whole number of months between 1 and 36")
		return
	}

	rows, active, err := h.cohorts(r.Context(), school.ID, months, counting)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the cohorts",
			"error", err, "school", school.Slug, "counting", counting)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]cohortBody, 0, len(rows))
	for _, c := range rows {
		one := cohortBody{Month: c.Month.UTC().Format("2006-01"), People: c.People, Active: c.Active}
		if one.Active == nil {
			one.Active = []int{}
		}
		out = append(out, one)
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"school": schoolBody{
			ID: school.ID.String(), Slug: school.Slug, Name: school.Name, Accent: school.Accent,
		},
		"cohorts": out,
		"months":  months,

		// WHAT "ACTIVE" MEANS, ANSWERED RATHER THAN ASSUMED. A cohort table means
		// whatever that word means, so a screen drawing one without saying it is
		// a screen whose numbers cannot be argued with. It comes from the package
		// that applied it, for the reason the item analysis's thresholds do.
		"active": active,

		"counting":    counting,
		"banner":      banner,
		"populations": populationOrder,

		/* AND THE HALF THAT IS NOT BUILT, NAMED. `Measured` on a funnel step and
		   this field are the same idea: an absent report and an empty one must
		   not read alike. */
		"by_subscription": false,
		"why_no_subscription": "Nothing writes a subscription into the event stream yet — " +
			"there is no payment gateway — so there is no moment to group by. This is the " +
			"same gap that makes the funnel's last step unmeasured.",

		"scope": "one school",
	})
}

// monthsFrom reads `?months=N`, defaulting to a year and refusing the rest.
//
// THE CEILING IS NOT DECORATION. Each month is a column on the screen and a
// column in every row above it; `months=100000` is a table nobody can read and a
// response nobody asked for.
func monthsFrom(r *http.Request) (int, bool) {
	raw := r.URL.Query().Get("months")
	if raw == "" {
		return 12, true
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n < 1 || n > 36 {
		return 0, false
	}
	return n, true
}

/* ---------- where the people are ---------- */

// Country is one row of the map.
type Country struct {
	Code   string
	People int
}

// Where is the whole answer: the countries, and every person counted once.
type Where struct {
	Countries []Country
	People    int
}

// Countries is what this package may not import: `analysis` folds the two
// identities on an event into a person, and `event` owns the stream.
type Countries func(ctx context.Context, school uuid.UUID, since time.Time,
	counting string) (Where, error)

type countryBody struct {
	Code   string `json:"code"`
	People int    `json:"people"`
}

/*
WHERE THE PEOPLE ARE, WHICH IS A REPORT WITH A TRAP IN IT.

	The countries add up to MORE than the number of people, because somebody who
	studied at home and again on a trip is honestly in both. Anybody reading the
	rows will add them up, so the honest total travels beside them rather than
	being left to be computed — the same rule as a threshold arriving with the
	number it produced (K-16).

	AND THE SCREEN IS NOT TOLD THE RULE, it is told the numbers. A sentence about
	double counting written into the interface would keep saying it after the
	rule changed, and it is the interface of a console whose whole job is to be
	trusted about arithmetic.
*/
func (h *UnderstandHandler) countriesOf(w http.ResponseWriter, r *http.Request) {
	school, ok := h.schoolFrom(w, r)
	if !ok {
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

	since, sane := windowFrom(r)
	if !sane {
		web.Fail(w, http.StatusBadRequest, "not_a_window",
			"`days` is a whole number of days, and 0 or nothing means since the beginning")
		return
	}

	where, err := h.countries(r.Context(), school.ID, since, counting)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading where the people are",
			"error", err, "school", school.Slug, "counting", counting)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]countryBody, 0, len(where.Countries))
	for _, c := range where.Countries {
		out = append(out, countryBody(c))
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"school": schoolBody{
			ID: school.ID.String(), Slug: school.Slug, Name: school.Name, Accent: school.Accent,
		},
		"countries": out,

		// EVERY PERSON ONCE, which is not the sum of the rows above and is the
		// only defence against somebody adding them up.
		"people": where.People,

		// The word for a country nobody could place, sent rather than spelled in
		// the interface: it is the same string the events carry, and a second
		// copy of it in JavaScript is a copy that stops matching.
		"unknown": Unknown,

		"counting":    counting,
		"banner":      banner,
		"populations": populationOrder,
		"scope":       "one school",
	})
}

// Unknown is the country of an event nobody could place.
//
// IT IS SPELLED HERE RATHER THAN IMPORTED, because `console` may not reach into
// `analysis` and neither may reach into `platform/geo` from the other side of
// the module rule. Four packages therefore write this word, and
// `internal/unknown_test.go` — which is outside all of them — is the only thing
// that can hold them to each other.
//
// It is EXPORTED for exactly that: an unexported one would leave the console
// out of the check, and the console is the copy that reaches the screen.
const Unknown = "unknown"
