package exam_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/exam"
	"github.com/codeschool-ing/schooling/internal/grade"
)

// EVERY TEST HERE MAKES ITS OWN SCHOOL and hangs everything off it. Packages
// run in parallel against one database, and a test that truncated a shared
// table would fail whichever other package happened to be halfway through — the
// kind of red that passes locally and only appears in CI, which is exactly what
// happened once.

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

func school(t *testing.T, db *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := db.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		"exam-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:12]).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

func student(t *testing.T, db *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := db.QueryRow(context.Background(),
		`INSERT INTO accounts (email) VALUES ($1) RETURNING id`,
		strings.ReplaceAll(uuid.NewString(), "-", "")[:16]+"@example.tld").Scan(&id); err != nil {
		t.Fatalf("seeding a student: %v", err)
	}
	return id
}

// questions seeds a pool of quizzes, each with a different choice marked
// correct, so that answering by luck is visible rather than plausible.
func questions(t *testing.T, db *pgxpool.Pool, tenantID uuid.UUID,
	scope exam.Scope, scopeID string, n int) {

	t.Helper()
	for i := range n {
		id := fmt.Sprintf("q%02d", i)
		correct := i % 4

		payload := map[string]any{
			"id": id, "version": 1, "type": "quiz",
			"prompt": fmt.Sprintf("Question %d?", i),
			"choices": []map[string]any{
				{"text": "first", "correct": correct == 0},
				{"text": "second", "correct": correct == 1},
				{"text": "third", "correct": correct == 2},
				{"text": "fourth", "correct": correct == 3},
			},
		}
		body, err := json.Marshal(payload)
		if err != nil {
			t.Fatalf("building a question: %v", err)
		}

		var courseID, trackID string
		if scope == exam.ScopeCourse {
			courseID = scopeID
		} else {
			trackID = scopeID
		}

		if _, err := db.Exec(context.Background(), `
			INSERT INTO catalog_exercises
				(tenant_id, id, course_id, track_id, exam, version, type, prompt, payload)
			VALUES ($1, $2, $3, $4, true, 1, 'quiz', $5, $6)
		`, tenantID, id, courseID, trackID, payload["prompt"], body); err != nil {
			t.Fatalf("seeding a question: %v", err)
		}
	}
}

// open is a paywall that says yes, which is what most of these tests need to
// get past to reach what they are actually about.
func open(_ context.Context, _ exam.Scope, _ string) (bool, error) { return true, nil }

func shut(_ context.Context, _ exam.Scope, _ string) (bool, error) { return false, nil }

// rightAnswer is what a student who knows the material would send: the correct
// choice, expressed against the shuffled paper they were actually shown.
//
// It reads the permutation out of the database because that is where it lives —
// the whole point of the design is that it never reaches the client, so a test
// standing in for a student who knows the answer has to go and get it.
func rightAnswer(t *testing.T, db *pgxpool.Pool, attemptID uuid.UUID, position int) json.RawMessage {
	t.Helper()

	var kind string
	var perm []int
	var sealed []byte
	if err := db.QueryRow(context.Background(), `
		SELECT type, perm, sealed FROM exam_answers WHERE attempt_id = $1 AND position = $2
	`, attemptID, position).Scan(&kind, &perm, &sealed); err != nil {
		t.Fatalf("reading question %d: %v", position, err)
	}

	key, err := grade.Key(kind, sealed)
	if err != nil {
		t.Fatalf("the key of question %d: %v", position, err)
	}
	var decoded struct {
		Chose []int `json:"chose"`
	}
	if err := json.Unmarshal(key, &decoded); err != nil {
		t.Fatalf("reading the key of question %d: %v", position, err)
	}

	inverse := make([]int, len(perm))
	for shown, original := range perm {
		inverse[original] = shown
	}
	moved := make([]int, len(decoded.Chose))
	for i, at := range decoded.Chose {
		moved[i] = inverse[at]
	}

	body, err := json.Marshal(map[string]any{"chose": moved})
	if err != nil {
		t.Fatalf("building an answer: %v", err)
	}
	return body
}

// wrongAnswer picks a choice that is not the right one.
func wrongAnswer(t *testing.T, db *pgxpool.Pool, attemptID uuid.UUID, position int) json.RawMessage {
	t.Helper()

	var right struct {
		Chose []int `json:"chose"`
	}
	if err := json.Unmarshal(rightAnswer(t, db, attemptID, position), &right); err != nil {
		t.Fatalf("reading the right answer: %v", err)
	}
	body, err := json.Marshal(map[string]any{"chose": []int{(right.Chose[0] + 1) % 4}})
	if err != nil {
		t.Fatalf("building an answer: %v", err)
	}
	return body
}

/* ---------- the three that matter ---------- */

// THE FIRST ONE.
//
// The answer must not leave the server. `grade` proves that a presented
// question hides its key; this proves that what an exam actually puts on the
// wire is the presented form and not the question — which is a different claim,
// and the one a mistake in this package would break.
func TestAPaperCarriesNoAnswers(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 6)

	store := exam.NewStore(db, open)
	paper, _, err := store.Start(context.Background(), school, student,
		exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}
	if len(paper.Questions) != 6 {
		t.Fatalf("the paper has %d questions, want 6", len(paper.Questions))
	}

	for _, q := range paper.Questions {
		shown := string(q.Shown)
		for _, tell := range []string{`"correct"`, `"why"`} {
			if strings.Contains(shown, tell) {
				t.Errorf("question %d went out carrying %s:\n  %s", q.Position, tell, shown)
			}
		}
		if q.Correct != nil {
			t.Errorf("question %d says whether it is right before the paper is handed in", q.Position)
		}
	}

	// And the sealed copy IS in the database, because that is what the paper is
	// marked against. A test that only checked the wire would pass just as well
	// against a version that never stored the question at all.
	var sealed []byte
	if err := db.QueryRow(context.Background(),
		`SELECT sealed FROM exam_answers WHERE attempt_id = $1 AND position = 0`,
		paper.AttemptID).Scan(&sealed); err != nil {
		t.Fatalf("reading the sealed question: %v", err)
	}
	if !strings.Contains(string(sealed), `"correct"`) {
		t.Errorf("the sealed question has no answer key in it, so nothing could mark the paper:\n  %s",
			sealed)
	}
}

