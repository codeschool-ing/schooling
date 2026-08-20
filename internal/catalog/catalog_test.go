package catalog_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

// The fixtures are a real directory tree rather than an in-memory map, because
// half of what is checked is about the tree itself: a Markdown file nobody
// references, a lesson directory whose name disagrees with the id inside it.
// A map would let those cases be constructed impossibly.

// school loads testdata/good, optionally mutated, and answers every problem.
func school(t *testing.T, changes ...func(dir string)) []error {
	t.Helper()
	_, problems := loadGood(t, changes...)
	return problems
}

// loadGood is the same, and hands back what was loaded as well — for the few
// checks that are about what the catalogue SAYS rather than what is wrong with
// it.
func loadGood(t *testing.T, changes ...func(dir string)) (*catalog.School, []error) {
	t.Helper()

	dir := t.TempDir()
	copyTree(t, "testdata/good", dir)
	for _, change := range changes {
		change(dir)
	}

	loaded, problems := catalog.Load(os.DirFS(dir))
	if loaded != nil {
		problems = append(problems, catalog.Validate(loaded)...)
	}
	return loaded, problems
}

func courseNamed(t *testing.T, s *catalog.School, id string) *catalog.Course {
	t.Helper()
	for _, c := range s.Courses {
		if c.ID == id {
			return c
		}
	}
	t.Fatalf("the fixture has no course %q", id)
	return nil
}

// says answers whether any problem mentions each fragment.
func says(problems []error, fragments ...string) bool {
	joined := ""
	for _, p := range problems {
		joined += p.Error() + "\n"
	}
	for _, f := range fragments {
		if !strings.Contains(joined, f) {
			return false
		}
	}
	return true
}

func report(t *testing.T, problems []error) string {
	t.Helper()
	if len(problems) == 0 {
		return "  (none)"
	}
	var b strings.Builder
	for _, p := range problems {
		b.WriteString("  - " + p.Error() + "\n")
	}
	return b.String()
}

// A catalogue with nothing wrong with it has nothing said about it. Without
// this, every check below could pass by complaining about everything.
func TestAGoodCatalogueIsSilent(t *testing.T) {
	if problems := school(t); len(problems) != 0 {
		t.Errorf("the good fixture was refused:\n%s", report(t, problems))
	}
}

// THE ONE THAT MATTERS MOST.
//
// `requires` is knowledge and a track is a sequence, and conflating them cost
// 18 false edges once. The case that catches it is a fork: a prerequisite
// satisfied only by the branch a student did not choose is not satisfied.
func TestAPrerequisiteInsideAForkIsNotSatisfiedByTheOtherOption(t *testing.T) {
	problems := school(t, requireOf("angular", "react-ts"))

	if !says(problems, `the track "frontend" reaches "angular" before "react-ts"`) {
		t.Errorf("a course requiring the other side of a fork was accepted:\n%s", report(t, problems))
	}
	if !says(problems, "sequence rather than knowledge") {
		t.Errorf("the message does not offer the fix that is usually right:\n%s", report(t, problems))
	}
}

// A cycle is unsatisfiable in every track, forever, so it is reported once and
// the per-track checks are skipped rather than repeating it.
func TestACycleInRequiresIsReportedOnceAndPlainly(t *testing.T) {
	problems := school(t, requireOf("web-fundamentals", "angular"))

	if !says(problems, "the prerequisites form a cycle", "→") {
		t.Errorf("a cycle was not reported:\n%s", report(t, problems))
	}
	if len(problems) != 1 {
		t.Errorf("a cycle produced %d problems; it is one fact and should read as one:\n%s",
			len(problems), report(t, problems))
	}
}

// Content that was generated and forgotten shows up nowhere else in the system
// (C-13): nothing links it, so no screen misses it, and it sits in the
// repository looking like work that was done.
func TestProseNoSectionReferencesIsRefused(t *testing.T) {
	problems := school(t, write(
		"courses/web-fundamentals/lessons/client-and-server/packets.md",
		"---\ntitle: Packets\n---\n\nWritten, and never linked to anything.\n"))

	if !says(problems, "packets.md is not referenced by any section") {
		t.Errorf("an orphaned file was accepted:\n%s", report(t, problems))
	}
}

