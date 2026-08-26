// Command check-css keeps this repository's stylesheets from laying out the
// copied one's elements.
//
// # THE FAILURE IT EXISTS TO CATCH
//
// `base.css` and `portal.css` came from `portal-frontend` byte for byte, and
// they are loaded first. That repository has since been deleted, so this tool is
// no longer the second line of defence behind a diff — it is the only one. `exercises.css` and `app.css` are this repository's and are
// loaded after them. So a rule written here against a class name the copied
// stylesheet already uses does not conflict, does not warn and does not appear
// in any diff: it simply WINS, on every element of the copied markup carrying
// that name, on screens the change was never about.
//
// It has happened twice. The first time was a whole retired stylesheet whose
// vocabulary — `.lessons`, `.node`, `.graph`, `.option`, `.question`, `.search`
// — outlived the screens it was written for, and was found by putting the two
// interfaces side by side. The second was three lines: an enrolment list styled
// as `.steps`, which in `portal.css` is the row of section tabs at the top of a
// lesson. The row became a column, on every lesson in the platform, and the
// pull request that did it touched nothing near a lesson.
//
// Neither was visible in a review of the diff. That is what a tool is for.
//
// # WHAT IT CHECKS, AND WHY NOT SIMPLY THE NAMES
//
// The obvious check — no class of theirs may be re-declared here — is the wrong
// one, and running it says so: it fails on forty rules that are the entire
// reason `app.css` exists. That file overrides the copied stylesheet ON PURPOSE,
// once per accessibility defect, by naming their class and setting a colour.
//
// What separates those from the defect is the rule `app.css`'s own header
// states and did not keep: THERE IS NO LAYOUT IN THIS FILE. A colour on their
// class fixes their element and moves nothing. A `display` or a `gap` on their
// class re-lays-out their screen. So the check is:
//
//	a rule that sets a layout property, on a class the copied stylesheet
//	declares, with nothing of ours in the selector to hold it to our screen.
//
// The last clause is the way out and it is the shape a deliberate reach already
// has: `.view-account .on` names the screen, so it cannot leave it. `.steps`
// named nothing, so it went everywhere.
//
// # AND THE ONE THAT MEANS TO
//
// `deliberate` below is for a layout property that is itself the accessibility
// fix — a target six pixels short of WCAG 2.2's 24 by 24 is corrected with a
// `height` and nothing else will do. One line each, with the argument. An entry
// that stops being needed fails too: an exception that outlived what it excused
// reads as current, which is worse than never having been written down.
//
//	check-css [ui directory]     (default: ui/)
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// THE LOAD ORDER, as `ui/index.html` declares it. A stylesheet can only be
// shadowed by one that comes after it, so this order is the whole of the
// relationship: everything in `copied` is what `ours` must not lay out.
//
// THE CONSOLE IS NOT HERE, and it was, until running it said why. It loads
// `base.css` too and its stylesheet re-declares nineteen of that file's rules —
// `.search`, `.chips`, `.tag`, `.eyebrow`, the theme toggle's two icons — every
// one of them a `display` or a `gap`. None of it is this defect. There is no
// copied MARKUP on that host: every element on a console screen is written by
// `internal/console/ui/app`, and the study interface's `.search` and the
// console's are never on the same page. What is being restyled there is the
// console's own element, in the shell's vocabulary, on purpose.
//
// The failure this tool exists for needs both halves — their stylesheet AND
// their markup — and only one host has them.
var host = struct {
	copied []string // theirs, loaded first
	ours   []string // this repository's, in load order
}{
	copied: []string{"assets/base.css", "assets/portal.css"},
	ours:   []string{"assets/exercises.css", "assets/app.css"},
}

// A LAYOUT PROPERTY IS ONE THAT MOVES SOMETHING ELSE. Colour, weight, opacity
// and the rest change the element and stop there; these change where its
// siblings end up, which is how a rule meant for one screen is felt on another.
//
// `overflow` is in the list because a copied element given a scrollbar hides
// its own content — that is the defect this platform already met on the lesson
// tabs, from the other direction.
var layout = []string{
	"display", "position", "float", "clear", "box-sizing", "columns",
	"top", "right", "bottom", "left", "inset",
	"width", "height",
	"margin", "padding", "gap",
	"flex", "grid", "order",
	"align-", "justify-", "place-",
	"overflow",
}

// A layout property that IS the accessibility fix. Keyed by class and property.
var deliberate = map[string]string{
	"ord-arrow height": "24 by 18 is under WCAG 2.2's 24 by 24 target, and that target is " +
		"the keyboard and pointer path for the ordering question — six pixels, on the axis " +
		"they were short",
}

func main() {
	dir := "ui"
	if len(os.Args) > 1 {
		dir = os.Args[1]
	}

	problems, rules, err := check(dir, deliberate)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	if len(problems) > 0 {
		for _, p := range problems {
			fmt.Fprintln(os.Stderr, p)
		}
		fmt.Fprintf(os.Stderr, "\n%d problem(s)\n", len(problems))
		os.Exit(1)
	}
	fmt.Printf("%d of our rules, and none of them lays out an element of theirs\n", rules)
}

