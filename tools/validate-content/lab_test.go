package main

import (
	"strings"
	"testing"
	"testing/fstest"
)

func school(files map[string]string) fstest.MapFS {
	m := fstest.MapFS{}
	for p, body := range files {
		m[p] = &fstest.MapFile{Data: []byte(body)}
	}
	return m
}

// THE DEFECT THIS EXISTS FOR, in the two shapes it shipped in: the setup step
// that runs the author's script, and a program from the author's `lab/`.
func TestALessonCitingTheAuthorsLabIsRefused(t *testing.T) {
	fs := school(map[string]string{
		"courses/rag/course.json":                  `{}`,
		"courses/rag/lab.sh":                       "#!/bin/sh\n",
		"courses/rag/lab/ask.py":                   "print()\n",
		"courses/rag/lessons/le-1/start.md":        "Run this first:\n\n```\n$ sudo bash lab.sh up\n```\n",
		"courses/rag/lessons/le-1/start.pt.md":     "Rode antes:\n\n```\n$ python lab/ask.py.\n```\n",
		"courses/rag/lessons/le-1/captures.sh":     "lab.sh is fine in here\n",
		"courses/rag/lessons/le-1/exercises.json":  `[{"hint": "captures.sh shows it"}]`,
		"courses/rag/lessons/le-1/lesson.json":     `{"sections": [{"videos": [{"script": "open lab/ask.py"}]}]}`,
		"courses/rag/lab/README.md":                "lab.sh here is the author's own note\n",
		"courses/rag/exam.json":                    `[]`,
		"courses/rag/lessons/le-1/figures-tool.py": "lab.sh\n",
	})

	problems, notes := checkLabReferences("code", fs, map[string]bool{})
	if len(notes) != 0 {
		t.Errorf("nothing is listed, so nothing is counted quietly; got %v", notes)
	}

	var got []string
	for _, p := range problems {
		got = append(got, p.Error())
	}
	all := strings.Join(got, "\n")
	for _, want := range []string{
		`rag/lessons/le-1/start.md:4 names "lab.sh"`,
		`rag/lessons/le-1/start.pt.md:4 names "lab/ask.py"`,
		`rag/lessons/le-1/exercises.json:1 names "captures.sh"`,
		`rag/lessons/le-1/lesson.json:1 names "lab/ask.py"`,
	} {
		if !strings.Contains(all, want) {
			t.Errorf("expected a problem containing %q; got:\n%s", want, all)
		}
	}
	if len(problems) != 4 {
		t.Errorf("the author's own files are not read by the student and are not checked; "+
			"want 4 problems, got %d:\n%s", len(problems), all)
	}
}

// A `lab/` that belongs to somebody else is not the course's: a log directory
// on a machine the lesson built, the student's own folder, a word ending in it.
// And a course with no `lab/` of its own has nothing a `lab/` could point at.
func TestALabThatIsNotTheCoursesIsNotACitation(t *testing.T) {
	fs := school(map[string]string{
		"courses/net/lab/x.sh": "",
		"courses/net/lessons/le-1/logs.md": "Read /var/log/lab/portal.log, then make ~/lab/ " +
			"and look in guardlab/pipeline.py.\n",
		"courses/web/lessons/le-1/start.md": "Make a folder: `mkdir lab/` and work there.\n",
	})

	if problems, _ := checkLabReferences("code", fs, map[string]bool{}); len(problems) != 0 {
		t.Errorf("none of these is the course's authoring lab; got %v", problems)
	}
}

// THE RATCHET. A listed course is counted rather than refused; a listed course
// with nothing left fails until it is unlisted; a listing for a course that is
// gone fails, because nobody would ever delete it.
func TestTheListOnlyShrinks(t *testing.T) {
	fs := school(map[string]string{
		"courses/still/lessons/le-1/a.md": "sudo bash lab.sh up\n",
		"courses/fixed/lessons/le-1/a.md": "Install it yourself.\n",
	})
	pending := map[string]bool{"code/still": true, "code/fixed": true, "code/gone": true}

	problems, notes := checkLabReferences("code", fs, pending)
	if len(notes) != 1 || !strings.Contains(notes[0], "code: still still cites its lab in 1 place") {
		t.Errorf("the listed course with a citation is counted out loud; got %v", notes)
	}

	all := ""
	for _, p := range problems {
		all += p.Error() + "\n"
	}
	if !strings.Contains(all, "fixed cites no authoring file any more") {
		t.Errorf("a fixed course that is still listed must fail; got:\n%s", all)
	}
	if !strings.Contains(all, "lab-pending/code/gone names a course that does not exist") {
		t.Errorf("a listing for a missing course must fail; got:\n%s", all)
	}
	if len(problems) != 2 {
		t.Errorf("want exactly those two; got:\n%s", all)
	}
}

// The embedded list is read, and the README beside it is not a course.
func TestTheEmbeddedListIsRead(t *testing.T) {
	pending, err := pendingCourses()
	if err != nil {
		t.Fatal(err)
	}
	for key := range pending {
		if !strings.Contains(key, "/") || strings.HasSuffix(key, ".md") {
			t.Errorf("%q is not a <school>/<slug> listing", key)
		}
	}
}
