/*
check-figures holds a diagram to the palette it is drawn against.

	# A FIGURE DOES NOT BREAK, IT DISAPPEARS

	`CONTENT.md` says it plainly and said it with nothing behind it: *"The
	palette is this application's, and there is no check that it is. A token
	that does not exist resolves to nothing and the figure renders invisible."*
	It goes on to record that the thirteen figures of `web-fundamentals` lesson
	one were drawn against a different palette and were one command away from
	shipping exactly like that.

	That is the worst failure shape a check can be written for. A stylesheet
	that will not parse takes a rule down and somebody notices; `var(--phosfor)`
	takes ONE SHAPE out of ONE drawing, in a document that still renders, still
	validates, still passes every other check in this repository — and the
	reviewer reading the diff sees a colour name that looks like the others.

	# THE TOKENS ARE READ OUT OF THE CSS AND NEVER LISTED HERE

	There are two palettes: the nine in `ui/assets/base.css`, which a document
	is drawn with, and the twenty-seven `--term-*` in `ui/assets/terminal.css`,
	which a captured terminal is drawn with. Both are parsed. A constant here
	would be a third statement of a fact two files already make, and it would
	disagree with them the first time somebody adds a token — which is the
	arrangement `term-capture`'s own `palette.go` refuses in its opening comment
	and `check-design` refuses for the sheet format.

	# WHAT IT DOES NOT FAIL ON, AND WHY THAT IS SAID OUT LOUD

	A literal colour inside a figure is not refused, because 91 of them are
	CORRECT: `tools/term-capture` writes a fixed value for text on a captured
	ground, and `terminal.css` carries the paragraph explaining which one and at
	what contrast. A capture is not a drawing, and this tool cannot tell them
	apart from the outside — so it counts them, prints the count, and says that
	it did not judge them. A check that quietly skipped them would read as a
	check that found nothing.
*/
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// figure is the JSON inside a ```schooling-figure fence, as `CONTENT.md`
// specifies it: an inline `svg`, or an `image` for a photograph or a
// screenshot, and a caption either way.
type figure struct {
	SVG     string `json:"svg"`
	Image   string `json:"image"`
	Alt     string `json:"alt"`
	Caption string `json:"caption"`

	/* Same is the labels of a TRANSLATED figure that are the same word in that
	   language, written down because somebody decided rather than because
	   nobody looked.

	   IT IS THE `check-interface` RULE, ONE LAYER IN: *a string that is the
	   same in both languages gets an entry mapping to itself*. Here the entry
	   lives on the translated figure and not in a list per school, because a
	   list is how this gets weakened — one `the row` added once and every
	   figure in the catalogue may carry it in English. A figure states its own,
	   and an entry that matches nothing fails. */
	Same []string `json:"same,omitempty"`
}

var (
	fence   = regexp.MustCompile("(?s)```schooling-figure\n(.*?)\n```")
	uses    = regexp.MustCompile(`var\(\s*--([a-zA-Z0-9-]+)`)
	defines = regexp.MustCompile(`(?m)^\s*--([a-zA-Z0-9-]+)\s*:`)

	// A colour written into the drawing rather than taken from the palette.
	// Counted and reported; see the package comment for why it is not refused.
	literal = regexp.MustCompile(`(?:fill|stroke|stop-color)="(#[0-9a-fA-F]{3,8}|rgba?\([^)]*\))"`)

	// Text, and the token it is painted in.
	inked = regexp.MustCompile(`<(?:text|tspan)[^>]*fill="var\(\s*--([a-zA-Z0-9-]+)`)

	// One drawn label: its attributes, and what it says.
	drawn  = regexp.MustCompile(`(?s)<text([^>]*)>(.*?)</text>`)
	markup = regexp.MustCompile(`<[^>]*>`)
	spaces = regexp.MustCompile(`\s+`)
	speaks = regexp.MustCompile(`aria-label="([^"]*)"`)
	letter = regexp.MustCompile(`\p{L}`)
)

