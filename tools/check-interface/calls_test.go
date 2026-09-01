package main

import "testing"

/* What counts as a fixed string, which is the whole question this tool asks of a
   source before it can check anything.

   THE DEFECT THESE HOLD IS THE ONE THAT FAILS TWICE. A call the scanner cannot
   see is not merely unchecked: the screen shows English in every language, AND
   the entry that would have translated it is reported stale — so acting on the
   report deletes the fix. `ui/my/app/queue.js` says it has cost this repository
   two strings, and the defence until now was a rule written in a comment. */

// THE ONE THAT WAS INVISIBLE. Two literals are one key, and it is the key the
// runtime asks the dictionary for — a joined string, not a pair of fragments.
func TestLiteralsJoinedByAPlusAreOneString(t *testing.T) {
	only(t, `const a = txt('a very long sentence ' + 'continued on the next line.');`,
		"a very long sentence continued on the next line.")

	// However many, and across lines, which is the reason to write one at all.
	only(t, `
	const a = txt('one ' +
	              'two ' +
	              'three');
	`, "one two three")

	// The quotes need not agree with each other; JavaScript does not care and
	// neither does the value.
	only(t, `const a = txt('single ' + "double");`, "single double")
}

/*
A VARIABLE ANYWHERE MEANS THE WHOLE CALL IS INVISIBLE, and that is deliberate.

	`txt('at or over ' + n)` is a key that depends on a value, and no dictionary
	can be written against one. What must not happen is the scanner reading the
	literal half and asking for `"at or over "` — a fragment, which is precisely
	the thing a translator cannot move within a sentence. So the pattern wants a
	literal at every position or it wants none of them.

	`internal/console/language_test.go` is what covers these instead, by reading
	the lists they are drawn from.
*/
func TestACallWithAValueInItIsStillInvisible(t *testing.T) {
	only(t, `const a = txt('at or over ' + n);`)
	only(t, `const a = txt(n + ' and counting');`)
	only(t, `const a = txt('a ' + 'b' + c);`)
	only(t, `const a = txt(word);`)

	// A template literal is not a fixed string either, for the same reason.
	only(t, "const a = txt(`over ${n}`);")
}

// AND A PLUS OUTSIDE THE CALL IS SOMEBODY ELSE'S. This interface builds its
// markup by concatenation, so a `txt()` call has a `+` on both sides of it far
// more often than not — reading those would join a sentence to its neighbour.
func TestOnlyThePlusesInsideTheCallCount(t *testing.T) {
	only(t, `
	const html = '<h1>' + esc(txt('Nothing due')) + '</h1>' +
	             '<p>' + esc(txt('Come back tomorrow.')) + '</p>';
	`, "Nothing due", "Come back tomorrow.")
}

// AN ESCAPED QUOTE SURVIVES THE JOIN. Each literal is unescaped on its own and
// then joined, so a `\'` in the first half cannot end the second.
func TestEscapesSurviveTheJoin(t *testing.T) {
	only(t, `const a = txt('it\'s ' + 'here');`, "it's here")
}
