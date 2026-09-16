// Command validate-content is the reviewer.
//
// THERE IS NO HUMAN ONE. The material is written by a machine, and what stands
// between a wrong answer key and a student is this and nothing else (C-14). So
// it runs on every pull request, over the files, and it refuses — it does not
// warn, and it has no flag that makes it lenient.
//
// IT REPORTS EVERYTHING AND THEN FAILS. A checker that stops at the first
// problem turns fixing a catalogue into a sequence of runs, each teaching one
// fact. The same argument as config, and the same as the loader it calls.
//
//	validate-content [directory]     (default: content/)
//
// An absent directory is not a failure. The system is finished before any
// content is written, so "there is nothing to check yet" is the expected answer
// for most of this project's life — and a check that failed on it would be
// turned off long before the first course arrived.
package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/codeschool-ing/schooling/internal/catalog"
	"github.com/codeschool-ing/schooling/internal/grade"
	"github.com/codeschool-ing/schooling/ui"
)

func main() {
	root := "content"
	if len(os.Args) > 1 {
		root = os.Args[1]
	}

	problems, schools, err := check(root)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	for _, p := range problems {
		fmt.Fprintln(os.Stderr, " -", p)
	}

	switch {
	case len(problems) > 0:
		fmt.Fprintf(os.Stderr, "\n%d problem(s) across %d school(s). "+
			"Nothing here is a warning: each one is something a student would meet.\n",
			len(problems), schools)
		os.Exit(1)
	case schools == 0:
		fmt.Printf("%s holds no schools yet — the system is finished before the content is "+
			"written, so this is the expected answer for now\n", root)
	default:
		fmt.Printf("%d school(s), nothing to report\n", schools)
	}
}

// checkKeys runs every exercise's own answer key back through the grader that
// will judge a student's.
//
// A QUESTION THAT CANNOT BE ANSWERED CORRECTLY passes every shape check there
// is: a quiz with two correct choices, an ordering with one item, a cloze whose
// accepted set is empty once normalised. It reaches a student as a question
// they cannot get right however well they know the material — and with no human
// reviewer, this is the only thing between the two.
//
// A type with no grader yet is reported rather than skipped. `code` and
// `expected-output` need a sandbox; until there is one, a question of either
// type cannot be checked, and saying so on every run is the point. Silence
// would read as a pass.
func checkKeys(school string, s *catalog.School) []error {
	var problems []error

	check := func(where string, exercises []catalog.Exercise) {
		for _, e := range exercises {
			if err := grade.CheckKey(e.Type, e.Raw); err != nil {
				problems = append(problems, fmt.Errorf("%s: %s/%s: %w", school, where, e.ID, err))
			}
		}
	}

	for _, course := range s.Courses {
		for _, lesson := range course.Loaded {
			check(course.ID+"/"+lesson.ID, lesson.Exercises)
		}
		check(course.ID+"/exam", course.Exam)
	}
	for _, track := range s.Tracks {
		check(track.ID+"/exam", track.Exam)
	}
	return problems
}

// servedFonts answers the font families the interface actually ships.
//
// IT READS THE EMBED AND NOT A PATH, so this says the same thing wherever the
// tool is run from, and so that "the app serves it" means the bytes that go
// into the binary rather than a file that happens to sit next to the checker.
func servedFonts() (map[string]bool, error) {
	body, err := fs.ReadFile(ui.Files, "assets/fonts/fonts.css")
	if err != nil {
		return nil, fmt.Errorf("reading the interface's font faces: %w", err)
	}
	families := map[string]bool{}
	for _, m := range declaresFamily.FindAllStringSubmatch(string(body), -1) {
		families[strings.ToLower(m[1])] = true
	}
	if len(families) == 0 {
		return nil, fmt.Errorf("the interface's stylesheet declares no font faces at all, " +
			"which cannot be right and would let every figure below pass")
	}
	return families, nil
}

var (
	declaresFamily = regexp.MustCompile(`(?i)font-family:\s*'([^']+)'`)
	declaresRange  = regexp.MustCompile(`(?i)unicode-range:\s*([^;]+);`)
	faceOf         = regexp.MustCompile(`(?s)@font-face\s*\{.*?\}`)

	/* THE BACKSLASH IS NOT OPTIONAL DECORATION, it is the whole reason the first
	   version of this check passed on the very files it was written for. A
	   figure's SVG is a STRING inside the JSON of a `schooling-figure` fence, so
	   in the file the attribute reads `font-family=\"Archivo, sans-serif\"` —
	   every quote escaped. A pattern expecting a bare quote matches nothing, and
	   a check that matches nothing reports nothing, which is indistinguishable
	   from a clean run. It was caught by putting the defect back and watching
	   this stay silent. */
	namesFamily = regexp.MustCompile(`(?i)font-family=\\?"([^\\"]*)`)
)

