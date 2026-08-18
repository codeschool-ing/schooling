package event_test

import (
	"context"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/event"
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

// school returns one school to emit against, under a name nothing else uses.
//
// NO TRUNCATE. `go test` runs packages in parallel against one database, so
// clearing a shared table deletes another package's rows mid-run, and a fixed
// slug collides on the unique index. Every assertion below is therefore scoped
// to what this test wrote — which is a better assertion anyway.
func school(t *testing.T, pool *pgxpool.Pool) (uuid.UUID, string) {
	t.Helper()

	slug := "code-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`, slug,
	).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id, slug
}

// THE ONE THAT MATTERS.
//
// Every event carries the plan, the school, the country and the locale as they
// were when it happened. The failure this prevents is not an error — it is a
// report that answers with today's plan for something that happened in March,
// confidently and wrongly, which nobody notices.
func TestAnEventCarriesItsDimensions(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	ctx := context.Background()

	account := uuid.New()
	err := event.NewStore(pool).Emit(ctx, event.Event{
		Name:       "course.finished",
		Dimensions: event.ForSchool(id, slug, "annual", "BR", "pt-br"),
		AccountID:  &account,
		Payload:    map[string]any{"course": "python"},
	})
	if err != nil {
		t.Fatalf("emitting: %v", err)
	}

	// The plan then changes, which is the entire point: the row must not.
	var plan, country, locale, school string
	if err := pool.QueryRow(ctx, `
		SELECT plan, country, locale, school_slug FROM events
		WHERE name = 'course.finished' AND tenant_id = $1
	`, id).Scan(&plan, &country, &locale, &school); err != nil {
		t.Fatalf("reading it back: %v", err)
	}

	if plan != "annual" || country != "BR" || locale != "pt-br" || school != slug {
		t.Errorf("the dimensions did not survive: plan=%q country=%q locale=%q school=%q",
			plan, country, locale, school)
	}
}

// A dimension cannot be left out, and the reason it cannot is the type: there
// are no exported fields, so the only way to build one is a constructor that
// takes every dimension as an argument. This test is what remains to check —
// that a value which is present but empty is refused rather than stored as a
// blank that reads like a value.
func TestADimensionThatIsEmptyIsRefused(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	ctx := context.Background()
	store := event.NewStore(pool)

	for _, c := range []struct {
		what string
		dims event.Dimensions
	}{
		{"no plan", event.ForSchool(id, slug, "", "BR", "pt-br")},
		{"no country", event.ForSchool(id, slug, "annual", "", "pt-br")},
		{"no locale", event.ForSchool(id, slug, "annual", "BR", "")},
		{"no slug beside the id", event.ForSchool(id, "", "annual", "BR", "pt-br")},
	} {
		err := store.Emit(ctx, event.Event{Name: "test", Dimensions: c.dims})
		if err == nil {
			t.Errorf("%s: accepted, and the row would answer a report with a blank", c.what)
			continue
		}
		if !strings.Contains(err.Error(), "test") {
			t.Errorf("%s: the error does not name the event: %v", c.what, err)
		}
	}

	// And nothing was written by any of them.
	var count int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM events WHERE tenant_id = $1`, id).Scan(&count); err != nil {
		t.Fatalf("counting: %v", err)
	}
	if count != 0 {
		t.Errorf("%d events were written by calls that should all have been refused", count)
	}
}

// A refused dimension reports every problem at once. A caller fixing them one
// per run is the same waste as a misconfigured deploy that teaches one fact per
// restart.
func TestEveryEmptyDimensionIsReportedTogether(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)

	err := event.NewStore(pool).Emit(context.Background(), event.Event{
		Name:       "test",
		Dimensions: event.ForSchool(id, slug, "", "", ""),
	})
	if err == nil {
		t.Fatal("an event with three empty dimensions was accepted")
	}
	for _, want := range []string{"plan", "country", "locale"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("%q is missing from the error, so it takes another run to find: %v", want, err)
		}
	}
}

// A platform event belongs to no school, and says so rather than guessing one.
func TestAPlatformEventNamesNoSchool(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	// A platform event has no school to scope the assertion by, so the name is
	// what makes it this test's row.
	name := "visitor.arrived." + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]

	err := event.NewStore(pool).Emit(ctx, event.Event{
		Name:       name,
		Dimensions: event.ForPlatform(event.PlanNone, event.Unknown, "en"),
	})
	if err != nil {
		t.Fatalf("emitting a platform event: %v", err)
	}

	var tenant *uuid.UUID
	var slug string
	if err := pool.QueryRow(ctx,
		`SELECT tenant_id, school_slug FROM events WHERE name = $1`, name,
	).Scan(&tenant, &slug); err != nil {
		t.Fatalf("reading it back: %v", err)
	}
	if tenant != nil || slug != "" {
		t.Errorf("a platform event claimed a school: tenant=%v slug=%q", tenant, slug)
	}
}

// Append-only is a trigger and not an arrangement. The difference shows up on
// the day somebody corrects data by hand, which is the day it matters.
func TestTheEventStreamRefusesToBeEdited(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	ctx := context.Background()

	if err := event.NewStore(pool).Emit(ctx, event.Event{
		Name:       "course.finished",
		Dimensions: event.ForSchool(id, slug, "annual", "BR", "pt-br"),
	}); err != nil {
		t.Fatalf("emitting: %v", err)
	}

	if _, err := pool.Exec(ctx,
		`UPDATE events SET plan = 'free' WHERE tenant_id = $1`, id); err == nil {
		t.Error("an event was rewritten — history is editable, and every report drawn from " +
			"it is now a claim rather than a record")
	}
	if _, err := pool.Exec(ctx,
		`DELETE FROM events WHERE tenant_id = $1`, id); err == nil {
		t.Error("an event was deleted")
	}

	var count int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM events WHERE tenant_id = $1`, id).Scan(&count); err != nil {
		t.Fatalf("counting: %v", err)
	}
	if count != 1 {
		t.Errorf("%d events survived, want 1", count)
	}
}
