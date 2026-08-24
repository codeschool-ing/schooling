package identity_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/identity"
)

/* Who is here, and the five ways a presence count goes quietly wrong.

   EVERY ONE OF THEM READS AS A NUMBER. That is what makes this worth a test
   file: a funnel that miscounts looks odd, and a presence count that miscounts
   looks like a Tuesday. Sessions instead of people, an operator counted as the
   student they are looking at, a signed-out browser still standing there — each
   of those is a plausible figure on a screen nobody can check against anything.

   THE PLATFORM-WIDE FIGURE IS NEVER ASSERTED HERE. These tests run against one
   database beside every other package's, without truncating anything, so
   `everywhere` counts people this file has never heard of. What each test owns
   is its own school, and that is what it reads. */

// present is how many people this school has, out of an answer about all of
// them.
func present(t *testing.T, store *identity.Store, school uuid.UUID) int {
	t.Helper()
	rows, _, err := store.Presence(context.Background(), identity.PresenceWindow)
	if err != nil {
		t.Fatalf("reading who is here: %v", err)
	}
	for _, one := range rows {
		if one.School == school {
			return one.People
		}
	}
	return 0
}

// A session is only somewhere once it has been used somewhere. `Issue` cannot
// know the school — it runs on the sign-in route, which is the same route on
// every host — so the first authenticated request is what places it, and that
// is what `Verify` does with its third argument.
func seenAt(t *testing.T, store *identity.Store, token string, school uuid.UUID) {
	t.Helper()
	if _, _, err := store.Verify(context.Background(), token, &school); err != nil {
		t.Fatalf("verifying a session: %v", err)
	}
}

// THE PLAIN CASE, which also proves the heartbeat: a session is issued with no
// school on it at all, and one request to a school's address is what makes its
// holder present there.
func TestSomebodyUsingASchoolIsPresentInIt(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	account, _ := create(t, store)
	school := aSchoolID(t, pool)

	token, err := store.Issue(context.Background(), account.ID, "a browser")
	if err != nil {
		t.Fatalf("issuing a session: %v", err)
	}

	if got := present(t, store, school); got != 0 {
		t.Fatalf("a session that has touched no school counted as %d in one", got)
	}

	seenAt(t, store, token, school)

	if got := present(t, store, school); got != 1 {
		t.Errorf("one person is in the school and it says %d", got)
	}
}

// ONE PERSON WITH TWO BROWSERS IS ONE PERSON. Counting sessions would make the
// number rise when somebody opens their phone, which is a platform that looks
// busier every time one student is thorough.
func TestALaptopAndAPhoneAreOnePerson(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	account, _ := create(t, store)
	school := aSchoolID(t, pool)
	ctx := context.Background()

	for _, agent := range []string{"a laptop", "a phone"} {
		token, err := store.Issue(ctx, account.ID, agent)
		if err != nil {
			t.Fatalf("issuing a session: %v", err)
		}
		seenAt(t, store, token, school)
	}

	if got := present(t, store, school); got != 1 {
		t.Errorf("one person on two devices counted as %d", got)
	}
}

// SIGNING OUT IS LEAVING. A revoked session keeps its `last_seen_at`, because
// "signed out at" is a fact worth keeping — so the presence read has to exclude
// it explicitly rather than rely on the timestamp ageing out.
func TestSomebodyWhoSignedOutIsNotHere(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	account, _ := create(t, store)
	school := aSchoolID(t, pool)
	ctx := context.Background()

	token, err := store.Issue(ctx, account.ID, "a browser")
	if err != nil {
		t.Fatalf("issuing a session: %v", err)
	}
	seenAt(t, store, token, school)

	if err := store.Revoke(ctx, token); err != nil {
		t.Fatalf("signing out: %v", err)
	}
	if got := present(t, store, school); got != 0 {
		t.Errorf("somebody who signed out a second ago is still counted: %d", got)
	}
}

/*
AN OPERATOR LOOKING AT A STUDENT'S SCREENS IS NOT THE STUDENT BEING HERE.

A viewing is a session on the school's host, held by the student's account, and
it answers `/api/v1/me` exactly as the student's own does — which is the whole
point of it being a session row (K-02). Counted as presence it would be a number
that rises when support gets busy, on a screen whose only job is to say whether
anybody is studying.
*/
func TestAViewingIsNotSomebodyBeingHere(t *testing.T) {
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
		t.Fatalf("redeeming the link: %v", err)
	}
	seenAt(t, store, token, school)

	if got := present(t, store, school); got != 0 {
		t.Errorf("an operator viewing a student counted as %d person present", got)
	}
}

/*
THE CONSOLE IS NOT A SCHOOL, AND READING THE LANDING PAGE DOES NOT MOVE ANYBODY.

Two rules in one test, because they are the same rule from both sides. A request
that arrived at no school passes nil, and nil must neither place a session in a
school nor take it out of the one it is in — otherwise a staff member with the
console open would appear in whichever school they last opened, and a student
who glanced at the platform's own address between two lessons would vanish from
the one they are studying in.
*/
func TestAHostThatIsNoSchoolNeitherPlacesNorRemoves(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	account, _ := create(t, store)
	school := aSchoolID(t, pool)
	ctx := context.Background()

	token, err := store.Issue(ctx, account.ID, "a browser")
	if err != nil {
		t.Fatalf("issuing a session: %v", err)
	}

	// Nowhere, before anywhere: this must not invent a school.
	if _, _, err := store.Verify(ctx, token, nil); err != nil {
		t.Fatalf("verifying a session: %v", err)
	}
	rows, _, err := store.Presence(ctx, identity.PresenceWindow)
	if err != nil {
		t.Fatalf("reading who is here: %v", err)
	}
	for _, one := range rows {
		if one.School == school {
			t.Errorf("a session used on no school at all was counted in one")
		}
	}

	// And now somewhere, then nowhere again: the school has to survive.
	seenAt(t, store, token, school)
	if _, _, err := store.Verify(ctx, token, nil); err != nil {
		t.Fatalf("verifying a session: %v", err)
	}
	if got := present(t, store, school); got != 1 {
		t.Errorf("reading the landing page took somebody out of their school: %d", got)
	}
}

// THE WINDOW IS WHAT MAKES IT "NOW". A window of nothing is nobody, which is
// the same query with the only number that matters set to zero — and it proves
// the read is bounded by `last_seen_at` rather than merely by the session being
// live.
func TestNobodyIsHereInAWindowOfNoTime(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	account, _ := create(t, store)
	school := aSchoolID(t, pool)

	token, err := store.Issue(context.Background(), account.ID, "a browser")
	if err != nil {
		t.Fatalf("issuing a session: %v", err)
	}
	seenAt(t, store, token, school)

	rows, _, err := store.Presence(context.Background(), 0*time.Second)
	if err != nil {
		t.Fatalf("reading who is here: %v", err)
	}
	for _, one := range rows {
		if one.School == school {
			t.Errorf("%d people were seen in the last no seconds", one.People)
		}
	}
}
