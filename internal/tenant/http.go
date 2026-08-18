package tenant

import (
	"errors"
	"net/http"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Resolve is the middleware every school-scoped route sits behind.
//
// AN UNKNOWN HOST IS A 404, AND NEVER A DEFAULT SCHOOL. That is the single
// most important line in this package. Falling back to "the first school" or
// "the only school" is the kind of convenience that works perfectly until
// there are two, and then serves one school's catalogue at another's address
// without anything looking wrong — no error, no log, no symptom. The
// correctness of every school-scoped query downstream rests on this refusing.
//
// A lookup that FAILS is a different thing from a host that is unknown, and
// they answer differently: the first is a 503, because the database blinked
// and the address may well be fine. Answering 404 there would tell a student
// their school does not exist because a connection dropped.
func Resolve(store *Store) web.Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			school, err := store.ByHost(r.Context(), r.Host)

			if errors.Is(err, ErrUnknownHost) {
				web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no school answers at this address")
				return
			}
			if err != nil {
				web.LoggerFrom(r.Context()).Error("resolving the school", "error", err, "host", r.Host)
				web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not tell which school this is")
				return
			}

			next.ServeHTTP(w, r.WithContext(with(r.Context(), school)))
		})
	}
}

// Handler serves what a school says about itself. It is the smallest possible
//
// school-scoped route, and it exists as much to prove the resolution end to
// end as to be useful — though it is useful: the app reads its name and its
// accent colour from here before it paints anything.
type Handler struct{}

func NewHandler() *Handler { return &Handler{} }

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/school", h.school)
}

type schoolBody struct {
	Slug   string `json:"slug"`
	Name   string `json:"name"`
	Accent string `json:"accent"`
}

func (h *Handler) school(w http.ResponseWriter, r *http.Request) {
	school, ok := FromContext(r.Context())
	if !ok {
		/* Only reachable by mounting this route outside the middleware, which
		   is a programming mistake rather than a request the client got wrong.
		   It says so instead of pretending. */
		web.LoggerFrom(r.Context()).Error("a school-scoped route ran without a school in the context", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}

	web.JSON(w, http.StatusOK, schoolBody{Slug: school.Slug, Name: school.Name, Accent: school.Accent})
}
