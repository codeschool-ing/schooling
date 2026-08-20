package catalog

import (
	"encoding/json"
	"fmt"
	"maps"
	"regexp"
	"slices"
	"sort"
	"strconv"
	"strings"
)

// Validate says everything that is wrong with a school.
//
// IT IS THE REVIEWER. There is no human one, so this runs in CI over the files
// and refuses a pull request rather than warning about it (C-14). Every check
// here exists because its absence has a cost that is paid later and by a
// student.
func Validate(school *School) []error {
	var problems []error

	problems = append(problems, checkSchool(school)...)
	problems = append(problems, checkIDs(school)...)
	problems = append(problems, checkLessons(school)...)
	problems = append(problems, checkExercises(school)...)
	problems = append(problems, checkTracks(school)...)
	problems = append(problems, checkTracksAreOrdered(school)...)
	problems = append(problems, checkRequires(school)...)
	problems = append(problems, checkCourseText(school)...)
	problems = append(problems, checkExerciseText(school)...)

	sort.Slice(problems, func(i, j int) bool {
		return problems[i].Error() < problems[j].Error()
	})
	return problems
}

// A slug is the readable name. It appears in an address and in a file name, it
// is what every reference inside `content/` uses, and it is free to change.
var slug = regexp.MustCompile(`^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`)

/*
An id is opaque, and this is what makes it so.

	`tr-p00q6jw0`, `co-cbwm5kwa`, `le-5he7q8tg`, `se-gy02rmmz`: two letters
	saying what kind of thing it is, then eight characters of Crockford's base32
	— no i, no l, no o, no u, so nothing is ambiguous when it is read off a
	screen and typed into a query.

	WHY A SHAPE AND NOT JUST "SOMETHING UNIQUE". A generated id nobody checks
	drifts back towards being derived: the next person adding a course by hand
	writes `co-statistics`, it is unique, everything works, and the property the
	opaque id existed for is quietly gone. It is the same failure the topic ids
	were made to end, arriving through the door marked convenience.

	THE PREFIX IS FOR PEOPLE, NOT FOR CODE. It is there so `se-gy02rmmz` in a log
	or an error identifies itself without a join. Nothing may branch on it: a
	`strings.HasPrefix(id, "co-")` deciding behaviour is type information smuggled
	inside a string, which is worse than the column it is standing in for.
*/
var opaqueID = regexp.MustCompile(`^(tr|co|le|se|ex)-[0-9a-hjkmnp-tv-z]{8}$`)

// claim records that an id belongs to something, and reports the second thing
// that says it owns the same one.
func claim(taken map[string]string, id, what string) []error {
	if id == "" {
		return nil // already reported as missing, by whoever asked for it
	}
	if had, ok := taken[id]; ok {
		return []error{fmt.Errorf(
			"%s and %s have the same id %q — two things one student's records cannot tell apart",
			had, what, id)}
	}
	taken[id] = what
	return nil
}

func checkID(id, prefix, what string) []error {
	if opaqueID.MatchString(id) && strings.HasPrefix(id, prefix+"-") {
		return nil
	}
	return []error{fmt.Errorf(
		"%s has the id %q, and an id is %q and eight characters of 0-9a-z without i, l, o or u "+
			"— for example %s-4mzk8p2r. It is generated once and never derived from a name, "+
			"because a name is a thing somebody rewrites", what, id, prefix+"-…", prefix)}
}

func checkSchool(s *School) []error {
	var problems []error

	if !slug.MatchString(s.ID) {
		problems = append(problems, fmt.Errorf(
			"the school id %q is not a slug — it becomes a subdomain, so it is lowercase "+
				"letters, digits and hyphens", s.ID))
	}
	if strings.TrimSpace(s.Name) == "" {
		problems = append(problems, fmt.Errorf("the school %q has no name", s.ID))
	}
	if len(s.Locales) == 0 {
		problems = append(problems, fmt.Errorf(
			"the school %q lists no locales, so nothing can decide which translation to serve", s.ID))
	}
	if len(s.Courses) == 0 {
		problems = append(problems, fmt.Errorf("the school %q has no courses", s.ID))
	}
	return problems
}

