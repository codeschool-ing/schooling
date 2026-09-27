/*
Package trackblock reads the passages of a section that are written for one
track and not another.

	# WHY A SECTION NEEDS THEM

	`portfolio-project` is in sixteen tracks, second from the end of every one,
	and its third lesson is "what somebody hiring in your field actually opens".
	A course that is the same whichever track reached it has to be generic at
	exactly the point where generic is useless; a course copied sixteen times has
	sixteen copies of everything that is not about the track. So one section
	carries its common text once and, where it has to differ, alternatives:

		The README is the first thing opened.

		::: track frontend
		A front-end reviewer opens the live link before the code.
		:::

		::: track data-science
		A data reviewer opens the notebook, and reads the first cell.
		:::

		::: track *
		Whoever reviews it opens the thing it produces before the code.
		:::

	Consecutive blocks, separated by nothing but blank lines, are ONE GROUP: the
	alternatives a reader sees one of. `*` is the reader whose track the group
	does not name — somebody on a different track, or on none, because a student
	can open a course from the catalogue without choosing a track at all.

	# WHY IT IS INSIDE THE SECTION AND NOT A SECTION OF ITS OWN

	Progress counts sections (A-05), and a certificate rests on them. A section
	that existed for one track and not another would make "how much of this
	course is done" depend on which map the student had open, and there is no
	enrolment on the server to say which that is: the track a student is on is
	the one they are looking at (`ui/app/api.js`, `enrol`). Varying the WORDS
	inside a section varies nothing anybody counts.

	# THE ONE GRAMMAR, IN THE ONE PLACE

	The checker refuses a malformed marker, the loader renames what the markers
	name, and the public pages keep the `*` passage — three readers, and a
	grammar spelt three times is three grammars. It is a library (see
	`libraries` in `internal/architecture_test.go`) because it is rules over a
	string: no table, no route, no module behind it.

	The interface reads the same markers in `ui/app/api.js`, which cannot import
	Go. What holds the two together is `tools/track-test`, which opens a lesson
	carrying a group and asserts which passage is on the screen.
*/
package trackblock

import (
	"fmt"
	"sort"
	"strings"
)

// Anyone is the token for the reader whose track a group does not name.
const Anyone = "*"

// The two marker lines. Nothing else that starts with `:::` means anything, and
// a line that does is refused rather than shown: a typo in a marker would
// otherwise put every alternative on the screen at once, in a row, and read as
// a section that repeats itself.
const (
	opener = "::: track"
	closer = ":::"
	marker = ":::"
	fence  = "```"
)

// Problem is one way the markers are wrong, at the line it was found on.
//
// THE LINE IS KEPT APART FROM THE SENTENCE because the text parsed is a
// section's body, and a person fixes the FILE, which has front matter above
// the body. The caller knows how many lines that is; this package does not.
type Problem struct {
	Line int
	Text string
}

func (p Problem) Error() string { return fmt.Sprintf("line %d: %s", p.Line, p.Text) }

func problem(line int, format string, args ...any) Problem {
	return Problem{Line: line, Text: fmt.Sprintf(format, args...)}
}

// Block is one alternative: the line its marker is on, and who it is for.
type Block struct {
	Line   int      // 1-based, in the text that was parsed
	Tracks []string // as written — slugs in `content/`, ids once loaded
}

// Group is the alternatives a reader sees exactly one of.
type Group []Block

// Signature is what a translation has to agree with: the same groups, naming
// the same readers, in the same order. The words inside are free; the shape is
// not, because a Portuguese reader on `frontend` must meet the passage an
// English one does, and a group only one language has is a passage the other
// language's reader never meets.
func Signature(groups []Group) string {
	var parts []string
	for _, g := range groups {
		var blocks []string
		for _, b := range g {
			tracks := append([]string(nil), b.Tracks...)
			sort.Strings(tracks)
			blocks = append(blocks, strings.Join(tracks, " "))
		}
		parts = append(parts, "["+strings.Join(blocks, " | ")+"]")
	}
	return strings.Join(parts, " ")
}