// The other direction: a step a student opens to find nothing. A schema check
// passes this, which is exactly why the schema is not the reviewer.
func TestAReadingSectionWithNoProseIsRefused(t *testing.T) {
	problems := school(t, addSection("web-fundamentals", "client-and-server",
		catalog.Section{ID: "packets", Kind: catalog.KindReading}))

	if !says(problems, "there is no packets.md", "opens it and finds nothing") {
		t.Errorf("a reading section with no prose was accepted:\n%s", report(t, problems))
	}
}

// THE JOIN THE PREDECESSOR MADE BY TITLE TEXT.
func TestAnExerciseNamingAMissingSectionIsRefused(t *testing.T) {
	problems := school(t, sectionOf("wf-roles-quiz", "the-roles"))

	if !says(problems, `names the section "the-roles"`, "title text") {
		t.Errorf("an exercise joined to nothing was accepted:\n%s", report(t, problems))
	}
}

func TestAnExerciseWithoutAVersionIsRefused(t *testing.T) {
	problems := school(t, patchExercises(
		func(e []map[string]any) { delete(e[0], "version") }))

	if !says(problems, "has version 0", "December's apple with March's orange") {
		t.Errorf("an unversioned exercise was accepted:\n%s", report(t, problems))
	}
}

func TestATypeWithNoGraderIsRefused(t *testing.T) {
	problems := school(t, patchExercises(
		func(e []map[string]any) { e[0]["type"] = "essay" }))

	if !says(problems, `is of type "essay"`, "machine grader") {
		t.Errorf("a question nothing can grade was accepted:\n%s", report(t, problems))
	}
}

// A field written once and silently ignored ever since is how a catalogue
// collects beliefs nobody holds.
func TestAFieldNothingReadsIsRefused(t *testing.T) {
	problems := school(t, patchJSON("courses/web-fundamentals/course.json",
		func(d map[string]any) { d["duration"] = "40h" }))

	if !says(problems, "duration") {
		t.Errorf("an unknown field was accepted:\n%s", report(t, problems))
	}
}

// An id that disagrees with its directory is a rename that stopped halfway, and
// every link points at the directory.
func TestAnIDThatDisagreesWithItsDirectoryIsRefused(t *testing.T) {
	problems := school(t, patchJSON("courses/html-css/course.json",
		func(d map[string]any) { d["id"] = "html-and-css" }))

	if !says(problems, "rename that stopped halfway") {
		t.Errorf("a course whose id and directory disagree was accepted:\n%s", report(t, problems))
	}
}

func TestATrackNamingACourseThatIsNotThereIsRefused(t *testing.T) {
	problems := school(t, patchJSON("tracks/frontend.json", func(d map[string]any) {
		courses, _ := d["courses"].([]any)
		d["courses"] = append(courses, "svelte")
	}))

	if !says(problems, `names the course "svelte", which does not exist`) {
		t.Errorf("a track pointing at nothing was accepted:\n%s", report(t, problems))
	}
}

// A track's final lives beside it rather than inside it, because a track has no
// lessons to put it in (A-08, C-11). It is loaded, checked by the same rules as
// any other question, and it is NOT a track of its own.
func TestATracksFinalIsLoadedAndIsNotATrack(t *testing.T) {
	loaded, problems := catalog.Load(os.DirFS("testdata/good"))
	if loaded == nil {
		t.Fatalf("the good fixture would not load: %v", problems)
	}

	var frontend *catalog.Track
	for _, track := range loaded.Tracks {
		if track.ID == "frontend-exam" {
			t.Fatal("tracks/frontend-exam.json was read as a track, so the final is a track " +
				"nobody can take and the track it belongs to has no final")
		}
		if track.ID == "frontend" {
			frontend = track
		}
	}
	if frontend == nil {
		t.Fatal("the frontend track was not loaded at all")
	}
	if len(frontend.Exam) != 2 {
		t.Fatalf("the frontend final has %d questions, want 2", len(frontend.Exam))
	}
	if frontend.Exam[0].Raw == nil {
		t.Error("a final's question reached the loader with no payload, so the mirror would get " +
			"a question with no answers in it")
	}
}