// checkFigureFonts holds a drawing's lettering to the fonts the app has.
//
// # NOTHING READS INSIDE AN SVG, AND THAT IS THE THIRD TIME IT COST SOMETHING
//
// A figure is markup written inside a content file, which puts it past every
// check here: this tool reads the catalogue's shape, `check-exercises` reads
// the questions, and axe reads the rendered page and has no opinion about which
// typeface it is in. Inside the drawing nobody was looking, and three separate
// defects lived there — twelve palette tokens that resolved to nothing and
// would have rendered invisible, three labels still in Portuguese in the
// English lesson, and this: every `<text>` in all thirteen figures asked for
// `Archivo` and `JetBrains Mono`, which this application has never shipped. Each
// one fell through to whatever generic the browser chose, so the lettering was a
// different typeface from the page around it and a different one per machine.
//
// # IT CHECKS THE FIRST NAME AND NOT THE FALLBACK
//
// `font-family="'IBM Plex Sans', sans-serif"` is right, and the generic at the
// end is what a stack is for. The question is whether the FIRST choice is one
// the app can honour, because a first choice it cannot honour is a decision
// handed silently to the browser.
func checkFigureFonts(school string, s *catalog.School, families map[string]bool) []error {
	var problems []error
	seen := map[string]bool{}

	for _, course := range s.Courses {
		complain := func(where, first string) {
			if first == "" || families[first] || seen[where] {
				return
			}
			seen[where] = true
			problems = append(problems, fmt.Errorf(
				"%s is not a font this interface serves, so every label asking for it "+
					"falls back to whatever generic the browser picks — a different "+
					"typeface from the page around it, and a different one per machine",
				where))
		}

		for _, lesson := range course.Loaded {
			for _, t := range lesson.Text {
				for _, m := range namesFamily.FindAllStringSubmatch(t.Body, -1) {
					complain(fmt.Sprintf("%s: %s/%s/%s (%s): %q",
						school, course.ID, lesson.ID, t.SectionID, t.Locale, firstOf(m[1])),
						firstOf(m[1]))
				}
			}
		}

		/* AND THE PICTURES, WHICH WERE THE ONE PLACE LEFT.

		   This walked prose and nothing else, because when it was written every
		   drawing in the catalogue lived inside a `.md`. A `labelling` question
		   names a file in `images/` instead, and that file is an SVG full of
		   `<text>` exactly like the others — read by the loader, served by a
		   route, carried into the offline bundle, and looked at by nothing here.

		   The first one arrives with lesson two of `web-fundamentals`, so this
		   arrives with it. A picture is not a different kind of drawing because
		   of where it is stored. */
		for _, img := range course.Images {
			if img.MediaType != "image/svg+xml" {
				continue
			}
			for _, m := range namesFamily.FindAllStringSubmatch(string(img.Bytes), -1) {
				complain(fmt.Sprintf("%s: %s/images/%s: %q",
					school, course.Slug, img.Name, firstOf(m[1])), firstOf(m[1]))
			}
		}
	}
	return problems
}