// Every id is a slug and unique within its scope, and nothing anywhere joins by
// anything else.
func checkIDs(s *School) []error {
	var problems []error

	/* BOTH NAMES ARE CHECKED, AND BOTH HAVE TO BE UNIQUE.

	   The slug because two courses sharing one would make an address ambiguous
	   and a reference in `content/` resolve to whichever was read last. The id
	   because two things sharing one is two things a student's records cannot
	   tell apart — the failure the id exists to make impossible, arriving from
	   a copy-pasted file. */
	taken := map[string]string{} // id -> the slug that has it

	seenTrack := map[string]bool{}
	for _, t := range s.Tracks {
		problems = append(problems, checkSlug(t.Slug, "the track")...)
		problems = append(problems, checkID(t.ID, "tr", "the track "+t.Slug)...)
		problems = append(problems, claim(taken, t.ID, t.Slug)...)
		if seenTrack[t.Slug] {
			problems = append(problems, fmt.Errorf("two tracks are called %q", t.Slug))
		}
		seenTrack[t.Slug] = true
	}

	seenCourse := map[string]bool{}
	for _, c := range s.Courses {
		problems = append(problems, checkSlug(c.Slug, "the course")...)
		problems = append(problems, checkID(c.ID, "co", "the course "+c.Slug)...)
		problems = append(problems, claim(taken, c.ID, c.Slug)...)
		if seenCourse[c.Slug] {
			problems = append(problems, fmt.Errorf("two courses are called %q", c.Slug))
		}
		seenCourse[c.Slug] = true

		/* EVERY TOPIC IS A THING WITH A NAME, and that name is what a lesson, a
		   note and a progress row are all keyed by.

		   THE ID IS WRITTEN DOWN, NEVER WORKED OUT. There was a fallback here
		   that took the slug of the title when no id was given — which is what
		   used to happen implicitly, and is exactly why the title could not be
		   edited afterwards without moving a student's work out from under
		   them. It is gone, and its absence is the point: a fallback that
		   derives an id from prose keeps the hazard alive for whoever leaves
		   the id out, and the schools that will be written next have nobody to
		   remind them.

		   So a topic with no id is refused, and the message says what to write
		   instead. Refusing is louder than deriving, and it happens on a pull
		   request rather than on the day somebody reworded a heading. */
		topics := map[string]bool{}
		for at, topic := range c.Topics {
			id := topic.ID
			if strings.TrimSpace(topic.Title) == "" {
				problems = append(problems, fmt.Errorf(
					"topic %d of the course %q has no title", at, c.Slug))
			}
			if id == "" {
				problems = append(problems, fmt.Errorf(
					"topic %d of the course %q has no id — write one, as "+
						`{"id": "le-xxxxxxxx", "title": %q}. It is never derived from the title: `+
						"a machine rewrites titles, and every lesson, note and progress row "+
						"keyed by this would follow the rewrite", at, c.Slug, topic.Title))
				continue
			}
			problems = append(problems, checkID(id, "le", "the topic "+topic.Title)...)
			problems = append(problems, claim(taken, id, c.Slug+"/"+topic.Title)...)
			if topics[id] {
				problems = append(problems, fmt.Errorf(
					"the course %q has two topics called %q — one of them would take the "+
						"other's lessons, notes and progress", c.Slug, id))
			}
			topics[id] = true
		}

		/* AND `lessons` NAMES TOPICS.

		   It is a subset of them — `javascript` declares twenty-two topics and
		   has four written — and until now nothing tied one to the other except
		   that a directory happened to be named `slug(title)` and the interface
		   looked the lesson up by that title. A lesson whose title no topic
		   lists is a lesson no screen can reach: it draws the placeholder for a
		   course nobody has written, which is a state that looks deliberate.

		   This is the only place that correspondence can be seen at all. */
		seenLesson := map[string]bool{}
		for _, id := range c.Lessons {
			problems = append(problems, checkID(id, "le", "the lesson")...)
			if seenLesson[id] {
				problems = append(problems, fmt.Errorf(
					"the course %q names the lesson %q twice", c.Slug, id))
			}
			seenLesson[id] = true

			if len(c.Topics) > 0 && !topics[id] {
				problems = append(problems, fmt.Errorf(
					"the course %q has a lesson %q and no topic of that name — a lesson is a "+
						"topic somebody has written, so this one is on no screen", c.Slug, id))
			}
		}
	}

	return problems
}

func checkSlug(id, what string) []error {
	if slug.MatchString(id) {
		return nil
	}
	return []error{fmt.Errorf(
		"%s id %q is not a slug — ids never derive from a title, because a machine rewrites "+
			"titles and every link would follow", what, id)}
}

// The declared order names every track, exactly once, and nothing else.
//
// It is the same check `course.json`'s lesson list gets, for the same reason: a
// list that says what order things come in is a second place the ids live, and
// a second place drifts. A track missing from it is shown last rather than lost
// — see inDeclaredOrder — and this is what says so out loud.
func checkTracksAreOrdered(s *School) []error {
	if len(s.Order) == 0 && len(s.Tracks) == 0 {
		return nil
	}

	var problems []error

	have := map[string]bool{}
	for _, t := range s.Tracks {
		have[t.Slug] = true
	}

	seen := map[string]bool{}
	for _, id := range s.Order {
		if seen[id] {
			problems = append(problems, fmt.Errorf(
				"the school names the track %q twice in its order", id))
		}
		seen[id] = true
		if !have[id] {
			problems = append(problems, fmt.Errorf(
				"the school's order names %q, and there is no tracks/%s.json", id, id))
		}
	}

	for _, t := range s.Tracks {
		if !seen[t.Slug] {
			problems = append(problems, fmt.Errorf(
				"the track %q is not in the school's order, so it is offered last — "+
					"order is declared, never inferred (C-10)", t.Slug))
		}
	}
	return problems
}

