---
title: Two module systems, one runtime
version: 1
---

**Node has two module systems, and every `.js` file it loads is one or the other.** javascript
lesson 9 introduced both: **CommonJS**, Node's original, with `require` and `module.exports`, and
**ES modules**, the language's own, with `import` and `export`. That lesson was about what each one
means. This one is about what Node does with them: how it decides which a file is, where it looks
for what you named, and what happens when the two meet.

Two facts from lesson 9 carry this whole lesson:

| | CommonJS | ES modules |
|---|---|---|
| how a module asks | `require("./x")`, a function called while the file runs | `import ... from "./x"`, read before any of the file runs |
| what it receives | a copy of whatever `module.exports` held at that moment | a live view of the exported names |

**The first row is why the two cannot be swapped by search and replace.** A `require` can sit
inside an `if` and run or not; an `import` statement is found and loaded before the first line of
the file executes, which is what lets Node report a missing module before anything runs, and what
makes top-level `await` possible.

## Why both still exist

CommonJS came first, in 2009, because JavaScript had no modules at all. ES modules arrived in the
language in 2015 and in Node, without a flag, in 2020. By then most of npm was CommonJS, and it
still holds a great deal of it; a server you maintain will import packages written both ways. So the
practical position is:

- **new code you write is ES modules**, because that is the language's own system and the one the
  browser, Deno and Bun share;
- **CommonJS is something you will read and depend on for years**, so you need to know its rules too.

This course writes ES modules from lesson 4 on. This lesson uses both, side by side, because the
differences are easiest to see that way.
