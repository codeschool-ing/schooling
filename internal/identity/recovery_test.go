package identity_test

import (
	"context"
	"errors"
	"net/http"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/identity"
)

/* Recovery codes.

   THE SCREEN PROMISED THESE BEFORE THEY EXISTED. "Enter the code from your
   authenticator app, or a recovery code" has been on the sign-in screen since
   the second factor shipped, and nothing issued one — so the only way back into
   an account whose phone was gone was an edit to the database, which is the
   arrangement the console exists to end. */

// ENROLLING ISSUES THEM, because there is no second moment when somebody is
// looking at a screen ready to write ten strings down. A feature that has to be
// opened later is a feature nobody opens.
func TestEnrollingIssuesRecoveryCodes(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	secret, err := identity.NewTOTPSecret()
	if err != nil {
		t.Fatalf("making a secret: %v", err)
	}

	codes, err := store.EnrolSecondFactor(ctx, account.ID, noSession, secret,
		codeAt(t, secret, time.Now()))
	if err != nil {
		t.Fatalf("enrolling: %v", err)
	}

	if len(codes) != 10 {
		t.Fatalf("enrolling handed over %d codes, want 10", len(codes))
	}

	seen := map[string]bool{}
	shape := regexp.MustCompile(`^[0-9A-HJ-NP-TV-Z]{5}-[0-9A-HJ-NP-TV-Z]{5}$`)
	for _, code := range codes {
		if !shape.MatchString(code) {
			t.Errorf("%q is not the shape a person is asked to write down", code)
		}
		/* THE LETTERS PEOPLE MISREAD ARE NOT IN IT. `I` and `L` are read as
		   `1`, `O` as `0`, and a code that cannot be transcribed off a piece of
		   paper is a code that does not work on the day it is needed. */
		if strings.ContainsAny(code, "ILOU") {
			t.Errorf("%q contains a character that is misread off paper", code)
		}
		if seen[code] {
			t.Errorf("%q was issued twice in one set", code)
		}
		seen[code] = true
	}

	left, err := store.RecoveryCodesLeft(ctx, account.ID)
	if err != nil {
		t.Fatalf("counting: %v", err)
	}
	if left != 10 {
		t.Errorf("%d codes are unspent, want 10", left)
	}
}

// A CODE WORKS ONCE. Twice would mean somebody who saw it over a shoulder can
// still use it after the person who owned it did.
func TestARecoveryCodeIsSpentWhenItIsUsed(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	codes := enrolWithCodes(t, store, account.ID)

	if err := store.SpendRecoveryCode(ctx, account.ID, codes[0]); err != nil {
		t.Fatalf("spending: %v", err)
	}
	if err := store.SpendRecoveryCode(ctx, account.ID, codes[0]); !errors.Is(err, identity.ErrNoRecoveryCode) {
		t.Errorf("the same code was spent twice: %v", err)
	}

	left, err := store.RecoveryCodesLeft(ctx, account.ID)
	if err != nil {
		t.Fatalf("counting: %v", err)
	}
	if left != 9 {
		t.Errorf("%d codes are unspent after spending one, want 9", left)
	}
}

// AND IT IS READ THE WAY A PERSON TYPES IT. A code is copied off paper, so the
// separator and the case are what the reader does, not what the code is.
func TestARecoveryCodeIsReadTheWayItIsTyped(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	codes := enrolWithCodes(t, store, account.ID)

	typed := strings.ToLower(strings.ReplaceAll(codes[0], "-", " "))
	if err := store.SpendRecoveryCode(ctx, account.ID, typed); err != nil {
		t.Errorf("%q was refused for the code %q — the separator and the case are "+
			"what the person did, not what the code is", typed, codes[0])
	}
}

// SOMEBODY ELSE'S CODE IS NOT A CODE. The lookup is by account as well as by
// hash, so a set issued to one person cannot open another's door.
func TestARecoveryCodeBelongsToOneAccount(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	mine, _ := create(t, store)
	theirs, _ := create(t, store)
	codes := enrolWithCodes(t, store, mine.ID)

	if err := store.SpendRecoveryCode(ctx, theirs.ID, codes[0]); !errors.Is(err, identity.ErrNoRecoveryCode) {
		t.Errorf("one account's recovery code was accepted for another: %v", err)
	}
}

