package console_test

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

/* The strings `check-interface` admits it cannot see.

   # WHY THIS TEST EXISTS AT ALL

   `tools/check-interface internal/console/ui` reads literal `txt('…')` calls.
   The rail does not make one: it draws `txt(s.name)` and `txt(g)`, where the
   argument comes from `sections.js` — the console's map of itself. That is the
   right shape (a section's identity must not depend on what language somebody
   is reading in) and it means seventeen of the most visible strings in this
   console are invisible to the checker, in BOTH directions:

     - a section added without a translation draws its English name in the
       middle of a Portuguese rail, and nothing fails;
     - a section renamed or removed leaves an entry behind, which reads as
       current — the failure the checker exists for, on the strings it cannot
       reach.

   The tool says so in its own header rather than pretending. This is the part
   that can be closed anyway, because the list is CLOSED: both files are read
   here and compared, which is the same job the checker does with the same
   argument behind it.

   # IT READS THE FILES AND NOT THE EMBED

   `screen` is unexported and this is an external test package, which is the
   right way round: reading the source is what makes a mismatch a fact about
   the repository rather than about a build. Go runs a test in its package's
   directory, so these paths are stable.
*/

/*
read is the one place a file is opened, and every caller hands it a literal.

	gosec's G304 is about a filename that came from somewhere — and it is right
	about that — so the answer is one reader rather than a `//nolint` on each
	helper. Everything below works on the text.
*/
func read(t *testing.T, name string) string {
	t.Helper()
	// G304 is about a filename that came from somewhere, and it is right about
	// that in general. Every call site below hands this a literal; gosec cannot
	// see across the call, and one suppression on one line is the honest
	// version of saying so.
	source, err := os.ReadFile(name) //nolint:gosec // every caller passes a literal
	if err != nil {
		t.Fatalf("reading %s: %v", name, err)
	}
	return string(source)
}

// sectionNames is every `name:` in the sections list, and every group.
func sectionNames(t *testing.T) []string {
	t.Helper()

	source := read(t, "ui/app/sections.js")
	text := source

	var out []string
	for _, m := range regexp.MustCompile(`name: '([^']+)'`).FindAllStringSubmatch(text, -1) {
		out = append(out, m[1])
	}

	/* THE GROUPS COME FROM THE ONE LINE THAT DECLARES THEM. A rail heading is
	   read exactly as often as a section name and translated by the same call. */
	groups := regexp.MustCompile(`GROUPS = \[([^\]]+)\]`).FindStringSubmatch(text)
	if groups == nil {
		t.Fatal("no GROUPS in sections.js — if the rail's headings moved, this test has to follow")
	}
	for _, m := range regexp.MustCompile(`'([^']+)'`).FindAllStringSubmatch(groups[1], -1) {
		out = append(out, m[1])
	}

	if len(out) < 10 {
		t.Fatalf("only %d names were found in sections.js, which is fewer than this console "+
			"has — the shape of that file changed and this test is reading nothing", len(out))
	}
	return out
}

// portuguese is every key the dictionary carries.
func portuguese(t *testing.T) map[string]bool {
	t.Helper()

	source := read(t, "ui/assets/i18n-pt.js")

	/* A KEY IS A QUOTED STRING FOLLOWED BY A COLON, which is enough here and
	   would not be in general: this file is written by hand in one shape, and a
	   JavaScript parser to read a flat object of literals would be a great deal
	   of machinery to answer a question a regular expression answers. The
	   guard is below — too few keys and this is reading the wrong thing. */
	keys := map[string]bool{}
	for _, m := range regexp.MustCompile(`(?m)^\s*'((?:[^'\\]|\\.)*)':`).
		FindAllStringSubmatch(source, -1) {

		keys[strings.ReplaceAll(m[1], `\'`, `'`)] = true
	}
	if len(keys) < 10 {
		t.Fatalf("only %d keys were found in the dictionary — its shape changed and this "+
			"test is reading nothing", len(keys))
	}
	return keys
}

