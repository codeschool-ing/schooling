// Command check-actions reads this repository's workflows and refuses an action
// that is not pinned to a commit, or that runs on a JavaScript runtime GitHub
// has deprecated.
//
// # THE FAILURE IT EXISTS TO CATCH
//
// The deploy of `v0.51.0` went out green with a warning at the foot of its log:
// `google-github-actions/auth` and `setup-gcloud` declared `node20`, which
// GitHub had deprecated, and the runner forced them onto Node 24 rather than
// failing. It worked — for as long as the forcing lasts. The day it stops, the
// job that breaks is `Deploy`, which is the one nobody can test before running
// it: it breaks on the afternoon of a release, after five images have already
// been pushed to the registry.
//
// IT WAS FIVE ACTIONS AND THE WARNING NAMED TWO. A warning is emitted by the
// job that ran the action, so the `Deploy` warning listed the two actions that
// job uses. `setup-go`, `setup-node` and `golangci-lint-action` were in exactly
// the same state and said so at the foot of the `Go` and `Browser` jobs, which
// nobody had read. That is the shape this tool answers: the information was
// there, once per job, in the place people look only when something is already
// red.
//
// # WHY IT FETCHES, AND WHY THE RUNTIME IS NOT WRITTEN DOWN HERE
//
// Nothing in a workflow file says what runtime an action uses. The obvious
// cheap answer is to record it beside the pin — `# v7.0.0 node24` — and check
// the token offline. That is a claim held by a comment: it is written by the
// same person, in the same edit, as the pin it describes, and it stays green
// while being wrong. This repository has that rule the other way round, so the
// runtime is READ from the action rather than asserted about it: the pinned
// commit's own `action.yml`, fetched, and `runs.using` taken from it.
//
// It is the second thing here that touches the network, after `tools/fonts`,
// and `-offline` drops to the half that does not — the pinning rules, which are
// about the text of the workflow and need nobody's server.
//
// # WHAT IT CHECKS
//
//  1. Every `uses:` naming somebody else's action is pinned to a 40-character
//     commit. A moving tag is somebody else's repository deciding what runs
//     with this one's credentials, and `release.yml` authenticates to Google.
//  2. Every pin carries the version it was cut from in a comment. The commit is
//     what runs; the comment is the only thing that makes the pin legible to a
//     person deciding whether it is old. A pin with no version is a pin nobody
//     will ever move.
//  3. The runtime that commit declares is not one GitHub has deprecated.
//
// A local `./.github/workflows/…` is exempt from all three: it is this
// repository, at this commit, and there is nothing to pin it to.
//
// # WHAT IT DOES NOT CHECK
//
// Whether a pin is OLD. A deprecation is a fact with a date on it and this tool
// can see it; "there is a newer version" is not a defect, and a check that said
// so would fail on the morning of every upstream release and be silenced by
// lunchtime.
package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// The runtimes GitHub has announced the end of. A runner still runs these, by
// forcing them onto a newer Node and warning — which is the state this tool
// exists to make visible, because the forcing is temporary and the warning is
// at the foot of a log that is green.
//
// `node24` is absent on purpose: what belongs in this list is what has been
// deprecated, not what is not the newest. The day node24 joins it, this is the
// one line that changes.
var deprecated = map[string]string{
	"node12": "deprecated in 2022",
	"node16": "deprecated in 2023",
	"node20": "deprecated in 2025",
}

// A `uses:` line, with whatever trailing comment it carries. The leading `- `
// is optional because a step with a `name:` above it puts the `uses:` on its
// own line — two of this repository's are written that way, including the one
// that exchanges a token for Google credentials.
//
// It is read from the text rather than from parsed YAML for one reason: the
// comment. A YAML parser drops it, and the comment is where the version lives —
// so parsing the file properly would throw away half of what is being checked.
var usesLine = regexp.MustCompile(`^\s*(?:-\s+)?uses:\s*(\S+)\s*(#.*)?$`)