/*
A SECTION REFERENCE THAT NAMES A NUMBER NO SCREEN SHOWS.

	The interface numbers sections WITHIN a lesson — `ui/app/screens/lesson.js`
	draws `01`, `02`, `03` down the tabs — and lessons within a course, in
	`rail.js` and `screens/course.js`. Nothing anywhere renders a course-wide
	index.

	So prose that says "section 111" names a number the reader cannot find. In
	`linux-terminal` that was 991 references across both languages, counted
	course-wide from the first section of the first lesson: the highest was 225,
	and the course's longest lesson has 21 sections.

	THE QUIET HALF IS WORSE THAN THE LOUD ONE. A reference over the count is
	unresolvable and at least looks it. A reference UNDER it resolves — to the
	tab with that number in whatever lesson the reader is in, which is a
	different section, with no sign that anything went wrong. Fifty-eight of them
	were in that range.

	The rule is the same for both: a reference may only name a number its lesson
	actually has. Which lesson that is comes from the sentence when it says
	("lesson 4 section 08", "section 08 of lesson 4") and from the section it is
	written in when it does not.
*/
func checkSectionReferences(school string, s *catalog.School) []error {
	var problems []error

	// `section 8`, `sections 04 and 09`, `seção 12`, `seções 04 a 11` — with an
	// optional trailing "of lesson N" / "da aula N".
	ref := regexp.MustCompile(`(?i)\b(?:sections?|se[çc][õo]es|se[çc][ãa]o)\s+` +
		`(\d+(?:\s*(?:and|to|or|e|a|at[ée]|ou|,|&)\s*\d+)*)` +
		`(?:\s+(?:of|de|da)\s+(?:lesson|aula)\s+(\d+))?`)
	// The other order, which this catalogue also writes: "lesson 4 section 08".
	before := regexp.MustCompile(`(?i)(?:lesson|aula)\s+(\d+)\s*$`)
	digits := regexp.MustCompile(`\d+`)

	for _, course := range s.Courses {
		// How many sections each lesson has, by its position in the course —
		// which is the number the rail and the tabs draw.
		count := make([]int, len(course.Loaded)+1)
		for i, lesson := range course.Loaded {
			count[i+1] = len(lesson.Sections)
		}

		for i, lesson := range course.Loaded {
			here := i + 1

			// THE SPOKEN SCRIPTS COUNT TOO, and they write the number as a word
			// because an avatar cannot say "07". A script that said "section
			// forty" would be exactly the same defect with none of the same
			// spelling, and nothing was reading them.
			type passage struct{ where, locale, body string }
			var passages []passage
			for _, t := range lesson.Text {
				passages = append(passages, passage{t.SectionID, t.Locale, withoutFences(t.Body)})
			}
			for _, sec := range lesson.Sections {
				for _, v := range sec.Videos {
					passages = append(passages, passage{sec.ID, "script", spellOut(v.Script)})
				}
			}

			for _, t := range passages {
				body := t.body
				for _, m := range ref.FindAllStringSubmatchIndex(body, -1) {
					named := here
					if m[4] >= 0 { // ...of lesson N
						named, _ = strconv.Atoi(body[m[4]:m[5]])
					} else if lead := before.FindStringSubmatch(
						body[max(0, m[0]-24):m[0]]); lead != nil { // lesson N section...
						named, _ = strconv.Atoi(lead[1])
					}
					limit := 0
					if named >= 0 && named < len(count) {
						limit = count[named]
					}
					for _, d := range digits.FindAllString(body[m[2]:m[3]], -1) {
						n, _ := strconv.Atoi(d)
						if n <= limit {
							continue
						}
						problems = append(problems, fmt.Errorf(
							"%s: %s/%s/%s (%s): %q points at section %d of lesson %d, which has %d "+
								"sections — the tabs are numbered within a lesson and no screen "+
								"shows a course-wide number, so the reader cannot find it",
							school, course.ID, lesson.ID, t.where, t.locale,
							firstChars(body[m[0]:m[1]]), n, named, limit))
					}
				}
			}
		}
	}
	return problems
}

// A script's spoken numbers, written back as digits so that one rule reads both
// halves of a lesson.
//
// A narrator says "section seventeen", not "section 17", and a check that only
// knew digits would have read every script as clean.
//
// THE CLOSING `\b` IS WHAT STOPS `seven` EATING `seventeen`, and it is worth
// naming because the obvious guess is wrong. The throwaway version of this in
// Python had no trailing boundary and reported four spoken references, three of
// which were the word `seven` inside a longer one. Ordering the alternation
// longest-first also fixes it, and was what I reached for first — but with the
// boundary in place the order makes no difference at all, which
// `TestSeventeenIsNotSeven` is here to keep true:
//
//	\b(?:seven|seventeen)\b   -> "seventeen"
//	\b(?:seven|seventeen)     -> "seven"
func spellOut(script string) string {
	return spoken.ReplaceAllStringFunc(script, func(w string) string {
		if n, ok := spokenNumbers[strings.ToLower(w)]; ok {
			return strconv.Itoa(n)
		}
		return w
	})
}

// Twenty is as far as this goes on purpose: the longest lesson in the catalogue
// has twenty-one sections, and a narrator saying a compound number ("section
// twenty-two") is naming something that does not exist in any lesson, which the
// digits either side of it will already have said.
var spokenNumbers = map[string]int{
	"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
	"eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
	"fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
	"nineteen": 19, "twenty": 20,
	"um": 1, "dois": 2, "três": 3, "quatro": 4, "cinco": 5, "seis": 6, "sete": 7,
	"oito": 8, "nove": 9, "dez": 10, "onze": 11, "doze": 12, "treze": 13,
	"catorze": 14, "quatorze": 14, "quinze": 15, "dezesseis": 16, "dezessete": 17,
	"dezoito": 18, "dezenove": 19, "vinte": 20,
}

