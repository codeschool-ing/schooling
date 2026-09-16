// Command term-capture photographs a full-screen terminal program and writes
// the result as an SVG figure, in the shape `schooling-figure` already takes.
//
// # WHY IT EXISTS
//
// Everything else in the courses is a transcript: a command was run, its output
// was pasted into a fence, and a reader can run the same command and compare.
// Full-screen programs break that. `htop` paints a terminal rather than
// printing lines — there is no output to redirect and nothing to paste — so
// lesson 6's htop figure was DRAWN, with invented PIDs and an invented nginx
// worker at 78.4%, and its own caption said so in amber.
//
// It was the only fabricated figure in the catalogue. This is how it stops
// being one.
//
// # WHAT IT DOES
//
// A pseudo-terminal, a terminal emulator, and an SVG writer:
//
//	pty    the program needs a terminal, so it gets one, at a fixed size
//	vt     resolves cursor moves, erases and repeats into a final screen
//	svg    one <rect> per coloured background, one <tspan> per colour run
//
// Three details are the whole difficulty, and each was found by getting it
// wrong first.
//
// THE SNAPSHOT IS TAKEN WHILE THE PROGRAM IS STILL RUNNING. A full-screen
// program leaves the alternate screen buffer on its way out — `ESC [ ? 1049 l`
// — and a correct emulator honours that by restoring the primary screen, which
// is blank. Feed it the whole session and you get an empty picture. So the
// screen is read before the quit key is sent, and the teardown is discarded.
//
// IT WARMS UP FIRST. htop's opening frame has no previous sample to subtract,
// so its meters read 0.0% and its CPU% column reads N/A. Several refresh
// periods have to pass before the numbers mean anything.
//
// IT ASKS FOR A FULL REPAINT AND WAITS FOR SILENCE. A full-screen program
// redraws only the cells that changed, and reading in the middle of a partial
// update interleaves two frames — columns land inside each other and the text
// is nonsense. Ctrl-L asks for the whole screen again; the read then waits for
// the program to stop writing.
//
// # USAGE
//
//	go run ./tools/term-capture -out figure.svg -- htop -u ana
//
// The SVG goes to -out and the JSON for the `schooling-figure` fence goes to
// stdout, ready to paste. Callouts are numbered in the order given:
//
//	-callout '1:one bar per processor, and this machine has four'
//
// A screen that is not the one the program opens on is reached by typing:
//
//	-send G            -- vim server.conf      # the ruler now reads 6,1
//	-send i            -- vim server.conf      # -- INSERT --
//	-quit '\e:q!\r'    -- vim …                # how this one is left
//	-quit '^X'         -- nano …               # and how that one is
//
// `\e` is Escape and `^X` is a control character, because neither is something
// a shell hands over on its own. Every key-taking flag reads the same two.
//
// `-repaint` is the key that asks for the whole screen again, Ctrl-L by
// default. It is a flag because the key is not universal: vim and nano redraw,
// emacs RECENTRES, and a program that paints its whole screen at once — vim on
// a small file — wants `-repaint ”` so the keystroke does not appear in
// the picture.
//
// # WHAT IT DOES NOT DO
//
// It does not make the capture true. The machine has to be worth capturing —
// the load staged the way the section stages it, the process list filtered to
// something a reader should see. `-u ana` is not decoration. Photographing the
// wrong machine faster than drawing it is not an improvement.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"html"
	"image/color"
	"io"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	uv "github.com/charmbracelet/ultraviolet"
	"github.com/charmbracelet/x/ansi"
	"github.com/charmbracelet/x/vt"
	"golang.org/x/sys/unix"
)

