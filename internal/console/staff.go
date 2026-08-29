package console

import (
	"context"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* Who can open this console.

   # THE ONE QUESTION THIS CONSOLE COULD NOT ASK ABOUT ITSELF

   `cmd/staff list` has printed this since phase 0 and prints it into a
   terminal, next to the database, on a machine somebody has to be sitting at.
   So the console could set what every student pays, erase a person, quarantine
   a question and read every entry in the audit — and could not answer "who else
   can do all of that". That is not a small gap. An access list nobody can see
   is an access list nobody reviews, and the row that matters on it is always
   the one nobody remembered was there.

   # IT IS A READ AND IT STAYS A READ

   Nothing here grants or revokes. That is not squeamishness about a form: the
   first owner cannot be granted a role by a console that needs a role to open,
   so `cmd/staff` has to exist regardless — and two doors that both write to
   `staff` is two paths to keep audited, tested and in agreement, bought for the
   convenience of not opening a terminal on the rarest write this platform has.
   The screen says where the grant lives instead.

   `writes.go` lists what this console can CHANGE, and this route is correctly
   absent from it.

   # WHY THIS IS NOT THE THING K-22 REFUSES

   K-22 says a person is found by an exact address and never listed, because
   browsing personal data is indistinguishable from working. The argument does
   not reach this list, and the difference is not one of degree:

     - it is not a population, it is this platform's access-control list, and
       there is no version of reviewing one that goes address by address — the
       whole question is who is on it that you did not think to ask about;
     - everybody on it consented to operating the platform rather than to using
       it, and their address is already in every audit entry they have written;
     - it is bounded by the number of people who run this, which is a number
       that fits on one screen and always will.

   # AND IT IS NOT AUDITED, WHICH IS A DECISION AND NOT AN OMISSION

   K-20 audits the personal-data export because afterwards a person's record is
   a file on a laptop, outside every control this system has. Nothing here
   leaves: it is the roster, read by people who are on it, and an entry per
   read would be an audit trail of operators looking at their own names — noise
   in exactly the log that has to stay searchable for the week it matters.

   # WHAT IT SHOWS THAT `cmd/staff list` DOES NOT

   Who granted it, whether the row was revoked, and when they last presented a
   second factor. The last of those is the one an access review is actually for:
   a role nobody has used in a year is the row to ask about, and neither the
   role nor the enrolment says a word about it.
*/

// Operator is one person with a role, as this console shows them.
type Operator struct {
	AccountID uuid.UUID
	Name      string
	Email     string
	Role      string

	GrantedAt time.Time

	// Who granted it, or empty for the first owner — who has nobody above them
	// and whose row says so with a null rather than with a name.
	GrantedByName  string
	GrantedByEmail string

	// Set on somebody who left. Revoked rows are shown rather than filtered,
	// because "who has ever been able to open this" is the question with an
	// audit in it and the one a screen is for.
	RevokedAt *time.Time

	// Whether they have a second factor at all. A role without one opens
	// nothing.
	SecondFactor bool

	// When they last presented it, which is when they last actually opened this
	// console — nil for somebody who never has.
	LastOpenedConsole *time.Time
}

// Operators is what this package may not import: `identity` owns the table.
type Operators func(ctx context.Context) ([]Operator, error)

// StaffHandler answers who can open this console.
//
// IT TAKES NO `Record`, NO `Label` AND NO RANK CLOSURE, and the shortness of
// this struct is the design rather than a stage it has not reached. There is
// nothing to record because nothing is written; there is nobody to label
// because no entry is produced; and there is no second rank because read-only
// is the floor of the console and reviewing who has access is the most
// read-only act there is.
type StaffHandler struct {
	operators Operators
}

func NewStaffHandler(operators Operators) *StaffHandler {
	return &StaffHandler{operators: operators}
}

func (h *StaffHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/staff", h.list)
}

type operatorBody struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	Role  string `json:"role"`

	GrantedAt      time.Time `json:"granted_at"`
	GrantedByName  string    `json:"granted_by_name,omitempty"`
	GrantedByEmail string    `json:"granted_by_email,omitempty"`

	// Absent rather than null on somebody still here: the screen draws a row
	// differently when there is one, and `omitempty` is that rule said once.
	RevokedAt *time.Time `json:"revoked_at,omitempty"`

	// NOT `omitempty`. False is the answer that matters most on this screen —
	// a role that opens nothing — and a key the interface failed to read must
	// not look like it.
	SecondFactor bool `json:"second_factor"`

	// Absent on somebody who has never opened the console, which the screen
	// says in words. A zero time would be drawn as a date in the year 1.
	LastOpenedConsole *time.Time `json:"last_opened_console,omitempty"`
}

func (h *StaffHandler) list(w http.ResponseWriter, r *http.Request) {
	people, err := h.operators(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who can open the console", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]operatorBody, 0, len(people))
	for _, one := range people {
		out = append(out, operatorBody{
			ID: one.AccountID.String(), Name: one.Name, Email: one.Email, Role: one.Role,
			GrantedAt:      one.GrantedAt,
			GrantedByName:  one.GrantedByName,
			GrantedByEmail: one.GrantedByEmail,
			RevokedAt:      one.RevokedAt,
			SecondFactor:   one.SecondFactor,

			LastOpenedConsole: one.LastOpenedConsole,
		})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"staff": out,

		/* WHERE THE GRANT LIVES, SENT RATHER THAN WRITTEN INTO THE SCREEN.
		   Somebody reading this list is one thought away from wanting to change
		   it, and a screen that says nothing leaves them looking for a button
		   that is deliberately not there. The command is the answer, and it is
		   here so that the reason travels with it. */
		"how_to_change_it": "A role is granted and revoked with `staff grant` and " +
			"`staff revoke`, from a terminal where the database is reachable. It is not a " +
			"form here because the first owner cannot be granted a role by a console that " +
			"needs one to open — so that door has to exist anyway, and a second door onto " +
			"the same table would be a second thing to keep audited and in agreement.",

		/* AND WHY THE ROSTER IS NOT AN ALARM. `job_runs` has the same sentence
		   for the same reason: a screen answers "should I trust this" for
		   somebody already looking, and it cannot answer "has something
		   changed" for somebody who is not. */
		"about_reviewing": "Every row here is somebody who can open this console, or could. " +
			"The column worth reading is the last one: a role granted a year ago and never " +
			"used since is access nobody is missing, and it is the row an access review " +
			"exists to find. Revoked rows stay so that somebody who left is distinguishable " +
			"from somebody who was never here.",

		// A DATABASE WITH NO STAFF IS UNREACHABLE FROM HERE, which makes this
		// sentence a statement about a defect rather than an empty state. The
		// request that arrived was authenticated by a live staff row, so the
		// reader is on the list they are being told is empty.
		"impossible": "Nobody has a role, which cannot be true — this page was opened by " +
			"somebody who has one. Something is answering wrongly rather than there being " +
			"nobody here.",
	})
}