// And the price of the convention, caught rather than discovered.
//
// `tracks/<x>-exam.json` is skipped as a track and read only by the track `<x>`
// — so if there is no such track, it is a file full of questions that nothing in
// the system will ever mention. That is content generated and forgotten (C-13),
// and it is also what a track somebody happened to call `backend-exam` becomes.
func TestAFinalWithNoTrackIsRefused(t *testing.T) {
	problems := school(t, write("tracks/backend-exam.json", `[
		{"id": "orphan", "version": 1, "type": "quiz", "prompt": "Anybody?",
		 "choices": [{"text": "yes", "correct": true}, {"text": "no"}]}
	]`))

	if !says(problems, "does not exist") {
		t.Errorf("a final belonging to no track was accepted:\n%s", report(t, problems))
	}
}

func TestATrackThatContinuesItselfIsRefused(t *testing.T) {
	problems := school(t, patchJSON("tracks/frontend.json",
		func(d map[string]any) { d["continues"] = "frontend" }))

	if !says(problems, "continues itself") {
		t.Errorf("a track continuing itself was accepted:\n%s", report(t, problems))
	}
}

// A track that continues another may assume its courses, which is what lets a
// second track require the first one's material without listing its hours again.
func TestATrackMayAssumeWhatTheTrackItContinuesTaught(t *testing.T) {
	problems := school(t,
		write("tracks/advanced.json", `{
			"id": "advanced",
			"name": "Advanced Front-end",
			"goal": "…",
			"outcome": "…",
			"courses": ["performance"],
			"continues": "frontend"
		}`),
		course("performance", "web-fundamentals"),
		// A new track is offered somewhere, and the school says where (C-10).
		patchJSON("school.json", func(d map[string]any) {
			d["tracks"] = []any{"frontend", "advanced"}
		}),
	)

	if len(problems) != 0 {
		t.Errorf("a track continuing another was refused for requiring its courses:\n%s",
			report(t, problems))
	}
}

/* ---------- mutations ---------- */

// readFixture and writeFixture are the only two places this file touches the
// disk.
//
// EVERY PATH THEY TAKE IS ONE THIS TEST JUST BUILT, under t.TempDir(). gosec
// cannot see that and flags each call as file inclusion from a variable, so the
// exception is written once here rather than eight times across the helpers —
// which is the difference between one decision somebody can review and eight
// they scroll past.
func readFixture(path string) []byte {
	body, err := os.ReadFile(path) //nolint:gosec // a path this test built under t.TempDir()
	if err != nil {
		panic(err)
	}
	return body
}

func writeFixture(path string, body []byte) {
	if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
		panic(err)
	}
	if err := os.WriteFile(path, body, 0o600); err != nil { //nolint:gosec // the same
		panic(err)
	}
}

func write(name, body string) func(string) {
	return func(dir string) {
		writeFixture(filepath.Join(dir, filepath.FromSlash(name)), []byte(body))
	}
}

func patchJSON(name string, change func(map[string]any)) func(string) {
	return func(dir string) {
		path := filepath.Join(dir, filepath.FromSlash(name))

		var d map[string]any
		if err := json.Unmarshal(readFixture(path), &d); err != nil {
			panic(err)
		}
		change(d)

		out, err := json.MarshalIndent(d, "", "  ")
		if err != nil {
			panic(err)
		}
		writeFixture(path, out)
	}
}

func requireOf(courseID, needed string) func(string) {
	return patchJSON("courses/"+courseID+"/course.json", func(d map[string]any) {
		d["requires"] = []any{needed}
	})
}

func sectionOf(exerciseID, section string) func(string) {
	return patchExercises(func(e []map[string]any) {
		for _, one := range e {
			if one["id"] == exerciseID {
				one["section"] = section
			}
		}
	})
}

