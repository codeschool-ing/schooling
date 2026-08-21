package practice_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
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
		// A REAL PAYLOAD, because the server marks the answer now. A stub
		// would make every one of these tests pass against a grader that
		// refused everything.
		payload := `{"id":"` + q.id + `","version":1,"type":"quiz",` +
			`"prompt":"Which one?","choices":[` +
			`{"text":"The right one","correct":true},{"text":"The other one"}]}`

		if _, err := pool.Exec(context.Background(), `
			INSERT INTO catalog_exercises
				(tenant_id, id, course_id, lesson_id, section_id, exam, version, type,
				 drillable, prompt, payload)
			VALUES ($1, $2, $3, $4, 'roles', false, 1, 'quiz', $5, 'Which one?', $6::jsonb)
		`, tenant, q.id, q.course, q.lesson, q.drillable, payload); err != nil {
			t.Fatalf("seeding %s: %v", q.id, err)
		}
	}
}

// Nothing is out of circulation. The tests about a withdrawn card pass a set.
func nothingWithdrawn(context.Context, uuid.UUID) (map[practice.Item]bool, error) {
	return nil, nil
}

func store(t *testing.T, pool *pgxpool.Pool) *practice.Store {
	t.Helper()
	return practice.NewStore(pool, mayOpen, nothingWithdrawn)
}

