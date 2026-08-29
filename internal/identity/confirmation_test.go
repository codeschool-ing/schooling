package identity_test

import (
	"context"
	"errors"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/identity"
)

/* Confirming an address.

   `accounts.email_verified_at` has existed since migration 0004 with nothing
   writing it — read by the personal-data export, counted by a funnel step that
   says out loud it cannot be counted. These hold the thing that finally writes
   it, and the four ways a link can be no good. */

// confirmed reads the fact off the account row, which is where it lives — the
// three doors into a session all answer with this account and all three have to
// tell the screen whether to show the nudge.
func confirmed(t *testing.T, store *identity.Store, id uuid.UUID) (time.Time, bool) {
	t.Helper()
	account, err := store.ByID(context.Background(), id)
	if err != nil {
		t.Fatalf("reading the account: %v", err)
	}
	if account.EmailVerifiedAt == nil {
		return time.Time{}, false
	}
	return *account.EmailVerifiedAt, true
}

// THE HAPPY PATH, AND IT WRITES THE COLUMN. That is the whole point of the
// change: a fact about an account that nothing has ever been able to record.
func TestFollowingTheLinkConfirmsTheAddress(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, email := create(t, store)

	if _, yes := confirmed(t, store, account.ID); yes {
		t.Fatal("a new account is already confirmed")
	}

	link, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}
	if link.Token == "" {
		t.Fatal("the link carries no token")
	}
	if !strings.EqualFold(link.Email, email) {
		t.Errorf("the link was issued for %q, want the account's %q", link.Email, email)
	}
	if until := time.Until(link.ExpiresAt); until < 23*time.Hour || until > 25*time.Hour {
		t.Errorf("the link lives for %v, want about a day", until)
	}

	got, err := store.ConfirmEmail(ctx, link.Token)
	if err != nil {
		t.Fatalf("confirming: %v", err)
	}
	if got.ID != account.ID {
		t.Errorf("the link confirmed %v, want %v", got.ID, account.ID)
	}

	at, yes := confirmed(t, store, account.ID)
	if !yes {
		t.Fatal("the address is still unconfirmed")
	}
	if time.Since(at) > time.Minute {
		t.Errorf("the address was confirmed at %v, which is not now", at)
	}
}

/*
A LINK WORKS ONCE.

	The redemption is one statement that both decides and records, so two
	requests carrying the same token cannot both find it unspent. This is the
	sequential half; the concurrent half is below.
*/
func TestALinkCannotBeFollowedTwice(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, _ := create(t, store)

	link, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}
	if _, err := store.ConfirmEmail(ctx, link.Token); err != nil {
		t.Fatalf("the first follow failed: %v", err)
	}
	if _, err := store.ConfirmEmail(ctx, link.Token); !errors.Is(err, identity.ErrNoConfirmation) {
		t.Errorf("the second follow answered %v, want ErrNoConfirmation", err)
	}
}

// AND ONLY ONE OF TWO SIMULTANEOUS FOLLOWS SUCCEEDS. A mail client that
// prefetches links, or somebody double-clicking, is two requests at once — and
// read-then-write would let both through.
func TestTwoSimultaneousFollowsSpendOneLink(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, _ := create(t, store)

	link, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	var wg sync.WaitGroup
	results := make([]error, 8)
	for i := range results {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, results[i] = store.ConfirmEmail(ctx, link.Token)
		}()
	}
	wg.Wait()

	won := 0
	for _, err := range results {
		switch {
		case err == nil:
			won++
		case errors.Is(err, identity.ErrNoConfirmation):
		default:
			t.Errorf("an unexpected failure: %v", err)
		}
	}
	if won != 1 {
		t.Errorf("%d of 8 simultaneous follows succeeded, want exactly 1", won)
	}
}

// A SECOND LINK DOES NOT MOVE THE DATE. `email_verified_at` is when they proved
// it, not when they last clicked — and because resending ADDS links rather than
// replacing them, a second one arriving later is the normal case rather than
// the odd one.
func TestConfirmingAgainKeepsTheFirstDate(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, _ := create(t, store)

	first, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing the first: %v", err)
	}
	second, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing the second: %v", err)
	}
	if first.Token == second.Token {
		t.Fatal("two links carry the same token")
	}

	if _, err := store.ConfirmEmail(ctx, first.Token); err != nil {
		t.Fatalf("following the first: %v", err)
	}
	was, _ := confirmed(t, store, account.ID)

	/* THE FIRST LINK DID NOT KILL THE SECOND, which is this store's difference
	   from IssueRecoveryCodes and the reason a slow message still works. */
	if _, err := store.ConfirmEmail(ctx, second.Token); err != nil {
		t.Fatalf("the second link stopped working when the first was used: %v", err)
	}
	now, _ := confirmed(t, store, account.ID)
	if !now.Equal(was) {
		t.Errorf("the second follow moved the date from %v to %v", was, now)
	}
}

