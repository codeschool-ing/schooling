package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func says(problems []string, fragments ...string) bool {
	for _, p := range problems {
		all := true
		for _, f := range fragments {
			if !strings.Contains(p, f) {
				all = false
				break
			}
		}
		if all {
			return true
		}
	}
	return false
}

func listed(t *testing.T, problems []string) string {
	t.Helper()
	if len(problems) == 0 {
		return "  (none)"
	}
	return "  - " + strings.Join(problems, "\n  - ")
}

// one sheet and one course that agree about everything, which each test then
// breaks in exactly one place.
func agreeing() ([]sheet, []course) {
	return []sheet{{
			file: "sql-databases.md", slug: "sql-databases", format: "5",
			id: "co-1y7mkp4n", lessons: 13, sections: 150, exercises: 700, diagrams: 45,
		}}, []course{{
			school: "code", slug: "sql-databases", id: "co-1y7mkp4n",
			topics: 13, lessons: 13, sections: 145, written: 788, exam: 100, figures: 10,
		}}
}

func TestASheetAndItsCourseAgreeing(t *testing.T) {
	s, c := agreeing()
	if problems := compare(s, c); len(problems) > 0 {
		t.Errorf("a sheet that agrees with its course was refused:\n%s", listed(t, problems))
	}
}

/*
AN ID IS WRITTEN DOWN AND NEVER WORKED OUT, so two documents naming different
ones means somebody typed one of them.

	It is the failure with the least visible symptom of any here: both files
	render, both read correctly, and the id in the sheet is never resolved
	against anything — so it can name another course entirely, or a course that
	was deleted, for as long as the repository exists.
*/
func TestASheetNamingAnotherCoursesIDIsRefused(t *testing.T) {
	s, c := agreeing()
	s[0].id = "co-8k2p91xz"
	problems := compare(s, c)
	if !says(problems, "names the id co-8k2p91xz", "one of these two was typed") {
		t.Errorf("a sheet naming the wrong id was accepted:\n%s", listed(t, problems))
	}
}

// THE LESSON COUNT IS COMPARED AGAINST `topics`, which is the design, and a
// disagreement there is two documents describing different courses.
func TestADifferentLessonCountIsRefused(t *testing.T) {
	s, c := agreeing()
	c[0].topics = 16
	problems := compare(s, c)
	if !says(problems, "designs 13 lessons", "declares 16 topics") {
		t.Errorf("a sheet designing a different course was accepted:\n%s", listed(t, problems))
	}
}

/*
AND BEING HALF WRITTEN IS NOT A DISAGREEMENT, which is the line this whole tool
is arranged around.

	A course with four of its thirteen lessons written, a fifth of its sections
	and none of its exercises is a course somebody is working on. Refusing it
	would make this tool red from the day a course is started until the day it
	is finished — and a check nobody can keep green is one whose output
	everybody learns to skip, including on the day it names something real.
*/
func TestACourseHalfWrittenIsNotADisagreement(t *testing.T) {
	s, c := agreeing()
	c[0].lessons, c[0].sections, c[0].written, c[0].figures, c[0].exam = 4, 30, 0, 0, 0
	if problems := compare(s, c); len(problems) > 0 {
		t.Errorf("a course that is being written was reported as broken:\n%s",
			listed(t, problems))
	}
}

// A COURSE WITH NO SHEET IS THE ONE THAT ACTUALLY HAPPENS. Nothing downstream
// needs a sheet, so writing one is the step that gets skipped — and then the
// sweep `docs/design/README.md` describes quietly stops being about all of them.
func TestACourseWithNoSheetIsRefused(t *testing.T) {
	s, c := agreeing()
	c = append(c, course{school: "code", slug: "rust", id: "co-000rust0", topics: 9})
	problems := compare(s, c)
	if !says(problems, "code/rust has no design sheet") {
		t.Errorf("a course nobody designed was accepted:\n%s", listed(t, problems))
	}
}

