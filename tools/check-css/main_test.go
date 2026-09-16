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
	write(t, dir, "assets/portal.css", ".steps{display:flex;flex-wrap:wrap}\n.code-bar{display:flex}")
	write(t, dir, "assets/exercises.css", ".choice{color:red}")
	// Tokens and nothing else, which is what a palette file is: no selector of
	// theirs, so nothing here can move one of their elements.
	write(t, dir, "assets/terminal.css", ":root{--term-green:#3ddc84}")
	// AND THE SHAPE THE WAY OUT ACTUALLY HAS. `.code-bar` is theirs and this
	// moves what is inside it, which is the defect — except that `.code-win` is
	// ours and is in the selector, so the rule cannot reach a bar this
	// repository did not draw.
	write(t, dir, "assets/code-window.css", ".code-win .code-bar{align-items:flex-end}")

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

// THE THREE SHAPES, AND WHAT A BROWSER DOES WITH EACH. The comments are not a
// guess: they are the output of loading exactly these three stylesheets into
// Chromium and reading `cssRules` back, which is also how the `cssRules.length`
// check was ruled out — in all three the sheet still has rules in it.
func TestAFileThatStopsParsingIsFoundAtTheLineItStopsOn(t *testing.T) {
	for _, c := range []struct {
		name string
		css  string
		line int
		says string
	}{
		// Chromium keeps `.a` and `.c`. `.b` is gone.
		{"a stray close", ".a{color:red}\n*/\n.b{color:blue}\n.c{color:green}\n", 2, "never opened"},
		// Chromium keeps `.a` and nothing else.
		{"a comment nobody closed", ".a{color:red}\n/* oops\n.b{color:blue}\n", 2, "never closed"},
		// Chromium keeps `.a`, with `.c` NESTED inside it, and drops `.b`.
		{"a block nobody closed", ".a{color:red\n.b{color:blue}\n.c{color:green}\n", 1, "never closed"},
		{"a close with no open", ".a{color:red}\n}\n", 2, "never opened"},
		{"a string nobody closed", ".a{content:\"oops\n.b{color:blue}\n", 1, "never closed on it"},
	} {
		t.Run(c.name, func(t *testing.T) {
			line, what := stops(c.css)
			if line != c.line {
				t.Errorf("the break is on line %d, the check says line %d (%s)", c.line, line, what)
			}
			if !strings.Contains(what, c.says) {
				t.Errorf("the message has to say what did not close, so there is something to go "+
					"and fix: %q", what)
			}
		})
	}
}

// AND THE OTHER DIRECTION, WHICH IS THE ONE THAT MATTERS MORE. A scanner that
// answers "broken" to everything would pass the test above and fail the
// repository on its first run; these are the shapes a stylesheet legitimately
// contains that a naive `*/` or `{` count reads as a break.
func TestTheShapesAStylesheetLegitimatelyContains(t *testing.T) {
	const css = `
/* A comment with a } in it, and an unbalanced { , and even a quote: " */
.plain{color:red}
@media (max-width:700px){
  .inside{display:grid}
}
.q[data-x="a } inside a string"]{gap:4px}
.q[data-y='and a { in the other quote']{gap:4px}
.escaped::after{content:"he said \"stop\""}
.continued::after{content:"a string that \
carries on below"}
.slash{background-image:url(data:image/svg+xml;utf8,<svg/>)}
`
	if line, what := stops(css); line > 0 {
		t.Errorf("this file parses to its end; the check says it breaks on line %d: %s", line, what)
	}
}

// The whole verdict, over a tree: a file that does not parse is named, and the
// rest of the tool never runs against it.
func TestTheParsePassNamesTheFile(t *testing.T) {
	dir := t.TempDir()
	write(t, dir, "assets/fine.css", ".a{color:red}")
	write(t, dir, "assets/broken.css", ".a{color:red}\n*/\n.b{color:blue}")
	// Not a stylesheet, and full of braces that do not balance.
	write(t, dir, "assets/notes.md", "{{{")

	problems, sheets, err := parses([]string{dir})
	if err != nil {
		t.Fatal(err)
	}
	if sheets != 2 {
		t.Errorf("two stylesheets under this tree, the walk read %d — it is picking up files "+
			"that are not stylesheets, or missing one that is", sheets)
	}
	if len(problems) != 1 || !strings.Contains(problems[0], "broken.css:2") {
		t.Fatalf("one file breaks, on line 2, and the message has to name it: %v", problems)
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
	if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
}
