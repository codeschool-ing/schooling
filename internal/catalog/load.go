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
	school.Tracks = inDeclaredOrder(tracks, school.Order)
	problems = append(problems, found...)

	courses, found := loadCourses(dir)
	school.Courses = courses
	problems = append(problems, found...)

	return &school, problems
}

// inDeclaredOrder puts the tracks in the order `school.json` names them.
//
// A track the file does not name keeps its place at the end rather than
// vanishing: losing a whole career path from every screen because somebody
// forgot a line is a far worse failure than showing it last, and `Validate`
// reports the omission by name.
func inDeclaredOrder(tracks []*Track, order []string) []*Track {
	if len(order) == 0 {
		return tracks
	}

	// `school.json` names its tracks by slug, like every other reference in
	// `content/`.
	bySlug := map[string]*Track{}
	for _, t := range tracks {
		bySlug[t.Slug] = t
	}

	out := make([]*Track, 0, len(tracks))
	taken := map[string]bool{}
	for _, slug := range order {
		if t, ok := bySlug[slug]; ok && !taken[slug] {
			out = append(out, t)
			taken[slug] = true
		}
	}
	for _, t := range tracks {
		if !taken[t.Slug] {
			out = append(out, t)
		}
	}
	return out
}

func loadTracks(dir fs.FS) ([]*Track, []error) {
	names, err := fs.Glob(dir, "tracks/*.json")
	if err != nil {
		return nil, []error{fmt.Errorf("listing the tracks: %w", err)}
	}
	// Read in a stable order; the order they are OFFERED in is `school.json`'s
	// and is applied by the caller, which is the only place that knows it.
	sort.Strings(names)

	var tracks []*Track
	var problems []error
	for _, name := range names {
		// A translation is not a track. It carries only what is translated and
		// is read beside the file it translates.
		if isTranslation(name) {
			continue
		}
		// Neither is an exam. It sits beside its track rather than inside it
		// because a track has no lessons to put it in — and it is read below, by
		// the track it belongs to, rather than found here as a track of its own.
		if isTrackExam(name) {
			continue
		}

		var track Track
		if err := readJSON(dir, name, &track); err != nil {
			problems = append(problems, err)
			continue
		}
		/* THE FILE IS NAMED FOR THE SLUG, not for the id. The slug is the
		   readable name and the one every reference in `content/` uses, so it
		   is the one a file name has to agree with; the id is opaque and would
		   make a directory nobody can work in. */
		if track.Slug != strings.TrimSuffix(path.Base(name), ".json") {
			problems = append(problems, fmt.Errorf(
				"%s: the track calls itself %q, and a file name is a fact that links do not follow — "+
					"a slug that disagrees with its file is a rename half-done", name, track.Slug))
		}

		// The track in other languages, beside the file it translates.
		text, found := readTranslations[TrackText](dir, "tracks", track.Slug)
		track.Text = text
		problems = append(problems, found...)

		// The final, which is optional while a track is being written. Its
		// stem is `<slug>-exam`, so its translations are `<slug>-exam.pt.json`
		// and the track's own are `<slug>.pt.json` — neither glob catches the
		// other.
		if exam, err := readExercises(dir, path.Join("tracks", track.Slug+examSuffix)); err != nil {
			problems = append(problems, err)
		} else {
			track.Exam = exam
		}
		examText, found := readTranslations[map[string]ExerciseText](
			dir, "tracks", strings.TrimSuffix(track.Slug+examSuffix, ".json"))
		track.ExamText = examText
		problems = append(problems, found...)

		tracks = append(tracks, &track)
	}

	problems = append(problems, orphanedFinals(names, tracks)...)
	return tracks, problems
}

