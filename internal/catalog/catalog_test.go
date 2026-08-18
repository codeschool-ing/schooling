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

	dir := t.TempDir()
	copyTree(t, "testdata/good", dir)
	for _, change := range changes {
		change(dir)
	}

	loaded, problems := catalog.Load(os.DirFS(dir))
	if loaded != nil {
		problems = append(problems, catalog.Validate(loaded)...)
	}
	return problems
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
	problems := school(t, patchExercises("web-fundamentals", "client-and-server",
		func(e []map[string]any) { delete(e[0], "version") }))

	if !says(problems, "has version 0", "December's apple with March's orange") {
		t.Errorf("an unversioned exercise was accepted:\n%s", report(t, problems))
	}
}

func TestATypeWithNoGraderIsRefused(t *testing.T) {
	problems := school(t, patchExercises("web-fundamentals", "client-and-server",
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
	return patchExercises("web-fundamentals", "client-and-server", func(e []map[string]any) {
		for _, one := range e {
			if one["id"] == exerciseID {
				one["section"] = section
			}
		}
	})
}

func patchExercises(courseID, lessonID string, change func([]map[string]any)) func(string) {
	name := "courses/" + courseID + "/lessons/" + lessonID + "/exercises.json"
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
