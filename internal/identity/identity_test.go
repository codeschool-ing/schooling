package identity_test

import (
	"context"
	"crypto/sha256"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/identity"
)

func testPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("SCHOOLING_TEST_DATABASE_URL")
	if url == "" {
		t.Skip("set SCHOOLING_TEST_DATABASE_URL to run the tests that need a database")
	}
	pool, err := pgxpool.New(context.Background(), url)
	if err != nil {
		t.Fatalf("opening the test database: %v", err)
	}
	t.Cleanup(pool.Close)
	return pool
}

// NO TRUNCATE, and every address is unique to the test that made it: packages
// run in parallel against one database.
func address(t *testing.T) string {
	t.Helper()
	return strings.ReplaceAll(uuid.NewString(), "-", "")[:16] + "@example.tld"
}

const goodPassword = "a long enough passphrase"

func create(t *testing.T, store *identity.Store) (identity.Account, string) {
	t.Helper()
	email := address(t)
	account, err := store.Create(context.Background(), identity.NewAccount{
		Email: email, Name: "Alexandre", Password: goodPassword,
	})
	if err != nil {
		t.Fatalf("creating an account: %v", err)
	}
	return account, email
}

func TestAnAccountSignsInWithItsPassword(t *testing.T) {
	store := identity.NewStore(testPool(t))
	account, email := create(t, store)

	got, err := store.Authenticate(context.Background(), email, goodPassword)
	if err != nil {
		t.Fatalf("signing in: %v", err)
	}
	if got.ID != account.ID {
		t.Errorf("signed in as %v, want %v", got.ID, account.ID)
	}

	// The address is a person's, not a string's: capitals and stray spaces are
	// the same person coming back.
	if _, err := store.Authenticate(context.Background(), "  "+strings.ToUpper(email)+" ", goodPassword); err != nil {
		t.Errorf("the same address in capitals did not sign in: %v", err)
	}
}

func TestTheWrongPasswordIsRefused(t *testing.T) {
	store := identity.NewStore(testPool(t))
	_, email := create(t, store)

	_, err := store.Authenticate(context.Background(), email, goodPassword+"!")
	if !errors.Is(err, identity.ErrWrongPassword) {
		t.Errorf("a wrong password gave %v, want ErrWrongPassword", err)
	}
}

// THE ONE THAT MATTERS MOST HERE.
//
// The session token exists in exactly one place: the browser. What the database
// holds is its SHA-256, so a backup that leaked — or a query somebody ran and
// pasted into a chat — hands over nothing that can be replayed as somebody.
//
// This is checked by looking for the token in the table, because the failure it
// guards against is a column somebody added "to make debugging easier".
func TestTheSessionTokenIsNeverStored(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	account, _ := create(t, store)
	ctx := context.Background()

	token, err := store.Issue(ctx, account.ID, "a test")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}
	if token == "" {
		t.Fatal("the session token is empty")
	}

	// Nowhere in the row, in any text column.
	var found bool
	if err := pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM sessions
			WHERE account_id = $1 AND (user_agent = $2 OR encode(token_hash, 'escape') = $2)
		)
	`, account.ID, token).Scan(&found); err != nil {
		t.Fatalf("looking for the token: %v", err)
	}
	if found {
		t.Error("the session token is in the database — a backup that leaks is then every " +
			"live session, rather than a rotation")
	}

	// And what IS stored is its hash, which is what makes the lookup work.
	sum := sha256.Sum256([]byte(token))
	var stored bool
	if err := pool.QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM sessions WHERE token_hash = $1)`, sum[:]).Scan(&stored); err != nil {
		t.Fatalf("looking for the hash: %v", err)
	}
	if !stored {
		t.Error("the session is not stored as the SHA-256 of its token")
	}
}

func TestASessionIdentifiesItsAccountUntilItIsRevoked(t *testing.T) {
	store := identity.NewStore(testPool(t))
	account, _ := create(t, store)
	ctx := context.Background()

	token, err := store.Issue(ctx, account.ID, "a test")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}

	got, _, err := store.Verify(ctx, token)
	if err != nil {
		t.Fatalf("verifying: %v", err)
	}
	if got.ID != account.ID {
		t.Errorf("the session named %v, want %v", got.ID, account.ID)
	}

	if err := store.Revoke(ctx, token); err != nil {
		t.Fatalf("revoking: %v", err)
	}
	if _, _, err := store.Verify(ctx, token); !errors.Is(err, identity.ErrNoSession) {
		t.Errorf("a revoked session gave %v, want ErrNoSession", err)
	}

	// And a token nobody issued is the same answer, not a different one.
	if _, _, err := store.Verify(ctx, "not-a-token"); !errors.Is(err, identity.ErrNoSession) {
		t.Errorf("an invented token gave %v, want ErrNoSession", err)
	}
}

// Signing out of one browser must not sign somebody out of their phone.
func TestSigningOutEndsOneSessionAndNotTheOthers(t *testing.T) {
	store := identity.NewStore(testPool(t))
	account, _ := create(t, store)
	ctx := context.Background()

	phone, err := store.Issue(ctx, account.ID, "a phone")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}
	laptop, err := store.Issue(ctx, account.ID, "a laptop")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}

	if err := store.Revoke(ctx, laptop); err != nil {
		t.Fatalf("revoking: %v", err)
	}
	if _, _, err := store.Verify(ctx, phone); err != nil {
		t.Errorf("signing out of the laptop ended the phone's session too: %v", err)
	}
}

