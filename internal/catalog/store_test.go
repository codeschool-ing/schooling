package catalog_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/catalog"
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

// loaded seeds a school and fills its mirror by running the real load job.
//
// BY RUNNING cmd/load AND NOT BY INSERTING ROWS. What is under test is what a
// student is served, and the shape of those rows is the load job's decision —
// a test that wrote them itself would agree with its own idea of the mirror
// rather than with the one that exists. It also keeps the "only the load job
// writes the catalogue" rule true of this file.
func loaded(t *testing.T, pool *pgxpool.Pool, changes ...func(dir string)) uuid.UUID {
	t.Helper()

	slug := "code-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		slug).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}

	root := t.TempDir()
	dir := filepath.Join(root, slug)
	copyTree(t, "testdata/good", dir)
	patchJSON("school.json", func(d map[string]any) { d["id"] = slug })(dir)
	for _, change := range changes {
		change(dir)
	}

	// The program is a literal and the only variable is a directory this test
	// just created; gosec sees a variable in an argument and cannot tell.
	cmd := exec.Command("go", "run", "../../cmd/load", root) //nolint:gosec
	cmd.Env = append(os.Environ(),
		"SCHOOLING_DATABASE_URL="+os.Getenv("SCHOOLING_TEST_DATABASE_URL"),
		"SCHOOLING_PLATFORM_DOMAIN=example.tld",
		"SCHOOLING_ENV=development",
	)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("loading the fixture: %v\n%s", err, out)
	}
	return id
}

// THE ONE THAT MATTERS.
//
// The paywall errs closed. Something recognised opens a course; anything else
// closes it — an unknown plan, an empty plan, a plan somebody misspells in a
// migration two years from now. A paywall that opens on an unrecognised input
// is a paywall with a list of ways around it that nobody has finished writing.
func TestAnUnrecognisedPlanIsAGuest(t *testing.T) {
	course := &catalog.Course{ID: htmlCSS}

	for _, plan := range []catalog.Plan{
		"", "full ", "FULL", "premium", "annual", "trial", "admin",
	} {
		access := catalog.MayOpen(plan, course, false)
		if access.Allowed {
			t.Errorf("the plan %q opened a paid course — the paywall opens on an input nobody "+
				"wrote a rule for", plan)
		}
		if access.Reason != catalog.ReasonUnknownPlan {
			t.Errorf("the plan %q was refused as %q rather than as unrecognised", plan, access.Reason)
		}
	}

	// And the recognised ones still behave.
	if a := catalog.MayOpen(catalog.PlanFull, course, false); !a.Allowed {
		t.Errorf("a full plan did not open a paid course: %+v", a)
	}
	if a := catalog.MayOpen(catalog.PlanNone, course, false); a.Allowed {
		t.Errorf("no plan opened a paid course: %+v", a)
	}
}

// A draft is invisible to everybody, including somebody who has paid. It is not
// a permission — it is not a product yet.
func TestADraftIsInvisibleEvenToASubscriber(t *testing.T) {
	access := catalog.MayOpen(catalog.PlanFull, &catalog.Course{ID: "x", Draft: true}, true)
	if access.Allowed {
		t.Error("a subscriber opened a draft — half a course seen first is worse than not seen")
	}
	if access.Reason != catalog.ReasonDraft {
		t.Errorf("a draft was refused as %q", access.Reason)
	}
}

// The shop window is open at every door (N-04): the first course of every
// track, computed from the track's order rather than flagged on the course.
func TestTheFirstCourseOfEveryTrackIsFree(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)
	store := catalog.NewStore(pool)

	listing, err := store.Courses(context.Background(), id, catalog.PlanNone, "en")
	if err != nil {
		t.Fatalf("listing: %v", err)
	}
	if len(listing) != 4 {
		t.Fatalf("%d courses, want 4", len(listing))
	}

	for _, c := range listing {
		free := c.ID == webFundamentals // the first step of the only track
		if c.Free != free {
			t.Errorf("%s: free=%v, want %v", c.ID, c.Free, free)
		}
		if c.Locked == free {
			t.Errorf("%s: free=%v and locked=%v, which cannot both be right", c.ID, c.Free, c.Locked)
		}
	}
}

// A draft never appears — not locked, not greyed, absent. The difference
// between "not for you" and "not yet" belongs to the console.
func TestADraftIsNotInTheCatalogueAtAll(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool, patchJSON("courses/html-css/course.json",
		func(d map[string]any) { d["draft"] = true }))
	store := catalog.NewStore(pool)
	ctx := context.Background()

	listing, err := store.Courses(ctx, id, catalog.PlanFull, "en")
	if err != nil {
		t.Fatalf("listing: %v", err)
	}
	for _, c := range listing {
		if c.ID == htmlCSS {
			t.Error("a draft is in the catalogue, even locked — a stranger now knows what is " +
				"being written")
		}
	}

	// And asking for it directly answers exactly as a course that is not there.
	if _, err := store.Course(ctx, id, htmlCSS, "en", catalog.PlanFull); !errors.Is(err, catalog.ErrNotFound) {
		t.Errorf("a draft answered %v, want ErrNotFound", err)
	}
}

