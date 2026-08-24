package console

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* What students say is wrong with the material, and settling it.

   # THE ONE SCREEN IN THIS CONSOLE WITH SOMEBODY WAITING ON THE OTHER END

   Every other read here answers a question the operator had. This one carries a
   question somebody else had, and the difference shows up in how it is built:
   the queue is oldest-first, because a report that has been waiting three weeks
   is the one that has been failing somebody the longest; and settling one is a
   WRITE, which makes this the third screen with a rank above read-only and an
   audit entry.

   # THE REPORT GOES WHEN THE PERSON DOES, AND THE DECISION DOES NOT

   `content_reports` cascades on erasure, because a note is a sentence somebody
   wrote in their own words. What must survive is the operational fact — this
   section was reported, it was looked at, this is what was found — and that is
   the audit entry, written here, which does not erase (K-01).

   So the order matters and it is the erase path's order, not the convenience
   one: RECORD FIRST, THEN SETTLE. A decision nobody can account for is worse
   than a report nobody closed.

   # IT DOES NOT SHOW WHO REPORTED IT

   K-22 says a person is found by an exact address and never listed, and a queue
   that named its reporters would be a list of people who complain — sortable,
   browsable, and exactly the read an audit cannot tell from working. What the
   screen gets is the report and the section; the account id is on the row for
   the erase path and does not leave this package.
*/

// Report is one open report as the console shows it.
//
// IT CARRIES NO ACCOUNT. Not "carries one and the screen ignores it" — the
// field is not here, so there is nothing for a later handler to start putting
// on an answer.
type Report struct {
	ID uuid.UUID

	// THE COORDINATES AND NOT THE TITLES, which is a decision rather than a
	// gap. Resolving them would be another read, a plan to read it under, and a
	// blank where a course has since been unpublished — all to turn
	// `web-fundamentals` into "Web Fundamentals". The ids are already slugs, and
	// they are what somebody types to find the file this report is about, which
	// is the next thing they do.
	CourseID  string
	LessonID  string
	SectionID string

	Reason string
	Note   string

	// When it was said. The screen turns it into "three days ago", because how
	// long somebody has been waiting is the only thing about this timestamp
	// anybody reads.
	ReportedAt time.Time
}

// Reports is what this package may not import: `report` owns the queue and
// `catalog` owns what the coordinates are called.
type Reports struct {
	// Open is one school's queue, oldest first.
	Open func(ctx context.Context, school uuid.UUID) ([]Report, error)

	// Settle closes one with a verdict, and answers what it was about so the
	// audit entry can name it. It is called AFTER the entry is written.
	Settle func(ctx context.Context, id, by uuid.UUID, verdict string) error

	// About is the report as it stands, read before anything is decided — the
	// audit entry has to name the section rather than a uuid.
	About func(ctx context.Context, id uuid.UUID) (Report, uuid.UUID, error)

	// Verdicts is the closed list, so that the screen offers what the store
	// will accept rather than its own copy of it.
	Verdicts []string

	// Refused is a caller error rather than a broken database, and
	// AlreadySettled is somebody else having got there first.
	Refused        func(error) bool
	AlreadySettled func(error) bool
	NotThere       func(error) bool
}

// ContentHandler answers the reported-content queue.
type ContentHandler struct {
	schools Schools
	reports Reports
	record  Record
	label   Label
	who     func(ctx context.Context) (uuid.UUID, bool)

	// maySettle is the second rank, as setting a colour and viewing a student
	// have one. Read-only opened the door so that a console nobody can look at
	// is not a console nobody checks; answering a student is not a thing a
	// read-only role does.
	maySettle func(ctx context.Context) bool
}

func NewContentHandler(schools Schools, reports Reports, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	maySettle func(ctx context.Context) bool,
) *ContentHandler {
	return &ContentHandler{
		schools: schools, reports: reports, record: record,
		label: label, who: who, maySettle: maySettle,
	}
}

func (h *ContentHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/schools/{id}/reports", h.queue)
	mux.HandleFunc("POST /console/api/v1/reports/{report}/settle", h.settle)
}

// school resolves the id in the path. It is `understand.go`'s `schoolFrom`
// written once more rather than shared, and that is not an oversight: this
// handler is a different type and Go has no free function to inherit. What
// would be shared is four lines and a 404.
func (h *ContentHandler) school(w http.ResponseWriter, r *http.Request) (School, bool) {
	id, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
		return School{}, false
	}

	all, err := h.schools.All(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return School{}, false
	}
	for _, s := range all {
		if s.ID == id {
			return s, true
		}
	}
	web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such school")
	return School{}, false
}

