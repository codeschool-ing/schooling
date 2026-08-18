package audit_test

import (
	"context"
	"os"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/audit"
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

func clear(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	if _, err := pool.Exec(context.Background(), `TRUNCATE audit_log`); err != nil {
		t.Fatalf("clearing: %v", err)
	}
}

// THE ONE THAT MATTERS.
//
// An entry with nobody against it is a log, not an audit — and the failure is
// not that the write fails, it is that a year later nobody can say which of two
// people changed a student's plan. Entries written without an actor cannot grow
// one afterwards, which is why the refusal is here from the first entry.
//
// It is an error and NOT A DEFAULT. Filling in "system" for a caller who forgot
// would produce an audit that reads plausibly and is wrong, and that is worse
// than one with rows missing: the missing rows get noticed.
func TestAnActionWithNoActorIsRefused(t *testing.T) {
	pool := testPool(t)
	clear(t, pool)
	ctx := context.Background()
	store := audit.NewStore(pool)

	// The zero Actor is what a caller who forgot ends up with.
	err := store.Record(ctx, audit.Entry{
		Action:      "account.plan.changed",
		SubjectKind: "account",
		SubjectID:   uuid.New().String(),
	})
	if err == nil {
		t.Fatal("an administrative action was recorded with nobody against it")
	}

	var count int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM audit_log`).Scan(&count); err != nil {
		t.Fatalf("counting: %v", err)
	}
	if count != 0 {
		t.Errorf("%d entries were written by a call that should have been refused", count)
	}
}

func TestAnActionRecordsWhoTookIt(t *testing.T) {
	pool := testPool(t)
	clear(t, pool)
	ctx := context.Background()

	staff := uuid.New()
	subject := uuid.New()
	err := audit.NewStore(pool).Record(ctx, audit.Entry{
		Actor:       audit.Staff(staff, "Alexandre"),
		Action:      "account.plan.changed",
		SubjectKind: "account",
		SubjectID:   subject.String(),
		Before:      map[string]any{"plan": "monthly"},
		After:       map[string]any{"plan": "annual"},
		Reason:      "support request 41",
	})
	if err != nil {
		t.Fatalf("recording: %v", err)
	}

	var actorID uuid.UUID
	var kind, label, action string
	var before, after map[string]any
	if err := pool.QueryRow(ctx, `
		SELECT actor_id, actor_kind, actor_label, action, before, after FROM audit_log
	`).Scan(&actorID, &kind, &label, &action, &before, &after); err != nil {
		t.Fatalf("reading it back: %v", err)
	}

	if actorID != staff || kind != audit.KindStaff {
		t.Errorf("actor %v of kind %q, want %v as staff", actorID, kind, staff)
	}
	// The name is copied in rather than joined later: people are renamed and
	// people leave, and an entry that reads "actor 9f2c…" is not an answer.
	if label != "Alexandre" {
		t.Errorf("actor label %q, want the name as it was at the time", label)
	}
	if before["plan"] != "monthly" || after["plan"] != "annual" {
		t.Errorf("both sides did not survive: before=%v after=%v", before, after)
	}
}

// The platform acting on its own is a real actor, not an absent one. Giving it
// a name of its own is what keeps "nobody" available to mean nobody.
func TestTheSystemIsAnActorWithAName(t *testing.T) {
	pool := testPool(t)
	clear(t, pool)
	ctx := context.Background()

	if err := audit.NewStore(pool).Record(ctx, audit.Entry{
		Actor:       audit.System("dunning"),
		Action:      "subscription.suspended",
		SubjectKind: "subscription",
		SubjectID:   uuid.New().String(),
	}); err != nil {
		t.Fatalf("recording: %v", err)
	}

	var kind, label string
	var actorID uuid.UUID
	if err := pool.QueryRow(ctx,
		`SELECT actor_kind, actor_label, actor_id FROM audit_log`).Scan(&kind, &label, &actorID); err != nil {
		t.Fatalf("reading it back: %v", err)
	}
	if kind != audit.KindSystem || label != "dunning" {
		t.Errorf("kind %q label %q, want the system with a name", kind, label)
	}
	if actorID == uuid.Nil {
		t.Error("the system acted under the nil uuid, which is what an uninitialised " +
			"variable looks like — the one thing this package exists to tell apart")
	}
}

// An audit that can be edited is a document, not a record.
func TestTheAuditRefusesToBeEdited(t *testing.T) {
	pool := testPool(t)
	clear(t, pool)
	ctx := context.Background()

	if err := audit.NewStore(pool).Record(ctx, audit.Entry{
		Actor:       audit.Staff(uuid.New(), "Alexandre"),
		Action:      "account.deleted",
		SubjectKind: "account",
	}); err != nil {
		t.Fatalf("recording: %v", err)
	}

	if _, err := pool.Exec(ctx, `UPDATE audit_log SET actor_label = 'somebody else'`); err == nil {
		t.Error("an audit entry was rewritten to name a different person")
	}
	if _, err := pool.Exec(ctx, `DELETE FROM audit_log`); err == nil {
		t.Error("an audit entry was deleted")
	}
}
