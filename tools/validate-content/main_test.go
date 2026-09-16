package main

import "testing"

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
