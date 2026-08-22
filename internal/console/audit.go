package console

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* The history, read back.

   EVERY ADMINISTRATIVE WRITE HAS RECORDED ITS ACTOR SINCE PHASE 0 (K-01), and
   until this screen the only way to read one was a SQL client against
   production. That is the same gap the personal-data screen closed for the
   export and the erasure, left open on the other side: the console can write
   the history and could not show it.

   IT IS THE READ THAT MAKES THE OTHER SCREEN SAFE TO USE. An operator who can
   erase somebody, and nobody who can see that they did, is one half of an
   arrangement. The entry is written before the action; this is where it is
   answered.

   # THIS SCREEN IS NOT AUDITED, AND THAT IS A DECISION

   Reading the audit does not write to it. An audit of the audit is a table that
   grows with every glance at it, whose own entries are the least interesting
   rows in the system, and whose first question — who read the log of who read
   the log — has no bottom. What protects this read is the door: a live staff
   role and a second factor already shown.

   The one thing that IS still recorded is the export of a person, because that
   read leaves the system. Reading an entry on a screen does not. */

// ErrNoEntry is an id that is not in the history.
var ErrNoEntry = errors.New("console: no such entry")

// ErrRefused is a query this screen will not ask the database for. It is
// separate from "nothing found" because the two mean opposite things to whoever
// typed it: one is an answer and the other is a sentence about the question.
var ErrRefused = errors.New("console: that is not a question this screen asks")

// Deed is one entry as a console screen needs it.
//
// Before and After are empty on a list and filled on one entry: see `History`.
type Deed struct {
	ID         int64
	OccurredAt time.Time

	ActorID    uuid.UUID
	ActorKind  string
	ActorLabel string

	Action      string
	SubjectKind string
	SubjectID   string

	// Absent for a platform-wide action, which is a real thing an owner does
	// and not a missing field.
	TenantID *uuid.UUID

	Reason    string
	RequestID string

	Before json.RawMessage
	After  json.RawMessage
}

// Ask is one page of history, in the shapes an index already sorts (K-21).
type Ask struct {
	ActorID     *uuid.UUID
	SubjectKind string
	SubjectID   string

	// AfterTime and AfterID are the last row of the previous page. Paging by
	// the row rather than by an offset is what stops an entry written between
	// two pages from shifting every row after it.
	AfterTime *time.Time
	AfterID   int64

	Limit int
}

// History is what this package may not import.
//
// `audit` owns the table; a console that imported it would be the module
// boundary broken by the package with the best excuse, exactly as `People`
// would have been. So it names two shapes and `cmd/api` says who provides them.
type History struct {
	// Page answers newest first, WITHOUT `before` and `after`.
	Page func(ctx context.Context, ask Ask) ([]Deed, error)

	// One answers a single entry, with them.
	One func(ctx context.Context, id int64) (Deed, error)
}

// HistoryHandler is the list and the entry.
type HistoryHandler struct{ history History }

func NewHistoryHandler(history History) *HistoryHandler {
	return &HistoryHandler{history: history}
}

func (h *HistoryHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/audit", h.page)
	mux.HandleFunc("GET /console/api/v1/audit/{id}", h.one)
}

// pageSize is what one screen asks for. It is smaller than the store's cap
// because a page is a thing somebody reads, not a thing somebody scrolls past.
const pageSize = 50

type deedBody struct {
	ID         int64     `json:"id"`
	OccurredAt time.Time `json:"occurredAt"`

	Actor     string `json:"actor"`
	ActorID   string `json:"actorId"`
	ActorKind string `json:"actorKind"`
	Action    string `json:"action"`
	Subject   string `json:"subject"`
	SubjectID string `json:"subjectId"`
	School    string `json:"school,omitempty"`
	Reason    string `json:"reason,omitempty"`
	RequestID string `json:"requestId,omitempty"`

	Before json.RawMessage `json:"before,omitempty"`
	After  json.RawMessage `json:"after,omitempty"`
}

type pageBody struct {
	Entries []deedBody `json:"entries"`

	// The marker for the page after this one, absent when this was the last.
	// The screen sends it back untouched as `?after=`, which is the only thing
	// it needs to know about paging.
	Next string `json:"next,omitempty"`

	// What this page was narrowed to, echoed back so a screen can say it
	// (K-18). A page that does not state its scope is a page whose reader
	// supplies one.
	Scope string `json:"scope"`
}

