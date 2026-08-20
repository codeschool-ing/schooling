// Package catalog reads `content/` and says what is wrong with it.
//
// THE FILES ARE THE SOURCE OF TRUTH AND THE DATABASE IS A MIRROR (C-01). This
// package touches no database at all: it reads a directory and answers with a
// school and a list of complaints. What writes the mirror is a separate job,
// and it reads what this produces.
//
// # WHY THIS IS THE MOST IMPORTANT CODE IN THE REPOSITORY
//
// The material is written by a machine and there is no human reviewer. What
// stands between a wrong answer key and a student is this and nothing else
// (C-14). So it does not stop at the first problem, it does not warn, and it
// does not have a flag to make it lenient: it collects everything wrong with a
// catalogue and fails.
//
// # TWO RULES THE FORMAT EXISTS TO ENFORCE
//
//  1. NOTHING JOINS BY PROSE OR BY POSITION, only by a stable id. The
//     predecessor joined exercises to lessons by the lesson's TITLE TEXT and
//     keyed translations by ARRAY POSITION; both are quiet failures waiting for
//     an edit, and one of them shipped. With a machine renaming titles and
//     inserting steps they stop being hazards and become certainties. (C-09)
//
//  2. ORDER IS DECLARED, NEVER INFERRED FROM THE FILESYSTEM. No numeric
//     prefixes on directories: `course.json` names its lessons in order.
//     Reordering is one changed line rather than a cascade of renames that git
//     shows as deletions. (C-10)
package catalog

import (
	"encoding/json"
	"fmt"
)

// School is one school's whole catalogue, as it is on disk.
type School struct {
	ID      string   `json:"id"`
	Name    string   `json:"name"`
	Accent  string   `json:"accent"`
	Locales []string `json:"locales"`

	// The tracks, in the order a student is offered them.
	//
	// DECLARED, NEVER INFERRED FROM THE FILESYSTEM (C-10) — the rule the rest of
	// this format already obeys, and the one place it did not. The order used to
	// come from sorting the file names, which is alphabetical by id: a school's
	// nineteen career paths were presented in the order their slugs happen to
	// fall in, and the first thing a student saw was whichever one starts with
	// an `a`. Renaming a track's id would have silently reordered the menu.
	//
	// Every track file must be named here exactly once; `Validate` says so.
	Order []string `json:"tracks"`

	// Filled by Load, not by the file.
	Tracks  []*Track  `json:"-"`
	Courses []*Course `json:"-"`
}

// Track is an order of courses, with forks.
type Track struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Goal    string `json:"goal"`
	Outcome string `json:"outcome"`

	// Courses is a mixture of course ids and forks, in order. It is decoded by
	// hand because JSON has no sum type: see Step.
	Courses []Step `json:"courses"`

	// Continues names another track whose courses this one may assume the
	// student has taken. It is what lets `data-platform` require `python`
	// without listing the entry track's hours again.
	Continues string `json:"continues"`

	// Links is THIS TRACK'S OWN SEQUENCE, and it is the other half of the rule
	// that `requires` is knowledge.
	//
	// A course's `requires` names only what a student has to know first, so
	// that the course can be reused in another track without dragging five
	// hundred hours behind it. What is left over — "in THIS track, this one
	// comes after that one" — still has to be said, and this is where it is
	// said. It draws an arrow in this track and nowhere else.
	//
	// Keyed by course id; each target is either the index of a step in
	// `Courses` or another course's id. Both, because a fork has no id to point
	// at and a course does.
	//
	// LEAVING IT OUT DOES NOT LEAVE OUT THE ARROW. The graph falls back to the
	// previous step when a course has no prerequisite inside the track, so a
	// missing link is not a missing edge — it is the WRONG edge, which is worse
	// because nothing looks broken. Dropped at the import, the front-end track
	// drew fourteen edges where the vitrine draws seventeen.
	Links map[string][]LinkTarget `json:"links,omitempty"`

	// The track exam — the final. Filled by Load from `tracks/<id>-exam.json`,
	// because an exam belongs to no lesson and a track has none to put it in.
	Exam []Exercise `json:"-"`

	// What this track is called in other languages, by locale. Filled by Load
	// from `tracks/<id>.<locale>.json`, which is read beside the file it
	// translates so that a missing translation shows up in `ls`.
	Text map[string]TrackText `json:"-"`
}

