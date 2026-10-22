---
title: Update, and the messages it is sent
version: 1
---

Code that reacts to keys is usually written as handlers: a function per key, each changing some
shared state as a side effect. **`Update` is one function with one job: given the current model and
one message, return the next model.** Every change to the screen passes through it, in the order the
messages arrived, and nothing else holds state that could disagree with it. Save it beside the model
as `internal/tui/update.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tui/update.go",
  "parts": [
    {
      "code": "package tui\n\nimport tea \"charm.land/bubbletea/v2\"\n",
      "note": "A second file in the same package. Go compiles every file of a directory together, so `Update` sees `Model` and `row` from `model.go`."
    },
    {
      "code": "// Update is the only place the model changes. It receives one message and\n// returns the next model, and a command when something has to happen\n// outside: here, only quitting.\nfunc (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {",
      "note": "**The receiver is a copy, and the copy is what comes back.** The program keeps whatever `Update` returns as the new model, so a change made to `m` and returned is the next state, and a change made and not returned is lost."
    },
    {
      "code": "\tswitch msg := msg.(type) {\n\tcase loaded:\n\t\tm.rows, m.err = msg.rows, msg.err\n\t\tif m.err != nil {\n\t\t\treturn m, tea.Quit\n\t\t}",
      "note": "A message is any Go value, and a type switch tells them apart. `loaded` is this program's own message, the result of section 04's count; the other two cases are messages Bubble Tea sends."
    },
    {
      "code": "\tcase tea.WindowSizeMsg:\n\t\tm.width = msg.Width",
      "note": "The terminal's size arrives once at the start and again after every resize. Storing the width is all `Update` does with it; `View` turns it into the length of a bar."
    },
    {
      "code": "\tcase tea.KeyPressMsg:\n\t\tswitch msg.String() {\n\t\tcase \"q\", \"ctrl+c\":\n\t\t\treturn m, tea.Quit\n\t\tcase \"up\", \"k\":\n\t\t\tif !m.open && m.cursor > 0 {\n\t\t\t\tm.cursor--\n\t\t\t}\n\t\tcase \"down\", \"j\":\n\t\t\tif !m.open && m.cursor < len(m.rows)-1 {\n\t\t\t\tm.cursor++\n\t\t\t}\n\t\tcase \"enter\":\n\t\t\tm.open = len(m.rows) > 0\n\t\tcase \"esc\":\n\t\t\tm.open = false\n\t\t}\n\t}",
      "note": "**A key press is a message like any other, and `String` names it**: `\"up\"`, `\"j\"`, `\"enter\"`, `\"esc\"`, `\"ctrl+c\"`. The arrows and `j`/`k` share a case, which is what makes both work. The cursor stops at either end, and moves only while the list is showing."
    },
    {
      "code": "\treturn m, nil\n}",
      "note": "Every message that reaches this line leaves with no command. That includes the messages nobody asked for, which section 04 lists."
    }
  ]
}
```

## A message is any value

`tea.Msg` is an interface every type satisfies, so a message can be a struct of Bubble Tea's, a
struct of yours, or anything else. **The type switch is how `Update` reads one.** A message no case
names falls through to `return m, nil`, which is the right thing to do with something you did not
ask for, and section 04 shows that several arrive that nobody asked for.

Version 2 changed key messages more than anything else. In version 1, `tea.KeyMsg` was the struct
for a key press. In version 2, **`tea.KeyMsg` is an interface that covers both pressing and
releasing a key, and a press is `tea.KeyPressMsg`**. Code written as `case tea.KeyMsg:` still
compiles against version 2 and seems to work, until the view asks the terminal for release events
with `KeyboardEnhancements.ReportEventTypes`. From then on, on a terminal that supports them, that
case sees every key twice: once going down and once coming up.

The names `String` returns are what the cases compare against:

| key | `String()` | what `hits browse` does |
|---|---|---|
| up arrow, `k` | `"up"`, `"k"` | the cursor up one row, stopping at the top |
| down arrow, `j` | `"down"`, `"j"` | the cursor down one row, stopping at the bottom |
| Enter | `"enter"` | opens the highlighted path |
| Esc | `"esc"` | back to the list |
| `q`, Ctrl+C | `"q"`, `"ctrl+c"` | returns `tea.Quit`, section 04's command |

**Ctrl+C is a key here, not a signal.** Bubble Tea puts the terminal in raw mode, where the terminal
driver no longer turns Ctrl+C into `SIGINT`, so the keystroke arrives as an ordinary message. A
program whose `Update` forgets that case cannot be stopped with Ctrl+C at all, and the user is left
looking for another terminal to kill it from.

## The window's size is a message too

`tea.WindowSizeMsg` arrives once when the program starts and again every time the terminal is
resized. `hits browse` keeps the width and nothing else, and `View` uses it to scale the bars on the
second screen. Here is the screen after the list above received three more key presses, `j`, `j` and
Enter, on a terminal 72 columns wide:

```schooling-figure
{"caption": "The same run after j, j and Enter: the statuses of /static/app.js, each with a bar scaled to the terminal's width.", "svg": "<svg viewBox=\"0 0 558 319\" role=\"img\" aria-label=\"The breakdown screen for /static/app.js, 2526 requests, on a terminal 72 columns wide. Each status code is listed with its count and a bar of # characters: 200 has 944 and the longest bar, 56 characters; 404 has 340 and a bar of 20; the other eight statuses have between 141 and 174 and bars of 8 to 10. The last line reads esc: back, q: quit.\"><rect x=\"26\" y=\"0\" width=\"532\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">requests to /static/app.js: 2526</tspan></text><text x=\"40\" y=\"41.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  200    944  ########################################################</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  201    148  ########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  204    152  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  301    155  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  304    156  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  400    159  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  401    157  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  404    340  ####################</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  500    174  ##########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  503    141  ########</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">esc: back   q: quit</tspan></text></g><text x=\"13.00\" y=\"25.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"13.00\" y=\"56.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"13.00\" y=\"165.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"13.00\" y=\"283.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"30.00\" y=\"283.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the path that was highlighted, and its total</text><text x=\"13.00\" y=\"299.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"30.00\" y=\"299.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the largest count fills the width less 16 columns</text><text x=\"13.00\" y=\"315.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"30.00\" y=\"315.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">404, listed twice in genlog, has about twice the bar</text></svg>"}
```

The bar for `200` is the longest count and fills 72 less 16 columns. **Before the first
`WindowSizeMsg` the width is 0 and `View` draws no bars at all**, which is an honest answer to "how
wide is the screen" when nobody has said yet. A terminal dragged narrower sends a new message, the
next `View` draws shorter bars, and no code anywhere goes looking for the size.

## The program is a function of its messages

Put `Update` and `View` together and the whole program is one sentence: **the screen is `View`
applied to whatever `Update` made of the messages, in order.** Two runs that receive the same
messages draw the same screens, whatever the terminal and however fast the keys came.

The cursor's two limits show why that matters. Pressing `k` on the first row must do nothing, and so
must `j` on the last; Esc must close the breakdown and leave the cursor on the row it opened. **Each
of those is one message and one expected model**, and section 05 checks two of them by sending the
messages to `Update` directly, with no terminal and no keyboard anywhere in the test.
