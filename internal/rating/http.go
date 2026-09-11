package rating

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Who this is and where they are. Both come from the session and the host and
// never from the request, for the reason every student route here does: which
// course is being rated is something a client chooses, whose opinion it is is
// not.
type (
	SchoolOf  func(ctx context.Context) (uuid.UUID, bool)
	StudentOf func(ctx context.Context) (uuid.UUID, bool)
)

// Release is which build of the material this is. A function rather than a
// string so the handler is not holding a copy of something taken at start-up,
// and a dependency rather than an import so a test can be at any release.
type Release func() string

// AskDeeperAt reads the threshold. It is the settings store's, so a value moved
// in the console reaches the next student rather than the next deploy.
type AskDeeperAt func(ctx context.Context) int

type Handler struct {
	store     *Store
	schoolOf  SchoolOf
	studentOf StudentOf
	release   Release
	askDeeper AskDeeperAt
}

func NewHandler(store *Store, schoolOf SchoolOf, studentOf StudentOf,
	release Release, askDeeper AskDeeperAt) *Handler {

	return &Handler{store: store, schoolOf: schoolOf, studentOf: studentOf,
		release: release, askDeeper: askDeeper}
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/ratings", h.give)

	/* THE LIST IS THE STUDENT'S OWN. It exists so a course they have already
	   rated is drawn with their own stars on it rather than as an invitation to
	   rate it again — and so that changing a rating starts from what they said
	   last time instead of from nothing.

	   There is no route here that reads anybody else's, and no route anywhere
	   that answers an average to a student. What a school's students think of a
	   course is the console's, behind the console's two gates: a number on a
	   course card is a recommendation engine, and this is a feedback channel. */
	mux.HandleFunc("GET /api/v1/ratings", h.mine)
}

// The words and the numbers the interface may work with, sent with every
// answer.
//
// A SCREEN THAT HELD ITS OWN COPY would keep offering the old list after an
// aspect was added, and what it then sends is refused. The threshold travels
// for the same reason and one further: it is a parameter an operator can move,
// and an interface with it hard-coded would keep asking the old question after
// somebody decided otherwise.
func (h *Handler) lists(ctx context.Context) map[string]any {
	return map[string]any{
		"kinds":     Kinds,
		"aspects":   Aspects,
		"lowest":    Lowest,
		"highest":   Highest,
		"askDeeper": h.askDeeper(ctx),
	}
}

type givenBody struct {
	Kind      string `json:"kind"`
	SubjectID string `json:"subjectId"`

	Stars int `json:"stars"`

	// A MAP AND NOT FOUR FIELDS. Three answered and one skipped is the ordinary
	// case, and four numbers with a zero in one of them cannot say which.
	Aspects map[string]int `json:"aspects"`
}

func (h *Handler) give(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	var in givenBody
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4<<10)).Decode(&in); err != nil {
		web.Fail(w, http.StatusBadRequest, "invalid", "that was not a rating this understands")
		return
	}

	one, err := h.store.Give(r.Context(), Given{
		School: school, Account: student,
		Kind: in.Kind, SubjectID: in.SubjectID,
		Stars: in.Stars, Aspects: in.Aspects,

		// NEVER FROM THE BODY. The column exists to compare releases, and a
		// release a browser named is the release of whatever tab was left open.
		Version: h.release(),
	})
	switch {
	case errors.Is(err, ErrNoSuchSubject):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "there is no such course or track here")
		return
	case errors.Is(err, ErrRefused):
		web.Fail(w, http.StatusBadRequest, "invalid", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("recording a rating", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded — please try again")
		return
	}

	web.JSON(w, http.StatusOK, said(one))
}

func (h *Handler) mine(w http.ResponseWriter, r *http.Request) {
	school, student, ok := h.who(w, r)
	if !ok {
		return
	}

	rows, err := h.store.Mine(r.Context(), school, student)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a student's ratings", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]map[string]any, 0, len(rows))
	for _, one := range rows {
		out = append(out, said(one))
	}

	answer := h.lists(r.Context())
	answer["ratings"] = out
	web.JSON(w, http.StatusOK, answer)
}

// One rating, as the interface reads it.
//
// THE RELEASE IS NOT IN IT. It is the console's column and says nothing to the
// person who gave the rating — and a version number on a student's screen is a
// question they then have to have an opinion about.
func said(one Rating) map[string]any {
	aspects := one.Aspects
	if aspects == nil {
		aspects = map[string]int{}
	}
	return map[string]any{
		"kind":      one.Kind,
		"subjectId": one.SubjectID,
		"stars":     one.Stars,
		"aspects":   aspects,
		"at":        one.RatedAt,
		"changed":   one.ChangedAt != nil,
	}
}

func (h *Handler) who(w http.ResponseWriter, r *http.Request) (school, student uuid.UUID, ok bool) {
	school, ok = h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a rating route ran with no school resolved",
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