func checkLessons(s *School) []error {
	var problems []error

	for _, c := range s.Courses {
		/* A COURSE WITH NO LESSONS IS ANNOUNCED, NOT WRITTEN, and that is a
		   state a catalogue of 122 courses is in for most of its life.

		   This used to be an error, and the rule it encoded was right about one
		   thing and wrong about another. Right: a course a student can OPEN and
		   find nothing in is a broken promise. Wrong: the same row is what a
		   track is drawn from, what the hours on a career path are summed from,
		   and what somebody deciding whether to subscribe is reading. Refusing
		   it means a track cannot exist until every course on it is written,
		   which is nineteen tracks that cannot be shown for a year.

		   So the catalogue carries it and the course screen says the material is
		   not written yet — see `CourseView.Lessons` being empty, which the
		   interface already has to handle for a locked course. What is NOT
		   allowed is a lesson that is empty, or a section with no prose, and
		   those checks are below and unchanged: the line is between "not written
		   yet" and "written wrongly". */

		for _, l := range c.Loaded {
			where := c.Slug + "/" + l.ID

			if strings.TrimSpace(l.Title) == "" {
				problems = append(problems, fmt.Errorf("%s has no title", where))
			}
			if len(l.Sections) == 0 {
				problems = append(problems, fmt.Errorf("%s has no sections", where))
			}

			seen := map[string]bool{}
			for _, sec := range l.Sections {
				problems = append(problems, checkSlug(sec.Slug, "the section")...)
				problems = append(problems, checkID(sec.ID, "se", where+"/"+sec.Slug)...)
				if seen[sec.Slug] {
					problems = append(problems, fmt.Errorf(
						"%s has two sections called %q, and an exercise naming it would join to "+
							"whichever came first", where, sec.Slug))
				}
				seen[sec.Slug] = true

				if !sectionKinds[sec.Kind] {
					problems = append(problems, fmt.Errorf(
						"%s/%s is of kind %q, which nothing knows how to show", where, sec.Slug, sec.Kind))
				}
				if sec.Kind == KindAssessment {
					problems = append(problems, fmt.Errorf(
						"%s/%s is an assessment, and assessments are appended by the platform "+
							"rather than written in a file", where, sec.Slug))
				}

				// A reading section with no prose is a step a student opens to
				// find nothing. It is the failure that a schema check cannot
				// see, because the schema is satisfied.
				// BY SLUG, because that is what the file is called and what the
				// person reading this has to go and write.
				if sec.Kind == KindReading && !l.Prose[sec.Slug] {
					problems = append(problems, fmt.Errorf(
						"%s/%s is a reading section and there is no %s.md — a student opens it "+
							"and finds nothing", where, sec.Slug, sec.Slug))
				}
				if sec.Kind == KindVideo && !sec.Video && !l.Prose[sec.Slug] {
					problems = append(problems, fmt.Errorf(
						"%s/%s is a video section with neither a video nor prose", where, sec.Slug))
				}
			}

			// AND THE OTHER DIRECTION. Content that was generated and forgotten
			// shows up nowhere else in the system (C-13): it is not linked, so
			// no screen misses it, and it sits in the repository looking like
			// work that was done.
			for _, file := range l.Files {
				if !seen[sectionOfProse(file)] {
					problems = append(problems, fmt.Errorf(
						"%s/%s is not referenced by any section — it was written and forgotten, "+
							"and nothing else in the system would ever mention it", where, file))
				}
			}
		}
	}

	return problems
}

