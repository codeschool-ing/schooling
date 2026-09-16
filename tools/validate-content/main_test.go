package main

import (
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

// The mono family covers ASCII and the box-drawing block, which is what
// `ui/assets/fonts/fonts.css` declares after `go run ./tools/fonts`.
func mono() coverage {
	c := coverage{}
	for r := rune(0x20); r <= 0x7E; r++ {
		c[r] = true
	}
	for r := rune(0x2500); r <= 0x257F; r++ {
		c[r] = true
	}
	return c
}

func TestAFenceIsWalkedAndProseIsNot(t *testing.T) {
	body := "A paragraph with ✦ in it, which is prose and not a grid.\n" +
		"\n" +
		"```\n" +
		"┌────┐\n" +
		"│ ok │\n" +
		"└────┘\n" +
		"```\n" +
		"\n" +
		"| `○` | stopped |\n"

	if found := drawnWith(body, mono()); len(found) != 0 {
		t.Errorf("the box characters are covered and the other two are prose, so this reports "+
			"nothing; got %v", found)
	}
}

// THE BUG THIS FILE EXISTS FOR. A figure's fence closes with the same ``` that
// opens any other, so a toggle that only looks at the opening line treats the
// CLOSE of a drawing as the START of a block — and reads the rest of the
// section, tables and all, as code. The first run of the check did exactly
// that and reported a table row as a broken drawing.
func TestTheCloseOfADrawingIsNotTheStartOfABlock(t *testing.T) {
	body := "```schooling-figure\n" +
		"{\"svg\": \"<svg><text>✦</text></svg>\", \"caption\": \"a drawing\"}\n" +
		"```\n" +
		"\n" +
		"| hollow `○` | stopped, and nobody is complaining |\n"

	if found := drawnWith(body, mono()); len(found) != 0 {
		t.Errorf("everything here is either inside a drawing or prose, and neither is this "+
			"check's; got %v", found)
	}
}

func TestACharacterNobodyShipsIsFoundWithItsLine(t *testing.T) {
	body := "Prose.\n" +
		"\n" +
		"```\n" +
		"ana@vm:~$ systemctl status nginx\n" +
		"● nginx.service - a state dot this font has never had\n" +
		"```\n"

	found := drawnWith(body, mono())
	if len(found) != 1 {
		t.Fatalf("one character in the block is outside the font; got %v", found)
	}
	if found[0].glyph != '●' {
		t.Errorf("the character is the state dot, got %q", found[0].glyph)
	}
	// The body's lines are counted from one, so the reader can open the file
	// and look at the line the message names.
	if found[0].line != 5 {
		t.Errorf("it is on line 5 of the body, the message said %d", found[0].line)
	}
}

// A tab is a character no font draws, and every fence in the catalogue that
// shows a Makefile or a Go program has one. Reporting it would be reporting
// the whole of `linux-terminal` lesson eight.
func TestATabIsNotAMissingGlyph(t *testing.T) {
	if found := drawnWith("```\nif true; then\n\techo yes\nfi\n```\n", mono()); len(found) != 0 {
		t.Errorf("a tab is whitespace, not a glyph the font is missing; got %v", found)
	}
}

// A course with two lessons: the first has three sections, the second has two.
// So `section 4` is a number nothing in it can show.
func twoLessons() *catalog.School {
	sec := func(n int) []catalog.Section {
		out := make([]catalog.Section, n)
		return out
	}
	return &catalog.School{Courses: []*catalog.Course{{
		ID: "co-x",
		Loaded: []*catalog.Lesson{
			{ID: "le-1", Sections: sec(3)},
			{ID: "le-2", Sections: sec(2)},
		},
	}}}
}

func refs(t *testing.T, lesson int, body string) []error {
	t.Helper()
	s := twoLessons()
	s.Courses[0].Loaded[lesson].Text = []catalog.Prose{
		{SectionID: "se-a", Locale: "en", Body: body},
	}
	return checkSectionReferences("code", s)
}

// THE LOUD HALF: a number no lesson in this course has.
func TestAReferencePastTheEndOfItsLessonIsReported(t *testing.T) {
	if got := refs(t, 0, "The rule is in section 4, which explains it."); len(got) != 1 {
		t.Errorf("lesson 1 has three sections, so `section 4` is unreachable; got %v", got)
	}
	if got := refs(t, 0, "The rule is in section 3, which explains it."); len(got) != 0 {
		t.Errorf("`section 3` is the last section of lesson 1 and resolves; got %v", got)
	}
}

// THE QUIET HALF, AND IT IS THE ONE THAT COST SOMETHING. A reference that names
// a lesson is measured against THAT lesson, not the one it is written in — so a
// section 3 written in lesson 1 and pointing at lesson 2 is wrong even though
// lesson 1 has a third section.
func TestAReferenceIsMeasuredAgainstTheLessonItNames(t *testing.T) {
	for _, body := range []string{
		"Covered in section 3 of lesson 2.",
		"Covered in lesson 2 section 3.",
	} {
		if got := refs(t, 0, body); len(got) != 1 {
			t.Errorf("%q: lesson 2 has two sections; got %v", body, got)
		}
	}
	if got := refs(t, 0, "Covered in lesson 2 section 2."); len(got) != 0 {
		t.Errorf("lesson 2 has a second section; got %v", got)
	}
}

// A list of numbers is a list of references, and the last one is as checkable
// as the first. `sections 04 and 09` reported only the 04 until this said so.
func TestEveryNumberInAListIsChecked(t *testing.T) {
	if got := refs(t, 0, "Both sections 2 and 9 say it."); len(got) != 1 {
		t.Errorf("the 9 is past the end of lesson 1; got %v", got)
	}
	if got := refs(t, 1, "Compare seções 1 a 5 do outro lado."); len(got) != 1 {
		t.Errorf("Portuguese counts too, and lesson 2 has two sections; got %v", got)
	}
}

// A transcript may say anything. `# section 300 of the manual` inside a fence
// is not a cross-reference and this check has no business reading it.
func TestAFenceIsNotACrossReference(t *testing.T) {
	body := "Prose.\n\n```\n$ echo section 300\n```\n\nMore prose.\n"
	if got := refs(t, 0, body); len(got) != 0 {
		t.Errorf("the only number here is inside a fence; got %v", got)
	}
}

// A NARRATOR SAYS THE NUMBER, and nothing was reading the scripts at all.
func TestASpokenReferenceIsCheckedToo(t *testing.T) {
	s := twoLessons()
	s.Courses[0].Loaded[0].Sections[0] = catalog.Section{
		ID: "se-v", Kind: catalog.KindVideo,
		Videos: []catalog.Video{{Script: "Read it the way section four taught you."}},
	}
	if got := checkSectionReferences("code", s); len(got) != 1 {
		t.Errorf("lesson 1 has three sections, so a spoken `section four` is unreachable; got %v", got)
	}

	s.Courses[0].Loaded[0].Sections[0].Videos[0].Script = "Read it the way section three taught you."
	if got := checkSectionReferences("code", s); len(got) != 0 {
		t.Errorf("`section three` is the last section of lesson 1; got %v", got)
	}
}

// AND THE LONGER WORD WINS, which is the closing `\b` doing it rather than the
// order of the alternation. Without the boundary `seven` matches inside
// `seventeen` and a reference that is fine reads as broken — the Python sketch
// of this check had no boundary and reported three of its four findings against
// the word `seven` inside a longer one.
func TestSeventeenIsNotSeven(t *testing.T) {
	if got := spellOut("section seventeen"); got != "section 17" {
		t.Errorf("spellOut(%q) = %q, want %q", "section seventeen", got, "section 17")
	}
	if got := spellOut("seção dezessete"); got != "seção 17" {
		t.Errorf("spellOut(%q) = %q, want %q", "seção dezessete", got, "seção 17")
	}
	// THIS ASSERTION USED TO READ `"19 and ninety"`, because the table stopped at
	// twenty and the comment above it argued that was enough. It was not: three
	// compound numbers were already written in the scripts, every one of them a
	// course-wide reference. The tens are in the table now, and this line is the
	// one that had to change to say so.
	if got := spellOut("nineteen and ninety"); got != "19 and 90" {
		t.Errorf("the tens are read now; got %q", got)
	}
}

func oneScript(script string, seconds int) *catalog.School {
	return &catalog.School{Courses: []*catalog.Course{{
		ID: "co-x",
		Loaded: []*catalog.Lesson{{
			ID: "le-1",
			Sections: []catalog.Section{{
				ID: "se-v", Kind: catalog.KindVideo,
				Videos: []catalog.Video{{Script: script, Seconds: seconds}},
			}},
		}},
	}}}
}

// Sixty words is a minute at one a second; the band is 1.0 to 3.0.
func TestADurationNoNarratorCouldMeetIsReported(t *testing.T) {
	words := strings.Repeat("word ", 300)

	for _, c := range []struct {
		seconds int
		want    int
		why     string
	}{
		{seconds: 60, want: 1, why: "5.00 words a second is faster than anyone speaks"},
		{seconds: 99, want: 1, why: "3.03 is just past the ceiling"},
		{seconds: 100, want: 0, why: "3.00 is the ceiling exactly, and the band includes it"},
		{seconds: 150, want: 0, why: "2.00 is ordinary narration"},
		{seconds: 300, want: 0, why: "1.00 is the floor and a demonstration script sits near it"},
		{seconds: 400, want: 1, why: "0.75 is a video that is three quarters silence"},
	} {
		got := checkNarrationRate("code", oneScript(words, c.seconds))
		if len(got) != c.want {
			t.Errorf("%d words in %ds: got %d problem(s), want %d — %s",
				300, c.seconds, len(got), c.want, c.why)
		}
	}
}

// THE CUES ARE NOT SPOKEN. `{{terminal}}` tells the renderer to cut to a shot;
// counting it as a word makes a script look longer than it is, and on a short
// script with many cues that is the difference between passing and failing.
func TestCuesAreNotCountedAsWords(t *testing.T) {
	spoken := strings.Repeat("word ", 150)
	cues := strings.Repeat("{{shot}} ", 150)
	if got := checkNarrationRate("code", oneScript(spoken+cues, 75)); len(got) != 0 {
		t.Errorf("150 spoken words in 75s is 2.00 a second; the cues must not count: %v", got)
	}
}

// A script with no duration, or a duration with no script, is not this check's
// to judge — there is no rate to compute.
func TestNothingToMeasureIsNotAProblem(t *testing.T) {
	for _, s := range []*catalog.School{oneScript("", 60), oneScript("some words here", 0)} {
		if got := checkNarrationRate("code", s); len(got) != 0 {
			t.Errorf("got %v, want nothing to report", got)
		}
	}
}

// THE HOLE THIS FILE SHIPPED WITH. The first version of `spellOut` carried
// units, teens and twenty, and argued that a compound number would be naming
// something no lesson has. That is true, and it is what the rule is FOR: three
// were already written — "section seventy-eight", "sections seventy-nine and
// eighty-one", "section ninety-six" — and the table stopped one word short of
// seeing any of them.
func TestACompoundSpokenNumberIsRead(t *testing.T) {
	for _, c := range [][2]string{
		{"section seventeen", "section 17"},
		{"section twenty-one", "section 21"},
		{"section seventy-eight", "section 78"},
		{"section ninety-six", "section 96"},
		{"section one hundred", "section 100"},
		{"seção dezessete", "seção 17"},
		{"nothing numeric here", "nothing numeric here"},
	} {
		if got := spellOut(c[0]); got != c[1] {
			t.Errorf("spellOut(%q) = %q, want %q", c[0], got, c[1])
		}
	}
}

// AND THE ONE THAT DECIDES WHETHER THE HOLE IS CLOSED OR MOVED. Reading the
// "and" of "seventy-nine and eighty-one" as part of one number gives 160 —
// which is inside a 228-section course, so it would pass, and the defect would
// survive the fix meant to catch it.
func TestAndSeparatesTwoSpokenNumbers(t *testing.T) {
	if got := spellOut("sections seventy-nine and eighty-one"); got != "sections 79 and 81" {
		t.Errorf("got %q, want %q — 160 is in range and would pass", got, "sections 79 and 81")
	}

	// The cost of that choice, stated where it can be seen: this is wrong, and
	// harmless, because the rule only reads the number after `section`.
	if got := spellOut("exit one hundred and twenty-seven"); got != "exit 100 and 27" {
		t.Errorf("got %q, want the documented %q", got, "exit 100 and 27")
	}
}

// A spoken reference is measured against the lesson it is in, like any other.
func TestASpokenCompoundOutOfRangeIsReported(t *testing.T) {
	s := twoLessons()
	s.Courses[0].Loaded[0].Sections[0] = catalog.Section{
		ID: "se-v", Kind: catalog.KindVideo,
		Videos: []catalog.Video{{Script: "You saw why in section seventy-eight."}},
	}
	if got := checkSectionReferences("code", s); len(got) != 1 {
		t.Errorf("lesson 1 has three sections; got %v", got)
	}
}

// THE MARK A RENUMBERING LEFT. Three of these shipped, and the shape is one
// nobody writes: the prefix repeated with only a possessive between it and the
// reference that already had one.
func TestALessonNamedTwiceIsReported(t *testing.T) {
	say := func(body string) []error {
		s := twoLessons()
		s.Courses[0].Loaded[0].Text = []catalog.Prose{{SectionID: "se-a", Locale: "en", Body: body}}
		return checkDoubledLesson("code", s)
	}

	for _, body := range []string{
		"That is the payoff of lesson 2's lesson 2 section 01 being a standard.",
		"It opens the editor of lesson 2 lesson 2 section 01 to do it.",
		"Recolhe códigos de saída continuamente (aula 2, aula 2 seção 01).",
	} {
		if got := say(body); len(got) != 1 {
			t.Errorf("%q names its lesson twice; got %v", body, got)
		}
	}

	// AND THE ONE IT MUST NOT TOUCH: the same lesson named twice, correctly,
	// because there are two references and two sections.
	for _, body := range []string{
		"Lesson 2 section 01's convention, and lesson 2 section 02's table.",
		"Covered in lesson 1 section 03 and in lesson 2 section 01.",
	} {
		if got := say(body); len(got) != 0 {
			t.Errorf("%q is two references, not a doubled prefix; got %v", body, got)
		}
	}
}
