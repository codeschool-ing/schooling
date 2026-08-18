package catalog

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"path"
	"sort"
	"strings"
)

// Load reads one school from a directory.
//
// IT READS EVERYTHING BEFORE IT COMPLAINS. A loader that stops at the first bad
// file makes fixing a catalogue a sequence of runs, each teaching one fact —
// the same waste as a misconfigured deploy that restarts once per missing
// variable. What comes back is the school as far as it could be read, and every
// problem found on the way.
//
// The fs.FS is the seam that makes this testable against a directory of
// deliberately broken fixtures, which is the only way to know the checks fire.
func Load(dir fs.FS) (*School, []error) {
	var problems []error

	var school School
	if err := readJSON(dir, "school.json", &school); err != nil {
		// Without this file there is no school and nothing else can be read
		// against it, so this is the one problem worth stopping for.
		return nil, []error{err}
	}

	tracks, found := loadTracks(dir)
	school.Tracks = tracks
	problems = append(problems, found...)

	courses, found := loadCourses(dir)
	school.Courses = courses
	problems = append(problems, found...)

	return &school, problems
}

func loadTracks(dir fs.FS) ([]*Track, []error) {
	names, err := fs.Glob(dir, "tracks/*.json")
	if err != nil {
		return nil, []error{fmt.Errorf("listing the tracks: %w", err)}
	}
	sort.Strings(names)

	var tracks []*Track
	var problems []error
	for _, name := range names {
		// A translation is not a track. It carries only what is translated and
		// is read beside the file it translates.
		if isTranslation(name) {
			continue
		}

		var track Track
		if err := readJSON(dir, name, &track); err != nil {
			problems = append(problems, err)
			continue
		}
		if track.ID != strings.TrimSuffix(path.Base(name), ".json") {
			problems = append(problems, fmt.Errorf(
				"%s: the track calls itself %q, and a file name is a fact that links do not follow — "+
					"an id that disagrees with its file is a rename half-done", name, track.ID))
		}
		tracks = append(tracks, &track)
	}
	return tracks, problems
}

func loadCourses(dir fs.FS) ([]*Course, []error) {
	entries, err := fs.ReadDir(dir, "courses")
	if err != nil {
		return nil, []error{fmt.Errorf("reading courses/: %w", err)}
	}

	var courses []*Course
	var problems []error
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		course, found := loadCourse(dir, entry.Name())
		problems = append(problems, found...)
		if course != nil {
			courses = append(courses, course)
		}
	}
	return courses, problems
}

func loadCourse(dir fs.FS, name string) (*Course, []error) {
	base := path.Join("courses", name)

	var course Course
	if err := readJSON(dir, path.Join(base, "course.json"), &course); err != nil {
		return nil, []error{err}
	}

	var problems []error
	if course.ID != name {
		problems = append(problems, fmt.Errorf(
			"%s/course.json: the course calls itself %q and lives in %q — one of the two is a "+
				"rename that stopped halfway, and every link points at the directory", base, course.ID, name))
	}

	// The exam, which is optional while a course is being written.
	if exam, err := readExercises(dir, path.Join(base, "exam.json")); err != nil {
		problems = append(problems, err)
	} else {
		course.Exam = exam
	}

	for _, id := range course.Lessons {
		lesson, found := loadLesson(dir, path.Join(base, "lessons", id), id)
		problems = append(problems, found...)
		if lesson != nil {
			course.Loaded = append(course.Loaded, lesson)
		}
	}

	return &course, problems
}

func loadLesson(dir fs.FS, base, name string) (*Lesson, []error) {
	var lesson Lesson
	if err := readJSON(dir, path.Join(base, "lesson.json"), &lesson); err != nil {
		return nil, []error{err}
	}

	var problems []error
	if lesson.ID != name {
		problems = append(problems, fmt.Errorf(
			"%s/lesson.json: the lesson calls itself %q and lives in %q", base, lesson.ID, name))
	}

	if exercises, err := readExercises(dir, path.Join(base, "exercises.json")); err != nil {
		problems = append(problems, err)
	} else {
		lesson.Exercises = exercises
	}

	// Every Markdown file in the directory, so the orphan check has both sides
	// of the comparison. Content that was generated and forgotten shows up
	// nowhere else (C-13) — this is the only place it can be seen.
	lesson.Prose = map[string]bool{}
	files, err := fs.ReadDir(dir, base)
	if err != nil {
		return &lesson, append(problems, fmt.Errorf("reading %s: %w", base, err))
	}
	for _, f := range files {
		if f.IsDir() || !strings.HasSuffix(f.Name(), ".md") {
			continue
		}
		lesson.Files = append(lesson.Files, f.Name())
		lesson.Prose[sectionOfProse(f.Name())] = true
	}

	return &lesson, problems
}

// sectionOfProse answers which section a Markdown file belongs to.
//
// `roles.md` and `roles.pt.md` are the same section in two languages. The
// language is a suffix on the name rather than a directory, so a missing
// translation shows up in `ls` — the cheapest review there is (C-11).
func sectionOfProse(file string) string {
	name := strings.TrimSuffix(file, ".md")
	if i := strings.LastIndex(name, "."); i > 0 {
		return name[:i]
	}
	return name
}

func isTranslation(name string) bool {
	base := strings.TrimSuffix(path.Base(name), ".json")
	return strings.Contains(base, ".")
}

func readExercises(dir fs.FS, name string) ([]Exercise, error) {
	body, err := fs.ReadFile(dir, name)
	if err != nil {
		return nil, nil // optional: a lesson may have no exercises yet
	}

	var exercises []Exercise
	if err := json.Unmarshal(body, &exercises); err != nil {
		return nil, fmt.Errorf("%s: %w", name, err)
	}
	return exercises, nil
}

func readJSON(dir fs.FS, name string, into any) error {
	body, err := fs.ReadFile(dir, name)
	if err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}

	decoder := json.NewDecoder(strings.NewReader(string(body)))
	// A field nobody reads is a field somebody believed in. The predecessor's
	// catalogue collected several, each written once and silently ignored ever
	// since — so an unknown field is an error rather than a shrug.
	decoder.DisallowUnknownFields()

	if err := decoder.Decode(into); err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

// UnmarshalJSON decodes a step, which is either a course id or a fork.
//
// JSON HAS NO SUM TYPE, so this is where the mixture is taken apart. The
// alternative — a field that is sometimes a string and sometimes an object,
// decoded into `any` and type-switched at every use — pushes the same decision
// into every reader instead of making it once.
func (s *Step) UnmarshalJSON(body []byte) error {
	var id string
	if err := json.Unmarshal(body, &id); err == nil {
		s.Course = id
		return nil
	}

	var fork Fork
	decoder := json.NewDecoder(strings.NewReader(string(body)))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&fork); err != nil {
		return fmt.Errorf("a step in a track is either a course id or a fork with options: %w", err)
	}
	s.Fork = &fork
	return nil
}
