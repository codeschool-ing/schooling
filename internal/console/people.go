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

	// ByID answers the person behind an id that is already in an address bar.
	//
	// IT IS NOT A THIRD WAY TO SEARCH, and it was a second one until `List`
	// existed. An id is what a screen was already handed — a record has to
	// survive a reload and a pasted link like any other detail route — so
	// nothing about it selects a person from a population, which is what the
	// four conditions on `List` are there to hold.
	ByID func(ctx context.Context, id uuid.UUID) (Person, error)

	/* List answers a page of people, newest first, matching a substring or
	   nothing at all.

	   THIS IS THE AMENDMENT TO K-22 AND NOT A HOLE IN IT. See the block above
	   `list` below for the whole argument; the short version is that the
	   decision's reasoning — an audit cannot tell browsing from working — is
	   true of one read and false of a hundred, and what it was missing is that
	   an audit does not have to tell them apart one at a time in order to make
	   the difference visible.

	   The page size is not a parameter here for the same reason it is not one
	   in `identity`: a caller who chooses it chooses ten thousand, and the
	   listing becomes an export nothing recorded. */
	List func(ctx context.Context, look Look) ([]Person, error)

	/* Page is how many `List` answers at once, told rather than known.

	   THIS WAS A CONSTANT IN THIS FILE FOR ONE DRAFT and it was the wrong
	   shape: `identity` sets the page size, this package may not import it
	   (X-02), and a second copy of a number is a number that goes stale in
	   silence. What it decides is whether there is a cursor after this page —
	   so a copy that drifted low would end every listing early, with people
	   below the cut reachable by nothing. */
	Page int

	// Held is everything the platform holds about them, keyed by table — the
	// registry's own answer, including the tables with no rows, because an
	// export that silently omits an empty table cannot be told from one that
	// forgot it.
	Held func(ctx context.Context, accountID uuid.UUID) (map[string][]map[string]any, error)

	// Erase severs the person and leaves the statistics.
	Erase func(ctx context.Context, accountID uuid.UUID) error
}