// One lesson in the fixture has exercises, so neither the course nor the lesson
// is a parameter. A parameter that only ever receives one value reads as a
// choice somebody made, and there is no choice here to make.
func patchExercises(change func([]map[string]any)) func(string) {
	const name = "courses/web-fundamentals/lessons/client-and-server/exercises.json"
	return func(dir string) {
		path := filepath.Join(dir, filepath.FromSlash(name))

		var d []map[string]any
		if err := json.Unmarshal(readFixture(path), &d); err != nil {
			panic(err)
		}
		change(d)

		out, err := json.MarshalIndent(d, "", "  ")
		if err != nil {
			panic(err)
		}
		writeFixture(path, out)
	}
}

func addSection(courseID, lessonID string, section catalog.Section) func(string) {
	return patchJSON("courses/"+courseID+"/lessons/"+lessonID+"/lesson.json",
		func(d map[string]any) {
			sections, _ := d["sections"].([]any)
			d["sections"] = append(sections, map[string]any{
				"id": section.ID, "kind": section.Kind,
			})
		})
}

// course writes a whole small course, for the cases that need one more.
func course(id, requires string) func(string) {
	return func(dir string) {
		write("courses/"+id+"/course.json", `{
			"id": "`+id+`",
			"name": "`+id+`",
			"category": "front-end",
			"level": "advanced",
			"hours": 20,
			"summary": "A course.",
			"requires": ["`+requires+`"],
			"prerequisites": "…",
			"lessons": ["only"]
		}`)(dir)
		write("courses/"+id+"/lessons/only/lesson.json", `{
			"id": "only",
			"title": "The only lesson",
			"sections": [{ "id": "overview", "kind": "reading" }]
		}`)(dir)
		write("courses/"+id+"/lessons/only/overview.md", "---\ntitle: Overview\n---\n\nText.\n")(dir)
	}
}

func copyTree(t *testing.T, from, to string) {
	t.Helper()
	err := filepath.Walk(from, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(from, path)
		if err != nil {
			return err
		}
		target := filepath.Join(to, rel)
		if info.IsDir() {
			return os.MkdirAll(target, 0o750)
		}
		writeFixture(target, readFixture(path))
		return nil
	})
	if err != nil {
		t.Fatalf("copying the fixture: %v", err)
	}
}

/* ---------- the pictures a question is asked about ---------- */

// A QUESTION ABOUT A PICTURE NOBODY WROTE cannot be answered however well the
// student knows the material, and this is the only place it can be seen. The
// grader compares coordinates and never opens the file; the interface asks the
// server and gets a 404; the student gets a question with a hole in it.
func TestALabellingQuestionNamingAPictureThatIsNotThereIsRefused(t *testing.T) {
	problems := school(t, patchExercises(
		func(e []map[string]any) {
			for _, one := range e {
				if one["id"] == "wf-roles-diagram" {
					one["image"] = "a-diagram-nobody-drew.png"
				}
			}
		}))

	if !says(problems, "a-diagram-nobody-drew.png", "no such file in that course's images/") {
		t.Errorf("a question about a missing picture was accepted:\n%s", report(t, problems))
	}
}

// AND THE OTHER DIRECTION, exactly as for a forgotten `.md`. A picture nothing
// asks about sits in the repository looking like work that was done, goes into
// the mirror, and no screen misses it (C-13).
func TestAPictureNoQuestionLabelsIsRefused(t *testing.T) {
	problems := school(t, write(
		"courses/web-fundamentals/images/nobody-asks.png", "\x89PNG\r\n\x1a\nand the rest"))

	if !says(problems, "nobody-asks.png", "no question labels") {
		t.Errorf("an orphaned picture was accepted:\n%s", report(t, problems))
	}
}

// A file in `images/` that nothing can serve is either a mistake or a format
// with no media type — and the type is a list rather than a sniff, so that what
// a browser is told cannot change under it between releases.
func TestSomethingThatIsNotAPictureInImagesIsRefused(t *testing.T) {
	problems := school(t, write("courses/web-fundamentals/images/notes.txt", "not a picture"))

	if !says(problems, "notes.txt", "not a picture this can serve") {
		t.Errorf("a non-picture in images/ was accepted:\n%s", report(t, problems))
	}
}