func checkExercises(s *School) []error {
	var problems []error

	// Ids are unique across the school, not merely within a lesson: an exercise
	// id travels into a student's answer history, where the lesson it came from
	// is not part of the key.
	seen := map[string]string{}

	// `used` is filled as the questions are read and compared against what the
	// courses hold, so a picture nobody asks about fails the same way a
	// forgotten `.md` does. It is keyed by file name within the course being
	// checked, which is the same scope the pictures themselves have.
	used := map[string]bool{}

	// `pictures` is nil only for a TRACK final: a track is one JSON file with
	// nowhere to keep an image. A course exam has its course's.
	check := func(where string, sections, pictures map[string]bool, exercises []Exercise) {
		for _, e := range exercises {
			problems = append(problems, checkID(e.ID, "ex", "the exercise in "+where)...)

			if at, taken := seen[e.ID]; taken {
				problems = append(problems, fmt.Errorf(
					"the exercise id %q is used in %s and in %s — an answer records the id, so "+
						"two questions sharing one make the history unreadable", e.ID, at, where))
			}
			seen[e.ID] = where

			if e.Version < 1 {
				problems = append(problems, fmt.Errorf(
					"%s/%s has version %d — a student's answer records the version it answered, "+
						"and without one the history compares December's apple with March's orange",
					where, e.ID, e.Version))
			}
			if !exerciseTypes[e.Type] {
				problems = append(problems, fmt.Errorf(
					"%s/%s is of type %q, which has no machine grader — and a grader is the "+
						"entry requirement for a type, not a nice-to-have", where, e.ID, e.Type))
			}
			if strings.TrimSpace(e.Prompt) == "" {
				problems = append(problems, fmt.Errorf("%s/%s has no prompt", where, e.ID))
			}

			// sections is nil for an exam, which belongs to no lesson.
			if sections != nil && !sections[e.Section] {
				problems = append(problems, fmt.Errorf(
					"%s/%s names the section %q, which that lesson does not have — this is the "+
						"join that the predecessor made by title text and lost on every rename",
					where, e.ID, e.Section))
			}

			// THE PICTURE HAS TO EXIST, and this is the only place that can see
			// whether it does. The grader checks an answer against coordinates
			// and never opens the file; the interface asks the server and gets a
			// 404; the student gets a question they cannot answer however well
			// they know the material. It fails here, on a pull request.
			if e.Type == "labelling" {
				switch {
				case pictures == nil:
					problems = append(problems, fmt.Errorf(
						"%s/%s is a labelling question in a TRACK final, and a track is one JSON "+
							"file with no directory to keep a picture in. A course exam can carry "+
							"one; this cannot, until a track has somewhere of its own", where, e.ID))
				case e.Image == "":
					problems = append(problems, fmt.Errorf(
						"%s/%s is a labelling question and names no image", where, e.ID))
				case !pictures[e.Image]:
					problems = append(problems, fmt.Errorf(
						"%s/%s labels %q and there is no such file in that course's images/ — a "+
							"question about a picture nobody wrote cannot be answered at all",
						where, e.ID, e.Image))
				default:
					used[e.Image] = true
				}
			}
		}
	}

	for _, c := range s.Courses {
		pictures := map[string]bool{}
		for _, img := range c.Images {
			pictures[img.Name] = true
		}

		// A course at a time, so `used` answers about this course's files and
		// a picture in one course does not excuse the same name in another.
		clear(used)

		for _, l := range c.Loaded {
			sections := map[string]bool{}
			for _, sec := range l.Sections {
				sections[sec.Slug] = true
			}
			check(c.Slug+"/"+l.ID, sections, pictures, l.Exercises)
		}
		check(c.Slug+"/exam", nil, pictures, c.Exam)

		// AND THE OTHER DIRECTION, for pictures as it already is for prose. A
		// file nothing asks about is work that was done and forgotten: it sits
		// in the repository looking finished, it goes into the mirror, and no
		// screen misses it (C-13). This is the only place it can be seen.
		for _, img := range c.Images {
			if !used[img.Name] {
				problems = append(problems, fmt.Errorf(
					"%s/images/%s is a picture no question labels — it was added and forgotten, "+
						"and nothing else in the system would ever mention it", c.Slug, img.Name))
			}
			if len(img.Bytes) > maxPictureBytes {
				problems = append(problems, fmt.Errorf(
					"%s/images/%s is %d kB and the limit is %d — a picture that size is a "+
						"photograph rather than a diagram, and it travels into the offline "+
						"bundle whole", c.Slug, img.Name, len(img.Bytes)/1000, maxPictureBytes/1000))
			}
		}
	}

	// The finals. A track exam is drawn from the same pool machinery and checked
	// by the same rules — an exam that belongs to a track rather than a course is
	// a different place to look for it, not a different kind of question (A-08).
	for _, t := range s.Tracks {
		check(t.Slug+"/exam", nil, nil, t.Exam)
	}

	return problems
}

// What a diagram costs, with room to spare. The database restates it as a CHECK
// — this runs on a pull request, that runs on every write, and the two agreeing
// is the point rather than a duplication to remove.
const maxPictureBytes = 512 * 1024

