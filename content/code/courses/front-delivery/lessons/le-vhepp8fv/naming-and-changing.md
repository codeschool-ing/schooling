---
title: Naming tokens, and changing them later
version: 1
---

**A token's name is an interface, and the products that use it depend on it the way code depends on a
function's name.** The value behind `accent` can change every month without anybody noticing, which is
the point. The name `accent` cannot change without every stylesheet that says `var(--accent)` breaking,
silently: an unknown custom property is simply empty, and the button loses its colour with no error
anywhere.

## Names that survive

Three habits keep names stable:

- **name the meaning, not the value.** `accent`, `muted`, `space-4`; never `green`, `grey-text` or
  `space-16px`. A name that describes its value becomes a lie the day the value changes.
- **one order for the parts**, the same everywhere: category, then variant, then state, such as
  `button-background-hover`. Which order matters less than having one, because people guess names, and a
  consistent order makes the guess right.
- **few words, chosen once.** `surface` or `background`, `muted` or `subtle`: pick one and write it down.
  Two synonyms in one system are two tokens nobody is sure are different.

## Changing a name

When a name has to change, the change is made in two releases, never one:

1. **add the new name and keep the old one as an alias** of it, marked deprecated: `subtle` is
   `{theme.muted}` for a while. Every product keeps working, and a warning, in the documentation or from a
   lint rule, tells each one to move.
2. **remove the old name** once nothing uses it, in a release whose version says it can break things.

Lesson 7 gives the version numbers their meaning: adding a token is a minor change, removing or renaming
one is a major change. That rule is the reason a design system needs versions at all.

## The same names in the design tool

Design tools keep their own variables, and the most common failure of a design system is the tool and the
code drifting apart: a designer's `Accent/Default` and a developer's `--accent` that started equal and are
two greens a year later. The Design Tokens Community Group format exists so that the tokens file can be
the one source both read, exported from the tool or imported into it. Whichever side is the source, **it
is one file with one owner, and the other side is generated from it**, exactly as `tokens.css` is from
`tokens.json`.
