package main

import (
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

const goodExample = `{"language": "python", "file": "greet.py", "parts": [
  {"code": "name = input()", "note": "What the person typed, as a string."},
  {"code": "print(f\"hi {name}\")"}
], "output": "hi ana"}`

func fence(json string) string { return "```schooling-example\n" + json + "\n```\n" }

func TestAGoodExampleIsAccepted(t *testing.T) {
	if _, err := parseExample(goodExample); err != nil {
		t.Errorf("a language, parts with code and one note is the whole shape; got %v", err)
	}
}

// EACH OF THESE PARSES AS JSON AND DRAWS SOMETHING WRONG WITHOUT AN ERROR, or
// does not parse and shows the reader raw JSON. Each is refused by name.
func TestAnExampleTheRendererWouldDrawWronglyIsRefused(t *testing.T) {
	for name, raw := range map[string]string{
		"a misspelt note":        `{"language": "python", "parts": [{"code": "x = 1", "notes": "one"}]}`,
		"output by another name": `{"language": "python", "parts": [{"code": "x = 1", "note": "one"}], "result": "1"}`,
		"no language":            `{"parts": [{"code": "x = 1", "note": "one"}]}`,
		"no parts":               `{"language": "python", "parts": []}`,
		"a part with no code":    `{"language": "python", "parts": [{"code": "  ", "note": "beside nothing"}]}`,
		"no note anywhere":       `{"language": "python", "parts": [{"code": "x = 1"}, {"code": "y = 2"}]}`,
		"not JSON":               `language: python`,
		"two objects":            `{"language": "python", "parts": [{"code": "x", "note": "n"}]} {}`,
	} {
		if _, err := parseExample(raw); err == nil {
			t.Errorf("%s was accepted", name)
		}
	}
}

func TestAnExampleIsFoundWithTheLineThatOpensIt(t *testing.T) {
	body := "Prose.\n\n```python\nx = 1\n```\n\n" + fence(goodExample) +
		"\n```schooling-figure\n{\"svg\": \"<svg/>\", \"caption\": \"c\"}\n```\n"
	found := examplesIn(body)
	if len(found) != 1 {
		t.Fatalf("one example among a code block and a figure; got %d", len(found))
	}
	if found[0].line != 7 {
		t.Errorf("the example opens on line 7; got %d", found[0].line)
	}
	if _, err := parseExample(found[0].raw); err != nil {
		t.Errorf("the body handed back is the block's JSON and parses; got %v", err)
	}
}

func lessonWith(texts ...catalog.Prose) *catalog.School {
	return &catalog.School{Courses: []*catalog.Course{{
		ID:     "co-x",
		Loaded: []*catalog.Lesson{{ID: "le-1", Text: texts}},
	}}}
}

func TestATranslationWithTheSameShapeIsAccepted(t *testing.T) {
	pt := strings.ReplaceAll(goodExample, "What the person typed, as a string.", "O que a pessoa digitou, como texto.")
	s := lessonWith(
		catalog.Prose{SectionID: "se-a", Locale: "en", Body: fence(goodExample)},
		catalog.Prose{SectionID: "se-a", Locale: "pt", Body: fence(pt)},
	)
	if got := checkExamples("code", s); len(got) != 0 {
		t.Errorf("the notes differ and nothing else; got %v", got)
	}
}

// THE FAILURE THIS CHECK EXISTS FOR: two copies of one block, one of them
// edited. Each screen reads well on its own.
func TestATranslationThatDriftedIsReported(t *testing.T) {
	for name, pt := range map[string]string{
		"a part fewer":     `{"language": "python", "file": "greet.py", "parts": [{"code": "nome = input()", "note": "O texto."}], "output": "hi ana"}`,
		"another language": strings.Replace(goodExample, `"python"`, `"py"`, 1),
		"another file":     strings.Replace(goodExample, "greet.py", "saudar.py", 1),
	} {
		s := lessonWith(
			catalog.Prose{SectionID: "se-a", Locale: "en", Body: fence(goodExample)},
			catalog.Prose{SectionID: "se-a", Locale: "pt", Body: fence(pt)},
		)
		if got := checkExamples("code", s); len(got) != 1 {
			t.Errorf("%s: expected one report; got %v", name, got)
		}
	}

	s := lessonWith(
		catalog.Prose{SectionID: "se-a", Locale: "en", Body: fence(goodExample) + fence(goodExample)},
		catalog.Prose{SectionID: "se-a", Locale: "pt", Body: fence(goodExample)},
	)
	if got := checkExamples("code", s); len(got) != 1 {
		t.Errorf("an example missing from the translation: expected one report; got %v", got)
	}
}

// A BROKEN BLOCK IS REPORTED ONCE, as what it is, and not a second time as a
// translation that disagrees with it.
func TestABrokenBlockIsReportedOnce(t *testing.T) {
	s := lessonWith(
		catalog.Prose{SectionID: "se-a", Locale: "en", Body: fence(goodExample)},
		catalog.Prose{SectionID: "se-a", Locale: "pt", Body: fence(`{"language": "python"}`)},
	)
	got := checkExamples("code", s)
	if len(got) != 1 || !strings.Contains(got[0].Error(), "line 1") {
		t.Errorf("one report, naming the line; got %v", got)
	}
}

// THE GLYPH CHECK READS INSIDE THE JSON. The code of an example is drawn in
// the mono face like any other block, and so is its output.
func TestAGlyphInsideAnExampleIsFound(t *testing.T) {
	for name, raw := range map[string]string{
		"in the code":   `{"language": "sh", "parts": [{"code": "echo ✦", "note": "n"}]}`,
		"in the output": `{"language": "sh", "parts": [{"code": "echo", "note": "n"}], "output": "● ok"}`,
	} {
		found := drawnWith("Prose.\n\n"+fence(raw), mono())
		if len(found) != 1 || found[0].line != 3 {
			t.Errorf("%s: one glyph, on the line that opens the fence; got %v", name, found)
		}
	}
	// And a note is prose: it is drawn in the sans face, and is not this check's.
	if found := drawnWith(fence(`{"language": "sh", "parts": [{"code": "ls", "note": "lists ✦"}]}`), mono()); len(found) != 0 {
		t.Errorf("a note is prose; got %v", found)
	}
}