/*
checkExerciseText holds a question's translations to the question.

	A TRANSLATION IS JOINED BY ID AND ITS LISTS BY POSITION, and both ends can
	come loose. The id end is the ordinary one: a question renamed or a file
	copied from another lesson leaves a translation describing something that is
	not there, which is silent — the English survives and nobody sees a gap.

	The POSITION end is the one that matters. `choices[1]` in the translation is
	`choices[1]` in the question, which is also the answer key: a translation
	one option short does not shift the key, it shifts the WORDS OVER it, and a
	Portuguese student reads the third option's text above the second option's
	verdict. Perfect grammar, wrong meaning, and the English screen is fine.

	So a list that disagrees in length is refused. It cannot be checked any
	harder than that — nothing can tell whether two sentences mean the same
	thing — but a length is exactly the symptom of an insert or a deletion.

	IT COUNTS AND DOES NOT READ. The English payload is decoded into a struct of
	raw messages, so this stays a count of how many there are rather than an
	opinion about what a choice or a label IS. That knowledge belongs to
	`internal/grade`, which is where the answer keys are checked.
*/
func checkExerciseText(s *School) []error {
	var problems []error

	known := map[string]bool{}
	for _, l := range s.Locales {
		known[l] = true
	}

	check := func(where string, exercises []Exercise, text map[string]map[string]ExerciseText) {
		by := map[string]Exercise{}
		for _, e := range exercises {
			by[e.ID] = e
		}

		for _, locale := range slices.Sorted(maps.Keys(text)) {
			if !known[locale] {
				problems = append(problems, fmt.Errorf(
					"the questions in %s are translated into %q, which the school does not list "+
						"in `locales` — so nothing would ever serve it", where, locale))
			}

			for _, id := range slices.Sorted(maps.Keys(text[locale])) {
				e, found := by[id]
				if !found {
					problems = append(problems, fmt.Errorf(
						"the %s of %s translates the question %q, which is not there — the id was "+
							"renamed, or the file was copied from another lesson", locale, where, id))
					continue
				}
				problems = append(problems, checkOneExerciseText(
					locale, where, e, text[locale][id])...)
			}
		}
	}

	for _, c := range s.Courses {
		for _, l := range c.Loaded {
			check(c.Slug+"/"+l.ID, l.Exercises, l.ExerciseText)
		}
		check(c.Slug+"/exam", c.Exam, c.ExamText)
	}
	for _, t := range s.Tracks {
		check(t.Slug+"/exam", t.Exam, t.ExamText)
	}
	return problems
}

func checkOneExerciseText(locale, where string, e Exercise, text ExerciseText) []error {
	// See the comment above: a count, never an opinion about the contents.
	var counts struct {
		Choices          []json.RawMessage `json:"choices"`
		Items            []json.RawMessage `json:"items"`
		Pairs            []json.RawMessage `json:"pairs"`
		Labels           []json.RawMessage `json:"labels"`
		RightDistractors []json.RawMessage `json:"right_distractors"`
	}
	if err := json.Unmarshal(e.Raw, &counts); err != nil {
		return []error{fmt.Errorf("%s/%s: %w", where, e.ID, err)}
	}

	var problems []error
	lengths := []struct {
		what       string
		translated int
		original   int
	}{
		{"options", len(text.Choices), len(counts.Choices)},
		{"items", len(text.Items), len(counts.Items)},
		{"pairs", len(text.Pairs), len(counts.Pairs)},
		{"labels", len(text.Labels), len(counts.Labels)},
		{"leftover options", len(text.RightDistractors), len(counts.RightDistractors)},
	}
	for _, l := range lengths {
		// Nothing translated is not a shortfall: a translation carries what
		// somebody translated and the English survives the rest (C-11).
		if l.translated > 0 && l.translated != l.original {
			problems = append(problems, fmt.Errorf(
				"the %s of %s/%s gives %d %s and the question has %d — they are matched by "+
					"position, so one of them is written over the wrong one",
				locale, where, e.ID, l.translated, l.what, l.original))
		}
	}
	return problems
}