// orphanedFinals catches `tracks/<x>-exam.json` where there is no track `<x>`.
//
// IT IS THE ONLY WAY THAT MISTAKE IS EVER SEEN. Such a file is skipped as a
// track and read by no track, so it is a file full of questions that nothing in
// the system will ever mention — content that was generated and forgotten
// (C-13), which is precisely the failure this catalogue's format exists to make
// impossible. It also catches the other spelling of it: somebody who meant to
// add a track and called it `backend-exam`.
func orphanedFinals(names []string, tracks []*Track) []error {
	// BY SLUG: the file is `tracks/<slug>-exam.json`, beside `tracks/<slug>.json`.
	known := map[string]bool{}
	for _, t := range tracks {
		known[t.Slug] = true
	}

	var problems []error
	for _, name := range names {
		if !isTrackExam(name) {
			continue
		}
		of := strings.TrimSuffix(path.Base(name), examSuffix)
		if !known[of] {
			problems = append(problems, fmt.Errorf(
				"%s is the final of a track %q that does not exist — nothing will ever read it, so "+
					"either the track is missing or this is a track that was named like an exam",
				name, of))
		}
	}
	return problems
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
	// The directory is named for the slug; see the note in loadTracks.
	if course.Slug != name {
		problems = append(problems, fmt.Errorf(
			"%s/course.json: the course calls itself %q and lives in %q — one of the two is a "+
				"rename that stopped halfway, and every link points at the directory", base, course.Slug, name))
	}

	// What the course is called in other languages, beside the file it
	// translates. See `readTranslations` for why they are found by listing
	// rather than by asking for each locale by name.
	text, found := readTranslations[CourseText](dir, base, "course")
	course.Text = text
	problems = append(problems, found...)

	// The exam, which is optional while a course is being written.
	if exam, err := readExercises(dir, path.Join(base, "exam.json")); err != nil {
		problems = append(problems, err)
	} else {
		course.Exam = exam
	}
	examText, found := readTranslations[map[string]ExerciseText](dir, base, "exam")
	course.ExamText = examText
	problems = append(problems, found...)

	images, found := loadImages(dir, path.Join(base, "images"))
	course.Images = images
	problems = append(problems, found...)

	for _, id := range course.Lessons {
		lesson, found := loadLesson(dir, path.Join(base, "lessons", id), id)
		problems = append(problems, found...)
		if lesson != nil {
			course.Loaded = append(course.Loaded, lesson)
		}
	}

	return &course, problems
}

// loadImages reads a course's `images/` directory.
//
// AN ABSENT DIRECTORY IS NOT A PROBLEM. Most courses have no picture in them,
// and a checker that complained would be a checker somebody adds an empty
// folder to satisfy. A file in there that is not a picture IS a problem: it is
// either a mistake or a format nothing can serve, and it would sit in the
// repository looking like work that was done.
func loadImages(dir fs.FS, base string) ([]Image, []error) {
	files, err := fs.ReadDir(dir, base)
	if err != nil {
		return nil, nil
	}

	var images []Image
	var problems []error
	for _, f := range files {
		if f.IsDir() {
			problems = append(problems, fmt.Errorf(
				"%s/%s is a directory — pictures sit directly in images/, because a question "+
					"names a file and not a path", base, f.Name()))
			continue
		}

		kind := pictureType(f.Name())
		if kind == "" {
			problems = append(problems, fmt.Errorf(
				"%s/%s is not a picture this can serve — png, jpeg, webp and svg are the list, "+
					"and it is a list rather than a sniff so that the type a browser is told "+
					"cannot change under it", base, f.Name()))
			continue
		}

		body, err := fs.ReadFile(dir, path.Join(base, f.Name()))
		if err != nil {
			problems = append(problems, fmt.Errorf("%s/%s: %w", base, f.Name(), err))
			continue
		}
		images = append(images, Image{Name: f.Name(), MediaType: kind, Bytes: body})
	}
	return images, problems
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
	text, found := readTranslations[map[string]ExerciseText](dir, base, "exercises")
	lesson.ExerciseText = text
	problems = append(problems, found...)

	/* THE PROSE IS NAMED FOR THE SLUG AND FILED UNDER THE ID.

	   `vps.md` is what somebody writing a section types, and `se-gy02rmmz` is
	   what the row holding a student's progress through it points at. This is
	   the seam between the two, and it is the only place in the loader that has
	   to know both — every reader downstream gets ids.

	   A file naming no section keeps its own stem, so the orphan check below
	   can say `vps.md` rather than a code that resolves to nothing. */
	bySlug := map[string]string{}
	for _, sec := range lesson.Sections {
		bySlug[sec.Slug] = sec.ID
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

		slug, locale := sectionAndLocale(f.Name())
		lesson.Prose[slug] = true
		section := slug
		if id, ok := bySlug[slug]; ok {
			section = id
		}

		body, err := fs.ReadFile(dir, path.Join(base, f.Name()))
		if err != nil {
			problems = append(problems, fmt.Errorf("%s/%s: %w", base, f.Name(), err))
			continue
		}
		title, text := frontMatter(string(body))
		lesson.Text = append(lesson.Text, Prose{
			SectionID: section, Locale: locale, Title: title, Body: text,
		})
	}

	return &lesson, problems
}

// pictureType answers what a file is, or "" for something that is not a
// picture at all.
//
// A LIST AND NOT A SNIFF. What comes back is served verbatim as the response's
// content type, and a sniffed type is one that changes when the sniffer does —
// which would mean a picture that renders on one release and downloads on the
// next. Four formats cover a diagram; a fifth is one line here and a
// conversation about why.
//
// SVG IS ON THE LIST and that is a considered answer rather than an oversight.
// An SVG can carry script, but it is shown in an `<img>`, where a browser runs
// none of it — and the response says `nosniff` so it cannot be talked into
// being a document. What is NOT allowed is linking to one, which nothing here
// does.
func pictureType(file string) string {
	switch strings.ToLower(path.Ext(file)) {
	case ".png":
		return "image/png"
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".webp":
		return "image/webp"
	case ".svg":
		return "image/svg+xml"
	default:
		return ""
	}
}