// A locked course shows its SHAPE and not one word of its material. The shape
// is what somebody deciding whether to subscribe is looking at.
func TestALockedCourseShowsItsShapeAndNoWords(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)
	store := catalog.NewStore(pool)
	ctx := context.Background()

	course, err := store.Course(ctx, id, htmlCSS, "en", catalog.PlanNone)
	if err != nil {
		t.Fatalf("reading a locked course: %v", err)
	}
	if !course.Locked {
		t.Fatal("html-css is not the first course of a track and was not locked")
	}
	if len(course.Lessons) == 0 {
		t.Error("a locked course shows no lessons at all, so nobody can see what they would buy")
	}
	for _, l := range course.Lessons {
		for _, s := range l.Sections {
			if s.Body != "" {
				t.Errorf("a locked course served the words of %s/%s", l.ID, s.ID)
			}
		}
	}

	// And the lesson route refuses rather than answering an empty body, which
	// would be a paywall that looks like a bug.
	if _, err := store.Lesson(ctx, id, htmlCSS, boxes, "en", catalog.PlanNone); !errors.Is(err, catalog.ErrLocked) {
		t.Errorf("a locked lesson answered %v, want ErrLocked", err)
	}
}

func TestAFreeLessonServesItsWords(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)
	store := catalog.NewStore(pool)

	lesson, err := store.Lesson(context.Background(), id,
		webFundamentals, clientAndServer, "en", catalog.PlanNone)
	if err != nil {
		t.Fatalf("reading a free lesson: %v", err)
	}

	var roles *catalog.SectionView
	for i := range lesson.Sections {
		if lesson.Sections[i].ID == rolesSection {
			roles = &lesson.Sections[i]
		}
	}
	if roles == nil {
		t.Fatal("the lesson has no roles section")
	}
	if roles.Title != "The two roles" {
		t.Errorf("the front-matter title did not arrive: %q", roles.Title)
	}
	if !strings.Contains(roles.Body, "client") {
		t.Errorf("the body did not arrive: %q", roles.Body)
	}
}

// THE SECOND ONE THAT MATTERS.
//
// A section translated in its title but not its body keeps the ENGLISH BODY
// rather than losing the title too (C-11). Falling back per document would make
// a half-translated lesson worse than an untranslated one, which is the shape
// of thing that makes people stop translating.
func TestATranslationFallsBackFieldByField(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool, write(
		"courses/web-fundamentals/lessons/"+clientAndServer+"/roles.pt.md",
		"---\ntitle: As duas funções\nversion: 1\n---\n"))
	store := catalog.NewStore(pool)

	lesson, err := store.Lesson(context.Background(), id,
		webFundamentals, clientAndServer, "pt", catalog.PlanNone)
	if err != nil {
		t.Fatalf("reading: %v", err)
	}

	for _, s := range lesson.Sections {
		if s.ID != rolesSection {
			continue
		}
		if s.Title != "As duas funções" {
			t.Errorf("the Portuguese title was lost: %q", s.Title)
		}
		if !strings.Contains(s.Body, "client") {
			t.Errorf("the English body was lost along with the untranslated one: %q", s.Body)
		}
		return
	}
	t.Fatal("the lesson has no roles section")
}

// The track keeps its order and its forks on the way back out of the rows the
// load job flattened it into.
func TestATrackComesBackWithItsForkIntact(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)

	track, err := catalog.NewStore(pool).Track(context.Background(), id, frontend, "en")
	if err != nil {
		t.Fatalf("reading the track: %v", err)
	}
	if len(track.Steps) != 3 {
		t.Fatalf("%d steps, want 3", len(track.Steps))
	}
	if track.Steps[0].Course != webFundamentals || track.Steps[1].Course != htmlCSS {
		t.Errorf("the plain steps came back wrong: %+v", track.Steps[:2])
	}

	fork := track.Steps[2]
	if fork.Choice != "the framework" {
		t.Errorf("the fork lost its question: %q", fork.Choice)
	}
	if len(fork.Options) != 2 {
		t.Fatalf("%d options, want 2", len(fork.Options))
	}
	if fork.Options[0].Name != "React + TypeScript" || fork.Options[0].Courses[0] != reactTS {
		t.Errorf("the first option came back wrong: %+v", fork.Options[0])
	}
	if fork.Options[1].Name != "Angular" || fork.Options[1].Courses[0] != angular {
		t.Errorf("the second option came back wrong: %+v", fork.Options[1])
	}
}

