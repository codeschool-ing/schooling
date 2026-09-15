---
title: `case`, and the option parser every script ends up with
version: 1
---

`case` matches one value against a list of patterns and runs the first that matches. It is what a
chain of six `elif`s wanted to be.

```
ana@vm:~/work/scripts$ cat kindof.sh
#!/bin/bash
case "$1" in
  *.log)          echo "a log file" ;;
  *.tar.gz|*.tgz) echo "a compressed tarball" ;;
  *.txt|*.md)     echo "text" ;;
  "")             echo "you gave me nothing" ;;
  *)              echo "no idea what $1 is" ;;
esac
ana@vm:~/work/scripts$ ./kindof.sh access.log; ./kindof.sh backup.tar.gz; ./kindof.sh notes.md
a log file
a compressed tarball
text
ana@vm:~/work/scripts$ ./kindof.sh; ./kindof.sh mystery.bin
you gave me nothing
no idea what mystery.bin is
```

The shape:

| | |
|---|---|
| `case "$x" in` | the value, quoted |
| `pattern)` | a **glob**, not a regular expression — section 45's syntax |
| `a\|b)` | alternatives, with `\|` |
| `;;` | end of this branch. Easy to forget, and a syntax error when you do |
| `*)` | the catch-all. Put it last; it matches everything |
| `esac` | `case` backwards, like `fi` |

**`*)` is not required and you should write it anyway.** Without it, an unmatched value falls
through silently and the script does nothing — which looks exactly like success.

Two details:

**The patterns are globs.** `*.log` matches, `[0-9]*` matches, `report?.txt` matches. `.*` does
not mean what it means in a regular expression; it matches a literal dot followed by anything.

**The first match wins and nothing falls through.** There is no C-style fallthrough — `;;` ends the
branch completely. (Bash has `;&` and `;;&` for falling through, and in twenty years you will not
need them.)

## The one thing everybody writes with it

Every script that takes options ends up with this loop. It is `while` from section 147, `shift`
from section 142, and `case`:

```
ana@vm:~/work/scripts$ cat deploy.sh
#!/bin/bash
verbose=0
env=staging
while [ "$#" -gt 0 ]; do
  case "$1" in
    -v|--verbose) verbose=1 ;;
    -e|--env)     env="$2"; shift ;;
    --env=*)      env="${1#*=}" ;;
    -h|--help)    echo "usage: deploy.sh [-v] [-e ENV] TARGET"; exit 0 ;;
    -*)           echo "unknown option: $1" >&2; exit 2 ;;
    *)            target="$1" ;;
  esac
  shift
done
echo "target=${target:-none} env=$env verbose=$verbose"
```

Sixteen lines, and it handles every convention a command-line tool is expected to handle:

```
ana@vm:~/work/scripts$ ./deploy.sh web01
target=web01 env=staging verbose=0
ana@vm:~/work/scripts$ ./deploy.sh -v --env production web01
target=web01 env=production verbose=1
ana@vm:~/work/scripts$ ./deploy.sh --env=qa web02
target=web02 env=qa verbose=0
ana@vm:~/work/scripts$ ./deploy.sh --wat; echo "exit $?"
unknown option: --wat
exit 2
ana@vm:~/work/scripts$ ./deploy.sh --help
usage: deploy.sh [-v] [-e ENV] TARGET
```

Read it branch by branch, because each line is a decision worth copying:

| | |
|---|---|
| `-v\|--verbose` | short and long spellings of a flag, one branch |
| `-e\|--env` | takes a value: use `$2`, then `shift` **an extra time** for it |
| `--env=*` | the `--opt=value` spelling. `${1#*=}` is "everything after the first `=`" |
| `-h\|--help` | prints usage and exits **zero** — asking for help is not an error |
| `-*)` | **anything else starting with a dash is a mistake.** Say so, on stderr, exit non-zero |
| `*)` | not an option, so it is a positional argument |

The branch that gets left out of hand-written parsers is `-*)`, and it is the one that matters.
Here is the same loop without it, given a typo:

```
ana@vm:~/work/scripts$ ./nodash.sh --verbsoe web01
target=web01 verbose=0
ana@vm:~/work/scripts$ ./deploy.sh --verbsoe web01; echo "exit $?"
unknown option: --verbsoe
exit 2
```

**`--verbsoe` fell into `*)`, was assigned to `target`, and was then overwritten by `web01`.** The
script ran, said nothing, and did the job without the flag you asked for. Four characters in the
`case` turn that into an error with an exit status.

## Where this stops being enough

This loop does not handle bundled short flags — `-vf` is not the same as `-v -f` to it — and it
does not handle `--` as an end-of-options marker.

`getopts` is the builtin that does the first properly:

```sh
while getopts ":vt:n:" opt; do
  case "$opt" in
    v) verbose=1 ;;
    t) threshold="$OPTARG" ;;
    n) rows="$OPTARG" ;;
    \?) echo "unknown option: -$OPTARG" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
```

```
ana@vm:~/work/scripts$ ./getopts.sh -v -t 3000 -n 3 access.log
verbose=1 threshold=3000 rows=3 rest=access.log
ana@vm:~/work/scripts$ ./getopts.sh -vt3000 access.log
verbose=1 threshold=3000 rows=5 rest=access.log
ana@vm:~/work/scripts$ ./getopts.sh -z access.log; echo "exit $?"
unknown option: -z
exit 2
ana@vm:~/work/scripts$ ./getopts.sh --verbose access.log; echo "exit $?"
unknown option: --
exit 2
```

`-vt3000` bundled correctly, which the hand-written loop cannot do. `shift $((OPTIND - 1))` at the
end drops everything `getopts` consumed and leaves the positional arguments in `$@`.

**And `--verbose` was read as `-` followed by `-verbose`.** `getopts` handles short options only;
it has no idea what a long option is, and the error message it produces for one is confusing. That
is the trade, and it is why most real scripts use the hand-written `case` loop above: long options
are worth more than bundling.

If you need both, properly, you have reached the point where the script wants to be a program in
something else — which is the argument the closing video makes about bash in general.