/*
surfaces are the tokens that are a ground or a hairline, never an ink.

	NOT A MATTER OF TASTE, AND MEASURED RATHER THAN ASSUMED. Against the two
	things a figure is ever drawn on, in both themes: `wire` reaches between
	1.35 and 1.49 to one, and `scan` between 1.09 and 1.24. AA asks for 4.5. A
	label painted in either is invisible everywhere, and it is invisible in a
	way no other check here can see — `check-figures` asks whether a token
	exists and `axe` never loads the page, because these live inside a JSON
	string in a Markdown file.

	It caught the author of this rule: the FALSE box of lesson 1's three-valued
	logic figure was drawn with `wire` as both its border and its text, which is
	the whole mistake in one line — a border colour and an ink are different
	jobs and the palette names them apart.

	`ink` AND `panel` ARE DELIBERATELY NOT HERE. Dark text on a bright ground is
	a real thing and a captured terminal does exactly that, with `term-capture`
	measuring the pair it writes. A rule against them would refuse correct
	drawings, which is how a check teaches people to ignore it.
*/
var surfaces = map[string]string{
	"wire": "a hairline, at most 1.49:1 against a panel",
	"scan": "a faint ground, at most 1.24:1 against a panel",
}

func main() {
	content, styles := "content", []string{"ui/assets/base.css", "ui/assets/terminal.css"}
	if len(os.Args) > 1 {
		content = os.Args[1]
	}

	palette, problems := readPalette(styles)
	figures, literals, found := readFigures(content, palette)
	problems = append(problems, found...)

	pairs, translated := readTranslations(content)
	problems = append(problems, translated...)

	fmt.Printf("%d figure(s) against %d palette token(s) from %s, and %d of them against their "+
		"own translation\n", figures, len(palette), strings.Join(styles, " and "), pairs)
	if literals > 0 {
		fmt.Printf("%d colour(s) written into a drawing rather than taken from the palette. "+
			"COUNTED AND NOT JUDGED: a captured terminal carries fixed values on purpose — "+
			"`term-capture` writes them and `terminal.css` says at what contrast — and this "+
			"tool cannot tell WHICH LITERAL belongs to which from the outside. (It can name a "+
			"capture: one is painted in the `--term-*` palette, which is how the translation "+
			"pass below leaves them alone. What it cannot do is attribute a single "+
			"`fill=\"#…\"` to the capture around it rather than to a drawing.)\n", literals)
	}

	if len(problems) > 0 {
		fmt.Println("\nfigures that would render wrongly:")
		for _, p := range problems {
			fmt.Println(" - " + p)
		}
		fmt.Printf("\n%d problem(s). A figure with a token nothing defines does not break: it "+
			"renders invisible, in a document that still passes every other check here.\n",
			len(problems))
		os.Exit(1)
	}
	fmt.Println("every figure names a token that exists, says what it draws, and its " +
		"translations say it in their own language")
}

// readPalette is every custom property the two stylesheets define, which is the
// only list of them this repository has.
func readPalette(styles []string) (map[string]bool, []string) {
	palette := map[string]bool{}
	var problems []string
	for _, f := range styles {
		body, err := os.ReadFile(f) //nolint:gosec // a path this tool declares
		if err != nil {
			problems = append(problems, fmt.Sprintf(
				"%s cannot be read, so there is no palette to check anything against: %v", f, err))
			continue
		}
		for _, m := range defines.FindAllStringSubmatch(string(body), -1) {
			palette[m[1]] = true
		}
	}
	if len(palette) == 0 {
		problems = append(problems, "no custom property was found in any stylesheet — every "+
			"figure would be reported, which is the shape of a broken checker rather than a "+
			"broken catalogue")
	}
	return palette, problems
}

/*
readFigures walks every prose file, including the translations.

	THE TRANSLATIONS ARE READ TOO, and that is the half most worth having. A
	figure is drawn once and its translation carries the same drawing with a
	translated caption and aria-label — so a token broken while translating is
	a diagram that disappears for the Portuguese reader and nobody else, in a
	file the English reviewer had no reason to open. It is the same failure
	`check-exercises` found when it started reading both languages.
*/
func readFigures(dir string, palette map[string]bool) (figures, literals int, problems []string) {
	files, err := filepath.Glob(filepath.Join(dir, "*", "courses", "*", "lessons", "*", "*.md"))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	sort.Strings(files)

	for _, f := range files {
		body, err := os.ReadFile(f) //nolint:gosec // a path from this tool's own glob
		if err != nil {
			problems = append(problems, fmt.Sprintf("%s: %v", f, err))
			continue
		}
		for i, m := range fence.FindAllStringSubmatch(string(body), -1) {
			at := fmt.Sprintf("%s figure %d", where(f), i+1)
			figures++

			var fig figure
			if err := json.Unmarshal([]byte(m[1]), &fig); err != nil {
				problems = append(problems, fmt.Sprintf(
					"%s is not JSON, so the renderer has nothing to draw and the fence shows "+
						"as a block of code: %v", at, err))
				continue
			}

			n, found := check(at, fig, palette)
			literals += n
			problems = append(problems, found...)
		}
	}
	return figures, literals, problems
}