// THE SECOND ONE THAT MATTERS.
//
// Changing a password because somebody else may have it is worthless if that
// person's session keeps working — which is what everybody who has ever been
// told to change their password believes it does.
func TestChangingThePasswordEndsEveryOtherSession(t *testing.T) {
	store := identity.NewStore(testPool(t))
	account, email := create(t, store)
	ctx := context.Background()

	mine, err := store.Issue(ctx, account.ID, "the browser I am holding")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}
	theirs, err := store.Issue(ctx, account.ID, "somebody else's")
	if err != nil {
		t.Fatalf("starting a session: %v", err)
	}

	const replacement = "an even longer passphrase"
	if err := store.SetPassword(ctx, account.ID, replacement, mine); err != nil {
		t.Fatalf("changing the password: %v", err)
	}

	if _, _, err := store.Verify(ctx, theirs); !errors.Is(err, identity.ErrNoSession) {
		t.Error("the other session survived a password change — the person who changed it " +
			"believes they locked somebody out, and they did not")
	}
	if _, _, err := store.Verify(ctx, mine); err != nil {
		t.Errorf("the session that asked for the change was ended too: %v", err)
	}

	if _, err := store.Authenticate(ctx, email, replacement); err != nil {
		t.Errorf("the new password does not work: %v", err)
	}
	if _, err := store.Authenticate(ctx, email, goodPassword); !errors.Is(err, identity.ErrWrongPassword) {
		t.Error("the old password still works")
	}
}

func TestOneAddressIsOneAccount(t *testing.T) {
	store := identity.NewStore(testPool(t))
	_, email := create(t, store)

	// Capitals and spaces are the same person, and the second attempt has to
	// say so rather than making a shadow account nobody can sign in to twice.
	_, err := store.Create(context.Background(), identity.NewAccount{
		Email: " " + strings.ToUpper(email) + " ", Password: goodPassword,
	})
	if !errors.Is(err, identity.ErrTaken) {
		t.Errorf("a second account for the same address gave %v, want ErrTaken", err)
	}
}

// An account with no credential can neither sign in nor be created again,
// because the address is taken. Both or neither.
func TestARefusedSignUpLeavesNoAccountBehind(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	email := address(t)

	if _, err := store.Create(context.Background(), identity.NewAccount{
		Email: email, Password: "short",
	}); err == nil {
		t.Fatal("a five-character password was accepted")
	}

	var exists bool
	if err := pool.QueryRow(context.Background(),
		`SELECT EXISTS (SELECT 1 FROM accounts WHERE email = $1)`, email).Scan(&exists); err != nil {
		t.Fatalf("looking for the account: %v", err)
	}
	if exists {
		t.Error("the account was created without a password — it can never sign in, and the " +
			"address can never be used again")
	}
}

// Every problem at once, for the same reason config reports every problem at
// once: a person fixing one per attempt is a form that takes four attempts.
func TestASignUpReportsEveryProblemTogether(t *testing.T) {
	store := identity.NewStore(testPool(t))

	_, err := store.Create(context.Background(), identity.NewAccount{
		Email: "not-an-address", Password: "short",
	})
	if err == nil {
		t.Fatal("an invalid address and a short password were accepted")
	}
	for _, want := range []string{"not-an-address", "characters"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("%q is missing from the refusal, so it takes another attempt to find: %v",
				want, err)
		}
	}
}

// AN ADDRESS FINDS ONE PERSON OR NOBODY, and never a list (K-22).
//
// It is the console's one way of reaching somebody, and the reason it is a
// lookup rather than a search is that a search is browsing people — which an
// audit trail cannot tell apart from working.
func TestAnAccountIsFoundByAWholeAddress(t *testing.T) {
	pool := testPool(t)
	store := identity.NewStore(pool)
	ctx := context.Background()

	email := strings.ReplaceAll(uuid.NewString(), "-", "")[:16] + "@example.tld"
	made, err := store.Create(ctx, identity.NewAccount{
		Email: email, Password: "a-long-enough-password", Name: "Sam",
	})
	if err != nil {
		t.Fatalf("creating an account: %v", err)
	}

	// Exactly, and as it arrives out of a support message: pasted, with the
	// capitals and the space somebody's mail client added.
	for _, typed := range []string{email, strings.ToUpper(email), "  " + email + " "} {
		got, err := store.ByEmail(ctx, typed)
		if err != nil {
			t.Errorf("ByEmail(%q): %v", typed, err)
			continue
		}
		if got.ID != made.ID {
			t.Errorf("ByEmail(%q) found %s, want %s", typed, got.ID, made.ID)
		}
	}

	// And not a prefix of it, which is what would make this a search.
	for _, near := range []string{email[:8], "@example.tld", "", "   "} {
		if _, err := store.ByEmail(ctx, near); !errors.Is(err, identity.ErrNoAccount) {
			t.Errorf("ByEmail(%q) answered %v, want ErrNoAccount — a lookup became a search", near, err)
		}
	}
}