var spoken = func() *regexp.Regexp {
	words := make([]string, 0, len(spokenNumbers))
	for w := range spokenNumbers {
		words = append(words, w)
	}
	// Sorted so the pattern is the same string on every run: a map's order is
	// not, and a checker whose regexp differs between two runs is one whose
	// failures cannot be reproduced. The order does not affect what it matches
	// — see the note above — only that it is stable.
	sort.Strings(words)
	return regexp.MustCompile(`(?i)\b(?:` + strings.Join(words, "|") + `)\b`)
}()

// The body with its fenced blocks taken out. A transcript may say anything;
// only the prose around it is this file's business.
func withoutFences(body string) string {
	var out strings.Builder
	fence := false
	for _, line := range strings.Split(body, "\n") {
		if strings.HasPrefix(line, "```") {
			fence = !fence
			out.WriteString("\n")
			continue
		}
		if fence {
			out.WriteString("\n")
			continue
		}
		out.WriteString(line)
		out.WriteString("\n")
	}
	return out.String()
}

/*
A LINE THAT BEGINS WITH A PIPE AND IS NOT A TABLE.

	`blocksOf` in `ui/app/api.js` reads a table by its SECOND line: the `---`
	rule is what tells a row apart from prose that happens to start with a pipe.
	Without the rule underneath, the line falls through every branch, and the
	paragraph branch refuses lines starting with a pipe — so nothing consumed it
	and nothing advanced. The reader got `RangeError: Invalid array length` and a
	course that would not open.

	The parser cannot hang on it any more; this is the other half, because what
	it renders instead is a stray fragment of a sentence standing alone as a
	paragraph. One wrapped line produced both: a paragraph in
	`sorting-and-grouping.pt.md` broke after the pipe inside `grep | cut | sort`,
	in Portuguese only, so the course opened in English and hung in Portuguese.

	THE RULE IS THE SECOND LINE, not the first, because `| a | b |` on its own IS
	how every table here starts. A row inside a table is fine; a pipe-first line
	with no rule under it and no table above it is the shape that breaks.
*/
func checkPipeLines(school string, s *catalog.School) []error {
	var problems []error
	rule := regexp.MustCompile(`^\|[\s|:-]+\|?\s*$`)

	for _, course := range s.Courses {
		for _, lesson := range course.Loaded {
			for _, t := range lesson.Text {
				lines := strings.Split(t.Body, "\n")
				fence := false
				table := false
				for i, line := range lines {
					if strings.HasPrefix(line, "```") {
						fence = !fence
						continue
					}
					if fence {
						continue
					}
					if !strings.HasPrefix(line, "|") {
						table = false
						continue
					}
					// the first row of a table is the one the rule sits under
					if i+1 < len(lines) && rule.MatchString(lines[i+1]) {
						table = true
						continue
					}
					if table {
						continue
					}
					problems = append(problems, fmt.Errorf(
						"%s: %s/%s/%s (%s) line %d begins with a pipe and is not a table row: %q — "+
							"a wrapped line that breaks after a pipe reads as prose to a person and "+
							"as a broken table to the renderer",
						school, course.ID, lesson.ID, t.SectionID, t.Locale, i+1, firstChars(line)))
				}
			}
		}
	}
	return problems
}