/*
drawnThroughAVariable is every English string a screen looks up before showing.

	THE CHECKER READS `txt('…')` AND THESE ARE `txt(SOMETHING[key])`, which is
	the same blindness the rail has and for the same good reason: the value is a
	CLOSED LIST that also has to stay English, because it is what the server
	sends, what the audit records, or what the console's own map of itself calls
	a section. Translating in the data would make an identity depend on what
	language somebody is reading in.

	SO THE LIST OF SOURCES IS MAINTAINED HERE, and it grows. That is a cost and
	it is the smaller one: the alternative is a test that tries to recognise
	"an object literal of English strings" across twenty screens, which is
	fragile in the direction that fails silently. A new map like these needs a
	line here, and the failure if somebody forgets is the one this file already
	describes — English words inside a Portuguese screen, with nothing else
	looking wrong.
*/
func drawnThroughAVariable(t *testing.T) []string {
	t.Helper()
	out := sectionNames(t)

	// The reasons a student picks, and the three verdicts an operator answers
	// with. `reports.js` holds both as module-level maps, English on the value
	// side, and draws them as `txt(WHY[…])` and `txt(MEANS[…])`.
	out = append(out, mapValues(t, "reports.js", read(t, "ui/app/screens/reports.js"),
		"MEANS", "WHY")...)

	/* THE TWO THEME NAMES. `schools.js` draws a specimen per theme from
	   `['dark', 'light']` and prints `txt(theme)` in three places, so the words
	   are looked up rather than said. They are written out here rather than
	   parsed out of an array literal: two words that have not changed since the
	   stylesheet had two themes, and a regular expression for a bare array is
	   the kind that quietly matches the wrong one. */
	out = append(out, "dark", "light")

	/* THE TWENTY SUGGESTED COLOURS, whose names `schools.js` draws through
	   `txt(name)` beside a hex it never translates. */
	out = append(out, pairFirsts(t, "schools.js", read(t, "ui/app/screens/schools.js"),
		"SUGGESTED")...)

	/* THE THREE TERMS THIS PLATFORM SELLS. `plan.js` holds them in `TERMS` —
	   objects rather than a flat map — and draws `txt(term.name)` and
	   `txt(term.note)`. `PLAN.md` says the list is closed on purpose: a screen
	   with an open "how many months" field would be inviting somebody to invent
	   a fourth product by typing. */
	out = append(out, fieldValues(t, "plan.js", read(t, "ui/app/screens/plan.js"),
		"TERMS", "name", "note")...)

	return out
}

// fieldValues reads named string fields out of a `const X = [ … ]` list of
// objects, which is the other shape a closed list takes in this console.
func fieldValues(t *testing.T, file, source, list string, fields ...string) []string {
	t.Helper()

	block := regexp.MustCompile(`(?s)const ` + list + ` = \[(.*?)\n\];`).
		FindStringSubmatch(source)
	if block == nil {
		t.Fatalf("no `const %s = […]` in %s — it was renamed or removed, and this test is "+
			"now checking nothing", list, file)
	}

	var out []string
	for _, field := range fields {
		/* A VALUE MAY BE CONCATENATED ACROSS LINES here, unlike a dictionary
		   key: these are ordinary JavaScript expressions and the file is
		   written that way. So the literals are gathered up to the line that
		   ends the entry — a comma at the end of a line with no open quote. */
		found := regexp.MustCompile(`(?s)`+field+`:\s*((?:'(?:[^'\\]|\\.)*'\s*\+?\s*)+),`).
			FindAllStringSubmatch(block[1], -1)
		if len(found) == 0 {
			t.Fatalf("no `%s:` in %s's %s, so its shape changed", field, file, list)
		}
		for _, m := range found {
			var whole strings.Builder
			for _, part := range regexp.MustCompile(`'((?:[^'\\]|\\.)*)'`).
				FindAllStringSubmatch(m[1], -1) {

				whole.WriteString(part[1])
			}
			out = append(out, strings.ReplaceAll(whole.String(), `\'`, `'`))
		}
	}
	return out
}