// The figure's geometry. The advance is IBM Plex Mono's, MEASURED in a browser
// with the repository's own font file rather than taken from the 0.6 em a
// monospace face is assumed to have: it is 7.0 at 12px, which is 0.5833.
//
// It has to be exact because the background rectangles are placed by arithmetic
// while the text is placed by the font, and a wrong advance slides them apart.
// Every run also carries a `textLength`, which pins it to the grid even when
// the face is not the one this constant describes — and it is not, for bold:
// `ui/assets/fonts` ships weight 400 of the mono only, so a bold run is
// SYNTHESISED by the browser and comes out wider. `tools/figure-fit` found that
// as a label 753 wide in a box of 748.
//
// The adjustment is `spacingAndGlyphs` rather than `spacing` for the same
// reason. Spacing alone only closes the gaps BETWEEN glyphs, and a synthesised
// bold run is wider than the gaps can give back — htop's function-key bar came
// out as "F4ilter" and "F9ill", each run's first letter buried under the one
// before it.
//
// # AND `textLength` IS NOT HONOURED EVERYWHERE, WHICH LEAVES THE FIGURE 3% WIDE
//
// On the browser this was reported from, the compression does not happen: the
// ground under a row ends where the arithmetic put it and the text runs past
// it, which is what a row drawn at its natural width looks like. Whether that
// is `lengthAdjust` on a `<tspan>` going unimplemented or something narrower
// was not established — only that the bridge is not there. Reported from
// a real reader's screen: the red ground under vim's `E37` stops half way
// through the last letter of `override`, and emacs's `C-h C-a` chip leaves its
// `-a` on the panel behind it, where that dark blue is invisible.
//
// MEASURED, on the same font file, for one 51-cell row:
//
//	Chromium, IBM Plex Mono applied     7.0000 per cell   (this constant)
//	Chromium, the system monospace      7.2247 per cell
//	Firefox on the live page            7.1900 per cell
//
// and `letter-spacing: normal`, `word-spacing: 0px`, the font loaded. Two
// browsers disagree by 2.7% about the same file, which is its own puzzle and
// not one this comment settles. The effect is 11.5px over that row, which is
// the one and a half characters the reader sees.
//
// THE FIX, TESTED AND NOT TAKEN: give every character its own `x`, the way a
// terminal emulator does, instead of writing the row and asking the browser to
// squeeze it. Simulated by forcing the wider face in Chromium, the closing
// bracket of that row lands at 390 and ends at 397.23 against a ground that
// ends at 397 — against 401.22 to 408.47 as it is drawn today.
//
// It costs almost nothing in bytes, which was the objection worth checking:
// 81% of the grid is trailing padding that carries no glyph, so listing the
// positions up to the last letter adds about 68 KB across the catalogue while
// dropping that padding removes about 61 KB of it.
//
// It was left undone deliberately: 54 figures in 20 files would be redrawn, and
// this half of the change cannot be verified in the browser that needs it —
// only Chromium is installed where the tools run.
const (
	fontSize   = 12.0
	charWidth  = fontSize * 7.0 / 12.0
	lineHeight = 15.5
	padding    = 14.0
	gutter     = 26.0 // the left margin the callout numbers sit in

	// The same as `tools/bundle` and `tools/fonts` write with: the file is the
	// author's own, on the author's own machine, on the way into a commit.
	fileMode = 0o600

	// A terminal is addressed in 16-bit fields, and the flags are somebody
	// typing. Past this the conversion below wraps instead of failing.
	maxDimension = 1000
)

// The eight ANSI colours are tokens rather than values, so a figure follows the
// reader's theme. There are two sets and that is not redundancy: htop's header
// is black on green, so a background has to keep its contrast against the text
// painted ON it, while a foreground keeps its contrast against the panel BEHIND
// it. Only the foregrounds change between themes; `ui/assets/terminal.css` has
// both.
var ansiToken = [...]string{
	"black", "red", "green", "yellow",
	"blue", "magenta", "cyan", "white",
	"grey", "red", "green", "yellow",
	"blue", "magenta", "cyan", "white",
}

