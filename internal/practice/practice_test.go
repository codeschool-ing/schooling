package practice_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/practice"
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

// The catalogue as the one question this module asks it. A fake is honest here:
// what is under test is what practice does with the answer, and the catalogue's
// own tests cover the answer.
func mayOpen(_ context.Context, courseID string) (bool, error) {
	return courseID != "paid-course", nil
}

func school(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		"drill-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:10]).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

func student(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO accounts (email) VALUES ($1) RETURNING id`,
		strings.ReplaceAll(uuid.NewString(), "-", "")[:16]+"@example.tld").Scan(&id); err != nil {
		t.Fatalf("seeding a student: %v", err)
	}
	return id
}

// The questions a school has: two to drill, one that is not for drilling, and
// one in a course nobody has paid for.
func questions(t *testing.T, pool *pgxpool.Pool, tenant uuid.UUID) {
	t.Helper()

	for _, q := range []struct {
		id, course, lesson string
		drillable          bool
	}{
		{"free-1", "free-course", "one", true},
		{"free-2", "free-course", "one", true},
		{"exam-only", "free-course", "one", false},
		{"behind-the-till", "paid-course", "one", true},
	} {
		if _, err := pool.Exec(context.Background(), `
			INSERT INTO catalog_exercises
				(tenant_id, id, course_id, lesson_id, section_id, exam, version, type,
				 drillable, prompt, payload)
			VALUES ($1, $2, $3, $4, 'roles', false, 1, 'quiz', $5, 'A question', '{}'::jsonb)
		`, tenant, q.id, q.course, q.lesson, q.drillable); err != nil {
			t.Fatalf("seeding %s: %v", q.id, err)
		}
	}
}

func store(t *testing.T, pool *pgxpool.Pool) *practice.Store {
	t.Helper()
	return practice.NewStore(pool, mayOpen)
}

func has(cards []practice.Card, id string) bool {
	for _, c := range cards {
		if c.ExerciseID == id {
			return true
		}
	}
	return false
}

// THE ONE THAT MATTERS, and the sentence the phase is done when it is true:
// yesterday's review comes back today, and today's does not come back until it
// is due.
func TestAnAnsweredCardLeavesTheQueueAndComesBackWhenItIsDue(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()
	questions(t, pool, tenant)

	before, err := s.Due(ctx, tenant, me, 0)
	if err != nil {
		t.Fatalf("reading the queue: %v", err)
	}
	if !has(before, "free-1") {
		t.Fatalf("a question nobody has answered is not in the queue: %v", before)
	}

	if _, err := s.Answered(ctx, tenant, me, "free-1", true, 2*time.Second); err != nil {
		t.Fatalf("answering: %v", err)
	}

	after, err := s.Due(ctx, tenant, me, 0)
	if err != nil {
		t.Fatalf("reading the queue: %v", err)
	}
	if has(after, "free-1") {
		t.Error("a card answered correctly is still in today's queue — the schedule is not " +
			"being read, and the student would be asked the same question until they got it wrong")
	}

	// And it is back the moment its day arrives. Moved by hand rather than by
	// waiting: a test that could only run tomorrow would not be run.
	if _, err := pool.Exec(ctx, `
		UPDATE practice_state SET due_on = current_date
		WHERE tenant_id = $1 AND account_id = $2 AND exercise_id = 'free-1'
	`, tenant, me); err != nil {
		t.Fatalf("moving the due date: %v", err)
	}

	due, err := s.Due(ctx, tenant, me, 0)
	if err != nil {
		t.Fatalf("reading the queue: %v", err)
	}
	if !has(due, "free-1") {
		t.Error("a card whose day has come is not in the queue — which is the whole feature")
	}
}

// BOTH WRITES OR NEITHER. The state and the log are one fact in two tables: a
// state without its log entry is a schedule that can never be refitted, and the
// log is what has been written since Fase 0 for exactly that.
func TestAnsweringWritesTheStateAndTheLogTogether(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()
	questions(t, pool, tenant)

	if _, err := s.Answered(ctx, tenant, me, "free-1", false, 90*time.Second); err != nil {
		t.Fatalf("answering: %v", err)
	}

	var intervalBefore, intervalAfter, quality int
	var easeBefore float64
	var scheduler string
	if err := pool.QueryRow(ctx, `
		SELECT interval_before, interval_after, quality, ease_before, scheduler
		FROM practice_review
		WHERE tenant_id = $1 AND account_id = $2 AND exercise_id = 'free-1'
	`, tenant, me).Scan(&intervalBefore, &intervalAfter, &quality, &easeBefore, &scheduler); err != nil {
		t.Fatalf("reading the review log: %v", err)
	}

	// THE "BEFORE" COLUMNS ARE THE POINT. A later scheduler is fitted by
	// replaying what was known at each answer; without these there is nothing
	// to replay, and they are the ones nobody thinks to store.
	if easeBefore == 0 {
		t.Error("the log recorded a zero ease before the answer — a new card starts at 2.5, " +
			"and a zero here means the state was read after it was written")
	}
	if scheduler != practice.Scheduler {
		t.Errorf("the log says scheduler %q, want %q — rows from different schedulers must "+
			"stay distinguishable", scheduler, practice.Scheduler)
	}
	if quality >= 3 {
		t.Errorf("a wrong answer was logged with quality %d, which reads as remembering it", quality)
	}
}

// A LOCKED COURSE CONTRIBUTES NOTHING, at both ends. In the queue, because a
// paywall discovered one question at a time is not a paywall; and on the way
// in, because a client does not have to use the queue to reach this.
func TestACardInALockedCourseIsNeitherOfferedNorAnswerable(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()
	questions(t, pool, tenant)

	queue, err := s.Due(ctx, tenant, me, 0)
	if err != nil {
		t.Fatalf("reading the queue: %v", err)
	}
	if has(queue, "behind-the-till") {
		t.Error("a question from a course this student cannot open is in their queue")
	}

	if _, err := s.Answered(ctx, tenant, me, "behind-the-till", true, time.Second); !errors.Is(err, practice.ErrLocked) {
		t.Errorf("answering a locked course's card gave %v, want ErrLocked", err)
	}
}

// `drillable` IS CHECKED RATHER THAN TRUSTED. An exam-only question that could
// be drilled would tell a student which questions are on the paper.
func TestAQuestionThatIsNotForDrillingIsRefused(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()
	questions(t, pool, tenant)

	queue, err := s.Due(ctx, tenant, me, 0)
	if err != nil {
		t.Fatalf("reading the queue: %v", err)
	}
	if has(queue, "exam-only") {
		t.Error("a question that is not drillable is in the drill queue")
	}

	if _, err := s.Answered(ctx, tenant, me, "exam-only", true, time.Second); !errors.Is(err, practice.ErrNotDrillable) {
		t.Errorf("drilling an exam-only question gave %v, want ErrNotDrillable", err)
	}
}

// An id a client invented must not reach the review log. That log is what a
// later scheduler is fitted against, and rows naming nothing would be rows
// nobody could interpret and nobody could delete with confidence.
func TestAnExerciseThatDoesNotExistIsRefused(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()
	questions(t, pool, tenant)

	_, err := s.Answered(ctx, tenant, me, "invented-by-a-client", true, time.Second)
	if !errors.Is(err, practice.ErrNoSuchExercise) {
		t.Fatalf("answering an exercise that does not exist gave %v, want ErrNoSuchExercise", err)
	}

	var logged int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM practice_review WHERE tenant_id = $1`, tenant).Scan(&logged); err != nil {
		t.Fatalf("counting the log: %v", err)
	}
	if logged != 0 {
		t.Errorf("%d rows reached the review log for a question that does not exist", logged)
	}
}

