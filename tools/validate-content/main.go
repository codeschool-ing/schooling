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
	}

	sort.Slice(problems, func(i, j int) bool { return problems[i].Error() < problems[j].Error() })
	return problems, schools, nil
}