func main() {
	var (
		cols    = flag.Int("cols", 100, "terminal width, in columns")
		rows    = flag.Int("rows", 26, "terminal height, in rows")
		warmup  = flag.Duration("warmup", 5*time.Second, "how long to let the program run before reading it")
		quiet   = flag.Duration("quiet", 400*time.Millisecond, "how long it must stop writing for")
		out     = flag.String("out", "", "where to write the SVG (required)")
		label   = flag.String("label", "", "the figure's aria-label (required)")
		quitKey = flag.String("quit", "q", "the key that makes the program exit")
		repaint = flag.String("repaint", "^L", "the key that asks for a full redraw, or empty for none")
		save    = flag.String("save", "", "also write the screen here, to be drawn again with -from")
		from    = flag.String("from", "", "draw a screen saved earlier instead of running a program")
	)
	var sends sendList
	flag.Var(&sends, "send", "keys to type before reading, repeatable and in order")
	var callouts calloutList
	flag.Var(&callouts, "callout", "a numbered note, as ROW:TEXT, repeatable")
	flag.Parse()

	if *out == "" || *label == "" || (*from == "" && flag.NArg() == 0) {
		fmt.Fprintln(os.Stderr, "usage: term-capture -out FILE -label TEXT [-callout ROW:TEXT] -- COMMAND [ARGS]\n"+
			"       term-capture -from SCREEN -out FILE -label TEXT [-callout ROW:TEXT]")
		os.Exit(2)
	}
	if *from != "" && flag.NArg() > 0 {
		fmt.Fprintln(os.Stderr, "term-capture: -from draws a screen that was already taken, so there is "+
			"no command to run")
		os.Exit(2)
	}
	if *cols < 1 || *cols > maxDimension || *rows < 1 || *rows > maxDimension {
		fmt.Fprintf(os.Stderr, "term-capture: a screen is between 1 and %d columns and rows, not %dx%d\n",
			maxDimension, *cols, *rows)
		os.Exit(2)
	}

	repaintKeys, err := keystrokes(*repaint)
	if err != nil {
		fmt.Fprintln(os.Stderr, "term-capture: -repaint:", err)
		os.Exit(2)
	}
	quitKeys, err := keystrokes(*quitKey)
	if err != nil {
		fmt.Fprintln(os.Stderr, "term-capture: -quit:", err)
		os.Exit(2)
	}

	/* ONE CAPTURE, DRAWN ONCE PER LANGUAGE.

	   The callouts are prose and belong in the reader's language; the screen
	   behind them is a measurement and must not move between the two. Running
	   the program twice gives two screens — the same figure with different
	   numbers in English and in Portuguese, which is worse than not translating
	   at all. So the screen is saved and drawn again.

	   It is how this was got wrong: the first pair wrote one SVG into both
	   files and translated only the caption, so a reader in Portuguese met four
	   callouts in English under a figure whose caption was theirs. */
	var screen grid
	if *from != "" {
		screen, err = load(*from)
	} else {
		screen, err = capture(flag.Args(), *cols, *rows, *warmup, *quiet, sends, repaintKeys, quitKeys)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "term-capture:", err)
		os.Exit(1)
	}
	if *from != "" {
		*rows, *cols = len(screen), 0
		if len(screen) > 0 {
			*cols = len(screen[0])
		}
	}

	if *save != "" {
		if err := store(*save, screen); err != nil {
			fmt.Fprintln(os.Stderr, "term-capture:", err)
			os.Exit(1)
		}
	}

	svg := draw(screen, *cols, *rows, *label, callouts)
	if err := os.WriteFile(*out, []byte(svg+"\n"), fileMode); err != nil {
		fmt.Fprintln(os.Stderr, "term-capture:", err)
		os.Exit(1)
	}

	// The fence wants JSON, so print it rather than making somebody escape a
	// few thousand quotes by hand.
	fence, err := json.Marshal(map[string]string{"svg": svg, "caption": ""})
	if err != nil {
		fmt.Fprintln(os.Stderr, "term-capture:", err)
		os.Exit(1)
	}
	fmt.Println(string(fence))
	fmt.Fprintf(os.Stderr, "term-capture: wrote %s, %d bytes, %d columns by %d rows\n",
		*out, len(svg), *cols, *rows)
}