// TrackText is a track in one other language.
//
// EVERY FIELD IS A POINTER, and that is the whole of the field-by-field
// fallback (C-11): a translation carries what somebody translated and no more,
// so a track translated in its name and not its goal keeps the English goal
// rather than losing it. `nil` is "nobody wrote this", which an empty string
// cannot say.
type TrackText struct {
	Name    *string `json:"name"`
	Goal    *string `json:"goal"`
	Outcome *string `json:"outcome"`

	// KEYED BY THE STEP'S POSITION, because a fork has no id — its identity is
	// where it sits. Which makes this the one join in the catalogue that a
	// reordering can silently break, and `validate.go` is where that is caught:
	// a position that is not a fork, or a list of options a different length
	// from the fork's, is what the failure looks like from outside.
	Steps map[string]ForkText `json:"steps"`
}

type ForkText struct {
	Choice  *string  `json:"choice"`
	Note    *string  `json:"note"`
	Options []string `json:"options"`
}

// LinkTarget is one end of a link: a step of this track, or a course of it.
//
// TWO SHAPES IN ONE JSON ARRAY, which is why this is decoded by hand like Step:
// `{"testing-cicd": ["apis"], "front-quality": [5]}` is what the catalogue
// writes, and both entries mean "comes after". A number is a position in
// `Courses` — the only way to point at a fork, which has no id — and a string
// is a course.
type LinkTarget struct {
	// Exactly one of these is set. Step is an index into Track.Courses.
	Step   *int
	Course string
}

func (l *LinkTarget) UnmarshalJSON(data []byte) error {
	var course string
	if err := json.Unmarshal(data, &course); err == nil {
		*l = LinkTarget{Course: course}
		return nil
	}
	var step int
	if err := json.Unmarshal(data, &step); err != nil {
		return fmt.Errorf("a link is either a step number or a course id, and %s is neither", data)
	}
	*l = LinkTarget{Step: &step}
	return nil
}

// MarshalJSON writes back what was read, so that the interface receives the
// catalogue's own shape and needs no translation for it.
func (l LinkTarget) MarshalJSON() ([]byte, error) {
	if l.Step != nil {
		return json.Marshal(*l.Step)
	}
	return json.Marshal(l.Course)
}

// Step is one position in a track: either a single course or a fork.
//
// A FORK IS A STEP WITH NAMED OPTIONS, and each option is a list of course ids.
// Modelling it as a step rather than as a separate list is what keeps "the
// order of a track" one thing — a track with the forks pulled out into a second
// field has two orders that can disagree.
type Step struct {
	// Exactly one of these is set.
	Course string
	Fork   *Fork
}

type Fork struct {
	Choice  string   `json:"choice"`
	Note    string   `json:"note"`
	Options []Option `json:"options"`
}

type Option struct {
	Name    string   `json:"name"`
	Courses []string `json:"courses"`
}

// Course is a course as `course.json` declares it.
type Course struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Category string `json:"category"`
	Level    string `json:"level"`
	Hours    int    `json:"hours"`
	Summary  string `json:"summary"`

	// Requires names ONLY what the student has to know first.
	//
	// If the reason is "in this track it comes after that one", it belongs to
	// the track's order instead. Conflating the two cost 18 false edges once: a
	// course looked as though it needed 500 hours before it, so it could not be
	// reused in another track, and the site drew arrows at prerequisites the
	// track did not contain.
	Requires []string `json:"requires"`

	// Prerequisites is prose, for a person. It is not the graph.
	Prerequisites string `json:"prerequisites"`

	// TWO LISTS THAT SAY WHAT IS IN THE COURSE, at two depths, for two readers.
	//
	// Syllabus is five to seven lines and is the commercial read: what somebody
	// deciding whether to take the course takes away from it. Topics is the
	// complete technical list, for somebody who already decided.
	//
	// They are declared rather than derived from the lessons, and the reason is
	// the state most of a catalogue is in: a course is ANNOUNCED long before it
	// is written, and these two lists are the whole of what can honestly be said
	// about it until then. Derived, an unwritten course would have nothing to
	// show — the same failure as refusing to carry it at all.
	//
	// Both are optional. A course with no `topics` shows no technical list
	// rather than an empty heading.
	Syllabus []string `json:"syllabus"`
	Topics   []string `json:"topics"`

	Lessons []string `json:"lessons"`

	// What this course is called in other languages, by locale. Filled by Load
	// from `course.<locale>.json` beside `course.json`. See TrackText for why
	// every field is a pointer.
	Text map[string]CourseText `json:"-"`

	// Draft keeps a course out of what a student sees while it is being
	// written. It is a field rather than a directory, so publishing is a
	// changed line rather than a move that loses the file's history.
	Draft bool `json:"draft"`

	// Filled by Load.
	Loaded []*Lesson `json:"-"`
	Exam   []Exercise

	// Images is every picture in `images/`, which is where a course keeps the
	// diagrams its questions are asked about. They get the same treatment as
	// the prose, in both directions: a question naming one that is not here
	// fails, and one here that no question names fails too.
	Images []Image `json:"-"`
}

