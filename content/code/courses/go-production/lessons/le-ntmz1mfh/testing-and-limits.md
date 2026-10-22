---
title: Testing the screen, and when not to have one
version: 1
---

A full-screen program looks like the hardest thing in this course to test: it needs a terminal, it
reads keys one at a time, and its output is escape sequences. **A Bubble Tea program needs none of
that to be tested, because the screen is a function of the model and the model a function of the
messages.** A test builds a model, hands it messages, and compares what `View` returns with the
screen it expects. `internal/tui/tui_test.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tui/tui_test.go",
  "parts": [
    {
      "code": "package tui\n\nimport (\n\t\"strings\"\n\t\"testing\"\n\n\ttea \"charm.land/bubbletea/v2\"\n)\n\nconst log = \"2026-10-01T09:00:01Z GET / 200 5ms\\n\" +\n\t\"2026-10-01T09:00:02Z GET /login 404 7ms\\n\" +\n\t\"2026-10-01T09:00:03Z POST /login 200 9ms\\n\"\n",
      "note": "**The test is in package `tui` itself**, so it can read the model's unexported fields and call `Init`'s command directly. Three lines of log, two paths."
    },
    {
      "code": "// send hands the messages to Update one at a time, as the program would.\nfunc send(m Model, msgs ...tea.Msg) Model {\n\tfor _, msg := range msgs {\n\t\tnext, _ := m.Update(msg)\n\t\tm = next.(Model)\n\t}\n\treturn m\n}\n",
      "note": "`send` is the program's loop with the terminal taken out: each message goes to `Update`, and what comes back is the model the next message meets."
    },
    {
      "code": "var (\n\tdown  = tea.KeyPressMsg{Code: tea.KeyDown}\n\tj     = tea.KeyPressMsg{Code: 'j', Text: \"j\"}\n\tenter = tea.KeyPressMsg{Code: tea.KeyEnter}\n\tesc   = tea.KeyPressMsg{Code: tea.KeyEscape}\n)\n",
      "note": "Key presses built by hand, field by field. `Text` is what a printable key typed; the arrows, Enter and Esc have only a `Code`."
    },
    {
      "code": "func TestScreens(t *testing.T) {\n\tm := New(\"test.log\", strings.NewReader(log))\n\tif got := m.View().Content; got != \"counting test.log ...\\n\" {\n\t\tt.Fatalf(\"before the count:\\n%s\", got)\n\t}\n\tm = send(m, m.Init()(), tea.WindowSizeMsg{Width: 26, Height: 10})\n",
      "note": "**`m.Init()()` runs the count here, synchronously**: the first call returns the command and the second runs it. The width of 26 leaves 10 columns for a bar, so the test can name exactly how many `#` it wants."
    },
    {
      "code": "\tlist := \"test.log: 2 paths\\n\\n\" +\n\t\t\"> /login                2\\n\" +\n\t\t\"  /                     1\\n\\n\" +\n\t\t\"up/down or j/k: move   enter: statuses   q: quit\\n\"\n\tif got := m.View().Content; got != list {\n\t\tt.Errorf(\"list:\\n%s\\nwant:\\n%s\", got, list)\n\t}\n",
      "note": "The whole screen, compared as a string. A test that only looked for `/login` somewhere in the text would pass with the cursor on the wrong row."
    },
    {
      "code": "\tm = send(m, down, j, enter) // two steps down from the top stop at the last row\n\topen := \"requests to /: 1\\n\\n\" +\n\t\t\"  200      1  ##########\\n\\n\" +\n\t\t\"esc: back   q: quit\\n\"\n\tif got := m.View().Content; got != open {\n\t\tt.Errorf(\"open:\\n%s\\nwant:\\n%s\", got, open)\n\t}\n\n\tif m = send(m, esc); m.open || m.cursor != 1 {\n\t\tt.Errorf(\"after esc: open=%t cursor=%d, want false and 1\", m.open, m.cursor)\n\t}\n}\n",
      "note": "Two steps down on a list of two rows: the second press is refused at the bottom, and Enter opens `/`. The bar is ten `#` because `/` has one status, which is therefore the largest."
    },
    {
      "code": "func TestQuit(t *testing.T) {\n\tfor _, k := range []tea.KeyPressMsg{\n\t\t{Code: 'q', Text: \"q\"},\n\t\t{Code: 'c', Mod: tea.ModCtrl},\n\t} {\n\t\t_, cmd := New(\"test.log\", nil).Update(k)\n\t\tif cmd == nil {\n\t\t\tt.Fatalf(\"%s: no command\", k)\n\t\t}\n\t\tif _, ok := cmd().(tea.QuitMsg); !ok {\n\t\t\tt.Errorf(\"%s: command sent %T, want tea.QuitMsg\", k, cmd())\n\t\t}\n\t}\n}\n",
      "note": "`q` and Ctrl+C must both return a command, and that command must produce `tea.QuitMsg`. The model needs no log for this, so the reader is `nil`."
    },
    {
      "code": "func TestBadLine(t *testing.T) {\n\tm := New(\"bad.log\", strings.NewReader(log+\"oops\\n\"))\n\tnext, cmd := m.Update(m.Init()())\n\tif err := next.(Model).Err(); err == nil || err.Error() != \"line 4: want 5 fields, got 1\" {\n\t\tt.Errorf(\"error %v, want line 4\", err)\n\t}\n\tif cmd == nil {\n\t\tt.Error(\"a log that cannot be read should quit the program\")\n\t}\n}\n\nfunc TestEmptyLog(t *testing.T) {\n\tm := New(\"empty.log\", strings.NewReader(\"\"))\n\tm = send(m, m.Init()(), enter)\n\tif m.open {\n\t\tt.Error(\"enter opened a row in a log with no rows\")\n\t}\n}",
      "note": "The two failures section 04 could name. A line that will not parse is kept in the model and quits the program; an empty log gives an empty list, where Enter has nothing to open."
    }
  ]
}
```

```
ana@vm:~/tea-hits$ go test -v ./internal/tui
=== RUN   TestScreens
--- PASS: TestScreens (0.00s)
=== RUN   TestQuit
--- PASS: TestQuit (0.00s)
=== RUN   TestBadLine
--- PASS: TestBadLine (0.00s)
=== RUN   TestEmptyLog
--- PASS: TestEmptyLog (0.00s)
PASS
ok  	example.com/hits/internal/tui	0.003s
ana@vm:~/tea-hits$ go test ./...
ok  	example.com/hits	0.006s
?   	example.com/hits/internal/tally	[no test files]
ok  	example.com/hits/internal/tui	0.008s
?   	example.com/hits/tools/genlog	[no test files]
```

**Four tests of a full-screen program ran in milliseconds, and no terminal was opened.** It is
lesson 1's trick, `run` with its streams passed in, in another shape, and `go test ./...` runs
lesson 1's `TestRun` beside them unchanged: the loop that needs a terminal belongs to the library,
and everything that decides what appears is ordinary code. The two failures in `TestBadLine` and
`TestEmptyLog` are the ones worth writing first, because neither shows up when you try the program
by hand on a good log.

What these tests cannot see is the terminal itself. They check the text `View` returned, not the
escape sequences Bubble Tea turned it into, and they feed messages in an order the test chose, while
a real terminal sends its replies and its sizes in its own order. A screen like section 02's is how
that half gets checked: on a real terminal, by eye.

## When the screen is the wrong tool

A full-screen program is built for one reader: a person with eyes on a terminal. **Everybody else is
better served by `hits top`**, and `hits browse` says so instead of trying:

```
ana@vm:~/tea-hits$ ./hits browse access.log | head -3; echo ${PIPESTATUS[@]}
hits: browse draws on a terminal, and standard output is not one; use hits top
2 0
ana@vm:~/tea-hits$ ./hits browse access.log > /dev/null; echo $?
hits: browse draws on a terminal, and standard output is not one; use hits top
2
ana@vm:~/tea-hits$ stat -c "%F  %n" /dev/null
character special file  /dev/null
ana@vm:~/tea-hits$ ./hits top -n 3 access.log | cat
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
```

The refusal comes before Bubble Tea is started, and it is needed, because **Bubble Tea itself does
not refuse**. When its output is not a terminal it skips the setup it would do to one and starts
anyway. To see what that costs, delete the first `if` block of `browse` and the `golang.org/x/term`
import, and build the result as `hits-raw`. Then run `./hits-raw browse access.log > screen.out` on
a terminal and press `q`:

```
ana@vm:~/tea-hits$ wc -c screen.out
108 screen.out
ana@vm:~/tea-hits$ grep -c login screen.out
0
ana@vm:~/tea-hits$ od -c screen.out | head -4
0000000 033   [   ?   2   0   2   6   $   p 033   [   ?   2   0   2   7
0000020   $   p 033   [   >   4   m 033   [   ?   1   0   4   9   h 033
0000040   [   ?   2   5   l 033   [   ?   5   W 033   [   ?   2   0   0
0000060   4   h 033   [   >   4   ;   2   m 033   [   >   1   u 033   [
```

108 bytes reached the file, and not one of them is a path. They are escape sequences, the
questions Bubble Tea asks a terminal and the switches it flips on the way in and out, written into a
file nobody will ever display. A script reading that output would get no data and no error.

The check is `term.IsTerminal`, from `golang.org/x/term`, which asks the operating system whether
the descriptor is a terminal. A shorter test is often suggested: `os.Stdout.Stat()` and a look for
`os.ModeCharDevice`. The second command of the session shows why it is not enough. **`/dev/null` is
a character device too**, so `hits browse access.log > /dev/null` would pass it and start a screen
nobody could see, waiting for a key.

Three kinds of reader are on the far side of that check:

| reader | what a full-screen program gives it | what `hits top` gives it |
|---|---|---|
| a script, a pipe, a cron job | escape sequences, or an error when there is no terminal to read keys from | lines of text and an exit code |
| a screen reader | a screen repainted in place, cell by cell | lines in the order they were printed |
| you, ten minutes later | nothing: the alternate screen is erased on exit | the table, still in the terminal's scrollback |

**A screen reader follows text as a program writes it**, and a full-screen program writes cursor
movements and repaints only the cells that changed. What reaches the reader is fragments in no
useful order, and the one fact the screen exists to show, which row is chosen, is a `>` in the first
column. That is why the course keeps `hits top` and never makes `browse` the only way to see the
data. A screen can be an extra for the people it suits; it should not be the only door.

Terminals also differ in what they answer. The two `ModeReportMsg` lines of section 04 were one
terminal's replies, and another terminal replies differently or not at all. The replies change what
Bubble Tea does next: a `2` for mode 2026 would have switched on drawing whole frames at once, and
the `0` this terminal sent left it off. None of that is behaviour a test in this section ever saw,
and the fewer such replies a program depends on, the fewer surprises it has on somebody else's
machine.

So the rule this course follows: **a command that produces data prints it, and a screen is added for
browsing what a person would otherwise scroll through.** `hits` has both, the screen checks that it
has a terminal to draw on, and anything that is not a person at a terminal gets lesson 1's plain
table and lesson 1's exit codes.
