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

// School is what the console knows about a school.
//
// ONE TYPE FOR TWO SCREENS, and the fourth field is why it is worth saying: the
// record loops over schools to gather one student's standing and never looks at
// the colour, while the schools screen exists to change it. Two types differing
// by one field would be two lists to keep in step with `tenants`.
//
// `Accent` is empty where the row has none, which is a real state: the school
// then wears the palette's own blue, and a screen has to say so rather than
// draw an empty swatch.
type School struct {
	ID     uuid.UUID
	Slug   string
	Name   string
	Accent string

	// THERE IS NO PRICE HERE ANY MORE. `0041` moved it to the platform: one
	// subscription opens every school (N-02), so a number per school was an
	// offer somebody could shop between. What it costs is `PlanHandler`'s, and
	// a school that carried a copy of it would be showing the same figure on
	// every row while implying it belongs to one of them.
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

	/* Empty when they have never held anything here, which is different from a
	   plan that ended: the screen says which.

	   AND IN PRACTICE IT IS ALWAYS EMPTY TODAY, because there is no per-school
	   subscription to find: N-02 made one subscription cover every school and
	   it is held at scope `all`. These three are kept rather than deleted
	   because `subscriptions.scope` exists precisely so that can narrow later
	   (N-03) — and what a screen needs meanwhile is `Holding` below, which is
	   platform-wide and says so. */
	Plan        string
	State       string
	PaidThrough *time.Time

	Courses      []Course
	Exams        []Sat
	Certificates []Given
}

/*
Holding is what one person is paying for and everything they have ever bought.

	IT IS PLATFORM-WIDE AND SITS BESIDE THE SCHOOLS RATHER THAN INSIDE ONE. One
	login, one subscription, every school (N-01, N-02) — so putting it under a
	school would be the scope error this project keeps naming, and repeating it
	under each would show the same figure several times as though there were
	several.

	IT IS THE SAME ANSWER THE STUDENT GETS. `GET /api/v1/subscription` draws
	their own account screen from these fields; an operator on the telephone
	needs to be looking at what the person on the other end is looking at, and
	two readings of one subscription is how a conversation goes wrong.
*/
type Holding struct {
	// State is empty when they have never held anything, `none` never appears
	// here: absence is absence, and the screen leaves the section out.
	State string

	// Opens is whether it opens paid courses TODAY, which is not readable from
	// the state — `grace` opens and `suspended` does not.
	Opens bool

	// Model is how it was bought, and it matters because the consequence
	// differs: an instalment plan ends and nothing renews it.
	Model string

	Since       *time.Time
	PaidThrough *time.Time

	/* Price is what the term running now was bought at, resolved.

	   IT IS `plan.go`'S TYPE AND NOT ONE OF ITS OWN, deliberately: this is a
	   row of the same series that screen lists, and two types for it would be
	   two places to keep in step with `plan_prices`. `From` is when that price
	   took effect, which is the fact that turns "they pay R$ 690,00" into "they
	   pay the price published in June". */
	Price *Price

	// Purchases is every checkout, paid or not, newest first.
	Purchases []Purchase
}

