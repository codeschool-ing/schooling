package exam

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Exams over HTTP.
//
// EVERY ROUTE HERE NEEDS A STUDENT, and the account comes from the session
// rather than from the request — the same rule progress follows, for the same
// reason. Whose paper is being written is not something a client chooses.
type (
	SchoolOf  func(ctx context.Context) (uuid.UUID, bool)
	StudentOf func(ctx context.Context) (uuid.UUID, bool)
)

// Emit is where events go. It is a callback because this module may not import
// the one that owns them.
type Emit func(ctx context.Context, name string, payload map[string]any)

// Awarded is called once, when a paper is marked and passed.
//
// IT IS HOW A CERTIFICATE COMES TO EXIST AT THE MOMENT IT IS EARNED. Certifying
// is another module's job and this one may not reach into it; what this module
// knows, and nothing else does, is the instant a pass happens. It must not fail
// the request: the student passed, and that is recorded on the attempt whatever
// happens next — a document that could not be written is worth strictly less
// than an exam result that was lost writing it.
type Awarded func(ctx context.Context, scope Scope, id string)

type Handler struct {
	store     *Store
	schoolOf  SchoolOf
	studentOf StudentOf
	emit      Emit
	awarded   Awarded
}

func NewHandler(store *Store, schoolOf SchoolOf, studentOf StudentOf,
	emit Emit, awarded Awarded) *Handler {

	return &Handler{
		store: store, schoolOf: schoolOf, studentOf: studentOf,
		emit: emit, awarded: awarded,
	}
}

// Routes mounts the exam routes.
//
// THE SCOPE IS IN THE PATH AND THERE ARE TWO PATHS, rather than one route with
// a `{scope}` wildcard. A closed set of two belongs in the router: it means no
// handler ever holds a scope a client invented, and the 404 for a third one is
// the router's rather than a validation branch somebody has to remember to
// write.
func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/exams/course/{id}/start", h.start(ScopeCourse))
	mux.HandleFunc("POST /api/v1/exams/track/{id}/start", h.start(ScopeTrack))

	mux.HandleFunc("GET /api/v1/exams/attempts", h.history)
	mux.HandleFunc("GET /api/v1/exams/attempts/{attempt}", h.paper)
	mux.HandleFunc("PUT /api/v1/exams/attempts/{attempt}/answers/{position}", h.answer)
	mux.HandleFunc("POST /api/v1/exams/attempts/{attempt}/hand-in", h.handIn)
}

func (h *Handler) start(scope Scope) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		school, student, ok := h.who(w, r)
		if !ok {
			return
		}
		id := r.PathValue("id")

		paper, resumed, err := h.store.Start(r.Context(), school, student, scope, id, web.Locale(r))
		if err != nil {
			h.refuse(w, r, err)
			return
		}

		// ONLY A REAL START IS COUNTED. A student reopening the tab resumes the
		// same paper, and counting that would make "exams started" a measure of
		// how often people reload.
		if !resumed {
			h.emitted(r, "exam.started", map[string]any{
				"scope": string(scope), "exam": id, "questions": len(paper.Questions),
			})
		}

		status := http.StatusCreated
		if resumed {
			status = http.StatusOK
		}
		web.JSON(w, status, map[string]any{"paper": paper, "resumed": resumed})
	}
}

func (h *Handler) paper(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}
	attempt, ok := h.attemptID(w, r)
	if !ok {
		return
	}

	paper, err := h.store.Attempt(r.Context(), school, student, attempt)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"paper": paper})
}

func (h *Handler) answer(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}
	attempt, ok := h.attemptID(w, r)
	if !ok {
		return
	}

	position, err := strconv.Atoi(r.PathValue("position"))
	if err != nil || position < 0 {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such question on this paper")
		return
	}

	// The answer is whatever shape its own type takes, so it is carried through
	// as raw JSON and read by the grader rather than decoded here.
	var in struct {
		Answer json.RawMessage `json:"answer"`
	}
	r.Body = http.MaxBytesReader(w, r.Body, 64*1024)
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil || len(in.Answer) == 0 {
		web.Fail(w, http.StatusBadRequest, "invalid", "that is not the JSON this route expects")
		return
	}

	if err := h.store.Answer(r.Context(), school, student, attempt, position, in.Answer); err != nil {
		h.refuse(w, r, err)
		return
	}

	// NOTHING IS SAID ABOUT WHETHER IT WAS RIGHT. The reply is that it was
	// recorded, because the paper is not marked until it is handed in — and a
	// reply that differed for a correct answer would be a grader a client could
	// run one question at a time.
	web.JSON(w, http.StatusOK, map[string]string{"status": "recorded"})
}

