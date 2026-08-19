package legal

import (
	"errors"
	"net/http"
	"strings"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// The two documents over HTTP.
//
// THEY ARE NOT SCHOOL-SCOPED AND THEY ARE NOT BEHIND A SESSION. A privacy
// policy that only a signed-in student could read would be a privacy policy
// nobody can read before deciding whether to sign up — which is the moment it
// exists for. It is the same document in every school, because there is one
// platform and one company behind it.

type Handler struct{}

func NewHandler() *Handler { return &Handler{} }

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/legal/{document}", h.document)
}

func (h *Handler) document(w http.ResponseWriter, r *http.Request) {
	doc, err := Read(r.PathValue("document"), locale(r))
	if errors.Is(err, ErrNoSuchDocument) {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "there is no such document")
		return
	}
	if err != nil {
		// A document that will not parse is a build-time mistake that reached
		// production: the checker below runs over every one of them in CI, so
		// this is the path that should be unreachable. It says so rather than
		// answering an empty policy.
		web.LoggerFrom(r.Context()).Error("reading a legal document",
			"error", err, "document", r.PathValue("document"))
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}

	web.JSON(w, http.StatusOK, doc)
}

// locale is the same reading as the catalogue's, so a lesson and a policy are
// asked for in the same language by the same query string.
func locale(r *http.Request) string {
	l := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("lang")))
	if l == "" || len(l) > 8 || strings.ContainsAny(l, " /?&") {
		return Fallback
	}
	return l
}
