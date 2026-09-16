package discover

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

/*
EVERY LESSON IN THE REPOSITORY, THROUGH THE EXTRACTOR.

	The cases above are shapes somebody thought of. This is the prose that
	exists — every `.md` under `content/`, which is what the snapshot loads into
	`catalog_prose` and therefore what these pages are written from.

	What it asserts is the one thing that would be embarrassing in public: that
	no CONSTRUCTION reaches the text. A figure's SVG, a fence of shell, the
	pipes of a table — each of those on a page would be visible from the search
	result, and none of them is a sentence.

	The front matter goes first, as it does on the way into the store: the
	section's title is a column there, not the first line of its body.
*/
func TestEveryRealLessonComesOutAsWords(t *testing.T) {
	var files []string
	_ = filepath.Walk("../../content", func(p string, info os.FileInfo, err error) error {
		if err == nil && strings.HasSuffix(p, ".md") {
			files = append(files, p)
		}
		return nil
	})
	if len(files) < 100 {
		t.Skipf("only %d lesson files here", len(files))
	}

	words, titleOnly := 0, 0
	for _, f := range files {
		body, err := os.ReadFile(f) //nolint:gosec // a walk of this repository's own content directory
		if err != nil {
			t.Fatal(err)
		}
		for _, p := range Extract(withoutFrontMatter(string(body))) {
			text := p.Text + p.Heading
			words += len(strings.Fields(text))
			for _, construction := range []string{"```", "schooling-figure", "<svg", "viewBox", "|---", "title:"} {
				if strings.Contains(text, construction) {
					t.Fatalf("%s: %q reached the text: %q", f, construction, text[:min(140, len(text))])
				}
			}
		}
		/* A SECTION MAY BE A TITLE AND NOTHING ELSE, and 170 of these are: the
		   `intro` and `closing` of a lesson carry their sentence in the title
		   and have no body. So "came out empty" is not a failure on its own —
		   the failure is coming out empty from a body that HAS something in
		   it, which is the extractor dropping prose rather than the author
		   writing none. */
		text := withoutFrontMatter(string(body))
		if len(Extract(text)) == 0 {
			titleOnly++
			if says(text) {
				t.Errorf("%s has a body and no prose came out of it", f)
			}
		}
	}

	t.Logf("%d lesson files, %d words of prose, %d that are a title and nothing else",
		len(files), words, titleOnly)
	if words < 100000 {
		t.Errorf("only %d words came out of the whole catalogue", words)
	}
}

// says is whether there is anything in here that is not a construction — the
// question `Extract` is answering, asked a second way so that agreeing with it
// means something.
func says(markdown string) bool {
	fenced := false
	for _, line := range strings.Split(markdown, "\n") {
		l := strings.TrimSpace(line)
		if strings.HasPrefix(l, "```") {
			fenced = !fenced
			continue
		}
		if fenced || l == "" || strings.HasPrefix(l, "|") {
			continue
		}
		return true
	}
	return false
}

// `---` ... `---` at the top, which the snapshot turns into columns.
func withoutFrontMatter(s string) string {
	if !strings.HasPrefix(s, "---\n") {
		return s
	}
	if end := strings.Index(s[4:], "\n---"); end >= 0 {
		return s[4+end+4:]
	}
	return s
}
