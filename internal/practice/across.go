package practice

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* The queue that crosses schools, and the address it is asked at.

   # WHY THIS COULD NOT BE A PARAMETER ON `Due`

   A request arrives at a school's host and is scoped to that school before any
   module sees it. That is not an accident of the middleware order — it is what
   makes every query in this package safe to write, because there is exactly one
   school on the context and no route can be talked into another one. Adding
   "…or all of them" to `Due` would put a second meaning behind the same door.

   So it is a SECOND ENTRY POINT OVER THE SAME ROWS, at an address that is no
   school's: `app.<platform domain>`, beside `console.<platform domain>` and for
   the same reason (K-17). Nothing is duplicated — the schedule, the SM-2 state
   and the answering are exactly what they were, and this reads across them.

   # THE SESSION ALREADY REACHES IT, AND THAT IS WHY N-01 IS TRUE

   The session cookie has been on the PARENT domain since it existed, precisely
   so one sign-in covers every school. `app.` is a sibling of `code.` under that
   parent, so a student who signed in at their school is signed in here with no
   new mechanism and no second cookie. The design decided this years before
   there was anywhere to use it.

   # WHAT IS IN IT: WHAT IS DUE, AND NOT WHAT IS NEW

   `Due` offers two kinds of card — what is scheduled, and questions never
   answered, so a school's queue is never empty for somebody who finished
   today's. This one carries only the first, and the difference is what makes it
   a review queue rather than a firehose: a never-answered question is an
   invitation to start something, and four schools' worth of invitations
   interleaved by nothing is not a queue, it is a catalogue with a timer on it.

   It also settles which schools are in scope without needing a rule about it. A
   card is here because the student has a `practice_state` row for it, which
   means they answered it once — so the schools that appear are the schools they
   are actually in, rather than every school on the platform offering its free
   first course.

   # AND THE PAYWALL IS THE SAME PAYWALL

   Naming a school at this address grants nothing: `MayOpen` is asked per course
   with that school on the context, exactly as it is at the school's own host,
   and a card in a course the student may no longer open is dropped here as it
   is dropped there. What is out of circulation is asked per school for the same
   reason — a question withdrawn in one school is a fact about that school's
   catalogue.
*/

// Host is where the platform answers a student, derived from the platform's own
// domain.
//
// ONE PLACE THE DOMAIN IS WRITTEN, which is the argument `console.HostOf` makes
// in the same words: a second environment variable for this host would be a
// second thing to get wrong the day somebody moves the platform, and the two
// would be found to disagree by a 404 nobody could explain.
//
// `app` IS ALREADY A RESERVED LABEL — `migrations/0003_reserved_labels.sql` has
// held it since phase 0 — so no school can be created that would answer here.
// That reservation was written before anything used it, which is the only order
// in which such a rule ever works.
func Host(platformDomain string) string {
	domain := strings.ToLower(strings.TrimSpace(platformDomain))
	if domain == "" {
		return ""
	}
	return "app." + domain
}

// In puts a school on a context, the way the tenant middleware does for a
// request that arrived at a school's host.
//
// IT IS A CALLBACK BECAUSE `tenant` IS ANOTHER MODULE (X-02), and this one may
// not import it. What it buys is that `MayOpen` and everything under it are the
// SAME code here as at a school's address — a second way to say which school a
// request is for would be a second thing to get wrong about a paywall.
type In func(ctx context.Context, school uuid.UUID) context.Context

// Waiting is one school's share of the queue.
//
// THE SCHOOL IS NAMED AND NOT JUST IDENTIFIED, because the screen has to send
// somebody somewhere: a card is answered at its own school's address, where the
// catalogue that explains it lives. An id would make the interface ask a second
// question per school to draw one line.
type Waiting struct {
	School uuid.UUID `json:"-"`

	Slug string `json:"school"`
	Name string `json:"school_name"`
	Host string `json:"host"`

	Cards []Card `json:"cards"`
}

// Where is a school's public facts, for the schools a student has cards in.
// `tenant` owns the rows; this is the shape this package needs of them.
type Where struct {
	ID   uuid.UUID
	Slug string
	Name string
	Host string
}

// Schools answers those facts for a set of ids, in one go rather than one
// query per school.
type Schools func(ctx context.Context, ids []uuid.UUID) ([]Where, error)

