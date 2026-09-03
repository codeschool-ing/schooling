package catalog_test

import (
	"strings"
	"testing"
)

/*
THE FRONT MATTER SAYS NO, WHICH IS THE HALF IT WAS MISSING.

	It read `title` and ignored every other key in silence. A `version:` written
	before the parser learned the word would have parsed, been dropped, and
	looked exactly like it had worked — and nothing anywhere would have said so.

	That is the failure this repository keeps meeting from a different side: not
	a wrong answer, but a confident one nobody can disprove. A closed list is
	only closed if it refuses, so these are the two tests that make the list
	real.
*/
func TestTheFrontMatterRefusesAKeyItDoesNotKnow(t *testing.T) {
	problems := school(t, write(
		"courses/web-fundamentals/lessons/"+clientAndServer+"/roles.md",
		"---\ntitle: The two roles\nversion: 1\nauthor: somebody\n---\n\nText.\n"))

	if !says(problems, "author", "only `title` and `version`") {
		t.Errorf("an unknown front-matter key was accepted:\n%s", report(t, problems))
	}
}

func TestTheFrontMatterReadsTheVersion(t *testing.T) {
	loaded, problems := loadGood(t)
	if len(problems) > 0 {
		t.Fatalf("the fixture does not load:\n%s", report(t, problems))
	}

	found := false
	for _, c := range loaded.Courses {
		for _, l := range c.Loaded {
			for _, p := range l.Text {
				found = true
				if p.Version < 1 {
					t.Errorf("%s/%s (%s) came back with version %d",
						c.Slug, p.SectionID, p.Locale, p.Version)
				}
			}
		}
	}
	if !found {
		t.Fatal("no prose was read at all, so this test checked nothing")
	}
}

// A VERSION THAT IS NOT A NUMBER IS NOT A VERSION, and silence here would put
// a zero on the row and let the comparison read it as "no version" for ever.
func TestAProseVersionHasToBeAWholeNumber(t *testing.T) {
	problems := school(t, write(
		"courses/web-fundamentals/lessons/"+clientAndServer+"/roles.md",
		"---\ntitle: The two roles\nversion: soon\n---\n\nText.\n"))

	if !says(problems, "not a whole number") {
		t.Errorf("a version of \"soon\" was accepted:\n%s", report(t, problems))
	}
}

// AND A FILE WITH NO VERSION AT ALL. C-25 compares two generations of a text by
// what a reading event recorded; the first generation of every section would
// have no baseline, which is the comparison the version exists for, lost
// exactly where material changes most.
func TestProseWithoutAVersionIsRefused(t *testing.T) {
	problems := school(t, write(
		"courses/web-fundamentals/lessons/"+clientAndServer+"/roles.md",
		"---\ntitle: The two roles\n---\n\nText.\n"))

	if !says(problems, "has no version in its front matter") {
		t.Errorf("prose with no version was accepted:\n%s", report(t, problems))
	}
}

/*
AND WHAT MAKES A VIDEO ONE.

	`Video bool` could say a rendering was there and nothing about which one,
	while an event records the version watched and an object key carries it
	(C-18). These four are what the boolean had no room for, and each is a
	silent failure rather than a loud one: a missing script is a transcript
	nobody can show, a repeated id is two files at one address with the second
	upload winning, and a locale the school does not offer is a selector naming
	what it cannot play.
*/
func withVideos(t *testing.T, videos ...map[string]any) []error {
	t.Helper()
	return school(t, patchJSON(
		"courses/web-fundamentals/lessons/"+clientAndServer+"/lesson.json",
		func(lesson map[string]any) {
			sections, _ := lesson["sections"].([]any)
			for _, raw := range sections {
				section, _ := raw.(map[string]any)
				if section["kind"] == "video" {
					out := make([]any, 0, len(videos))
					for _, v := range videos {
						out = append(out, v)
					}
					section["videos"] = out
					return
				}
			}
			t.Fatal("the fixture has no video section to patch")
		}))
}

func good(over ...func(map[string]any)) map[string]any {
	v := map[string]any{
		"id": "vd-7k2m9x4p", "version": 1,
		"script":  "Two roles, and everything else is detail.",
		"seconds": 480.0, "locales": []any{"en"},
	}
	for _, f := range over {
		f(v)
	}
	return v
}

func TestAVideoWithoutAScriptIsRefused(t *testing.T) {
	problems := withVideos(t, good(func(v map[string]any) { v["script"] = "   " }))
	if !says(problems, "has no script") {
		t.Errorf("a video with no script was accepted:\n%s", report(t, problems))
	}
}

func TestAVideoWithoutAVersionIsRefused(t *testing.T) {
	problems := withVideos(t, good(func(v map[string]any) { delete(v, "version") }))
	if !says(problems, "has no version") {
		t.Errorf("a video with no version was accepted:\n%s", report(t, problems))
	}
}

func TestTwoVideosMayNotShareAnID(t *testing.T) {
	problems := withVideos(t, good(), good(func(v map[string]any) {
		v["script"] = "A different recording, answering to the same address."
	}))
	if !says(problems, "repeats the video id", "one object key") {
		t.Errorf("two videos shared an id:\n%s", report(t, problems))
	}
}

func TestAVideoMayNotClaimALanguageTheSchoolDoesNotOffer(t *testing.T) {
	problems := withVideos(t, good(func(v map[string]any) {
		v["locales"] = []any{"en", "eo"}
	}))
	if !says(problems, "eo", "this school does not offer") {
		t.Errorf("a video claimed a language the school has no dictionary for:\n%s",
			report(t, problems))
	}
}

// AND THE SHAPE THE FIXTURE ACTUALLY CARRIES IS ACCEPTED, because a rule that
// refuses everything passes every test above and is useless.
func TestTheFixtureVideoIsAccepted(t *testing.T) {
	if problems := withVideos(t, good()); len(problems) > 0 {
		t.Errorf("a well-formed video was refused:\n%s", report(t, problems))
	}
}

// A LOCALE LIST MAY BE EMPTY AND THAT IS ORDINARY (C-19). Languages arrive
// unevenly, one correction at a time, and refusing a video that has not been
// narrated yet would mean no video could be written before all five existed.
func TestAVideoWithNoLanguagesYetIsFine(t *testing.T) {
	problems := withVideos(t, good(func(v map[string]any) { v["locales"] = []any{} }))
	for _, p := range problems {
		if strings.Contains(p.Error(), "locale") {
			t.Errorf("an empty locale list was treated as an error: %v", p)
		}
	}
}
