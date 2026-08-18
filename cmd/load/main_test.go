package main

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

const fixture = "../../internal/catalog/testdata/good"

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

// school seeds a school under a name nothing else is using, and answers the
// directory holding a copy of the fixture renamed to match it.
//
// NO TRUNCATE: packages run in parallel against one database, and this one
// writes to tables every other catalogue test also reads.
func school(t *testing.T, pool *pgxpool.Pool) (id uuid.UUID, dir string) {
	t.Helper()

	slug := "code-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		slug).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}

	dir = filepath.Join(t.TempDir(), slug)
	copyTree(t, fixture, dir)
	patch(t, filepath.Join(dir, "school.json"), func(d map[string]any) { d["id"] = slug })

	return id, dir
}

func load(t *testing.T, pool *pgxpool.Pool, dir string) error {
	t.Helper()
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	return loadSchool(context.Background(), log, pool, dir)
}

func count(t *testing.T, pool *pgxpool.Pool, table string, id uuid.UUID) int {
	t.Helper()
	var n int
	// The table name comes from this file's own callers and never from data.
	if err := pool.QueryRow(context.Background(),
		"SELECT count(*) FROM "+table+" WHERE tenant_id = $1", id).Scan(&n); err != nil {
		t.Fatalf("counting %s: %v", table, err)
	}
	return n
}

func TestLoadingWritesTheWholeCatalogue(t *testing.T) {
	pool := testPool(t)
	id, dir := school(t, pool)

	if err := load(t, pool, dir); err != nil {
		t.Fatalf("loading: %v", err)
	}

	for table, want := range map[string]int{
		"catalog_tracks":        1,
		"catalog_track_forks":   1,
		"catalog_track_courses": 4,
		"catalog_courses":       4,
		"catalog_lessons":       4,
		"catalog_sections":      6,
		"catalog_exercises":     1,
	} {
		if got := count(t, pool, table, id); got != want {
			t.Errorf("%s has %d rows, want %d", table, got, want)
		}
	}

	// The payload survives whole. A loader that decoded the fields it
	// recognised and dropped the rest would write a mirror with no answers in
	// it, and every screen above it would look right.
	var payload []byte
	if err := pool.QueryRow(context.Background(),
		`SELECT payload FROM catalog_exercises WHERE tenant_id = $1`, id).Scan(&payload); err != nil {
		t.Fatalf("reading the payload: %v", err)
	}
	var decoded map[string]any
	if err := json.Unmarshal(payload, &decoded); err != nil {
		t.Fatalf("the payload is not an object: %v", err)
	}
	if decoded["hint"] == nil {
		t.Errorf("the exercise payload lost fields on the way in: %s", payload)
	}
}

// THE ONE THAT MATTERS.
//
// A catalogue that does not pass must not touch the mirror. The gap between
// "CI was green on that commit" and "this is what is being loaded now" is
// exactly where a half-written catalogue reaches students — so this refuses,
// and what was already there keeps serving.
func TestARefusedCatalogueLeavesThePreviousOneServing(t *testing.T) {
	pool := testPool(t)
	id, dir := school(t, pool)

	if err := load(t, pool, dir); err != nil {
		t.Fatalf("the first load: %v", err)
	}
	before := count(t, pool, "catalog_courses", id)
	if before == 0 {
		t.Fatal("the first load wrote nothing, so this proves nothing")
	}

	// Break it in a way only the validator can see: a section a student would
	// open to find nothing.
	patch(t, filepath.Join(dir, "courses/web-fundamentals/lessons/client-and-server/lesson.json"),
		func(d map[string]any) {
			sections, _ := d["sections"].([]any)
			d["sections"] = append(sections, map[string]any{"id": "packets", "kind": "reading"})
		})

	err := load(t, pool, dir)
	if err == nil {
		t.Fatal("a catalogue with a reading section that has no prose was loaded")
	}
	if !strings.Contains(err.Error(), "nothing was written") {
		t.Errorf("the refusal does not say that nothing was written: %v", err)
	}

	if after := count(t, pool, "catalog_courses", id); after != before {
		t.Errorf("the mirror changed from %d courses to %d during a refused load — a student "+
			"is now looking at a catalogue that is neither the old one nor the new one",
			before, after)
	}
}

