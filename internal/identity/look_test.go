package identity_test

import (
	"context"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/identity"
)

/* `Store.Look` — the query K-22 refused until it was amended.

   THE SUITE IS SHARED AND SO IS `accounts`. Every other test in this package
   creates people, and they are all in this table while this one runs — so
   nothing here asserts on how many came back, or on which row is first. What it
   asserts is about the accounts it made, found by id, with a search term unique
   to this run. That is not a workaround: it is the shape a listing test has to
   have, because the thing being tested is a query over a table somebody else is
   writing to. */

// unique is a fragment no other test's address can contain.
func unique(t *testing.T) string {
	t.Helper()
	return "look" + strings.ReplaceAll(uuid.NewString(), "-", "")[:10]
}

// holds answers whether a page contains an account.
func holds(page []identity.Sought, id uuid.UUID) bool {
	for _, one := range page {
		if one.ID == id {
			return true
		}
	}
	return false
}

/*
TestSomebodyIsFoundByAFragmentOfTheirAddressOrTheirName.

	This is the case K-22 never handled and the reason it was amended: somebody
	writes in from an address that is not the one they signed up with, or signs
	their e-mail with a surname. `ByEmail` answers yes or no about a whole
	string, so answering them meant guessing spellings at a form — and the
	fallback was a SQL client against production, which is the same power with
	no audit and no gate.

	BOTH COLUMNS, because a search over one sends whoever is answering that
	e-mail back to guessing the other.
*/
func TestSomebodyIsFoundByAFragmentOfTheirAddressOrTheirName(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	word := unique(t)
	account, err := store.Create(ctx, identity.NewAccount{
		Email: word + "@example.tld", Name: "Ada " + word, Password: goodPassword,
	})
	if err != nil {
		t.Fatalf("creating an account: %v", err)
	}

	for _, fragment := range []string{
		word,                      // the whole distinguishing part
		word[4:10],                // a piece of it, from the middle of the address
		strings.ToUpper(word[:8]), // and in capitals, because a search is not a string match
		"Ada " + word,             // the name
		strings.ToUpper("ada " + word[:6]),
	} {
		t.Run(fragment, func(t *testing.T) {
			page, err := store.Look(ctx, identity.Look{Words: fragment})
			if err != nil {
				t.Fatalf("looking: %v", err)
			}
			if !holds(page, account.ID) {
				t.Fatalf("%q found %d people and not the one it describes", fragment, len(page))
			}
		})
	}
}

/*
TestAWildcardSomebodyTyped is not a wildcard.

	`%` and `_` are LIKE's, not the operator's — so an unescaped one would make
	`%` on its own the "give me everybody" that the page size exists to stop
	from being one keystroke, and would make an address containing a per cent
	sign unsearchable at the same time.
*/
func TestAWildcardSomebodyTypedIsNotAWildcard(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	word := unique(t)
	if _, err := store.Create(ctx, identity.NewAccount{
		Email: word + "@example.tld", Name: "Ada", Password: goodPassword,
	}); err != nil {
		t.Fatalf("creating an account: %v", err)
	}

	// `_` matches any single character in LIKE. Escaped, it matches an
	// underscore — and there is none in the address above.
	page, err := store.Look(ctx, identity.Look{Words: word[:4] + "_" + word[5:]})
	if err != nil {
		t.Fatalf("looking: %v", err)
	}
	for _, one := range page {
		if strings.Contains(one.Email, word) {
			t.Fatalf("an underscore matched any character, so %q found %q",
				word[:4]+"_"+word[5:], one.Email)
		}
	}

	// And a lone per cent sign is a search for a per cent sign, not for
	// everybody — this platform has no address with one in it.
	page, err = store.Look(ctx, identity.Look{Words: "%"})
	if err != nil {
		t.Fatalf("looking: %v", err)
	}
	if len(page) != 0 {
		t.Fatalf("a lone per cent sign returned %d people, which is the whole table one "+
			"keystroke away from a field that records what was typed", len(page))
	}
}

/*
TestNothingSearchedForIsEverybodyNewestFirst.

	"Who signed up this week" is a real question with no search term in it, so an
	empty `Words` is not a mistake to refuse. What matters is the ORDER, because
	that is what makes the answer useful and what the cursor depends on.
*/
func TestNothingSearchedForIsEverybodyNewestFirst(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	fresh, _ := create(t, store)

	page, err := store.Look(ctx, identity.Look{})
	if err != nil {
		t.Fatalf("looking: %v", err)
	}
	if len(page) == 0 {
		t.Fatal("an empty search found nobody, in a suite that has just made somebody")
	}
	if !holds(page, fresh.ID) {
		t.Fatal("the account made a moment ago is not on the first page of a listing " +
			"ordered newest first")
	}
	for i := 1; i < len(page); i++ {
		if page[i].CreatedAt.After(page[i-1].CreatedAt) {
			t.Fatalf("row %d was created after row %d, so the order is not newest first",
				i, i-1)
		}
	}
}

