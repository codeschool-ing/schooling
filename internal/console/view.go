package console

import (
	"context"
	"net/http"
	"net/url"
	"strings"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* Seeing what a student sees, started from here.

   # THE MOST USEFUL SUPPORT TOOL AND THE MOST CLASSIC BREACH VECTOR (K-02)

   Somebody writes in saying a course will not open. Every other answer to that
   is a guess: their progress rows look fine, their subscription looks fine, and
   what they are describing is a screen. This is the tool that ends the guessing,
   and it is also the one that, unrestrained, is an operator reading anybody's
   work whenever they like.

   So it ships with three restraints or it does not ship: AUDITED, TIME-LIMITED,
   VISIBLE BANNER. This file is the first; `identity` holds the second; the
   student interface draws the third from what `/api/v1/me` says.

   # AND A FOURTH: IT CANNOT WRITE

   `identity.RefuseWrites` refuses a viewing session anything but a GET. That is
   not in K-02 and it should be: an operator who can answer an exam question as a
   student can forge a pass, and an audit trail explains that afterwards rather
   than preventing it.

   # THE ENTRY IS WRITTEN BEFORE THE VIEWING EXISTS

   Same rule as the erase path and the accent: a viewing nobody can account for
   is worse than a viewing nobody started. If the audit cannot be written, this
   refuses — and the cost of the other order, an entry for a viewing that then
   failed to start, is a line saying somebody looked when they did not, which is
   the direction that costs nothing.

   # IT NAMES THE SCHOOL, IN THE ENTRY AND IN THE LINK

   The console crosses schools and a student's screens are served on one. An
   entry saying only "viewed Ada Lovelace" is ambiguous with two tabs open, and
   the value of this record shows up in the conversation that begins "why did you
   open that person's account" — where a screenshot and a log line telling the
   same story is an answer, and two partial versions is an argument.
*/

// Viewings is what this package may not import: `identity` owns sessions and
// `tenant` owns which address a school answers at.
type Viewings struct {
	// Start mints a viewing of one student on one school and answers the token
	// that begins it. It does not audit — this package does that, first.
	Start func(ctx context.Context, operator, student, school uuid.UUID) (string, error)

	// HostOf is where the link points.
	HostOf func(ctx context.Context, school uuid.UUID) (string, error)
}

// ViewHandler starts a viewing.
type ViewHandler struct {
	viewings Viewings
	schools  Schools
	record   Record
	label    Label
	who      func(ctx context.Context) (uuid.UUID, bool)

	// mayView is the second rank, as setting a colour has one. Read-only opened
	// the console door so that a console nobody can look at is not a console
	// nobody checks; reading one student's screens is not a thing a read-only
	// role does.
	mayView func(ctx context.Context) bool
}

func NewViewHandler(viewings Viewings, schools Schools, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	mayView func(ctx context.Context) bool,
) *ViewHandler {
	return &ViewHandler{
		viewings: viewings, schools: schools, record: record,
		label: label, who: who, mayView: mayView,
	}
}

func (h *ViewHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /console/api/v1/students/{id}/view/{school}", h.start)
}

func (h *ViewHandler) start(w http.ResponseWriter, r *http.Request) {
	if !h.mayView(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"reading a student's own screens asks for an operator")
		return
	}

	student, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such student")
		return
	}
	/* THE SCHOOL ARRIVES AS A SLUG AND NOT AS AN ID, because the screen that
	   offers this is the student record — and what that screen holds per school
	   is the slug, which is also what a person would type. Resolving it here
	   costs the read this handler already does. */
	slug := r.PathValue("school")

	/* AND IT IS RESOLVED FIRST, so a name belonging to nobody is a 404 rather
	   than an audit entry about a school that does not exist. */
	all, err := h.schools.All(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}
	var school School
	for _, s := range all {
		if s.Slug == slug && slug != "" {
			school = s
		}
	}
	if school.ID == uuid.Nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
		return
	}

	host, err := h.viewings.HostOf(r.Context(), school.ID)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a school's address",
			"error", err, "school", school.Slug)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that school has no address to send you to")
		return
	}

	actor, ok := h.who(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a console route ran with no account", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}
	if actor == student {
		web.Fail(w, http.StatusBadRequest, "not_somebody_else",
			"that is your own account — there is nothing to view")
		return
	}
	name, email, err := h.label(r.Context(), actor)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is acting", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not record that")
		return
	}

	/* RECORDED BEFORE IT IS DONE. A viewing nobody can account for is worse than
	   a viewing nobody started, so a failure to record is a refusal to start. */
	if err := h.record(r.Context(), actor, label(name, email),
		"student.viewed",
		Subject{Kind: "account", ID: student.String()},
		Changed{After: "started viewing this student's screens on " + school.Slug},
		// K-02 asks for the record and not for an essay. What a viewing is for
		// is in the ticket that prompted it, which lives outside this system.
		"",
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a viewing", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return
	}

	token, err := h.viewings.Start(r.Context(), actor, student, school.ID)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("starting a viewing",
			"error", err, "school", school.Slug)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the viewing was recorded and then could not be started, which is a defect — "+
				"the history now says something happened that did not")
		return
	}

	/* THE LINK IS THE ANSWER, and it is not followed here.

	   The console cannot set a cookie for a school's host, so the operator's
	   browser has to make the request itself. The token is in the URL for exactly
	   one hop and is spent on arrival — see `identity.RedeemViewing`. */
	web.JSON(w, http.StatusOK, map[string]any{
		"link":    schemeOf(r) + "://" + host + "/view?t=" + url.QueryEscape(token),
		"school":  school.Name,
		"host":    host,
		"student": student.String(),

		// WHAT THE OPERATOR IS ABOUT TO BE ABLE TO DO, said before they do it.
		// A control whose limits are discovered by clicking is a control people
		// report as broken.
		"reads_only": true,
		"note": "You will see this student's screens and cannot change anything on them. " +
			"The link works once and lasts seconds; the viewing itself ends after half an " +
			"hour, or when you press stop. They are not signed out and are not told.",
	})
}

// label is how an actor is written into the log: a name and an address, because
// a uuid a year later is not an answer.
func label(name, email string) string {
	if name == "" {
		return "<" + email + ">"
	}
	return name + " <" + email + ">"
}

// schemeOf is how the operator reached the console, which is how they will reach
// the school.
//
// IT IS NOT HARD-CODED TO `https`, and the first version of this was. In
// production it would have been right and nowhere else: the local stack is
// `docker compose` over plain http, and a link that insisted on TLS would be a
// feature that works only where nobody develops it.
//
// `X-Forwarded-Proto` FIRST BECAUSE THE SERVER IS BEHIND SOMETHING. Cloud Run
// terminates TLS and hands this process a plain request, so `r.TLS` is nil on
// every production request there is — reading it alone would get this exactly
// backwards.
func schemeOf(r *http.Request) string {
	if said := r.Header.Get("X-Forwarded-Proto"); said != "" {
		if i := strings.IndexByte(said, ','); i >= 0 {
			said = said[:i] // a chain of proxies; the first is the client's
		}
		if s := strings.TrimSpace(said); s == "http" || s == "https" {
			return s
		}
	}
	if r.TLS != nil {
		return "https"
	}
	return "http"
}
