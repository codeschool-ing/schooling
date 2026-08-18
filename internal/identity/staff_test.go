package identity_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/platform/web"
)

func TestARoleCoversTheOnesBelowIt(t *testing.T) {
	for _, c := range []struct {
		held, needed identity.Role
		want         bool
	}{
		{identity.RoleOwner, identity.RoleOwner, true},
		{identity.RoleOwner, identity.RoleOperator, true},
		{identity.RoleOwner, identity.RoleReadOnly, true},
		{identity.RoleOperator, identity.RoleOwner, false},
		{identity.RoleOperator, identity.RoleOperator, true},
		{identity.RoleOperator, identity.RoleReadOnly, true},
		{identity.RoleReadOnly, identity.RoleOperator, false},
		{identity.RoleReadOnly, identity.RoleReadOnly, true},
		{"", identity.RoleReadOnly, false},
		{"administrator", identity.RoleReadOnly, false}, // a role nobody defined covers nothing
	} {
		if got := c.held.Covers(c.needed); got != c.want {
			t.Errorf("%q.Covers(%q) = %v, want %v", c.held, c.needed, got, c.want)
		}
	}
}

// THE ONE THAT MATTERS.
//
// "Mandatory MFA for staff" is a claim about a state that has to be
// unreachable, and the state is reachable the moment somebody signs in with a
// password: a live session, a real role, no second factor. If the check lives
// anywhere except the door — in how accounts are set up, in a rule about
// enrolment — then that session works, and the guarantee was a description.
func TestAStaffSessionWithNoSecondFactorIsRefused(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	if err := store.Grant(ctx, account.ID, identity.RoleOwner, uuid.Nil); err != nil {
		t.Fatalf("granting: %v", err)
	}

	token, err := store.Issue(ctx, account.ID, "a test")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}

	rec := getStaff(t, store, identity.RoleReadOnly, token)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("an owner with no second factor reached a staff route with %d — mandatory MFA "+
			"is a description rather than a guarantee", rec.Code)
	}
	if body := rec.Body.String(); !strings.Contains(body, "second_factor_required") {
		t.Errorf("the refusal does not say what is missing, so nobody can act on it: %s", body)
	}

	// Enrol, present, and the same session now passes.
	secret, err := identity.NewTOTPSecret()
	if err != nil {
		t.Fatalf("making a secret: %v", err)
	}
	code := codeAt(t, secret, time.Now())

	if err := store.EnrolSecondFactor(ctx, account.ID, secret, code); err != nil {
		t.Fatalf("enrolling: %v", err)
	}
	if err := store.PresentSecondFactor(ctx, token, code); err != nil {
		t.Fatalf("presenting: %v", err)
	}

	if rec := getStaff(t, store, identity.RoleReadOnly, token); rec.Code != http.StatusOK {
		t.Errorf("after enrolling and presenting a second factor the route answered %d: %s",
			rec.Code, rec.Body.String())
	}
}