func check(dir string, allowedTo map[string]string) ([]string, int, error) {
	var problems []string
	ours := 0
	used := map[string]bool{}

	// Everything loaded before ours, and which file each name came from — the
	// message is only useful if it says where to go and look.
	theirs := map[string]string{}
	for _, name := range host.copied {
		rules, err := rulesIn(filepath.Join(dir, name))
		if err != nil {
			return nil, ours, err
		}
		for _, r := range rules {
			for _, c := range r.classes {
				if _, seen := theirs[c]; !seen {
					theirs[c] = name
				}
			}
		}
	}

	for _, name := range host.ours {
		rules, err := rulesIn(filepath.Join(dir, name))
		if err != nil {
			return nil, ours, err
		}
		ours += len(rules)

		for _, r := range rules {
			moved := r.moves()
			if len(moved) == 0 {
				continue
			}
			// One class of ours anywhere in the selector is enough: it cannot
			// match outside the markup that carries it.
			held := false
			var reached []string
			for _, c := range r.classes {
				if _, copied := theirs[c]; copied {
					reached = append(reached, c)
				} else {
					held = true
				}
			}
			if held || len(reached) == 0 {
				continue
			}

			for _, c := range reached {
				for _, p := range moved {
					key := c + " " + p
					if _, allowed := allowedTo[key]; allowed {
						used[key] = true
						continue
					}
					problems = append(problems, fmt.Sprintf(
						"%s:%d: `%s` sets `%s` on `.%s`, which is %s's — that lays out THEIR "+
							"elements, everywhere the copied markup uses the name. Put a class "+
							"of ours in the selector, or rename it; if the property is itself "+
							"the accessibility fix, add it to `deliberate` with the argument",
						name, r.line, r.selector, p, c, theirs[c]))
				}
			}
		}
	}

	for key := range allowedTo {
		if !used[key] {
			problems = append(problems, fmt.Sprintf(
				"`%s` is listed as a deliberate layout override and no rule needs it any more — "+
					"either the rule went away or the copied stylesheet did; take the line out", key))
		}
	}

	sort.Strings(problems)
	return problems, ours, nil
}

type rule struct {
	selector string
	line     int
	classes  []string
	body     string
}

// The properties this rule sets that move something. Prefix-matched, so
// `margin` catches `margin-top` and `flex` catches `flex-direction`.
func (r rule) moves() []string {
	var out []string
	for _, d := range strings.Split(r.body, ";") {
		name, _, ok := strings.Cut(d, ":")
		name = strings.ToLower(strings.TrimSpace(name))
		if !ok || name == "" || strings.HasPrefix(name, "--") {
			continue
		}
		for _, p := range layout {
			if name == p || strings.HasPrefix(name, p) {
				out = append(out, name)
				break
			}
		}
	}
	return out
}

// The comments go first, then the file is walked: a prelude is the text from
// the last `{`, `}` or `;` up to the next `{`, and a body is what follows it.
// Class names are read from preludes and nothing else, which is what keeps
// `font-size:.68rem` and `transition:color .15s` out of the answer — and
// pattern-matching the whole file for `.name` is exactly the hand-rolled
// scanner that is subtly wrong for a year.
func rulesIn(path string) ([]rule, error) {
	b, err := os.ReadFile(path) //nolint:gosec // a path from this tool's own list of stylesheets
	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}

	// Blanked rather than removed, so the line numbers still point at the file.
	css := comments.ReplaceAllStringFunc(string(b), func(c string) string {
		return strings.Repeat("\n", strings.Count(c, "\n"))
	})

	var out []rule
	start, depth := 0, 0
	for i, r := range css {
		switch r {
		case '{':
			prelude := strings.TrimSpace(css[start:i])
			depth++
			// `@media`, `@supports` and friends open a block whose prelude is a
			// condition, not a selector. Their CONTENTS are selectors and are
			// reached by the walk, since the next prelude starts after this `{`.
			if strings.HasPrefix(prelude, "@") || prelude == "" {
				start = i + 1
				continue
			}
			body := css[i+1:]
			if end := strings.IndexByte(body, '}'); end >= 0 {
				body = body[:end]
			}
			var classes []string
			seen := map[string]bool{}
			for _, m := range className.FindAllStringSubmatch(prelude, -1) {
				if !seen[m[1]] {
					seen[m[1]] = true
					classes = append(classes, m[1])
				}
			}
			if len(classes) > 0 {
				out = append(out, rule{
					selector: strings.Join(strings.Fields(prelude), " "),
					line:     1 + strings.Count(css[:i], "\n"),
					classes:  classes,
					body:     body,
				})
			}
			start = i + 1
		case '}':
			depth--
			start = i + 1
		case ';':
			start = i + 1
		}
	}

	return out, nil
}

var (
	comments  = regexp.MustCompile(`(?s)/\*.*?\*/`)
	className = regexp.MustCompile(`\.([A-Za-z_][A-Za-z0-9_-]*)`)
)