// grid is a resolved screen: what the program had drawn at the moment it was
// read, one entry per cell.
type grid [][]cell

/*
A SCREEN ON DISK, so one capture can be drawn in more than one language.

	JSON and not the SVG, because what has to survive is the cells: re-reading
	an SVG would mean parsing back out what this wrote, and the second drawing
	would inherit every decision the first made about layout.
*/
type savedCell struct {
	Text string `json:"t"`
	Fg   string `json:"f,omitempty"`
	Bg   string `json:"b,omitempty"`
	Bold bool   `json:"o,omitempty"`
}

func store(path string, g grid) error {
	rows := make([][]savedCell, len(g))
	for y, row := range g {
		rows[y] = make([]savedCell, len(row))
		for x, c := range row {
			rows[y][x] = savedCell{Text: c.text, Fg: c.fg, Bg: c.bg, Bold: c.bold}
		}
	}
	b, err := json.Marshal(rows)
	if err != nil {
		return fmt.Errorf("writing the screen: %w", err)
	}
	if err := os.WriteFile(path, b, fileMode); err != nil {
		return fmt.Errorf("writing the screen: %w", err)
	}
	return nil
}

func load(path string) (grid, error) {
	b, err := os.ReadFile(path) //nolint:gosec // the author names the file
	if err != nil {
		return nil, fmt.Errorf("reading the screen: %w", err)
	}
	var rows [][]savedCell
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, fmt.Errorf("reading the screen: %w", err)
	}
	g := make(grid, len(rows))
	for y, row := range rows {
		g[y] = make([]cell, len(row))
		for x, c := range row {
			g[y][x] = cell{text: c.Text, fg: c.Fg, bg: c.Bg, bold: c.Bold}
		}
	}
	return g, nil
}

type cell struct {
	text   string
	fg, bg string // "" means the terminal's default
	bold   bool
}