// Enrolment stores nothing until the person proves they can produce a code.
//
// Storing first and verifying later produces an account locked out by a QR code
// that was never scanned: the person believes they enrolled, the system
// believes it too, and it is discovered at the worst possible moment.
func TestEnrolmentRequiresProofBeforeItStoresAnything(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()

	account, _ := create(t, store)
	secret, err := identity.NewTOTPSecret()
	if err != nil {
		t.Fatalf("making a secret: %v", err)
	}

	if err := store.EnrolSecondFactor(ctx, account.ID, secret, "000000"); !errors.Is(err, identity.ErrWrongCode) {
		// 000000 is a valid code roughly one time in a million; a flake here is
		// a lottery win rather than a defect.
		t.Fatalf("enrolment with a wrong code gave %v, want ErrWrongCode", err)
	}

	var stored bool
	if err := pool.QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM account_credentials WHERE account_id = $1 AND kind = 'totp')
	`, account.ID).Scan(&stored); err != nil {
		t.Fatalf("looking for the credential: %v", err)
	}
	if stored {
		t.Error("a second factor was stored without proof that anybody can produce a code " +
			"from it — the account is locked out of every staff route and nothing says so")
	}
}

// A person who is not staff gets the same answer as a route that does not
// exist. Telling them "forbidden" tells them the route is there.
func TestSomebodyWhoIsNotStaffLearnsNothingAboutTheRoute(t *testing.T) {
	store := identity.NewStore(testPool(t))
	account, _ := create(t, store)

	token, err := store.Issue(context.Background(), account.ID, "a test")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}

	if rec := getStaff(t, store, identity.RoleReadOnly, token); rec.Code != http.StatusNotFound {
		t.Errorf("a student reached a staff route with %d, want 404 — 403 tells them it is there",
			rec.Code)
	}
}

// A role too small is a 403, because that person already knows the route
// exists: they are staff.
func TestStaffWithTooSmallARoleIsToldSo(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	if err := store.Grant(ctx, account.ID, identity.RoleReadOnly, uuid.Nil); err != nil {
		t.Fatalf("granting: %v", err)
	}
	token := enrolled(t, store, account.ID)

	if rec := getStaff(t, store, identity.RoleOwner, token); rec.Code != http.StatusForbidden {
		t.Errorf("read-only reached an owner route with %d, want 403", rec.Code)
	}
	if rec := getStaff(t, store, identity.RoleReadOnly, token); rec.Code != http.StatusOK {
		t.Errorf("read-only was refused its own route with %d", rec.Code)
	}
}

// THE SECOND ONE THAT MATTERS.
//
// Revoking a role while somebody is signed in, and leaving their session alive
// until it expires, is the difference between removing access and scheduling
// it — and the day this is used in anger is the day that difference is the
// entire point.
func TestRevokingARoleEndsTheSessionsThatHeldIt(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	if err := store.Grant(ctx, account.ID, identity.RoleOperator, uuid.Nil); err != nil {
		t.Fatalf("granting: %v", err)
	}
	token := enrolled(t, store, account.ID)

	if rec := getStaff(t, store, identity.RoleOperator, token); rec.Code != http.StatusOK {
		t.Fatalf("the operator could not reach their own route: %d", rec.Code)
	}

	if err := store.RevokeStaff(ctx, account.ID); err != nil {
		t.Fatalf("revoking: %v", err)
	}

	if _, err := store.Verify(ctx, token); !errors.Is(err, identity.ErrNoSession) {
		t.Error("the session survived the revocation — access was scheduled rather than removed")
	}
	if rec := getStaff(t, store, identity.RoleOperator, token); rec.Code == http.StatusOK {
		t.Error("a former operator still reaches an operator route")
	}
}

// A code that is right on one session does not mark another. The factor
// belongs to the sitting, not to the account.
func TestPresentingTheFactorMarksOnlyThatSession(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	if err := store.Grant(ctx, account.ID, identity.RoleOwner, uuid.Nil); err != nil {
		t.Fatalf("granting: %v", err)
	}

	secret, err := identity.NewTOTPSecret()
	if err != nil {
		t.Fatalf("making a secret: %v", err)
	}
	code := codeAt(t, secret, time.Now())
	if err := store.EnrolSecondFactor(ctx, account.ID, secret, code); err != nil {
		t.Fatalf("enrolling: %v", err)
	}

	here, err := store.Issue(ctx, account.ID, "the browser in front of me")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}
	elsewhere, err := store.Issue(ctx, account.ID, "somewhere else")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}

	if err := store.PresentSecondFactor(ctx, here, code); err != nil {
		t.Fatalf("presenting: %v", err)
	}

	if rec := getStaff(t, store, identity.RoleOwner, elsewhere); rec.Code != http.StatusUnauthorized {
		t.Errorf("a second session was marked by a code shown on another: %d — the factor is "+
			"attached to the account rather than to the sitting", rec.Code)
	}
}

/* ---------- helpers ---------- */

// getStaff calls a route guarded by RequireStaff, through the same middleware
// cmd/api uses.
func getStaff(t *testing.T, store *identity.Store, needed identity.Role, token string) *httptest.ResponseRecorder {
	t.Helper()

	guarded := web.Chain(
		http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			web.JSON(w, http.StatusOK, map[string]string{"status": "the console"})
		}),
		identity.Authenticate(store),
		identity.RequireStaff(store, needed),
	)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/console/whatever", nil)
	req.AddCookie(&http.Cookie{Name: identity.CookieName, Value: token})
	rec := httptest.NewRecorder()
	guarded.ServeHTTP(rec, req)
	return rec
}

// enrolled gives an account a second factor and returns a session that has
// presented it.
func enrolled(t *testing.T, store *identity.Store, accountID uuid.UUID) string {
	t.Helper()
	ctx := context.Background()

	secret, err := identity.NewTOTPSecret()
	if err != nil {
		t.Fatalf("making a secret: %v", err)
	}
	code := codeAt(t, secret, time.Now())

	if err := store.EnrolSecondFactor(ctx, accountID, secret, code); err != nil {
		t.Fatalf("enrolling: %v", err)
	}
	token, err := store.Issue(ctx, accountID, "a test")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}
	if err := store.PresentSecondFactor(ctx, token, code); err != nil {
		t.Fatalf("presenting: %v", err)
	}
	return token
}
