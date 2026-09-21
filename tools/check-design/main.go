/*
check-design compares every course that has been written against the sheet that
said what it would be.

	# THE SHEETS WERE A SPECIFICATION NOTHING CHECKED

	`docs/design/` holds one sheet per course, all 122, written before any of
	their material: how many lessons, how many sections, how many exercises, how
	many diagrams somebody has to draw, and what the course may assume from the
	ones before it. `docs/design/README.md` argues why they exist, and the
	argument is good — some questions only have an answer at catalogue scale.

	Nothing compared them to `content/`. A sheet could name a course that does
	not exist, carry an id that belongs to another one, or declare thirteen
	lessons for a course whose structure says sixteen, and every check in this
	repository would pass: `validate-content` reads the catalogue and has never
	heard of a sheet, and a sheet is prose that renders perfectly whatever it
	says. It is the same failure shape as the privacy policy against the
	registry, one layer along — a document that keeps looking finished while the
	thing it describes moves underneath it.

	# WHAT IT REFUSES AND WHAT IT ONLY REPORTS, AND WHY THAT LINE IS THERE

	It REFUSES a disagreement of fact: two documents asserting different things
	about one course. The id, the slug, the number of lessons the course is
	designed to have. Those have a right answer, both sides claim to know it,
	and when they differ one of them is wrong and no screen would ever say so.

	It REPORTS a budget. A sheet says a course carries about 150 sections and at
	least 700 exercises; a course being written has fewer, and that is what
	being written IS. Failing on it would make the tool red from the day a
	course is started until the day it is finished, which is a check nobody can
	keep green and therefore a check nobody reads. The numbers are printed
	instead, every run, because the count is the evidence and "it is coming
	along" is an assertion.

	# THE PLAN IS `topics` AND THE MATERIAL IS `lessons`

	A course declares `topics` — the structure, settled before anything is
	written — and gains a `lessons` entry for each topic somebody has written.
	That is `CLAUDE.md`'s sentence: a lesson is a topic somebody wrote. So the
	sheet's lesson count is compared against `topics`, where both are claims
	about the design, and never against `lessons`, which is a claim about
	progress and is supposed to be smaller.
*/
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// sheet is what a design sheet asserts, as far as anything can be compared.
type sheet struct {
	file   string
	slug   string // the `course:` in the front matter
	format string

	// From the headline, which is one line of prose and the only place the
	// sheet names the course's id.
	id      string
	title   string
	hours   int
	lessons int

	// The budgets, which are targets and are only ever printed. Zero means the
	// sheet does not give one, which several legitimately do not.
	sections  int
	exercises int
	diagrams  int

	/* AND WHAT THE SHEET SAYS ABOUT ITSELF TWICE.

	   A sheet whose sections are designed states them as a numbered list AND as
	   a total in `Shape`, and two statements of one fact drift. `listed` counts
	   the rows of that list by kind and `said` is the total row; where both
	   exist they are compared, along with the numbering itself, because a gap
	   or a repeat in 1..N is the silent kind of defect — the list still reads
	   as a list. */
	listed, said sectionCounts
	numbering    []int

	/* AND THE LIST BY IDENTITY RATHER THAN BY COUNT.

	   The totals above answer "how many", which is the question that misses the
	   one that matters. `linux-terminal` designed 223 sections and 228 were
	   written, so this tool reported five — and underneath those five, seven of
	   its thirteen lessons had been written against a different arrangement
	   entirely: fifty-five section names the sheet did not have, and fifty-three
	   the sheet had and the course did not. A difference of five hid a
	   difference of fifty-five, because a total cannot see a rename.

	   `web-fundamentals` is why this is checkable rather than a guess: its sheet
	   and its course share every slug, 74 of 74, so the slug in the sheet IS the
	   slug in `content/` and always was. */
	enumerated []lessonList
}