// answer draws a card and answers it in the frame it was shown, which is the
// only way an answer can be marked. `right` picks the choice the payload says
// is correct — found by asking the presented question which position it is in,
// because the whole point of presenting is that the position moves.
func answer(t *testing.T, s *practice.Store, tenant, me uuid.UUID,
	id string, right bool, elapsed time.Duration) (practice.Marked, error) {
	t.Helper()

	card, err := s.Draw(context.Background(), tenant, me, id, "en")
	if err != nil {
		return practice.Marked{}, err
	}

	var shown struct {
		Choices []struct {
			Text string `json:"text"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(card.Shown, &shown); err != nil {
		t.Fatalf("reading the presented question: %v", err)
	}

	chose := -1
	for i, c := range shown.Choices {
		if (c.Text == "The right one") == right {
			chose = i
			break
		}
	}
	if chose < 0 {
		t.Fatalf("the presented question has no choice to pick: %s", card.Shown)
	}

	return s.Answered(context.Background(), tenant, me, id,
		json.RawMessage(fmt.Sprintf(`{"chose":[%d]}`, chose)), elapsed, "en")
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

	if _, err := answer(t, s, tenant, me, "free-1", true, 2*time.Second); err != nil {
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

	if _, err := answer(t, s, tenant, me, "free-1", false, 90*time.Second); err != nil {
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

	if _, err := answer(t, s, tenant, me, "behind-the-till", true, time.Second); !errors.Is(err, practice.ErrLocked) {
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

	if _, err := answer(t, s, tenant, me, "exam-only", true, time.Second); !errors.Is(err, practice.ErrNotDrillable) {
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

	_, err := answer(t, s, tenant, me, "invented-by-a-client", true, time.Second)
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

	if _, err := answer(t, s, tenant, me, "free-1", true, time.Second); err != nil {
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

// THE SERVER DECIDES WHETHER IT WAS RIGHT. For one commit the client said so,
// which could only ever have been an assertion nothing checked: the question a
// client is given has no key in it, so it has nothing to check against.
func TestTheServerMarksTheAnswerRatherThanBeingTold(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	questions(t, pool, tenant)

	right, err := answer(t, s, tenant, me, "free-1", true, time.Second)
	if err != nil {
		t.Fatalf("answering: %v", err)
	}
	if !right.Correct {
		t.Error("the right choice was marked wrong")
	}

	wrong, err := answer(t, s, tenant, me, "free-2", false, time.Second)
	if err != nil {
		t.Fatalf("answering: %v", err)
	}
	if wrong.Correct {
		t.Error("the wrong choice was marked right")
	}
}

// THE SHUFFLE HAS TO SURVIVE THE ROUND TRIP, and this is the test that says so.
// An `ordering` question is the case that bites: the order IS the answer, so it
// is shuffled on the way out, and an answer marked without mapping it back
// through the permutation tells a student who put four steps in perfect order
// that they are wrong.
//
// It answers with the shown positions in the order the payload says is right,
// which is what a student who knows the material would do.
func TestAnOrderingAnswerIsMarkedInTheFrameTheStudentSaw(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()

	if _, err := pool.Exec(ctx, `
		INSERT INTO catalog_exercises
			(tenant_id, id, course_id, lesson_id, section_id, exam, version, type,
			 drillable, prompt, payload)
		VALUES ($1, 'steps', 'free-course', 'one', 'roles', false, 1, 'ordering', true,
		        'In order', $2::jsonb)
	`, tenant, `{"id":"steps","version":1,"type":"ordering","prompt":"In order",`+
		`"items":["first","second","third","fourth"]}`); err != nil {
		t.Fatalf("seeding: %v", err)
	}

	card, err := s.Draw(ctx, tenant, me, "steps", "en")
	if err != nil {
		t.Fatalf("drawing: %v", err)
	}

	var shown struct {
		Items []string `json:"items"`
	}
	if err := json.Unmarshal(card.Shown, &shown); err != nil {
		t.Fatalf("reading the presented question: %v", err)
	}

	// The right answer, expressed as the shown positions: for each item of the
	// original order, where it now is.
	want := []string{"first", "second", "third", "fourth"}
	order := make([]int, 0, len(want))
	for _, item := range want {
		for at, s := range shown.Items {
			if s == item {
				order = append(order, at)
				break
			}
		}
	}
	if len(order) != len(want) {
		t.Fatalf("the presented question is missing items: %s", card.Shown)
	}

	body, err := json.Marshal(map[string]any{"order": order})
	if err != nil {
		t.Fatalf("building the answer: %v", err)
	}

	marked, err := s.Answered(ctx, tenant, me, "steps", body, 3*time.Second, "en")
	if err != nil {
		t.Fatalf("answering: %v", err)
	}
	if !marked.Correct {
		t.Errorf("a perfect ordering answer was marked wrong.\nshown: %s\nanswer: %s\n"+
			"The permutation is not being read back, so the answer is being compared "+
			"against an arrangement the student never saw.", card.Shown, body)
	}
}

// An answer to a card nobody drew cannot be marked, because there is no
// permutation to map it through. It is refused rather than guessed at: guessing
// would mean assuming no shuffle, which for an ordering question is assuming
// the answer.
func TestAnAnswerToACardThatWasNeverDrawnIsRefused(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()
	questions(t, pool, tenant)

	_, err := s.Answered(ctx, tenant, me, "free-1", json.RawMessage(`{"chose":[0]}`), time.Second, "en")
	if !errors.Is(err, practice.ErrNotDrawn) {
		t.Fatalf("answering an undrawn card gave %v, want ErrNotDrawn", err)
	}

	var logged int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM practice_review WHERE tenant_id = $1`, tenant).Scan(&logged); err != nil {
		t.Fatalf("counting the log: %v", err)
	}
	if logged != 0 {
		t.Errorf("%d rows reached the review log for a card nobody was shown", logged)
	}
}

// A MALFORMED ANSWER IS NOT A WRONG ONE. Recording it as wrong would move a
// schedule on the strength of a client's bug: a card the student never failed
// would come back tomorrow, and the log would carry a failure that never
// happened.
func TestAnAnswerThatDoesNotFitTheQuestionIsNotAWrongAnswer(t *testing.T) {
	pool := testPool(t)
	s, tenant, me := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()
	questions(t, pool, tenant)

	if _, err := s.Draw(ctx, tenant, me, "free-1", "en"); err != nil {
		t.Fatalf("drawing: %v", err)
	}

	_, err := s.Answered(ctx, tenant, me, "free-1", json.RawMessage(`{"order":[9,9,9]}`), time.Second, "en")
	if !errors.Is(err, practice.ErrBadAnswer) {
		t.Fatalf("a malformed answer gave %v, want ErrBadAnswer", err)
	}

	var scheduled int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM practice_state WHERE tenant_id = $1 AND account_id = $2`,
		tenant, me).Scan(&scheduled); err != nil {
		t.Fatalf("counting the schedule: %v", err)
	}
	if scheduled != 0 {
		t.Error("a malformed answer moved the schedule — the student would find a card " +
			"they never failed coming back tomorrow")
	}
}

func withdrawing(out ...practice.Item) practice.Quarantined {
	set := map[practice.Item]bool{}
	for _, q := range out {
		set[q] = true
	}
	return func(context.Context, uuid.UUID) (map[practice.Item]bool, error) { return set, nil }
}

// A WITHDRAWN CARD IS NOT IN THE QUEUE. Drilling a question we already know is
// broken would tell somebody they are wrong about something we got wrong — and
// then schedule it to come back and do it again.
func TestAWithdrawnCardIsNotInTheQueue(t *testing.T) {
	pool := testPool(t)
	tenant, account := school(t, pool), student(t, pool)
	questions(t, pool, tenant)

	drilling := practice.NewStore(pool, mayOpen,
		withdrawing(practice.Item{ExerciseID: "free-1", Version: 1}))

	queue, err := drilling.Due(context.Background(), tenant, account, 20)
	if err != nil {
		t.Fatalf("reading the queue: %v", err)
	}
	for _, card := range queue {
		if card.ExerciseID == "free-1" {
			t.Error("a withdrawn card is in the drill queue")
		}
	}
	if len(queue) == 0 {
		t.Error("the queue is empty; the other drillable card should still be in it")
	}
}

// AND IT IS REFUSED IF SOMEBODY REACHES IT ANYWAY. A queue is fetched once and
// drilled through, so a student holding one from before a sweep would still
// reach the card — the queue being right is not the same guarantee as the card
// being answerable.
func TestAWithdrawnCardCannotBeDrawnOrAnswered(t *testing.T) {
	pool := testPool(t)
	tenant, account := school(t, pool), student(t, pool)
	questions(t, pool, tenant)

	// Drawn while it is still in circulation, which is the situation this is
	// about: the student has the card in front of them.
	before := store(t, pool)
	if _, err := before.Draw(context.Background(), tenant, account, "free-1", "en"); err != nil {
		t.Fatalf("drawing: %v", err)
	}

	after := practice.NewStore(pool, mayOpen,
		withdrawing(practice.Item{ExerciseID: "free-1", Version: 1}))

	if _, err := after.Draw(context.Background(), tenant, account, "free-1", "en"); !errors.Is(err, practice.ErrWithdrawn) {
		t.Errorf("drawing a withdrawn card gave %v, want ErrWithdrawn", err)
	}

	answer := json.RawMessage(`{"chose":[0]}`)
	if _, err := after.Answered(context.Background(), tenant, account, "free-1",
		answer, time.Second, "en"); !errors.Is(err, practice.ErrWithdrawn) {
		t.Errorf("answering a withdrawn card gave %v, want ErrWithdrawn", err)
	}
}

/* ---------- the report on what a student has answered ---------- */

// It reads the LOG, so every answer is in it — including two answers to the
// same question. A report built from the scheduler's state instead would show
// one row per card and call it a history.
func TestTheHistoryCarriesEveryAnswerAndNotOneRowPerCard(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant, me := school(t, pool), student(t, pool)
	questions(t, pool, tenant)
	s := store(t, pool)

	if _, err := answer(t, s, tenant, me, "free-1", false, time.Second); err != nil {
		t.Fatal(err)
	}
	if _, err := answer(t, s, tenant, me, "free-1", true, time.Second); err != nil {
		t.Fatal(err)
	}

	history, err := s.History(ctx, tenant, me)
	if err != nil {
		t.Fatal(err)
	}
	if len(history) != 2 {
		t.Fatalf("two answers to one question came back as %d rows", len(history))
	}
	if !history[0].ReviewedAt.After(history[1].ReviewedAt) &&
		!history[0].ReviewedAt.Equal(history[1].ReviewedAt) {
		t.Error("the history is not newest first")
	}
	for _, a := range history {
		if a.CourseID != "free-course" {
			t.Errorf("an answer came back under the course %q", a.CourseID)
		}
		if a.Type != "quiz" {
			t.Errorf("an answer came back as the type %q", a.Type)
		}
	}
}

// THE COURSE AND THE TYPE ARE JOINED FROM THE CATALOGUE, not copied onto the
// log. They are facts about the QUESTION: an exercise moved to another lesson
// is the same exercise, and a report grouped by an id copied at answer time
// would group by where the question used to live.
//
// The cost of joining is this: an exercise the catalogue no longer has drops
// out of the report. The row stays in the log — that is what append-only means
// — and what cannot be shown is which course it belonged to.
func TestAnAnswerToAQuestionTheCatalogueLostDropsOutOfTheReport(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant, me := school(t, pool), student(t, pool)
	questions(t, pool, tenant)
	s := store(t, pool)

	if _, err := answer(t, s, tenant, me, "free-1", true, time.Second); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx,
		`DELETE FROM catalog_exercises WHERE tenant_id = $1 AND id = 'free-1'`, tenant); err != nil {
		t.Fatal(err)
	}

	history, err := s.History(ctx, tenant, me)
	if err != nil {
		t.Fatalf("the report failed rather than dropping the row: %v", err)
	}
	if len(history) != 0 {
		t.Errorf("an answer to a question the catalogue lost is still in the report: %+v", history)
	}

	// And the log itself still has it, which is the half that must not change.
	var kept int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM practice_review WHERE tenant_id = $1 AND account_id = $2`,
		tenant, me).Scan(&kept); err != nil {
		t.Fatal(err)
	}
	if kept != 1 {
		t.Errorf("the append-only log holds %d rows; the answer was given and cannot un-happen", kept)
	}
}

