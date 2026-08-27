package identity_test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/identity"
)

/* Moving an account to a different address.

   THE PROPERTY EVERY TEST HERE IS ABOUT is that nothing happens until the link
   comes back. A typo has to be a message nobody can read, and never an account
   nobody can reach — which is the failure this feature would otherwise be a new
   way to cause. */

// THE HAPPY PATH, AND IT MOVES THE ADDRESS AND STAMPS IT VERIFIED.
func TestFollowingTheLinkMovesTheAddress(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, was := create(t, store)
	next := address(t)

	change, err := store.RequestEmailChange(ctx, account.ID, next)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if !strings.EqualFold(change.Email, next) {
		t.Errorf("the link was issued for %q, want %q", change.Email, next)
	}

	/* NOTHING HAS HAPPENED YET, which is the whole design and is checked before
	   the link is followed rather than inferred afterwards. */
	before, err := store.ByID(ctx, account.ID)
	if err != nil {
		t.Fatalf("reading the account: %v", err)
	}
	if !strings.EqualFold(before.Email, was) {
		t.Fatalf("the address moved to %q before the link was followed", before.Email)
	}

	moved, previous, err := store.ConfirmEmailChange(ctx, change.Token)
	if err != nil {
		t.Fatalf("following: %v", err)
	}
	if !strings.EqualFold(moved.Email, next) {
		t.Errorf("the account is on %q, want %q", moved.Email, next)
	}
	if !strings.EqualFold(previous, was) {
		t.Errorf("the old address came back as %q, want %q — it is where the notice goes",
			previous, was)
	}
	if moved.EmailVerifiedAt == nil {
		t.Error("the new address is not marked verified, and following the link is the proof")
	}
}

/*
THE OLD CONFIRMATION LINK STOPS WORKING, FOR FREE.

	`ConfirmEmail` requires the token's address to equal the account's, which
	`0035` added so a link for one address could not confirm another. Nothing in
	this feature touches that condition — and it means every link sitting in the
	old inbox dies the moment the address moves. Held here because it is a
	guarantee people would otherwise assume rather than know.
*/
func TestAChangeKillsTheLinksSentToTheOldAddress(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, _ := create(t, store)

	old, err := store.IssueEmailConfirmation(ctx, account.ID)
	if err != nil {
		t.Fatalf("issuing a confirmation: %v", err)
	}

	change, err := store.RequestEmailChange(ctx, account.ID, address(t))
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if _, _, err := store.ConfirmEmailChange(ctx, change.Token); err != nil {
		t.Fatalf("following: %v", err)
	}

	if _, err := store.ConfirmEmail(ctx, old.Token); !errors.Is(err, identity.ErrNoConfirmation) {
		t.Errorf("a link sent to the old address answered %v, want ErrNoConfirmation", err)
	}
}

// A CHANGE LINK WORKS ONCE. The redemption is one statement that both decides
// and records, so a mail client that prefetches links cannot spend it twice.
func TestAChangeLinkCannotBeFollowedTwice(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, _ := create(t, store)

	change, err := store.RequestEmailChange(ctx, account.ID, address(t))
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if _, _, err := store.ConfirmEmailChange(ctx, change.Token); err != nil {
		t.Fatalf("the first follow failed: %v", err)
	}
	if _, _, err := store.ConfirmEmailChange(ctx, change.Token); !errors.Is(err, identity.ErrNoChange) {
		t.Errorf("the second follow answered %v, want ErrNoChange", err)
	}
}

// AN EXPIRED LINK MOVES NOTHING. Aged in place rather than by waiting a day: a
// test that takes a day is a test nobody runs, and what is being checked is
// that the expiry is in the statement's condition.
func TestAnExpiredChangeLinkIsRefused(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	account, was := create(t, store)

	change, err := store.RequestEmailChange(ctx, account.ID, address(t))
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if _, err := pool.Exec(ctx, `
		UPDATE account_email_changes
		   SET created_at = now() - interval '8 days', expires_at = now() - interval '7 days'
		 WHERE account_id = $1
	`, account.ID); err != nil {
		t.Fatalf("ageing the link: %v", err)
	}

	if _, _, err := store.ConfirmEmailChange(ctx, change.Token); !errors.Is(err, identity.ErrNoChange) {
		t.Errorf("an expired link answered %v, want ErrNoChange", err)
	}
	now, err := store.ByID(ctx, account.ID)
	if err != nil {
		t.Fatalf("reading the account: %v", err)
	}
	if !strings.EqualFold(now.Email, was) {
		t.Errorf("an expired link moved the address to %q anyway", now.Email)
	}
}

/*
THE CAP, WHICH IS THE ONE ABUSE SURFACE THIS FEATURE OPENS.

	An authenticated session can make this platform post a message to an address
	of the sender's choosing. What arrives does nothing unless clicked, but it
	arrives on our domain and our reputation, to somebody who did not ask. Three
	an hour is a number a person correcting a typo never reaches.
*/
func TestAnAccountCannotPostStrangersMailAllDay(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, _ := create(t, store)

	for i := 0; i < 3; i++ {
		if _, err := store.RequestEmailChange(ctx, account.ID, address(t)); err != nil {
			t.Fatalf("ask %d: %v", i+1, err)
		}
	}
	if _, err := store.RequestEmailChange(ctx, account.ID, address(t)); !errors.Is(err, identity.ErrTooManyChanges) {
		t.Errorf("the fourth ask answered %v, want ErrTooManyChanges", err)
	}
}

