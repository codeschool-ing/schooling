package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

var nine = map[string]bool{
	"ink": true, "panel": true, "scan": true, "phosphor": true, "phosphor-dim": true,
	"amber": true, "paper": true, "paper-dim": true, "wire": true,
}

func says(problems []string, fragments ...string) bool {
	for _, p := range problems {
		all := true
		for _, f := range fragments {
			if !strings.Contains(p, f) {
				all = false
				break
			}
		}
		if all {
			return true
		}
	}
	return false
}

func listed(problems []string) string {
	if len(problems) == 0 {
		return "  (none)"
	}
	return "  - " + strings.Join(problems, "\n  - ")
}

func drawing(svg string) figure {
	return figure{SVG: `<svg role="img" aria-label="a thing">` + svg + `</svg>`, Caption: "A thing."}
}

func TestAFigureDrawnWithThePaletteIsAccepted(t *testing.T) {
	fig := drawing(`<rect fill="var(--panel)" stroke="var(--wire)"/>` +
		`<text fill="var(--paper)">x</text>`)
	if _, problems := check("at", fig, nine); len(problems) > 0 {
		t.Errorf("a figure drawn with the palette was refused:\n%s", listed(problems))
	}
}

/*
THE RULE THIS TOOL WAS WRITTEN FOR, and the reason it is worth a tool.

	A token nothing defines resolves to nothing, so the shape renders
	INVISIBLE — in a document that still renders, still validates and still
	passes every other check in this repository. `CONTENT.md` records that
	thirteen figures of `web-fundamentals` lesson one were drawn against a
	different palette and were one command away from shipping exactly so.

	There is no symptom to notice and no test anywhere else that could have.
*/
func TestATokenNothingDefinesIsRefused(t *testing.T) {
	_, problems := check("at", drawing(`<rect fill="var(--phosfor)"/>`), nine)
	if !says(problems, "asks for `--phosfor`", "renders invisible") {
		t.Errorf("a token nothing defines was accepted:\n%s", listed(problems))
	}
}

// AND IT NAMES THE ONE SOMEBODY MEANT. A typo is the whole population of this
// failure — nobody invents a colour name from nothing — so the message that
// costs an investigation and the one that can be acted on while reading differ
// by this.
func TestTheMessageNamesTheTokenProbablyMeant(t *testing.T) {
	_, problems := check("at", drawing(`<rect fill="var(--phosfor)"/>`), nine)
	if !says(problems, "did you mean `--phosphor`?") {
		t.Errorf("the nearest token was not offered:\n%s", listed(problems))
	}

	// AND IT DOES NOT GUESS WILDLY. A name that is not a typo of anything gets
	// no suggestion, because a wrong one sends somebody to the wrong file.
	_, problems = check("at", drawing(`<rect fill="var(--brandcolour17)"/>`), nine)
	if says(problems, "did you mean") {
		t.Errorf("a name unlike any token was given a suggestion:\n%s", listed(problems))
	}
}

// ONE MESSAGE PER TOKEN, not one per use. A figure that draws twenty shapes in
// the same wrong colour is one mistake, and twenty lines of it would bury the
// other figures in the same run.
func TestARepeatedWrongTokenIsReportedOnce(t *testing.T) {
	_, problems := check("at", drawing(
		`<rect fill="var(--phosfor)"/><rect fill="var(--phosfor)"/><rect fill="var(--phosfor)"/>`), nine)
	if len(problems) != 1 {
		t.Errorf("one wrong token used three times gave %d messages:\n%s",
			len(problems), listed(problems))
	}
}

/*
A DIAGRAM A SCREEN READER CANNOT ANNOUNCE IS A STUDENT WHO CANNOT STUDY.

	This is an education product, so the usual sentence about accessibility
	being a degraded experience does not apply: the figure IS the explanation in
	the sections that carry one. `aria-label` is what is said instead of the
	drawing, and axe cannot see these — they are inside a JSON string in a
	Markdown file, not in a document any browser has loaded.
*/
func TestADrawingWithNoLabelIsRefused(t *testing.T) {
	fig := figure{SVG: `<svg role="img"><rect fill="var(--panel)"/></svg>`, Caption: "A thing."}
	if _, problems := check("at", fig, nine); !says(problems, "no `aria-label`") {
		t.Errorf("a drawing a reader cannot announce was accepted:\n%s", listed(problems))
	}
}

