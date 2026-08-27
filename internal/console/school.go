package console

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"regexp"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* A school's own colour, chosen from the console.

   ONE COLOUR IS THE WHOLE OF THE VISUAL DIFFERENCE BETWEEN SCHOOLS. The column
   has said so since the first migration: one design system, one accent, so a
   student knows where they are without the brand fragmenting. What was missing
   was any way to set it — the rows were written by hand, in SQL, against
   production, which is the same power with no gate and no record.

   # IT IS A SETTING AND NOT CONTENT

   `content/<school>/school.json` carried an `accent` field that nothing ever
   read, and that was the right accident to notice: the catalogue is a mirror of
   files and is rewritten by every load, so a colour living there would be undone
   the next time somebody published a course. It is a school's setting, it lives
   on the school's row, and this is the one thing that writes it.

   That field is gone in the same change, because two places claiming to hold one
   value is how the wrong one gets edited.

   # WHAT THE SERVER CAN AND CANNOT CHECK

   It checks that a colour is a colour: six hex digits, which is what the
   interface's own reader accepts and what the column is worth holding.

   It does NOT check contrast, and that is not an omission — the correction is a
   function of the PALETTE, which lives in a stylesheet in a browser, and a
   server measuring it would be a second implementation of the one rule this
   platform has about colour. The screen does that measurement with the study
   interface's own module, shows what each theme will actually use, and says so
   where a colour has to move. An accent that cannot be read is corrected on the
   way to the page rather than rejected here; what nobody may do is set one and
   not be told.

   # AND IT IS AUDITED WITH BOTH VALUES

   A setting changed with no record of what it was before is a change nobody can
   review, which is the roadmap's own wording for the parameters this is the
   first of. The entry carries the colour that was there and the colour that
   replaced it, and it is written FIRST: an accent nobody can account for is
   worse than an accent nobody changed.
*/

// ErrNoSchool is an id that belongs to no school.
var ErrNoSchool = errors.New("console: no school with that id")

// Schools is what this package may not import: `tenant` owns the rows.
type Schools struct {
	// All is every school on the platform, with its colour.
	All func(ctx context.Context) ([]School, error)

	// SetAccent writes one school's colour and answers what was there before.
	//
	// THE BEFORE COMES BACK FROM THE WRITE rather than being read first, so the
	// two cannot disagree: a read, a decision and a write in three steps is a
	// change that records a value somebody else replaced in between.
	SetAccent func(ctx context.Context, id uuid.UUID, accent string) (was string, err error)
}

// SchoolsHandler lists the schools and sets their colours.
type SchoolsHandler struct {
	schools Schools
	record  Record
	label   Label
	who     func(ctx context.Context) (uuid.UUID, bool)

	// maySet is the second rank, as the erase path has one: read-only opened
	// the door, and changing what every student of a school sees is not a thing
	// a read-only role does.
	maySet func(ctx context.Context) bool
}

func NewSchoolsHandler(schools Schools, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	maySet func(ctx context.Context) bool,
) *SchoolsHandler {
	return &SchoolsHandler{schools: schools, record: record, label: label, who: who, maySet: maySet}
}

func (h *SchoolsHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/schools", h.list)
	mux.HandleFunc("PUT /console/api/v1/schools/{id}/accent", h.setAccent)
}

/*
A COLOUR IS SIX HEX DIGITS AND NOTHING ELSE.

	Not three, and not a name. `accent.js` reads exactly this form — a shorthand
	or a keyword reaches it as "not a colour" and the whole correction is skipped,
	which shows up as a school that silently stayed blue. Refusing here is how
	that becomes a sentence somebody reads instead of a colour that did nothing.
*/
var colour = regexp.MustCompile(`^#[0-9a-fA-F]{6}$`)

type schoolBody struct {
	ID     string `json:"id"`
	Slug   string `json:"slug"`
	Name   string `json:"name"`
	Accent string `json:"accent,omitempty"`
}

func bodyOf(s School) schoolBody {
	return schoolBody{
		ID: s.ID.String(), Slug: s.Slug, Name: s.Name, Accent: s.Accent,
	}
}

func (h *SchoolsHandler) list(w http.ResponseWriter, r *http.Request) {
	all, err := h.schools.All(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]schoolBody, 0, len(all))
	for _, s := range all {
		out = append(out, bodyOf(s))
	}
	web.JSON(w, http.StatusOK, map[string]any{
		"schools": out,
		// K-18: this screen is about every school, and a screen that did not say
		// so would be read as being about the one whose name is nearest.
		"scope": "every school",
	})
}