// AND THE CAP IS A WINDOW AND NOT A LIFETIME. Somebody who mistyped three times
// this morning has to be able to try again this afternoon.
func TestTheCapLetsGoAfterTheWindow(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	account, _ := create(t, store)

	for i := 0; i < 3; i++ {
		if _, err := store.RequestEmailChange(ctx, account.ID, address(t)); err != nil {
			t.Fatalf("ask %d: %v", i+1, err)
		}
	}
	if _, err := pool.Exec(ctx, `
		UPDATE account_email_changes SET created_at = now() - interval '2 hours'
		 WHERE account_id = $1
	`, account.ID); err != nil {
		t.Fatalf("ageing the asks: %v", err)
	}

	if _, err := store.RequestEmailChange(ctx, account.ID, address(t)); err != nil {
		t.Errorf("an ask after the window answered %v, want it to be allowed", err)
	}
}

// MOVING SOMEWHERE THE ACCOUNT ALREADY IS DOES NOTHING AND SAYS SO, rather than
// spending one of the three above and sending a message about a change that
// cannot happen. Case and space do not make it a different address.
func TestMovingToTheSameAddressIsRefused(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, was := create(t, store)

	for _, same := range []string{was, strings.ToUpper(was), "  " + was + "  "} {
		if _, err := store.RequestEmailChange(ctx, account.ID, same); !errors.Is(err, identity.ErrSameAddress) {
			t.Errorf("asking to move to %q answered %v, want ErrSameAddress", same, err)
		}
	}
}

/*
AN ADDRESS TAKEN BETWEEN THE ASKING AND THE CLICKING.

	Rare and real, and it has its own error because the person can act on it:
	pick another address. Refusing at the moment of ASKING was considered and
	rejected — the answer would be a way to ask whether a particular person
	studies here, and it would be a race anyway.
*/
func TestAnAddressTakenInTheMeantimeIsRefusedAtTheLink(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, was := create(t, store)
	wanted := address(t)

	change, err := store.RequestEmailChange(ctx, account.ID, wanted)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}

	// Somebody else signs up with it while the link sits in an inbox.
	if _, err := store.Create(ctx, identity.NewAccount{
		Email: wanted, Password: goodPassword,
	}); err != nil {
		t.Fatalf("the other sign-up: %v", err)
	}

	if _, _, err := store.ConfirmEmailChange(ctx, change.Token); !errors.Is(err, identity.ErrTaken) {
		t.Errorf("following answered %v, want ErrTaken", err)
	}
	now, err := store.ByID(ctx, account.ID)
	if err != nil {
		t.Fatalf("reading the account: %v", err)
	}
	if !strings.EqualFold(now.Email, was) {
		t.Errorf("the account moved to %q anyway", now.Email)
	}
}

// AN ADDRESS NOBODY COULD SIGN UP WITH CANNOT BE MOVED ONTO EITHER. The two
// checks are literally the same function, because an account sitting somewhere
// the rest of the platform believes impossible is a bug with no owner.
func TestAnAddressThatIsNotOneIsRefused(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()
	account, _ := create(t, store)

	for _, bad := range []string{"", "   ", "nobody", "@example.tld", "nobody@", "a b@example.tld"} {
		if _, err := store.RequestEmailChange(ctx, account.ID, bad); err == nil {
			t.Errorf("asking to move to %q was allowed", bad)
		}
	}
}

// AN ACCOUNT THAT IS NOT THERE CANNOT BE MOVED, and says so with the error every
// caller in this package already handles.
func TestAskingForNobodyIsErrNoAccount(t *testing.T) {
	store := identity.NewStore(testPool(t))

	_, err := store.RequestEmailChange(context.Background(), uuid.New(), "somebody@example.tld")
	if !errors.Is(err, identity.ErrNoAccount) {
		t.Errorf("asking for a stranger answered %v, want ErrNoAccount", err)
	}
}

// A TOKEN NOBODY ISSUED IS THE SAME ANSWER AS A SPENT ONE, for the confirmation
// table's reason: telling them apart confirms to a guesser that a token is real.
func TestAnInventedChangeTokenIsRefused(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	for _, token := range []string{"", "not-a-token", strings.Repeat("A", 43)} {
		if _, _, err := store.ConfirmEmailChange(ctx, token); !errors.Is(err, identity.ErrNoChange) {
			t.Errorf("%q answered %v, want ErrNoChange", token, err)
		}
	}
}

// THE TOKEN IS NOT IN THE TABLE. What is stored is a hash, for session tokens'
// reason: a table somebody can read is a table somebody can use — and this one's
// tokens move an account rather than merely confirming it.
func TestTheChangeTableHoldsNoTokenAnybodyCouldUse(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()
	account, _ := create(t, store)

	change, err := store.RequestEmailChange(ctx, account.ID, address(t))
	if err != nil {
		t.Fatalf("asking: %v", err)
	}

	var found int
	if err := pool.QueryRow(ctx, `
		SELECT count(*) FROM account_email_changes
		 WHERE account_id = $1 AND encode(token_hash, 'escape') LIKE '%' || $2 || '%'
	`, account.ID, change.Token).Scan(&found); err != nil {
		t.Fatalf("looking for the token: %v", err)
	}
	if found != 0 {
		t.Error("the change row carries the token itself")
	}
}