// AND THE OTHER DIRECTION: a sheet for a course that is not there is either a
// rename that stopped halfway or a design for something nobody built.
func TestASheetForNoCourseIsRefused(t *testing.T) {
	s, c := agreeing()
	s = append(s, sheet{file: "rust.md", slug: "rust", format: "5", id: "co-000rust0", lessons: 9})
	problems := compare(s, c)
	if !says(problems, "there is no such course in content/") {
		t.Errorf("a sheet for nothing was accepted:\n%s", listed(t, problems))
	}
}

// ONE FORMAT ACROSS ALL OF THEM, because a revision that stopped halfway leaves
// two kinds of document that read alike.
func TestASheetAtAnotherFormatIsRefused(t *testing.T) {
	s, c := agreeing()
	s = append(s, sheet{file: "linux-terminal.md", slug: "linux-terminal", format: "4",
		id: "co-7mr8mhy8", lessons: 13})
	c = append(c, course{school: "code", slug: "linux-terminal", id: "co-7mr8mhy8", topics: 13})
	problems := compare(s, c)
	if !says(problems, "is at format 4", "newest sheet is at 5") {
		t.Errorf("a sheet at an older format was accepted:\n%s", listed(t, problems))
	}
}

/*
THE HEADLINE WRAPS IN THREE OF THEM, and that is not a formatting preference to
tidy away: a title can be long and these files are read as text.

	This is the test that would have caught the first version, which matched the
	headline on one line and reported three sheets as having none — where "no
	headline" is the message meaning *nothing about this sheet can be checked at
	all*, so three courses would have been silently unchecked by a run that
	still exited non-zero for a reason that looked like a formatting complaint.
*/
func TestAWrappedHeadlineIsStillRead(t *testing.T) {
	dir := t.TempDir()
	body := "---\nformat: 5\ncourse: git\n---\n\n# git\n\n" +
		"**Git and Teamwork: Version Control, Review and Process** · `co-g2dkab2w` · 40 h declared\n" +
		"· beginner · 19 lessons · `foundations` · paid\n"
	if err := os.WriteFile(filepath.Join(dir, "git.md"), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}

	sheets, problems := readSheets(dir)
	if len(problems) > 0 {
		t.Fatalf("a sheet whose headline wraps was reported as broken:\n%s", listed(t, problems))
	}
	if len(sheets) != 1 || sheets[0].id != "co-g2dkab2w" || sheets[0].lessons != 19 {
		t.Errorf("the wrapped headline read as %+v, and it says co-g2dkab2w and 19 lessons",
			sheets[0])
	}
}