func (h *Handler) handIn(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}
	attempt, ok := h.attemptID(w, r)
	if !ok {
		return
	}

	paper, marked, err := h.store.Submit(r.Context(), school, student, attempt)
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	if marked && paper.Result != nil {
		h.emitted(r, "exam.submitted", map[string]any{
			"scope": string(paper.Scope), "exam": paper.ScopeID,
			"score": paper.Result.Score, "of": paper.Result.Of,
			"pass_mark": paper.Result.PassMark, "passed": paper.Result.Passed,
		})

		// ONE EVENT PER QUESTION, and it is what item analysis is made of
		// (C-06): a question everybody gets wrong is either excellent or broken,
		// and nothing can tell which without the answers of everybody who sat
		// it. It goes into the event stream rather than into a table of its own
		// because events survive an erasure orphaned — so a student asking to be
		// forgotten does not take the evidence about a bad question with them.
		for _, q := range paper.Questions {
			if q.Correct == nil {
				continue
			}
			// THE ATTEMPT'S OWN SCORE TRAVELS WITH EVERY ITEM, and it is
			// carried rather than joined for the same reason the dimensions
			// are. The discrimination index asks whether the students who did
			// well on the paper got THIS question right more often than the
			// students who did badly — which needs each answer beside the mark
			// of the person who gave it. Joining an item event to the
			// submission event afterwards would work until an event was
			// emitted out of order, dropped, or emitted twice, and then it
			// would answer with the wrong number rather than with an error.
			h.emitted(r, "exam.item.answered", map[string]any{
				"scope": string(paper.Scope), "exam": paper.ScopeID,
				"exercise": q.ExerciseID, "version": q.Version, "type": q.Type,
				"correct": *q.Correct,
				"attempt": paper.AttemptID.String(),
				"score":   paper.Result.Score, "of": paper.Result.Of,
			})
		}

		if paper.Result.Passed && h.awarded != nil {
			h.awarded(r.Context(), paper.Scope, paper.ScopeID)
		}
	}

	web.JSON(w, http.StatusOK, map[string]any{"paper": paper, "marked": marked})
}

func (h *Handler) history(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	sat, err := h.store.History(r.Context(), school, student)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"attempts": sat})
}

func (h *Handler) who(w http.ResponseWriter, r *http.Request) (school, student uuid.UUID, ok bool) {
	school, ok = h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("an exam route ran with no school resolved",
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

// attemptID reads the attempt from the path.
//
// AN UNPARSEABLE ID IS THE SAME 404 AS AN ATTEMPT THAT IS SOMEBODY ELSE'S. The
// store already refuses to tell those two apart, and a handler that answered
// "malformed" for one and "not found" for the other would put the distinction
// back.
func (h *Handler) attemptID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue("attempt"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such attempt")
		return uuid.Nil, false
	}
	return id, true
}

// emitted counts something, and never fails the request over it.
func (h *Handler) emitted(r *http.Request, name string, payload map[string]any) {
	if h.emit != nil {
		h.emit(r.Context(), name, payload)
	}
}

func (h *Handler) refuse(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrLocked):
		web.Fail(w, http.StatusPaymentRequired, "locked",
			"this exam is not open on the current plan")
	case errors.Is(err, ErrNoSuchExam):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "there is no exam for that")
	case errors.Is(err, ErrNoSuchAttempt):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such attempt")
	case errors.Is(err, ErrNoSuchQuestion):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such question on this paper")
	case errors.Is(err, ErrHandedIn):
		// 409 rather than 400: the request is well formed and the paper is over,
		// which is a state and not a mistake.
		web.Fail(w, http.StatusConflict, "handed-in",
			"that exam was handed in and cannot be changed")
	case errors.Is(err, ErrBadAnswer):
		web.Fail(w, http.StatusBadRequest, "invalid",
			"that is not an answer to that question")
	default:
		web.LoggerFrom(r.Context()).Error("exam", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that could not be done just now")
	}
}