func (h *ContentHandler) queue(w http.ResponseWriter, r *http.Request) {
	school, ok := h.school(w, r)
	if !ok {
		return
	}

	rows, err := h.reports.Open(r.Context(), school.ID)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the reported content",
			"error", err, "school", school.Slug)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]map[string]any, 0, len(rows))
	for _, one := range rows {
		out = append(out, map[string]any{
			"id":          one.ID,
			"course_id":   one.CourseID,
			"lesson_id":   one.LessonID,
			"section_id":  one.SectionID,
			"reason":      one.Reason,
			"note":        one.Note,
			"reported_at": one.ReportedAt,
		})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"school":   map[string]any{"id": school.ID, "name": school.Name, "slug": school.Slug},
		"reports":  out,
		"verdicts": h.reports.Verdicts,

		// WHAT THE QUEUE DOES NOT SAY, said by the thing that decided not to
		// say it. An operator wondering why they cannot see who reported
		// something should find the rule rather than conclude it was forgotten.
		"anonymous": "A report is shown without its reporter. A person is found here by an " +
			"exact address and never listed, and a queue naming who complained is a list " +
			"of people to browse.",
	})
}

type settleBody struct {
	Verdict string `json:"verdict"`
}

func (h *ContentHandler) settle(w http.ResponseWriter, r *http.Request) {
	if !h.maySettle(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"answering a student asks for an operator")
		return
	}

	id, err := uuid.Parse(r.PathValue("report"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such report")
		return
	}

	var in settleBody
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4<<10)).Decode(&in); err != nil {
		web.Fail(w, http.StatusBadRequest, "invalid", "that was not a verdict this understands")
		return
	}

	/* THE VERDICT IS CHECKED BEFORE ANYTHING IS WRITTEN, and that is a
	   correction rather than an extra layer. Recording first is the rule
	   everywhere in this package, and its accepted cost is a line saying
	   somebody did a thing that then failed — cheap, because the alternative is
	   a thing done with nobody accountable for it.

	   A VERDICT THAT IS NOT A WORD IS NOT THAT CASE. It cannot succeed, so
	   recording it first buys nothing and writes "settled as banana" into a
	   history that never erases. The list is on the answer to the screen and is
	   the store's own, so this refuses with the same words the store would. */
	if !known(h.reports.Verdicts, in.Verdict) {
		web.Fail(w, http.StatusBadRequest, "invalid",
			"a report is settled as one of: "+strings.Join(h.reports.Verdicts, ", "))
		return
	}

	/* WHAT IT IS ABOUT, READ FIRST. The audit entry has to name the section
	   rather than a uuid — an entry saying "settled a report" is an entry
	   nobody can use in the conversation it exists for. */
	about, school, err := h.reports.About(r.Context(), id)
	switch {
	case h.reports.NotThere(err):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such report")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading a report", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	actor, ok := h.who(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a console route ran with no account", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}
	name, email, err := h.label(r.Context(), actor)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is acting", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not record that")
		return
	}

	/* RECORDED BEFORE IT IS DONE, and here that is not only the usual rule.
	   The report itself is deleted when the person who wrote it is erased, so
	   the audit entry is the ONLY lasting record that this section was ever
	   complained about — writing it afterwards would mean a settle that failed
	   halfway leaves nothing at all. */
	where := about.CourseID + " · " + about.LessonID + " · " + about.SectionID
	if err := h.record(r.Context(), actor, label(name, email),
		"content.report.settled",
		Subject{Kind: "content", ID: where},
		Changed{Before: "reported as " + about.Reason, After: "settled as " + in.Verdict},
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a settled report", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return
	}

	err = h.reports.Settle(r.Context(), id, actor, in.Verdict)
	switch {
	case h.reports.Refused(err):
		web.Fail(w, http.StatusBadRequest, "invalid", err.Error())
		return
	case h.reports.AlreadySettled(err):
		// Two operators in the queue at once, which is the ordinary way this
		// happens rather than a defect. The first decision stands.
		web.Fail(w, http.StatusConflict, "already_settled",
			"somebody settled that one first — reload the queue")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("settling a report", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the decision was recorded and then could not be applied, which is a defect — "+
				"the history now says something happened that did not")
		return
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"id":      id,
		"verdict": in.Verdict,
		"school":  school,
		"about":   where,
	})
}

// known is the same membership test `report` exports, written here because this
// package may not import it. Four lines duplicated rather than a boundary
// crossed for them.
func known(list []string, word string) bool {
	for _, one := range list {
		if one == word {
			return true
		}
	}
	return false
}
