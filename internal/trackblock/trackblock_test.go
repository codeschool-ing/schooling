package trackblock_test

import (
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/trackblock"
)

const section = "The README is opened first.\n\n" +
	"::: track frontend backend\n" +
	"A reviewer opens the live link.\n" +
	":::\n\n" +
	"::: track *\n" +
	"A reviewer opens what it produces.\n" +
	":::\n\n" +
	"Then the code.\n"

func TestAGroupIsTheBlocksThatFollowEachOther(t *testing.T) {
	groups, problems := trackblock.Parse(section)
	if len(problems) > 0 {
		t.Fatalf("a well-formed section was refused: %v", problems)
	}
	if len(groups) != 1 || len(groups[0]) != 2 {
		t.Fatalf("want one group of two blocks, got %v", groups)
	}
	if got := trackblock.Signature(groups); got != "[backend frontend | *]" {
		t.Errorf("signature %q", got)
	}
}

// Text between two blocks ends the first group: the second block is a new
// question for the reader, and it needs a `*` of its own.
func TestProseBetweenBlocksStartsANewGroup(t *testing.T) {
	text := section + "\n::: track frontend\nMore.\n:::\n\n::: track *\nMore, for anyone.\n:::\n"
	groups, problems := trackblock.Parse(text)
	if len(problems) > 0 {
		t.Fatalf("refused: %v", problems)
	}
	if len(groups) != 2 {
		t.Fatalf("want two groups, got %d", len(groups))
	}
}

// Every way a marker can be wrong has a sentence, because each one is a
// passage somebody meets wrongly — or never.
func TestAMalformedGroupIsRefusedAndSaysWhy(t *testing.T) {
	for name, c := range map[string]struct{ text, says string }{
		"no fallback":      {"::: track frontend\nx\n:::\n", "no `::: track *` block"},
		"never closed":     {"::: track *\nx\n", "never closed"},
		"closed twice":     {"::: track *\nx\n:::\n:::\n", "never opened"},
		"nested":           {"::: track *\n::: track frontend\nx\n:::\n:::\n", "do not nest"},
		"names nobody":     {"::: track\nx\n:::\n", "names nobody"},
		"unknown marker":   {"::: note\nx\n:::\n", "not a marker"},
		"named twice":      {"::: track frontend\na\n:::\n::: track frontend\nb\n:::\n::: track *\nc\n:::\n", "named again"},
		"star with others": {"::: track frontend *\na\n:::\n", "`*` shares a block"},
	} {
		_, problems := trackblock.Parse(c.text)
		joined := ""
		for _, p := range problems {
			joined += p.Error() + "\n"
		}
		if !strings.Contains(joined, c.says) {
			t.Errorf("%s: want a problem saying %q, got:\n%s", name, c.says, joined)
		}
	}
}

// A capture or a code block may print `:::` — it is showing it, not asking to
// vary.
func TestAMarkerInsideAFenceIsText(t *testing.T) {
	text := "```\n::: track frontend\n:::\n```\n"
	groups, problems := trackblock.Parse(text)
	if len(groups) != 0 || len(problems) != 0 {
		t.Errorf("a fenced marker was read as one: %v %v", groups, problems)
	}
}

func TestRenameTurnsSlugsIntoIDsAndLeavesTheRest(t *testing.T) {
	got := trackblock.Rename(section, map[string]string{"frontend": "tr-aaaaaaaa"})
	if !strings.Contains(got, "::: track tr-aaaaaaaa backend\n") {
		t.Errorf("the marker was not renamed:\n%s", got)
	}
	if !strings.Contains(got, "::: track *\n") {
		t.Errorf("`*` did not survive:\n%s", got)
	}
}

func TestForKeepsTheReadersPassageAndDropsTheMarkers(t *testing.T) {
	for track, want := range map[string]string{
		"frontend": "live link",
		"backend":  "live link",
		"security": "what it produces",
		"":         "what it produces",
	} {
		got := trackblock.For(section, track)
		if !strings.Contains(got, want) {
			t.Errorf("%q: want the passage mentioning %q, got:\n%s", track, want, got)
		}
		if strings.Contains(got, ":::") {
			t.Errorf("%q: a marker reached the reader:\n%s", track, got)
		}
		if !strings.Contains(got, "The README is opened first.") || !strings.Contains(got, "Then the code.") {
			t.Errorf("%q: the common text was lost:\n%s", track, got)
		}
	}
}
