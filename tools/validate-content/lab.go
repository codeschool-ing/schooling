package main

import (
	"bufio"
	"bytes"
	"embed"
	"fmt"
	"io/fs"
	"path"
	"regexp"
	"sort"
	"strings"
)

/*
A LESSON THAT HANDS THE STUDENT A FILE THEY WERE NEVER GIVEN.

	A course is written in a sandbox, and the sandbox has a lab: `lab.sh` beside
	`course.json` builds the machines, a lesson's `captures.sh` reproduces its
	transcripts, and `lab/` holds the programs the lab runs. They are how this
	repository proves every capture was run. The STUDENT gets none of them: the
	loader reads `course.json`, the lessons and the questions, and nothing else
	in the directory reaches a screen (C-38: the student's own machine is the
	lab, and the platform provides none).

	So a lesson that says `sudo bash lab.sh up` is a first step nobody can take,
	and one that says "run lab/evalkit.py" names a program that is not on the
	student's computer. Both read perfectly. Both passed every check this
	repository had, and 21 courses carried at least one before this existed —
	the brief that asked for a lab never said that the student does not get it.

	What is caught is the NAME of an authoring file: `lab.sh`, `captures.sh` and
	its relatives, and a path under the course's own `lab/`. Inside a fence too,
	because a command in a fence is the one most likely to be typed. What is NOT
	caught is a command the lab installs under a plain name, an example project
	the lessons use and never show, or data the student never receives — those
	have no spelling a machine can recognise, and the audit that found the 21
	found them by reading.

	THE COURSES ALREADY WRONG ARE LISTED, ONE FILE EACH, in `lab-pending/`. The
	list is a ratchet and not an exemption: a listed course is counted on every
	run, a listed course with nothing left to report fails until its file is
	deleted, and a course that is not listed fails on its first hit. One file per
	course so that the pull requests fixing them, which run side by side, each
	delete their own line without conflicting with the others.
*/

//go:embed all:lab-pending
var labPending embed.FS

// authoringScript is a capture or lab script by name. `captures-browser.sh` and
// the singular `capture.sh` are the same thing under the spellings the
// catalogue already uses.
var authoringScript = regexp.MustCompile(`\b(?:lab|captures?(?:-[a-z0-9-]+)?)\.sh\b`)

// labPath is a path that starts at the course's own `lab/`. A `lab/` with a
// slash, a tilde or a word before it is somebody else's: `/var/log/lab/` on a
// machine the lesson built, `~/lab/` in the student's home, `guardlab/`.
var labPath = regexp.MustCompile(`(?:^|[^~/\w.-])(lab/(?:[\w./-]*[\w/])?)`)

// pendingCourses reads `lab-pending/<school>/<slug>`. The README beside them is
// not a course.
func pendingCourses() (map[string]bool, error) {
	pending := map[string]bool{}
	err := fs.WalkDir(labPending, "lab-pending", func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || path.Base(p) == "README.md" {
			return nil
		}
		pending[strings.TrimPrefix(p, "lab-pending/")] = true
		return nil
	})
	return pending, err
}

// studentFile answers whether the loader reads a file at this path inside a
// course directory, which is what makes it something a student reads.
func studentFile(rel string) bool {
	parts := strings.Split(rel, "/")
	name := parts[len(parts)-1]
	switch len(parts) {
	case 1:
		return strings.HasSuffix(name, ".json") &&
			(strings.HasPrefix(name, "course.") || strings.HasPrefix(name, "exam."))
	case 3:
		if parts[0] != "lessons" {
			return false
		}
		return name == "lesson.json" || strings.HasSuffix(name, ".md") ||
			(strings.HasPrefix(name, "exercises.") && strings.HasSuffix(name, ".json"))
	}
	return false
}

type labHit struct {
	file string
	line int
	text string
}

// labHits finds every authoring name in one file. `hasLab` says whether the
// course has a `lab/` of its own; without one, a `lab/` in its prose is not
// a reference to anything this repository holds.
func labHits(file string, body []byte, hasLab bool) []labHit {
	var hits []labHit
	sc := bufio.NewScanner(bytes.NewReader(body))
	sc.Buffer(make([]byte, 0, 1<<20), 1<<24)
	for n := 1; sc.Scan(); n++ {
		line := sc.Text()
		for _, m := range authoringScript.FindAllString(line, -1) {
			hits = append(hits, labHit{file, n, m})
		}
		if !hasLab {
			continue
		}
		for _, m := range labPath.FindAllStringSubmatch(line, -1) {
			hits = append(hits, labHit{file, n, m[1]})
		}
	}
	return hits
}

// checkLabReferences walks every course of one school. It answers the problems
// and, separately, one line per listed course that still has hits — said on
// every run, because a ratchet nobody sees turning is a list nobody shortens.
func checkLabReferences(school string, schoolFS fs.FS, pending map[string]bool) (problems []error, notes []string) {
	courses, err := fs.ReadDir(schoolFS, "courses")
	if err != nil {
		return []error{fmt.Errorf("%s: reading courses: %w", school, err)}, nil
	}

	seen := map[string]bool{}
	for _, c := range courses {
		if !c.IsDir() {
			continue
		}
		slug := c.Name()
		key := school + "/" + slug
		seen[key] = true
		root := "courses/" + slug

		_, statErr := fs.Stat(schoolFS, root+"/lab")
		hasLab := statErr == nil

		var hits []labHit
		walkErr := fs.WalkDir(schoolFS, root, func(p string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			rel := strings.TrimPrefix(p, root+"/")
			if d.IsDir() || !studentFile(rel) {
				return nil
			}
			body, err := fs.ReadFile(schoolFS, p)
			if err != nil {
				return err
			}
			hits = append(hits, labHits(rel, body, hasLab)...)
			return nil
		})
		if walkErr != nil {
			problems = append(problems, fmt.Errorf("%s: %s: %w", school, slug, walkErr))
			continue
		}

		switch {
		case pending[key] && len(hits) == 0:
			problems = append(problems, fmt.Errorf(
				"%s: %s cites no authoring file any more and is still listed in "+
					"tools/validate-content/lab-pending/%s — delete that file, or the next "+
					"course to slip back in passes unnoticed", school, slug, key))
		case pending[key]:
			files := map[string]bool{}
			for _, h := range hits {
				files[h.file] = true
			}
			notes = append(notes, fmt.Sprintf(
				"%s: %s still cites its lab in %d place(s) across %d file(s) (listed in lab-pending)",
				school, slug, len(hits), len(files)))
		default:
			for _, h := range hits {
				problems = append(problems, fmt.Errorf(
					"%s: %s/%s:%d names %q, and the student is never given the course's "+
						"authoring files (C-38) — show what they need inside the lesson, or "+
						"teach them to build it on their own machine",
					school, slug, h.file, h.line, h.text))
			}
		}
	}

	// A listed course that is not there any more is a listing nobody will ever
	// delete, which is how an exception outlives what it excused.
	var stale []string
	for key := range pending {
		if strings.HasPrefix(key, school+"/") && !seen[key] {
			stale = append(stale, key)
		}
	}
	sort.Strings(stale)
	for _, key := range stale {
		problems = append(problems, fmt.Errorf(
			"tools/validate-content/lab-pending/%s names a course that does not exist", key))
	}
	return problems, notes
}
