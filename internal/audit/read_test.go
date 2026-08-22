package audit_test

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/audit"
)

/* Reading the history back, against a real Postgres.

   A DATABASE AND NOT FAKES HERE, and it is the opposite call from
   `internal/console`'s tests for the same feature. What those check is what the
   console decides — that a list does not carry the two states, that a question
   with no index is refused. What these check is whether the SQL is right, and a
   fake that returns rows in the order it was given them cannot be wrong about
   ordering, about a filter, or about a page boundary.

   NO TRUNCATE, for the reason the file next door gives: packages run in
   parallel against one database. Every test here invents its own actor and asks
   only about that actor's entries, which is what it meant to assert anyway. */

func TestTheHistoryComesBackNewestFirst(t *testing.T) {
	pool := testPool(t)
	store := audit.NewStore(pool)
	ctx := context.Background()

	actor := uuid.New()
	for i := range 4 {
		write(t, store, actor, "thing", uuid.NewString(), i)
	}

	rows, err := store.Recent(ctx, audit.Query{ActorID: &actor})
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(rows) != 4 {
		t.Fatalf("read %d entries, want 4", len(rows))
	}
	for i := 1; i < len(rows); i++ {
		if rows[i-1].OccurredAt.Before(rows[i].OccurredAt) {
			t.Errorf("entry %d is older than the one after it — the history is not newest first", i)
		}
	}
}

// ONE ACTOR'S ENTRIES, AND ONLY THEIRS. The filter is the point: a console
// screen that asked "what has this person been doing" and answered with
// somebody else's row would be worse than having no screen.
func TestOneActorsEntriesAreOnlyTheirs(t *testing.T) {
	pool := testPool(t)
	store := audit.NewStore(pool)
	ctx := context.Background()

	mine, theirs := uuid.New(), uuid.New()
	write(t, store, mine, "thing", "a", 0)
	write(t, store, mine, "thing", "b", 1)
	write(t, store, theirs, "thing", "c", 2)

	rows, err := store.Recent(ctx, audit.Query{ActorID: &mine})
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(rows) != 2 {
		t.Fatalf("read %d entries for one actor, want 2", len(rows))
	}
	for _, r := range rows {
		if r.ActorID != mine {
			t.Errorf("an entry by %s came back under a filter for %s", r.ActorID, mine)
		}
	}
}

// EVERYTHING DONE TO ONE SUBJECT, which is the question asked about a person:
// what has happened to them, whoever did it.
func TestEverythingDoneToOneSubject(t *testing.T) {
	pool := testPool(t)
	store := audit.NewStore(pool)
	ctx := context.Background()

	subject := uuid.NewString()
	one, two := uuid.New(), uuid.New()
	write(t, store, one, "account", subject, 0)
	write(t, store, two, "account", subject, 1)
	write(t, store, one, "account", uuid.NewString(), 2)

	rows, err := store.Recent(ctx, audit.Query{SubjectKind: "account", SubjectID: subject})
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(rows) != 2 {
		t.Fatalf("read %d entries about one subject, want 2", len(rows))
	}
	for _, r := range rows {
		if r.SubjectID != subject {
			t.Errorf("an entry about %s came back under a filter for %s", r.SubjectID, subject)
		}
	}
}

func TestHalfASubjectIsAnError(t *testing.T) {
	store := audit.NewStore(testPool(t))
	for _, q := range []audit.Query{{SubjectKind: "account"}, {SubjectID: "x"}} {
		if _, err := store.Recent(context.Background(), q); err == nil {
			t.Errorf("%+v was accepted — the index leads with the kind, so an id "+
				"on its own reads the whole table", q)
		}
	}
}

