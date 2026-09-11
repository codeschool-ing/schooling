package lesson

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// A lesson's questions over HTTP.
//
// BOTH ROUTES NEED A STUDENT, because both ask the paywall, and which course a
// plan opens is a fact about a person rather than about a request.
type (
	SchoolOf  func(ctx context.Context) (uuid.UUID, bool)
	StudentOf func(ctx context.Context) (uuid.UUID, bool)
)

// Emit is where an answer is counted. It is a callback for the same reason
// every other boundary here is: this module may not reach into the one that
// owns events, and modules meet in `cmd/`.
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

// Routes are under the course, the way `images/` already is: a lesson's
// questions belong to a course, the paywall is asked per course, and a path
// that carried only the exercise id would make the route that serves them
// impossible to read.
func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/courses/{course}/lessons/{lesson}/exercises", h.questions)
	mux.HandleFunc("POST /api/v1/courses/{course}/lessons/{lesson}/exercises/{exercise}/answered", h.answered)
}

func (h *Handler) questions(w http.ResponseWriter, r *http.Request) {
	school, ok := h.who(w, r)
	if !ok {
		return
	}

	qs, err := h.store.Questions(r.Context(), school,
		r.PathValue("course"), r.PathValue("lesson"), web.Locale(r))
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	// AN EMPTY LESSON IS AN EMPTY LIST AND NOT A 404. Almost every course in
	// this catalogue has no questions yet, and a screen that treated "none
	// written" as an error would be a screen showing a failure for the ordinary
	// state of the material.
	if qs == nil {
		qs = []Question{}
	}
	web.JSON(w, http.StatusOK, qs)
}

// What the client sends when a question has been answered.
//
// IT SENDS THE ANSWER AND THE FRAME IT WAS SHOWN IN, and is told. There is no
// field for `correct`: the question it was given has no key in it, so the
// client cannot know, and a field it could fill would put the one piece of
// grading in this system outside `internal/grade`.
//
// AND NO FIELD FOR HOW LONG IT TOOK. The drill has one because time decides the
// SM-2 quality (A-04); here there is no schedule and no score, so a duration
// would be a number nothing reads — and a number nothing reads is a number
// somebody eventually starts reading.
type answer struct {
	Answer json.RawMessage `json:"answer"`
	Perm   []int           `json:"perm"`
}

func (h *Handler) answered(w http.ResponseWriter, r *http.Request) {
	school, ok := h.who(w, r)
	if !ok {
		return
	}

	var body answer
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 8<<10)).Decode(&body); err != nil {
		web.Fail(w, http.StatusBadRequest, "invalid", "that is not the JSON this route expects")
		return
	}

	marked, err := h.store.Answered(r.Context(), school,
		r.PathValue("exercise"), body.Perm, body.Answer, web.Locale(r))
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	/* THE OBSERVATION, WHICH IS THE ONLY THING A WRONG ANSWER LEAVES BEHIND.
	   A-10 keeps no score, and this is what it keeps instead: `internal/analysis`
	   reads the event stream (K-03), so a lesson question earns its difficulty
	   and its discrimination here exactly as an exam question does — and a
	   lesson is the cheaper place to earn them, because every student answers
	   every one of them (A-12). */
	if h.emit != nil {
		h.emit(r.Context(), "lesson_answered", map[string]any{
			"course":   r.PathValue("course"),
			"lesson":   r.PathValue("lesson"),
			"exercise": r.PathValue("exercise"),
			"correct":  marked.Correct,
		})
	}

	/* FLAT, THE WAY THE DRILL SENDS IT AND THE WAY EVERY RENDERER READS IT.

	   This sent `"reveal": {"expected": …, "explanations": …}` — the struct, one
	   level down — and `applyKey` in the browser reads `v.expected`. It found
	   `undefined` on every answer this route has ever marked and returned
	   without doing anything.

	   What that costs is the whole of the feedback. A quiz keeps no `correct`
	   on any choice, so the option the student ticked gets `choice-wrong` for
	   being ticked and not correct, and NOTHING is marked right: a correct
	   answer was painted red under a banner saying it was correct. An ordering
	   question never showed the right order, a matching question revealed no
	   pairing, and the per-choice `why` — the one thing A-10 keeps instead of a
	   score — never appeared at all.

	   `internal/practice` has flattened it since it was written, with a comment
	   describing this exact contract. Two routes, one client, one of them
	   shaped differently: the same join this repository keeps finding. */
	web.JSON(w, http.StatusOK, map[string]any{
		"correct":      marked.Correct,
		"why":          marked.Why,
		"expected":     marked.Reveal.Expected,
		"explanations": marked.Reveal.Explanations,
	})
}

// who resolves the school and insists on a signed-in student.
//
// IT RETURNS THE SCHOOL AND NOT THE STUDENT, and that is A-10 showing up in a
// signature. Being signed in is required — the paywall is a fact about a person
// and the question is which courses this one may open — but WHICH person is
// answering is not recorded anywhere, because nothing is recorded anywhere.
// `unparam` noticed the unused return before this comment existed, which is the
// linter agreeing with the decision rather than complaining about it.
func (h *Handler) who(w http.ResponseWriter, r *http.Request) (school uuid.UUID, ok bool) {
	school, ok = h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a lesson route ran with no school resolved",
			"path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return uuid.Nil, false
	}

	if _, signedIn := h.studentOf(r.Context()); !signedIn {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return uuid.Nil, false
	}
	return school, true
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
	case errors.Is(err, ErrIsAnExamQuestion):
		// 404 and not 403, and this is the one place that deliberately says
		// less than it knows: "that is an exam question" tells somebody probing
		// ids which ones are on the paper.
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such exercise in this lesson")
	case errors.Is(err, ErrWithdrawn):
		// 410 and not 404: the question was there, and it is gone on purpose.
		web.Fail(w, http.StatusGone, "withdrawn",
			"that question has been withdrawn while it is looked at")
	default:
		web.LoggerFrom(r.Context()).Error("a lesson route failed",
			"path", r.URL.Path, "error", err)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
	}
}
