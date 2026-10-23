---
title: process.env
version: 1
---

**Every process starts with a list of names and values from whoever started it, the environment, and
Node gives it to you as `process.env`.** Your shell has one, and every program it starts inherits a
copy. It is the oldest way to tell a program something without changing its code, and on servers it is
still the main one.

```
ana@dev:~/server/links$ node -p 'process.env.HOME'
/home/ana
ana@dev:~/server/links$ PORT=4000 node -p 'process.env.PORT'
4000
ana@dev:~/server/links$ echo "the shell: [$PORT]"
the shell: []
ana@dev:~/server/links$ node -p 'process.env.NOTHING'
undefined
ana@dev:~/server/links$ EMPTY= node -p 'JSON.stringify(process.env.EMPTY)'
""
ana@dev:~/server/links$ DEBUG=false node -p 'process.env.DEBUG ? "truthy" : "falsy"'
truthy
ana@dev:~/server/links$ export REGION=sa-east
ana@dev:~/server/links$ node -p 'process.env.REGION'
sa-east
```

The lines in that transcript show the four facts that matter:

- **A name set before the command is in that program's environment only**: `PORT=4000 node …` does
  not change the shell's own.
- **A name nobody set is `undefined`**, and a name set to nothing is `""`. The two are different, and
  a program has to decide what each one means.
- **Every value is a string.** `DEBUG=false` arrives as the five letters `"false"`, which is truthy, so
  `if (process.env.DEBUG)` is true. The section on parsing configuration turns strings into the types
  the program needs, once.
- **`export` puts a name in the shell's environment**, so every program started from that shell after
  it sees it, until the shell closes.

A process can change its own `process.env`, and its children inherit the change, but nothing it does
reaches the shell that started it: the environment is copied downwards, never back up.
