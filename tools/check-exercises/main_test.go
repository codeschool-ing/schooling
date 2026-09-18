package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// This file exists because the tool shipped without one and the gap had a
// consequence. `LongestShareCeiling` asked only whether the correct option was
// the LONGEST, three lessons of this catalogue went out with it the SHORTEST in
// 97%, 100% and 100% of their questions, and every run reported them clean.
// Nothing held the claim that the tool catches the length tell, so the claim
// was decoration.

// lesson builds a set of four-option questions where the correct option is put
// at the length rank the caller asks for. Rank 0 is the longest.
func lesson(n, rank int) []exercise {
	var out []exercise
	// Four texts of clearly different lengths, longest first.
	lengths := []int{80, 60, 40, 20}
	for i := 0; i < n; i++ {
		e := exercise{ID: "ex-test", Type: "quiz"}
		for k, l := range lengths {
			e.Choices = append(e.Choices, choice{
				Text:    strings.Repeat("x", l),
				Correct: k == rank,
			})
		}
		out = append(out, e)
	}
	return out
}

func ruled(t *testing.T, exs []exercise) bool {
	t.Helper()
	problems, _ := checkLesson("at", languages["en"], exs)
	for _, p := range problems {
		if strings.Contains(p, "pass with a ruler") {
			return true
		}
	}
	return false
}

// The tell the tool always caught. Kept so that fixing the other end did not
// quietly cost this one.
func TestTheCorrectOptionBeingLongestIsATell(t *testing.T) {
	if !ruled(t, lesson(40, 0)) {
		t.Fatal("a lesson whose correct option is always the longest was reported clean")
	}
}

// The tell it did not catch, which is why this file exists.
func TestTheCorrectOptionBeingShortestIsATellToo(t *testing.T) {
	if !ruled(t, lesson(40, 3)) {
		t.Fatal("a lesson whose correct option is always the shortest was reported clean")
	}
}

// And the rank a repair lands on when somebody trims the correct option until
// it stops being longest. A check that only watches one end pays for the repair
// by moving the habit rather than removing it.
func TestTheCorrectOptionBeingSecondLongestIsATellToo(t *testing.T) {
	if !ruled(t, lesson(40, 1)) {
		t.Fatal("a lesson whose correct option is always the second-longest was reported clean")
	}
}

// A lesson where length says nothing has to pass, or the tool cries wolf and
// the next person learns to skip its output.
func TestLengthSayingNothingIsNotATell(t *testing.T) {
	var exs []exercise
	for rank := 0; rank < 4; rank++ {
		exs = append(exs, lesson(10, rank)...)
	}
	if ruled(t, exs) {
		t.Fatal("a lesson with the correct option evenly spread across the ranks was flagged")
	}
}

// Four options of one length is the ideal rather than a failure: a ruler
// separates none of them. This catalogue has a question written that way on
// purpose, and counting it as a habit is what the tie rule prevents.
func TestOptionsOfEqualLengthAreNotATell(t *testing.T) {
	var exs []exercise
	for i := 0; i < 40; i++ {
		e := exercise{ID: "ex-test", Type: "quiz"}
		for k := 0; k < 4; k++ {
			e.Choices = append(e.Choices, choice{Text: strings.Repeat("x", 40), Correct: k == 0})
		}
		exs = append(exs, e)
	}
	if ruled(t, exs) {
		t.Fatal("a lesson whose options are all one length was flagged")
	}
}

// The end-to-end number has to name the strategy that actually scored, because
// a report that says "the longest option" while the paper is answerable by the
// shortest sends the reader to fix the wrong thing.
func TestTheReportNamesTheStrategyThatScored(t *testing.T) {
	_, report := checkLesson("at", languages["en"], lesson(40, 3))
	if !strings.Contains(report, "the shortest option") {
		t.Fatalf("report does not name the winning strategy: %s", report)
	}
}

