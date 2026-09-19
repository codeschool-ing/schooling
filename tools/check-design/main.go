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
var budget = regexp.MustCompile(`(?m)^\| (?:\*\*)?([a-z ]+?)(?:\*\*)? \| ~?\*{0,2}(\d+)`)

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

		for _, m := range budget.FindAllStringSubmatch(text, -1) {
			n, _ := strconv.Atoi(m[2])
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

		c.sections = countSections(d, declared.Lessons)
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
func countSections(dir string, lessons []string) int {
	n := 0
	for _, id := range lessons {
		var lesson struct {
			Sections []struct {
				ID string `json:"id"`
			} `json:"sections"`
		}
		body, err := os.ReadFile(filepath.Join(dir, "lessons", id, "lesson.json")) //nolint:gosec // composed from a declared id
		if err != nil {
			continue
		}
		if json.Unmarshal(body, &lesson) == nil {
			n += len(lesson.Sections)
		}
	}
	return n
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

	format := ""
	for _, s := range sheets {
		seen[s.slug] = true

		/* ONE FORMAT ACROSS ALL OF THEM. A sheet at an older format is a
		   revision that was started and not finished, and the half that was
		   revised reads exactly like the half that was not. */
		switch {
		case s.format == "":
			problems = append(problems, fmt.Sprintf(
				"%s declares no `format:`, so nothing says which revision of the sheet "+
					"format it was written against", s.file))
		case format == "":
			format = s.format
		case s.format != format:
			problems = append(problems, fmt.Sprintf(
				"%s is format %s where the sheets before it are format %s — a revision that "+
					"stopped halfway leaves two kinds of document that read alike",
				s.file, s.format, format))
		}

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
