---
title: Commands, for the work that takes time
version: 1
---

The tempting place to read the log is `Init` or `Update` itself: open the file, count it, store the
rows. It compiles and it even works on a small file, but **the loop calls `View` only after `Update`
returns**, so while a large file is being read the terminal shows nothing and every key pressed
waits in a queue. `Update` must return quickly, every time. Work that takes as long as it takes goes
in a command.

**A `tea.Cmd` is a function, `func() tea.Msg`. The program runs it in a goroutine of its own, and
whatever it returns is delivered to `Update` as the next message.** `go doc` describes it as "an IO
operation that returns a message when it's complete". In Bubble Tea's source, each command `Update`
returns is started with `go func()` and its result sent back into the loop, so the screen keeps
answering keys while the command runs.

`internal/tui/load.go` holds `Init` and the count:

```schooling-example
{
  "language": "go",
  "file": "internal/tui/load.go",
  "parts": [
    {
      "code": "package tui\n\nimport (\n\t\"bufio\"\n\t\"fmt\"\n\t\"io\"\n\n\ttea \"charm.land/bubbletea/v2\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "The third file of the package, and the one that touches the outside world: it imports lesson 1's `tally` for `Parse` and `Top`."
    },
    {
      "code": "// loaded is the message the count sends when it has finished.\ntype loaded struct {\n\trows []row\n\terr  error\n}\n",
      "note": "**A message type of the program's own**, unexported, because nothing outside the package sends it. It carries the rows or the error, and `Update` copies both into the model."
    },
    {
      "code": "// Init starts the count. The program runs the command it returns in a\n// goroutine of its own, and hands its result to Update.\nfunc (m Model) Init() tea.Cmd {\n\treturn count(m.in)\n}\n",
      "note": "**`Init` does not read the file; it returns the function that will.** The program calls `Init` once, before the first screen, and runs the command in a goroutine of its own."
    },
    {
      "code": "// count reads the whole log and tallies each path's statuses.\nfunc count(r io.Reader) tea.Cmd {\n\treturn func() tea.Msg {",
      "note": "`count` builds the command: a closure over the reader that returns a `tea.Msg` when it is done. Nothing in it touches the model or the screen."
    },
    {
      "code": "\t\tbyPath := map[string]map[int]int{}\n\t\thits := map[string]int{}\n\t\tsc := bufio.NewScanner(r)\n\t\tfor n := 1; sc.Scan(); n++ {\n\t\t\te, err := tally.Parse(sc.Text())\n\t\t\tif err != nil {\n\t\t\t\treturn loaded{err: fmt.Errorf(\"line %d: %w\", n, err)}\n\t\t\t}\n\t\t\tif byPath[e.Path] == nil {\n\t\t\t\tbyPath[e.Path] = map[int]int{}\n\t\t\t}\n\t\t\tbyPath[e.Path][e.Status]++\n\t\t\thits[e.Path]++\n\t\t}\n\t\tif err := sc.Err(); err != nil {\n\t\t\treturn loaded{err: err}\n\t\t}",
      "note": "The same reading loop as lesson 1's `tally.Count`, keeping one map of statuses per path. A line that will not parse ends the count, and the message carries the error with the line's number."
    },
    {
      "code": "\t\trows := make([]row, 0, len(hits))\n\t\tfor _, pc := range tally.Top(tally.Summary{ByPath: hits}, len(hits)) {\n\t\t\trows = append(rows, row{pc.Path, pc.Hits, byPath[pc.Path]})\n\t\t}\n\t\treturn loaded{rows: rows}\n\t}\n}",
      "note": "`tally.Top` sorts the paths the way `hits top` does, most requests first and ties alphabetically, so the two commands list the paths in the same order. **`rows` is made empty rather than left `nil`**, so that an empty log draws an empty list instead of `counting` forever."
    }
  ]
}
```

`tea.Quit`, which `Update` returns for `q`, is a command too. It is a function of exactly that type,
returning `tea.QuitMsg`, and when that message comes round the loop the program stops and `Run`
returns. **A command is the only way a model asks for anything**: reading, waiting, quitting. It
never does the thing itself.