/*
mapValues reads the quoted values out of named `const X = { … }` maps.

	IT TAKES THE SOURCE AND NOT A PATH, which is why there is no `os.ReadFile`
	here: gosec flags a read whose filename is a variable (G304), and it is right
	to in general — the fix is to have one reader, called with a literal, rather
	than a suppression on every helper that happens to need a file.
*/
func mapValues(t *testing.T, file, source string, names ...string) []string {
	t.Helper()

	var out []string
	for _, name := range names {
		block := regexp.MustCompile(`(?s)const ` + name + ` = \{(.*?)\n\};`).
			FindStringSubmatch(source)
		if block == nil {
			t.Fatalf("no `const %s = {…}` in %s — it was renamed or removed, and this test "+
				"is now checking nothing", name, file)
		}
		found := regexp.MustCompile(`:\s*'((?:[^'\\]|\\.)*)'`).
			FindAllStringSubmatch(block[1], -1)
		if len(found) == 0 {
			t.Fatalf("%s in %s has no quoted values, so its shape changed", name, file)
		}
		for _, m := range found {
			out = append(out, strings.ReplaceAll(m[1], `\'`, `'`))
		}
	}
	return out
}

/*
TestEveryStringDrawnThroughAVariableHasPortuguese is the missing half of the
checker.

	A section name or a verdict with no entry draws in English inside a
	Portuguese screen, which is the one place somebody reads it as a bug in the
	translation rather than as a missing one — and nothing else looks wrong.
*/
func TestEveryStringDrawnThroughAVariableHasPortuguese(t *testing.T) {
	has := portuguese(t)

	for _, name := range drawnThroughAVariable(t) {
		if !has[name] {
			t.Errorf("the console draws %q and the dictionary has no Portuguese for it. "+
				"`check-interface` cannot see this one: it is looked up through a variable, "+
				"so the call it scans for is not there", name)
		}
	}
}

/*
TestEveryKeyIsOneStringOnOneLine, which is a syntax rule and cost a whole file.

	An object key cannot be an expression, so this is a syntax error:

	    'half a sentence ' +
	    'and the rest':  'a tradução',

	It reads perfectly, it is what somebody writes when a key is too long for a
	line, and the VALUE beside it may be concatenated exactly that way — which is
	where the habit comes from. What it does is stop the whole file parsing.
	`window.I18N` is then never set, `txt()` answers with its key, every screen
	falls back to English, and NOTHING LOOKS BROKEN: a console in English is what
	a console in English looks like.

	`check-interface` passed the broken file. It reads keys with a regular
	expression rather than a parser — which is the right trade for what it does —
	so it validated a dictionary no browser could load, and reported every string
	translated. This shipped for the length of one browser run, and what found it
	was driving the picker rather than any check.

	THE RULE HELD HERE IS: A LINE ENDING IN `+` IS NEVER FOLLOWED BY A KEY. That
	is what a concatenated key IS, and it is sound in both directions — a
	concatenated VALUE puts a string ending in a comma on the next line, never
	one followed by a colon.

	The first version of this test was narrower and wrong. It looked for a line
	ENDING a key without starting it, which catches the shape the mistake
	happened to take here — the value on the line after — and misses the ordinary
	one, where the value follows the key on the same line. It passed on a
	deliberately broken file. A guard is worth what it catches, so it is worth
	breaking the file on purpose before believing it.
*/
func TestEveryKeyIsOneStringOnOneLine(t *testing.T) {
	source := read(t, "ui/assets/i18n-pt.js")

	joins := regexp.MustCompile(`\+\s*$`)
	isKey := regexp.MustCompile(`^\s*'(?:[^'\\]|\\.)*'\s*:`)

	lines := strings.Split(source, "\n")
	for i := 0; i+1 < len(lines); i++ {
		if !joins.MatchString(lines[i]) || !isKey.MatchString(lines[i+1]) {
			continue
		}
		t.Errorf("the key on line %d is concatenated from line %d, and an object key "+
			"cannot be an expression. That is a syntax error which stops the WHOLE "+
			"dictionary parsing, so every screen falls back to English and nothing looks "+
			"broken:\n  %s\n  %s",
			i+2, i+1, strings.TrimSpace(lines[i]), strings.TrimSpace(lines[i+1]))
	}
}