// A TOKEN NOBODY ISSUED IS THE SAME ANSWER AS A SPENT ONE. Telling them apart
// would confirm to a guesser that a token is real.
func TestAnInventedTokenIsRefused(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	for _, token := range []string{"", "not-a-token", strings.Repeat("A", 43)} {
		if _, err := store.ConfirmEmail(ctx, token); !errors.Is(err, identity.ErrNoConfirmation) {
			t.Errorf("%q answered %v, want ErrNoConfirmation", token, err)
		}
	}
}

/*
AN EXPIRED LINK IS NO LINK.

	The row is aged in place rather than by waiting a day, because a test that
	takes a day is a test nobody runs. What is being checked is that the expiry
	is in the condition of the statement that redeems, which is where it has to
	be for the database rather than the process to settle it.
*/
func TestAnExpiredLinkIsRefused(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	account, _ := create(t, store)

	link, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	if _, err := pool.Exec(ctx, `
		UPDATE account_email_confirmations
		   SET created_at = now() - interval '8 days', expires_at = now() - interval '7 days'
		 WHERE account_id = $1
	`, account.ID); err != nil {
		t.Fatalf("ageing the link: %v", err)
	}

	if _, err := store.ConfirmEmail(ctx, link.Token); !errors.Is(err, identity.ErrNoConfirmation) {
		t.Errorf("an expired link answered %v, want ErrNoConfirmation", err)
	}
	if _, yes := confirmed(t, store, account.ID); yes {
		t.Error("an expired link confirmed the address anyway")
	}
}

/*
A LINK IS ABOUT THE ADDRESS IT WAS SENT TO.

	What somebody proves by following it is that they can read the mail that
	arrived at ONE address. If the account has since become a different one,
	nobody has proved anything about the new one — and this is the half of
	changing an address that cannot be added afterwards, because a link issued
	before the guard existed would sail through it.
*/
func TestALinkDoesNotConfirmAnAddressItWasNotSentTo(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	account, _ := create(t, store)

	link, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	// Changing an address is not built; this is the state it would leave.
	if _, err := pool.Exec(ctx,
		`UPDATE accounts SET email = $2 WHERE id = $1`, account.ID, address(t)); err != nil {
		t.Fatalf("moving the address: %v", err)
	}

	if _, err := store.ConfirmEmail(ctx, link.Token); !errors.Is(err, identity.ErrNoConfirmation) {
		t.Errorf("a link for the old address answered %v, want ErrNoConfirmation", err)
	}
	if _, yes := confirmed(t, store, account.ID); yes {
		t.Error("a link for the old address confirmed the new one")
	}
}

// AN ACCOUNT THAT IS NOT THERE CANNOT BE SENT A LINK, and says so with the
// error every caller in this package already handles.
func TestIssuingForNobodyIsErrNoAccount(t *testing.T) {
	store := identity.NewStore(testPool(t))

	_, err := store.IssueEmailConfirmation(context.Background(), uuid.New())
	if !errors.Is(err, identity.ErrNoAccount) {
		t.Errorf("issuing for a stranger answered %v, want ErrNoAccount", err)
	}
}

// THE TOKEN IS NOT IN THE TABLE. What is stored is a hash, for session tokens'
// reason: a table somebody can read is a table somebody can use.
func TestTheTableHoldsNoTokenAnybodyCouldUse(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	account, _ := create(t, store)

	link, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	var found int
	if err := pool.QueryRow(ctx, `
		SELECT count(*) FROM account_email_confirmations
		 WHERE account_id = $1 AND encode(token_hash, 'escape') LIKE '%' || $2 || '%'
	`, account.ID, link.Token).Scan(&found); err != nil {
		t.Fatalf("looking for the token: %v", err)
	}
	if found != 0 {
		t.Error("the confirmation row carries the token itself")
	}
}

