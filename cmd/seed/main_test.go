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

	lives := populate(rand.New(rand.NewSource(7)), rand.New(rand.NewSource(7+1)), s, from, to, 400) //nolint:gosec // repeatable on purpose

	// The order the steps of a journey may appear in. A step is only allowed
	// once whatever comes before it has happened.
	needs := map[string]string{
		"account.created": "visitor.arrived",

		/* CONFIRMING IS NOT ON THE PATH TO ANYTHING, which is why nothing
		   depends on it: `track.opened` needs the account and not the
		   confirmation. What is asserted is only that it never happens before
		   there is an account to confirm. */
		"account.confirmed": "account.created",

		"track.opened":      "account.created",
		"lesson.opened":     "track.opened",
		"section.completed": "lesson.opened",
		"course.completed":  "section.completed",
		"exam.submitted":    "course.completed",

		/* AND WHAT HAPPENS TO A SUBSCRIPTION, which is three more steps that
		   cannot come in any order. An ending before a start is the one that
		   would render perfectly and describe nothing: a refund of something
		   nobody bought, drawn as a churned customer by anything reading it. */
		"subscription.started": "course.completed",
		"subscription.ended":   "subscription.started",
		"subscription.renewed": "subscription.started",
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
	lives := populate(rand.New(rand.NewSource(3)), rand.New(rand.NewSource(3+1)), s, to.AddDate(0, -6, 0), to, 800) //nolint:gosec // repeatable on purpose

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
	if count["exam.submitted"] < analysis.MinimumSample.Fallback {
		t.Errorf("only %d people sat an exam, and item analysis says nothing below %d",
			count["exam.submitted"], analysis.MinimumSample.Fallback)
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

	out := seeded(t, slug, "--people", "1200", "--rand", "11")
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
		s, err := analysis.Summarise(answers, analysis.MinimumSample.Fallback)
		if err != nil {
			t.Fatalf("summarising %s: %v", question, err)
		}
		if s.Attempts < analysis.MinimumSample.Fallback {
			t.Errorf("%s has %d answers and needs %d before anything can be said",
				question, s.Attempts, analysis.MinimumSample.Fallback)
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
	seeded(t, slug, "--people", "1200", "--rand", "5")

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

/*
AND THAT REFUSAL IS ABOUT ITEM ANALYSIS, SO IT ONLY APPLIES WHERE THERE IS AN EXAM.

	Every school this platform has today has no exam questions, because the
	content pipeline has not written one. Asked for fifty seeded people there,
	the first version refused and cited the minimum sample for an analysis that
	cannot run on a school with nothing to analyse — arithmetic that was right,
	for a reason that could not apply.

	That is the harder kind of wrong to notice, because a refusal reads as
	authoritative and this one names a real constant. It needs no database, which
	is why it is here and not beside the run that found it.
*/
func TestASchoolWithNoExamIsNotRefusedForItsSampleSize(t *testing.T) {
	if err := enough(1, ""); err != nil {
		t.Errorf("one person was refused on a school with no exam question to plant a "+
			"key on: %v — the funnel, the cohorts, presence and the map all want a "+
			"population and none of them wants an exam", err)
	}

	// AND WHERE THERE IS AN EXAM IT STILL REFUSES, which is the half that was
	// already right and must stay right: the stream cannot be un-written.
	if err := enough(1, "the-planted-question"); err == nil {
		t.Error("one person was accepted for a school with an exam, and item analysis " +
			"says nothing below thirty answers to a question")
	}
	if err := enough(enoughPeople, "the-planted-question"); err != nil {
		t.Errorf("%d people is the number this command computes as enough and it was "+
			"refused: %v", enoughPeople, err)
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
	r := rand.New(rand.NewSource(1)) //nolint:gosec // repeatable on purpose

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

/*
THE FOURTH BEHAVIOUR EXISTS, AND IT IS THE ONE THIS SEEDER COULD NOT PRODUCE.

	`docs/ROADMAP.md` keeps a box open for a seeder that generates history —
	abandonment, returns, duplicate signups and refunds — and it stayed open on
	the refund alone, because nothing emitted a subscription into the stream.
	This asserts the shape rather than the count: a fixture that produced two
	refunds in a thousand people would satisfy a `> 0` and would still be a
	fixture where a screen that draws an ending wrongly looks fine.
*/
func TestTheSeededPastContainsRefunds(t *testing.T) {
	to := time.Now().UTC()
	from := to.AddDate(0, -6, 0)
	s := shape{
		id: uuid.New(), slug: "seeded", track: "tr-one", course: "co-one", lesson: "le-one",
		sections:  []string{"se-1", "se-2", "se-3"},
		questions: []question{{id: "ex-1", version: 1, kind: "quiz"}},
		broken:    "ex-1",
	}

	lives := populate(rand.New(rand.NewSource(11)), rand.New(rand.NewSource(11+1)), s, from, to, 800) //nolint:gosec // repeatable on purpose

	started, ended := 0, 0
	for _, l := range lives {
		for _, m := range l.moments {
			switch m.name {
			case "subscription.started":
				started++
			case "subscription.ended":
				ended++
				if got := m.payload["reason"]; got != "refunded" {
					t.Errorf("an ending says its reason is %v; the only ending this "+
						"seeder can honestly write is a refund, because a term running "+
						"out is a job's finding and not a person's act", got)
				}
			}
		}
	}

	if started == 0 {
		t.Fatal("nobody in eight hundred people subscribed, so the funnel's last step " +
			"has nothing to draw and this fixture demonstrates the screen it was made for " +
			"exactly as well as an empty database would")
	}
	if ended == 0 {
		t.Error("nobody was refunded — the one behaviour of the four this seeder was " +
			"written unable to produce, and the reason its box stays open")
	}
	if ended >= started {
		t.Errorf("%d of %d subscriptions ended; a population where everybody who paid "+
			"asked for it back is not a shape any screen should be built against",
			ended, started)
	}
}

/*
A SUBSCRIPTION IS WRITTEN AGAINST NO SCHOOL, AND EVERYTHING ELSE IS.

	One subscription covers every school (N-02), so these are the only moments
	this seeder marks `platform` — and the funnel reads them with a query of its
	own, `tenant_id IS NULL`. Written against a school they would be accepted by
	the database and invisible to the report: the last step would come back
	empty while every other step of the same run looked right, which reads as a
	broken screen rather than as a bad fixture.
*/
func TestOnlyTheSubscriptionMomentsBelongToNoSchool(t *testing.T) {
	to := time.Now().UTC()
	from := to.AddDate(0, -6, 0)
	s := shape{
		id: uuid.New(), slug: "seeded", track: "tr-one", course: "co-one", lesson: "le-one",
		sections:  []string{"se-1", "se-2"},
		questions: []question{{id: "ex-1", version: 1, kind: "quiz"}},
		broken:    "ex-1",
	}

	lives := populate(rand.New(rand.NewSource(13)), rand.New(rand.NewSource(13+1)), s, from, to, 400) //nolint:gosec // repeatable on purpose

	for i, l := range lives {
		for _, m := range l.moments {
			subscription := strings.HasPrefix(m.name, "subscription.")
			if subscription != m.platform {
				t.Fatalf("person %d has %q with platform=%v — a subscription belongs to "+
					"no school and everything else belongs to one, and the dimension is "+
					"what a report filters on", i, m.name, m.platform)
			}

			/* AND IT CARRIES NO BROWSER. A subscription is bought signed in;
			   which browser it was bought from is not a fact about it, and the
			   funnel folds it onto the person through the account anyway. */
			if subscription && m.visitor >= 0 {
				t.Errorf("person %d has %q carrying a visitor", i, m.name)
			}
			if subscription && m.account < 0 {
				t.Errorf("person %d has %q carrying no account, so there is nobody "+
					"for it to be counted for", i, m.name)
			}
		}
	}
}

/*
AND THE PLAN GOES BACK TO `none` AFTER A REFUND.

	Every event carries the plan as it was at the moment it happened, which is
	the whole reason `Dimensions` cannot be built by naming the fields you
	remembered. A refund that left the person on `full` would put a stream in
	the database describing somebody who bought once and never stopped — and
	`plan` is exactly the dimension a retention report reads, so it would answer
	confidently and wrongly, which is the failure `internal/event`'s own header
	opens with.
*/
func TestAfterARefundTheLaterEventsSayTheyAreNotPaying(t *testing.T) {
	to := time.Now().UTC()
	from := to.AddDate(0, -18, 0) // long enough that a story continues past a refund
	s := shape{
		id: uuid.New(), slug: "seeded", track: "tr-one", course: "co-one", lesson: "le-one",
		sections:  []string{"se-1", "se-2"},
		questions: []question{{id: "ex-1", version: 1, kind: "quiz"}},
		broken:    "ex-1",
	}

	lives := populate(rand.New(rand.NewSource(17)), rand.New(rand.NewSource(17+1)), s, from, to, 800) //nolint:gosec // repeatable on purpose

	checked := 0
	for i, l := range lives {
		refunded := false
		for _, m := range l.moments {
			if refunded && m.plan != "none" {
				t.Errorf("person %d has %q on plan %q after a refund; the stream would "+
					"describe somebody who bought once and never stopped",
					i, m.name, m.plan)
			}
			if m.name == "subscription.ended" {
				refunded = true
				checked++
			}
		}
	}
	if checked == 0 {
		t.Skip("this seed produced no refunds, so there was nothing to check")
	}
}

/*
THE PLANTED KEY IS FOUND ON EVERY SEED, AND NOT ON MOST OF THEM.

	# WHAT THIS IS GUARDING

	`TestTheBrokenKeyIsFound` runs the command once, on one seed, against a
	database. It is the end-to-end check and it cannot be the reliability check:
	one seed passing says nothing about the next one, and for a long time the
	next one was a coin toss. Measured over forty seeds at the population the
	command used to accept, the analysis called the planted question `inverted`
	NINE times — and the command errors out when it does not, so three runs in
	four failed on a fixture built exactly as designed.

	Nothing caught it because everything that ran, ran on a seed that worked.

	# WHY IT CAN BE A REAL TEST RATHER THAN A NOTE IN A COMMENT

	The model is a pure function of a seed — that is `population.go`'s first
	claim — so twenty-five populations can be generated and marked in-process,
	with no Postgres and no command. The whole thing costs less than the single
	database run it protects.

	# WHAT IT WILL CATCH

	Anything that weakens the demonstration without breaking it outright: a
	gentler slope on the planted key, a smaller `readableMultiple`, a change to
	the drop-off rates that thins the exam population, or a threshold moving in
	`analysis`. Each of those leaves every existing test passing on its own
	lucky seed.
*/
func TestThePlantedKeyIsFoundOnEverySeed(t *testing.T) {
	to := time.Now().UTC()
	from := to.AddDate(0, -6, 0)

	const seeds = 25
	var missed []string

	for seed := int64(1); seed <= seeds; seed++ {
		s := shape{
			id: uuid.New(), slug: "seeded", track: "tr-one", course: "co-one", lesson: "le-one",
			sections: []string{"se-1", "se-2", "se-3"},
			broken:   "ex-1",
		}
		for i := 1; i <= 6; i++ {
			id := fmt.Sprintf("ex-%d", i)
			s.questions = append(s.questions,
				question{id: id, version: 1, kind: "quiz", ease: easeOf(id)})
		}

		/* AT `enoughPeople` AND NOT AT WHATEVER IS COMFORTABLE. That constant is
		   what the command refuses below, so it is the promise being made: run
		   this many and the demonstration works. A test at a larger population
		   would be checking a promise nobody made. */
		lives := populate(
			rand.New(rand.NewSource(seed)),   //nolint:gosec // repeatable on purpose
			rand.New(rand.NewSource(seed+1)), //nolint:gosec // the same
			s, from, to, enoughPeople)

		answers := map[string][]analysis.Answer{}
		for _, l := range lives {
			for _, m := range l.moments {
				if m.name != event.ItemAnswered {
					continue
				}
				id, _ := m.payload["exercise"].(string)
				correct, _ := m.payload["correct"].(bool)
				attempt, _ := m.payload["attempt"].(string)
				score, _ := m.payload["score"].(int)
				of, _ := m.payload["of"].(int)
				answers[id] = append(answers[id], analysis.Answer{
					ExerciseID: id, Version: 1, Type: "quiz", AttemptID: attempt,
					Correct: correct, Score: score, Of: of, AnsweredAt: m.at,
				})
			}
		}

		got, err := analysis.Summarise(answers[s.broken], analysis.MinimumSample.Fallback)
		if err != nil {
			t.Fatalf("summarising seed %d: %v", seed, err)
		}
		if got.Verdict != analysis.VerdictInverted {
			missed = append(missed, fmt.Sprintf("seed %d: %s (%d answers, discrimination %+.2f)",
				seed, got.Verdict, got.Attempts, got.Discrimination))
		}
	}

	if len(missed) > 0 {
		t.Errorf("the planted key was missed on %d of %d seeds, and the command errors "+
			"out when that happens — so this is the share of runs that fail for somebody "+
			"who did nothing wrong:\n  %s",
			len(missed), seeds, strings.Join(missed, "\n  "))
	}
}

/*
AND THE GOOD QUESTIONS ARE NOT CONDEMNED, on every seed as well.

	The other half of a demonstration worth believing. A fixture that called
	every question broken would find the planted one too, and would prove
	nothing at all — so the same twenty-five populations are asked about the
	five questions nothing was done to.

	IT ALLOWS `weak` AND REFUSES `inverted`. Weak is a note about a question that
	barely separates students, which a small sample will produce honestly;
	inverted is the accusation, and it is the one that would be false.
*/
func TestNoGoodQuestionIsCondemnedOnAnySeed(t *testing.T) {
	to := time.Now().UTC()
	from := to.AddDate(0, -6, 0)

	const seeds = 25
	var wrong []string

	for seed := int64(1); seed <= seeds; seed++ {
		s := shape{
			id: uuid.New(), slug: "seeded", track: "tr-one", course: "co-one", lesson: "le-one",
			sections: []string{"se-1", "se-2", "se-3"},
			broken:   "ex-1",
		}
		for i := 1; i <= 6; i++ {
			id := fmt.Sprintf("ex-%d", i)
			s.questions = append(s.questions,
				question{id: id, version: 1, kind: "quiz", ease: easeOf(id)})
		}
		lives := populate(
			rand.New(rand.NewSource(seed)),   //nolint:gosec // repeatable on purpose
			rand.New(rand.NewSource(seed+1)), //nolint:gosec // the same
			s, from, to, enoughPeople)

		answers := map[string][]analysis.Answer{}
		for _, l := range lives {
			for _, m := range l.moments {
				if m.name != event.ItemAnswered {
					continue
				}
				id, _ := m.payload["exercise"].(string)
				correct, _ := m.payload["correct"].(bool)
				attempt, _ := m.payload["attempt"].(string)
				score, _ := m.payload["score"].(int)
				of, _ := m.payload["of"].(int)
				answers[id] = append(answers[id], analysis.Answer{
					ExerciseID: id, Version: 1, Type: "quiz", AttemptID: attempt,
					Correct: correct, Score: score, Of: of, AnsweredAt: m.at,
				})
			}
		}

		for id, got := range answers {
			if id == s.broken {
				continue
			}
			sum, err := analysis.Summarise(got, analysis.MinimumSample.Fallback)
			if err != nil {
				t.Fatalf("summarising %s on seed %d: %v", id, seed, err)
			}
			if sum.Verdict == analysis.VerdictInverted {
				wrong = append(wrong, fmt.Sprintf("seed %d: %s came back inverted "+
					"(discrimination %+.2f)", seed, id, sum.Discrimination))
			}
		}
	}

	if len(wrong) > 0 {
		t.Errorf("%d good questions were condemned across %d seeds — a seeder that "+
			"condemns questions it did not break is one nobody can believe about the "+
			"one it did:\n  %s", len(wrong), seeds, strings.Join(wrong, "\n  "))
	}
}