func checkTracks(s *School) []error {
	var problems []error

	courses := map[string]bool{}
	for _, c := range s.Courses {
		courses[c.Slug] = true
	}
	tracks := map[string]*Track{}
	for _, t := range s.Tracks {
		tracks[t.Slug] = t
	}

	for _, t := range s.Tracks {
		if len(t.Courses) == 0 {
			problems = append(problems, fmt.Errorf("the track %q has no courses", t.Slug))
		}

		// A course may appear once in a track. Twice is either a mistake or an
		// order that cannot be drawn.
		seen := map[string]bool{}
		for i, step := range t.Courses {
			switch {
			case step.Fork != nil:
				if len(step.Fork.Options) < 2 {
					problems = append(problems, fmt.Errorf(
						"the track %q has a fork at step %d with fewer than two options, which "+
							"is not a choice", t.Slug, i+1))
				}
				for _, option := range step.Fork.Options {
					if strings.TrimSpace(option.Name) == "" {
						problems = append(problems, fmt.Errorf(
							"the track %q has an unnamed option at step %d", t.Slug, i+1))
					}
					if len(option.Courses) == 0 {
						problems = append(problems, fmt.Errorf(
							"the track %q offers %q at step %d and it contains no courses",
							t.Slug, option.Name, i+1))
					}
					for _, id := range option.Courses {
						problems = append(problems, checkTrackCourse(t.Slug, id, courses, seen)...)
					}
				}
			case step.Course != "":
				problems = append(problems, checkTrackCourse(t.Slug, step.Course, courses, seen)...)
			default:
				problems = append(problems, fmt.Errorf(
					"the track %q has an empty step at position %d", t.Slug, i+1))
			}
		}

		problems = append(problems, checkLinks(t, seen)...)
		problems = append(problems, checkTrackText(s, t)...)

		// `continues` is followed to the end of the chain, so a loop in it is a
		// loader that never returns rather than a wrong answer.
		if t.Continues != "" {
			if err := checkContinues(t, tracks); err != nil {
				problems = append(problems, err)
			}
		}
	}

	return problems
}

// checkLinks holds a track's own sequence to the track.
//
// BOTH ENDS HAVE TO BE IN THIS TRACK, and that is the whole rule. A link says
// "here, this one comes after that one"; naming a course the track does not
// contain says it about nothing, and the graph would quietly draw a different
// edge instead — the same silent failure the `requires`/`links` split exists to
// avoid, arriving from the other side.
//
// `seen` is the set of courses this track contains, which the loop above has
// just finished collecting. It is passed rather than recomputed so that "in
// this track" has one definition, forks included.
func checkLinks(t *Track, seen map[string]bool) []error {
	var problems []error

	for _, course := range slices.Sorted(maps.Keys(t.Links)) {
		if !seen[course] {
			problems = append(problems, fmt.Errorf(
				"the track %q gives an order for the course %q, which the track does not contain",
				t.Slug, course))
		}
		for _, target := range t.Links[course] {
			switch {
			case target.Step != nil:
				if *target.Step < 0 || *target.Step >= len(t.Courses) {
					problems = append(problems, fmt.Errorf(
						"the track %q says %q comes after step %d, and the track has %d steps",
						t.Slug, course, *target.Step, len(t.Courses)))
				}
			case target.Course == course:
				problems = append(problems, fmt.Errorf(
					"the track %q says %q comes after itself", t.Slug, course))
			case !seen[target.Course]:
				problems = append(problems, fmt.Errorf(
					"the track %q says %q comes after %q, which the track does not contain",
					t.Slug, course, target.Course))
			}
		}
	}
	return problems
}

// checkTrackText holds a track's translations to the track and to the school.
//
// THE FORKS ARE THE POINT. A fork has no id, so its translation is keyed by the
// step's POSITION — the one join in this catalogue that a reordering can break
// in silence. The predecessor shipped exactly that: a step was inserted, every
// fork after it moved, and the translations stayed where they were, describing
// a different choice in perfect Portuguese.
//
// It cannot be keyed on anything else, so it is checked instead. A position
// that is not a fork is the symptom of the insert; a list of options a
// different length from the fork's is the symptom of a fork gaining or losing
// one. Both are what that failure looks like from outside, and both fail here.
func checkTrackText(s *School, t *Track) []error {
	var problems []error

	known := map[string]bool{}
	for _, l := range s.Locales {
		known[l] = true
	}

	for _, locale := range slices.Sorted(maps.Keys(t.Text)) {
		if !known[locale] {
			problems = append(problems, fmt.Errorf(
				"the track %q is translated into %q, which the school does not list in `locales` — "+
					"so nothing would ever serve it", t.Slug, locale))
		}
		text := t.Text[locale]

		for _, at := range slices.Sorted(maps.Keys(text.Steps)) {
			position, err := strconv.Atoi(at)
			if err != nil {
				problems = append(problems, fmt.Errorf(
					"the %s of the track %q translates a step called %q, and a step is a position",
					locale, t.Slug, at))
				continue
			}
			if position < 0 || position >= len(t.Courses) {
				problems = append(problems, fmt.Errorf(
					"the %s of the track %q translates step %d, and the track has %d steps",
					locale, t.Slug, position, len(t.Courses)))
				continue
			}
			fork := t.Courses[position].Fork
			if fork == nil {
				problems = append(problems, fmt.Errorf(
					"the %s of the track %q translates step %d as a choice, and that step is the "+
						"course %q — a step was inserted or removed and the translation stayed behind",
					locale, t.Slug, position, t.Courses[position].Course))
				continue
			}
			if n := len(text.Steps[at].Options); n > 0 && n != len(fork.Options) {
				problems = append(problems, fmt.Errorf(
					"the %s of the track %q gives step %d %d option names and the choice has %d — "+
						"they are matched by position, so one of them is describing the wrong option",
					locale, t.Slug, position, n, len(fork.Options)))
			}
		}
	}
	return problems
}