func capture(argv []string, cols, rows int, warmup, quiet time.Duration,
	keys []string, repaint, quitKey string) (grid, error) {
	master, slave, err := openPTY(cols, rows)
	if err != nil {
		return nil, fmt.Errorf("opening a pseudo-terminal: %w", err)
	}
	// read-only from here: there is nothing a failed close could lose
	defer func() { _ = master.Close() }()

	// The command is what the author typed after `--`, which is the whole point
	// of the tool: it photographs a program somebody chose. It runs on an
	// author's machine with that author's own privileges, so there is no
	// boundary here for a tainted argument to cross.
	cmd := exec.Command(argv[0], argv[1:]...) //nolint:gosec
	cmd.Stdin, cmd.Stdout, cmd.Stderr = slave, slave, slave
	// A program with no locale draws its box and its arrows in ASCII: htop's
	// sort indicator comes out as "-" where it means "▽". The capture should
	// look like the reader's terminal, and the reader has a locale.
	cmd.Env = append(os.Environ(),
		"TERM=xterm-256color", "COLORTERM=truecolor",
		"LANG=C.UTF-8", "LC_ALL=C.UTF-8")
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true, Setctty: true, Ctty: 0}
	if err := cmd.Start(); err != nil {
		_ = slave.Close() // the child never got it; nothing was written
		return nil, fmt.Errorf("starting %s: %w", argv[0], err)
	}
	// The child holds its own descriptor now. This end has to go or the read
	// below never sees EOF.
	_ = slave.Close()
	defer func() {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
	}()

	term := vt.NewSafeEmulator(cols, rows)

	// THE EMULATOR IS NOT CLOSED, AND THAT IS THE LESSER OF TWO THINGS.
	//
	// It used to be, on a `defer`, to unblock the reply pump below — and doing
	// that is a data race inside the library. `SafeEmulator` guards `Write`,
	// `Resize` and the rest with a mutex and deliberately does NOT guard `Read`,
	// because `Read` blocks; `Emulator.Read` and `Emulator.Close` then both
	// touch the same `closed` field with nothing between them. Closing while the
	// pump sits inside that Read is exactly the pair, and `-race` says so:
	//
	//	Write at 0x…958 by goroutine 18:      vt.(*Emulator).Close()
	//	Previous read by goroutine 19:        vt.(*Emulator).Read()
	//
	// Nothing had ever run this function under `-race`: the CLI is not built
	// with it and no test reached the pseudo-terminal half. It took the test
	// this repository added last, and it failed on `main` rather than on the
	// branch, because the branch's own run was the one that got lucky.
	//
	// There is no way to unblock that Read from outside except the Close that
	// races with it, so the pump is left where it is — blocked, holding one
	// goroutine, until the process ends. That costs a goroutine per capture in
	// a program that captures once and exits, and it buys a `go test -race`
	// that means what it says.
	//
	// THE PROGRAM ASKS THE TERMINAL QUESTIONS AND HAS TO GET ANSWERS. vim opens
	// by querying device attributes; an emulator composes the reply and writes
	// it to an io.Pipe, which BLOCKS until somebody reads it — while holding the
	// emulator's lock. Nothing drained it in the first version, so reading the
	// first cell of a vim screen deadlocked against a reply nobody collected.
	// htop never asks, which is why it never showed.
	go func() { _, _ = io.Copy(master, term) }()

	var lastWrite atomic.Int64
	lastWrite.Store(time.Now().UnixNano())
	go func() {
		buf := make([]byte, 64*1024)
		for {
			n, err := master.Read(buf)
			if n > 0 {
				_, _ = term.Write(buf[:n])
				lastWrite.Store(time.Now().UnixNano())
			}
			if err != nil {
				return
			}
		}
	}()

	time.Sleep(warmup)

	// Typing, when the screen wanted is not the one the program opens on. Each
	// batch settles before the next, because a program that is still redrawing
	// has not finished reading either.
	//
	// THE CLOCK IS PUT FORWARD AT THE KEYSTROKE, and without that one line none
	// of this did anything at all. `settle` waits for the program to be quiet
	// for `quiet` — and a program that has been sitting still through the
	// warmup is ALREADY quieter than that, so it returned on its first
	// comparison, before the keystroke had crossed the line discipline. The
	// screen was then read exactly as it had been before anything was typed.
	//
	// IT FAILED SILENTLY, WHICH IS WHAT MADE IT EXPENSIVE. `-send G` produced
	// the opening screen and reported success; the ruler read `1,1` and the
	// caption beside it said the cursor had moved. The conclusion drawn from it
	// in this repository was that a pseudo-terminal could not carry vim's
	// visual mode — a fact about this tool, mistaken for a fact about
	// terminals, and taken as a reason not to capture twenty more screens.
	//
	// Moving the clock makes the wait mean what its name says: at least `quiet`
	// after the key was sent, and longer if the program is still drawing when
	// that runs out.
	for i, k := range keys {
		if _, err := master.Write([]byte(k)); err != nil {
			return nil, fmt.Errorf("typing -send %d: %w", i+1, err)
		}
		lastWrite.Store(time.Now().UnixNano())
		if err := settle(&lastWrite, quiet); err != nil {
			return nil, fmt.Errorf("after -send %d: %w", i+1, err)
		}
	}

	// A full-screen program redraws only what changed, so a read in the middle
	// of a partial update interleaves two frames. This asks for the whole
	// screen. It is a flag because the key is not universal: Ctrl-L redraws in
	// vim and nano and RECENTRES THE VIEW in emacs, which moves the thing being
	// photographed.
	if repaint != "" {
		if _, err := master.Write([]byte(repaint)); err != nil {
			return nil, fmt.Errorf("asking for a repaint: %w", err)
		}
		// The same clock, for the same reason as the loop above: without it
		// the wait below can end before the redraw this key asked for has
		// started, which is the interleaved frame it exists to prevent.
		lastWrite.Store(time.Now().UnixNano())
	}
	if err := settle(&lastWrite, quiet); err != nil {
		return nil, err
	}

	g := read(term, cols, rows)

	// Let it put the terminal back the way it found it. Nothing here reads the
	// teardown, but a program killed mid-frame can leave a child behind.
	_, _ = master.Write([]byte(quitKey))
	time.Sleep(200 * time.Millisecond)
	return g, nil
}

