package console

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* One person, and the two things that may be done about them.

   THIS IS THE PHASE-0 ITEM AND IT IS AN OBLIGATION RATHER THAN A FEATURE.
   Somebody writes in and asks what is held about them, or asks to be forgotten;
   the export and the erasure have existed and been tested since phase 0, and
   until now there was no way for a person to reach them without somebody
   opening a SQL client against production. That is not a smaller version of
   this — it is the same power with no audit and no gate. */

// ErrNoPerson is nobody at that address. It is a state and not a failure: most
// addresses somebody types belong to nobody here.
var ErrNoPerson = errors.New("console: no account at that address")

// Person is who a staff member is looking at.
//
// IT IS NOT AN ACCOUNT ROW. What a screen needs to identify somebody before
// acting on them is a name, an address and when they arrived — not their
// locale, not their country, and nothing that would make this a place to read
// personal data casually. Reading more is what the export is for, and the
// export is audited.
type Person struct {
	ID        uuid.UUID
	Name      string
	Email     string
	CreatedAt time.Time

	// Synthetic students exist to be excluded from aggregates (K-11), and a
	// screen about to erase one should know it is looking at a seeded person.
	Synthetic bool
}

// People is what this package may not import.
//
// `identity` owns accounts and `privacy` owns the registry; a console that
// imported either would be the module boundary broken by the one package with
// the best excuse. So it names three shapes and `cmd/api` says who provides
// them.
type People struct {
	// Find answers the person at exactly this address, or ErrNoPerson.
	Find func(ctx context.Context, email string) (Person, error)

	// Held is everything the platform holds about them, keyed by table — the
	// registry's own answer, including the tables with no rows, because an
	// export that silently omits an empty table cannot be told from one that
	// forgot it.
	Held func(ctx context.Context, accountID uuid.UUID) (map[string][]map[string]any, error)

	// Erase severs the person and leaves the statistics.
	Erase func(ctx context.Context, accountID uuid.UUID) error
}

// Record is what the console writes down about itself.
//
// BOTH ACTIONS ARE RECORDED, INCLUDING THE EXPORT (K-20). An erasure is a write
// and K-01 covers it. An export is a read — and it is the one read that removes
// the protection every other read has, because afterwards a person's whole
// record is a file on somebody's laptop, outside every access control this
// system has. "Who took a copy of whose data, and when" is asked once, in the
// worst week, and the answer has to already exist by then.
//
// # THE ENTRY DOES NOT NAME THE PERSON, AND THAT IS THE HARD PART
//
// `audit_log.actor_label` is denormalised precisely because a uuid a year later
// is not an answer, and the same argument reaches for the SUBJECT: after an
// erasure the account row is gone, so an entry pointing at its id points at
// nothing.
//
// It stays an id anyway. An append-only table that recorded "erased the account
// of <address>" would make the audit the last surviving copy of the person who
// asked to be forgotten — erasure defeated by the mechanism that proves it
// happened.
//
// So what the entry carries instead is COUNTS: how many rows, in which tables,
// were handed over or removed. That answers every question an audit is for —
// who did it, when, how much went — without the log becoming the thing it is
// auditing. Somebody who needs to connect an entry to a person has the ticket
// they were answering, which is outside this system and is where that link
// belongs.
type Record func(ctx context.Context, actor uuid.UUID, actorLabel, action string,
	subject uuid.UUID, what any, requestID string) error

// PeopleHandler is find, show, export, erase.
type PeopleHandler struct {
	people People
	record Record
	label  Label
	who    func(ctx context.Context) (uuid.UUID, bool)

	// mayErase is the second rank. Read-only opened the door; erasing is not a
	// thing a read-only role does, and the check is here rather than in a rule
	// somebody remembers.
	mayErase func(ctx context.Context) bool
}

func NewPeopleHandler(people People, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	mayErase func(ctx context.Context) bool,
) *PeopleHandler {
	return &PeopleHandler{people: people, record: record, label: label, who: who, mayErase: mayErase}
}

func (h *PeopleHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/people", h.find)
	mux.HandleFunc("GET /console/api/v1/people/{id}/held", h.held)
	mux.HandleFunc("GET /console/api/v1/people/{id}/export", h.export)
	mux.HandleFunc("POST /console/api/v1/people/{id}/erase", h.erase)
}