// checkCourseText holds a course's translations to the school's languages.
func checkCourseText(s *School) []error {
	var problems []error

	known := map[string]bool{}
	for _, l := range s.Locales {
		known[l] = true
	}

	for _, c := range s.Courses {
		for _, locale := range slices.Sorted(maps.Keys(c.Text)) {
			if !known[locale] {
				problems = append(problems, fmt.Errorf(
					"the course %q is translated into %q, which the school does not list in "+
						"`locales` — so nothing would ever serve it", c.Slug, locale))
			}

			/* THE TRANSLATED TOPICS ARE KEYED BY THE TOPIC'S ID, and every key
			   has to name a topic this course actually has.

			   They were an array matched by POSITION, and the check here was
			   that the two lists were the same length — the best that could be
			   done when a position was all there was to join on. It caught a
			   translation one entry short and could not catch one that was the
			   right length and shifted.

			   Keyed by id, a translation that has come loose says so precisely:
			   the key names a topic that is not there. A topic with NO
			   translation is still fine — a translation carries what somebody
			   translated (C-11) and the English title survives. */
			text := c.Text[locale]
			mine := map[string]bool{}
			for _, topic := range c.Topics {
				mine[topic.ID] = true
			}
			for _, id := range slices.Sorted(maps.Keys(text.Topics)) {
				if !mine[id] {
					problems = append(problems, fmt.Errorf(
						"the %s of the course %q translates the topic %q, which that course does "+
							"not have — the id was renamed, or the translation was copied from "+
							"another course", locale, c.Slug, id))
				}
			}
			if n := len(text.Syllabus); n > 0 && n != len(c.Syllabus) {
				problems = append(problems, fmt.Errorf(
					"the %s of the course %q lists %d syllabus lines and the course has %d — "+
						"they are matched by position", locale, c.Slug, n, len(c.Syllabus)))
			}
		}
	}
	return problems
}

func checkTrackCourse(track, id string, courses, seen map[string]bool) []error {
	var problems []error
	if !courses[id] {
		problems = append(problems, fmt.Errorf(
			"the track %q names the course %q, which does not exist", track, id))
	}
	if seen[id] {
		problems = append(problems, fmt.Errorf(
			"the track %q contains the course %q twice — including once inside a fork, which "+
				"makes the order undrawable", track, id))
	}
	seen[id] = true
	return problems
}

// checkContinues walks the chain and refuses a loop in it.
//
// EVERY COMPARISON HERE IS BY SLUG, and mixing the two names is not a tidiness
// problem: `continues` names a track the way the rest of `content/` does, by
// slug, and comparing it against the opaque id made the self-reference test
// never fire. The walk then followed `frontend` to `frontend` for ever — a
// validator that hangs instead of refusing, which the test caught by timing out
// rather than by failing.
func checkContinues(t *Track, tracks map[string]*Track) error {
	visited := map[string]bool{t.Slug: true}

	for at := t; at.Continues != ""; {
		if at.Continues == at.Slug {
			return fmt.Errorf("the track %q continues itself", at.Slug)
		}
		next, ok := tracks[at.Continues]
		if !ok {
			return fmt.Errorf("the track %q continues %q, which does not exist", at.Slug, at.Continues)
		}
		if visited[next.Slug] {
			return fmt.Errorf(
				"the tracks %q and %q continue each other, so following the chain never ends",
				at.Slug, next.Slug)
		}
		visited[next.Slug] = true
		at = next
	}
	return nil
}

// checkRequires is the one that cost 18 false edges.
//
// TWO SEPARATE THINGS ARE CHECKED HERE, and conflating them is the mistake the
// format exists to prevent:
//
//   - `requires` names KNOWLEDGE. A cycle in it is impossible to satisfy in any
//     order, in any track, forever.
//
//   - A track is a SEQUENCE. A course's prerequisites have to be met by what
//     comes BEFORE it in that track — including the courses of any track it
//     continues, because a student on it has taken them.
//
// The second is checked per BRANCH, because a fork means a student takes one
// option and not the others: a prerequisite satisfied only by the branch nobody
// chose is not satisfied.
func checkRequires(s *School) []error {
	var problems []error

	byID := map[string]*Course{}
	for _, c := range s.Courses {
		byID[c.Slug] = c
	}

	for _, c := range s.Courses {
		for _, id := range c.Requires {
			if _, ok := byID[id]; !ok {
				problems = append(problems, fmt.Errorf(
					"the course %q requires %q, which does not exist", c.Slug, id))
			}
		}
	}

	if err := checkNoCycle(s.Courses, byID); err != nil {
		problems = append(problems, err)
		// A cycle makes every order check below meaningless, and reporting one
		// problem per track for the same cycle is noise.
		return problems
	}

	tracks := map[string]*Track{}
	for _, t := range s.Tracks {
		tracks[t.Slug] = t
	}

	for _, t := range s.Tracks {
		problems = append(problems, checkTrackOrder(t, tracks, byID)...)
	}

	return problems
}

