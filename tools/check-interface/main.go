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
	"os"
	"path/filepath"
	"regexp"
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
	dictionaries, err := filepath.Glob(filepath.Join(dir, "assets", "i18n-*.js"))
	if err != nil {
		return nil, 0, err
	}
	if len(dictionaries) == 0 {
		return nil, 0, fmt.Errorf("check-interface: no dictionary in %s — the interface claims to "+
			"speak more than one language and there is nothing to speak it with", dir)
	}
	sort.Strings(dictionaries)

	for _, path := range dictionaries {
		language := strings.TrimSuffix(strings.TrimPrefix(filepath.Base(path), "i18n-"), ".js")

		entries, err := dictionaryKeys(path)
		if err != nil {
			return nil, 0, err
		}

		for _, s := range said {
			if !entries[s] {
				problems = append(problems, fmt.Sprintf(
					"%s: no %s for %q — it will be shown in English to everybody reading in %s, "+
						"and nothing else will look wrong", filepath.Base(path), language, s, language))
			}
		}

		saidSet := map[string]bool{}
		for _, s := range said {
			saidSet[s] = true
		}
		for entry := range entries {
			if !saidSet[entry] {
				problems = append(problems, fmt.Sprintf(
					"%s: %q is translated and nothing says it any more — a stale entry reads as "+
						"current, which is worse than a missing one", filepath.Base(path), entry))
			}
		}
	}

	sort.Strings(problems)
	return problems, len(said), nil
}

/* ---------- what the interface says ---------- */

// txtCall finds `txt('…')` and `txt("…")`. A call with anything else in it — a
// variable, a template literal — is not a fixed string and cannot be checked
// against a dictionary; `trouble()` is the one place that does it deliberately,
// and the package comment says why.
// The two quotes are written out rather than captured and back-referenced,
// because Go's regexp has no back-references at all — RE2 trades them for the
// guarantee that a pattern cannot take exponential time.
var txtCall = regexp.MustCompile(`\btxt\(\s*(?:'((?:\\.|[^'\\])*)'|"((?:\\.|[^"\\])*)")\s*\)`)

func stringsSaid(dir string) ([]string, error) {
	found := map[string]bool{}

	scripts, err := filepath.Glob(filepath.Join(dir, "assets", "*.js"))
	if err != nil {
		return nil, err
	}
	for _, path := range scripts {
		if strings.HasPrefix(filepath.Base(path), "i18n-") {
			continue // a dictionary quotes every string; it does not say them
		}
		body, err := os.ReadFile(path) //nolint:gosec // a path from this tool's own glob
		if err != nil {
			return nil, err
		}
		for _, match := range txtCall.FindAllStringSubmatch(string(body), -1) {
			found[unescape(match[1]+match[2])] = true // exactly one of the two matched
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