## Wiring it into `hits`

The subcommand is a new file in package `main`, `browse.go`:

```schooling-example
{
  "language": "go",
  "file": "browse.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\n\ttea \"charm.land/bubbletea/v2\"\n\t\"golang.org/x/term\"\n\n\t\"example.com/hits/internal/tui\"\n)\n",
      "note": "A new file beside `main.go`, in package `main`. It imports Bubble Tea, `golang.org/x/term` and the `tui` package."
    },
    {
      "code": "// browse runs the interactive screen. It needs a terminal on standard\n// output; a script, a pipe and a screen reader are sent to hits top.\nfunc browse(args []string, stdout, stderr io.Writer) int {\n\tif f, ok := stdout.(*os.File); !ok || !term.IsTerminal(int(f.Fd())) {\n\t\tfmt.Fprintln(stderr, \"hits: browse draws on a terminal, and standard output is not one; use hits top\")\n\t\treturn 2\n\t}",
      "note": "**The first thing `browse` checks is that standard output is a terminal**, and section 05 says why the check is `term.IsTerminal` and not something simpler. A pipe, a file or a test's buffer is refused with status 2 and pointed at `hits top`."
    },
    {
      "code": "\tif len(args) != 1 {\n\t\tfmt.Fprintf(stderr, \"hits: browse wants one file, got %d\\n\", len(args))\n\t\treturn 2\n\t}\n\tf, err := os.Open(args[0])\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\tdefer f.Close()\n",
      "note": "One file, opened before the screen appears, so a missing file is an ordinary message on an ordinary terminal. Standard input is not offered: in a terminal it is the keyboard, and Bubble Tea reads its keys there."
    },
    {
      "code": "\tvar opts []tea.ProgramOption\n\tif path := os.Getenv(\"HITS_DEBUG\"); path != \"\" {\n\t\tw, err := os.Create(path)\n\t\tif err != nil {\n\t\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\t\treturn 1\n\t\t}\n\t\tdefer w.Close()\n\t\topts = append(opts, tea.WithFilter(func(_ tea.Model, msg tea.Msg) tea.Msg {\n\t\t\tline := fmt.Sprintf(\"%T %v\", msg, msg)\n\t\t\tfmt.Fprintln(w, line[:min(len(line), 72)])\n\t\t\treturn msg\n\t\t}))\n\t}\n",
      "note": "A switch for watching the program work. With `HITS_DEBUG` set, `tea.WithFilter` sees every message before `Update` does and writes its type and value, cut to 72 characters, to that file. The filter returns the message unchanged, so the program behaves the same with it or without."
    },
    {
      "code": "\tfinal, err := tea.NewProgram(tui.New(args[0], f), opts...).Run()\n\tif err == nil {\n\t\terr = final.(tui.Model).Err()\n\t}\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}",
      "note": "**`Run` takes the terminal, runs the loop and hands back the last model when the loop ends.** An error from Bubble Tea itself, or one the model kept, is printed now, after the alternate screen has gone and the shell's lines are back."
    }
  ]
}
```

