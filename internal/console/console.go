// Package console is the staff side of the platform, and it is one console for
// every school (K-17).
//
// # WHY IT IS NOT UNDER A SCHOOL
//
// A school is resolved by `Host` and everything under it belongs to that
// school. The console operates ACROSS schools — an account has no `tenant_id`
// at all (N-01), so a person exists platform-wide and exporting or erasing one
// crosses every school they ever touched. Mounted under a school's address, it
// would be either a console that sees one school or a school address that
// reaches another school's data. Neither is a thing to build.
//
// So it answers on its own host, and the rule that host obeys is written as
// three cases so that nobody has to infer the third:
//
//	a host is a school's, or the console's, or a 404
//
// # TWO GATES, AND THEY FAIL DIFFERENTLY (K-19)
//
// The host has to be the console's AND the session has to carry a staff role
// with a second factor already shown. Either alone is one mistake away from a
// hole, and they are not the same kind of mistake: a misconfigured host is a
// deployment error and a missing role check is a code error. A system that
// needs both to be wrong survives one of them.
//
// The second gate is `identity.RequireStaff`, which already existed and had
// never been mounted on anything.
//
// # THIS PACKAGE IMPORTS NO OTHER MODULE
//
// It reads accounts, the audit and the privacy registry, and it may import
// none of them — `internal/architecture_test.go` enforces that. So it declares
// the shapes it needs and `cmd/api` says who provides them, which is the same
// wiring `visitor.SchoolOf` uses. `K-07` wants a layer between the console and
// its data anyway, and this is where that layer starts.
package console

import (
	"context"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Settings are what the console cannot work out for itself.
type Settings struct {
	// Host is the address the console answers at, already normalised —
	// lowercase, no port. `cmd/api` derives it from the platform domain, so it
	// is not a second place the domain is written down.
	Host string
}

// Label is a person's name for the audit, and their role for the screen.
//
// IT IS A FUNCTION AND NOT AN IMPORT, like everything else this package needs.
// The console has to record WHO did a thing, and a uuid a year later is not an
// answer — `audit_log.actor_label` exists for exactly that reason and this is
// what fills it.
type Label func(ctx context.Context, accountID uuid.UUID) (name, email string, err error)

// Handler is the console's routes. It holds no store: every read it will grow
// arrives as a function the wiring provides.
type Handler struct {
	label Label
	who   func(ctx context.Context) (uuid.UUID, bool)
	role  func(ctx context.Context) (string, bool)
}

func NewHandler(
	label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	role func(ctx context.Context) (string, bool),
) *Handler {
	return &Handler{label: label, who: who, role: role}
}

// Routes are mounted BEHIND the two gates, never beside them. Registering one
// here does not make it reachable — `cmd/api` chains the host check and
// `RequireStaff` around the whole mux, so a route added without a thought is
// still a route nobody can reach without a role.
func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/me", h.me)
}

type meBody struct {
	Name  string `json:"name"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

// me answers who is holding the door open.
//
// It is the smallest route the console can have and it exists to prove the
// whole chain end to end: the host was the console's, the session was real, the
// role was live, and the second factor had been shown. Everything else the
// console will ever do sits behind exactly those four facts.
func (h *Handler) me(w http.ResponseWriter, r *http.Request) {
	account, ok := h.who(r.Context())
	if !ok {
		// Unreachable behind the gates, which is why it says so rather than
		// inventing an answer: getting here means the chain was assembled wrong.
		web.LoggerFrom(r.Context()).Error("a console route ran with no account", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}

	role, _ := h.role(r.Context())

	name, email, err := h.label(r.Context(), account)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is signed in", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read your account")
		return
	}

	web.JSON(w, http.StatusOK, meBody{Name: name, Email: email, Role: role})
}

/* ---------- the host ---------- */

// Is answers whether this request arrived at the console's address.
//
// THE SAME NORMALISATION AS A SCHOOL'S, and that is the point rather than a
// convenience: two rules for reading a `Host` header is two chances to disagree
// about `CONSOLE.example.tld:8080`, and the disagreement would be a request
// that is neither a school's nor the console's — the fourth case the design
// says does not exist.
//
// It takes the normaliser as an argument for the same reason everything else
// here does: this package may not import `tenant`.
func Is(settings Settings, normalise func(string) string) func(*http.Request) bool {
	host := normalise(settings.Host)
	return func(r *http.Request) bool {
		return host != "" && normalise(r.Host) == host
	}
}

// HostOf builds the console's address from the platform's.
//
// ONE PLACE THE DOMAIN IS WRITTEN, which is what `config.PlatformDomain`'s own
// comment asks for. A second environment variable for the console's host would
// be a second thing to get wrong on a day somebody moves the platform, and the
// two would be discovered to disagree by a 404 nobody could explain.
func HostOf(platformDomain string) string {
	domain := strings.ToLower(strings.TrimSpace(platformDomain))
	if domain == "" {
		return ""
	}
	return "console." + domain
}
