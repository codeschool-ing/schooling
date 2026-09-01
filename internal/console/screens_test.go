package console_test

import (
	"regexp"
	"strings"
	"testing"
)

/*
TestEveryScreensEyebrowIsItsRailGroup.

	# WHAT AN EYEBROW IS FOR

	Every screen in this console opens with a small word above its heading, and
	that word is where the reader is: `Govern`, `Operate`, `Measure`. The rail
	on the left says the same thing about the same screen, and the two are read
	together — the eyebrow answers "what am I looking at" for somebody who
	followed a link and never saw the rail.

	# WHAT WENT WRONG

	Two of the fourteen said `Watch`, a group that does not exist. It had been
	one once; the rail was renamed and the two screens were not, so `presence`
	and `jobs` sat under `Measure` in the rail and announced themselves as
	something else at the top of the page. Nothing failed, nothing looked
	broken, and both words are plausible English for what those screens do —
	which is why it survived a translation into Portuguese, where it became
	`Acompanhar` over `Medir` and read as two different places.

	# WHY A TEST AND NOT JUST THE FIX

	Because the fix is two words and the defect is structural: there is no
	mechanism tying an eyebrow to a group, so the next rename does this again.
	This is the mechanism, and it costs a millisecond — both facts are already
	in the source, one in `sections.js` and one in each screen.

	IT READS THE SOURCE RATHER THAN THE DOM, for the reason `language_test.go`
	does: the alternative is a browser, and a rule this cheap should not need
	one to be enforced.
*/
func TestEveryScreensEyebrowIsItsRailGroup(t *testing.T) {
	sections := read(t, "ui/app/sections.js")

	/* WHICH FILE EACH SCREEN IS IN, from the imports. It cannot be guessed from
	   the section's id — `audit` is drawn by `history.js` — and a test that
	   guessed would silently skip the one screen whose name does not match. */
	files := map[string]string{}
	for _, m := range regexp.MustCompile(
		`import\s+(\w+)[^'"]*from\s+'\./screens/([\w-]+\.js)'`).
		FindAllStringSubmatch(sections, -1) {

		files[m[1]] = m[2]
	}
	if len(files) < 10 {
		t.Fatalf("only %d screen imports were found in sections.js — its shape changed "+
			"and this test is reading nothing", len(files))
	}

	entries := regexp.MustCompile(
		`\{\s*id:\s*'([\w-]+)',\s*name:\s*'[^']*',\s*group:\s*'(\w+)',\s*screen:\s*(\w+)`).
		FindAllStringSubmatch(sections, -1)
	if len(entries) < 10 {
		t.Fatalf("only %d sections were found — sections.js changed shape", len(entries))
	}

	// The view header's eyebrow, which is a `span`. `record.js` has `h3`s with
	// the same class inside its blocks, and those are headings within a screen
	// rather than a statement about where the screen is.
	eyebrow := regexp.MustCompile(`<span class="eyebrow mono">' \+ esc\(txt\('([^']+)'\)\)`)

	seen := 0
	for _, e := range entries {
		id, group, screen := e[1], e[2], e[3]

		file, known := files[screen]
		if !known {
			t.Errorf("section %q is drawn by %q and nothing imports that", id, screen)
			continue
		}

		found := eyebrow.FindStringSubmatch(read(t, "ui/app/screens/"+file))
		if found == nil {
			t.Errorf("%s opens with no eyebrow, so a reader who followed a link into it "+
				"is not told where they are", file)
			continue
		}
		seen++

		if found[1] != group {
			t.Errorf("%s says %q above its heading and the rail files it under %q — "+
				"one screen in two places, and both words are plausible, which is why "+
				"nobody notices", file, found[1], group)
		}
	}

	if seen < 10 {
		t.Fatalf("only %d screens were actually checked", seen)
	}
}

// The groups the rail offers, so a screen cannot announce a fourth that no rail
// entry will ever show. `GROUPS` is the list and the order.
func TestNoScreenClaimsAGroupTheRailDoesNotHave(t *testing.T) {
	sections := read(t, "ui/app/sections.js")

	found := regexp.MustCompile(`export const GROUPS = \[([^\]]*)\]`).
		FindStringSubmatch(sections)
	if found == nil {
		t.Fatal("there is no `export const GROUPS = [...]` in sections.js")
	}
	known := map[string]bool{}
	for _, m := range regexp.MustCompile(`'(\w+)'`).FindAllStringSubmatch(found[1], -1) {
		known[m[1]] = true
	}
	if len(known) == 0 {
		t.Fatal("GROUPS is empty")
	}

	for _, m := range regexp.MustCompile(`group:\s*'(\w+)'`).
		FindAllStringSubmatch(sections, -1) {

		if !known[m[1]] {
			t.Errorf("a section is filed under %q, which is not one of the rail's groups "+
				"(%s) — so it appears in no group at all", m[1], strings.Join(keys(known), ", "))
		}
	}
}

func keys(of map[string]bool) []string {
	out := make([]string, 0, len(of))
	for k := range of {
		out = append(out, k)
	}
	return out
}