/* THE OTHER DIRECTION IS NOT CHECKED HERE, AND THAT IS NOT AN OVERSIGHT.

   An entry for a section that was renamed reads as current, which is the
   failure `check-interface` exists for — so the obvious companion to the test
   above is one that fails on a key nothing says any more. It was written, and
   it is not here, because it cannot be made sound.

   A key in this dictionary is one of three things: a rail string, a literal
   `txt('…')` somewhere in the console's scripts, or a sentence the SERVER sent
   — which arrives at run time, in English, from Go. The first two are
   enumerable and the third is not, so anything left over is indistinguishable
   from a server sentence somebody translated correctly. The version that was
   written reported ten of those as suspects on its first run.

   A check that cries wolf about correct entries is worse than the gap it
   covers: it teaches whoever reads it to skip the output, which is the same
   output that would one day name a real one. The tool already reports the count
   of unsaid entries without failing on it, for exactly this reason, and that
   count is where a rename would show up for somebody looking. */

/*
TestNoKeyIsWrittenTwice, because JavaScript will not say a word about it.

	A duplicate key in an object literal is legal: the last one wins, silently.
	So two people translating the same English sentence — or one person adding an
	entry to a screen's block that a rail block already carries — produce a file
	where one of the two translations decides nothing, and every check passes.
	`check-interface` reads keys into a map and cannot see it either.

	IT ALMOST SHIPPED IN THIS FILE. `History` was written twice, once as a
	section name and once as the heading of the screen it names. Both mapped to
	the same Portuguese, so nothing would have looked wrong — which is the whole
	problem: the version that catches this has to run when the two agree, because
	by the time they disagree somebody is already reading the wrong one.
*/
func TestNoKeyIsWrittenTwice(t *testing.T) {
	source := read(t, "ui/assets/i18n-pt.js")

	seen := map[string]int{}
	key := regexp.MustCompile(`(?m)^\s*'((?:[^'\\]|\\.)*)':`)
	for i, line := range strings.Split(source, "\n") {
		m := key.FindStringSubmatch(line)
		if m == nil {
			continue
		}
		if before, twice := seen[m[1]]; twice {
			t.Errorf("%q is a key on line %d and again on line %d. JavaScript keeps the "+
				"last one and says nothing, so one of the two translations decides "+
				"nothing", m[1], before, i+1)
			continue
		}
		seen[m[1]] = i + 1
	}
}

// pairFirsts reads the first string of each `['a', 'b']` pair in a named list.
func pairFirsts(t *testing.T, file, source, list string) []string {
	t.Helper()

	block := regexp.MustCompile(`(?s)const ` + list + ` = \[(.*?)\n\];`).
		FindStringSubmatch(source)
	if block == nil {
		t.Fatalf("no `const %s = […]` in %s — it was renamed or removed, and this test is "+
			"now checking nothing", list, file)
	}

	found := regexp.MustCompile(`\['((?:[^'\\]|\\.)*)',`).FindAllStringSubmatch(block[1], -1)
	if len(found) == 0 {
		t.Fatalf("%s in %s has no pairs, so its shape changed", list, file)
	}

	out := make([]string, 0, len(found))
	for _, m := range found {
		out = append(out, strings.ReplaceAll(m[1], `\'`, `'`))
	}
	return out
}
