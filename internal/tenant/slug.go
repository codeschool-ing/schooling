package tenant

import (
	"fmt"
	"regexp"
	"slices"
	"strings"
)

// Reserved are the labels a school may not be called.
//
// EVERY ONE OF THEM IS AN ADDRESS SOMETHING ELSE ALREADY WANTS. `api` and
// `app` are where this platform's own things go; `www` is what a browser
// silently tries; `mail` and `cdn` are where a provider expects to put a
// record; `status` and `docs` are where a person looks when the rest is down.
// A school called `api` does not fail at creation — it fails months later, at
// the moment somebody adds the address the school already took.
//
// `console` and `admin` are both here and only one is used. The console lives
// at `console.<platform domain>`; `admin` was reserved for it before it had a
// name and stays reserved, because taking a label off this list is strictly
// worse than leaving one on it.
//
// It is checked here AND by a constraint in the database, because this list is
// the kind of rule that gets bypassed by a script somebody wrote to fix
// something else. A test proves the database refuses every entry.
var Reserved = []string{
	"admin",
	"api",
	"app",
	"auth",
	"cdn",
	"console",
	"docs",
	"mail",
	"static",
	"status",
	"www",
}

// A host name label: lowercase letters, digits and hyphens, never starting or
// ending with a hyphen, at most 63 characters. The same expression is a CHECK
// constraint on the column, and the reason it is in both places is that an
// address that is not a legal host name cannot exist — so the database refuses
// it, and this exists to say so before the round trip.
var slugShape = regexp.MustCompile(`^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$`)

// ValidateSlug answers why a slug may not be used, or nil.
func ValidateSlug(slug string) error {
	switch {
	case slug == "":
		return fmt.Errorf("a school needs a slug: it is the label its address is built from")
	case slug != strings.ToLower(slug):
		return fmt.Errorf("%q has capitals in it, and host names do not — use %q",
			slug, strings.ToLower(slug))
	case !slugShape.MatchString(slug):
		return fmt.Errorf("%q is not a host name label: lowercase letters, digits and hyphens, "+
			"not starting or ending with a hyphen, at most 63 characters", slug)
	case slices.Contains(Reserved, slug):
		return fmt.Errorf("%q is reserved — it is an address the platform itself needs, and a "+
			"school holding it is discovered on the day something else needs to go there", slug)
	}
	return nil
}