// THE SECOND ONE.
//
// Starting an exam that is already open resumes it. If it drew a second paper,
// the way to pass would be to start, read, abandon and start again until the
// questions were ones you liked — and every one of those draws is an
// ordinary-looking row that no report would flag.
func TestStartingAgainResumesTheSamePaper(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 8)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	first, resumed, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}
	if resumed {
		t.Error("the first start says it resumed something")
	}

	again, resumed, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting again: %v", err)
	}
	if !resumed {
		t.Error("starting again drew a new paper instead of resuming the open one")
	}
	if again.AttemptID != first.AttemptID {
		t.Fatalf("starting again gave attempt %s, want %s", again.AttemptID, first.AttemptID)
	}

	// The same questions, in the same order. An attempt id that matched while
	// the paper had been redrawn would be the same defect wearing the answer.
	for i := range first.Questions {
		if first.Questions[i].ExerciseID != again.Questions[i].ExerciseID {
			t.Fatalf("question %d was %q and is now %q", i,
				first.Questions[i].ExerciseID, again.Questions[i].ExerciseID)
		}
		if string(first.Questions[i].Shown) != string(again.Questions[i].Shown) {
			t.Errorf("question %d was shuffled again between one reload and the next", i)
		}
	}
}

// THE THIRD ONE.
//
// A paper is marked once, at submission, and nothing about it moves afterwards.
// The trigger in the schema is the last line of that, and it is checked here
// with a hand-written UPDATE — because the rule has to hold against SQL that
// this package did not write, which is the only kind that will ever break it.
func TestNothingChangesAfterThePaperIsHandedIn(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 4)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	paper, _, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}
	for _, q := range paper.Questions {
		if err := store.Answer(ctx, school, student, paper.AttemptID, q.Position,
			rightAnswer(t, db, paper.AttemptID, q.Position)); err != nil {
			t.Fatalf("answering %d: %v", q.Position, err)
		}
	}

	marked, first, err := store.Submit(ctx, school, student, paper.AttemptID)
	if err != nil {
		t.Fatalf("handing in: %v", err)
	}
	if !first {
		t.Error("the first hand-in says it did not mark the paper")
	}
	if marked.Result == nil || marked.Result.Score != 4 || !marked.Result.Passed {
		t.Fatalf("a paper answered correctly throughout came back as %+v", marked.Result)
	}

	// An answer after the fact.
	err = store.Answer(ctx, school, student, paper.AttemptID, 0,
		wrongAnswer(t, db, paper.AttemptID, 0))
	if !errors.Is(err, exam.ErrHandedIn) {
		t.Errorf("answering a handed-in paper gave %v, want ErrHandedIn", err)
	}

	// A second hand-in is the same paper, not a second marking.
	again, second, err := store.Submit(ctx, school, student, paper.AttemptID)
	if err != nil {
		t.Fatalf("handing in again: %v", err)
	}
	if second {
		t.Error("handing in twice marked the paper twice, and would count the event twice with it")
	}
	if again.Result == nil || *again.Result != *marked.Result {
		t.Errorf("handing in again gave %+v, want %+v", again.Result, marked.Result)
	}

	// And the schema itself refuses, whoever is asking.
	_, err = db.Exec(ctx, `UPDATE exam_attempts SET score = 0, passed = false WHERE id = $1`,
		paper.AttemptID)
	if err == nil {
		t.Error("a handed-in attempt was edited by hand, so the score no longer explains the rows " +
			"it came from")
	}
}

