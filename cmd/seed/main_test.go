package main

import (
	"bytes"
	"context"
	"fmt"
	"math/rand"
	"os"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/analysis"
	"github.com/codeschool-ing/schooling/internal/event"
)

/* What a seeder has to be held to.

   IT WRITES SOMETHING NOTHING CAN TAKE BACK — the stream is append-only by
   trigger — so the interesting failures are not "it crashed". They are: a
   history that could not have happened, a population that leaks into a report
   about real people, and a demonstration that demonstrates nothing because the
   planted defect is not actually findable.

   Each of those is a test below, and two of them are checked by breaking what
   holds them: the default read is asked for the same rows and answers with
   none. */

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

// aSchool is the smallest catalogue a seeded life can be about: a track with a
// course in it, one lesson, three sections and six exam questions.
//
// SIX AND NOT ONE, because the discrimination index is a comparison between how
// the strong and the weak did on the WHOLE PAPER — with one question the paper
// is the question, and every student is in the group their answer put them in.
func aSchool(t *testing.T, pool *pgxpool.Pool) (uuid.UUID, string) {
	t.Helper()
	ctx := context.Background()

	slug := "seed-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:10]
	var id uuid.UUID
	if err := pool.QueryRow(ctx,
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Seeded') RETURNING id`,
		slug).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}

	must := func(sql string, args ...any) {
		t.Helper()
		if _, err := pool.Exec(ctx, sql, args...); err != nil {
			t.Fatalf("seeding the catalogue: %v", err)
		}
	}

	must(`INSERT INTO catalog_tracks (tenant_id, id, name, position)
	      VALUES ($1, 'tr-one', 'A track', 1)`, id)
	must(`INSERT INTO catalog_courses (tenant_id, id, name, draft)
	      VALUES ($1, 'co-one', 'A course', false)`, id)
	must(`INSERT INTO catalog_track_courses (tenant_id, track_id, course_id, position)
	      VALUES ($1, 'tr-one', 'co-one', 1)`, id)
	must(`INSERT INTO catalog_lessons (tenant_id, course_id, id, title, position)
	      VALUES ($1, 'co-one', 'le-one', 'A lesson', 1)`, id)
	for i := 1; i <= 3; i++ {
		must(`INSERT INTO catalog_sections
		        (tenant_id, course_id, lesson_id, id, kind, position)
		      VALUES ($1, 'co-one', 'le-one', $2, 'prose', $3)`,
			id, fmt.Sprintf("se-%d", i), i)
	}
	for i := 1; i <= 6; i++ {
		must(`INSERT INTO catalog_exercises
		        (tenant_id, id, course_id, exam, version, type, prompt, payload)
		      VALUES ($1, $2, 'co-one', true, 1, 'quiz', 'A question', '{}'::jsonb)`,
			id, fmt.Sprintf("ex-%d", i))
	}
	return id, slug
}

// seeded runs the command the way somebody would, against the test database.
func seeded(t *testing.T, slug string, args ...string) string {
	t.Helper()
	t.Setenv("SCHOOLING_DATABASE_URL", os.Getenv("SCHOOLING_TEST_DATABASE_URL"))
	t.Setenv("SCHOOLING_PLATFORM_DOMAIN", "example.tld")
	t.Setenv("SCHOOLING_ENV", "development")

	var out bytes.Buffer
	err := run(append([]string{"--school", slug, "--by", "the seeder's test"}, args...), &out)
	if err != nil {
		t.Fatalf("seeding %s: %v\n%s", slug, err, out.String())
	}
	return out.String()
}

