---
title: Completion with the Tab key
version: 1
---

Pressing Tab after `./hits t` and getting `top` looks like something the shell knows about `hits`.
It knows nothing. **Completion is a conversation in two halves: a script in the shell that runs
when Tab is pressed, and the program itself, which the script asks what to offer.** Cobra writes
both. The script comes from the `completion` command it added to the tree, and the answers come from
a hidden command, `__complete`, that reads the same tree `hits` runs from. A subcommand or a flag
added tomorrow completes tomorrow, with nothing to regenerate.

## The shell's half

```
ana@vm:~/cobra-hits$ ./hits completion bash | wc -l
426
ana@vm:~/cobra-hits$ ./hits completion bash | grep -n "requestComp=\|complete -o"
26:    requestComp="${words[0]} __complete ${args[*]}"
36:        requestComp="${requestComp} ''"
421:    complete -o default -F __start_hits hits
423:    complete -o default -o nospace -F __start_hits hits
```

**426 lines of bash, and two of them carry the idea.** Line 421 is bash's own `complete` builtin
registering the function `__start_hits` for the command `hits` (423 is the fallback for a bash without the
`compopt` builtin). Line 26 is what that function runs on every Tab: the command as typed,
`__complete`, and the words so far. `completion` writes scripts for zsh, fish and PowerShell as
well, from the same tree; only the bash one was run for this lesson.

The script uses functions from the `bash-completion` package, as `./hits completion bash --help`
says. Ubuntu's default `~/.bashrc` loads that package when it is installed, and on the lab machine
it was installed with `sudo apt install bash-completion`. Then one line loads the script into the
shell you are typing in:

```sh
source <(./hits completion bash)
```

To have it in every new shell, save the output where the package looks for it: it reads
`~/.local/share/bash-completion/completions/hits` the first time you complete a command called
`hits`, or `/etc/bash_completion.d/hits` for everybody on the machine.

## The program's half

`__complete` is an ordinary command that does not appear in the help. **You can call it yourself
and see exactly what Tab would be told**, which is the fastest way to debug a completion:

```
ana@vm:~/cobra-hits$ ./hits __complete ""
completion	Generate the autocompletion script for the specified shell
count	Requests per status code
help	Help about any command
top	The paths with the most requests
:4
Completion ended with directive: ShellCompDirectiveNoFileComp
ana@vm:~/cobra-hits$ ./hits __complete t
top	The paths with the most requests
:4
Completion ended with directive: ShellCompDirectiveNoFileComp
ana@vm:~/cobra-hits$ ./hits __complete t 2>/dev/null
top	The paths with the most requests
:4
```

The answer has three parts. Each candidate is a line, with its description after a tab; the
descriptions are the `Short` of each command. **A line starting with a colon is the directive**, a
number telling the script what to do besides offering the candidates. And the last line, for a
person reading, went to standard error, which the third command threw away: the script reads only
standard output. An empty word, `""`, asks what can follow `hits` at all; `t` asks what begins with
`t`, and only `top` does.

The directive is a set of bits, and two of them matter to `hits`:

| directive | value | the script then |
|---|---|---|
| `ShellCompDirectiveNoFileComp` | 4 | offers the candidates and nothing else, not even file names |
| `ShellCompDirectiveFilterFileExt` | 8 | treats the candidates as file extensions and offers matching files |

## What `logFiles` answers

The file argument of `count` and `top` has no fixed list of values, so each command names a
function in `ValidArgsFunction`. Cobra calls it with the arguments already typed and the word being
completed, and `logFiles` answers in two ways:

```
ana@vm:~/cobra-hits$ ./hits __complete top --
--json	print JSON instead of a table
--help	help for top
--number	how many paths to show
:4
Completion ended with directive: ShellCompDirectiveNoFileComp
ana@vm:~/cobra-hits$ ./hits __complete top ""
log
:8
Completion ended with directive: ShellCompDirectiveFilterFileExt
ana@vm:~/cobra-hits$ ./hits __complete top access.log ""
:4
Completion ended with directive: ShellCompDirectiveNoFileComp
ana@vm:~/cobra-hits$ ls -p
access.log
go.mod
go.sum
hits
internal/
main.go
main_test.go
notes.txt
old/
tools/
```

The first needed no code: a word starting with `--` is completed from the flags, local and inherited,
straight from the tree. In the second, nothing is typed yet after `top`, so `logFiles` returns the
extension `log` with directive 8, and **the filtering happens in the shell**: the program never
lists the directory. In the third a file is already named, and `cobra.MaximumNArgs(1)` would refuse
a second, so `logFiles` returns nothing with directive 4, and Tab offers nothing at all. Without
that first `if`, Tab would go on offering log files that the command would reject.

A command whose arguments are a fixed set of words would not need a function: `ValidArgs`, a
`[]string` on the command, is completed the same way. The directory above has an empty `notes.txt`
and an `old/` holding `jan.log`, placed there to see what the filter keeps. Here is the conversation
from the shell's side, in a real bash after `source`:

```schooling-figure
{"caption": "A real bash session in ~/cobra-hits, captured from a terminal after the Tab presses: the generated script asked ./hits __complete each time, and bash drew the answer.", "svg": "<svg viewBox=\"0 0 614 242\" role=\"img\" aria-label=\"A real bash session in ~/cobra-hits. After source &lt;(./hits completion bash), Tab pressed twice after ./hits lists completion, count, help and top, each with its short description. Typing t and Tab completes the word to top. Tab pressed twice after ./hits top lists access.log, internal/, old/ and tools/: the one .log file and the directories, while go.mod, main.go and notes.txt are left out.\"><rect x=\"26\" y=\"0\" width=\"588\" height=\"168\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"264.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">ana@vm:~/cobra-hits$ source &lt;(./hits completion bash)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">ana@vm:~/cobra-hits$ ./hits</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">completion  (Generate the autocompletion script for the specified shell)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">count       (Requests per status code)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">help        (Help about any command)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">top         (The paths with the most requests)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">ana@vm:~/cobra-hits$ ./hits top</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">access.log  internal/   old/        tools/</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">ana@vm:~/cobra-hits$ ./hits top </tspan><tspan fill=\"#0a0e14\"> </tspan></text></g><text x=\"13.00\" y=\"41.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"13.00\" y=\"118.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"13.00\" y=\"134.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"13.00\" y=\"205.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"30.00\" y=\"205.50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tab twice after ./hits: the four commands, each with its Short</text><text x=\"13.00\" y=\"221.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"30.00\" y=\"221.50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">t and one Tab: the only command starting with t, written in full</text><text x=\"13.00\" y=\"237.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"30.00\" y=\"237.50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tab twice after top: access.log and the directories; notes.txt and main.go are not offered</text></svg>"}
```


`access.log` is offered and `notes.txt`, `main.go` and `go.mod` are not, which is the extension at
work. **The directories are offered as well**, because the script's file filter keeps them, so Tab
can still walk into `old/` and find `jan.log`. The completion was registered for the name `hits`,
and the screen shows bash using it for `./hits` too. That covers the third item on lesson 1's list,
and with it the whole list: a suggestion for `cont`, help for each command, and Tab, in 163 lines of
`hits` and none of them a parser.
