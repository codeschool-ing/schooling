package catalog

import (
	"fmt"

	"github.com/codeschool-ing/schooling/internal/trackblock"
)

/*
checkTrackBlocks holds the passages written for one track to the catalogue
they sit in.

	`trackblock.Parse` knows the grammar and nothing about the school, so it can
	say a group has no `*` but not that `frontend` is a track, nor that the
	course is in it. Those are the two mistakes that pass every other check and
	still put the wrong words in front of somebody:

	- A NAME NO TRACK HAS is a passage no reader is ever on, so every reader
	  gets `*` — which is what a typo in a slug looks like from the screen. It
	  reads perfectly and it is never the passage it was written to be.

	- A TRACK THAT DOES NOT CONTAIN THE COURSE is the same failure one step
	  removed: the slug is real, and nobody on it can reach this section. It is
	  how a passage survives the day a course leaves a track, and it is what
	  that day should announce.

	AND THE TRANSLATION HAS THE SAME SHAPE. A Portuguese reader on `frontend`
	meets the `frontend` passage an English one does, so every language carries
	the same groups naming the same readers in the same order. The words inside
	are the translator's; the shape is not, because a group only English has is
	a passage the Portuguese reader silently never gets.
*/
func checkTrackBlocks(s *School) []error {
	var problems []error

	// Which courses each track reaches, by slug — which is how both the track
	// and the marker name them in `content/`.
	reaches := map[string]map[string]bool{}
	for _, t := range s.Tracks {
		reaches[t.Slug] = map[string]bool{}
		for _, c := range everyCourseIn(t) {
			reaches[t.Slug][c] = true
		}
	}

	for _, c := range s.Courses {
		for _, l := range c.Loaded {
			slugOf := map[string]string{}
			for _, sec := range l.Sections {
				slugOf[sec.ID] = sec.Slug
			}

			// The shape each section has in English, which every other language
			// is held to.
			shape := map[string]string{}
			for _, p := range l.Text {
				if p.Locale == sourceLocale {
					groups, _ := trackblock.Parse(p.Body)
					shape[p.SectionID] = trackblock.Signature(groups)
				}
			}

			for _, p := range l.Text {
				file := fmt.Sprintf("%s/%s/%s", c.Slug, l.ID, proseFile(slugOf[p.SectionID], p.Locale))

				groups, bad := trackblock.Parse(p.Body)
				for _, b := range bad {
					problems = append(problems, fmt.Errorf("%s: line %d: %s", file, p.Above+b.Line, b.Text))
				}

				for _, g := range groups {
					for _, b := range g {
						for _, name := range b.Tracks {
							if name == trackblock.Anyone {
								continue
							}
							courses, known := reaches[name]
							switch {
							case !known:
								problems = append(problems, fmt.Errorf(
									"%s: line %d: `::: track %s` names a track this school does not have "+
										"— no reader is ever on it, so every reader gets the `*` passage and "+
										"this one is never shown", file, p.Above+b.Line, name))
							case !courses[c.Slug]:
								problems = append(problems, fmt.Errorf(
									"%s: line %d: `::: track %s` is written for a track that does not "+
										"contain %s — nobody on it can reach this section", file, p.Above+b.Line, name, c.Slug))
							}
						}
					}
				}

				if p.Locale != sourceLocale {
					if want, ok := shape[p.SectionID]; ok {
						if got := trackblock.Signature(groups); got != want {
							problems = append(problems, fmt.Errorf(
								"%s varies by track as %s and the text it translates as %s — a reader "+
									"in either language has to meet the passage for their track, so the "+
									"groups, and the tracks each block names, are the same in every language",
								file, orNone(got), orNone(want)))
						}
					}
				}
			}
		}
	}
	return problems
}

// proseFile is the name a person knows the file by: `roles.md`, `roles.pt.md`.
func proseFile(slug, locale string) string {
	if locale == sourceLocale {
		return slug + ".md"
	}
	return slug + "." + locale + ".md"
}

func orNone(signature string) string {
	if signature == "" {
		return "nothing"
	}
	return signature
}

// TrackBlocksWithIDs is a section's Markdown with every track its markers name
// renamed from slug to id — the translation `cmd/load` makes before the prose
// reaches the mirror, where nothing speaks slugs.
func TrackBlocksWithIDs(markdown string, tracks []*Track) string {
	ids := make(map[string]string, len(tracks))
	for _, t := range tracks {
		ids[t.Slug] = t.ID
	}
	return trackblock.Rename(markdown, ids)
}
