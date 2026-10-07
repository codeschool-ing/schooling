---
title: The same idea, inside one program
version: 1
---

Contracts are not only for data that leaves a company. The platform you are studying on applies the
same idea between the parts of a single program, and its reason is the one this lesson started with:
a change in one place should never break another place silently.

Its code is divided into **modules**, each owning its own tables, and one rule is enforced by a test
that runs on every change:

```go
// The dependency graph between modules, enforced rather than agreed.
//
// IT EXISTS FROM THE FIRST MODULE ON PURPOSE. A rule like this only works if
// it was there before the first violation: added later, it fails on code that
// already ships, and the pressure is then to weaken the rule rather than fix
// the dependency. Written now, while there are three packages, it costs
// nothing and it is what turns "extract this into its own service" from a
// rewrite into a day's work.
//
// # THE TWO RULES
//
//  1. `platform` imports nothing else from this repository. Whatever lands
//     there is available to every module, so anything with an opinion about the
//     product does not belong in it — and an import pointing outwards is how
//     that opinion would arrive.
//
//  2. No module imports another module. They talk through interfaces the
//     consumer defines, and are wired together in `cmd/`. `platform` is the
//     exception every module may depend on, because that is what it is for.
//
// When a second module needs something from a first, the answer is not an
// import: it is an interface where it is used, satisfied by the other and
// passed in from `cmd/`. That is the whole discipline, and it is the reason a
// binary this small can be split later without archaeology.
```

"No module imports another module. They talk through interfaces the consumer defines." In this
lesson's words: **no team reads another team's tables directly; it reads what the other team has
promised to serve.** The interface is the contract; the test is the checker; and the comment explains
why it was written before the first violation rather than after — added later, a rule like this fails
on code that already ships, and the pressure is then to weaken the rule.

## Why it matters for governance

Every argument of this course about tables applies here:

- **ownership** is clear, because each table belongs to one module, and that module decides what it
  means;
- **lineage** is readable, because every path between two modules goes through a declared interface;
- **erasure** is possible, because every table is registered with what it holds and what erasing a
  person does to it, and a test fails on a new table that nobody registered — lesson 6's check, in
  the platform's own code.

A database where any query may join any table is a database where nobody can say what depends on what.
Contracts, between companies or between modules, are how that question gets an answer.
