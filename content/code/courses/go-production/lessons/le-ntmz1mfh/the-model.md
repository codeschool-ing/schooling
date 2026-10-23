---
title: A model, a view, and a loop you do not write
version: 1
---

The obvious way to write an interactive screen is a loop of your own: read a key, change a few
variables, clear the screen, print everything again. It works for a page of code, and then the
variables multiply, the redraw happens in three places, and nothing can be tested without a person
pressing keys. **Bubble Tea turns the loop inside out. You write the state and the rules, and the
library runs the loop.** The shape comes from Elm, a language for web pages, and is known as the Elm
architecture.

This lesson builds `hits browse`, an interactive screen over the same access log lesson 1 counted.
Here it is on a real terminal, after `j` was pressed twice:

```schooling-figure
{"caption": "A real terminal, 72 columns wide, running hits browse access.log after j was pressed twice: tools/term-capture drew the screen the program had painted.", "svg": "<svg viewBox=\"0 0 558 288\" role=\"img\" aria-label=\"The hits browse screen on a real terminal, 72 columns wide. The title reads access.log: 8 paths. Below it the eight paths with their request counts, from /login with 2576 to /health with 2364. A &gt; marks /static/app.js, the third row, after j was pressed twice. The last line lists the keys: up/down or j/k to move, enter for statuses, q to quit.\"><rect x=\"26\" y=\"0\" width=\"532\" height=\"214\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">access.log: 8 paths</tspan></text><text x=\"40\" y=\"41.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /login             2576</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /api/orders        2542</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">&gt; /static/app.js     2526</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /api/users         2512</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /api/orders/42     2503</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /static/app.css    2490</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /                  2487</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /health            2364</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">up/down or j/k: move   enter: statuses   q: quit</tspan></text></g><text x=\"13.00\" y=\"25.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"13.00\" y=\"87.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"13.00\" y=\"196.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"13.00\" y=\"252.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"30.00\" y=\"252.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the log and how many paths it holds</text><text x=\"13.00\" y=\"268.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"30.00\" y=\"268.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the cursor, after j was pressed twice</text><text x=\"13.00\" y=\"284.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"30.00\" y=\"284.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the keys this screen answers</text></svg>"}
```

The paths and their counts are `hits top`'s, in the same order. What `top` cannot do is let you pick
one: Enter opens the highlighted path and shows its requests by status code, and Esc comes back to
the list.

## Four pieces

In Bubble Tea a program is **a value of a type you write, called the model, with three methods**.
The library calls them; your code never calls them itself:

| piece | what it is given | what it returns | when the library calls it |
|---|---|---|---|
| the model | | | it is the state: a struct of your own |
| `Init` | nothing | the first command, or `nil` | once, before the first screen |
| `Update` | one message | the next model, and a command or `nil` | for every message, one at a time |
| `View` | nothing | what the screen should show, a `tea.View` | after every `Update` |