/* ---------- the door ---------- */

func TestAnExamNobodyMaySitCannotBeStarted(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 4)

	store := exam.NewStore(db, shut)
	_, _, err := store.Start(context.Background(), school, student,
		exam.ScopeCourse, "web-fundamentals")
	if !errors.Is(err, exam.ErrLocked) {
		t.Fatalf("starting a locked exam gave %v, want ErrLocked", err)
	}

	var attempts int
	if err := db.QueryRow(context.Background(),
		`SELECT count(*) FROM exam_attempts WHERE tenant_id = $1`, school).Scan(&attempts); err != nil {
		t.Fatalf("counting attempts: %v", err)
	}
	if attempts != 0 {
		t.Errorf("a locked exam left %d attempts behind", attempts)
	}
}

// AN EXAM WITH NO QUESTIONS IS NOT AN EMPTY PAPER. An empty paper is passed by
// everybody at once — zero of zero is a hundred percent by every arithmetic
// anybody would write — so there is no such thing as one.
func TestAnExamWithNoQuestionsIsNotAnEmptyPaper(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)

	store := exam.NewStore(db, open)
	_, _, err := store.Start(context.Background(), school, student, exam.ScopeCourse, "nothing-here")
	if !errors.Is(err, exam.ErrNoSuchExam) {
		t.Fatalf("an exam with no questions gave %v, want ErrNoSuchExam", err)
	}
}

// One student's paper is one student's. The boundary between students is this
// code rather than the database noticing (P-05), which is why it is asserted
// rather than assumed.
func TestSomebodyElsesPaperIsNotFound(t *testing.T) {
	db := testPool(t)
	school := school(t, db)
	mine, theirs := student(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 4)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	paper, _, err := store.Start(ctx, school, mine, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}

	if _, err := store.Attempt(ctx, school, theirs, paper.AttemptID); !errors.Is(err, exam.ErrNoSuchAttempt) {
		t.Errorf("reading somebody else's paper gave %v, want ErrNoSuchAttempt", err)
	}
	err = store.Answer(ctx, school, theirs, paper.AttemptID, 0, json.RawMessage(`{"chose":[0]}`))
	if !errors.Is(err, exam.ErrNoSuchAttempt) {
		t.Errorf("answering on somebody else's paper gave %v, want ErrNoSuchAttempt", err)
	}
	if _, _, err := store.Submit(ctx, school, theirs, paper.AttemptID); !errors.Is(err, exam.ErrNoSuchAttempt) {
		t.Errorf("handing in somebody else's paper gave %v, want ErrNoSuchAttempt", err)
	}
}

/* ---------- marking ---------- */

// AN UNANSWERED QUESTION IS WRONG. A paper marked out of the questions somebody
// chose to attempt would let a student answer the one they were sure of and
// score a hundred percent.
func TestAnUnansweredQuestionIsWrong(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 4)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	paper, _, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}
	if err := store.Answer(ctx, school, student, paper.AttemptID, 0,
		rightAnswer(t, db, paper.AttemptID, 0)); err != nil {
		t.Fatalf("answering: %v", err)
	}

	marked, _, err := store.Submit(ctx, school, student, paper.AttemptID)
	if err != nil {
		t.Fatalf("handing in: %v", err)
	}
	if marked.Result.Score != 1 || marked.Result.Of != 4 {
		t.Fatalf("one right answer out of four scored %d/%d", marked.Result.Score, marked.Result.Of)
	}
	if marked.Result.Passed {
		t.Error("a quarter of the paper passed it")
	}
	for _, q := range marked.Questions {
		if q.Correct == nil {
			t.Errorf("question %d came back unmarked", q.Position)
		}
	}
}

