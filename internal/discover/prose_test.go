package discover

import (
	"strings"
	"testing"
)

// A reader from a search engine is on no track, so the page carries the `*`
// passage and none of the others — and never a marker.
func TestAPublicPageKeepsThePassageForAnyReader(t *testing.T) {
	got := Extract("The README is opened first.\n\n" +
		"::: track tr-aaaaaaaa\nA front-end reviewer opens the live link.\n:::\n\n" +
		"::: track *\nWhoever reviews it opens what it produces.\n:::\n")

	var text []string
	for _, p := range got {
		text = append(text, p.Text)
	}
	joined := strings.Join(text, "\n")
	if !strings.Contains(joined, "Whoever reviews it opens what it produces.") {
		t.Errorf("the passage for any reader is missing:\n%s", joined)
	}
	if strings.Contains(joined, "live link") || strings.Contains(joined, ":::") {
		t.Errorf("a track's passage or a marker reached the public page:\n%s", joined)
	}
	if !strings.Contains(joined, "The README is opened first.") {
		t.Errorf("the common text was lost:\n%s", joined)
	}
}