// One student's report is one student's — the rule the rest of this module
// obeys, checked on the read that goes across everything they have ever done.
func TestTheHistoryNeverCarriesAnotherStudentsAnswers(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant := school(t, pool)
	mine, theirs := student(t, pool), student(t, pool)
	questions(t, pool, tenant)
	s := store(t, pool)

	if _, err := answer(t, s, tenant, theirs, "free-1", true, time.Second); err != nil {
		t.Fatal(err)
	}

	history, err := s.History(ctx, tenant, mine)
	if err != nil {
		t.Fatal(err)
	}
	if len(history) != 0 {
		t.Errorf("a student who has answered nothing has %d answers", len(history))
	}
}

// A CARD IS DRAWN IN THE LANGUAGE THE STUDENT IS READING IN, and falls back to
// English rather than to nothing.
//
// The fallback is the half worth a test. A join that dropped a card with no
// translation would empty the queue of a Portuguese student the moment a
// question was added and not yet translated — and it would look like the
// schedule working, not like a bug.
func TestACardIsDrawnInTheStudentsLanguage(t *testing.T) {
	pool := testPool(t)
	tenant, me := school(t, pool), student(t, pool)
	questions(t, pool, tenant)
	s := store(t, pool)
	ctx := context.Background()

	if _, err := pool.Exec(ctx, `
		INSERT INTO catalog_exercise_text (tenant_id, exercise_id, locale, prompt, payload)
		VALUES ($1, 'free-1', 'pt', 'Qual delas?', $2::jsonb)
	`, tenant, `{"id":"free-1","version":1,"type":"quiz","prompt":"Qual delas?",`+
		`"choices":[{"text":"A certa","correct":true},{"text":"A outra"}]}`); err != nil {
		t.Fatalf("seeding the translation: %v", err)
	}

	card, err := s.Draw(ctx, tenant, me, "free-1", "pt")
	if err != nil {
		t.Fatalf("drawing in Portuguese: %v", err)
	}
	if !strings.Contains(string(card.Shown), "Qual delas?") {
		t.Errorf("the Portuguese card came back in English: %s", card.Shown)
	}

	// The same question in a language nobody wrote, and one nobody translated.
	for _, at := range []struct{ id, locale string }{
		{"free-1", "fr"},
		{"free-2", "pt"},
	} {
		card, err := s.Draw(ctx, tenant, me, at.id, at.locale)
		if err != nil {
			t.Fatalf("drawing %s in %s: %v", at.id, at.locale, err)
		}
		if !strings.Contains(string(card.Shown), "Which one?") {
			t.Errorf("%s in %s came back as %s, and English was the only thing left to show",
				at.id, at.locale, card.Shown)
		}
	}
}