type personBody struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"createdAt"`
	Synthetic bool      `json:"synthetic,omitempty"`
}

// find is the only way in, and it takes a whole address.
//
// THE ADDRESS IS IN THE QUERY STRING AND THE ANSWER IS ONE PERSON OR NONE.
// There is no listing route on purpose, and no prefix match: see K-22. A
// console that can produce a page of people is a console somebody can browse,
// and browsing personal data is indistinguishable from working.
func (h *PeopleHandler) find(w http.ResponseWriter, r *http.Request) {
	email := strings.TrimSpace(r.URL.Query().Get("email"))
	if email == "" {
		web.Fail(w, http.StatusBadRequest, web.CodeNotFound,
			"give the whole address — there is no search here, only a lookup")
		return
	}

	person, err := h.people.Find(r.Context(), email)
	switch {
	case errors.Is(err, ErrNoPerson):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no account at that address")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("looking a person up", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not look that up")
		return
	}

	web.JSON(w, http.StatusOK, personBody{
		ID: person.ID.String(), Name: person.Name, Email: person.Email,
		CreatedAt: person.CreatedAt, Synthetic: person.Synthetic,
	})
}

type heldBody struct {
	// Rows per table, and never the rows themselves. A screen that showed the
	// contents would be an export nobody recorded.
	Tables map[string]int `json:"tables"`
	Total  int            `json:"total"`
}

// held is the count and not the contents.
//
// A SCREEN THAT SHOWED THE ROWS WOULD BE AN UNRECORDED EXPORT. What an operator
// needs before erasing somebody is confidence that they have the right person
// and a sense of what is about to go; what they do not need is to read it. The
// moment they do need to, that is the export, and the export writes an audit
// entry.
func (h *PeopleHandler) held(w http.ResponseWriter, r *http.Request) {
	id, ok := subject(w, r)
	if !ok {
		return
	}

	held, err := h.people.Held(r.Context(), id)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading what is held", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	body := heldBody{Tables: make(map[string]int, len(held))}
	for table, rows := range held {
		body.Tables[table] = len(rows)
		body.Total += len(rows)
	}
	web.JSON(w, http.StatusOK, body)
}

// export hands over everything, and says so in the audit before it does.
//
// THE ENTRY IS WRITTEN FIRST, AND A FAILURE TO WRITE IT REFUSES THE EXPORT.
// Recording afterwards would mean an export that succeeded and an audit that
// did not is an export nobody can see — and the failure mode of an audit is
// precisely that it is missing when somebody asks. Better a staff member who
// has to try again than a copy of somebody's life with no record of who took
// it.
func (h *PeopleHandler) export(w http.ResponseWriter, r *http.Request) {
	id, ok := subject(w, r)
	if !ok {
		return
	}

	held, err := h.people.Held(r.Context(), id)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("exporting", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	if !h.wrote(w, r, "personal-data.export", id, counts(held)) {
		return
	}

	// Named for the person it is about and the day it was taken, because a
	// second copy in a downloads folder six months later has to be explicable.
	w.Header().Set("Content-Disposition",
		fmt.Sprintf(`attachment; filename="schooling-%s-%s.json"`, id, time.Now().UTC().Format("2006-01-02")))
	web.JSON(w, http.StatusOK, held)
}

// erase severs the person and leaves the statistics, and needs more than the
// door asked for.
func (h *PeopleHandler) erase(w http.ResponseWriter, r *http.Request) {
	id, ok := subject(w, r)
	if !ok {
		return
	}

	/* READ-ONLY GOT THROUGH THE DOOR AND STOPS HERE. The console's floor is
	   read-only (K-19) because a screen nobody can open is a screen nobody
	   checks; an erasure cannot be undone, so it asks for the rank that exists
	   to say so. */
	if !h.mayErase(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"erasing needs more than a read-only role")
		return
	}

	/* THE CONFIRMATION IS THE ADDRESS, TYPED. An erasure reached by one click
	   from a list somebody was scrolling is the accident this guards against —
	   and it is the person's own address, so getting it right means having the
	   right person on the screen. */
	var in struct {
		Email  string `json:"email"`
		Reason string `json:"reason"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4<<10)).Decode(&in); err != nil {
		web.Fail(w, http.StatusBadRequest, web.CodeNotFound, "that request could not be read")
		return
	}

	person, err := h.people.Find(r.Context(), in.Email)
	switch {
	case errors.Is(err, ErrNoPerson), err == nil && person.ID != id:
		web.Fail(w, http.StatusBadRequest, web.CodeNotFound,
			"the address does not belong to the person being erased")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("confirming an erasure", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not confirm that")
		return
	}

	/* WHAT IS ABOUT TO GO, COUNTED WHILE IT IS STILL THERE. Afterwards there is
	   nothing to count, and an entry that says an erasure happened without
	   saying how much went is an entry nobody can check against anything. */
	held, err := h.people.Held(r.Context(), id)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("counting before an erasure", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	if !h.wrote(w, r, "personal-data.erase", id, counts(held)) {
		return
	}

	if err := h.people.Erase(r.Context(), id); err != nil {
		web.LoggerFrom(r.Context()).Error("erasing", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not erase that")
		return
	}
	web.JSON(w, http.StatusNoContent, nil)
}

/* ---------- the two things every route here does ---------- */

// counts turns the registry's answer into what the audit is allowed to keep:
// how many rows in which table, and nothing that was in them.
func counts(held map[string][]map[string]any) map[string]int {
	out := make(map[string]int, len(held))
	for table, rows := range held {
		out[table] = len(rows)
	}
	return out
}

// subject reads the person out of the path.
func subject(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such person")
		return uuid.Nil, false
	}
	return id, true
}

// wrote records the action, and answers whether the caller may go on.
//
// The actor's label is read here rather than carried on the session, because
// `audit_log.actor_label` is denormalised on purpose — people are renamed and
// people leave, and an entry reading "erased an account, actor 9f2c…" a year
// later is not an answer.
func (h *PeopleHandler) wrote(w http.ResponseWriter, r *http.Request,
	action string, subject uuid.UUID, what any) bool {
	actor, ok := h.who(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a console route ran with no account", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return false
	}

	name, email, err := h.label(r.Context(), actor)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is acting", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not record that")
		return false
	}
	label := strings.TrimSpace(name + " <" + email + ">")

	if err := h.record(r.Context(), actor, label, action, subject, what,
		web.RequestIDFrom(r.Context())); err != nil {
		web.LoggerFrom(r.Context()).Error("recording a console action", "error", err, "action", action)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return false
	}
	return true
}
