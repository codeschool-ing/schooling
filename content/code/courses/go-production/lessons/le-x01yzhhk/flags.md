---
title: Flags that belong to one command, and flags that reach all of them
version: 1
---

`hits` has two flags, and they are declared in two different ways. **A local flag, added with
`Flags()`, belongs to one command; a persistent flag, added with `PersistentFlags()`, belongs to a
command and to every command below it.** `-n` only means something to `top`, so it is local to
`top`. `--json` means the same thing to both subcommands, so it is declared once, on the root, and
inherited. Lesson 1 declared `-json` twice, once in each `FlagSet`, and would have needed a third
copy for a third subcommand.

The flags are parsed by `pflag`, not by the standard library's `flag`, and the two disagree about
syntax. pflag follows the GNU conventions most Linux tools use: a long name takes two dashes,
`--number`, a one-letter shorthand takes one, `-n`, and **flags may appear anywhere among the
arguments**, not only before them.

## A flag after the file name

Lesson 1 section 02 showed the standard library stop reading flags at the first word that is not
one, so `./args jan.log -v` left `-v` as an argument. pflag keeps going:

```
ana@vm:~/cobra-hits$ ./hits top access.log -n 2
path         requests
/login       2576
/api/orders  2542
ana@vm:~/cobra-hits$ ./hits top --number=2 access.log --json
[{"path":"/login","hits":2576},{"path":"/api/orders","hits":2542}]
ana@vm:~/cobra-hits$ ./hits --json count access.log
{"200":7554,"201":1256,"204":1248,"301":1192,"304":1229,"400":1223,"401":1226,"404":2549,"500":1269,"503":1254}
```

The first line is the one that failed in lesson 1: `-n 2` after the file name was read as a flag.
The second uses the long name with `=` and puts `--json` last. In the third, **`--json` comes before
the subcommand** and still reaches `count`, which is what persistent means: Cobra collects the flags
of every command on the path from the root to the one it runs. Everything that is not a flag is
left for the command's arguments, in order, and a bare `-` counts as an argument, so
`./hits top - -n 1` still reads standard input. A `--` still ends the flags, as it did for the
standard library.

## One dash, one letter

The price of the GNU syntax is that a single dash now means a shorthand, and a shorthand is one
letter. Lesson 1's spelling of the JSON flag no longer parses:

```
ana@vm:~/cobra-hits$ ./hits top -json access.log; echo $?
hits: unknown shorthand flag: 'j' in -json
Run 'hits top --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits count -n 2 access.log; echo $?
hits: unknown shorthand flag: 'n' in -n
Run 'hits count --help' for usage.
2
```

**pflag read `-json` as four shorthands, `-j -s -o -n`, and stopped at the first one it did not
know.** That is how `ls -la` works, and it is why the standard library's habit of accepting one dash
for a long name cannot survive the move. A script written against lesson 1's `hits` that says
`-json` breaks here, with exit status 2 and a message, which is the right way for it to break. The
second command is **a local flag in the wrong place**: `-n` is `top`'s, and `count` has never heard of
it.

If a program has to keep the old behaviour, where flags stop at the first argument, **pflag can be
told so with `cmd.Flags().SetInterspersed(false)`**. `hits` does not, because the GNU order is what
people who use Linux tools type.

## Where the help comes from

Each flag was declared with a name, a shorthand, a default and a sentence, and that is all the help
needs:

```
ana@vm:~/cobra-hits$ ./hits top --help
The paths with the most requests

Usage:
  hits top [file] [flags]

Flags:
  -h, --help         help for top
  -n, --number int   how many paths to show (default 3)

Global Flags:
      --json   print JSON instead of a table
```

The first line is `top`'s `Short`, and the usage line is its `Use` with `[flags]` added. **The local
flags and the inherited ones are listed apart**, under `Flags` and `Global Flags`, so a reader can
tell which ones `top` adds. `int` is the type of `-n`, read from `IntVarP`, and `(default 3)` is
printed because 3 is not the zero value; `--json` defaults to `false`, the zero value, and says
nothing. `-h, --help` was added by Cobra to every command without a line of `hits` asking for it.

The whole arrangement fits in one picture:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 292\" role=\"img\" aria-label=\"The command tree of hits. The root command, hits, declares --json as a persistent flag, so every command below it accepts --json too; it also has -h, --help. Its children are count, which takes a file and inherits --json; top, which takes a file, inherits --json and adds its own local flag -n, --number; completion, with bash, fish, powershell and zsh below it, and help, both added by Cobra. A hidden command, __complete, answers the shell when Tab is pressed.\"><rect x=\"230\" y=\"14\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"340\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">hits</text><text x=\"336\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">--json</text><text x=\"344\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">persistent</text><text x=\"340\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-h, --help</text><path d=\"M340 90 L340 112 L95 112 L95 138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M340 90 L340 112 L255 112 L255 138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M340 90 L340 112 L415 112 L415 138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M340 90 L340 112 L575 112 L575 138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"20\" y=\"138\" width=\"150\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"180\" y=\"138\" width=\"150\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"340\" y=\"138\" width=\"150\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"500\" y=\"138\" width=\"150\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">count [file]</text><text x=\"91\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">--json</text><text x=\"99\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inherited</text><text x=\"95\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-h, --help</text><text x=\"255\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">top [file]</text><text x=\"278\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">--json</text><text x=\"286\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inherited</text><text x=\"278\" y=\"202\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">-n, --number</text><text x=\"286\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">local</text><text x=\"415\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">completion</text><text x=\"415\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bash  fish</text><text x=\"415\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">powershell  zsh</text><text x=\"415\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">added by Cobra</text><text x=\"575\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">help [command]</text><text x=\"575\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">added by Cobra</text><path d=\"M340 112 L660 112 L660 262 L650 262\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><rect x=\"340\" y=\"244\" width=\"310\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"446\" y=\"262\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">__complete</text><text x=\"454\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">hidden: what Tab asks (section 05)</text></svg>", "caption": "The tree hits is built from. A flag declared with PersistentFlags on a node reaches every node below it; one declared with Flags belongs to its node alone. Cobra adds help, completion and the hidden __complete to any root that has subcommands."}
```


The tree is also where a flag's reach is decided, so a mistake in it shows up as a flag in the wrong
place rather than as a bug in a command. A flag that every subcommand repeats belongs one level up,
as a persistent flag; a persistent flag that only one subcommand reads belongs one level down, where
it stops appearing in the help of the others.
