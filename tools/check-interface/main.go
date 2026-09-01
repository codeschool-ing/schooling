// Command check-interface holds the interface's translations to its strings.
//
// # THE FAILURE IT EXISTS TO CATCH
//
// Somebody writes `txt('Hand in')` on a new screen and does not add the
// Portuguese. Nothing breaks: the runtime falls back to the key, which is
// already English, so the screen works perfectly — in the wrong language, for
// half the students, until one of them mentions it. That is the whole class of
// defect here, and it is invisible to every other check in this repository.
//
// # AND THE OTHER DIRECTION, WHICH IS THE ONE PEOPLE FORGET
//
// A dictionary entry for a string nothing says any more is worse than a missing
// one: it reads as current, it survives every rename around it, and the next
// person to look assumes the sentence is still on a screen somewhere. So a
// stale entry fails too. It is the same mechanism as the tenancy exceptions and
// for the same reason — an exception that outlived what it excused.
//
// # WHAT IT READS, AND WHAT IT CANNOT
//
// Two sources, both of which are the truth rather than a copy of it: every
// `txt(...)` call in the interface's scripts, and every translatable string in
// `index.html` — its text, its `placeholder`, `aria-label` and `title`, and the
// document title. The HTML is parsed rather than pattern-matched, because a
// hand-rolled scanner over markup is the kind of thing that is subtly wrong for
// a year.
//
// It cannot see a sentence the SERVER writes. Those arrive in English and go
// through `txt()` at the point of display, so they can be translated by adding
// an entry — but no static check can enumerate them, and pretending otherwise
// would be worse than saying so here.
//
//	check-interface [ui directory]     (default: ui/)
package main

import (
	"fmt"
	"maps"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"sort"
	"strings"

	"golang.org/x/net/html"
)

func main() {
	dir := "ui"
	if len(os.Args) > 1 {
		dir = os.Args[1]
	}

	problems, checked, err := check(dir)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if len(problems) == 0 {
		fmt.Printf("%d interface strings, all of them translated\n", checked)
		return
	}

	// Everything, then fail. A checker that stops at the first problem turns
	// translating a screen into a sequence of runs, each teaching one word.
	for _, p := range problems {
		fmt.Fprintln(os.Stderr, p)
	}
	fmt.Fprintf(os.Stderr, "\n%d problems in %d interface strings\n", len(problems), checked)
	os.Exit(1)
}