// Lesson is a lesson as `lesson.json` declares it.
type Lesson struct {
	ID       string    `json:"id"`
	Title    string    `json:"title"`
	Sections []Section `json:"sections"`

	// Filled by Load.
	Exercises []Exercise `json:"-"`

	// Prose is the section ids that have a Markdown file, and Files is every
	// Markdown file found in the lesson directory. The orphan check is the
	// difference between them.
	Prose map[string]bool `json:"-"`
	Files []string        `json:"-"`

	// Text is what those files say, one entry per section per locale.
	Text []Prose `json:"-"`
}

// Image is a picture a course is written around — today, the one a `labelling`
// question asks a student to place labels on.
//
// THE BYTES TRAVEL WITH IT. They go into the mirror, back out as a response
// body, and into the offline bundle as a data URI. A path or a URL would be a
// second thing to deploy and a fourth way for a question to be unanswerable.
//
// IT BELONGS TO THE COURSE AND NOT THE LESSON, which is not where the file
// naturally wants to sit. The reason is who renders a question: today, only the
// exam paper, and an exam question belongs to a course and to no lesson. Scoped
// to a lesson this would have shipped a question type no student could reach.
type Image struct {
	// The file name and nothing else — no path, no directory. A question names
	// it exactly as it appears in the course's `images/` folder, because a path
	// in a payload is a path somebody eventually escapes.
	Name string

	MediaType string
	Bytes     []byte
}

// Prose is one section's words in one language.
//
// A MISSING TRANSLATION IS A MISSING ENTRY, never an empty one. The server
// falls back field by field, so a section translated in its title but not its
// body keeps the English body rather than losing the title too (C-11) — and
// that only works if "absent" and "blank" are different things all the way
// down.
type Prose struct {
	SectionID string
	Locale    string

	// Title comes from the front matter, which carries only what belongs to the
	// prose itself. Everything the JSON already knows stays in the JSON.
	Title string
	Body  string
}

// CourseText is a course in one other language.
type CourseText struct {
	Name          *string  `json:"name"`
	Summary       *string  `json:"summary"`
	Prerequisites *string  `json:"prerequisites"`
	Syllabus      []string `json:"syllabus"`
	Topics        []string `json:"topics"`
}

// Section is one step of a lesson.
type Section struct {
	ID   string `json:"id"`
	Kind string `json:"kind"`

	Video     bool     `json:"video"`
	Duration  string   `json:"duration"`
	Materials []string `json:"materials"`

	// Countable is separate from Kind on purpose, so progress semantics never
	// have to be inferred from what a section IS.
	Countable *bool `json:"countable"`
}

// The kinds a section may be. `assessment` is appended by the platform and is
// not written in a file, but it is listed because a file that contains one is
// wrong in a way worth naming rather than merely unrecognised.
const (
	KindReading    = "reading"
	KindVideo      = "video"
	KindPractice   = "practice"
	KindAssessment = "assessment"
)

var sectionKinds = map[string]bool{
	KindReading:    true,
	KindVideo:      true,
	KindPractice:   true,
	KindAssessment: true,
}

// Exercise is one question.
//
// ITS PAYLOAD IS KEPT WHOLE AND UNREAD. A `quiz` has choices, a `code` has test
// cases, a `numeric` has a unit and a tolerance — and this package deliberately
// does not know the difference, because checking a `code` key means EXECUTING
// it, which is the other half of the checks. What it must not do is drop the
// payload on the way past: a loader that decodes the fields it recognises and
// silently discards the rest would write a mirror with no answers in it.
type Exercise struct {
	// Raw is the whole object as it was written, including everything above.
	Raw json.RawMessage `json:"-"`

	ID         string `json:"id"`
	Version    int    `json:"version"`
	Section    string `json:"section"`
	Type       string `json:"type"`
	Difficulty string `json:"difficulty"`
	Drillable  bool   `json:"drillable"`
	Prompt     string `json:"prompt"`
	Hint       string `json:"hint"`

	// Image is the picture a `labelling` question is asked about, named as the
	// file appears in the lesson's directory. It is read here as well as by the
	// grader because the checker has to see it: a question naming a file nobody
	// wrote is one a student cannot answer however well they know the material,
	// and that has to fail on a pull request rather than on a screen.
	Image string `json:"image"`
}

// The question types. EVERY TYPE HAS A MACHINE GRADER — that is the entry
// requirement, not a nice-to-have. Free-text essays are out, because nothing
// can check them and this system has no reviewer.
var exerciseTypes = map[string]bool{
	"quiz":              true,
	"multiple-choice":   true,
	"ordering":          true,
	"matching":          true,
	"code":              true,
	"expected-output":   true,
	"expression-answer": true,
	"numeric":           true,
	"cloze":             true,
	"labelling":         true,
}