// AND WHAT IT IS TOLD AFTERWARDS IS IN THE SAME LANGUAGE.
//
// `why` is the question's own words — a wrong choice's reason, an ordering's
// trap — so a student who answered in Portuguese and is told why in English has
// been handed the one sentence on the screen meant to teach them something, in
// a language they did not choose.
func TestTheReasonAnAnswerIsWrongComesBackTranslated(t *testing.T) {
	pool := testPool(t)
	tenant, me := school(t, pool), student(t, pool)
	questions(t, pool, tenant)
	s := store(t, pool)
	ctx := context.Background()

	if _, err := pool.Exec(ctx, `
		UPDATE catalog_exercises SET payload = $2::jsonb WHERE tenant_id = $1 AND id = 'free-1'
	`, tenant, `{"id":"free-1","version":1,"type":"quiz","prompt":"Which one?","choices":[`+
		`{"text":"The right one","correct":true,"why":"Whoever asks is the client."},`+
		`{"text":"The other one"}]}`); err != nil {
		t.Fatalf("giving the question a reason: %v", err)
	}
	if _, err := pool.Exec(ctx, `
		INSERT INTO catalog_exercise_text (tenant_id, exercise_id, locale, prompt, payload)
		VALUES ($1, 'free-1', 'pt', 'Qual delas?', $2::jsonb)
	`, tenant, `{"id":"free-1","version":1,"type":"quiz","prompt":"Qual delas?","choices":[`+
		`{"text":"A certa","correct":true,"why":"Quem pergunta é o cliente."},`+
		`{"text":"A outra"}]}`); err != nil {
		t.Fatalf("seeding the translation: %v", err)
	}

	card, err := s.Draw(ctx, tenant, me, "free-1", "pt")
	if err != nil {
		t.Fatalf("drawing: %v", err)
	}

	// THE WRONG ONE IN THE FRAME IT WAS SHOWN IN. The presented question is
	// shuffled, so a fixed index is whichever choice the shuffle put there —
	// which is how this test first passed by marking the right answer wrong.
	var shown struct {
		Choices []struct {
			Text string `json:"text"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(card.Shown, &shown); err != nil {
		t.Fatalf("reading the presented question: %v", err)
	}
	chose := -1
	for i, c := range shown.Choices {
		if c.Text != "A certa" {
			chose = i
			break
		}
	}
	if chose < 0 {
		t.Fatalf("the presented question has no wrong choice to pick: %s", card.Shown)
	}

	marked, err := s.Answered(ctx, tenant, me, "free-1",
		json.RawMessage(fmt.Sprintf(`{"chose":[%d]}`, chose)), 3*time.Second, "pt")
	if err != nil {
		t.Fatalf("answering: %v", err)
	}

	if marked.Correct {
		t.Fatal("the wrong choice was marked correct, so this proves nothing")
	}
	if marked.Why != "Quem pergunta é o cliente." {
		t.Errorf("the reason came back as %q, want the Portuguese one", marked.Why)
	}
}