// lessonList is one lesson's sections in order, from a sheet or from
// `content/`. The two are compared element by element.
type lessonList struct {
	lesson string // `le-…`, which is what the two sides join by
	rows   []sectionRef
}

// sectionRef is what both sides state about a section: its slug and its kind.
// The sheet's `covers` column is prose for a person and has no counterpart in
// `content/`, so it is deliberately not compared.
type sectionRef struct{ slug, kind string }

// sectionCounts is a sheet's section list, or its `Shape` row, by kind.
type sectionCounts struct{ total, reading, video, practice int }

func (c sectionCounts) String() string {
	return fmt.Sprintf("%d (%d reading, %d video, %d practice)",
		c.total, c.reading, c.video, c.practice)
}

// course is what `content/` holds for one of them.
type course struct {
	school   string
	slug     string
	id       string
	topics   int
	lessons  int
	sections int
	written  int // exercises in its lessons
	exam     int // exercises in its exam pool
	figures  int

	// Each written lesson's sections in order, for the comparison by identity.
	lists []lessonList

	// Every lesson this course declares, written or not — so a sheet naming a
	// lesson that belongs to nothing can be told apart from one naming a lesson
	// nobody has written yet. The first is a defect; the second is progress.
	declares map[string]bool
}

func main() {
	design, content := "docs/design", "content"
	if len(os.Args) > 1 {
		design = os.Args[1]
	}
	if len(os.Args) > 2 {
		content = os.Args[2]
	}

	sheets, problems := readSheets(design)
	courses, found := readCourses(content)
	problems = append(problems, found...)
	problems = append(problems, compare(sheets, courses)...)

	report(sheets, courses)

	if len(problems) > 0 {
		fmt.Println("\nwhere the sheet and the course disagree:")
		for _, p := range problems {
			fmt.Println(" - " + p)
		}
		fmt.Printf("\n%d disagreement(s). A sheet is prose and renders perfectly whatever it "+
			"says, so nothing else in this repository would ever have mentioned these.\n",
			len(problems))
		os.Exit(1)
	}
	fmt.Printf("\n%d sheet(s) against %d course(s), and every fact they both claim agrees\n",
		len(sheets), len(courses))
}

/*
The headline, which is the only place a sheet names the course's id.

	IT IS PROSE AND IT IS PARSED ANYWAY, which is a trade worth naming. The
	alternative was to put these fields in the front matter, where they would be
	trivial to read and would be a SECOND place saying what the headline already
	says — and two places holding one value is how the wrong one gets edited.
	The headline is what a person reads, so the headline is what is compared.

	IT WRAPS. Three of the sheets carry it over two lines, broken before a `·`,
	because a title can be long and these files are read as text. Joining those
	lines back is one substitution and the alternative is a rule about how to
	format a document nobody would remember.
*/
var headline = regexp.MustCompile(
	"\\*\\*([^*]+)\\*\\* · `(co-[0-9a-z]{8})` · (\\d+) h declared · \\w+ · (\\d+) lessons · ")

// A budget row of the shape table. The value is prose — `~890, floor 700` and
// `~150, about 11.5 a lesson` are both real — so the FIRST number is taken and
// the rest is commentary, which is the only rule that holds across all of them.
//
// THE WHOLE CELL IS CAPTURED AND THE NUMBER FOUND INSIDE IT, rather than
// matched at its start. The pattern used to read `~?\*{0,2}(\d+)`, which is the
// rule with an order imposed on it: a tilde, then emphasis, then the digits. A
// sheet writing `**~85**` puts them the other way round and matched nothing, so
// the row was read as no budget at all — and `diagrams to draw` is printed as
// `?` when it is zero, which looks like a sheet that declined to say rather
// than a tool that could not read. Seven sheets wrote it that way, and they are
// not a random seven: a sheet bolds the number when the load is remarkable
// ("the most of any course swept so far", "and they are the course"), so the
// reading failed on exactly the courses where the figure budget carries the
// most information.
var budget = regexp.MustCompile(`(?m)^\| (?:\*\*)?([a-z ]+?)(?:\*\*)? \| ([^|\n]*)`)