// ONE PERSON'S CARDS ARE ONE PERSON'S. Row-level security is deliberately
// absent (P-05), so the boundary between students is this code — which means it
// is worth a test that asks for somebody else's schedule and insists on getting
// none of it.
func TestOneStudentsScheduleIsNotAnothers(t *testing.T) {
	pool := testPool(t)
	s, tenant := store(t, pool), school(t, pool)
	me, them := student(t, pool), student(t, pool)
	ctx := context.Background()
	questions(t, pool, tenant)

	if _, err := s.Answered(ctx, tenant, me, "free-1", true, time.Second); err != nil {
		t.Fatalf("answering: %v", err)
	}

	// Mine has moved out of today's queue; theirs has not moved at all.
	theirs, err := s.Due(ctx, tenant, them, 0)
	if err != nil {
		t.Fatalf("reading their queue: %v", err)
	}
	if !has(theirs, "free-1") {
		t.Error("answering a card for one student took it out of another student's queue")
	}

	state, err := s.State(ctx, tenant, them, "free-1")
	if err != nil {
		t.Fatalf("reading their state: %v", err)
	}
	if state.Repetition != 0 {
		t.Errorf("another student's card shows %d repetitions of somebody else's work",
			state.Repetition)
	}
}

// A school's cards are that school's. Every query here leads with the tenant,
// and this is the test that says so rather than the convention.
func TestOneSchoolsCardsAreNotAnothers(t *testing.T) {
	pool := testPool(t)
	s, me := store(t, pool), student(t, pool)
	here, elsewhere := school(t, pool), school(t, pool)
	ctx := context.Background()
	questions(t, pool, here)

	queue, err := s.Due(ctx, elsewhere, me, 0)
	if err != nil {
		t.Fatalf("reading the queue: %v", err)
	}
	if len(queue) != 0 {
		t.Errorf("a school with no questions of its own offered %d cards from another school",
			len(queue))
	}
}
