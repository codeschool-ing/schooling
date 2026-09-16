package main

import (
	"image/color"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/charmbracelet/x/ansi"
	"github.com/charmbracelet/x/vt"
)

// Most of what is tested here is the half that has no pseudo-terminal in it:
// the arithmetic, which is where the figure went wrong twice.
//
// IT USED TO SAY THAT THE OTHER HALF NEEDED NO TEST, because "its failures are
// visible in the figure rather than subtle". That was wrong in the one way that
// costs the most. `-send` did nothing at all — the wait after a keystroke could
// end before the program had read it — and what came out was not a broken
// picture but a PERFECTLY GOOD ONE of the wrong screen: the file vim opens on,
// under a caption saying the cursor had moved. Nothing in a figure says which
// keys were pressed to reach it.
//
// So there is one pty test now, below, and it uses `cat` rather than an editor:
// the claim is that a keystroke arrives before the screen is read, and the
// smallest program that can answer it is the one that echoes.

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

// A KEYBOARD IS NOT A GO STRING LITERAL. Escape leaves vim's insert mode and
// control characters are the whole of nano's and emacs's vocabulary, and Go's
// own unquoting has neither. Every key-taking flag goes through one decoder,
// because the first version decoded only `-send`: `-quit ':q!\r'` then sent a
// literal backslash and an r, vim sat holding an unfinished command line, and
// the capture hung until it was killed.
func TestKeystrokesDecodesWhatAKeyboardSends(t *testing.T) {
	for _, c := range []struct{ in, want string }{
		{`i`, "i"},
		{`\e`, "\x1b"},
		{`:q!\r`, ":q!\r"},
		{`^X`, "\x18"},
		{`^x`, "\x18"}, // the shift is not part of the control character
		{`^L`, "\x0c"}, // the repaint key
		{`^^`, "^"},    // and the way to type the caret itself
		{`\\n`, `\n`},  // an escaped backslash is not an escape
		{`G`, "G"},     // an ordinary key survives the decoder
	} {
		got, err := keystrokes(c.in)
		if err != nil {
			t.Errorf("keystrokes(%q): %v", c.in, err)
			continue
		}
		if got != c.want {
			t.Errorf("keystrokes(%q) = %q, want %q", c.in, got, c.want)
		}
	}

	for _, bad := range []string{`\q`, `^!`} {
		if _, err := keystrokes(bad); err == nil {
			t.Errorf("keystrokes(%q) should refuse: a key nobody can send is a "+
				"silent no-op in the middle of a capture", bad)
		}
	}
}

// REVERSE VIDEO IS A SWAP AND THE SVG HAS NO ATTRIBUTE FOR IT. nano draws its
// title bar, its message line and its two rows of shortcuts this way: neither
// colour is set, the two are exchanged. The first version named the defaults
// the wrong way round and painted a black bar on a dark panel — a bar nobody
// could see.
func TestReverseVideoBecomesALightBar(t *testing.T) {
	// `ESC [ 7 m` is what nano writes before its title bar. No colour is named:
	// the terminal is told to exchange the two it already has.
	term := vt.NewSafeEmulator(3, 1)
	if _, err := term.Write([]byte("\x1b[7mGNU")); err != nil {
		t.Fatal(err)
	}
	g := read(term, 3, 1)

	if g[0][0].fg != "black" || g[0][0].bg != "white" {
		t.Fatalf("reversed with no colours set should read dark on light, got fg=%q bg=%q",
			g[0][0].fg, g[0][0].bg)
	}

	svg := draw(g, 3, 1, "a screen", nil)
	if !strings.Contains(svg, "var(--term-white-bg)") {
		t.Errorf("the ground has to be the light token or the bar is invisible on a dark panel; got %s", svg)
	}
}

// ONE CAPTURE, DRAWN TWICE. The callouts are prose and belong in the reader's
// language; the screen behind them is a measurement and must not move between
// the two. Running the program once per language gives two screens — the same
// figure with different numbers in English and in Portuguese, which is worse
// than not translating at all.
//
// Getting it wrong the first time went the other way: one SVG written into both
// files, so a reader in Portuguese met four English callouts under a caption
// that was theirs.
func TestASavedScreenDrawsAgainUnchanged(t *testing.T) {
	g := grid{
		append(text("PID", "black", "green"), text(" ana", "", "")...),
		text("2396", "", ""),
	}

	path := filepath.Join(t.TempDir(), "screen.json")
	if err := store(path, g); err != nil {
		t.Fatal(err)
	}
	back, err := load(path)
	if err != nil {
		t.Fatal(err)
	}

	mono := regexp.MustCompile(`(?s)<g font-family[^>]*>.*?</g>`)
	first := mono.FindString(draw(g, 7, 2, "a screen", calloutList{{row: 0, text: "one bar per processor"}}))
	again := mono.FindString(draw(back, 7, 2, "uma tela", calloutList{{row: 0, text: "uma barra por processador"}}))

	if first == "" || first != again {
		t.Errorf("the screen has to survive the round trip byte for byte, or the two languages "+
			"carry different numbers under the same figure:\n first: %s\n again: %s", first, again)
	}
}