/*
Purchase is one checkout: what was asked for, how, and what became of it.

	IT IS NOT A LEDGER ROW AND MUST NOT BE READ AS ONE. An instalment plan is
	one sale collected several times and the ledger is keyed by the charge, so
	the biennial bought in three parts is three rows there and one line here.
	An operator adding up ledger rows to answer "what did they pay" would get
	the right total by luck and the wrong story every time.
*/
type Purchase struct {
	ID uuid.UUID

	OpenedAt time.Time
	MovedAt  time.Time

	// Stage is how far it got — `opened`, `charged`, `paid`, `abandoned`. It is
	// deliberately not the word `state`: that one is the subscription's and is
	// what access is computed from.
	Stage string

	// Cents is what was actually charged and Listed is the offer it came from.
	// They differ by the Pix discount, and an operator asked "why R$ 655,50 when
	// the site says R$ 690,00" needs both to answer in one sentence.
	Cents      int
	Listed     int
	Currency   string
	TermMonths int

	Method      string
	Instalments int

	// InvoiceURL is where the payer was sent. It is here so an operator can
	// give somebody back a Pix code they lost rather than tell them to start
	// again — which would open a second checkout for one sale.
	InvoiceURL string

	// PaidThrough is where the term stood after this purchase, absent when it
	// bought nothing or predates the log recording it.
	PaidThrough *time.Time
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

	// Holding is their subscription and their purchases, platform-wide. A zero
	// value is somebody who has never bought anything, which is most people and
	// is not an error.
	Holding func(ctx context.Context, accountID uuid.UUID) (Holding, error)
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

	// Holding is beside the schools and not inside one, because a subscription
	// covers every school (N-02). Absent for somebody who has never bought
	// anything, which is most people.
	Holding *holdingBody `json:"holding,omitempty"`
}

type holdingBody struct {
	State       string     `json:"state,omitempty"`
	Opens       bool       `json:"opens"`
	Model       string     `json:"model,omitempty"`
	Since       *time.Time `json:"since,omitempty"`
	PaidThrough *time.Time `json:"paidThrough,omitempty"`

	Price *priceBody `json:"price,omitempty"`

	// Purchases is never omitted once there is a holding at all: an operator
	// seeing no key cannot tell an empty history from a version that does not
	// send one.
	Purchases []purchaseBody `json:"purchases"`
}

type priceBody struct {
	TermMonths int       `json:"termMonths"`
	Cents      int       `json:"cents"`
	Currency   string    `json:"currency"`
	From       time.Time `json:"from"`
}

type purchaseBody struct {
	ID string `json:"id"`

	OpenedAt time.Time `json:"openedAt"`
	MovedAt  time.Time `json:"movedAt"`
	Stage    string    `json:"stage"`

	Cents      int    `json:"cents"`
	Listed     int    `json:"listed"`
	Currency   string `json:"currency"`
	TermMonths int    `json:"termMonths"`

	Method      string `json:"method"`
	Instalments int    `json:"instalments"`

	InvoiceURL  string     `json:"invoiceUrl,omitempty"`
	PaidThrough *time.Time `json:"paidThrough,omitempty"`
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

	/* AND WHAT THEY ARE PAYING FOR, WHICH IS NOT A SCHOOL'S. Last, because it
	   is the one read that is allowed to be absent: somebody who has never
	   bought anything has no holding, and the section is left out rather than
	   drawn empty. */
	holding, err := h.records.Holding(r.Context(), id)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a subscription",
			"error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}
	if holding.State != "" || len(holding.Purchases) > 0 {
		body.Holding = shownHolding(holding)
	}

	web.JSON(w, http.StatusOK, body)
}

func shownHolding(h Holding) *holdingBody {
	out := &holdingBody{
		State: h.State, Opens: h.Opens, Model: h.Model,
		Since: h.Since, PaidThrough: h.PaidThrough,
		Purchases: make([]purchaseBody, 0, len(h.Purchases)),
	}
	if h.Price != nil {
		out.Price = &priceBody{
			TermMonths: h.Price.TermMonths, Cents: h.Price.Cents,
			Currency: h.Price.Currency, From: h.Price.From,
		}
	}
	for _, p := range h.Purchases {
		out.Purchases = append(out.Purchases, purchaseBody{
			ID:       p.ID.String(),
			OpenedAt: p.OpenedAt, MovedAt: p.MovedAt, Stage: p.Stage,
			Cents: p.Cents, Listed: p.Listed, Currency: p.Currency,
			TermMonths: p.TermMonths,
			Method:     p.Method, Instalments: p.Instalments,
			InvoiceURL: p.InvoiceURL, PaidThrough: p.PaidThrough,
		})
	}
	return out
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