// The first number in a budget cell, whatever decorates it. Safe because no
// budget row in `docs/design/` opens with prose ahead of its number — the four
// keys this tool reads all begin the cell with the figure, decorated or bare.
var firstNumber = regexp.MustCompile(`\d+`)

var frontCourse = regexp.MustCompile(`(?m)^course:\s*(\S+)\s*$`)
var frontFormat = regexp.MustCompile(`(?m)^format:\s*(\S+)\s*$`)

func readSheets(dir string) ([]sheet, []string) {
	files, err := filepath.Glob(filepath.Join(dir, "*.md"))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	sort.Strings(files)

	var out []sheet
	var problems []string
	for _, f := range files {
		name := strings.TrimSuffix(filepath.Base(f), ".md")
		if name == "README" {
			continue
		}
		body, err := os.ReadFile(f) //nolint:gosec // a path from this tool's own glob
		if err != nil {
			problems = append(problems, fmt.Sprintf("%s: %v", f, err))
			continue
		}
		text := string(body)

		s := sheet{file: filepath.Base(f), slug: name}
		if m := frontCourse.FindStringSubmatch(text); m != nil {
			s.slug = m[1]
		} else {
			problems = append(problems, fmt.Sprintf(
				"%s has no `course:` in its front matter, so nothing says which course it is "+
					"about except its file name", s.file))
		}
		if m := frontFormat.FindStringSubmatch(text); m != nil {
			s.format = m[1]
		}

		/* THE FILE NAME IS THE SLUG, and a sheet that disagrees with its own
		   name is the one failure a reader cannot see: every link to it, every
		   listing and every glob goes by the name, and the field inside is what
		   this tool joins on. They would point at two different courses and
		   both would look right. */
		if s.slug != name {
			problems = append(problems, fmt.Sprintf(
				"%s says it is about %q, and a sheet is found by its file name — so a link "+
					"to it and the course it claims are two different courses", s.file, s.slug))
		}

		// The headline wraps in a few of them, broken before a `·`.
		joined := strings.ReplaceAll(text, "\n·", " ·")
		if m := headline.FindStringSubmatch(joined); m != nil {
			s.title, s.id = strings.TrimSpace(m[1]), m[2]
			s.hours, _ = strconv.Atoi(m[3])
			s.lessons, _ = strconv.Atoi(m[4])
		} else {
			problems = append(problems, fmt.Sprintf(
				"%s has no headline naming its id, its hours and its lessons — that line is "+
					"the only place the sheet and the catalogue say the same things, so "+
					"without it nothing about this sheet can be checked at all", s.file))
		}

		readSelf(&s, text)
		problems = append(problems, consistent(s)...)

		for _, m := range budget.FindAllStringSubmatch(text, -1) {
			n, _ := strconv.Atoi(firstNumber.FindString(m[2]))
			switch strings.TrimSpace(m[1]) {
			/* `sections` WINS OVER `section budget`, and both rows exist on
			   purpose. The budget is the rule of thumb the sheet started from
			   — `~150, about 11.5 a lesson` — and `sections` is what the
			   design came out at once somebody laid the course out, which on
			   `linux-terminal` is 223. Reporting a written course against the
			   rule of thumb would call it 50% over a number the sheet itself
			   already revised. */
			case "sections":
				s.sections = n
			case "section budget":
				if s.sections == 0 {
					s.sections = n
				}
			case "exercises":
				s.exercises = n
			case "diagrams to draw":
				s.diagrams = n
			}
		}
		out = append(out, s)
	}
	return out, problems
}

