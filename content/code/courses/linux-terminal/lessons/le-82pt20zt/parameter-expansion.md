---
title: Parameter expansion, or how to not call `basename`
version: 1
---

`${var}` has a second half: a handful of operators that cut, replace and default a value **without
running a program**. They look cryptic, there are about twelve of them, and four are worth
memorising.

## Cutting paths apart

```
ana@vm:~/work/scripts$ p=/var/log/nginx/access.log.1
ana@vm:~/work/scripts$ echo "${p##*/}"; echo "${p#*/}"
access.log.1
var/log/nginx/access.log.1
ana@vm:~/work/scripts$ echo "${p%/*}"; echo "${p%%.*}"
/var/log/nginx
/var/log/nginx/access
```

Two characters, and the pattern is regular:

| | |
|---|---|
| `#` | remove from the **front** |
| `%` | remove from the **back** |
| doubled | remove the **longest** match instead of the shortest |

So `${p##*/}` is "remove the longest thing ending in a slash" — which is the filename, which is
`basename`. And `${p%/*}` is "remove the shortest thing starting with a slash, from the end" —
which is the directory, which is `dirname`.

```sh
${p##*/}     # basename, without a process
${p%/*}      # dirname,  without a process
```

The hook for remembering which is which: **`#` is to the left of `$` on a keyboard and `%` is to
the right.** It is a silly mnemonic and it works.

The pattern is a glob, not a regular expression — section 45's syntax, the same as `case`.

### Extensions

```
ana@vm:~/work/scripts$ f=report.tar.gz; echo "${f%.tar.gz}"; echo "${f%.*}"
report
report.tar
```

`${f%.*}` removes the shortest match, which is the last extension only. `${f%%.*}` would remove
from the first dot and give `report`. Which one you want depends on whether `.tar.gz` is one
extension or two, and the answer is that it depends on the file — which is why naming the exact
suffix, as in the first example, is the version that cannot surprise you.

## Defaults and requirements

```
ana@vm:~/work/scripts$ unset v; echo "[${v:-default}] v is still [${v-unset}]"
[default] v is still [unset]
ana@vm:~/work/scripts$ unset v; echo "[${v:=assigned}] v is now [$v]"
[assigned] v is now [assigned]
ana@vm:~/work/scripts$ unset v; echo "${v:?the script needs v}"
bash: v: the script needs v
```

| | |
|---|---|
| `${v:-x}` | use `x` if `v` is unset or empty. **`v` is unchanged** |
| `${v:=x}` | use `x` and **assign it to `v`** |
| `${v:?msg}` | print `msg` to stderr and exit, if `v` is unset or empty |
| `${v:+x}` | use `x` only if `v` **is** set. Otherwise nothing |

`:-` is the everyday one — `rows="${2:-5}"`, `"${LOG_LEVEL:-info}"`.

**`:?` is the one that saves you from section 141's empty path.** Under `set -u` an unset variable
already errors; `:?` adds your own message and also catches the variable that is set but empty,
which `-u` does not.

`:+` is the rarest and is genuinely useful for building an optional flag:

```
ana@vm:~/work/scripts$ unset T; echo "[${T:+-H \"auth $T\"}]"
[]
ana@vm:~/work/scripts$ T=abc; echo "[${T:+-H \"auth $T\"}]"
[-H "auth abc"]
```

Nothing at all when the variable is unset, the whole flag when it is set — which is how
`curl ${TOKEN:+-H "Authorization: Bearer $TOKEN"} "$url"` sends the header only when there is a
token.

And remember the colon from section 140: without it, the test is only "unset", and an empty string
counts as a value.

```
ana@vm:~/work/scripts$ v=; echo "[${v:?needs a value}]"
bash: v: needs a value
ana@vm:~/work/scripts$ v=; echo "[${v?needs a value}]"
[]
```

Same variable, same message, one character of difference, and the second one let an empty string
through. **Write the colon.**

## Replacing

```
ana@vm:~/work/scripts$ echo "${p/log/LOG}"; echo "${p//log/LOG}"
/var/LOG/nginx/access.log.1
/var/LOG/nginx/access.LOG.1
```

**One slash replaces the first occurrence, two slashes replace all** — the same distinction as
`sed`'s `g` flag in section 131, and the same order of surprise.

```
ana@vm:~/work/scripts$ echo "[${p//log/}]"; s=logfile; echo "[${s/#log/X}] [${s/%file/Y}]"
[/var//nginx/access..1]
[Xfile] [logY]
```

**Omit the replacement entirely and it deletes** — look at the double slash and the double dot
where the text was removed. `/#` anchors the pattern to the front and `/%` to the back, which is
how you replace a prefix without touching the same letters elsewhere in the string.

For anything more than this, `sed` is the right tool. For exactly this, parameter expansion is
faster, has no quoting problems and does not fork.

## Length, slicing, case

```
ana@vm:~/work/scripts$ echo "${#p}"
27
ana@vm:~/work/scripts$ echo "${p:5}"; echo "${p:5:3}"
log/nginx/access.log.1
log
ana@vm:~/work/scripts$ name=ana; echo "${name^^} ${name^}"
ANA Ana
ana@vm:~/work/scripts$ shout=ANA; echo "${shout,,}"
ana
```

| | |
|---|---|
| `${#v}` | length in characters |
| `${v:n}` | from offset `n` to the end. **Offsets start at zero** |
| `${v:n:m}` | `m` characters from offset `n` |
| `${v^^}` `${v,,}` | upper case, lower case. `^` and `,` do the first character only |

`${v^^}` and `${v,,}` are bash 4, and they are the reason not to pipe a variable through `tr` for
something this small.

## Why bother

Every one of these avoids starting a process:

```sh
name=$(basename "$path")     # forks
name=${path##*/}             # does not

lower=$(echo "$x" | tr A-Z a-z)   # forks twice
lower=${x,,}                      # does not
```

On one line it makes no measurable difference. **In a loop over ten thousand files it is the
difference between a second and half a minute**, and it is the most common reason a shell script is
described as slow when the slowness is entirely self-inflicted.

There is a second reason, and it is the better one: `${path##*/}` cannot go wrong on a filename
with a space, a newline or a leading dash in it, and `$(basename $path)` can.

## The four to remember

```sh
${v:-default}     # a fallback
${v:?message}     # a requirement
${p##*/}          # the filename
${p%/*}           # the directory
```

The rest you will look up, and the fact that they exist is the part worth carrying.