`main.go` gains one case and two lines of usage. Here it is whole, because a file the lesson changes
is printed whole; only the parts with a note differ from lesson 1:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"errors\"\n\t\"flag\"\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"os\"\n\t\"slices\"\n\t\"text/tabwriter\"\n\n\t\"example.com/hits/internal/tally\"\n)\n\nconst usage = `usage: hits <command> [flags] [file]\n\ncommands:\n  count   requests per status code\n  top     the paths with the most requests\n  browse  the same paths on an interactive screen; needs a terminal\n\nWith no file, or with -, count and top read standard input.\n`\n",
      "note": "**Two lines differ from lesson 1 here**: the usage names `browse`, and the last line says which commands read standard input, since `browse` does not."
    },
    {
      "code": "func main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n\nfunc run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tif len(args) == 0 {\n\t\tfmt.Fprint(stderr, usage)\n\t\treturn 2\n\t}\n\tswitch args[0] {\n\tcase \"count\":\n\t\treturn count(args[1:], stdin, stdout, stderr)\n\tcase \"top\":\n\t\treturn top(args[1:], stdin, stdout, stderr)\n\tcase \"browse\":\n\t\treturn browse(args[1:], stdout, stderr)\n\tcase \"help\", \"-h\", \"-help\", \"--help\":\n\t\tfmt.Fprint(stdout, usage)\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stderr, \"hits: unknown command %q\\n\\n%s\", args[0], usage)\n\treturn 2\n}\n",
      "note": "One new case. `browse` takes no standard input, for the reason in the notes on `browse.go`."
    },
    {
      "code": "func count(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"count\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, s.ByStatus)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"status\\trequests\")\n\tfor _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {\n\t\tfmt.Fprintf(tw, \"%d\\t%d\\n\", status, s.ByStatus[status])\n\t}\n\treturn flush(tw, stderr)\n}\n\nfunc top(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"top\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tn := fs.Int(\"n\", 3, \"how many paths to show\")\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\trows := tally.Top(s, *n)\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, rows)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"path\\trequests\")\n\tfor _, r := range rows {\n\t\tfmt.Fprintf(tw, \"%s\\t%d\\n\", r.Path, r.Hits)\n\t}\n\treturn flush(tw, stderr)\n}\n\n// summarise counts the file named in args, or standard input.\nfunc summarise(args []string, stdin io.Reader, stderr io.Writer) (tally.Summary, int) {\n\tin := stdin\n\tswitch {\n\tcase len(args) > 1:\n\t\tfmt.Fprintf(stderr, \"hits: one file at most, got %d\\n\", len(args))\n\t\treturn tally.Summary{}, 2\n\tcase len(args) == 1 && args[0] != \"-\":\n\t\tf, err := os.Open(args[0])\n\t\tif err != nil {\n\t\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\t\treturn tally.Summary{}, 1\n\t\t}\n\t\tdefer f.Close()\n\t\tin = f\n\t}\n\ts, err := tally.Count(in)\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn s, 1\n\t}\n\treturn s, 0\n}\n\n// flush writes out a table, and encode a value as JSON. A write can fail,\n// on a full disk for one, and that is reported.\nfunc flush(tw *tabwriter.Writer, stderr io.Writer) int {\n\tif err := tw.Flush(); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\nfunc encode(stdout, stderr io.Writer, v any) int {\n\tif err := json.NewEncoder(stdout).Encode(v); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\n// flagError turns a failed parse into an exit code. The flag package has\n// already printed the message and the usage.\nfunc flagError(err error) int {\n\tif errors.Is(err, flag.ErrHelp) {\n\t\treturn 0\n\t}\n\treturn 2\n}",
      "note": "From here to the end, the file is lesson 1 section 03's, unchanged."
    }
  ]
}
```

With all five files in place, the module tidies, builds and lists its new subcommand:

```
ana@vm:~/tea-hits$ go mod tidy
ana@vm:~/tea-hits$ find . -name "*.go" | sort
./browse.go
./internal/tally/tally.go
./internal/tui/load.go
./internal/tui/model.go
./internal/tui/update.go
./main.go
./main_test.go
./tools/genlog/main.go
ana@vm:~/tea-hits$ go build -o hits . && stat -c "%s bytes  %n" hits
6773596 bytes  hits
ana@vm:~/tea-hits$ go list -deps -f "{{if not .Standard}}{{.ImportPath}}{{end}}" . | grep -v ^example.com | grep -c .
19
ana@vm:~/tea-hits$ ./hits
usage: hits <command> [flags] [file]

commands:
  count   requests per status code
  top     the paths with the most requests
  browse  the same paths on an interactive screen; needs a terminal