// readCourses is what `content/` actually holds, counted from the files rather
// than from the mirror: this runs on a pull request, where there is no database
// and the files are the truth anyway (C-01).
func readCourses(dir string) ([]course, []string) {
	dirs, err := filepath.Glob(filepath.Join(dir, "*", "courses", "*"))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	sort.Strings(dirs)

	var out []course
	var problems []string
	for _, d := range dirs {
		info, err := os.Stat(d)
		if err != nil || !info.IsDir() {
			continue
		}
		c := course{school: filepath.Base(filepath.Dir(filepath.Dir(d))), slug: filepath.Base(d)}

		var declared struct {
			ID      string   `json:"id"`
			Lessons []string `json:"lessons"`
			Topics  []struct {
				ID string `json:"id"`
			} `json:"topics"`
		}
		body, err := os.ReadFile(filepath.Join(d, "course.json")) //nolint:gosec // this tool's own glob
		if err != nil {
			problems = append(problems, fmt.Sprintf("%s has no course.json: %v", c.slug, err))
			continue
		}
		if err := json.Unmarshal(body, &declared); err != nil {
			problems = append(problems, fmt.Sprintf("%s/course.json: %v", c.slug, err))
			continue
		}
		c.id, c.lessons, c.topics = declared.ID, len(declared.Lessons), len(declared.Topics)

		c.declares = map[string]bool{}
		for _, t := range declared.Topics {
			c.declares[t.ID] = true
		}
		for _, id := range declared.Lessons {
			c.declares[id] = true
		}

		c.sections, c.lists = countSections(d, declared.Lessons)
		c.written = countExercises(filepath.Join(d, "lessons", "*", "exercises.json"))
		c.exam = countExercises(filepath.Join(d, "exam.json"))
		c.figures = countFigures(d)
		out = append(out, c)
	}
	return out, problems
}

// countSections reads each written lesson's own declaration rather than listing
// its directory: order is declared, never inferred from the filesystem (C-10),
// and a `.md` nobody references is `validate-content`'s finding and not this
// tool's.
func countSections(dir string, lessons []string) (int, []lessonList) {
	n := 0
	var lists []lessonList
	for _, id := range lessons {
		var lesson struct {
			Sections []struct {
				ID   string `json:"id"`
				Slug string `json:"slug"`
				Kind string `json:"kind"`
			} `json:"sections"`
		}
		body, err := os.ReadFile(filepath.Join(dir, "lessons", id, "lesson.json")) //nolint:gosec // composed from a declared id
		if err != nil {
			// A LESSON NOT WRITTEN YET, which is not a disagreement: a course is
			// written one lesson at a time and the sheet designs all of them.
			// It is left out of `lists` so the comparison below has nothing to
			// say about it.
			continue
		}
		if json.Unmarshal(body, &lesson) != nil {
			continue
		}
		n += len(lesson.Sections)
		list := lessonList{lesson: id}
		for _, sec := range lesson.Sections {
			list.rows = append(list.rows, sectionRef{slug: sec.Slug, kind: sec.Kind})
		}
		lists = append(lists, list)
	}
	return n, lists
}

func countExercises(pattern string) int {
	files, err := filepath.Glob(pattern)
	if err != nil {
		return 0
	}
	n := 0
	for _, f := range files {
		body, err := os.ReadFile(f) //nolint:gosec // a path from this tool's own glob
		if err != nil {
			continue
		}
		var exercises []struct {
			ID string `json:"id"`
		}
		if json.Unmarshal(body, &exercises) == nil {
			n += len(exercises)
		}
	}
	return n
}

/*
countFigures counts the diagrams the sheet budgets for.

	IT COUNTS THE ENGLISH ONLY. A figure is drawn once and its translation
	carries the same drawing with a translated caption, so counting every `.md`
	would report a course with two languages as having twice the diagrams —
	a number that grows when somebody translates and says nothing about how much
	drawing is left.
*/
func countFigures(dir string) int {
	files, err := filepath.Glob(filepath.Join(dir, "lessons", "*", "*.md"))
	if err != nil {
		return 0
	}
	n := 0
	for _, f := range files {
		if strings.Count(filepath.Base(f), ".") > 1 {
			continue // `text.pt.md` is a translation of `text.md`
		}
		body, err := os.ReadFile(f) //nolint:gosec // a path from this tool's own glob
		if err != nil {
			continue
		}
		n += strings.Count(string(body), "```schooling-figure")
	}
	return n
}

