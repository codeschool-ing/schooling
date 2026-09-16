package main

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

// THE COPY OF THE PALETTE IN `palette.go` IS ONLY SAFE BECAUSE OF THIS.
// It fails in both directions: a value edited in the stylesheet and not here,
// and a token added or removed on either side.
func TestThePaletteMatchesTheCSS(t *testing.T) {
	css, err := os.ReadFile("../../ui/assets/terminal.css")
	if err != nil {
		t.Fatalf("the stylesheet this palette is a copy of: %v", err)
	}
	block := func(selector string) map[string]string {
		m := regexp.MustCompile(regexp.QuoteMeta(selector) + `\{([^}]*)\}`).FindSubmatch(css)
		if m == nil {
			t.Fatalf("%s is not in terminal.css any more", selector)
		}
		out := map[string]string{}
		for _, d := range regexp.MustCompile(`--term-([a-z-]+):\s*(#[0-9a-f]{6})`).
			FindAllStringSubmatch(string(m[1]), -1) {
			out[d[1]] = d[2]
		}
		return out
	}
	root, light := block(":root"), block(`html[data-theme="light"]`)

	want := map[string]string{}
	for name, v := range term.dark {
		want[name] = v
	}
	for name, v := range term.bg {
		want[name+"-bg"] = v
	}
	same := func(what string, got, mine map[string]string) {
		for k, v := range got {
			if mine[k] != v {
				t.Errorf("%s: terminal.css says --term-%s is %s, this file says %s",
					what, k, v, mine[k])
			}
		}
		for k, v := range mine {
			if _, ok := got[k]; !ok {
				t.Errorf("%s: this file has --term-%s as %s and the stylesheet does not have it",
					what, k, v)
			}
		}
	}
	same(":root", root, want)
	same("the light theme", light, term.light)
}

// THE CLAIM THE WHOLE FILE IS FOR, over every pair it can be asked about:
// whatever comes back is readable, in both themes, against the ground it was
// asked about. A rule that answered "the colour you gave me" would pass every
// test above this one and fail this.
func TestEveryAnswerReadsInBothThemes(t *testing.T) {
	grounds := []string{""}
	for name := range term.bg {
		grounds = append(grounds, "var(--term-"+name+"-bg)")
	}
	grounds = append(grounds, "#6c6c6c", "#f5f5f5", "#bfbfbf") // vim's and emacs's own

	asked := []string{""}
	for name := range term.dark {
		asked = append(asked, "var(--term-"+name+")")
	}
	// Every direct colour any figure in this catalogue actually carries, and
	// the five that were below AA are all here.
	asked = append(asked, "#a0522d", "#b22222", "#0000cd", "#87ffaf", "#ffd7d7", "#00008b")

	for _, bg := range grounds {
		for _, fg := range asked {
			got := fill(fg, bg)
			for _, theme := range []string{"dark", "light"} {
				text, ground := inTheme(got, theme), inTheme(bg, theme)
				if ground == "" {
					if theme == "dark" {
						ground = panelDark
					} else {
						ground = panelLight
					}
				}
				if r := within(text, ground); r < aa {
					t.Errorf("%s on %s answered %s, which is %.2f:1 in the %s theme",
						or(fg, "the terminal's own colour"), or(bg, "the panel"), got, r, theme)
				}
			}
		}
	}
}

// A GROUND IS FIXED, SO THE TEXT ON IT HAS TO BE. A token there flips out from
// under a ground that does not, and that is the defect this file was written
// for — not a possibility it guards against.
func TestTextOnAGroundIsNeverAToken(t *testing.T) {
	for name := range term.bg {
		for fg := range term.dark {
			got := fill("var(--term-"+fg+")", "var(--term-"+name+"-bg)")
			if strings.HasPrefix(got, "var(") {
				t.Errorf("%s on the %s ground answered %s, which moves between themes while "+
					"the ground under it does not", fg, name, got)
			}
		}
	}
}

// AND THE PANEL IS TWO GROUNDS, so the text on it has to be a token: there is
// no single value that reads against #111721 and #ffffff, and a rule that
// returned one would be choosing a theme for the reader.
func TestTextOnThePanelIsAToken(t *testing.T) {
	for _, fg := range []string{"", "#87ffaf", "#ffd7d7", "#a0522d", "var(--term-green)"} {
		if got := fill(fg, ""); !strings.HasPrefix(got, "var(") {
			t.Errorf("%q on the panel answered %s, a fixed value — the panel is not fixed", fg, got)
		}
	}
}

// FIDELITY WHERE IT COSTS NOTHING. A colour that already reads is the colour
// the program chose, and this rule does not touch it.
func TestAColourThatReadsIsLeftAlone(t *testing.T) {
	// Black on white: 15.49:1, and nothing to improve.
	if got := fill("var(--term-black)", "var(--term-white-bg)"); got != term.dark["black"] {
		t.Errorf("black text on a white ground reads perfectly well; the rule returned %s", got)
	}
	// A token that reads against its own panel stays that token.
	if got := fill("var(--term-cyan)", ""); got != "var(--term-cyan)" {
		t.Errorf("cyan reads on both panels; the rule returned %s", got)
	}
}

// AND WHAT IT KEEPS WHEN IT HAS TO MOVE. Hue is the part a reader recognises
// across a theme change, so it is the part that survives.
func TestMovingAColourKeepsItsHue(t *testing.T) {
	// vim's pale green message, on the panel: still a green.
	if got := fill("#87ffaf", ""); got != "var(--term-green)" {
		t.Errorf("a pale green on the panel should become the green token, got %s", got)
	}
	// vim's pale pink message: still a red.
	if got := fill("#ffd7d7", ""); got != "var(--term-red)" {
		t.Errorf("a pale pink on the panel should become the red token, got %s", got)
	}
	// htop's green tab bracket on its own green ground: darkened, still green.
	got := fill("var(--term-green)", "var(--term-green-bg)")
	h, _, _ := toHSL(got)
	want, _, _ := toHSL(term.dark["green"])
	if away := h - want; away > 2 || away < -2 {
		t.Errorf("green on green should walk its lightness and keep its hue; %s is at %.0f "+
			"where green is at %.0f", got, h, want)
	}
}

// The value a token stands for in one theme, for the measurement above.
func inTheme(v, theme string) string {
	if strings.HasPrefix(v, "#") || v == "" {
		return v
	}
	if name := strings.TrimSuffix(strings.TrimPrefix(v, "var(--term-"), "-bg)"); strings.HasSuffix(v, "-bg)") {
		return term.bg[name]
	}
	if name, ok := tokenName(v); ok {
		if theme == "light" {
			return term.light[name]
		}
		return term.dark[name]
	}
	if v == "var(--paper)" {
		if theme == "light" {
			return "#20263c"
		}
		return "#e8e6df"
	}
	return v
}

func or(v, fallback string) string {
	if v == "" {
		return fallback
	}
	return v
}
