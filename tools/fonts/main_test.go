package main

import (
	"strings"
	"testing"
)

// THE RANGE IS THE CLAIM AND THE CLAIM IS WHAT IS CHECKED. `validate-content`
// reads `unicode-range` out of the stylesheet to say whether the catalogue
// draws with a character nobody ships, so a cut whose declared range does not
// match the characters it was cut from does not fail loudly — it makes that
// check lie, in whichever direction the mismatch goes.
func TestTheDeclaredRangeIsTheCharactersAskedFor(t *testing.T) {
	for _, c := range []struct {
		name, declared, want string
		ok                   bool
	}{
		{"exactly the block", "U+2500-257f", boxOnly(), true},
		{"the same, spelled in capitals", "U+2500-257F", boxOnly(), true},
		{"a list of single points", "U+2190, U+2192", "←→", true},
		{"narrower than asked", "U+2500-2510", boxOnly(), false},
		{"wider than asked", "U+2500-25ff", boxOnly(), false},
		{"nothing at all", "", boxOnly(), false},
	} {
		err := rangeCovers(c.declared, c.want)
		if c.ok && err != nil {
			t.Errorf("%s: %v", c.name, err)
		}
		if !c.ok && err == nil {
			t.Errorf("%s: `%s` was accepted, and it should not be", c.name, c.declared)
		}
	}
}

// A WIDER RANGE IS THE ONE WORTH A SENTENCE, because it is the mismatch that
// looks harmless: the browser still picks the right face, and the font still
// has no glyph. What changes is that the stylesheet now says it does.
func TestAWiderRangeSaysWhichCharacterItInvented(t *testing.T) {
	err := rangeCovers("U+2500-25ff", boxOnly())
	if err == nil {
		t.Fatal("a range past the characters asked for has to be refused")
	}
	if !strings.Contains(err.Error(), "U+2580") {
		t.Errorf("the message has to name the first character it invented, so there is "+
			"something to go and look at: %v", err)
	}
}

// The catalogue's own list, so a change to `terminalGlyphs` is a change the
// test sees too rather than one it happens to agree with.
func TestTheCutAsksForWholeBlocksAndNamedArrows(t *testing.T) {
	for _, r := range []rune{0x2500, 0x257F, 0x2580, 0x259F, '→', '←'} {
		if !strings.ContainsRune(terminalGlyphs, r) {
			t.Errorf("the cut does not ask for %q (U+%04X)", r, r)
		}
	}
	// `●` is the one the catalogue needs and IBM Plex Mono does not have, so
	// asking for it would produce a range claiming a glyph that is not there.
	if strings.ContainsRune(terminalGlyphs, '●') {
		t.Error("U+25CF is not in this font; asking for it would widen the range over nothing")
	}
}

func boxOnly() string {
	var b strings.Builder
	for r := rune(0x2500); r <= 0x257F; r++ {
		b.WriteRune(r)
	}
	return b.String()
}