A **message** is anything that happened: a key pressed, the window resized, a file finished reading.
A **command** is work to be done outside the loop, whose result comes back as another message.
Section 03 is about messages and section 04 about commands. The loop that joins them is the
library's, and it is short enough to draw:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 730 310\" role=\"img\" aria-label=\"The loop Bubble Tea runs. The terminal sends keys, sizes and replies into a queue of messages, taken one at a time. Each message goes to Update(msg), which returns the next model and a command or nil. The next model goes to View(), which draws it, and the screen is repainted on the terminal. A command, tea.Cmd, runs in a goroutine of its own, and its result comes back into the queue as a message; Init's command joins the queue the same way.\"><defs><marker id=\"lp-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"lp-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"lp-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the terminal</text><text x=\"105\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">keys, sizes, replies</text><rect x=\"250\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a queue of messages</text><text x=\"350\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">taken one at a time</text><rect x=\"510\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Update(msg)</text><text x=\"610\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">returns a model and a command</text><rect x=\"510\" y=\"200\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">View()</text><text x=\"610\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">draws that model</text><rect x=\"250\" y=\"200\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">tea.Cmd</text><text x=\"350\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">runs in a goroutine of its own</text><path d=\"M190 68 H246\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-wire)\"></path><path d=\"M450 68 H506\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-wire)\"></path><path d=\"M610 96 V196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-phosphor)\"></path><text x=\"618\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the next model</text><path d=\"M560 96 V150 H420 V196\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-amber)\"></path><text x=\"490\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a command, or nil</text><path d=\"M290 200 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-amber)\"></path><text x=\"282\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">its result, as a message</text><path d=\"M610 256 V284 H105 V100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-wire)\"></path><text x=\"357\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the screen, repainted</text><text x=\"350\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Init's command joins here too</text><path d=\"M350 30 V36\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-wire)\"></path></svg>", "caption": "The loop is the library's. Your code is what runs in the coloured boxes, and only Update changes the model."}
```

**Nothing else changes the model.** A key press does not move the cursor; it becomes a message, and
`Update` decides what the next model is. That one rule is what section 05 tests without a terminal.

## The project

`hits browse` lives in its own directory, `~/tea-hits`, so that lesson 1's program stays as it was.
Make the module with `go mod init example.com/hits`, copy three of lesson 1's files into it,
`tools/genlog/main.go`, `internal/tally/tally.go` and `main_test.go`, and write the 20,000-line
`access.log` with `genlog` as lesson 1 did. `main.go` comes in section 04, with a new subcommand.
Then two dependencies, Bubble Tea and the package that answers "is this a terminal":

```
ana@vm:~/tea-hits$ go get charm.land/bubbletea/v2@v2.1.0 golang.org/x/term@v0.47.0
go: added charm.land/bubbletea/v2 v2.1.0
go: added github.com/charmbracelet/colorprofile v0.4.3
go: added github.com/charmbracelet/ultraviolet v0.0.0-20261008173134-6b8d4baf91b4
go: added github.com/charmbracelet/x/ansi v0.11.9
go: added github.com/charmbracelet/x/term v0.2.2
go: added github.com/charmbracelet/x/termios v0.1.1
go: added github.com/charmbracelet/x/windows v0.2.2
go: added github.com/clipperhouse/displaywidth v0.11.0
go: added github.com/clipperhouse/uax29/v2 v2.7.0
go: added github.com/lucasb-eyer/go-colorful v1.4.1
go: added github.com/mattn/go-runewidth v0.0.30
go: added github.com/muesli/cancelreader v0.2.2
go: added github.com/rivo/uniseg v0.4.7
go: added github.com/xo/terminfo v1.0.0
go: added golang.org/x/sync v0.22.0
go: added golang.org/x/sys v0.49.0
go: added golang.org/x/term v0.47.0
```

**The import path is `charm.land/bubbletea/v2`**, and version 2 differs from version 1 in ways that
break most code written for it. On a first run the go command also prints a `go: downloading` line
for each module it fetches; these modules were already in the cache.

## The model

The screen's state and the function that draws it go in a new package, `internal/tui`, in
`model.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tui/model.go",
  "parts": [
    {
      "code": "// Package tui is an interactive screen over an access log: the paths with\n// their request counts, and the statuses of the one under the cursor.\npackage tui\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"slices\"\n\t\"strings\"\n\n\ttea \"charm.land/bubbletea/v2\"\n)\n",
      "note": "A package of its own under `internal/`, beside `tally`. The import is renamed `tea` by convention, and the path is `charm.land/bubbletea/v2`: version 2 moved off `github.com`, so an import from an older tutorial names a different module."
    },
    {
      "code": "// row is one path and what it was answered with.\ntype row struct {\n\tpath     string\n\thits     int\n\tbyStatus map[int]int\n}\n",
      "note": "One line of the list, carrying the breakdown that Enter shows. Lesson 1's `tally.Summary` counts paths and statuses separately, so the per-path statuses need a type of their own."
    },
    {
      "code": "// Model is everything the screen knows. It is passed by value: Update\n// returns a changed copy, and View only reads it.\ntype Model struct {\n\tname   string    // the file, as the title shows it\n\tin     io.Reader // where Init's command reads the log from\n\trows   []row     // nil until the log has been read\n\terr    error     // what stopped the reading, if anything\n\tcursor int       // the index of the highlighted row\n\topen   bool      // showing the statuses of rows[cursor]\n\twidth  int       // the terminal's width, 0 until it is known\n}\n",
      "note": "**Everything the screen can show is in these seven fields.** Which row is highlighted, whether it is open, how wide the terminal is: none of it lives in a global or in the terminal. `rows` is `nil` until the count has finished, and that one fact tells `View` which of its three screens to draw."
    },
    {
      "code": "// New returns a model for the log in r. Nothing is read yet.\nfunc New(name string, r io.Reader) Model {\n\treturn Model{name: name, in: r}\n}\n\n// Err is what stopped the reading. The screen is gone by the time anybody\n// can read a message, so the caller prints it.\nfunc (m Model) Err() error { return m.err }\n",
      "note": "`New` only stores the reader. Reading belongs to `Init`'s command, in section 04. `Err` exists because the screen is cleared on the way out, so an error has to be handed back and printed afterwards."
    },
    {
      "code": "// View draws the model. It is called after every Update.\nfunc (m Model) View() tea.View {\n\tvar b strings.Builder\n\tswitch {\n\tcase m.rows == nil:\n\t\tfmt.Fprintf(&b, \"counting %s ...\\n\", m.name)\n\tcase m.open:\n\t\tr := m.rows[m.cursor]\n\t\tfmt.Fprintf(&b, \"requests to %s: %d\\n\\n\", r.path, r.hits)\n\t\tmost := slices.Max(slices.Collect(maps.Values(r.byStatus)))\n\t\tfor _, status := range slices.Sorted(maps.Keys(r.byStatus)) {\n\t\t\tn := r.byStatus[status]\n\t\t\tfmt.Fprintf(&b, \"  %d %6d  %s\\n\", status, n, bar(n, most, m.width-16))\n\t\t}\n\t\tb.WriteString(\"\\nesc: back   q: quit\\n\")\n\tdefault:\n\t\tfmt.Fprintf(&b, \"%s: %d paths\\n\\n\", m.name, len(m.rows))\n\t\tfor i, r := range m.rows {\n\t\t\tmark := \" \"\n\t\t\tif i == m.cursor {\n\t\t\t\tmark = \">\"\n\t\t\t}\n\t\t\tfmt.Fprintf(&b, \"%s %-16s %6d\\n\", mark, r.path, r.hits)\n\t\t}\n\t\tb.WriteString(\"\\nup/down or j/k: move   enter: statuses   q: quit\\n\")\n\t}\n\tv := tea.NewView(b.String())\n\tv.AltScreen = true\n\treturn v\n}\n",
      "note": "**`View` reads the model and returns what the screen should show; it changes nothing.** A `strings.Builder` collects the text and `tea.NewView` wraps it. Setting `AltScreen` asks for the terminal's alternate screen, the one `less` and `vim` use, so the shell's own lines come back untouched on exit."
    },
    {
      "code": "// bar draws n as a run of # characters, the largest count filling width.\nfunc bar(n, most, width int) string {\n\tif width < 1 {\n\t\treturn \"\"\n\t}\n\treturn strings.Repeat(\"#\", n*width/most)\n}",
      "note": "The bar scales to the terminal: the largest count fills the width less 16 columns for the labels. Until the width is known it is 0, and no bar is drawn."
    }
  ]
}
```

**`View` draws one of three screens, and the model alone decides which.** While `rows` is `nil` the
log is still being read. With `open` set, the highlighted path's statuses are listed with a bar
each. Otherwise the list is drawn with a `>` beside the cursor. The cursor is a character rather
than a colour on purpose: it survives a copy and paste, a terminal with no colours, and a screenshot
printed in grey.

Two differences from version 1 matter here, because most of the tutorials on the web predate them.
**`View` returns a `tea.View`, not a `string`**, and the alternate screen is a field of that value
instead of an option given to the program. The view now says what the terminal should be doing,
every time it is drawn, and Bubble Tea works out what to change.

One field breaks the rule that the model is plain data: `in`, the reader the log comes from. It is
there so that `Init` can start the count, and nothing in `View` or `Update` reads from it. `Model`
is not yet a `tea.Model`, because `Update` and `Init` live in two more files of the same package,
one in each of the next two sections.
