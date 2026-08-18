// Command validate-content is the reviewer.
//
// THERE IS NO HUMAN ONE. The material is written by a machine, and what stands
// between a wrong answer key and a student is this and nothing else (C-14). So
// it runs on every pull request, over the files, and it refuses — it does not
// warn, and it has no flag that makes it lenient.
//
// IT REPORTS EVERYTHING AND THEN FAILS. A checker that stops at the first
// problem turns fixing a catalogue into a sequence of runs, each teaching one
// fact. The same argument as config, and the same as the loader it calls.
//
//	validate-content [directory]     (default: content/)
//
// An absent directory is not a failure. The system is finished before any
// content is written, so "there is nothing to check yet" is the expected answer
// for most of this project's life — and a check that failed on it would be
// turned off long before the first course arrived.
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

func main() {
	root := "content"
	if len(os.Args) > 1 {
		root = os.Args[1]
	}

	problems, schools, err := check(root)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	for _, p := range problems {
		fmt.Fprintln(os.Stderr, " -", p)
	}

	switch {
	case len(problems) > 0:
		fmt.Fprintf(os.Stderr, "\n%d problem(s) across %d school(s). "+
			"Nothing here is a warning: each one is something a student would meet.\n",
			len(problems), schools)
		os.Exit(1)
	case schools == 0:
		fmt.Printf("%s holds no schools yet — the system is finished before the content is "+
			"written, so this is the expected answer for now\n", root)
	default:
		fmt.Printf("%d school(s), nothing to report\n", schools)
	}
}

func check(root string) (problems []error, schools int, err error) {
	entries, err := os.ReadDir(root)
	if os.IsNotExist(err) {
		return nil, 0, nil
	}
	if err != nil {
		return nil, 0, fmt.Errorf("reading %s: %w", root, err)
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		dir := filepath.Join(root, entry.Name())

		// A directory with no school.json is not a school and is not silently
		// skipped either: something is in `content/` that nothing will serve.
		if _, err := os.Stat(filepath.Join(dir, "school.json")); err != nil {
			problems = append(problems, fmt.Errorf(
				"%s has no school.json — nothing will serve it, and nothing else will mention it", dir))
			continue
		}
		schools++

		school, found := catalog.Load(os.DirFS(dir))
		for _, p := range found {
			problems = append(problems, fmt.Errorf("%s: %w", entry.Name(), p))
		}
		if school == nil {
			continue
		}
		for _, p := range catalog.Validate(school) {
			problems = append(problems, fmt.Errorf("%s: %w", entry.Name(), p))
		}
	}

	sort.Slice(problems, func(i, j int) bool { return problems[i].Error() < problems[j].Error() })
	return problems, schools, nil
}
