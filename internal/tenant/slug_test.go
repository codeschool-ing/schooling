package tenant_test

import (
	"context"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/tenant"
)

func TestASlugThatIsNotAHostLabelIsRefused(t *testing.T) {
	for _, c := range []struct{ slug, why string }{
		{"", "nothing"},
		{"Code", "capitals, which host names do not have"},
		{"-code", "a leading hyphen"},
		{"code-", "a trailing hyphen"},
		{"code.school", "a dot, which would be another label"},
		{"code school", "a space"},
		{"código", "a letter that is not in the allowed set"},
		{strings.Repeat("a", 64), "longer than a label may be"},
	} {
		if err := tenant.ValidateSlug(c.slug); err == nil {
			t.Errorf("%q was accepted (%s), and it cannot become an address", c.slug, c.why)
		}
	}

	for _, slug := range []string{"code", "math", "music-theory", "a", strings.Repeat("a", 63)} {
		if err := tenant.ValidateSlug(slug); err != nil {
			t.Errorf("%q should be a usable slug: %v", slug, err)
		}
	}
}

// THE ONE THAT MATTERS, and it is about the day this is discovered rather than
// about the insert.
//
// A school called `api` works perfectly until the platform needs
// `api.example.tld` for itself — and the fix at that point is renaming a school
// that students have bookmarked. Refusing it at creation costs nothing;
// refusing it later is not available.
func TestAReservedLabelIsRefusedByGoAndByTheDatabase(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	if len(tenant.Reserved) == 0 {
		t.Fatal("the reserved list is empty, so this test proves nothing")
	}

	for _, slug := range tenant.Reserved {
		if err := tenant.ValidateSlug(slug); err == nil {
			t.Errorf("%q is in the reserved list and ValidateSlug accepted it", slug)
		}

		// AND THE DATABASE, because the Go list holds only for the paths that
		// call it — and a seed script, a fixture, or somebody unblocking
		// themselves at nine on a Friday is not one of those paths.
		_, err := pool.Exec(ctx,
			`INSERT INTO tenants (slug, name) VALUES ($1, 'Should not exist')`, slug)
		if err == nil {
			t.Errorf("the database accepted a school called %q — the constraint and the Go "+
				"list disagree, and the constraint is the one that cannot be bypassed", slug)

			// Do not leave it behind for the other tests to trip over.
			_, _ = pool.Exec(ctx, `DELETE FROM tenants WHERE slug = $1`, slug)
		}
	}
}

// A school whose slug is fine is still created, which is the half that a
// constraint written slightly too broadly would break silently.
func TestAnOrdinarySchoolIsStillAllowed(t *testing.T) {
	pool := testPool(t)
	slug := "music-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]

	if err := tenant.ValidateSlug(slug); err != nil {
		t.Fatalf("%q was refused by ValidateSlug: %v", slug, err)
	}
	if _, err := pool.Exec(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Music theory')`, slug); err != nil {
		t.Errorf("the database refused an ordinary school called %q: %v", slug, err)
	}
}
