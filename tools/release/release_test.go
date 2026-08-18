package main

import "testing"

// The shape, and the reason there is only one of it.
func TestOnlyOneShapeOfTagIsARelease(t *testing.T) {
	good := []string{"v0.0.1", "v0.1.0", "v1.0.0", "v1.2.3", "v10.20.30"}
	for _, tag := range good {
		if _, err := parse(tag); err != nil {
			t.Errorf("%s should be a release tag: %v", tag, err)
		}
	}

	bad := map[string]string{
		"1.2.3":        "no v",
		"v1.2":         "two components",
		"v1.2.3.4":     "four components",
		"v1.2.3-rc.1":  "a pre-release, which this repository does not have",
		"v1.2.3+build": "build metadata, same reason",
		"v01.2.3":      "a leading zero — two tags for one release, one of them uncheckoutable",
		"v1.2.3 ":      "trailing space",
		"release-1":    "not a version at all",
		"":             "nothing",
	}
	for tag, why := range bad {
		if _, err := parse(tag); err == nil {
			t.Errorf("%q was accepted as a release tag (%s)", tag, why)
		}
	}
}

// THE ONE THAT MATTERS. A version that goes backwards is not a failed release —
// it is a release that succeeds and then sorts wrongly for as long as the
// repository exists.
func TestAVersionThatDoesNotIncreaseIsRefused(t *testing.T) {
	existing := []string{"v0.1.0", "v0.2.0", "v1.0.0", "v1.9.0", "v1.10.0"}

	refused := []string{
		"v1.10.0", // the same as the highest
		"v1.9.1",  // ahead of one that exists, behind the highest
		"v1.2.0",  // the classic: v1.10.0 typed as v1.1.0's neighbour
		"v0.9.0",
	}
	for _, tag := range refused {
		if err := check(tag, existing); err == nil {
			t.Errorf("%s was accepted, and v1.10.0 already exists", tag)
		}
	}

	accepted := []string{"v1.10.1", "v1.11.0", "v2.0.0"}
	for _, tag := range accepted {
		if err := check(tag, existing); err != nil {
			t.Errorf("%s should be accepted after v1.10.0: %v", tag, err)
		}
	}
}

// Ten is after nine. Comparing tags as text is the bug this whole check exists
// to catch, so it is worth pinning directly.
func TestVersionsCompareAsNumbersAndNotAsText(t *testing.T) {
	ten, nine := version{1, 10, 0}, version{1, 9, 0}
	if !ten.after(nine) {
		t.Error("v1.10.0 should come after v1.9.0 — compared as text it does not")
	}
	if nine.after(ten) {
		t.Error("v1.9.0 came after v1.10.0")
	}
	if ten.after(ten) {
		t.Error("a version came after itself, so re-tagging the same number would be allowed")
	}
}

// The first release has nothing to be ahead of, and must not be refused for it.
func TestTheFirstReleaseIsAllowed(t *testing.T) {
	for _, existing := range [][]string{nil, {}, {"v-not-a-version"}, {"nightly"}} {
		if err := check("v0.1.0", existing); err != nil {
			t.Errorf("the first release was refused with existing tags %v: %v", existing, err)
		}
	}
}

// A repository collects tags for other reasons. Refusing a release because
// somebody once tagged `nightly` would make this tool the reason a release
// cannot happen, which is worse than the mistake it is looking for.
func TestTagsThatAreNotReleasesAreIgnored(t *testing.T) {
	if err := check("v1.0.0", []string{"v0.9.0", "vendor-sync", "v2-experiment", "v1.0.0-rc.1"}); err != nil {
		t.Errorf("a valid release was refused because of unrelated tags: %v", err)
	}
}