func check(dir string) (problems []string, checked int, err error) {
	said, err := stringsSaid(dir)
	if err != nil {
		return nil, 0, err
	}
	if len(said) == 0 {
		return nil, 0, fmt.Errorf("check-interface: %s says nothing at all, which cannot be right — "+
			"either the directory is wrong or this tool has stopped finding what it reads", dir)
	}

	// One file per language, and English is not one of them: the key IS the
	// English string, so an `en` dictionary would be an identity map.
	//
	// A DICTIONARY IS A FILE THAT DECLARES ONE, not a file whose name starts
	// with `i18n-`. The name was enough while `assets/` held one dictionary and
	// nothing else that answered to the pattern; then the portal's interface was
	// copied in and brought `i18n-runtime.js`, which is the RUNTIME — it reads
	// dictionaries, it is not one — and `i18n-courses-pt.js`, which translates
	// the catalogue rather than the interface. Both matched, and the first thing
	// the reader met was `const LANGUAGES = [`, which it correctly refused to
	// guess at.
	//
	// So the file has to say what it is: `window.I18N.<lang>.ui = {`. Anything
	// matching the pattern and declaring none of those is not a dictionary and
	// is named below rather than passed over in silence — a real dictionary that
	// stopped declaring one would otherwise vanish from this check without a
	// word, which is the failure this tool exists to prevent.
	candidates, err := filepath.Glob(filepath.Join(dir, "assets", "i18n-*.js"))
	if err != nil {
		return nil, 0, err
	}
	sort.Strings(candidates)

	dictionaries := map[string]string{} // path -> language
	var notDictionaries []string
	for _, path := range candidates {
		language, err := languageOf(path)
		if err != nil {
			return nil, 0, err
		}
		if language == "" {
			notDictionaries = append(notDictionaries, filepath.Base(path))
			continue
		}
		dictionaries[path] = language
	}
	if len(notDictionaries) > 0 {
		fmt.Printf("not dictionaries, and not read: %s\n", strings.Join(notDictionaries, ", "))
	}
	if len(dictionaries) == 0 {
		return nil, 0, fmt.Errorf("check-interface: no dictionary in %s — the interface claims to "+
			"speak more than one language and there is nothing to speak it with", dir)
	}

	/* MERGED BY LANGUAGE, because a language can have more than one file and
	   here it does: `i18n-pt.js` is the portal's, copied and kept syncable, and
	   `i18n-schooling-pt.js` adds the strings that exist only in this
	   repository. The runtime sees one object; checking them one file at a time
	   would report every entry of each as missing from the other. */
	merged := map[string]map[string]bool{} // language -> keys
	files := map[string][]string{}         // language -> which files carry it
	for _, path := range candidates {
		language, isDictionary := dictionaries[path]
		if !isDictionary {
			continue
		}
		entries, err := dictionaryKeys(path)
		if err != nil {
			return nil, 0, err
		}
		if merged[language] == nil {
			merged[language] = map[string]bool{}
		}
		for key := range entries {
			merged[language][key] = true
		}
		files[language] = append(files[language], filepath.Base(path))
	}

	for _, language := range slices.Sorted(maps.Keys(merged)) {
		entries := merged[language]
		where := strings.Join(files[language], " + ")

		for _, s := range said {
			if !entries[s] {
				problems = append(problems, fmt.Sprintf(
					"%s: no %s for %q — it will be shown in English to everybody reading in %s, "+
						"and nothing else will look wrong", where, language, s, language))
			}
		}

		/* ---------- AND THE OTHER DIRECTION, WHICH IS COUNTED AND NOT FAILED ----------

		   An entry for a string nothing says is worse than a missing one when
		   the dictionary belongs to the interface it translates: it reads as
		   current and survives every rename around it. That was true when this
		   tool was written, and it is not true of the file it now reads.

		   `i18n-pt.js` IS NOT THIS REPOSITORY'S. It is the vitrine's, copied
		   whole and kept syncable on purpose, and it translates two interfaces
		   at once — the marketing site's pages and the portal's screens. Every
		   sentence about pricing, plans and companies in it is said on a screen
		   that is over there, so "nothing says it HERE" is a fact about which
		   half of the file this deployment uses, not a defect in it.

		   The copy is also unfinished — the legal, practice and account screens
		   are not in yet — so part of this number is a list of what is still
		   missing rather than of what is stale.

		   So it is counted and named, and it does not fail. The half that does
		   fail is the one above, which is the failure this tool was built for: a
		   string on a screen with no translation behind it. Both halves become
		   failures again on the day this repository authors its own dictionary
		   or the copy is complete — whichever comes first. */
		saidSet := map[string]bool{}
		for _, s := range said {
			saidSet[s] = true
		}
		var unsaid int
		for entry := range entries {
			if !saidSet[entry] {
				unsaid++
			}
		}
		/* THE NOTE NAMES BOTH REASONS AND ASSERTS NEITHER, because this tool
		   cannot tell them apart and used to claim the first one for every
		   directory it was pointed at. Read against `ui/my` — one screen, its
		   own dictionary, no copied anything — it explained a single unsaid
		   entry as the vitrine's, which was false and would have sent somebody
		   looking for a file that is not there.

		   The second reason is the one that entry actually is. It is out of this
		   tool's reach for good — nothing static can enumerate a string that
		   arrives over HTTP — so the check for it lives where the string is
		   declared instead: `internal/practice/across_test.go` holds the
		   dictionary to `practice.About`, character for character. */
		noun := "entries"
		if unsaid == 1 {
			noun = "entry"
		}
		if unsaid > 0 {
			fmt.Printf("%s: %d %s this interface does not say. Counted and not failed: a "+
				"dictionary may translate more than one interface — `ui/`'s carries the "+
				"vitrine's screens too — and a sentence the SERVER sends arrives at run time, "+
				"where no static scan can see it\n", where, unsaid, noun)
		}
	}

	sort.Strings(problems)
	return problems, len(said), nil
}