// The defect this file's second half exists for. The tool globbed
// `exercises.json` and nothing else, so a lesson was measured in a language
// most of these students do not read — and the first run that looked at the
// other one found six lessons over the ruler ceiling that were clean in
// English, three of them in a pull request that had just repaired the English
// of those same lessons.

// lessonFiles writes an English battery and one translation of it, and answers
// the path of the English file.
func lessonFiles(t *testing.T, translated map[string]any) string {
	t.Helper()
	dir := t.TempDir()

	var en []map[string]any
	for i := 0; i < 40; i++ {
		en = append(en, map[string]any{
			"id": fmt.Sprintf("ex-%02d", i), "type": "quiz",
			"prompt": "which one",
			"choices": []map[string]any{
				{"text": strings.Repeat("a", 40), "correct": true},
				{"text": strings.Repeat("b", 40)},
				{"text": strings.Repeat("c", 40)},
				{"text": strings.Repeat("d", 40)},
			},
		})
	}
	write(t, filepath.Join(dir, "exercises.json"), en)
	for locale, body := range translated {
		write(t, filepath.Join(dir, "exercises."+locale+".json"), body)
	}
	return filepath.Join(dir, "exercises.json")
}

func write(t *testing.T, at string, body any) {
	t.Helper()
	encoded, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(at, encoded, 0o600); err != nil {
		t.Fatal(err)
	}
}

func versions(t *testing.T, f string) []version {
	t.Helper()
	body, err := os.ReadFile(f) //nolint:gosec // a path this test just wrote
	if err != nil {
		t.Fatal(err)
	}
	var exs []exercise
	if err := json.Unmarshal(body, &exs); err != nil {
		t.Fatal(err)
	}
	read, err := everyLanguage(f, body, exs)
	if err != nil {
		t.Fatal(err)
	}
	return read
}

// The English options here are all one length, so the English battery is the
// ideal: a ruler separates none of them. The translation lengthens the correct
// one and nothing else, which is a tell that exists in one language and in
// neither the other one nor the file anybody reviews.
func TestATranslationThatReintroducesTheRulerIsCaught(t *testing.T) {
	pt := map[string]any{}
	for i := 0; i < 40; i++ {
		pt[fmt.Sprintf("ex-%02d", i)] = map[string]any{
			"choices": []map[string]any{{"text": strings.Repeat("á", 90)}},
		}
	}
	read := versions(t, lessonFiles(t, map[string]any{"pt": pt}))
	if len(read) != 2 {
		t.Fatalf("read %d version(s), want the English and the Portuguese", len(read))
	}
	if ruled(t, read[0].exercises) {
		t.Fatal("the English battery was flagged, and its four options are one length")
	}
	problems, _ := checkLesson("at", read[1].lang, read[1].exercises)
	found := false
	for _, p := range problems {
		if strings.Contains(p, "pass with a ruler") {
			found = true
		}
	}
	if !found {
		t.Fatal("a translation whose correct option is always the longest was reported clean")
	}
}

// A locale with no word list would score zero on three of the checkable rows
// and print a number anyway, which is worse than not running. So the day
// somebody adds the third language is the day the build says so.
func TestALocaleWithNoWordListIsNotMeasuredHalfway(t *testing.T) {
	read := versions(t, lessonFiles(t, map[string]any{"es": map[string]any{}}))
	for _, v := range read {
		if v.locale == "es" {
			if v.lang != nil {
				t.Fatal("a locale with no word list was handed one")
			}
			return
		}
	}
	t.Fatal("the Spanish file was not read at all")
}

// Go's `\b` is ASCII, so `\bsó\b` never matches: the boundary it wants after
// the word is already there. Every accented Portuguese absolute would have been
// invisible, and the run would have said so with confidence.
func TestAnAccentedAbsoluteIsFound(t *testing.T) {
	for _, word := range []string{"só", "ninguém", "impossível", "não pode"} {
		if !languages["pt"].absolutes.MatchString("a resposta " + word + " vale") {
			t.Fatalf("%q is in the list and was not found", word)
		}
	}
	if languages["pt"].absolutes.MatchString("o diretório sólido") {
		t.Fatal("`só` was found inside `sólido`")
	}
}