func TestAFigureWithNoCaptionIsRefused(t *testing.T) {
	fig := figure{SVG: `<svg role="img" aria-label="x"><rect fill="var(--panel)"/></svg>`}
	if _, problems := check("at", fig, nine); !says(problems, "no caption") {
		t.Errorf("a figure with no caption was accepted:\n%s", listed(problems))
	}
}

func TestAFigureWithNothingToDrawIsRefused(t *testing.T) {
	if _, problems := check("at", figure{Caption: "A thing."}, nine); !says(problems,
		"neither `svg` nor `image`") {
		t.Errorf("a figure with nothing in it was accepted:\n%s", listed(problems))
	}
}

// AND ONE CARRYING BOTH, where which is drawn is a fact about the renderer
// rather than about the figure.
func TestAFigureCarryingBothIsRefused(t *testing.T) {
	fig := figure{SVG: `<svg role="img" aria-label="x"/>`, Image: "diagram.png",
		Alt: "x", Caption: "A thing."}
	if _, problems := check("at", fig, nine); !says(problems, "carries both") {
		t.Errorf("an ambiguous figure was accepted:\n%s", listed(problems))
	}
}

/*
A LITERAL COLOUR IS COUNTED AND NOT REFUSED, and that is a decision rather than
an omission.

	`tools/term-capture` writes fixed values for text on a captured ground —
	`terminal.css` carries the paragraph naming which and at what contrast — so
	91 of the literals in this catalogue are correct. A capture is not a
	drawing, and nothing in the figure says which it is, so this tool reports
	the count and says it did not judge them. A check that silently skipped
	them would print like a check that found nothing.
*/
func TestALiteralColourIsCountedRatherThanRefused(t *testing.T) {
	fig := drawing(`<rect fill="#0a0e14"/><text fill="var(--paper)">x</text>`)
	literals, problems := check("at", fig, nine)
	if literals != 1 {
		t.Errorf("a literal colour was counted %d times, and the count is what the run "+
			"prints instead of a verdict", literals)
	}
	if len(problems) > 0 {
		t.Errorf("a literal colour was refused, and a capture legitimately carries one:\n%s",
			listed(problems))
	}
}