// sectionOfProse answers which section a Markdown file belongs to.
//
// `roles.md` and `roles.pt.md` are the same section in two languages. The
// language is a suffix on the name rather than a directory, so a missing
// translation shows up in `ls` — the cheapest review there is (C-11).
func sectionOfProse(file string) string {
	section, _ := sectionAndLocale(file)
	return section
}

func sectionAndLocale(file string) (section, locale string) {
	name := strings.TrimSuffix(file, ".md")
	if i := strings.LastIndex(name, "."); i > 0 {
		return name[:i], name[i+1:]
	}
	// No suffix means the source language, which is English everywhere.
	return name, "en"
}

// frontMatter takes the leading `---` block off a Markdown file.
//
// IT IS NOT YAML AND WILL NOT BECOME YAML. The block carries what belongs to
// the prose and nothing the JSON already knows, which today is one line. A
// parser for the general case would invite the second line, and the second line
// is where a catalogue starts having two places that declare the same thing.
func frontMatter(body string) (title, rest string) {
	body = strings.ReplaceAll(body, "\r\n", "\n")
	if !strings.HasPrefix(body, "---\n") {
		return "", strings.TrimSpace(body)
	}

	block, after, found := strings.Cut(body[len("---\n"):], "\n---")
	if !found {
		// An opening fence with no closing one: the whole file is front matter
		// as far as any parser can tell, so it is left as prose rather than
		// swallowed.
		return "", strings.TrimSpace(body)
	}

	for _, line := range strings.Split(block, "\n") {
		key, value, ok := strings.Cut(line, ":")
		if ok && strings.TrimSpace(key) == "title" {
			title = strings.Trim(strings.TrimSpace(value), `"'`)
		}
	}
	return title, strings.TrimSpace(after)
}

// examSuffix is what makes `tracks/frontend-exam.json` the exam of `frontend`
// rather than a track called `frontend-exam`.
//
// THE PRICE OF THE CONVENTION IS THAT A TRACK MAY NOT BE NAMED `<x>-exam`, and
// `Validate` says so rather than leaving it to be discovered: without that
// check, such a track would be silently skipped here and its own file read as
// somebody else's questions.
const examSuffix = "-exam.json"

func isTrackExam(name string) bool { return strings.HasSuffix(path.Base(name), examSuffix) }

func isTranslation(name string) bool {
	base := strings.TrimSuffix(path.Base(name), ".json")
	return strings.Contains(base, ".")
}

/*
readTranslations reads every `<stem>.<locale>.json` in a directory.

	BY LISTING RATHER THAN BY ASKING. The alternative is to take the school's
	`locales` and open one file per language, which reads the same for the
	languages somebody remembered and says nothing about the ones they did not —
	a file named `course.ptbr.json` or `course.pt-BR.json` would sit there
	untouched and untranslated, and the only symptom would be a screen in
	English. Listing finds every file that looks like a translation and hands the
	locale to `Validate`, which holds it to the school's list.

	The stem is the file's own name — `course` for a course, the track's id for a
	track — so `course.pt.json` and `frontend.pt.json` are found the same way and
	`frontend-exam.json` is not.
*/
func readTranslations[T any](dir fs.FS, base, stem string) (map[string]T, []error) {
	names, err := fs.Glob(dir, path.Join(base, stem+".*.json"))
	if err != nil || len(names) == 0 {
		return nil, nil
	}
	sort.Strings(names)

	out := map[string]T{}
	var problems []error
	for _, name := range names {
		locale := strings.TrimSuffix(strings.TrimPrefix(path.Base(name), stem+"."), ".json")
		if locale == "" || strings.Contains(locale, ".") {
			problems = append(problems, fmt.Errorf(
				"%s: a translation is named `%s.<locale>.json` and this is not", name, stem))
			continue
		}
		var text T
		if err := readJSON(dir, name, &text); err != nil {
			problems = append(problems, err)
			continue
		}
		out[locale] = text
	}
	if len(out) == 0 {
		return nil, problems
	}
	return out, problems
}

func readExercises(dir fs.FS, name string) ([]Exercise, error) {
	body, err := fs.ReadFile(dir, name)
	if err != nil {
		return nil, nil // optional: a lesson may have no exercises yet
	}

	// Decoded twice on purpose: once into the fields this package checks, and
	// once as raw objects so the payload reaches the mirror whole. A single
	// pass would mean either knowing every type's shape here — which is the
	// executable half's job — or dropping the answers.
	var exercises []Exercise
	if err := json.Unmarshal(body, &exercises); err != nil {
		return nil, fmt.Errorf("%s: %w", name, err)
	}

	var raw []json.RawMessage
	if err := json.Unmarshal(body, &raw); err != nil {
		return nil, fmt.Errorf("%s: %w", name, err)
	}
	for i := range exercises {
		exercises[i].Raw = raw[i]
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