With no file, or with -, count and top read standard input.
```

**The binary went from lesson 1's 4,031,903 bytes to 6,773,596**, and `go list -deps` counts
19 packages from outside the standard library compiled into it, not counting `hits`'s own:
Bubble Tea and `ultraviolet`, the terminal layer under it, libraries that parse escape sequences and
measure how many columns a character takes, and `golang.org/x/term`. Lesson 2's Cobra cost 1,076,140
bytes for help and completion; a screen costs about two and a half times that.

## Watching the messages arrive

`HITS_DEBUG` writes down every message before `Update` sees it. Here is the file from the run that
drew the first screen of section 02, where `j` was pressed twice and then `q`:

```
ana@vm:~/tea-hits$ cat msgs.log
tea.ColorProfileMsg ANSI256
tea.WindowSizeMsg {72 14}
tea.EnvMsg [HITS_DEBUG=msgs.log PWD=/home/ana/tea-hits TZ=America/Sao_Pa
tui.loaded {[{/login 2576 map[200:967 201:159 204:156 301:147 304:163 40
tea.ModeReportMsg {2026 0}
tea.ModeReportMsg {2027 0}
tea.KeyPressMsg j
tea.KeyPressMsg j
tea.KeyPressMsg q
tea.QuitMsg {}
```

Read it from the top. **`tui.loaded` arrives fourth, after Bubble Tea's own first messages**: the
count ran in its goroutine while the program set itself up, and its result joined the queue like
anything else. The order is not fixed. In another run of the same capture the first two lines came
the other way round, because they too come from different goroutines. The 20,000 lines were counted
too quickly to see, but on a file a thousand times larger the screen would show `counting access.log
...` and answer `q` the whole time.

The other messages are Bubble Tea telling the model about the terminal. `ColorProfileMsg` says how
many colours it can show, and `EnvMsg` carries the environment. The two `ModeReportMsg` lines are
the terminal's answers to two questions Bubble Tea asked about modes `2026` and `2027`: whether it
can draw a whole frame at once, and whether it measures characters the modern Unicode way. The `0`
in each answer means "not recognised". **They arrive whether or not the model wants them**, and
`Update`'s type switch lets them fall through to `return m, nil`. On another terminal those lines
differ, because that terminal answers differently, and section 05 comes back to that.

## The error comes after the screen

A full-screen program owns the terminal until it exits, and on the way out the alternate screen is
switched off, which puts back the shell's lines and erases everything the program drew. So **an
error has to be printed after `Run` returns**, or it vanishes with the screen. That is why `count`
puts its error in a message, `Update` keeps it in the model and quits, and `browse` asks the final
model for `Err`. Three mistakes, typed at a real terminal, with a file of one bad line made first:

```
ana@vm:~/tea-hits$ printf 'oops\n' > bad.log
```

```
ana@vm:~/tea-hits$ ./hits browse; echo $?
hits: browse wants one file, got 0
2
ana@vm:~/tea-hits$ ./hits browse nope.log; echo $?
hits: open nope.log: no such file or directory
1
ana@vm:~/tea-hits$ ./hits browse bad.log; echo $?
hits: line 1: want 5 fields, got 1
^[[?2026;0$y^[[?2027;0$y1
ana@vm:~/tea-hits$ 2026;0$y2027;0$y
```

The first two never start the screen: the file is checked before `Run`, and the messages are
ordinary lines on an ordinary terminal, with lesson 1's codes, 2 for a wrong call and 1 for a failed
run. The third did start it, for an instant: the count found line 1 unreadable, `Update` returned
`tea.Quit`, the alternate screen went away, and only then did `browse` print the line.

**The last two lines are something nobody typed.** `^[[?2026;0$y` and `^[[?2027;0$y` are the
terminal's replies to the same two questions as in `msgs.log`. This run quit before they came back,
so they reached the shell instead: bash echoed them as though they had been typed, in front of the
`1` from `echo`, and what it did not swallow was left waiting on the next prompt. Nothing is broken,
and Ctrl+C clears the line, but a program that quits almost as soon as it starts and leaves residue
on the screen is a fair preview of section 05's argument.
