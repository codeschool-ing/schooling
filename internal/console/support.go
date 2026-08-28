package console

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/google/uuid"
)

/* Where a student writes to use the seven days.

   # THIS IS A PARAMETER AND IT HAD TO ARGUE ITS WAY IN

   `writes.go` opens by refusing the shape that suggests itself — a table of
   names and values with a screen that edits any row — and sets the bar for
   anything settable: the value must have NO RIGHT ANSWER, because a value with
   one belongs in code where a test can hold it.

   No test can say which address is the correct one to publish. It is a fact
   about who is answering, and it changes when that person does — a handover, a
   shared box, a support desk — with no code changing at all. Same shape as a
   school's accent colour, and settable for the same reason.

   # AND IT WAS SOMEWHERE WORSE BEFORE

   It was `SCHOOLING_SUPPORT_EMAIL` in the infrastructure, which meant changing
   it took an apply and a new revision, from the ONE machine whose gitignored
   `terraform.tfvars` holds the value. An apply from anywhere else plans it back
   to empty and takes the address off the screen with nothing failing — which is
   how a right the terms promise quietly loses the way to use it. `0044` is that
   argument in full.

   The variable stays as the fallback, and both empty is still allowed: the
   notice then names the deadline and no address.

   # REPLACED, AND THE AUDIT IS THE HISTORY

   A price is a series because a March invoice has to stay explicable in
   November (K-14). An address owes nothing like that — "what was published in
   March" is what the audit log answers, with who changed it and when, which is
   written here BEFORE the value moves.

   # THE REASON IS ASKED FOR, UNLIKE THE PRICE

   `plan.go` records a price change with an empty reason and has a comment
   saying it is the write that most deserves one. This one asks, because the
   answer is short and load-bearing: an address that changed because the person
   answering changed is a different fact from one that changed because the last
   one was a typo, and only the second is a reason to go looking at what was
   published in between.
*/

// Contact is the address the platform publishes, as the console shows it.
type Contact struct {
	Email string

	// Since is when it last moved, and zero when nobody has ever set one — the
	// screen then says the deployment's variable is answering, which is a
	// different fact from an address set long ago.
	Since time.Time
}

// Support is what this package may not import: `billing` owns the row, because
// `billing` is what publishes the value on the account screen.
type Support struct {
	// Now is the row, or a zero Contact when there is none. It is deliberately
	// NOT the value the student sees: the fallback to the deployment's variable
	// happens in `cmd`, and a console that showed the resolved answer could not
	// tell an operator whether this screen is what decides it.
	Now func(ctx context.Context) (Contact, error)

	// Set replaces it and answers what was there, so the handler can notice
	// somebody else moving it between the read and the write.
	Set func(ctx context.Context, email string) (was Contact, err error)

	// Refused is an address the caller can fix by sending another. `billing`
	// builds the sentence and this package may not import its errors, so the
	// predicate travels instead — the same seam `Plan.Refused` uses.
	Refused func(error) bool
}

// Fallback is what the deployment configured, shown beside the row so an
// operator can see what an empty row falls back to.
//
// IT IS A VALUE AND NOT A FUNCTION because it cannot change while the process
// runs — that is the whole reason this screen exists.
type Fallback string

// SupportHandler reads and writes where a student writes.
type SupportHandler struct {
	support  Support
	fallback Fallback
	record   Record
	label    Label
	who      func(ctx context.Context) (uuid.UUID, bool)

	// maySet is the second rank, like every other parameter here: read-only
	// opened the door, and changing what is published to every student is not
	// a thing a read-only role does.
	maySet func(ctx context.Context) bool
}

func NewSupportHandler(support Support, fallback Fallback, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	maySet func(ctx context.Context) bool,
) *SupportHandler {
	return &SupportHandler{support: support, fallback: fallback,
		record: record, label: label, who: who, maySet: maySet}
}

func (h *SupportHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/support/contact", h.contact)
	mux.HandleFunc("PUT /console/api/v1/support/contact", h.setContact)
}

