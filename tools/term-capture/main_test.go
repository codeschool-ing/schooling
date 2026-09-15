package main

import (
	"image/color"
	"regexp"
	"strconv"
	"strings"
	"testing"

	"github.com/charmbracelet/x/ansi"
)

// What is tested here is the half that has no pseudo-terminal in it. The other
// half — a program started, warmed up, asked to repaint and read while it is
// still running — needs a real `htop` and four seconds, and its failures are
// visible in the figure rather than subtle. This is the arithmetic, which is
// where the figure went wrong twice.

func row(cells ...cell) []cell { return cells }

func text(s string, fg, bg string) []cell {
	out := make([]cell, 0, len(s))
	for _, r := range s {
		out = append(out, cell{text: string(r), fg: fg, bg: bg})
	}
	return out
}

func TestRunsMergeByStyleAndRememberTheirColumn(t *testing.T) {
	line := append(text("PID", "black", "green"), text(" ana", "", "")...)
	got := runs(line)

	if len(got) != 2 {
		t.Fatalf("two styles make two runs, got %d: %+v", len(got), got)
	}
	if got[0].text != "PID" || got[0].fg != "black" || got[0].bg != "green" || got[0].start != 0 {
		t.Errorf("first run should be PID, black on green, at column 0; got %+v", got[0])
	}
	if got[1].text != " ana" || got[1].bg != "" || got[1].start != 3 {
		t.Errorf("second run should be \" ana\", unstyled, at column 3; got %+v", got[1])
	}
}

func TestBoldSplitsARunEvenWhenTheColoursMatch(t *testing.T) {
	line := row(
		cell{text: "1", fg: "green"},
		cell{text: "2", fg: "green", bold: true},
	)
	if got := runs(line); len(got) != 2 {
		t.Errorf("bold is a style, so it starts a new run; got %d runs: %+v", len(got), got)
	}
}

var tspanOf = regexp.MustCompile(`<tspan[^>]*textLength="([0-9.]+)"[^>]*>([^<]*)</tspan>`)

// THE FIGURE IS A GRID AND THE FONT IS NOT TRUSTED TO KEEP IT. `ui/assets/fonts`
// ships weight 400 of the mono only, so a bold run is synthesised by the browser
// and comes out wider than its cells; the first version of this drew htop's
// function-key bar as "F4ilter" and "F9ill", each run's first letter buried
// under the one before it. Every run carries the width its cells are worth.
func TestEveryRunIsPinnedToTheGrid(t *testing.T) {
	g := grid{
		append(text("ab", "green", ""), text("cde", "", "")...),
	}
	svg := draw(g, 5, 1, "a screen", nil)

	found := tspanOf.FindAllStringSubmatch(svg, -1)
	if len(found) != 2 {
		t.Fatalf("two runs make two tspans, got %d in %s", len(found), svg)
	}
	for _, m := range found {
		want := float64(len([]rune(m[2]))) * charWidth
		got, err := strconv.ParseFloat(m[1], 64)
		if err != nil {
			t.Fatalf("textLength %q does not parse: %v", m[1], err)
		}
		if got != want {
			t.Errorf("run %q should be %v wide, its tspan says %v", m[2], want, got)
		}
	}
	if !strings.Contains(svg, `lengthAdjust="spacingAndGlyphs"`) {
		t.Error("closing the gaps is not enough when the glyphs themselves are too wide")
	}
}

// `tools/figure-fit` measures a label against the box drawn around it, and it
// reads coordinates as they are written: a group transform is not applied, so
// text under one looks like it starts to the left of its own box. That is how
// the first version failed, 36 times in one figure.
func TestTextIsPlacedWithoutAGroupTransform(t *testing.T) {
	svg := draw(grid{text("ab", "", "")}, 2, 1, "a screen", nil)
	if strings.Contains(svg, "transform=") {
		t.Error("figure-fit does not apply transforms, so the coordinates have to be absolute")
	}
	if !strings.Contains(svg, `<text x="40.00"`) {
		t.Errorf("text should start at the gutter plus the padding, 40; got %s", svg)
	}
}

func TestTrailingBlankRowsAreNotContent(t *testing.T) {
	g := grid{text("x", "", ""), text(" ", "", ""), text(" ", "", "")}
	tall := draw(g, 1, 3, "a screen", nil)
	short := draw(grid{text("x", "", "")}, 1, 1, "a screen", nil)

	height := regexp.MustCompile(`viewBox="0 0 [0-9.]+ ([0-9.]+)"`)
	if height.FindStringSubmatch(tall)[1] != height.FindStringSubmatch(short)[1] {
		t.Error("a screen filled to one row should not draw a box three rows tall")
	}
}

// A row that looks empty but carries a background is a drawn thing — htop's
// function-key bar is exactly that, spaces on a coloured ground.
func TestABlankRowWithABackgroundIsKept(t *testing.T) {
	g := grid{text("x", "", ""), text("  ", "", "cyan")}
	svg := draw(g, 2, 2, "a screen", nil)
	if !strings.Contains(svg, "var(--term-cyan-bg)") {
		t.Errorf("a coloured ground is content even with no letters on it; got %s", svg)
	}
}

func TestTheEightAreTokensAndTheRestKeepTheirOwnValue(t *testing.T) {
	if got := token(nil); got != "" {
		t.Errorf("no colour is the terminal's default, not a value; got %q", got)
	}
	if got := token(ansi.BasicColor(2)); got != "green" {
		t.Errorf("basic colour 2 is green; got %q", got)
	}
	if got := token(ansi.BasicColor(10)); got != "green" {
		t.Errorf("the bright half names the same eight; got %q", got)
	}
	// A program that reached past the eight chose that colour itself.
	if got := token(color.RGBA{R: 0x8a, G: 0x6a, B: 0x0a, A: 0xff}); got != "#8a6a0a" {
		t.Errorf("a direct colour is not ours to reinterpret; got %q", got)
	}
}

func TestBackgroundAndForegroundAreDifferentTokens(t *testing.T) {
	// htop's header is black on green. If both sides resolved to the same token
	// the light theme would put dark text on a dark ground, which is what the
	// first palette did.
	if colour("green", "", true) == colour("green", "", false) {
		t.Error("a background holds its contrast against the text on it, a foreground against the panel")
	}
}

func TestACalloutNeedsARowAndText(t *testing.T) {
	var l calloutList
	if err := l.Set("9:the sorted column"); err != nil {
		t.Fatalf("a well-formed callout was refused: %v", err)
	}
	if l[0].row != 9 || l[0].text != "the sorted column" {
		t.Errorf("callout parsed as %+v", l[0])
	}
	if err := l.Set("no colon here"); err == nil {
		t.Error("a callout with no row is a silently misplaced number")
	}
	if err := l.Set("nine:the sorted column"); err == nil {
		t.Error("a callout whose row is not a number is the same failure")
	}
}
