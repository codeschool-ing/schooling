package certificate

import (
	"context"
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Certificates over HTTP, in two halves that could not be more different.
//
// The student's half needs a session, like everything else they own. THE
// VERIFICATION HALF NEEDS NOTHING AT ALL — no account, no cookie, no referrer.
// Somebody hiring reads a code off a document and types it in, and asking them
// to sign up first would make the certificate worthless.
type (
	// SchoolOf answers the school and its name, which is captured onto a
	// certificate at the moment it is issued.
	SchoolOf  func(ctx context.Context) (id uuid.UUID, name string, ok bool)
	StudentOf func(ctx context.Context) (uuid.UUID, bool)
)

type Handler struct {
	store     *Store
	schoolOf  SchoolOf
	studentOf StudentOf
}

func NewHandler(store *Store, schoolOf SchoolOf, studentOf StudentOf) *Handler {
	return &Handler{store: store, schoolOf: schoolOf, studentOf: studentOf}
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/certificates", h.mine)

	// The scope is in the path and there are two paths rather than one
	// `{scope}` wildcard, for the reason exams give: a closed set of two
	// belongs in the router.
	mux.HandleFunc("POST /api/v1/certificates/course/{id}", h.claim(ScopeCourse))
	mux.HandleFunc("POST /api/v1/certificates/track/{id}", h.claim(ScopeTrack))

	// THE PUBLIC ONE. No session is read on this route, and none is required.
	mux.HandleFunc("GET /api/v1/verify/{code}", h.verify)
}

func (h *Handler) mine(w http.ResponseWriter, r *http.Request) {
	school, _, student, ok := h.who(w, r)
	if !ok {
		return
	}

	held, err := h.store.All(r.Context(), school, student)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]any{"certificates": held})
}

// claim issues a certificate for an exam already passed.
//
// IT EXISTS BECAUSE OF THE NAME. Handing in a passing paper issues the
// certificate on the spot, but a student who has not told us their name cannot
// have one — a document with no name on it asserts nothing. The pass stands, so
// this is how they collect it afterwards, and it is also what makes issuing
// testable without sitting an exam through the API.
func (h *Handler) claim(scope Scope) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		school, schoolName, student, ok := h.who(w, r)
		if !ok {
			return
		}

		issued, err := h.store.Issue(r.Context(), school, student, schoolName, scope, r.PathValue("id"))
		if err != nil {
			h.refuse(w, r, err)
			return
		}
		web.JSON(w, http.StatusOK, map[string]any{"certificate": issued})
	}
}

// verify is the public page's half.
//
// IT ANSWERS THE SAME WAY FOR A CODE THAT NEVER EXISTED AND ONE THAT HAS BEEN
// ERASED. Distinguishing them would say that a certificate had once been
// there — which is exactly the fact an erasure removes.
func (h *Handler) verify(w http.ResponseWriter, r *http.Request) {
	school, _, ok := h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a verification ran with no school resolved",
			"path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}

	found, err := h.store.Verify(r.Context(), school, r.PathValue("code"))
	if errors.Is(err, ErrNotFound) {
		// Not an error page. Somebody typed a code and the answer is that it
		// does not certify anything — which is a result, and the one an employer
		// checking a false claim needs to see plainly.
		web.JSON(w, http.StatusNotFound, map[string]any{"valid": false})
		return
	}
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"valid":       true,
		"certificate": found,
		// Printed the way it appears on the document, so the reader can see at a
		// glance that they are looking at the same code they typed.
		"code_as_printed": Grouped(found.Code),
	})
}

func (h *Handler) who(w http.ResponseWriter, r *http.Request) (
	school uuid.UUID, schoolName string, student uuid.UUID, ok bool) {

	school, schoolName, ok = h.schoolOf(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a certificate route ran with no school resolved",
			"path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return uuid.Nil, "", uuid.Nil, false
	}

	student, ok = h.studentOf(r.Context())
	if !ok {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return uuid.Nil, "", uuid.Nil, false
	}
	return school, schoolName, student, true
}

func (h *Handler) refuse(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, ErrNotPassed):
		web.Fail(w, http.StatusForbidden, "not-passed",
			"that exam has not been passed")
	case errors.Is(err, ErrNoName):
		// 409 and a message that says what to do. The pass is not in question;
		// what is missing is what to write on the document.
		web.Fail(w, http.StatusConflict, "no-name",
			"a certificate carries a name — add yours and ask again")
	case errors.Is(err, ErrNotFound):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such certificate")
	default:
		web.LoggerFrom(r.Context()).Error("certificate", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that could not be done just now")
	}
}
