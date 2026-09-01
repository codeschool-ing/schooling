package main

import "testing"

/* Blanking the comments, which is the difference between reading a file and
   reading what it says.

   THE DEFECT THESE HOLD WAS FOUND BY A COMMENT ABOUT THIS TOOL. A file
   explaining that the scanner reads literal calls only wrote one out as the
   example, and the example was counted as an interface string somebody had to
   translate. Every file where somebody has just learnt that rule hits it. */

// said is what the scanner would find in a source, after the comments go. It is
// the tool's own `saidIn` and not a second copy of the walk: a helper that
// reimplemented it would keep passing on the day the real one stopped working.
func said(source string) []string { return saidIn(source) }

func only(t *testing.T, source string, want ...string) {
	t.Helper()
	got := said(source)
	if len(got) != len(want) {
		t.Fatalf("found %q, want %q", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("found %q, want %q", got, want)
			return
		}
	}
}

// THE ONE THAT WAS FAILING. A rule explained in the syntax it is about.
func TestACommentedExampleIsNotAnInterfaceString(t *testing.T) {
	only(t, `
	// The scanner reads literal calls only, so txt('an example') is invisible.
	const a = txt('Due today');
	/* And in a block comment too: txt('another example'), which is prose. */
	const b = txt('Nothing due');
	`, "Due today", "Nothing due")
}

/*
A SLASH IS THREE THINGS IN JAVASCRIPT and only the tokens before it say which.

	`.replace(/&/g, …)` is in the very file that found this defect, and a scanner
	that read that slash as a comment would blank the rest of the line — taking a
	real string with it, which fails as a dictionary entry nothing says. The
	failure would have been loud, and about the wrong thing.
*/
func TestARegularExpressionIsNotAComment(t *testing.T) {
	only(t, `
	const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');
	const a = txt('after a pattern');
	`, "after a pattern")

	// A slash inside a character class does not end the pattern.
	only(t, `
	const p = /[^/]+/g;
	const a = txt('after a class');
	`, "after a class")

	// And division still divides: the character before it is a name.
	only(t, `
	const half = total / 2;
	const a = txt('after a division');
	`, "after a division")
}

// A COMMENT WRITTEN INSIDE A STRING IS TEXT. This tool's whole subject is text
// inside quotes, so a URL is the case that must not lose the rest of its line.
func TestSlashesInsideStringsAreNotComments(t *testing.T) {
	only(t, `
	const where = 'https://example.tld/path';
	const a = txt('after a url');
	const also = "a /* not a comment */ b";
	const b = txt('after a quoted block');
	`, "after a url", "after a quoted block")

	// A template literal counts as a string for the same reason.
	only(t, "const t = `https://x/y ${n}`;\nconst a = txt('after a template');",
		"after a template")
}

// AN ESCAPED QUOTE DOES NOT END A STRING, which is the other way to swallow a
// file: a mis-read closing quote leaves the scanner inside a string for the
// rest of it and finds nothing at all.
func TestAnEscapedQuoteDoesNotEndTheString(t *testing.T) {
	only(t, `
	const s = 'it\'s a string, with // in it';
	const a = txt('after an escape');
	`, "after an escape")
}

// AND THE BLANKING KEEPS THE FILE THE SAME LENGTH. Deleting a comment could
// join the token before it to the token after, which invents identifiers.
func TestBlankingDoesNotJoinTokens(t *testing.T) {
	source := "const a/* gone */= txt('kept');"
	out := withoutComments(source)
	if len(out) != len(source) {
		t.Errorf("the source is %d bytes and what came back is %d", len(source), len(out))
	}
	only(t, source, "kept")
}

// An unterminated comment is a broken file, and the answer is to blank the rest
// of it rather than to loop or to panic: the strings after it are not there to
// be found anyway.
func TestAnUnterminatedCommentDoesNotHang(t *testing.T) {
	only(t, "const a = txt('before');\n/* and then nothing closes this\nconst b = txt('after');",
		"before")
}
