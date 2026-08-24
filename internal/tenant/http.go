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
// school-scoped route, and it exists as much to prove the resolution end to
// end as to be useful — though it is useful: the app reads its name, its accent
// colour, its own address and what a subscription costs from here before it
// paints anything.
type Handler struct {
	// passMark is the share of an exam a student has to reach, in whole percent.
	//
	// IT IS HANDED IN RATHER THAN IMPORTED, because `exam` owns it and a module
	// may not import another module (X-02). `cmd/api` is the one line that says
	// the two are the same number.
	//
	// WHY A SCHOOL SAYS IT AT ALL. The interface prints "minimum to pass" on a
	// course card, before any exam has been started and so before any paper
	// exists to carry it. Until this field, it printed a `PASS_MARK = 70` of its
	// own — two copies of one decision, where moving the constant marks the exam
	// at the new number and describes it as the old one.
	passMark int
}

func NewHandler(passMark int) *Handler { return &Handler{passMark: passMark} }

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/school", h.school)
}

type schoolBody struct {
	Slug   string `json:"slug"`
	Name   string `json:"name"`
	Accent string `json:"accent"`
	// Absent rather than empty: the interface draws the link only when there
	// is one, and `omitempty` is that rule said once instead of on both sides.
	Site string `json:"site,omitempty"`

	// What the subscription costs here. `omitempty` again, and for the same
	// reason: a school with no price set says nothing about one rather than
	// offering zero.
	PlanPriceCents int    `json:"planPriceCents,omitempty"`
	PlanCurrency   string `json:"planCurrency,omitempty"`

	// What an exam has to reach here, in whole percent. NOT `omitempty`: zero is
	// not a pass mark anybody set, and a screen that read a missing field as
	// "no minimum" would say an exam is passed by answering nothing.
	PassMark int `json:"passMark"`
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

	cents, currency := school.Price()
	web.JSON(w, http.StatusOK, schoolBody{
		Slug: school.Slug, Name: school.Name, Accent: school.Accent, Site: school.Site,
		PlanPriceCents: cents, PlanCurrency: currency,
		PassMark: h.passMark,
	})
}
