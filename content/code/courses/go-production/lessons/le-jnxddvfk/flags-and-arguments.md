---
title: Flags, arguments and where values come from
version: 1
---

The flag package of lesson 1 reads flags from the front of the list and stops at the first word that
is not one. **urfave/cli v3 reads the whole list**: a word starting with a dash is a flag wherever it
sits, and the words that are not flags, in their order, are what `cmd.Args()` returns. That one
difference removes the most common surprise of lesson 1 section 03, where `-v` after `jan.log` was
taken for a file name. A flag in v3 is also more than a name and a default, as `top`'s `-n` showed in
section 02, and each of the extra fields is worth running once.

## Anywhere on the line

The file first and the flag after it, and then a second name and the other flag before the file:

```
ana@vm:~/cli-hits$ ./hits top access.log -n 2
path         requests
/login       2576
/api/orders  2542
ana@vm:~/cli-hits$ ./hits top --limit 2 -json access.log
[{"path":"/login","hits":2576},{"path":"/api/orders","hits":2542}]
```

**`-n 2` after the file worked**, which lesson 1's version refuses: there, `-n` and `2` would have
been two more arguments and `summarise` would have complained about three files. `--limit` is the
alias declared in `Aliases`, and the two names set one value. The library accepted `-json` with one
dash even though it prints the name as `--json` in its help, so lesson 1's spelling keeps working;
`--json` works too.

What has not changed is the convention for an argument that starts with a dash, and standard input
as `-`:

```
ana@vm:~/cli-hits$ go run ./tools/genlog -n 1000 -seed 3 | ./hits top -n 2 -
path             requests
/static/app.css  137
/api/users       135
ana@vm:~/cli-hits$ ./hits top -- -n
hits: open -n: no such file or directory
```

`-` is not a flag to anyone, so it reaches `summarise`, which reads standard input as lesson 1's did;
the two paths and their counts are lesson 1 section 05's. **After `--`, nothing is a flag**, so `-n`
became a file name and the open failed. That is the way to hand `hits` a file that really is called
`-n`.

## A value from the environment, and a value that is refused

`Sources: cli.EnvVars("HITS_TOP")` gives `-n` a second place to come from. When the flag is on the
command line it wins; when it is absent, the variable is read; when neither is there, the default
applies:

```
ana@vm:~/cli-hits$ HITS_TOP=4 ./hits top access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
/api/users      2512
ana@vm:~/cli-hits$ HITS_TOP=4 ./hits top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
```

**The order is command line, then environment, then `Value`**, and it is the order you want: a
variable set in a shell profile becomes a personal default, and a flag typed for one run still
overrides it. `EnvVars` takes several names and tries them in turn. v3 also has sources for files,
and `Sources` is a chain precisely so that more than one kind can be listed; this lesson uses only
the environment.

`Validator` is called with the parsed value, after the library has already refused anything that is
not an `int`:

```
ana@vm:~/cli-hits$ ./hits top -n 0 access.log 2>&1 | head -1
Incorrect Usage: invalid value "0" for flag -n: must be at least 1, got 0
```

Lesson 1's `top` had no such check, and `tally.Top` slices its rows with `rows[:min(n, len(rows))]`:
`-n 0` asked for a table with no rows, and a negative `-n` makes that slice expression panic.
**A value the program cannot use is now refused at the door**, with the flag's name in the message.
`Incorrect Usage` is only the first line of what the library printed, and section 04 is about the
rest.

The field next to these two is `Required`. A flag declared with `Required: true` that is missing
from the command line stops the run before the Action, through the same path as a refused value.
Neither of `hits`'s flags needs it, because each has a sensible default, which is the usual reason a
flag is a flag and not an argument.

## The help writes itself

Every field above also ends up in the help, which the library builds from the declarations:

```
ana@vm:~/cli-hits$ ./hits top -h
NAME:
   hits top - the paths with the most requests

USAGE:
   hits top [options] [file]

OPTIONS:
   -n int, --limit int  how many paths to show (default: 3) [$HITS_TOP]
   --json               print JSON instead of a table
   --help, -h           show help
```

**Nothing in `hits` writes this text.** The usage line comes from `ArgsUsage`, the two names of `-n`
from `Aliases`, `int` from the flag's type, the default from `Value` and `[$HITS_TOP]` from
`Sources`. Lesson 1's `usage` constant was written by hand and could drift from the code it
described; this cannot, because it is the code read back. The help prints one dash before a
one-letter name and two before a longer one, the GNU convention, while accepting either spelling.

## A word the library takes for itself

One word is not an argument in v3 even where an argument is expected:

```
ana@vm:~/cli-hits$ ./hits top help | head -2
NAME:
   hits top - the paths with the most requests
```

Every command gets a built-in `help` subcommand, and **`hits top help` asks for `top`'s help**
rather than reading a file called `help`. It is the same rule as `--`: the library claims some words
of the command line, and a file that happens to be named like one of them needs a different
spelling, `./help` here. Lesson 1's dispatch only claimed `help` in first position, because it was
twenty lines of `switch` and did nothing it was not told to.