// TEXT ON A GROUND CANNOT BORROW A COLOUR THAT MOVES.
//
// `--paper` is light in the dark theme and dark in the light one; a captured
// background is a fixed value in both. A ground that reads against both a light
// and a dark foreground does not exist, so text left on `var(--paper)` over a
// background is unreadable in one theme by construction — 2.85:1 in the light
// theme over vim's visual selection, which is how this was found.
func TestTextOnAGroundDoesNotTakeAColourThatMoves(t *testing.T) {
	for _, c := range []struct{ ground, want string }{
		{"#f5f5f5", "var(--term-black)"}, // emacs' menu bar
		{"#6c6c6c", "var(--term-white)"}, // vim's visual selection
		{"#bfbfbf", "var(--term-black)"}, // emacs' mode line
		{"#000000", "var(--term-white)"},
		{"#ffffff", "var(--term-black)"},
		// A token's value lives in `terminal.css` and not here — see `over`.
		{"var(--term-green-bg)", "var(--paper)"},
		{"", "var(--paper)"},
		{"#zzz", "var(--paper)"}, // not a colour; not this function's to guess
	} {
		if got := over(c.ground); got != c.want {
			t.Errorf("text on %q should be %s, got %s", c.ground, c.want, got)
		}
	}
}

// And the whole of it, through `draw`: a run with a background and no colour of
// its own comes out with a fixed fill rather than the one that moves.
func TestARunWithAGroundIsDrawnWithAFixedFill(t *testing.T) {
	svg := draw(grid{text("ab", "", "#6c6c6c")}, 2, 1, "a screen", nil)
	if !strings.Contains(svg, `fill="var(--term-white)"`) {
		t.Errorf("a run on a dark ground is drawn in white and stays white in both themes; got %s", svg)
	}
	if strings.Contains(svg, `<tspan fill="var(--paper)"`) {
		t.Error("`--paper` moves between themes and the ground under it does not")
	}
	// And a run with no ground at all is still the terminal's own foreground.
	plain := draw(grid{text("ab", "", "")}, 2, 1, "a screen", nil)
	if !strings.Contains(plain, `fill="var(--paper)"`) {
		t.Errorf("text on the panel is the panel's foreground, which follows the theme; got %s", plain)
	}
}

// A KEYSTROKE HAS TO ARRIVE BEFORE THE SCREEN IS READ, and for a while none
// did.
//
// `settle` waits for the program to stop writing for `quiet`. A program that
// has sat still through the warmup is already quieter than that, so the wait
// after a `-send` returned on its first comparison — before the bytes had
// crossed the line discipline, let alone been drawn. Every capture came back as
// the screen the program opened on.
//
// It is checked with `cat`, which answers a keystroke the way a terminal makes
// it answer: the line discipline echoes what was typed, and then the program
// prints it. Two lines, and a screen with neither is a screen read too early.
func TestAKeystrokeArrivesBeforeTheScreenIsRead(t *testing.T) {
	screen, err := capture(
		[]string{"cat"}, 40, 6,
		300*time.Millisecond, // warmup: long enough for `cat` to be waiting
		200*time.Millisecond, // quiet
		[]string{"hello\r"},  // -send
		"",                   // -repaint: `cat` has no redraw to ask for
		"\x04",               // -quit: end of file
	)
	if err != nil {
		t.Fatalf("capturing `cat`: %v", err)
	}

	var lines []string
	for _, r := range screen {
		var b strings.Builder
		for _, c := range r {
			b.WriteString(c.text)
		}
		if s := strings.TrimRight(b.String(), " "); s != "" {
			lines = append(lines, s)
		}
	}

	if len(lines) != 2 || lines[0] != "hello" || lines[1] != "hello" {
		t.Errorf("`cat` sent `hello` echoes it and then prints it, so the screen is two "+
			"identical lines; it reads %q. An empty screen is the failure this test exists "+
			"for: the keystroke was written and the screen was read without waiting for "+
			"anything to happen to it.", lines)
	}
}
