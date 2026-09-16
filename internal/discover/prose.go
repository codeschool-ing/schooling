package discover

import (
	"strings"
)

/*
A lesson's prose as TEXT, and deliberately as nothing else.

	# WHY THIS IS NOT A RENDERER

	A lesson is written in Markdown, and the interface turns it into a screen
	with two pieces: `ui/app/api.js` splits the source into blocks — headings,
	tables, fenced code, figures, worked examples — and `ui/app/markdown.js`
	renders the prose inside them. Between them they are the thing a student
	reads, and `markdown.js` says why they live in the browser: "the server has
	no Markdown dependency and adding one is a decision about a dependency that
	outlives this screen".

	That decision is not this package's to reverse, and porting the pair is
	worse than either option. `markdown.js`'s own comment names the failure: "a
	renderer that quietly supported half of a feature — tables with no header
	row, nested lists one level deep — would be worse than one that supports
	none: the author would write it, see something that almost worked, and never
	be told." A second renderer in another language, kept in step by nobody,
	is that failure with a longer fuse.

	# SO THIS SUPPORTS NOTHING, WHICH IS THE ONE THING IT CANNOT HALF-DO

	It takes the words out and drops everything that is a construction: fences
	whole — code, figures, worked examples, the JSON of each — tables, and the
	inline markers around a word rather than the word. What comes back is
	paragraphs and headings, which is what a page is read for and what a search
	engine has to have.

	The lesson itself is one link away, in the interface, with its figures and
	its exercises. The page says so. A page that reproduced the lesson and got
	its tables wrong would be a worse copy of something the reader can have
	whole, one click from here.
*/

// Prose is what a section says, reduced to blocks of text.
type Prose struct {
	Heading string // "" for a paragraph
	Text    string
}

// A fence opens and closes with three backticks. Everything between is a
// construction — code a lesson is showing, a figure's JSON, a worked example —
// and none of it is prose.
const fence = "```"

// Extract is what a lesson says, as text. See the file comment.
func Extract(markdown string) []Prose {
	var out []Prose
	var paragraph []string

	closeParagraph := func() {
		if len(paragraph) > 0 {
			out = append(out, Prose{Text: inlineText(strings.Join(paragraph, " "))})
			paragraph = nil
		}
	}

	inFence := false
	for _, line := range strings.Split(markdown, "\n") {
		if strings.HasPrefix(strings.TrimSpace(line), fence) {
			closeParagraph()
			inFence = !inFence
			continue
		}
		if inFence {
			continue
		}

		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			closeParagraph()
			continue
		}

		// A table needs its second line to be known for certain, and none of it
		// is a sentence. A row is dropped rather than flattened into one.
		if strings.HasPrefix(trimmed, "|") {
			closeParagraph()
			continue
		}

		if hashes := countHashes(trimmed); hashes > 0 {
			closeParagraph()
			if title := inlineText(strings.TrimSpace(trimmed[hashes:])); title != "" {
				out = append(out, Prose{Heading: title})
			}
			continue
		}

		// A bullet or a numbered item is a sentence with a marker in front of
		// it. The marker goes; the sentence is a paragraph of its own, which is
		// what it reads as without the list around it.
		if item, ok := listItem(trimmed); ok {
			closeParagraph()
			out = append(out, Prose{Text: inlineText(item)})
			continue
		}

		if quote, ok := strings.CutPrefix(trimmed, ">"); ok {
			closeParagraph()
			out = append(out, Prose{Text: inlineText(strings.TrimSpace(quote))})
			continue
		}

		paragraph = append(paragraph, trimmed)
	}
	closeParagraph()
	return out
}

func countHashes(line string) int {
	n := 0
	for n < len(line) && line[n] == '#' {
		n++
	}
	if n == 0 || n > 6 || n >= len(line) || line[n] != ' ' {
		return 0
	}
	return n
}

func listItem(line string) (string, bool) {
	if rest, ok := strings.CutPrefix(line, "- "); ok {
		return strings.TrimSpace(rest), true
	}
	if rest, ok := strings.CutPrefix(line, "* "); ok {
		return strings.TrimSpace(rest), true
	}
	// `12. ` and nothing else that starts with a digit.
	for i := 0; i < len(line); i++ {
		if line[i] >= '0' && line[i] <= '9' {
			continue
		}
		if i > 0 && line[i] == '.' && i+1 < len(line) && line[i+1] == ' ' {
			return strings.TrimSpace(line[i+2:]), true
		}
		break
	}
	return "", false
}

/*
The markers around a word, taken off the word.

	`**bold**` is the word in bold and `[text](url)` is the text; a reader of
	this page wants both of those and neither of the marks. Nothing here is
	turned into a tag — that is the renderer this file is not.

	IT RUNS ON THE SOURCE AND THE TEMPLATE ESCAPES THE RESULT. So a lesson that
	contains `<script>` — and one about HTML will — arrives on the page as those
	characters rather than as markup, and does so because `html/template` puts it
	in a text node, not because anything here removed it.
*/
func inlineText(s string) string {
	s = strip(s, "`")
	s = strip(s, "**")
	s = strip(s, "*")
	s = strip(s, "_")
	return strings.TrimSpace(links(s))
}

// strip removes a marker that comes in pairs, leaving whatever it wrapped. An
// odd one out is left alone: a lone asterisk in a sentence is an asterisk.
func strip(s, marker string) string {
	for {
		open := strings.Index(s, marker)
		if open < 0 {
			return s
		}
		close := strings.Index(s[open+len(marker):], marker)
		if close < 0 {
			return s
		}
		close += open + len(marker)
		s = s[:open] + s[open+len(marker):close] + s[close+len(marker):]
	}
}

// `[what it says](where it goes)` -> `what it says`. The address is not text a
// person reads, and a page of bare URLs reads as spam to the one thing this
// page exists for.
func links(s string) string {
	var b strings.Builder
	for {
		open := strings.Index(s, "[")
		if open < 0 {
			b.WriteString(s)
			return b.String()
		}
		shut := strings.Index(s[open:], "](")
		if shut < 0 {
			b.WriteString(s)
			return b.String()
		}
		shut += open
		end := strings.Index(s[shut:], ")")
		if end < 0 {
			b.WriteString(s)
			return b.String()
		}
		end += shut
		b.WriteString(s[:open])
		b.WriteString(s[open+1 : shut])
		s = s[end+1:]
	}
}