// page is the list, and the query string is the whole of what it accepts.
//
// THE REFUSAL IS PART OF THE SCREEN. `?q=` — free text through `before` and
// `after` — is the query somebody will reach for first, and it is a sequential
// scan of a table that only grows. Answering it slowly today and unusably in a
// year is worse than refusing it now with a sentence that says which questions
// this screen does ask.
func (h *HistoryHandler) page(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()

	for _, unasked := range []string{"q", "search", "action", "from", "to"} {
		if q.Has(unasked) {
			web.Fail(w, http.StatusBadRequest, web.CodeNotFound,
				"this screen asks three questions — everything newest first, one "+
					"actor's entries, or everything done to one subject. Anything else "+
					"has no index behind it and would read the whole table.")
			return
		}
	}

	ask := Ask{Limit: pageSize}

	if raw := strings.TrimSpace(q.Get("actor")); raw != "" {
		id, err := uuid.Parse(raw)
		if err != nil {
			web.Fail(w, http.StatusBadRequest, web.CodeNotFound, "that is not an actor's id")
			return
		}
		ask.ActorID = &id
	}

	ask.SubjectKind = strings.TrimSpace(q.Get("subjectKind"))
	ask.SubjectID = strings.TrimSpace(q.Get("subject"))
	if (ask.SubjectKind == "") != (ask.SubjectID == "") {
		web.Fail(w, http.StatusBadRequest, web.CodeNotFound,
			"a subject is a kind and an id — the index leads with the kind, so an id "+
				"on its own would read the whole table")
		return
	}

	if raw := strings.TrimSpace(q.Get("after")); raw != "" {
		at, id, err := decodeCursor(raw)
		if err != nil {
			web.Fail(w, http.StatusBadRequest, web.CodeNotFound, "that is not a page marker")
			return
		}
		ask.AfterTime, ask.AfterID = &at, id
	}

	deeds, err := h.history.Page(r.Context(), ask)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the history", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	body := pageBody{Entries: make([]deedBody, 0, len(deeds)), Scope: scopeOf(ask)}
	for _, d := range deeds {
		body.Entries = append(body.Entries, shown(d))
	}

	/* A FULL PAGE OFFERS ANOTHER AND DOES NOT PROMISE ONE. Asking the database
	   whether a further row exists costs a second query on every page to save a
	   reader one empty one, and an empty page is a sentence rather than a
	   failure. */
	if len(deeds) == pageSize {
		last := deeds[len(deeds)-1]
		body.Next = encodeCursor(last.OccurredAt, last.ID)
	}

	web.JSON(w, http.StatusOK, body)
}

// one is the whole entry, and the only place `before` and `after` are served.
func (h *HistoryHandler) one(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(r.PathValue("id"), 10, 64)
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such entry")
		return
	}

	deed, err := h.history.One(r.Context(), id)
	switch {
	case errors.Is(err, ErrNoEntry):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such entry")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading an entry", "error", err, "entry", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	body := shown(deed)
	body.Before, body.After = deed.Before, deed.After
	web.JSON(w, http.StatusOK, body)
}

func shown(d Deed) deedBody {
	body := deedBody{
		ID: d.ID, OccurredAt: d.OccurredAt,
		Actor: d.ActorLabel, ActorID: d.ActorID.String(), ActorKind: d.ActorKind,
		Action: d.Action, Subject: d.SubjectKind, SubjectID: d.SubjectID,
		Reason: d.Reason, RequestID: d.RequestID,
	}
	if d.TenantID != nil {
		body.School = d.TenantID.String()
	}
	return body
}

// scopeOf says in words what the page was narrowed to, for a screen to print.
//
// IT IS BUILT HERE AND NOT ON THE SCREEN because the scope is a property of the
// query that ran, and a sentence assembled from the address bar is a sentence
// that can disagree with the rows underneath it.
func scopeOf(ask Ask) string {
	switch {
	case ask.ActorID != nil:
		return "one actor, every school"
	case ask.SubjectKind != "":
		return "one " + ask.SubjectKind + ", every school"
	default:
		return "every action, every school"
	}
}

/* The cursor is the row, printed. `<unix nanoseconds>.<id>` — not opaque,
   because an opaque cursor here would be encoding two numbers that are already
   in the response and calling it a secret. It is validated on the way back in
   like any other parameter. */

func encodeCursor(at time.Time, id int64) string {
	return strconv.FormatInt(at.UnixNano(), 10) + "." + strconv.FormatInt(id, 10)
}

func decodeCursor(raw string) (time.Time, int64, error) {
	at, id, ok := strings.Cut(raw, ".")
	if !ok {
		return time.Time{}, 0, ErrRefused
	}
	nanos, err := strconv.ParseInt(at, 10, 64)
	if err != nil {
		return time.Time{}, 0, ErrRefused
	}
	n, err := strconv.ParseInt(id, 10, 64)
	if err != nil {
		return time.Time{}, 0, ErrRefused
	}
	return time.Unix(0, nanos).UTC(), n, nil
}
