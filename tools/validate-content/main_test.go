package main

import (
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