// THE PAGE BOUNDARY, WITH EVERY ROW SHARING ONE TIMESTAMP.
//
// This is what the cursor is for and it is the only case that can go wrong
// quietly. Four entries at the same instant, read two at a time: a cursor of
// `occurred_at` alone would either return the same two rows forever or skip the
// other two, and both look like a working screen. The tiebreaker is the id.
//
// The rows are inserted directly rather than through `Record`, because `Record`
// takes `now()` per statement and this needs the tie to be certain rather than
// likely.
func TestAPageBoundaryDoesNotRepeatOrLoseARowWhenTimestampsTie(t *testing.T) {
	pool := testPool(t)
	store := audit.NewStore(pool)
	ctx := context.Background()

	actor := uuid.New()
	at := time.Now().UTC().Truncate(time.Second)
	for i := range 4 {
		_, err := pool.Exec(ctx, `
			INSERT INTO audit_log (occurred_at, actor_id, actor_kind, actor_label,
			                       action, subject_kind, subject_id)
			VALUES ($1, $2, 'staff', 'the page test', $3, 'thing', $4)
		`, at, actor, "tied", uuid.NewString())
		if err != nil {
			t.Fatalf("seeding entry %d: %v", i, err)
		}
	}

	seen := map[int64]bool{}
	var cursor *audit.Cursor
	for page := range 3 {
		rows, err := store.Recent(ctx, audit.Query{ActorID: &actor, Limit: 2, After: cursor})
		if err != nil {
			t.Fatalf("page %d: %v", page, err)
		}
		for _, r := range rows {
			if seen[r.ID] {
				t.Errorf("entry %d came back on two pages — a reader paging down sees it twice", r.ID)
			}
			seen[r.ID] = true
		}
		if len(rows) < 2 {
			break
		}
		last := rows[len(rows)-1]
		cursor = &audit.Cursor{At: last.OccurredAt, ID: last.ID}
	}

	if len(seen) != 4 {
		t.Errorf("paging saw %d of 4 entries — the rest are invisible to anybody "+
			"reading this screen", len(seen))
	}
}

// THE TWO STATES COME BACK FROM `One` AND NOT FROM `Recent`, which is the whole
// reason there are two methods rather than one with a flag.
func TestTheTwoStatesAreOnlyOnOneEntry(t *testing.T) {
	pool := testPool(t)
	store := audit.NewStore(pool)
	ctx := context.Background()

	actor := uuid.New()
	if err := store.Record(ctx, audit.Entry{
		Actor:       audit.Staff(actor, "Ada"),
		Action:      "plan.changed",
		SubjectKind: "account",
		SubjectID:   uuid.NewString(),
		Before:      map[string]string{"plan": "free"},
		After:       map[string]string{"plan": "annual"},
	}); err != nil {
		t.Fatalf("recording: %v", err)
	}

	rows, err := store.Recent(ctx, audit.Query{ActorID: &actor})
	if err != nil || len(rows) != 1 {
		t.Fatalf("reading the list: %v, %d rows", err, len(rows))
	}
	if len(rows[0].Before) != 0 || len(rows[0].After) != 0 {
		t.Error("the list carried the two states, which is the payload it exists not to carry")
	}

	one, err := store.One(ctx, rows[0].ID)
	if err != nil {
		t.Fatalf("reading one entry: %v", err)
	}
	var before, after map[string]string
	if err := json.Unmarshal(one.Before, &before); err != nil {
		t.Fatalf("the before state did not come back as json: %v", err)
	}
	if err := json.Unmarshal(one.After, &after); err != nil {
		t.Fatalf("the after state did not come back as json: %v", err)
	}
	if before["plan"] != "free" || after["plan"] != "annual" {
		t.Errorf("the entry says %v → %v, want free → annual", before, after)
	}
}

// AND IT IS `ErrNoEntry` AND NOT MERELY AN ERROR.
//
// Written as "any error will do" this passed with the database switched off,
// which is the shape of assertion that gives a green run its worst kind of
// value: it was true for a reason that had nothing to do with the claim.
func TestAnEntryThatIsNotThere(t *testing.T) {
	store := audit.NewStore(testPool(t))
	_, err := store.One(context.Background(), -1)
	if !errors.Is(err, audit.ErrNoEntry) {
		t.Errorf("an id that cannot exist answered %v, want ErrNoEntry", err)
	}
}

func write(t *testing.T, store *audit.Store, actor uuid.UUID, kind, subject string, n int) {
	t.Helper()
	err := store.Record(context.Background(), audit.Entry{
		Actor:       audit.Staff(actor, "the read tests"),
		Action:      "read-test.wrote",
		SubjectKind: kind,
		SubjectID:   subject,
		Reason:      "entry " + string(rune('a'+n)),
	})
	if err != nil {
		t.Fatalf("recording entry %d: %v", n, err)
	}
}
