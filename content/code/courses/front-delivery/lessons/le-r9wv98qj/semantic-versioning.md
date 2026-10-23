---
title: Semantic versioning, for a design system
version: 1
---

**A version number is a promise about what changed, and semantic versioning makes the promise precise:
`MAJOR.MINOR.PATCH`, where each part says what kind of change the release contains.** The planner's
consumers will read `0.1.0` and `0.2.0` and decide from the numbers alone whether to upgrade without
looking, so the numbers have to be right.

| part | goes up when a release | a consumer can |
|---|---|---|
| PATCH, `0.1.0` → `0.1.1` | fixes something without changing what is offered | take it without reading anything |
| MINOR, `0.1.1` → `0.2.0` | adds something, and removes or changes nothing | take it, and use the new thing if they want |
| MAJOR, `0.2.0` → `1.0.0` | removes or changes something consumers could depend on | read the notes and change their code first |

**Before `1.0.0` the rules shift down one place.** The specification says anything may change in a `0.x`
version; in practice npm treats a `0.x` minor as the breaking part, so `^0.1.0` accepts `0.1.5` and refuses
`0.2.0`. A library at `0.x` is telling its consumers it has not yet promised stability. `1.0.0` is the
release that makes the promise.

## What counts as breaking, for a design system

For an ordinary library, breaking means code that compiled now fails. A design system breaks in that way
and in two quieter ones:

- **its code interface**: an export removed or renamed, an argument added that is required, a type
  narrowed. `tsc` catches these in the consumer, which is the easy case.
- **its token names**: `--muted` renamed to `--subtle`. Nothing fails to compile; the consumer's CSS
  silently loses a colour, as lesson 5 showed. **A token rename is a major change** even though no tool
  complains.
- **its look**: a default padding doubled, a radius changed. Whether that is breaking is a judgement, and
  teams disagree. A useful rule: if a consumer's screenshot tests would fail and they would need to
  re-approve pictures, say so in the version.

## What the consumer writes

The other half of the promise is the range a consumer accepts. `npm install` writes `^0.1.0` by default,
which takes any compatible update automatically. **This course pins exact versions**, `0.1.0`, so an
upgrade is a commit somebody makes and reviews, and the lockfile pins everything beneath. For a design
system that is worth the small effort: a new version can move pixels on every screen, and that is a change
somebody should look at, through the visual tests of lesson 6, on purpose.
