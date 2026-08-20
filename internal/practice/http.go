package practice

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Practice over HTTP.
//
// EVERY ROUTE HERE NEEDS A STUDENT, and the account comes from the session
// rather than from the request. Which card is being answered is a client's
// choice; whose schedule moves is not.
type (
	SchoolOf  func(ctx context.Context) (uuid.UUID, bool)
	StudentOf func(ctx context.Context) (uuid.UUID, bool)
)

// Emit is where an answer is counted, for the same reason everything else here
// is a callback: this module may not reach into the one that owns events.
type Emit func(ctx context.Context, name string, payload map[string]any)

type Handler struct {
	store     *Store
	schoolOf  SchoolOf
	studentOf StudentOf
	emit      Emit
}

func NewHandler(store *Store, schoolOf SchoolOf, studentOf StudentOf, emit Emit) *Handler {
	return &Handler{store: store, schoolOf: schoolOf, studentOf: studentOf, emit: emit}
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/practice", h.queue)
	mux.HandleFunc("POST /api/v1/practice/{exercise}/draw", h.draw)
	mux.HandleFunc("POST /api/v1/practice/{exercise}/answered", h.answered)

	// What the student has already answered, which is a REPORT and not a
	// queue: the two are different screens and the second is the one somebody
	// opens to find out how they are doing.
	mux.HandleFunc("GET /api/v1/practice/history", h.history)
}

func (h *Handler) history(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	answers, err := h.store.History(r.Context(), school, student)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"answers": answers})
}

func (h *Handler) queue(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	cards, err := h.store.Due(r.Context(), school, student, limit)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	if cards == nil {
		// An empty queue is a real and good answer — it means somebody has done
		// today's — so it is an empty list rather than null, which a client
		// would have to special-case.
		cards = []Card{}
	}
	web.JSON(w, http.StatusOK, map[string]any{"cards": cards})
}

// DRAWING IS A POST, not a GET, and that is not pedantry: it writes down how
// the card was shuffled. A GET that changed the shuffle would be a GET that
// changed the answer a subsequent POST is marked against, and every proxy,
// prefetch and double-click would be a card silently re-dealt under a student
// who was halfway through it.
func (h *Handler) draw(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	card, err := h.store.Draw(r.Context(), school, student, r.PathValue("exercise"))
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, card)
}

// What the client sends when a card has been answered.
//
// IT SENDS THE ANSWER AND IS TOLD. It said `correct` for one commit, which was
// wrong twice over: a client cannot know — the question it was given has no key
// in it — so the field could only ever be an assertion nothing checked, and it
// put the one piece of grading in this system outside `internal/grade`.
//
// AND NOTHING ABOUT HOW WELL THEY FELT THEY REMEMBERED. That is A-04, visible
// in the shape: there is no field for an opinion, so no client can send one and
// no later version can start reading one by accident.
type answered struct {
	Answer    json.RawMessage `json:"answer"`
	ElapsedMs int             `json:"elapsed_ms"`
}

func (h *Handler) answered(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	var body answered
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4<<10)).Decode(&body); err != nil {
		web.Fail(w, http.StatusBadRequest, "invalid", "that is not the JSON this route expects")
		return
	}

	/* A NEGATIVE OR ABSURD ELAPSED TIME IS THE CLIENT'S CLOCK, not the
	   student's speed. It decides the quality, so an hour recorded because a tab
	   was left open would schedule a card as though it had been laboured over.
	   Clamped rather than refused: the answer itself is still real. */
	elapsed := time.Duration(body.ElapsedMs) * time.Millisecond
	if elapsed < 0 {
		elapsed = 0
	}
	if elapsed > time.Hour {
		elapsed = time.Hour
	}

	marked, err := h.store.Answered(r.Context(), school, student,
		r.PathValue("exercise"), body.Answer, elapsed)
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	if h.emit != nil {
		h.emit(r.Context(), "practice_answered", map[string]any{
			"exercise": r.PathValue("exercise"),
			"correct":  marked.Correct,
			"interval": marked.State.Interval,
			"lapses":   marked.State.Lapses,
		})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"correct": marked.Correct,
		// The question's own words, not this code's: a grader that wrote its
		// own feedback would be writing content.
		"why":           marked.Why,
		"interval_days": marked.State.Interval,
		"lapses":        marked.State.Lapses,
		"due_on":        Due(time.Now().UTC(), marked.State).Format(time.DateOnly),
	})
}

func (h *Handler) who(w http.ResponseWriter, r *http.Request) (school, student uuid.UUID, ok bool) {
	school, ok = h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a practice route ran with no school resolved",
			"path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return uuid.Nil, uuid.Nil, false
	}

	student, ok = h.studentOf(r.Context())
	if !ok {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return uuid.Nil, uuid.Nil, false
	}
	return school, student, true
}

func (h *Handler) refuse(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrLocked):
		// The same 402 the catalogue gives, for the same reason: a purchase
		// rather than a permission.
		web.Fail(w, http.StatusPaymentRequired, "locked",
			"this course is not open on the current plan")
	case errors.Is(err, ErrNoSuchExercise):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such exercise in this school")
	case errors.Is(err, ErrWithdrawn):
		// 410 and not 404: the question was there, and it is gone on purpose.
		// The distinction is worth the status code — a student who saw a card
		// in their queue a minute ago is owed "we withdrew it" rather than
		// "there is no such thing", which reads as their mistake.
		web.Fail(w, http.StatusGone, "withdrawn",
			"that question has been withdrawn while it is looked at")
	case errors.Is(err, ErrNotDrawn):
		// 409 and not 404: the question exists and this student has not been
		// shown it, which is a different fact and a different thing to do next
		// — draw it.
		web.Fail(w, http.StatusConflict, "not-drawn",
			"draw that card before answering it")
	case errors.Is(err, ErrBadAnswer):
		web.Fail(w, http.StatusBadRequest, "invalid",
			"that answer does not fit the question")
	case errors.Is(err, ErrNotDrillable):
		// 409 and not 404: the question exists and this is not a thing to do
		// with it, which is a different fact and a different screen.
		web.Fail(w, http.StatusConflict, "not-drillable",
			"that question is not one to drill")
	default:
		web.LoggerFrom(r.Context()).Error("practice", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that could not be recorded just now")
	}
}
