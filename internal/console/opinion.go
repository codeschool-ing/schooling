package console

import (
	"context"
	"net/http"
	"sort"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* What a school's students think of its courses, its tracks and this place.

   # IT IS THE ONE SCREEN HERE THAT MEASURES US

   Every other reading in this console is about the students: how many arrived,
   how far they got, what they got wrong, who is present. This one runs the
   other way, and it is the only number in the system that can say a course was
   not worth the evening — the grader knows whether they answered it, the funnel
   knows whether they left, and neither of those is the same question.

   # THE DISTRIBUTION AND NOT THE MEAN, WHICH IS THE WHOLE SCREEN

   A mean of 3.0 where everybody said 3 and a mean of 3.0 where half said 1 and
   half said 5 are two different problems and only one of them is urgent, so the
   counts travel and the mean rides along as a convenience. `rating.Spread`
   carries both for the same reason a screen must not compute one: two places
   computing a number is two numbers that eventually disagree.

   AND `depth` HAS NO GOOD END. Too easy and too hard are both misses, and
   averaging them produces a serene 3 for a course half the students could not
   follow and half found trivial. Nothing here sorts or scores by it.

   # GROUPED BY RELEASE, WHICH IS WHAT MAKES IT ACTIONABLE

   A course rewritten because it scored badly has to be comparable to itself,
   and nobody writes the old number down before the rewrite. Each row is one
   subject at one release, so the screen can put them side by side; a single
   lifetime average would sink slowly after a fix and say the fix did not work.

   # NOBODY IS NAMED, AND THAT IS NOT AN OVERSIGHT

   The queue on Content shows a report without its reporter, for a reason it
   states on the screen. This is stronger: the aggregate never carried an
   account id in the first place, so there is nothing here to withhold. A
   console that could see which student called a course padded would be a list
   of people picked out by an opinion. */

// Rated is one subject at one release, as this screen reads it.
type Rated struct {
	Kind      string
	SubjectID string
	Version   string

	// How many answered each point of the scale, and how many in total. The
	// index is the answer: `Stars[4]` is how many said four.
	Stars     []int
	StarCount int
	StarMean  float64

	// The same shape per aspect, keyed by the aspect's name. An aspect nobody
	// answered is present with a count of zero rather than absent, so the
	// screen draws an empty row instead of a missing one — "nobody was asked"
	// and "the question does not exist" look identical otherwise.
	Aspects map[string]RatedAspect

	First time.Time
	Last  time.Time
}

// RatedAspect is one of the four pairs at one release.
type RatedAspect struct {
	At    []int
	Count int
	Mean  float64
}

// Ratings is what this package may not import: `rating` owns the table and the
// closed lists that describe it.
type Ratings struct {
	// Over is every rating of one kind in one school, already grouped by
	// subject and release.
	Over func(ctx context.Context, school uuid.UUID, kind string) ([]Rated, error)

	// Kinds and Aspects are the closed lists, so the screen offers what the
	// store knows rather than its own copy — the same arrangement as
	// `Reports.Verdicts` one file along.
	Kinds   []string
	Aspects []string

	// Refused is a kind this does not know, which is a caller error and not a
	// broken database.
	Refused func(error) bool
}

// OpinionHandler answers the ratings screen.
//
// IT HAS NO WRITE AND WILL NOT GET ONE. The console reads and never writes the
// catalogue (C-07); this is the same rule one step further out — an operator
// who could delete a rating could delete the ones they disagreed with, and the
// number would then measure the operator.
type OpinionHandler struct {
	schools Schools
	ratings Ratings
}

func NewOpinionHandler(schools Schools, ratings Ratings) *OpinionHandler {
	return &OpinionHandler{schools: schools, ratings: ratings}
}

func (h *OpinionHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/schools/{id}/ratings", h.over)
}

// school resolves the id in the path, as `content.go` and `understand.go` each
// do for themselves. Four lines and a 404, written a third time rather than
// shared between three handler types that have nothing else in common.
func (h *OpinionHandler) school(w http.ResponseWriter, r *http.Request) (School, bool) {
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

func (h *OpinionHandler) over(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	/* ONE KIND PER REQUEST, DEFAULTING TO COURSES. The three are different
	   questions with different populations — every student meets a course, few
	   finish a track, everybody is on the platform — and a screen showing all
	   three at once would be three tables somebody has to notice are unrelated. */
	kind := r.URL.Query().Get("kind")
	if kind == "" {
		kind = "course"
	}

	rows, err := h.ratings.Over(r.Context(), school.ID, kind)
	switch {
	case h.ratings.Refused(err):
		web.Fail(w, http.StatusBadRequest, "invalid", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading the ratings",
			"error", err, "school", school.Slug, "kind", kind)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	/* SORTED BY THE SUBJECT AND THEN BY THE RELEASE, so that the releases of
	   one course sit together in the order they happened and the screen can
	   read them as a series. The store answers in scan order, which is stable
	   and is not this. */
	sort.SliceStable(rows, func(a, b int) bool {
		if rows[a].SubjectID != rows[b].SubjectID {
			return rows[a].SubjectID < rows[b].SubjectID
		}
		return rows[a].First.Before(rows[b].First)
	})

	out := make([]map[string]any, 0, len(rows))
	for _, one := range rows {
		aspects := map[string]any{}
		for name, spread := range one.Aspects {
			aspects[name] = map[string]any{
				"at": spread.At, "count": spread.Count, "mean": spread.Mean,
			}
		}
		out = append(out, map[string]any{
			"kind":       one.Kind,
			"subject_id": one.SubjectID,
			"version":    one.Version,
			"stars":      map[string]any{"at": one.Stars, "count": one.StarCount, "mean": one.StarMean},
			"aspects":    aspects,
			"first":      one.First,
			"last":       one.Last,
		})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"school":  map[string]any{"id": school.ID, "name": school.Name, "slug": school.Slug},
		"kind":    kind,
		"kinds":   h.ratings.Kinds,
		"aspects": h.ratings.Aspects,
		"ratings": out,

		// WHAT THIS SCREEN WILL NOT SHOW, said by the thing that decided not to
		// show it, as the report queue does one file along.
		"anonymous": "A rating is counted and never attributed. Unlike the report queue, which " +
			"holds the reporter's account and declines to draw it, nothing here ever read " +
			"one — the aggregate is built without it. A console that could see who called a " +
			"course padded would be a list of people picked out by an opinion.",

		// AND THE ONE READING THAT IS A MISTAKE, next to the numbers that invite
		// it. `depth` is the only aspect with no good end, and a screen that
		// ranked by its mean would report a serene 3 for a course half the
		// students found trivial and half could not follow.
		"depth": "Too easy and too hard are both misses, so the mean of this one says nothing. " +
			"Read its shape: a flat spread is a course pitched at nobody, and two humps is a " +
			"course being taken by two different audiences.",
	})
}
