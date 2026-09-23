package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

// exampleBlock is the JSON inside a ```schooling-example fence, in the shape
// `annotatedExample` in `ui/app/text.js` reads it: the program cut into parts,
// each with the note that is drawn beside it.
type exampleBlock struct {
	Language string        `json:"language"`
	File     string        `json:"file,omitempty"`
	Parts    []examplePart `json:"parts"`
	Output   string        `json:"output,omitempty"`
}

type examplePart struct {
	Code string `json:"code"`
	Note string `json:"note,omitempty"`
}

// One ```schooling-example fence in a section's body, with the line its
// opening marker is on.
type fencedExample struct {
	line int
	raw  string
}

// examplesIn answers every annotated example in a body, in order.
func examplesIn(body string) []fencedExample {
	var found []fencedExample
	var open *fencedExample
	var inside []string
	fence := false

	for i, line := range strings.Split(body, "\n") {
		if !strings.HasPrefix(line, "```") {
			if open != nil {
				inside = append(inside, line)
			}
			continue
		}
		if fence {
			if open != nil {
				open.raw = strings.Join(inside, "\n")
				found = append(found, *open)
			}
			fence, open, inside = false, nil, nil
			continue
		}
		fence = true
		if strings.TrimSpace(line) == "```schooling-example" {
			open = &fencedExample{line: i + 1}
		}
	}
	return found
}

// parseExample reads one block and refuses what the renderer would draw
// wrongly without saying so.
//
// # A WRONG KEY IS AN EMPTY WINDOW
//
// The client parses the JSON and reads `parts`, `code`, `note` and `output` by
// name. A block that is valid JSON with `notes` for `note` or `result` for
// `output` renders as a window with nothing where the explanation was, and no
// error anywhere: the JSON parsed, so the fallback that shows unreadable
// blocks as text never runs. So an unknown key is refused here, where a
// person can still read the message.
//
// # AN EXAMPLE WITH NO NOTE IS A CODE BLOCK
//
// A part may go without a note — a closing brace does not need one — but a
// block where none of them has one is a program in a frame built for
// commentary, and it belongs in an ordinary fence with its language.
func parseExample(raw string) (exampleBlock, error) {
	var ex exampleBlock
	dec := json.NewDecoder(bytes.NewReader([]byte(raw)))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&ex); err != nil {
		return ex, fmt.Errorf("is not the JSON a `schooling-example` takes: %w", err)
	}
	if dec.More() {
		return ex, errors.New("carries something after its JSON object")
	}
	if strings.TrimSpace(ex.Language) == "" {
		return ex, errors.New("names no `language`, so nothing highlights it and its window has no title")
	}
	if len(ex.Parts) == 0 {
		return ex, errors.New("has no `parts`, which draws an empty window")
	}
	noted := false
	for i, p := range ex.Parts {
		if strings.TrimSpace(p.Code) == "" {
			return ex, fmt.Errorf("part %d has no `code` — a note beside nothing", i+1)
		}
		if strings.TrimSpace(p.Note) != "" {
			noted = true
		}
	}
	if !noted {
		return ex, errors.New("has no `note` on any part: that is a program, and it belongs in an " +
			"ordinary fence with its language")
	}
	return ex, nil
}

// checkExamples reads every annotated example, and holds a translated section
// to the examples of the section it translates.
//
// # THE TRANSLATION IS A SECOND COPY OF THE BLOCK, AND IT CAN DRIFT
//
// A `.pt.md` carries its own `schooling-example`, with the notes in Portuguese
// and the code with its comments and names translated, so the code is not
// compared — it is not meant to be identical. What is compared is the shape:
// the same number of examples, and each with the same number of parts, the
// same `language` and the same `file`. A part added in English and not in
// Portuguese moves every note after it onto the wrong code, and each screen
// reads perfectly on its own.
//
// Blocks are paired by their order in the section, which is a join by
// position; inside one section, between a text and its translation, that is
// the only identity a block has — the same trade `tools/check-figures` makes
// when it holds a figure to its translation.
func checkExamples(school string, s *catalog.School) []error {
	var problems []error

	for _, course := range s.Courses {
		for _, lesson := range course.Loaded {
			bySection := map[string]map[string][]exampleBlock{}

			for _, t := range lesson.Text {
				where := fmt.Sprintf("%s: %s/%s/%s (%s)", school, course.ID, lesson.ID, t.SectionID, t.Locale)
				var blocks []exampleBlock
				broken := false
				for _, f := range examplesIn(t.Body) {
					ex, err := parseExample(f.raw)
					if err != nil {
						problems = append(problems, fmt.Errorf(
							"%s line %d: this `schooling-example` %w", where, f.line, err))
						broken = true
						continue
					}
					blocks = append(blocks, ex)
				}
				if broken {
					// Comparing a broken block's shape would report the same
					// fault twice, the second time less clearly.
					continue
				}
				if bySection[t.SectionID] == nil {
					bySection[t.SectionID] = map[string][]exampleBlock{}
				}
				bySection[t.SectionID][t.Locale] = blocks
			}

			for section, locales := range bySection {
				source, ok := locales[catalogSource]
				if !ok {
					continue
				}
				for locale, blocks := range locales {
					if locale == catalogSource {
						continue
					}
					where := fmt.Sprintf("%s: %s/%s/%s (%s)", school, course.ID, lesson.ID, section, locale)
					if len(blocks) != len(source) {
						problems = append(problems, fmt.Errorf(
							"%s has %d `schooling-example` block(s) and the text it translates has %d",
							where, len(blocks), len(source)))
						continue
					}
					for i := range source {
						a, b := source[i], blocks[i]
						switch {
						case len(a.Parts) != len(b.Parts):
							problems = append(problems, fmt.Errorf(
								"%s: example %d has %d part(s) and the one it translates has %d — every "+
									"note after the difference sits beside the wrong code",
								where, i+1, len(b.Parts), len(a.Parts)))
						case a.Language != b.Language:
							problems = append(problems, fmt.Errorf(
								"%s: example %d is `%s` and the one it translates is `%s`",
								where, i+1, b.Language, a.Language))
						case a.File != b.File:
							problems = append(problems, fmt.Errorf(
								"%s: example %d is titled %q and the one it translates %q — a file "+
									"name is the same in every language",
								where, i+1, b.File, a.File))
						}
					}
				}
			}
		}
	}
	return problems
}

// The locale every translation is compared against. It is the catalogue's own
// constant, repeated because that one is unexported.
const catalogSource = "en"