// checkFenceGlyphs holds a monospaced block to the characters this interface
// ships a glyph for.
//
// # A MONOSPACED BLOCK IS A GRID OR IT IS NOTHING
//
// `linux-terminal` draws 76 screens in box-drawing characters and quotes a
// `systemctl` line that prints `→`. None of those code points were in `latin`
// or `latin-ext`, which are the only cuts this interface used to ship — so each
// one was drawn by whatever mono font the reader's machine happened to have, at
// whatever width that font gave it, in a block where every other character was
// ours at 0.6 em.
//
// The widths agreed on the machine the drawings were written on and disagreed
// on a Windows laptop, where the fallback glyph is about 92%% of a cell: a rule
// of 72 dashes came up six characters short of the corner it was drawn to meet.
// It shipped, and a reader found it.
//
// Nothing could have reported it. The content is valid, the markup is right,
// axe has no opinion about typefaces, and `checkFigureFonts` below asks which
// FAMILY a drawing names, which was never the question here — the family was
// right and the glyph was not in it.
//
// # IT READS THE RANGES THE STYLESHEET DECLARES
//
// Which is what the browser reads, and what `tools/fonts` is careful to keep
// honest: that tool asks css2 for the characters by name and refuses a cut
// whose range comes back wider than what it asked for, precisely so that this
// check cannot be lied to.
//
// PROSE IS NOT CHECKED, and that is a scope and not an oversight. A character
// the sans font lacks is a glyph in the wrong typeface, which is a blemish; the
// same character inside a `<pre>` moves every column after it, which is a
// drawing that no longer means what it says.
func checkFenceGlyphs(school string, s *catalog.School, mono coverage, used map[rune]bool) []error {
	var problems []error
	seen := map[rune]bool{}

	for _, course := range s.Courses {
		for _, lesson := range course.Loaded {
			for _, t := range lesson.Text {
				for _, d := range drawnWith(t.Body, mono) {
					if seen[d.glyph] {
						continue
					}
					if allowedOutsideTheFont[d.glyph] != "" {
						used[d.glyph] = true
						continue
					}
					seen[d.glyph] = true
					problems = append(problems, fmt.Errorf(
						"%s: %s/%s/%s (%s) line %d draws with %q (U+%04X), which no font this "+
							"interface serves has a glyph for — inside a `<pre>` that is a cell "+
							"as wide as the reader's machine decides, and every column after it "+
							"moves. Add it to `terminalGlyphs` in tools/fonts and re-run the "+
							"tool, or write it another way",
						school, course.ID, lesson.ID, t.SectionID, t.Locale, d.line, d.glyph, d.glyph))
				}
			}
		}
	}
	return problems
}

// One character in a fence that the mono family has no glyph for, and the line
// of the section body it is on.
type drawn struct {
	glyph rune
	line  int
}

// drawnWith walks a section's markdown and answers every such character.
//
// THE MARKER THAT CLOSES A FENCE IS THE ONE THAT OPENS ONE, so a toggle is not
// enough: `fence = !fence && !schooling` reads the closing ``` of a figure as
// an OPENING one, and every line after a drawing then looks like code. That is
// how the first run of this check reported a table row, and it is what the test
// beside this file holds it to.
func drawnWith(body string, mono coverage) []drawn {
	var found []drawn
	fence, drawing := false, false

	for i, line := range strings.Split(body, "\n") {
		if strings.HasPrefix(line, "```") {
			if fence {
				fence, drawing = false, false
			} else {
				// A `schooling-` fence is JSON for a block with a reader of its
				// own, and `checkFigureFonts` is what looks inside that one.
				fence = true
				drawing = strings.HasPrefix(line, "```schooling-")
			}
			continue
		}
		if !fence || drawing {
			continue
		}
		for _, r := range line {
			if !mono.has(r) {
				found = append(found, drawn{glyph: r, line: i + 1})
			}
		}
	}
	return found
}

// A CHARACTER THE FONT DOES NOT HAVE AND THE CONTENT CANNOT DROP. One entry so
// far, and each one is a sentence explaining why the alternative is worse.
//
// An entry that stops being needed fails too — see the bottom of `run`. An
// exception that outlived what it excused reads as current.
var allowedOutsideTheFont = map[rune]string{
	'\u25cf': "`systemctl status` prints it as the state dot and IBM Plex Mono has no U+25CF " +
		"at all, so no cut of it would fix this. It opens a line and nothing is aligned to " +
		"what follows it, so the width the reader's machine gives it moves nothing that means " +
		"anything",
}

// coverage is the set of code points the interface declares a face for.
type coverage map[rune]bool

func (c coverage) has(r rune) bool { return r == '\t' || c[r] }