// THE THIRD ONE THAT MATTERS.
//
// An unreadable catalogue refuses; it does not answer empty. A 200 with no
// courses cannot be told from a school that has none — so a database that is
// down would look like a catalogue that was deleted, on every screen, with
// nothing a student could quote.
func TestAnUnreadableCatalogueRefusesRatherThanAnsweringEmpty(t *testing.T) {
	broken, err := pgxpool.New(context.Background(),
		"postgres://nobody:nobody@127.0.0.1:1/nothing?sslmode=disable&connect_timeout=1")
	if err != nil {
		t.Fatalf("building a deliberately broken pool: %v", err)
	}
	defer broken.Close()

	school := uuid.New()
	handler := catalog.NewHandler(catalog.NewStore(broken),
		func(context.Context) (uuid.UUID, bool) { return school, true },
		func(context.Context) catalog.Plan { return catalog.PlanNone },
		nil)

	mux := http.NewServeMux()
	handler.Routes(mux)

	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/courses", nil))

	if rec.Code == http.StatusOK {
		var body struct {
			Courses []any `json:"courses"`
		}
		_ = json.Unmarshal(rec.Body.Bytes(), &body)
		t.Fatalf("an unreachable database answered 200 with %d courses — every screen now says "+
			"the school is empty", len(body.Courses))
	}
	if rec.Code != http.StatusServiceUnavailable {
		t.Errorf("status %d, want 503", rec.Code)
	}
}

// A locked course over HTTP is 402 and not 403: this is a purchase rather than
// a permission, and the client shows a different screen for each.
func TestALockedLessonAnswers402(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)

	handler := catalog.NewHandler(catalog.NewStore(pool),
		func(context.Context) (uuid.UUID, bool) { return id, true },
		func(context.Context) catalog.Plan { return catalog.PlanNone },
		nil)

	mux := http.NewServeMux()
	handler.Routes(mux)

	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, httptest.NewRequest(http.MethodGet,
		"/api/v1/courses/"+htmlCSS+"/lessons/"+boxes, nil))

	if rec.Code != http.StatusPaymentRequired {
		t.Errorf("a locked lesson answered %d, want 402: %s", rec.Code, rec.Body.String())
	}
}

// HOW MUCH THERE IS, AND ONLY WHAT CAN BE FINISHED.
//
// `sections` is the denominator of every progress bar the interface draws, so
// it counts countable sections and not all of them. The fixture's first course
// is three sections of which one is a video, and a bar that said "2 of 3" for a
// student who had finished everything there is to finish would be wrong in the
// direction that makes somebody go looking for work that does not exist.
func TestACourseSaysHowManyLessonsAndFinishableSectionsItHas(t *testing.T) {
	pool := testPool(t)
	school := loaded(t, pool)

	courses, err := catalog.NewStore(pool).Courses(context.Background(), school, catalog.PlanFull, "en")
	if err != nil {
		t.Fatal(err)
	}

	var found *catalog.Listing
	for i := range courses {
		if courses[i].ID == webFundamentals {
			found = &courses[i]
		}
	}
	if found == nil {
		t.Fatal("the fixture's first course is not in the catalogue")
	}

	if found.Lessons != 1 {
		t.Errorf("a course with one lesson says it has %d", found.Lessons)
	}
	if found.Sections != 2 {
		t.Errorf("three sections of which one is a video counted as %d finishable; want 2",
			found.Sections)
	}
}

// AND THE COUNTS DO NOT MULTIPLY AGAINST THE PREREQUISITES.
//
// Both counts are scalar subqueries rather than two more joins beside
// `catalog_course_requires`. Joined in, a course with two prerequisites and one
// section would report two — the rows multiply, and `count(*)` over the product
// answers neither question. It is invisible in a fixture where every course has
// exactly one prerequisite, which is why this test gives one course two.
func TestTheCountsDoNotMultiplyAgainstThePrerequisites(t *testing.T) {
	pool := testPool(t)
	school := loaded(t, pool, patchJSON("courses/react-ts/course.json", func(d map[string]any) {
		d["requires"] = []any{"html-css", "web-fundamentals"}
	}))

	courses, err := catalog.NewStore(pool).Courses(context.Background(), school, catalog.PlanFull, "en")
	if err != nil {
		t.Fatal(err)
	}

	for _, c := range courses {
		if c.ID != reactTS {
			continue
		}
		if len(c.Requires) != 2 {
			t.Fatalf("the course under test has %d prerequisites, want the two this test set",
				len(c.Requires))
		}
		if c.Lessons != 1 || c.Sections != 1 {
			t.Errorf("one lesson and one section, behind two prerequisites, counted as %d and %d",
				c.Lessons, c.Sections)
		}
		return
	}
	t.Fatal("react-ts is not in the catalogue")
}
