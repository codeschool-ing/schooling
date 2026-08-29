package identity_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/identity"
)

/* `Store.Staff` — the whole roster in one query.

   THE SUITE IS SHARED AND SO IS THE TABLE. Other tests in this package grant
   roles to accounts of their own, and this one runs beside them; so nothing
   here asserts on the LENGTH of the answer or on the first row of it. What it
   asserts is about the accounts it made, found by id in whatever came back —
   which is also how the screen behaves, and the only shape that does not fail
   for a reason that has nothing to do with it. */

// mine picks one account's row out of the roster.
func mine(t *testing.T, all []identity.Standing, id uuid.UUID) identity.Standing {
	t.Helper()
	for _, one := range all {
		if one.AccountID == id {
			return one
		}
	}
	t.Fatalf("%v is not in the roster", id)
	return identity.Standing{}
}

/*
TestTheRosterCarriesWhatAnAccessReviewNeeds.

	Four facts per person and none of them is in `staff` alone: the address is on
	`accounts`, the second factor is on `account_credentials`, the last sitting
	is on `sessions`, and who granted it is another `accounts` row. The reason
	`Staff` exists rather than a loop over `StaffOf` is that the loop is four
	queries per person on the one screen that has every person on it.
*/
func TestTheRosterCarriesWhatAnAccessReviewNeeds(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	boss, _ := create(t, store)
	if err := store.Grant(ctx, boss.ID, identity.RoleOwner, uuid.Nil); err != nil {
		t.Fatalf("granting the first owner: %v", err)
	}

	hired, _ := create(t, store)
	if err := store.Grant(ctx, hired.ID, identity.RoleOperator, boss.ID); err != nil {
		t.Fatalf("granting an operator: %v", err)
	}
	enrolled(t, store, hired.ID) // and they open the console

	all, err := store.Staff(ctx)
	if err != nil {
		t.Fatalf("reading the roster: %v", err)
	}

	/* THE FIRST OWNER HAS NOBODY ABOVE THEM, which is one null in any
	   deployment's life and the reason the column is nullable at all. */
	first := mine(t, all, boss.ID)
	if first.Role != identity.RoleOwner {
		t.Errorf("the owner reads as %q", first.Role)
	}
	if first.GrantedByEmail != "" {
		t.Errorf("the first owner was granted by %q, and there is nobody above them",
			first.GrantedByEmail)
	}
	if first.SecondFactor {
		t.Error("an account that never enrolled one reads as having a second factor")
	}
	if first.LastOpenedConsole != nil {
		t.Errorf("an account that never presented a code last opened the console at %v",
			first.LastOpenedConsole)
	}

	/* AND THE ONE WHO WAS LET IN CARRIES WHO LET THEM. A uuid here would be an
	   answer nobody can read a year later, which is the same argument
	   `audit_log.actor_label` is denormalised for. */
	second := mine(t, all, hired.ID)
	if second.GrantedByEmail != boss.Email {
		t.Errorf("the operator was granted by %q, wanted %q", second.GrantedByEmail, boss.Email)
	}
	if !second.SecondFactor {
		t.Error("somebody who enrolled a second factor reads as having none")
	}
	if second.LastOpenedConsole == nil {
		t.Fatal("somebody who presented a code has never opened the console — which is the " +
			"one column an access review is for")
	}
	if since := time.Since(*second.LastOpenedConsole); since > time.Minute {
		t.Errorf("they last opened it %v ago, in a test that just did it", since)
	}
}

/*
TestSomebodyWhoLeftIsStillOnTheRoster.

	`0005` sets `revoked_at` rather than deleting the row, so that a person who
	left is distinguishable from a person who was never staff. `cmd/staff list`
	filters those rows and is right to — it answers "who can get in right now",
	for somebody about to grant or revoke. A screen answers "who has ever been
	able to", and dropping them would throw away the only reason the row was
	kept.
*/
func TestSomebodyWhoLeftIsStillOnTheRoster(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	left, _ := create(t, store)
	if err := store.Grant(ctx, left.ID, identity.RoleReadOnly, uuid.Nil); err != nil {
		t.Fatalf("granting: %v", err)
	}
	if err := store.RevokeStaff(ctx, left.ID); err != nil {
		t.Fatalf("revoking: %v", err)
	}

	all, err := store.Staff(ctx)
	if err != nil {
		t.Fatalf("reading the roster: %v", err)
	}

	gone := mine(t, all, left.ID)
	if gone.RevokedAt == nil {
		t.Fatal("somebody who was revoked reads as current, which is the one thing the row " +
			"was kept to prevent")
	}

	// AND `StaffOf` STILL REFUSES THEM, which is the check that matters. A
	// roster that showed a revoked row and an access check that honoured it
	// would be the same fact answered two ways.
	if _, err := store.StaffOf(ctx, left.ID); err == nil {
		t.Fatal("a revoked account still has a live staff standing")
	}
}

/*
TestTheRosterIsOrderedByRankAndNotByTheWord.

	`role` is a text column, and `ORDER BY role` sorts it alphabetically:
	operator, owner, read-only. That reads as an order and is not one — it puts
	the rank that can grant roles in the middle. The real order is `rank` in
	`staff.go`, and this is what holds the SQL to it.
*/
func TestTheRosterIsOrderedByRankAndNotByTheWord(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	made := map[identity.Role]uuid.UUID{}
	for _, role := range []identity.Role{
		identity.RoleReadOnly, identity.RoleOperator, identity.RoleOwner,
	} {
		account, _ := create(t, store)
		if err := store.Grant(ctx, account.ID, role, uuid.Nil); err != nil {
			t.Fatalf("granting %s: %v", role, err)
		}
		made[role] = account.ID
	}

	all, err := store.Staff(ctx)
	if err != nil {
		t.Fatalf("reading the roster: %v", err)
	}

	// Where each of the three landed, among whatever else the suite has granted.
	at := map[identity.Role]int{}
	for i, one := range all {
		for role, id := range made {
			if one.AccountID == id {
				at[role] = i
			}
		}
	}

	if at[identity.RoleOwner] >= at[identity.RoleOperator] ||
		at[identity.RoleOperator] >= at[identity.RoleReadOnly] {

		t.Fatalf("the roster reads owner at %d, operator at %d, read-only at %d — which is "+
			"the alphabet rather than the rank",
			at[identity.RoleOwner], at[identity.RoleOperator], at[identity.RoleReadOnly])
	}
}