// Look is a page of people, as the console asks for one.
//
// IT CARRIES NO SIZE. `identity` sets that, and the reason is in both files: a
// page whose size the caller chooses is a listing that can be asked for whole.
type Look struct {
	// Words is matched as a substring against the address and the name. Empty
	// is everybody, which is a real question — "who signed up this week" has no
	// search term in it — rather than a request to refuse.
	Words string

	// Where the previous page ended. Both or neither.
	Before   time.Time
	BeforeID uuid.UUID
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
//
// # AND WHY, IN THE ACTOR'S OWN WORDS
//
// `audit_log.reason` has existed since the table did, and the screen that reads
// the history already draws it. Nothing ever set it: this seam had no parameter
// for one, so every entry the console has written carries an empty string
// there. The erasure was the sharpest version of that — the handler read a
// `reason` off the request body and dropped it on the floor, so somebody typing
// why they were erasing a person was typing into nothing.
//
// It matters most for the writes that move money or time. `before` and `after`
// say what changed and can never say what for: "sixty days, because we lost
// their fortnight to the March outage" is not derivable from two dates, and it
// is the whole of what somebody reviewing this a year later came for.
type Record func(ctx context.Context, actor uuid.UUID, actorLabel, action string,
	subject Subject, what Changed, reason, requestID string) error

// Subject is what an entry is about.
//
// THE KIND IS CARRIED RATHER THAN ASSUMED. This was `uuid.UUID` while the only
// thing the console could act on was an account, and the wiring wrote the word
// "account" into every entry it produced. The console sets a school's colour
// now, and an audit that called a school an account would be wrong in the one
// column somebody searches by.
type Subject struct {
	Kind string
	ID   string
}

// Changed is the value an entry is about, on both sides of it.
//
// BOTH, AND EITHER MAY BE ABSENT: the audit's own columns are nullable so that
// "did not change" can be told from "was not there", and flattening the two
// into one field is how a change loses the half that makes it reviewable. A
// colour that moved has both; an erasure has only what was there.
type Changed struct {
	Before any
	After  any
}

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
	mux.HandleFunc("GET /console/api/v1/people/list", h.list)
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

// find takes a whole address and answers one person or none.
//
// IT WAS "THE ONLY WAY IN" AND IS NOT ANY MORE. `list` is one route along, and
// it is the amendment to K-22 — bounded, minimal, counted and named. This route
// is none of those and does not need to be: it discloses only whether the
// address somebody already typed belongs to an account, which tells the asker
// nothing they did not bring with them.
//
// WHICH IS EXACTLY WHY IT MUST NOT GROW A PREFIX MATCH. Every protection on the
// listing is on the listing; a lookup that started matching partially would be
// the same power reached by the route that records nothing.
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

/*
list is a page of people, and it is the decision that was amended.

	# WHAT K-22 SAID, AND WHICH HALF OF IT WAS RIGHT

	"A person is found by an exact address, and never listed", because browsing
	personal data is precisely what an audit cannot tell from working.

	The observation is true and the conclusion did not follow. An audit cannot
	tell ONE read from another — nothing about opening a record says whether the
	person opening it had a reason. But it does not have to: reviewing access is
	not done one entry at a time, and "this operator listed people four hundred
	times last month" is a shape that is plainly visible in a log and plainly
	absent from a month of answering support. What the old decision protected
	against was a listing that left no trace. This one leaves one per page.

	# AND WHAT IT COST TO STAND AS WRITTEN

	The case it never handled is the ordinary one. Somebody writes in from an
	address that is not the one they signed up with; somebody signs their e-mail
	with a surname; somebody types their own address wrongly in the message
	asking why they cannot sign in. `find` answers yes or no about a string, so
	the operator's job became guessing spellings at a form — and the fallback,
	every time, is a SQL client against production, which is the same power with
	no audit and no gate. A refusal that is routed around is not a control.

	# THE FOUR THINGS THAT MAKE THIS DEFENSIBLE, AND NONE OF THEM IS THE AUDIT
	ALONE

	  BOUNDED    a page is fifty, set by `identity` and not by the request.
	             A listing whose size the caller picks is an export that
	             nothing recorded.

	  MINIMAL    a name, an address, when they arrived, and whether they are
	             seeded — the same four fields `find` returns about one person.
	             Everything else is the record, one person at a time, and the
	             whole of it is the export, which has an entry against it (K-20).

	  COUNTED    an entry per page, carrying what was searched for and how many
	             came back. See below for what it deliberately does not carry.

	  NAMED      the screen says what the list is for, in its own words, above
	             the field. That is not decoration: it is the only part of this
	             arrangement that reaches somebody BEFORE they type, and a
	             purpose nobody states is a purpose nobody can be held to.

	# THE ENTRY CARRIES THE QUERY, WHICH IS THE UNCOMFORTABLE PART

	`erase` deliberately records counts and never the person, so that an
	append-only log does not become the last surviving copy of somebody who
	asked to be forgotten. The same instinct says not to store what was typed
	here — and it is wrong, because without the query the entry says "somebody
	listed people" and cannot distinguish the two things this record exists to
	distinguish.

	So it is stored, and the cost is real and worth naming: somebody who types a
	whole address into this field leaves a fragment of it in a log that survives
	that person's erasure. What limits the damage is that the entry carries the
	QUERY and never the RESULTS — the log says what was asked, not who was
	found, so it never becomes a copy of the list.
*/
func (h *PeopleHandler) list(w http.ResponseWriter, r *http.Request) {
	if h.people.List == nil {
		/* A DEPLOYMENT THAT DID NOT WIRE IT SAYS SO. Answering an empty page
		   would be this screen's most dangerous lie: "nobody matches" is what an
		   operator would read, about a platform full of people. */
		web.LoggerFrom(r.Context()).Error("the people listing is not wired", "path", r.URL.Path)
		web.Fail(w, http.StatusNotImplemented, web.CodeInternal,
			"this deployment cannot list people")
		return
	}

	look := Look{Words: strings.TrimSpace(r.URL.Query().Get("q"))}

	/* THE CURSOR IS BOTH HALVES OR NEITHER, and a broken one is a first page
	   rather than a refusal. Somebody who edited an address bar gets the top of
	   the list, which is the honest answer to a cursor that means nothing —
	   where a 400 would be this screen breaking on a bookmark. */
	if at, err := time.Parse(time.RFC3339Nano, r.URL.Query().Get("before")); err == nil {
		if id, err := uuid.Parse(r.URL.Query().Get("beforeId")); err == nil {
			look.Before, look.BeforeID = at, id
		}
	}

	found, err := h.people.List(r.Context(), look)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("listing people", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	/* RECORDED AFTER THE READ AND BEFORE THE ANSWER, which is not the order the
	   export uses and the difference is deliberate. The export records first,
	   because a copy that left with no entry is the failure it is guarding
	   against. Here the entry has to say HOW MANY came back, and that is not
	   known until the query has run — an entry written first would carry a
	   number nobody had counted.

	   IT STILL REFUSES ON A FAILED WRITE. The rows are in this process and have
	   reached nobody; answering with them after failing to record the read
	   would be a listing this console cannot see, which is the entire objection
	   K-22 raised. */
	if !h.wroteAbout(w, r, "personal-data.listed",
		Subject{Kind: "people", ID: "list"},
		map[string]any{
			// What was asked. "" is everybody, and it is written as a word
			// rather than left as an empty string, because a missing value and
			// a deliberate one look identical in a log.
			"query": either(look.Words, "everybody"),

			// AND HOW MANY CAME BACK, which is the number a review actually
			// reads. One is somebody answering an e-mail; fifty, forty times in
			// an afternoon, is somebody reading the customer list.
			"returned": len(found),

			// Whether this was a first page or a continuation, so a run of
			// pages is legible as one act rather than as several.
			"continued": !look.Before.IsZero(),
		}, "") {

		return
	}

	out := make([]personBody, 0, len(found))
	for _, one := range found {
		out = append(out, personBody{
			ID: one.ID.String(), Name: one.Name, Email: one.Email,
			CreatedAt: one.CreatedAt, Synthetic: one.Synthetic,
		})
	}

	body := map[string]any{
		"people": out,

		/* WHAT THIS LIST IS FOR, SENT RATHER THAN WRITTEN INTO THE SCREEN. It is
		   the one of the four protections that reaches somebody before they
		   type, so it lives beside the rule it describes rather than in an
		   interface that can drift from it. */
		"about": "This list answers a question somebody outside asked: they wrote in, and " +
			"the address on the message is not the one they signed up with, or they signed " +
			"their name and nothing else. It shows what identifies a person and not what is " +
			"held about them — that is their record, one at a time, and the whole of it is " +
			"the export, which is recorded against your name. Every page of this is recorded " +
			"too, with what you searched for and how many came back.",

		"none": "Nobody here matches that. It is matched anywhere in the address or the " +
			"name, so a fragment is enough — and nothing at all lists everybody, newest first.",
	}

	/* THE NEXT PAGE IS A CURSOR AND NOT A NUMBER, and it is absent on the last
	   one. A full page is not proof there is another — the next query can come
	   back empty — but a short page IS proof there is not, which is the half
	   worth acting on: the screen draws no button rather than one that answers
	   nothing. */
	if h.people.Page > 0 && len(found) == h.people.Page {
		last := found[len(found)-1]
		body["before"] = last.CreatedAt.Format(time.RFC3339Nano)
		body["beforeId"] = last.ID.String()
	}

	web.JSON(w, http.StatusOK, body)
}

// either is a value or the word for its absence, so a log never has to be read
// as "empty string, or a field nobody set".
func either(value, absent string) string {
	if value == "" {
		return absent
	}
	return value
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

	/* NO REASON ON AN EXPORT, and that is not an omission. Nobody is asked for
	   one — the screen is a button — and a sentence written here would be this
	   console describing its own behaviour rather than an actor explaining
	   themselves. The erasure below asks, because somebody is already typing
	   the address to confirm it. */
	if !h.wrote(w, r, "personal-data.export", id, counts(held), "") {
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
	   right person on the screen.

	   THAT LIST NOW EXISTS, which turns this from a precaution into the thing
	   doing the work. It was written while K-22 stood and the only way to reach
	   a record was to type the whole address, so the sentence above described a
	   danger this console did not have. It has it now, and this is the guard
	   that was already there for it: an operator two clicks from a page of
	   people still cannot erase one without typing that person's address. */
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

	/* AND THE REASON THEY TYPED, WHICH USED TO GO NOWHERE. It was read off the
	   body and dropped: an operator explaining an irreversible act was writing
	   into a field this code discarded. */
	if !h.wrote(w, r, "personal-data.erase", id, counts(held), strings.TrimSpace(in.Reason)) {
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
	action string, subject uuid.UUID, what any, why string) bool {

	/* THE COUNTS SIT ON THE `before` SIDE, and for an erasure that is exactly
	   what they are: how much was there, before it was not. An export changes
	   nothing, and its counts describe the state that was read — which is the
	   same side of the same word. Neither is a creation, so neither carries an
	   `after`. */
	return h.wroteAbout(w, r, action, Subject{Kind: "account", ID: subject.String()}, what, why)
}

/*
wroteAbout is `wrote` for an entry whose subject is not a person.

	THE LISTING NEEDED THIS AND IT IS NOT A LISTING-SHAPED SEAM. `wrote` took a
	`uuid.UUID` and wrote the word "account" beside it, which was true of
	everything this handler could do until a read arrived whose subject is the
	ACT rather than anybody in particular: "somebody listed people" is about the
	console, and filing it against an account id would mean inventing one or
	filing it against whoever happened to come back first.

	SO THE SUBJECT IS `people/list`, WHICH IS A FILTER THAT WORKS. The history
	screen already draws "everything done to one subject", so every listing this
	console has ever answered is one address away — which is the review the
	amendment to K-22 rests on being possible at all.
*/
func (h *PeopleHandler) wroteAbout(w http.ResponseWriter, r *http.Request,
	action string, about Subject, what any, why string) bool {

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

	if err := h.record(r.Context(), actor, label, action,
		about, Changed{Before: what},
		why, web.RequestIDFrom(r.Context())); err != nil {
		web.LoggerFrom(r.Context()).Error("recording a console action", "error", err, "action", action)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return false
	}
	return true
}