// contact is the row, the deployment's fallback, and which of the two is
// answering — three facts rather than one, because an operator looking at this
// screen is deciding whether to type anything at all.
func (h *SupportHandler) contact(w http.ResponseWriter, r *http.Request) {
	found, err := h.support.Now(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading where a student writes", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	body := map[string]any{
		"email":    found.Email,
		"fallback": string(h.fallback),

		// WHAT A STUDENT ACTUALLY SEES, resolved here so the screen does not
		// have to re-implement an order of precedence that lives in `cmd`. An
		// empty answer means the notice names the deadline and no address.
		"published": published(found.Email, string(h.fallback)),
	}
	if !found.Since.IsZero() {
		body["since"] = found.Since
	}
	web.JSON(w, http.StatusOK, body)
}

/*
SETTING IT IS REPLACING IT, AND THE ENTRY IS WRITTEN FIRST.

Every write in this console records before it acts, so a change nobody can
account for cannot happen quietly — and if the write then fails, the history
says something happened that did not, which is a defect the message names out
loud rather than a silence.
*/
func (h *SupportHandler) setContact(w http.ResponseWriter, r *http.Request) {
	if !h.maySet(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"changing where students are told to write asks for an operator")
		return
	}

	var asked struct {
		Email  string `json:"email"`
		Reason string `json:"reason"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<10)).Decode(&asked); err != nil {
		web.Fail(w, http.StatusBadRequest, "unreadable", "that is not a request this reads")
		return
	}
	email := strings.TrimSpace(asked.Email)
	reason := strings.TrimSpace(asked.Reason)

	if reason == "" {
		web.Fail(w, http.StatusBadRequest, "no_reason",
			"say why in a few words. This address is published to every student as the way "+
				"to use the seven days, and the log has to be able to tell an address that "+
				"moved because the person answering changed from one that moved because the "+
				"last was a typo")
		return
	}

	actor, label, ok := acting(w, r, h.who, h.label)
	if !ok {
		return
	}

	// What is there, so the entry can name both sides. No row is a zero, which
	// `Changed` carries as nothing rather than as a blank address.
	was, err := h.support.Now(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading where a student writes", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	if err := h.record(r.Context(), actor, label,
		"support.contact.changed",
		/* THE SUBJECT IS THE PLATFORM AND NOT A PERSON. Every other subject
		   here is a school, a plan or somebody's account; this one is the whole
		   deployment, and saying so is what stops the entry reading as a change
		   to whoever happened to be on screen. */
		Subject{Kind: "platform", ID: "support contact"},
		Changed{Before: nothingOr(was.Email), After: email},
		reason,
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a support address change", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return
	}

	before, err := h.support.Set(r.Context(), email)
	switch {
	case h.support.Refused != nil && h.support.Refused(err):
		web.Fail(w, http.StatusBadRequest, "not_an_address", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("setting where a student writes", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the change was recorded and then could not be written, which is a defect — "+
				"the history now says something happened that did not")
		return
	}
	if before.Email != was.Email {
		// Somebody else set it between the read and the write, so the entry
		// above names a `before` that was already gone. This is the line that
		// says where to look.
		web.LoggerFrom(r.Context()).Warn("the support address moved under a change",
			"recorded_before", nothingOr(was.Email),
			"actually_was", nothingOr(before.Email))
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"email":     email,
		"published": email,
	})
}

// published is what the student sees: the row when there is one, and the
// deployment's variable behind it. It mirrors `cmd`'s wiring on purpose and is
// the one duplication of that order — see `contact` on why the screen is told
// rather than left to work it out.
func published(row, fallback string) string {
	if row != "" {
		return row
	}
	return fallback
}

// nothingOr keeps an absent address out of the audit as a word rather than as
// an empty string, so an entry reads "nothing → a@b.c" instead of " → a@b.c".
func nothingOr(email string) any {
	if email == "" {
		return "nothing"
	}
	return email
}
