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
	mux.HandleFunc("POST /api/v1/practice/{exercise}/answered", h.answered)
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

// What the client sends when a card has been answered.
//
// IT SAYS WHETHER IT WAS RIGHT AND HOW LONG IT TOOK, and nothing about how well
// the student felt they remembered. That is the whole point of A-04, and it is
// visible here: there is no field for an opinion, so no client can send one and
// no future version can start reading one by accident.
//
// CORRECTNESS IS THE CLIENT'S WORD FOR NOW, and that is a real limitation
// rather than an oversight. The grader lives in `internal/grade` and marks an
// exam server-side; a drill is not an exam — nothing is awarded for it, it is
// excluded from every certificate — so a student who lied would be moving their
// own schedule and cheating nobody. When the practice screen exists it should
// send the ANSWER and be told, which is the same shape the exam already uses.
type answered struct {
	Correct   bool `json:"correct"`
	ElapsedMs int  `json:"elapsed_ms"`
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

	state, err := h.store.Answered(r.Context(), school, student,
		r.PathValue("exercise"), body.Correct, elapsed)
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	if h.emit != nil {
		h.emit(r.Context(), "practice_answered", map[string]any{
			"exercise": r.PathValue("exercise"),
			"correct":  body.Correct,
			"interval": state.Interval,
			"lapses":   state.Lapses,
		})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"interval_days": state.Interval,
		"lapses":        state.Lapses,
		"due_on":        Due(time.Now().UTC(), state).Format(time.DateOnly),
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
