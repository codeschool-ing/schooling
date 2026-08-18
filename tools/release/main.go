// Command release decides whether a tag may become a release.
//
// It runs in the release workflow, before anything is built, and it exists
// because a release is the one action in this repository that cannot be undone
// quietly. A tag can be deleted, but not from the machine of somebody who
// already fetched it, and not from a deployment that already went out with the
// number stamped in it.
//
// THREE REFUSALS, and each is a mistake that has a cost:
//
//  1. A tag that is not `vMAJOR.MINOR.PATCH`. There is no pre-release form on
//     purpose — `dev` is already every build that is not a release, so `v1.2.0-rc.1`
//     would be a third state meaning the same as one of the two that exist, and
//     it would drag full semantic-version precedence in behind it.
//
//  2. A tag that does not increase. `v1.10.0` typed as `v1.1.0` sorts backwards
//     for the rest of the repository's life, and the next release after it is
//     either a lie or a gap.
//
//  3. A tag on a commit that is not on main. A release nobody merged cannot be
//     reproduced from main, and the checks that gate main never ran on it.
//
// Usage: release <tag>, from inside the repository, with the tags fetched.
package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: release <tag>")
		os.Exit(2)
	}
	tag := os.Args[1]

	existing, err := otherTags(tag)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if err := check(tag, existing); err != nil {
		fmt.Fprintf(os.Stderr, "%s is not a release this repository will make:\n  %v\n", tag, err)
		os.Exit(1)
	}

	if err := onMain(tag); err != nil {
		fmt.Fprintf(os.Stderr, "%s is not a release this repository will make:\n  %v\n", tag, err)
		os.Exit(1)
	}

	fmt.Printf("%s is a release: it is well formed, it is ahead of every tag before it, "+
		"and its commit is on main\n", tag)
}

/* ---------- the part with the decisions in it ---------- */

var wellFormed = regexp.MustCompile(`^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`)

type version [3]int

// parse reads a tag, and refuses anything that is not exactly the one shape.
//
// Leading zeroes are refused by the pattern rather than accepted and
// normalised: `v1.02.0` and `v1.2.0` would otherwise be two tags naming one
// release, and only one of them can be checked out by a person who read it in a
// changelog.
func parse(tag string) (version, error) {
	m := wellFormed.FindStringSubmatch(tag)
	if m == nil {
		return version{}, fmt.Errorf("a release tag is vMAJOR.MINOR.PATCH — %q is not, "+
			"and there is no pre-release form: every build that is not a release is `dev`", tag)
	}
	var v version
	for i := range v {
		// The pattern already proved these are digits, so this cannot fail.
		v[i], _ = strconv.Atoi(m[i+1])
	}
	return v, nil
}

func (v version) String() string { return fmt.Sprintf("v%d.%d.%d", v[0], v[1], v[2]) }

// after answers whether v comes strictly after w.
func (v version) after(w version) bool {
	for i := range v {
		if v[i] != w[i] {
			return v[i] > w[i]
		}
	}
	return false
}

// check holds the two rules that need no repository to decide: the shape, and
// that the tag is ahead of every release before it.
//
// EXISTING IS THE OTHER RELEASES, not including this one. The caller does that
// filtering, because the tag being pushed is in git's list too and a rule that
// quietly skipped anything matching by name would also skip the case it exists
// to catch — a version number being used a second time.
//
// Anything in existing that is not a release tag is ignored rather than
// refused. A repository collects tags for other reasons, and none of them are
// this tool's business.
func check(tag string, existing []string) error {
	v, err := parse(tag)
	if err != nil {
		return err
	}

	var highest version
	var found bool
	for _, e := range existing {
		w, err := parse(e)
		if err != nil {
			continue
		}
		if !found || w.after(highest) {
			highest, found = w, true
		}
	}

	if found && !v.after(highest) {
		return fmt.Errorf("%s does not come after %s, the highest release so far — "+
			"a version that goes backwards sorts wrongly for as long as the repository exists",
			v, highest)
	}
	return nil
}

/* ---------- the part that asks git ---------- */

// otherTags lists every tag except the one being released.
//
// The exclusion is here and not in the rule, and it is by name, which is all
// git offers: a tag deleted and recreated on another commit looks identical to
// the one being pushed. That case is caught a step later, when the release
// itself already exists and `gh release create` refuses — not by this.
func otherTags(releasing string) ([]string, error) {
	out, err := run("git", "tag", "--list", "v*")
	if err != nil {
		return nil, fmt.Errorf("listing the tags: %w", err)
	}

	all := strings.Fields(out)
	others := make([]string, 0, len(all))
	for _, t := range all {
		if t != releasing {
			others = append(others, t)
		}
	}
	return others, nil
}

// onMain answers whether the tagged commit is on main.
//
// `origin/main` rather than `main`, because a workflow checking out a tag has
// no local main branch — and a local one could be behind whatever the release
// is being cut from.
func onMain(tag string) error {
	if _, err := run("git", "merge-base", "--is-ancestor", tag+"^{commit}", "origin/main"); err != nil {
		var exit *exec.ExitError
		if errors.As(err, &exit) {
			return fmt.Errorf("the commit %s points at is not on main — a release that was never "+
				"merged cannot be reproduced from main, and the checks that gate main never ran on it", tag)
		}
		return fmt.Errorf("asking git whether %s is on main: %w", tag, err)
	}
	return nil
}

func run(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	return string(out), err
}