// THE PASS MARK, ON THE MARK.
//
// It lives in code with a test on it (K-13), and this is the test: exactly the
// mark passes and one question fewer does not. The comparison is integer
// arithmetic for this reason — a student sitting on the boundary must not pass
// or fail depending on how a ratio rounded.
func TestTheMarkIsExact(t *testing.T) {
	const of = 20
	needed := of * exam.PassMark / 100 // 14 of 20, at seventy percent

	for _, right := range []int{needed, needed - 1} {
		db := testPool(t)
		school, student := school(t, db), student(t, db)
		questions(t, db, school, exam.ScopeCourse, "web-fundamentals", of)
		store := exam.NewStore(db, open)
		ctx := context.Background()

		paper, _, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
		if err != nil {
			t.Fatalf("starting: %v", err)
		}
		for _, q := range paper.Questions {
			answer := wrongAnswer(t, db, paper.AttemptID, q.Position)
			if q.Position < right {
				answer = rightAnswer(t, db, paper.AttemptID, q.Position)
			}
			if err := store.Answer(ctx, school, student, paper.AttemptID, q.Position, answer); err != nil {
				t.Fatalf("answering %d: %v", q.Position, err)
			}
		}

		marked, _, err := store.Submit(ctx, school, student, paper.AttemptID)
		if err != nil {
			t.Fatalf("handing in: %v", err)
		}
		if marked.Result.Score != right {
			t.Fatalf("%d right answers scored %d", right, marked.Result.Score)
		}
		if want := right >= needed; marked.Result.Passed != want {
			t.Errorf("%d of %d at a pass mark of %d%% came back passed=%v, want %v",
				right, of, exam.PassMark, marked.Result.Passed, want)
		}
		if marked.Result.PassMark != exam.PassMark {
			t.Errorf("the attempt recorded a pass mark of %d, want %d",
				marked.Result.PassMark, exam.PassMark)
		}
	}
}

// A pass is a fact about a day somebody knew the material, and sitting the exam
// again out of curiosity and failing does not unmake it (A-05).
func TestAPassIsNotUndoneByALaterFailure(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 4)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	sit := func(correctly bool) {
		paper, _, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
		if err != nil {
			t.Fatalf("starting: %v", err)
		}
		for _, q := range paper.Questions {
			answer := wrongAnswer(t, db, paper.AttemptID, q.Position)
			if correctly {
				answer = rightAnswer(t, db, paper.AttemptID, q.Position)
			}
			if err := store.Answer(ctx, school, student, paper.AttemptID, q.Position, answer); err != nil {
				t.Fatalf("answering: %v", err)
			}
		}
		if _, _, err := store.Submit(ctx, school, student, paper.AttemptID); err != nil {
			t.Fatalf("handing in: %v", err)
		}
	}

	sit(true)
	sit(false)

	passed, err := store.Passed(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if !passed {
		t.Error("a later failure unmade an earlier pass, and a certificate would go with it")
	}

	history, err := store.History(ctx, school, student)
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if len(history) != 2 {
		t.Fatalf("the history has %d attempts, want 2", len(history))
	}
}

/* ---------- the draw ---------- */

// A pool longer than a paper is drawn from, and two students do not get the
// same paper. Without the draw, a pool of two hundred is memorised one attempt
// at a time.
func TestALongPoolIsDrawnFrom(t *testing.T) {
	db := testPool(t)
	school := school(t, db)
	first, second := student(t, db), student(t, db)
	questions(t, db, school, exam.ScopeTrack, "frontend", exam.QuestionsPerAttempt+8)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	papers := make([][]string, 2)
	for i, who := range []uuid.UUID{first, second} {
		paper, _, err := store.Start(ctx, school, who, exam.ScopeTrack, "frontend")
		if err != nil {
			t.Fatalf("starting: %v", err)
		}
		if len(paper.Questions) != exam.QuestionsPerAttempt {
			t.Fatalf("a pool of %d gave a paper of %d, want %d",
				exam.QuestionsPerAttempt+8, len(paper.Questions), exam.QuestionsPerAttempt)
		}
		for _, q := range paper.Questions {
			papers[i] = append(papers[i], q.ExerciseID)
		}
	}

	if strings.Join(papers[0], ",") == strings.Join(papers[1], ",") {
		t.Error("two students got the same paper in the same order out of a pool half again as " +
			"long, which is not a draw")
	}
}

