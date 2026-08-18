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

// School is one school's whole catalogue, as it is on disk.
type School struct {
	ID      string   `json:"id"`
	Name    string   `json:"name"`
	Accent  string   `json:"accent"`
	Locales []string `json:"locales"`

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

	Lessons []string `json:"lessons"`

	// Draft keeps a course out of what a student sees while it is being
	// written. It is a field rather than a directory, so publishing is a
	// changed line rather than a move that loses the file's history.
	Draft bool `json:"draft"`

	// Filled by Load.
	Loaded []*Lesson `json:"-"`
	Exam   []Exercise
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

// Exercise is one question. Its payload varies by type and is kept raw here:
// checking that a `code` exercise has test cases belongs to the executable half
// of the checks, which runs the answer keys.
type Exercise struct {
	ID         string `json:"id"`
	Version    int    `json:"version"`
	Section    string `json:"section"`
	Type       string `json:"type"`
	Difficulty string `json:"difficulty"`
	Drillable  bool   `json:"drillable"`
	Prompt     string `json:"prompt"`
	Hint       string `json:"hint"`
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