/* ---------- what the interface says ---------- */

/*
txtCall finds a `txt(…)` whose argument is a fixed string, and `oneLiteral`
takes that argument apart again.

# IT USED TO READ ONE LITERAL AND NOTHING ELSE

`txt('a ' + 'b')` matched nothing, so the call was invisible — and invisible
here is not neutral, it fails in BOTH directions at once. The screen says
English in every language, because nobody was told a translation was missing.
And the entry that would have translated it is reported STALE, because this tool
believes nothing says that sentence — so acting on the second report means
deleting the thing that would have fixed the first. `ui/my/app/queue.js` says it
has cost this repository two strings.

It was defended by a rule written in a comment, in two files, which is a rule
defended by whoever remembers reading it. The tool can see the string instead:
the runtime asks the dictionary for the joined value, and joining the literals
here asks for exactly the same key.

# A LITERAL AT EVERY POSITION, OR NOTHING

`txt('at or over ' + n)` still matches nothing, and must not: that key depends on
a value, and no dictionary can be written against it. The pattern requires a
literal on both sides of every `+`, so a call with a variable anywhere in it
falls out entirely rather than being read as its literal half — which would ask
for a fragment, and a fragment is the thing a translator cannot reorder.
`internal/console/language_test.go` covers those, by reading the lists they are
drawn from.

# TWO PATTERNS, BECAUSE RE2 KEEPS ONLY THE LAST REPETITION

A repeated capturing group answers once, with whatever matched last, so one
pattern cannot hand back four literals. The first finds the whole call and keeps
its argument; the second walks that argument. The quotes are written out rather
than captured and back-referenced, because Go's regexp has no back-references at
all — RE2 trades them for the guarantee that a pattern cannot take exponential
time.
*/
const literal = `(?:'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")`

var (
	txtCall    = regexp.MustCompile(`\btxt\(\s*(` + literal + `(?:\s*\+\s*` + literal + `)*)\s*\)`)
	oneLiteral = regexp.MustCompile(literal)
)

// saidIn is every fixed string a source says through `txt()`. The comments come
// out first — see `withoutComments` for the defect that requires it.
func saidIn(source string) []string {
	var out []string
	for _, call := range txtCall.FindAllStringSubmatch(withoutComments(source), -1) {
		var joined strings.Builder
		for _, quoted := range oneLiteral.FindAllString(call[1], -1) {
			joined.WriteString(unescape(quoted[1 : len(quoted)-1])) // the quotes come off
		}
		out = append(out, joined.String())
	}
	return out
}