// A TRACK HAS NO DIRECTORY, so a labelling question in a final has nowhere for
// its picture to live. It is refused by name rather than let through to fail on
// a screen — and the message says which exams CAN carry one.
func TestALabellingQuestionInATrackFinalIsRefused(t *testing.T) {
	problems := school(t, write("tracks/frontend-exam.json",
		`[{"id":"fe-final-diagram","version":1,"type":"labelling",`+
			`"prompt":"Where is the browser?","image":"request.png",`+
			`"labels":[{"text":"The browser","x":0.5,"y":0.2,"radius":0.1}]}]`))

	if !says(problems, "fe-final-diagram", "TRACK final") {
		t.Errorf("a labelling question in a final was accepted:\n%s", report(t, problems))
	}
}

// A COURSE THAT IS ANNOUNCED AND NOT YET WRITTEN IS ALLOWED, and it is the
// state most of a 122-course catalogue is in for most of its life.
//
// It was an error once. The rule was right that a course a student can OPEN and
// find nothing in is a broken promise, and wrong that the same row is only
// that: it is what a track is drawn from, what a career path's hours are summed
// from, and what somebody deciding whether to subscribe is reading. Refusing it
// meant no track could exist until every course on it was written.
func TestACourseWithNoLessonsIsAnnouncedRatherThanRefused(t *testing.T) {
	problems := school(t, patchJSON("courses/angular/course.json", func(d map[string]any) {
		d["lessons"] = []any{}
	}))

	if len(problems) != 0 {
		t.Errorf("a course that is announced and not yet written was refused:\n%s",
			report(t, problems))
	}
}

// AND AN EMPTY LESSON IS STILL REFUSED. The line is between "not written yet"
// and "written wrongly": a course may be announced with nothing in it, and a
// lesson that exists and holds no sections is a step a student opens to find
// nothing.
func TestALessonWithNoSectionsIsStillRefused(t *testing.T) {
	problems := school(t, patchJSON(
		"courses/web-fundamentals/lessons/client-and-server/lesson.json",
		func(d map[string]any) { d["sections"] = []any{} }))

	if !says(problems, "has no sections") {
		t.Errorf("a lesson with no sections was accepted:\n%s", report(t, problems))
	}
}

// ORDER IS DECLARED, NEVER INFERRED FROM THE FILESYSTEM (C-10), and the tracks
// were the one place this format still inferred it. Sorted by file name, a
// school's nineteen career paths are offered in the order their slugs happen to
// fall in — the first thing a student sees is whichever one starts with an `a`,
// and renaming an id silently reorders the menu.
func TestATrackMissingFromTheSchoolsOrderIsReported(t *testing.T) {
	problems := school(t, patchJSON("school.json", func(d map[string]any) {
		d["tracks"] = []any{}
	}))

	if !says(problems, `the track "frontend" is not in the school's order`) {
		t.Errorf("a track left out of the declared order was accepted:\n%s", report(t, problems))
	}
}

// And the other direction: an order naming a track that has no file is a
// rename half-done, and it says so rather than quietly offering eighteen.
func TestAnOrderNamingATrackThatIsNotThereIsReported(t *testing.T) {
	problems := school(t, patchJSON("school.json", func(d map[string]any) {
		d["tracks"] = []any{"frontend", "backend"}
	}))

	if !says(problems, `names "backend", and there is no tracks/backend.json`) {
		t.Errorf("an order naming a track that does not exist was accepted:\n%s",
			report(t, problems))
	}
}

/* ---------- the track's own sequence, and the catalogue in other languages ---------- */

