package analysis_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/analysis"
)

// An audit that remembers, so a test can ask what was recorded rather than
// trusting that something was.
type recorder struct {
	entries []string
	reasons []string
	fail    error
}

func (r *recorder) record(_ context.Context, action string, _ uuid.UUID,
	exercise string, version int, _, _ any, reason string) error {

	if r.fail != nil {
		return r.fail
	}
	r.entries = append(r.entries, action+" "+exercise)
	r.reasons = append(r.reasons, reason)
	_ = version
	return nil
}

func quarantining(t *testing.T, pool *pgxpool.Pool, answers map[uuid.UUID][]analysis.Answer,
	log *recorder) *analysis.Store {

	t.Helper()
	return storeOver(t, pool, answers).WithAudit(log.record)
}

// THE WHOLE POINT. A question the strong students fail goes out of circulation
// on its own, because waiting for somebody to read a list is the same as not
// acting — the list is read on the days somebody remembers to read it.
func TestAFlaggedQuestionIsTakenOutOfCirculation(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	log := &recorder{}

	store := quarantining(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 0, 20, 20)}, log)
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	taken, err := store.Sweep(context.Background(), id, time.Now().UTC())
	if err != nil {
		t.Fatalf("sweeping: %v", err)
	}
	if len(taken) != 1 || taken[0].ExerciseID != "q" {
		t.Fatalf("the sweep took %v", taken)
	}

	inForce, err := store.InForce(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if !inForce[analysis.Question{ExerciseID: "q", Version: 1}] {
		t.Error("the question is not out of circulation after being swept")
	}

	// AND IT SAYS WHY, IN THE NUMBERS. The first thing anybody asks about a
	// question that vanished from a course is what it was measured at.
	if len(log.entries) != 1 || log.entries[0] != analysis.ActionQuarantined+" q" {
		t.Fatalf("the audit recorded %v", log.entries)
	}
	if !strings.Contains(log.reasons[0], "-1.00") || !strings.Contains(log.reasons[0], "40") {
		t.Errorf("the reason is %q; it should carry the index and the attempts", log.reasons[0])
	}
}

// NOTHING ELSE IS TAKEN OUT. Quarantining is the strongest thing this system
// does on its own — it removes a question from a course without anybody looking
// — so it happens for exactly one verdict.
func TestOnlyAnInvertedQuestionIsQuarantined(t *testing.T) {
	pool := testPool(t)
	log := &recorder{}

	for _, c := range []struct {
		name    string
		answers []analysis.Answer
	}{
		{"a good question", paper(20, 18, 20, 4)},
		{"a trivial one", paper(20, 20, 20, 19)},
		{"a hard one that separates students", paper(20, 4, 20, 0)},
		{"one below the minimum sample", paper(7, 0, 7, 7)},
	} {
		id := school(t, pool)
		store := quarantining(t, pool, map[uuid.UUID][]analysis.Answer{id: c.answers}, log)
		if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
			t.Fatal(err)
		}

		taken, err := store.Sweep(context.Background(), id, time.Now().UTC())
		if err != nil {
			t.Fatalf("%s: %v", c.name, err)
		}
		if len(taken) != 0 {
			t.Errorf("%s was taken out of circulation", c.name)
		}
	}
}

// AND IT CANNOT BE WIDENED BY THE ONE CALLER THAT COULD. Quarantine refuses a
// verdict that is not flagged, so a future caller reaching for it directly
// cannot remove a question for being hard.
func TestQuarantineRefusesAVerdictThatIsNotFlagged(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	log := &recorder{}
	store := quarantining(t, pool, nil, log)

	for _, verdict := range []analysis.Verdict{
		analysis.VerdictFine, analysis.VerdictWeak,
		analysis.VerdictTooEasy, analysis.VerdictInsufficient,
	} {
		err := store.Quarantine(context.Background(), id, analysis.Statistics{
			ExerciseID: "x", Version: 1, Verdict: verdict,
			Attempts: 100, MinimumSample: analysis.MinimumSample.Fallback,
		}, time.Now().UTC())
		if err == nil {
			t.Errorf("a %q question was quarantined", verdict)
		}
	}
}

// RUNNING THE SWEEP TWICE DOES NOT QUARANTINE ANYTHING TWICE. A nightly job
// that wrote an audit entry every night for the same question would bury the
// night it actually happened.
func TestSweepingTwiceRecordsItOnce(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	log := &recorder{}

	store := quarantining(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 0, 20, 20)}, log)
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	for range 3 {
		if _, err := store.Sweep(context.Background(), id, time.Now().UTC()); err != nil {
			t.Fatal(err)
		}
	}
	if len(log.entries) != 1 {
		t.Errorf("three sweeps wrote %d audit entries: %v", len(log.entries), log.entries)
	}
}

