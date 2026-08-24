package identity_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/codeschool-ing/schooling/internal/identity"
)

/* Seeing what a student sees, and the four things that keep it safe.

   EVERY FAILURE HERE IS SILENT AND SERIOUS. A viewing that can write forges a
   student's work; one that survives its link being shared is a credential in a
   URL; one that crosses schools is a session nobody authorised. None of them
   looks wrong from the outside — the screens render, the banner appears, and
   the audit says somebody looked at exactly what they said they would. */

func operatorAndStudent(t *testing.T, store *identity.Store) (uuid.UUID, uuid.UUID) {
	t.Helper()
	operator, _ := create(t, store)
	student, _ := create(t, store)
	return operator.ID, student.ID
}

// A school to bind a viewing to. The row is all this needs — no host, no
// catalogue: what is under test is the session, and `viewingBelongsHere` in
// `cmd/api` is what compares it against the school a request arrived at.
func aSchoolID(t *testing.T, pool interface {
	QueryRow(context.Context, string, ...any) pgx.Row
},
) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		"view-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:10]).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

// A LINK WORKS ONCE. It is a credential in a URL — in a history, in a referrer,
// in a message somebody pasted — so the second use of it is refused whether it
// is the same person or not.
func TestAViewingLinkIsSpentOnFirstUse(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	operator, student := operatorAndStudent(t, store)
	school := aSchoolID(t, pool)

	token, err := store.StartViewing(ctx, operator, student, school)
	if err != nil {
		t.Fatalf("starting a viewing: %v", err)
	}

	if err := store.RedeemViewing(ctx, token); err != nil {
		t.Fatalf("the first use of a link was refused: %v", err)
	}
	if err := store.RedeemViewing(ctx, token); !errors.Is(err, identity.ErrNotAViewing) {
		t.Errorf("the second use answered %v — a link in somebody's history is a link "+
			"somebody else can follow", err)
	}
}

// AND IT IS NOT A SESSION UNTIL IT HAS BEEN REDEEMED. A token that arrived in a
// cookie without ever going through the handoff is a token that was intercepted
// on its way, and honouring it would make the single-use rule decorative.
func TestATokenThatWasNeverRedeemedIsNotASession(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	operator, student := operatorAndStudent(t, store)
	school := aSchoolID(t, pool)

	token, err := store.StartViewing(ctx, operator, student, school)
	if err != nil {
		t.Fatal(err)
	}

	if _, _, err := store.Verify(ctx, token, nil); !errors.Is(err, identity.ErrNoSession) {
		t.Errorf("an unredeemed viewing verified as a session: %v", err)
	}

	if err := store.RedeemViewing(ctx, token); err != nil {
		t.Fatal(err)
	}
	who, seeing, err := store.Verify(ctx, token, nil)
	if err != nil {
		t.Fatalf("a redeemed viewing did not verify: %v", err)
	}
	if who.ID != student {
		t.Errorf("the viewing is of %v and verified as %v", student, who.ID)
	}
	if !seeing.Is() {
		t.Fatal("a redeemed viewing verified as an ordinary session — no banner, no refusal")
	}
	if seeing.By != operator {
		t.Errorf("the viewing says it is by %v, want %v", seeing.By, operator)
	}
	if seeing.School != school {
		t.Errorf("the viewing is bound to %v, want %v", seeing.School, school)
	}
}

// AN ORDINARY SESSION IS NOT A VIEWING, which is the other half of the same
// claim: if `Verify` reported one for everybody the banner would be on every
// student's screen and the refusal would be on every student's work.
func TestAnOrdinarySessionIsNotAViewing(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	somebody, _ := create(t, store)
	student := somebody.ID

	token, err := store.Issue(ctx, student, "a browser")
	if err != nil {
		t.Fatal(err)
	}
	_, seeing, err := store.Verify(ctx, token, nil)
	if err != nil {
		t.Fatal(err)
	}
	if seeing.Is() {
		t.Error("an ordinary sign-in came back as somebody viewing somebody")
	}
}

// AN OPERATOR CANNOT VIEW THEMSELVES. Not a hazard — nonsense, and nonsense that
// would put a banner with somebody's own name on their own screens.
func TestAnOperatorCannotViewThemselves(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	somebody, _ := create(t, store)
	me := somebody.ID

	if _, err := store.StartViewing(ctx, me, me, aSchoolID(t, pool)); err == nil {
		t.Error("an operator started a viewing of themselves")
	}
}

/* ---------- the fourth restraint, which K-02 does not name ---------- */

// A VIEWING MAY READ AND MAY NOT ACT.
//
// One rule on the method rather than a list of protected routes, because a list
// is where the route nobody added lives. An operator who can answer an exam
// question as a student can forge a pass, and the audit would explain that
// afterwards rather than prevent it.
func TestAViewingIsRefusedEverythingButAGet(t *testing.T) {
	reached := false
	handler := identity.RefuseWrites(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		reached = true
	}))

	viewing := identity.Viewing{By: uuid.New(), School: uuid.New()}

	for _, method := range []string{http.MethodGet, http.MethodHead} {
		reached = false
		r := httptest.NewRequest(method, "/api/v1/anything", nil)
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, r.WithContext(identity.WithViewing(r.Context(), viewing)))
		if !reached {
			t.Errorf("a viewing was refused a %s, and looking is the whole feature", method)
		}
	}

	for _, method := range []string{
		http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete,
	} {
		reached = false
		r := httptest.NewRequest(method, "/api/v1/anything", nil)
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, r.WithContext(identity.WithViewing(r.Context(), viewing)))
		if reached {
			t.Errorf("a viewing was allowed a %s — that is an operator acting as a student",
				method)
		}
		if w.Code != http.StatusForbidden {
			t.Errorf("a %s by a viewing answered %d, want 403", method, w.Code)
		}
	}
}

// AND A STUDENT USING THEIR OWN ACCOUNT IS NOT REFUSED ANYTHING. The rule is
// about viewings; a refusal that leaked onto ordinary sessions would be every
// student unable to answer a question, which is the failure that would be
// noticed instantly and is worth a line anyway.
func TestAnOrdinarySessionMayStillWrite(t *testing.T) {
	reached := false
	handler := identity.RefuseWrites(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		reached = true
	}))

	r := httptest.NewRequest(http.MethodPost, "/api/v1/anything", nil)
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, r)
	if !reached {
		t.Errorf("a student's own POST was refused with %d", w.Code)
	}
}