// servedGlyphs answers which code points the mono family is declared to cover,
// read from the same embedded stylesheet as `servedFonts`.
func servedGlyphs(family string) (coverage, error) {
	body, err := fs.ReadFile(ui.Files, "assets/fonts/fonts.css")
	if err != nil {
		return nil, fmt.Errorf("reading the interface's font faces: %w", err)
	}

	covered := coverage{}
	for _, block := range faceOf.FindAllString(string(body), -1) {
		name := declaresFamily.FindStringSubmatch(block)
		ranges := declaresRange.FindStringSubmatch(block)
		if name == nil || ranges == nil || !strings.EqualFold(name[1], family) {
			continue
		}
		for _, part := range strings.Split(ranges[1], ",") {
			lo, hi, found := strings.Cut(strings.TrimPrefix(strings.ToLower(strings.TrimSpace(part)), "u+"), "-")
			if !found {
				hi = lo
			}
			from, err := strconv.ParseInt(lo, 16, 32)
			if err != nil {
				return nil, fmt.Errorf("the stylesheet declares %q, which is not a code point", part)
			}
			to, err := strconv.ParseInt(hi, 16, 32)
			if err != nil {
				return nil, fmt.Errorf("the stylesheet declares %q, which is not a code point", part)
			}
			for r := from; r <= to; r++ {
				covered[rune(r)] = true
			}
		}
	}

	if len(covered) == 0 {
		return nil, fmt.Errorf("the interface's stylesheet declares no range for %s at all, "+
			"which cannot be right and would fail every block below", family)
	}
	return covered, nil
}

func firstChars(s string) string {
	if len(s) > 60 {
		return s[:60] + "…"
	}
	return s
}

// firstOf is the first choice of a font stack, which is the one that has to be
// a font the application ships. The generic at the end is what a stack is for.
func firstOf(stack string) string {
	return strings.ToLower(strings.Trim(strings.TrimSpace(strings.Split(stack, ",")[0]), `'"`))
}

func check(root string) (problems []error, schools int, err error) {
	entries, err := os.ReadDir(root)
	if os.IsNotExist(err) {
		return nil, 0, nil
	}
	if err != nil {
		return nil, 0, fmt.Errorf("reading %s: %w", root, err)
	}

	families, err := servedFonts()
	if err != nil {
		return nil, 0, err
	}

	mono, err := servedGlyphs("IBM Plex Mono")
	if err != nil {
		return nil, 0, err
	}
	used := map[rune]bool{}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		dir := filepath.Join(root, entry.Name())

		// A directory with no school.json is not a school and is not silently
		// skipped either: something is in `content/` that nothing will serve.
		if _, err := os.Stat(filepath.Join(dir, "school.json")); err != nil {
			problems = append(problems, fmt.Errorf(
				"%s has no school.json — nothing will serve it, and nothing else will mention it", dir))
			continue
		}
		schools++

		school, found := catalog.Load(os.DirFS(dir))
		for _, p := range found {
			problems = append(problems, fmt.Errorf("%s: %w", entry.Name(), p))
		}
		if school == nil {
			continue
		}
		for _, p := range catalog.Validate(school) {
			problems = append(problems, fmt.Errorf("%s: %w", entry.Name(), p))
		}

		// AND THE ANSWER KEYS, which is the half a schema cannot do (C-12).
		//
		// `catalog` may not import `grade` — they are two modules — so the
		// joining happens here, which is what cmd/ and tools/ are for. It is
		// also the honest place: reading files and judging answers are two
		// jobs, and the only thing that needs both is the checker.
		problems = append(problems, checkKeys(entry.Name(), school)...)

		// AND THE LETTERING OF EVERY DRAWING, against the fonts the binary
		// actually carries. See `checkFigureFonts` for the three defects that
		// have now lived inside an SVG, where nothing was reading.
		problems = append(problems, checkFigureFonts(entry.Name(), school, families)...)
		problems = append(problems, checkPipeLines(entry.Name(), school)...)

		// AND THAT A CROSS-REFERENCE POINTS AT SOMETHING THE READER CAN FIND.
		// See `checkSectionReferences`: the numbering on screen is per lesson,
		// and a course-wide number resolves nowhere — or worse, resolves to the
		// wrong section without saying so.
		problems = append(problems, checkSectionReferences(entry.Name(), school)...)

		// AND THE CHARACTERS THEMSELVES, which is a different question from the
		// family: a block can name the right font and still be drawn with a
		// glyph that font has never had. See `checkFenceGlyphs`.
		problems = append(problems, checkFenceGlyphs(entry.Name(), school, mono, used)...)
	}

	// An exception that outlived what it excused reads as current, and the next
	// person to meet this character would read it as settled rather than as a
	// thing nobody has had to decide again.
	for r, why := range allowedOutsideTheFont {
		if !used[r] {
			problems = append(problems, fmt.Errorf(
				"%q (U+%04X) is excused in `allowedOutsideTheFont` — %s — and no block draws "+
					"with it any more. Delete the entry", r, r, why))
		}
	}

	sort.Slice(problems, func(i, j int) bool { return problems[i].Error() < problems[j].Error() })
	return problems, schools, nil
}