// FIXING THE QUESTION IS THE ORDINARY WAY OUT. A new version is a different
// question, so the quarantine on version 1 says nothing about version 2 and
// nobody has to remember to release anything.
func TestANewVersionIsNotUnderTheOldQuarantine(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	log := &recorder{}

	store := quarantining(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 0, 20, 20)}, log)
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Sweep(context.Background(), id, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	inForce, err := store.InForce(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if inForce[analysis.Question{ExerciseID: "q", Version: 2}] {
		t.Error("version 2 is under version 1's quarantine; fixing a question would not release it")
	}
	if !inForce[analysis.Question{ExerciseID: "q", Version: 1}] {
		t.Error("version 1 is not out of circulation")
	}
}

// AND THE OTHER WAY OUT NEEDS A REASON. Releasing overrides the numbers, and an
// override nobody explained is indistinguishable a year later from somebody
// having clicked the wrong row.
func TestReleasingNeedsAReasonAndIsAudited(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	log := &recorder{}

	store := quarantining(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 0, 20, 20)}, log)
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Sweep(context.Background(), id, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	q := analysis.Question{ExerciseID: "q", Version: 1}

	if err := store.Release(context.Background(), id, q, time.Now().UTC(), ""); err == nil {
		t.Error("a question was put back with no reason given")
	}

	if err := store.Release(context.Background(), id, q, time.Now().UTC(),
		"the cohort that sat it was a pilot group"); err != nil {
		t.Fatalf("releasing: %v", err)
	}

	inForce, err := store.InForce(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if inForce[q] {
		t.Error("the question is still out of circulation after being released")
	}

	if len(log.entries) != 2 || log.entries[1] != analysis.ActionReleased+" q" {
		t.Errorf("the release was not audited: %v", log.entries)
	}
	if log.reasons[1] != "the cohort that sat it was a pilot group" {
		t.Errorf("the reason recorded is %q", log.reasons[1])
	}

	// Releasing something that is not out of circulation says so rather than
	// quietly doing nothing.
	if err := store.Release(context.Background(), id, q, time.Now().UTC(), "again"); !errors.Is(err, analysis.ErrNotQuarantined) {
		t.Errorf("releasing an unquarantined question gave %v", err)
	}
}

// A SWEEP AFTER A RELEASE PUTS IT BACK OUT, because the numbers still say so.
// Releasing is an override of a verdict rather than a permanent exemption —
// the way to keep a question in circulation is to fix it or to fix the numbers.
func TestASweepAfterAReleaseTakesItOutAgain(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	log := &recorder{}

	store := quarantining(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 0, 20, 20)}, log)
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Sweep(context.Background(), id, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	q := analysis.Question{ExerciseID: "q", Version: 1}
	if err := store.Release(context.Background(), id, q, time.Now().UTC(), "looked at it"); err != nil {
		t.Fatal(err)
	}

	taken, err := store.Sweep(context.Background(), id, time.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	if len(taken) != 1 {
		t.Errorf("the next sweep took %d back out; the numbers still say it is inverted", len(taken))
	}
}

// A QUARANTINE THAT WAS NOT AUDITED IS A QUESTION THAT VANISHED WITH NOTHING
// SAYING WHY. It is an error rather than a silence, and a store with no audit
// at all cannot quarantine.
func TestQuarantiningWithoutAnAuditIsRefused(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)

	// No WithAudit at all.
	store := storeOver(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 0, 20, 20)})
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Sweep(context.Background(), id, time.Now().UTC()); err == nil {
		t.Error("a question was quarantined by a store with nowhere to record it")
	}

	// AND AN AUDIT THAT FAILS IS REPORTED RATHER THAN SWALLOWED. The row is
	// already written by then, so the error is the only thing that says the
	// two halves disagree — treating it as fine would leave a question out of
	// circulation with no entry explaining it.
	failing := &recorder{fail: errors.New("the log is down")}
	other := school(t, pool)
	loud := quarantining(t, pool, map[uuid.UUID][]analysis.Answer{other: paper(20, 0, 20, 20)}, failing)
	if _, err := loud.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if _, err := loud.Sweep(context.Background(), other, time.Now().UTC()); err == nil {
		t.Error("a quarantine whose audit entry failed to write was reported as a success")
	}
}