// check is one figure, and every rule in it is a way for a drawing to reach a
// student as something other than a drawing.
func check(at string, fig figure, palette map[string]bool) (literals int, problems []string) {
	switch {
	case fig.SVG == "" && fig.Image == "":
		problems = append(problems, fmt.Sprintf(
			"%s carries neither `svg` nor `image`, so there is nothing to draw", at))
	case fig.SVG != "" && fig.Image != "":
		problems = append(problems, fmt.Sprintf(
			"%s carries both `svg` and `image` and the renderer draws one of them — which one "+
				"is a fact about the renderer rather than about the figure", at))
	}

	/* A CAPTION AND A LABEL ARE NOT DECORATION. This is an education product,
	   so a diagram a screen reader cannot announce is not a degraded experience
	   — it is a student who cannot study the section (X-05). `aria-label` is
	   what the reader says INSTEAD of the drawing, and a caption is what every
	   reader gets under it. */
	if strings.TrimSpace(fig.Caption) == "" {
		problems = append(problems, fmt.Sprintf("%s has no caption", at))
	}
	if fig.SVG != "" && !strings.Contains(fig.SVG, "aria-label") {
		problems = append(problems, fmt.Sprintf(
			"%s is a drawing with no `aria-label`, so a screen reader announces an image and "+
				"nothing about it — which on a diagram is the whole of what it said", at))
	}
	if fig.Image != "" && strings.TrimSpace(fig.Alt) == "" {
		problems = append(problems, fmt.Sprintf("%s is an image with no `alt`", at))
	}

	// AND IT HAS TO BE AN INK. A ground or a hairline used as text is invisible,
	// in both themes, against everything a figure is drawn on.
	said := map[string]bool{}
	for _, m := range inked.FindAllStringSubmatch(fig.SVG, -1) {
		why, ground := surfaces[m[1]]
		if !ground || said[m[1]] {
			continue
		}
		said[m[1]] = true
		problems = append(problems, fmt.Sprintf(
			"%s paints text in `--%s`, which is %s — the words are there and nobody can read "+
				"them, in either theme", at, m[1], why))
	}

	// THE TOKEN HAS TO EXIST. This is the rule the tool was written for.
	seen := map[string]bool{}
	for _, m := range uses.FindAllStringSubmatch(fig.SVG, -1) {
		if palette[m[1]] || seen[m[1]] {
			continue
		}
		seen[m[1]] = true
		problems = append(problems, fmt.Sprintf(
			"%s asks for `--%s`, which no stylesheet defines — it resolves to nothing and "+
				"that shape renders invisible, in a figure that is otherwise perfect%s",
			at, m[1], nearest(m[1], palette)))
	}

	return len(literal.FindAllString(fig.SVG, -1)), problems
}

/*
nearest names the token somebody probably meant.

	A TYPO IS THE WHOLE POPULATION OF THIS FAILURE. Nobody invents a colour name
	from nothing; they write `phosfor` for `phosphor`, `papper` for `paper`, or
	`--term-gray` for the `--term-grey` this repository spells the other way.
	Printing the name that is one small edit away turns a message somebody has
	to go and investigate into one they can act on while reading it.
*/
func nearest(token string, palette map[string]bool) string {
	best, distance := "", 4 // far enough apart and it is a different word
	for known := range palette {
		if d := edits(token, known); d < distance {
			best, distance = known, d
		}
	}
	if best == "" {
		return ""
	}
	return fmt.Sprintf(" — did you mean `--%s`?", best)
}

// edits is the Levenshtein distance, which is the whole of what `nearest` needs
// and is shorter than any way of avoiding writing it.
func edits(a, b string) int {
	prev := make([]int, len(b)+1)
	curr := make([]int, len(b)+1)
	for j := range prev {
		prev[j] = j
	}
	for i := 1; i <= len(a); i++ {
		curr[0] = i
		for j := 1; j <= len(b); j++ {
			cost := 1
			if a[i-1] == b[j-1] {
				cost = 0
			}
			curr[j] = min(prev[j]+1, min(curr[j-1]+1, prev[j-1]+cost))
		}
		prev, curr = curr, prev
	}
	return prev[len(b)]
}