/*
compare is the half that refuses, and every rule in it is two documents
asserting different things about one course.

	NOT ONE OF THEM IS ABOUT HOW MUCH IS WRITTEN. A course with no material at
	all passes every check here, which is correct: 119 of them have none, and a
	tool that called that a problem would be a tool reporting the state of the
	project rather than a defect in it.
*/
func compare(sheets []sheet, courses []course) []string {
	var problems []string

	byslug := map[string]course{}
	for _, c := range courses {
		byslug[c.slug] = c
	}
	seen := map[string]bool{}

	/* THE CURRENT FORMAT IS WHATEVER THE NEWEST SHEET DECLARES, and there is
	   deliberately no constant anywhere saying which one that is: a constant
	   would be a second place stating the same fact and would disagree with the
	   sheets the first time somebody bumped one file and stopped.

	   So raising the format on one sheet is what fails the others, by name.
	   That is the point rather than a side effect — a sheet left at an older
	   format looks finished and is missing fields nobody remembers. */
	current := 0
	for _, s := range sheets {
		if n, err := strconv.Atoi(s.format); err == nil && n > current {
			current = n
		}
	}

	named := map[string]string{}
	for _, s := range sheets {
		seen[s.slug] = true

		switch n, err := strconv.Atoi(s.format); {
		case s.format == "":
			problems = append(problems, fmt.Sprintf(
				"%s declares no `format:`, so a sheet at an older revision cannot be told "+
					"apart from a current one", s.file))
		case err != nil:
			problems = append(problems, fmt.Sprintf(
				"%s declares format %q, which is not a whole number", s.file, s.format))
		case n < current:
			problems = append(problems, fmt.Sprintf(
				"%s is at format %d and the newest sheet is at %d — bring it up or the "+
					"register is half migrated, with both halves reading as finished",
				s.file, n, current))
		}

		/* AND TWO SHEETS FOR ONE COURSE, which the loop below cannot see: the
		   second silently replaces the first in the map, so the one nobody is
		   reading goes on passing every check there is. */
		if at, taken := named[s.slug]; taken {
			problems = append(problems, fmt.Sprintf(
				"%s and %s are both sheets for %q, and only one of them is ever read",
				at, s.file, s.slug))
		}
		named[s.slug] = s.file

		c, ok := byslug[s.slug]
		if !ok {
			problems = append(problems, fmt.Sprintf(
				"%s is a sheet for %q and there is no such course in content/ — either the "+
					"course was renamed and the sheet was not, or this sheet is for something "+
					"nobody built", s.file, s.slug))
			continue
		}

		if s.id != "" && s.id != c.id {
			problems = append(problems, fmt.Sprintf(
				"%s names the id %s and %s/course.json says %s — an id is written down and "+
					"never worked out, so one of these two was typed and is wrong",
				s.file, s.id, c.slug, c.id))
		}

		/* AGAINST `topics` AND NOT AGAINST `lessons`. A topic is a lesson
		   somebody has not written yet, so `topics` is the design and is what
		   the sheet is also describing; `lessons` is how far along it is, and
		   comparing against that would fail every course that has been started
		   and not finished. */
		if s.lessons > 0 && c.topics > 0 && s.lessons != c.topics {
			problems = append(problems, fmt.Sprintf(
				"%s designs %d lessons and %s/course.json declares %d topics — a topic is a "+
					"lesson somebody has not written yet, so these are two statements of one "+
					"number and they differ", s.file, s.lessons, c.slug, c.topics))
		}

		problems = append(problems, sameSections(s, c)...)
	}

	/* AND THE OTHER DIRECTION, which is the one that actually happens. A course
	   is added to `content/` and the sheet is the step that gets skipped,
	   because nothing downstream needs one — so the catalogue grows a course
	   nobody designed and the sweep the README describes silently stops being
	   about all of them. */
	for _, c := range courses {
		if !seen[c.slug] {
			problems = append(problems, fmt.Sprintf(
				"%s/%s has no design sheet — `docs/design/` is one per course and the "+
					"questions it answers are the ones that only have an answer at catalogue "+
					"scale, so a course missing from it is missing from every one of them",
				c.school, c.slug))
		}
	}
	return problems
}

