package main

import (
	"os"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

func section(en, pt string) *catalog.School {
	return lessonWith(
		catalog.Prose{SectionID: "se-a", Locale: "en", Body: en},
		catalog.Prose{SectionID: "se-a", Locale: "pt", Body: pt},
	)
}

const program = "Prose.\n\n```python\nvalue = m.group(1)   # None when it did not match\n```\n"

func TestTheSameCodeInBothLanguagesIsAccepted(t *testing.T) {
	pt := strings.Replace(program, "Prose.", "Prosa.", 1)
	if got := checkTranslatedCode("code", section(program, pt)); len(got) != 0 {
		t.Errorf("only the prose differs; got %v", got)
	}
}

// EACH OF THESE IS A TRANSLATION THAT READS PERFECTLY AND SHOWS A PROGRAM NOBODY
// RAN — a comment, a name, an output, a label — and each is reported.
func TestCodeThatWasTranslatedIsReported(t *testing.T) {
	for name, pt := range map[string]string{
		"a comment":             strings.Replace(program, "None when it did not match", "None quando não casou", 1),
		"a name":                strings.Replace(program, "value =", "valor =", 1),
		"the label":             strings.Replace(program, "```python", "```py", 1),
		"a block left out":      "Prosa.\n",
		"an output reworded":    "Prosa.\n\n```\n500.000 linhas\n```\n",
		"an example's code":     fence(strings.Replace(goodExample, "name = input()", "nome = input()", 1)),
		"an example's output":   fence(strings.Replace(goodExample, `"hi ana"`, `"oi ana"`, 1)),
		"localised on one side": strings.Replace(program, "```python", "```localised", 1),
	} {
		en := program
		switch name {
		case "an output reworded":
			en = "Prose.\n\n```\n500,000 rows\n```\n"
		case "an example's code", "an example's output":
			en = fence(goodExample)
		}
		if got := checkTranslatedCode("code", section(en, pt)); len(got) != 1 {
			t.Errorf("%s: expected one report; got %v", name, got)
		}
	}
}

// THE NOTES OF AN EXAMPLE ARE PROSE, and a figure is held by its own tool.
func TestWhatBelongsToTheReaderIsFree(t *testing.T) {
	notes := strings.Replace(goodExample, "What the person typed, as a string.", "O que a pessoa digitou.", 1)
	if got := checkTranslatedCode("code", section(fence(goodExample), fence(notes))); len(got) != 0 {
		t.Errorf("an example's notes are translated; got %v", got)
	}
	figure := func(label string) string {
		return "```schooling-figure\n{\"svg\": \"<svg><text>" + label + "</text></svg>\", \"caption\": \"c\"}\n```\n"
	}
	if got := checkTranslatedCode("code", section(figure("the row"), figure("a linha"))); len(got) != 0 {
		t.Errorf("a figure is check-figures' to compare; got %v", got)
	}
}

// THE EXCEPTION, AND ITS LIMIT. Words in mono and a formula the software
// spells per locale may differ when both sides say so; a capture may not, even
// declared.
func TestALocalisedBlockIsFreeAndACaptureNeverIs(t *testing.T) {
	en := "```localised\n=ROUND(total - summary, 2)\n```\n"
	pt := "```localised\n=ARRED(total - resumo; 2)\n```\n"
	if got := checkTranslatedCode("code", section(en, pt)); len(got) != 0 {
		t.Errorf("both sides are localised; got %v", got)
	}

	for _, capture := range []string{
		"ana@vm:~/notas$ ls leiame.txt\nleiame.txt",
		"$ ls -estranho",
		">>> nome\n'ana'",
	} {
		body := "```localised\n" + capture + "\n```\n"
		got := checkTranslatedCode("code", section(body, body))
		if len(got) != 2 {
			t.Errorf("%q is a capture in both files, and each is reported; got %v", capture, got)
		}
	}
}

// THE LABEL IS WRITTEN IN TWO LANGUAGES, and the two must be one string: the
// validator exempts it and the renderer draws it without a title.
func TestTheLabelIsTheOneTheRendererKnows(t *testing.T) {
	text, err := os.ReadFile("../../ui/app/text.js")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(text), "export const LOCALISED = '"+localised+"';") {
		t.Errorf("ui/app/text.js does not export LOCALISED as %q, which is the label this checker exempts", localised)
	}
}