/*
Across answers what is due today, everywhere this student practises.

	IT IS ORDERED BY WHAT IS AT RISK AND NOT BY SCHOOL. The rows come back oldest
	first across every school, and the grouping happens afterwards — so a card
	overdue by a month in one school is inside the limit and a card due this
	morning in another may not be. Ordering by school first would make the
	student's second school the one that quietly rots.
*/
func (s *Store) Across(ctx context.Context, in In, schools Schools,
	accountID uuid.UUID, limit int) ([]Waiting, error) {

	if in == nil || schools == nil {
		return nil, fmt.Errorf("practice: the cross-school queue was asked for without " +
			"a way to scope a school — that is a wiring mistake and not a student with none")
	}
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	today := s.today()

	/* ONLY WHAT HAS A SCHEDULE. The join is an inner one on purpose: a card
	   with no `practice_state` row is a question nobody has answered, which is
	   this package's other kind of card and belongs to a school's own queue. */
	rows, err := s.pool.Query(ctx, `
		SELECT p.tenant_id, e.id, e.version, e.course_id, e.lesson_id, e.type,
		       p.interval_days, p.lapses, p.due_on
		FROM practice_state p
		JOIN catalog_exercises e
		     ON e.tenant_id = p.tenant_id
		    AND e.id = p.exercise_id
		WHERE p.account_id = $1
		  AND p.due_on <= $2
		  AND e.drillable
		ORDER BY p.due_on ASC, p.tenant_id, e.id
	`, accountID, today)
	if err != nil {
		return nil, fmt.Errorf("practice: reading the queue across schools: %w", err)
	}
	defer rows.Close()

	type row struct {
		school  uuid.UUID
		card    Card
		version int
	}
	var found []row
	for rows.Next() {
		var r row
		var due time.Time
		if err := rows.Scan(&r.school, &r.card.ExerciseID, &r.version,
			&r.card.CourseID, &r.card.LessonID, &r.card.Type,
			&r.card.Interval, &r.card.Lapses, &due); err != nil {
			return nil, fmt.Errorf("practice: reading the queue across schools: %w", err)
		}
		r.card.DueOn = due.Format(time.DateOnly)
		found = append(found, r)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("practice: reading the queue across schools: %w", err)
	}
	if len(found) == 0 {
		return nil, nil
	}

	/* THE TWO GATES, ASKED ONCE PER SCHOOL AND ONCE PER COURSE. Both are the
	   same calls a school's own queue makes, with that school on the context —
	   which is the whole safety argument for letting a client reach this
	   address at all. Nothing here trusts the host; the school's queue never
	   did either. */
	withdrawn := map[uuid.UUID]map[Item]bool{}
	open := map[string]bool{}

	/* SCOPED ONCE PER SCHOOL AND NOT ONCE PER CARD. `In` is a lookup on the
	   other side of a module boundary — it has to find the school before it can
	   put it on a context — and a student with two hundred cards due would
	   otherwise make two hundred of those to learn the same two answers. */
	scoped := map[uuid.UUID]context.Context{}

	kept := map[uuid.UUID][]Card{}
	var order []uuid.UUID
	total := 0

	for _, r := range found {
		here, known := scoped[r.school]
		if !known {
			here = in(ctx, r.school)
			scoped[r.school] = here
		}

		gone, asked := withdrawn[r.school]
		if !asked {
			gone, err = s.outOfCirculation(here, r.school)
			if err != nil {
				return nil, err
			}
			withdrawn[r.school] = gone
		}
		if gone[Item{ExerciseID: r.card.ExerciseID, Version: r.version}] {
			continue
		}

		// Keyed by school AND course: two schools may hold a course with the
		// same id, and a shared key would let one school's paywall answer for
		// the other's.
		key := r.school.String() + "/" + r.card.CourseID
		allowed, asked := open[key]
		if !asked {
			allowed, err = s.may(here, r.card.CourseID)
			if err != nil {
				return nil, err
			}
			open[key] = allowed
		}
		if !allowed {
			continue
		}

		if _, seen := kept[r.school]; !seen {
			order = append(order, r.school)
		}
		kept[r.school] = append(kept[r.school], r.card)

		total++
		if total == limit {
			break
		}
	}
	if total == 0 {
		return nil, nil
	}

	/* AND THE SCHOOLS ARE NAMED IN ONE QUESTION. `order` is the order the first
	   card of each school appeared in, which is the order of what is most
	   overdue — so the school a student is furthest behind in is first. */
	named, err := schools(ctx, order)
	if err != nil {
		return nil, err
	}
	byID := make(map[uuid.UUID]Where, len(named))
	for _, w := range named {
		byID[w.ID] = w
	}

	out := make([]Waiting, 0, len(order))
	for _, id := range order {
		/* A SCHOOL THE LOOKUP DID NOT ANSWER FOR IS DROPPED rather than shown
		   with a blank name. There is one way for that to happen — a school
		   deleted between the two queries — and a card that cannot say where it
		   is answered is a card nobody can act on. */
		w, ok := byID[id]
		if !ok {
			continue
		}
		out = append(out, Waiting{
			School: id, Slug: w.Slug, Name: w.Name, Host: w.Host, Cards: kept[id],
		})
	}
	return out, nil
}

/* ---------- and over HTTP ---------- */

// AcrossHandler answers the queue at the platform's own address.
//
// IT IS A SECOND HANDLER AND NOT A SECOND ROUTE ON THE FIRST, because the two
// are mounted behind different middleware: everything in `Handler` runs after a
// school has been resolved from the host, and nothing here may. Registering
// this on the same mux would make which chain a route gets a matter of where
// somebody typed it.
type AcrossHandler struct {
	store     *Store
	in        In
	schools   Schools
	studentOf StudentOf
}

func NewAcrossHandler(store *Store, in In, schools Schools,
	studentOf StudentOf) *AcrossHandler {

	return &AcrossHandler{store: store, in: in, schools: schools, studentOf: studentOf}
}

func (h *AcrossHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/review", h.review)
}

func (h *AcrossHandler) review(w http.ResponseWriter, r *http.Request) {
	student, ok := h.studentOf(r.Context())
	if !ok {
		/* SIGN IN FIRST, AND THE SESSION IS ALREADY HERE IF THERE IS ONE. The
		   cookie is on the parent domain, so somebody signed in at their school
		   arrives here signed in; a 401 at this address means signed in nowhere
		   rather than signed in at the wrong place. */
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	waiting, err := h.store.Across(r.Context(), h.in, h.schools, student, limit)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the queue across schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}
	if waiting == nil {
		waiting = []Waiting{}
	}

	total := 0
	for _, one := range waiting {
		total += len(one.Cards)
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"schools": waiting,
		"due":     total,

		/* WHAT THIS QUEUE IS, SAID BY THE SERVER. It is the one thing a student
		   arriving here will get wrong on their own: this is what is SCHEDULED,
		   and a school with nothing due is not a school with nothing to do —
		   its own queue still offers questions never answered. A screen holding
		   its own sentence about that would keep saying it after this changes. */
		"about": "What is due today, everywhere you practise. Questions you have never " +
			"answered are not here: those belong to a course you are working through, and " +
			"each school's own practice screen still offers them.",
	})
}