/* ---------- answers ---------- */

// An answer that is not shaped like one is refused while the student can still
// do something about it, rather than marked wrong in silence at the end.
func TestAnAnswerThatIsNotAnAnswerIsRefused(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 4)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	paper, _, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}

	for _, nonsense := range []string{`{"chose":[9]}`, `{"order":[0,1]}`, `"yes"`, `[]`} {
		err := store.Answer(ctx, school, student, paper.AttemptID, 0, json.RawMessage(nonsense))
		if !errors.Is(err, exam.ErrBadAnswer) {
			t.Errorf("the answer %s gave %v, want ErrBadAnswer", nonsense, err)
		}
	}

	// AND `{}` IS NOT NONSENSE. It is a student who chose nothing, which is an
	// answer and a wrong one — the distinction this error exists to draw is
	// between a client sending rubbish and a person being wrong, and "I picked
	// none of them" is firmly the second.
	if err := store.Answer(ctx, school, student, paper.AttemptID, 0,
		json.RawMessage(`{}`)); err != nil {
		t.Errorf("choosing nothing was refused as malformed: %v", err)
	}

	err = store.Answer(ctx, school, student, paper.AttemptID, 99, json.RawMessage(`{"chose":[0]}`))
	if !errors.Is(err, exam.ErrNoSuchQuestion) {
		t.Errorf("answering a question that is not on the paper gave %v, want ErrNoSuchQuestion", err)
	}
}

// An answer may be replaced until the paper is handed in, and the last one is
// the one that counts. That is what sitting an exam is.
func TestAnAnswerCanBeChangedUntilTheEnd(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 4)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	paper, _, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}
	for _, q := range paper.Questions {
		if err := store.Answer(ctx, school, student, paper.AttemptID, q.Position,
			wrongAnswer(t, db, paper.AttemptID, q.Position)); err != nil {
			t.Fatalf("answering: %v", err)
		}
	}
	for _, q := range paper.Questions {
		if err := store.Answer(ctx, school, student, paper.AttemptID, q.Position,
			rightAnswer(t, db, paper.AttemptID, q.Position)); err != nil {
			t.Fatalf("changing an answer: %v", err)
		}
	}

	marked, _, err := store.Submit(ctx, school, student, paper.AttemptID)
	if err != nil {
		t.Fatalf("handing in: %v", err)
	}
	if marked.Result.Score != 4 {
		t.Errorf("a paper answered wrongly and then corrected scored %d of %d",
			marked.Result.Score, marked.Result.Of)
	}
}

// THE CATALOGUE MOVES AND THE PAPER DOES NOT.
//
// The load job rewrites the whole catalogue on every content deploy. A student
// who started an exam ten minutes earlier is marked against the questions they
// were asked, because the attempt carries them — and this is the test that
// would fail the day somebody grades against `catalog_exercises` instead.
func TestAPaperOutlivesTheCatalogueItCameFrom(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	questions(t, db, school, exam.ScopeCourse, "web-fundamentals", 4)
	store := exam.NewStore(db, open)
	ctx := context.Background()

	paper, _, err := store.Start(ctx, school, student, exam.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}
	answers := make([]json.RawMessage, len(paper.Questions))
	for _, q := range paper.Questions {
		answers[q.Position] = rightAnswer(t, db, paper.AttemptID, q.Position)
	}

	// The deploy: every question this exam was drawn from, gone.
	if _, err := db.Exec(ctx, `DELETE FROM catalog_exercises WHERE tenant_id = $1`, school); err != nil {
		t.Fatalf("emptying the catalogue: %v", err)
	}

	for _, q := range paper.Questions {
		if err := store.Answer(ctx, school, student, paper.AttemptID, q.Position,
			answers[q.Position]); err != nil {
			t.Fatalf("answering after the deploy: %v", err)
		}
	}
	marked, _, err := store.Submit(ctx, school, student, paper.AttemptID)
	if err != nil {
		t.Fatalf("handing in after the deploy: %v", err)
	}
	if marked.Result.Score != 4 {
		t.Errorf("a paper answered correctly scored %d of %d after the catalogue was rewritten "+
			"underneath it", marked.Result.Score, marked.Result.Of)
	}
}
