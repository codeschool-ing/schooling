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
const (
	fontSize   = 12.0
	charWidth  = fontSize * 7.0 / 12.0
	lineHeight = 15.5
	padding    = 14.0
	gutter     = 26.0 // the left margin the callout numbers sit in
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
	)
	var callouts calloutList
	flag.Var(&callouts, "callout", "a numbered note, as ROW:TEXT, repeatable")
	flag.Parse()

	if *out == "" || *label == "" || flag.NArg() == 0 {
		fmt.Fprintln(os.Stderr, "usage: term-capture -out FILE -label TEXT [-callout ROW:TEXT] -- COMMAND [ARGS]")
		os.Exit(2)
	}

	screen, err := capture(flag.Args(), *cols, *rows, *warmup, *quiet, *quitKey)
	if err != nil {
		fmt.Fprintln(os.Stderr, "term-capture:", err)
		os.Exit(1)
	}

	svg := draw(screen, *cols, *rows, *label, callouts)
	if err := os.WriteFile(*out, []byte(svg+"\n"), 0o644); err != nil {
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

type cell struct {
	text   string
	fg, bg string // "" means the terminal's default
	bold   bool
}

func capture(argv []string, cols, rows int, warmup, quiet time.Duration, quitKey string) (grid, error) {
	master, slave, err := openPTY(cols, rows)
	if err != nil {
		return nil, fmt.Errorf("opening a pseudo-terminal: %w", err)
	}
	defer master.Close()

	cmd := exec.Command(argv[0], argv[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = slave, slave, slave
	// A program with no locale draws its box and its arrows in ASCII: htop's
	// sort indicator comes out as "-" where it means "▽". The capture should
	// look like the reader's terminal, and the reader has a locale.
	cmd.Env = append(os.Environ(),
		"TERM=xterm-256color", "COLORTERM=truecolor",
		"LANG=C.UTF-8", "LC_ALL=C.UTF-8")
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true, Setctty: true, Ctty: 0}
	if err := cmd.Start(); err != nil {
		slave.Close()
		return nil, fmt.Errorf("starting %s: %w", argv[0], err)
	}
	slave.Close()
	defer func() {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
	}()

	term := vt.NewSafeEmulator(cols, rows)
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

	if _, err := master.Write([]byte{0x0c}); err != nil { // Ctrl-L
		return nil, fmt.Errorf("asking for a repaint: %w", err)
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
			g[y][x] = cell{
				text: text,
				fg:   token(c.Style.Fg),
				bg:   token(c.Style.Bg),
				bold: c.Style.Attrs&uv.AttrBold != 0,
			}
		}
	}
	return g
}

// token names the CSS custom property a colour becomes, or returns "" for the
// terminal's default. A colour the palette has no name for — a 256-colour index
// or a direct RGB — keeps its own value: it was chosen by the program and is
// not ours to reinterpret.
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
				weight, colour(r.fg, "var(--paper)", false),
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
		m.Close()
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
	ws := unix.Winsize{Row: uint16(rows), Col: uint16(cols)}
	if err := unix.IoctlSetWinsize(int(m.Fd()), unix.TIOCSWINSZ, &ws); err != nil {
		s.Close()
		return closeOnError(err)
	}
	return m, s, nil
}
