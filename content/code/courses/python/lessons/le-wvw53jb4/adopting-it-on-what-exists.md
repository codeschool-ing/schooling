---
title: Twenty thousand lines with no annotations
version: 1
---

The advice is always "turn on `--strict`", and on an existing codebase that produces four
thousand errors, an afternoon of despair, and a `# type: ignore` at the top of every file. Here
is the order that works instead.

## 1. Put it in CI on day one, loose

```toml
[tool.mypy]
files = ["app"]
```

Nothing else. It will report almost nothing, and **that is the point**: the pipeline now has a
step that can go red, and everything after this is raising the bar on a thing that already runs.

## 2. Turn on `check_untyped_defs`

```toml
check_untyped_defs = true
```

The cheapest real win available. It asks nobody to write an annotation and starts checking inside
the function bodies that already exist, so the errors it finds are bugs rather than paperwork.
Expect a first batch, fix it, and it stays quiet after that.

## 3. Stop the untyped half from growing

```toml
[tool.mypy]
files = ["app"]
check_untyped_defs = true
disallow_untyped_defs = true

[[tool.mypy.overrides]]
module = ["app.legacy.*", "app.reports.*", "app.jobs.*"]
disallow_untyped_defs = false
```

**This is the important step and it is easy to miss.** Strict by default, with the modules that
are not ready listed as exceptions — so every NEW module is checked properly from its first line,
and the list of exceptions can only shrink.

Written the other way round — loose by default, strict on a list of ready modules — the untyped
half grows every week and nobody notices, because nothing changes colour when it does.

## 4. Delete one line from the list at a time

Take the module at the top, annotate it, delete its line, and let CI tell you what broke. The
list is now a to-do list with a length, which is a very different thing from "we should add types
some day".

Annotate signatures before locals: a function with annotated parameters and return type gives the
checker almost everything it needs, and the locals are mostly inferred.

## 5. `--strict` last, if at all

By the time the override list is empty you already have most of what `--strict` gives. Add the
rest — `warn_return_any`, `disallow_any_generics`, `warn_unused_ignores` — one flag per pull
request, each with its own small fix-up.

## The rule for the whole process

**Never merge with a new ignore that has no reason beside it.** The state you are trying to avoid
is not "some code is unchecked" — that is where you started. It is a codebase full of comments
telling a checker to be quiet, where nobody remembers which ones are load-bearing.