/*
THE PALETTE IS READ OUT OF THE CSS, and an empty one is a broken checker rather
than a broken catalogue.

	Without this, a stylesheet that moved or a regular expression that stopped
	matching would report every figure in the catalogue as wrong — hundreds of
	lines, all false, on a day somebody is looking for something real. It fails
	on the checker instead, in one sentence.
*/
func TestAPaletteThatCameBackEmptyFailsAsTheCheckerRatherThanTheContent(t *testing.T) {
	dir := t.TempDir()
	empty := filepath.Join(dir, "nothing.css")
	if err := os.WriteFile(empty, []byte("body{color:red}\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	palette, problems := readPalette([]string{empty})
	if len(palette) != 0 {
		t.Fatalf("a stylesheet with no custom property gave %d token(s)", len(palette))
	}
	if !says(problems, "broken checker rather than a broken catalogue") {
		t.Errorf("an empty palette was treated as an answer:\n%s", listed(problems))
	}
}

// AND THE REAL STYLESHEETS ARE THE TWO THIS TOOL NAMES. A token added to either
// is available to a figure the same day, with nothing to update here.
func TestTheRealPaletteHoldsBothFamilies(t *testing.T) {
	palette, problems := readPalette([]string{"../../ui/assets/base.css", "../../ui/assets/terminal.css"})
	if len(problems) > 0 {
		t.Fatalf("reading the palette:\n%s", listed(problems))
	}
	for _, token := range []string{"paper", "phosphor", "wire", "term-green", "term-white-bg"} {
		if !palette[token] {
			t.Errorf("`--%s` is not in the palette this tool reads, and a figure using it "+
				"would be reported as invisible when it is not", token)
		}
	}
}

/*
A GROUND OR A HAIRLINE USED AS TEXT IS INVISIBLE, and this rule caught its own
author.

	The FALSE box of lesson 1's three-valued logic figure was drawn with `wire`
	as both its border and its text. A border colour and an ink are different
	jobs; the palette names them apart and nothing was checking. Measured
	against the two grounds a figure is drawn on, in both themes, `wire` reaches
	at most 1.49 to one and `scan` at most 1.24, where AA asks 4.5.

	No other check here could see it. This tool asks whether a token exists, and
	axe never loads these: they live inside a JSON string in a Markdown file.
*/
func TestTextPaintedInAGroundIsRefused(t *testing.T) {
	for _, token := range []string{"wire", "scan"} {
		fig := drawing(`<text fill="var(--` + token + `)">FALSE</text>`)
		_, problems := check("at", fig, map[string]bool{token: true, "panel": true})
		if !says(problems, "paints text in `--"+token+"`", "nobody can read them") {
			t.Errorf("text painted in `--%s` was accepted:\n%s", token, listed(problems))
		}
	}
}

// AND A GROUND USED AS A GROUND IS FINE, which is what keeps the rule about
// text rather than about the token.
func TestAGroundUsedAsAFillIsNotRefused(t *testing.T) {
	fig := drawing(`<rect fill="var(--scan)" stroke="var(--wire)"/>` +
		`<text fill="var(--paper)">x</text>`)
	if _, problems := check("at", fig, nine); len(problems) > 0 {
		t.Errorf("a rectangle filled with a ground was refused:\n%s", listed(problems))
	}
}

/* ---------- and whether a translation translated anything ----------

   THE DEFECT THESE PIN REACHED PRODUCTION. Nine Portuguese figures drew
   `the row on disk`, `one lookup per row` and `walked once, together` in
   English, and every check in this repository passed on them, because each
   reads one file. */

// sans is a label drawn in the prose face — the one this pass asks about.
func sans(text string) string {
	return `<text font-family="'IBM Plex Sans', sans-serif">` + text + `</text>`
}

// mono is a label drawn in the code face, which is never asked about.
func mono(text string) string {
	return `<text font-family="'IBM Plex Mono', monospace">` + text + `</text>`
}

func pair(english, translated string) (figure, figure) {
	return figure{SVG: `<svg aria-label="a thing">` + english + `</svg>`, Caption: "A thing."},
		figure{SVG: `<svg aria-label="uma coisa">` + translated + `</svg>`, Caption: "Uma coisa."}
}

func TestALabelLeftInEnglishIsRefused(t *testing.T) {
	from, into := pair(sans("the row on disk"), sans("the row on disk"))
	problems := untranslated("at [pt]", from, into)
	if !says(problems, "the label is still", "the row on disk") {
		t.Errorf("a label a translation left in English was not reported:\n%s", listed(problems))
	}
}

func TestALabelTheTranslationTranslatedIsAccepted(t *testing.T) {
	from, into := pair(sans("the row on disk"), sans("a linha no disco"))
	if problems := untranslated("at [pt]", from, into); len(problems) > 0 {
		t.Errorf("a translated label was reported:\n%s", listed(problems))
	}
}

// THE DECISION IS THE `check-interface` RULE: an entry says somebody decided,
// where an absence says nobody looked.
func TestALabelRecordedAsTheSameWordIsAccepted(t *testing.T) {
	from, into := pair(sans("Debian"), sans("Debian"))
	into.Same = []string{"Debian"}
	if problems := untranslated("at [pt]", from, into); len(problems) > 0 {
		t.Errorf("a label decided to be the same word was reported:\n%s", listed(problems))
	}
}

// AND AN ENTRY NOTHING SAYS ANY MORE FAILS, which is the direction that keeps
// the list from becoming a place to put anything.
func TestAStaleSameEntryIsRefused(t *testing.T) {
	from, into := pair(sans("the row"), sans("a linha"))
	into.Same = []string{"a label that was rewritten"}
	problems := untranslated("at [pt]", from, into)
	if !says(problems, "`same` carries", "a label that was rewritten") {
		t.Errorf("a `same` entry matching no label was not reported:\n%s", listed(problems))
	}
}

/*
CODE IS NOT ASKED ABOUT, and the drawing is what says which is which.

	Most labels in these figures are SQL, plan nodes, header names and table
	rows — identical in every language, correctly. Asking about them would put
	238 findings in front of somebody of which thirty are real, and a check that
	cries wolf is one nobody reads. The mono face is the author's own statement
	that a label is code.
*/
func TestALabelInTheCodeFaceIsNotAskedAbout(t *testing.T) {
	from, into := pair(mono("SELECT customer_id")+mono("Seq Scan"),
		mono("SELECT customer_id")+mono("Seq Scan"))
	if problems := untranslated("at [pt]", from, into); len(problems) > 0 {
		t.Errorf("code drawn in the mono face was reported:\n%s", listed(problems))
	}
}

// A LABEL WITH NO LETTER CANNOT BE TRANSLATED. Mechanical, not a judgement.
func TestALabelWithNoLetterIsNotAskedAbout(t *testing.T) {
	from, into := pair(sans("1")+sans("×")+sans("02:30"), sans("1")+sans("×")+sans("02:30"))
	if problems := untranslated("at [pt]", from, into); len(problems) > 0 {
		t.Errorf("a label with nothing to translate was reported:\n%s", listed(problems))
	}
}

/*
A CAPTURE IS NOT A DRAWING, and this is structural rather than a guess about
content: `term-capture` writes the bytes a real terminal produced, painted in
the `--term-*` palette, and those bytes are the same in every language.
*/
func TestACapturedTerminalIsLeftAlone(t *testing.T) {
	captured := sans("Permission denied") + `<rect fill="var(--term-bg)"/>`
	from, into := pair(captured, captured)
	if problems := untranslated("at [pt]", from, into); len(problems) > 0 {
		t.Errorf("a captured terminal was asked to be translated:\n%s", listed(problems))
	}
}

// THE THREE THAT ARE ALWAYS PROSE. A caption is a sentence, an `alt` is what an
// image is announced as, and an `aria-label` is the whole figure for a reader
// who cannot see it — none of them is ever code.
func TestACaptionAnAltAndAnAriaLabelAreAsked(t *testing.T) {
	for _, one := range []struct {
		what string
		from figure
		into figure
	}{
		{"caption",
			figure{SVG: `<svg aria-label="a">x</svg>`, Caption: "The same sentence."},
			figure{SVG: `<svg aria-label="b">x</svg>`, Caption: "The same sentence."}},
		{"alt text",
			figure{Image: "a.png", Alt: "The same alt.", Caption: "Uma."},
			figure{Image: "a.png", Alt: "The same alt.", Caption: "Duas."}},
		{"aria-label",
			figure{SVG: `<svg aria-label="The same spoken sentence.">x</svg>`, Caption: "Uma."},
			figure{SVG: `<svg aria-label="The same spoken sentence.">x</svg>`, Caption: "Duas."}},
	} {
		problems := untranslated("at [pt]", one.from, one.into)
		if !says(problems, "the "+one.what+" is still") {
			t.Errorf("an untranslated %s was not reported:\n%s", one.what, listed(problems))
		}
	}
}

// A TRANSLATION REDRAWS NOTHING. A different number of labels means the two
// figures cannot be walked side by side, and every comparison after that would
// be against the wrong label.
func TestATranslationThatRedrewTheFigureIsRefused(t *testing.T) {
	from, into := pair(sans("one")+sans("two"), sans("um"))
	problems := untranslated("at [pt]", from, into)
	if !says(problems, "a translation redraws nothing") {
		t.Errorf("a translation with a different number of labels was not reported:\n%s",
			listed(problems))
	}
}

// AND THE REAL CATALOGUE PASSES, which is the claim the tool makes on every
// run and the one a fixture cannot make for it.
func TestEveryTranslatedFigureInTheCatalogueSaysItInItsOwnLanguage(t *testing.T) {
	if _, err := os.Stat(filepath.Join("..", "..", "content")); err != nil {
		t.Skip("no content tree beside this test")
	}
	pairs, problems := readTranslations(filepath.Join("..", "..", "content"))
	if pairs == 0 {
		t.Fatal("no figure was compared against a translation, so this test asserts nothing " +
			"— which is how a check comes to pass on a tree it never read")
	}
	if len(problems) > 0 {
		t.Errorf("%d figure(s) disagree with their translation:\n%s", len(problems), listed(problems))
	}
}