// `owner/repo@ref`, optionally with a path in between — `owner/repo/dir@ref` is
// legal and a few actions publish that way.
var useRef = regexp.MustCompile(`^([^/@]+/[^@]+)@(.+)$`)

var commitSHA = regexp.MustCompile(`^[0-9a-f]{40}$`)

// The version in the trailing comment. `# v7.0.0`, and anything after it is
// commentary.
var versionComment = regexp.MustCompile(`#\s*(v\d+\.\d+\.\d+\S*)`)

// `runs:` → `using:` out of an `action.yml`, read with a pattern rather than a
// YAML parser because this is the only field wanted and an action file may
// carry anything else at all.
var runsUsing = regexp.MustCompile(`(?m)^\s*using:\s*['"]?([a-zA-Z0-9]+)['"]?`)

// A pin found in a workflow, and where it was written.
type pin struct {
	where   string // `.github/workflows/release.yml:199`
	action  string // `google-github-actions/auth`
	ref     string // the commit, or the tag somebody left in place of one
	version string // out of the trailing comment, empty if there is none
}

func main() {
	offline := false
	for _, a := range os.Args[1:] {
		if a == "-offline" || a == "--offline" {
			offline = true
			continue
		}
		fmt.Fprintf(os.Stderr, "unknown argument %q — the only one is -offline\n", a)
		os.Exit(2)
	}

	pins, err := read(".github/workflows")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	// A walk that found nothing passes forever and says nothing, which is the
	// failure every check that reads a tree can have and never report.
	if len(pins) == 0 {
		fmt.Fprintln(os.Stderr, "no action is used by any workflow, which cannot be right")
		os.Exit(1)
	}

	problems := pinned(pins)

	runtimes := map[string]string{}
	if offline {
		fmt.Println("· the runtimes were not read: -offline")
	} else {
		var errs []string
		runtimes, errs = runtimesOf(pins)
		problems = append(problems, errs...)
		problems = append(problems, obsolete(pins, runtimes)...)
	}

	if len(problems) > 0 {
		for _, p := range problems {
			fmt.Fprintln(os.Stderr, p)
		}
		fmt.Fprintf(os.Stderr, "\n%d problem(s)\n", len(problems))
		os.Exit(1)
	}

	if offline {
		fmt.Printf("%d action use(s) across the workflows, every one pinned to a commit "+
			"and carrying the version it was cut from\n", len(pins))
		return
	}
	fmt.Printf("%d action use(s) across the workflows, %d distinct commit(s), "+
		"every one pinned and carrying its version, and none on a runtime "+
		"GitHub has deprecated\n", len(pins), len(runtimes))
}

// read collects every `uses:` in every workflow under dir.
func read(dir string) ([]pin, error) {
	var pins []pin

	err := filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if ext := filepath.Ext(path); ext != ".yml" && ext != ".yaml" {
			return nil
		}

		f, err := os.Open(path) //nolint:gosec // a path this tool's own walk produced
		if err != nil {
			return err
		}
		// read-only: there is nothing a failed close could lose
		defer func() { _ = f.Close() }()

		rel := filepath.ToSlash(path)
		scan := bufio.NewScanner(f)
		for n := 1; scan.Scan(); n++ {
			m := usesLine.FindStringSubmatch(scan.Text())
			if m == nil {
				continue
			}
			// This repository, at this commit. `release.yml` calls `ci.yml`
			// rather than repeating its steps, and there is nothing to pin.
			if strings.HasPrefix(m[1], "./") {
				continue
			}

			p := pin{where: fmt.Sprintf("%s:%d", rel, n), action: m[1]}
			if r := useRef.FindStringSubmatch(m[1]); r != nil {
				p.action, p.ref = r[1], r[2]
			}
			if v := versionComment.FindStringSubmatch(m[2]); v != nil {
				p.version = v[1]
			}
			pins = append(pins, p)
		}
		return scan.Err()
	})
	if err != nil {
		return nil, fmt.Errorf("reading %s: %w", dir, err)
	}
	return pins, nil
}