func stringsSaid(dir string) ([]string, error) {
	found := map[string]bool{}

	// `assets/` AND `app/`, and the second one is where the screens went.
	//
	// The interface was one flat directory of scripts when this was written. It
	// is `portal-frontend`'s now — a tree under `app/`, twenty-odd modules deep
	// — and every sentence a student reads is said in there. Reading only
	// `assets/` left this tool with a handful of strings and a dictionary full
	// of entries for the rest, which it duly reported as five hundred stale
	// translations: the check inverted, and would have gone on passing while
	// nothing was checked at all.
	var scripts []string
	for _, where := range []string{"assets", "app"} {
		err := filepath.WalkDir(filepath.Join(dir, where), func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if !d.IsDir() && strings.HasSuffix(path, ".js") {
				scripts = append(scripts, path)
			}
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	sort.Strings(scripts)

	for _, path := range scripts {
		if strings.HasPrefix(filepath.Base(path), "i18n-") {
			continue // a dictionary quotes every string; it does not say them
		}
		body, err := os.ReadFile(path) //nolint:gosec // a path from this tool's own walk
		if err != nil {
			return nil, err
		}
		for _, s := range saidIn(string(body)) {
			found[s] = true
		}
	}

	fromHTML, err := htmlStrings(filepath.Join(dir, "index.html"))
	if err != nil {
		return nil, err
	}
	for _, s := range fromHTML {
		found[s] = true
	}

	out := make([]string, 0, len(found))
	for s := range found {
		out = append(out, s)
	}
	sort.Strings(out)
	return out, nil
}

// htmlStrings is every translatable string in the shell.
//
// The containers the router fills are NOT skipped, and they do not need to be:
// they are empty in the file. What the router puts in them goes through txt()
// and is found in the scripts instead — which is the same string, arrived at
// from the source that actually writes it.
func htmlStrings(path string) ([]string, error) {
	file, err := os.Open(path) //nolint:gosec // a path built from this tool's argument
	if err != nil {
		return nil, err
	}
	defer func() { _ = file.Close() }() // read-only: there is nothing a failed close could lose

	doc, err := html.Parse(file)
	if err != nil {
		return nil, fmt.Errorf("check-interface: %s: %w", path, err)
	}

	var out []string
	var walk func(*html.Node, bool)
	walk = func(n *html.Node, insideScript bool) {
		if n.Type == html.ElementNode {
			switch n.Data {
			case "script", "style":
				insideScript = true
			}
			// THE BRAND IS A NAME AND NAMES ARE NOT TRANSLATED. The markup
			// carries `codeschool.ing` because it is the portal's, and this
			// deployment overwrites it at boot with whichever school the
			// address named — so the words in the file are a placeholder for a
			// row in a table, not a sentence anybody is asked to translate.
			// Demanding a Portuguese for "ing" is the check being wrong.
			// The same is true of the TAB, for the same reason: the router
			// writes `document.title` from the school's name on every
			// navigation, so the `<title>` in the file is the value used until
			// the catalogue lands and never a sentence to translate.
			if n.Data == "title" || hasClass(n, "brand-name") {
				return
			}
			for _, attr := range n.Attr {
				switch attr.Key {
				case "placeholder", "aria-label", "title":
					if translatable(attr.Val) {
						out = append(out, strings.TrimSpace(attr.Val))
					}
				}
			}
		}

		if n.Type == html.TextNode && !insideScript && translatable(n.Data) {
			out = append(out, strings.TrimSpace(n.Data))
		}

		for child := n.FirstChild; child != nil; child = child.NextSibling {
			walk(child, insideScript)
		}
	}
	walk(doc, false)

	return out, nil
}

func hasClass(n *html.Node, want string) bool {
	for _, attr := range n.Attr {
		if attr.Key != "class" {
			continue
		}
		for _, c := range strings.Fields(attr.Val) {
			if c == want {
				return true
			}
		}
	}
	return false
}

// The same test the runtime applies: more than two characters and containing a
// letter. Written here as well because the two have to agree, and a checker
// that counted a different set of strings than the runtime translates would
// report on things nobody can fix.
var hasLetter = regexp.MustCompile(`[A-Za-zÀ-ÿ]`)

func translatable(s string) bool {
	s = strings.TrimSpace(s)
	return len(s) > 2 && hasLetter.MatchString(s)
}

/* ---------- what a dictionary carries ---------- */

// A key at the start of a line, quoted, followed by a colon. The dictionaries
// are written that way on purpose — see the refusal below, which is what stops
// that from being a hope.
// What a dictionary of the INTERFACE declares. `.ui` and not `.courses` or
// `.tracks`: those translate the catalogue, which is content and is checked
// against the content rather than against the strings the screens say.
//
// It matches whether the file ASSIGNS the object or ADDS to it. There are two,
// and they are two on purpose: one is `portal-frontend`'s, copied and kept
// syncable, and the other holds the strings that exist only here — see the
// header of `i18n-schooling-pt.js`. Both are dictionaries of the same language
// and both are read.
var declaresUI = regexp.MustCompile(`(?m)^\s*window\.I18N\.([A-Za-z-]+)\.ui\s*=`)

// languageOf answers which language a file is a dictionary of, or "" for a file
// that is not one.
func languageOf(path string) (string, error) {
	body, err := os.ReadFile(path) //nolint:gosec // a path from this tool's own glob
	if err != nil {
		return "", err
	}
	m := declaresUI.FindSubmatch(body)
	if m == nil {
		return "", nil
	}
	return string(m[1]), nil
}

var dictionaryKey = regexp.MustCompile(`^\s*(?:'((?:\\.|[^'\\])*)'|"((?:\\.|[^"\\])*)")\s*:`)

// A line that is a brace, a blank, the file's own scaffolding, or the
// continuation of a value that ran onto a second line.
var notAKey = regexp.MustCompile(`^\s*($|//|[}\];]|window\.|ui\s*:|['"])`)

func dictionaryKeys(path string) (map[string]bool, error) {
	body, err := os.ReadFile(path) //nolint:gosec // a path from this tool's own glob
	if err != nil {
		return nil, err
	}

	keys := map[string]bool{}
	inComment := false

	for i, line := range strings.Split(string(body), "\n") {
		// Block comments are TRACKED rather than recognised line by line. The
		// header of every one of these files is a paragraph of prose, and its
		// middle lines look like nothing in particular — which is exactly what
		// the refusal below is there to shout about, so it has to know they are
		// inside a comment.
		if inComment {
			if strings.Contains(line, "*/") {
				inComment = false
			}
			continue
		}
		if before, after, found := strings.Cut(line, "/*"); found {
			// A comment that closes on its own line leaves whatever came before
			// it; one that does not opens the state above.
			if !strings.Contains(after, "*/") {
				inComment = true
			}
			line = before
		}

		if match := dictionaryKey.FindStringSubmatch(line); match != nil {
			keys[unescape(match[1]+match[2])] = true
			continue
		}

		// A LINE THIS CANNOT CLASSIFY IS AN ERROR, not something to skip. The
		// regex above is the whole of this tool's understanding of JavaScript,
		// and a dictionary written in a shape it does not recognise would be
		// quietly half-read — every key in the unread half reported missing, or
		// worse, not reported at all.
		if !notAKey.MatchString(line) {
			return nil, fmt.Errorf("check-interface: %s:%d: this line is neither a key nor "+
				"anything this tool recognises, so the dictionary cannot be read with any "+
				"confidence:\n  %s", path, i+1, strings.TrimSpace(line))
		}
	}
	return keys, nil
}

// unescape undoes what a JavaScript string literal escapes, for the two
// sequences these files actually contain.
func unescape(s string) string {
	return strings.NewReplacer(`\'`, `'`, `\"`, `"`, `\\`, `\`).Replace(s)
}

/*
withoutComments blanks a script's comments, leaving everything else where it was.

# THE DEFECT IT FIXES IS THIS TOOL DESCRIBING ITSELF

`ui/my/app/queue.js` explains, in a comment, that the scanner reads literal
calls only — and spelling that out in the obvious syntax made the example itself
an interface string. The tool asked for the Portuguese of an ellipsis. Any file
that documents this rule hits it, which is every file where somebody has just
learnt the rule the hard way.

# WHY A LEXER AND NOT A PATTERN

Because of `/`. In JavaScript it starts a comment, a regular expression or a
division, and only the tokens before it say which — `.replace(/&/g, …)` is in
the very file that found this. So the walk below tracks what it is inside:
code, a string of each of the three kinds, a regular expression, or a comment.

The regex-or-division question is answered by the last significant character, a
heuristic every syntax highlighter uses: after `(`, `,`, `=`, `:`, `[`, `!`, `&`,
`|`, `?`, `{`, `}`, `;` or a newline, a slash opens a pattern; after a name, a
number or a closing bracket, it divides.

# AND BEING WRONG HERE IS LOUD

That heuristic can be fooled, and the consequence is bounded on purpose: this
function only decides which bytes the scanner reads. Blank too much and a real
string goes missing, which fails as a dictionary entry nothing says. Blank too
little and a commented example is counted, which fails as a string with no
translation. Both stop a pull request with a sentence naming the string. There
is no arrangement of mistakes here that passes quietly, which is the property
worth having in a check.

Blanked rather than deleted, so that removing a comment cannot join two tokens
into one.
*/
func withoutComments(source string) string {
	out := make([]byte, 0, len(source))

	// The last character that was not whitespace, which is what decides whether
	// a slash opens a pattern or divides.
	var significant byte

	for i := 0; i < len(source); {
		c := source[i]

		switch {
		// ---------- a comment ----------
		case c == '/' && i+1 < len(source) && source[i+1] == '/':
			for i < len(source) && source[i] != '\n' {
				out = append(out, ' ')
				i++
			}

		case c == '/' && i+1 < len(source) && source[i+1] == '*':
			// The newlines are kept so that a line number, if this ever reports
			// one, still counts the same lines the file has.
			for i < len(source) {
				if source[i] == '\n' {
					out = append(out, '\n')
				} else {
					out = append(out, ' ')
				}
				if source[i] == '*' && i+1 < len(source) && source[i+1] == '/' {
					out = append(out, ' ')
					i += 2
					break
				}
				i++
			}

		// ---------- a string, of any of the three kinds ----------
		//
		// Kept as it is: a comment written inside a string is text, and this
		// tool's whole subject is text inside quotes.
		case c == '\'' || c == '"' || c == '`':
			quote := c
			out = append(out, c)
			i++
			for i < len(source) {
				if source[i] == '\\' && i+1 < len(source) {
					out = append(out, source[i], source[i+1])
					i += 2
					continue
				}
				out = append(out, source[i])
				if source[i] == quote {
					i++
					break
				}
				i++
			}
			significant = quote

		// ---------- a regular expression ----------
		case c == '/' && opensAPattern(significant):
			out = append(out, c)
			i++
			inClass := false
			for i < len(source) {
				if source[i] == '\\' && i+1 < len(source) {
					out = append(out, source[i], source[i+1])
					i += 2
					continue
				}
				out = append(out, source[i])
				switch source[i] {
				case '[':
					inClass = true
				case ']':
					inClass = false
				case '/':
					// A slash inside a character class is a literal one:
					// `[^/]` is not the end of the pattern.
					if !inClass {
						i++
						goto closed
					}
				case '\n':
					// A pattern cannot span lines. Something is being read
					// wrongly; stop rather than swallow the rest of the file.
					i++
					goto closed
				}
				i++
			}
		closed:
			significant = '/'

		default:
			out = append(out, c)
			if c != ' ' && c != '\t' && c != '\r' {
				significant = c
			}
			i++
		}
	}

	return string(out)
}

// opensAPattern answers the regex-or-division question from the character
// before the slash. A file that has said nothing yet — `significant` is zero —
// is at its start, where a slash cannot be dividing anything.
func opensAPattern(significant byte) bool {
	switch significant {
	case 0, '(', ',', '=', ':', '[', '!', '&', '|', '?', '{', '}', ';', '\n', '+', '-', '*', '%', '<', '>', '~', '^':
		return true
	}
	return false
}
