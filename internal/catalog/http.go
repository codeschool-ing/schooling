package catalog

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// The catalogue over HTTP.
//
// SchoolOf and PlanOf are functions rather than imports, for the reason the
// module graph exists: this package may not reach into the one that resolves
// schools, nor into the one that will decide what somebody is paying for.
// `cmd/api` knows about all three and joins them.
type (
	SchoolOf func(ctx context.Context) (uuid.UUID, bool)
	PlanOf   func(ctx context.Context) Plan

	// Emit counts something a visitor did. A callback for the same reason the
	// other two are, and nil-able: the catalogue answers just as well with
	// nobody counting, and a reader must never fail because a report cannot be
	// written.
	Emit func(ctx context.Context, name string, payload map[string]any)
)

type Handler struct {
	store    *Store
	schoolOf SchoolOf
	planOf   PlanOf
	emit     Emit
}

func NewHandler(store *Store, schoolOf SchoolOf, planOf PlanOf, emit Emit) *Handler {
	return &Handler{store: store, schoolOf: schoolOf, planOf: planOf, emit: emit}
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/courses", h.courses)

	// The shape of every course at once — lessons and sections, no prose. What
	// a rail is drawn from; see Store.Structure for why it is one read.
	mux.HandleFunc("GET /api/v1/lessons", h.structure)
	mux.HandleFunc("GET /api/v1/courses/{course}", h.course)
	mux.HandleFunc("GET /api/v1/courses/{course}/lessons/{lesson}", h.lesson)
	mux.HandleFunc("GET /api/v1/courses/{course}/images/{name}", h.picture)
	mux.HandleFunc("GET /api/v1/tracks", h.tracks)
	mux.HandleFunc("GET /api/v1/tracks/{track}", h.track)
}

func (h *Handler) courses(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	listing, err := h.store.Courses(r.Context(), school, h.plan(r))
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	if listing == nil {
		listing = []Listing{}
	}
	web.JSON(w, http.StatusOK, map[string]any{"courses": listing})
}

func (h *Handler) structure(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	// IN A LANGUAGE, like the lesson beside it. The shape carries the section
	// TITLES, and a title is a translated string here — the school's own rows,
	// not a dictionary shipped with the interface. Answering it in English only
	// would put "Introduction" on a Portuguese dashboard.
	shape, err := h.store.Structure(r.Context(), school, locale(r))
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"lessons": shape})
}

func (h *Handler) course(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	course, err := h.store.Course(r.Context(), school, r.PathValue("course"), h.plan(r))
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, course)
}

func (h *Handler) lesson(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	lesson, err := h.store.Lesson(r.Context(), school,
		r.PathValue("course"), r.PathValue("lesson"), locale(r), h.plan(r))
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, lesson)
}

// picture serves a course's image.
//
// IT IS THE ONE ENDPOINT HERE THAT DOES NOT ANSWER JSON, and everything odd
// about it follows from that. The bytes go out with the type the load job
// recorded rather than a sniffed one, `nosniff` so a browser cannot be talked
// into treating an SVG as a document, and a content policy of nothing at all so
// that even if one were opened directly it could reach for no script, no font
// and no other origin.
//
// The store decides whether it may be read, by asking for the course — see
// `Store.Picture`. A locked course's diagram is as locked as its words.
func (h *Handler) picture(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	kind, body, err := h.store.Picture(r.Context(), school,
		r.PathValue("course"), r.PathValue("name"), h.plan(r))
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	w.Header().Set("Content-Type", kind)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Content-Security-Policy", "default-src 'none'; sandbox")
	/* The catalogue changes when the load job runs, which is a deploy. Ten
	   minutes is short enough that a corrected diagram reaches a student the
	   same morning and long enough that a lesson full of them is not refetched
	   on every visit. */
	w.Header().Set("Cache-Control", "private, max-age=600")
	_, _ = w.Write(body)
}

func (h *Handler) tracks(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	tracks, err := h.store.Tracks(r.Context(), school)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	if tracks == nil {
		tracks = []TrackView{}
	}
	web.JSON(w, http.StatusOK, map[string]any{"tracks": tracks})
}

func (h *Handler) track(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	track, err := h.store.Track(r.Context(), school, r.PathValue("track"))
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	// "CHOSE A TRACK" IS A STEP OF THE FUNNEL AND NOBODY CLICKS IT. There is no
	// enrolment here — a student does not sign up to a track, they open one and
	// start reading — so the honest signal is that they looked at it. The
	// funnel takes the first per person.
	//
	// It is emitted AFTER the read succeeded, so a track that does not exist
	// does not count as one somebody chose.
	if h.emit != nil {
		h.emit(r.Context(), "track.opened", map[string]any{"track": track.ID})
	}

	web.JSON(w, http.StatusOK, track)
}

// school answers which school this request is for, or refuses.
//
// A ROUTE THAT REACHES HERE WITHOUT ONE IS MOUNTED IN THE WRONG PLACE. Every
// catalogue route sits behind the tenant middleware, so the absence is a
// programming mistake rather than a request somebody made — and answering with
// an empty catalogue would hide it behind a screen that merely looks bare.
func (h *Handler) school(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, ok := h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a catalogue route ran with no school resolved",
			"path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return uuid.Nil, false
	}
	return id, true
}

// plan answers what this request is paying for, and defaults CLOSED.
func (h *Handler) plan(r *http.Request) Plan {
	if h.planOf == nil {
		return PlanNone
	}
	return h.planOf(r.Context())
}

// refuse maps the store's answers onto statuses.
//
// AN UNREADABLE CATALOGUE REFUSES; IT DOES NOT ANSWER EMPTY. A 200 with no
// courses is indistinguishable from a school that has none — so a database that
// is down would look like a catalogue that was deleted, on every screen, with
// nothing in the logs that a student could quote.
func (h *Handler) refuse(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such thing in this school")
	case errors.Is(err, ErrLocked):
		// 402 rather than 403: this is not a permission, it is a purchase, and
		// the client shows a different screen for each.
		web.Fail(w, http.StatusPaymentRequired, "locked",
			"this course is not open on the current plan")
	default:
		web.LoggerFrom(r.Context()).Error("reading the catalogue", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
	}
}

// locale takes the language off the query string, falling back to English.
//
// A QUERY PARAMETER AND NOT Accept-Language. The language a student chose is a
// setting they can change, not a property of the browser they happen to be
// using — and a page that reads differently depending on which machine opened
// it is the kind of thing nobody reports because nobody believes it.
func locale(r *http.Request) string {
	l := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("lang")))
	if l == "" || len(l) > 8 || strings.ContainsAny(l, " /?&") {
		return "en"
	}
	return l
}