// THE SECOND ONE THAT MATTERS.
//
// What the files no longer carry has to leave the mirror. A load that only
// inserted would accumulate every course ever written, and a course deleted
// from `content/` would keep serving forever — visible to students, invisible
// in the repository.
func TestWhatTheFilesNoLongerCarryIsPruned(t *testing.T) {
	pool := testPool(t)
	id, dir := school(t, pool)

	if err := load(t, pool, dir); err != nil {
		t.Fatalf("the first load: %v", err)
	}
	if got := count(t, pool, "catalog_courses", id); got != 4 {
		t.Fatalf("the first load wrote %d courses, want 4", got)
	}

	// Take the fork out of the track and delete both of its courses.
	patch(t, filepath.Join(dir, "tracks/frontend.json"), func(d map[string]any) {
		d["courses"] = []any{"web-fundamentals", "html-css"}
	})
	for _, gone := range []string{"react-ts", "angular"} {
		if err := os.RemoveAll(filepath.Join(dir, "courses", gone)); err != nil {
			t.Fatalf("removing %s: %v", gone, err)
		}
	}

	if err := load(t, pool, dir); err != nil {
		t.Fatalf("the second load: %v", err)
	}

	if got := count(t, pool, "catalog_courses", id); got != 2 {
		t.Errorf("%d courses after two were deleted from the files, want 2 — a course removed "+
			"from content/ would keep serving forever", got)
	}
	if got := count(t, pool, "catalog_track_forks", id); got != 0 {
		t.Errorf("%d forks left after the fork was removed from the track", got)
	}
	if got := count(t, pool, "catalog_track_courses", id); got != 2 {
		t.Errorf("%d courses in the track, want 2", got)
	}
}

// A directory in content/ does not create a school. A typo in one would
// otherwise become a school that answers at no address and shows up in every
// count.
func TestADirectoryDoesNotCreateASchool(t *testing.T) {
	pool := testPool(t)

	dir := filepath.Join(t.TempDir(), "nobody")
	copyTree(t, fixture, dir)
	patch(t, filepath.Join(dir, "school.json"), func(d map[string]any) {
		d["id"] = "nobody-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:8]
	})

	err := load(t, pool, dir)
	if err == nil {
		t.Fatal("a catalogue for a school nobody created was loaded")
	}
	if !strings.Contains(err.Error(), "does not create one") {
		t.Errorf("the refusal does not explain why: %v", err)
	}
}

/* ---------- fixtures ---------- */

func patch(t *testing.T, path string, change func(map[string]any)) {
	t.Helper()

	body, err := os.ReadFile(path) //nolint:gosec // a path this test built under t.TempDir()
	if err != nil {
		t.Fatalf("reading %s: %v", path, err)
	}
	var d map[string]any
	if err := json.Unmarshal(body, &d); err != nil {
		t.Fatalf("decoding %s: %v", path, err)
	}
	change(d)

	out, err := json.MarshalIndent(d, "", "  ")
	if err != nil {
		t.Fatalf("encoding %s: %v", path, err)
	}
	if err := os.WriteFile(path, out, 0o600); err != nil {
		t.Fatalf("writing %s: %v", path, err)
	}
}

func copyTree(t *testing.T, from, to string) {
	t.Helper()

	err := filepath.Walk(from, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(from, path)
		if err != nil {
			return err
		}
		target := filepath.Join(to, rel)
		if info.IsDir() {
			return os.MkdirAll(target, 0o750)
		}
		body, err := os.ReadFile(path) //nolint:gosec // a path this walk produced from the fixture
		if err != nil {
			return err
		}
		return os.WriteFile(target, body, 0o600)
	})
	if err != nil {
		t.Fatalf("copying the fixture: %v", err)
	}
}