// A LINK IS AN ARROW AND AN ARROW HAS TO POINT AT SOMETHING IN THIS TRACK.
//
// `links` says "in this track, that one comes after this one", so both ends
// have to be in the track. A link naming a course the track does not contain
// draws an arrow from nowhere — or, worse, draws nothing at all and leaves the
// graph on its fallback, which is the previous step. That is a WRONG edge
// rather than a missing one, and nothing about the screen says so.
func TestALinkNamingSomethingTheTrackDoesNotContainIsRefused(t *testing.T) {
	problems := school(t, patchJSON("tracks/frontend.json", func(d map[string]any) {
		d["links"] = map[string]any{"react-ts": []any{"docker"}}
	}))
	if !says(problems, `says "react-ts" comes after "docker", which the track does not contain`) {
		t.Errorf("a link to a course outside the track was accepted:\n%s", report(t, problems))
	}

	problems = school(t, patchJSON("tracks/frontend.json", func(d map[string]any) {
		d["links"] = map[string]any{"docker": []any{"html-css"}}
	}))
	if !says(problems, `gives an order for the course "docker", which the track does not contain`) {
		t.Errorf("an order for a course outside the track was accepted:\n%s", report(t, problems))
	}
}

// A step number is a position, and a position past the end of the track is a
// link that survived a deletion.
func TestALinkToAStepThatIsNotThereIsRefused(t *testing.T) {
	problems := school(t, patchJSON("tracks/frontend.json", func(d map[string]any) {
		d["links"] = map[string]any{"react-ts": []any{9}}
	}))
	if !says(problems, `comes after step 9, and the track has 3 steps`) {
		t.Errorf("a link to a step that is not there was accepted:\n%s", report(t, problems))
	}
}

// THE ONE THE POSITION KEY EXISTS TO CATCH.
//
// A fork has no id, so its translation is keyed by where the fork sits. Insert
// a step and every fork after it moves while the translations stay put,
// describing a different choice in perfect Portuguese. It is invisible in
// review — both files are well-formed and both read correctly on their own.
func TestAForkTranslationLeftBehindByAReorderingIsRefused(t *testing.T) {
	problems := school(t, patchJSON("tracks/frontend.json", func(d map[string]any) {
		// A step inserted at the front: the fork moves from 2 to 3, and
		// `frontend.pt.json` still translates step 2.
		d["courses"] = append([]any{"react-ts"}, d["courses"].([]any)...)
	}))
	if !says(problems, "translates step 2 as a choice, and that step is the course") {
		t.Errorf("a fork translation describing the wrong step was accepted:\n%s",
			report(t, problems))
	}
}

// And a fork that gained or lost an option leaves its translation naming a
// different number of them. They are matched by position, so the names slide
// onto the wrong branches and a student picks the framework they did not want.
func TestAForkTranslationWithTheWrongNumberOfOptionsIsRefused(t *testing.T) {
	problems := school(t, patchJSON("tracks/frontend.pt.json", func(d map[string]any) {
		d["steps"] = map[string]any{
			"2": map[string]any{"options": []any{"React + TypeScript"}},
		}
	}))
	if !says(problems, "1 option names and the choice has 2") {
		t.Errorf("a fork translation with too few option names was accepted:\n%s",
			report(t, problems))
	}
}

// A TRANSLATION INTO A LANGUAGE THE SCHOOL DOES NOT SERVE IS WORK NOBODY WILL
// EVER SEE. It is not harmful and it is still refused: somebody wrote it
// expecting it to appear, and a file that is silently ignored is worse than one
// that is rejected with a reason.
func TestATranslationIntoALanguageTheSchoolDoesNotListIsRefused(t *testing.T) {
	problems := school(t, write("courses/html-css/course.de.json", `{"name":"HTML und CSS"}`))
	if !says(problems, `"de"`) {
		t.Errorf("a course translated into an unlisted language was accepted:\n%s",
			report(t, problems))
	}
}

/* ---------- a topic is a thing, not a sentence ---------- */

