package catalog

import (
	"fmt"
	"maps"
	"regexp"
	"slices"
	"sort"
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

	sort.Slice(problems, func(i, j int) bool {
		return problems[i].Error() < problems[j].Error()
	})
	return problems
}

// An id is a slug and never derives from a title (C-09, C-10). A title is
// rewritten by a machine; an id that followed it would take every link with it.
var slug = regexp.MustCompile(`^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`)

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

	seenTrack := map[string]bool{}
	for _, t := range s.Tracks {
		problems = append(problems, checkSlug(t.ID, "the track")...)
		if seenTrack[t.ID] {
			problems = append(problems, fmt.Errorf("two tracks are called %q", t.ID))
		}
		seenTrack[t.ID] = true
	}

	seenCourse := map[string]bool{}
	for _, c := range s.Courses {
		problems = append(problems, checkSlug(c.ID, "the course")...)
		if seenCourse[c.ID] {
			problems = append(problems, fmt.Errorf("two courses are called %q", c.ID))
		}
		seenCourse[c.ID] = true

		seenLesson := map[string]bool{}
		for _, id := range c.Lessons {
			problems = append(problems, checkSlug(id, "the lesson")...)
			if seenLesson[id] {
				problems = append(problems, fmt.Errorf(
					"the course %q names the lesson %q twice", c.ID, id))
			}
			seenLesson[id] = true
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
		have[t.ID] = true
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
		if !seen[t.ID] {
			problems = append(problems, fmt.Errorf(
				"the track %q is not in the school's order, so it is offered last — "+
					"order is declared, never inferred (C-10)", t.ID))
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
			where := c.ID + "/" + l.ID

			if strings.TrimSpace(l.Title) == "" {
				problems = append(problems, fmt.Errorf("%s has no title", where))
			}
			if len(l.Sections) == 0 {
				problems = append(problems, fmt.Errorf("%s has no sections", where))
			}

			seen := map[string]bool{}
			for _, sec := range l.Sections {
				problems = append(problems, checkSlug(sec.ID, "the section")...)
				if seen[sec.ID] {
					problems = append(problems, fmt.Errorf(
						"%s has two sections called %q, and an exercise naming it would join to "+
							"whichever came first", where, sec.ID))
				}
				seen[sec.ID] = true

				if !sectionKinds[sec.Kind] {
					problems = append(problems, fmt.Errorf(
						"%s/%s is of kind %q, which nothing knows how to show", where, sec.ID, sec.Kind))
				}
				if sec.Kind == KindAssessment {
					problems = append(problems, fmt.Errorf(
						"%s/%s is an assessment, and assessments are appended by the platform "+
							"rather than written in a file", where, sec.ID))
				}

				// A reading section with no prose is a step a student opens to
				// find nothing. It is the failure that a schema check cannot
				// see, because the schema is satisfied.
				if sec.Kind == KindReading && !l.Prose[sec.ID] {
					problems = append(problems, fmt.Errorf(
						"%s/%s is a reading section and there is no %s.md — a student opens it "+
							"and finds nothing", where, sec.ID, sec.ID))
				}
				if sec.Kind == KindVideo && !sec.Video && !l.Prose[sec.ID] {
					problems = append(problems, fmt.Errorf(
						"%s/%s is a video section with neither a video nor prose", where, sec.ID))
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
			problems = append(problems, checkSlug(e.ID, "the exercise")...)

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
				sections[sec.ID] = true
			}
			check(c.ID+"/"+l.ID, sections, pictures, l.Exercises)
		}
		check(c.ID+"/exam", nil, pictures, c.Exam)

		// AND THE OTHER DIRECTION, for pictures as it already is for prose. A
		// file nothing asks about is work that was done and forgotten: it sits
		// in the repository looking finished, it goes into the mirror, and no
		// screen misses it (C-13). This is the only place it can be seen.
		for _, img := range c.Images {
			if !used[img.Name] {
				problems = append(problems, fmt.Errorf(
					"%s/images/%s is a picture no question labels — it was added and forgotten, "+
						"and nothing else in the system would ever mention it", c.ID, img.Name))
			}
			if len(img.Bytes) > maxPictureBytes {
				problems = append(problems, fmt.Errorf(
					"%s/images/%s is %d kB and the limit is %d — a picture that size is a "+
						"photograph rather than a diagram, and it travels into the offline "+
						"bundle whole", c.ID, img.Name, len(img.Bytes)/1000, maxPictureBytes/1000))
			}
		}
	}

	// The finals. A track exam is drawn from the same pool machinery and checked
	// by the same rules — an exam that belongs to a track rather than a course is
	// a different place to look for it, not a different kind of question (A-08).
	for _, t := range s.Tracks {
		check(t.ID+"/exam", nil, nil, t.Exam)
	}

	return problems
}

// What a diagram costs, with room to spare. The database restates it as a CHECK
// — this runs on a pull request, that runs on every write, and the two agreeing
// is the point rather than a duplication to remove.
const maxPictureBytes = 512 * 1024

func checkTracks(s *School) []error {
	var problems []error

	courses := map[string]bool{}
	for _, c := range s.Courses {
		courses[c.ID] = true
	}
	tracks := map[string]*Track{}
	for _, t := range s.Tracks {
		tracks[t.ID] = t
	}

	for _, t := range s.Tracks {
		if len(t.Courses) == 0 {
			problems = append(problems, fmt.Errorf("the track %q has no courses", t.ID))
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
							"is not a choice", t.ID, i+1))
				}
				for _, option := range step.Fork.Options {
					if strings.TrimSpace(option.Name) == "" {
						problems = append(problems, fmt.Errorf(
							"the track %q has an unnamed option at step %d", t.ID, i+1))
					}
					if len(option.Courses) == 0 {
						problems = append(problems, fmt.Errorf(
							"the track %q offers %q at step %d and it contains no courses",
							t.ID, option.Name, i+1))
					}
					for _, id := range option.Courses {
						problems = append(problems, checkTrackCourse(t.ID, id, courses, seen)...)
					}
				}
			case step.Course != "":
				problems = append(problems, checkTrackCourse(t.ID, step.Course, courses, seen)...)
			default:
				problems = append(problems, fmt.Errorf(
					"the track %q has an empty step at position %d", t.ID, i+1))
			}
		}

		problems = append(problems, checkLinks(t, seen)...)

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
				t.ID, course))
		}
		for _, target := range t.Links[course] {
			switch {
			case target.Step != nil:
				if *target.Step < 0 || *target.Step >= len(t.Courses) {
					problems = append(problems, fmt.Errorf(
						"the track %q says %q comes after step %d, and the track has %d steps",
						t.ID, course, *target.Step, len(t.Courses)))
				}
			case target.Course == course:
				problems = append(problems, fmt.Errorf(
					"the track %q says %q comes after itself", t.ID, course))
			case !seen[target.Course]:
				problems = append(problems, fmt.Errorf(
					"the track %q says %q comes after %q, which the track does not contain",
					t.ID, course, target.Course))
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

func checkContinues(t *Track, tracks map[string]*Track) error {
	visited := map[string]bool{t.ID: true}

	for at := t; at.Continues != ""; {
		if at.Continues == at.ID {
			return fmt.Errorf("the track %q continues itself", at.ID)
		}
		next, ok := tracks[at.Continues]
		if !ok {
			return fmt.Errorf("the track %q continues %q, which does not exist", at.ID, at.Continues)
		}
		if visited[next.ID] {
			return fmt.Errorf(
				"the tracks %q and %q continue each other, so following the chain never ends",
				at.ID, next.ID)
		}
		visited[next.ID] = true
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
		byID[c.ID] = c
	}

	for _, c := range s.Courses {
		for _, id := range c.Requires {
			if _, ok := byID[id]; !ok {
				problems = append(problems, fmt.Errorf(
					"the course %q requires %q, which does not exist", c.ID, id))
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
		tracks[t.ID] = t
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
		if err := walk(c.ID); err != nil {
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
	for at := t; at.Continues != ""; {
		next, ok := tracks[at.Continues]
		if !ok {
			return nil // already reported
		}
		for _, id := range everyCourseIn(next) {
			arriving[id] = true
		}
		at = next
		if at.ID == t.ID {
			return nil // a loop, already reported
		}
	}

	branches, tooMany := branchesOf(t)
	if tooMany {
		return []error{fmt.Errorf(
			"the track %q has so many forks that its branches cannot all be checked — which is "+
				"itself the problem: a student cannot hold that many choices either", t.ID)}
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

				key := t.ID + "/" + id + "/" + needed
				if reported[key] {
					continue
				}
				reported[key] = true

				problems = append(problems, fmt.Errorf(
					"the track %q reaches %q before %q, which it requires — either the track's "+
						"order is wrong, or %q is sequence rather than knowledge and belongs to "+
						"the track instead of to `requires`",
					t.ID, id, needed, needed))
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