// THE HISTORY IT WRITES COULD HAVE HAPPENED.
//
// A seeded past is worth exactly what its shape is worth. Moments out of order,
// a course completed before the lesson was opened, or an event dated after today
// would each produce a funnel that draws perfectly and describes nothing — and
// none of them would fail anything else.
//
// This one needs no database: the model is a pure function, which is what makes
// the question askable at all.
func TestTheHistoryItWritesCouldHaveHappened(t *testing.T) {
	to := time.Now().UTC()
	from := to.AddDate(0, -6, 0)
	s := shape{
		id: uuid.New(), slug: "seeded", track: "tr-one", course: "co-one", lesson: "le-one",
		sections:  []string{"se-1", "se-2", "se-3"},
		questions: []question{{id: "ex-1", version: 1, kind: "quiz"}, {id: "ex-2", version: 1, kind: "quiz"}},
		broken:    "ex-1",
	}

	lives := populate(rand.New(rand.NewSource(7)), s, from, to, 400) //nolint:gosec // repeatable on purpose

	// The order the steps of a journey may appear in. A step is only allowed
	// once whatever comes before it has happened.
	needs := map[string]string{
		"account.created":   "visitor.arrived",
		"track.opened":      "account.created",
		"lesson.opened":     "track.opened",
		"section.completed": "lesson.opened",
		"course.completed":  "section.completed",
		"exam.submitted":    "course.completed",
	}

	var everybodyMoved int
	for i, l := range lives {
		seen := map[string]bool{}
		var last time.Time
		for _, m := range l.moments {
			switch {
			case m.at.Before(from) || m.at.After(to):
				t.Fatalf("person %d has %q at %s, outside the window %s..%s",
					i, m.name, m.at, from, to)
			case m.at.Before(last):
				t.Fatalf("person %d has %q at %s, before the moment before it at %s — "+
					"a life that runs backwards is a funnel nobody can read",
					i, m.name, m.at, last)
			}
			if before, ok := needs[m.name]; ok && !seen[before] {
				t.Fatalf("person %d reached %q with no %q before it", i, m.name, before)
			}
			seen[m.name] = true
			last = m.at
		}
		if len(l.moments) > 0 {
			everybodyMoved++
		}

		// An event carrying an account index has to have an account to carry.
		for _, m := range l.moments {
			if m.account >= len(l.accounts) || m.visitor >= len(l.visitors) {
				t.Fatalf("person %d has %q pointing at an identity they do not have",
					i, m.name)
			}
		}
	}
	if everybodyMoved != len(lives) {
		t.Errorf("%d of %d people did nothing at all, and everybody at least arrives",
			len(lives)-everybodyMoved, len(lives))
	}
}

// AND IT HAS THE SHAPE A FUNNEL IS FOR: fewer people at every step.
func TestItFallsOffAtEveryStep(t *testing.T) {
	to := time.Now().UTC()
	s := shape{
		track: "tr-one", course: "co-one", lesson: "le-one",
		sections:  []string{"se-1", "se-2"},
		questions: []question{{id: "ex-1", version: 1, kind: "quiz"}},
		broken:    "ex-1",
	}
	lives := populate(rand.New(rand.NewSource(3)), s, to.AddDate(0, -6, 0), to, 800) //nolint:gosec // repeatable on purpose

	count := map[string]int{}
	for _, l := range lives {
		seen := map[string]bool{}
		for _, m := range l.moments {
			if !seen[m.name] {
				count[m.name]++
				seen[m.name] = true
			}
		}
	}

	steps := []string{"visitor.arrived", "account.created", "track.opened",
		"lesson.opened", "section.completed", "course.completed", "exam.submitted"}
	for i := 1; i < len(steps); i++ {
		if count[steps[i]] >= count[steps[i-1]] {
			t.Errorf("%s (%d) is not fewer than %s (%d) — a funnel that does not narrow "+
				"is a population nobody can read a drop out of",
				steps[i], count[steps[i]], steps[i-1], count[steps[i-1]])
		}
	}
	if count["exam.submitted"] < analysis.MinimumSample {
		t.Errorf("only %d people sat an exam, and item analysis says nothing below %d",
			count["exam.submitted"], analysis.MinimumSample)
	}
}

