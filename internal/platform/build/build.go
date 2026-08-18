// Package build carries what this binary is, and is set at link time.
//
// THE TAG IS THE ONLY PLACE A VERSION IS WRITTEN. Not a file in the repository,
// not a constant here — the git tag, stamped into the binary by the release
// workflow. The predecessor kept the number in a file because GitHub Pages
// served the branch as it was and there was no build to stamp anything during;
// that constraint does not exist here, and without it a file would only be a
// second copy of a number. This project has already paid for a second copy of a
// version: three places named a Go version, two agreed, and CI failed with a
// message about none of them.
//
// So there is nothing to keep in sync, which is the point. What the release
// workflow checks is not a file against the tag — it is the tag against semantic
// versioning, against the history of main, and against the last release.
package build

import "runtime/debug"

// Set with -ldflags -X. Unstamped they say so, rather than claiming something
// nobody released: a wrong version answers with confidence, which is worse than
// answering nothing.
var (
	// Version is the release tag, or "dev" for every build that is not one.
	Version = "dev"

	// Commit is the revision built. It is what "dev" is missing — the question
	// during an incident is which code is running, and a tag only answers it on
	// the days there is one.
	Commit = ""

	// Built is when, in RFC 3339. A revision alone does not distinguish a
	// rebuild of the same commit against a different base image.
	Built = ""
)

// Info is what the binary reports about itself.
type Info struct {
	Version  string `json:"version"`
	Commit   string `json:"commit"`
	Built    string `json:"built,omitempty"`
	Released bool   `json:"released"`
}

// Current answers this binary's identity.
//
// The commit falls back to what the Go toolchain embeds by itself, so a build
// nobody stamped — `go run` on a laptop, a container built by hand — still says
// which revision it came from instead of nothing at all.
func Current() Info {
	commit := Commit
	if commit == "" {
		commit = vcsRevision()
	}
	return Info{
		Version:  Version,
		Commit:   commit,
		Built:    Built,
		Released: Version != "dev",
	}
}

func vcsRevision() string {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return ""
	}
	for _, s := range info.Settings {
		if s.Key == "vcs.revision" {
			return s.Value
		}
	}
	return ""
}