// settle waits for the program to stop writing for `quiet`, which is how a
// partial repaint is avoided.
func settle(lastWrite *atomic.Int64, quiet time.Duration) error {
	deadline := time.Now().Add(20 * time.Second)
	for time.Now().Before(deadline) {
		if time.Since(time.Unix(0, lastWrite.Load())) > quiet {
			return nil
		}
		time.Sleep(quiet / 8)
	}
	return fmt.Errorf("the program never stopped writing for %s; it may be animating", quiet)
}

func read(term *vt.SafeEmulator, cols, rows int) grid {
	g := make(grid, rows)
	for y := range g {
		g[y] = make([]cell, cols)
		for x := range g[y] {
			c := term.CellAt(x, y)
			if c == nil {
				g[y][x] = cell{text: " "}
				continue
			}
			text := c.Content
			if text == "" {
				text = " "
			}
			fg, bg := token(c.Style.Fg), token(c.Style.Bg)
			// REVERSE VIDEO IS A SWAP, NOT AN ATTRIBUTE THE SVG HAS. nano's
			// title bar and its two rows of shortcuts are drawn this way, and
			// so is a vim selection: no colour is set, the two are exchanged.
			// Ignoring it loses the bar entirely — it comes out as ordinary
			// text on the ordinary ground.
			if c.Style.Attrs&uv.AttrReverse != 0 {
				// The defaults have to be named before they can be swapped, and
				// in the right order: the text is the light one and the ground
				// is the dark one, so reversing gives dark text on a light bar.
				// Naming them the other way round paints a black bar on a dark
				// panel, which is a bar nobody can see.
				if fg == "" {
					fg = "white"
				}
				if bg == "" {
					bg = "black"
				}
				fg, bg = bg, fg
			}
			g[y][x] = cell{
				text: text,
				fg:   fg,
				bg:   bg,
				bold: c.Style.Attrs&uv.AttrBold != 0,
			}
		}
	}
	return g
}

// token names the CSS custom property a colour becomes, or returns "" for the
// terminal's default. A colour the palette has no name for — a 256-colour index
// or a direct RGB — comes back as its own value here, which is what the program
// asked for and not necessarily what gets drawn: `fill` decides that, against
// the ground the run lands on. This function's job is to report, not to judge.
func token(c color.Color) string {
	switch v := c.(type) {
	case nil:
		return ""
	case ansi.BasicColor:
		if int(v) < len(ansiToken) {
			return ansiToken[v]
		}
	}
	r, g, b, a := c.RGBA()
	if a == 0 {
		return ""
	}
	return fmt.Sprintf("#%02x%02x%02x", r>>8, g>>8, b>>8)
}

func colour(name, fallback string, background bool) string {
	switch {
	case name == "":
		return fallback
	case strings.HasPrefix(name, "#"):
		return name
	case background:
		return "var(--term-" + name + "-bg)"
	default:
		return "var(--term-" + name + ")"
	}
}