func (h *SchoolsHandler) setAccent(w http.ResponseWriter, r *http.Request) {
	if !h.maySet(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"changing what a school looks like asks for an operator")
		return
	}

	id, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
		return
	}

	var asked struct {
		Accent string `json:"accent"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<10)).Decode(&asked); err != nil {
		web.Fail(w, http.StatusBadRequest, "unreadable", "that is not a request this reads")
		return
	}

	accent := strings.ToLower(strings.TrimSpace(asked.Accent))
	if !colour.MatchString(accent) {
		web.Fail(w, http.StatusBadRequest, "not_a_colour",
			"a colour here is six hex digits after a hash, like #5b8cff — a shorthand or a "+
				"name reaches the interface as no colour at all, and the school stays as it was "+
				"with nothing to say why")
		return
	}

	/* THE SCHOOL IS READ BEFORE ANYTHING IS WRITTEN, so an id that belongs to
	   nobody is a 404 rather than an audit entry about a school that does not
	   exist. */
	all, err := h.schools.All(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}
	var school School
	for _, s := range all {
		if s.ID == id {
			school = s
		}
	}
	if school.ID == uuid.Nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
		return
	}

	// Nothing to record and nothing to write. Answering 200 rather than
	// refusing: pressing save twice is not a mistake, and an entry per press
	// would make the history a log of somebody's clicking.
	if strings.EqualFold(school.Accent, accent) {
		web.JSON(w, http.StatusOK, bodyOf(school))
		return
	}

	actor, label, ok := acting(w, r, h.who, h.label)
	if !ok {
		return
	}

	/* RECORDED BEFORE IT IS DONE, which is the erase path's rule and is here for
	   the same reason: the entry is what makes the change reviewable, and a
	   change that could not be recorded is a change nobody may make. The cost is
	   the other way round — a write that then fails leaves an entry for
	   something that did not happen — and that is why the failure below says so
	   plainly rather than reporting a colour that was not kept. */
	if err := h.record(r.Context(), actor, label,
		"school.accent.changed",
		Subject{Kind: "school", ID: school.ID.String()},
		Changed{Before: colourOrNone(school.Accent), After: accent},
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a colour change", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return
	}

	was, err := h.schools.SetAccent(r.Context(), school.ID, accent)
	switch {
	case errors.Is(err, ErrNoSchool):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("setting a school's accent",
			"error", err, "school", school.Slug)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the change was recorded and then could not be written, which is a defect — "+
				"the history now says something happened that did not")
		return
	}
	if !strings.EqualFold(was, school.Accent) {
		// Somebody else changed it between the read and the write. The entry
		// above names a `before` that was already gone, and that is worth a line
		// in the log rather than silence.
		web.LoggerFrom(r.Context()).Warn("a school's accent moved under a change",
			"school", school.Slug, "recorded_before", school.Accent, "actually_was", was)
	}

	school.Accent = accent
	web.JSON(w, http.StatusOK, bodyOf(school))
}

// colourOrNone is what an entry says about a school that had no colour: the
// word rather than an empty string, so a reader is not left deciding whether
// the value was blank or the field was missing.
func colourOrNone(accent string) string {
	if strings.TrimSpace(accent) == "" {
		return "none — the palette's own"
	}
	return accent
}

// acting is who is making the change, named for the audit.
//
// IT IS A FUNCTION AND NOT A METHOD because two handlers need it and neither
// owns it: the accent is a school's and the price is the platform's, and "who
// is doing this, and what do we call them" is the same question in both. It was
// a method on `SchoolsHandler` while the price lived there, and the copy that
// would otherwise have appeared in `plan.go` is why it moved.
func acting(w http.ResponseWriter, r *http.Request,
	who func(context.Context) (uuid.UUID, bool), label Label) (uuid.UUID, string, bool) {

	actor, ok := who(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a console route ran with no account", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return uuid.Nil, "", false
	}
	name, email, err := label(r.Context(), actor)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is acting", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not record that")
		return uuid.Nil, "", false
	}
	return actor, strings.TrimSpace(name + " <" + email + ">"), true
}

/*
MONEY IN THE AUDIT IS WRITTEN IN CENTS AND SAYS SO.

`4900 BRL cents` rather than `R$ 49,00`. An entry is read a year later by
somebody comparing it against a ledger row, and the ledger is in cents; a
formatted amount would be the one place in this system where money is a decimal
string, and it would be the place somebody reads a comma as a thousands
separator.

No price at all is `none` rather than `0`, because zero is a number somebody
might have chosen and no offer is not.
*/
func money(cents int, currency string) string {
	if cents <= 0 || currency == "" {
		return "none"
	}
	return strconv.Itoa(cents) + " " + currency + " cents"
}
