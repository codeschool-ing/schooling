package progress

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Progress over HTTP.
//
// EVERY ROUTE HERE NEEDS A STUDENT, and the account comes from the session
// rather than from the request. A course id in a path is something a client
// chooses; whose progress is being written is not — and an endpoint that took
// an account id would be one missing check away from letting anybody write
// anybody's history.
type (
	SchoolOf  func(ctx context.Context) (uuid.UUID, bool)
	StudentOf func(ctx context.Context) (uuid.UUID, bool)
)

// Completed is what a completion is worth counting as, emitted where events
// are emitted. It is a callback for the same reason everything else here is.
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
	mux.HandleFunc("GET /api/v1/progress/{course}", h.ofCourse)
	mux.HandleFunc("POST /api/v1/progress/{course}/{lesson}/{section}/complete", h.complete)
	mux.HandleFunc("POST /api/v1/progress/{course}/{lesson}/{section}/visit", h.visit)
	mux.HandleFunc("GET /api/v1/resume", h.recent)
	mux.HandleFunc("PUT /api/v1/notes/{course}/{lesson}/{section}", h.setNote)
	mux.HandleFunc("GET /api/v1/notes/{course}", h.notes)

	// The two the interface reads to draw a list rather than a page. Both are
	// the whole of something — every course a student has touched, every note
	// they have written — because a sidebar with a count beside twenty courses
	// is twenty requests otherwise, and a list of notes across courses cannot
	// be assembled from a route that takes one course at a time.
	//
	// They sit AFTER the more specific patterns above and that is not luck:
	// `GET /api/v1/notes/{course}` and `GET /api/v1/notes` are different
	// patterns to ServeMux, which prefers the more specific one whatever the
	// registration order. Written adjacently so that nobody has to know that.
	mux.HandleFunc("GET /api/v1/progress", h.summary)
	mux.HandleFunc("GET /api/v1/notes", h.allNotes)
}

func (h *Handler) ofCourse(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	done, where, err := h.store.OfCourse(r.Context(), school, student, r.PathValue("course"))
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	notes, err := h.store.Notes(r.Context(), school, student, r.PathValue("course"))
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"completed": done,
		"resume":    where,
		"notes":     notes,
	})
}

func (h *Handler) complete(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}
	course, lesson, section := r.PathValue("course"), r.PathValue("lesson"), r.PathValue("section")

	first, finished, err := h.store.Complete(r.Context(), school, student, course, lesson, section)
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	// ONLY THE FIRST TIME. Statistics come from the event stream, so emitting
	// on every call would inflate "sections completed this month" by every
	// double tap and every retry — quietly, and in the direction that flatters.
	if first && h.emit != nil {
		h.emit(r.Context(), "section.completed", map[string]any{
			"course": course, "lesson": lesson, "section": section,
		})
	}

	// AND THE STEP OF THE FUNNEL THAT ONLY THIS PLACE CAN SEE. Finishing a
	// course is not a thing a student does; it is a thing that becomes true
	// when they finish the last section of it, and nobody clicks it. Derived
	// afterwards it would be a query over the catalogue as it is TODAY, which
	// answers with the wrong number the first time a section is added.
	if finished && h.emit != nil {
		h.emit(r.Context(), "course.completed", map[string]any{"course": course})
	}

	web.JSON(w, http.StatusOK, map[string]any{"status": "completed", "first": first})
}

func (h *Handler) visit(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	course, lesson := r.PathValue("course"), r.PathValue("lesson")

	if err := h.store.Visit(r.Context(), school, student,
		course, lesson, r.PathValue("section")); err != nil {
		h.refuse(w, r, err)
		return
	}

	// EVERY TIME, UNLIKE A COMPLETION, and the difference is what the two
	// words mean. Completing is a STATE: it can be re-asserted, and counting
	// the second tap would say somebody finished a section twice. Opening is a
	// MOMENT: it genuinely recurs, and a student who comes back to a lesson has
	// opened it again.
	//
	// The funnel takes the first per person, which is what "opened the first
	// lesson" asks — and having the repeats is what lets a later question be
	// asked at all, like whether the people who came back are the ones who
	// subscribed.
	if h.emit != nil {
		h.emit(r.Context(), "lesson.opened", map[string]any{
			"course": course, "lesson": lesson, "section": r.PathValue("section"),
		})
	}

	web.JSON(w, http.StatusOK, map[string]string{"status": "noted"})
}

func (h *Handler) recent(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	where, err := h.store.Recent(r.Context(), school, student, 10)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"resume": where})
}

func (h *Handler) setNote(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	var in struct {
		Body string `json:"body"`
	}
	r.Body = http.MaxBytesReader(w, r.Body, 64*1024)
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		web.Fail(w, http.StatusBadRequest, "invalid", "that is not the JSON this route expects")
		return
	}

	if err := h.store.SetNote(r.Context(), school, student, r.PathValue("course"),
		r.PathValue("lesson"), r.PathValue("section"), in.Body); err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]string{"status": "saved"})
}

func (h *Handler) notes(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	notes, err := h.store.Notes(r.Context(), school, student, r.PathValue("course"))
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"notes": notes})
}

func (h *Handler) summary(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	done, err := h.store.Summary(r.Context(), school, student)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"progress": done})
}

func (h *Handler) allNotes(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	notes, err := h.store.AllNotes(r.Context(), school, student)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"notes": notes})
}

// who answers the school and the student, and refuses without either.
//
// THE ACCOUNT IS NEVER TAKEN FROM THE REQUEST. It comes from the session, so
// there is no shape of request that writes somebody else's history — which is
// the kind of hole that is found by a stranger rather than by a test.
func (h *Handler) who(w http.ResponseWriter, r *http.Request) (school, student uuid.UUID, ok bool) {
	school, ok = h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a progress route ran with no school resolved",
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
		// The same 402 the catalogue gives, for the same reason: this is a
		// purchase and not a permission, and a client that could not read the
		// lesson must not be able to mark it done either.
		web.Fail(w, http.StatusPaymentRequired, "locked",
			"this course is not open on the current plan")
	case errors.Is(err, ErrNoSuchSection):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such section in that course")
	default:
		web.LoggerFrom(r.Context()).Error("progress", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that could not be recorded just now")
	}
}