/*
report is the half that never fails, and it is printed on every run.

	A BUDGET IS NOT A RULE. A sheet says a course carries about 150 sections and
	at least 700 exercises; a course being written has fewer, and that is what
	being written is. A tool that failed on it would be red from the day a
	course is started until the day it is finished — which is a check nobody can
	keep green, and a check nobody can keep green is one whose output everybody
	learns to skip, including on the day it names something real.

	SO THE NUMBERS ARE PRINTED INSTEAD. The count is the evidence; "it is coming
	along" is an assertion. This is the first thing in the repository that can
	answer how far a written course is from what it was designed to be, and the
	answer for `sql-databases` on the day it was written was 20 diagrams against
	a budget of 45.

	ONLY THE COURSES THAT HAVE SOMETHING. 119 rows of zeroes would bury the
	three that say anything, and "nothing written yet" is a fact about the
	project that `ROADMAP.md` already carries.
*/
func report(sheets []sheet, courses []course) {
	design := map[string]sheet{}
	for _, s := range sheets {
		design[s.slug] = s
	}

	sort.Slice(courses, func(i, j int) bool { return courses[i].slug < courses[j].slug })
	started := 0
	for _, c := range courses {
		if c.lessons == 0 {
			continue
		}
		if started == 0 {
			fmt.Println("what is written, against what the sheet designed:")
			fmt.Printf("  %-18s %10s %12s %14s %10s %8s\n",
				"", "lessons", "sections", "exercises", "figures", "exam")
		}
		started++
		s := design[c.slug]
		fmt.Printf("  %-18s %10s %12s %14s %10s %8s\n",
			c.slug,
			against(c.lessons, c.topics),
			against(c.sections, s.sections),
			against(c.written, s.exercises),
			against(c.figures, s.diagrams),
			pool(c.exam))
	}
	if started == 0 {
		fmt.Println("no course has a lesson written yet")
	}
}

// against is "written of designed", or the bare count where the sheet gives no
// number — which is honest rather than tidy: a denominator nobody wrote down is
// not a denominator of zero.
func against(got, want int) string {
	if want <= 0 {
		return fmt.Sprintf("%d of ?", got)
	}
	return fmt.Sprintf("%d of %d", got, want)
}

// pool says how many questions the course's exam holds, and `none` rather than
// `0` — because a course with no exam is a course that cannot be passed and no
// certificate can rest on it (A-08), which a zero in a column does not say.
func pool(n int) string {
	if n == 0 {
		return "none"
	}
	return strconv.Itoa(n)
}

// A row of a sheet's own section list, and the `Shape` row that totals it.
var sectionRow = regexp.MustCompile("(?m)^\\| (\\d+) \\| `[^`]+` \\| (\\w+) \\|")

// A lesson heading in a sheet that lays its sections out, and the rows under
// it. The heading carries the lesson id, which is what the sheet and
// `content/` join by — a title would be joining by prose (C-09), and the
// position would break the moment somebody inserts a lesson.
var lessonHead = regexp.MustCompile("(?m)^\\*\\*Lesson \\d+ · [^\\n]*?`(le-[0-9a-z]{8})`[^\\n]*$")
var listRow = regexp.MustCompile("(?m)^\\| \\d+ \\| `([^`]+)` \\| (\\w+) \\|")
var sectionSaid = regexp.MustCompile(
	`\| sections \| \*\*(\d+)\*\* — (\d+) reading, (\d+) video, (\d+) practice`)

