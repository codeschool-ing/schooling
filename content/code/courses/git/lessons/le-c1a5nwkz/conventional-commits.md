---
title: Conventional Commits
version: 1
---

**Conventional Commits** is a published convention, currently at version 1.0.0, for the first line
and footer of a message. It adds structure that a program can read, without making the message less
readable to a person:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A commit message with its parts labelled. The first line reads feat(order)!: require a pickup time for every order. feat is the type, what kind of change it is; order in brackets is the scope; the exclamation mark says it breaks something; the rest is the description, in the imperative. After a blank line comes the body, saying why. After another blank line, the footer BREAKING CHANGE states what breaks.\"><defs><marker id=\"cm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"680\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">feat</text><text x=\"64.8\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">(order)</text><text x=\"115.2\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">!</text><text x=\"122.4\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">: require a pickup time for every order</text><text x=\"36\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">The phone line used to accept orders with no time, and nobody knew</text><text x=\"36\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">when to bake them.</text><text x=\"36\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BREAKING CHANGE: an order sent without a pickup time is refused.</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">type: what kind of change</text><path d=\"M50 38 L50 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"210.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">scope: which part</text><path d=\"M90.0 38 L90.0 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"418.8\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">!: it breaks something</text><path d=\"M118.8 64 L118.8 44 L358.8 38\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"700\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">description: what it does, in the imperative</text><text x=\"700\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">body: why, wrapped at about 72</text><text x=\"700\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">footer: the breaking change, stated</text></svg>", "caption": "Every part can be read by a person, and the first line and the footer by a program as well."}
```

- **The type** is the first word: `feat` for something new, `fix` for a bug fixed. Those two are in
  the specification. Most teams add a few more that it allows: `docs`, `style`, `refactor` for a
  change that alters no behaviour, `test`, `chore`.
- **The scope**, optional, in brackets, says which part of the project: `(menu)`, `(order)`.
- **`!`** after the type or scope says the change breaks something that used to work.
- **The description** follows the colon, in the imperative, as in the last section.
- **The footer** `BREAKING CHANGE:` states what breaks, for anybody who needs to adapt.

Here is the site after four such commits since `v1.0`:

```
ana@vm:~/site$ git log --oneline v1.0..HEAD
566d361 feat(order)!: require a pickup time for every order
d991070 docs: explain how to add a menu item
85d0100 feat(menu): add carrot cake
ca5ac49 fix(menu): show the new price of cheese rolls
ana@vm:~/site$ git log --oneline --grep="^feat" v1.0..HEAD
566d361 feat(order)!: require a pickup time for every order
85d0100 feat(menu): add carrot cake
ana@vm:~/site$ git log -1 --format=%B
feat(order)!: require a pickup time for every order

The phone line used to accept orders with no time, and nobody knew
when to bake them.

BREAKING CHANGE: an order sent without a pickup time is refused.
```

`git log --grep="^feat"` lists the new features since the last release, which is the first half of
its release notes, written by nobody. The last command prints one message whole, so the footer can be
read in full.

## What the structure buys

The point of the convention is that **the history now answers questions a program can ask**:

- *What goes in the release notes?* Every `feat` and `fix` since the last tag, grouped.
- *What should the next version number be?* Lesson 7's semantic versioning, decided by the types: a
  `fix` since `v1.0` makes it `v1.0.1`, a `feat` makes it `v1.1.0`, and a breaking change makes it
  `v2.0.0`. Here there is a `!`, so the next release is `v2.0.0`.

Tools that do both from the log are common, and a team that adopts the convention usually adopts one,
together with a check on pull requests that refuses a message not in the format.

## Where it does not help

A type is not a reason. `fix: fix bug` is in the format and says nothing; *fix(menu): show the new price
of cheese rolls* is in the format and says what happened. The convention structures a message; it does
not write one. Adopt it when a team wants the release notes and version numbers to come from the
history. Without that, a clear first line is worth more than a correct prefix.