// where names a figure by its course, its lesson and its file, which is enough
// to open it and short enough to read a column of.
func where(f string) string {
	parts := strings.Split(filepath.ToSlash(f), "/")
	for i, p := range parts {
		if p == "lessons" && i > 0 && i+2 < len(parts) {
			return parts[i-1] + "/" + parts[i+1] + "/" + parts[i+2]
		}
	}
	return f
}

/*
readTranslations asks whether a translated figure was translated.

	# A LABEL LEFT IN ENGLISH IS INVISIBLE TO EVERY OTHER CHECK HERE

	Each of them reads ONE file. `validate-content` reads the shape,
	`check-figures` above reads the palette of a drawing, `figure-contrast`
	reads what can be read, `figure-fit` reads what fits. None of them has ever
	held two files side by side — so a Portuguese lesson drawing *"the row on
	disk"* and *"one lookup per row"* passes all of them, and reads perfectly
	well to anybody who happens to know English.

	It is the same failure the dictionaries were given a tool for and the same
	remedy: `check-interface` fails on a string with no translation AND on a
	translation nothing says any more. This is that, one layer in, where the
	strings are drawn instead of written.

	# WHAT IS ASKED ABOUT IS DECIDED BY THE DRAWING, NOT BY A GUESS

	Most labels in these figures are SQL, plan nodes, header names, file paths
	and table rows — identical in every language, correctly. A check that
	reported them would report 238 things of which some thirty are real, and a
	check that cries wolf teaches whoever reads it to skip the output that would
	one day name a real one; this repository says exactly that about the
	console's dictionary test, and measured it.

	So the discriminator is one the author already wrote down: **code is drawn
	in the mono face and prose in the sans face.** `IBM Plex Sans` is the
	question; `IBM Plex Mono` is not asked about at all. That is a fact stated
	in the figure rather than a heuristic applied to it, and it takes the
	question from 238 to 86 with every real one still in.

	Two more exemptions, both mechanical rather than decided:

	  - **A capture is not a drawing.** `term-capture` writes the bytes a real
	    terminal produced, painted with the `--term-*` palette, and those bytes
	    are the same in every language BY CONSTRUCTION. The tokens name it, so
	    this is structural and not a judgement about content.
	  - **A label with no letter in it cannot be translated** — `1`, `×`, a
	    step number. Nothing to decide.

	# WHAT IT CANNOT SEE, SAID OUT LOUD

	A label drawn in the mono face that IS prose. The rule buys its silence with
	a class of miss, and the miss is in the safe direction — a word goes
	unasked, rather than a correct figure being reported until somebody stops
	reading the output. The way to close it is the lesson's own code fences: a
	word that appears in one is code and a word that does not is not. That is
	the next version, if this one earns it.
*/
func readTranslations(dir string) (pairs int, problems []string) {
	files, err := filepath.Glob(filepath.Join(dir, "*", "courses", "*", "lessons", "*", "*.md"))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	sort.Strings(files)

	for _, source := range files {
		// `<name>.md` is the source; `<name>.<locale>.md` is a translation of
		// it. A file with a locale in its own name is never a source.
		base := strings.TrimSuffix(filepath.Base(source), ".md")
		if strings.Contains(base, ".") {
			continue
		}
		for _, translated := range translationsOf(source, base) {
			n, found := comparable(source, translated)
			pairs += n
			problems = append(problems, found...)
		}
	}
	return pairs, problems
}

// translationsOf is every `<name>.<locale>.md` beside `<name>.md`.
func translationsOf(source, base string) []string {
	matches, err := filepath.Glob(filepath.Join(filepath.Dir(source), base+".*.md"))
	if err != nil {
		return nil
	}
	sort.Strings(matches)
	return matches
}

// comparable reads both files and walks their figures in step.
func comparable(source, translated string) (pairs int, problems []string) {
	from, err := figuresIn(source)
	if err != nil {
		return 0, []string{err.Error()}
	}
	into, err := figuresIn(translated)
	if err != nil {
		return 0, []string{err.Error()}
	}

	/* A TRANSLATION CARRIES THE SAME DRAWINGS. A different number of them is
	   not a translation question — it is a figure added to one language and not
	   the other, and every comparison below would be against the wrong figure. */
	if len(from) != len(into) {
		return 0, []string{fmt.Sprintf(
			"%s draws %d figure(s) and %s draws %d — they are the same drawings in two "+
				"languages, so one of them has gained or lost one",
			where(source), len(from), where(translated), len(into))}
	}

	locale := localeOf(translated)
	for i := range from {
		at := fmt.Sprintf("%s figure %d [%s]", where(source), i+1, locale)
		problems = append(problems, untranslated(at, from[i], into[i])...)
		pairs++
	}
	return pairs, problems
}