// THE PLANTED KEY IS FOUND BY THE SAME CODE THE CONSOLE WILL SHOW.
//
// This is phase 4's `Done when` — "a question with a broken answer key is found
// by the statistics" — asked of a real database, end to end: the command writes
// a population, and `analysis` reads the stream back and calls the one question
// with the inverted key inverted.
//
// The other five are checked too, and that half matters as much: a seeder that
// made every question look broken would pass the first half and be useless.
func TestTheBrokenKeyIsFound(t *testing.T) {
	pool := testPool(t)
	id, slug := aSchool(t, pool)

	out := seeded(t, slug, "--people", "600", "--rand", "11")
	if !strings.Contains(out, "the planted key was found") {
		t.Fatalf("the run did not report finding the planted key:\n%s", out)
	}

	answers, err := event.NewStore(pool).ItemAnswers(context.Background(), id, time.Time{},
		event.CountingSeeded)
	if err != nil {
		t.Fatalf("reading the seeded answers: %v", err)
	}

	byQuestion := map[string][]analysis.Answer{}
	for _, a := range answers {
		byQuestion[a.ExerciseID] = append(byQuestion[a.ExerciseID], analysis.Answer{
			ExerciseID: a.ExerciseID, Version: a.Version, Type: a.Type,
			AttemptID: a.AttemptID, Correct: a.Correct,
			Score: a.Score, Of: a.Of, AnsweredAt: a.AnsweredAt,
		})
	}
	if len(byQuestion) != 6 {
		t.Fatalf("the population answered %d of the 6 questions", len(byQuestion))
	}

	var others int
	for question, answers := range byQuestion {
		s, err := analysis.Summarise(answers)
		if err != nil {
			t.Fatalf("summarising %s: %v", question, err)
		}
		if s.Attempts < analysis.MinimumSample {
			t.Errorf("%s has %d answers and needs %d before anything can be said",
				question, s.Attempts, analysis.MinimumSample)
		}
		switch {
		case question == "ex-1" && s.Verdict != analysis.VerdictInverted:
			t.Errorf("the question seeded with an inverted key came back %q "+
				"(discrimination %+.2f) — the demonstration demonstrates nothing",
				s.Verdict, s.Discrimination)
		case question != "ex-1" && s.Verdict == analysis.VerdictInverted:
			t.Errorf("%s was seeded with a good key and came back inverted "+
				"(discrimination %+.2f) — a seeder that condemns every question is one "+
				"nobody can believe about the one it planted", question, s.Discrimination)
		case question != "ex-1":
			others++
		}
	}
	if others != 5 {
		t.Errorf("%d of the 5 good questions came back un-condemned", others)
	}
}

// AND NONE OF IT IS COUNTED AS A REAL PERSON.
//
// The seeded population and the real one live in the same table, and the ONLY
// thing keeping a report about people from being a report about the seeder is
// that flag. So the same two reads that answered above are asked again with
// their default, and have to answer with nothing.
func TestTheDefaultReadCannotSeeAnyOfIt(t *testing.T) {
	pool := testPool(t)
	id, slug := aSchool(t, pool)
	seeded(t, slug, "--people", "400", "--rand", "5")

	ctx := context.Background()
	events := event.NewStore(pool)

	for _, who := range []struct {
		counting event.Counting
		wantAny  bool
	}{
		{event.CountingSeeded, true},
		{event.CountingEverybody, true},
		{event.CountingReal, false},
	} {
		answers, err := events.ItemAnswers(ctx, id, time.Time{}, who.counting)
		if err != nil {
			t.Fatalf("reading answers as %s: %v", who.counting, err)
		}
		if got := len(answers) > 0; got != who.wantAny {
			t.Errorf("counting %s found %d answers, want any = %v",
				who.counting, len(answers), who.wantAny)
		}

		reached, err := events.Reached(ctx, id,
			[]string{"visitor.arrived", "account.created"}, time.Time{}, who.counting)
		if err != nil {
			t.Fatalf("reading who reached each step as %s: %v", who.counting, err)
		}
		if got := len(reached) > 0; got != who.wantAny {
			t.Errorf("counting %s found %d identities, want any = %v",
				who.counting, len(reached), who.wantAny)
		}
	}

	// And the accounts themselves, because the flag has to be on the row as
	// well as on the event: a screen listing people reads that table.
	var real int
	if err := pool.QueryRow(ctx, `
		SELECT count(*) FROM accounts
		WHERE NOT synthetic AND email LIKE '%@seed.invalid'
	`).Scan(&real); err != nil {
		t.Fatalf("counting the seeded accounts: %v", err)
	}
	if real != 0 {
		t.Errorf("%d seeded accounts are not flagged synthetic, which puts invented "+
			"students into every screen about people", real)
	}
}