/*
THE ACCOUNT SAYS WHETHER A LINK IS STILL WAITING TO BE FOLLOWED.

	It is what stops the nudge banner claiming "we sent a link to X" at somebody
	who was never sent one — every account created before confirmations existed,
	and anybody whose link expired unread.

	The four conditions are the four `ConfirmEmail` redeems on, which is why
	they are one constant and not two lists that can drift.
*/
func TestAnAccountKnowsWhetherALinkIsOutstanding(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()

	pending := func(id uuid.UUID) bool {
		t.Helper()
		account, err := store.ByID(ctx, id)
		if err != nil {
			t.Fatalf("reading the account: %v", err)
		}
		return account.ConfirmationPending
	}

	account, _ := create(t, store)
	if pending(account.ID) {
		t.Error("a brand new account has a link outstanding and nothing issued one")
	}

	link, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}
	if !pending(account.ID) {
		t.Error("a link was issued and the account does not say so")
	}

	// SPENT IS NOT OUTSTANDING. Following the link is the whole point, and a
	// banner still offering to resend afterwards would be offering nothing.
	if _, err := store.ConfirmEmail(ctx, link.Token); err != nil {
		t.Fatalf("confirming: %v", err)
	}
	if pending(account.ID) {
		t.Error("a spent link still counts as outstanding")
	}
}

// AND AN EXPIRED ONE IS NOT OUTSTANDING EITHER, which is the case that made
// this worth a column: a link nobody followed within the day is gone, and the
// screen has to offer a new one rather than point at the old.
func TestAnExpiredLinkIsNotOutstanding(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	account, _ := create(t, store)

	if _, err := store.IssueEmailConfirmation(ctx, account.ID); err != nil {
		t.Fatalf("issuing: %v", err)
	}
	if _, err := pool.Exec(ctx, `
		UPDATE account_email_confirmations
		   SET created_at = now() - interval '3 days', expires_at = now() - interval '2 days'
		 WHERE account_id = $1
	`, account.ID); err != nil {
		t.Fatalf("ageing the link: %v", err)
	}

	got, err := store.ByID(ctx, account.ID)
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if got.ConfirmationPending {
		t.Error("an expired link still counts as outstanding")
	}
}

// A LINK FOR AN ADDRESS THE ACCOUNT HAS LEFT IS NOT OUTSTANDING, for
// `ConfirmEmail`'s reason: it cannot be redeemed, so offering to resend it
// would be offering something that no longer works.
func TestALinkForAnOldAddressIsNotOutstanding(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	account, _ := create(t, store)

	if _, err := store.IssueEmailConfirmation(ctx, account.ID); err != nil {
		t.Fatalf("issuing: %v", err)
	}
	if _, err := pool.Exec(ctx,
		`UPDATE accounts SET email = $2 WHERE id = $1`, account.ID, address(t)); err != nil {
		t.Fatalf("moving the address: %v", err)
	}

	got, err := store.ByID(ctx, account.ID)
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if got.ConfirmationPending {
		t.Error("a link for the old address still counts as outstanding")
	}
}

/*
AND THE LINK LIVES AS LONG AS THE PARAMETER SAYS.

	The test above wires nothing and so measures the twenty-four hours this
	package shipped with. What `0046` adds is that a deployment can lengthen the
	leash for students who read their mail on Monday, or shorten it, and that
	both ends are fenced: under an hour somebody who stepped away has to ask
	again, over three days a forwarded message is a standing key.

	ONE DECLARATION FEEDS BOTH LINKS. `change.go` used to carry a `changeLife`
	of its own with a comment saying it was the same number for the same reason,
	which is two names for one fact — so this checks the change link moves with
	it, and that is the assertion that would fail if somebody re-split them.
*/
func TestTheLinkLivesAsLongAsTheParameterSays(t *testing.T) {
	for _, hours := range []int{2, 48} {
		store := identity.NewStore(testPool(t)).WithLimits(identity.Limits{
			ConfirmationLife: func(context.Context) int { return hours },
		})
		ctx := context.Background()
		account, _ := create(t, store)

		link, err := store.IssueEmailConfirmation(ctx, account.ID)
		if err != nil {
			t.Fatalf("at %d hours, minting a confirmation: %v", hours, err)
		}
		if until := time.Until(link.ExpiresAt); until < time.Duration(hours-1)*time.Hour ||
			until > time.Duration(hours)*time.Hour {

			t.Errorf("at %d hours the confirmation link expires in %s", hours, until)
		}

		moving, err := store.RequestEmailChange(ctx, account.ID, address(t))
		if err != nil {
			t.Fatalf("at %d hours, asking to move: %v", hours, err)
		}
		if until := time.Until(moving.ExpiresAt); until < time.Duration(hours-1)*time.Hour ||
			until > time.Duration(hours)*time.Hour {

			t.Errorf("at %d hours the change link expires in %s — the two links are one "+
				"declaration, and this is what says so", hours, until)
		}
	}
}