func draw(g grid, cols, rows int, label string, callouts calloutList) string {
	// Blank rows at the bottom are where the program stopped, not content: a
	// screen sized for 26 rows and filled to 13 should not draw a box with
	// half of it empty.
	for rows > 1 && blank(g[rows-1]) {
		rows--
	}

	boxW := padding*2 + float64(cols)*charWidth
	boxH := padding*2 + float64(rows)*lineHeight

	var rects, lines strings.Builder
	for y := 0; y < rows; y++ {
		var spans strings.Builder
		for _, r := range runs(g[y]) {
			if r.bg != "" {
				fmt.Fprintf(&rects,
					`<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s"/>`,
					gutter+padding+float64(r.start)*charWidth, padding+float64(y)*lineHeight,
					float64(len([]rune(r.text)))*charWidth, lineHeight,
					colour(r.bg, "var(--panel)", true))
			}
			weight := ""
			if r.bold {
				weight = ` font-weight="600"`
			}
			fmt.Fprintf(&spans, `<tspan%s fill="%s" textLength="%.2f" lengthAdjust="spacingAndGlyphs">%s</tspan>`,
				weight, fill(colour(r.fg, "", false), colour(r.bg, "", true)),
				float64(len([]rune(r.text)))*charWidth, html.EscapeString(r.text))
		}
		fmt.Fprintf(&lines, `<text x="%.2f" y="%.2f" xml:space="preserve">%s</text>`,
			gutter+padding, padding+float64(y)*lineHeight+11.5, spans.String())
	}

	var marks, notes strings.Builder
	for i, c := range callouts {
		n := i + 1
		fmt.Fprintf(&marks,
			`<text x="%.2f" y="%.2f" text-anchor="middle" font-family="'IBM Plex Sans', sans-serif" font-size="10" font-weight="600" fill="var(--phosphor)">%d</text>`,
			gutter/2, padding+float64(c.row)*lineHeight+11.5, n)
		fmt.Fprintf(&notes,
			`<text x="%.2f" y="%.2f" text-anchor="middle" font-family="'IBM Plex Sans', sans-serif" font-size="11" font-weight="600" fill="var(--phosphor)">%d</text>`+
				`<text x="%.2f" y="%.2f" font-family="'IBM Plex Sans', sans-serif" font-size="11" fill="var(--paper-dim)">%s</text>`,
			gutter/2, boxH+22+float64(n)*16, n,
			gutter+4, boxH+22+float64(n)*16, html.EscapeString(c.text))
	}

	width := gutter + boxW
	height := boxH
	if len(callouts) > 0 {
		height += 26 + float64(len(callouts))*16
	}

	return fmt.Sprintf(
		`<svg viewBox="0 0 %.0f %.0f" role="img" aria-label="%s">`+
			`<rect x="%.0f" y="0" width="%.0f" height="%.0f" rx="3" fill="var(--panel)" stroke="var(--wire)" stroke-width="1.5"></rect>`+
			`%s<g font-family="'IBM Plex Mono', monospace" font-size="%g">%s</g>`+
			`%s%s</svg>`,
		width, height, html.EscapeString(label),
		gutter, boxW, boxH,
		rects.String(), fontSize, lines.String(),
		marks.String(), notes.String())
}

// run is a stretch of one row that shares a colour, which is what becomes one
// <tspan> and, when it has a background, one <rect>.
type run struct {
	text   string
	fg, bg string
	bold   bool
	start  int
}

func runs(row []cell) []run {
	var out []run
	for x, c := range row {
		if n := len(out); n > 0 {
			if last := &out[n-1]; last.fg == c.fg && last.bg == c.bg && last.bold == c.bold {
				last.text += c.text
				continue
			}
		}
		out = append(out, run{text: c.text, fg: c.fg, bg: c.bg, bold: c.bold, start: x})
	}
	return out
}

func blank(row []cell) bool {
	for _, c := range row {
		if strings.TrimSpace(c.text) != "" || c.bg != "" {
			return false
		}
	}
	return true
}

// sendList is the keys typed before the screen is read. The escapes are the
// ones a keyboard needs and Go's own unquoting does not have: `\e` is Escape,
// which is how you leave vim's insert mode, and `^X` is a control character,
// which is how you do anything at all in nano and emacs.
type sendList []string