// REISSUING REPLACES, and that is the whole reason to reissue. A set that grew
// would leave a code printed two years ago working after somebody replaced them
// because they believed the old ones were compromised.
func TestReissuingReplacesTheSet(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	old := enrolWithCodes(t, store, account.ID)

	fresh, err := store.IssueRecoveryCodes(ctx, account.ID)
	if err != nil {
		t.Fatalf("reissuing: %v", err)
	}
	if len(fresh) != 10 {
		t.Fatalf("reissuing handed over %d codes, want 10", len(fresh))
	}

	if err := store.SpendRecoveryCode(ctx, account.ID, old[0]); !errors.Is(err, identity.ErrNoRecoveryCode) {
		t.Error("a code from the replaced set still works, which is the one thing " +
			"reissuing is asked to prevent")
	}
	if err := store.SpendRecoveryCode(ctx, account.ID, fresh[0]); err != nil {
		t.Errorf("a code from the new set does not work: %v", err)
	}

	left, err := store.RecoveryCodesLeft(ctx, account.ID)
	if err != nil {
		t.Fatalf("counting: %v", err)
	}
	if left != 9 {
		t.Errorf("%d codes are unspent, want 9 — the old set should be gone entirely", left)
	}
}

// THE DOOR TAKES ONE, which is the point of all of the above: the person whose
// phone is gone gets through with what they wrote down.
func TestARecoveryCodeOpensTheDoorLikeAnAppCode(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	if err := store.Grant(ctx, account.ID, identity.RoleOwner, uuid.Nil); err != nil {
		t.Fatalf("granting: %v", err)
	}
	codes := enrolWithCodes(t, store, account.ID)

	token, err := store.Issue(ctx, account.ID, "the phone is gone")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}
	if rec := getStaff(t, store, identity.RoleOwner, token); rec.Code == http.StatusOK {
		t.Fatal("a session with no factor shown was let in before the interesting part")
	}

	if err := store.PresentSecondFactor(ctx, token, codes[0]); err != nil {
		t.Fatalf("presenting a recovery code: %v", err)
	}
	if rec := getStaff(t, store, identity.RoleOwner, token); rec.Code != http.StatusOK {
		t.Errorf("a recovery code was accepted and the door still refused: %d", rec.Code)
	}

	// And it is spent by having been used, not merely checked.
	left, err := store.RecoveryCodesLeft(ctx, account.ID)
	if err != nil {
		t.Fatalf("counting: %v", err)
	}
	if left != 9 {
		t.Errorf("%d codes are unspent after one opened the door, want 9", left)
	}
}

// AND A WRONG CODE IS STILL WRONG. The recovery path must not turn a refusal
// into an acceptance for anything that merely fails to be a TOTP code.
func TestNonsenseIsRefusedByBothPaths(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	account, _ := create(t, store)
	enrolWithCodes(t, store, account.ID)

	token, err := store.Issue(ctx, account.ID, "a test")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}

	for _, wrong := range []string{"000000", "NOTAC-ODEXX", "", "----------"} {
		if err := store.PresentSecondFactor(ctx, token, wrong); err == nil {
			t.Errorf("%q was accepted as a second factor", wrong)
		}
	}
}

// enrolWithCodes gives an account a second factor and returns its recovery
// codes.
func enrolWithCodes(t *testing.T, store *identity.Store, accountID uuid.UUID) []string {
	t.Helper()
	secret, err := identity.NewTOTPSecret()
	if err != nil {
		t.Fatalf("making a secret: %v", err)
	}
	codes, err := store.EnrolSecondFactor(context.Background(), accountID, noSession, secret,
		codeAt(t, secret, time.Now()))
	if err != nil {
		t.Fatalf("enrolling: %v", err)
	}
	return codes
}
