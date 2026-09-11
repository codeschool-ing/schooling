package rating_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/rating"
)

/* What a student thinks of a course, against a real Postgres.

   THE RULES THAT ONLY EXIST IN THE SCHEMA ARE CHECKED HERE and nowhere else:
   one rating per person per subject, the platform naming nothing, and the
   bounds on every one of the five numbers. Each is a constraint or a unique
   index, and none of them can be exercised against a fake. */

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

// The catalogue this store is checked against: one course and one track, and it
// refuses everything else — which is the shape the real closure has, and means
// "no such subject" is tested rather than assumed.
const (
	course = "web-fundamentals"
	track  = "front-end"
)

func aStore(t *testing.T, pool *pgxpool.Pool) *rating.Store {
	t.Helper()
	return rating.NewStore(pool,
		func(_ context.Context, _ uuid.UUID, kind, id string) (bool, error) {
			switch kind {
			case rating.KindCourse:
				return id == course, nil
			case rating.KindTrack:
				return id == track, nil
			}
			return false, errors.New("the platform should never reach the catalogue")
		},
	)
}

func aSchool(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	slug := "rat-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:10]
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		slug).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

func aStudent(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	email := strings.ReplaceAll(uuid.NewString(), "-", "")[:16] + "@example.tld"
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO accounts (email, name) VALUES ($1, 'Ada') RETURNING id`,
		email).Scan(&id); err != nil {
		t.Fatalf("seeding a student: %v", err)
	}
	return id
}

func stars(school, student uuid.UUID, n int) rating.Given {
	return rating.Given{
		School: school, Account: student,
		Kind: rating.KindCourse, SubjectID: course,
		Stars: n, Version: "v1.0.0",
	}
}

func TestOneTapIsAWholeRating(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	one, err := store.Give(ctx, stars(school, student, 4))
	if err != nil {
		t.Fatalf("giving four stars: %v", err)
	}
	if one.Stars != 4 {
		t.Errorf("four stars came back as %d", one.Stars)
	}
	/* THE CONTRACT WITH SOMEBODY WHO WANTS TO BE LEFT ALONE. A row that needed
	   the pairs would be an interface promising one gesture and a store
	   demanding five. */
	if len(one.Aspects) != 0 {
		t.Errorf("a rating given without the pairs came back carrying %v", one.Aspects)
	}
	if one.ChangedAt != nil {
		t.Error("a rating given once says it was changed")
	}
}

func TestTheSecondRatingIsTheSameRating(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	if _, err := store.Give(ctx, stars(school, student, 2)); err != nil {
		t.Fatalf("giving two stars: %v", err)
	}

	/* A PERSON WHO COMES BACK AFTER A REWRITE IS NOT A SECOND PERSON. This is
	   the decision `report` makes in the opposite direction, and the reason is
	   that a report is an event and a rating is a state. */
	changed := stars(school, student, 5)
	changed.Version = "v1.1.0"
	after, err := store.Give(ctx, changed)
	if err != nil {
		t.Fatalf("changing a mind: %v", err)
	}
	if after.Stars != 5 {
		t.Errorf("the changed rating says %d stars", after.Stars)
	}
	if after.ChangedAt == nil {
		t.Error("a rating that was changed does not say so")
	}

	mine, err := store.Mine(ctx, school, student)
	if err != nil {
		t.Fatalf("reading a student's own: %v", err)
	}
	if len(mine) != 1 {
		t.Fatalf("one person rating one course twice left %d rows", len(mine))
	}

	/* AND THE OPINION MOVED TO THE RELEASE IT WAS FORMED AGAINST, which is the
	   whole reason the column is there: the old stars were about the old
	   material and the new stars are not. */
	if mine[0].Version != "v1.1.0" {
		t.Errorf("the changed rating is still filed under %q", mine[0].Version)
	}
}

func TestAnsweringTheShortFormAgainClearsThePairs(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	deep := stars(school, student, 2)
	deep.Aspects = map[string]int{
		rating.AspectCompleteness: 1,
		rating.AspectPadding:      2,
	}
	if _, err := store.Give(ctx, deep); err != nil {
		t.Fatalf("giving a rating with pairs: %v", err)
	}

	/* THE HONEST READING of somebody answering the short form the second time
	   is that what they are telling us is the stars. Keeping the old pairs would
	   attach last month's reasons to this month's opinion. */
	after, err := store.Give(ctx, stars(school, student, 4))
	if err != nil {
		t.Fatalf("giving stars alone the second time: %v", err)
	}
	if len(after.Aspects) != 0 {
		t.Errorf("the pairs survived a rating that did not carry them: %v", after.Aspects)
	}
}

func TestTheScaleAndTheListsAreHeld(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	tooMany := stars(school, student, 6)
	if _, err := store.Give(ctx, tooMany); !errors.Is(err, rating.ErrRefused) {
		t.Errorf("six stars on a five-star scale answered %v", err)
	}

	none := stars(school, student, 0)
	if _, err := store.Give(ctx, none); !errors.Is(err, rating.ErrRefused) {
		t.Errorf("zero stars answered %v — a rating exists because somebody tapped", err)
	}

	/* AN ASPECT THIS DOES NOT KNOW IS REFUSED AND NOT DROPPED. Ignoring it
	   silently would let a screen offer a fifth question for a release and a
	   half before anybody noticed nothing was being recorded. */
	invented := stars(school, student, 3)
	invented.Aspects = map[string]int{"vibes": 5}
	if _, err := store.Give(ctx, invented); !errors.Is(err, rating.ErrRefused) {
		t.Errorf("an aspect nobody declared answered %v", err)
	}

	offScale := stars(school, student, 3)
	offScale.Aspects = map[string]int{rating.AspectDepth: 9}
	if _, err := store.Give(ctx, offScale); !errors.Is(err, rating.ErrRefused) {
		t.Errorf("a pair answered nine on a five-point scale answered %v", err)
	}
}

func TestTheSubjectHasToBeReal(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	ghost := stars(school, student, 5)
	ghost.SubjectID = "a-course-nobody-wrote"
	if _, err := store.Give(ctx, ghost); !errors.Is(err, rating.ErrNoSuchSubject) {
		t.Errorf("rating a course that does not exist answered %v", err)
	}

	nameless := stars(school, student, 5)
	nameless.SubjectID = ""
	if _, err := store.Give(ctx, nameless); !errors.Is(err, rating.ErrRefused) {
		t.Errorf("a course rating naming no course answered %v", err)
	}
}

func TestThePlatformNamesNothing(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	/* THE CATALOGUE IS NEVER ASKED. The fake above returns an error for any
	   other kind, so a store that looked the platform up would fail here — which
	   is the point: there is one platform and it is in no catalogue. */
	one, err := store.Give(ctx, rating.Given{
		School: school, Account: student,
		Kind: rating.KindPlatform, Stars: 4, Version: "v1.0.0",
	})
	if err != nil {
		t.Fatalf("rating the platform: %v", err)
	}
	if one.SubjectID != "" {
		t.Errorf("the platform came back named %q", one.SubjectID)
	}

	named := rating.Given{
		School: school, Account: student,
		Kind: rating.KindPlatform, SubjectID: course, Stars: 4,
	}
	if _, err := store.Give(ctx, named); !errors.Is(err, rating.ErrRefused) {
		t.Errorf("a platform rating carrying a course id answered %v", err)
	}
}

func TestACourseAndATrackAreDifferentOpinions(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	if _, err := store.Give(ctx, stars(school, student, 5)); err != nil {
		t.Fatalf("rating the course: %v", err)
	}
	/* A TRACK IS NOT THE MEAN OF ITS COURSES. Four good courses in an order
	   that teaches nothing is a bad track, and the unique index is per kind
	   precisely so both can be said. */
	if _, err := store.Give(ctx, rating.Given{
		School: school, Account: student,
		Kind: rating.KindTrack, SubjectID: track, Stars: 2, Version: "v1.0.0",
	}); err != nil {
		t.Fatalf("rating the track: %v", err)
	}

	mine, err := store.Mine(ctx, school, student)
	if err != nil {
		t.Fatalf("reading a student's own: %v", err)
	}
	if len(mine) != 2 {
		t.Fatalf("a course and a track rating left %d rows", len(mine))
	}
}

func TestTheSummaryIsTheSpreadAndNotTheMean(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school := aSchool(t, pool)

	/* FOUR PEOPLE, TWO AT EACH END. The mean is 3 and so is the mean of four
	   people who all said 3 — and they are opposite problems. A console reading
	   the mean would draw them as the same course, which is the one thing this
	   summary exists to prevent. */
	for _, n := range []int{1, 1, 5, 5} {
		if _, err := store.Give(ctx, stars(school, aStudent(t, pool), n)); err != nil {
			t.Fatalf("giving %d stars: %v", n, err)
		}
	}

	over, err := store.Over(ctx, school, rating.KindCourse)
	if err != nil {
		t.Fatalf("reading the summary: %v", err)
	}
	if len(over) != 1 {
		t.Fatalf("one course at one release came back as %d rows", len(over))
	}
	one := over[0]
	if one.Stars.Count != 4 {
		t.Errorf("four ratings counted as %d", one.Stars.Count)
	}
	if one.Stars.Mean != 3 {
		t.Errorf("two ones and two fives have a mean of %v", one.Stars.Mean)
	}
	if one.Stars.At[1] != 2 || one.Stars.At[5] != 2 || one.Stars.At[3] != 0 {
		t.Errorf("the spread of two ones and two fives is %v — nobody said three", one.Stars.At)
	}
}

func TestTheSummaryIsPerRelease(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school := aSchool(t, pool)

	before := stars(school, aStudent(t, pool), 1)
	before.Version = "v1.0.0"
	if _, err := store.Give(ctx, before); err != nil {
		t.Fatalf("the rating before the rewrite: %v", err)
	}

	after := stars(school, aStudent(t, pool), 5)
	after.Version = "v1.1.0"
	if _, err := store.Give(ctx, after); err != nil {
		t.Fatalf("the rating after the rewrite: %v", err)
	}

	/* THE WHOLE REASON THE COLUMN IS THERE. A course rewritten because it
	   scored badly has to be comparable to itself, and one lifetime average
	   would report a 3 that says the rewrite half-worked. */
	over, err := store.Over(ctx, school, rating.KindCourse)
	if err != nil {
		t.Fatalf("reading the summary: %v", err)
	}
	if len(over) != 2 {
		t.Fatalf("one course at two releases came back as %d rows: %+v", len(over), over)
	}
	by := map[string]float64{}
	for _, one := range over {
		by[one.Version] = one.Stars.Mean
	}
	if by["v1.0.0"] != 1 || by["v1.1.0"] != 5 {
		t.Errorf("the two releases read %v, and they are one and five", by)
	}
}

func TestASummaryOfNothingIsNotAnError(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)

	over, err := store.Over(context.Background(), aSchool(t, pool), rating.KindTrack)
	if err != nil {
		t.Fatalf("reading a summary with nothing in it: %v", err)
	}
	if len(over) != 0 {
		t.Errorf("a school nobody has rated came back with %d rows", len(over))
	}
}

func TestTheThresholdIsDeclaredWithinTheScale(t *testing.T) {
	/* THE PARAMETER DECIDES WHETHER ANYBODY IS ASKED THE PAIRS, and one whose
	   bounds fell outside the scale could be set to a value no rating can ever
	   be at or below — an interface that silently stops asking. */
	if rating.AskDeeper.Least != rating.Lowest || rating.AskDeeper.Most != rating.Highest {
		t.Errorf("the threshold is bounded %d..%d and the scale is %d..%d",
			rating.AskDeeper.Least, rating.AskDeeper.Most, rating.Lowest, rating.Highest)
	}
	if rating.AskDeeper.Fallback < rating.Lowest || rating.AskDeeper.Fallback > rating.Highest {
		t.Errorf("the threshold falls back to %d, outside the scale", rating.AskDeeper.Fallback)
	}
}