// readSelf fills in what a sheet says about its own sections, in both places it
// says it.
func readSelf(s *sheet, text string) {
	for _, m := range sectionRow.FindAllStringSubmatch(text, -1) {
		n, _ := strconv.Atoi(m[1])
		s.numbering = append(s.numbering, n)
		s.listed.total++
		switch m[2] {
		case "reading":
			s.listed.reading++
		case "video":
			s.listed.video++
		case "practice":
			s.listed.practice++
		}
	}
	/* THE LIST GROUPED BY LESSON. Everything from one lesson's heading to the
	   next belongs to that lesson, which is how the sheet already reads to a
	   person — so nothing here asks an author to write anything new. */
	heads := lessonHead.FindAllStringSubmatchIndex(text, -1)
	for i, h := range heads {
		end := len(text)
		if i+1 < len(heads) {
			end = heads[i+1][0]
		}
		list := lessonList{lesson: text[h[2]:h[3]]}
		for _, m := range listRow.FindAllStringSubmatch(text[h[1]:end], -1) {
			list.rows = append(list.rows, sectionRef{slug: m[1], kind: m[2]})
		}
		s.enumerated = append(s.enumerated, list)
	}

	if m := sectionSaid.FindStringSubmatch(text); m != nil {
		s.said.total, _ = strconv.Atoi(m[1])
		s.said.reading, _ = strconv.Atoi(m[2])
		s.said.video, _ = strconv.Atoi(m[3])
		s.said.practice, _ = strconv.Atoi(m[4])
	}
}

/*
consistent is a sheet against itself, which is the half that needs no catalogue.

	These rules were a Python heredoc in `docs.yml` until `check-design` existed,
	and two of them were then being made twice — once there and once here. Two
	checks of one thing is the arrangement where the strictness of the pair is
	whichever of them somebody edits last, so they are one now.

	WHAT MOVING THEM BOUGHT is that they can be run before pushing. A heredoc
	inside a workflow answers only after a push, has no test, and cannot be
	pointed at a directory — which is why the version in `CLAUDE.md`'s list is
	the version that gets run.
*/
func consistent(s sheet) []string {
	var problems []string
	if s.listed.total == 0 {
		return nil // most sheets do not lay their sections out, which is not a defect
	}

	/* THE NUMBERING IS 1..N, and a gap or a repeat is the silent kind: the list
	   still reads as a list, and the section somebody meant to write is the one
	   that is not there. */
	if missing, repeated := offBy(s.numbering); len(missing)+len(repeated) > 0 {
		problems = append(problems, fmt.Sprintf(
			"%s numbers its sections 1..%d with %v missing and %v repeated — a gap or a "+
				"repeat leaves a list that still reads as a list",
			s.file, len(s.numbering), or(missing), or(repeated)))
	}

	switch {
	case s.said == (sectionCounts{}):
		problems = append(problems, fmt.Sprintf(
			"%s lays its sections out and has no `sections` line in Shape to check the list "+
				"against — the total is then stated once and drifts alone", s.file))
	case s.said != s.listed:
		problems = append(problems, fmt.Sprintf(
			"%s says %s in Shape and lists %s — two statements of one fact, and they differ",
			s.file, s.said, s.listed))
	}
	return problems
}

/*
offBy answers what a numbering of 1..N is missing and what it repeats.

	NAMED RATHER THAN DUMPED. The first version printed the whole list and said
	which position was wrong, which on a sheet of 223 sections is a screenful of
	numbers hiding the two that matter — and a message somebody scrolls past is
	a message that did not arrive.
*/
func offBy(numbering []int) (missing, repeated []int) {
	seen := map[int]int{}
	for _, n := range numbering {
		seen[n]++
	}
	for i := 1; i <= len(numbering); i++ {
		if seen[i] == 0 {
			missing = append(missing, i)
		}
	}
	for n, count := range seen {
		if count > 1 {
			repeated = append(repeated, n)
		}
	}
	sort.Ints(repeated)
	return missing, repeated
}