// localeOf reads `pt` out of `frames.pt.md`.
func localeOf(path string) string {
	parts := strings.Split(filepath.Base(path), ".")
	if len(parts) < 3 {
		return "?"
	}
	return parts[len(parts)-2]
}

func figuresIn(path string) ([]figure, error) {
	body, err := os.ReadFile(path) //nolint:gosec // a path from this tool's own glob
	if err != nil {
		return nil, fmt.Errorf("%s: %w", where(path), err)
	}
	var out []figure
	for _, m := range fence.FindAllStringSubmatch(string(body), -1) {
		var fig figure
		// A fence that is not JSON is reported by the pass above; here it is one
		// figure with nothing in it, so the two sides still line up by position.
		_ = json.Unmarshal([]byte(m[1]), &fig)
		out = append(out, fig)
	}
	return out, nil
}

// untranslated is one figure against its translation.
func untranslated(at string, from, into figure) (problems []string) {
	decided := map[string]bool{}
	for _, s := range into.Same {
		decided[s] = true
	}
	met := map[string]bool{}

	ask := func(what, english, other string) {
		english, other = strings.TrimSpace(english), strings.TrimSpace(other)
		if english == "" || english != other {
			return
		}
		if decided[english] {
			met[english] = true
			return
		}
		problems = append(problems, fmt.Sprintf(
			"%s: the %s is still %q. If that IS the word in this language, say so in the "+
				"translated figure's `same` — an entry there says somebody decided, where an "+
				"absence says nobody looked", at, what, english))
	}

	/* THE THREE THAT ARE ALWAYS PROSE, asked with no filter at all. A caption
	   is a sentence under the drawing, an `alt` is what an image is announced
	   as, and an `aria-label` is what a screen reader says INSTEAD of a
	   diagram — the whole figure, for the reader who cannot see it. */
	ask("caption", from.Caption, into.Caption)
	ask("alt text", from.Alt, into.Alt)
	ask("aria-label", spoken(from.SVG), spoken(into.SVG))

	// A capture is bytes a real terminal produced. See the note above.
	if strings.Contains(from.SVG, "var(--term-") {
		return problems
	}

	english, translated := prose(from.SVG), prose(into.SVG)
	if len(english) != len(translated) {
		problems = append(problems, fmt.Sprintf(
			"%s draws %d label(s) in the prose face and its translation draws %d, so they "+
				"cannot be compared one to one — a translation redraws nothing",
			at, len(english), len(translated)))
		return problems
	}
	for i := range english {
		ask("label", english[i], translated[i])
	}

	/* AND AN ENTRY NOTHING SAYS ANY MORE. A `same` left behind by a rewritten
	   label reads as a decision somebody made about this figure and is about a
	   figure that no longer exists — which is `check-interface`'s stale entry,
	   and it is why that tool checks both directions. */
	for _, s := range into.Same {
		if !met[s] {
			problems = append(problems, fmt.Sprintf(
				"%s: `same` carries %q and no label of this figure says it — an entry left "+
					"behind by a rewrite reads as current", at, s))
		}
	}
	return problems
}

// spoken is the sentence a screen reader is given instead of the drawing.
func spoken(svg string) string {
	if m := speaks.FindStringSubmatch(svg); m != nil {
		return m[1]
	}
	return ""
}

/*
prose is every label drawn in the sans face, in order.

	The mono face is code and is not asked about; a label with no letter in it
	cannot be translated. Both are named in the note above `readTranslations`.
*/
func prose(svg string) []string {
	var out []string
	for _, m := range drawn.FindAllStringSubmatch(svg, -1) {
		if !strings.Contains(m[1], "Plex Sans") {
			continue
		}
		text := strings.TrimSpace(spaces.ReplaceAllString(markup.ReplaceAllString(m[2], ""), " "))
		if text == "" || !letter.MatchString(text) {
			continue
		}
		out = append(out, text)
	}
	return out
}
