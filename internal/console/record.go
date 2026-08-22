package console

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* One student's record.

   THE OTHER HALF OF WHAT MAKES THE FIRST SCREEN SAFE TO USE. `Personal data`
   answers "is this the right person and how much is held about them", which is
   what somebody needs before erasing. It answers nothing about the conversation
   that usually brings a person to write in: what they are paying for, how far
   they have got, what they sat, what they were awarded.

   Until now that was a SQL client, exactly as the audit was.

   # IT IS PER SCHOOL, AND THE SCREEN SAYS SO (K-18)

   Almost everything here is school-scoped: progress, exams and certificates are
   keyed by `(tenant_id, account_id)`, and a subscription is held for a scope.
   The account is not — one account crosses every school (N-01) — so a record is
   a person, then a section per school they have anything in.

   Presenting it as one flat list would be the scope error this project keeps
   naming: two schools' progress added together is a number about nobody.

   # WHAT IT COSTS, SAID OUT LOUD

   One query set per school, so the work grows with schools rather than with
   students. At two schools that is nothing; at fifty it is a screen that wants
   a different shape — and the honest place to notice is when a fiftieth school
   exists, not now, because every one of these reads is on an index that leads
   with `(tenant_id, account_id)` (K-21).

   # AND IT IS NOT AN EXPORT

   It shows what an operator needs to hold a conversation: counts, states, dates
   and titles. It does not show a note somebody wrote, an answer they gave, or
   anything else that reads as their work rather than as their standing. Reading
   THAT is the export, and the export is audited.
*/

// Sitting is one browser signed in. The token is not here and never will be:
// what an operator needs is "how many, since when, from what" — not something
// that would let them become the person.
type Sitting struct {
	ID         uuid.UUID
	CreatedAt  time.Time
	LastSeenAt *time.Time
	ExpiresAt  time.Time
	RevokedAt  *time.Time
	UserAgent  string
}

// School is the one thing about a school a record needs.
type School struct {
	ID   uuid.UUID
	Slug string
	Name string
}

// Course is how far along one course they are.
type Course struct {
	CourseID string
	Sections int
}

// Sat is one exam attempt.
type Sat struct {
	Scope     string
	ScopeID   string
	StartedAt time.Time
	HandedIn  *time.Time
	Passed    *bool
	Score     *int
}

// Given is one certificate.
type Given struct {
	Code     string
	Title    string
	IssuedAt time.Time
}

// AtSchool is everything about one person at one school.
type AtSchool struct {
	School School

	// Empty when they have never held anything here, which is different from a
	// plan that ended: the screen says which.
	Plan        string
	State       string
	PaidThrough *time.Time

	Courses      []Course
	Exams        []Sat
	Certificates []Given
}

// Records is what this package may not import — and here that is four modules
// rather than one, which is why the seam is one function and not four.
//
// `billing`, `progress`, `exam` and `certificate` each answer a question about
// one person at one school. A console that imported them would be the module
// boundary broken four times over; a console that named four function types
// would make `cmd/api` wire four things that are only ever called together. So
// it names ONE, and the joining happens where the modules already meet.
type Records struct {
	// Schools is every school on the platform, for the record to be gathered
	// across. It is not a screen's list of schools — it is the loop.
	Schools func(ctx context.Context) ([]School, error)

	// Sittings are platform-wide, because an account is.
	Sittings func(ctx context.Context, accountID uuid.UUID) ([]Sitting, error)

	// At is one person at one school, or a zero value if they have nothing
	// there. It is not an error to have nothing: most people are at one school.
	At func(ctx context.Context, school School, accountID uuid.UUID) (AtSchool, error)
}

// RecordHandler is the record for one person.
type RecordHandler struct {
	people  People
	records Records
}

func NewRecordHandler(people People, records Records) *RecordHandler {
	return &RecordHandler{people: people, records: records}
}

func (h *RecordHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/people/{id}/record", h.record)
}

type recordBody struct {
	Person   personBody     `json:"person"`
	Sittings []sittingBody  `json:"sittings"`
	Schools  []atSchoolBody `json:"schools"`
	Scope    string         `json:"scope"`
}

type sittingBody struct {
	ID        string     `json:"id"`
	CreatedAt time.Time  `json:"createdAt"`
	LastSeen  *time.Time `json:"lastSeenAt,omitempty"`
	ExpiresAt time.Time  `json:"expiresAt"`
	RevokedAt *time.Time `json:"revokedAt,omitempty"`
	UserAgent string     `json:"userAgent,omitempty"`
	Live      bool       `json:"live"`
}