func (l *sendList) String() string { return fmt.Sprint(*l) }

func (l *sendList) Set(v string) error {
	k, err := keystrokes(v)
	if err != nil {
		return err
	}
	*l = append(*l, k)
	return nil
}

// keystrokes turns what somebody can type on a command line into what a
// terminal driver expects. Go's own unquoting has neither of the two that
// matter here: `\e` is Escape, which is how you leave vim's insert mode, and
// `^X` is a control character, which is how you do anything in nano or emacs.
//
// EVERY key-taking flag goes through this. The first version decoded only
// `-send`, so `-quit ':q!\r'` sent a literal backslash and an r — vim sat in
// its command line holding an unfinished `:q!` and the capture hung.
func keystrokes(v string) (string, error) {
	var b strings.Builder
	for i := 0; i < len(v); i++ {
		switch {
		case v[i] == '^' && i+1 < len(v):
			c := v[i+1]
			if c == '^' {
				b.WriteByte('^')
			} else if c >= '?' && c <= '_' || c >= 'a' && c <= 'z' {
				b.WriteByte(strings.ToUpper(string(c))[0] & 0x1f)
			} else {
				return "", fmt.Errorf("%q is not a control character", v[i:i+2])
			}
			i++
		case v[i] == '\\' && i+1 < len(v):
			switch v[i+1] {
			case 'e':
				b.WriteByte(0x1b)
			case 'r':
				b.WriteByte('\r')
			case 'n':
				b.WriteByte('\n')
			case 't':
				b.WriteByte('\t')
			case '\\':
				b.WriteByte('\\')
			default:
				return "", fmt.Errorf("%q is not an escape this understands", v[i:i+2])
			}
			i++
		default:
			b.WriteByte(v[i])
		}
	}
	return b.String(), nil
}

type callout struct {
	row  int
	text string
}

type calloutList []callout

func (l *calloutList) String() string { return fmt.Sprint(*l) }

func (l *calloutList) Set(v string) error {
	row, text, ok := strings.Cut(v, ":")
	if !ok {
		return fmt.Errorf("a callout is ROW:TEXT, and %q has no colon", v)
	}
	n, err := strconv.Atoi(strings.TrimSpace(row))
	if err != nil {
		return fmt.Errorf("a callout's row is a number, and %q is not: %w", row, err)
	}
	*l = append(*l, callout{row: n, text: text})
	return nil
}

// openPTY opens a master/slave pair. This is `x/sys/unix` rather than a pty
// package because `x/sys` is already in the module graph and this is thirty
// lines: a dependency added for thirty lines is a dependency to explain at
// every upgrade.
func openPTY(cols, rows int) (master, slave *os.File, err error) {
	m, err := os.OpenFile("/dev/ptmx", os.O_RDWR, 0)
	if err != nil {
		return nil, nil, err
	}
	closeOnError := func(e error) (*os.File, *os.File, error) {
		_ = m.Close() // already failing; a second error would bury the first
		return nil, nil, e
	}
	if err := unix.IoctlSetPointerInt(int(m.Fd()), unix.TIOCSPTLCK, 0); err != nil {
		return closeOnError(err)
	}
	n, err := unix.IoctlGetInt(int(m.Fd()), unix.TIOCGPTN)
	if err != nil {
		return closeOnError(err)
	}
	s, err := os.OpenFile(fmt.Sprintf("/dev/pts/%d", n), os.O_RDWR|unix.O_NOCTTY, 0)
	if err != nil {
		return closeOnError(err)
	}
	// `main` refuses anything outside 1..maxDimension, which is well inside
	// what these fields hold.
	ws := unix.Winsize{Row: uint16(rows), Col: uint16(cols)} //nolint:gosec
	if err := unix.IoctlSetWinsize(int(m.Fd()), unix.TIOCSWINSZ, &ws); err != nil {
		_ = s.Close() // same
		return closeOnError(err)
	}
	return m, s, nil
}
