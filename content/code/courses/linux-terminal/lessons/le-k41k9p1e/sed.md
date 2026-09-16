---
title: `sed`, and the one command that is ninety per cent of it
version: 1
---

`sed` is a stream editor: it reads lines, applies commands to them, and prints the result. It has a
whole language and you will use one command out of it.

## `s`, substitute

```
ana@vm:~/work$ echo "the cat sat on the mat" | sed "s/cat/dog/"
the dog sat on the mat
```

The shape is `s/what/with/flags`, and there are two flags worth knowing.

**`g` is not the default**, which is the first surprise:

```
ana@vm:~/work$ echo "the cat sat on the cat" | sed "s/cat/dog/"
the dog sat on the cat
ana@vm:~/work$ echo "the cat sat on the cat" | sed "s/cat/dog/g"
the dog sat on the dog
```

**Without `g`, `sed` replaces the first match on each line.** That is occasionally what you want and
usually not, and it is a bug that only shows up on lines where the thing appears twice.

`i` is the other one: `s/cat/dog/gi` ignores case.

## The separator is whatever you type

```
ana@vm:~/work$ echo "a/b/c" | sed "s|/|-|g"
a-b-c
```

**`s|…|…|` and `s#…#…#` work exactly like `s/…/…/`.** The character immediately after the `s` is the
separator for that command.

This matters constantly, because the things you replace most often are paths, and a path full of
slashes inside an `s/…/…/` needs every one of them escaped. `s|/usr/local|/opt|` is readable;
`s/\/usr\/local/\/opt/` is the same thing and nobody can check it by eye.

## Addresses: which lines

Put something in front of the command and it applies to those lines only:

```
ana@vm:~/work$ sed -n "3p" logs/app.log
app handled a request
ana@vm:~/work$ sed -n "2,4p" logs/app.log
app ready
app handled a request
app started
```

**`-n` turns off the automatic printing**, so `-n` with `p` means "print only these". Without `-n`,
`sed "3p"` prints every line and line three twice.

| | |
|---|---|
| `3` | line 3 |
| `2,4` | lines 2 to 4 |
| `$` | the last line |
| `/pattern/` | every line matching |
| `2,$` | from line 2 to the end |

```
ana@vm:~/work$ sed "1d" data/sales.csv | head -2
north,ana,Q1,171,8721
north,bruno,Q1,49,4116
```

**`1d` deletes the first line**, which is the header-dropping idiom alongside section 05's
`tail -n +2`. Either is fine; `sed 1d` is shorter and `tail -n +2` is faster on a large file.

```
ana@vm:~/work$ sed -n "/error/p" logs/app.log
```

Nothing, because that file has no line containing `error` — and `sed -n /pattern/p` is `grep`, more
slowly. **Use `grep` to find and `sed` to change.**

## Changing every line

```
ana@vm:~/work$ sed "s/^/> /" logs/app.log | head -2
> app started
> app ready
```

`^` matches the start of a line and is zero characters wide, so substituting it **inserts**. `s/$/;/`
appends. Those two are how you add a prefix or a suffix to every line of something.

A real one, turning addresses into networks:

```
ana@vm:~/work$ cut -d" " -f1 logs/access.log | sed "s/\.[0-9]*$/.0\/24/" | sort -u | head -4
10.0.1.0/24
198.51.100.0/24
203.0.113.0/24
```

"Replace a dot and the digits at the end of the line with `.0/24`." Twelve hundred addresses become
three networks. Note the `\/` — the replacement contains a slash and the separator is a slash, so it
had to be escaped. `s|\.[0-9]*$|.0/24|` avoids that.

## In place

```
ana@vm:~/work$ cp logs/app.log /tmp/edit.log
ana@vm:~/work$ sed -i "s/app/service/g" /tmp/edit.log
ana@vm:~/work$ head -3 /tmp/edit.log
service started
service ready
service handled a request
```

**`-i` edits the file rather than printing to stdout**, and it is the answer to section 03's
`sort file > file` problem.

It is also the flag to be careful with, because there is no undo. `-i.bak` keeps a copy:

```
ana@vm:~/work$ cp logs/app.log /tmp/edit2.log
ana@vm:~/work$ sed -i.bak "s/app/service/g" /tmp/edit2.log
ana@vm:~/work$ ls /tmp/edit2*
/tmp/edit2.log  /tmp/edit2.log.bak
```

**The habit worth forming: run it without `-i` first.** `sed 's/…/…/g' file | head` shows you what
it would do, costs nothing, and catches the pattern that matched more than you meant.

And a portability note that bites: **BSD `sed` on macOS requires an argument to `-i`**, so
`sed -i '' 's/…/…/' file` there and `sed -i 's/…/…/' file` on Linux. A script with `-i` in it is not
portable between the two without care.

## The rest of `sed`

`sed` has branches, labels, a hold space and multi-line commands. It is a complete language and
people have written surprising programs in it.

**You do not need any of it.** When a `sed` command needs a second line, the answer is `awk`, and
when the `awk` needs a second variable the answer is a script. The `sed` you will write for the rest
of your career is:

```
sed 's/old/new/g'                   # substitute
sed -n '5,10p'                      # print a range
sed '1d'                            # drop a line
sed -i.bak 's|/old/path|/new|g'     # edit files in place, with a backup
```

Four commands, and the last one is the one worth checking twice before you run it.