type atSchoolBody struct {
	School      string     `json:"school"`
	Name        string     `json:"name"`
	Plan        string     `json:"plan,omitempty"`
	State       string     `json:"state,omitempty"`
	PaidThrough *time.Time `json:"paidThrough,omitempty"`

	Courses      []courseBody `json:"courses"`
	Exams        []examBody   `json:"exams"`
	Certificates []certBody   `json:"certificates"`
}

type courseBody struct {
	Course   string `json:"course"`
	Sections int    `json:"sections"`
}

type examBody struct {
	Scope     string     `json:"scope"`
	ScopeID   string     `json:"subject"`
	StartedAt time.Time  `json:"startedAt"`
	HandedIn  *time.Time `json:"handedInAt,omitempty"`
	Passed    *bool      `json:"passed,omitempty"`
	Score     *int       `json:"score,omitempty"`
}

type certBody struct {
	Code     string    `json:"code"`
	Title    string    `json:"title"`
	IssuedAt time.Time `json:"issuedAt"`
}

// record answers the whole thing in one response.
//
// ONE REQUEST AND NOT SIX. The screen shows all of it at once — a person on the
// telephone is not read out in instalments — and six round trips would be six
// chances for a screen to be half drawn while somebody decides something.
func (h *RecordHandler) record(w http.ResponseWriter, r *http.Request) {
	id, ok := subject(w, r)
	if !ok {
		return
	}

	/* THE PERSON IS READ FIRST AND BY ID, so a record for an id that belongs to
	   nobody is a 404 rather than an empty page. An empty page is what a person
	   who has done nothing looks like, and those two must not look alike. */
	person, err := h.people.ByID(r.Context(), id)
	switch {
	case errors.Is(err, ErrNoPerson):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such person")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading a person", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	sittings, err := h.records.Sittings(r.Context(), id)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading sittings", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	schools, err := h.records.Schools(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the schools", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	body := recordBody{
		Person: personBody{
			ID: person.ID.String(), Name: person.Name, Email: person.Email,
			CreatedAt: person.CreatedAt, Synthetic: person.Synthetic,
		},
		Sittings: make([]sittingBody, 0, len(sittings)),
		Schools:  make([]atSchoolBody, 0, len(schools)),
		Scope:    "every school",
	}

	now := time.Now()
	for _, s := range sittings {
		body.Sittings = append(body.Sittings, sittingBody{
			ID: s.ID.String(), CreatedAt: s.CreatedAt, LastSeen: s.LastSeenAt,
			ExpiresAt: s.ExpiresAt, RevokedAt: s.RevokedAt, UserAgent: s.UserAgent,
			Live: s.RevokedAt == nil && s.ExpiresAt.After(now),
		})
	}

	for _, school := range schools {
		at, err := h.records.At(r.Context(), school, id)
		if err != nil {
			web.LoggerFrom(r.Context()).Error("reading a record at a school",
				"error", err, "account", id, "school", school.Slug)
			web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
			return
		}

		/* A SCHOOL THEY HAVE NEVER TOUCHED IS LEFT OUT. Rendering every school
		   with four empty tables is a screen where the answer is buried in the
		   part that says nothing. */
		if at.Plan == "" && len(at.Courses) == 0 && len(at.Exams) == 0 && len(at.Certificates) == 0 {
			continue
		}
		body.Schools = append(body.Schools, shownAtSchool(school, at))
	}

	web.JSON(w, http.StatusOK, body)
}

func shownAtSchool(school School, at AtSchool) atSchoolBody {
	out := atSchoolBody{
		School: school.Slug, Name: school.Name,
		Plan: at.Plan, State: at.State, PaidThrough: at.PaidThrough,
		Courses:      make([]courseBody, 0, len(at.Courses)),
		Exams:        make([]examBody, 0, len(at.Exams)),
		Certificates: make([]certBody, 0, len(at.Certificates)),
	}
	for _, c := range at.Courses {
		out.Courses = append(out.Courses, courseBody{Course: c.CourseID, Sections: c.Sections})
	}
	/* A CONVERSION AND NOT A LITERAL, which is `staticcheck`'s S1016 and is
	   right: these two pairs are the same fields in the same order, differing
	   only in their JSON tags, and a field-by-field copy is a place for a field
	   to be forgotten when one of them grows.

	   The two types still exist for the reason they always did — the shape this
	   package works in and the shape that goes over the wire are separate
	   decisions — and the day they stop being identical the conversion stops
	   compiling, which is exactly the moment somebody should be looking. */
	for _, e := range at.Exams {
		out.Exams = append(out.Exams, examBody(e))
	}
	for _, c := range at.Certificates {
		out.Certificates = append(out.Certificates, certBody(c))
	}
	return out
}
