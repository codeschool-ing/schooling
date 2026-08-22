package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// THE PARSER IS THE PART THAT CAN BE SUBTLY WRONG, and wrong in the direction
// that costs nothing to notice and everything to miss: a scanner that skips a
// `@media` block reads a stylesheet as smaller than it is, finds no collision
// and passes. So the fixture is written out of the shapes both copied files
// actually contain.
func TestReadsSelectorsAndNotDeclarations(t *testing.T) {
	const css = `
/* A comment with a .fake-class in it, and a } to end a block that never opened. */
.plain{color:red}
.numbers{font-size:.68rem;transition:color .15s,border-color .3s;opacity:.65}
@media (max-width:700px){
  .inside-a-media-query{display:grid}
}
.a,.b > .c:hover,.d[data-x="."]{gap:4px}
`

	rules := parse(t, css)

	want := map[string]bool{
		"plain": true, "numbers": true, "inside-a-media-query": true,
		"a": true, "b": true, "c": true, "d": true,
	}
	got := map[string]bool{}
	for _, r := range rules {
		for _, c := range r.classes {
			got[c] = true
		}
	}
	for c := range want {
		if !got[c] {
			t.Errorf("`.%s` is declared in the fixture and the parser did not find it", c)
		}
	}
	for c := range got {
		if !want[c] {
			t.Errorf("`.%s` is not a class in the fixture — the parser read a declaration or a "+
				"comment as a selector", c)
		}
	}
}

// `.68rem` and `.15s` are not classes and `--tint` is not a layout property.
// Both mistakes fail open, which is why they are asserted rather than assumed.
func TestOnlyLayoutPropertiesCount(t *testing.T) {
	const css = `
.moves{display:flex;gap:4px;margin-top:2px;flex-direction:column}
.stays{color:red;opacity:.65;font-size:.68rem;--gap-of-ours:4px;transition:margin .2s}
`
	for _, r := range parse(t, css) {
		moved := r.moves()
		switch r.selector {
		case ".moves":
			if len(moved) != 4 {
				t.Errorf(".moves sets four layout properties, the check found %d: %v", len(moved), moved)
			}
		case ".stays":
			if len(moved) != 0 {
				t.Errorf(".stays moves nothing, the check found %v — a custom property, a "+
					"transition or a fractional value was read as layout", moved)
			}
		}
	}
}

// The whole verdict, over a tree the shape of `ui/`: the same class, laid out
// once loose and once behind a screen of ours.
func TestOursMayOverrideButNotLayOut(t *testing.T) {
	dir := t.TempDir()
	write(t, dir, "assets/base.css", ".on{color:blue}")
	write(t, dir, "assets/portal.css", ".steps{display:flex;flex-wrap:wrap}")
	write(t, dir, "assets/exercises.css", ".choice{color:red}")

	// A colour on their class, and a layout property held to a screen of ours.
	write(t, dir, "assets/app.css", ".steps{color:red}\n.view-account .on{display:flex}")
	problems, _, err := check(dir, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(problems) != 0 {
		t.Errorf("an override that moves nothing, and a layout rule a screen of ours holds, "+
			"are both allowed — got %v", problems)
	}

	// And the defect itself.
	write(t, dir, "assets/app.css", ".steps{display:flex;flex-direction:column}")
	problems, _, err = check(dir, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(problems) != 2 {
		t.Fatalf("laying out `.steps`, which is theirs, is two problems — got %d: %v",
			len(problems), problems)
	}
	if !strings.Contains(problems[0], "assets/portal.css's") {
		t.Errorf("the message has to say whose the class is, so there is somewhere to go and "+
			"look: %q", problems[0])
	}

	// The allow-list lets exactly that one through, and complains when it stops
	// being needed.
	problems, _, err = check(dir, map[string]string{
		"steps display": "because", "steps flex-direction": "because", "gone height": "stale",
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(problems) != 1 || !strings.Contains(problems[0], "gone height") {
		t.Errorf("two allowed, one stale, so one problem and it names the stale entry — got %v",
			problems)
	}
}

func parse(t *testing.T, css string) []rule {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, "x.css")
	if err := os.WriteFile(path, []byte(css), 0o600); err != nil {
		t.Fatal(err)
	}
	rules, err := rulesIn(path)
	if err != nil {
		t.Fatal(err)
	}
	return rules
}

func write(t *testing.T, dir, name, body string) {
	t.Helper()
	path := filepath.Join(dir, name)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
}