/*
TestAPageIsAPageAndTheCursorReachesTheNextOne.

	The two halves of paging, checked together because neither is worth much
	alone: a page that is capped and a cursor that does not move would be a
	screen showing the same fifty for ever.

	KEYSET AND NOT OFFSET, which is what the pair (created_at, id) is for. This
	suite creates accounts in a loop, fast enough that several can share a
	timestamp — which is exactly the case an offset page or a cursor on time
	alone gets wrong, by showing one person twice and skipping another.
*/
func TestAPageIsAPageAndTheCursorReachesTheNextOne(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	word := unique(t)
	made := map[uuid.UUID]bool{}
	for i := 0; i < identity.Page+5; i++ {
		account, err := store.Create(ctx, identity.NewAccount{
			Email: word + uuid.NewString()[:8] + "@example.tld",
			Name:  "Ada", Password: goodPassword,
		})
		if err != nil {
			t.Fatalf("creating account %d: %v", i, err)
		}
		made[account.ID] = true
	}

	first, err := store.Look(ctx, identity.Look{Words: word})
	if err != nil {
		t.Fatalf("looking: %v", err)
	}
	if len(first) != identity.Page {
		t.Fatalf("a page of %d came back for %d matching people — the cap is what stops a "+
			"listing being an export", len(first), len(made))
	}

	last := first[len(first)-1]
	second, err := store.Look(ctx, identity.Look{
		Words: word, Before: last.CreatedAt, BeforeID: last.ID,
	})
	if err != nil {
		t.Fatalf("looking again: %v", err)
	}
	if len(second) != 5 {
		t.Fatalf("the second page has %d rows, wanted the remaining 5", len(second))
	}

	/* AND NOBODY IS ON BOTH PAGES OR ON NEITHER, which is the whole claim. An
	   OFFSET page would fail this the moment another test in this suite inserts
	   a row between the two queries; a cursor on `created_at` alone fails it
	   whenever two of the accounts above share a timestamp. */
	seen := map[uuid.UUID]int{}
	for _, one := range append(append([]identity.Sought{}, first...), second...) {
		seen[one.ID]++
	}
	for id := range made {
		switch seen[id] {
		case 1:
		case 0:
			t.Fatalf("%v is on neither page", id)
		default:
			t.Fatalf("%v is on both pages", id)
		}
	}
}

/*
TestALookShowsTheMinimumThatIdentifies.

	"Minimal" is one of the four conditions the amendment to K-22 rests on: a
	name, an address, when they arrived, and whether they are seeded — the same
	four fields the exact lookup already returns about one person. This holds the
	shape from the other end, where a field would be added: `Sought` is what the
	query selects, and a fifth column here is a change to the decision rather
	than to a struct.
*/
func TestALookShowsTheMinimumThatIdentifies(t *testing.T) {
	store := identity.NewStore(testPool(t))
	ctx := context.Background()

	word := unique(t)
	made, err := store.Create(ctx, identity.NewAccount{
		Email: word + "@example.tld", Name: "Ada", Password: goodPassword,
	})
	if err != nil {
		t.Fatalf("creating an account: %v", err)
	}

	page, err := store.Look(ctx, identity.Look{Words: word})
	if err != nil {
		t.Fatalf("looking: %v", err)
	}
	if len(page) != 1 {
		t.Fatalf("%d people match a fragment nobody else has", len(page))
	}

	one := page[0]
	if one.ID != made.ID || one.Email != made.Email || one.Name != "Ada" {
		t.Fatalf("the row reads %+v", one)
	}
	if one.CreatedAt.IsZero() {
		t.Error("the row does not say when they arrived, which is half of what identifies " +
			"two people with the same name")
	}
	if one.Synthetic {
		t.Error("an account made by the sign-up path reads as seeded")
	}
}

/*
TestASeededPersonIsListedAndSaidToBeOne.

	Every aggregate excludes synthetic students (K-11), and this screen must not.
	An operator about to erase a seeded person has to be able to reach one — and
	a listing that hid them would be a screen whose emptiness means two different
	things. So they are listed, and marked.
*/
func TestASeededPersonIsListedAndSaidToBeOne(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()

	word := unique(t)
	made, err := store.Create(ctx, identity.NewAccount{
		Email: word + "@example.tld", Name: "Ada", Password: goodPassword,
	})
	if err != nil {
		t.Fatalf("creating an account: %v", err)
	}
	if _, err := pool.Exec(ctx,
		`UPDATE accounts SET synthetic = true WHERE id = $1`, made.ID); err != nil {
		t.Fatalf("seeding: %v", err)
	}

	page, err := store.Look(ctx, identity.Look{Words: word})
	if err != nil {
		t.Fatalf("looking: %v", err)
	}
	if len(page) != 1 {
		t.Fatalf("a seeded person is %d rows, and hiding them makes an empty screen mean "+
			"two things", len(page))
	}
	if !page[0].Synthetic {
		t.Fatal("a seeded person is not marked as one, so an operator about to erase them " +
			"cannot see what they are looking at")
	}
}
