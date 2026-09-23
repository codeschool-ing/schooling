package main

import (
	"encoding/json"
	"fmt"
	"regexp"
	"strings"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

// A fenced block of a section: its info string, its body, and the line its
// opening marker is on.
type fenced struct {
	info string
	body string
	line int
}

// fencesIn answers every fenced block in a body, in order.
func fencesIn(body string) []fenced {
	var found []fenced
	var open *fenced
	var inside []string

	for i, line := range strings.Split(body, "\n") {
		if !strings.HasPrefix(line, "```") {
			if open != nil {
				inside = append(inside, line)
			}
			continue
		}
		if open != nil {
			open.body = strings.Join(inside, "\n")
			found = append(found, *open)
			open, inside = nil, nil
			continue
		}
		open = &fenced{info: strings.TrimSpace(strings.TrimPrefix(line, "```")), line: i + 1}
	}
	return found
}

// checkTranslatedCode holds every translated section to the code of the
// section it translates, byte for byte.
//
// # CODE IS THE SAME PROGRAM IN EVERY LANGUAGE
//
// A translation used to be free to translate its code: names, comments,
// strings, and — because nothing drew the line — output too. `python`'s
// Portuguese showed a timing table as `vetorizado  0,002 s`, a path the
// interpreter returned as `/tmp/projeto/...` and a DataFrame header as
// `centavos`. No program printed any of those. They were evidence of a run,
// rewritten by hand, and every screen read perfectly on its own.
//
// And a translated program is a second program nobody runs. Nothing here can
// check that `repetir(vezes=3)` still does what `retry(times=3)` does, so the
// rule that CAN be checked is the one that removes the question: the code is
// identical, and what a reader needs in their own language goes where
// translation belongs — the prose, and the notes of a `schooling-example`.
//
// # WHAT IS COMPARED
//
// Every fence, in order, by its info string and its body — except a
// `schooling-figure`, whose labels ARE translated and which
// `tools/check-figures` holds to its translation instead. For a
// `schooling-example` the notes are prose and free; its code parts and its
// output are compared, because they are the program and what it printed.
//
// # ONE LABEL IS EXEMPT, AND IT IS DECLARED ON THE BLOCK
//
// `localised`, in both languages: an explanation drawn in mono, or a formula
// the software spells per locale — `=ARRED(…; 2)` is right in a Portuguese
// spreadsheet and `=ROUND(…, 2)` would be refused by it. A pair where both
// sides say `localised` is not compared, one side alone is a difference like
// any other, and the label is refused on anything that looks like a capture,
// because what a machine printed is never the reader's to reword.
//
// Fences are paired by their order in the section, a join by position that is
// the only identity a block has between a text and its translation — the same
// trade `checkExamples` makes, and a count that differs is reported as what it
// is before any pair is compared.
func checkTranslatedCode(school string, s *catalog.School) []error {
	var problems []error

	for _, course := range s.Courses {
		for _, lesson := range course.Loaded {
			bySection := map[string]map[string]string{}
			for _, t := range lesson.Text {
				if bySection[t.SectionID] == nil {
					bySection[t.SectionID] = map[string]string{}
				}
				bySection[t.SectionID][t.Locale] = t.Body
			}

			for _, t := range lesson.Text {
				for _, f := range fencesIn(t.Body) {
					if f.info == localised && looksCaptured(f.body) {
						problems = append(problems, fmt.Errorf(
							"%s: %s/%s/%s (%s) line %d: a `localised` block that looks like a capture — "+
								"a prompt, `$ ` or `>>> `. What a machine printed is evidence of a run and "+
								"is the same in every language",
							school, course.ID, lesson.ID, t.SectionID, t.Locale, f.line))
					}
				}
			}

			for section, locales := range bySection {
				source, ok := locales[catalogSource]
				if !ok {
					continue
				}
				want := codeOf(fencesIn(source))
				for locale, body := range locales {
					if locale == catalogSource {
						continue
					}
					where := fmt.Sprintf("%s: %s/%s/%s (%s)", school, course.ID, lesson.ID, section, locale)
					got := codeOf(fencesIn(body))
					if len(got) != len(want) {
						problems = append(problems, fmt.Errorf(
							"%s has %d block(s) of code and the text it translates has %d",
							where, len(got), len(want)))
						continue
					}
					for i := range want {
						if got[i].text != want[i].text {
							problems = append(problems, fmt.Errorf(
								"%s line %d: this block differs from the one it translates (line %d). "+
									"Code, and what it printed, is the same in every language — what a "+
									"reader needs in theirs goes in the prose or in a `schooling-example` note",
								where, got[i].line, want[i].line))
						}
					}
				}
			}
		}
	}
	return problems
}

// One comparable block: what must be identical, and where it starts.
type codeBlock struct {
	text string
	line int
}

// codeOf reduces a section's fences to what a translation must repeat.
func codeOf(fences []fenced) []codeBlock {
	var out []codeBlock
	for _, f := range fences {
		switch f.info {
		case "schooling-figure":
			continue
		case localised:
			// Its words are the reader's; only the label has to match.
			out = append(out, codeBlock{text: localised, line: f.line})
		case "schooling-example":
			var ex exampleBlock
			if json.Unmarshal([]byte(f.body), &ex) != nil {
				// Unreadable is `checkExamples`'s to report; compared as it
				// stands, it still differs if either side changed.
				out = append(out, codeBlock{text: f.body, line: f.line})
				continue
			}
			var b strings.Builder
			for _, p := range ex.Parts {
				b.WriteString(p.Code)
				b.WriteString("\x00")
			}
			b.WriteString("\x01" + ex.Output)
			out = append(out, codeBlock{text: "example\x02" + b.String(), line: f.line})
		default:
			out = append(out, codeBlock{text: f.info + "\x02" + f.body, line: f.line})
		}
	}
	return out
}

// The one fence label a translation may change the body of. It is the same
// string as `LOCALISED` in `ui/app/text.js`, which draws it.
const localised = "localised"

// The shapes of a capture: a shell prompt, a bare `$ ` and the Python REPL's.
var capturedLine = regexp.MustCompile(`(?m)^([\w.-]+@[\w.-]+:\S*[$#] |\$ |>>> |PS [^>\n]*> )`)

func looksCaptured(body string) bool { return capturedLine.MatchString(body) }