// Parse finds the groups in a section's Markdown, and every way the markers in
// it are wrong.
//
// A LINE INSIDE A FENCE IS NEVER A MARKER. A lesson about this very feature
// would show one in a code block, and a capture could print `:::` — neither is
// the section asking to vary.
func Parse(markdown string) ([]Group, []Problem) {
	var (
		groups   []Group
		problems []Problem
		current  Group
		open     *Block
		inFence  bool
		// Whether anything but blank lines has appeared since the last block
		// closed, which is what ends a group.
		between bool
	)

	finish := func() {
		if len(current) > 0 {
			problems = append(problems, checkGroup(current)...)
			groups = append(groups, current)
			current = nil
		}
	}

	lines := strings.Split(markdown, "\n")
	for i, raw := range lines {
		n := i + 1
		line := strings.TrimRight(raw, " \t\r")

		if strings.HasPrefix(strings.TrimLeft(line, " \t"), fence) {
			inFence = !inFence
			if open == nil {
				between = true
			}
			continue
		}
		if inFence {
			continue
		}

		switch {
		case line == closer:
			if open == nil {
				problems = append(problems, problem(n, "`:::` closes a track block that was never opened"))
				continue
			}
			current = append(current, *open)
			open = nil
			between = false

		case line == opener || strings.HasPrefix(line, opener+" "):
			if open != nil {
				problems = append(problems, problem(n, "a track block opens inside the one opened on line %d — "+
					"close that one with `:::` first; blocks do not nest", open.Line))
				continue
			}
			if between {
				finish()
			}
			tracks := strings.Fields(strings.TrimPrefix(line, opener))
			if len(tracks) == 0 {
				problems = append(problems, problem(n, "`::: track` names nobody — write the tracks it is for, or `*` "+
					"for every other reader"))
			}
			open = &Block{Line: n, Tracks: tracks}

		case strings.HasPrefix(line, marker):
			problems = append(problems, problem(n, "%q is not a marker this format knows — a track block opens with "+
				"`::: track <track> …` and closes with `:::` alone", line))

		default:
			if open == nil && strings.TrimSpace(line) != "" {
				between = true
			}
		}
	}

	if open != nil {
		problems = append(problems, problem(open.Line, "the track block opened here is never closed — end it with `:::`"))
	}
	finish()
	return groups, problems
}

// checkGroup refuses a group that some reader would meet wrongly.
func checkGroup(g Group) []Problem {
	var problems []Problem
	seen := map[string]int{}
	anyone := 0
	for _, b := range g {
		for _, t := range b.Tracks {
			if t == Anyone {
				anyone++
				if len(b.Tracks) > 1 {
					problems = append(problems, problem(b.Line, "`*` shares a block with named tracks — `*` already means "+
						"everybody the group does not name, so the others are either "+
						"redundant or meant to have their own block"))
				}
			}
			if first, ok := seen[t]; ok {
				problems = append(problems, problem(b.Line, "%s is named again, after line %d in the same group — a reader "+
					"sees one passage of a group, so a second one for them can never be shown", t, first))
				continue
			}
			seen[t] = b.Line
		}
	}
	if anyone == 0 {
		problems = append(problems, problem(g[0].Line, "this group has no `::: track *` block — a reader on any other track, "+
			"or on none, would meet nothing here at all, and nothing on the screen would "+
			"say a passage was missing"))
	}
	return problems
}

// Rename rewrites what each marker names through `to`: slugs in, ids out.
//
// A NAME `to` DOES NOT KNOW IS LEFT AS WRITTEN, and so is `*`. The loader only
// runs this on a catalogue that validated, where every name resolves; leaving
// the rest alone means a mistake reaches the reader as the slug somebody typed
// rather than as an empty string that matches no track and shows no passage.
func Rename(markdown string, to map[string]string) string {
	lines := strings.Split(markdown, "\n")
	inFence := false
	for i, raw := range lines {
		line := strings.TrimRight(raw, " \t\r")
		if strings.HasPrefix(strings.TrimLeft(line, " \t"), fence) {
			inFence = !inFence
			continue
		}
		if inFence || line != opener && !strings.HasPrefix(line, opener+" ") {
			continue
		}
		names := strings.Fields(strings.TrimPrefix(line, opener))
		for j, name := range names {
			if id, ok := to[name]; ok {
				names[j] = id
			}
		}
		lines[i] = strings.TrimSpace(opener + " " + strings.Join(names, " "))
	}
	return strings.Join(lines, "\n")
}

// For is the section as one reader meets it: the text outside every group,
// and inside each group the passage for `track` — or the `*` passage, when the
// group does not name it. The markers themselves go.
//
// `track` is whatever the markers name: a slug before the loader, an id after
// it. "" is a reader on no track, and gets `*` everywhere.
func For(markdown, track string) string {
	groups, _ := Parse(markdown)
	if len(groups) == 0 {
		return markdown
	}

	// Which block of each group this reader gets, by the line it opens on.
	keep := map[int]bool{}
	for _, g := range groups {
		chosen := -1
		for _, b := range g {
			for _, t := range b.Tracks {
				if t == track && track != "" {
					chosen = b.Line
				}
			}
		}
		if chosen < 0 {
			for _, b := range g {
				if len(b.Tracks) == 1 && b.Tracks[0] == Anyone {
					chosen = b.Line
				}
			}
		}
		keep[chosen] = true
	}

	var out []string
	inFence := false
	inBlock, showing := false, false
	for i, raw := range strings.Split(markdown, "\n") {
		n := i + 1
		line := strings.TrimRight(raw, " \t\r")

		if strings.HasPrefix(strings.TrimLeft(line, " \t"), fence) {
			inFence = !inFence
		} else if !inFence {
			if !inBlock && (line == opener || strings.HasPrefix(line, opener+" ")) {
				inBlock, showing = true, keep[n]
				continue
			}
			if inBlock && line == closer {
				inBlock = false
				continue
			}
		}
		if inBlock && !showing {
			continue
		}
		out = append(out, raw)
	}
	return strings.Join(out, "\n")
}