func checkNoCycle(courses []*Course, byID map[string]*Course) error {
	const (
		unvisited = 0
		onStack   = 1
		done      = 2
	)
	state := map[string]int{}
	var path []string

	var walk func(id string) error
	walk = func(id string) error {
		switch state[id] {
		case done:
			return nil
		case onStack:
			at := 0
			for i, seen := range path {
				if seen == id {
					at = i
					break
				}
			}
			return fmt.Errorf(
				"the prerequisites form a cycle: %s — no order of study satisfies it, in any track",
				strings.Join(append(append([]string{}, path[at:]...), id), " → "))
		}

		state[id] = onStack
		path = append(path, id)
		for _, next := range byID[id].Requires {
			if _, ok := byID[next]; !ok {
				continue // already reported as missing
			}
			if err := walk(next); err != nil {
				return err
			}
		}
		path = path[:len(path)-1]
		state[id] = done
		return nil
	}

	for _, c := range courses {
		if err := walk(c.Slug); err != nil {
			return err
		}
	}
	return nil
}

// checkTrackOrder walks every branch a student could take through a track.
func checkTrackOrder(t *Track, tracks map[string]*Track, byID map[string]*Course) []error {
	// What a student arrives with, from the chain of continued tracks. Every
	// course of those tracks, from every branch, because "a student on this
	// track has taken that one" says nothing about which option they chose.
	arriving := map[string]bool{}
	/* THE LOOP GUARD IS A SET AND NOT A COMPARISON WITH THE START. Two other
	   tracks continuing each other is a cycle this walk falls into without ever
	   coming back to `t`, and `checkContinues` reports it — but only for the
	   track it starts from, so this one still has to get out. */
	walked := map[string]bool{t.Slug: true}
	for at := t; at.Continues != ""; {
		next, ok := tracks[at.Continues]
		if !ok {
			return nil // already reported
		}
		for _, id := range everyCourseIn(next) {
			arriving[id] = true
		}
		if walked[next.Slug] {
			return nil // a loop, already reported
		}
		walked[next.Slug] = true
		at = next
	}

	branches, tooMany := branchesOf(t)
	if tooMany {
		return []error{fmt.Errorf(
			"the track %q has so many forks that its branches cannot all be checked — which is "+
				"itself the problem: a student cannot hold that many choices either", t.Slug)}
	}

	var problems []error
	reported := map[string]bool{}

	for _, branch := range branches {
		taken := map[string]bool{}
		for id := range arriving {
			taken[id] = true
		}

		for _, id := range branch {
			course, ok := byID[id]
			if !ok {
				continue // already reported as missing
			}
			for _, needed := range course.Requires {
				if taken[needed] {
					continue
				}
				if _, exists := byID[needed]; !exists {
					continue // already reported
				}

				key := t.Slug + "/" + id + "/" + needed
				if reported[key] {
					continue
				}
				reported[key] = true

				problems = append(problems, fmt.Errorf(
					"the track %q reaches %q before %q, which it requires — either the track's "+
						"order is wrong, or %q is sequence rather than knowledge and belongs to "+
						"the track instead of to `requires`",
					t.Slug, id, needed, needed))
			}
			taken[id] = true
		}
	}

	return problems
}

// branchesOf enumerates the paths through a track, one per combination of fork
// options.
func branchesOf(t *Track) (branches [][]string, tooMany bool) {
	branches = [][]string{{}}

	for _, step := range t.Courses {
		switch {
		case step.Fork != nil:
			var next [][]string
			for _, branch := range branches {
				for _, option := range step.Fork.Options {
					extended := append(append([]string{}, branch...), option.Courses...)
					next = append(next, extended)
				}
			}
			// A hundred branches is already more choices than a track should
			// offer; the limit is a signal rather than a resource concern.
			if len(next) > 100 {
				return nil, true
			}
			branches = next
		case step.Course != "":
			for i := range branches {
				branches[i] = append(branches[i], step.Course)
			}
		}
	}
	return branches, false
}

func everyCourseIn(t *Track) []string {
	var out []string
	for _, step := range t.Courses {
		if step.Fork != nil {
			for _, option := range step.Fork.Options {
				out = append(out, option.Courses...)
			}
			continue
		}
		if step.Course != "" {
			out = append(out, step.Course)
		}
	}
	return out
}