// A POPULATION TOO SMALL TO READ IS REFUSED BEFORE IT IS WRITTEN.
//
// The stream cannot be un-written, so "that produced nothing usable" has to be
// said in advance rather than discovered in the output.
func TestItRefusesAPopulationNothingCouldBeReadFrom(t *testing.T) {
	pool := testPool(t)
	_, slug := aSchool(t, pool)

	t.Setenv("SCHOOLING_DATABASE_URL", os.Getenv("SCHOOLING_TEST_DATABASE_URL"))
	t.Setenv("SCHOOLING_PLATFORM_DOMAIN", "example.tld")
	t.Setenv("SCHOOLING_ENV", "development")

	var out bytes.Buffer
	err := run([]string{"--school", slug, "--by", "the seeder's test", "--people", "50"}, &out)
	if err == nil {
		t.Fatal("50 people were accepted, and item analysis needs 30 answers per question")
	}
	if !strings.Contains(err.Error(), "at least") {
		t.Errorf("the refusal does not say how many people would do: %v", err)
	}

	var events int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM events WHERE school_slug = $1`, slug).Scan(&events); err != nil {
		t.Fatalf("counting what it wrote: %v", err)
	}
	if events != 0 {
		t.Errorf("%d events were written by a run that refused, and the stream is "+
			"append-only", events)
	}
}

// AND IT IS AN ADMINISTRATIVE WRITE, SO IT ASKS WHO IS DOING IT.
func TestItRefusesWithoutAnActor(t *testing.T) {
	var out bytes.Buffer
	err := run([]string{"--school", "anything", "--people", "600"}, &out)
	if err == nil || !strings.Contains(err.Error(), "--by") {
		t.Errorf("a run with no actor answered %v, and every administrative write "+
			"records one", err)
	}
}

/*
THE COUNTRIES IT WRITES ARE THE ONES EVERYTHING ELSE READS.

	This wrote `BR` for its first three weeks while `platform/geo` wrote `br`,
	the console's map was keyed by `br`, and its `isRegion` refused anything
	that was not two lower-case letters. A seeded Brazil therefore matched no
	outline, showed no flag and got no name — it rendered as a row labelled
	`BR` beside rows labelled `Brazil`, which is this mistake's whole shape:
	nothing fails, and one country is quietly two.

	`analysis` folds the case now, so the rows already written come out right.
	This is the other end of it: what is written from here on is what the rest
	of the platform writes.
*/
func TestTheSeededCountriesAreSpeltTheWayEverythingElseSpellsThem(t *testing.T) {
	r := rand.New(rand.NewSource(1))

	seen := map[string]bool{}
	for i := 0; i < 2000; i++ {
		country, _ := where(r)
		seen[country] = true

		if country != strings.ToLower(country) {
			t.Fatalf("the seeder writes %q, and everything that reads this column "+
				"writes and expects lower case", country)
		}
		if country != event.Unknown && !regexp.MustCompile(`^[a-z]{2}$`).MatchString(country) {
			t.Fatalf("%q is neither an ISO alpha-2 code nor %q", country, event.Unknown)
		}
	}

	// And it produces more than one, or the weighting has collapsed and every
	// seeded report would be about a single country without saying so.
	if len(seen) < 3 {
		t.Errorf("two thousand draws produced only %v", seen)
	}
}