// A TOPIC'S ID IS DECLARED AND IS NOT ITS TITLE.
//
// This is the whole point, so it is checked the only way that proves it: the
// fixture's first topic has an id that its title does not yield. If anything
// derived the id from the title, this would come back as
// `who-asks-and-who-answers` and the lesson it names would be unreachable.
func TestATopicKeepsTheIDItDeclaresWhateverItIsCalled(t *testing.T) {
	loaded, problems := loadGood(t)
	if len(problems) != 0 {
		t.Fatalf("the good fixture was refused:\n%s", report(t, problems))
	}

	course := courseNamed(t, loaded, "web-fundamentals")
	if n := len(course.Topics); n != 2 {
		t.Fatalf("%d topics, want the two the fixture declares", n)
	}

	if got := catalog.TopicID(course.Topics[0]); got != "client-and-server" {
		t.Errorf("a declared id came back as %q — the title is %q, and if that is where this "+
			"came from then rewording a topic moves a student's work",
			got, course.Topics[0].Title)
	}
	if course.Topics[0].Title != "Who asks and who answers" {
		t.Errorf("the title came back as %q", course.Topics[0].Title)
	}

	// And a bare string is still a topic: it takes the slug of its own title,
	// which is what happened implicitly before this existed.
	if got := catalog.TopicID(course.Topics[1]); got != "something-nobody-has-written-yet" {
		t.Errorf("a topic written as a plain string derived %q", got)
	}
}

// Two topics with one id is one topic taking the other's lessons, notes and
// progress — the collision is silent everywhere else.
func TestTwoTopicsWithTheSameIDAreRefused(t *testing.T) {
	problems := school(t, patchJSON("courses/web-fundamentals/course.json",
		func(d map[string]any) {
			d["topics"] = []any{
				map[string]any{"id": "client-and-server", "title": "Who asks"},
				map[string]any{"id": "client-and-server", "title": "And who answers"},
			}
		}))
	if !says(problems, `two topics called "client-and-server"`) {
		t.Errorf("a course with two topics of one name was accepted:\n%s", report(t, problems))
	}
}

// AND A LESSON IS A TOPIC SOMEBODY HAS WRITTEN.
//
// Nothing used to hold those two lists to each other. A lesson whose title no
// topic listed was a lesson no screen could reach: the course drew the
// placeholder for one nobody has written, which looks deliberate. That was met
// once for real, in the browser fixture, and patched there by making two
// strings equal to each other.
func TestALessonThatIsNotATopicIsRefused(t *testing.T) {
	problems := school(t, patchJSON("courses/web-fundamentals/course.json",
		func(d map[string]any) {
			d["topics"] = []any{"Something else entirely"}
		}))
	if !says(problems, `has a lesson "client-and-server" and no topic of that name`) {
		t.Errorf("a lesson no topic names was accepted:\n%s", report(t, problems))
	}
}

// A topic id is a slug, for the reason every other id is: a machine rewrites
// titles, and an id that followed one would take every link with it.
func TestATopicIDThatIsNotASlugIsRefused(t *testing.T) {
	problems := school(t, patchJSON("courses/web-fundamentals/course.json",
		func(d map[string]any) {
			d["topics"] = []any{
				map[string]any{"id": "Client And Server", "title": "Who asks and who answers"},
			}
		}))
	if !says(problems, "is not a slug") {
		t.Errorf("a topic id that is not a slug was accepted:\n%s", report(t, problems))
	}
}

// THE TRANSLATED LISTS ARE MATCHED BY POSITION AND NOTHING CHECKED THE LENGTH.
//
// One entry short and every translation from that point on describes the topic
// above it, in perfect Portuguese, on a screen that looks entirely normal. It is
// the fork-translation failure that shipped in the predecessor, one level down.
func TestATranslatedTopicListOfTheWrongLengthIsRefused(t *testing.T) {
	problems := school(t, write("courses/web-fundamentals/course.pt.json",
		`{"topics":["Quem pergunta e quem responde"]}`))
	if !says(problems, "lists 1 topics and the course has 2") {
		t.Errorf("a short translated topic list was accepted:\n%s", report(t, problems))
	}
}

// And a translation that leaves the list out entirely is fine: a translation
// carries what somebody translated (C-11), and the English contents survive.
func TestATranslationWithNoTopicsAtAllIsAccepted(t *testing.T) {
	problems := school(t, write("courses/web-fundamentals/course.pt.json",
		`{"name":"Fundamentos da web"}`))
	if len(problems) != 0 {
		t.Errorf("a translation of the name alone was refused:\n%s", report(t, problems))
	}
}