// or prints an empty list as a word, because `[]` beside `[5]` reads as a second
// number somebody has to decode.
func or(ns []int) any {
	if len(ns) == 0 {
		return "nothing"
	}
	return ns
}

/*
sameSections is the sheet's section list against the course's, by identity.

	THE TOTAL CANNOT SEE A RENAME, and that is not hypothetical. This tool
	reported `linux-terminal` as 228 sections against 223 — five. Underneath the
	five, seven of its thirteen lessons had been written against a different
	arrangement of sections altogether: fifty-five names the sheet did not have,
	fifty-three it had and the course did not. The difference of five was the
	only symptom, and it read as a course that had grown slightly.

	IT IS CHECKABLE BECAUSE THE SLUG IS ALREADY THE SAME STRING. `web-fundamentals`
	shares every slug with its sheet, 74 of 74, which is what makes this a
	measurement rather than a convention somebody is now being asked to adopt.

	WHAT IS COMPARED IS THE SLUG AND THE KIND, in order. The `covers` column is
	prose written for a person and has nothing in `content/` to be compared with;
	the number in the first column is checked separately, as a numbering of 1..N.

	AND ONLY WHERE BOTH SIDES HAVE THE LESSON. A sheet designs every lesson and a
	course is written one at a time, so a lesson with no `lesson.json` yet is
	progress rather than a disagreement — it is left out. A lesson the sheet
	names and the course does not DECLARE is the other thing entirely, and says
	so.
*/
func sameSections(s sheet, c course) []string {
	if len(s.enumerated) == 0 {
		return nil // most sheets do not lay their sections out
	}

	written := map[string][]sectionRef{}
	for _, l := range c.lists {
		written[l.lesson] = l.rows
	}

	var problems []string
	for _, listed := range s.enumerated {
		if !c.declares[listed.lesson] {
			problems = append(problems, fmt.Sprintf(
				"%s lays out sections for %s and %s/course.json does not declare that lesson "+
					"at all — a sheet designing a lesson nothing will ever read",
				s.file, listed.lesson, c.slug))
			continue
		}
		rows, ok := written[listed.lesson]
		if !ok {
			continue // designed, not written yet
		}
		if where, why := firstDifference(listed.rows, rows); why != "" {
			problems = append(problems, fmt.Sprintf(
				"%s and %s/%s disagree at section %d: %s. The sheet lists %d sections there "+
					"and the lesson declares %d — a total cannot see a rename, so a lesson "+
					"rewritten under new names can agree on the count and share nothing",
				s.file, c.slug, listed.lesson, where+1, why,
				len(listed.rows), len(rows)))
		}
	}
	return problems
}

// firstDifference names ONE disagreement rather than printing both lists. A
// lesson holds twenty sections and a sheet holds two hundred; a message that
// dumps them is a message somebody scrolls past, which is the same lesson
// `offBy` learnt one column over.
func firstDifference(listed, written []sectionRef) (int, string) {
	for i := range listed {
		if i >= len(written) {
			return i, fmt.Sprintf("the sheet has `%s` and the lesson ends", listed[i].slug)
		}
		switch {
		case listed[i].slug != written[i].slug:
			return i, fmt.Sprintf("the sheet says `%s` and the lesson says `%s`",
				listed[i].slug, written[i].slug)
		case listed[i].kind != written[i].kind:
			return i, fmt.Sprintf("`%s` is %s on the sheet and %s in the lesson",
				listed[i].slug, listed[i].kind, written[i].kind)
		}
	}
	if len(written) > len(listed) {
		return len(listed), fmt.Sprintf("the lesson has `%s` and the sheet ends",
			written[len(listed)].slug)
	}
	return 0, ""
}