// English splits the absolute from the hedge into two words and Portuguese does
// not: `não pode` carries `pode`. Without the blanking, the commonest refusal in
// the language is reported as a hedge on every question that uses it.
func TestARefusalIsNotAHedge(t *testing.T) {
	if languages["pt"].hedged("o servidor não pode entrar") {
		t.Fatal("`não pode` was read as a hedge")
	}
	if !languages["pt"].hedged("o servidor pode entrar") {
		t.Fatal("`pode` on its own is a hedge and was not found")
	}
}

// The types the tool used to walk past. `docs/EXERCISES.md` had the gap under
// its own heading, and 429 of the catalogue's 2022 questions sat inside it.

func typed(t *testing.T, e exercise) []string {
	t.Helper()
	return checkTyped("at", e)
}

func cloze(prompt string, b blank) exercise {
	return exercise{ID: "ex-test", Type: "cloze", Prompt: prompt, Blanks: []blank{b}}
}

// The plainest one in the catalogue on the first run: the prompt said *before
// you paste a block of text* and the blank accepted `paste`.
func TestABlankFilledByCopyingThePromptIsCaught(t *testing.T) {
	e := cloze("Before you paste a block of text, run :set _____ so vim stops indenting.",
		blank{Accept: []string{"paste"}, IgnoreCase: true})
	if len(typed(t, e)) == 0 {
		t.Fatal("a blank whose answer is a word of its own prompt was reported clean")
	}
}

// A prompt showing `IS NOT NULL` is showing the shape of an answer, which is a
// teaching device rather than the answer lying in the open.
func TestAnAnswerInsideBackticksIsNotAnEcho(t *testing.T) {
	e := cloze("Write the operator that asks about the state: ___ ___ and `IS NOT NULL`.",
		blank{Accept: []string{"null"}, IgnoreCase: true})
	if p := typed(t, e); len(p) != 0 {
		t.Fatalf("a code span was read as a word of the prompt: %v", p)
	}
}

// Whether the prompt's `with` fills a blank that accepts `WITH` is the blank's
// decision and not this tool's — so a blank that cares about case is measured
// with case.
func TestABlankThatCaresAboutCaseIsMeasuredWithIt(t *testing.T) {
	prompt := "The steps are named with ___."
	if p := typed(t, cloze(prompt, blank{Accept: []string{"WITH"}})); len(p) != 0 {
		t.Fatalf("case was ignored where the blank does not ignore it: %v", p)
	}
	if len(typed(t, cloze(prompt, blank{Accept: []string{"WITH"}, IgnoreCase: true}))) == 0 {
		t.Fatal("case was respected where the blank ignores it")
	}
}

// Two is the coin flip `MinimumChoices` refuses for a quiz, arriving as an
// arrangement rather than as a list of options.
func TestTwoItemsOrTwoPairsAreACoinFlip(t *testing.T) {
	if len(typed(t, exercise{ID: "ex-test", Type: "ordering", Items: []string{"a", "b"}})) == 0 {
		t.Fatal("an ordering of two items was reported clean")
	}
	if p := typed(t, exercise{ID: "ex-test", Type: "ordering", Items: []string{"a", "b", "c"}}); len(p) != 0 {
		t.Fatalf("an ordering of three items was flagged: %v", p)
	}
	two := []pair{{Left: "a", Right: "1"}, {Left: "b", Right: "2"}}
	if len(typed(t, exercise{ID: "ex-test", Type: "matching", Pairs: two})) == 0 {
		t.Fatal("a matching of two pairs against two rights was reported clean")
	}
	withOne := exercise{ID: "ex-test", Type: "matching", Pairs: two, RightDistractors: []string{"3"}}
	if p := typed(t, withOne); len(p) != 0 {
		t.Fatalf("a distractor takes the chance to one in six, and it was flagged anyway: %v", p)
	}
}