// AND A BUDGET ROW IS PROSE, so the first number is the budget and the rest is
// commentary — `~890, floor 700` and `~150, about 11.5 a lesson` are both real.
func TestTheDesignedCountWinsOverTheRuleOfThumb(t *testing.T) {
	dir := t.TempDir()
	body := "---\nformat: 5\ncourse: linux-terminal\n---\n\n" +
		"**Linux** · `co-7mr8mhy8` · 70 h declared · beginner · 13 lessons · `infra` · **free**\n\n" +
		"| section budget | ~150, about 11.5 a lesson — **and 223 are designed** |\n" +
		"| sections | **223** — 170 reading, 40 video, 13 practice |\n" +
		"| exercises | ~890, floor 700 |\n" +
		"| diagrams to draw | ~28 — the filesystem tree, the permission bits |\n"
	if err := os.WriteFile(filepath.Join(dir, "linux-terminal.md"), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	sheets, _ := readSheets(dir)
	if len(sheets) != 1 {
		t.Fatalf("read %d sheets", len(sheets))
	}
	got := sheets[0]
	if got.sections != 223 {
		t.Errorf("the section budget read as %d — the sheet revised its own rule of thumb to "+
			"223 and reporting against 150 would call a finished course 50%% over", got.sections)
	}
	if got.exercises != 890 || got.diagrams != 28 {
		t.Errorf("exercises %d and diagrams %d, from `~890, floor 700` and `~28 — …`",
			got.exercises, got.diagrams)
	}
}

// TWO SHEETS FOR ONE COURSE is the duplicate the comparison itself cannot see:
// the second replaces the first in the map, and the one nobody reads goes on
// passing every check there is.
func TestTwoSheetsForOneCourseAreRefused(t *testing.T) {
	s, c := agreeing()
	s = append(s, sheet{file: "sql.md", slug: "sql-databases", format: "5",
		id: "co-1y7mkp4n", lessons: 13})
	problems := compare(s, c)
	if !says(problems, "are both sheets for", "only one of them is ever read") {
		t.Errorf("a second sheet for one course was accepted:\n%s", listed(t, problems))
	}
}

/*
A SHEET STATES ITS SECTIONS TWICE, and two statements of one fact drift.

	These three rules were a Python heredoc inside `docs.yml` until this tool
	existed, and two of the ones beside them were then being made twice — once
	there and once here. A pair of checks over one thing is an arrangement whose
	strictness is whichever of the two somebody edited last.

	Moving them here is what makes them runnable before a push: a heredoc in a
	workflow answers only after one, carries no test, and cannot be pointed at a
	directory.
*/
func TestASheetsSectionListIsCheckedAgainstItsOwnTotal(t *testing.T) {
	s := sheet{file: "x.md",
		listed:    sectionCounts{total: 4, reading: 2, video: 1, practice: 1},
		said:      sectionCounts{total: 4, reading: 3, video: 0, practice: 1},
		numbering: []int{1, 2, 3, 4}}
	if !says(consistent(s), "says 4 (3 reading, 0 video, 1 practice)", "lists 4 (2 reading") {
		t.Errorf("a Shape row disagreeing with its own list was accepted:\n%s",
			listed(t, consistent(s)))
	}
}

func TestAGapInTheSectionNumberingIsRefused(t *testing.T) {
	s := sheet{file: "x.md",
		listed:    sectionCounts{total: 3, reading: 3},
		said:      sectionCounts{total: 3, reading: 3},
		numbering: []int{1, 2, 4}}
	if !says(consistent(s), "[3] missing", "still reads as a list") {
		t.Errorf("a numbering with a gap was accepted:\n%s", listed(t, consistent(s)))
	}
}

// AND A SHEET THAT DOES NOT LAY ITS SECTIONS OUT IS NOT INCOMPLETE. Most of the
// 122 give a budget and no list, which is the sheet doing its job at the stage
// the course is at.
func TestASheetWithNoSectionListIsFine(t *testing.T) {
	if problems := consistent(sheet{file: "x.md", sections: 150}); len(problems) > 0 {
		t.Errorf("a sheet that budgets its sections without listing them was refused:\n%s",
			listed(t, problems))
	}
}

// A BUDGET THE SHEET BOLDED IS STILL A BUDGET. `~85` and `**~85**` are one
// number written two ways, and the pattern used to require the tilde before the
// emphasis — so the second read as no budget at all and `diagrams to draw`
// printed `?`, which is what the tool prints for a sheet that declined to say.
// Seven sheets write it bolded, and a sheet bolds the number precisely when the
// load is remarkable, so the unreadable ones were the informative ones.
func TestABoldedBudgetIsRead(t *testing.T) {
	dir := t.TempDir()
	body := "---\nformat: 5\ncourse: computing-essentials\n---\n\n" +
		"**Computing** · `co-4t9wqm2h` · 60 h declared · beginner · 16 lessons · `it` · **free**\n\n" +
		"| section budget | ~129, about 8.1 a lesson |\n" +
		"| exercises | **719**, counted after the course was written |\n" +
		"| diagrams to draw | **~85** |\n"
	if err := os.WriteFile(filepath.Join(dir, "computing-essentials.md"), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	sheets, _ := readSheets(dir)
	if len(sheets) != 1 {
		t.Fatalf("read %d sheets", len(sheets))
	}
	if got := sheets[0].diagrams; got != 85 {
		t.Errorf("`**~85**` read as %d diagrams — a budget nobody can read is printed as `?`, "+
			"which reads as a sheet that said nothing rather than a tool that saw nothing", got)
	}
	if got := sheets[0].exercises; got != 719 {
		t.Errorf("`**719**, counted after…` read as %d exercises", got)
	}
}

// AND A CELL WITH NO NUMBER IS STILL NO BUDGET. The row exists, says something
// in words, and means the sheet declined to put a figure on it — which has to
// stay distinct from a number the tool failed to read, or widening the reading
// would turn every prose row into a budget of zero.
func TestABudgetRowWithNoNumberSaysNothing(t *testing.T) {
	dir := t.TempDir()
	body := "---\nformat: 5\ncourse: git\n---\n\n" +
		"**Git** · `co-g2dkab2w` · 40 h declared · beginner · 19 lessons · `foundations` · paid\n\n" +
		"| diagrams to draw | to be decided once the lessons are laid out |\n"
	if err := os.WriteFile(filepath.Join(dir, "git.md"), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	sheets, _ := readSheets(dir)
	if len(sheets) != 1 {
		t.Fatalf("read %d sheets", len(sheets))
	}
	if got := sheets[0].diagrams; got != 0 {
		t.Errorf("a budget row with no figure in it read as %d", got)
	}
}

// laid is a sheet and a course that enumerate the same two-section lesson, for
// the tests below to break in one place each.
func laid() (sheet, course) {
	s := sheet{file: "sql-databases.md", slug: "sql-databases", format: "5",
		id: "co-1y7mkp4n", lessons: 13,
		enumerated: []lessonList{{lesson: "le-5he7q8tg", rows: []sectionRef{
			{slug: "intro", kind: "video"},
			{slug: "the-tree", kind: "reading"},
		}}}}
	c := course{school: "code", slug: "sql-databases", id: "co-1y7mkp4n", topics: 13,
		declares: map[string]bool{"le-5he7q8tg": true},
		lists: []lessonList{{lesson: "le-5he7q8tg", rows: []sectionRef{
			{slug: "intro", kind: "video"},
			{slug: "the-tree", kind: "reading"},
		}}}}
	return s, c
}

func TestASheetAndItsCourseListingTheSameSections(t *testing.T) {
	s, c := laid()
	if problems := sameSections(s, c); len(problems) > 0 {
		t.Errorf("two lists that agree were reported:\n%s", listed(t, problems))
	}
}

// THE FAILURE THIS WAS WRITTEN FOR, and the only shape of it that matters: the
// counts agree and the sections are different. `linux-terminal` had seven
// lessons in this state and the tool reported a difference of five, because a
// total cannot see a rename.
func TestARenamedSectionIsRefusedEvenWhenTheCountAgrees(t *testing.T) {
	s, c := laid()
	c.lists[0].rows[1].slug = "the-filesystem"

	problems := sameSections(s, c)
	if !says(problems, "the sheet says `the-tree`", "the lesson says `the-filesystem`") {
		t.Errorf("a renamed section with the count unchanged was not reported:\n%s",
			listed(t, problems))
	}
	if len(s.enumerated[0].rows) != len(c.lists[0].rows) {
		t.Fatal("this test is only worth anything while both sides have two sections")
	}
}

// AND A KIND IS HALF OF WHAT A SECTION IS. A reading written where the sheet
// designed a video is the same defect one column across, and the slug agreeing
// is what would hide it.
func TestASectionOfAnotherKindIsRefused(t *testing.T) {
	s, c := laid()
	c.lists[0].rows[1].kind = "video"

	if problems := sameSections(s, c); !says(problems, "`the-tree` is reading on the sheet") {
		t.Errorf("a kind that changed was not reported:\n%s", listed(t, problems))
	}
}

// A LESSON DESIGNED AND NOT YET WRITTEN IS PROGRESS. A sheet designs every
// lesson of a course and the course is written one at a time, so comparing
// against what exists would fail every course that has been started.
func TestALessonNotWrittenYetIsNotADisagreement(t *testing.T) {
	s, c := laid()
	s.enumerated = append(s.enumerated, lessonList{lesson: "le-9999zzzz",
		rows: []sectionRef{{slug: "intro", kind: "video"}}})
	c.declares["le-9999zzzz"] = true // declared as a topic, no lesson.json yet

	if problems := sameSections(s, c); len(problems) > 0 {
		t.Errorf("a lesson designed and not written was reported:\n%s", listed(t, problems))
	}
}

// AND A LESSON THE COURSE DOES NOT DECLARE IS THE OTHER THING ENTIRELY: the
// sheet is designing sections for something nothing will ever read, which is
// indistinguishable from the case above unless the two are told apart.
func TestASheetLayingOutALessonTheCourseDoesNotDeclareIsRefused(t *testing.T) {
	s, c := laid()
	s.enumerated = append(s.enumerated, lessonList{lesson: "le-9999zzzz",
		rows: []sectionRef{{slug: "intro", kind: "video"}}})

	if problems := sameSections(s, c); !says(problems, "does not declare that lesson") {
		t.Errorf("a sheet designing a lesson of no course was not reported:\n%s",
			listed(t, problems))
	}
}

// A SHEET THAT LAYS NOTHING OUT SAYS NOTHING, which is most of them: 120 of the
// 122 give a section budget and no list, and reading that as "zero sections
// designed" would fail every one of them.
func TestASheetWithNoListIsNotCompared(t *testing.T) {
	_, c := laid()
	if problems := sameSections(sheet{file: "git.md", slug: "git"}, c); len(problems) > 0 {
		t.Errorf("a sheet with no section list was reported:\n%s", listed(t, problems))
	}
}

// AND THE LIST IS READ OUT OF A REAL SHEET, grouped by the lesson heading —
// because everything above takes the parsed lists as given, and the parsing is
// where a heading that stops matching would silently produce no lists at all
// and pass every test on this page.
func TestTheSectionListIsReadGroupedByLesson(t *testing.T) {
	dir := t.TempDir()
	body := "---\nformat: 5\ncourse: linux-terminal\n---\n\n" +
		"**Linux** · `co-7mr8mhy8` · 70 h declared · beginner · 13 lessons · `infra` · **free**\n\n" +
		"**Lesson 1 · Where you are** — `le-232xd54k`\n\n" +
		"| | slug | kind | covers |\n|---|---|---|---|\n" +
		"| 01 | `intro` | video | opening |\n" +
		"| 02 | `the-prompt` | reading | reading `user@host:~$` |\n\n" +
		"**Lesson 2 · The tree** — `le-072kcf6w`\n\n" +
		"| | slug | kind | covers |\n|---|---|---|---|\n" +
		"| 03 | `paths` | reading | absolute and relative |\n"
	if err := os.WriteFile(filepath.Join(dir, "linux-terminal.md"), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	sheets, _ := readSheets(dir)
	if len(sheets) != 1 {
		t.Fatalf("read %d sheets", len(sheets))
	}
	got := sheets[0].enumerated
	if len(got) != 2 {
		t.Fatalf("two lesson headings produced %d lists", len(got))
	}
	if got[0].lesson != "le-232xd54k" || len(got[0].rows) != 2 {
		t.Errorf("lesson 1 read as %+v", got[0])
	}
	if got[1].lesson != "le-072kcf6w" || len(got[1].rows) != 1 ||
		got[1].rows[0].slug != "paths" {
		t.Errorf("lesson 2 read as %+v", got[1])
	}
}
