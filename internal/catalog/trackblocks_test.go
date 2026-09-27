package catalog_test

import (
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

// roles is the fixture's section with one group in it: a passage for the
// fixture's only track, and one for everybody else.
func roles(frontendLine, anyoneLine string) string {
	return "---\ntitle: The two roles\nversion: 1\n---\n\n" +
		"The **client** asks; the **server** answers.\n\n" +
		"::: track frontend\n" + frontendLine + "\n:::\n\n" +
		"::: track *\n" + anyoneLine + "\n:::\n"
}

const rolesDir = "courses/web-fundamentals/lessons/" + clientAndServer + "/"

func TestAPassageForATrackThatReachesTheCourseIsAccepted(t *testing.T) {
	loaded, problems := loadGood(t,
		write(rolesDir+"roles.md", roles("In a browser, the page is the client.", "Whatever asks is the client.")),
		write(rolesDir+"roles.pt.md", roles("No navegador, a página é o cliente.", "Quem pergunta é o cliente.")))
	if len(problems) > 0 {
		t.Fatalf("a well-formed group was refused:\n%s", report(t, problems))
	}

	// And past the loader it names the track by id, which is the only name the
	// interface has for the track a student is on.
	c := courseNamed(t, loaded, "web-fundamentals")
	for _, l := range c.Loaded {
		for _, p := range l.Text {
			if p.SectionID != rolesSection {
				continue
			}
			got := catalog.TrackBlocksWithIDs(p.Body, loaded.Tracks)
			if !strings.Contains(got, "::: track "+frontend+"\n") || strings.Contains(got, "::: track frontend") {
				t.Errorf("%s: the marker still names the slug:\n%s", p.Locale, got)
			}
		}
	}
}

// A typo in a slug reads perfectly and is never shown: every reader gets `*`.
func TestAPassageForATrackThatDoesNotExistIsRefused(t *testing.T) {
	problems := school(t,
		write(rolesDir+"roles.md", strings.Replace(roles("a", "b"), "track frontend", "track frontnd", 1)),
		write(rolesDir+"roles.pt.md", strings.Replace(roles("a", "b"), "track frontend", "track frontnd", 1)))
	if !says(problems, "roles.md: line", "`::: track frontnd` names a track this school does not have") {
		t.Errorf("a passage for no track was accepted:\n%s", report(t, problems))
	}
}

// The slug is real and nobody on that track can reach the section.
func TestAPassageForATrackThatDoesNotContainTheCourseIsRefused(t *testing.T) {
	problems := school(t,
		write("tracks/design.json", `{
  "id": "tr-5d3s1gnx",
  "slug": "design",
  "name": "Design",
  "goal": "Draw interfaces.",
  "outcome": "Junior Designer",
  "courses": ["angular"],
  "continues": null,
  "links": {}
}`),
		patchJSON("school.json", func(d map[string]any) {
			d["tracks"] = append(d["tracks"].([]any), "design")
		}),
		write(rolesDir+"roles.md", strings.Replace(roles("a", "b"), "track frontend", "track design", 1)),
		write(rolesDir+"roles.pt.md", strings.Replace(roles("a", "b"), "track frontend", "track design", 1)))
	if !says(problems, "`::: track design` is written for a track that does not contain web-fundamentals") {
		t.Errorf("a passage nobody can reach was accepted:\n%s", report(t, problems))
	}
}

// A reader in either language meets the passage for their track.
func TestATranslationThatVariesDifferentlyIsRefused(t *testing.T) {
	problems := school(t,
		write(rolesDir+"roles.md", roles("a", "b")),
		write(rolesDir+"roles.pt.md", "---\ntitle: Os dois papéis\nversion: 1\n---\n\nSem blocos.\n"))
	if !says(problems, "roles.pt.md varies by track as nothing and the text it translates as [frontend | *]") {
		t.Errorf("a translation with a different shape was accepted:\n%s", report(t, problems))
	}
}

// The grammar's own refusals arrive with the file they are in.
func TestAGroupWithNoPassageForEverybodyElseIsRefusedByFile(t *testing.T) {
	body := "---\ntitle: The two roles\nversion: 1\n---\n\n::: track frontend\nOnly for them.\n:::\n"
	problems := school(t, write(rolesDir+"roles.md", body), write(rolesDir+"roles.pt.md", body))
	if !says(problems, "web-fundamentals/"+clientAndServer+"/roles.md: line 6: this group has no `::: track *` block") {
		t.Errorf("a group with no fallback was accepted:\n%s", report(t, problems))
	}
}