// pinned is the offline half: a commit, and a version beside it.
func pinned(pins []pin) []string {
	var problems []string
	for _, p := range pins {
		switch {
		case p.ref == "":
			problems = append(problems, fmt.Sprintf(
				"%s uses %s with no ref at all", p.where, p.action))
		case !commitSHA.MatchString(p.ref):
			problems = append(problems, fmt.Sprintf(
				"%s pins %s to %q, which is a tag rather than a commit — a tag is "+
					"somebody else's repository deciding what runs with this one's "+
					"credentials, and `release.yml` authenticates to Google",
				p.where, p.action, p.ref))
		case p.version == "":
			problems = append(problems, fmt.Sprintf(
				"%s pins %s to a commit with no version beside it — write `# vX.Y.Z`. "+
					"The commit is what runs; the comment is the only thing that makes "+
					"the pin legible to somebody deciding whether it is old",
				p.where, p.action))
		}
	}
	return problems
}

// runtimesOf fetches each distinct pinned commit's `action.yml` and reads
// `runs.using` out of it. The key is `action@commit`.
func runtimesOf(pins []pin) (map[string]string, []string) {
	found := map[string]string{}
	var problems []string

	client := &http.Client{Timeout: 20 * time.Second}
	for _, p := range pins {
		if !commitSHA.MatchString(p.ref) {
			continue // already reported by the offline half
		}
		key := p.action + "@" + p.ref
		if _, seen := found[key]; seen {
			continue
		}
		using, err := runtimeAt(client, p.action, p.ref)
		if err != nil {
			// DELIBERATELY ITS OWN SENTENCE and not a verdict. "Could not
			// reach it" and "it is deprecated" are different facts, and a tool
			// that reported the first as the second would send somebody to
			// change a pin that is fine.
			problems = append(problems, fmt.Sprintf(
				"%s: the runtime of %s could not be read: %v", p.where, key, err))
			continue
		}
		found[key] = using
	}
	return found, problems
}

// obsolete is the verdict, over runtimes already read.
func obsolete(pins []pin, runtimes map[string]string) []string {
	var problems []string
	said := map[string]bool{}
	for _, p := range pins {
		key := p.action + "@" + p.ref
		using, ok := runtimes[key]
		if !ok || said[key] {
			continue
		}
		if when, dead := deprecated[using]; dead {
			said[key] = true
			problems = append(problems, fmt.Sprintf(
				"%s: %s (%s) declares `using: %s`, %s. A runner still runs it, by "+
					"forcing it onto a newer Node and warning at the foot of a green "+
					"log — until it does not, and then the job simply fails",
				p.where, p.action, p.version, using, when))
		}
	}
	return problems
}

// runtimeAt reads `runs.using` from one commit's action file. An action may
// name it `action.yml` or `action.yaml`; both are legal and both are used.
func runtimeAt(client *http.Client, action, sha string) (string, error) {
	var last error
	for _, name := range []string{"action.yml", "action.yaml"} {
		url := fmt.Sprintf("https://raw.githubusercontent.com/%s/%s/%s", action, sha, name)
		body, err := get(client, url)
		if err != nil {
			last = err
			continue
		}
		m := runsUsing.FindStringSubmatch(body)
		if m == nil {
			return "", fmt.Errorf("%s names no `using:`", name)
		}
		return m[1], nil
	}
	return "", last
}

func get(client *http.Client, url string) (string, error) {
	resp, err := client.Get(url) //nolint:gosec,noctx // a URL built from a pin this tool read
	if err != nil {
		return "", err
	}
	// read-only, and the body is drained below: a failed close loses nothing
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return "", errors.New(resp.Status)
	}
	// An action file is a few kilobytes. The cap is there so a redirect to
	// something enormous cannot become this tool's memory problem.
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return "", err
	}
	return string(body), nil
}
